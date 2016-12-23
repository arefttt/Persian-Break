//
//  libxnuexp.m
//  libxnuexp
//
//  Created by qwertyoruiop on 03/09/15.
//  Copyright (c) 2015 Kim Jong Cracks - World Wide Crack Distribution Inc. All rights reserved.
//

#import "libxnuexp.h"

__unused static struct section_64 *find_section_64(struct segment_command_64 *seg, const char *name)
{
    struct section_64 *sect, *fs = NULL;
    uint32_t i = 0;
    for (i = 0, sect = (struct section_64 *)((uint64_t)seg + (uint64_t)sizeof(struct segment_command_64));
         i < seg->nsects;
         i++, sect = (struct section_64 *)((uint64_t)sect + sizeof(struct section_64)))
    {
        if (!strcmp(sect->sectname, name)) {
            fs = sect;
            break;
        }
    }
    return fs;
}


__unused static struct section *find_section(struct segment_command *seg, const char *name)
{
    struct section *sect, *fs = NULL;
    uint32_t i = 0;
    for (i = 0, sect = (struct section *)((uint64_t)seg + (uint64_t)sizeof(struct segment_command));
         i < seg->nsects;
         i++, sect = (struct section*)((uint64_t)sect + sizeof(struct section)))
    {
        if (!strcmp(sect->sectname, name)) {
            fs = sect;
            break;
        }
    }
    return fs;
}
__unused static struct segment_command_64 *find_segment_64(struct mach_header_64 *mh, const char *segname)
{
    struct load_command *lc;
    struct segment_command_64 *s, *fs = NULL;
    lc = (struct load_command *)((uint64_t)mh + sizeof(struct mach_header_64));
    while ((uint64_t)lc < (uint64_t)mh + (uint64_t)mh->sizeofcmds) {
        if (lc->cmd == LC_SEGMENT_64) {
            s = (struct segment_command_64 *)lc;
            if (!strcmp(s->segname, segname)) {
                fs = s;
                break;
            }
        }
        lc = (struct load_command *)((uint64_t)lc + (uint64_t)lc->cmdsize);
    }
    return fs;
}

__unused static struct segment_command *find_segment(struct mach_header *mh, const char *segname)
{
    struct load_command *lc;
    struct segment_command *s, *fs = NULL;
    lc = (struct load_command *)((uint64_t)mh + sizeof(struct mach_header));
    while ((uint64_t)lc < (uint64_t)mh + (uint64_t)mh->sizeofcmds) {
        if (lc->cmd == LC_SEGMENT) {
            s = (struct segment_command *)lc;
            if (!strcmp(s->segname, segname)) {
                fs = s;
                break;
            }
        }
        lc = (struct load_command *)((uint64_t)lc + (uint64_t)lc->cmdsize);
    }
    return fs;
}
static struct load_command *find_load_command_64(struct mach_header_64 *mh, uint32_t cmd)
{
    struct load_command *lc, *flc;
    lc = (struct load_command *)((uint64_t)mh + sizeof(struct mach_header_64));
    while ((uint64_t)lc < (uint64_t)mh + (uint64_t)mh->sizeofcmds) {
        if (lc->cmd == cmd) {
            flc = (struct load_command *)lc;
            break;
        }
        lc = (struct load_command *)((uint64_t)lc + (uint64_t)lc->cmdsize);
    }
    return flc;
}
static struct load_command *find_load_command(struct mach_header *mh, uint32_t cmd)
{
    struct load_command *lc, *flc;
    lc = (struct load_command *)((uint64_t)mh + sizeof(struct mach_header));
    while ((uint64_t)lc < (uint64_t)mh + (uint64_t)mh->sizeofcmds) {
        if (lc->cmd == cmd) {
            flc = (struct load_command *)lc;
            break;
        }
        lc = (struct load_command *)((uint64_t)lc + (uint64_t)lc->cmdsize);
    }
    return flc;
}

__unused static struct segment_command_64 *find_offzero_segment_64(struct mach_header_64 *mh)
{
    struct load_command *lc;
    struct segment_command_64 *s, *fs = NULL;
    lc = (struct load_command *)((uint64_t)mh + sizeof(struct mach_header_64));
    while ((uint64_t)lc < (uint64_t)mh + (uint64_t)mh->sizeofcmds) {
        if (lc->cmd == LC_SEGMENT_64) {
            s = (struct segment_command_64 *)lc;
            if (s->fileoff == 0 && s->filesize != 0) {
                fs = s;
                break;
            }
        }
        lc = (struct load_command *)((uint64_t)lc + (uint64_t)lc->cmdsize);
    }
    return fs;
}

__unused static struct segment_command *find_offzero_segment(struct mach_header *mh)
{
    struct load_command *lc;
    struct segment_command *s, *fs = NULL;
    lc = (struct load_command *)((uint64_t)mh + sizeof(struct mach_header));
    while ((uint64_t)lc < (uint64_t)mh + (uint64_t)mh->sizeofcmds) {
        if (lc->cmd == LC_SEGMENT) {
            s = (struct segment_command *)lc;
            if (s->fileoff == 0 && s->filesize != 0) {
                fs = s;
                break;
            }
        }
        lc = (struct load_command *)((uint64_t)lc + (uint64_t)lc->cmdsize);
    }
    return fs;
}

@interface xnuexp_mach_o_32 : xnuexp_mach_o
@end

@interface xnuexp_mach_o_64 : xnuexp_mach_o
@end


@implementation xnuexp_mach_o_32
- (uint64_t) solveSymbol:(NSString*) string {
    if ([symbolCache objectForKey:string]) {
        return [[symbolCache objectForKey:string] unsignedLongLongValue] + self.slide;
    }
    const char* name = [string UTF8String];
    struct mach_header* mh = (struct mach_header*)hdr;
    struct symtab_command *symtab = (struct symtab_command *)find_load_command(mh, LC_SYMTAB);
    
    char* sym_str_table = (((char*)mh) + symtab->stroff);
    struct nlist* sym_table = (struct nlist*) (((char*)mh) + symtab->symoff);
    
    for (int i = 0; i < symtab->nsyms; i++) {
        if (sym_table[i].n_value && !strcmp(name,&sym_str_table[sym_table[i].n_un.n_strx])) {
            [symbolCache setObject:[NSNumber numberWithUnsignedLongLong:sym_table[i].n_value] forKey:string];
            return (uint64_t) (sym_table[i].n_value + self.slide);
        }
    }
    return 0;
}
@end

@implementation xnuexp_mach_o_64
- (uint64_t) solveSymbol:(NSString*) string {
    if ([symbolCache objectForKey:string]) {
        return [[symbolCache objectForKey:string] unsignedLongLongValue] + self.slide;
    }
    const char* name = [string UTF8String];
    struct mach_header_64* mh = (struct mach_header_64*)hdr;
    struct symtab_command *symtab = (struct symtab_command *)find_load_command_64(mh, LC_SYMTAB);

    char* sym_str_table = (((char*)mh) + symtab->stroff);
    struct nlist_64* sym_table = (struct nlist_64*) (((char*)mh) + symtab->symoff);

    for (int i = 0; i < symtab->nsyms; i++) {
        if (sym_table[i].n_value && !strcmp(name,&sym_str_table[sym_table[i].n_un.n_strx])) {
            [symbolCache setObject:[NSNumber numberWithUnsignedLongLong:sym_table[i].n_value] forKey:string];
            return (uint64_t) (sym_table[i].n_value + self.slide);
        }
    }
    return 0;
}
@end
@implementation xnuexp_fat_mach_o
- (xnuexp_fat_mach_o*) initWithContentsOfFile:(NSString*) path
{
    int fd=open([path UTF8String], O_RDONLY);
    if(fd < 0) return nil;
    struct stat sb;
    fstat(fd, &sb);
    if (sb.st_size < 0x1000) {
        return nil;
    }
    void* map = mmap(NULL, sb.st_size  & 0xFFFFFFFF, PROT_READ|PROT_EXEC|PROT_WRITE, MAP_PRIVATE, fd, 0);
    assert(map != (void*)-1);
    if ((self = [self initWithBytes:map])) {
        free_size = sb.st_size  & 0xFFFFFFFF;
        return self;
    }
    munmap(map, sb.st_size  & 0xFFFFFFFF);
    return self;
}
#define SwapMeMaybe(x) ((hdr->magic == FAT_CIGAM) ? OSSwapInt32(x) : x)
- (xnuexp_fat_mach_o*) initWithBytes:(struct fat_header*) header
{
    if (header->magic == FAT_MAGIC || header->magic == FAT_CIGAM) {
        hdr = header;
        return self;
    }
    return nil;
}
+ (xnuexp_fat_mach_o*) withContentsOfFile:(NSString*) path
{
    return [[self alloc] initWithContentsOfFile:path];
}
+ (xnuexp_fat_mach_o*) withBytes:(struct fat_header*) header
{
    return [[self alloc] initWithBytes: header];
}
- (xnuexp_mach_o*) getArchitectureByNumber:(uint32_t) archNum
{
    struct fat_arch* arch = (void*)(hdr + 1);
    for (int i = 0; i < SwapMeMaybe(hdr->nfat_arch); i++) {
        struct mach_header* arch_header = (void*)(((char*)hdr)+SwapMeMaybe(arch->offset));
        if (i == archNum) {
            return [xnuexp_mach_o withBytes:arch_header]; // I know.
        }
        arch++;
    }
    return nil;
}
- (xnuexp_mach_o*) getArchitectureByFirstMagicMatch:(uint32_t) magic
{
    struct fat_arch* arch = (void*)(hdr + 1);
    for (int i = 0; i < SwapMeMaybe(hdr->nfat_arch); i++) {
        struct mach_header* arch_header = (void*)(((char*)hdr)+SwapMeMaybe(arch->offset));
        if (arch_header->magic == magic) {
            return [xnuexp_mach_o withBytes:arch_header]; // I know.
        }
        arch++;
    }
    return nil;
}
- (xnuexp_mach_o*) getArchitectureByCPUType:(uint32_t) cpuType subType:(uint32_t) cpuSubtype;
{
    struct fat_arch* arch = (void*)(hdr + 1);
    for (int i = 0; i < SwapMeMaybe(hdr->nfat_arch); i++) {
        struct mach_header* arch_header = (void*)(((char*)hdr)+SwapMeMaybe(arch->offset));
        if (arch_header->cpusubtype == cpuSubtype && arch_header->cputype == cpuType) {
            return [xnuexp_mach_o withBytes:arch_header]; // I know.
        }
        arch++;
    }
    return nil;
}
-(void)dealloc
{
    if(free_size)
        munmap(hdr, free_size  & 0xFFFFFFFF);
#ifndef __ARC__
    [super dealloc];
#endif
}
@end

@implementation xnuexp_mach_o
@synthesize hdr;
@synthesize free_size;
@synthesize slide;
@synthesize base;

- (uint64_t) solveSymbol:(NSString*) string {
    return 0;
}

+ (xnuexp_mach_o*) withContentsOfFile:(NSString*) path
{
    return [[self alloc] initWithContentsOfFile:path];
}

+ (xnuexp_mach_o*) withBytes:(struct mach_header*) header
{
    return [[self alloc] initWithBytes: header];
}

- (xnuexp_mach_o*) initWithContentsOfFile:(NSString*) path {
    int fd=open([path UTF8String], O_RDONLY);
    if(fd < 0) return nil;
    struct stat sb;
    fstat(fd, &sb);
    if (sb.st_size < 0x1000) {
        return nil;
    }
    void* map = mmap(NULL, sb.st_size  & 0xFFFFFFFF, PROT_READ|PROT_EXEC|PROT_WRITE, MAP_PRIVATE, fd, 0);
    assert(map != (void*)-1);
    if ((self = [self initWithBytes:map])) {
        free_size = sb.st_size  & 0xFFFFFFFF;
        return self;
    }
    munmap(map, sb.st_size  & 0xFFFFFFFF);
    return self;
}
- (xnuexp_mach_o*) initWithBytes:(struct mach_header *)header
{
    if (header->magic == MH_MAGIC) {
        self = [[xnuexp_mach_o_32 alloc] init];
        hdr = header;
        symbolCache = [NSMutableDictionary new];
        base = find_offzero_segment((struct mach_header*)hdr)->vmaddr;
        return self;
    } else if (header->magic == MH_MAGIC_64) {
        self = [[xnuexp_mach_o_64 alloc] init];
        hdr = header;
        symbolCache = [NSMutableDictionary new];
        base = find_offzero_segment_64((struct mach_header_64*)hdr)->vmaddr;
        return self;
    }
    return nil;
}
-(void)dealloc
{
    if(free_size)
        munmap(hdr, free_size  & 0xFFFFFFFF);
#ifndef __ARC__
    [super dealloc];
#endif
}

@end

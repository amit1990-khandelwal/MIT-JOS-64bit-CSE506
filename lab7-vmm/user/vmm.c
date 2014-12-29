#ifndef VMM_GUEST
#include <inc/lib.h>
#include <inc/vmx.h>
#include <inc/elf.h>
#include <inc/ept.h>

#define GUEST_KERN "/vmm/kernel"
#define GUEST_BOOT "/vmm/boot"

#define JOS_ENTRY 0x7000

// Map a region of file fd into the guest at guest physical address gpa.
// The file region to map should start at fileoffset and be length filesz.
// The region to map in the guest should be memsz.  The region can span multiple pages.
//
// Return 0 on success, <0 on failure.
//
static int
map_in_guest( envid_t guest, uintptr_t gpa, size_t memsz, 
	      int fd, size_t filesz, off_t fileoffset ) {
	/* Your code here */
	if (PGOFF(gpa)) {
		ROUNDDOWN(gpa, PGSIZE);
	}
	int i, r = 0;
    for (i = 0; i < filesz; i += PGSIZE) {
	    r = sys_page_alloc(0, UTEMP, PTE_P | PTE_U | PTE_W);
		if (r < 0)
			return r;
	    r = seek(fd, fileoffset + i);
		if (r < 0)
			return r;
	    r = readn(fd, UTEMP, MIN(PGSIZE, filesz-i));
		if (r<0) 
			return r;
	    r = sys_ept_map(thisenv->env_id, (void*)UTEMP, guest, (void*) (gpa + i), __EPTE_FULL);
		if (r < 0)
			panic("Something wrong with map_in_guest after calling sys_ept_map: %e", r);
	    sys_page_unmap(0, UTEMP);	   
	}
	for (; i < memsz; i+= PGSIZE) {
		r = sys_page_alloc(0, (void*) UTEMP, __EPTE_FULL);
		if (r < 0)
			return r;
	    r = sys_ept_map(thisenv->env_id, UTEMP, guest, (void *)(gpa + i), __EPTE_FULL);
		if (r < 0)
			panic("Something wrong with sys_ept_map: %e", r);
	    sys_page_unmap(0, UTEMP);
	}
	return 0;
} 

// Read the ELF headers of kernel file specified by fname,
// mapping all valid segments into guest physical memory as appropriate.
//
// Return 0 on success, <0 on error
//
// Hint: compare with ELF parsing in env.c, and use map_in_guest for each segment.
static int
copy_guest_kern_gpa( envid_t guest, char* fname ) {
	/* Your code here */
	int fd = open(fname, O_RDONLY);
	if(fd < 0)
		return -E_NOT_FOUND;
	char data[512]; //512 bytes block size
	if (readn(fd, data, sizeof(data)) != sizeof(data)) {
		close(fd);
		return -E_NOT_FOUND;
	}
	struct Elf *elfhdr = (struct Elf*)data;
	if (elfhdr->e_magic != ELF_MAGIC) {
		close(fd);
		return -E_NOT_EXEC;
	}
	// Program Header part from env.c...
	struct Proghdr* ph = (struct Proghdr*) (data + elfhdr->e_phoff);
	struct Proghdr* eph = ph + elfhdr->e_phnum;
	int r = 0;
	for (; ph < eph; ph++) {
    	if (ph->p_type == ELF_PROG_LOAD) {
			// Call map_in_guest if needed.
			r = map_in_guest(guest, ph->p_pa, ph->p_memsz, fd, ph->p_filesz, ph->p_offset);
			if (r < 0) {
				close(fd);
				return -E_NO_SYS;
			}
		}
	}
	close(fd);
	return r;
}
void
umain(int argc, char **argv) {
	int ret;
	envid_t guest;

	if ((ret = sys_env_mkguest( GUEST_MEM_SZ, JOS_ENTRY )) < 0) {
		cprintf("Error creating a guest OS env: %e\n", ret );
		exit();
	}
	guest = ret;

	// Copy the guest kernel code into guest phys mem.
	if((ret = copy_guest_kern_gpa(guest, GUEST_KERN)) < 0) {
		cprintf("Error copying page into the guest - %d\n.", ret);
		exit();
	}

	// Now copy the bootloader.
	int fd;
	if ((fd = open( GUEST_BOOT, O_RDONLY)) < 0 ) {
		cprintf("open %s for read: %e\n", GUEST_BOOT, fd );
		exit();
	}

	// sizeof(bootloader) < 512.
	if ((ret = map_in_guest(guest, JOS_ENTRY, 512, fd, 512, 0)) < 0) {
		cprintf("Error mapping bootloader into the guest - %d\n.", ret);
		exit();
	}

	// Mark the guest as runnable.
	sys_env_set_status(guest, ENV_RUNNABLE);
	wait(guest);
}
#endif
#ifdef VMM_GUEST
#include <inc/lib.h>
#include <inc/elf.h>
void umain(int argc, char **argv) {
	exit();
}
#endif

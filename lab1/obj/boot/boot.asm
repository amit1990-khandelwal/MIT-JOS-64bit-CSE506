
obj/boot/boot.out:     file format elf32-i386


Disassembly of section .text:

00007c00 <start>:

.globl multiboot_info
.globl start
start:
  .code16                     # Assemble for 16-bit mode
  cli                         # Disable interrupts
    7c00:	fa                   	cli    
  cld                         # String operations increment
    7c01:	fc                   	cld    

  # Set up the important data segment registers (DS, ES, SS).
  xorw    %ax,%ax             # Segment number zero
    7c02:	31 c0                	xor    %eax,%eax
  movw    %ax,%ds             # -> Data Segment
    7c04:	8e d8                	mov    %eax,%ds
  movw    %ax,%es             # -> Extra Segment
    7c06:	8e c0                	mov    %eax,%es
  movw    %ax,%ss             # -> Stack Segment
    7c08:	8e d0                	mov    %eax,%ss

00007c0a <seta20.1>:
  # Enable A20:
  #   For backwards compatibility with the earliest PCs, physical
  #   address line 20 is tied low, so that addresses higher than
  #   1MB wrap around to zero by default.  This code undoes this.
seta20.1:
  inb     $0x64,%al               # Wait for not busy
    7c0a:	e4 64                	in     $0x64,%al
  testb   $0x2,%al
    7c0c:	a8 02                	test   $0x2,%al
  jnz     seta20.1
    7c0e:	75 fa                	jne    7c0a <seta20.1>

  movb    $0xd1,%al               # 0xd1 -> port 0x64
    7c10:	b0 d1                	mov    $0xd1,%al
  outb    %al,$0x64
    7c12:	e6 64                	out    %al,$0x64

00007c14 <seta20.2>:

seta20.2:
  inb     $0x64,%al               # Wait for not busy
    7c14:	e4 64                	in     $0x64,%al
  testb   $0x2,%al
    7c16:	a8 02                	test   $0x2,%al
  jnz     seta20.2
    7c18:	75 fa                	jne    7c14 <seta20.2>

  movb    $0xdf,%al               # 0xdf -> port 0x60
    7c1a:	b0 df                	mov    $0xdf,%al
  outb    %al,$0x60
    7c1c:	e6 60                	out    %al,$0x60

00007c1e <do_e820>:

  # get the E820 memory map from the BIOS
do_e820:
  movl $0xe820, %eax
    7c1e:	66 b8 20 e8          	mov    $0xe820,%ax
    7c22:	00 00                	add    %al,(%eax)
  movl $e820_map, %ebx
    7c24:	66 bb 34 70          	mov    $0x7034,%bx
    7c28:	00 00                	add    %al,(%eax)
  movl %ebx, %edi
    7c2a:	66 89 df             	mov    %bx,%di
  addl $4, %edi
    7c2d:	66 83 c7 04          	add    $0x4,%di
  xorl %ebx, %ebx
    7c31:	66 31 db             	xor    %bx,%bx
  movl $0x534D4150, %edx
    7c34:	66 ba 50 41          	mov    $0x4150,%dx
    7c38:	4d                   	dec    %ebp
    7c39:	53                   	push   %ebx
  movl $24, %ecx
    7c3a:	66 b9 18 00          	mov    $0x18,%cx
    7c3e:	00 00                	add    %al,(%eax)
  int $0x15
    7c40:	cd 15                	int    $0x15
  jc failed
    7c42:	72 4d                	jb     7c91 <failed>
  cmpl %eax, %edx
    7c44:	66 39 c2             	cmp    %ax,%dx
  jne failed
    7c47:	75 48                	jne    7c91 <failed>
  testl %ebx, %ebx
    7c49:	66 85 db             	test   %bx,%bx
  je failed
    7c4c:	74 43                	je     7c91 <failed>
  movl $24, %ebp
    7c4e:	66 bd 18 00          	mov    $0x18,%bp
	...

00007c54 <next_entry>:

next_entry:
  #increment di
  movl %ecx, -4(%edi)
    7c54:	67 66 89 4f fc       	mov    %cx,-0x4(%bx)
  addl $24, %edi
    7c59:	66 83 c7 18          	add    $0x18,%di
  movl $0xe820, %eax
    7c5d:	66 b8 20 e8          	mov    $0xe820,%ax
    7c61:	00 00                	add    %al,(%eax)
  movl $24, %ecx
    7c63:	66 b9 18 00          	mov    $0x18,%cx
    7c67:	00 00                	add    %al,(%eax)
  int $0x15
    7c69:	cd 15                	int    $0x15
  jc done
    7c6b:	72 0b                	jb     7c78 <done>
  addl $24, %ebp
    7c6d:	66 83 c5 18          	add    $0x18,%bp
  testl %ebx, %ebx
    7c71:	66 85 db             	test   %bx,%bx
  je done
    7c74:	74 02                	je     7c78 <done>
  jmp next_entry
    7c76:	eb dc                	jmp    7c54 <next_entry>

00007c78 <done>:

done:
  movl %ecx, -4(%edi)
    7c78:	67 66 89 4f fc       	mov    %cx,-0x4(%bx)
  movw $0x40, (MB_flag) #multiboot info flags
    7c7d:	c7 06 00 70 40 00    	movl   $0x407000,(%esi)
  movl $e820_map, (MB_mmap_addr)
    7c83:	66 c7 06 30 70       	movw   $0x7030,(%esi)
    7c88:	34 70                	xor    $0x70,%al
    7c8a:	00 00                	add    %al,(%eax)
  movl %ebp, (MB_mmap_len)
    7c8c:	66 89 2e             	mov    %bp,(%esi)
    7c8f:	2c 70                	sub    $0x70,%al

00007c91 <failed>:
 
  # Switch from real to protected mode, using a bootstrap GDT
  # and segment translation that makes virtual addresses 
  # identical to their physical addresses, so that the 
  # effective memory map does not change during the switch.
  lgdt    gdtdesc
    7c91:	0f 01 16             	lgdtl  (%esi)
    7c94:	dc 7c 0f 20          	fdivrl 0x20(%edi,%ecx,1)
  movl    %cr0, %eax
    7c98:	c0 66 83 c8          	shlb   $0xc8,-0x7d(%esi)
  orl     $CR0_PE_ON, %eax
    7c9c:	01 0f                	add    %ecx,(%edi)
  movl    %eax, %cr0
    7c9e:	22 c0                	and    %al,%al
 
  # Jump to next instruction, but in 32-bit code segment.
  # Switches processor into 32-bit mode.
  ljmp    $PROT_MODE_CSEG, $protcseg
    7ca0:	ea a5 7c 08 00 66 b8 	ljmp   $0xb866,$0x87ca5

00007ca5 <protcseg>:

  .code32                     # Assemble for 32-bit mode
protcseg:
  # Set up the protected-mode data segment registers
  movw    $PROT_MODE_DSEG, %ax    # Our data segment selector
    7ca5:	66 b8 10 00          	mov    $0x10,%ax
  movw    %ax, %ds                # -> DS: Data Segment
    7ca9:	8e d8                	mov    %eax,%ds
  movw    %ax, %es                # -> ES: Extra Segment
    7cab:	8e c0                	mov    %eax,%es
  movw    %ax, %fs                # -> FS
    7cad:	8e e0                	mov    %eax,%fs
  movw    %ax, %gs                # -> GS
    7caf:	8e e8                	mov    %eax,%gs
  movw    %ax, %ss                # -> SS: Stack Segment
    7cb1:	8e d0                	mov    %eax,%ss
  
  # Set up the stack pointer and call into C.
  movl    $start, %esp
    7cb3:	bc 00 7c 00 00       	mov    $0x7c00,%esp
  movl $multiboot_info, %ebx
    7cb8:	bb 00 70 00 00       	mov    $0x7000,%ebx
 # call bootmain
   call bootmain
    7cbd:	e8 c1 00 00 00       	call   7d83 <bootmain>

00007cc2 <spin>:

  # If bootmain returns (it shouldn't), loop.
spin:
  jmp spin
    7cc2:	eb fe                	jmp    7cc2 <spin>

00007cc4 <gdt>:
	...
    7ccc:	ff                   	(bad)  
    7ccd:	ff 00                	incl   (%eax)
    7ccf:	00 00                	add    %al,(%eax)
    7cd1:	9a cf 00 ff ff 00 00 	lcall  $0x0,$0xffff00cf
    7cd8:	00 92 cf 00 17 00    	add    %dl,0x1700cf(%edx)

00007cdc <gdtdesc>:
    7cdc:	17                   	pop    %ss
    7cdd:	00 c4                	add    %al,%ah
    7cdf:	7c 00                	jl     7ce1 <gdtdesc+0x5>
    7ce1:	00 90 90 55 ba f7    	add    %dl,-0x845aa70(%eax)

00007ce4 <waitdisk>:
	}
}

void
waitdisk(void)
{
    7ce4:	55                   	push   %ebp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
    7ce5:	ba f7 01 00 00       	mov    $0x1f7,%edx
    7cea:	89 e5                	mov    %esp,%ebp
    7cec:	ec                   	in     (%dx),%al
	// wait for disk reaady
	while ((inb(0x1F7) & 0xC0) != 0x40)
    7ced:	25 c0 00 00 00       	and    $0xc0,%eax
    7cf2:	83 f8 40             	cmp    $0x40,%eax
    7cf5:	75 f5                	jne    7cec <waitdisk+0x8>
		/* do nothing */;
}
    7cf7:	5d                   	pop    %ebp
    7cf8:	c3                   	ret    

00007cf9 <readsect>:

void
readsect(void *dst, uint32_t offset)
{
    7cf9:	55                   	push   %ebp
    7cfa:	89 e5                	mov    %esp,%ebp
    7cfc:	57                   	push   %edi
    7cfd:	8b 7d 0c             	mov    0xc(%ebp),%edi
	// wait for disk to be ready
	waitdisk();
    7d00:	e8 df ff ff ff       	call   7ce4 <waitdisk>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
    7d05:	ba f2 01 00 00       	mov    $0x1f2,%edx
    7d0a:	b0 01                	mov    $0x1,%al
    7d0c:	ee                   	out    %al,(%dx)
    7d0d:	b2 f3                	mov    $0xf3,%dl
    7d0f:	89 f8                	mov    %edi,%eax
    7d11:	ee                   	out    %al,(%dx)

	outb(0x1F2, 1);		// count = 1
	outb(0x1F3, offset);
	outb(0x1F4, offset >> 8);
    7d12:	89 f8                	mov    %edi,%eax
    7d14:	b2 f4                	mov    $0xf4,%dl
    7d16:	c1 e8 08             	shr    $0x8,%eax
    7d19:	ee                   	out    %al,(%dx)
	outb(0x1F5, offset >> 16);
    7d1a:	89 f8                	mov    %edi,%eax
    7d1c:	b2 f5                	mov    $0xf5,%dl
    7d1e:	c1 e8 10             	shr    $0x10,%eax
    7d21:	ee                   	out    %al,(%dx)
	outb(0x1F6, (offset >> 24) | 0xE0);
    7d22:	c1 ef 18             	shr    $0x18,%edi
    7d25:	b2 f6                	mov    $0xf6,%dl
    7d27:	89 f8                	mov    %edi,%eax
    7d29:	83 c8 e0             	or     $0xffffffe0,%eax
    7d2c:	ee                   	out    %al,(%dx)
    7d2d:	b0 20                	mov    $0x20,%al
    7d2f:	b2 f7                	mov    $0xf7,%dl
    7d31:	ee                   	out    %al,(%dx)
	outb(0x1F7, 0x20);	// cmd 0x20 - read sectors

	// wait for disk to be ready
	waitdisk();
    7d32:	e8 ad ff ff ff       	call   7ce4 <waitdisk>
}

static __inline void
insl(int port, void *addr, int cnt)
{
	__asm __volatile("cld\n\trepne\n\tinsl"			:
    7d37:	8b 7d 08             	mov    0x8(%ebp),%edi
    7d3a:	b9 80 00 00 00       	mov    $0x80,%ecx
    7d3f:	ba f0 01 00 00       	mov    $0x1f0,%edx
    7d44:	fc                   	cld    
    7d45:	f2 6d                	repnz insl (%dx),%es:(%edi)

	// read a sector
	insl(0x1F0, dst, SECTSIZE/4);
}
    7d47:	5f                   	pop    %edi
    7d48:	5d                   	pop    %ebp
    7d49:	c3                   	ret    

00007d4a <readseg>:

// Read 'count' bytes at 'offset' from kernel into physical address 'pa'.
// Might copy more than asked
void
readseg(uint32_t pa, uint32_t count, uint32_t offset)
{
    7d4a:	55                   	push   %ebp
    7d4b:	89 e5                	mov    %esp,%ebp
    7d4d:	57                   	push   %edi
	uint32_t end_pa;

	end_pa = pa + count;
    7d4e:	8b 7d 0c             	mov    0xc(%ebp),%edi

// Read 'count' bytes at 'offset' from kernel into physical address 'pa'.
// Might copy more than asked
void
readseg(uint32_t pa, uint32_t count, uint32_t offset)
{
    7d51:	56                   	push   %esi
    7d52:	8b 75 10             	mov    0x10(%ebp),%esi
    7d55:	53                   	push   %ebx
    7d56:	8b 5d 08             	mov    0x8(%ebp),%ebx
	
	// round down to sector boundary
	pa &= ~(SECTSIZE - 1);

	// translate from bytes to sectors, and kernel starts at sector 3
	offset = (offset / SECTSIZE) + 1;
    7d59:	c1 ee 09             	shr    $0x9,%esi
void
readseg(uint32_t pa, uint32_t count, uint32_t offset)
{
	uint32_t end_pa;

	end_pa = pa + count;
    7d5c:	01 df                	add    %ebx,%edi
	
	// round down to sector boundary
	pa &= ~(SECTSIZE - 1);

	// translate from bytes to sectors, and kernel starts at sector 3
	offset = (offset / SECTSIZE) + 1;
    7d5e:	46                   	inc    %esi

	end_pa = pa + count;
	uint32_t orgoff = offset;
	
	// round down to sector boundary
	pa &= ~(SECTSIZE - 1);
    7d5f:	81 e3 00 fe ff ff    	and    $0xfffffe00,%ebx
	offset = (offset / SECTSIZE) + 1;

	// If this is too slow, we could read lots of sectors at a time.
	// We'd write more to memory than asked, but it doesn't matter --
	// we load in increasing order.
	while (pa < end_pa) {
    7d65:	eb 10                	jmp    7d77 <readseg+0x2d>
		readsect((uint8_t*) pa, offset);
    7d67:	56                   	push   %esi
		pa += SECTSIZE;
		offset++;
    7d68:	46                   	inc    %esi

	// If this is too slow, we could read lots of sectors at a time.
	// We'd write more to memory than asked, but it doesn't matter --
	// we load in increasing order.
	while (pa < end_pa) {
		readsect((uint8_t*) pa, offset);
    7d69:	53                   	push   %ebx
		pa += SECTSIZE;
    7d6a:	81 c3 00 02 00 00    	add    $0x200,%ebx

	// If this is too slow, we could read lots of sectors at a time.
	// We'd write more to memory than asked, but it doesn't matter --
	// we load in increasing order.
	while (pa < end_pa) {
		readsect((uint8_t*) pa, offset);
    7d70:	e8 84 ff ff ff       	call   7cf9 <readsect>
		pa += SECTSIZE;
		offset++;
    7d75:	58                   	pop    %eax
    7d76:	5a                   	pop    %edx
	offset = (offset / SECTSIZE) + 1;

	// If this is too slow, we could read lots of sectors at a time.
	// We'd write more to memory than asked, but it doesn't matter --
	// we load in increasing order.
	while (pa < end_pa) {
    7d77:	39 fb                	cmp    %edi,%ebx
    7d79:	72 ec                	jb     7d67 <readseg+0x1d>
		readsect((uint8_t*) pa, offset);
		pa += SECTSIZE;
		offset++;
	}
}
    7d7b:	8d 65 f4             	lea    -0xc(%ebp),%esp
    7d7e:	5b                   	pop    %ebx
    7d7f:	5e                   	pop    %esi
    7d80:	5f                   	pop    %edi
    7d81:	5d                   	pop    %ebp
    7d82:	c3                   	ret    

00007d83 <bootmain>:
void readseg(uint32_t, uint32_t, uint32_t);


void
bootmain(void)
{
    7d83:	55                   	push   %ebp
    7d84:	89 e5                	mov    %esp,%ebp
    7d86:	56                   	push   %esi
    7d87:	53                   	push   %ebx
    /* __asm __volatile("movl %%ebx, %0": "=r" (multiboot_info)); */
	struct Proghdr *ph, *eph;

    extern char multiboot_info[];
	// read 1st 2 pages off disk
	readseg((uint32_t) ELFHDR, SECTSIZE*8, 0);
    7d88:	6a 00                	push   $0x0
    7d8a:	68 00 10 00 00       	push   $0x1000
    7d8f:	68 00 00 01 00       	push   $0x10000
    7d94:	e8 b1 ff ff ff       	call   7d4a <readseg>

	// is this a valid ELF?
	if (ELFHDR->e_magic != ELF_MAGIC)
    7d99:	83 c4 0c             	add    $0xc,%esp
    7d9c:	81 3d 00 00 01 00 7f 	cmpl   $0x464c457f,0x10000
    7da3:	45 4c 46 
    7da6:	75 3f                	jne    7de7 <bootmain+0x64>
		goto bad;

	// load each program segment (ignores ph flags)
	// test whether this has written to 0x100000
	ph = (struct Proghdr *) ((uint8_t *) ELFHDR + ELFHDR->e_phoff);
	eph = ph + ELFHDR->e_phnum;
    7da8:	0f b7 35 38 00 01 00 	movzwl 0x10038,%esi
	if (ELFHDR->e_magic != ELF_MAGIC)
		goto bad;

	// load each program segment (ignores ph flags)
	// test whether this has written to 0x100000
	ph = (struct Proghdr *) ((uint8_t *) ELFHDR + ELFHDR->e_phoff);
    7daf:	8b 1d 20 00 01 00    	mov    0x10020,%ebx
	eph = ph + ELFHDR->e_phnum;
    7db5:	6b f6 38             	imul   $0x38,%esi,%esi
	if (ELFHDR->e_magic != ELF_MAGIC)
		goto bad;

	// load each program segment (ignores ph flags)
	// test whether this has written to 0x100000
	ph = (struct Proghdr *) ((uint8_t *) ELFHDR + ELFHDR->e_phoff);
    7db8:	81 c3 00 00 01 00    	add    $0x10000,%ebx
	eph = ph + ELFHDR->e_phnum;
    7dbe:	01 de                	add    %ebx,%esi
	for (; ph < eph; ph++)
    7dc0:	eb 14                	jmp    7dd6 <bootmain+0x53>
		readseg(ph->p_pa, ph->p_memsz, ph->p_offset);
    7dc2:	ff 73 08             	pushl  0x8(%ebx)
    7dc5:	ff 73 28             	pushl  0x28(%ebx)
    7dc8:	ff 73 18             	pushl  0x18(%ebx)

	// load each program segment (ignores ph flags)
	// test whether this has written to 0x100000
	ph = (struct Proghdr *) ((uint8_t *) ELFHDR + ELFHDR->e_phoff);
	eph = ph + ELFHDR->e_phnum;
	for (; ph < eph; ph++)
    7dcb:	83 c3 38             	add    $0x38,%ebx
		readseg(ph->p_pa, ph->p_memsz, ph->p_offset);
    7dce:	e8 77 ff ff ff       	call   7d4a <readseg>

	// load each program segment (ignores ph flags)
	// test whether this has written to 0x100000
	ph = (struct Proghdr *) ((uint8_t *) ELFHDR + ELFHDR->e_phoff);
	eph = ph + ELFHDR->e_phnum;
	for (; ph < eph; ph++)
    7dd3:	83 c4 0c             	add    $0xc,%esp
    7dd6:	39 f3                	cmp    %esi,%ebx
    7dd8:	72 e8                	jb     7dc2 <bootmain+0x3f>
		readseg(ph->p_pa, ph->p_memsz, ph->p_offset);

	// call the entry point from the ELF header
	// note: does not return!

    __asm __volatile("movl %0, %%ebx": : "r" (multiboot_info));
    7dda:	b8 00 70 00 00       	mov    $0x7000,%eax
    7ddf:	89 c3                	mov    %eax,%ebx
	((void (*)(void)) ((uint32_t)(ELFHDR->e_entry)))();
    7de1:	ff 15 18 00 01 00    	call   *0x10018
}

static __inline void
outw(int port, uint16_t data)
{
	__asm __volatile("outw %0,%w1" : : "a" (data), "d" (port));
    7de7:	ba 00 8a 00 00       	mov    $0x8a00,%edx
    7dec:	b8 00 8a ff ff       	mov    $0xffff8a00,%eax
    7df1:	66 ef                	out    %ax,(%dx)
    7df3:	b8 00 8e ff ff       	mov    $0xffff8e00,%eax
    7df8:	66 ef                	out    %ax,(%dx)
    7dfa:	eb fe                	jmp    7dfa <bootmain+0x77>


obj/kern/kernel:     file format elf64-x86-64


Disassembly of section .bootstrap:

0000000000100000 <_head64>:
.text
.globl _head64
_head64:

# Save multiboot_info addr passed by bootloader
    movl $multiboot_info, %eax
  100000:	b8 00 70 10 00       	mov    $0x107000,%eax
    movl %ebx, (%eax)
  100005:	89 18                	mov    %ebx,(%rax)

	movw $0x1234,0x472			# warm boot
  100007:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472(%rip)        # 100482 <verify_cpu_no_longmode+0x36f>
  10000e:	34 12 
# Reset the stack pointer in case we didn't come from the loader
    movl $0x7c00,%esp
  100010:	bc 00 7c 00 00       	mov    $0x7c00,%esp

    call verify_cpu   #check if CPU supports long mode
  100015:	e8 cc 00 00 00       	callq  1000e6 <verify_cpu>
    movl $CR4_PAE,%eax
  10001a:	b8 20 00 00 00       	mov    $0x20,%eax
    movl %eax,%cr4
  10001f:	0f 22 e0             	mov    %rax,%cr4

# build an early boot pml4 at 0x8000

    #initializing the page tables
    movl $pml4,%edi
  100022:	bf 00 20 10 00       	mov    $0x102000,%edi
    xorl %eax,%eax
  100027:	31 c0                	xor    %eax,%eax
    movl $((4096/4)*5),%ecx  # moving these many words to the 6 pages with 4 second level pages + 1 3rd level + 1 4th level pages 
  100029:	b9 00 14 00 00       	mov    $0x1400,%ecx
    rep stosl
  10002e:	f3 ab                	rep stos %eax,%es:(%rdi)
    # creating a 4G boot page table
    # setting the 4th level page table only the second entry needed (PML4)
    movl $pml4,%eax
  100030:	b8 00 20 10 00       	mov    $0x102000,%eax
    movl $pdpt1, %ebx
  100035:	bb 00 30 10 00       	mov    $0x103000,%ebx
    orl $PTE_P,%ebx
  10003a:	83 cb 01             	or     $0x1,%ebx
    orl $PTE_W,%ebx
  10003d:	83 cb 02             	or     $0x2,%ebx
    movl %ebx,(%eax)
  100040:	89 18                	mov    %ebx,(%rax)

    movl $pdpt2, %ebx
  100042:	bb 00 40 10 00       	mov    $0x104000,%ebx
    orl $PTE_P,%ebx
  100047:	83 cb 01             	or     $0x1,%ebx
    orl $PTE_W,%ebx
  10004a:	83 cb 02             	or     $0x2,%ebx
    movl %ebx,0x8(%eax)
  10004d:	89 58 08             	mov    %ebx,0x8(%rax)

    # setting the 3rd level page table (PDPE)
    # 4 entries (counter in ecx), point to the next four physical pages (pgdirs)
    # pgdirs in 0xa0000--0xd000
    movl $pdpt1,%edi
  100050:	bf 00 30 10 00       	mov    $0x103000,%edi
    movl $pde1,%ebx
  100055:	bb 00 50 10 00       	mov    $0x105000,%ebx
    orl $PTE_P,%ebx
  10005a:	83 cb 01             	or     $0x1,%ebx
    orl $PTE_W,%ebx
  10005d:	83 cb 02             	or     $0x2,%ebx
    movl %ebx,(%edi)
  100060:	89 1f                	mov    %ebx,(%rdi)

    movl $pdpt2,%edi
  100062:	bf 00 40 10 00       	mov    $0x104000,%edi
    movl $pde2,%ebx
  100067:	bb 00 60 10 00       	mov    $0x106000,%ebx
    orl $PTE_P,%ebx
  10006c:	83 cb 01             	or     $0x1,%ebx
    orl $PTE_W,%ebx
  10006f:	83 cb 02             	or     $0x2,%ebx
    movl %ebx,(%edi)
  100072:	89 1f                	mov    %ebx,(%rdi)
    
    # setting the pgdir so that the LA=PA
    # mapping first 1G of mem at KERNBASE
    movl $128,%ecx
  100074:	b9 80 00 00 00       	mov    $0x80,%ecx
    # Start at the end and work backwards
    #leal (pml4 + 5*0x1000 - 0x8),%edi
    movl $pde1,%edi
  100079:	bf 00 50 10 00       	mov    $0x105000,%edi
    movl $pde2,%ebx
  10007e:	bb 00 60 10 00       	mov    $0x106000,%ebx
    #64th entry - 0x8004000000
    addl $256,%ebx 
  100083:	81 c3 00 01 00 00    	add    $0x100,%ebx
    # PTE_P|PTE_W|PTE_MBZ
    movl $0x00000183,%eax
  100089:	b8 83 01 00 00       	mov    $0x183,%eax
  1:
     movl %eax,(%edi)
  10008e:	89 07                	mov    %eax,(%rdi)
     movl %eax,(%ebx)
  100090:	89 03                	mov    %eax,(%rbx)
     addl $0x8,%edi
  100092:	83 c7 08             	add    $0x8,%edi
     addl $0x8,%ebx
  100095:	83 c3 08             	add    $0x8,%ebx
     addl $0x00200000,%eax
  100098:	05 00 00 20 00       	add    $0x200000,%eax
     subl $1,%ecx
  10009d:	83 e9 01             	sub    $0x1,%ecx
     cmp $0x0,%ecx
  1000a0:	83 f9 00             	cmp    $0x0,%ecx
     jne 1b
  1000a3:	75 e9                	jne    10008e <_head64+0x8e>
 /*    subl $1,%ecx */
 /*    cmp $0x0,%ecx */
 /*    jne 1b */

    # set the cr3 register
    movl $pml4,%eax
  1000a5:	b8 00 20 10 00       	mov    $0x102000,%eax
    movl %eax, %cr3
  1000aa:	0f 22 d8             	mov    %rax,%cr3

	
    # enable the long mode in MSR
    movl $EFER_MSR,%ecx
  1000ad:	b9 80 00 00 c0       	mov    $0xc0000080,%ecx
    rdmsr
  1000b2:	0f 32                	rdmsr  
    btsl $EFER_LME,%eax
  1000b4:	0f ba e8 08          	bts    $0x8,%eax
    wrmsr
  1000b8:	0f 30                	wrmsr  
    
    # enable paging 
    movl %cr0,%eax
  1000ba:	0f 20 c0             	mov    %cr0,%rax
    orl $CR0_PE,%eax
  1000bd:	83 c8 01             	or     $0x1,%eax
    orl $CR0_PG,%eax
  1000c0:	0d 00 00 00 80       	or     $0x80000000,%eax
    orl $CR0_AM,%eax
  1000c5:	0d 00 00 04 00       	or     $0x40000,%eax
    orl $CR0_WP,%eax
  1000ca:	0d 00 00 01 00       	or     $0x10000,%eax
    orl $CR0_MP,%eax
  1000cf:	83 c8 02             	or     $0x2,%eax
    movl %eax,%cr0
  1000d2:	0f 22 c0             	mov    %rax,%cr0
    #jump to long mode with CS=0 and

    movl $gdtdesc_64,%eax
  1000d5:	b8 18 10 10 00       	mov    $0x101018,%eax
    lgdt (%eax)
  1000da:	0f 01 10             	lgdt   (%rax)
    pushl $0x8
  1000dd:	6a 08                	pushq  $0x8
    movl $_start,%eax
  1000df:	b8 0c 00 20 00       	mov    $0x20000c,%eax
    pushl %eax
  1000e4:	50                   	push   %rax

00000000001000e5 <jumpto_longmode>:
    
    .globl jumpto_longmode
    .type jumpto_longmode,@function
jumpto_longmode:
    lret
  1000e5:	cb                   	lret   

00000000001000e6 <verify_cpu>:
/*     movabs $_back_from_head64, %rax */
/*     pushq %rax */
/*     lretq */

verify_cpu:
    pushfl                   # get eflags in eax -- standardard way to check for cpuid
  1000e6:	9c                   	pushfq 
    popl %eax
  1000e7:	58                   	pop    %rax
    movl %eax,%ecx
  1000e8:	89 c1                	mov    %eax,%ecx
    xorl $0x200000, %eax
  1000ea:	35 00 00 20 00       	xor    $0x200000,%eax
    pushl %eax
  1000ef:	50                   	push   %rax
    popfl
  1000f0:	9d                   	popfq  
    pushfl
  1000f1:	9c                   	pushfq 
    popl %eax
  1000f2:	58                   	pop    %rax
    cmpl %eax,%ebx
  1000f3:	39 c3                	cmp    %eax,%ebx
    jz verify_cpu_no_longmode   # no cpuid -- no long mode
  1000f5:	74 1c                	je     100113 <verify_cpu_no_longmode>

    movl $0x0,%eax              # see if cpuid 1 is implemented
  1000f7:	b8 00 00 00 00       	mov    $0x0,%eax
    cpuid
  1000fc:	0f a2                	cpuid  
    cmpl $0x1,%eax
  1000fe:	83 f8 01             	cmp    $0x1,%eax
    jb verify_cpu_no_longmode    # cpuid 1 is not implemented
  100101:	72 10                	jb     100113 <verify_cpu_no_longmode>


    mov $0x80000001, %eax
  100103:	b8 01 00 00 80       	mov    $0x80000001,%eax
    cpuid                 
  100108:	0f a2                	cpuid  
    test $(1 << 29),%edx                 #Test if the LM-bit, is set or not.
  10010a:	f7 c2 00 00 00 20    	test   $0x20000000,%edx
    jz verify_cpu_no_longmode
  100110:	74 01                	je     100113 <verify_cpu_no_longmode>

    ret
  100112:	c3                   	retq   

0000000000100113 <verify_cpu_no_longmode>:

verify_cpu_no_longmode:
    jmp verify_cpu_no_longmode
  100113:	eb fe                	jmp    100113 <verify_cpu_no_longmode>
	...

0000000000101000 <gdt_64>:
	...
  101008:	ff                   	(bad)  
  101009:	ff 00                	incl   (%rax)
  10100b:	00 00                	add    %al,(%rax)
  10100d:	9a                   	(bad)  
  10100e:	af                   	scas   %es:(%rdi),%eax
  10100f:	00 ff                	add    %bh,%bh
  101011:	ff 00                	incl   (%rax)
  101013:	00 00                	add    %al,(%rax)
  101015:	92                   	xchg   %eax,%edx
  101016:	cf                   	iret   
	...

0000000000101018 <gdtdesc_64>:
  101018:	17                   	(bad)  
  101019:	00 00                	add    %al,(%rax)
  10101b:	10 10                	adc    %dl,(%rax)
	...

0000000000102000 <pml4virt>:
	...

0000000000103000 <pdpt1>:
	...

0000000000104000 <pdpt2>:
	...

0000000000105000 <pde1>:
	...

0000000000106000 <pde2>:
	...

0000000000107000 <multiboot_info>:
  107000:	00 00                	add    %al,(%rax)
	...

Disassembly of section .text:

0000008004200000 <_start+0x8003fffff4>:
  8004200000:	02 b0 ad 1b 00 00    	add    0x1bad(%rax),%dh
  8004200006:	00 00                	add    %al,(%rax)
  8004200008:	fe 4f 52             	decb   0x52(%rdi)
  800420000b:	e4 48                	in     $0x48,%al

000000800420000c <entry>:
entry:

/* .globl _back_from_head64 */
/* _back_from_head64: */

    movabs   $gdtdesc_64,%rax
  800420000c:	48 b8 38 b0 21 04 80 	movabs $0x800421b038,%rax
  8004200013:	00 00 00 
    lgdt     (%rax)
  8004200016:	0f 01 10             	lgdt   (%rax)
    movw    $DATA_SEL,%ax
  8004200019:	66 b8 10 00          	mov    $0x10,%ax
    movw    %ax,%ds
  800420001d:	8e d8                	mov    %eax,%ds
    movw    %ax,%ss
  800420001f:	8e d0                	mov    %eax,%ss
    movw    %ax,%fs
  8004200021:	8e e0                	mov    %eax,%fs
    movw    %ax,%gs
  8004200023:	8e e8                	mov    %eax,%gs
    movw    %ax,%es
  8004200025:	8e c0                	mov    %eax,%es
    pushq   $CODE_SEL
  8004200027:	6a 08                	pushq  $0x8
    movabs  $relocated,%rax
  8004200029:	48 b8 36 00 20 04 80 	movabs $0x8004200036,%rax
  8004200030:	00 00 00 
    pushq   %rax
  8004200033:	50                   	push   %rax
    lretq
  8004200034:	48 cb                	lretq  

0000008004200036 <relocated>:
relocated:

	# Clear the frame pointer register (RBP)
	# so that once we get into debugging C code,
	# stack backtraces will be terminated properly.
	movq	$0x0,%rbp			# nuke frame pointer
  8004200036:	48 c7 c5 00 00 00 00 	mov    $0x0,%rbp

	# Set the stack pointer
	movabs	$(bootstacktop),%rax
  800420003d:	48 b8 00 b0 21 04 80 	movabs $0x800421b000,%rax
  8004200044:	00 00 00 
	movq  %rax,%rsp
  8004200047:	48 89 c4             	mov    %rax,%rsp

	# now to C code
    movabs $i386_init, %rax
  800420004a:	48 b8 dc 00 20 04 80 	movabs $0x80042000dc,%rax
  8004200051:	00 00 00 
	call *%rax
  8004200054:	ff d0                	callq  *%rax

0000008004200056 <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
  8004200056:	eb fe                	jmp    8004200056 <spin>

0000008004200058 <test_backtrace>:


// Test the stack backtrace function (lab 1 only)
void
test_backtrace(int x)
{
  8004200058:	55                   	push   %rbp
  8004200059:	48 89 e5             	mov    %rsp,%rbp
  800420005c:	48 83 ec 10          	sub    $0x10,%rsp
  8004200060:	89 7d fc             	mov    %edi,-0x4(%rbp)
	cprintf("entering test_backtrace %d\n", x);
  8004200063:	8b 45 fc             	mov    -0x4(%rbp),%eax
  8004200066:	89 c6                	mov    %eax,%esi
  8004200068:	48 bf 00 93 20 04 80 	movabs $0x8004209300,%rdi
  800420006f:	00 00 00 
  8004200072:	b8 00 00 00 00       	mov    $0x0,%eax
  8004200077:	48 ba 22 16 20 04 80 	movabs $0x8004201622,%rdx
  800420007e:	00 00 00 
  8004200081:	ff d2                	callq  *%rdx
	if (x > 0)
  8004200083:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  8004200087:	7e 16                	jle    800420009f <test_backtrace+0x47>
		test_backtrace(x-1);
  8004200089:	8b 45 fc             	mov    -0x4(%rbp),%eax
  800420008c:	83 e8 01             	sub    $0x1,%eax
  800420008f:	89 c7                	mov    %eax,%edi
  8004200091:	48 b8 58 00 20 04 80 	movabs $0x8004200058,%rax
  8004200098:	00 00 00 
  800420009b:	ff d0                	callq  *%rax
  800420009d:	eb 1b                	jmp    80042000ba <test_backtrace+0x62>
	else
		mon_backtrace(0, 0, 0);
  800420009f:	ba 00 00 00 00       	mov    $0x0,%edx
  80042000a4:	be 00 00 00 00       	mov    $0x0,%esi
  80042000a9:	bf 00 00 00 00       	mov    $0x0,%edi
  80042000ae:	48 b8 64 11 20 04 80 	movabs $0x8004201164,%rax
  80042000b5:	00 00 00 
  80042000b8:	ff d0                	callq  *%rax
	cprintf("leaving test_backtrace %d\n", x);
  80042000ba:	8b 45 fc             	mov    -0x4(%rbp),%eax
  80042000bd:	89 c6                	mov    %eax,%esi
  80042000bf:	48 bf 1c 93 20 04 80 	movabs $0x800420931c,%rdi
  80042000c6:	00 00 00 
  80042000c9:	b8 00 00 00 00       	mov    $0x0,%eax
  80042000ce:	48 ba 22 16 20 04 80 	movabs $0x8004201622,%rdx
  80042000d5:	00 00 00 
  80042000d8:	ff d2                	callq  *%rdx
}
  80042000da:	c9                   	leaveq 
  80042000db:	c3                   	retq   

00000080042000dc <i386_init>:

void
i386_init(void)
{
  80042000dc:	55                   	push   %rbp
  80042000dd:	48 89 e5             	mov    %rsp,%rbp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
  80042000e0:	48 ba 60 cc 21 04 80 	movabs $0x800421cc60,%rdx
  80042000e7:	00 00 00 
  80042000ea:	48 b8 c0 b6 21 04 80 	movabs $0x800421b6c0,%rax
  80042000f1:	00 00 00 
  80042000f4:	48 89 d1             	mov    %rdx,%rcx
  80042000f7:	48 29 c1             	sub    %rax,%rcx
  80042000fa:	48 89 c8             	mov    %rcx,%rax
  80042000fd:	48 89 c2             	mov    %rax,%rdx
  8004200100:	be 00 00 00 00       	mov    $0x0,%esi
  8004200105:	48 bf c0 b6 21 04 80 	movabs $0x800421b6c0,%rdi
  800420010c:	00 00 00 
  800420010f:	48 b8 5b 2e 20 04 80 	movabs $0x8004202e5b,%rax
  8004200116:	00 00 00 
  8004200119:	ff d0                	callq  *%rax

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
  800420011b:	48 b8 8e 0e 20 04 80 	movabs $0x8004200e8e,%rax
  8004200122:	00 00 00 
  8004200125:	ff d0                	callq  *%rax

	cprintf("6828 decimal is %o octal!\n", 6828);
  8004200127:	be ac 1a 00 00       	mov    $0x1aac,%esi
  800420012c:	48 bf 37 93 20 04 80 	movabs $0x8004209337,%rdi
  8004200133:	00 00 00 
  8004200136:	b8 00 00 00 00       	mov    $0x0,%eax
  800420013b:	48 ba 22 16 20 04 80 	movabs $0x8004201622,%rdx
  8004200142:	00 00 00 
  8004200145:	ff d2                	callq  *%rdx

    extern char end[];
    end_debug = read_section_headers((0x10000+KERNBASE), (uintptr_t)end); 
  8004200147:	48 b8 60 cc 21 04 80 	movabs $0x800421cc60,%rax
  800420014e:	00 00 00 
  8004200151:	48 89 c6             	mov    %rax,%rsi
  8004200154:	48 bf 00 00 01 04 80 	movabs $0x8004010000,%rdi
  800420015b:	00 00 00 
  800420015e:	48 b8 1f 89 20 04 80 	movabs $0x800420891f,%rax
  8004200165:	00 00 00 
  8004200168:	ff d0                	callq  *%rax
  800420016a:	48 ba 68 bd 21 04 80 	movabs $0x800421bd68,%rdx
  8004200171:	00 00 00 
  8004200174:	48 89 02             	mov    %rax,(%rdx)


	// Test the stack backtrace function (lab 1 only)
	test_backtrace(5);
  8004200177:	bf 05 00 00 00       	mov    $0x5,%edi
  800420017c:	48 b8 58 00 20 04 80 	movabs $0x8004200058,%rax
  8004200183:	00 00 00 
  8004200186:	ff d0                	callq  *%rax

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
  8004200188:	bf 00 00 00 00       	mov    $0x0,%edi
  800420018d:	48 b8 14 15 20 04 80 	movabs $0x8004201514,%rax
  8004200194:	00 00 00 
  8004200197:	ff d0                	callq  *%rax
  8004200199:	eb ed                	jmp    8004200188 <i386_init+0xac>

000000800420019b <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
  800420019b:	55                   	push   %rbp
  800420019c:	48 89 e5             	mov    %rsp,%rbp
  800420019f:	48 81 ec f0 00 00 00 	sub    $0xf0,%rsp
  80042001a6:	48 89 bd 28 ff ff ff 	mov    %rdi,-0xd8(%rbp)
  80042001ad:	89 b5 24 ff ff ff    	mov    %esi,-0xdc(%rbp)
  80042001b3:	48 89 8d 68 ff ff ff 	mov    %rcx,-0x98(%rbp)
  80042001ba:	4c 89 85 70 ff ff ff 	mov    %r8,-0x90(%rbp)
  80042001c1:	4c 89 8d 78 ff ff ff 	mov    %r9,-0x88(%rbp)
  80042001c8:	84 c0                	test   %al,%al
  80042001ca:	74 20                	je     80042001ec <_panic+0x51>
  80042001cc:	0f 29 45 80          	movaps %xmm0,-0x80(%rbp)
  80042001d0:	0f 29 4d 90          	movaps %xmm1,-0x70(%rbp)
  80042001d4:	0f 29 55 a0          	movaps %xmm2,-0x60(%rbp)
  80042001d8:	0f 29 5d b0          	movaps %xmm3,-0x50(%rbp)
  80042001dc:	0f 29 65 c0          	movaps %xmm4,-0x40(%rbp)
  80042001e0:	0f 29 6d d0          	movaps %xmm5,-0x30(%rbp)
  80042001e4:	0f 29 75 e0          	movaps %xmm6,-0x20(%rbp)
  80042001e8:	0f 29 7d f0          	movaps %xmm7,-0x10(%rbp)
  80042001ec:	48 89 95 18 ff ff ff 	mov    %rdx,-0xe8(%rbp)
	va_list ap;

	if (panicstr)
  80042001f3:	48 b8 70 bd 21 04 80 	movabs $0x800421bd70,%rax
  80042001fa:	00 00 00 
  80042001fd:	48 8b 00             	mov    (%rax),%rax
  8004200200:	48 85 c0             	test   %rax,%rax
  8004200203:	0f 85 ab 00 00 00    	jne    80042002b4 <_panic+0x119>
		goto dead;
	panicstr = fmt;
  8004200209:	48 b8 70 bd 21 04 80 	movabs $0x800421bd70,%rax
  8004200210:	00 00 00 
  8004200213:	48 8b 95 18 ff ff ff 	mov    -0xe8(%rbp),%rdx
  800420021a:	48 89 10             	mov    %rdx,(%rax)

	// Be extra sure that the machine is in as reasonable state
	__asm __volatile("cli; cld");
  800420021d:	fa                   	cli    
  800420021e:	fc                   	cld    

	va_start(ap, fmt);
  800420021f:	c7 85 38 ff ff ff 18 	movl   $0x18,-0xc8(%rbp)
  8004200226:	00 00 00 
  8004200229:	c7 85 3c ff ff ff 30 	movl   $0x30,-0xc4(%rbp)
  8004200230:	00 00 00 
  8004200233:	48 8d 45 10          	lea    0x10(%rbp),%rax
  8004200237:	48 89 85 40 ff ff ff 	mov    %rax,-0xc0(%rbp)
  800420023e:	48 8d 85 50 ff ff ff 	lea    -0xb0(%rbp),%rax
  8004200245:	48 89 85 48 ff ff ff 	mov    %rax,-0xb8(%rbp)
	cprintf("kernel panic at %s:%d: ", file, line);
  800420024c:	8b 95 24 ff ff ff    	mov    -0xdc(%rbp),%edx
  8004200252:	48 8b 85 28 ff ff ff 	mov    -0xd8(%rbp),%rax
  8004200259:	48 89 c6             	mov    %rax,%rsi
  800420025c:	48 bf 52 93 20 04 80 	movabs $0x8004209352,%rdi
  8004200263:	00 00 00 
  8004200266:	b8 00 00 00 00       	mov    $0x0,%eax
  800420026b:	48 b9 22 16 20 04 80 	movabs $0x8004201622,%rcx
  8004200272:	00 00 00 
  8004200275:	ff d1                	callq  *%rcx
	vcprintf(fmt, ap);
  8004200277:	48 8d 95 38 ff ff ff 	lea    -0xc8(%rbp),%rdx
  800420027e:	48 8b 85 18 ff ff ff 	mov    -0xe8(%rbp),%rax
  8004200285:	48 89 d6             	mov    %rdx,%rsi
  8004200288:	48 89 c7             	mov    %rax,%rdi
  800420028b:	48 b8 c3 15 20 04 80 	movabs $0x80042015c3,%rax
  8004200292:	00 00 00 
  8004200295:	ff d0                	callq  *%rax
	cprintf("\n");
  8004200297:	48 bf 6a 93 20 04 80 	movabs $0x800420936a,%rdi
  800420029e:	00 00 00 
  80042002a1:	b8 00 00 00 00       	mov    $0x0,%eax
  80042002a6:	48 ba 22 16 20 04 80 	movabs $0x8004201622,%rdx
  80042002ad:	00 00 00 
  80042002b0:	ff d2                	callq  *%rdx
  80042002b2:	eb 01                	jmp    80042002b5 <_panic+0x11a>
_panic(const char *file, int line, const char *fmt,...)
{
	va_list ap;

	if (panicstr)
		goto dead;
  80042002b4:	90                   	nop
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
  80042002b5:	bf 00 00 00 00       	mov    $0x0,%edi
  80042002ba:	48 b8 14 15 20 04 80 	movabs $0x8004201514,%rax
  80042002c1:	00 00 00 
  80042002c4:	ff d0                	callq  *%rax
  80042002c6:	eb ed                	jmp    80042002b5 <_panic+0x11a>

00000080042002c8 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
  80042002c8:	55                   	push   %rbp
  80042002c9:	48 89 e5             	mov    %rsp,%rbp
  80042002cc:	48 81 ec f0 00 00 00 	sub    $0xf0,%rsp
  80042002d3:	48 89 bd 28 ff ff ff 	mov    %rdi,-0xd8(%rbp)
  80042002da:	89 b5 24 ff ff ff    	mov    %esi,-0xdc(%rbp)
  80042002e0:	48 89 8d 68 ff ff ff 	mov    %rcx,-0x98(%rbp)
  80042002e7:	4c 89 85 70 ff ff ff 	mov    %r8,-0x90(%rbp)
  80042002ee:	4c 89 8d 78 ff ff ff 	mov    %r9,-0x88(%rbp)
  80042002f5:	84 c0                	test   %al,%al
  80042002f7:	74 20                	je     8004200319 <_warn+0x51>
  80042002f9:	0f 29 45 80          	movaps %xmm0,-0x80(%rbp)
  80042002fd:	0f 29 4d 90          	movaps %xmm1,-0x70(%rbp)
  8004200301:	0f 29 55 a0          	movaps %xmm2,-0x60(%rbp)
  8004200305:	0f 29 5d b0          	movaps %xmm3,-0x50(%rbp)
  8004200309:	0f 29 65 c0          	movaps %xmm4,-0x40(%rbp)
  800420030d:	0f 29 6d d0          	movaps %xmm5,-0x30(%rbp)
  8004200311:	0f 29 75 e0          	movaps %xmm6,-0x20(%rbp)
  8004200315:	0f 29 7d f0          	movaps %xmm7,-0x10(%rbp)
  8004200319:	48 89 95 18 ff ff ff 	mov    %rdx,-0xe8(%rbp)
	va_list ap;

	va_start(ap, fmt);
  8004200320:	c7 85 38 ff ff ff 18 	movl   $0x18,-0xc8(%rbp)
  8004200327:	00 00 00 
  800420032a:	c7 85 3c ff ff ff 30 	movl   $0x30,-0xc4(%rbp)
  8004200331:	00 00 00 
  8004200334:	48 8d 45 10          	lea    0x10(%rbp),%rax
  8004200338:	48 89 85 40 ff ff ff 	mov    %rax,-0xc0(%rbp)
  800420033f:	48 8d 85 50 ff ff ff 	lea    -0xb0(%rbp),%rax
  8004200346:	48 89 85 48 ff ff ff 	mov    %rax,-0xb8(%rbp)
	cprintf("kernel warning at %s:%d: ", file, line);
  800420034d:	8b 95 24 ff ff ff    	mov    -0xdc(%rbp),%edx
  8004200353:	48 8b 85 28 ff ff ff 	mov    -0xd8(%rbp),%rax
  800420035a:	48 89 c6             	mov    %rax,%rsi
  800420035d:	48 bf 6c 93 20 04 80 	movabs $0x800420936c,%rdi
  8004200364:	00 00 00 
  8004200367:	b8 00 00 00 00       	mov    $0x0,%eax
  800420036c:	48 b9 22 16 20 04 80 	movabs $0x8004201622,%rcx
  8004200373:	00 00 00 
  8004200376:	ff d1                	callq  *%rcx
	vcprintf(fmt, ap);
  8004200378:	48 8d 95 38 ff ff ff 	lea    -0xc8(%rbp),%rdx
  800420037f:	48 8b 85 18 ff ff ff 	mov    -0xe8(%rbp),%rax
  8004200386:	48 89 d6             	mov    %rdx,%rsi
  8004200389:	48 89 c7             	mov    %rax,%rdi
  800420038c:	48 b8 c3 15 20 04 80 	movabs $0x80042015c3,%rax
  8004200393:	00 00 00 
  8004200396:	ff d0                	callq  *%rax
	cprintf("\n");
  8004200398:	48 bf 6a 93 20 04 80 	movabs $0x800420936a,%rdi
  800420039f:	00 00 00 
  80042003a2:	b8 00 00 00 00       	mov    $0x0,%eax
  80042003a7:	48 ba 22 16 20 04 80 	movabs $0x8004201622,%rdx
  80042003ae:	00 00 00 
  80042003b1:	ff d2                	callq  *%rdx
	va_end(ap);
}
  80042003b3:	c9                   	leaveq 
  80042003b4:	c3                   	retq   
  80042003b5:	00 00                	add    %al,(%rax)
	...

00000080042003b8 <delay>:
static void cons_putc(int c);

// Stupid I/O delay routine necessitated by historical PC design flaws
static void
delay(void)
{
  80042003b8:	55                   	push   %rbp
  80042003b9:	48 89 e5             	mov    %rsp,%rbp
  80042003bc:	53                   	push   %rbx
  80042003bd:	48 83 ec 28          	sub    $0x28,%rsp
  80042003c1:	c7 45 f4 84 00 00 00 	movl   $0x84,-0xc(%rbp)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  80042003c8:	8b 55 f4             	mov    -0xc(%rbp),%edx
  80042003cb:	89 55 d4             	mov    %edx,-0x2c(%rbp)
  80042003ce:	8b 55 d4             	mov    -0x2c(%rbp),%edx
  80042003d1:	ec                   	in     (%dx),%al
  80042003d2:	89 c3                	mov    %eax,%ebx
  80042003d4:	88 5d f3             	mov    %bl,-0xd(%rbp)
	return data;
  80042003d7:	c7 45 ec 84 00 00 00 	movl   $0x84,-0x14(%rbp)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  80042003de:	8b 55 ec             	mov    -0x14(%rbp),%edx
  80042003e1:	89 55 d4             	mov    %edx,-0x2c(%rbp)
  80042003e4:	8b 55 d4             	mov    -0x2c(%rbp),%edx
  80042003e7:	ec                   	in     (%dx),%al
  80042003e8:	89 c3                	mov    %eax,%ebx
  80042003ea:	88 5d eb             	mov    %bl,-0x15(%rbp)
	return data;
  80042003ed:	c7 45 e4 84 00 00 00 	movl   $0x84,-0x1c(%rbp)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  80042003f4:	8b 55 e4             	mov    -0x1c(%rbp),%edx
  80042003f7:	89 55 d4             	mov    %edx,-0x2c(%rbp)
  80042003fa:	8b 55 d4             	mov    -0x2c(%rbp),%edx
  80042003fd:	ec                   	in     (%dx),%al
  80042003fe:	89 c3                	mov    %eax,%ebx
  8004200400:	88 5d e3             	mov    %bl,-0x1d(%rbp)
	return data;
  8004200403:	c7 45 dc 84 00 00 00 	movl   $0x84,-0x24(%rbp)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  800420040a:	8b 55 dc             	mov    -0x24(%rbp),%edx
  800420040d:	89 55 d4             	mov    %edx,-0x2c(%rbp)
  8004200410:	8b 55 d4             	mov    -0x2c(%rbp),%edx
  8004200413:	ec                   	in     (%dx),%al
  8004200414:	89 c3                	mov    %eax,%ebx
  8004200416:	88 5d db             	mov    %bl,-0x25(%rbp)
	inb(0x84);
	inb(0x84);
	inb(0x84);
	inb(0x84);
}
  8004200419:	48 83 c4 28          	add    $0x28,%rsp
  800420041d:	5b                   	pop    %rbx
  800420041e:	5d                   	pop    %rbp
  800420041f:	c3                   	retq   

0000008004200420 <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
  8004200420:	55                   	push   %rbp
  8004200421:	48 89 e5             	mov    %rsp,%rbp
  8004200424:	53                   	push   %rbx
  8004200425:	48 83 ec 18          	sub    $0x18,%rsp
  8004200429:	c7 45 f4 fd 03 00 00 	movl   $0x3fd,-0xc(%rbp)
  8004200430:	8b 55 f4             	mov    -0xc(%rbp),%edx
  8004200433:	89 55 e4             	mov    %edx,-0x1c(%rbp)
  8004200436:	8b 55 e4             	mov    -0x1c(%rbp),%edx
  8004200439:	ec                   	in     (%dx),%al
  800420043a:	89 c3                	mov    %eax,%ebx
  800420043c:	88 5d f3             	mov    %bl,-0xd(%rbp)
	return data;
  800420043f:	0f b6 45 f3          	movzbl -0xd(%rbp),%eax
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
  8004200443:	0f b6 c0             	movzbl %al,%eax
  8004200446:	83 e0 01             	and    $0x1,%eax
  8004200449:	85 c0                	test   %eax,%eax
  800420044b:	75 07                	jne    8004200454 <serial_proc_data+0x34>
		return -1;
  800420044d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  8004200452:	eb 1d                	jmp    8004200471 <serial_proc_data+0x51>
  8004200454:	c7 45 ec f8 03 00 00 	movl   $0x3f8,-0x14(%rbp)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  800420045b:	8b 55 ec             	mov    -0x14(%rbp),%edx
  800420045e:	89 55 e4             	mov    %edx,-0x1c(%rbp)
  8004200461:	8b 55 e4             	mov    -0x1c(%rbp),%edx
  8004200464:	ec                   	in     (%dx),%al
  8004200465:	89 c3                	mov    %eax,%ebx
  8004200467:	88 5d eb             	mov    %bl,-0x15(%rbp)
	return data;
  800420046a:	0f b6 45 eb          	movzbl -0x15(%rbp),%eax
	return inb(COM1+COM_RX);
  800420046e:	0f b6 c0             	movzbl %al,%eax
}
  8004200471:	48 83 c4 18          	add    $0x18,%rsp
  8004200475:	5b                   	pop    %rbx
  8004200476:	5d                   	pop    %rbp
  8004200477:	c3                   	retq   

0000008004200478 <serial_intr>:

void
serial_intr(void)
{
  8004200478:	55                   	push   %rbp
  8004200479:	48 89 e5             	mov    %rsp,%rbp
	if (serial_exists)
  800420047c:	48 b8 c0 b6 21 04 80 	movabs $0x800421b6c0,%rax
  8004200483:	00 00 00 
  8004200486:	0f b6 00             	movzbl (%rax),%eax
  8004200489:	84 c0                	test   %al,%al
  800420048b:	74 16                	je     80042004a3 <serial_intr+0x2b>
		cons_intr(serial_proc_data);
  800420048d:	48 bf 20 04 20 04 80 	movabs $0x8004200420,%rdi
  8004200494:	00 00 00 
  8004200497:	48 b8 0f 0d 20 04 80 	movabs $0x8004200d0f,%rax
  800420049e:	00 00 00 
  80042004a1:	ff d0                	callq  *%rax
}
  80042004a3:	5d                   	pop    %rbp
  80042004a4:	c3                   	retq   

00000080042004a5 <serial_putc>:

static void
serial_putc(int c)
{
  80042004a5:	55                   	push   %rbp
  80042004a6:	48 89 e5             	mov    %rsp,%rbp
  80042004a9:	53                   	push   %rbx
  80042004aa:	48 83 ec 28          	sub    $0x28,%rsp
  80042004ae:	89 7d d4             	mov    %edi,-0x2c(%rbp)
	int i;

	for (i = 0;
  80042004b1:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%rbp)
  80042004b8:	eb 10                	jmp    80042004ca <serial_putc+0x25>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
		delay();
  80042004ba:	48 b8 b8 03 20 04 80 	movabs $0x80042003b8,%rax
  80042004c1:	00 00 00 
  80042004c4:	ff d0                	callq  *%rax
{
	int i;

	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
  80042004c6:	83 45 f4 01          	addl   $0x1,-0xc(%rbp)
  80042004ca:	c7 45 f0 fd 03 00 00 	movl   $0x3fd,-0x10(%rbp)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  80042004d1:	8b 55 f0             	mov    -0x10(%rbp),%edx
  80042004d4:	89 55 d0             	mov    %edx,-0x30(%rbp)
  80042004d7:	8b 55 d0             	mov    -0x30(%rbp),%edx
  80042004da:	ec                   	in     (%dx),%al
  80042004db:	89 c3                	mov    %eax,%ebx
  80042004dd:	88 5d ef             	mov    %bl,-0x11(%rbp)
	return data;
  80042004e0:	0f b6 45 ef          	movzbl -0x11(%rbp),%eax
serial_putc(int c)
{
	int i;

	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
  80042004e4:	0f b6 c0             	movzbl %al,%eax
  80042004e7:	83 e0 20             	and    $0x20,%eax
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
  80042004ea:	85 c0                	test   %eax,%eax
  80042004ec:	75 09                	jne    80042004f7 <serial_putc+0x52>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
  80042004ee:	81 7d f4 ff 31 00 00 	cmpl   $0x31ff,-0xc(%rbp)
  80042004f5:	7e c3                	jle    80042004ba <serial_putc+0x15>
	     i++)
		delay();

	outb(COM1 + COM_TX, c);
  80042004f7:	8b 45 d4             	mov    -0x2c(%rbp),%eax
  80042004fa:	0f b6 c0             	movzbl %al,%eax
  80042004fd:	c7 45 e8 f8 03 00 00 	movl   $0x3f8,-0x18(%rbp)
  8004200504:	88 45 e7             	mov    %al,-0x19(%rbp)
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  8004200507:	0f b6 45 e7          	movzbl -0x19(%rbp),%eax
  800420050b:	8b 55 e8             	mov    -0x18(%rbp),%edx
  800420050e:	ee                   	out    %al,(%dx)
}
  800420050f:	48 83 c4 28          	add    $0x28,%rsp
  8004200513:	5b                   	pop    %rbx
  8004200514:	5d                   	pop    %rbp
  8004200515:	c3                   	retq   

0000008004200516 <serial_init>:

static void
serial_init(void)
{
  8004200516:	55                   	push   %rbp
  8004200517:	48 89 e5             	mov    %rsp,%rbp
  800420051a:	53                   	push   %rbx
  800420051b:	48 83 ec 58          	sub    $0x58,%rsp
  800420051f:	c7 45 f4 fa 03 00 00 	movl   $0x3fa,-0xc(%rbp)
  8004200526:	c6 45 f3 00          	movb   $0x0,-0xd(%rbp)
  800420052a:	0f b6 45 f3          	movzbl -0xd(%rbp),%eax
  800420052e:	8b 55 f4             	mov    -0xc(%rbp),%edx
  8004200531:	ee                   	out    %al,(%dx)
  8004200532:	c7 45 ec fb 03 00 00 	movl   $0x3fb,-0x14(%rbp)
  8004200539:	c6 45 eb 80          	movb   $0x80,-0x15(%rbp)
  800420053d:	0f b6 45 eb          	movzbl -0x15(%rbp),%eax
  8004200541:	8b 55 ec             	mov    -0x14(%rbp),%edx
  8004200544:	ee                   	out    %al,(%dx)
  8004200545:	c7 45 e4 f8 03 00 00 	movl   $0x3f8,-0x1c(%rbp)
  800420054c:	c6 45 e3 0c          	movb   $0xc,-0x1d(%rbp)
  8004200550:	0f b6 45 e3          	movzbl -0x1d(%rbp),%eax
  8004200554:	8b 55 e4             	mov    -0x1c(%rbp),%edx
  8004200557:	ee                   	out    %al,(%dx)
  8004200558:	c7 45 dc f9 03 00 00 	movl   $0x3f9,-0x24(%rbp)
  800420055f:	c6 45 db 00          	movb   $0x0,-0x25(%rbp)
  8004200563:	0f b6 45 db          	movzbl -0x25(%rbp),%eax
  8004200567:	8b 55 dc             	mov    -0x24(%rbp),%edx
  800420056a:	ee                   	out    %al,(%dx)
  800420056b:	c7 45 d4 fb 03 00 00 	movl   $0x3fb,-0x2c(%rbp)
  8004200572:	c6 45 d3 03          	movb   $0x3,-0x2d(%rbp)
  8004200576:	0f b6 45 d3          	movzbl -0x2d(%rbp),%eax
  800420057a:	8b 55 d4             	mov    -0x2c(%rbp),%edx
  800420057d:	ee                   	out    %al,(%dx)
  800420057e:	c7 45 cc fc 03 00 00 	movl   $0x3fc,-0x34(%rbp)
  8004200585:	c6 45 cb 00          	movb   $0x0,-0x35(%rbp)
  8004200589:	0f b6 45 cb          	movzbl -0x35(%rbp),%eax
  800420058d:	8b 55 cc             	mov    -0x34(%rbp),%edx
  8004200590:	ee                   	out    %al,(%dx)
  8004200591:	c7 45 c4 f9 03 00 00 	movl   $0x3f9,-0x3c(%rbp)
  8004200598:	c6 45 c3 01          	movb   $0x1,-0x3d(%rbp)
  800420059c:	0f b6 45 c3          	movzbl -0x3d(%rbp),%eax
  80042005a0:	8b 55 c4             	mov    -0x3c(%rbp),%edx
  80042005a3:	ee                   	out    %al,(%dx)
  80042005a4:	c7 45 bc fd 03 00 00 	movl   $0x3fd,-0x44(%rbp)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  80042005ab:	8b 55 bc             	mov    -0x44(%rbp),%edx
  80042005ae:	89 55 a4             	mov    %edx,-0x5c(%rbp)
  80042005b1:	8b 55 a4             	mov    -0x5c(%rbp),%edx
  80042005b4:	ec                   	in     (%dx),%al
  80042005b5:	89 c3                	mov    %eax,%ebx
  80042005b7:	88 5d bb             	mov    %bl,-0x45(%rbp)
	return data;
  80042005ba:	0f b6 45 bb          	movzbl -0x45(%rbp),%eax
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
  80042005be:	3c ff                	cmp    $0xff,%al
  80042005c0:	0f 95 c2             	setne  %dl
  80042005c3:	48 b8 c0 b6 21 04 80 	movabs $0x800421b6c0,%rax
  80042005ca:	00 00 00 
  80042005cd:	88 10                	mov    %dl,(%rax)
  80042005cf:	c7 45 b4 fa 03 00 00 	movl   $0x3fa,-0x4c(%rbp)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  80042005d6:	8b 55 b4             	mov    -0x4c(%rbp),%edx
  80042005d9:	89 55 a4             	mov    %edx,-0x5c(%rbp)
  80042005dc:	8b 55 a4             	mov    -0x5c(%rbp),%edx
  80042005df:	ec                   	in     (%dx),%al
  80042005e0:	89 c3                	mov    %eax,%ebx
  80042005e2:	88 5d b3             	mov    %bl,-0x4d(%rbp)
	return data;
  80042005e5:	c7 45 ac f8 03 00 00 	movl   $0x3f8,-0x54(%rbp)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  80042005ec:	8b 55 ac             	mov    -0x54(%rbp),%edx
  80042005ef:	89 55 a4             	mov    %edx,-0x5c(%rbp)
  80042005f2:	8b 55 a4             	mov    -0x5c(%rbp),%edx
  80042005f5:	ec                   	in     (%dx),%al
  80042005f6:	89 c3                	mov    %eax,%ebx
  80042005f8:	88 5d ab             	mov    %bl,-0x55(%rbp)
	(void) inb(COM1+COM_IIR);
	(void) inb(COM1+COM_RX);

}
  80042005fb:	48 83 c4 58          	add    $0x58,%rsp
  80042005ff:	5b                   	pop    %rbx
  8004200600:	5d                   	pop    %rbp
  8004200601:	c3                   	retq   

0000008004200602 <lpt_putc>:
// For information on PC parallel port programming, see the class References
// page.

static void
lpt_putc(int c)
{
  8004200602:	55                   	push   %rbp
  8004200603:	48 89 e5             	mov    %rsp,%rbp
  8004200606:	53                   	push   %rbx
  8004200607:	48 83 ec 38          	sub    $0x38,%rsp
  800420060b:	89 7d c4             	mov    %edi,-0x3c(%rbp)
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
  800420060e:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%rbp)
  8004200615:	eb 10                	jmp    8004200627 <lpt_putc+0x25>
		delay();
  8004200617:	48 b8 b8 03 20 04 80 	movabs $0x80042003b8,%rax
  800420061e:	00 00 00 
  8004200621:	ff d0                	callq  *%rax
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
  8004200623:	83 45 f4 01          	addl   $0x1,-0xc(%rbp)
  8004200627:	c7 45 f0 79 03 00 00 	movl   $0x379,-0x10(%rbp)
  800420062e:	8b 55 f0             	mov    -0x10(%rbp),%edx
  8004200631:	89 55 c0             	mov    %edx,-0x40(%rbp)
  8004200634:	8b 55 c0             	mov    -0x40(%rbp),%edx
  8004200637:	ec                   	in     (%dx),%al
  8004200638:	89 c3                	mov    %eax,%ebx
  800420063a:	88 5d ef             	mov    %bl,-0x11(%rbp)
	return data;
  800420063d:	0f b6 45 ef          	movzbl -0x11(%rbp),%eax
  8004200641:	84 c0                	test   %al,%al
  8004200643:	78 09                	js     800420064e <lpt_putc+0x4c>
  8004200645:	81 7d f4 ff 31 00 00 	cmpl   $0x31ff,-0xc(%rbp)
  800420064c:	7e c9                	jle    8004200617 <lpt_putc+0x15>
		delay();
	outb(0x378+0, c);
  800420064e:	8b 45 c4             	mov    -0x3c(%rbp),%eax
  8004200651:	0f b6 c0             	movzbl %al,%eax
  8004200654:	c7 45 e8 78 03 00 00 	movl   $0x378,-0x18(%rbp)
  800420065b:	88 45 e7             	mov    %al,-0x19(%rbp)
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  800420065e:	0f b6 45 e7          	movzbl -0x19(%rbp),%eax
  8004200662:	8b 55 e8             	mov    -0x18(%rbp),%edx
  8004200665:	ee                   	out    %al,(%dx)
  8004200666:	c7 45 e0 7a 03 00 00 	movl   $0x37a,-0x20(%rbp)
  800420066d:	c6 45 df 0d          	movb   $0xd,-0x21(%rbp)
  8004200671:	0f b6 45 df          	movzbl -0x21(%rbp),%eax
  8004200675:	8b 55 e0             	mov    -0x20(%rbp),%edx
  8004200678:	ee                   	out    %al,(%dx)
  8004200679:	c7 45 d8 7a 03 00 00 	movl   $0x37a,-0x28(%rbp)
  8004200680:	c6 45 d7 08          	movb   $0x8,-0x29(%rbp)
  8004200684:	0f b6 45 d7          	movzbl -0x29(%rbp),%eax
  8004200688:	8b 55 d8             	mov    -0x28(%rbp),%edx
  800420068b:	ee                   	out    %al,(%dx)
	outb(0x378+2, 0x08|0x04|0x01);
	outb(0x378+2, 0x08);
}
  800420068c:	48 83 c4 38          	add    $0x38,%rsp
  8004200690:	5b                   	pop    %rbx
  8004200691:	5d                   	pop    %rbp
  8004200692:	c3                   	retq   

0000008004200693 <cga_init>:
static uint16_t *crt_buf;
static uint16_t crt_pos;

static void
cga_init(void)
{
  8004200693:	55                   	push   %rbp
  8004200694:	48 89 e5             	mov    %rsp,%rbp
  8004200697:	53                   	push   %rbx
  8004200698:	48 83 ec 38          	sub    $0x38,%rsp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
  800420069c:	c7 45 f0 00 80 0b 04 	movl   $0x40b8000,-0x10(%rbp)
  80042006a3:	c7 45 f4 80 00 00 00 	movl   $0x80,-0xc(%rbp)
	was = *cp;
  80042006aa:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  80042006ae:	0f b7 00             	movzwl (%rax),%eax
  80042006b1:	66 89 45 ee          	mov    %ax,-0x12(%rbp)
	*cp = (uint16_t) 0xA55A;
  80042006b5:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  80042006b9:	66 c7 00 5a a5       	movw   $0xa55a,(%rax)
	if (*cp != 0xA55A) {
  80042006be:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  80042006c2:	0f b7 00             	movzwl (%rax),%eax
  80042006c5:	66 3d 5a a5          	cmp    $0xa55a,%ax
  80042006c9:	74 20                	je     80042006eb <cga_init+0x58>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
  80042006cb:	c7 45 f0 00 00 0b 04 	movl   $0x40b0000,-0x10(%rbp)
  80042006d2:	c7 45 f4 80 00 00 00 	movl   $0x80,-0xc(%rbp)
		addr_6845 = MONO_BASE;
  80042006d9:	48 b8 c4 b6 21 04 80 	movabs $0x800421b6c4,%rax
  80042006e0:	00 00 00 
  80042006e3:	c7 00 b4 03 00 00    	movl   $0x3b4,(%rax)
  80042006e9:	eb 1b                	jmp    8004200706 <cga_init+0x73>
	} else {
		*cp = was;
  80042006eb:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  80042006ef:	0f b7 55 ee          	movzwl -0x12(%rbp),%edx
  80042006f3:	66 89 10             	mov    %dx,(%rax)
		addr_6845 = CGA_BASE;
  80042006f6:	48 b8 c4 b6 21 04 80 	movabs $0x800421b6c4,%rax
  80042006fd:	00 00 00 
  8004200700:	c7 00 d4 03 00 00    	movl   $0x3d4,(%rax)
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
  8004200706:	48 b8 c4 b6 21 04 80 	movabs $0x800421b6c4,%rax
  800420070d:	00 00 00 
  8004200710:	8b 00                	mov    (%rax),%eax
  8004200712:	89 45 e4             	mov    %eax,-0x1c(%rbp)
  8004200715:	c6 45 e3 0e          	movb   $0xe,-0x1d(%rbp)
  8004200719:	0f b6 45 e3          	movzbl -0x1d(%rbp),%eax
  800420071d:	8b 55 e4             	mov    -0x1c(%rbp),%edx
  8004200720:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
  8004200721:	48 b8 c4 b6 21 04 80 	movabs $0x800421b6c4,%rax
  8004200728:	00 00 00 
  800420072b:	8b 00                	mov    (%rax),%eax
  800420072d:	83 c0 01             	add    $0x1,%eax
  8004200730:	89 45 dc             	mov    %eax,-0x24(%rbp)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  8004200733:	8b 55 dc             	mov    -0x24(%rbp),%edx
  8004200736:	89 55 c4             	mov    %edx,-0x3c(%rbp)
  8004200739:	8b 55 c4             	mov    -0x3c(%rbp),%edx
  800420073c:	ec                   	in     (%dx),%al
  800420073d:	89 c3                	mov    %eax,%ebx
  800420073f:	88 5d db             	mov    %bl,-0x25(%rbp)
	return data;
  8004200742:	0f b6 45 db          	movzbl -0x25(%rbp),%eax
  8004200746:	0f b6 c0             	movzbl %al,%eax
  8004200749:	c1 e0 08             	shl    $0x8,%eax
  800420074c:	89 45 e8             	mov    %eax,-0x18(%rbp)
	outb(addr_6845, 15);
  800420074f:	48 b8 c4 b6 21 04 80 	movabs $0x800421b6c4,%rax
  8004200756:	00 00 00 
  8004200759:	8b 00                	mov    (%rax),%eax
  800420075b:	89 45 d4             	mov    %eax,-0x2c(%rbp)
  800420075e:	c6 45 d3 0f          	movb   $0xf,-0x2d(%rbp)
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  8004200762:	0f b6 45 d3          	movzbl -0x2d(%rbp),%eax
  8004200766:	8b 55 d4             	mov    -0x2c(%rbp),%edx
  8004200769:	ee                   	out    %al,(%dx)
	pos |= inb(addr_6845 + 1);
  800420076a:	48 b8 c4 b6 21 04 80 	movabs $0x800421b6c4,%rax
  8004200771:	00 00 00 
  8004200774:	8b 00                	mov    (%rax),%eax
  8004200776:	83 c0 01             	add    $0x1,%eax
  8004200779:	89 45 cc             	mov    %eax,-0x34(%rbp)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  800420077c:	8b 55 cc             	mov    -0x34(%rbp),%edx
  800420077f:	89 55 c4             	mov    %edx,-0x3c(%rbp)
  8004200782:	8b 55 c4             	mov    -0x3c(%rbp),%edx
  8004200785:	ec                   	in     (%dx),%al
  8004200786:	89 c3                	mov    %eax,%ebx
  8004200788:	88 5d cb             	mov    %bl,-0x35(%rbp)
	return data;
  800420078b:	0f b6 45 cb          	movzbl -0x35(%rbp),%eax
  800420078f:	0f b6 c0             	movzbl %al,%eax
  8004200792:	09 45 e8             	or     %eax,-0x18(%rbp)

	crt_buf = (uint16_t*) cp;
  8004200795:	48 b8 c8 b6 21 04 80 	movabs $0x800421b6c8,%rax
  800420079c:	00 00 00 
  800420079f:	48 8b 55 f0          	mov    -0x10(%rbp),%rdx
  80042007a3:	48 89 10             	mov    %rdx,(%rax)
	crt_pos = pos;
  80042007a6:	8b 45 e8             	mov    -0x18(%rbp),%eax
  80042007a9:	89 c2                	mov    %eax,%edx
  80042007ab:	48 b8 d0 b6 21 04 80 	movabs $0x800421b6d0,%rax
  80042007b2:	00 00 00 
  80042007b5:	66 89 10             	mov    %dx,(%rax)
}
  80042007b8:	48 83 c4 38          	add    $0x38,%rsp
  80042007bc:	5b                   	pop    %rbx
  80042007bd:	5d                   	pop    %rbp
  80042007be:	c3                   	retq   

00000080042007bf <cga_putc>:



static void
cga_putc(int c)
{
  80042007bf:	55                   	push   %rbp
  80042007c0:	48 89 e5             	mov    %rsp,%rbp
  80042007c3:	48 83 ec 40          	sub    $0x40,%rsp
  80042007c7:	89 7d cc             	mov    %edi,-0x34(%rbp)
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
  80042007ca:	8b 45 cc             	mov    -0x34(%rbp),%eax
  80042007cd:	b0 00                	mov    $0x0,%al
  80042007cf:	85 c0                	test   %eax,%eax
  80042007d1:	75 07                	jne    80042007da <cga_putc+0x1b>
		c |= 0x0700;
  80042007d3:	81 4d cc 00 07 00 00 	orl    $0x700,-0x34(%rbp)

	switch (c & 0xff) {
  80042007da:	8b 45 cc             	mov    -0x34(%rbp),%eax
  80042007dd:	25 ff 00 00 00       	and    $0xff,%eax
  80042007e2:	83 f8 09             	cmp    $0x9,%eax
  80042007e5:	0f 84 f9 00 00 00    	je     80042008e4 <cga_putc+0x125>
  80042007eb:	83 f8 09             	cmp    $0x9,%eax
  80042007ee:	7f 0a                	jg     80042007fa <cga_putc+0x3b>
  80042007f0:	83 f8 08             	cmp    $0x8,%eax
  80042007f3:	74 18                	je     800420080d <cga_putc+0x4e>
  80042007f5:	e9 41 01 00 00       	jmpq   800420093b <cga_putc+0x17c>
  80042007fa:	83 f8 0a             	cmp    $0xa,%eax
  80042007fd:	74 74                	je     8004200873 <cga_putc+0xb4>
  80042007ff:	83 f8 0d             	cmp    $0xd,%eax
  8004200802:	0f 84 88 00 00 00    	je     8004200890 <cga_putc+0xd1>
  8004200808:	e9 2e 01 00 00       	jmpq   800420093b <cga_putc+0x17c>
	case '\b':
		if (crt_pos > 0) {
  800420080d:	48 b8 d0 b6 21 04 80 	movabs $0x800421b6d0,%rax
  8004200814:	00 00 00 
  8004200817:	0f b7 00             	movzwl (%rax),%eax
  800420081a:	66 85 c0             	test   %ax,%ax
  800420081d:	0f 84 53 01 00 00    	je     8004200976 <cga_putc+0x1b7>
			crt_pos--;
  8004200823:	48 b8 d0 b6 21 04 80 	movabs $0x800421b6d0,%rax
  800420082a:	00 00 00 
  800420082d:	0f b7 00             	movzwl (%rax),%eax
  8004200830:	8d 50 ff             	lea    -0x1(%rax),%edx
  8004200833:	48 b8 d0 b6 21 04 80 	movabs $0x800421b6d0,%rax
  800420083a:	00 00 00 
  800420083d:	66 89 10             	mov    %dx,(%rax)
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
  8004200840:	48 b8 c8 b6 21 04 80 	movabs $0x800421b6c8,%rax
  8004200847:	00 00 00 
  800420084a:	48 8b 10             	mov    (%rax),%rdx
  800420084d:	48 b8 d0 b6 21 04 80 	movabs $0x800421b6d0,%rax
  8004200854:	00 00 00 
  8004200857:	0f b7 00             	movzwl (%rax),%eax
  800420085a:	0f b7 c0             	movzwl %ax,%eax
  800420085d:	48 01 c0             	add    %rax,%rax
  8004200860:	48 01 c2             	add    %rax,%rdx
  8004200863:	8b 45 cc             	mov    -0x34(%rbp),%eax
  8004200866:	b0 00                	mov    $0x0,%al
  8004200868:	83 c8 20             	or     $0x20,%eax
  800420086b:	66 89 02             	mov    %ax,(%rdx)
		}
		break;
  800420086e:	e9 03 01 00 00       	jmpq   8004200976 <cga_putc+0x1b7>
	case '\n':
		crt_pos += CRT_COLS;
  8004200873:	48 b8 d0 b6 21 04 80 	movabs $0x800421b6d0,%rax
  800420087a:	00 00 00 
  800420087d:	0f b7 00             	movzwl (%rax),%eax
  8004200880:	8d 50 50             	lea    0x50(%rax),%edx
  8004200883:	48 b8 d0 b6 21 04 80 	movabs $0x800421b6d0,%rax
  800420088a:	00 00 00 
  800420088d:	66 89 10             	mov    %dx,(%rax)
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
  8004200890:	48 b8 d0 b6 21 04 80 	movabs $0x800421b6d0,%rax
  8004200897:	00 00 00 
  800420089a:	0f b7 30             	movzwl (%rax),%esi
  800420089d:	48 b8 d0 b6 21 04 80 	movabs $0x800421b6d0,%rax
  80042008a4:	00 00 00 
  80042008a7:	0f b7 08             	movzwl (%rax),%ecx
  80042008aa:	0f b7 c1             	movzwl %cx,%eax
  80042008ad:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
  80042008b3:	c1 e8 10             	shr    $0x10,%eax
  80042008b6:	89 c2                	mov    %eax,%edx
  80042008b8:	66 c1 ea 06          	shr    $0x6,%dx
  80042008bc:	89 d0                	mov    %edx,%eax
  80042008be:	c1 e0 02             	shl    $0x2,%eax
  80042008c1:	01 d0                	add    %edx,%eax
  80042008c3:	c1 e0 04             	shl    $0x4,%eax
  80042008c6:	89 ca                	mov    %ecx,%edx
  80042008c8:	66 29 c2             	sub    %ax,%dx
  80042008cb:	89 f0                	mov    %esi,%eax
  80042008cd:	66 29 d0             	sub    %dx,%ax
  80042008d0:	89 c2                	mov    %eax,%edx
  80042008d2:	48 b8 d0 b6 21 04 80 	movabs $0x800421b6d0,%rax
  80042008d9:	00 00 00 
  80042008dc:	66 89 10             	mov    %dx,(%rax)
		break;
  80042008df:	e9 93 00 00 00       	jmpq   8004200977 <cga_putc+0x1b8>
	case '\t':
		cons_putc(' ');
  80042008e4:	bf 20 00 00 00       	mov    $0x20,%edi
  80042008e9:	48 b8 4e 0e 20 04 80 	movabs $0x8004200e4e,%rax
  80042008f0:	00 00 00 
  80042008f3:	ff d0                	callq  *%rax
		cons_putc(' ');
  80042008f5:	bf 20 00 00 00       	mov    $0x20,%edi
  80042008fa:	48 b8 4e 0e 20 04 80 	movabs $0x8004200e4e,%rax
  8004200901:	00 00 00 
  8004200904:	ff d0                	callq  *%rax
		cons_putc(' ');
  8004200906:	bf 20 00 00 00       	mov    $0x20,%edi
  800420090b:	48 b8 4e 0e 20 04 80 	movabs $0x8004200e4e,%rax
  8004200912:	00 00 00 
  8004200915:	ff d0                	callq  *%rax
		cons_putc(' ');
  8004200917:	bf 20 00 00 00       	mov    $0x20,%edi
  800420091c:	48 b8 4e 0e 20 04 80 	movabs $0x8004200e4e,%rax
  8004200923:	00 00 00 
  8004200926:	ff d0                	callq  *%rax
		cons_putc(' ');
  8004200928:	bf 20 00 00 00       	mov    $0x20,%edi
  800420092d:	48 b8 4e 0e 20 04 80 	movabs $0x8004200e4e,%rax
  8004200934:	00 00 00 
  8004200937:	ff d0                	callq  *%rax
		break;
  8004200939:	eb 3c                	jmp    8004200977 <cga_putc+0x1b8>
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
  800420093b:	48 b8 c8 b6 21 04 80 	movabs $0x800421b6c8,%rax
  8004200942:	00 00 00 
  8004200945:	48 8b 10             	mov    (%rax),%rdx
  8004200948:	48 b8 d0 b6 21 04 80 	movabs $0x800421b6d0,%rax
  800420094f:	00 00 00 
  8004200952:	0f b7 00             	movzwl (%rax),%eax
  8004200955:	0f b7 c8             	movzwl %ax,%ecx
  8004200958:	48 01 c9             	add    %rcx,%rcx
  800420095b:	48 01 d1             	add    %rdx,%rcx
  800420095e:	8b 55 cc             	mov    -0x34(%rbp),%edx
  8004200961:	66 89 11             	mov    %dx,(%rcx)
  8004200964:	8d 50 01             	lea    0x1(%rax),%edx
  8004200967:	48 b8 d0 b6 21 04 80 	movabs $0x800421b6d0,%rax
  800420096e:	00 00 00 
  8004200971:	66 89 10             	mov    %dx,(%rax)
		break;
  8004200974:	eb 01                	jmp    8004200977 <cga_putc+0x1b8>
	case '\b':
		if (crt_pos > 0) {
			crt_pos--;
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
		}
		break;
  8004200976:	90                   	nop
	}

	// When the crt pos is more than that of CRT_SIZE (if output exceeds CRT_SIZE), it adds one more row at the end 
	// filling it up with ' ' (scrolls down to the next line). The data from the second line of the screen to the end 
	// is put into crt_buf, effectively removing the first line of the screen
	if (crt_pos >= CRT_SIZE) {
  8004200977:	48 b8 d0 b6 21 04 80 	movabs $0x800421b6d0,%rax
  800420097e:	00 00 00 
  8004200981:	0f b7 00             	movzwl (%rax),%eax
  8004200984:	66 3d cf 07          	cmp    $0x7cf,%ax
  8004200988:	0f 86 89 00 00 00    	jbe    8004200a17 <cga_putc+0x258>
		int i;
		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
  800420098e:	48 b8 c8 b6 21 04 80 	movabs $0x800421b6c8,%rax
  8004200995:	00 00 00 
  8004200998:	48 8b 00             	mov    (%rax),%rax
  800420099b:	48 8d 88 a0 00 00 00 	lea    0xa0(%rax),%rcx
  80042009a2:	48 b8 c8 b6 21 04 80 	movabs $0x800421b6c8,%rax
  80042009a9:	00 00 00 
  80042009ac:	48 8b 00             	mov    (%rax),%rax
  80042009af:	ba 00 0f 00 00       	mov    $0xf00,%edx
  80042009b4:	48 89 ce             	mov    %rcx,%rsi
  80042009b7:	48 89 c7             	mov    %rax,%rdi
  80042009ba:	48 b8 e6 2e 20 04 80 	movabs $0x8004202ee6,%rax
  80042009c1:	00 00 00 
  80042009c4:	ff d0                	callq  *%rax
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
  80042009c6:	c7 45 fc 80 07 00 00 	movl   $0x780,-0x4(%rbp)
  80042009cd:	eb 22                	jmp    80042009f1 <cga_putc+0x232>
			crt_buf[i] = 0x0700 | ' ';
  80042009cf:	48 b8 c8 b6 21 04 80 	movabs $0x800421b6c8,%rax
  80042009d6:	00 00 00 
  80042009d9:	48 8b 00             	mov    (%rax),%rax
  80042009dc:	8b 55 fc             	mov    -0x4(%rbp),%edx
  80042009df:	48 63 d2             	movslq %edx,%rdx
  80042009e2:	48 01 d2             	add    %rdx,%rdx
  80042009e5:	48 01 d0             	add    %rdx,%rax
  80042009e8:	66 c7 00 20 07       	movw   $0x720,(%rax)
	// filling it up with ' ' (scrolls down to the next line). The data from the second line of the screen to the end 
	// is put into crt_buf, effectively removing the first line of the screen
	if (crt_pos >= CRT_SIZE) {
		int i;
		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
  80042009ed:	83 45 fc 01          	addl   $0x1,-0x4(%rbp)
  80042009f1:	81 7d fc cf 07 00 00 	cmpl   $0x7cf,-0x4(%rbp)
  80042009f8:	7e d5                	jle    80042009cf <cga_putc+0x210>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
  80042009fa:	48 b8 d0 b6 21 04 80 	movabs $0x800421b6d0,%rax
  8004200a01:	00 00 00 
  8004200a04:	0f b7 00             	movzwl (%rax),%eax
  8004200a07:	8d 50 b0             	lea    -0x50(%rax),%edx
  8004200a0a:	48 b8 d0 b6 21 04 80 	movabs $0x800421b6d0,%rax
  8004200a11:	00 00 00 
  8004200a14:	66 89 10             	mov    %dx,(%rax)
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
  8004200a17:	48 b8 c4 b6 21 04 80 	movabs $0x800421b6c4,%rax
  8004200a1e:	00 00 00 
  8004200a21:	8b 00                	mov    (%rax),%eax
  8004200a23:	89 45 f8             	mov    %eax,-0x8(%rbp)
  8004200a26:	c6 45 f7 0e          	movb   $0xe,-0x9(%rbp)
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  8004200a2a:	0f b6 45 f7          	movzbl -0x9(%rbp),%eax
  8004200a2e:	8b 55 f8             	mov    -0x8(%rbp),%edx
  8004200a31:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
  8004200a32:	48 b8 d0 b6 21 04 80 	movabs $0x800421b6d0,%rax
  8004200a39:	00 00 00 
  8004200a3c:	0f b7 00             	movzwl (%rax),%eax
  8004200a3f:	66 c1 e8 08          	shr    $0x8,%ax
  8004200a43:	0f b6 c0             	movzbl %al,%eax
  8004200a46:	48 ba c4 b6 21 04 80 	movabs $0x800421b6c4,%rdx
  8004200a4d:	00 00 00 
  8004200a50:	8b 12                	mov    (%rdx),%edx
  8004200a52:	83 c2 01             	add    $0x1,%edx
  8004200a55:	89 55 f0             	mov    %edx,-0x10(%rbp)
  8004200a58:	88 45 ef             	mov    %al,-0x11(%rbp)
  8004200a5b:	0f b6 45 ef          	movzbl -0x11(%rbp),%eax
  8004200a5f:	8b 55 f0             	mov    -0x10(%rbp),%edx
  8004200a62:	ee                   	out    %al,(%dx)
	outb(addr_6845, 15);
  8004200a63:	48 b8 c4 b6 21 04 80 	movabs $0x800421b6c4,%rax
  8004200a6a:	00 00 00 
  8004200a6d:	8b 00                	mov    (%rax),%eax
  8004200a6f:	89 45 e8             	mov    %eax,-0x18(%rbp)
  8004200a72:	c6 45 e7 0f          	movb   $0xf,-0x19(%rbp)
  8004200a76:	0f b6 45 e7          	movzbl -0x19(%rbp),%eax
  8004200a7a:	8b 55 e8             	mov    -0x18(%rbp),%edx
  8004200a7d:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos);
  8004200a7e:	48 b8 d0 b6 21 04 80 	movabs $0x800421b6d0,%rax
  8004200a85:	00 00 00 
  8004200a88:	0f b7 00             	movzwl (%rax),%eax
  8004200a8b:	0f b6 c0             	movzbl %al,%eax
  8004200a8e:	48 ba c4 b6 21 04 80 	movabs $0x800421b6c4,%rdx
  8004200a95:	00 00 00 
  8004200a98:	8b 12                	mov    (%rdx),%edx
  8004200a9a:	83 c2 01             	add    $0x1,%edx
  8004200a9d:	89 55 e0             	mov    %edx,-0x20(%rbp)
  8004200aa0:	88 45 df             	mov    %al,-0x21(%rbp)
  8004200aa3:	0f b6 45 df          	movzbl -0x21(%rbp),%eax
  8004200aa7:	8b 55 e0             	mov    -0x20(%rbp),%edx
  8004200aaa:	ee                   	out    %al,(%dx)
}
  8004200aab:	c9                   	leaveq 
  8004200aac:	c3                   	retq   

0000008004200aad <kbd_proc_data>:
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
  8004200aad:	55                   	push   %rbp
  8004200aae:	48 89 e5             	mov    %rsp,%rbp
  8004200ab1:	53                   	push   %rbx
  8004200ab2:	48 83 ec 38          	sub    $0x38,%rsp
  8004200ab6:	c7 45 e4 64 00 00 00 	movl   $0x64,-0x1c(%rbp)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  8004200abd:	8b 55 e4             	mov    -0x1c(%rbp),%edx
  8004200ac0:	89 55 cc             	mov    %edx,-0x34(%rbp)
  8004200ac3:	8b 55 cc             	mov    -0x34(%rbp),%edx
  8004200ac6:	ec                   	in     (%dx),%al
  8004200ac7:	89 c3                	mov    %eax,%ebx
  8004200ac9:	88 5d e3             	mov    %bl,-0x1d(%rbp)
	return data;
  8004200acc:	0f b6 45 e3          	movzbl -0x1d(%rbp),%eax
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
  8004200ad0:	0f b6 c0             	movzbl %al,%eax
  8004200ad3:	83 e0 01             	and    $0x1,%eax
  8004200ad6:	85 c0                	test   %eax,%eax
  8004200ad8:	75 0a                	jne    8004200ae4 <kbd_proc_data+0x37>
		return -1;
  8004200ada:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  8004200adf:	e9 02 02 00 00       	jmpq   8004200ce6 <kbd_proc_data+0x239>
  8004200ae4:	c7 45 dc 60 00 00 00 	movl   $0x60,-0x24(%rbp)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  8004200aeb:	8b 55 dc             	mov    -0x24(%rbp),%edx
  8004200aee:	89 55 cc             	mov    %edx,-0x34(%rbp)
  8004200af1:	8b 55 cc             	mov    -0x34(%rbp),%edx
  8004200af4:	ec                   	in     (%dx),%al
  8004200af5:	89 c3                	mov    %eax,%ebx
  8004200af7:	88 5d db             	mov    %bl,-0x25(%rbp)
	return data;
  8004200afa:	0f b6 45 db          	movzbl -0x25(%rbp),%eax

	data = inb(KBDATAP);
  8004200afe:	88 45 eb             	mov    %al,-0x15(%rbp)

	if (data == 0xE0) {
  8004200b01:	80 7d eb e0          	cmpb   $0xe0,-0x15(%rbp)
  8004200b05:	75 27                	jne    8004200b2e <kbd_proc_data+0x81>
		// E0 escape character
		shift |= E0ESC;
  8004200b07:	48 b8 e8 b8 21 04 80 	movabs $0x800421b8e8,%rax
  8004200b0e:	00 00 00 
  8004200b11:	8b 00                	mov    (%rax),%eax
  8004200b13:	89 c2                	mov    %eax,%edx
  8004200b15:	83 ca 40             	or     $0x40,%edx
  8004200b18:	48 b8 e8 b8 21 04 80 	movabs $0x800421b8e8,%rax
  8004200b1f:	00 00 00 
  8004200b22:	89 10                	mov    %edx,(%rax)
		return 0;
  8004200b24:	b8 00 00 00 00       	mov    $0x0,%eax
  8004200b29:	e9 b8 01 00 00       	jmpq   8004200ce6 <kbd_proc_data+0x239>
	} else if (data & 0x80) {
  8004200b2e:	0f b6 45 eb          	movzbl -0x15(%rbp),%eax
  8004200b32:	84 c0                	test   %al,%al
  8004200b34:	79 65                	jns    8004200b9b <kbd_proc_data+0xee>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
  8004200b36:	48 b8 e8 b8 21 04 80 	movabs $0x800421b8e8,%rax
  8004200b3d:	00 00 00 
  8004200b40:	8b 00                	mov    (%rax),%eax
  8004200b42:	83 e0 40             	and    $0x40,%eax
  8004200b45:	85 c0                	test   %eax,%eax
  8004200b47:	75 09                	jne    8004200b52 <kbd_proc_data+0xa5>
  8004200b49:	0f b6 45 eb          	movzbl -0x15(%rbp),%eax
  8004200b4d:	83 e0 7f             	and    $0x7f,%eax
  8004200b50:	eb 04                	jmp    8004200b56 <kbd_proc_data+0xa9>
  8004200b52:	0f b6 45 eb          	movzbl -0x15(%rbp),%eax
  8004200b56:	88 45 eb             	mov    %al,-0x15(%rbp)
		shift &= ~(shiftcode[data] | E0ESC);
  8004200b59:	0f b6 45 eb          	movzbl -0x15(%rbp),%eax
  8004200b5d:	48 ba 60 b0 21 04 80 	movabs $0x800421b060,%rdx
  8004200b64:	00 00 00 
  8004200b67:	48 98                	cltq   
  8004200b69:	0f b6 04 02          	movzbl (%rdx,%rax,1),%eax
  8004200b6d:	83 c8 40             	or     $0x40,%eax
  8004200b70:	0f b6 c0             	movzbl %al,%eax
  8004200b73:	f7 d0                	not    %eax
  8004200b75:	89 c2                	mov    %eax,%edx
  8004200b77:	48 b8 e8 b8 21 04 80 	movabs $0x800421b8e8,%rax
  8004200b7e:	00 00 00 
  8004200b81:	8b 00                	mov    (%rax),%eax
  8004200b83:	21 c2                	and    %eax,%edx
  8004200b85:	48 b8 e8 b8 21 04 80 	movabs $0x800421b8e8,%rax
  8004200b8c:	00 00 00 
  8004200b8f:	89 10                	mov    %edx,(%rax)
		return 0;
  8004200b91:	b8 00 00 00 00       	mov    $0x0,%eax
  8004200b96:	e9 4b 01 00 00       	jmpq   8004200ce6 <kbd_proc_data+0x239>
	} else if (shift & E0ESC) {
  8004200b9b:	48 b8 e8 b8 21 04 80 	movabs $0x800421b8e8,%rax
  8004200ba2:	00 00 00 
  8004200ba5:	8b 00                	mov    (%rax),%eax
  8004200ba7:	83 e0 40             	and    $0x40,%eax
  8004200baa:	85 c0                	test   %eax,%eax
  8004200bac:	74 21                	je     8004200bcf <kbd_proc_data+0x122>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
  8004200bae:	80 4d eb 80          	orb    $0x80,-0x15(%rbp)
		shift &= ~E0ESC;
  8004200bb2:	48 b8 e8 b8 21 04 80 	movabs $0x800421b8e8,%rax
  8004200bb9:	00 00 00 
  8004200bbc:	8b 00                	mov    (%rax),%eax
  8004200bbe:	89 c2                	mov    %eax,%edx
  8004200bc0:	83 e2 bf             	and    $0xffffffbf,%edx
  8004200bc3:	48 b8 e8 b8 21 04 80 	movabs $0x800421b8e8,%rax
  8004200bca:	00 00 00 
  8004200bcd:	89 10                	mov    %edx,(%rax)
	}

	shift |= shiftcode[data];
  8004200bcf:	0f b6 45 eb          	movzbl -0x15(%rbp),%eax
  8004200bd3:	48 ba 60 b0 21 04 80 	movabs $0x800421b060,%rdx
  8004200bda:	00 00 00 
  8004200bdd:	48 98                	cltq   
  8004200bdf:	0f b6 04 02          	movzbl (%rdx,%rax,1),%eax
  8004200be3:	0f b6 d0             	movzbl %al,%edx
  8004200be6:	48 b8 e8 b8 21 04 80 	movabs $0x800421b8e8,%rax
  8004200bed:	00 00 00 
  8004200bf0:	8b 00                	mov    (%rax),%eax
  8004200bf2:	09 c2                	or     %eax,%edx
  8004200bf4:	48 b8 e8 b8 21 04 80 	movabs $0x800421b8e8,%rax
  8004200bfb:	00 00 00 
  8004200bfe:	89 10                	mov    %edx,(%rax)
	shift ^= togglecode[data];
  8004200c00:	0f b6 45 eb          	movzbl -0x15(%rbp),%eax
  8004200c04:	48 ba 60 b1 21 04 80 	movabs $0x800421b160,%rdx
  8004200c0b:	00 00 00 
  8004200c0e:	48 98                	cltq   
  8004200c10:	0f b6 04 02          	movzbl (%rdx,%rax,1),%eax
  8004200c14:	0f b6 d0             	movzbl %al,%edx
  8004200c17:	48 b8 e8 b8 21 04 80 	movabs $0x800421b8e8,%rax
  8004200c1e:	00 00 00 
  8004200c21:	8b 00                	mov    (%rax),%eax
  8004200c23:	31 c2                	xor    %eax,%edx
  8004200c25:	48 b8 e8 b8 21 04 80 	movabs $0x800421b8e8,%rax
  8004200c2c:	00 00 00 
  8004200c2f:	89 10                	mov    %edx,(%rax)

	c = charcode[shift & (CTL | SHIFT)][data];
  8004200c31:	48 b8 e8 b8 21 04 80 	movabs $0x800421b8e8,%rax
  8004200c38:	00 00 00 
  8004200c3b:	8b 00                	mov    (%rax),%eax
  8004200c3d:	89 c2                	mov    %eax,%edx
  8004200c3f:	83 e2 03             	and    $0x3,%edx
  8004200c42:	48 b8 60 b5 21 04 80 	movabs $0x800421b560,%rax
  8004200c49:	00 00 00 
  8004200c4c:	89 d2                	mov    %edx,%edx
  8004200c4e:	48 8b 14 d0          	mov    (%rax,%rdx,8),%rdx
  8004200c52:	0f b6 45 eb          	movzbl -0x15(%rbp),%eax
  8004200c56:	48 01 d0             	add    %rdx,%rax
  8004200c59:	0f b6 00             	movzbl (%rax),%eax
  8004200c5c:	0f b6 c0             	movzbl %al,%eax
  8004200c5f:	89 45 ec             	mov    %eax,-0x14(%rbp)
	if (shift & CAPSLOCK) {
  8004200c62:	48 b8 e8 b8 21 04 80 	movabs $0x800421b8e8,%rax
  8004200c69:	00 00 00 
  8004200c6c:	8b 00                	mov    (%rax),%eax
  8004200c6e:	83 e0 08             	and    $0x8,%eax
  8004200c71:	85 c0                	test   %eax,%eax
  8004200c73:	74 22                	je     8004200c97 <kbd_proc_data+0x1ea>
		if ('a' <= c && c <= 'z')
  8004200c75:	83 7d ec 60          	cmpl   $0x60,-0x14(%rbp)
  8004200c79:	7e 0c                	jle    8004200c87 <kbd_proc_data+0x1da>
  8004200c7b:	83 7d ec 7a          	cmpl   $0x7a,-0x14(%rbp)
  8004200c7f:	7f 06                	jg     8004200c87 <kbd_proc_data+0x1da>
			c += 'A' - 'a';
  8004200c81:	83 6d ec 20          	subl   $0x20,-0x14(%rbp)
  8004200c85:	eb 10                	jmp    8004200c97 <kbd_proc_data+0x1ea>
		else if ('A' <= c && c <= 'Z')
  8004200c87:	83 7d ec 40          	cmpl   $0x40,-0x14(%rbp)
  8004200c8b:	7e 0a                	jle    8004200c97 <kbd_proc_data+0x1ea>
  8004200c8d:	83 7d ec 5a          	cmpl   $0x5a,-0x14(%rbp)
  8004200c91:	7f 04                	jg     8004200c97 <kbd_proc_data+0x1ea>
			c += 'a' - 'A';
  8004200c93:	83 45 ec 20          	addl   $0x20,-0x14(%rbp)
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
  8004200c97:	48 b8 e8 b8 21 04 80 	movabs $0x800421b8e8,%rax
  8004200c9e:	00 00 00 
  8004200ca1:	8b 00                	mov    (%rax),%eax
  8004200ca3:	f7 d0                	not    %eax
  8004200ca5:	83 e0 06             	and    $0x6,%eax
  8004200ca8:	85 c0                	test   %eax,%eax
  8004200caa:	75 37                	jne    8004200ce3 <kbd_proc_data+0x236>
  8004200cac:	81 7d ec e9 00 00 00 	cmpl   $0xe9,-0x14(%rbp)
  8004200cb3:	75 2e                	jne    8004200ce3 <kbd_proc_data+0x236>
		cprintf("Rebooting!\n");
  8004200cb5:	48 bf 86 93 20 04 80 	movabs $0x8004209386,%rdi
  8004200cbc:	00 00 00 
  8004200cbf:	b8 00 00 00 00       	mov    $0x0,%eax
  8004200cc4:	48 ba 22 16 20 04 80 	movabs $0x8004201622,%rdx
  8004200ccb:	00 00 00 
  8004200cce:	ff d2                	callq  *%rdx
  8004200cd0:	c7 45 d4 92 00 00 00 	movl   $0x92,-0x2c(%rbp)
  8004200cd7:	c6 45 d3 03          	movb   $0x3,-0x2d(%rbp)
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  8004200cdb:	0f b6 45 d3          	movzbl -0x2d(%rbp),%eax
  8004200cdf:	8b 55 d4             	mov    -0x2c(%rbp),%edx
  8004200ce2:	ee                   	out    %al,(%dx)
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
  8004200ce3:	8b 45 ec             	mov    -0x14(%rbp),%eax
}
  8004200ce6:	48 83 c4 38          	add    $0x38,%rsp
  8004200cea:	5b                   	pop    %rbx
  8004200ceb:	5d                   	pop    %rbp
  8004200cec:	c3                   	retq   

0000008004200ced <kbd_intr>:

void
kbd_intr(void)
{
  8004200ced:	55                   	push   %rbp
  8004200cee:	48 89 e5             	mov    %rsp,%rbp
	cons_intr(kbd_proc_data);
  8004200cf1:	48 bf ad 0a 20 04 80 	movabs $0x8004200aad,%rdi
  8004200cf8:	00 00 00 
  8004200cfb:	48 b8 0f 0d 20 04 80 	movabs $0x8004200d0f,%rax
  8004200d02:	00 00 00 
  8004200d05:	ff d0                	callq  *%rax
}
  8004200d07:	5d                   	pop    %rbp
  8004200d08:	c3                   	retq   

0000008004200d09 <kbd_init>:

static void
kbd_init(void)
{
  8004200d09:	55                   	push   %rbp
  8004200d0a:	48 89 e5             	mov    %rsp,%rbp
}
  8004200d0d:	5d                   	pop    %rbp
  8004200d0e:	c3                   	retq   

0000008004200d0f <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
  8004200d0f:	55                   	push   %rbp
  8004200d10:	48 89 e5             	mov    %rsp,%rbp
  8004200d13:	48 83 ec 20          	sub    $0x20,%rsp
  8004200d17:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
	int c;

	while ((c = (*proc)()) != -1) {
  8004200d1b:	eb 6c                	jmp    8004200d89 <cons_intr+0x7a>
		if (c == 0)
  8004200d1d:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  8004200d21:	74 65                	je     8004200d88 <cons_intr+0x79>
			continue;
		cons.buf[cons.wpos++] = c;
  8004200d23:	48 b8 e0 b6 21 04 80 	movabs $0x800421b6e0,%rax
  8004200d2a:	00 00 00 
  8004200d2d:	8b 80 04 02 00 00    	mov    0x204(%rax),%eax
  8004200d33:	8b 55 fc             	mov    -0x4(%rbp),%edx
  8004200d36:	89 d6                	mov    %edx,%esi
  8004200d38:	48 b9 e0 b6 21 04 80 	movabs $0x800421b6e0,%rcx
  8004200d3f:	00 00 00 
  8004200d42:	89 c2                	mov    %eax,%edx
  8004200d44:	40 88 34 11          	mov    %sil,(%rcx,%rdx,1)
  8004200d48:	8d 50 01             	lea    0x1(%rax),%edx
  8004200d4b:	48 b8 e0 b6 21 04 80 	movabs $0x800421b6e0,%rax
  8004200d52:	00 00 00 
  8004200d55:	89 90 04 02 00 00    	mov    %edx,0x204(%rax)
		if (cons.wpos == CONSBUFSIZE)
  8004200d5b:	48 b8 e0 b6 21 04 80 	movabs $0x800421b6e0,%rax
  8004200d62:	00 00 00 
  8004200d65:	8b 80 04 02 00 00    	mov    0x204(%rax),%eax
  8004200d6b:	3d 00 02 00 00       	cmp    $0x200,%eax
  8004200d70:	75 17                	jne    8004200d89 <cons_intr+0x7a>
			cons.wpos = 0;
  8004200d72:	48 b8 e0 b6 21 04 80 	movabs $0x800421b6e0,%rax
  8004200d79:	00 00 00 
  8004200d7c:	c7 80 04 02 00 00 00 	movl   $0x0,0x204(%rax)
  8004200d83:	00 00 00 
  8004200d86:	eb 01                	jmp    8004200d89 <cons_intr+0x7a>
{
	int c;

	while ((c = (*proc)()) != -1) {
		if (c == 0)
			continue;
  8004200d88:	90                   	nop
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
  8004200d89:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004200d8d:	ff d0                	callq  *%rax
  8004200d8f:	89 45 fc             	mov    %eax,-0x4(%rbp)
  8004200d92:	83 7d fc ff          	cmpl   $0xffffffff,-0x4(%rbp)
  8004200d96:	75 85                	jne    8004200d1d <cons_intr+0xe>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
  8004200d98:	c9                   	leaveq 
  8004200d99:	c3                   	retq   

0000008004200d9a <cons_getc>:

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
  8004200d9a:	55                   	push   %rbp
  8004200d9b:	48 89 e5             	mov    %rsp,%rbp
  8004200d9e:	48 83 ec 10          	sub    $0x10,%rsp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
  8004200da2:	48 b8 78 04 20 04 80 	movabs $0x8004200478,%rax
  8004200da9:	00 00 00 
  8004200dac:	ff d0                	callq  *%rax
	kbd_intr();
  8004200dae:	48 b8 ed 0c 20 04 80 	movabs $0x8004200ced,%rax
  8004200db5:	00 00 00 
  8004200db8:	ff d0                	callq  *%rax

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
  8004200dba:	48 b8 e0 b6 21 04 80 	movabs $0x800421b6e0,%rax
  8004200dc1:	00 00 00 
  8004200dc4:	8b 90 00 02 00 00    	mov    0x200(%rax),%edx
  8004200dca:	48 b8 e0 b6 21 04 80 	movabs $0x800421b6e0,%rax
  8004200dd1:	00 00 00 
  8004200dd4:	8b 80 04 02 00 00    	mov    0x204(%rax),%eax
  8004200dda:	39 c2                	cmp    %eax,%edx
  8004200ddc:	74 69                	je     8004200e47 <cons_getc+0xad>
		c = cons.buf[cons.rpos++];
  8004200dde:	48 b8 e0 b6 21 04 80 	movabs $0x800421b6e0,%rax
  8004200de5:	00 00 00 
  8004200de8:	8b 80 00 02 00 00    	mov    0x200(%rax),%eax
  8004200dee:	48 b9 e0 b6 21 04 80 	movabs $0x800421b6e0,%rcx
  8004200df5:	00 00 00 
  8004200df8:	89 c2                	mov    %eax,%edx
  8004200dfa:	0f b6 14 11          	movzbl (%rcx,%rdx,1),%edx
  8004200dfe:	0f b6 d2             	movzbl %dl,%edx
  8004200e01:	89 55 fc             	mov    %edx,-0x4(%rbp)
  8004200e04:	8d 50 01             	lea    0x1(%rax),%edx
  8004200e07:	48 b8 e0 b6 21 04 80 	movabs $0x800421b6e0,%rax
  8004200e0e:	00 00 00 
  8004200e11:	89 90 00 02 00 00    	mov    %edx,0x200(%rax)
		if (cons.rpos == CONSBUFSIZE)
  8004200e17:	48 b8 e0 b6 21 04 80 	movabs $0x800421b6e0,%rax
  8004200e1e:	00 00 00 
  8004200e21:	8b 80 00 02 00 00    	mov    0x200(%rax),%eax
  8004200e27:	3d 00 02 00 00       	cmp    $0x200,%eax
  8004200e2c:	75 14                	jne    8004200e42 <cons_getc+0xa8>
			cons.rpos = 0;
  8004200e2e:	48 b8 e0 b6 21 04 80 	movabs $0x800421b6e0,%rax
  8004200e35:	00 00 00 
  8004200e38:	c7 80 00 02 00 00 00 	movl   $0x0,0x200(%rax)
  8004200e3f:	00 00 00 
		return c;
  8004200e42:	8b 45 fc             	mov    -0x4(%rbp),%eax
  8004200e45:	eb 05                	jmp    8004200e4c <cons_getc+0xb2>
	}
	return 0;
  8004200e47:	b8 00 00 00 00       	mov    $0x0,%eax
}
  8004200e4c:	c9                   	leaveq 
  8004200e4d:	c3                   	retq   

0000008004200e4e <cons_putc>:

// output a character to the console
static void
cons_putc(int c)
{
  8004200e4e:	55                   	push   %rbp
  8004200e4f:	48 89 e5             	mov    %rsp,%rbp
  8004200e52:	48 83 ec 10          	sub    $0x10,%rsp
  8004200e56:	89 7d fc             	mov    %edi,-0x4(%rbp)
	serial_putc(c);
  8004200e59:	8b 45 fc             	mov    -0x4(%rbp),%eax
  8004200e5c:	89 c7                	mov    %eax,%edi
  8004200e5e:	48 b8 a5 04 20 04 80 	movabs $0x80042004a5,%rax
  8004200e65:	00 00 00 
  8004200e68:	ff d0                	callq  *%rax
	lpt_putc(c);
  8004200e6a:	8b 45 fc             	mov    -0x4(%rbp),%eax
  8004200e6d:	89 c7                	mov    %eax,%edi
  8004200e6f:	48 b8 02 06 20 04 80 	movabs $0x8004200602,%rax
  8004200e76:	00 00 00 
  8004200e79:	ff d0                	callq  *%rax
	cga_putc(c);
  8004200e7b:	8b 45 fc             	mov    -0x4(%rbp),%eax
  8004200e7e:	89 c7                	mov    %eax,%edi
  8004200e80:	48 b8 bf 07 20 04 80 	movabs $0x80042007bf,%rax
  8004200e87:	00 00 00 
  8004200e8a:	ff d0                	callq  *%rax
}
  8004200e8c:	c9                   	leaveq 
  8004200e8d:	c3                   	retq   

0000008004200e8e <cons_init>:

// initialize the console devices
void
cons_init(void)
{
  8004200e8e:	55                   	push   %rbp
  8004200e8f:	48 89 e5             	mov    %rsp,%rbp
	cga_init();
  8004200e92:	48 b8 93 06 20 04 80 	movabs $0x8004200693,%rax
  8004200e99:	00 00 00 
  8004200e9c:	ff d0                	callq  *%rax
	kbd_init();
  8004200e9e:	48 b8 09 0d 20 04 80 	movabs $0x8004200d09,%rax
  8004200ea5:	00 00 00 
  8004200ea8:	ff d0                	callq  *%rax
	serial_init();
  8004200eaa:	48 b8 16 05 20 04 80 	movabs $0x8004200516,%rax
  8004200eb1:	00 00 00 
  8004200eb4:	ff d0                	callq  *%rax

	if (!serial_exists)
  8004200eb6:	48 b8 c0 b6 21 04 80 	movabs $0x800421b6c0,%rax
  8004200ebd:	00 00 00 
  8004200ec0:	0f b6 00             	movzbl (%rax),%eax
  8004200ec3:	83 f0 01             	xor    $0x1,%eax
  8004200ec6:	84 c0                	test   %al,%al
  8004200ec8:	74 1b                	je     8004200ee5 <cons_init+0x57>
		cprintf("Serial port does not exist!\n");
  8004200eca:	48 bf 92 93 20 04 80 	movabs $0x8004209392,%rdi
  8004200ed1:	00 00 00 
  8004200ed4:	b8 00 00 00 00       	mov    $0x0,%eax
  8004200ed9:	48 ba 22 16 20 04 80 	movabs $0x8004201622,%rdx
  8004200ee0:	00 00 00 
  8004200ee3:	ff d2                	callq  *%rdx
}
  8004200ee5:	5d                   	pop    %rbp
  8004200ee6:	c3                   	retq   

0000008004200ee7 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
  8004200ee7:	55                   	push   %rbp
  8004200ee8:	48 89 e5             	mov    %rsp,%rbp
  8004200eeb:	48 83 ec 10          	sub    $0x10,%rsp
  8004200eef:	89 7d fc             	mov    %edi,-0x4(%rbp)
	cons_putc(c);
  8004200ef2:	8b 45 fc             	mov    -0x4(%rbp),%eax
  8004200ef5:	89 c7                	mov    %eax,%edi
  8004200ef7:	48 b8 4e 0e 20 04 80 	movabs $0x8004200e4e,%rax
  8004200efe:	00 00 00 
  8004200f01:	ff d0                	callq  *%rax
}
  8004200f03:	c9                   	leaveq 
  8004200f04:	c3                   	retq   

0000008004200f05 <getchar>:

int
getchar(void)
{
  8004200f05:	55                   	push   %rbp
  8004200f06:	48 89 e5             	mov    %rsp,%rbp
  8004200f09:	48 83 ec 10          	sub    $0x10,%rsp
	int c;

	while ((c = cons_getc()) == 0)
  8004200f0d:	48 b8 9a 0d 20 04 80 	movabs $0x8004200d9a,%rax
  8004200f14:	00 00 00 
  8004200f17:	ff d0                	callq  *%rax
  8004200f19:	89 45 fc             	mov    %eax,-0x4(%rbp)
  8004200f1c:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  8004200f20:	74 eb                	je     8004200f0d <getchar+0x8>
		/* do nothing */;
	return c;
  8004200f22:	8b 45 fc             	mov    -0x4(%rbp),%eax
}
  8004200f25:	c9                   	leaveq 
  8004200f26:	c3                   	retq   

0000008004200f27 <iscons>:

int
iscons(int fdnum)
{
  8004200f27:	55                   	push   %rbp
  8004200f28:	48 89 e5             	mov    %rsp,%rbp
  8004200f2b:	48 83 ec 08          	sub    $0x8,%rsp
  8004200f2f:	89 7d fc             	mov    %edi,-0x4(%rbp)
	// used by readline
	return 1;
  8004200f32:	b8 01 00 00 00       	mov    $0x1,%eax
}
  8004200f37:	c9                   	leaveq 
  8004200f38:	c3                   	retq   
  8004200f39:	00 00                	add    %al,(%rax)
	...

0000008004200f3c <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
  8004200f3c:	55                   	push   %rbp
  8004200f3d:	48 89 e5             	mov    %rsp,%rbp
  8004200f40:	48 83 ec 30          	sub    $0x30,%rsp
  8004200f44:	89 7d ec             	mov    %edi,-0x14(%rbp)
  8004200f47:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
  8004200f4b:	48 89 55 d8          	mov    %rdx,-0x28(%rbp)
	int i;

	for (i = 0; i < NCOMMANDS; i++)
  8004200f4f:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%rbp)
  8004200f56:	eb 6c                	jmp    8004200fc4 <mon_help+0x88>
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
  8004200f58:	48 b9 80 b5 21 04 80 	movabs $0x800421b580,%rcx
  8004200f5f:	00 00 00 
  8004200f62:	8b 45 fc             	mov    -0x4(%rbp),%eax
  8004200f65:	48 63 d0             	movslq %eax,%rdx
  8004200f68:	48 89 d0             	mov    %rdx,%rax
  8004200f6b:	48 01 c0             	add    %rax,%rax
  8004200f6e:	48 01 d0             	add    %rdx,%rax
  8004200f71:	48 c1 e0 03          	shl    $0x3,%rax
  8004200f75:	48 01 c8             	add    %rcx,%rax
  8004200f78:	48 8b 48 08          	mov    0x8(%rax),%rcx
  8004200f7c:	48 be 80 b5 21 04 80 	movabs $0x800421b580,%rsi
  8004200f83:	00 00 00 
  8004200f86:	8b 45 fc             	mov    -0x4(%rbp),%eax
  8004200f89:	48 63 d0             	movslq %eax,%rdx
  8004200f8c:	48 89 d0             	mov    %rdx,%rax
  8004200f8f:	48 01 c0             	add    %rax,%rax
  8004200f92:	48 01 d0             	add    %rdx,%rax
  8004200f95:	48 c1 e0 03          	shl    $0x3,%rax
  8004200f99:	48 01 f0             	add    %rsi,%rax
  8004200f9c:	48 8b 00             	mov    (%rax),%rax
  8004200f9f:	48 89 ca             	mov    %rcx,%rdx
  8004200fa2:	48 89 c6             	mov    %rax,%rsi
  8004200fa5:	48 bf 41 94 20 04 80 	movabs $0x8004209441,%rdi
  8004200fac:	00 00 00 
  8004200faf:	b8 00 00 00 00       	mov    $0x0,%eax
  8004200fb4:	48 b9 22 16 20 04 80 	movabs $0x8004201622,%rcx
  8004200fbb:	00 00 00 
  8004200fbe:	ff d1                	callq  *%rcx
int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
	int i;

	for (i = 0; i < NCOMMANDS; i++)
  8004200fc0:	83 45 fc 01          	addl   $0x1,-0x4(%rbp)
  8004200fc4:	8b 45 fc             	mov    -0x4(%rbp),%eax
  8004200fc7:	83 f8 02             	cmp    $0x2,%eax
  8004200fca:	76 8c                	jbe    8004200f58 <mon_help+0x1c>
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
	return 0;
  8004200fcc:	b8 00 00 00 00       	mov    $0x0,%eax
}
  8004200fd1:	c9                   	leaveq 
  8004200fd2:	c3                   	retq   

0000008004200fd3 <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
  8004200fd3:	55                   	push   %rbp
  8004200fd4:	48 89 e5             	mov    %rsp,%rbp
  8004200fd7:	48 83 ec 30          	sub    $0x30,%rsp
  8004200fdb:	89 7d ec             	mov    %edi,-0x14(%rbp)
  8004200fde:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
  8004200fe2:	48 89 55 d8          	mov    %rdx,-0x28(%rbp)
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
  8004200fe6:	48 bf 4a 94 20 04 80 	movabs $0x800420944a,%rdi
  8004200fed:	00 00 00 
  8004200ff0:	b8 00 00 00 00       	mov    $0x0,%eax
  8004200ff5:	48 ba 22 16 20 04 80 	movabs $0x8004201622,%rdx
  8004200ffc:	00 00 00 
  8004200fff:	ff d2                	callq  *%rdx
	cprintf("  _start                  %08x (phys)\n", _start);
  8004201001:	48 be 0c 00 20 00 00 	movabs $0x20000c,%rsi
  8004201008:	00 00 00 
  800420100b:	48 bf 68 94 20 04 80 	movabs $0x8004209468,%rdi
  8004201012:	00 00 00 
  8004201015:	b8 00 00 00 00       	mov    $0x0,%eax
  800420101a:	48 ba 22 16 20 04 80 	movabs $0x8004201622,%rdx
  8004201021:	00 00 00 
  8004201024:	ff d2                	callq  *%rdx
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
  8004201026:	48 ba 0c 00 20 00 00 	movabs $0x20000c,%rdx
  800420102d:	00 00 00 
  8004201030:	48 be 0c 00 20 04 80 	movabs $0x800420000c,%rsi
  8004201037:	00 00 00 
  800420103a:	48 bf 90 94 20 04 80 	movabs $0x8004209490,%rdi
  8004201041:	00 00 00 
  8004201044:	b8 00 00 00 00       	mov    $0x0,%eax
  8004201049:	48 b9 22 16 20 04 80 	movabs $0x8004201622,%rcx
  8004201050:	00 00 00 
  8004201053:	ff d1                	callq  *%rcx
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
  8004201055:	48 ba f0 92 20 00 00 	movabs $0x2092f0,%rdx
  800420105c:	00 00 00 
  800420105f:	48 be f0 92 20 04 80 	movabs $0x80042092f0,%rsi
  8004201066:	00 00 00 
  8004201069:	48 bf b8 94 20 04 80 	movabs $0x80042094b8,%rdi
  8004201070:	00 00 00 
  8004201073:	b8 00 00 00 00       	mov    $0x0,%eax
  8004201078:	48 b9 22 16 20 04 80 	movabs $0x8004201622,%rcx
  800420107f:	00 00 00 
  8004201082:	ff d1                	callq  *%rcx
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
  8004201084:	48 ba c0 b6 21 00 00 	movabs $0x21b6c0,%rdx
  800420108b:	00 00 00 
  800420108e:	48 be c0 b6 21 04 80 	movabs $0x800421b6c0,%rsi
  8004201095:	00 00 00 
  8004201098:	48 bf e0 94 20 04 80 	movabs $0x80042094e0,%rdi
  800420109f:	00 00 00 
  80042010a2:	b8 00 00 00 00       	mov    $0x0,%eax
  80042010a7:	48 b9 22 16 20 04 80 	movabs $0x8004201622,%rcx
  80042010ae:	00 00 00 
  80042010b1:	ff d1                	callq  *%rcx
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
  80042010b3:	48 ba 60 cc 21 00 00 	movabs $0x21cc60,%rdx
  80042010ba:	00 00 00 
  80042010bd:	48 be 60 cc 21 04 80 	movabs $0x800421cc60,%rsi
  80042010c4:	00 00 00 
  80042010c7:	48 bf 08 95 20 04 80 	movabs $0x8004209508,%rdi
  80042010ce:	00 00 00 
  80042010d1:	b8 00 00 00 00       	mov    $0x0,%eax
  80042010d6:	48 b9 22 16 20 04 80 	movabs $0x8004201622,%rcx
  80042010dd:	00 00 00 
  80042010e0:	ff d1                	callq  *%rcx
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
  80042010e2:	48 c7 45 f8 00 04 00 	movq   $0x400,-0x8(%rbp)
  80042010e9:	00 
  80042010ea:	48 b8 0c 00 20 04 80 	movabs $0x800420000c,%rax
  80042010f1:	00 00 00 
  80042010f4:	48 8b 55 f8          	mov    -0x8(%rbp),%rdx
  80042010f8:	48 29 c2             	sub    %rax,%rdx
  80042010fb:	48 b8 60 cc 21 04 80 	movabs $0x800421cc60,%rax
  8004201102:	00 00 00 
  8004201105:	48 83 e8 01          	sub    $0x1,%rax
  8004201109:	48 01 d0             	add    %rdx,%rax
  800420110c:	48 89 45 f0          	mov    %rax,-0x10(%rbp)
  8004201110:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8004201114:	ba 00 00 00 00       	mov    $0x0,%edx
  8004201119:	48 f7 75 f8          	divq   -0x8(%rbp)
  800420111d:	48 89 d0             	mov    %rdx,%rax
  8004201120:	48 8b 55 f0          	mov    -0x10(%rbp),%rdx
  8004201124:	48 89 d1             	mov    %rdx,%rcx
  8004201127:	48 29 c1             	sub    %rax,%rcx
  800420112a:	48 89 c8             	mov    %rcx,%rax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
  800420112d:	48 8d 90 ff 03 00 00 	lea    0x3ff(%rax),%rdx
  8004201134:	48 85 c0             	test   %rax,%rax
  8004201137:	48 0f 48 c2          	cmovs  %rdx,%rax
  800420113b:	48 c1 f8 0a          	sar    $0xa,%rax
  800420113f:	48 89 c6             	mov    %rax,%rsi
  8004201142:	48 bf 30 95 20 04 80 	movabs $0x8004209530,%rdi
  8004201149:	00 00 00 
  800420114c:	b8 00 00 00 00       	mov    $0x0,%eax
  8004201151:	48 ba 22 16 20 04 80 	movabs $0x8004201622,%rdx
  8004201158:	00 00 00 
  800420115b:	ff d2                	callq  *%rdx
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
  800420115d:	b8 00 00 00 00       	mov    $0x0,%eax
}
  8004201162:	c9                   	leaveq 
  8004201163:	c3                   	retq   

0000008004201164 <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
  8004201164:	55                   	push   %rbp
  8004201165:	48 89 e5             	mov    %rsp,%rbp
  8004201168:	53                   	push   %rbx
  8004201169:	48 81 ec c8 04 00 00 	sub    $0x4c8,%rsp
  8004201170:	89 bd 4c fb ff ff    	mov    %edi,-0x4b4(%rbp)
  8004201176:	48 89 b5 40 fb ff ff 	mov    %rsi,-0x4c0(%rbp)
  800420117d:	48 89 95 38 fb ff ff 	mov    %rdx,-0x4c8(%rbp)

static __inline uint64_t
read_rbp(void)
{
        uint64_t rbp;
        __asm __volatile("movq %%rbp,%0" : "=r" (rbp)::"cc","memory");
  8004201184:	48 89 eb             	mov    %rbp,%rbx
  8004201187:	48 89 5d c8          	mov    %rbx,-0x38(%rbp)
        return rbp;
  800420118b:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
	// Displays the backtrace of the called functions.
	uint64_t* rbp = (uint64_t*)read_rbp();
  800420118f:	48 89 45 e8          	mov    %rax,-0x18(%rbp)
	uint64_t rip;
	read_rip(rip);
  8004201193:	48 8d 1d 00 00 00 00 	lea    0x0(%rip),%rbx        # 800420119a <mon_backtrace+0x36>
  800420119a:	48 89 5d e0          	mov    %rbx,-0x20(%rbp)
	int count = 0;
  800420119e:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%rbp)
	cprintf("Stack backtrace:\n"); 
  80042011a5:	48 bf 5a 95 20 04 80 	movabs $0x800420955a,%rdi
  80042011ac:	00 00 00 
  80042011af:	b8 00 00 00 00       	mov    $0x0,%eax
  80042011b4:	48 ba 22 16 20 04 80 	movabs $0x8004201622,%rdx
  80042011bb:	00 00 00 
  80042011be:	ff d2                	callq  *%rdx
	while (rbp != 0) {//stop when you reach the top of the function call
  80042011c0:	e9 26 01 00 00       	jmpq   80042012eb <mon_backtrace+0x187>
		//print the current values of rbp and rip and then dereference the previous values.
		cprintf("  rbp %#016x  rip %#016x\n", (uint64_t)rbp, rip);
  80042011c5:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  80042011c9:	48 8b 55 e0          	mov    -0x20(%rbp),%rdx
  80042011cd:	48 89 c6             	mov    %rax,%rsi
  80042011d0:	48 bf 6c 95 20 04 80 	movabs $0x800420956c,%rdi
  80042011d7:	00 00 00 
  80042011da:	b8 00 00 00 00       	mov    $0x0,%eax
  80042011df:	48 b9 22 16 20 04 80 	movabs $0x8004201622,%rcx
  80042011e6:	00 00 00 
  80042011e9:	ff d1                	callq  *%rcx
		struct Ripdebuginfo info;
		if (debuginfo_rip(rip, &info) == 0) {
  80042011eb:	48 8d 95 50 fb ff ff 	lea    -0x4b0(%rbp),%rdx
  80042011f2:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  80042011f6:	48 89 d6             	mov    %rdx,%rsi
  80042011f9:	48 89 c7             	mov    %rax,%rdi
  80042011fc:	48 b8 6b 1c 20 04 80 	movabs $0x8004201c6b,%rax
  8004201203:	00 00 00 
  8004201206:	ff d0                	callq  *%rax
  8004201208:	85 c0                	test   %eax,%eax
  800420120a:	0f 85 c0 00 00 00    	jne    80042012d0 <mon_backtrace+0x16c>
			//check if the structure is populated.
			cprintf("       %s:%d: %s+%#016x  args:%d", info.rip_file, info.rip_line, info.rip_fn_name, (uint64_t)rip-info.rip_fn_addr, info.rip_fn_narg);
  8004201210:	8b b5 78 fb ff ff    	mov    -0x488(%rbp),%esi
  8004201216:	48 8b 85 70 fb ff ff 	mov    -0x490(%rbp),%rax
  800420121d:	48 8b 55 e0          	mov    -0x20(%rbp),%rdx
  8004201221:	48 89 d7             	mov    %rdx,%rdi
  8004201224:	48 29 c7             	sub    %rax,%rdi
  8004201227:	48 8b 8d 60 fb ff ff 	mov    -0x4a0(%rbp),%rcx
  800420122e:	8b 95 58 fb ff ff    	mov    -0x4a8(%rbp),%edx
  8004201234:	48 8b 85 50 fb ff ff 	mov    -0x4b0(%rbp),%rax
  800420123b:	41 89 f1             	mov    %esi,%r9d
  800420123e:	49 89 f8             	mov    %rdi,%r8
  8004201241:	48 89 c6             	mov    %rax,%rsi
  8004201244:	48 bf 88 95 20 04 80 	movabs $0x8004209588,%rdi
  800420124b:	00 00 00 
  800420124e:	b8 00 00 00 00       	mov    $0x0,%eax
  8004201253:	49 ba 22 16 20 04 80 	movabs $0x8004201622,%r10
  800420125a:	00 00 00 
  800420125d:	41 ff d2             	callq  *%r10
			//Print the arguments
			int args = info.rip_fn_narg;
  8004201260:	8b 85 78 fb ff ff    	mov    -0x488(%rbp),%eax
  8004201266:	89 45 d8             	mov    %eax,-0x28(%rbp)
			int argc = 1;
  8004201269:	c7 45 d4 01 00 00 00 	movl   $0x1,-0x2c(%rbp)
			while (args > 0) {
  8004201270:	eb 3d                	jmp    80042012af <mon_backtrace+0x14b>
				cprintf("  %#016x", *(rbp-argc)>>32);
  8004201272:	8b 45 d4             	mov    -0x2c(%rbp),%eax
  8004201275:	48 98                	cltq   
  8004201277:	48 c1 e0 03          	shl    $0x3,%rax
  800420127b:	48 f7 d8             	neg    %rax
  800420127e:	48 03 45 e8          	add    -0x18(%rbp),%rax
  8004201282:	48 8b 00             	mov    (%rax),%rax
  8004201285:	48 c1 e8 20          	shr    $0x20,%rax
  8004201289:	48 89 c6             	mov    %rax,%rsi
  800420128c:	48 bf a9 95 20 04 80 	movabs $0x80042095a9,%rdi
  8004201293:	00 00 00 
  8004201296:	b8 00 00 00 00       	mov    $0x0,%eax
  800420129b:	48 ba 22 16 20 04 80 	movabs $0x8004201622,%rdx
  80042012a2:	00 00 00 
  80042012a5:	ff d2                	callq  *%rdx
				args--;
  80042012a7:	83 6d d8 01          	subl   $0x1,-0x28(%rbp)
				argc++;
  80042012ab:	83 45 d4 01          	addl   $0x1,-0x2c(%rbp)
			//check if the structure is populated.
			cprintf("       %s:%d: %s+%#016x  args:%d", info.rip_file, info.rip_line, info.rip_fn_name, (uint64_t)rip-info.rip_fn_addr, info.rip_fn_narg);
			//Print the arguments
			int args = info.rip_fn_narg;
			int argc = 1;
			while (args > 0) {
  80042012af:	83 7d d8 00          	cmpl   $0x0,-0x28(%rbp)
  80042012b3:	7f bd                	jg     8004201272 <mon_backtrace+0x10e>
				cprintf("  %#016x", *(rbp-argc)>>32);
				args--;
				argc++;
			}
			cprintf("\n");
  80042012b5:	48 bf b2 95 20 04 80 	movabs $0x80042095b2,%rdi
  80042012bc:	00 00 00 
  80042012bf:	b8 00 00 00 00       	mov    $0x0,%eax
  80042012c4:	48 ba 22 16 20 04 80 	movabs $0x8004201622,%rdx
  80042012cb:	00 00 00 
  80042012ce:	ff d2                	callq  *%rdx
		}
		rip = *(rbp + 1);	
  80042012d0:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  80042012d4:	48 8b 40 08          	mov    0x8(%rax),%rax
  80042012d8:	48 89 45 e0          	mov    %rax,-0x20(%rbp)
		rbp = (uint64_t*)  *rbp;
  80042012dc:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  80042012e0:	48 8b 00             	mov    (%rax),%rax
  80042012e3:	48 89 45 e8          	mov    %rax,-0x18(%rbp)
		count++;
  80042012e7:	83 45 dc 01          	addl   $0x1,-0x24(%rbp)
	uint64_t* rbp = (uint64_t*)read_rbp();
	uint64_t rip;
	read_rip(rip);
	int count = 0;
	cprintf("Stack backtrace:\n"); 
	while (rbp != 0) {//stop when you reach the top of the function call
  80042012eb:	48 83 7d e8 00       	cmpq   $0x0,-0x18(%rbp)
  80042012f0:	0f 85 cf fe ff ff    	jne    80042011c5 <mon_backtrace+0x61>
		}
		rip = *(rbp + 1);	
		rbp = (uint64_t*)  *rbp;
		count++;
	}
	return count;
  80042012f6:	8b 45 dc             	mov    -0x24(%rbp),%eax
}
  80042012f9:	48 81 c4 c8 04 00 00 	add    $0x4c8,%rsp
  8004201300:	5b                   	pop    %rbx
  8004201301:	5d                   	pop    %rbp
  8004201302:	c3                   	retq   

0000008004201303 <runcmd>:
#define WHITESPACE "\t\r\n "
#define MAXARGS 16

static int
runcmd(char *buf, struct Trapframe *tf)
{
  8004201303:	55                   	push   %rbp
  8004201304:	48 89 e5             	mov    %rsp,%rbp
  8004201307:	48 81 ec a0 00 00 00 	sub    $0xa0,%rsp
  800420130e:	48 89 bd 68 ff ff ff 	mov    %rdi,-0x98(%rbp)
  8004201315:	48 89 b5 60 ff ff ff 	mov    %rsi,-0xa0(%rbp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
  800420131c:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%rbp)
	argv[argc] = 0;
  8004201323:	8b 45 fc             	mov    -0x4(%rbp),%eax
  8004201326:	48 98                	cltq   
  8004201328:	48 c7 84 c5 70 ff ff 	movq   $0x0,-0x90(%rbp,%rax,8)
  800420132f:	ff 00 00 00 00 
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
  8004201334:	eb 15                	jmp    800420134b <runcmd+0x48>
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
	}
  8004201336:	90                   	nop
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
  8004201337:	eb 12                	jmp    800420134b <runcmd+0x48>
			*buf++ = 0;
  8004201339:	48 8b 85 68 ff ff ff 	mov    -0x98(%rbp),%rax
  8004201340:	c6 00 00             	movb   $0x0,(%rax)
  8004201343:	48 83 85 68 ff ff ff 	addq   $0x1,-0x98(%rbp)
  800420134a:	01 
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
  800420134b:	48 8b 85 68 ff ff ff 	mov    -0x98(%rbp),%rax
  8004201352:	0f b6 00             	movzbl (%rax),%eax
  8004201355:	84 c0                	test   %al,%al
  8004201357:	74 2a                	je     8004201383 <runcmd+0x80>
  8004201359:	48 8b 85 68 ff ff ff 	mov    -0x98(%rbp),%rax
  8004201360:	0f b6 00             	movzbl (%rax),%eax
  8004201363:	0f be c0             	movsbl %al,%eax
  8004201366:	89 c6                	mov    %eax,%esi
  8004201368:	48 bf b4 95 20 04 80 	movabs $0x80042095b4,%rdi
  800420136f:	00 00 00 
  8004201372:	48 b8 e7 2d 20 04 80 	movabs $0x8004202de7,%rax
  8004201379:	00 00 00 
  800420137c:	ff d0                	callq  *%rax
  800420137e:	48 85 c0             	test   %rax,%rax
  8004201381:	75 b6                	jne    8004201339 <runcmd+0x36>
			*buf++ = 0;
		if (*buf == 0)
  8004201383:	48 8b 85 68 ff ff ff 	mov    -0x98(%rbp),%rax
  800420138a:	0f b6 00             	movzbl (%rax),%eax
  800420138d:	84 c0                	test   %al,%al
  800420138f:	0f 84 93 00 00 00    	je     8004201428 <runcmd+0x125>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
  8004201395:	83 7d fc 0f          	cmpl   $0xf,-0x4(%rbp)
  8004201399:	75 2a                	jne    80042013c5 <runcmd+0xc2>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
  800420139b:	be 10 00 00 00       	mov    $0x10,%esi
  80042013a0:	48 bf b9 95 20 04 80 	movabs $0x80042095b9,%rdi
  80042013a7:	00 00 00 
  80042013aa:	b8 00 00 00 00       	mov    $0x0,%eax
  80042013af:	48 ba 22 16 20 04 80 	movabs $0x8004201622,%rdx
  80042013b6:	00 00 00 
  80042013b9:	ff d2                	callq  *%rdx
			return 0;
  80042013bb:	b8 00 00 00 00       	mov    $0x0,%eax
  80042013c0:	e9 4d 01 00 00       	jmpq   8004201512 <runcmd+0x20f>
		}
		argv[argc++] = buf;
  80042013c5:	8b 45 fc             	mov    -0x4(%rbp),%eax
  80042013c8:	48 98                	cltq   
  80042013ca:	48 8b 95 68 ff ff ff 	mov    -0x98(%rbp),%rdx
  80042013d1:	48 89 94 c5 70 ff ff 	mov    %rdx,-0x90(%rbp,%rax,8)
  80042013d8:	ff 
  80042013d9:	83 45 fc 01          	addl   $0x1,-0x4(%rbp)
		while (*buf && !strchr(WHITESPACE, *buf))
  80042013dd:	eb 08                	jmp    80042013e7 <runcmd+0xe4>
			buf++;
  80042013df:	48 83 85 68 ff ff ff 	addq   $0x1,-0x98(%rbp)
  80042013e6:	01 
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
  80042013e7:	48 8b 85 68 ff ff ff 	mov    -0x98(%rbp),%rax
  80042013ee:	0f b6 00             	movzbl (%rax),%eax
  80042013f1:	84 c0                	test   %al,%al
  80042013f3:	0f 84 3d ff ff ff    	je     8004201336 <runcmd+0x33>
  80042013f9:	48 8b 85 68 ff ff ff 	mov    -0x98(%rbp),%rax
  8004201400:	0f b6 00             	movzbl (%rax),%eax
  8004201403:	0f be c0             	movsbl %al,%eax
  8004201406:	89 c6                	mov    %eax,%esi
  8004201408:	48 bf b4 95 20 04 80 	movabs $0x80042095b4,%rdi
  800420140f:	00 00 00 
  8004201412:	48 b8 e7 2d 20 04 80 	movabs $0x8004202de7,%rax
  8004201419:	00 00 00 
  800420141c:	ff d0                	callq  *%rax
  800420141e:	48 85 c0             	test   %rax,%rax
  8004201421:	74 bc                	je     80042013df <runcmd+0xdc>
			buf++;
	}
  8004201423:	e9 0e ff ff ff       	jmpq   8004201336 <runcmd+0x33>
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
		if (*buf == 0)
			break;
  8004201428:	90                   	nop
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
	}
	argv[argc] = 0;
  8004201429:	8b 45 fc             	mov    -0x4(%rbp),%eax
  800420142c:	48 98                	cltq   
  800420142e:	48 c7 84 c5 70 ff ff 	movq   $0x0,-0x90(%rbp,%rax,8)
  8004201435:	ff 00 00 00 00 

	// Lookup and invoke the command
	if (argc == 0)
  800420143a:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  800420143e:	75 0a                	jne    800420144a <runcmd+0x147>
		return 0;
  8004201440:	b8 00 00 00 00       	mov    $0x0,%eax
  8004201445:	e9 c8 00 00 00       	jmpq   8004201512 <runcmd+0x20f>
	for (i = 0; i < NCOMMANDS; i++) {
  800420144a:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%rbp)
  8004201451:	e9 86 00 00 00       	jmpq   80042014dc <runcmd+0x1d9>
		if (strcmp(argv[0], commands[i].name) == 0)
  8004201456:	48 b9 80 b5 21 04 80 	movabs $0x800421b580,%rcx
  800420145d:	00 00 00 
  8004201460:	8b 45 f8             	mov    -0x8(%rbp),%eax
  8004201463:	48 63 d0             	movslq %eax,%rdx
  8004201466:	48 89 d0             	mov    %rdx,%rax
  8004201469:	48 01 c0             	add    %rax,%rax
  800420146c:	48 01 d0             	add    %rdx,%rax
  800420146f:	48 c1 e0 03          	shl    $0x3,%rax
  8004201473:	48 01 c8             	add    %rcx,%rax
  8004201476:	48 8b 10             	mov    (%rax),%rdx
  8004201479:	48 8b 85 70 ff ff ff 	mov    -0x90(%rbp),%rax
  8004201480:	48 89 d6             	mov    %rdx,%rsi
  8004201483:	48 89 c7             	mov    %rax,%rdi
  8004201486:	48 b8 1f 2d 20 04 80 	movabs $0x8004202d1f,%rax
  800420148d:	00 00 00 
  8004201490:	ff d0                	callq  *%rax
  8004201492:	85 c0                	test   %eax,%eax
  8004201494:	75 42                	jne    80042014d8 <runcmd+0x1d5>
			return commands[i].func(argc, argv, tf);
  8004201496:	48 b9 80 b5 21 04 80 	movabs $0x800421b580,%rcx
  800420149d:	00 00 00 
  80042014a0:	8b 45 f8             	mov    -0x8(%rbp),%eax
  80042014a3:	48 63 d0             	movslq %eax,%rdx
  80042014a6:	48 89 d0             	mov    %rdx,%rax
  80042014a9:	48 01 c0             	add    %rax,%rax
  80042014ac:	48 01 d0             	add    %rdx,%rax
  80042014af:	48 c1 e0 03          	shl    $0x3,%rax
  80042014b3:	48 01 c8             	add    %rcx,%rax
  80042014b6:	48 83 c0 10          	add    $0x10,%rax
  80042014ba:	4c 8b 00             	mov    (%rax),%r8
  80042014bd:	48 8b 95 60 ff ff ff 	mov    -0xa0(%rbp),%rdx
  80042014c4:	48 8d 8d 70 ff ff ff 	lea    -0x90(%rbp),%rcx
  80042014cb:	8b 45 fc             	mov    -0x4(%rbp),%eax
  80042014ce:	48 89 ce             	mov    %rcx,%rsi
  80042014d1:	89 c7                	mov    %eax,%edi
  80042014d3:	41 ff d0             	callq  *%r8
  80042014d6:	eb 3a                	jmp    8004201512 <runcmd+0x20f>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
  80042014d8:	83 45 f8 01          	addl   $0x1,-0x8(%rbp)
  80042014dc:	8b 45 f8             	mov    -0x8(%rbp),%eax
  80042014df:	83 f8 02             	cmp    $0x2,%eax
  80042014e2:	0f 86 6e ff ff ff    	jbe    8004201456 <runcmd+0x153>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
  80042014e8:	48 8b 85 70 ff ff ff 	mov    -0x90(%rbp),%rax
  80042014ef:	48 89 c6             	mov    %rax,%rsi
  80042014f2:	48 bf d6 95 20 04 80 	movabs $0x80042095d6,%rdi
  80042014f9:	00 00 00 
  80042014fc:	b8 00 00 00 00       	mov    $0x0,%eax
  8004201501:	48 ba 22 16 20 04 80 	movabs $0x8004201622,%rdx
  8004201508:	00 00 00 
  800420150b:	ff d2                	callq  *%rdx
	return 0;
  800420150d:	b8 00 00 00 00       	mov    $0x0,%eax
}
  8004201512:	c9                   	leaveq 
  8004201513:	c3                   	retq   

0000008004201514 <monitor>:

void
monitor(struct Trapframe *tf)
{
  8004201514:	55                   	push   %rbp
  8004201515:	48 89 e5             	mov    %rsp,%rbp
  8004201518:	48 83 ec 20          	sub    $0x20,%rsp
  800420151c:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
  8004201520:	48 bf f0 95 20 04 80 	movabs $0x80042095f0,%rdi
  8004201527:	00 00 00 
  800420152a:	b8 00 00 00 00       	mov    $0x0,%eax
  800420152f:	48 ba 22 16 20 04 80 	movabs $0x8004201622,%rdx
  8004201536:	00 00 00 
  8004201539:	ff d2                	callq  *%rdx
	cprintf("Type 'help' for a list of commands.\n");
  800420153b:	48 bf 18 96 20 04 80 	movabs $0x8004209618,%rdi
  8004201542:	00 00 00 
  8004201545:	b8 00 00 00 00       	mov    $0x0,%eax
  800420154a:	48 ba 22 16 20 04 80 	movabs $0x8004201622,%rdx
  8004201551:	00 00 00 
  8004201554:	ff d2                	callq  *%rdx
  8004201556:	eb 01                	jmp    8004201559 <monitor+0x45>
	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
  8004201558:	90                   	nop
	cprintf("Welcome to the JOS kernel monitor!\n");
	cprintf("Type 'help' for a list of commands.\n");


	while (1) {
		buf = readline("K> ");
  8004201559:	48 bf 3d 96 20 04 80 	movabs $0x800420963d,%rdi
  8004201560:	00 00 00 
  8004201563:	48 b8 04 2a 20 04 80 	movabs $0x8004202a04,%rax
  800420156a:	00 00 00 
  800420156d:	ff d0                	callq  *%rax
  800420156f:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
		if (buf != NULL)
  8004201573:	48 83 7d f8 00       	cmpq   $0x0,-0x8(%rbp)
  8004201578:	74 de                	je     8004201558 <monitor+0x44>
			if (runcmd(buf, tf) < 0)
  800420157a:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  800420157e:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8004201582:	48 89 d6             	mov    %rdx,%rsi
  8004201585:	48 89 c7             	mov    %rax,%rdi
  8004201588:	48 b8 03 13 20 04 80 	movabs $0x8004201303,%rax
  800420158f:	00 00 00 
  8004201592:	ff d0                	callq  *%rax
  8004201594:	85 c0                	test   %eax,%eax
  8004201596:	79 c0                	jns    8004201558 <monitor+0x44>
				break;
  8004201598:	90                   	nop
	}
}
  8004201599:	c9                   	leaveq 
  800420159a:	c3                   	retq   
	...

000000800420159c <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
  800420159c:	55                   	push   %rbp
  800420159d:	48 89 e5             	mov    %rsp,%rbp
  80042015a0:	48 83 ec 10          	sub    $0x10,%rsp
  80042015a4:	89 7d fc             	mov    %edi,-0x4(%rbp)
  80042015a7:	48 89 75 f0          	mov    %rsi,-0x10(%rbp)
	cputchar(ch);
  80042015ab:	8b 45 fc             	mov    -0x4(%rbp),%eax
  80042015ae:	89 c7                	mov    %eax,%edi
  80042015b0:	48 b8 e7 0e 20 04 80 	movabs $0x8004200ee7,%rax
  80042015b7:	00 00 00 
  80042015ba:	ff d0                	callq  *%rax
	*cnt++;
  80042015bc:	48 83 45 f0 04       	addq   $0x4,-0x10(%rbp)
}
  80042015c1:	c9                   	leaveq 
  80042015c2:	c3                   	retq   

00000080042015c3 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  80042015c3:	55                   	push   %rbp
  80042015c4:	48 89 e5             	mov    %rsp,%rbp
  80042015c7:	48 83 ec 30          	sub    $0x30,%rsp
  80042015cb:	48 89 7d d8          	mov    %rdi,-0x28(%rbp)
  80042015cf:	48 89 75 d0          	mov    %rsi,-0x30(%rbp)
	int cnt = 0;
  80042015d3:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%rbp)
    va_list aq;
    va_copy(aq,ap);
  80042015da:	48 8d 45 e0          	lea    -0x20(%rbp),%rax
  80042015de:	48 8b 55 d0          	mov    -0x30(%rbp),%rdx
  80042015e2:	48 8b 0a             	mov    (%rdx),%rcx
  80042015e5:	48 89 08             	mov    %rcx,(%rax)
  80042015e8:	48 8b 4a 08          	mov    0x8(%rdx),%rcx
  80042015ec:	48 89 48 08          	mov    %rcx,0x8(%rax)
  80042015f0:	48 8b 52 10          	mov    0x10(%rdx),%rdx
  80042015f4:	48 89 50 10          	mov    %rdx,0x10(%rax)
	vprintfmt((void*)putch, &cnt, fmt, aq);
  80042015f8:	48 8d 4d e0          	lea    -0x20(%rbp),%rcx
  80042015fc:	48 8b 55 d8          	mov    -0x28(%rbp),%rdx
  8004201600:	48 8d 45 fc          	lea    -0x4(%rbp),%rax
  8004201604:	48 89 c6             	mov    %rax,%rsi
  8004201607:	48 bf 9c 15 20 04 80 	movabs $0x800420159c,%rdi
  800420160e:	00 00 00 
  8004201611:	48 b8 64 22 20 04 80 	movabs $0x8004202264,%rax
  8004201618:	00 00 00 
  800420161b:	ff d0                	callq  *%rax
    va_end(aq);
	return cnt;
  800420161d:	8b 45 fc             	mov    -0x4(%rbp),%eax

}
  8004201620:	c9                   	leaveq 
  8004201621:	c3                   	retq   

0000008004201622 <cprintf>:

int
cprintf(const char *fmt, ...)
{
  8004201622:	55                   	push   %rbp
  8004201623:	48 89 e5             	mov    %rsp,%rbp
  8004201626:	48 81 ec 00 01 00 00 	sub    $0x100,%rsp
  800420162d:	48 89 b5 58 ff ff ff 	mov    %rsi,-0xa8(%rbp)
  8004201634:	48 89 95 60 ff ff ff 	mov    %rdx,-0xa0(%rbp)
  800420163b:	48 89 8d 68 ff ff ff 	mov    %rcx,-0x98(%rbp)
  8004201642:	4c 89 85 70 ff ff ff 	mov    %r8,-0x90(%rbp)
  8004201649:	4c 89 8d 78 ff ff ff 	mov    %r9,-0x88(%rbp)
  8004201650:	84 c0                	test   %al,%al
  8004201652:	74 20                	je     8004201674 <cprintf+0x52>
  8004201654:	0f 29 45 80          	movaps %xmm0,-0x80(%rbp)
  8004201658:	0f 29 4d 90          	movaps %xmm1,-0x70(%rbp)
  800420165c:	0f 29 55 a0          	movaps %xmm2,-0x60(%rbp)
  8004201660:	0f 29 5d b0          	movaps %xmm3,-0x50(%rbp)
  8004201664:	0f 29 65 c0          	movaps %xmm4,-0x40(%rbp)
  8004201668:	0f 29 6d d0          	movaps %xmm5,-0x30(%rbp)
  800420166c:	0f 29 75 e0          	movaps %xmm6,-0x20(%rbp)
  8004201670:	0f 29 7d f0          	movaps %xmm7,-0x10(%rbp)
  8004201674:	48 89 bd 08 ff ff ff 	mov    %rdi,-0xf8(%rbp)
	va_list ap;
	int cnt;
	va_start(ap, fmt);
  800420167b:	c7 85 30 ff ff ff 08 	movl   $0x8,-0xd0(%rbp)
  8004201682:	00 00 00 
  8004201685:	c7 85 34 ff ff ff 30 	movl   $0x30,-0xcc(%rbp)
  800420168c:	00 00 00 
  800420168f:	48 8d 45 10          	lea    0x10(%rbp),%rax
  8004201693:	48 89 85 38 ff ff ff 	mov    %rax,-0xc8(%rbp)
  800420169a:	48 8d 85 50 ff ff ff 	lea    -0xb0(%rbp),%rax
  80042016a1:	48 89 85 40 ff ff ff 	mov    %rax,-0xc0(%rbp)
    va_list aq;
    va_copy(aq,ap);
  80042016a8:	48 8d 85 18 ff ff ff 	lea    -0xe8(%rbp),%rax
  80042016af:	48 8d 95 30 ff ff ff 	lea    -0xd0(%rbp),%rdx
  80042016b6:	48 8b 0a             	mov    (%rdx),%rcx
  80042016b9:	48 89 08             	mov    %rcx,(%rax)
  80042016bc:	48 8b 4a 08          	mov    0x8(%rdx),%rcx
  80042016c0:	48 89 48 08          	mov    %rcx,0x8(%rax)
  80042016c4:	48 8b 52 10          	mov    0x10(%rdx),%rdx
  80042016c8:	48 89 50 10          	mov    %rdx,0x10(%rax)
	cnt = vcprintf(fmt, aq);
  80042016cc:	48 8d 95 18 ff ff ff 	lea    -0xe8(%rbp),%rdx
  80042016d3:	48 8b 85 08 ff ff ff 	mov    -0xf8(%rbp),%rax
  80042016da:	48 89 d6             	mov    %rdx,%rsi
  80042016dd:	48 89 c7             	mov    %rax,%rdi
  80042016e0:	48 b8 c3 15 20 04 80 	movabs $0x80042015c3,%rax
  80042016e7:	00 00 00 
  80042016ea:	ff d0                	callq  *%rax
  80042016ec:	89 85 4c ff ff ff    	mov    %eax,-0xb4(%rbp)
	va_end(aq);

	return cnt;
  80042016f2:	8b 85 4c ff ff ff    	mov    -0xb4(%rbp),%eax
}
  80042016f8:	c9                   	leaveq 
  80042016f9:	c3                   	retq   
	...

00000080042016fc <list_func_die>:

#endif


int list_func_die(struct Ripdebuginfo *info, Dwarf_Die *die, uint64_t addr)
{
  80042016fc:	55                   	push   %rbp
  80042016fd:	48 89 e5             	mov    %rsp,%rbp
  8004201700:	48 81 ec b0 61 00 00 	sub    $0x61b0,%rsp
  8004201707:	48 89 bd a8 9e ff ff 	mov    %rdi,-0x6158(%rbp)
  800420170e:	48 89 b5 a0 9e ff ff 	mov    %rsi,-0x6160(%rbp)
  8004201715:	48 89 95 98 9e ff ff 	mov    %rdx,-0x6168(%rbp)
	_Dwarf_Line ln;
	Dwarf_Attribute *low;
	Dwarf_Attribute *high;
	Dwarf_CU *cu = die->cu_header;
  800420171c:	48 8b 85 a0 9e ff ff 	mov    -0x6160(%rbp),%rax
  8004201723:	48 8b 80 60 03 00 00 	mov    0x360(%rax),%rax
  800420172a:	48 89 45 e8          	mov    %rax,-0x18(%rbp)
	Dwarf_Die *cudie = die->cu_die; 
  800420172e:	48 8b 85 a0 9e ff ff 	mov    -0x6160(%rbp),%rax
  8004201735:	48 8b 80 68 03 00 00 	mov    0x368(%rax),%rax
  800420173c:	48 89 45 e0          	mov    %rax,-0x20(%rbp)
	Dwarf_Die ret, sib=*die; 
  8004201740:	48 8b 95 a0 9e ff ff 	mov    -0x6160(%rbp),%rdx
  8004201747:	48 8d 85 b0 9e ff ff 	lea    -0x6150(%rbp),%rax
  800420174e:	48 89 d1             	mov    %rdx,%rcx
  8004201751:	ba 70 30 00 00       	mov    $0x3070,%edx
  8004201756:	48 89 ce             	mov    %rcx,%rsi
  8004201759:	48 89 c7             	mov    %rax,%rdi
  800420175c:	48 b8 fd 2f 20 04 80 	movabs $0x8004202ffd,%rax
  8004201763:	00 00 00 
  8004201766:	ff d0                	callq  *%rax
	Dwarf_Attribute *attr;
	uint64_t offset;
	uint64_t ret_val=8;
  8004201768:	48 c7 45 f8 08 00 00 	movq   $0x8,-0x8(%rbp)
  800420176f:	00 
	
	if(die->die_tag != DW_TAG_subprogram)
  8004201770:	48 8b 85 a0 9e ff ff 	mov    -0x6160(%rbp),%rax
  8004201777:	48 8b 40 18          	mov    0x18(%rax),%rax
  800420177b:	48 83 f8 2e          	cmp    $0x2e,%rax
  800420177f:	74 0a                	je     800420178b <list_func_die+0x8f>
		return 0;
  8004201781:	b8 00 00 00 00       	mov    $0x0,%eax
  8004201786:	e9 de 04 00 00       	jmpq   8004201c69 <list_func_die+0x56d>

	memset(&ln, 0, sizeof(_Dwarf_Line));
  800420178b:	48 8d 45 90          	lea    -0x70(%rbp),%rax
  800420178f:	ba 38 00 00 00       	mov    $0x38,%edx
  8004201794:	be 00 00 00 00       	mov    $0x0,%esi
  8004201799:	48 89 c7             	mov    %rax,%rdi
  800420179c:	48 b8 5b 2e 20 04 80 	movabs $0x8004202e5b,%rax
  80042017a3:	00 00 00 
  80042017a6:	ff d0                	callq  *%rax

	low  = _dwarf_attr_find(die, DW_AT_low_pc);
  80042017a8:	48 8b 85 a0 9e ff ff 	mov    -0x6160(%rbp),%rax
  80042017af:	be 11 00 00 00       	mov    $0x11,%esi
  80042017b4:	48 89 c7             	mov    %rax,%rdi
  80042017b7:	48 b8 cc 4d 20 04 80 	movabs $0x8004204dcc,%rax
  80042017be:	00 00 00 
  80042017c1:	ff d0                	callq  *%rax
  80042017c3:	48 89 45 d8          	mov    %rax,-0x28(%rbp)
	high = _dwarf_attr_find(die, DW_AT_high_pc);
  80042017c7:	48 8b 85 a0 9e ff ff 	mov    -0x6160(%rbp),%rax
  80042017ce:	be 12 00 00 00       	mov    $0x12,%esi
  80042017d3:	48 89 c7             	mov    %rax,%rdi
  80042017d6:	48 b8 cc 4d 20 04 80 	movabs $0x8004204dcc,%rax
  80042017dd:	00 00 00 
  80042017e0:	ff d0                	callq  *%rax
  80042017e2:	48 89 45 d0          	mov    %rax,-0x30(%rbp)

	if((low && (low->u[0].u64 < addr)) && (high && (high->u[0].u64 > addr)))
  80042017e6:	48 83 7d d8 00       	cmpq   $0x0,-0x28(%rbp)
  80042017eb:	0f 84 73 04 00 00    	je     8004201c64 <list_func_die+0x568>
  80042017f1:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  80042017f5:	48 8b 40 28          	mov    0x28(%rax),%rax
  80042017f9:	48 3b 85 98 9e ff ff 	cmp    -0x6168(%rbp),%rax
  8004201800:	0f 83 5e 04 00 00    	jae    8004201c64 <list_func_die+0x568>
  8004201806:	48 83 7d d0 00       	cmpq   $0x0,-0x30(%rbp)
  800420180b:	0f 84 53 04 00 00    	je     8004201c64 <list_func_die+0x568>
  8004201811:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  8004201815:	48 8b 40 28          	mov    0x28(%rax),%rax
  8004201819:	48 3b 85 98 9e ff ff 	cmp    -0x6168(%rbp),%rax
  8004201820:	0f 86 3e 04 00 00    	jbe    8004201c64 <list_func_die+0x568>
	{
		info->rip_file = die->cu_die->die_name;
  8004201826:	48 8b 85 a0 9e ff ff 	mov    -0x6160(%rbp),%rax
  800420182d:	48 8b 80 68 03 00 00 	mov    0x368(%rax),%rax
  8004201834:	48 8b 90 50 03 00 00 	mov    0x350(%rax),%rdx
  800420183b:	48 8b 85 a8 9e ff ff 	mov    -0x6158(%rbp),%rax
  8004201842:	48 89 10             	mov    %rdx,(%rax)

		info->rip_fn_name = die->die_name;
  8004201845:	48 8b 85 a0 9e ff ff 	mov    -0x6160(%rbp),%rax
  800420184c:	48 8b 90 50 03 00 00 	mov    0x350(%rax),%rdx
  8004201853:	48 8b 85 a8 9e ff ff 	mov    -0x6158(%rbp),%rax
  800420185a:	48 89 50 10          	mov    %rdx,0x10(%rax)
        info->rip_fn_namelen = strlen(die->die_name);
  800420185e:	48 8b 85 a0 9e ff ff 	mov    -0x6160(%rbp),%rax
  8004201865:	48 8b 80 50 03 00 00 	mov    0x350(%rax),%rax
  800420186c:	48 89 c7             	mov    %rax,%rdi
  800420186f:	48 b8 58 2b 20 04 80 	movabs $0x8004202b58,%rax
  8004201876:	00 00 00 
  8004201879:	ff d0                	callq  *%rax
  800420187b:	48 8b 95 a8 9e ff ff 	mov    -0x6158(%rbp),%rdx
  8004201882:	89 42 18             	mov    %eax,0x18(%rdx)

		info->rip_fn_addr = (uintptr_t)low->u[0].u64;
  8004201885:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  8004201889:	48 8b 50 28          	mov    0x28(%rax),%rdx
  800420188d:	48 8b 85 a8 9e ff ff 	mov    -0x6158(%rbp),%rax
  8004201894:	48 89 50 20          	mov    %rdx,0x20(%rax)

		assert(die->cu_die);	
  8004201898:	48 8b 85 a0 9e ff ff 	mov    -0x6160(%rbp),%rax
  800420189f:	48 8b 80 68 03 00 00 	mov    0x368(%rax),%rax
  80042018a6:	48 85 c0             	test   %rax,%rax
  80042018a9:	75 35                	jne    80042018e0 <list_func_die+0x1e4>
  80042018ab:	48 b9 98 99 20 04 80 	movabs $0x8004209998,%rcx
  80042018b2:	00 00 00 
  80042018b5:	48 ba a4 99 20 04 80 	movabs $0x80042099a4,%rdx
  80042018bc:	00 00 00 
  80042018bf:	be 69 00 00 00       	mov    $0x69,%esi
  80042018c4:	48 bf b9 99 20 04 80 	movabs $0x80042099b9,%rdi
  80042018cb:	00 00 00 
  80042018ce:	b8 00 00 00 00       	mov    $0x0,%eax
  80042018d3:	49 b8 9b 01 20 04 80 	movabs $0x800420019b,%r8
  80042018da:	00 00 00 
  80042018dd:	41 ff d0             	callq  *%r8
		dwarf_srclines(die->cu_die, &ln, addr, NULL); 
  80042018e0:	48 8b 85 a0 9e ff ff 	mov    -0x6160(%rbp),%rax
  80042018e7:	48 8b 80 68 03 00 00 	mov    0x368(%rax),%rax
  80042018ee:	48 8b 95 98 9e ff ff 	mov    -0x6168(%rbp),%rdx
  80042018f5:	48 8d 75 90          	lea    -0x70(%rbp),%rsi
  80042018f9:	b9 00 00 00 00       	mov    $0x0,%ecx
  80042018fe:	48 89 c7             	mov    %rax,%rdi
  8004201901:	48 b8 6b 84 20 04 80 	movabs $0x800420846b,%rax
  8004201908:	00 00 00 
  800420190b:	ff d0                	callq  *%rax

		info->rip_line = ln.ln_lineno;
  800420190d:	48 8b 45 a8          	mov    -0x58(%rbp),%rax
  8004201911:	89 c2                	mov    %eax,%edx
  8004201913:	48 8b 85 a8 9e ff ff 	mov    -0x6158(%rbp),%rax
  800420191a:	89 50 08             	mov    %edx,0x8(%rax)
		info->rip_fn_narg = 0;
  800420191d:	48 8b 85 a8 9e ff ff 	mov    -0x6158(%rbp),%rax
  8004201924:	c7 40 28 00 00 00 00 	movl   $0x0,0x28(%rax)

		Dwarf_Attribute* attr;

		if(dwarf_child(dbg, cu, &sib, &ret) != DW_DLE_NO_ENTRY)
  800420192b:	48 b8 c8 b5 21 04 80 	movabs $0x800421b5c8,%rax
  8004201932:	00 00 00 
  8004201935:	48 8b 00             	mov    (%rax),%rax
  8004201938:	48 8d 8d 20 cf ff ff 	lea    -0x30e0(%rbp),%rcx
  800420193f:	48 8d 95 b0 9e ff ff 	lea    -0x6150(%rbp),%rdx
  8004201946:	48 8b 75 e8          	mov    -0x18(%rbp),%rsi
  800420194a:	48 89 c7             	mov    %rax,%rdi
  800420194d:	48 b8 a3 50 20 04 80 	movabs $0x80042050a3,%rax
  8004201954:	00 00 00 
  8004201957:	ff d0                	callq  *%rax
  8004201959:	83 f8 04             	cmp    $0x4,%eax
  800420195c:	0f 84 fb 02 00 00    	je     8004201c5d <list_func_die+0x561>
		{
			if(ret.die_tag != DW_TAG_formal_parameter)
  8004201962:	48 8b 85 38 cf ff ff 	mov    -0x30c8(%rbp),%rax
  8004201969:	48 83 f8 05          	cmp    $0x5,%rax
  800420196d:	0f 85 e6 02 00 00    	jne    8004201c59 <list_func_die+0x55d>
				goto last;

			attr = _dwarf_attr_find(&ret, DW_AT_type);
  8004201973:	48 8d 85 20 cf ff ff 	lea    -0x30e0(%rbp),%rax
  800420197a:	be 49 00 00 00       	mov    $0x49,%esi
  800420197f:	48 89 c7             	mov    %rax,%rdi
  8004201982:	48 b8 cc 4d 20 04 80 	movabs $0x8004204dcc,%rax
  8004201989:	00 00 00 
  800420198c:	ff d0                	callq  *%rax
  800420198e:	48 89 45 f0          	mov    %rax,-0x10(%rbp)
	
try_again:
			if(attr != NULL)
  8004201992:	48 83 7d f0 00       	cmpq   $0x0,-0x10(%rbp)
  8004201997:	0f 84 d7 00 00 00    	je     8004201a74 <list_func_die+0x378>
			{
				offset = (uint64_t)cu->cu_offset + attr->u[0].u64;
  800420199d:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  80042019a1:	48 8b 50 30          	mov    0x30(%rax),%rdx
  80042019a5:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  80042019a9:	48 8b 40 28          	mov    0x28(%rax),%rax
  80042019ad:	48 01 d0             	add    %rdx,%rax
  80042019b0:	48 89 45 c8          	mov    %rax,-0x38(%rbp)
				dwarf_offdie(dbg, offset, &sib, *cu);
  80042019b4:	48 b8 c8 b5 21 04 80 	movabs $0x800421b5c8,%rax
  80042019bb:	00 00 00 
  80042019be:	48 8b 08             	mov    (%rax),%rcx
  80042019c1:	48 8d 95 b0 9e ff ff 	lea    -0x6150(%rbp),%rdx
  80042019c8:	48 8b 75 c8          	mov    -0x38(%rbp),%rsi
  80042019cc:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  80042019d0:	48 8b 38             	mov    (%rax),%rdi
  80042019d3:	48 89 3c 24          	mov    %rdi,(%rsp)
  80042019d7:	48 8b 78 08          	mov    0x8(%rax),%rdi
  80042019db:	48 89 7c 24 08       	mov    %rdi,0x8(%rsp)
  80042019e0:	48 8b 78 10          	mov    0x10(%rax),%rdi
  80042019e4:	48 89 7c 24 10       	mov    %rdi,0x10(%rsp)
  80042019e9:	48 8b 78 18          	mov    0x18(%rax),%rdi
  80042019ed:	48 89 7c 24 18       	mov    %rdi,0x18(%rsp)
  80042019f2:	48 8b 78 20          	mov    0x20(%rax),%rdi
  80042019f6:	48 89 7c 24 20       	mov    %rdi,0x20(%rsp)
  80042019fb:	48 8b 78 28          	mov    0x28(%rax),%rdi
  80042019ff:	48 89 7c 24 28       	mov    %rdi,0x28(%rsp)
  8004201a04:	48 8b 40 30          	mov    0x30(%rax),%rax
  8004201a08:	48 89 44 24 30       	mov    %rax,0x30(%rsp)
  8004201a0d:	48 89 cf             	mov    %rcx,%rdi
  8004201a10:	48 b8 c9 4c 20 04 80 	movabs $0x8004204cc9,%rax
  8004201a17:	00 00 00 
  8004201a1a:	ff d0                	callq  *%rax
				attr = _dwarf_attr_find(&sib, DW_AT_byte_size);
  8004201a1c:	48 8d 85 b0 9e ff ff 	lea    -0x6150(%rbp),%rax
  8004201a23:	be 0b 00 00 00       	mov    $0xb,%esi
  8004201a28:	48 89 c7             	mov    %rax,%rdi
  8004201a2b:	48 b8 cc 4d 20 04 80 	movabs $0x8004204dcc,%rax
  8004201a32:	00 00 00 
  8004201a35:	ff d0                	callq  *%rax
  8004201a37:	48 89 45 f0          	mov    %rax,-0x10(%rbp)
		
				if(attr != NULL)
  8004201a3b:	48 83 7d f0 00       	cmpq   $0x0,-0x10(%rbp)
  8004201a40:	74 0e                	je     8004201a50 <list_func_die+0x354>
				{
					ret_val = attr->u[0].u64;
  8004201a42:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8004201a46:	48 8b 40 28          	mov    0x28(%rax),%rax
  8004201a4a:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
  8004201a4e:	eb 24                	jmp    8004201a74 <list_func_die+0x378>
				}
				else
				{
					attr = _dwarf_attr_find(&sib, DW_AT_type);
  8004201a50:	48 8d 85 b0 9e ff ff 	lea    -0x6150(%rbp),%rax
  8004201a57:	be 49 00 00 00       	mov    $0x49,%esi
  8004201a5c:	48 89 c7             	mov    %rax,%rdi
  8004201a5f:	48 b8 cc 4d 20 04 80 	movabs $0x8004204dcc,%rax
  8004201a66:	00 00 00 
  8004201a69:	ff d0                	callq  *%rax
  8004201a6b:	48 89 45 f0          	mov    %rax,-0x10(%rbp)
					goto try_again;
  8004201a6f:	e9 1e ff ff ff       	jmpq   8004201992 <list_func_die+0x296>
				}
			}
			info->size_fn_arg[info->rip_fn_narg] = ret_val;
  8004201a74:	48 8b 85 a8 9e ff ff 	mov    -0x6158(%rbp),%rax
  8004201a7b:	8b 48 28             	mov    0x28(%rax),%ecx
  8004201a7e:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8004201a82:	89 c2                	mov    %eax,%edx
  8004201a84:	48 8b 85 a8 9e ff ff 	mov    -0x6158(%rbp),%rax
  8004201a8b:	48 63 c9             	movslq %ecx,%rcx
  8004201a8e:	48 83 c1 08          	add    $0x8,%rcx
  8004201a92:	89 54 88 0c          	mov    %edx,0xc(%rax,%rcx,4)
			info->rip_fn_narg++;
  8004201a96:	48 8b 85 a8 9e ff ff 	mov    -0x6158(%rbp),%rax
  8004201a9d:	8b 40 28             	mov    0x28(%rax),%eax
  8004201aa0:	8d 50 01             	lea    0x1(%rax),%edx
  8004201aa3:	48 8b 85 a8 9e ff ff 	mov    -0x6158(%rbp),%rax
  8004201aaa:	89 50 28             	mov    %edx,0x28(%rax)
			sib = ret; 
  8004201aad:	48 8d 85 b0 9e ff ff 	lea    -0x6150(%rbp),%rax
  8004201ab4:	48 8d 8d 20 cf ff ff 	lea    -0x30e0(%rbp),%rcx
  8004201abb:	ba 70 30 00 00       	mov    $0x3070,%edx
  8004201ac0:	48 89 ce             	mov    %rcx,%rsi
  8004201ac3:	48 89 c7             	mov    %rax,%rdi
  8004201ac6:	48 b8 fd 2f 20 04 80 	movabs $0x8004202ffd,%rax
  8004201acd:	00 00 00 
  8004201ad0:	ff d0                	callq  *%rax

			while(dwarf_siblingof(dbg, &sib, &ret, cu) == DW_DLV_OK)	
  8004201ad2:	e9 4a 01 00 00       	jmpq   8004201c21 <list_func_die+0x525>
			{
				if(ret.die_tag != DW_TAG_formal_parameter)
  8004201ad7:	48 8b 85 38 cf ff ff 	mov    -0x30c8(%rbp),%rax
  8004201ade:	48 83 f8 05          	cmp    $0x5,%rax
  8004201ae2:	0f 85 74 01 00 00    	jne    8004201c5c <list_func_die+0x560>
					break;

				attr = _dwarf_attr_find(&ret, DW_AT_type);
  8004201ae8:	48 8d 85 20 cf ff ff 	lea    -0x30e0(%rbp),%rax
  8004201aef:	be 49 00 00 00       	mov    $0x49,%esi
  8004201af4:	48 89 c7             	mov    %rax,%rdi
  8004201af7:	48 b8 cc 4d 20 04 80 	movabs $0x8004204dcc,%rax
  8004201afe:	00 00 00 
  8004201b01:	ff d0                	callq  *%rax
  8004201b03:	48 89 45 f0          	mov    %rax,-0x10(%rbp)
    
   		        if(attr != NULL)
  8004201b07:	48 83 7d f0 00       	cmpq   $0x0,-0x10(%rbp)
  8004201b0c:	0f 84 b1 00 00 00    	je     8004201bc3 <list_func_die+0x4c7>
            	{	   
                	offset = (uint64_t)cu->cu_offset + attr->u[0].u64;
  8004201b12:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004201b16:	48 8b 50 30          	mov    0x30(%rax),%rdx
  8004201b1a:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8004201b1e:	48 8b 40 28          	mov    0x28(%rax),%rax
  8004201b22:	48 01 d0             	add    %rdx,%rax
  8004201b25:	48 89 45 c8          	mov    %rax,-0x38(%rbp)
                	dwarf_offdie(dbg, offset, &sib, *cu);
  8004201b29:	48 b8 c8 b5 21 04 80 	movabs $0x800421b5c8,%rax
  8004201b30:	00 00 00 
  8004201b33:	48 8b 08             	mov    (%rax),%rcx
  8004201b36:	48 8d 95 b0 9e ff ff 	lea    -0x6150(%rbp),%rdx
  8004201b3d:	48 8b 75 c8          	mov    -0x38(%rbp),%rsi
  8004201b41:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004201b45:	48 8b 38             	mov    (%rax),%rdi
  8004201b48:	48 89 3c 24          	mov    %rdi,(%rsp)
  8004201b4c:	48 8b 78 08          	mov    0x8(%rax),%rdi
  8004201b50:	48 89 7c 24 08       	mov    %rdi,0x8(%rsp)
  8004201b55:	48 8b 78 10          	mov    0x10(%rax),%rdi
  8004201b59:	48 89 7c 24 10       	mov    %rdi,0x10(%rsp)
  8004201b5e:	48 8b 78 18          	mov    0x18(%rax),%rdi
  8004201b62:	48 89 7c 24 18       	mov    %rdi,0x18(%rsp)
  8004201b67:	48 8b 78 20          	mov    0x20(%rax),%rdi
  8004201b6b:	48 89 7c 24 20       	mov    %rdi,0x20(%rsp)
  8004201b70:	48 8b 78 28          	mov    0x28(%rax),%rdi
  8004201b74:	48 89 7c 24 28       	mov    %rdi,0x28(%rsp)
  8004201b79:	48 8b 40 30          	mov    0x30(%rax),%rax
  8004201b7d:	48 89 44 24 30       	mov    %rax,0x30(%rsp)
  8004201b82:	48 89 cf             	mov    %rcx,%rdi
  8004201b85:	48 b8 c9 4c 20 04 80 	movabs $0x8004204cc9,%rax
  8004201b8c:	00 00 00 
  8004201b8f:	ff d0                	callq  *%rax
                	attr = _dwarf_attr_find(&sib, DW_AT_byte_size);
  8004201b91:	48 8d 85 b0 9e ff ff 	lea    -0x6150(%rbp),%rax
  8004201b98:	be 0b 00 00 00       	mov    $0xb,%esi
  8004201b9d:	48 89 c7             	mov    %rax,%rdi
  8004201ba0:	48 b8 cc 4d 20 04 80 	movabs $0x8004204dcc,%rax
  8004201ba7:	00 00 00 
  8004201baa:	ff d0                	callq  *%rax
  8004201bac:	48 89 45 f0          	mov    %rax,-0x10(%rbp)
        
       		        if(attr != NULL)
  8004201bb0:	48 83 7d f0 00       	cmpq   $0x0,-0x10(%rbp)
  8004201bb5:	74 0c                	je     8004201bc3 <list_func_die+0x4c7>
                	{
                    	ret_val = attr->u[0].u64;
  8004201bb7:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8004201bbb:	48 8b 40 28          	mov    0x28(%rax),%rax
  8004201bbf:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
                	}
            	}
	
				info->size_fn_arg[info->rip_fn_narg]=ret_val;// _get_arg_size(ret);
  8004201bc3:	48 8b 85 a8 9e ff ff 	mov    -0x6158(%rbp),%rax
  8004201bca:	8b 48 28             	mov    0x28(%rax),%ecx
  8004201bcd:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8004201bd1:	89 c2                	mov    %eax,%edx
  8004201bd3:	48 8b 85 a8 9e ff ff 	mov    -0x6158(%rbp),%rax
  8004201bda:	48 63 c9             	movslq %ecx,%rcx
  8004201bdd:	48 83 c1 08          	add    $0x8,%rcx
  8004201be1:	89 54 88 0c          	mov    %edx,0xc(%rax,%rcx,4)
				info->rip_fn_narg++;
  8004201be5:	48 8b 85 a8 9e ff ff 	mov    -0x6158(%rbp),%rax
  8004201bec:	8b 40 28             	mov    0x28(%rax),%eax
  8004201bef:	8d 50 01             	lea    0x1(%rax),%edx
  8004201bf2:	48 8b 85 a8 9e ff ff 	mov    -0x6158(%rbp),%rax
  8004201bf9:	89 50 28             	mov    %edx,0x28(%rax)
				sib = ret; 
  8004201bfc:	48 8d 85 b0 9e ff ff 	lea    -0x6150(%rbp),%rax
  8004201c03:	48 8d 8d 20 cf ff ff 	lea    -0x30e0(%rbp),%rcx
  8004201c0a:	ba 70 30 00 00       	mov    $0x3070,%edx
  8004201c0f:	48 89 ce             	mov    %rcx,%rsi
  8004201c12:	48 89 c7             	mov    %rax,%rdi
  8004201c15:	48 b8 fd 2f 20 04 80 	movabs $0x8004202ffd,%rax
  8004201c1c:	00 00 00 
  8004201c1f:	ff d0                	callq  *%rax
			}
			info->size_fn_arg[info->rip_fn_narg] = ret_val;
			info->rip_fn_narg++;
			sib = ret; 

			while(dwarf_siblingof(dbg, &sib, &ret, cu) == DW_DLV_OK)	
  8004201c21:	48 b8 c8 b5 21 04 80 	movabs $0x800421b5c8,%rax
  8004201c28:	00 00 00 
  8004201c2b:	48 8b 00             	mov    (%rax),%rax
  8004201c2e:	48 8b 4d e8          	mov    -0x18(%rbp),%rcx
  8004201c32:	48 8d 95 20 cf ff ff 	lea    -0x30e0(%rbp),%rdx
  8004201c39:	48 8d b5 b0 9e ff ff 	lea    -0x6150(%rbp),%rsi
  8004201c40:	48 89 c7             	mov    %rax,%rdi
  8004201c43:	48 b8 5f 4e 20 04 80 	movabs $0x8004204e5f,%rax
  8004201c4a:	00 00 00 
  8004201c4d:	ff d0                	callq  *%rax
  8004201c4f:	85 c0                	test   %eax,%eax
  8004201c51:	0f 84 80 fe ff ff    	je     8004201ad7 <list_func_die+0x3db>
  8004201c57:	eb 04                	jmp    8004201c5d <list_func_die+0x561>
		Dwarf_Attribute* attr;

		if(dwarf_child(dbg, cu, &sib, &ret) != DW_DLE_NO_ENTRY)
		{
			if(ret.die_tag != DW_TAG_formal_parameter)
				goto last;
  8004201c59:	90                   	nop
  8004201c5a:	eb 01                	jmp    8004201c5d <list_func_die+0x561>
			sib = ret; 

			while(dwarf_siblingof(dbg, &sib, &ret, cu) == DW_DLV_OK)	
			{
				if(ret.die_tag != DW_TAG_formal_parameter)
					break;
  8004201c5c:	90                   	nop
				info->rip_fn_narg++;
				sib = ret; 
			}
		}
last:	
		return 1;
  8004201c5d:	b8 01 00 00 00       	mov    $0x1,%eax
  8004201c62:	eb 05                	jmp    8004201c69 <list_func_die+0x56d>
	}

	return 0;
  8004201c64:	b8 00 00 00 00       	mov    $0x0,%eax
}
  8004201c69:	c9                   	leaveq 
  8004201c6a:	c3                   	retq   

0000008004201c6b <debuginfo_rip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_rip(uintptr_t addr, struct Ripdebuginfo *info)
{
  8004201c6b:	55                   	push   %rbp
  8004201c6c:	48 89 e5             	mov    %rsp,%rbp
  8004201c6f:	48 81 ec c0 91 00 00 	sub    $0x91c0,%rsp
  8004201c76:	48 89 bd 48 6e ff ff 	mov    %rdi,-0x91b8(%rbp)
  8004201c7d:	48 89 b5 40 6e ff ff 	mov    %rsi,-0x91c0(%rbp)
    static struct Env* lastenv = NULL;
    void* elf;    
    Dwarf_Section *sect;
    Dwarf_CU cu;
    Dwarf_Die die, cudie, die2;
    Dwarf_Regtable *rt = NULL;
  8004201c84:	48 c7 45 f8 00 00 00 	movq   $0x0,-0x8(%rbp)
  8004201c8b:	00 
    //Set up initial pc
    uint64_t pc  = (uintptr_t)addr;
  8004201c8c:	48 8b 85 48 6e ff ff 	mov    -0x91b8(%rbp),%rax
  8004201c93:	48 89 45 f0          	mov    %rax,-0x10(%rbp)

    
    // Initialize *info
    info->rip_file = "<unknown>";
  8004201c97:	48 8b 85 40 6e ff ff 	mov    -0x91c0(%rbp),%rax
  8004201c9e:	48 ba c7 99 20 04 80 	movabs $0x80042099c7,%rdx
  8004201ca5:	00 00 00 
  8004201ca8:	48 89 10             	mov    %rdx,(%rax)
    info->rip_line = 0;
  8004201cab:	48 8b 85 40 6e ff ff 	mov    -0x91c0(%rbp),%rax
  8004201cb2:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%rax)
    info->rip_fn_name = "<unknown>";
  8004201cb9:	48 8b 85 40 6e ff ff 	mov    -0x91c0(%rbp),%rax
  8004201cc0:	48 ba c7 99 20 04 80 	movabs $0x80042099c7,%rdx
  8004201cc7:	00 00 00 
  8004201cca:	48 89 50 10          	mov    %rdx,0x10(%rax)
    info->rip_fn_namelen = 9;
  8004201cce:	48 8b 85 40 6e ff ff 	mov    -0x91c0(%rbp),%rax
  8004201cd5:	c7 40 18 09 00 00 00 	movl   $0x9,0x18(%rax)
    info->rip_fn_addr = addr;
  8004201cdc:	48 8b 85 40 6e ff ff 	mov    -0x91c0(%rbp),%rax
  8004201ce3:	48 8b 95 48 6e ff ff 	mov    -0x91b8(%rbp),%rdx
  8004201cea:	48 89 50 20          	mov    %rdx,0x20(%rax)
    info->rip_fn_narg = 0;
  8004201cee:	48 8b 85 40 6e ff ff 	mov    -0x91c0(%rbp),%rax
  8004201cf5:	c7 40 28 00 00 00 00 	movl   $0x0,0x28(%rax)
    
    // Find the relevant set of stabs
    if (addr >= ULIM) {
  8004201cfc:	48 b8 ff ff bf 03 80 	movabs $0x8003bfffff,%rax
  8004201d03:	00 00 00 
  8004201d06:	48 39 85 48 6e ff ff 	cmp    %rax,-0x91b8(%rbp)
  8004201d0d:	0f 86 95 00 00 00    	jbe    8004201da8 <debuginfo_rip+0x13d>
	    elf = (void *)0x10000 + KERNBASE;
  8004201d13:	c7 45 e8 00 00 01 04 	movl   $0x4010000,-0x18(%rbp)
  8004201d1a:	c7 45 ec 80 00 00 00 	movl   $0x80,-0x14(%rbp)
	    // Can't search for user-level addresses yet!
	    panic("User address");
    }
    
    
    _dwarf_init(dbg, elf);
  8004201d21:	48 b8 c8 b5 21 04 80 	movabs $0x800421b5c8,%rax
  8004201d28:	00 00 00 
  8004201d2b:	48 8b 00             	mov    (%rax),%rax
  8004201d2e:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  8004201d32:	48 89 d6             	mov    %rdx,%rsi
  8004201d35:	48 89 c7             	mov    %rax,%rdi
  8004201d38:	48 b8 9e 3c 20 04 80 	movabs $0x8004203c9e,%rax
  8004201d3f:	00 00 00 
  8004201d42:	ff d0                	callq  *%rax

    sect = _dwarf_find_section(".debug_info");	
  8004201d44:	48 bf d1 99 20 04 80 	movabs $0x80042099d1,%rdi
  8004201d4b:	00 00 00 
  8004201d4e:	48 b8 e8 85 20 04 80 	movabs $0x80042085e8,%rax
  8004201d55:	00 00 00 
  8004201d58:	ff d0                	callq  *%rax
  8004201d5a:	48 89 45 e0          	mov    %rax,-0x20(%rbp)
    dbg->dbg_info_offset_elf = (uint64_t)sect->ds_data; 
  8004201d5e:	48 b8 c8 b5 21 04 80 	movabs $0x800421b5c8,%rax
  8004201d65:	00 00 00 
  8004201d68:	48 8b 00             	mov    (%rax),%rax
  8004201d6b:	48 8b 55 e0          	mov    -0x20(%rbp),%rdx
  8004201d6f:	48 8b 52 08          	mov    0x8(%rdx),%rdx
  8004201d73:	48 89 50 08          	mov    %rdx,0x8(%rax)
    dbg->dbg_info_size = sect->ds_size;
  8004201d77:	48 b8 c8 b5 21 04 80 	movabs $0x800421b5c8,%rax
  8004201d7e:	00 00 00 
  8004201d81:	48 8b 00             	mov    (%rax),%rax
  8004201d84:	48 8b 55 e0          	mov    -0x20(%rbp),%rdx
  8004201d88:	48 8b 52 18          	mov    0x18(%rdx),%rdx
  8004201d8c:	48 89 50 10          	mov    %rdx,0x10(%rax)
    
    assert(dbg->dbg_info_size);
  8004201d90:	48 b8 c8 b5 21 04 80 	movabs $0x800421b5c8,%rax
  8004201d97:	00 00 00 
  8004201d9a:	48 8b 00             	mov    (%rax),%rax
  8004201d9d:	48 8b 40 10          	mov    0x10(%rax),%rax
  8004201da1:	48 85 c0             	test   %rax,%rax
  8004201da4:	74 2c                	je     8004201dd2 <debuginfo_rip+0x167>
  8004201da6:	eb 5f                	jmp    8004201e07 <debuginfo_rip+0x19c>
    // Find the relevant set of stabs
    if (addr >= ULIM) {
	    elf = (void *)0x10000 + KERNBASE;
    } else {
	    // Can't search for user-level addresses yet!
	    panic("User address");
  8004201da8:	48 ba dd 99 20 04 80 	movabs $0x80042099dd,%rdx
  8004201daf:	00 00 00 
  8004201db2:	be cd 00 00 00       	mov    $0xcd,%esi
  8004201db7:	48 bf b9 99 20 04 80 	movabs $0x80042099b9,%rdi
  8004201dbe:	00 00 00 
  8004201dc1:	b8 00 00 00 00       	mov    $0x0,%eax
  8004201dc6:	48 b9 9b 01 20 04 80 	movabs $0x800420019b,%rcx
  8004201dcd:	00 00 00 
  8004201dd0:	ff d1                	callq  *%rcx

    sect = _dwarf_find_section(".debug_info");	
    dbg->dbg_info_offset_elf = (uint64_t)sect->ds_data; 
    dbg->dbg_info_size = sect->ds_size;
    
    assert(dbg->dbg_info_size);
  8004201dd2:	48 b9 ea 99 20 04 80 	movabs $0x80042099ea,%rcx
  8004201dd9:	00 00 00 
  8004201ddc:	48 ba a4 99 20 04 80 	movabs $0x80042099a4,%rdx
  8004201de3:	00 00 00 
  8004201de6:	be d7 00 00 00       	mov    $0xd7,%esi
  8004201deb:	48 bf b9 99 20 04 80 	movabs $0x80042099b9,%rdi
  8004201df2:	00 00 00 
  8004201df5:	b8 00 00 00 00       	mov    $0x0,%eax
  8004201dfa:	49 b8 9b 01 20 04 80 	movabs $0x800420019b,%r8
  8004201e01:	00 00 00 
  8004201e04:	41 ff d0             	callq  *%r8
    while(_get_next_cu(dbg, &cu) == 0)
  8004201e07:	e9 46 01 00 00       	jmpq   8004201f52 <debuginfo_rip+0x2e7>
    {
	    if(dwarf_siblingof(dbg, NULL, &cudie, &cu) == DW_DLE_NO_ENTRY)
  8004201e0c:	48 b8 c8 b5 21 04 80 	movabs $0x800421b5c8,%rax
  8004201e13:	00 00 00 
  8004201e16:	48 8b 00             	mov    (%rax),%rax
  8004201e19:	48 8d 4d a0          	lea    -0x60(%rbp),%rcx
  8004201e1d:	48 8d 95 c0 9e ff ff 	lea    -0x6140(%rbp),%rdx
  8004201e24:	be 00 00 00 00       	mov    $0x0,%esi
  8004201e29:	48 89 c7             	mov    %rax,%rdi
  8004201e2c:	48 b8 5f 4e 20 04 80 	movabs $0x8004204e5f,%rax
  8004201e33:	00 00 00 
  8004201e36:	ff d0                	callq  *%rax
  8004201e38:	83 f8 04             	cmp    $0x4,%eax
  8004201e3b:	0f 84 0a 01 00 00    	je     8004201f4b <debuginfo_rip+0x2e0>
	    {
		    continue;
	    }	
	    cudie.cu_header = &cu;
  8004201e41:	48 8d 45 a0          	lea    -0x60(%rbp),%rax
  8004201e45:	48 89 85 20 a2 ff ff 	mov    %rax,-0x5de0(%rbp)
	    cudie.cu_die = NULL;
  8004201e4c:	48 c7 85 28 a2 ff ff 	movq   $0x0,-0x5dd8(%rbp)
  8004201e53:	00 00 00 00 
	    
	    if(dwarf_child(dbg, &cu, &cudie, &die) == DW_DLE_NO_ENTRY)
  8004201e57:	48 b8 c8 b5 21 04 80 	movabs $0x800421b5c8,%rax
  8004201e5e:	00 00 00 
  8004201e61:	48 8b 00             	mov    (%rax),%rax
  8004201e64:	48 8d 8d 30 cf ff ff 	lea    -0x30d0(%rbp),%rcx
  8004201e6b:	48 8d 95 c0 9e ff ff 	lea    -0x6140(%rbp),%rdx
  8004201e72:	48 8d 75 a0          	lea    -0x60(%rbp),%rsi
  8004201e76:	48 89 c7             	mov    %rax,%rdi
  8004201e79:	48 b8 a3 50 20 04 80 	movabs $0x80042050a3,%rax
  8004201e80:	00 00 00 
  8004201e83:	ff d0                	callq  *%rax
  8004201e85:	83 f8 04             	cmp    $0x4,%eax
  8004201e88:	0f 84 c0 00 00 00    	je     8004201f4e <debuginfo_rip+0x2e3>
	    {
		    continue;
	    }	
	    die.cu_header = &cu;
  8004201e8e:	48 8d 45 a0          	lea    -0x60(%rbp),%rax
  8004201e92:	48 89 85 90 d2 ff ff 	mov    %rax,-0x2d70(%rbp)
	    die.cu_die = &cudie;
  8004201e99:	48 8d 85 c0 9e ff ff 	lea    -0x6140(%rbp),%rax
  8004201ea0:	48 89 85 98 d2 ff ff 	mov    %rax,-0x2d68(%rbp)
	    while(1)
	    {
		    if(list_func_die(info, &die, addr))
  8004201ea7:	48 8b 95 48 6e ff ff 	mov    -0x91b8(%rbp),%rdx
  8004201eae:	48 8d 8d 30 cf ff ff 	lea    -0x30d0(%rbp),%rcx
  8004201eb5:	48 8b 85 40 6e ff ff 	mov    -0x91c0(%rbp),%rax
  8004201ebc:	48 89 ce             	mov    %rcx,%rsi
  8004201ebf:	48 89 c7             	mov    %rax,%rdi
  8004201ec2:	48 b8 fc 16 20 04 80 	movabs $0x80042016fc,%rax
  8004201ec9:	00 00 00 
  8004201ecc:	ff d0                	callq  *%rax
  8004201ece:	85 c0                	test   %eax,%eax
  8004201ed0:	0f 85 ae 00 00 00    	jne    8004201f84 <debuginfo_rip+0x319>
			    goto find_done;
		    if(dwarf_siblingof(dbg, &die, &die2, &cu) < 0)
  8004201ed6:	48 b8 c8 b5 21 04 80 	movabs $0x800421b5c8,%rax
  8004201edd:	00 00 00 
  8004201ee0:	48 8b 00             	mov    (%rax),%rax
  8004201ee3:	48 8d 4d a0          	lea    -0x60(%rbp),%rcx
  8004201ee7:	48 8d 95 50 6e ff ff 	lea    -0x91b0(%rbp),%rdx
  8004201eee:	48 8d b5 30 cf ff ff 	lea    -0x30d0(%rbp),%rsi
  8004201ef5:	48 89 c7             	mov    %rax,%rdi
  8004201ef8:	48 b8 5f 4e 20 04 80 	movabs $0x8004204e5f,%rax
  8004201eff:	00 00 00 
  8004201f02:	ff d0                	callq  *%rax
  8004201f04:	85 c0                	test   %eax,%eax
  8004201f06:	78 49                	js     8004201f51 <debuginfo_rip+0x2e6>
			    break; 
		    die = die2;
  8004201f08:	48 8d 85 30 cf ff ff 	lea    -0x30d0(%rbp),%rax
  8004201f0f:	48 8d 8d 50 6e ff ff 	lea    -0x91b0(%rbp),%rcx
  8004201f16:	ba 70 30 00 00       	mov    $0x3070,%edx
  8004201f1b:	48 89 ce             	mov    %rcx,%rsi
  8004201f1e:	48 89 c7             	mov    %rax,%rdi
  8004201f21:	48 b8 fd 2f 20 04 80 	movabs $0x8004202ffd,%rax
  8004201f28:	00 00 00 
  8004201f2b:	ff d0                	callq  *%rax
		    die.cu_header = &cu;
  8004201f2d:	48 8d 45 a0          	lea    -0x60(%rbp),%rax
  8004201f31:	48 89 85 90 d2 ff ff 	mov    %rax,-0x2d70(%rbp)
		    die.cu_die = &cudie;
  8004201f38:	48 8d 85 c0 9e ff ff 	lea    -0x6140(%rbp),%rax
  8004201f3f:	48 89 85 98 d2 ff ff 	mov    %rax,-0x2d68(%rbp)
	    }
  8004201f46:	e9 5c ff ff ff       	jmpq   8004201ea7 <debuginfo_rip+0x23c>
    assert(dbg->dbg_info_size);
    while(_get_next_cu(dbg, &cu) == 0)
    {
	    if(dwarf_siblingof(dbg, NULL, &cudie, &cu) == DW_DLE_NO_ENTRY)
	    {
		    continue;
  8004201f4b:	90                   	nop
  8004201f4c:	eb 04                	jmp    8004201f52 <debuginfo_rip+0x2e7>
	    cudie.cu_header = &cu;
	    cudie.cu_die = NULL;
	    
	    if(dwarf_child(dbg, &cu, &cudie, &die) == DW_DLE_NO_ENTRY)
	    {
		    continue;
  8004201f4e:	90                   	nop
  8004201f4f:	eb 01                	jmp    8004201f52 <debuginfo_rip+0x2e7>
	    while(1)
	    {
		    if(list_func_die(info, &die, addr))
			    goto find_done;
		    if(dwarf_siblingof(dbg, &die, &die2, &cu) < 0)
			    break; 
  8004201f51:	90                   	nop
    sect = _dwarf_find_section(".debug_info");	
    dbg->dbg_info_offset_elf = (uint64_t)sect->ds_data; 
    dbg->dbg_info_size = sect->ds_size;
    
    assert(dbg->dbg_info_size);
    while(_get_next_cu(dbg, &cu) == 0)
  8004201f52:	48 b8 c8 b5 21 04 80 	movabs $0x800421b5c8,%rax
  8004201f59:	00 00 00 
  8004201f5c:	48 8b 00             	mov    (%rax),%rax
  8004201f5f:	48 8d 55 a0          	lea    -0x60(%rbp),%rdx
  8004201f63:	48 89 d6             	mov    %rdx,%rsi
  8004201f66:	48 89 c7             	mov    %rax,%rdi
  8004201f69:	48 b8 7a 3d 20 04 80 	movabs $0x8004203d7a,%rax
  8004201f70:	00 00 00 
  8004201f73:	ff d0                	callq  *%rax
  8004201f75:	85 c0                	test   %eax,%eax
  8004201f77:	0f 84 8f fe ff ff    	je     8004201e0c <debuginfo_rip+0x1a1>
		    die.cu_header = &cu;
		    die.cu_die = &cudie;
	    }
    }
    
    return -1;
  8004201f7d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  8004201f82:	eb 06                	jmp    8004201f8a <debuginfo_rip+0x31f>
	    die.cu_header = &cu;
	    die.cu_die = &cudie;
	    while(1)
	    {
		    if(list_func_die(info, &die, addr))
			    goto find_done;
  8004201f84:	90                   	nop
    }
    
    return -1;

find_done:
    return 0;
  8004201f85:	b8 00 00 00 00       	mov    $0x0,%eax

}
  8004201f8a:	c9                   	leaveq 
  8004201f8b:	c3                   	retq   

0000008004201f8c <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
  8004201f8c:	55                   	push   %rbp
  8004201f8d:	48 89 e5             	mov    %rsp,%rbp
  8004201f90:	48 83 ec 30          	sub    $0x30,%rsp
  8004201f94:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
  8004201f98:	48 89 75 f0          	mov    %rsi,-0x10(%rbp)
  8004201f9c:	48 89 55 e8          	mov    %rdx,-0x18(%rbp)
  8004201fa0:	89 4d e4             	mov    %ecx,-0x1c(%rbp)
  8004201fa3:	44 89 45 e0          	mov    %r8d,-0x20(%rbp)
  8004201fa7:	44 89 4d dc          	mov    %r9d,-0x24(%rbp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
  8004201fab:	8b 45 e4             	mov    -0x1c(%rbp),%eax
  8004201fae:	48 3b 45 e8          	cmp    -0x18(%rbp),%rax
  8004201fb2:	77 52                	ja     8004202006 <printnum+0x7a>
		printnum(putch, putdat, num / base, base, width - 1, padc);
  8004201fb4:	8b 45 e0             	mov    -0x20(%rbp),%eax
  8004201fb7:	44 8d 40 ff          	lea    -0x1(%rax),%r8d
  8004201fbb:	8b 55 e4             	mov    -0x1c(%rbp),%edx
  8004201fbe:	48 89 55 d0          	mov    %rdx,-0x30(%rbp)
  8004201fc2:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004201fc6:	ba 00 00 00 00       	mov    $0x0,%edx
  8004201fcb:	48 f7 75 d0          	divq   -0x30(%rbp)
  8004201fcf:	48 89 c2             	mov    %rax,%rdx
  8004201fd2:	8b 7d dc             	mov    -0x24(%rbp),%edi
  8004201fd5:	8b 4d e4             	mov    -0x1c(%rbp),%ecx
  8004201fd8:	48 8b 75 f0          	mov    -0x10(%rbp),%rsi
  8004201fdc:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8004201fe0:	41 89 f9             	mov    %edi,%r9d
  8004201fe3:	48 89 c7             	mov    %rax,%rdi
  8004201fe6:	48 b8 8c 1f 20 04 80 	movabs $0x8004201f8c,%rax
  8004201fed:	00 00 00 
  8004201ff0:	ff d0                	callq  *%rax
  8004201ff2:	eb 1c                	jmp    8004202010 <printnum+0x84>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
  8004201ff4:	48 8b 55 f0          	mov    -0x10(%rbp),%rdx
  8004201ff8:	8b 45 dc             	mov    -0x24(%rbp),%eax
  8004201ffb:	48 8b 4d f8          	mov    -0x8(%rbp),%rcx
  8004201fff:	48 89 d6             	mov    %rdx,%rsi
  8004202002:	89 c7                	mov    %eax,%edi
  8004202004:	ff d1                	callq  *%rcx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  8004202006:	83 6d e0 01          	subl   $0x1,-0x20(%rbp)
  800420200a:	83 7d e0 00          	cmpl   $0x0,-0x20(%rbp)
  800420200e:	7f e4                	jg     8004201ff4 <printnum+0x68>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
  8004202010:	8b 4d e4             	mov    -0x1c(%rbp),%ecx
  8004202013:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004202017:	ba 00 00 00 00       	mov    $0x0,%edx
  800420201c:	48 f7 f1             	div    %rcx
  800420201f:	48 89 d0             	mov    %rdx,%rax
  8004202022:	48 ba c0 9a 20 04 80 	movabs $0x8004209ac0,%rdx
  8004202029:	00 00 00 
  800420202c:	0f b6 04 02          	movzbl (%rdx,%rax,1),%eax
  8004202030:	0f be c0             	movsbl %al,%eax
  8004202033:	48 8b 55 f0          	mov    -0x10(%rbp),%rdx
  8004202037:	48 8b 4d f8          	mov    -0x8(%rbp),%rcx
  800420203b:	48 89 d6             	mov    %rdx,%rsi
  800420203e:	89 c7                	mov    %eax,%edi
  8004202040:	ff d1                	callq  *%rcx
}
  8004202042:	c9                   	leaveq 
  8004202043:	c3                   	retq   

0000008004202044 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
  8004202044:	55                   	push   %rbp
  8004202045:	48 89 e5             	mov    %rsp,%rbp
  8004202048:	48 83 ec 20          	sub    $0x20,%rsp
  800420204c:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
  8004202050:	89 75 e4             	mov    %esi,-0x1c(%rbp)
	unsigned long long x;    
	if (lflag >= 2)
  8004202053:	83 7d e4 01          	cmpl   $0x1,-0x1c(%rbp)
  8004202057:	7e 52                	jle    80042020ab <getuint+0x67>
		x= va_arg(*ap, unsigned long long);
  8004202059:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  800420205d:	8b 00                	mov    (%rax),%eax
  800420205f:	83 f8 30             	cmp    $0x30,%eax
  8004202062:	73 24                	jae    8004202088 <getuint+0x44>
  8004202064:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004202068:	48 8b 50 10          	mov    0x10(%rax),%rdx
  800420206c:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004202070:	8b 00                	mov    (%rax),%eax
  8004202072:	89 c0                	mov    %eax,%eax
  8004202074:	48 01 d0             	add    %rdx,%rax
  8004202077:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  800420207b:	8b 12                	mov    (%rdx),%edx
  800420207d:	8d 4a 08             	lea    0x8(%rdx),%ecx
  8004202080:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  8004202084:	89 0a                	mov    %ecx,(%rdx)
  8004202086:	eb 17                	jmp    800420209f <getuint+0x5b>
  8004202088:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  800420208c:	48 8b 50 08          	mov    0x8(%rax),%rdx
  8004202090:	48 89 d0             	mov    %rdx,%rax
  8004202093:	48 8d 4a 08          	lea    0x8(%rdx),%rcx
  8004202097:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  800420209b:	48 89 4a 08          	mov    %rcx,0x8(%rdx)
  800420209f:	48 8b 00             	mov    (%rax),%rax
  80042020a2:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
  80042020a6:	e9 a3 00 00 00       	jmpq   800420214e <getuint+0x10a>
	else if (lflag)
  80042020ab:	83 7d e4 00          	cmpl   $0x0,-0x1c(%rbp)
  80042020af:	74 4f                	je     8004202100 <getuint+0xbc>
		x= va_arg(*ap, unsigned long);
  80042020b1:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  80042020b5:	8b 00                	mov    (%rax),%eax
  80042020b7:	83 f8 30             	cmp    $0x30,%eax
  80042020ba:	73 24                	jae    80042020e0 <getuint+0x9c>
  80042020bc:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  80042020c0:	48 8b 50 10          	mov    0x10(%rax),%rdx
  80042020c4:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  80042020c8:	8b 00                	mov    (%rax),%eax
  80042020ca:	89 c0                	mov    %eax,%eax
  80042020cc:	48 01 d0             	add    %rdx,%rax
  80042020cf:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  80042020d3:	8b 12                	mov    (%rdx),%edx
  80042020d5:	8d 4a 08             	lea    0x8(%rdx),%ecx
  80042020d8:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  80042020dc:	89 0a                	mov    %ecx,(%rdx)
  80042020de:	eb 17                	jmp    80042020f7 <getuint+0xb3>
  80042020e0:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  80042020e4:	48 8b 50 08          	mov    0x8(%rax),%rdx
  80042020e8:	48 89 d0             	mov    %rdx,%rax
  80042020eb:	48 8d 4a 08          	lea    0x8(%rdx),%rcx
  80042020ef:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  80042020f3:	48 89 4a 08          	mov    %rcx,0x8(%rdx)
  80042020f7:	48 8b 00             	mov    (%rax),%rax
  80042020fa:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
  80042020fe:	eb 4e                	jmp    800420214e <getuint+0x10a>
	else
		x= va_arg(*ap, unsigned int);
  8004202100:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004202104:	8b 00                	mov    (%rax),%eax
  8004202106:	83 f8 30             	cmp    $0x30,%eax
  8004202109:	73 24                	jae    800420212f <getuint+0xeb>
  800420210b:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  800420210f:	48 8b 50 10          	mov    0x10(%rax),%rdx
  8004202113:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004202117:	8b 00                	mov    (%rax),%eax
  8004202119:	89 c0                	mov    %eax,%eax
  800420211b:	48 01 d0             	add    %rdx,%rax
  800420211e:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  8004202122:	8b 12                	mov    (%rdx),%edx
  8004202124:	8d 4a 08             	lea    0x8(%rdx),%ecx
  8004202127:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  800420212b:	89 0a                	mov    %ecx,(%rdx)
  800420212d:	eb 17                	jmp    8004202146 <getuint+0x102>
  800420212f:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004202133:	48 8b 50 08          	mov    0x8(%rax),%rdx
  8004202137:	48 89 d0             	mov    %rdx,%rax
  800420213a:	48 8d 4a 08          	lea    0x8(%rdx),%rcx
  800420213e:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  8004202142:	48 89 4a 08          	mov    %rcx,0x8(%rdx)
  8004202146:	8b 00                	mov    (%rax),%eax
  8004202148:	89 c0                	mov    %eax,%eax
  800420214a:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
	return x;
  800420214e:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
}
  8004202152:	c9                   	leaveq 
  8004202153:	c3                   	retq   

0000008004202154 <getint>:

// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
  8004202154:	55                   	push   %rbp
  8004202155:	48 89 e5             	mov    %rsp,%rbp
  8004202158:	48 83 ec 20          	sub    $0x20,%rsp
  800420215c:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
  8004202160:	89 75 e4             	mov    %esi,-0x1c(%rbp)
	long long x;
	if (lflag >= 2)
  8004202163:	83 7d e4 01          	cmpl   $0x1,-0x1c(%rbp)
  8004202167:	7e 52                	jle    80042021bb <getint+0x67>
		x=va_arg(*ap, long long);
  8004202169:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  800420216d:	8b 00                	mov    (%rax),%eax
  800420216f:	83 f8 30             	cmp    $0x30,%eax
  8004202172:	73 24                	jae    8004202198 <getint+0x44>
  8004202174:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004202178:	48 8b 50 10          	mov    0x10(%rax),%rdx
  800420217c:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004202180:	8b 00                	mov    (%rax),%eax
  8004202182:	89 c0                	mov    %eax,%eax
  8004202184:	48 01 d0             	add    %rdx,%rax
  8004202187:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  800420218b:	8b 12                	mov    (%rdx),%edx
  800420218d:	8d 4a 08             	lea    0x8(%rdx),%ecx
  8004202190:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  8004202194:	89 0a                	mov    %ecx,(%rdx)
  8004202196:	eb 17                	jmp    80042021af <getint+0x5b>
  8004202198:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  800420219c:	48 8b 50 08          	mov    0x8(%rax),%rdx
  80042021a0:	48 89 d0             	mov    %rdx,%rax
  80042021a3:	48 8d 4a 08          	lea    0x8(%rdx),%rcx
  80042021a7:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  80042021ab:	48 89 4a 08          	mov    %rcx,0x8(%rdx)
  80042021af:	48 8b 00             	mov    (%rax),%rax
  80042021b2:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
  80042021b6:	e9 a3 00 00 00       	jmpq   800420225e <getint+0x10a>
	else if (lflag)
  80042021bb:	83 7d e4 00          	cmpl   $0x0,-0x1c(%rbp)
  80042021bf:	74 4f                	je     8004202210 <getint+0xbc>
		x=va_arg(*ap, long);
  80042021c1:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  80042021c5:	8b 00                	mov    (%rax),%eax
  80042021c7:	83 f8 30             	cmp    $0x30,%eax
  80042021ca:	73 24                	jae    80042021f0 <getint+0x9c>
  80042021cc:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  80042021d0:	48 8b 50 10          	mov    0x10(%rax),%rdx
  80042021d4:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  80042021d8:	8b 00                	mov    (%rax),%eax
  80042021da:	89 c0                	mov    %eax,%eax
  80042021dc:	48 01 d0             	add    %rdx,%rax
  80042021df:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  80042021e3:	8b 12                	mov    (%rdx),%edx
  80042021e5:	8d 4a 08             	lea    0x8(%rdx),%ecx
  80042021e8:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  80042021ec:	89 0a                	mov    %ecx,(%rdx)
  80042021ee:	eb 17                	jmp    8004202207 <getint+0xb3>
  80042021f0:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  80042021f4:	48 8b 50 08          	mov    0x8(%rax),%rdx
  80042021f8:	48 89 d0             	mov    %rdx,%rax
  80042021fb:	48 8d 4a 08          	lea    0x8(%rdx),%rcx
  80042021ff:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  8004202203:	48 89 4a 08          	mov    %rcx,0x8(%rdx)
  8004202207:	48 8b 00             	mov    (%rax),%rax
  800420220a:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
  800420220e:	eb 4e                	jmp    800420225e <getint+0x10a>
	else
		x=va_arg(*ap, int);
  8004202210:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004202214:	8b 00                	mov    (%rax),%eax
  8004202216:	83 f8 30             	cmp    $0x30,%eax
  8004202219:	73 24                	jae    800420223f <getint+0xeb>
  800420221b:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  800420221f:	48 8b 50 10          	mov    0x10(%rax),%rdx
  8004202223:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004202227:	8b 00                	mov    (%rax),%eax
  8004202229:	89 c0                	mov    %eax,%eax
  800420222b:	48 01 d0             	add    %rdx,%rax
  800420222e:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  8004202232:	8b 12                	mov    (%rdx),%edx
  8004202234:	8d 4a 08             	lea    0x8(%rdx),%ecx
  8004202237:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  800420223b:	89 0a                	mov    %ecx,(%rdx)
  800420223d:	eb 17                	jmp    8004202256 <getint+0x102>
  800420223f:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004202243:	48 8b 50 08          	mov    0x8(%rax),%rdx
  8004202247:	48 89 d0             	mov    %rdx,%rax
  800420224a:	48 8d 4a 08          	lea    0x8(%rdx),%rcx
  800420224e:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  8004202252:	48 89 4a 08          	mov    %rcx,0x8(%rdx)
  8004202256:	8b 00                	mov    (%rax),%eax
  8004202258:	48 98                	cltq   
  800420225a:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
	return x;
  800420225e:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
}
  8004202262:	c9                   	leaveq 
  8004202263:	c3                   	retq   

0000008004202264 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  8004202264:	55                   	push   %rbp
  8004202265:	48 89 e5             	mov    %rsp,%rbp
  8004202268:	41 54                	push   %r12
  800420226a:	53                   	push   %rbx
  800420226b:	48 83 ec 60          	sub    $0x60,%rsp
  800420226f:	48 89 7d a8          	mov    %rdi,-0x58(%rbp)
  8004202273:	48 89 75 a0          	mov    %rsi,-0x60(%rbp)
  8004202277:	48 89 55 98          	mov    %rdx,-0x68(%rbp)
  800420227b:	48 89 4d 90          	mov    %rcx,-0x70(%rbp)
	register int ch, err;
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;
	va_list aq;
	va_copy(aq,ap);
  800420227f:	48 8d 45 b8          	lea    -0x48(%rbp),%rax
  8004202283:	48 8b 55 90          	mov    -0x70(%rbp),%rdx
  8004202287:	48 8b 0a             	mov    (%rdx),%rcx
  800420228a:	48 89 08             	mov    %rcx,(%rax)
  800420228d:	48 8b 4a 08          	mov    0x8(%rdx),%rcx
  8004202291:	48 89 48 08          	mov    %rcx,0x8(%rax)
  8004202295:	48 8b 52 10          	mov    0x10(%rdx),%rdx
  8004202299:	48 89 50 10          	mov    %rdx,0x10(%rax)
	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  800420229d:	eb 17                	jmp    80042022b6 <vprintfmt+0x52>
			if (ch == '\0')
  800420229f:	85 db                	test   %ebx,%ebx
  80042022a1:	0f 84 d7 04 00 00    	je     800420277e <vprintfmt+0x51a>
				return;
			putch(ch, putdat);
  80042022a7:	48 8b 45 a0          	mov    -0x60(%rbp),%rax
  80042022ab:	48 8b 55 a8          	mov    -0x58(%rbp),%rdx
  80042022af:	48 89 c6             	mov    %rax,%rsi
  80042022b2:	89 df                	mov    %ebx,%edi
  80042022b4:	ff d2                	callq  *%rdx
	int base, lflag, width, precision, altflag;
	char padc;
	va_list aq;
	va_copy(aq,ap);
	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  80042022b6:	48 8b 45 98          	mov    -0x68(%rbp),%rax
  80042022ba:	0f b6 00             	movzbl (%rax),%eax
  80042022bd:	0f b6 d8             	movzbl %al,%ebx
  80042022c0:	83 fb 25             	cmp    $0x25,%ebx
  80042022c3:	0f 95 c0             	setne  %al
  80042022c6:	48 83 45 98 01       	addq   $0x1,-0x68(%rbp)
  80042022cb:	84 c0                	test   %al,%al
  80042022cd:	75 d0                	jne    800420229f <vprintfmt+0x3b>
				return;
			putch(ch, putdat);
		}

		// Process a %-escape sequence
		padc = ' ';
  80042022cf:	c6 45 d3 20          	movb   $0x20,-0x2d(%rbp)
		width = -1;
  80042022d3:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%rbp)
		precision = -1;
  80042022da:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,-0x28(%rbp)
		lflag = 0;
  80042022e1:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%rbp)
		altflag = 0;
  80042022e8:	c7 45 d4 00 00 00 00 	movl   $0x0,-0x2c(%rbp)
  80042022ef:	eb 04                	jmp    80042022f5 <vprintfmt+0x91>
			goto process_precision;

		case '.':
			if (width < 0)
				width = 0;
			goto reswitch;
  80042022f1:	90                   	nop
  80042022f2:	eb 01                	jmp    80042022f5 <vprintfmt+0x91>
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
			goto reswitch;
  80042022f4:	90                   	nop
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80042022f5:	48 8b 45 98          	mov    -0x68(%rbp),%rax
  80042022f9:	0f b6 00             	movzbl (%rax),%eax
  80042022fc:	0f b6 d8             	movzbl %al,%ebx
  80042022ff:	89 d8                	mov    %ebx,%eax
  8004202301:	48 83 45 98 01       	addq   $0x1,-0x68(%rbp)
  8004202306:	83 e8 23             	sub    $0x23,%eax
  8004202309:	83 f8 55             	cmp    $0x55,%eax
  800420230c:	0f 87 38 04 00 00    	ja     800420274a <vprintfmt+0x4e6>
  8004202312:	89 c0                	mov    %eax,%eax
  8004202314:	48 8d 14 c5 00 00 00 	lea    0x0(,%rax,8),%rdx
  800420231b:	00 
  800420231c:	48 b8 e8 9a 20 04 80 	movabs $0x8004209ae8,%rax
  8004202323:	00 00 00 
  8004202326:	48 01 d0             	add    %rdx,%rax
  8004202329:	48 8b 00             	mov    (%rax),%rax
  800420232c:	ff e0                	jmpq   *%rax

		// flag to pad on the right
		case '-':
			padc = '-';
  800420232e:	c6 45 d3 2d          	movb   $0x2d,-0x2d(%rbp)
			goto reswitch;
  8004202332:	eb c1                	jmp    80042022f5 <vprintfmt+0x91>

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
  8004202334:	c6 45 d3 30          	movb   $0x30,-0x2d(%rbp)
			goto reswitch;
  8004202338:	eb bb                	jmp    80042022f5 <vprintfmt+0x91>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
  800420233a:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%rbp)
				precision = precision * 10 + ch - '0';
  8004202341:	8b 55 d8             	mov    -0x28(%rbp),%edx
  8004202344:	89 d0                	mov    %edx,%eax
  8004202346:	c1 e0 02             	shl    $0x2,%eax
  8004202349:	01 d0                	add    %edx,%eax
  800420234b:	01 c0                	add    %eax,%eax
  800420234d:	01 d8                	add    %ebx,%eax
  800420234f:	83 e8 30             	sub    $0x30,%eax
  8004202352:	89 45 d8             	mov    %eax,-0x28(%rbp)
				ch = *fmt;
  8004202355:	48 8b 45 98          	mov    -0x68(%rbp),%rax
  8004202359:	0f b6 00             	movzbl (%rax),%eax
  800420235c:	0f be d8             	movsbl %al,%ebx
				if (ch < '0' || ch > '9')
  800420235f:	83 fb 2f             	cmp    $0x2f,%ebx
  8004202362:	7e 63                	jle    80042023c7 <vprintfmt+0x163>
  8004202364:	83 fb 39             	cmp    $0x39,%ebx
  8004202367:	7f 5e                	jg     80042023c7 <vprintfmt+0x163>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
  8004202369:	48 83 45 98 01       	addq   $0x1,-0x68(%rbp)
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
  800420236e:	eb d1                	jmp    8004202341 <vprintfmt+0xdd>
			goto process_precision;

		case '*':
			precision = va_arg(aq, int);
  8004202370:	8b 45 b8             	mov    -0x48(%rbp),%eax
  8004202373:	83 f8 30             	cmp    $0x30,%eax
  8004202376:	73 17                	jae    800420238f <vprintfmt+0x12b>
  8004202378:	48 8b 55 c8          	mov    -0x38(%rbp),%rdx
  800420237c:	8b 45 b8             	mov    -0x48(%rbp),%eax
  800420237f:	89 c0                	mov    %eax,%eax
  8004202381:	48 01 d0             	add    %rdx,%rax
  8004202384:	8b 55 b8             	mov    -0x48(%rbp),%edx
  8004202387:	83 c2 08             	add    $0x8,%edx
  800420238a:	89 55 b8             	mov    %edx,-0x48(%rbp)
  800420238d:	eb 0f                	jmp    800420239e <vprintfmt+0x13a>
  800420238f:	48 8b 55 c0          	mov    -0x40(%rbp),%rdx
  8004202393:	48 89 d0             	mov    %rdx,%rax
  8004202396:	48 83 c2 08          	add    $0x8,%rdx
  800420239a:	48 89 55 c0          	mov    %rdx,-0x40(%rbp)
  800420239e:	8b 00                	mov    (%rax),%eax
  80042023a0:	89 45 d8             	mov    %eax,-0x28(%rbp)
			goto process_precision;
  80042023a3:	eb 23                	jmp    80042023c8 <vprintfmt+0x164>

		case '.':
			if (width < 0)
  80042023a5:	83 7d dc 00          	cmpl   $0x0,-0x24(%rbp)
  80042023a9:	0f 89 42 ff ff ff    	jns    80042022f1 <vprintfmt+0x8d>
				width = 0;
  80042023af:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%rbp)
			goto reswitch;
  80042023b6:	e9 36 ff ff ff       	jmpq   80042022f1 <vprintfmt+0x8d>

		case '#':
			altflag = 1;
  80042023bb:	c7 45 d4 01 00 00 00 	movl   $0x1,-0x2c(%rbp)
			goto reswitch;
  80042023c2:	e9 2e ff ff ff       	jmpq   80042022f5 <vprintfmt+0x91>
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
			goto process_precision;
  80042023c7:	90                   	nop
		case '#':
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
  80042023c8:	83 7d dc 00          	cmpl   $0x0,-0x24(%rbp)
  80042023cc:	0f 89 22 ff ff ff    	jns    80042022f4 <vprintfmt+0x90>
				width = precision, precision = -1;
  80042023d2:	8b 45 d8             	mov    -0x28(%rbp),%eax
  80042023d5:	89 45 dc             	mov    %eax,-0x24(%rbp)
  80042023d8:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,-0x28(%rbp)
			goto reswitch;
  80042023df:	e9 10 ff ff ff       	jmpq   80042022f4 <vprintfmt+0x90>

		// long flag (doubled for long long)
		case 'l':
			lflag++;
  80042023e4:	83 45 e0 01          	addl   $0x1,-0x20(%rbp)
			goto reswitch;
  80042023e8:	e9 08 ff ff ff       	jmpq   80042022f5 <vprintfmt+0x91>

		// character
		case 'c':
			putch(va_arg(aq, int), putdat);
  80042023ed:	8b 45 b8             	mov    -0x48(%rbp),%eax
  80042023f0:	83 f8 30             	cmp    $0x30,%eax
  80042023f3:	73 17                	jae    800420240c <vprintfmt+0x1a8>
  80042023f5:	48 8b 55 c8          	mov    -0x38(%rbp),%rdx
  80042023f9:	8b 45 b8             	mov    -0x48(%rbp),%eax
  80042023fc:	89 c0                	mov    %eax,%eax
  80042023fe:	48 01 d0             	add    %rdx,%rax
  8004202401:	8b 55 b8             	mov    -0x48(%rbp),%edx
  8004202404:	83 c2 08             	add    $0x8,%edx
  8004202407:	89 55 b8             	mov    %edx,-0x48(%rbp)
  800420240a:	eb 0f                	jmp    800420241b <vprintfmt+0x1b7>
  800420240c:	48 8b 55 c0          	mov    -0x40(%rbp),%rdx
  8004202410:	48 89 d0             	mov    %rdx,%rax
  8004202413:	48 83 c2 08          	add    $0x8,%rdx
  8004202417:	48 89 55 c0          	mov    %rdx,-0x40(%rbp)
  800420241b:	8b 00                	mov    (%rax),%eax
  800420241d:	48 8b 55 a0          	mov    -0x60(%rbp),%rdx
  8004202421:	48 8b 4d a8          	mov    -0x58(%rbp),%rcx
  8004202425:	48 89 d6             	mov    %rdx,%rsi
  8004202428:	89 c7                	mov    %eax,%edi
  800420242a:	ff d1                	callq  *%rcx
			break;
  800420242c:	e9 47 03 00 00       	jmpq   8004202778 <vprintfmt+0x514>

		// error message
		case 'e':
			err = va_arg(aq, int);
  8004202431:	8b 45 b8             	mov    -0x48(%rbp),%eax
  8004202434:	83 f8 30             	cmp    $0x30,%eax
  8004202437:	73 17                	jae    8004202450 <vprintfmt+0x1ec>
  8004202439:	48 8b 55 c8          	mov    -0x38(%rbp),%rdx
  800420243d:	8b 45 b8             	mov    -0x48(%rbp),%eax
  8004202440:	89 c0                	mov    %eax,%eax
  8004202442:	48 01 d0             	add    %rdx,%rax
  8004202445:	8b 55 b8             	mov    -0x48(%rbp),%edx
  8004202448:	83 c2 08             	add    $0x8,%edx
  800420244b:	89 55 b8             	mov    %edx,-0x48(%rbp)
  800420244e:	eb 0f                	jmp    800420245f <vprintfmt+0x1fb>
  8004202450:	48 8b 55 c0          	mov    -0x40(%rbp),%rdx
  8004202454:	48 89 d0             	mov    %rdx,%rax
  8004202457:	48 83 c2 08          	add    $0x8,%rdx
  800420245b:	48 89 55 c0          	mov    %rdx,-0x40(%rbp)
  800420245f:	8b 18                	mov    (%rax),%ebx
			if (err < 0)
  8004202461:	85 db                	test   %ebx,%ebx
  8004202463:	79 02                	jns    8004202467 <vprintfmt+0x203>
				err = -err;
  8004202465:	f7 db                	neg    %ebx
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
  8004202467:	83 fb 07             	cmp    $0x7,%ebx
  800420246a:	7f 16                	jg     8004202482 <vprintfmt+0x21e>
  800420246c:	48 b8 80 9a 20 04 80 	movabs $0x8004209a80,%rax
  8004202473:	00 00 00 
  8004202476:	48 63 d3             	movslq %ebx,%rdx
  8004202479:	4c 8b 24 d0          	mov    (%rax,%rdx,8),%r12
  800420247d:	4d 85 e4             	test   %r12,%r12
  8004202480:	75 2e                	jne    80042024b0 <vprintfmt+0x24c>
				printfmt(putch, putdat, "error %d", err);
  8004202482:	48 8b 75 a0          	mov    -0x60(%rbp),%rsi
  8004202486:	48 8b 45 a8          	mov    -0x58(%rbp),%rax
  800420248a:	89 d9                	mov    %ebx,%ecx
  800420248c:	48 ba d1 9a 20 04 80 	movabs $0x8004209ad1,%rdx
  8004202493:	00 00 00 
  8004202496:	48 89 c7             	mov    %rax,%rdi
  8004202499:	b8 00 00 00 00       	mov    $0x0,%eax
  800420249e:	49 b8 88 27 20 04 80 	movabs $0x8004202788,%r8
  80042024a5:	00 00 00 
  80042024a8:	41 ff d0             	callq  *%r8
			else
				printfmt(putch, putdat, "%s", p);
			break;
  80042024ab:	e9 c8 02 00 00       	jmpq   8004202778 <vprintfmt+0x514>
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
			else
				printfmt(putch, putdat, "%s", p);
  80042024b0:	48 8b 75 a0          	mov    -0x60(%rbp),%rsi
  80042024b4:	48 8b 45 a8          	mov    -0x58(%rbp),%rax
  80042024b8:	4c 89 e1             	mov    %r12,%rcx
  80042024bb:	48 ba da 9a 20 04 80 	movabs $0x8004209ada,%rdx
  80042024c2:	00 00 00 
  80042024c5:	48 89 c7             	mov    %rax,%rdi
  80042024c8:	b8 00 00 00 00       	mov    $0x0,%eax
  80042024cd:	49 b8 88 27 20 04 80 	movabs $0x8004202788,%r8
  80042024d4:	00 00 00 
  80042024d7:	41 ff d0             	callq  *%r8
			break;
  80042024da:	e9 99 02 00 00       	jmpq   8004202778 <vprintfmt+0x514>

		// string
		case 's':
			if ((p = va_arg(aq, char *)) == NULL)
  80042024df:	8b 45 b8             	mov    -0x48(%rbp),%eax
  80042024e2:	83 f8 30             	cmp    $0x30,%eax
  80042024e5:	73 17                	jae    80042024fe <vprintfmt+0x29a>
  80042024e7:	48 8b 55 c8          	mov    -0x38(%rbp),%rdx
  80042024eb:	8b 45 b8             	mov    -0x48(%rbp),%eax
  80042024ee:	89 c0                	mov    %eax,%eax
  80042024f0:	48 01 d0             	add    %rdx,%rax
  80042024f3:	8b 55 b8             	mov    -0x48(%rbp),%edx
  80042024f6:	83 c2 08             	add    $0x8,%edx
  80042024f9:	89 55 b8             	mov    %edx,-0x48(%rbp)
  80042024fc:	eb 0f                	jmp    800420250d <vprintfmt+0x2a9>
  80042024fe:	48 8b 55 c0          	mov    -0x40(%rbp),%rdx
  8004202502:	48 89 d0             	mov    %rdx,%rax
  8004202505:	48 83 c2 08          	add    $0x8,%rdx
  8004202509:	48 89 55 c0          	mov    %rdx,-0x40(%rbp)
  800420250d:	4c 8b 20             	mov    (%rax),%r12
  8004202510:	4d 85 e4             	test   %r12,%r12
  8004202513:	75 0a                	jne    800420251f <vprintfmt+0x2bb>
				p = "(null)";
  8004202515:	49 bc dd 9a 20 04 80 	movabs $0x8004209add,%r12
  800420251c:	00 00 00 
			if (width > 0 && padc != '-')
  800420251f:	83 7d dc 00          	cmpl   $0x0,-0x24(%rbp)
  8004202523:	7e 7a                	jle    800420259f <vprintfmt+0x33b>
  8004202525:	80 7d d3 2d          	cmpb   $0x2d,-0x2d(%rbp)
  8004202529:	74 74                	je     800420259f <vprintfmt+0x33b>
				for (width -= strnlen(p, precision); width > 0; width--)
  800420252b:	8b 45 d8             	mov    -0x28(%rbp),%eax
  800420252e:	48 98                	cltq   
  8004202530:	48 89 c6             	mov    %rax,%rsi
  8004202533:	4c 89 e7             	mov    %r12,%rdi
  8004202536:	48 b8 86 2b 20 04 80 	movabs $0x8004202b86,%rax
  800420253d:	00 00 00 
  8004202540:	ff d0                	callq  *%rax
  8004202542:	29 45 dc             	sub    %eax,-0x24(%rbp)
  8004202545:	eb 17                	jmp    800420255e <vprintfmt+0x2fa>
					putch(padc, putdat);
  8004202547:	0f be 45 d3          	movsbl -0x2d(%rbp),%eax
  800420254b:	48 8b 55 a0          	mov    -0x60(%rbp),%rdx
  800420254f:	48 8b 4d a8          	mov    -0x58(%rbp),%rcx
  8004202553:	48 89 d6             	mov    %rdx,%rsi
  8004202556:	89 c7                	mov    %eax,%edi
  8004202558:	ff d1                	callq  *%rcx
		// string
		case 's':
			if ((p = va_arg(aq, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  800420255a:	83 6d dc 01          	subl   $0x1,-0x24(%rbp)
  800420255e:	83 7d dc 00          	cmpl   $0x0,-0x24(%rbp)
  8004202562:	7f e3                	jg     8004202547 <vprintfmt+0x2e3>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  8004202564:	eb 39                	jmp    800420259f <vprintfmt+0x33b>
				if (altflag && (ch < ' ' || ch > '~'))
  8004202566:	83 7d d4 00          	cmpl   $0x0,-0x2c(%rbp)
  800420256a:	74 1e                	je     800420258a <vprintfmt+0x326>
  800420256c:	83 fb 1f             	cmp    $0x1f,%ebx
  800420256f:	7e 05                	jle    8004202576 <vprintfmt+0x312>
  8004202571:	83 fb 7e             	cmp    $0x7e,%ebx
  8004202574:	7e 14                	jle    800420258a <vprintfmt+0x326>
					putch('?', putdat);
  8004202576:	48 8b 45 a0          	mov    -0x60(%rbp),%rax
  800420257a:	48 8b 55 a8          	mov    -0x58(%rbp),%rdx
  800420257e:	48 89 c6             	mov    %rax,%rsi
  8004202581:	bf 3f 00 00 00       	mov    $0x3f,%edi
  8004202586:	ff d2                	callq  *%rdx
  8004202588:	eb 0f                	jmp    8004202599 <vprintfmt+0x335>
				else
					putch(ch, putdat);
  800420258a:	48 8b 45 a0          	mov    -0x60(%rbp),%rax
  800420258e:	48 8b 55 a8          	mov    -0x58(%rbp),%rdx
  8004202592:	48 89 c6             	mov    %rax,%rsi
  8004202595:	89 df                	mov    %ebx,%edi
  8004202597:	ff d2                	callq  *%rdx
			if ((p = va_arg(aq, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  8004202599:	83 6d dc 01          	subl   $0x1,-0x24(%rbp)
  800420259d:	eb 01                	jmp    80042025a0 <vprintfmt+0x33c>
  800420259f:	90                   	nop
  80042025a0:	41 0f b6 04 24       	movzbl (%r12),%eax
  80042025a5:	0f be d8             	movsbl %al,%ebx
  80042025a8:	85 db                	test   %ebx,%ebx
  80042025aa:	0f 95 c0             	setne  %al
  80042025ad:	49 83 c4 01          	add    $0x1,%r12
  80042025b1:	84 c0                	test   %al,%al
  80042025b3:	74 28                	je     80042025dd <vprintfmt+0x379>
  80042025b5:	83 7d d8 00          	cmpl   $0x0,-0x28(%rbp)
  80042025b9:	78 ab                	js     8004202566 <vprintfmt+0x302>
  80042025bb:	83 6d d8 01          	subl   $0x1,-0x28(%rbp)
  80042025bf:	83 7d d8 00          	cmpl   $0x0,-0x28(%rbp)
  80042025c3:	79 a1                	jns    8004202566 <vprintfmt+0x302>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  80042025c5:	eb 16                	jmp    80042025dd <vprintfmt+0x379>
				putch(' ', putdat);
  80042025c7:	48 8b 45 a0          	mov    -0x60(%rbp),%rax
  80042025cb:	48 8b 55 a8          	mov    -0x58(%rbp),%rdx
  80042025cf:	48 89 c6             	mov    %rax,%rsi
  80042025d2:	bf 20 00 00 00       	mov    $0x20,%edi
  80042025d7:	ff d2                	callq  *%rdx
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  80042025d9:	83 6d dc 01          	subl   $0x1,-0x24(%rbp)
  80042025dd:	83 7d dc 00          	cmpl   $0x0,-0x24(%rbp)
  80042025e1:	7f e4                	jg     80042025c7 <vprintfmt+0x363>
				putch(' ', putdat);
			break;
  80042025e3:	e9 90 01 00 00       	jmpq   8004202778 <vprintfmt+0x514>

		// (signed) decimal
		case 'd':
			num = getint(&aq, 3);
  80042025e8:	48 8d 45 b8          	lea    -0x48(%rbp),%rax
  80042025ec:	be 03 00 00 00       	mov    $0x3,%esi
  80042025f1:	48 89 c7             	mov    %rax,%rdi
  80042025f4:	48 b8 54 21 20 04 80 	movabs $0x8004202154,%rax
  80042025fb:	00 00 00 
  80042025fe:	ff d0                	callq  *%rax
  8004202600:	48 89 45 e8          	mov    %rax,-0x18(%rbp)
			if ((long long) num < 0) {
  8004202604:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004202608:	48 85 c0             	test   %rax,%rax
  800420260b:	79 1d                	jns    800420262a <vprintfmt+0x3c6>
				putch('-', putdat);
  800420260d:	48 8b 45 a0          	mov    -0x60(%rbp),%rax
  8004202611:	48 8b 55 a8          	mov    -0x58(%rbp),%rdx
  8004202615:	48 89 c6             	mov    %rax,%rsi
  8004202618:	bf 2d 00 00 00       	mov    $0x2d,%edi
  800420261d:	ff d2                	callq  *%rdx
				num = -(long long) num;
  800420261f:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004202623:	48 f7 d8             	neg    %rax
  8004202626:	48 89 45 e8          	mov    %rax,-0x18(%rbp)
			}
			base = 10;
  800420262a:	c7 45 e4 0a 00 00 00 	movl   $0xa,-0x1c(%rbp)
			goto number;
  8004202631:	e9 d5 00 00 00       	jmpq   800420270b <vprintfmt+0x4a7>

		// unsigned decimal
		case 'u':
			num = getuint(&aq, 3);
  8004202636:	48 8d 45 b8          	lea    -0x48(%rbp),%rax
  800420263a:	be 03 00 00 00       	mov    $0x3,%esi
  800420263f:	48 89 c7             	mov    %rax,%rdi
  8004202642:	48 b8 44 20 20 04 80 	movabs $0x8004202044,%rax
  8004202649:	00 00 00 
  800420264c:	ff d0                	callq  *%rax
  800420264e:	48 89 45 e8          	mov    %rax,-0x18(%rbp)
			base = 10;
  8004202652:	c7 45 e4 0a 00 00 00 	movl   $0xa,-0x1c(%rbp)
			goto number;
  8004202659:	e9 ad 00 00 00       	jmpq   800420270b <vprintfmt+0x4a7>
		// (unsigned) octal
		case 'o':
			// Gets the variable argument with type integer from the point which was processed last by va_arg
			// calls getuint which returns a long long value, which then calls printnum which prints based on
			// base value.
			num = getuint(&aq, 3);
  800420265e:	48 8d 45 b8          	lea    -0x48(%rbp),%rax
  8004202662:	be 03 00 00 00       	mov    $0x3,%esi
  8004202667:	48 89 c7             	mov    %rax,%rdi
  800420266a:	48 b8 44 20 20 04 80 	movabs $0x8004202044,%rax
  8004202671:	00 00 00 
  8004202674:	ff d0                	callq  *%rax
  8004202676:	48 89 45 e8          	mov    %rax,-0x18(%rbp)
			base = 8;
  800420267a:	c7 45 e4 08 00 00 00 	movl   $0x8,-0x1c(%rbp)
			goto number;
  8004202681:	e9 85 00 00 00       	jmpq   800420270b <vprintfmt+0x4a7>

		// pointer
		case 'p':
			putch('0', putdat);
  8004202686:	48 8b 45 a0          	mov    -0x60(%rbp),%rax
  800420268a:	48 8b 55 a8          	mov    -0x58(%rbp),%rdx
  800420268e:	48 89 c6             	mov    %rax,%rsi
  8004202691:	bf 30 00 00 00       	mov    $0x30,%edi
  8004202696:	ff d2                	callq  *%rdx
			putch('x', putdat);
  8004202698:	48 8b 45 a0          	mov    -0x60(%rbp),%rax
  800420269c:	48 8b 55 a8          	mov    -0x58(%rbp),%rdx
  80042026a0:	48 89 c6             	mov    %rax,%rsi
  80042026a3:	bf 78 00 00 00       	mov    $0x78,%edi
  80042026a8:	ff d2                	callq  *%rdx
			num = (unsigned long long)
				(uintptr_t) va_arg(aq, void *);
  80042026aa:	8b 45 b8             	mov    -0x48(%rbp),%eax
  80042026ad:	83 f8 30             	cmp    $0x30,%eax
  80042026b0:	73 17                	jae    80042026c9 <vprintfmt+0x465>
  80042026b2:	48 8b 55 c8          	mov    -0x38(%rbp),%rdx
  80042026b6:	8b 45 b8             	mov    -0x48(%rbp),%eax
  80042026b9:	89 c0                	mov    %eax,%eax
  80042026bb:	48 01 d0             	add    %rdx,%rax
  80042026be:	8b 55 b8             	mov    -0x48(%rbp),%edx
  80042026c1:	83 c2 08             	add    $0x8,%edx
  80042026c4:	89 55 b8             	mov    %edx,-0x48(%rbp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
  80042026c7:	eb 0f                	jmp    80042026d8 <vprintfmt+0x474>
				(uintptr_t) va_arg(aq, void *);
  80042026c9:	48 8b 55 c0          	mov    -0x40(%rbp),%rdx
  80042026cd:	48 89 d0             	mov    %rdx,%rax
  80042026d0:	48 83 c2 08          	add    $0x8,%rdx
  80042026d4:	48 89 55 c0          	mov    %rdx,-0x40(%rbp)
  80042026d8:	48 8b 00             	mov    (%rax),%rax

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
  80042026db:	48 89 45 e8          	mov    %rax,-0x18(%rbp)
				(uintptr_t) va_arg(aq, void *);
			base = 16;
  80042026df:	c7 45 e4 10 00 00 00 	movl   $0x10,-0x1c(%rbp)
			goto number;
  80042026e6:	eb 23                	jmp    800420270b <vprintfmt+0x4a7>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&aq, 3);
  80042026e8:	48 8d 45 b8          	lea    -0x48(%rbp),%rax
  80042026ec:	be 03 00 00 00       	mov    $0x3,%esi
  80042026f1:	48 89 c7             	mov    %rax,%rdi
  80042026f4:	48 b8 44 20 20 04 80 	movabs $0x8004202044,%rax
  80042026fb:	00 00 00 
  80042026fe:	ff d0                	callq  *%rax
  8004202700:	48 89 45 e8          	mov    %rax,-0x18(%rbp)
			base = 16;
  8004202704:	c7 45 e4 10 00 00 00 	movl   $0x10,-0x1c(%rbp)
		number:
			printnum(putch, putdat, num, base, width, padc);
  800420270b:	44 0f be 45 d3       	movsbl -0x2d(%rbp),%r8d
  8004202710:	8b 4d e4             	mov    -0x1c(%rbp),%ecx
  8004202713:	8b 7d dc             	mov    -0x24(%rbp),%edi
  8004202716:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  800420271a:	48 8b 75 a0          	mov    -0x60(%rbp),%rsi
  800420271e:	48 8b 45 a8          	mov    -0x58(%rbp),%rax
  8004202722:	45 89 c1             	mov    %r8d,%r9d
  8004202725:	41 89 f8             	mov    %edi,%r8d
  8004202728:	48 89 c7             	mov    %rax,%rdi
  800420272b:	48 b8 8c 1f 20 04 80 	movabs $0x8004201f8c,%rax
  8004202732:	00 00 00 
  8004202735:	ff d0                	callq  *%rax
			break;
  8004202737:	eb 3f                	jmp    8004202778 <vprintfmt+0x514>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
  8004202739:	48 8b 45 a0          	mov    -0x60(%rbp),%rax
  800420273d:	48 8b 55 a8          	mov    -0x58(%rbp),%rdx
  8004202741:	48 89 c6             	mov    %rax,%rsi
  8004202744:	89 df                	mov    %ebx,%edi
  8004202746:	ff d2                	callq  *%rdx
			break;
  8004202748:	eb 2e                	jmp    8004202778 <vprintfmt+0x514>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  800420274a:	48 8b 45 a0          	mov    -0x60(%rbp),%rax
  800420274e:	48 8b 55 a8          	mov    -0x58(%rbp),%rdx
  8004202752:	48 89 c6             	mov    %rax,%rsi
  8004202755:	bf 25 00 00 00       	mov    $0x25,%edi
  800420275a:	ff d2                	callq  *%rdx
			for (fmt--; fmt[-1] != '%'; fmt--)
  800420275c:	48 83 6d 98 01       	subq   $0x1,-0x68(%rbp)
  8004202761:	eb 05                	jmp    8004202768 <vprintfmt+0x504>
  8004202763:	48 83 6d 98 01       	subq   $0x1,-0x68(%rbp)
  8004202768:	48 8b 45 98          	mov    -0x68(%rbp),%rax
  800420276c:	48 83 e8 01          	sub    $0x1,%rax
  8004202770:	0f b6 00             	movzbl (%rax),%eax
  8004202773:	3c 25                	cmp    $0x25,%al
  8004202775:	75 ec                	jne    8004202763 <vprintfmt+0x4ff>
				/* do nothing */;
			break;
  8004202777:	90                   	nop
		}
	}
  8004202778:	90                   	nop
	int base, lflag, width, precision, altflag;
	char padc;
	va_list aq;
	va_copy(aq,ap);
	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  8004202779:	e9 38 fb ff ff       	jmpq   80042022b6 <vprintfmt+0x52>
			if (ch == '\0')
				return;
  800420277e:	90                   	nop
				/* do nothing */;
			break;
		}
	}
    va_end(aq);
}
  800420277f:	48 83 c4 60          	add    $0x60,%rsp
  8004202783:	5b                   	pop    %rbx
  8004202784:	41 5c                	pop    %r12
  8004202786:	5d                   	pop    %rbp
  8004202787:	c3                   	retq   

0000008004202788 <printfmt>:

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
  8004202788:	55                   	push   %rbp
  8004202789:	48 89 e5             	mov    %rsp,%rbp
  800420278c:	48 81 ec f0 00 00 00 	sub    $0xf0,%rsp
  8004202793:	48 89 bd 28 ff ff ff 	mov    %rdi,-0xd8(%rbp)
  800420279a:	48 89 b5 20 ff ff ff 	mov    %rsi,-0xe0(%rbp)
  80042027a1:	48 89 8d 68 ff ff ff 	mov    %rcx,-0x98(%rbp)
  80042027a8:	4c 89 85 70 ff ff ff 	mov    %r8,-0x90(%rbp)
  80042027af:	4c 89 8d 78 ff ff ff 	mov    %r9,-0x88(%rbp)
  80042027b6:	84 c0                	test   %al,%al
  80042027b8:	74 20                	je     80042027da <printfmt+0x52>
  80042027ba:	0f 29 45 80          	movaps %xmm0,-0x80(%rbp)
  80042027be:	0f 29 4d 90          	movaps %xmm1,-0x70(%rbp)
  80042027c2:	0f 29 55 a0          	movaps %xmm2,-0x60(%rbp)
  80042027c6:	0f 29 5d b0          	movaps %xmm3,-0x50(%rbp)
  80042027ca:	0f 29 65 c0          	movaps %xmm4,-0x40(%rbp)
  80042027ce:	0f 29 6d d0          	movaps %xmm5,-0x30(%rbp)
  80042027d2:	0f 29 75 e0          	movaps %xmm6,-0x20(%rbp)
  80042027d6:	0f 29 7d f0          	movaps %xmm7,-0x10(%rbp)
  80042027da:	48 89 95 18 ff ff ff 	mov    %rdx,-0xe8(%rbp)
	va_list ap;

	va_start(ap, fmt);
  80042027e1:	c7 85 38 ff ff ff 18 	movl   $0x18,-0xc8(%rbp)
  80042027e8:	00 00 00 
  80042027eb:	c7 85 3c ff ff ff 30 	movl   $0x30,-0xc4(%rbp)
  80042027f2:	00 00 00 
  80042027f5:	48 8d 45 10          	lea    0x10(%rbp),%rax
  80042027f9:	48 89 85 40 ff ff ff 	mov    %rax,-0xc0(%rbp)
  8004202800:	48 8d 85 50 ff ff ff 	lea    -0xb0(%rbp),%rax
  8004202807:	48 89 85 48 ff ff ff 	mov    %rax,-0xb8(%rbp)
	vprintfmt(putch, putdat, fmt, ap);
  800420280e:	48 8d 8d 38 ff ff ff 	lea    -0xc8(%rbp),%rcx
  8004202815:	48 8b 95 18 ff ff ff 	mov    -0xe8(%rbp),%rdx
  800420281c:	48 8b b5 20 ff ff ff 	mov    -0xe0(%rbp),%rsi
  8004202823:	48 8b 85 28 ff ff ff 	mov    -0xd8(%rbp),%rax
  800420282a:	48 89 c7             	mov    %rax,%rdi
  800420282d:	48 b8 64 22 20 04 80 	movabs $0x8004202264,%rax
  8004202834:	00 00 00 
  8004202837:	ff d0                	callq  *%rax
	va_end(ap);
}
  8004202839:	c9                   	leaveq 
  800420283a:	c3                   	retq   

000000800420283b <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
  800420283b:	55                   	push   %rbp
  800420283c:	48 89 e5             	mov    %rsp,%rbp
  800420283f:	48 83 ec 10          	sub    $0x10,%rsp
  8004202843:	89 7d fc             	mov    %edi,-0x4(%rbp)
  8004202846:	48 89 75 f0          	mov    %rsi,-0x10(%rbp)
	b->cnt++;
  800420284a:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  800420284e:	8b 40 10             	mov    0x10(%rax),%eax
  8004202851:	8d 50 01             	lea    0x1(%rax),%edx
  8004202854:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8004202858:	89 50 10             	mov    %edx,0x10(%rax)
	if (b->buf < b->ebuf)
  800420285b:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  800420285f:	48 8b 10             	mov    (%rax),%rdx
  8004202862:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8004202866:	48 8b 40 08          	mov    0x8(%rax),%rax
  800420286a:	48 39 c2             	cmp    %rax,%rdx
  800420286d:	73 17                	jae    8004202886 <sprintputch+0x4b>
		*b->buf++ = ch;
  800420286f:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8004202873:	48 8b 00             	mov    (%rax),%rax
  8004202876:	8b 55 fc             	mov    -0x4(%rbp),%edx
  8004202879:	88 10                	mov    %dl,(%rax)
  800420287b:	48 8d 50 01          	lea    0x1(%rax),%rdx
  800420287f:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8004202883:	48 89 10             	mov    %rdx,(%rax)
}
  8004202886:	c9                   	leaveq 
  8004202887:	c3                   	retq   

0000008004202888 <vsnprintf>:

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
  8004202888:	55                   	push   %rbp
  8004202889:	48 89 e5             	mov    %rsp,%rbp
  800420288c:	48 83 ec 50          	sub    $0x50,%rsp
  8004202890:	48 89 7d c8          	mov    %rdi,-0x38(%rbp)
  8004202894:	89 75 c4             	mov    %esi,-0x3c(%rbp)
  8004202897:	48 89 55 b8          	mov    %rdx,-0x48(%rbp)
  800420289b:	48 89 4d b0          	mov    %rcx,-0x50(%rbp)
	va_list aq;
	va_copy(aq,ap);
  800420289f:	48 8d 45 e8          	lea    -0x18(%rbp),%rax
  80042028a3:	48 8b 55 b0          	mov    -0x50(%rbp),%rdx
  80042028a7:	48 8b 0a             	mov    (%rdx),%rcx
  80042028aa:	48 89 08             	mov    %rcx,(%rax)
  80042028ad:	48 8b 4a 08          	mov    0x8(%rdx),%rcx
  80042028b1:	48 89 48 08          	mov    %rcx,0x8(%rax)
  80042028b5:	48 8b 52 10          	mov    0x10(%rdx),%rdx
  80042028b9:	48 89 50 10          	mov    %rdx,0x10(%rax)
	struct sprintbuf b = {buf, buf+n-1, 0};
  80042028bd:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
  80042028c1:	48 89 45 d0          	mov    %rax,-0x30(%rbp)
  80042028c5:	8b 45 c4             	mov    -0x3c(%rbp),%eax
  80042028c8:	48 98                	cltq   
  80042028ca:	48 83 e8 01          	sub    $0x1,%rax
  80042028ce:	48 03 45 c8          	add    -0x38(%rbp),%rax
  80042028d2:	48 89 45 d8          	mov    %rax,-0x28(%rbp)
  80042028d6:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%rbp)

	if (buf == NULL || n < 1)
  80042028dd:	48 83 7d c8 00       	cmpq   $0x0,-0x38(%rbp)
  80042028e2:	74 06                	je     80042028ea <vsnprintf+0x62>
  80042028e4:	83 7d c4 00          	cmpl   $0x0,-0x3c(%rbp)
  80042028e8:	7f 07                	jg     80042028f1 <vsnprintf+0x69>
		return -E_INVAL;
  80042028ea:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
  80042028ef:	eb 2f                	jmp    8004202920 <vsnprintf+0x98>

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, aq);
  80042028f1:	48 8d 4d e8          	lea    -0x18(%rbp),%rcx
  80042028f5:	48 8b 55 b8          	mov    -0x48(%rbp),%rdx
  80042028f9:	48 8d 45 d0          	lea    -0x30(%rbp),%rax
  80042028fd:	48 89 c6             	mov    %rax,%rsi
  8004202900:	48 bf 3b 28 20 04 80 	movabs $0x800420283b,%rdi
  8004202907:	00 00 00 
  800420290a:	48 b8 64 22 20 04 80 	movabs $0x8004202264,%rax
  8004202911:	00 00 00 
  8004202914:	ff d0                	callq  *%rax
	va_end(aq);
	// null terminate the buffer
	*b.buf = '\0';
  8004202916:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  800420291a:	c6 00 00             	movb   $0x0,(%rax)

	return b.cnt;
  800420291d:	8b 45 e0             	mov    -0x20(%rbp),%eax
}
  8004202920:	c9                   	leaveq 
  8004202921:	c3                   	retq   

0000008004202922 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
  8004202922:	55                   	push   %rbp
  8004202923:	48 89 e5             	mov    %rsp,%rbp
  8004202926:	48 81 ec 10 01 00 00 	sub    $0x110,%rsp
  800420292d:	48 89 bd 08 ff ff ff 	mov    %rdi,-0xf8(%rbp)
  8004202934:	89 b5 04 ff ff ff    	mov    %esi,-0xfc(%rbp)
  800420293a:	48 89 8d 68 ff ff ff 	mov    %rcx,-0x98(%rbp)
  8004202941:	4c 89 85 70 ff ff ff 	mov    %r8,-0x90(%rbp)
  8004202948:	4c 89 8d 78 ff ff ff 	mov    %r9,-0x88(%rbp)
  800420294f:	84 c0                	test   %al,%al
  8004202951:	74 20                	je     8004202973 <snprintf+0x51>
  8004202953:	0f 29 45 80          	movaps %xmm0,-0x80(%rbp)
  8004202957:	0f 29 4d 90          	movaps %xmm1,-0x70(%rbp)
  800420295b:	0f 29 55 a0          	movaps %xmm2,-0x60(%rbp)
  800420295f:	0f 29 5d b0          	movaps %xmm3,-0x50(%rbp)
  8004202963:	0f 29 65 c0          	movaps %xmm4,-0x40(%rbp)
  8004202967:	0f 29 6d d0          	movaps %xmm5,-0x30(%rbp)
  800420296b:	0f 29 75 e0          	movaps %xmm6,-0x20(%rbp)
  800420296f:	0f 29 7d f0          	movaps %xmm7,-0x10(%rbp)
  8004202973:	48 89 95 f8 fe ff ff 	mov    %rdx,-0x108(%rbp)
	va_list ap;
	int rc;
	va_list aq;
	va_start(ap, fmt);
  800420297a:	c7 85 30 ff ff ff 18 	movl   $0x18,-0xd0(%rbp)
  8004202981:	00 00 00 
  8004202984:	c7 85 34 ff ff ff 30 	movl   $0x30,-0xcc(%rbp)
  800420298b:	00 00 00 
  800420298e:	48 8d 45 10          	lea    0x10(%rbp),%rax
  8004202992:	48 89 85 38 ff ff ff 	mov    %rax,-0xc8(%rbp)
  8004202999:	48 8d 85 50 ff ff ff 	lea    -0xb0(%rbp),%rax
  80042029a0:	48 89 85 40 ff ff ff 	mov    %rax,-0xc0(%rbp)
	va_copy(aq,ap);
  80042029a7:	48 8d 85 18 ff ff ff 	lea    -0xe8(%rbp),%rax
  80042029ae:	48 8d 95 30 ff ff ff 	lea    -0xd0(%rbp),%rdx
  80042029b5:	48 8b 0a             	mov    (%rdx),%rcx
  80042029b8:	48 89 08             	mov    %rcx,(%rax)
  80042029bb:	48 8b 4a 08          	mov    0x8(%rdx),%rcx
  80042029bf:	48 89 48 08          	mov    %rcx,0x8(%rax)
  80042029c3:	48 8b 52 10          	mov    0x10(%rdx),%rdx
  80042029c7:	48 89 50 10          	mov    %rdx,0x10(%rax)
	rc = vsnprintf(buf, n, fmt, aq);
  80042029cb:	48 8d 8d 18 ff ff ff 	lea    -0xe8(%rbp),%rcx
  80042029d2:	48 8b 95 f8 fe ff ff 	mov    -0x108(%rbp),%rdx
  80042029d9:	8b b5 04 ff ff ff    	mov    -0xfc(%rbp),%esi
  80042029df:	48 8b 85 08 ff ff ff 	mov    -0xf8(%rbp),%rax
  80042029e6:	48 89 c7             	mov    %rax,%rdi
  80042029e9:	48 b8 88 28 20 04 80 	movabs $0x8004202888,%rax
  80042029f0:	00 00 00 
  80042029f3:	ff d0                	callq  *%rax
  80042029f5:	89 85 4c ff ff ff    	mov    %eax,-0xb4(%rbp)
	va_end(aq);

	return rc;
  80042029fb:	8b 85 4c ff ff ff    	mov    -0xb4(%rbp),%eax
}
  8004202a01:	c9                   	leaveq 
  8004202a02:	c3                   	retq   
	...

0000008004202a04 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
  8004202a04:	55                   	push   %rbp
  8004202a05:	48 89 e5             	mov    %rsp,%rbp
  8004202a08:	48 83 ec 20          	sub    $0x20,%rsp
  8004202a0c:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
	int i, c, echoing;

	if (prompt != NULL)
  8004202a10:	48 83 7d e8 00       	cmpq   $0x0,-0x18(%rbp)
  8004202a15:	74 22                	je     8004202a39 <readline+0x35>
		cprintf("%s", prompt);
  8004202a17:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004202a1b:	48 89 c6             	mov    %rax,%rsi
  8004202a1e:	48 bf 98 9d 20 04 80 	movabs $0x8004209d98,%rdi
  8004202a25:	00 00 00 
  8004202a28:	b8 00 00 00 00       	mov    $0x0,%eax
  8004202a2d:	48 ba 22 16 20 04 80 	movabs $0x8004201622,%rdx
  8004202a34:	00 00 00 
  8004202a37:	ff d2                	callq  *%rdx

	i = 0;
  8004202a39:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%rbp)
	echoing = iscons(0);
  8004202a40:	bf 00 00 00 00       	mov    $0x0,%edi
  8004202a45:	48 b8 27 0f 20 04 80 	movabs $0x8004200f27,%rax
  8004202a4c:	00 00 00 
  8004202a4f:	ff d0                	callq  *%rax
  8004202a51:	89 45 f8             	mov    %eax,-0x8(%rbp)
  8004202a54:	eb 01                	jmp    8004202a57 <readline+0x53>
			if (echoing)
				cputchar('\n');
			buf[i] = 0;
			return buf;
		}
	}
  8004202a56:	90                   	nop
		cprintf("%s", prompt);

	i = 0;
	echoing = iscons(0);
	while (1) {
		c = getchar();
  8004202a57:	48 b8 05 0f 20 04 80 	movabs $0x8004200f05,%rax
  8004202a5e:	00 00 00 
  8004202a61:	ff d0                	callq  *%rax
  8004202a63:	89 45 f4             	mov    %eax,-0xc(%rbp)
		if (c < 0) {
  8004202a66:	83 7d f4 00          	cmpl   $0x0,-0xc(%rbp)
  8004202a6a:	79 2a                	jns    8004202a96 <readline+0x92>
			cprintf("read error: %e\n", c);
  8004202a6c:	8b 45 f4             	mov    -0xc(%rbp),%eax
  8004202a6f:	89 c6                	mov    %eax,%esi
  8004202a71:	48 bf 9b 9d 20 04 80 	movabs $0x8004209d9b,%rdi
  8004202a78:	00 00 00 
  8004202a7b:	b8 00 00 00 00       	mov    $0x0,%eax
  8004202a80:	48 ba 22 16 20 04 80 	movabs $0x8004201622,%rdx
  8004202a87:	00 00 00 
  8004202a8a:	ff d2                	callq  *%rdx
			return NULL;
  8004202a8c:	b8 00 00 00 00       	mov    $0x0,%eax
  8004202a91:	e9 c0 00 00 00       	jmpq   8004202b56 <readline+0x152>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
  8004202a96:	83 7d f4 08          	cmpl   $0x8,-0xc(%rbp)
  8004202a9a:	74 06                	je     8004202aa2 <readline+0x9e>
  8004202a9c:	83 7d f4 7f          	cmpl   $0x7f,-0xc(%rbp)
  8004202aa0:	75 26                	jne    8004202ac8 <readline+0xc4>
  8004202aa2:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  8004202aa6:	7e 20                	jle    8004202ac8 <readline+0xc4>
			if (echoing)
  8004202aa8:	83 7d f8 00          	cmpl   $0x0,-0x8(%rbp)
  8004202aac:	74 11                	je     8004202abf <readline+0xbb>
				cputchar('\b');
  8004202aae:	bf 08 00 00 00       	mov    $0x8,%edi
  8004202ab3:	48 b8 e7 0e 20 04 80 	movabs $0x8004200ee7,%rax
  8004202aba:	00 00 00 
  8004202abd:	ff d0                	callq  *%rax
			i--;
  8004202abf:	83 6d fc 01          	subl   $0x1,-0x4(%rbp)
  8004202ac3:	e9 89 00 00 00       	jmpq   8004202b51 <readline+0x14d>
		} else if (c >= ' ' && i < BUFLEN-1) {
  8004202ac8:	83 7d f4 1f          	cmpl   $0x1f,-0xc(%rbp)
  8004202acc:	7e 3d                	jle    8004202b0b <readline+0x107>
  8004202ace:	81 7d fc fe 03 00 00 	cmpl   $0x3fe,-0x4(%rbp)
  8004202ad5:	7f 34                	jg     8004202b0b <readline+0x107>
			if (echoing)
  8004202ad7:	83 7d f8 00          	cmpl   $0x0,-0x8(%rbp)
  8004202adb:	74 11                	je     8004202aee <readline+0xea>
				cputchar(c);
  8004202add:	8b 45 f4             	mov    -0xc(%rbp),%eax
  8004202ae0:	89 c7                	mov    %eax,%edi
  8004202ae2:	48 b8 e7 0e 20 04 80 	movabs $0x8004200ee7,%rax
  8004202ae9:	00 00 00 
  8004202aec:	ff d0                	callq  *%rax
			buf[i++] = c;
  8004202aee:	8b 45 f4             	mov    -0xc(%rbp),%eax
  8004202af1:	89 c1                	mov    %eax,%ecx
  8004202af3:	48 ba 00 b9 21 04 80 	movabs $0x800421b900,%rdx
  8004202afa:	00 00 00 
  8004202afd:	8b 45 fc             	mov    -0x4(%rbp),%eax
  8004202b00:	48 98                	cltq   
  8004202b02:	88 0c 02             	mov    %cl,(%rdx,%rax,1)
  8004202b05:	83 45 fc 01          	addl   $0x1,-0x4(%rbp)
  8004202b09:	eb 46                	jmp    8004202b51 <readline+0x14d>
		} else if (c == '\n' || c == '\r') {
  8004202b0b:	83 7d f4 0a          	cmpl   $0xa,-0xc(%rbp)
  8004202b0f:	74 0a                	je     8004202b1b <readline+0x117>
  8004202b11:	83 7d f4 0d          	cmpl   $0xd,-0xc(%rbp)
  8004202b15:	0f 85 3b ff ff ff    	jne    8004202a56 <readline+0x52>
			if (echoing)
  8004202b1b:	83 7d f8 00          	cmpl   $0x0,-0x8(%rbp)
  8004202b1f:	74 11                	je     8004202b32 <readline+0x12e>
				cputchar('\n');
  8004202b21:	bf 0a 00 00 00       	mov    $0xa,%edi
  8004202b26:	48 b8 e7 0e 20 04 80 	movabs $0x8004200ee7,%rax
  8004202b2d:	00 00 00 
  8004202b30:	ff d0                	callq  *%rax
			buf[i] = 0;
  8004202b32:	48 ba 00 b9 21 04 80 	movabs $0x800421b900,%rdx
  8004202b39:	00 00 00 
  8004202b3c:	8b 45 fc             	mov    -0x4(%rbp),%eax
  8004202b3f:	48 98                	cltq   
  8004202b41:	c6 04 02 00          	movb   $0x0,(%rdx,%rax,1)
			return buf;
  8004202b45:	48 b8 00 b9 21 04 80 	movabs $0x800421b900,%rax
  8004202b4c:	00 00 00 
  8004202b4f:	eb 05                	jmp    8004202b56 <readline+0x152>
		}
	}
  8004202b51:	e9 00 ff ff ff       	jmpq   8004202a56 <readline+0x52>
}
  8004202b56:	c9                   	leaveq 
  8004202b57:	c3                   	retq   

0000008004202b58 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  8004202b58:	55                   	push   %rbp
  8004202b59:	48 89 e5             	mov    %rsp,%rbp
  8004202b5c:	48 83 ec 18          	sub    $0x18,%rsp
  8004202b60:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
	int n;

	for (n = 0; *s != '\0'; s++)
  8004202b64:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%rbp)
  8004202b6b:	eb 09                	jmp    8004202b76 <strlen+0x1e>
		n++;
  8004202b6d:	83 45 fc 01          	addl   $0x1,-0x4(%rbp)
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
  8004202b71:	48 83 45 e8 01       	addq   $0x1,-0x18(%rbp)
  8004202b76:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004202b7a:	0f b6 00             	movzbl (%rax),%eax
  8004202b7d:	84 c0                	test   %al,%al
  8004202b7f:	75 ec                	jne    8004202b6d <strlen+0x15>
		n++;
	return n;
  8004202b81:	8b 45 fc             	mov    -0x4(%rbp),%eax
}
  8004202b84:	c9                   	leaveq 
  8004202b85:	c3                   	retq   

0000008004202b86 <strnlen>:

int
strnlen(const char *s, size_t size)
{
  8004202b86:	55                   	push   %rbp
  8004202b87:	48 89 e5             	mov    %rsp,%rbp
  8004202b8a:	48 83 ec 20          	sub    $0x20,%rsp
  8004202b8e:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
  8004202b92:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  8004202b96:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%rbp)
  8004202b9d:	eb 0e                	jmp    8004202bad <strnlen+0x27>
		n++;
  8004202b9f:	83 45 fc 01          	addl   $0x1,-0x4(%rbp)
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  8004202ba3:	48 83 45 e8 01       	addq   $0x1,-0x18(%rbp)
  8004202ba8:	48 83 6d e0 01       	subq   $0x1,-0x20(%rbp)
  8004202bad:	48 83 7d e0 00       	cmpq   $0x0,-0x20(%rbp)
  8004202bb2:	74 0b                	je     8004202bbf <strnlen+0x39>
  8004202bb4:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004202bb8:	0f b6 00             	movzbl (%rax),%eax
  8004202bbb:	84 c0                	test   %al,%al
  8004202bbd:	75 e0                	jne    8004202b9f <strnlen+0x19>
		n++;
	return n;
  8004202bbf:	8b 45 fc             	mov    -0x4(%rbp),%eax
}
  8004202bc2:	c9                   	leaveq 
  8004202bc3:	c3                   	retq   

0000008004202bc4 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  8004202bc4:	55                   	push   %rbp
  8004202bc5:	48 89 e5             	mov    %rsp,%rbp
  8004202bc8:	48 83 ec 20          	sub    $0x20,%rsp
  8004202bcc:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
  8004202bd0:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
	char *ret;

	ret = dst;
  8004202bd4:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004202bd8:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
	while ((*dst++ = *src++) != '\0')
  8004202bdc:	90                   	nop
  8004202bdd:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  8004202be1:	0f b6 10             	movzbl (%rax),%edx
  8004202be4:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004202be8:	88 10                	mov    %dl,(%rax)
  8004202bea:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004202bee:	0f b6 00             	movzbl (%rax),%eax
  8004202bf1:	84 c0                	test   %al,%al
  8004202bf3:	0f 95 c0             	setne  %al
  8004202bf6:	48 83 45 e8 01       	addq   $0x1,-0x18(%rbp)
  8004202bfb:	48 83 45 e0 01       	addq   $0x1,-0x20(%rbp)
  8004202c00:	84 c0                	test   %al,%al
  8004202c02:	75 d9                	jne    8004202bdd <strcpy+0x19>
		/* do nothing */;
	return ret;
  8004202c04:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
}
  8004202c08:	c9                   	leaveq 
  8004202c09:	c3                   	retq   

0000008004202c0a <strcat>:

char *
strcat(char *dst, const char *src)
{
  8004202c0a:	55                   	push   %rbp
  8004202c0b:	48 89 e5             	mov    %rsp,%rbp
  8004202c0e:	48 83 ec 20          	sub    $0x20,%rsp
  8004202c12:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
  8004202c16:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
	int len = strlen(dst);
  8004202c1a:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004202c1e:	48 89 c7             	mov    %rax,%rdi
  8004202c21:	48 b8 58 2b 20 04 80 	movabs $0x8004202b58,%rax
  8004202c28:	00 00 00 
  8004202c2b:	ff d0                	callq  *%rax
  8004202c2d:	89 45 fc             	mov    %eax,-0x4(%rbp)
	strcpy(dst + len, src);
  8004202c30:	8b 45 fc             	mov    -0x4(%rbp),%eax
  8004202c33:	48 98                	cltq   
  8004202c35:	48 03 45 e8          	add    -0x18(%rbp),%rax
  8004202c39:	48 8b 55 e0          	mov    -0x20(%rbp),%rdx
  8004202c3d:	48 89 d6             	mov    %rdx,%rsi
  8004202c40:	48 89 c7             	mov    %rax,%rdi
  8004202c43:	48 b8 c4 2b 20 04 80 	movabs $0x8004202bc4,%rax
  8004202c4a:	00 00 00 
  8004202c4d:	ff d0                	callq  *%rax
	return dst;
  8004202c4f:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
}
  8004202c53:	c9                   	leaveq 
  8004202c54:	c3                   	retq   

0000008004202c55 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
  8004202c55:	55                   	push   %rbp
  8004202c56:	48 89 e5             	mov    %rsp,%rbp
  8004202c59:	48 83 ec 28          	sub    $0x28,%rsp
  8004202c5d:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
  8004202c61:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
  8004202c65:	48 89 55 d8          	mov    %rdx,-0x28(%rbp)
	size_t i;
	char *ret;

	ret = dst;
  8004202c69:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004202c6d:	48 89 45 f0          	mov    %rax,-0x10(%rbp)
	for (i = 0; i < size; i++) {
  8004202c71:	48 c7 45 f8 00 00 00 	movq   $0x0,-0x8(%rbp)
  8004202c78:	00 
  8004202c79:	eb 27                	jmp    8004202ca2 <strncpy+0x4d>
		*dst++ = *src;
  8004202c7b:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  8004202c7f:	0f b6 10             	movzbl (%rax),%edx
  8004202c82:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004202c86:	88 10                	mov    %dl,(%rax)
  8004202c88:	48 83 45 e8 01       	addq   $0x1,-0x18(%rbp)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
  8004202c8d:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  8004202c91:	0f b6 00             	movzbl (%rax),%eax
  8004202c94:	84 c0                	test   %al,%al
  8004202c96:	74 05                	je     8004202c9d <strncpy+0x48>
			src++;
  8004202c98:	48 83 45 e0 01       	addq   $0x1,-0x20(%rbp)
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  8004202c9d:	48 83 45 f8 01       	addq   $0x1,-0x8(%rbp)
  8004202ca2:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8004202ca6:	48 3b 45 d8          	cmp    -0x28(%rbp),%rax
  8004202caa:	72 cf                	jb     8004202c7b <strncpy+0x26>
		*dst++ = *src;
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
  8004202cac:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
}
  8004202cb0:	c9                   	leaveq 
  8004202cb1:	c3                   	retq   

0000008004202cb2 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  8004202cb2:	55                   	push   %rbp
  8004202cb3:	48 89 e5             	mov    %rsp,%rbp
  8004202cb6:	48 83 ec 28          	sub    $0x28,%rsp
  8004202cba:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
  8004202cbe:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
  8004202cc2:	48 89 55 d8          	mov    %rdx,-0x28(%rbp)
	char *dst_in;

	dst_in = dst;
  8004202cc6:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004202cca:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
	if (size > 0) {
  8004202cce:	48 83 7d d8 00       	cmpq   $0x0,-0x28(%rbp)
  8004202cd3:	74 37                	je     8004202d0c <strlcpy+0x5a>
		while (--size > 0 && *src != '\0')
  8004202cd5:	eb 17                	jmp    8004202cee <strlcpy+0x3c>
			*dst++ = *src++;
  8004202cd7:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  8004202cdb:	0f b6 10             	movzbl (%rax),%edx
  8004202cde:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004202ce2:	88 10                	mov    %dl,(%rax)
  8004202ce4:	48 83 45 e8 01       	addq   $0x1,-0x18(%rbp)
  8004202ce9:	48 83 45 e0 01       	addq   $0x1,-0x20(%rbp)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
  8004202cee:	48 83 6d d8 01       	subq   $0x1,-0x28(%rbp)
  8004202cf3:	48 83 7d d8 00       	cmpq   $0x0,-0x28(%rbp)
  8004202cf8:	74 0b                	je     8004202d05 <strlcpy+0x53>
  8004202cfa:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  8004202cfe:	0f b6 00             	movzbl (%rax),%eax
  8004202d01:	84 c0                	test   %al,%al
  8004202d03:	75 d2                	jne    8004202cd7 <strlcpy+0x25>
			*dst++ = *src++;
		*dst = '\0';
  8004202d05:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004202d09:	c6 00 00             	movb   $0x0,(%rax)
	}
	return dst - dst_in;
  8004202d0c:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  8004202d10:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8004202d14:	48 89 d1             	mov    %rdx,%rcx
  8004202d17:	48 29 c1             	sub    %rax,%rcx
  8004202d1a:	48 89 c8             	mov    %rcx,%rax
}
  8004202d1d:	c9                   	leaveq 
  8004202d1e:	c3                   	retq   

0000008004202d1f <strcmp>:

int
strcmp(const char *p, const char *q)
{
  8004202d1f:	55                   	push   %rbp
  8004202d20:	48 89 e5             	mov    %rsp,%rbp
  8004202d23:	48 83 ec 10          	sub    $0x10,%rsp
  8004202d27:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
  8004202d2b:	48 89 75 f0          	mov    %rsi,-0x10(%rbp)
	while (*p && *p == *q)
  8004202d2f:	eb 0a                	jmp    8004202d3b <strcmp+0x1c>
		p++, q++;
  8004202d31:	48 83 45 f8 01       	addq   $0x1,-0x8(%rbp)
  8004202d36:	48 83 45 f0 01       	addq   $0x1,-0x10(%rbp)
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
  8004202d3b:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8004202d3f:	0f b6 00             	movzbl (%rax),%eax
  8004202d42:	84 c0                	test   %al,%al
  8004202d44:	74 12                	je     8004202d58 <strcmp+0x39>
  8004202d46:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8004202d4a:	0f b6 10             	movzbl (%rax),%edx
  8004202d4d:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8004202d51:	0f b6 00             	movzbl (%rax),%eax
  8004202d54:	38 c2                	cmp    %al,%dl
  8004202d56:	74 d9                	je     8004202d31 <strcmp+0x12>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
  8004202d58:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8004202d5c:	0f b6 00             	movzbl (%rax),%eax
  8004202d5f:	0f b6 d0             	movzbl %al,%edx
  8004202d62:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8004202d66:	0f b6 00             	movzbl (%rax),%eax
  8004202d69:	0f b6 c0             	movzbl %al,%eax
  8004202d6c:	89 d1                	mov    %edx,%ecx
  8004202d6e:	29 c1                	sub    %eax,%ecx
  8004202d70:	89 c8                	mov    %ecx,%eax
}
  8004202d72:	c9                   	leaveq 
  8004202d73:	c3                   	retq   

0000008004202d74 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  8004202d74:	55                   	push   %rbp
  8004202d75:	48 89 e5             	mov    %rsp,%rbp
  8004202d78:	48 83 ec 18          	sub    $0x18,%rsp
  8004202d7c:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
  8004202d80:	48 89 75 f0          	mov    %rsi,-0x10(%rbp)
  8004202d84:	48 89 55 e8          	mov    %rdx,-0x18(%rbp)
	while (n > 0 && *p && *p == *q)
  8004202d88:	eb 0f                	jmp    8004202d99 <strncmp+0x25>
		n--, p++, q++;
  8004202d8a:	48 83 6d e8 01       	subq   $0x1,-0x18(%rbp)
  8004202d8f:	48 83 45 f8 01       	addq   $0x1,-0x8(%rbp)
  8004202d94:	48 83 45 f0 01       	addq   $0x1,-0x10(%rbp)
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
  8004202d99:	48 83 7d e8 00       	cmpq   $0x0,-0x18(%rbp)
  8004202d9e:	74 1d                	je     8004202dbd <strncmp+0x49>
  8004202da0:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8004202da4:	0f b6 00             	movzbl (%rax),%eax
  8004202da7:	84 c0                	test   %al,%al
  8004202da9:	74 12                	je     8004202dbd <strncmp+0x49>
  8004202dab:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8004202daf:	0f b6 10             	movzbl (%rax),%edx
  8004202db2:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8004202db6:	0f b6 00             	movzbl (%rax),%eax
  8004202db9:	38 c2                	cmp    %al,%dl
  8004202dbb:	74 cd                	je     8004202d8a <strncmp+0x16>
		n--, p++, q++;
	if (n == 0)
  8004202dbd:	48 83 7d e8 00       	cmpq   $0x0,-0x18(%rbp)
  8004202dc2:	75 07                	jne    8004202dcb <strncmp+0x57>
		return 0;
  8004202dc4:	b8 00 00 00 00       	mov    $0x0,%eax
  8004202dc9:	eb 1a                	jmp    8004202de5 <strncmp+0x71>
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  8004202dcb:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8004202dcf:	0f b6 00             	movzbl (%rax),%eax
  8004202dd2:	0f b6 d0             	movzbl %al,%edx
  8004202dd5:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8004202dd9:	0f b6 00             	movzbl (%rax),%eax
  8004202ddc:	0f b6 c0             	movzbl %al,%eax
  8004202ddf:	89 d1                	mov    %edx,%ecx
  8004202de1:	29 c1                	sub    %eax,%ecx
  8004202de3:	89 c8                	mov    %ecx,%eax
}
  8004202de5:	c9                   	leaveq 
  8004202de6:	c3                   	retq   

0000008004202de7 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  8004202de7:	55                   	push   %rbp
  8004202de8:	48 89 e5             	mov    %rsp,%rbp
  8004202deb:	48 83 ec 10          	sub    $0x10,%rsp
  8004202def:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
  8004202df3:	89 f0                	mov    %esi,%eax
  8004202df5:	88 45 f4             	mov    %al,-0xc(%rbp)
	for (; *s; s++)
  8004202df8:	eb 17                	jmp    8004202e11 <strchr+0x2a>
		if (*s == c)
  8004202dfa:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8004202dfe:	0f b6 00             	movzbl (%rax),%eax
  8004202e01:	3a 45 f4             	cmp    -0xc(%rbp),%al
  8004202e04:	75 06                	jne    8004202e0c <strchr+0x25>
			return (char *) s;
  8004202e06:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8004202e0a:	eb 15                	jmp    8004202e21 <strchr+0x3a>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
  8004202e0c:	48 83 45 f8 01       	addq   $0x1,-0x8(%rbp)
  8004202e11:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8004202e15:	0f b6 00             	movzbl (%rax),%eax
  8004202e18:	84 c0                	test   %al,%al
  8004202e1a:	75 de                	jne    8004202dfa <strchr+0x13>
		if (*s == c)
			return (char *) s;
	return 0;
  8004202e1c:	b8 00 00 00 00       	mov    $0x0,%eax
}
  8004202e21:	c9                   	leaveq 
  8004202e22:	c3                   	retq   

0000008004202e23 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
  8004202e23:	55                   	push   %rbp
  8004202e24:	48 89 e5             	mov    %rsp,%rbp
  8004202e27:	48 83 ec 10          	sub    $0x10,%rsp
  8004202e2b:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
  8004202e2f:	89 f0                	mov    %esi,%eax
  8004202e31:	88 45 f4             	mov    %al,-0xc(%rbp)
	for (; *s; s++)
  8004202e34:	eb 11                	jmp    8004202e47 <strfind+0x24>
		if (*s == c)
  8004202e36:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8004202e3a:	0f b6 00             	movzbl (%rax),%eax
  8004202e3d:	3a 45 f4             	cmp    -0xc(%rbp),%al
  8004202e40:	74 12                	je     8004202e54 <strfind+0x31>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
  8004202e42:	48 83 45 f8 01       	addq   $0x1,-0x8(%rbp)
  8004202e47:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8004202e4b:	0f b6 00             	movzbl (%rax),%eax
  8004202e4e:	84 c0                	test   %al,%al
  8004202e50:	75 e4                	jne    8004202e36 <strfind+0x13>
  8004202e52:	eb 01                	jmp    8004202e55 <strfind+0x32>
		if (*s == c)
			break;
  8004202e54:	90                   	nop
	return (char *) s;
  8004202e55:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
}
  8004202e59:	c9                   	leaveq 
  8004202e5a:	c3                   	retq   

0000008004202e5b <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  8004202e5b:	55                   	push   %rbp
  8004202e5c:	48 89 e5             	mov    %rsp,%rbp
  8004202e5f:	48 83 ec 18          	sub    $0x18,%rsp
  8004202e63:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
  8004202e67:	89 75 f4             	mov    %esi,-0xc(%rbp)
  8004202e6a:	48 89 55 e8          	mov    %rdx,-0x18(%rbp)
	char *p;

	if (n == 0)
  8004202e6e:	48 83 7d e8 00       	cmpq   $0x0,-0x18(%rbp)
  8004202e73:	75 06                	jne    8004202e7b <memset+0x20>
		return v;
  8004202e75:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8004202e79:	eb 69                	jmp    8004202ee4 <memset+0x89>
	if ((int64_t)v%4 == 0 && n%4 == 0) {
  8004202e7b:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8004202e7f:	83 e0 03             	and    $0x3,%eax
  8004202e82:	48 85 c0             	test   %rax,%rax
  8004202e85:	75 48                	jne    8004202ecf <memset+0x74>
  8004202e87:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004202e8b:	83 e0 03             	and    $0x3,%eax
  8004202e8e:	48 85 c0             	test   %rax,%rax
  8004202e91:	75 3c                	jne    8004202ecf <memset+0x74>
		c &= 0xFF;
  8004202e93:	81 65 f4 ff 00 00 00 	andl   $0xff,-0xc(%rbp)
		c = (c<<24)|(c<<16)|(c<<8)|c;
  8004202e9a:	8b 45 f4             	mov    -0xc(%rbp),%eax
  8004202e9d:	89 c2                	mov    %eax,%edx
  8004202e9f:	c1 e2 18             	shl    $0x18,%edx
  8004202ea2:	8b 45 f4             	mov    -0xc(%rbp),%eax
  8004202ea5:	c1 e0 10             	shl    $0x10,%eax
  8004202ea8:	09 c2                	or     %eax,%edx
  8004202eaa:	8b 45 f4             	mov    -0xc(%rbp),%eax
  8004202ead:	c1 e0 08             	shl    $0x8,%eax
  8004202eb0:	09 d0                	or     %edx,%eax
  8004202eb2:	09 45 f4             	or     %eax,-0xc(%rbp)
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
  8004202eb5:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004202eb9:	48 89 c1             	mov    %rax,%rcx
  8004202ebc:	48 c1 e9 02          	shr    $0x2,%rcx
	if (n == 0)
		return v;
	if ((int64_t)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
  8004202ec0:	48 8b 55 f8          	mov    -0x8(%rbp),%rdx
  8004202ec4:	8b 45 f4             	mov    -0xc(%rbp),%eax
  8004202ec7:	48 89 d7             	mov    %rdx,%rdi
  8004202eca:	fc                   	cld    
  8004202ecb:	f3 ab                	rep stos %eax,%es:(%rdi)
  8004202ecd:	eb 11                	jmp    8004202ee0 <memset+0x85>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  8004202ecf:	48 8b 55 f8          	mov    -0x8(%rbp),%rdx
  8004202ed3:	8b 45 f4             	mov    -0xc(%rbp),%eax
  8004202ed6:	48 8b 4d e8          	mov    -0x18(%rbp),%rcx
  8004202eda:	48 89 d7             	mov    %rdx,%rdi
  8004202edd:	fc                   	cld    
  8004202ede:	f3 aa                	rep stos %al,%es:(%rdi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
  8004202ee0:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
}
  8004202ee4:	c9                   	leaveq 
  8004202ee5:	c3                   	retq   

0000008004202ee6 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  8004202ee6:	55                   	push   %rbp
  8004202ee7:	48 89 e5             	mov    %rsp,%rbp
  8004202eea:	48 83 ec 28          	sub    $0x28,%rsp
  8004202eee:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
  8004202ef2:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
  8004202ef6:	48 89 55 d8          	mov    %rdx,-0x28(%rbp)
	const char *s;
	char *d;

	s = src;
  8004202efa:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  8004202efe:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
	d = dst;
  8004202f02:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004202f06:	48 89 45 f0          	mov    %rax,-0x10(%rbp)
	if (s < d && s + n > d) {
  8004202f0a:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8004202f0e:	48 3b 45 f0          	cmp    -0x10(%rbp),%rax
  8004202f12:	0f 83 88 00 00 00    	jae    8004202fa0 <memmove+0xba>
  8004202f18:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  8004202f1c:	48 8b 55 f8          	mov    -0x8(%rbp),%rdx
  8004202f20:	48 01 d0             	add    %rdx,%rax
  8004202f23:	48 3b 45 f0          	cmp    -0x10(%rbp),%rax
  8004202f27:	76 77                	jbe    8004202fa0 <memmove+0xba>
		s += n;
  8004202f29:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  8004202f2d:	48 01 45 f8          	add    %rax,-0x8(%rbp)
		d += n;
  8004202f31:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  8004202f35:	48 01 45 f0          	add    %rax,-0x10(%rbp)
		if ((int64_t)s%4 == 0 && (int64_t)d%4 == 0 && n%4 == 0)
  8004202f39:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8004202f3d:	83 e0 03             	and    $0x3,%eax
  8004202f40:	48 85 c0             	test   %rax,%rax
  8004202f43:	75 3b                	jne    8004202f80 <memmove+0x9a>
  8004202f45:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8004202f49:	83 e0 03             	and    $0x3,%eax
  8004202f4c:	48 85 c0             	test   %rax,%rax
  8004202f4f:	75 2f                	jne    8004202f80 <memmove+0x9a>
  8004202f51:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  8004202f55:	83 e0 03             	and    $0x3,%eax
  8004202f58:	48 85 c0             	test   %rax,%rax
  8004202f5b:	75 23                	jne    8004202f80 <memmove+0x9a>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
  8004202f5d:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8004202f61:	48 83 e8 04          	sub    $0x4,%rax
  8004202f65:	48 8b 55 f8          	mov    -0x8(%rbp),%rdx
  8004202f69:	48 83 ea 04          	sub    $0x4,%rdx
  8004202f6d:	48 8b 4d d8          	mov    -0x28(%rbp),%rcx
  8004202f71:	48 c1 e9 02          	shr    $0x2,%rcx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int64_t)s%4 == 0 && (int64_t)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
  8004202f75:	48 89 c7             	mov    %rax,%rdi
  8004202f78:	48 89 d6             	mov    %rdx,%rsi
  8004202f7b:	fd                   	std    
  8004202f7c:	f3 a5                	rep movsl %ds:(%rsi),%es:(%rdi)
  8004202f7e:	eb 1d                	jmp    8004202f9d <memmove+0xb7>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
  8004202f80:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8004202f84:	48 8d 50 ff          	lea    -0x1(%rax),%rdx
  8004202f88:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8004202f8c:	48 8d 70 ff          	lea    -0x1(%rax),%rsi
		d += n;
		if ((int64_t)s%4 == 0 && (int64_t)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  8004202f90:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  8004202f94:	48 89 d7             	mov    %rdx,%rdi
  8004202f97:	48 89 c1             	mov    %rax,%rcx
  8004202f9a:	fd                   	std    
  8004202f9b:	f3 a4                	rep movsb %ds:(%rsi),%es:(%rdi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  8004202f9d:	fc                   	cld    
  8004202f9e:	eb 57                	jmp    8004202ff7 <memmove+0x111>
	} else {
		if ((int64_t)s%4 == 0 && (int64_t)d%4 == 0 && n%4 == 0)
  8004202fa0:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8004202fa4:	83 e0 03             	and    $0x3,%eax
  8004202fa7:	48 85 c0             	test   %rax,%rax
  8004202faa:	75 36                	jne    8004202fe2 <memmove+0xfc>
  8004202fac:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8004202fb0:	83 e0 03             	and    $0x3,%eax
  8004202fb3:	48 85 c0             	test   %rax,%rax
  8004202fb6:	75 2a                	jne    8004202fe2 <memmove+0xfc>
  8004202fb8:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  8004202fbc:	83 e0 03             	and    $0x3,%eax
  8004202fbf:	48 85 c0             	test   %rax,%rax
  8004202fc2:	75 1e                	jne    8004202fe2 <memmove+0xfc>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
  8004202fc4:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  8004202fc8:	48 89 c1             	mov    %rax,%rcx
  8004202fcb:	48 c1 e9 02          	shr    $0x2,%rcx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int64_t)s%4 == 0 && (int64_t)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
  8004202fcf:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8004202fd3:	48 8b 55 f8          	mov    -0x8(%rbp),%rdx
  8004202fd7:	48 89 c7             	mov    %rax,%rdi
  8004202fda:	48 89 d6             	mov    %rdx,%rsi
  8004202fdd:	fc                   	cld    
  8004202fde:	f3 a5                	rep movsl %ds:(%rsi),%es:(%rdi)
  8004202fe0:	eb 15                	jmp    8004202ff7 <memmove+0x111>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  8004202fe2:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8004202fe6:	48 8b 55 f8          	mov    -0x8(%rbp),%rdx
  8004202fea:	48 8b 4d d8          	mov    -0x28(%rbp),%rcx
  8004202fee:	48 89 c7             	mov    %rax,%rdi
  8004202ff1:	48 89 d6             	mov    %rdx,%rsi
  8004202ff4:	fc                   	cld    
  8004202ff5:	f3 a4                	rep movsb %ds:(%rsi),%es:(%rdi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
  8004202ff7:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
}
  8004202ffb:	c9                   	leaveq 
  8004202ffc:	c3                   	retq   

0000008004202ffd <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
  8004202ffd:	55                   	push   %rbp
  8004202ffe:	48 89 e5             	mov    %rsp,%rbp
  8004203001:	48 83 ec 18          	sub    $0x18,%rsp
  8004203005:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
  8004203009:	48 89 75 f0          	mov    %rsi,-0x10(%rbp)
  800420300d:	48 89 55 e8          	mov    %rdx,-0x18(%rbp)
	return memmove(dst, src, n);
  8004203011:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  8004203015:	48 8b 4d f0          	mov    -0x10(%rbp),%rcx
  8004203019:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  800420301d:	48 89 ce             	mov    %rcx,%rsi
  8004203020:	48 89 c7             	mov    %rax,%rdi
  8004203023:	48 b8 e6 2e 20 04 80 	movabs $0x8004202ee6,%rax
  800420302a:	00 00 00 
  800420302d:	ff d0                	callq  *%rax
}
  800420302f:	c9                   	leaveq 
  8004203030:	c3                   	retq   

0000008004203031 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  8004203031:	55                   	push   %rbp
  8004203032:	48 89 e5             	mov    %rsp,%rbp
  8004203035:	48 83 ec 28          	sub    $0x28,%rsp
  8004203039:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
  800420303d:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
  8004203041:	48 89 55 d8          	mov    %rdx,-0x28(%rbp)
	const uint8_t *s1 = (const uint8_t *) v1;
  8004203045:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004203049:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
	const uint8_t *s2 = (const uint8_t *) v2;
  800420304d:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  8004203051:	48 89 45 f0          	mov    %rax,-0x10(%rbp)

	while (n-- > 0) {
  8004203055:	eb 38                	jmp    800420308f <memcmp+0x5e>
		if (*s1 != *s2)
  8004203057:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  800420305b:	0f b6 10             	movzbl (%rax),%edx
  800420305e:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8004203062:	0f b6 00             	movzbl (%rax),%eax
  8004203065:	38 c2                	cmp    %al,%dl
  8004203067:	74 1c                	je     8004203085 <memcmp+0x54>
			return (int) *s1 - (int) *s2;
  8004203069:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  800420306d:	0f b6 00             	movzbl (%rax),%eax
  8004203070:	0f b6 d0             	movzbl %al,%edx
  8004203073:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8004203077:	0f b6 00             	movzbl (%rax),%eax
  800420307a:	0f b6 c0             	movzbl %al,%eax
  800420307d:	89 d1                	mov    %edx,%ecx
  800420307f:	29 c1                	sub    %eax,%ecx
  8004203081:	89 c8                	mov    %ecx,%eax
  8004203083:	eb 20                	jmp    80042030a5 <memcmp+0x74>
		s1++, s2++;
  8004203085:	48 83 45 f8 01       	addq   $0x1,-0x8(%rbp)
  800420308a:	48 83 45 f0 01       	addq   $0x1,-0x10(%rbp)
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800420308f:	48 83 7d d8 00       	cmpq   $0x0,-0x28(%rbp)
  8004203094:	0f 95 c0             	setne  %al
  8004203097:	48 83 6d d8 01       	subq   $0x1,-0x28(%rbp)
  800420309c:	84 c0                	test   %al,%al
  800420309e:	75 b7                	jne    8004203057 <memcmp+0x26>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
  80042030a0:	b8 00 00 00 00       	mov    $0x0,%eax
}
  80042030a5:	c9                   	leaveq 
  80042030a6:	c3                   	retq   

00000080042030a7 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
  80042030a7:	55                   	push   %rbp
  80042030a8:	48 89 e5             	mov    %rsp,%rbp
  80042030ab:	48 83 ec 28          	sub    $0x28,%rsp
  80042030af:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
  80042030b3:	89 75 e4             	mov    %esi,-0x1c(%rbp)
  80042030b6:	48 89 55 d8          	mov    %rdx,-0x28(%rbp)
	const void *ends = (const char *) s + n;
  80042030ba:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  80042030be:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  80042030c2:	48 01 d0             	add    %rdx,%rax
  80042030c5:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
	for (; s < ends; s++)
  80042030c9:	eb 13                	jmp    80042030de <memfind+0x37>
		if (*(const unsigned char *) s == (unsigned char) c)
  80042030cb:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  80042030cf:	0f b6 10             	movzbl (%rax),%edx
  80042030d2:	8b 45 e4             	mov    -0x1c(%rbp),%eax
  80042030d5:	38 c2                	cmp    %al,%dl
  80042030d7:	74 11                	je     80042030ea <memfind+0x43>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  80042030d9:	48 83 45 e8 01       	addq   $0x1,-0x18(%rbp)
  80042030de:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  80042030e2:	48 3b 45 f8          	cmp    -0x8(%rbp),%rax
  80042030e6:	72 e3                	jb     80042030cb <memfind+0x24>
  80042030e8:	eb 01                	jmp    80042030eb <memfind+0x44>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
  80042030ea:	90                   	nop
	return (void *) s;
  80042030eb:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
}
  80042030ef:	c9                   	leaveq 
  80042030f0:	c3                   	retq   

00000080042030f1 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
  80042030f1:	55                   	push   %rbp
  80042030f2:	48 89 e5             	mov    %rsp,%rbp
  80042030f5:	48 83 ec 38          	sub    $0x38,%rsp
  80042030f9:	48 89 7d d8          	mov    %rdi,-0x28(%rbp)
  80042030fd:	48 89 75 d0          	mov    %rsi,-0x30(%rbp)
  8004203101:	89 55 cc             	mov    %edx,-0x34(%rbp)
	int neg = 0;
  8004203104:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%rbp)
	long val = 0;
  800420310b:	48 c7 45 f0 00 00 00 	movq   $0x0,-0x10(%rbp)
  8004203112:	00 

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  8004203113:	eb 05                	jmp    800420311a <strtol+0x29>
		s++;
  8004203115:	48 83 45 d8 01       	addq   $0x1,-0x28(%rbp)
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800420311a:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  800420311e:	0f b6 00             	movzbl (%rax),%eax
  8004203121:	3c 20                	cmp    $0x20,%al
  8004203123:	74 f0                	je     8004203115 <strtol+0x24>
  8004203125:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  8004203129:	0f b6 00             	movzbl (%rax),%eax
  800420312c:	3c 09                	cmp    $0x9,%al
  800420312e:	74 e5                	je     8004203115 <strtol+0x24>
		s++;

	// plus/minus sign
	if (*s == '+')
  8004203130:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  8004203134:	0f b6 00             	movzbl (%rax),%eax
  8004203137:	3c 2b                	cmp    $0x2b,%al
  8004203139:	75 07                	jne    8004203142 <strtol+0x51>
		s++;
  800420313b:	48 83 45 d8 01       	addq   $0x1,-0x28(%rbp)
  8004203140:	eb 17                	jmp    8004203159 <strtol+0x68>
	else if (*s == '-')
  8004203142:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  8004203146:	0f b6 00             	movzbl (%rax),%eax
  8004203149:	3c 2d                	cmp    $0x2d,%al
  800420314b:	75 0c                	jne    8004203159 <strtol+0x68>
		s++, neg = 1;
  800420314d:	48 83 45 d8 01       	addq   $0x1,-0x28(%rbp)
  8004203152:	c7 45 fc 01 00 00 00 	movl   $0x1,-0x4(%rbp)

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
  8004203159:	83 7d cc 00          	cmpl   $0x0,-0x34(%rbp)
  800420315d:	74 06                	je     8004203165 <strtol+0x74>
  800420315f:	83 7d cc 10          	cmpl   $0x10,-0x34(%rbp)
  8004203163:	75 28                	jne    800420318d <strtol+0x9c>
  8004203165:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  8004203169:	0f b6 00             	movzbl (%rax),%eax
  800420316c:	3c 30                	cmp    $0x30,%al
  800420316e:	75 1d                	jne    800420318d <strtol+0x9c>
  8004203170:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  8004203174:	48 83 c0 01          	add    $0x1,%rax
  8004203178:	0f b6 00             	movzbl (%rax),%eax
  800420317b:	3c 78                	cmp    $0x78,%al
  800420317d:	75 0e                	jne    800420318d <strtol+0x9c>
		s += 2, base = 16;
  800420317f:	48 83 45 d8 02       	addq   $0x2,-0x28(%rbp)
  8004203184:	c7 45 cc 10 00 00 00 	movl   $0x10,-0x34(%rbp)
  800420318b:	eb 2c                	jmp    80042031b9 <strtol+0xc8>
	else if (base == 0 && s[0] == '0')
  800420318d:	83 7d cc 00          	cmpl   $0x0,-0x34(%rbp)
  8004203191:	75 19                	jne    80042031ac <strtol+0xbb>
  8004203193:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  8004203197:	0f b6 00             	movzbl (%rax),%eax
  800420319a:	3c 30                	cmp    $0x30,%al
  800420319c:	75 0e                	jne    80042031ac <strtol+0xbb>
		s++, base = 8;
  800420319e:	48 83 45 d8 01       	addq   $0x1,-0x28(%rbp)
  80042031a3:	c7 45 cc 08 00 00 00 	movl   $0x8,-0x34(%rbp)
  80042031aa:	eb 0d                	jmp    80042031b9 <strtol+0xc8>
	else if (base == 0)
  80042031ac:	83 7d cc 00          	cmpl   $0x0,-0x34(%rbp)
  80042031b0:	75 07                	jne    80042031b9 <strtol+0xc8>
		base = 10;
  80042031b2:	c7 45 cc 0a 00 00 00 	movl   $0xa,-0x34(%rbp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
  80042031b9:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  80042031bd:	0f b6 00             	movzbl (%rax),%eax
  80042031c0:	3c 2f                	cmp    $0x2f,%al
  80042031c2:	7e 1d                	jle    80042031e1 <strtol+0xf0>
  80042031c4:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  80042031c8:	0f b6 00             	movzbl (%rax),%eax
  80042031cb:	3c 39                	cmp    $0x39,%al
  80042031cd:	7f 12                	jg     80042031e1 <strtol+0xf0>
			dig = *s - '0';
  80042031cf:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  80042031d3:	0f b6 00             	movzbl (%rax),%eax
  80042031d6:	0f be c0             	movsbl %al,%eax
  80042031d9:	83 e8 30             	sub    $0x30,%eax
  80042031dc:	89 45 ec             	mov    %eax,-0x14(%rbp)
  80042031df:	eb 4e                	jmp    800420322f <strtol+0x13e>
		else if (*s >= 'a' && *s <= 'z')
  80042031e1:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  80042031e5:	0f b6 00             	movzbl (%rax),%eax
  80042031e8:	3c 60                	cmp    $0x60,%al
  80042031ea:	7e 1d                	jle    8004203209 <strtol+0x118>
  80042031ec:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  80042031f0:	0f b6 00             	movzbl (%rax),%eax
  80042031f3:	3c 7a                	cmp    $0x7a,%al
  80042031f5:	7f 12                	jg     8004203209 <strtol+0x118>
			dig = *s - 'a' + 10;
  80042031f7:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  80042031fb:	0f b6 00             	movzbl (%rax),%eax
  80042031fe:	0f be c0             	movsbl %al,%eax
  8004203201:	83 e8 57             	sub    $0x57,%eax
  8004203204:	89 45 ec             	mov    %eax,-0x14(%rbp)
  8004203207:	eb 26                	jmp    800420322f <strtol+0x13e>
		else if (*s >= 'A' && *s <= 'Z')
  8004203209:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  800420320d:	0f b6 00             	movzbl (%rax),%eax
  8004203210:	3c 40                	cmp    $0x40,%al
  8004203212:	7e 47                	jle    800420325b <strtol+0x16a>
  8004203214:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  8004203218:	0f b6 00             	movzbl (%rax),%eax
  800420321b:	3c 5a                	cmp    $0x5a,%al
  800420321d:	7f 3c                	jg     800420325b <strtol+0x16a>
			dig = *s - 'A' + 10;
  800420321f:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  8004203223:	0f b6 00             	movzbl (%rax),%eax
  8004203226:	0f be c0             	movsbl %al,%eax
  8004203229:	83 e8 37             	sub    $0x37,%eax
  800420322c:	89 45 ec             	mov    %eax,-0x14(%rbp)
		else
			break;
		if (dig >= base)
  800420322f:	8b 45 ec             	mov    -0x14(%rbp),%eax
  8004203232:	3b 45 cc             	cmp    -0x34(%rbp),%eax
  8004203235:	7d 23                	jge    800420325a <strtol+0x169>
			break;
		s++, val = (val * base) + dig;
  8004203237:	48 83 45 d8 01       	addq   $0x1,-0x28(%rbp)
  800420323c:	8b 45 cc             	mov    -0x34(%rbp),%eax
  800420323f:	48 98                	cltq   
  8004203241:	48 89 c2             	mov    %rax,%rdx
  8004203244:	48 0f af 55 f0       	imul   -0x10(%rbp),%rdx
  8004203249:	8b 45 ec             	mov    -0x14(%rbp),%eax
  800420324c:	48 98                	cltq   
  800420324e:	48 01 d0             	add    %rdx,%rax
  8004203251:	48 89 45 f0          	mov    %rax,-0x10(%rbp)
		// we don't properly detect overflow!
	}
  8004203255:	e9 5f ff ff ff       	jmpq   80042031b9 <strtol+0xc8>
		else if (*s >= 'A' && *s <= 'Z')
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
			break;
  800420325a:	90                   	nop
		s++, val = (val * base) + dig;
		// we don't properly detect overflow!
	}

	if (endptr)
  800420325b:	48 83 7d d0 00       	cmpq   $0x0,-0x30(%rbp)
  8004203260:	74 0b                	je     800420326d <strtol+0x17c>
		*endptr = (char *) s;
  8004203262:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  8004203266:	48 8b 55 d8          	mov    -0x28(%rbp),%rdx
  800420326a:	48 89 10             	mov    %rdx,(%rax)
	return (neg ? -val : val);
  800420326d:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  8004203271:	74 09                	je     800420327c <strtol+0x18b>
  8004203273:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8004203277:	48 f7 d8             	neg    %rax
  800420327a:	eb 04                	jmp    8004203280 <strtol+0x18f>
  800420327c:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
}
  8004203280:	c9                   	leaveq 
  8004203281:	c3                   	retq   

0000008004203282 <strstr>:

char * strstr(const char *in, const char *str)
{
  8004203282:	55                   	push   %rbp
  8004203283:	48 89 e5             	mov    %rsp,%rbp
  8004203286:	48 83 ec 30          	sub    $0x30,%rsp
  800420328a:	48 89 7d d8          	mov    %rdi,-0x28(%rbp)
  800420328e:	48 89 75 d0          	mov    %rsi,-0x30(%rbp)
    char c;
    size_t len;

    c = *str++;
  8004203292:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  8004203296:	0f b6 00             	movzbl (%rax),%eax
  8004203299:	88 45 ff             	mov    %al,-0x1(%rbp)
  800420329c:	48 83 45 d0 01       	addq   $0x1,-0x30(%rbp)
    if (!c)
  80042032a1:	80 7d ff 00          	cmpb   $0x0,-0x1(%rbp)
  80042032a5:	75 06                	jne    80042032ad <strstr+0x2b>
        return (char *) in;	// Trivial empty string case
  80042032a7:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  80042032ab:	eb 68                	jmp    8004203315 <strstr+0x93>

    len = strlen(str);
  80042032ad:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  80042032b1:	48 89 c7             	mov    %rax,%rdi
  80042032b4:	48 b8 58 2b 20 04 80 	movabs $0x8004202b58,%rax
  80042032bb:	00 00 00 
  80042032be:	ff d0                	callq  *%rax
  80042032c0:	48 98                	cltq   
  80042032c2:	48 89 45 f0          	mov    %rax,-0x10(%rbp)
    do {
        char sc;

        do {
            sc = *in++;
  80042032c6:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  80042032ca:	0f b6 00             	movzbl (%rax),%eax
  80042032cd:	88 45 ef             	mov    %al,-0x11(%rbp)
  80042032d0:	48 83 45 d8 01       	addq   $0x1,-0x28(%rbp)
            if (!sc)
  80042032d5:	80 7d ef 00          	cmpb   $0x0,-0x11(%rbp)
  80042032d9:	75 07                	jne    80042032e2 <strstr+0x60>
                return (char *) 0;
  80042032db:	b8 00 00 00 00       	mov    $0x0,%eax
  80042032e0:	eb 33                	jmp    8004203315 <strstr+0x93>
        } while (sc != c);
  80042032e2:	0f b6 45 ef          	movzbl -0x11(%rbp),%eax
  80042032e6:	3a 45 ff             	cmp    -0x1(%rbp),%al
  80042032e9:	75 db                	jne    80042032c6 <strstr+0x44>
    } while (strncmp(in, str, len) != 0);
  80042032eb:	48 8b 55 f0          	mov    -0x10(%rbp),%rdx
  80042032ef:	48 8b 4d d0          	mov    -0x30(%rbp),%rcx
  80042032f3:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  80042032f7:	48 89 ce             	mov    %rcx,%rsi
  80042032fa:	48 89 c7             	mov    %rax,%rdi
  80042032fd:	48 b8 74 2d 20 04 80 	movabs $0x8004202d74,%rax
  8004203304:	00 00 00 
  8004203307:	ff d0                	callq  *%rax
  8004203309:	85 c0                	test   %eax,%eax
  800420330b:	75 b9                	jne    80042032c6 <strstr+0x44>

    return (char *) (in - 1);
  800420330d:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  8004203311:	48 83 e8 01          	sub    $0x1,%rax
}
  8004203315:	c9                   	leaveq 
  8004203316:	c3                   	retq   
	...

0000008004203318 <_dwarf_read_lsb>:

int  _dwarf_find_section_enhanced(Dwarf_Section *ds);

uint64_t
_dwarf_read_lsb(uint8_t *data, uint64_t *offsetp, int bytes_to_read)
{
  8004203318:	55                   	push   %rbp
  8004203319:	48 89 e5             	mov    %rsp,%rbp
  800420331c:	48 83 ec 28          	sub    $0x28,%rsp
  8004203320:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
  8004203324:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
  8004203328:	89 55 dc             	mov    %edx,-0x24(%rbp)
	uint64_t ret;
	uint8_t *src;

	src = data + *offsetp;
  800420332b:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  800420332f:	48 8b 00             	mov    (%rax),%rax
  8004203332:	48 03 45 e8          	add    -0x18(%rbp),%rax
  8004203336:	48 89 45 f0          	mov    %rax,-0x10(%rbp)

	ret = 0;
  800420333a:	48 c7 45 f8 00 00 00 	movq   $0x0,-0x8(%rbp)
  8004203341:	00 
	switch (bytes_to_read) {
  8004203342:	8b 45 dc             	mov    -0x24(%rbp),%eax
  8004203345:	83 f8 02             	cmp    $0x2,%eax
  8004203348:	0f 84 ab 00 00 00    	je     80042033f9 <_dwarf_read_lsb+0xe1>
  800420334e:	83 f8 02             	cmp    $0x2,%eax
  8004203351:	7f 0e                	jg     8004203361 <_dwarf_read_lsb+0x49>
  8004203353:	83 f8 01             	cmp    $0x1,%eax
  8004203356:	0f 84 b3 00 00 00    	je     800420340f <_dwarf_read_lsb+0xf7>
  800420335c:	e9 d9 00 00 00       	jmpq   800420343a <_dwarf_read_lsb+0x122>
  8004203361:	83 f8 04             	cmp    $0x4,%eax
  8004203364:	74 65                	je     80042033cb <_dwarf_read_lsb+0xb3>
  8004203366:	83 f8 08             	cmp    $0x8,%eax
  8004203369:	0f 85 cb 00 00 00    	jne    800420343a <_dwarf_read_lsb+0x122>
	case 8:
		ret |= ((uint64_t) src[4]) << 32 | ((uint64_t) src[5]) << 40;
  800420336f:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8004203373:	48 83 c0 04          	add    $0x4,%rax
  8004203377:	0f b6 00             	movzbl (%rax),%eax
  800420337a:	0f b6 c0             	movzbl %al,%eax
  800420337d:	48 89 c2             	mov    %rax,%rdx
  8004203380:	48 c1 e2 20          	shl    $0x20,%rdx
  8004203384:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8004203388:	48 83 c0 05          	add    $0x5,%rax
  800420338c:	0f b6 00             	movzbl (%rax),%eax
  800420338f:	0f b6 c0             	movzbl %al,%eax
  8004203392:	48 c1 e0 28          	shl    $0x28,%rax
  8004203396:	48 09 d0             	or     %rdx,%rax
  8004203399:	48 09 45 f8          	or     %rax,-0x8(%rbp)
		ret |= ((uint64_t) src[6]) << 48 | ((uint64_t) src[7]) << 56;
  800420339d:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  80042033a1:	48 83 c0 06          	add    $0x6,%rax
  80042033a5:	0f b6 00             	movzbl (%rax),%eax
  80042033a8:	0f b6 c0             	movzbl %al,%eax
  80042033ab:	48 89 c2             	mov    %rax,%rdx
  80042033ae:	48 c1 e2 30          	shl    $0x30,%rdx
  80042033b2:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  80042033b6:	48 83 c0 07          	add    $0x7,%rax
  80042033ba:	0f b6 00             	movzbl (%rax),%eax
  80042033bd:	0f b6 c0             	movzbl %al,%eax
  80042033c0:	48 c1 e0 38          	shl    $0x38,%rax
  80042033c4:	48 09 d0             	or     %rdx,%rax
  80042033c7:	48 09 45 f8          	or     %rax,-0x8(%rbp)
	case 4:
		ret |= ((uint64_t) src[2]) << 16 | ((uint64_t) src[3]) << 24;
  80042033cb:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  80042033cf:	48 83 c0 02          	add    $0x2,%rax
  80042033d3:	0f b6 00             	movzbl (%rax),%eax
  80042033d6:	0f b6 c0             	movzbl %al,%eax
  80042033d9:	48 89 c2             	mov    %rax,%rdx
  80042033dc:	48 c1 e2 10          	shl    $0x10,%rdx
  80042033e0:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  80042033e4:	48 83 c0 03          	add    $0x3,%rax
  80042033e8:	0f b6 00             	movzbl (%rax),%eax
  80042033eb:	0f b6 c0             	movzbl %al,%eax
  80042033ee:	48 c1 e0 18          	shl    $0x18,%rax
  80042033f2:	48 09 d0             	or     %rdx,%rax
  80042033f5:	48 09 45 f8          	or     %rax,-0x8(%rbp)
	case 2:
		ret |= ((uint64_t) src[1]) << 8;
  80042033f9:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  80042033fd:	48 83 c0 01          	add    $0x1,%rax
  8004203401:	0f b6 00             	movzbl (%rax),%eax
  8004203404:	0f b6 c0             	movzbl %al,%eax
  8004203407:	48 c1 e0 08          	shl    $0x8,%rax
  800420340b:	48 09 45 f8          	or     %rax,-0x8(%rbp)
	case 1:
		ret |= src[0];
  800420340f:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8004203413:	0f b6 00             	movzbl (%rax),%eax
  8004203416:	0f b6 c0             	movzbl %al,%eax
  8004203419:	48 09 45 f8          	or     %rax,-0x8(%rbp)
		break;
  800420341d:	90                   	nop
	default:
		return (0);
	}

	*offsetp += bytes_to_read;
  800420341e:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  8004203422:	48 8b 10             	mov    (%rax),%rdx
  8004203425:	8b 45 dc             	mov    -0x24(%rbp),%eax
  8004203428:	48 98                	cltq   
  800420342a:	48 01 c2             	add    %rax,%rdx
  800420342d:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  8004203431:	48 89 10             	mov    %rdx,(%rax)

	return (ret);
  8004203434:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8004203438:	eb 05                	jmp    800420343f <_dwarf_read_lsb+0x127>
		ret |= ((uint64_t) src[1]) << 8;
	case 1:
		ret |= src[0];
		break;
	default:
		return (0);
  800420343a:	b8 00 00 00 00       	mov    $0x0,%eax
	}

	*offsetp += bytes_to_read;

	return (ret);
}
  800420343f:	c9                   	leaveq 
  8004203440:	c3                   	retq   

0000008004203441 <_dwarf_decode_lsb>:

uint64_t
_dwarf_decode_lsb(uint8_t **data, int bytes_to_read)
{
  8004203441:	55                   	push   %rbp
  8004203442:	48 89 e5             	mov    %rsp,%rbp
  8004203445:	48 83 ec 20          	sub    $0x20,%rsp
  8004203449:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
  800420344d:	89 75 e4             	mov    %esi,-0x1c(%rbp)
	uint64_t ret;
	uint8_t *src;

	src = *data;
  8004203450:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004203454:	48 8b 00             	mov    (%rax),%rax
  8004203457:	48 89 45 f0          	mov    %rax,-0x10(%rbp)

	ret = 0;
  800420345b:	48 c7 45 f8 00 00 00 	movq   $0x0,-0x8(%rbp)
  8004203462:	00 
	switch (bytes_to_read) {
  8004203463:	8b 45 e4             	mov    -0x1c(%rbp),%eax
  8004203466:	83 f8 02             	cmp    $0x2,%eax
  8004203469:	0f 84 ab 00 00 00    	je     800420351a <_dwarf_decode_lsb+0xd9>
  800420346f:	83 f8 02             	cmp    $0x2,%eax
  8004203472:	7f 0e                	jg     8004203482 <_dwarf_decode_lsb+0x41>
  8004203474:	83 f8 01             	cmp    $0x1,%eax
  8004203477:	0f 84 b3 00 00 00    	je     8004203530 <_dwarf_decode_lsb+0xef>
  800420347d:	e9 d9 00 00 00       	jmpq   800420355b <_dwarf_decode_lsb+0x11a>
  8004203482:	83 f8 04             	cmp    $0x4,%eax
  8004203485:	74 65                	je     80042034ec <_dwarf_decode_lsb+0xab>
  8004203487:	83 f8 08             	cmp    $0x8,%eax
  800420348a:	0f 85 cb 00 00 00    	jne    800420355b <_dwarf_decode_lsb+0x11a>
	case 8:
		ret |= ((uint64_t) src[4]) << 32 | ((uint64_t) src[5]) << 40;
  8004203490:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8004203494:	48 83 c0 04          	add    $0x4,%rax
  8004203498:	0f b6 00             	movzbl (%rax),%eax
  800420349b:	0f b6 c0             	movzbl %al,%eax
  800420349e:	48 89 c2             	mov    %rax,%rdx
  80042034a1:	48 c1 e2 20          	shl    $0x20,%rdx
  80042034a5:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  80042034a9:	48 83 c0 05          	add    $0x5,%rax
  80042034ad:	0f b6 00             	movzbl (%rax),%eax
  80042034b0:	0f b6 c0             	movzbl %al,%eax
  80042034b3:	48 c1 e0 28          	shl    $0x28,%rax
  80042034b7:	48 09 d0             	or     %rdx,%rax
  80042034ba:	48 09 45 f8          	or     %rax,-0x8(%rbp)
		ret |= ((uint64_t) src[6]) << 48 | ((uint64_t) src[7]) << 56;
  80042034be:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  80042034c2:	48 83 c0 06          	add    $0x6,%rax
  80042034c6:	0f b6 00             	movzbl (%rax),%eax
  80042034c9:	0f b6 c0             	movzbl %al,%eax
  80042034cc:	48 89 c2             	mov    %rax,%rdx
  80042034cf:	48 c1 e2 30          	shl    $0x30,%rdx
  80042034d3:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  80042034d7:	48 83 c0 07          	add    $0x7,%rax
  80042034db:	0f b6 00             	movzbl (%rax),%eax
  80042034de:	0f b6 c0             	movzbl %al,%eax
  80042034e1:	48 c1 e0 38          	shl    $0x38,%rax
  80042034e5:	48 09 d0             	or     %rdx,%rax
  80042034e8:	48 09 45 f8          	or     %rax,-0x8(%rbp)
	case 4:
		ret |= ((uint64_t) src[2]) << 16 | ((uint64_t) src[3]) << 24;
  80042034ec:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  80042034f0:	48 83 c0 02          	add    $0x2,%rax
  80042034f4:	0f b6 00             	movzbl (%rax),%eax
  80042034f7:	0f b6 c0             	movzbl %al,%eax
  80042034fa:	48 89 c2             	mov    %rax,%rdx
  80042034fd:	48 c1 e2 10          	shl    $0x10,%rdx
  8004203501:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8004203505:	48 83 c0 03          	add    $0x3,%rax
  8004203509:	0f b6 00             	movzbl (%rax),%eax
  800420350c:	0f b6 c0             	movzbl %al,%eax
  800420350f:	48 c1 e0 18          	shl    $0x18,%rax
  8004203513:	48 09 d0             	or     %rdx,%rax
  8004203516:	48 09 45 f8          	or     %rax,-0x8(%rbp)
	case 2:
		ret |= ((uint64_t) src[1]) << 8;
  800420351a:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  800420351e:	48 83 c0 01          	add    $0x1,%rax
  8004203522:	0f b6 00             	movzbl (%rax),%eax
  8004203525:	0f b6 c0             	movzbl %al,%eax
  8004203528:	48 c1 e0 08          	shl    $0x8,%rax
  800420352c:	48 09 45 f8          	or     %rax,-0x8(%rbp)
	case 1:
		ret |= src[0];
  8004203530:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8004203534:	0f b6 00             	movzbl (%rax),%eax
  8004203537:	0f b6 c0             	movzbl %al,%eax
  800420353a:	48 09 45 f8          	or     %rax,-0x8(%rbp)
		break;
  800420353e:	90                   	nop
	default:
		return (0);
	}

	*data += bytes_to_read;
  800420353f:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004203543:	48 8b 10             	mov    (%rax),%rdx
  8004203546:	8b 45 e4             	mov    -0x1c(%rbp),%eax
  8004203549:	48 98                	cltq   
  800420354b:	48 01 c2             	add    %rax,%rdx
  800420354e:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004203552:	48 89 10             	mov    %rdx,(%rax)

	return (ret);
  8004203555:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8004203559:	eb 05                	jmp    8004203560 <_dwarf_decode_lsb+0x11f>
		ret |= ((uint64_t) src[1]) << 8;
	case 1:
		ret |= src[0];
		break;
	default:
		return (0);
  800420355b:	b8 00 00 00 00       	mov    $0x0,%eax
	}

	*data += bytes_to_read;

	return (ret);
}
  8004203560:	c9                   	leaveq 
  8004203561:	c3                   	retq   

0000008004203562 <_dwarf_read_msb>:

uint64_t
_dwarf_read_msb(uint8_t *data, uint64_t *offsetp, int bytes_to_read)
{
  8004203562:	55                   	push   %rbp
  8004203563:	48 89 e5             	mov    %rsp,%rbp
  8004203566:	48 83 ec 28          	sub    $0x28,%rsp
  800420356a:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
  800420356e:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
  8004203572:	89 55 dc             	mov    %edx,-0x24(%rbp)
	uint64_t ret;
	uint8_t *src;

	src = data + *offsetp;
  8004203575:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  8004203579:	48 8b 00             	mov    (%rax),%rax
  800420357c:	48 03 45 e8          	add    -0x18(%rbp),%rax
  8004203580:	48 89 45 f0          	mov    %rax,-0x10(%rbp)

	switch (bytes_to_read) {
  8004203584:	8b 45 dc             	mov    -0x24(%rbp),%eax
  8004203587:	83 f8 02             	cmp    $0x2,%eax
  800420358a:	74 35                	je     80042035c1 <_dwarf_read_msb+0x5f>
  800420358c:	83 f8 02             	cmp    $0x2,%eax
  800420358f:	7f 0a                	jg     800420359b <_dwarf_read_msb+0x39>
  8004203591:	83 f8 01             	cmp    $0x1,%eax
  8004203594:	74 18                	je     80042035ae <_dwarf_read_msb+0x4c>
  8004203596:	e9 53 01 00 00       	jmpq   80042036ee <_dwarf_read_msb+0x18c>
  800420359b:	83 f8 04             	cmp    $0x4,%eax
  800420359e:	74 49                	je     80042035e9 <_dwarf_read_msb+0x87>
  80042035a0:	83 f8 08             	cmp    $0x8,%eax
  80042035a3:	0f 84 96 00 00 00    	je     800420363f <_dwarf_read_msb+0xdd>
  80042035a9:	e9 40 01 00 00       	jmpq   80042036ee <_dwarf_read_msb+0x18c>
	case 1:
		ret = src[0];
  80042035ae:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  80042035b2:	0f b6 00             	movzbl (%rax),%eax
  80042035b5:	0f b6 c0             	movzbl %al,%eax
  80042035b8:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
		break;
  80042035bc:	e9 34 01 00 00       	jmpq   80042036f5 <_dwarf_read_msb+0x193>
	case 2:
		ret = src[1] | ((uint64_t) src[0]) << 8;
  80042035c1:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  80042035c5:	48 83 c0 01          	add    $0x1,%rax
  80042035c9:	0f b6 00             	movzbl (%rax),%eax
  80042035cc:	0f b6 d0             	movzbl %al,%edx
  80042035cf:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  80042035d3:	0f b6 00             	movzbl (%rax),%eax
  80042035d6:	0f b6 c0             	movzbl %al,%eax
  80042035d9:	48 c1 e0 08          	shl    $0x8,%rax
  80042035dd:	48 09 d0             	or     %rdx,%rax
  80042035e0:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
		break;
  80042035e4:	e9 0c 01 00 00       	jmpq   80042036f5 <_dwarf_read_msb+0x193>
	case 4:
		ret = src[3] | ((uint64_t) src[2]) << 8;
  80042035e9:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  80042035ed:	48 83 c0 03          	add    $0x3,%rax
  80042035f1:	0f b6 00             	movzbl (%rax),%eax
  80042035f4:	0f b6 c0             	movzbl %al,%eax
  80042035f7:	48 8b 55 f0          	mov    -0x10(%rbp),%rdx
  80042035fb:	48 83 c2 02          	add    $0x2,%rdx
  80042035ff:	0f b6 12             	movzbl (%rdx),%edx
  8004203602:	0f b6 d2             	movzbl %dl,%edx
  8004203605:	48 c1 e2 08          	shl    $0x8,%rdx
  8004203609:	48 09 d0             	or     %rdx,%rax
  800420360c:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
		ret |= ((uint64_t) src[1]) << 16 | ((uint64_t) src[0]) << 24;
  8004203610:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8004203614:	48 83 c0 01          	add    $0x1,%rax
  8004203618:	0f b6 00             	movzbl (%rax),%eax
  800420361b:	0f b6 c0             	movzbl %al,%eax
  800420361e:	48 89 c2             	mov    %rax,%rdx
  8004203621:	48 c1 e2 10          	shl    $0x10,%rdx
  8004203625:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8004203629:	0f b6 00             	movzbl (%rax),%eax
  800420362c:	0f b6 c0             	movzbl %al,%eax
  800420362f:	48 c1 e0 18          	shl    $0x18,%rax
  8004203633:	48 09 d0             	or     %rdx,%rax
  8004203636:	48 09 45 f8          	or     %rax,-0x8(%rbp)
		break;
  800420363a:	e9 b6 00 00 00       	jmpq   80042036f5 <_dwarf_read_msb+0x193>
	case 8:
		ret = src[7] | ((uint64_t) src[6]) << 8;
  800420363f:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8004203643:	48 83 c0 07          	add    $0x7,%rax
  8004203647:	0f b6 00             	movzbl (%rax),%eax
  800420364a:	0f b6 c0             	movzbl %al,%eax
  800420364d:	48 8b 55 f0          	mov    -0x10(%rbp),%rdx
  8004203651:	48 83 c2 06          	add    $0x6,%rdx
  8004203655:	0f b6 12             	movzbl (%rdx),%edx
  8004203658:	0f b6 d2             	movzbl %dl,%edx
  800420365b:	48 c1 e2 08          	shl    $0x8,%rdx
  800420365f:	48 09 d0             	or     %rdx,%rax
  8004203662:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
		ret |= ((uint64_t) src[5]) << 16 | ((uint64_t) src[4]) << 24;
  8004203666:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  800420366a:	48 83 c0 05          	add    $0x5,%rax
  800420366e:	0f b6 00             	movzbl (%rax),%eax
  8004203671:	0f b6 c0             	movzbl %al,%eax
  8004203674:	48 89 c2             	mov    %rax,%rdx
  8004203677:	48 c1 e2 10          	shl    $0x10,%rdx
  800420367b:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  800420367f:	48 83 c0 04          	add    $0x4,%rax
  8004203683:	0f b6 00             	movzbl (%rax),%eax
  8004203686:	0f b6 c0             	movzbl %al,%eax
  8004203689:	48 c1 e0 18          	shl    $0x18,%rax
  800420368d:	48 09 d0             	or     %rdx,%rax
  8004203690:	48 09 45 f8          	or     %rax,-0x8(%rbp)
		ret |= ((uint64_t) src[3]) << 32 | ((uint64_t) src[2]) << 40;
  8004203694:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8004203698:	48 83 c0 03          	add    $0x3,%rax
  800420369c:	0f b6 00             	movzbl (%rax),%eax
  800420369f:	0f b6 c0             	movzbl %al,%eax
  80042036a2:	48 89 c2             	mov    %rax,%rdx
  80042036a5:	48 c1 e2 20          	shl    $0x20,%rdx
  80042036a9:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  80042036ad:	48 83 c0 02          	add    $0x2,%rax
  80042036b1:	0f b6 00             	movzbl (%rax),%eax
  80042036b4:	0f b6 c0             	movzbl %al,%eax
  80042036b7:	48 c1 e0 28          	shl    $0x28,%rax
  80042036bb:	48 09 d0             	or     %rdx,%rax
  80042036be:	48 09 45 f8          	or     %rax,-0x8(%rbp)
		ret |= ((uint64_t) src[1]) << 48 | ((uint64_t) src[0]) << 56;
  80042036c2:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  80042036c6:	48 83 c0 01          	add    $0x1,%rax
  80042036ca:	0f b6 00             	movzbl (%rax),%eax
  80042036cd:	0f b6 c0             	movzbl %al,%eax
  80042036d0:	48 89 c2             	mov    %rax,%rdx
  80042036d3:	48 c1 e2 30          	shl    $0x30,%rdx
  80042036d7:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  80042036db:	0f b6 00             	movzbl (%rax),%eax
  80042036de:	0f b6 c0             	movzbl %al,%eax
  80042036e1:	48 c1 e0 38          	shl    $0x38,%rax
  80042036e5:	48 09 d0             	or     %rdx,%rax
  80042036e8:	48 09 45 f8          	or     %rax,-0x8(%rbp)
		break;
  80042036ec:	eb 07                	jmp    80042036f5 <_dwarf_read_msb+0x193>
	default:
		return (0);
  80042036ee:	b8 00 00 00 00       	mov    $0x0,%eax
  80042036f3:	eb 1a                	jmp    800420370f <_dwarf_read_msb+0x1ad>
	}

	*offsetp += bytes_to_read;
  80042036f5:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  80042036f9:	48 8b 10             	mov    (%rax),%rdx
  80042036fc:	8b 45 dc             	mov    -0x24(%rbp),%eax
  80042036ff:	48 98                	cltq   
  8004203701:	48 01 c2             	add    %rax,%rdx
  8004203704:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  8004203708:	48 89 10             	mov    %rdx,(%rax)

	return (ret);
  800420370b:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
}
  800420370f:	c9                   	leaveq 
  8004203710:	c3                   	retq   

0000008004203711 <_dwarf_decode_msb>:

uint64_t
_dwarf_decode_msb(uint8_t **data, int bytes_to_read)
{
  8004203711:	55                   	push   %rbp
  8004203712:	48 89 e5             	mov    %rsp,%rbp
  8004203715:	48 83 ec 20          	sub    $0x20,%rsp
  8004203719:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
  800420371d:	89 75 e4             	mov    %esi,-0x1c(%rbp)
	uint64_t ret;
	uint8_t *src;

	src = *data;
  8004203720:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004203724:	48 8b 00             	mov    (%rax),%rax
  8004203727:	48 89 45 f0          	mov    %rax,-0x10(%rbp)

	ret = 0;
  800420372b:	48 c7 45 f8 00 00 00 	movq   $0x0,-0x8(%rbp)
  8004203732:	00 
	switch (bytes_to_read) {
  8004203733:	8b 45 e4             	mov    -0x1c(%rbp),%eax
  8004203736:	83 f8 02             	cmp    $0x2,%eax
  8004203739:	74 35                	je     8004203770 <_dwarf_decode_msb+0x5f>
  800420373b:	83 f8 02             	cmp    $0x2,%eax
  800420373e:	7f 0a                	jg     800420374a <_dwarf_decode_msb+0x39>
  8004203740:	83 f8 01             	cmp    $0x1,%eax
  8004203743:	74 18                	je     800420375d <_dwarf_decode_msb+0x4c>
  8004203745:	e9 53 01 00 00       	jmpq   800420389d <_dwarf_decode_msb+0x18c>
  800420374a:	83 f8 04             	cmp    $0x4,%eax
  800420374d:	74 49                	je     8004203798 <_dwarf_decode_msb+0x87>
  800420374f:	83 f8 08             	cmp    $0x8,%eax
  8004203752:	0f 84 96 00 00 00    	je     80042037ee <_dwarf_decode_msb+0xdd>
  8004203758:	e9 40 01 00 00       	jmpq   800420389d <_dwarf_decode_msb+0x18c>
	case 1:
		ret = src[0];
  800420375d:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8004203761:	0f b6 00             	movzbl (%rax),%eax
  8004203764:	0f b6 c0             	movzbl %al,%eax
  8004203767:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
		break;
  800420376b:	e9 34 01 00 00       	jmpq   80042038a4 <_dwarf_decode_msb+0x193>
	case 2:
		ret = src[1] | ((uint64_t) src[0]) << 8;
  8004203770:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8004203774:	48 83 c0 01          	add    $0x1,%rax
  8004203778:	0f b6 00             	movzbl (%rax),%eax
  800420377b:	0f b6 d0             	movzbl %al,%edx
  800420377e:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8004203782:	0f b6 00             	movzbl (%rax),%eax
  8004203785:	0f b6 c0             	movzbl %al,%eax
  8004203788:	48 c1 e0 08          	shl    $0x8,%rax
  800420378c:	48 09 d0             	or     %rdx,%rax
  800420378f:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
		break;
  8004203793:	e9 0c 01 00 00       	jmpq   80042038a4 <_dwarf_decode_msb+0x193>
	case 4:
		ret = src[3] | ((uint64_t) src[2]) << 8;
  8004203798:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  800420379c:	48 83 c0 03          	add    $0x3,%rax
  80042037a0:	0f b6 00             	movzbl (%rax),%eax
  80042037a3:	0f b6 c0             	movzbl %al,%eax
  80042037a6:	48 8b 55 f0          	mov    -0x10(%rbp),%rdx
  80042037aa:	48 83 c2 02          	add    $0x2,%rdx
  80042037ae:	0f b6 12             	movzbl (%rdx),%edx
  80042037b1:	0f b6 d2             	movzbl %dl,%edx
  80042037b4:	48 c1 e2 08          	shl    $0x8,%rdx
  80042037b8:	48 09 d0             	or     %rdx,%rax
  80042037bb:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
		ret |= ((uint64_t) src[1]) << 16 | ((uint64_t) src[0]) << 24;
  80042037bf:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  80042037c3:	48 83 c0 01          	add    $0x1,%rax
  80042037c7:	0f b6 00             	movzbl (%rax),%eax
  80042037ca:	0f b6 c0             	movzbl %al,%eax
  80042037cd:	48 89 c2             	mov    %rax,%rdx
  80042037d0:	48 c1 e2 10          	shl    $0x10,%rdx
  80042037d4:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  80042037d8:	0f b6 00             	movzbl (%rax),%eax
  80042037db:	0f b6 c0             	movzbl %al,%eax
  80042037de:	48 c1 e0 18          	shl    $0x18,%rax
  80042037e2:	48 09 d0             	or     %rdx,%rax
  80042037e5:	48 09 45 f8          	or     %rax,-0x8(%rbp)
		break;
  80042037e9:	e9 b6 00 00 00       	jmpq   80042038a4 <_dwarf_decode_msb+0x193>
	case 8:
		ret = src[7] | ((uint64_t) src[6]) << 8;
  80042037ee:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  80042037f2:	48 83 c0 07          	add    $0x7,%rax
  80042037f6:	0f b6 00             	movzbl (%rax),%eax
  80042037f9:	0f b6 c0             	movzbl %al,%eax
  80042037fc:	48 8b 55 f0          	mov    -0x10(%rbp),%rdx
  8004203800:	48 83 c2 06          	add    $0x6,%rdx
  8004203804:	0f b6 12             	movzbl (%rdx),%edx
  8004203807:	0f b6 d2             	movzbl %dl,%edx
  800420380a:	48 c1 e2 08          	shl    $0x8,%rdx
  800420380e:	48 09 d0             	or     %rdx,%rax
  8004203811:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
		ret |= ((uint64_t) src[5]) << 16 | ((uint64_t) src[4]) << 24;
  8004203815:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8004203819:	48 83 c0 05          	add    $0x5,%rax
  800420381d:	0f b6 00             	movzbl (%rax),%eax
  8004203820:	0f b6 c0             	movzbl %al,%eax
  8004203823:	48 89 c2             	mov    %rax,%rdx
  8004203826:	48 c1 e2 10          	shl    $0x10,%rdx
  800420382a:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  800420382e:	48 83 c0 04          	add    $0x4,%rax
  8004203832:	0f b6 00             	movzbl (%rax),%eax
  8004203835:	0f b6 c0             	movzbl %al,%eax
  8004203838:	48 c1 e0 18          	shl    $0x18,%rax
  800420383c:	48 09 d0             	or     %rdx,%rax
  800420383f:	48 09 45 f8          	or     %rax,-0x8(%rbp)
		ret |= ((uint64_t) src[3]) << 32 | ((uint64_t) src[2]) << 40;
  8004203843:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8004203847:	48 83 c0 03          	add    $0x3,%rax
  800420384b:	0f b6 00             	movzbl (%rax),%eax
  800420384e:	0f b6 c0             	movzbl %al,%eax
  8004203851:	48 89 c2             	mov    %rax,%rdx
  8004203854:	48 c1 e2 20          	shl    $0x20,%rdx
  8004203858:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  800420385c:	48 83 c0 02          	add    $0x2,%rax
  8004203860:	0f b6 00             	movzbl (%rax),%eax
  8004203863:	0f b6 c0             	movzbl %al,%eax
  8004203866:	48 c1 e0 28          	shl    $0x28,%rax
  800420386a:	48 09 d0             	or     %rdx,%rax
  800420386d:	48 09 45 f8          	or     %rax,-0x8(%rbp)
		ret |= ((uint64_t) src[1]) << 48 | ((uint64_t) src[0]) << 56;
  8004203871:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8004203875:	48 83 c0 01          	add    $0x1,%rax
  8004203879:	0f b6 00             	movzbl (%rax),%eax
  800420387c:	0f b6 c0             	movzbl %al,%eax
  800420387f:	48 89 c2             	mov    %rax,%rdx
  8004203882:	48 c1 e2 30          	shl    $0x30,%rdx
  8004203886:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  800420388a:	0f b6 00             	movzbl (%rax),%eax
  800420388d:	0f b6 c0             	movzbl %al,%eax
  8004203890:	48 c1 e0 38          	shl    $0x38,%rax
  8004203894:	48 09 d0             	or     %rdx,%rax
  8004203897:	48 09 45 f8          	or     %rax,-0x8(%rbp)
		break;
  800420389b:	eb 07                	jmp    80042038a4 <_dwarf_decode_msb+0x193>
	default:
		return (0);
  800420389d:	b8 00 00 00 00       	mov    $0x0,%eax
  80042038a2:	eb 1a                	jmp    80042038be <_dwarf_decode_msb+0x1ad>
		break;
	}

	*data += bytes_to_read;
  80042038a4:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  80042038a8:	48 8b 10             	mov    (%rax),%rdx
  80042038ab:	8b 45 e4             	mov    -0x1c(%rbp),%eax
  80042038ae:	48 98                	cltq   
  80042038b0:	48 01 c2             	add    %rax,%rdx
  80042038b3:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  80042038b7:	48 89 10             	mov    %rdx,(%rax)

	return (ret);
  80042038ba:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
}
  80042038be:	c9                   	leaveq 
  80042038bf:	c3                   	retq   

00000080042038c0 <_dwarf_read_sleb128>:

int64_t
_dwarf_read_sleb128(uint8_t *data, uint64_t *offsetp)
{
  80042038c0:	55                   	push   %rbp
  80042038c1:	48 89 e5             	mov    %rsp,%rbp
  80042038c4:	53                   	push   %rbx
  80042038c5:	48 83 ec 30          	sub    $0x30,%rsp
  80042038c9:	48 89 7d d0          	mov    %rdi,-0x30(%rbp)
  80042038cd:	48 89 75 c8          	mov    %rsi,-0x38(%rbp)
	int64_t ret = 0;
  80042038d1:	48 c7 45 f0 00 00 00 	movq   $0x0,-0x10(%rbp)
  80042038d8:	00 
	uint8_t b;
	int shift = 0;
  80042038d9:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%rbp)
	uint8_t *src;

	src = data + *offsetp;
  80042038e0:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
  80042038e4:	48 8b 00             	mov    (%rax),%rax
  80042038e7:	48 03 45 d0          	add    -0x30(%rbp),%rax
  80042038eb:	48 89 45 e0          	mov    %rax,-0x20(%rbp)

	do {
		b = *src++;
  80042038ef:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  80042038f3:	0f b6 00             	movzbl (%rax),%eax
  80042038f6:	88 45 df             	mov    %al,-0x21(%rbp)
  80042038f9:	48 83 45 e0 01       	addq   $0x1,-0x20(%rbp)
		ret |= ((b & 0x7f) << shift);
  80042038fe:	0f b6 45 df          	movzbl -0x21(%rbp),%eax
  8004203902:	89 c2                	mov    %eax,%edx
  8004203904:	83 e2 7f             	and    $0x7f,%edx
  8004203907:	8b 45 ec             	mov    -0x14(%rbp),%eax
  800420390a:	89 d3                	mov    %edx,%ebx
  800420390c:	89 c1                	mov    %eax,%ecx
  800420390e:	d3 e3                	shl    %cl,%ebx
  8004203910:	89 d8                	mov    %ebx,%eax
  8004203912:	48 98                	cltq   
  8004203914:	48 09 45 f0          	or     %rax,-0x10(%rbp)
		(*offsetp)++;
  8004203918:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
  800420391c:	48 8b 00             	mov    (%rax),%rax
  800420391f:	48 8d 50 01          	lea    0x1(%rax),%rdx
  8004203923:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
  8004203927:	48 89 10             	mov    %rdx,(%rax)
		shift += 7;
  800420392a:	83 45 ec 07          	addl   $0x7,-0x14(%rbp)
	} while ((b & 0x80) != 0);
  800420392e:	0f b6 45 df          	movzbl -0x21(%rbp),%eax
  8004203932:	84 c0                	test   %al,%al
  8004203934:	78 b9                	js     80042038ef <_dwarf_read_sleb128+0x2f>

	if (shift < 32 && (b & 0x40) != 0)
  8004203936:	83 7d ec 1f          	cmpl   $0x1f,-0x14(%rbp)
  800420393a:	7f 21                	jg     800420395d <_dwarf_read_sleb128+0x9d>
  800420393c:	0f b6 45 df          	movzbl -0x21(%rbp),%eax
  8004203940:	83 e0 40             	and    $0x40,%eax
  8004203943:	85 c0                	test   %eax,%eax
  8004203945:	74 16                	je     800420395d <_dwarf_read_sleb128+0x9d>
		ret |= (-1 << shift);
  8004203947:	8b 45 ec             	mov    -0x14(%rbp),%eax
  800420394a:	ba ff ff ff ff       	mov    $0xffffffff,%edx
  800420394f:	89 d3                	mov    %edx,%ebx
  8004203951:	89 c1                	mov    %eax,%ecx
  8004203953:	d3 e3                	shl    %cl,%ebx
  8004203955:	89 d8                	mov    %ebx,%eax
  8004203957:	48 98                	cltq   
  8004203959:	48 09 45 f0          	or     %rax,-0x10(%rbp)

	return (ret);
  800420395d:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
}
  8004203961:	48 83 c4 30          	add    $0x30,%rsp
  8004203965:	5b                   	pop    %rbx
  8004203966:	5d                   	pop    %rbp
  8004203967:	c3                   	retq   

0000008004203968 <_dwarf_read_uleb128>:

uint64_t
_dwarf_read_uleb128(uint8_t *data, uint64_t *offsetp)
{
  8004203968:	55                   	push   %rbp
  8004203969:	48 89 e5             	mov    %rsp,%rbp
  800420396c:	53                   	push   %rbx
  800420396d:	48 83 ec 30          	sub    $0x30,%rsp
  8004203971:	48 89 7d d0          	mov    %rdi,-0x30(%rbp)
  8004203975:	48 89 75 c8          	mov    %rsi,-0x38(%rbp)
	uint64_t ret = 0;
  8004203979:	48 c7 45 f0 00 00 00 	movq   $0x0,-0x10(%rbp)
  8004203980:	00 
	uint8_t b;
	int shift = 0;
  8004203981:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%rbp)
	uint8_t *src;

	src = data + *offsetp;
  8004203988:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
  800420398c:	48 8b 00             	mov    (%rax),%rax
  800420398f:	48 03 45 d0          	add    -0x30(%rbp),%rax
  8004203993:	48 89 45 e0          	mov    %rax,-0x20(%rbp)

	do {
		b = *src++;
  8004203997:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  800420399b:	0f b6 00             	movzbl (%rax),%eax
  800420399e:	88 45 df             	mov    %al,-0x21(%rbp)
  80042039a1:	48 83 45 e0 01       	addq   $0x1,-0x20(%rbp)
		ret |= ((b & 0x7f) << shift);
  80042039a6:	0f b6 45 df          	movzbl -0x21(%rbp),%eax
  80042039aa:	89 c2                	mov    %eax,%edx
  80042039ac:	83 e2 7f             	and    $0x7f,%edx
  80042039af:	8b 45 ec             	mov    -0x14(%rbp),%eax
  80042039b2:	89 d3                	mov    %edx,%ebx
  80042039b4:	89 c1                	mov    %eax,%ecx
  80042039b6:	d3 e3                	shl    %cl,%ebx
  80042039b8:	89 d8                	mov    %ebx,%eax
  80042039ba:	48 98                	cltq   
  80042039bc:	48 09 45 f0          	or     %rax,-0x10(%rbp)
		(*offsetp)++;
  80042039c0:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
  80042039c4:	48 8b 00             	mov    (%rax),%rax
  80042039c7:	48 8d 50 01          	lea    0x1(%rax),%rdx
  80042039cb:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
  80042039cf:	48 89 10             	mov    %rdx,(%rax)
		shift += 7;
  80042039d2:	83 45 ec 07          	addl   $0x7,-0x14(%rbp)
	} while ((b & 0x80) != 0);
  80042039d6:	0f b6 45 df          	movzbl -0x21(%rbp),%eax
  80042039da:	84 c0                	test   %al,%al
  80042039dc:	78 b9                	js     8004203997 <_dwarf_read_uleb128+0x2f>

	return (ret);
  80042039de:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
}
  80042039e2:	48 83 c4 30          	add    $0x30,%rsp
  80042039e6:	5b                   	pop    %rbx
  80042039e7:	5d                   	pop    %rbp
  80042039e8:	c3                   	retq   

00000080042039e9 <_dwarf_decode_sleb128>:

int64_t
_dwarf_decode_sleb128(uint8_t **dp)
{
  80042039e9:	55                   	push   %rbp
  80042039ea:	48 89 e5             	mov    %rsp,%rbp
  80042039ed:	53                   	push   %rbx
  80042039ee:	48 83 ec 28          	sub    $0x28,%rsp
  80042039f2:	48 89 7d d0          	mov    %rdi,-0x30(%rbp)
	int64_t ret = 0;
  80042039f6:	48 c7 45 f0 00 00 00 	movq   $0x0,-0x10(%rbp)
  80042039fd:	00 
	uint8_t b;
	int shift = 0;
  80042039fe:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%rbp)

	uint8_t *src = *dp;
  8004203a05:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  8004203a09:	48 8b 00             	mov    (%rax),%rax
  8004203a0c:	48 89 45 e0          	mov    %rax,-0x20(%rbp)

	do {
		b = *src++;
  8004203a10:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  8004203a14:	0f b6 00             	movzbl (%rax),%eax
  8004203a17:	88 45 df             	mov    %al,-0x21(%rbp)
  8004203a1a:	48 83 45 e0 01       	addq   $0x1,-0x20(%rbp)
		ret |= ((b & 0x7f) << shift);
  8004203a1f:	0f b6 45 df          	movzbl -0x21(%rbp),%eax
  8004203a23:	89 c2                	mov    %eax,%edx
  8004203a25:	83 e2 7f             	and    $0x7f,%edx
  8004203a28:	8b 45 ec             	mov    -0x14(%rbp),%eax
  8004203a2b:	89 d3                	mov    %edx,%ebx
  8004203a2d:	89 c1                	mov    %eax,%ecx
  8004203a2f:	d3 e3                	shl    %cl,%ebx
  8004203a31:	89 d8                	mov    %ebx,%eax
  8004203a33:	48 98                	cltq   
  8004203a35:	48 09 45 f0          	or     %rax,-0x10(%rbp)
		shift += 7;
  8004203a39:	83 45 ec 07          	addl   $0x7,-0x14(%rbp)
	} while ((b & 0x80) != 0);
  8004203a3d:	0f b6 45 df          	movzbl -0x21(%rbp),%eax
  8004203a41:	84 c0                	test   %al,%al
  8004203a43:	78 cb                	js     8004203a10 <_dwarf_decode_sleb128+0x27>

	if (shift < 32 && (b & 0x40) != 0)
  8004203a45:	83 7d ec 1f          	cmpl   $0x1f,-0x14(%rbp)
  8004203a49:	7f 21                	jg     8004203a6c <_dwarf_decode_sleb128+0x83>
  8004203a4b:	0f b6 45 df          	movzbl -0x21(%rbp),%eax
  8004203a4f:	83 e0 40             	and    $0x40,%eax
  8004203a52:	85 c0                	test   %eax,%eax
  8004203a54:	74 16                	je     8004203a6c <_dwarf_decode_sleb128+0x83>
		ret |= (-1 << shift);
  8004203a56:	8b 45 ec             	mov    -0x14(%rbp),%eax
  8004203a59:	ba ff ff ff ff       	mov    $0xffffffff,%edx
  8004203a5e:	89 d3                	mov    %edx,%ebx
  8004203a60:	89 c1                	mov    %eax,%ecx
  8004203a62:	d3 e3                	shl    %cl,%ebx
  8004203a64:	89 d8                	mov    %ebx,%eax
  8004203a66:	48 98                	cltq   
  8004203a68:	48 09 45 f0          	or     %rax,-0x10(%rbp)

	*dp = src;
  8004203a6c:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  8004203a70:	48 8b 55 e0          	mov    -0x20(%rbp),%rdx
  8004203a74:	48 89 10             	mov    %rdx,(%rax)

	return (ret);
  8004203a77:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
}
  8004203a7b:	48 83 c4 28          	add    $0x28,%rsp
  8004203a7f:	5b                   	pop    %rbx
  8004203a80:	5d                   	pop    %rbp
  8004203a81:	c3                   	retq   

0000008004203a82 <_dwarf_decode_uleb128>:

uint64_t
_dwarf_decode_uleb128(uint8_t **dp)
{
  8004203a82:	55                   	push   %rbp
  8004203a83:	48 89 e5             	mov    %rsp,%rbp
  8004203a86:	53                   	push   %rbx
  8004203a87:	48 83 ec 28          	sub    $0x28,%rsp
  8004203a8b:	48 89 7d d0          	mov    %rdi,-0x30(%rbp)
	uint64_t ret = 0;
  8004203a8f:	48 c7 45 f0 00 00 00 	movq   $0x0,-0x10(%rbp)
  8004203a96:	00 
	uint8_t b;
	int shift = 0;
  8004203a97:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%rbp)

	uint8_t *src = *dp;
  8004203a9e:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  8004203aa2:	48 8b 00             	mov    (%rax),%rax
  8004203aa5:	48 89 45 e0          	mov    %rax,-0x20(%rbp)

	do {
		b = *src++;
  8004203aa9:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  8004203aad:	0f b6 00             	movzbl (%rax),%eax
  8004203ab0:	88 45 df             	mov    %al,-0x21(%rbp)
  8004203ab3:	48 83 45 e0 01       	addq   $0x1,-0x20(%rbp)
		ret |= ((b & 0x7f) << shift);
  8004203ab8:	0f b6 45 df          	movzbl -0x21(%rbp),%eax
  8004203abc:	89 c2                	mov    %eax,%edx
  8004203abe:	83 e2 7f             	and    $0x7f,%edx
  8004203ac1:	8b 45 ec             	mov    -0x14(%rbp),%eax
  8004203ac4:	89 d3                	mov    %edx,%ebx
  8004203ac6:	89 c1                	mov    %eax,%ecx
  8004203ac8:	d3 e3                	shl    %cl,%ebx
  8004203aca:	89 d8                	mov    %ebx,%eax
  8004203acc:	48 98                	cltq   
  8004203ace:	48 09 45 f0          	or     %rax,-0x10(%rbp)
		shift += 7;
  8004203ad2:	83 45 ec 07          	addl   $0x7,-0x14(%rbp)
	} while ((b & 0x80) != 0);
  8004203ad6:	0f b6 45 df          	movzbl -0x21(%rbp),%eax
  8004203ada:	84 c0                	test   %al,%al
  8004203adc:	78 cb                	js     8004203aa9 <_dwarf_decode_uleb128+0x27>

	*dp = src;
  8004203ade:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  8004203ae2:	48 8b 55 e0          	mov    -0x20(%rbp),%rdx
  8004203ae6:	48 89 10             	mov    %rdx,(%rax)

	return (ret);
  8004203ae9:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
}
  8004203aed:	48 83 c4 28          	add    $0x28,%rsp
  8004203af1:	5b                   	pop    %rbx
  8004203af2:	5d                   	pop    %rbp
  8004203af3:	c3                   	retq   

0000008004203af4 <_dwarf_read_string>:

#define Dwarf_Unsigned uint64_t

char *
_dwarf_read_string(void *data, Dwarf_Unsigned size, uint64_t *offsetp)
{
  8004203af4:	55                   	push   %rbp
  8004203af5:	48 89 e5             	mov    %rsp,%rbp
  8004203af8:	48 83 ec 28          	sub    $0x28,%rsp
  8004203afc:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
  8004203b00:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
  8004203b04:	48 89 55 d8          	mov    %rdx,-0x28(%rbp)
	char *ret, *src;

	ret = src = (char *) data + *offsetp;
  8004203b08:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  8004203b0c:	48 8b 00             	mov    (%rax),%rax
  8004203b0f:	48 03 45 e8          	add    -0x18(%rbp),%rax
  8004203b13:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
  8004203b17:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8004203b1b:	48 89 45 f0          	mov    %rax,-0x10(%rbp)

	while (*src != '\0' && *offsetp < size) {
  8004203b1f:	eb 17                	jmp    8004203b38 <_dwarf_read_string+0x44>
		src++;
  8004203b21:	48 83 45 f8 01       	addq   $0x1,-0x8(%rbp)
		(*offsetp)++;
  8004203b26:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  8004203b2a:	48 8b 00             	mov    (%rax),%rax
  8004203b2d:	48 8d 50 01          	lea    0x1(%rax),%rdx
  8004203b31:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  8004203b35:	48 89 10             	mov    %rdx,(%rax)
{
	char *ret, *src;

	ret = src = (char *) data + *offsetp;

	while (*src != '\0' && *offsetp < size) {
  8004203b38:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8004203b3c:	0f b6 00             	movzbl (%rax),%eax
  8004203b3f:	84 c0                	test   %al,%al
  8004203b41:	74 0d                	je     8004203b50 <_dwarf_read_string+0x5c>
  8004203b43:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  8004203b47:	48 8b 00             	mov    (%rax),%rax
  8004203b4a:	48 3b 45 e0          	cmp    -0x20(%rbp),%rax
  8004203b4e:	72 d1                	jb     8004203b21 <_dwarf_read_string+0x2d>
		src++;
		(*offsetp)++;
	}

	if (*src == '\0' && *offsetp < size)
  8004203b50:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8004203b54:	0f b6 00             	movzbl (%rax),%eax
  8004203b57:	84 c0                	test   %al,%al
  8004203b59:	75 1f                	jne    8004203b7a <_dwarf_read_string+0x86>
  8004203b5b:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  8004203b5f:	48 8b 00             	mov    (%rax),%rax
  8004203b62:	48 3b 45 e0          	cmp    -0x20(%rbp),%rax
  8004203b66:	73 12                	jae    8004203b7a <_dwarf_read_string+0x86>
		(*offsetp)++;
  8004203b68:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  8004203b6c:	48 8b 00             	mov    (%rax),%rax
  8004203b6f:	48 8d 50 01          	lea    0x1(%rax),%rdx
  8004203b73:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  8004203b77:	48 89 10             	mov    %rdx,(%rax)

	return (ret);
  8004203b7a:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
}
  8004203b7e:	c9                   	leaveq 
  8004203b7f:	c3                   	retq   

0000008004203b80 <_dwarf_read_block>:

uint8_t *
_dwarf_read_block(void *data, uint64_t *offsetp, uint64_t length)
{
  8004203b80:	55                   	push   %rbp
  8004203b81:	48 89 e5             	mov    %rsp,%rbp
  8004203b84:	48 83 ec 28          	sub    $0x28,%rsp
  8004203b88:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
  8004203b8c:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
  8004203b90:	48 89 55 d8          	mov    %rdx,-0x28(%rbp)
	uint8_t *ret, *src;

	ret = src = (uint8_t *) data + *offsetp;
  8004203b94:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  8004203b98:	48 8b 00             	mov    (%rax),%rax
  8004203b9b:	48 03 45 e8          	add    -0x18(%rbp),%rax
  8004203b9f:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
  8004203ba3:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8004203ba7:	48 89 45 f0          	mov    %rax,-0x10(%rbp)

	(*offsetp) += length;
  8004203bab:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  8004203baf:	48 8b 00             	mov    (%rax),%rax
  8004203bb2:	48 89 c2             	mov    %rax,%rdx
  8004203bb5:	48 03 55 d8          	add    -0x28(%rbp),%rdx
  8004203bb9:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  8004203bbd:	48 89 10             	mov    %rdx,(%rax)

	return (ret);
  8004203bc0:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
}
  8004203bc4:	c9                   	leaveq 
  8004203bc5:	c3                   	retq   

0000008004203bc6 <_dwarf_elf_get_byte_order>:

Dwarf_Endianness
_dwarf_elf_get_byte_order(void *obj)
{
  8004203bc6:	55                   	push   %rbp
  8004203bc7:	48 89 e5             	mov    %rsp,%rbp
  8004203bca:	48 83 ec 20          	sub    $0x20,%rsp
  8004203bce:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
    Elf *e;

    e = (Elf *)obj;
  8004203bd2:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004203bd6:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
    assert(e != NULL);
  8004203bda:	48 83 7d f8 00       	cmpq   $0x0,-0x8(%rbp)
  8004203bdf:	75 35                	jne    8004203c16 <_dwarf_elf_get_byte_order+0x50>
  8004203be1:	48 b9 b0 9d 20 04 80 	movabs $0x8004209db0,%rcx
  8004203be8:	00 00 00 
  8004203beb:	48 ba ba 9d 20 04 80 	movabs $0x8004209dba,%rdx
  8004203bf2:	00 00 00 
  8004203bf5:	be 2b 01 00 00       	mov    $0x12b,%esi
  8004203bfa:	48 bf cf 9d 20 04 80 	movabs $0x8004209dcf,%rdi
  8004203c01:	00 00 00 
  8004203c04:	b8 00 00 00 00       	mov    $0x0,%eax
  8004203c09:	49 b8 9b 01 20 04 80 	movabs $0x800420019b,%r8
  8004203c10:	00 00 00 
  8004203c13:	41 ff d0             	callq  *%r8

//TODO: Need to check for 64bit here. Because currently Elf header for
//      64bit doesn't have any memeber e_ident. But need to see what is
//      similar in 64bit.
    switch (e->e_ident[EI_DATA]) {
  8004203c16:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8004203c1a:	0f b6 40 05          	movzbl 0x5(%rax),%eax
  8004203c1e:	0f b6 c0             	movzbl %al,%eax
  8004203c21:	83 f8 02             	cmp    $0x2,%eax
  8004203c24:	75 07                	jne    8004203c2d <_dwarf_elf_get_byte_order+0x67>
    case ELFDATA2MSB:
        return (DW_OBJECT_MSB);
  8004203c26:	b8 00 00 00 00       	mov    $0x0,%eax
  8004203c2b:	eb 05                	jmp    8004203c32 <_dwarf_elf_get_byte_order+0x6c>

    case ELFDATA2LSB:
    case ELFDATANONE:
    default:
        return (DW_OBJECT_LSB);
  8004203c2d:	b8 01 00 00 00       	mov    $0x1,%eax
    }
}
  8004203c32:	c9                   	leaveq 
  8004203c33:	c3                   	retq   

0000008004203c34 <_dwarf_elf_get_pointer_size>:

Dwarf_Small
_dwarf_elf_get_pointer_size(void *obj)
{
  8004203c34:	55                   	push   %rbp
  8004203c35:	48 89 e5             	mov    %rsp,%rbp
  8004203c38:	48 83 ec 20          	sub    $0x20,%rsp
  8004203c3c:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
    Elf *e;

    e = (Elf *) obj;
  8004203c40:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004203c44:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
    assert(e != NULL);
  8004203c48:	48 83 7d f8 00       	cmpq   $0x0,-0x8(%rbp)
  8004203c4d:	75 35                	jne    8004203c84 <_dwarf_elf_get_pointer_size+0x50>
  8004203c4f:	48 b9 b0 9d 20 04 80 	movabs $0x8004209db0,%rcx
  8004203c56:	00 00 00 
  8004203c59:	48 ba ba 9d 20 04 80 	movabs $0x8004209dba,%rdx
  8004203c60:	00 00 00 
  8004203c63:	be 41 01 00 00       	mov    $0x141,%esi
  8004203c68:	48 bf cf 9d 20 04 80 	movabs $0x8004209dcf,%rdi
  8004203c6f:	00 00 00 
  8004203c72:	b8 00 00 00 00       	mov    $0x0,%eax
  8004203c77:	49 b8 9b 01 20 04 80 	movabs $0x800420019b,%r8
  8004203c7e:	00 00 00 
  8004203c81:	41 ff d0             	callq  *%r8

    if (e->e_ident[4] == ELFCLASS32)
  8004203c84:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8004203c88:	0f b6 40 04          	movzbl 0x4(%rax),%eax
  8004203c8c:	3c 01                	cmp    $0x1,%al
  8004203c8e:	75 07                	jne    8004203c97 <_dwarf_elf_get_pointer_size+0x63>
        return (4);
  8004203c90:	b8 04 00 00 00       	mov    $0x4,%eax
  8004203c95:	eb 05                	jmp    8004203c9c <_dwarf_elf_get_pointer_size+0x68>
    else
        return (8);
  8004203c97:	b8 08 00 00 00       	mov    $0x8,%eax
}
  8004203c9c:	c9                   	leaveq 
  8004203c9d:	c3                   	retq   

0000008004203c9e <_dwarf_init>:

//Return 0 on success
int _dwarf_init(Dwarf_Debug dbg, void *obj)
{
  8004203c9e:	55                   	push   %rbp
  8004203c9f:	48 89 e5             	mov    %rsp,%rbp
  8004203ca2:	48 83 ec 10          	sub    $0x10,%rsp
  8004203ca6:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
  8004203caa:	48 89 75 f0          	mov    %rsi,-0x10(%rbp)
    memset(dbg, 0, sizeof(struct _Dwarf_Debug));
  8004203cae:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8004203cb2:	ba 58 00 00 00       	mov    $0x58,%edx
  8004203cb7:	be 00 00 00 00       	mov    $0x0,%esi
  8004203cbc:	48 89 c7             	mov    %rax,%rdi
  8004203cbf:	48 b8 5b 2e 20 04 80 	movabs $0x8004202e5b,%rax
  8004203cc6:	00 00 00 
  8004203cc9:	ff d0                	callq  *%rax
    dbg->curr_off_dbginfo = 0;
  8004203ccb:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8004203ccf:	48 c7 00 00 00 00 00 	movq   $0x0,(%rax)
    dbg->dbg_info_size = 0;
  8004203cd6:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8004203cda:	48 c7 40 10 00 00 00 	movq   $0x0,0x10(%rax)
  8004203ce1:	00 
    dbg->dbg_pointer_size = _dwarf_elf_get_pointer_size(obj); 
  8004203ce2:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8004203ce6:	48 89 c7             	mov    %rax,%rdi
  8004203ce9:	48 b8 34 3c 20 04 80 	movabs $0x8004203c34,%rax
  8004203cf0:	00 00 00 
  8004203cf3:	ff d0                	callq  *%rax
  8004203cf5:	0f b6 d0             	movzbl %al,%edx
  8004203cf8:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8004203cfc:	89 50 28             	mov    %edx,0x28(%rax)

    if (_dwarf_elf_get_byte_order(obj) == DW_OBJECT_MSB) {
  8004203cff:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8004203d03:	48 89 c7             	mov    %rax,%rdi
  8004203d06:	48 b8 c6 3b 20 04 80 	movabs $0x8004203bc6,%rax
  8004203d0d:	00 00 00 
  8004203d10:	ff d0                	callq  *%rax
  8004203d12:	85 c0                	test   %eax,%eax
  8004203d14:	75 26                	jne    8004203d3c <_dwarf_init+0x9e>
        dbg->read = _dwarf_read_msb;
  8004203d16:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8004203d1a:	48 ba 62 35 20 04 80 	movabs $0x8004203562,%rdx
  8004203d21:	00 00 00 
  8004203d24:	48 89 50 18          	mov    %rdx,0x18(%rax)
        dbg->decode = _dwarf_decode_msb;
  8004203d28:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8004203d2c:	48 ba 11 37 20 04 80 	movabs $0x8004203711,%rdx
  8004203d33:	00 00 00 
  8004203d36:	48 89 50 20          	mov    %rdx,0x20(%rax)
  8004203d3a:	eb 24                	jmp    8004203d60 <_dwarf_init+0xc2>
    } else {
        dbg->read = _dwarf_read_lsb;
  8004203d3c:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8004203d40:	48 ba 18 33 20 04 80 	movabs $0x8004203318,%rdx
  8004203d47:	00 00 00 
  8004203d4a:	48 89 50 18          	mov    %rdx,0x18(%rax)
        dbg->decode = _dwarf_decode_lsb;
  8004203d4e:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8004203d52:	48 ba 41 34 20 04 80 	movabs $0x8004203441,%rdx
  8004203d59:	00 00 00 
  8004203d5c:	48 89 50 20          	mov    %rdx,0x20(%rax)
    }
   _dwarf_frame_params_init(dbg);
  8004203d60:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8004203d64:	48 89 c7             	mov    %rax,%rdi
  8004203d67:	48 b8 a4 52 20 04 80 	movabs $0x80042052a4,%rax
  8004203d6e:	00 00 00 
  8004203d71:	ff d0                	callq  *%rax
   return 0;
  8004203d73:	b8 00 00 00 00       	mov    $0x0,%eax
}
  8004203d78:	c9                   	leaveq 
  8004203d79:	c3                   	retq   

0000008004203d7a <_get_next_cu>:

//Return 0 on success
int _get_next_cu(Dwarf_Debug dbg, Dwarf_CU *cu)
{
  8004203d7a:	55                   	push   %rbp
  8004203d7b:	48 89 e5             	mov    %rsp,%rbp
  8004203d7e:	48 83 ec 20          	sub    $0x20,%rsp
  8004203d82:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
  8004203d86:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
    uint32_t length;
    uint64_t offset;
    uint8_t dwarf_size;

    if(dbg->curr_off_dbginfo > dbg->dbg_info_size)
  8004203d8a:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004203d8e:	48 8b 10             	mov    (%rax),%rdx
  8004203d91:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004203d95:	48 8b 40 10          	mov    0x10(%rax),%rax
  8004203d99:	48 39 c2             	cmp    %rax,%rdx
  8004203d9c:	76 0a                	jbe    8004203da8 <_get_next_cu+0x2e>
        return -1;
  8004203d9e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  8004203da3:	e9 73 01 00 00       	jmpq   8004203f1b <_get_next_cu+0x1a1>

    offset = dbg->curr_off_dbginfo;
  8004203da8:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004203dac:	48 8b 00             	mov    (%rax),%rax
  8004203daf:	48 89 45 f0          	mov    %rax,-0x10(%rbp)
	cu->cu_offset = offset;
  8004203db3:	48 8b 55 f0          	mov    -0x10(%rbp),%rdx
  8004203db7:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  8004203dbb:	48 89 50 30          	mov    %rdx,0x30(%rax)

    length = dbg->read((uint8_t *)dbg->dbg_info_offset_elf, &offset,4);
  8004203dbf:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004203dc3:	4c 8b 40 18          	mov    0x18(%rax),%r8
  8004203dc7:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004203dcb:	48 8b 40 08          	mov    0x8(%rax),%rax
  8004203dcf:	48 8d 4d f0          	lea    -0x10(%rbp),%rcx
  8004203dd3:	ba 04 00 00 00       	mov    $0x4,%edx
  8004203dd8:	48 89 ce             	mov    %rcx,%rsi
  8004203ddb:	48 89 c7             	mov    %rax,%rdi
  8004203dde:	41 ff d0             	callq  *%r8
  8004203de1:	89 45 fc             	mov    %eax,-0x4(%rbp)
    if (length == 0xffffffff) {
  8004203de4:	83 7d fc ff          	cmpl   $0xffffffff,-0x4(%rbp)
  8004203de8:	75 2b                	jne    8004203e15 <_get_next_cu+0x9b>
        length = dbg->read((uint8_t *)dbg->dbg_info_offset_elf, &offset, 8);
  8004203dea:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004203dee:	4c 8b 40 18          	mov    0x18(%rax),%r8
  8004203df2:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004203df6:	48 8b 40 08          	mov    0x8(%rax),%rax
  8004203dfa:	48 8d 4d f0          	lea    -0x10(%rbp),%rcx
  8004203dfe:	ba 08 00 00 00       	mov    $0x8,%edx
  8004203e03:	48 89 ce             	mov    %rcx,%rsi
  8004203e06:	48 89 c7             	mov    %rax,%rdi
  8004203e09:	41 ff d0             	callq  *%r8
  8004203e0c:	89 45 fc             	mov    %eax,-0x4(%rbp)
        dwarf_size = 8;
  8004203e0f:	c6 45 fb 08          	movb   $0x8,-0x5(%rbp)
  8004203e13:	eb 04                	jmp    8004203e19 <_get_next_cu+0x9f>
    } else {
        dwarf_size = 4;
  8004203e15:	c6 45 fb 04          	movb   $0x4,-0x5(%rbp)
    }

    cu->cu_dwarf_size = dwarf_size;
  8004203e19:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  8004203e1d:	0f b6 55 fb          	movzbl -0x5(%rbp),%edx
  8004203e21:	88 50 19             	mov    %dl,0x19(%rax)
	if (length > ds->ds_size - offset) {
		return (DW_DLE_CU_LENGTH_ERROR);
	}*/

	/* Compute the offset to the next compilation unit: */
	dbg->curr_off_dbginfo = offset + length;
  8004203e24:	8b 55 fc             	mov    -0x4(%rbp),%edx
  8004203e27:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8004203e2b:	48 01 c2             	add    %rax,%rdx
  8004203e2e:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004203e32:	48 89 10             	mov    %rdx,(%rax)
	cu->cu_next_offset   = dbg->curr_off_dbginfo;
  8004203e35:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004203e39:	48 8b 10             	mov    (%rax),%rdx
  8004203e3c:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  8004203e40:	48 89 50 20          	mov    %rdx,0x20(%rax)

	/* Initialise the compilation unit. */
	cu->cu_length = (uint64_t)length;
  8004203e44:	8b 55 fc             	mov    -0x4(%rbp),%edx
  8004203e47:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  8004203e4b:	48 89 10             	mov    %rdx,(%rax)

	cu->cu_length_size   = (dwarf_size == 4 ? 4 : 12);
  8004203e4e:	80 7d fb 04          	cmpb   $0x4,-0x5(%rbp)
  8004203e52:	75 07                	jne    8004203e5b <_get_next_cu+0xe1>
  8004203e54:	b8 04 00 00 00       	mov    $0x4,%eax
  8004203e59:	eb 05                	jmp    8004203e60 <_get_next_cu+0xe6>
  8004203e5b:	b8 0c 00 00 00       	mov    $0xc,%eax
  8004203e60:	48 8b 55 e0          	mov    -0x20(%rbp),%rdx
  8004203e64:	88 42 18             	mov    %al,0x18(%rdx)
	cu->version              = dbg->read((uint8_t *)dbg->dbg_info_offset_elf, &offset, 2);
  8004203e67:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004203e6b:	4c 8b 40 18          	mov    0x18(%rax),%r8
  8004203e6f:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004203e73:	48 8b 40 08          	mov    0x8(%rax),%rax
  8004203e77:	48 8d 4d f0          	lea    -0x10(%rbp),%rcx
  8004203e7b:	ba 02 00 00 00       	mov    $0x2,%edx
  8004203e80:	48 89 ce             	mov    %rcx,%rsi
  8004203e83:	48 89 c7             	mov    %rax,%rdi
  8004203e86:	41 ff d0             	callq  *%r8
  8004203e89:	89 c2                	mov    %eax,%edx
  8004203e8b:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  8004203e8f:	66 89 50 08          	mov    %dx,0x8(%rax)
	cu->debug_abbrev_offset  = dbg->read((uint8_t *)dbg->dbg_info_offset_elf, &offset, dwarf_size);
  8004203e93:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004203e97:	4c 8b 40 18          	mov    0x18(%rax),%r8
  8004203e9b:	0f b6 55 fb          	movzbl -0x5(%rbp),%edx
  8004203e9f:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004203ea3:	48 8b 40 08          	mov    0x8(%rax),%rax
  8004203ea7:	48 8d 4d f0          	lea    -0x10(%rbp),%rcx
  8004203eab:	48 89 ce             	mov    %rcx,%rsi
  8004203eae:	48 89 c7             	mov    %rax,%rdi
  8004203eb1:	41 ff d0             	callq  *%r8
  8004203eb4:	48 8b 55 e0          	mov    -0x20(%rbp),%rdx
  8004203eb8:	48 89 42 10          	mov    %rax,0x10(%rdx)
	//cu->cu_abbrev_offset_cur = cu->cu_abbrev_offset;
	cu->addr_size  = dbg->read((uint8_t *)dbg->dbg_info_offset_elf, &offset, 1);
  8004203ebc:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004203ec0:	4c 8b 40 18          	mov    0x18(%rax),%r8
  8004203ec4:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004203ec8:	48 8b 40 08          	mov    0x8(%rax),%rax
  8004203ecc:	48 8d 4d f0          	lea    -0x10(%rbp),%rcx
  8004203ed0:	ba 01 00 00 00       	mov    $0x1,%edx
  8004203ed5:	48 89 ce             	mov    %rcx,%rsi
  8004203ed8:	48 89 c7             	mov    %rax,%rdi
  8004203edb:	41 ff d0             	callq  *%r8
  8004203ede:	89 c2                	mov    %eax,%edx
  8004203ee0:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  8004203ee4:	88 50 0a             	mov    %dl,0xa(%rax)

	if (cu->version < 2 || cu->version > 4) {
  8004203ee7:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  8004203eeb:	0f b7 40 08          	movzwl 0x8(%rax),%eax
  8004203eef:	66 83 f8 01          	cmp    $0x1,%ax
  8004203ef3:	76 0e                	jbe    8004203f03 <_get_next_cu+0x189>
  8004203ef5:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  8004203ef9:	0f b7 40 08          	movzwl 0x8(%rax),%eax
  8004203efd:	66 83 f8 04          	cmp    $0x4,%ax
  8004203f01:	76 07                	jbe    8004203f0a <_get_next_cu+0x190>
		return -1;
  8004203f03:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  8004203f08:	eb 11                	jmp    8004203f1b <_get_next_cu+0x1a1>
	}

	cu->cu_die_offset = offset;
  8004203f0a:	48 8b 55 f0          	mov    -0x10(%rbp),%rdx
  8004203f0e:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  8004203f12:	48 89 50 28          	mov    %rdx,0x28(%rax)

	return 0;
  8004203f16:	b8 00 00 00 00       	mov    $0x0,%eax
}
  8004203f1b:	c9                   	leaveq 
  8004203f1c:	c3                   	retq   

0000008004203f1d <print_cu>:

void print_cu(Dwarf_CU cu)
{
  8004203f1d:	55                   	push   %rbp
  8004203f1e:	48 89 e5             	mov    %rsp,%rbp
    cprintf("%ld---%du--%d\n",cu.cu_length,cu.version,cu.addr_size);
  8004203f21:	0f b6 45 1a          	movzbl 0x1a(%rbp),%eax
  8004203f25:	0f b6 c8             	movzbl %al,%ecx
  8004203f28:	0f b7 45 18          	movzwl 0x18(%rbp),%eax
  8004203f2c:	0f b7 d0             	movzwl %ax,%edx
  8004203f2f:	48 8b 45 10          	mov    0x10(%rbp),%rax
  8004203f33:	48 89 c6             	mov    %rax,%rsi
  8004203f36:	48 bf e2 9d 20 04 80 	movabs $0x8004209de2,%rdi
  8004203f3d:	00 00 00 
  8004203f40:	b8 00 00 00 00       	mov    $0x0,%eax
  8004203f45:	49 b8 22 16 20 04 80 	movabs $0x8004201622,%r8
  8004203f4c:	00 00 00 
  8004203f4f:	41 ff d0             	callq  *%r8
}
  8004203f52:	5d                   	pop    %rbp
  8004203f53:	c3                   	retq   

0000008004203f54 <_dwarf_abbrev_parse>:

//Return 0 on success
int
_dwarf_abbrev_parse(Dwarf_Debug dbg, Dwarf_CU cu, Dwarf_Unsigned *offset,
    Dwarf_Abbrev *abp, Dwarf_Section *ds)
{
  8004203f54:	55                   	push   %rbp
  8004203f55:	48 89 e5             	mov    %rsp,%rbp
  8004203f58:	48 83 ec 60          	sub    $0x60,%rsp
  8004203f5c:	48 89 7d b8          	mov    %rdi,-0x48(%rbp)
  8004203f60:	48 89 75 b0          	mov    %rsi,-0x50(%rbp)
  8004203f64:	48 89 55 a8          	mov    %rdx,-0x58(%rbp)
  8004203f68:	48 89 4d a0          	mov    %rcx,-0x60(%rbp)
    uint64_t tag;
    uint8_t children;
    uint64_t abbr_addr;
    int ret;

    assert(abp != NULL);
  8004203f6c:	48 83 7d a8 00       	cmpq   $0x0,-0x58(%rbp)
  8004203f71:	75 35                	jne    8004203fa8 <_dwarf_abbrev_parse+0x54>
  8004203f73:	48 b9 f1 9d 20 04 80 	movabs $0x8004209df1,%rcx
  8004203f7a:	00 00 00 
  8004203f7d:	48 ba ba 9d 20 04 80 	movabs $0x8004209dba,%rdx
  8004203f84:	00 00 00 
  8004203f87:	be a6 01 00 00       	mov    $0x1a6,%esi
  8004203f8c:	48 bf cf 9d 20 04 80 	movabs $0x8004209dcf,%rdi
  8004203f93:	00 00 00 
  8004203f96:	b8 00 00 00 00       	mov    $0x0,%eax
  8004203f9b:	49 b8 9b 01 20 04 80 	movabs $0x800420019b,%r8
  8004203fa2:	00 00 00 
  8004203fa5:	41 ff d0             	callq  *%r8
    assert(ds != NULL);
  8004203fa8:	48 83 7d a0 00       	cmpq   $0x0,-0x60(%rbp)
  8004203fad:	75 35                	jne    8004203fe4 <_dwarf_abbrev_parse+0x90>
  8004203faf:	48 b9 fd 9d 20 04 80 	movabs $0x8004209dfd,%rcx
  8004203fb6:	00 00 00 
  8004203fb9:	48 ba ba 9d 20 04 80 	movabs $0x8004209dba,%rdx
  8004203fc0:	00 00 00 
  8004203fc3:	be a7 01 00 00       	mov    $0x1a7,%esi
  8004203fc8:	48 bf cf 9d 20 04 80 	movabs $0x8004209dcf,%rdi
  8004203fcf:	00 00 00 
  8004203fd2:	b8 00 00 00 00       	mov    $0x0,%eax
  8004203fd7:	49 b8 9b 01 20 04 80 	movabs $0x800420019b,%r8
  8004203fde:	00 00 00 
  8004203fe1:	41 ff d0             	callq  *%r8

    if (*offset >= ds->ds_size)
  8004203fe4:	48 8b 45 b0          	mov    -0x50(%rbp),%rax
  8004203fe8:	48 8b 10             	mov    (%rax),%rdx
  8004203feb:	48 8b 45 a0          	mov    -0x60(%rbp),%rax
  8004203fef:	48 8b 40 18          	mov    0x18(%rax),%rax
  8004203ff3:	48 39 c2             	cmp    %rax,%rdx
  8004203ff6:	72 0a                	jb     8004204002 <_dwarf_abbrev_parse+0xae>
        	return (DW_DLE_NO_ENTRY);
  8004203ff8:	b8 04 00 00 00       	mov    $0x4,%eax
  8004203ffd:	e9 d7 01 00 00       	jmpq   80042041d9 <_dwarf_abbrev_parse+0x285>

    aboff = *offset;
  8004204002:	48 8b 45 b0          	mov    -0x50(%rbp),%rax
  8004204006:	48 8b 00             	mov    (%rax),%rax
  8004204009:	48 89 45 f8          	mov    %rax,-0x8(%rbp)

    abbr_addr = (uint64_t)ds->ds_data; //(uint64_t)((uint8_t *)elf_base_ptr + ds->sh_offset);
  800420400d:	48 8b 45 a0          	mov    -0x60(%rbp),%rax
  8004204011:	48 8b 40 08          	mov    0x8(%rax),%rax
  8004204015:	48 89 45 f0          	mov    %rax,-0x10(%rbp)

    entry = _dwarf_read_uleb128((uint8_t *)abbr_addr, offset);
  8004204019:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  800420401d:	48 8b 55 b0          	mov    -0x50(%rbp),%rdx
  8004204021:	48 89 d6             	mov    %rdx,%rsi
  8004204024:	48 89 c7             	mov    %rax,%rdi
  8004204027:	48 b8 68 39 20 04 80 	movabs $0x8004203968,%rax
  800420402e:	00 00 00 
  8004204031:	ff d0                	callq  *%rax
  8004204033:	48 89 45 e8          	mov    %rax,-0x18(%rbp)

    if (entry == 0) {
  8004204037:	48 83 7d e8 00       	cmpq   $0x0,-0x18(%rbp)
  800420403c:	75 15                	jne    8004204053 <_dwarf_abbrev_parse+0xff>
        /* Last entry. */
        //Need to make connection from below function
        abp->ab_entry = 0;
  800420403e:	48 8b 45 a8          	mov    -0x58(%rbp),%rax
  8004204042:	48 c7 00 00 00 00 00 	movq   $0x0,(%rax)
        return DW_DLE_NONE;
  8004204049:	b8 00 00 00 00       	mov    $0x0,%eax
  800420404e:	e9 86 01 00 00       	jmpq   80042041d9 <_dwarf_abbrev_parse+0x285>
    }

    tag = _dwarf_read_uleb128((uint8_t *)abbr_addr, offset);
  8004204053:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8004204057:	48 8b 55 b0          	mov    -0x50(%rbp),%rdx
  800420405b:	48 89 d6             	mov    %rdx,%rsi
  800420405e:	48 89 c7             	mov    %rax,%rdi
  8004204061:	48 b8 68 39 20 04 80 	movabs $0x8004203968,%rax
  8004204068:	00 00 00 
  800420406b:	ff d0                	callq  *%rax
  800420406d:	48 89 45 e0          	mov    %rax,-0x20(%rbp)
    children = dbg->read((uint8_t *)abbr_addr, offset, 1);
  8004204071:	48 8b 45 b8          	mov    -0x48(%rbp),%rax
  8004204075:	4c 8b 40 18          	mov    0x18(%rax),%r8
  8004204079:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  800420407d:	48 8b 4d b0          	mov    -0x50(%rbp),%rcx
  8004204081:	ba 01 00 00 00       	mov    $0x1,%edx
  8004204086:	48 89 ce             	mov    %rcx,%rsi
  8004204089:	48 89 c7             	mov    %rax,%rdi
  800420408c:	41 ff d0             	callq  *%r8
  800420408f:	88 45 df             	mov    %al,-0x21(%rbp)

    abp->ab_entry    = entry;
  8004204092:	48 8b 45 a8          	mov    -0x58(%rbp),%rax
  8004204096:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  800420409a:	48 89 10             	mov    %rdx,(%rax)
    abp->ab_tag      = tag;
  800420409d:	48 8b 45 a8          	mov    -0x58(%rbp),%rax
  80042040a1:	48 8b 55 e0          	mov    -0x20(%rbp),%rdx
  80042040a5:	48 89 50 08          	mov    %rdx,0x8(%rax)
    abp->ab_children = children;
  80042040a9:	48 8b 45 a8          	mov    -0x58(%rbp),%rax
  80042040ad:	0f b6 55 df          	movzbl -0x21(%rbp),%edx
  80042040b1:	88 50 10             	mov    %dl,0x10(%rax)
    abp->ab_offset   = aboff;
  80042040b4:	48 8b 45 a8          	mov    -0x58(%rbp),%rax
  80042040b8:	48 8b 55 f8          	mov    -0x8(%rbp),%rdx
  80042040bc:	48 89 50 18          	mov    %rdx,0x18(%rax)
    abp->ab_length   = 0;    /* fill in later. */
  80042040c0:	48 8b 45 a8          	mov    -0x58(%rbp),%rax
  80042040c4:	48 c7 40 20 00 00 00 	movq   $0x0,0x20(%rax)
  80042040cb:	00 
    abp->ab_atnum    = 0;
  80042040cc:	48 8b 45 a8          	mov    -0x58(%rbp),%rax
  80042040d0:	48 c7 40 28 00 00 00 	movq   $0x0,0x28(%rax)
  80042040d7:	00 

    /* Parse attribute definitions. */
    do {
        adoff = *offset;
  80042040d8:	48 8b 45 b0          	mov    -0x50(%rbp),%rax
  80042040dc:	48 8b 00             	mov    (%rax),%rax
  80042040df:	48 89 45 d0          	mov    %rax,-0x30(%rbp)
        attr = _dwarf_read_uleb128((uint8_t *)abbr_addr, offset);
  80042040e3:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  80042040e7:	48 8b 55 b0          	mov    -0x50(%rbp),%rdx
  80042040eb:	48 89 d6             	mov    %rdx,%rsi
  80042040ee:	48 89 c7             	mov    %rax,%rdi
  80042040f1:	48 b8 68 39 20 04 80 	movabs $0x8004203968,%rax
  80042040f8:	00 00 00 
  80042040fb:	ff d0                	callq  *%rax
  80042040fd:	48 89 45 c8          	mov    %rax,-0x38(%rbp)
        form = _dwarf_read_uleb128((uint8_t *)abbr_addr, offset);
  8004204101:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8004204105:	48 8b 55 b0          	mov    -0x50(%rbp),%rdx
  8004204109:	48 89 d6             	mov    %rdx,%rsi
  800420410c:	48 89 c7             	mov    %rax,%rdi
  800420410f:	48 b8 68 39 20 04 80 	movabs $0x8004203968,%rax
  8004204116:	00 00 00 
  8004204119:	ff d0                	callq  *%rax
  800420411b:	48 89 45 c0          	mov    %rax,-0x40(%rbp)
        if (attr != 0)
  800420411f:	48 83 7d c8 00       	cmpq   $0x0,-0x38(%rbp)
  8004204124:	0f 84 89 00 00 00    	je     80042041b3 <_dwarf_abbrev_parse+0x25f>
        {
            /* Initialise the attribute definition structure. */
            abp->ab_attrdef[abp->ab_atnum].ad_attrib = attr;
  800420412a:	48 8b 45 a8          	mov    -0x58(%rbp),%rax
  800420412e:	48 8b 50 28          	mov    0x28(%rax),%rdx
  8004204132:	48 8b 4d a8          	mov    -0x58(%rbp),%rcx
  8004204136:	48 89 d0             	mov    %rdx,%rax
  8004204139:	48 01 c0             	add    %rax,%rax
  800420413c:	48 01 d0             	add    %rdx,%rax
  800420413f:	48 c1 e0 03          	shl    $0x3,%rax
  8004204143:	48 01 c8             	add    %rcx,%rax
  8004204146:	48 8d 50 30          	lea    0x30(%rax),%rdx
  800420414a:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
  800420414e:	48 89 02             	mov    %rax,(%rdx)
            abp->ab_attrdef[abp->ab_atnum].ad_form   = form;
  8004204151:	48 8b 45 a8          	mov    -0x58(%rbp),%rax
  8004204155:	48 8b 50 28          	mov    0x28(%rax),%rdx
  8004204159:	48 8b 4d a8          	mov    -0x58(%rbp),%rcx
  800420415d:	48 89 d0             	mov    %rdx,%rax
  8004204160:	48 01 c0             	add    %rax,%rax
  8004204163:	48 01 d0             	add    %rdx,%rax
  8004204166:	48 c1 e0 03          	shl    $0x3,%rax
  800420416a:	48 01 c8             	add    %rcx,%rax
  800420416d:	48 8d 50 38          	lea    0x38(%rax),%rdx
  8004204171:	48 8b 45 c0          	mov    -0x40(%rbp),%rax
  8004204175:	48 89 02             	mov    %rax,(%rdx)
            abp->ab_attrdef[abp->ab_atnum].ad_offset = adoff;
  8004204178:	48 8b 45 a8          	mov    -0x58(%rbp),%rax
  800420417c:	48 8b 50 28          	mov    0x28(%rax),%rdx
  8004204180:	48 8b 4d a8          	mov    -0x58(%rbp),%rcx
  8004204184:	48 89 d0             	mov    %rdx,%rax
  8004204187:	48 01 c0             	add    %rax,%rax
  800420418a:	48 01 d0             	add    %rdx,%rax
  800420418d:	48 c1 e0 03          	shl    $0x3,%rax
  8004204191:	48 01 c8             	add    %rcx,%rax
  8004204194:	48 8d 50 40          	lea    0x40(%rax),%rdx
  8004204198:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  800420419c:	48 89 02             	mov    %rax,(%rdx)
            abp->ab_atnum++;
  800420419f:	48 8b 45 a8          	mov    -0x58(%rbp),%rax
  80042041a3:	48 8b 40 28          	mov    0x28(%rax),%rax
  80042041a7:	48 8d 50 01          	lea    0x1(%rax),%rdx
  80042041ab:	48 8b 45 a8          	mov    -0x58(%rbp),%rax
  80042041af:	48 89 50 28          	mov    %rdx,0x28(%rax)
        }
    } while (attr != 0);
  80042041b3:	48 83 7d c8 00       	cmpq   $0x0,-0x38(%rbp)
  80042041b8:	0f 85 1a ff ff ff    	jne    80042040d8 <_dwarf_abbrev_parse+0x184>

    //(*abp)->ab_length = *offset - aboff;
    abp->ab_length = (uint64_t)(*offset - aboff);
  80042041be:	48 8b 45 b0          	mov    -0x50(%rbp),%rax
  80042041c2:	48 8b 00             	mov    (%rax),%rax
  80042041c5:	48 89 c2             	mov    %rax,%rdx
  80042041c8:	48 2b 55 f8          	sub    -0x8(%rbp),%rdx
  80042041cc:	48 8b 45 a8          	mov    -0x58(%rbp),%rax
  80042041d0:	48 89 50 20          	mov    %rdx,0x20(%rax)

    return DW_DLV_OK;
  80042041d4:	b8 00 00 00 00       	mov    $0x0,%eax
}
  80042041d9:	c9                   	leaveq 
  80042041da:	c3                   	retq   

00000080042041db <_dwarf_abbrev_find>:

//Return 0 on success
int
_dwarf_abbrev_find(Dwarf_Debug dbg, Dwarf_CU cu, uint64_t entry, Dwarf_Abbrev *abp)
{
  80042041db:	55                   	push   %rbp
  80042041dc:	48 89 e5             	mov    %rsp,%rbp
  80042041df:	48 83 c4 80          	add    $0xffffffffffffff80,%rsp
  80042041e3:	48 89 7d d8          	mov    %rdi,-0x28(%rbp)
  80042041e7:	48 89 75 d0          	mov    %rsi,-0x30(%rbp)
  80042041eb:	48 89 55 c8          	mov    %rdx,-0x38(%rbp)
    Dwarf_Section *ds;
    uint64_t offset;
    int ret;

    if (entry == 0)
  80042041ef:	48 83 7d d0 00       	cmpq   $0x0,-0x30(%rbp)
  80042041f4:	75 0a                	jne    8004204200 <_dwarf_abbrev_find+0x25>
    {
		return (DW_DLE_NO_ENTRY);
  80042041f6:	b8 04 00 00 00       	mov    $0x4,%eax
  80042041fb:	e9 0b 01 00 00       	jmpq   800420430b <_dwarf_abbrev_find+0x130>
    }

    /* Load and search the abbrev table. */
    ds = _dwarf_find_section(".debug_abbrev");
  8004204200:	48 bf 08 9e 20 04 80 	movabs $0x8004209e08,%rdi
  8004204207:	00 00 00 
  800420420a:	48 b8 e8 85 20 04 80 	movabs $0x80042085e8,%rax
  8004204211:	00 00 00 
  8004204214:	ff d0                	callq  *%rax
  8004204216:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
    assert(ds != NULL);
  800420421a:	48 83 7d f8 00       	cmpq   $0x0,-0x8(%rbp)
  800420421f:	75 35                	jne    8004204256 <_dwarf_abbrev_find+0x7b>
  8004204221:	48 b9 fd 9d 20 04 80 	movabs $0x8004209dfd,%rcx
  8004204228:	00 00 00 
  800420422b:	48 ba ba 9d 20 04 80 	movabs $0x8004209dba,%rdx
  8004204232:	00 00 00 
  8004204235:	be e7 01 00 00       	mov    $0x1e7,%esi
  800420423a:	48 bf cf 9d 20 04 80 	movabs $0x8004209dcf,%rdi
  8004204241:	00 00 00 
  8004204244:	b8 00 00 00 00       	mov    $0x0,%eax
  8004204249:	49 b8 9b 01 20 04 80 	movabs $0x800420019b,%r8
  8004204250:	00 00 00 
  8004204253:	41 ff d0             	callq  *%r8

    //TODO: We are starting offset from 0, however libdwarf logic
    //      is keeping a counter for current offset. Ok. let use
    //      that. I relent, but this will be done in Phase 2. :)
    //offset = 0; //cu->cu_abbrev_offset_cur;
    offset = cu.debug_abbrev_offset; //cu->cu_abbrev_offset_cur;
  8004204256:	48 8b 45 20          	mov    0x20(%rbp),%rax
  800420425a:	48 89 45 e8          	mov    %rax,-0x18(%rbp)
    while (offset < ds->ds_size) {
  800420425e:	e9 8b 00 00 00       	jmpq   80042042ee <_dwarf_abbrev_find+0x113>
        ret = _dwarf_abbrev_parse(dbg, cu, &offset, abp, ds);
  8004204263:	48 8b 4d f8          	mov    -0x8(%rbp),%rcx
  8004204267:	48 8b 55 c8          	mov    -0x38(%rbp),%rdx
  800420426b:	48 8d 75 e8          	lea    -0x18(%rbp),%rsi
  800420426f:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  8004204273:	48 8b 7d 10          	mov    0x10(%rbp),%rdi
  8004204277:	48 89 3c 24          	mov    %rdi,(%rsp)
  800420427b:	48 8b 7d 18          	mov    0x18(%rbp),%rdi
  800420427f:	48 89 7c 24 08       	mov    %rdi,0x8(%rsp)
  8004204284:	48 8b 7d 20          	mov    0x20(%rbp),%rdi
  8004204288:	48 89 7c 24 10       	mov    %rdi,0x10(%rsp)
  800420428d:	48 8b 7d 28          	mov    0x28(%rbp),%rdi
  8004204291:	48 89 7c 24 18       	mov    %rdi,0x18(%rsp)
  8004204296:	48 8b 7d 30          	mov    0x30(%rbp),%rdi
  800420429a:	48 89 7c 24 20       	mov    %rdi,0x20(%rsp)
  800420429f:	48 8b 7d 38          	mov    0x38(%rbp),%rdi
  80042042a3:	48 89 7c 24 28       	mov    %rdi,0x28(%rsp)
  80042042a8:	48 8b 7d 40          	mov    0x40(%rbp),%rdi
  80042042ac:	48 89 7c 24 30       	mov    %rdi,0x30(%rsp)
  80042042b1:	48 89 c7             	mov    %rax,%rdi
  80042042b4:	48 b8 54 3f 20 04 80 	movabs $0x8004203f54,%rax
  80042042bb:	00 00 00 
  80042042be:	ff d0                	callq  *%rax
  80042042c0:	89 45 f4             	mov    %eax,-0xc(%rbp)
        if (ret != DW_DLE_NONE)
  80042042c3:	83 7d f4 00          	cmpl   $0x0,-0xc(%rbp)
  80042042c7:	74 05                	je     80042042ce <_dwarf_abbrev_find+0xf3>
            return (ret);
  80042042c9:	8b 45 f4             	mov    -0xc(%rbp),%eax
  80042042cc:	eb 3d                	jmp    800420430b <_dwarf_abbrev_find+0x130>
        if (abp->ab_entry == entry) {
  80042042ce:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
  80042042d2:	48 8b 00             	mov    (%rax),%rax
  80042042d5:	48 3b 45 d0          	cmp    -0x30(%rbp),%rax
  80042042d9:	75 07                	jne    80042042e2 <_dwarf_abbrev_find+0x107>
            //cu->cu_abbrev_offset_cur = offset;
            return DW_DLE_NONE;
  80042042db:	b8 00 00 00 00       	mov    $0x0,%eax
  80042042e0:	eb 29                	jmp    800420430b <_dwarf_abbrev_find+0x130>
        }
        if (abp->ab_entry == 0) {
  80042042e2:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
  80042042e6:	48 8b 00             	mov    (%rax),%rax
  80042042e9:	48 85 c0             	test   %rax,%rax
  80042042ec:	74 17                	je     8004204305 <_dwarf_abbrev_find+0x12a>
    //TODO: We are starting offset from 0, however libdwarf logic
    //      is keeping a counter for current offset. Ok. let use
    //      that. I relent, but this will be done in Phase 2. :)
    //offset = 0; //cu->cu_abbrev_offset_cur;
    offset = cu.debug_abbrev_offset; //cu->cu_abbrev_offset_cur;
    while (offset < ds->ds_size) {
  80042042ee:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  80042042f2:	48 8b 50 18          	mov    0x18(%rax),%rdx
  80042042f6:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  80042042fa:	48 39 c2             	cmp    %rax,%rdx
  80042042fd:	0f 87 60 ff ff ff    	ja     8004204263 <_dwarf_abbrev_find+0x88>
  8004204303:	eb 01                	jmp    8004204306 <_dwarf_abbrev_find+0x12b>
            return DW_DLE_NONE;
        }
        if (abp->ab_entry == 0) {
            //cu->cu_abbrev_offset_cur = offset;
            //cu->cu_abbrev_loaded = 1;
            break;
  8004204305:	90                   	nop
        }
    }

    return DW_DLE_NO_ENTRY;
  8004204306:	b8 04 00 00 00       	mov    $0x4,%eax
}
  800420430b:	c9                   	leaveq 
  800420430c:	c3                   	retq   

000000800420430d <_dwarf_attr_init>:

//Return 0 on success
int
_dwarf_attr_init(Dwarf_Debug dbg, uint64_t *offsetp, Dwarf_CU *cu, Dwarf_Die *ret_die, Dwarf_AttrDef *ad,
    uint64_t form, int indirect)
{
  800420430d:	55                   	push   %rbp
  800420430e:	48 89 e5             	mov    %rsp,%rbp
  8004204311:	48 81 ec d0 00 00 00 	sub    $0xd0,%rsp
  8004204318:	48 89 bd 68 ff ff ff 	mov    %rdi,-0x98(%rbp)
  800420431f:	48 89 b5 60 ff ff ff 	mov    %rsi,-0xa0(%rbp)
  8004204326:	48 89 95 58 ff ff ff 	mov    %rdx,-0xa8(%rbp)
  800420432d:	48 89 8d 50 ff ff ff 	mov    %rcx,-0xb0(%rbp)
  8004204334:	4c 89 85 48 ff ff ff 	mov    %r8,-0xb8(%rbp)
  800420433b:	4c 89 8d 40 ff ff ff 	mov    %r9,-0xc0(%rbp)
    struct _Dwarf_Attribute atref;
    Dwarf_Section *str;
    int ret;
    Dwarf_Section *ds = _dwarf_find_section(".debug_info");
  8004204342:	48 bf 16 9e 20 04 80 	movabs $0x8004209e16,%rdi
  8004204349:	00 00 00 
  800420434c:	48 b8 e8 85 20 04 80 	movabs $0x80042085e8,%rax
  8004204353:	00 00 00 
  8004204356:	ff d0                	callq  *%rax
  8004204358:	48 89 45 f0          	mov    %rax,-0x10(%rbp)
    uint8_t *ds_data = (uint8_t *)ds->ds_data; //(uint8_t *)dbg->dbg_info_offset_elf;
  800420435c:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8004204360:	48 8b 40 08          	mov    0x8(%rax),%rax
  8004204364:	48 89 45 e8          	mov    %rax,-0x18(%rbp)
    uint8_t dwarf_size = cu->cu_dwarf_size;
  8004204368:	48 8b 85 58 ff ff ff 	mov    -0xa8(%rbp),%rax
  800420436f:	0f b6 40 19          	movzbl 0x19(%rax),%eax
  8004204373:	88 45 e7             	mov    %al,-0x19(%rbp)

    ret = DW_DLE_NONE;
  8004204376:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%rbp)
    memset(&atref, 0, sizeof(atref));
  800420437d:	48 8d 85 70 ff ff ff 	lea    -0x90(%rbp),%rax
  8004204384:	ba 60 00 00 00       	mov    $0x60,%edx
  8004204389:	be 00 00 00 00       	mov    $0x0,%esi
  800420438e:	48 89 c7             	mov    %rax,%rdi
  8004204391:	48 b8 5b 2e 20 04 80 	movabs $0x8004202e5b,%rax
  8004204398:	00 00 00 
  800420439b:	ff d0                	callq  *%rax
    atref.at_die = ret_die;
  800420439d:	48 8b 85 50 ff ff ff 	mov    -0xb0(%rbp),%rax
  80042043a4:	48 89 85 70 ff ff ff 	mov    %rax,-0x90(%rbp)
    atref.at_attrib = ad->ad_attrib;
  80042043ab:	48 8b 85 48 ff ff ff 	mov    -0xb8(%rbp),%rax
  80042043b2:	48 8b 00             	mov    (%rax),%rax
  80042043b5:	48 89 45 80          	mov    %rax,-0x80(%rbp)
    atref.at_form = ad->ad_form;
  80042043b9:	48 8b 85 48 ff ff ff 	mov    -0xb8(%rbp),%rax
  80042043c0:	48 8b 40 08          	mov    0x8(%rax),%rax
  80042043c4:	48 89 45 88          	mov    %rax,-0x78(%rbp)
    atref.at_indirect = indirect;
  80042043c8:	8b 45 10             	mov    0x10(%rbp),%eax
  80042043cb:	89 45 90             	mov    %eax,-0x70(%rbp)
    atref.at_ld = NULL;
  80042043ce:	48 c7 45 b8 00 00 00 	movq   $0x0,-0x48(%rbp)
  80042043d5:	00 

    switch (form) {
  80042043d6:	48 83 bd 40 ff ff ff 	cmpq   $0x20,-0xc0(%rbp)
  80042043dd:	20 
  80042043de:	0f 87 b4 04 00 00    	ja     8004204898 <_dwarf_attr_init+0x58b>
  80042043e4:	48 8b 85 40 ff ff ff 	mov    -0xc0(%rbp),%rax
  80042043eb:	48 8d 14 c5 00 00 00 	lea    0x0(,%rax,8),%rdx
  80042043f2:	00 
  80042043f3:	48 b8 40 9e 20 04 80 	movabs $0x8004209e40,%rax
  80042043fa:	00 00 00 
  80042043fd:	48 01 d0             	add    %rdx,%rax
  8004204400:	48 8b 00             	mov    (%rax),%rax
  8004204403:	ff e0                	jmpq   *%rax
    case DW_FORM_addr:
        atref.u[0].u64 = dbg->read(ds_data, offsetp, cu->addr_size);
  8004204405:	48 8b 85 68 ff ff ff 	mov    -0x98(%rbp),%rax
  800420440c:	4c 8b 40 18          	mov    0x18(%rax),%r8
  8004204410:	48 8b 85 58 ff ff ff 	mov    -0xa8(%rbp),%rax
  8004204417:	0f b6 40 0a          	movzbl 0xa(%rax),%eax
  800420441b:	0f b6 d0             	movzbl %al,%edx
  800420441e:	48 8b 8d 60 ff ff ff 	mov    -0xa0(%rbp),%rcx
  8004204425:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004204429:	48 89 ce             	mov    %rcx,%rsi
  800420442c:	48 89 c7             	mov    %rax,%rdi
  800420442f:	41 ff d0             	callq  *%r8
  8004204432:	48 89 45 98          	mov    %rax,-0x68(%rbp)
        break;
  8004204436:	e9 67 04 00 00       	jmpq   80042048a2 <_dwarf_attr_init+0x595>
    case DW_FORM_block:
    case DW_FORM_exprloc:
        atref.u[0].u64 = _dwarf_read_uleb128(ds_data, offsetp);
  800420443b:	48 8b 95 60 ff ff ff 	mov    -0xa0(%rbp),%rdx
  8004204442:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004204446:	48 89 d6             	mov    %rdx,%rsi
  8004204449:	48 89 c7             	mov    %rax,%rdi
  800420444c:	48 b8 68 39 20 04 80 	movabs $0x8004203968,%rax
  8004204453:	00 00 00 
  8004204456:	ff d0                	callq  *%rax
  8004204458:	48 89 45 98          	mov    %rax,-0x68(%rbp)
        atref.u[1].u8p = (uint8_t*)_dwarf_read_block(ds_data, offsetp, atref.u[0].u64);
  800420445c:	48 8b 55 98          	mov    -0x68(%rbp),%rdx
  8004204460:	48 8b 8d 60 ff ff ff 	mov    -0xa0(%rbp),%rcx
  8004204467:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  800420446b:	48 89 ce             	mov    %rcx,%rsi
  800420446e:	48 89 c7             	mov    %rax,%rdi
  8004204471:	48 b8 80 3b 20 04 80 	movabs $0x8004203b80,%rax
  8004204478:	00 00 00 
  800420447b:	ff d0                	callq  *%rax
  800420447d:	48 89 45 a0          	mov    %rax,-0x60(%rbp)
        break;
  8004204481:	e9 1c 04 00 00       	jmpq   80042048a2 <_dwarf_attr_init+0x595>
    case DW_FORM_block1:
        atref.u[0].u64 = dbg->read(ds_data, offsetp, 1);
  8004204486:	48 8b 85 68 ff ff ff 	mov    -0x98(%rbp),%rax
  800420448d:	4c 8b 40 18          	mov    0x18(%rax),%r8
  8004204491:	48 8b 8d 60 ff ff ff 	mov    -0xa0(%rbp),%rcx
  8004204498:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  800420449c:	ba 01 00 00 00       	mov    $0x1,%edx
  80042044a1:	48 89 ce             	mov    %rcx,%rsi
  80042044a4:	48 89 c7             	mov    %rax,%rdi
  80042044a7:	41 ff d0             	callq  *%r8
  80042044aa:	48 89 45 98          	mov    %rax,-0x68(%rbp)
        atref.u[1].u8p = (uint8_t*)_dwarf_read_block(ds_data, offsetp, atref.u[0].u64);
  80042044ae:	48 8b 55 98          	mov    -0x68(%rbp),%rdx
  80042044b2:	48 8b 8d 60 ff ff ff 	mov    -0xa0(%rbp),%rcx
  80042044b9:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  80042044bd:	48 89 ce             	mov    %rcx,%rsi
  80042044c0:	48 89 c7             	mov    %rax,%rdi
  80042044c3:	48 b8 80 3b 20 04 80 	movabs $0x8004203b80,%rax
  80042044ca:	00 00 00 
  80042044cd:	ff d0                	callq  *%rax
  80042044cf:	48 89 45 a0          	mov    %rax,-0x60(%rbp)
        break;
  80042044d3:	e9 ca 03 00 00       	jmpq   80042048a2 <_dwarf_attr_init+0x595>
    case DW_FORM_block2:
        atref.u[0].u64 = dbg->read(ds_data, offsetp, 2);
  80042044d8:	48 8b 85 68 ff ff ff 	mov    -0x98(%rbp),%rax
  80042044df:	4c 8b 40 18          	mov    0x18(%rax),%r8
  80042044e3:	48 8b 8d 60 ff ff ff 	mov    -0xa0(%rbp),%rcx
  80042044ea:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  80042044ee:	ba 02 00 00 00       	mov    $0x2,%edx
  80042044f3:	48 89 ce             	mov    %rcx,%rsi
  80042044f6:	48 89 c7             	mov    %rax,%rdi
  80042044f9:	41 ff d0             	callq  *%r8
  80042044fc:	48 89 45 98          	mov    %rax,-0x68(%rbp)
        atref.u[1].u8p = (uint8_t*)_dwarf_read_block(ds_data, offsetp, atref.u[0].u64);
  8004204500:	48 8b 55 98          	mov    -0x68(%rbp),%rdx
  8004204504:	48 8b 8d 60 ff ff ff 	mov    -0xa0(%rbp),%rcx
  800420450b:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  800420450f:	48 89 ce             	mov    %rcx,%rsi
  8004204512:	48 89 c7             	mov    %rax,%rdi
  8004204515:	48 b8 80 3b 20 04 80 	movabs $0x8004203b80,%rax
  800420451c:	00 00 00 
  800420451f:	ff d0                	callq  *%rax
  8004204521:	48 89 45 a0          	mov    %rax,-0x60(%rbp)
        break;
  8004204525:	e9 78 03 00 00       	jmpq   80042048a2 <_dwarf_attr_init+0x595>
   case DW_FORM_block4:
        atref.u[0].u64 = dbg->read(ds_data, offsetp, 4);
  800420452a:	48 8b 85 68 ff ff ff 	mov    -0x98(%rbp),%rax
  8004204531:	4c 8b 40 18          	mov    0x18(%rax),%r8
  8004204535:	48 8b 8d 60 ff ff ff 	mov    -0xa0(%rbp),%rcx
  800420453c:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004204540:	ba 04 00 00 00       	mov    $0x4,%edx
  8004204545:	48 89 ce             	mov    %rcx,%rsi
  8004204548:	48 89 c7             	mov    %rax,%rdi
  800420454b:	41 ff d0             	callq  *%r8
  800420454e:	48 89 45 98          	mov    %rax,-0x68(%rbp)
        atref.u[1].u8p = (uint8_t*)_dwarf_read_block(ds_data, offsetp, atref.u[0].u64);
  8004204552:	48 8b 55 98          	mov    -0x68(%rbp),%rdx
  8004204556:	48 8b 8d 60 ff ff ff 	mov    -0xa0(%rbp),%rcx
  800420455d:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004204561:	48 89 ce             	mov    %rcx,%rsi
  8004204564:	48 89 c7             	mov    %rax,%rdi
  8004204567:	48 b8 80 3b 20 04 80 	movabs $0x8004203b80,%rax
  800420456e:	00 00 00 
  8004204571:	ff d0                	callq  *%rax
  8004204573:	48 89 45 a0          	mov    %rax,-0x60(%rbp)
        break;
  8004204577:	e9 26 03 00 00       	jmpq   80042048a2 <_dwarf_attr_init+0x595>
    case DW_FORM_data1:
    case DW_FORM_flag:
    case DW_FORM_ref1:
        atref.u[0].u64 = dbg->read(ds_data, offsetp, 1);
  800420457c:	48 8b 85 68 ff ff ff 	mov    -0x98(%rbp),%rax
  8004204583:	4c 8b 40 18          	mov    0x18(%rax),%r8
  8004204587:	48 8b 8d 60 ff ff ff 	mov    -0xa0(%rbp),%rcx
  800420458e:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004204592:	ba 01 00 00 00       	mov    $0x1,%edx
  8004204597:	48 89 ce             	mov    %rcx,%rsi
  800420459a:	48 89 c7             	mov    %rax,%rdi
  800420459d:	41 ff d0             	callq  *%r8
  80042045a0:	48 89 45 98          	mov    %rax,-0x68(%rbp)
        break;
  80042045a4:	e9 f9 02 00 00       	jmpq   80042048a2 <_dwarf_attr_init+0x595>
    case DW_FORM_data2:
    case DW_FORM_ref2:
        atref.u[0].u64 = dbg->read(ds_data, offsetp, 2);
  80042045a9:	48 8b 85 68 ff ff ff 	mov    -0x98(%rbp),%rax
  80042045b0:	4c 8b 40 18          	mov    0x18(%rax),%r8
  80042045b4:	48 8b 8d 60 ff ff ff 	mov    -0xa0(%rbp),%rcx
  80042045bb:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  80042045bf:	ba 02 00 00 00       	mov    $0x2,%edx
  80042045c4:	48 89 ce             	mov    %rcx,%rsi
  80042045c7:	48 89 c7             	mov    %rax,%rdi
  80042045ca:	41 ff d0             	callq  *%r8
  80042045cd:	48 89 45 98          	mov    %rax,-0x68(%rbp)
        break;
  80042045d1:	e9 cc 02 00 00       	jmpq   80042048a2 <_dwarf_attr_init+0x595>
    case DW_FORM_data4:
    case DW_FORM_ref4:
        atref.u[0].u64 = dbg->read(ds_data, offsetp, 4);
  80042045d6:	48 8b 85 68 ff ff ff 	mov    -0x98(%rbp),%rax
  80042045dd:	4c 8b 40 18          	mov    0x18(%rax),%r8
  80042045e1:	48 8b 8d 60 ff ff ff 	mov    -0xa0(%rbp),%rcx
  80042045e8:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  80042045ec:	ba 04 00 00 00       	mov    $0x4,%edx
  80042045f1:	48 89 ce             	mov    %rcx,%rsi
  80042045f4:	48 89 c7             	mov    %rax,%rdi
  80042045f7:	41 ff d0             	callq  *%r8
  80042045fa:	48 89 45 98          	mov    %rax,-0x68(%rbp)
        break;
  80042045fe:	e9 9f 02 00 00       	jmpq   80042048a2 <_dwarf_attr_init+0x595>
    case DW_FORM_data8:
    case DW_FORM_ref8:
        atref.u[0].u64 = dbg->read(ds_data, offsetp, 8);
  8004204603:	48 8b 85 68 ff ff ff 	mov    -0x98(%rbp),%rax
  800420460a:	4c 8b 40 18          	mov    0x18(%rax),%r8
  800420460e:	48 8b 8d 60 ff ff ff 	mov    -0xa0(%rbp),%rcx
  8004204615:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004204619:	ba 08 00 00 00       	mov    $0x8,%edx
  800420461e:	48 89 ce             	mov    %rcx,%rsi
  8004204621:	48 89 c7             	mov    %rax,%rdi
  8004204624:	41 ff d0             	callq  *%r8
  8004204627:	48 89 45 98          	mov    %rax,-0x68(%rbp)
        break;
  800420462b:	e9 72 02 00 00       	jmpq   80042048a2 <_dwarf_attr_init+0x595>
    case DW_FORM_indirect:
        form = _dwarf_read_uleb128(ds_data, offsetp);
  8004204630:	48 8b 95 60 ff ff ff 	mov    -0xa0(%rbp),%rdx
  8004204637:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  800420463b:	48 89 d6             	mov    %rdx,%rsi
  800420463e:	48 89 c7             	mov    %rax,%rdi
  8004204641:	48 b8 68 39 20 04 80 	movabs $0x8004203968,%rax
  8004204648:	00 00 00 
  800420464b:	ff d0                	callq  *%rax
  800420464d:	48 89 85 40 ff ff ff 	mov    %rax,-0xc0(%rbp)
        return (_dwarf_attr_init(dbg, offsetp, cu, ret_die, ad, form, 1));
  8004204654:	4c 8b 85 40 ff ff ff 	mov    -0xc0(%rbp),%r8
  800420465b:	48 8b bd 48 ff ff ff 	mov    -0xb8(%rbp),%rdi
  8004204662:	48 8b 8d 50 ff ff ff 	mov    -0xb0(%rbp),%rcx
  8004204669:	48 8b 95 58 ff ff ff 	mov    -0xa8(%rbp),%rdx
  8004204670:	48 8b b5 60 ff ff ff 	mov    -0xa0(%rbp),%rsi
  8004204677:	48 8b 85 68 ff ff ff 	mov    -0x98(%rbp),%rax
  800420467e:	c7 04 24 01 00 00 00 	movl   $0x1,(%rsp)
  8004204685:	4d 89 c1             	mov    %r8,%r9
  8004204688:	49 89 f8             	mov    %rdi,%r8
  800420468b:	48 89 c7             	mov    %rax,%rdi
  800420468e:	48 b8 0d 43 20 04 80 	movabs $0x800420430d,%rax
  8004204695:	00 00 00 
  8004204698:	ff d0                	callq  *%rax
  800420469a:	e9 31 03 00 00       	jmpq   80042049d0 <_dwarf_attr_init+0x6c3>
    case DW_FORM_ref_addr:
        if (cu->version == 2)
  800420469f:	48 8b 85 58 ff ff ff 	mov    -0xa8(%rbp),%rax
  80042046a6:	0f b7 40 08          	movzwl 0x8(%rax),%eax
  80042046aa:	66 83 f8 02          	cmp    $0x2,%ax
  80042046ae:	75 36                	jne    80042046e6 <_dwarf_attr_init+0x3d9>
            atref.u[0].u64 = dbg->read(ds_data, offsetp, cu->addr_size);
  80042046b0:	48 8b 85 68 ff ff ff 	mov    -0x98(%rbp),%rax
  80042046b7:	4c 8b 40 18          	mov    0x18(%rax),%r8
  80042046bb:	48 8b 85 58 ff ff ff 	mov    -0xa8(%rbp),%rax
  80042046c2:	0f b6 40 0a          	movzbl 0xa(%rax),%eax
  80042046c6:	0f b6 d0             	movzbl %al,%edx
  80042046c9:	48 8b 8d 60 ff ff ff 	mov    -0xa0(%rbp),%rcx
  80042046d0:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  80042046d4:	48 89 ce             	mov    %rcx,%rsi
  80042046d7:	48 89 c7             	mov    %rax,%rdi
  80042046da:	41 ff d0             	callq  *%r8
  80042046dd:	48 89 45 98          	mov    %rax,-0x68(%rbp)
        else if (cu->version == 3)
            atref.u[0].u64 = dbg->read(ds_data, offsetp, dwarf_size);
        break;
  80042046e1:	e9 bb 01 00 00       	jmpq   80042048a1 <_dwarf_attr_init+0x594>
        form = _dwarf_read_uleb128(ds_data, offsetp);
        return (_dwarf_attr_init(dbg, offsetp, cu, ret_die, ad, form, 1));
    case DW_FORM_ref_addr:
        if (cu->version == 2)
            atref.u[0].u64 = dbg->read(ds_data, offsetp, cu->addr_size);
        else if (cu->version == 3)
  80042046e6:	48 8b 85 58 ff ff ff 	mov    -0xa8(%rbp),%rax
  80042046ed:	0f b7 40 08          	movzwl 0x8(%rax),%eax
  80042046f1:	66 83 f8 03          	cmp    $0x3,%ax
  80042046f5:	0f 85 a6 01 00 00    	jne    80042048a1 <_dwarf_attr_init+0x594>
            atref.u[0].u64 = dbg->read(ds_data, offsetp, dwarf_size);
  80042046fb:	48 8b 85 68 ff ff ff 	mov    -0x98(%rbp),%rax
  8004204702:	4c 8b 40 18          	mov    0x18(%rax),%r8
  8004204706:	0f b6 55 e7          	movzbl -0x19(%rbp),%edx
  800420470a:	48 8b 8d 60 ff ff ff 	mov    -0xa0(%rbp),%rcx
  8004204711:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004204715:	48 89 ce             	mov    %rcx,%rsi
  8004204718:	48 89 c7             	mov    %rax,%rdi
  800420471b:	41 ff d0             	callq  *%r8
  800420471e:	48 89 45 98          	mov    %rax,-0x68(%rbp)
        break;
  8004204722:	e9 7a 01 00 00       	jmpq   80042048a1 <_dwarf_attr_init+0x594>
    case DW_FORM_ref_udata:
    case DW_FORM_udata:
        atref.u[0].u64 = _dwarf_read_uleb128(ds_data, offsetp);
  8004204727:	48 8b 95 60 ff ff ff 	mov    -0xa0(%rbp),%rdx
  800420472e:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004204732:	48 89 d6             	mov    %rdx,%rsi
  8004204735:	48 89 c7             	mov    %rax,%rdi
  8004204738:	48 b8 68 39 20 04 80 	movabs $0x8004203968,%rax
  800420473f:	00 00 00 
  8004204742:	ff d0                	callq  *%rax
  8004204744:	48 89 45 98          	mov    %rax,-0x68(%rbp)
        break;
  8004204748:	e9 55 01 00 00       	jmpq   80042048a2 <_dwarf_attr_init+0x595>
    case DW_FORM_sdata:
        atref.u[0].s64 = _dwarf_read_sleb128(ds_data, offsetp);
  800420474d:	48 8b 95 60 ff ff ff 	mov    -0xa0(%rbp),%rdx
  8004204754:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004204758:	48 89 d6             	mov    %rdx,%rsi
  800420475b:	48 89 c7             	mov    %rax,%rdi
  800420475e:	48 b8 c0 38 20 04 80 	movabs $0x80042038c0,%rax
  8004204765:	00 00 00 
  8004204768:	ff d0                	callq  *%rax
  800420476a:	48 89 45 98          	mov    %rax,-0x68(%rbp)
        break;
  800420476e:	e9 2f 01 00 00       	jmpq   80042048a2 <_dwarf_attr_init+0x595>
    case DW_FORM_sec_offset:
        atref.u[0].u64 = dbg->read(ds_data, offsetp, dwarf_size);
  8004204773:	48 8b 85 68 ff ff ff 	mov    -0x98(%rbp),%rax
  800420477a:	4c 8b 40 18          	mov    0x18(%rax),%r8
  800420477e:	0f b6 55 e7          	movzbl -0x19(%rbp),%edx
  8004204782:	48 8b 8d 60 ff ff ff 	mov    -0xa0(%rbp),%rcx
  8004204789:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  800420478d:	48 89 ce             	mov    %rcx,%rsi
  8004204790:	48 89 c7             	mov    %rax,%rdi
  8004204793:	41 ff d0             	callq  *%r8
  8004204796:	48 89 45 98          	mov    %rax,-0x68(%rbp)
        break;
  800420479a:	e9 03 01 00 00       	jmpq   80042048a2 <_dwarf_attr_init+0x595>
    case DW_FORM_string:
        atref.u[0].s =(char*) _dwarf_read_string(ds_data, (uint64_t)ds->ds_size, offsetp);
  800420479f:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  80042047a3:	48 8b 48 18          	mov    0x18(%rax),%rcx
  80042047a7:	48 8b 95 60 ff ff ff 	mov    -0xa0(%rbp),%rdx
  80042047ae:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  80042047b2:	48 89 ce             	mov    %rcx,%rsi
  80042047b5:	48 89 c7             	mov    %rax,%rdi
  80042047b8:	48 b8 f4 3a 20 04 80 	movabs $0x8004203af4,%rax
  80042047bf:	00 00 00 
  80042047c2:	ff d0                	callq  *%rax
  80042047c4:	48 89 45 98          	mov    %rax,-0x68(%rbp)
        break;
  80042047c8:	e9 d5 00 00 00       	jmpq   80042048a2 <_dwarf_attr_init+0x595>
    case DW_FORM_strp:
        atref.u[0].u64 = dbg->read(ds_data, offsetp, dwarf_size);
  80042047cd:	48 8b 85 68 ff ff ff 	mov    -0x98(%rbp),%rax
  80042047d4:	4c 8b 40 18          	mov    0x18(%rax),%r8
  80042047d8:	0f b6 55 e7          	movzbl -0x19(%rbp),%edx
  80042047dc:	48 8b 8d 60 ff ff ff 	mov    -0xa0(%rbp),%rcx
  80042047e3:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  80042047e7:	48 89 ce             	mov    %rcx,%rsi
  80042047ea:	48 89 c7             	mov    %rax,%rdi
  80042047ed:	41 ff d0             	callq  *%r8
  80042047f0:	48 89 45 98          	mov    %rax,-0x68(%rbp)
        str = _dwarf_find_section(".debug_str");
  80042047f4:	48 bf 22 9e 20 04 80 	movabs $0x8004209e22,%rdi
  80042047fb:	00 00 00 
  80042047fe:	48 b8 e8 85 20 04 80 	movabs $0x80042085e8,%rax
  8004204805:	00 00 00 
  8004204808:	ff d0                	callq  *%rax
  800420480a:	48 89 45 d8          	mov    %rax,-0x28(%rbp)
        assert(str != NULL);
  800420480e:	48 83 7d d8 00       	cmpq   $0x0,-0x28(%rbp)
  8004204813:	75 35                	jne    800420484a <_dwarf_attr_init+0x53d>
  8004204815:	48 b9 2d 9e 20 04 80 	movabs $0x8004209e2d,%rcx
  800420481c:	00 00 00 
  800420481f:	48 ba ba 9d 20 04 80 	movabs $0x8004209dba,%rdx
  8004204826:	00 00 00 
  8004204829:	be 53 02 00 00       	mov    $0x253,%esi
  800420482e:	48 bf cf 9d 20 04 80 	movabs $0x8004209dcf,%rdi
  8004204835:	00 00 00 
  8004204838:	b8 00 00 00 00       	mov    $0x0,%eax
  800420483d:	49 b8 9b 01 20 04 80 	movabs $0x800420019b,%r8
  8004204844:	00 00 00 
  8004204847:	41 ff d0             	callq  *%r8
        //atref.u[1].s = (char *)(elf_base_ptr + str->sh_offset) + atref.u[0].u64;
        atref.u[1].s = (char *)str->ds_data + atref.u[0].u64;
  800420484a:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  800420484e:	48 8b 50 08          	mov    0x8(%rax),%rdx
  8004204852:	48 8b 45 98          	mov    -0x68(%rbp),%rax
  8004204856:	48 01 d0             	add    %rdx,%rax
  8004204859:	48 89 45 a0          	mov    %rax,-0x60(%rbp)
        break;
  800420485d:	eb 43                	jmp    80042048a2 <_dwarf_attr_init+0x595>
    case DW_FORM_ref_sig8:
        atref.u[0].u64 = 8;
  800420485f:	48 c7 45 98 08 00 00 	movq   $0x8,-0x68(%rbp)
  8004204866:	00 
        atref.u[1].u8p = (uint8_t*)(_dwarf_read_block(ds_data, offsetp, atref.u[0].u64));
  8004204867:	48 8b 55 98          	mov    -0x68(%rbp),%rdx
  800420486b:	48 8b 8d 60 ff ff ff 	mov    -0xa0(%rbp),%rcx
  8004204872:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004204876:	48 89 ce             	mov    %rcx,%rsi
  8004204879:	48 89 c7             	mov    %rax,%rdi
  800420487c:	48 b8 80 3b 20 04 80 	movabs $0x8004203b80,%rax
  8004204883:	00 00 00 
  8004204886:	ff d0                	callq  *%rax
  8004204888:	48 89 45 a0          	mov    %rax,-0x60(%rbp)
        break;
  800420488c:	eb 14                	jmp    80042048a2 <_dwarf_attr_init+0x595>
    case DW_FORM_flag_present:
        /* This form has no value encoded in the DIE. */
        atref.u[0].u64 = 1;
  800420488e:	48 c7 45 98 01 00 00 	movq   $0x1,-0x68(%rbp)
  8004204895:	00 
        break;
  8004204896:	eb 0a                	jmp    80042048a2 <_dwarf_attr_init+0x595>
    default:
        //DWARF_SET_ERROR(dbg, error, DW_DLE_ATTR_FORM_BAD);
        ret = DW_DLE_ATTR_FORM_BAD;
  8004204898:	c7 45 fc 0e 00 00 00 	movl   $0xe,-0x4(%rbp)
        break;
  800420489f:	eb 01                	jmp    80042048a2 <_dwarf_attr_init+0x595>
    case DW_FORM_ref_addr:
        if (cu->version == 2)
            atref.u[0].u64 = dbg->read(ds_data, offsetp, cu->addr_size);
        else if (cu->version == 3)
            atref.u[0].u64 = dbg->read(ds_data, offsetp, dwarf_size);
        break;
  80042048a1:	90                   	nop
        //DWARF_SET_ERROR(dbg, error, DW_DLE_ATTR_FORM_BAD);
        ret = DW_DLE_ATTR_FORM_BAD;
        break;
    }

    if (ret == DW_DLE_NONE) {
  80042048a2:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  80042048a6:	0f 85 21 01 00 00    	jne    80042049cd <_dwarf_attr_init+0x6c0>
        if (form == DW_FORM_block || form == DW_FORM_block1 ||
  80042048ac:	48 83 bd 40 ff ff ff 	cmpq   $0x9,-0xc0(%rbp)
  80042048b3:	09 
  80042048b4:	74 1e                	je     80042048d4 <_dwarf_attr_init+0x5c7>
  80042048b6:	48 83 bd 40 ff ff ff 	cmpq   $0xa,-0xc0(%rbp)
  80042048bd:	0a 
  80042048be:	74 14                	je     80042048d4 <_dwarf_attr_init+0x5c7>
  80042048c0:	48 83 bd 40 ff ff ff 	cmpq   $0x3,-0xc0(%rbp)
  80042048c7:	03 
  80042048c8:	74 0a                	je     80042048d4 <_dwarf_attr_init+0x5c7>
            form == DW_FORM_block2 || form == DW_FORM_block4) {
  80042048ca:	48 83 bd 40 ff ff ff 	cmpq   $0x4,-0xc0(%rbp)
  80042048d1:	04 
  80042048d2:	75 10                	jne    80042048e4 <_dwarf_attr_init+0x5d7>
            atref.at_block.bl_len = atref.u[0].u64;
  80042048d4:	48 8b 45 98          	mov    -0x68(%rbp),%rax
  80042048d8:	48 89 45 a8          	mov    %rax,-0x58(%rbp)
            atref.at_block.bl_data = atref.u[1].u8p;
  80042048dc:	48 8b 45 a0          	mov    -0x60(%rbp),%rax
  80042048e0:	48 89 45 b0          	mov    %rax,-0x50(%rbp)
        }
        //ret = _dwarf_attr_add(die, &atref, NULL, error);
        if (atref.at_attrib == DW_AT_name) {
  80042048e4:	48 8b 45 80          	mov    -0x80(%rbp),%rax
  80042048e8:	48 83 f8 03          	cmp    $0x3,%rax
  80042048ec:	75 39                	jne    8004204927 <_dwarf_attr_init+0x61a>
                switch (atref.at_form) {
  80042048ee:	48 8b 45 88          	mov    -0x78(%rbp),%rax
  80042048f2:	48 83 f8 08          	cmp    $0x8,%rax
  80042048f6:	74 1a                	je     8004204912 <_dwarf_attr_init+0x605>
  80042048f8:	48 83 f8 0e          	cmp    $0xe,%rax
  80042048fc:	75 28                	jne    8004204926 <_dwarf_attr_init+0x619>
                case DW_FORM_strp:
                    ret_die->die_name = atref.u[1].s;
  80042048fe:	48 8b 55 a0          	mov    -0x60(%rbp),%rdx
  8004204902:	48 8b 85 50 ff ff ff 	mov    -0xb0(%rbp),%rax
  8004204909:	48 89 90 50 03 00 00 	mov    %rdx,0x350(%rax)
                    break;
  8004204910:	eb 15                	jmp    8004204927 <_dwarf_attr_init+0x61a>
                case DW_FORM_string:
                    ret_die->die_name = atref.u[0].s;
  8004204912:	48 8b 55 98          	mov    -0x68(%rbp),%rdx
  8004204916:	48 8b 85 50 ff ff ff 	mov    -0xb0(%rbp),%rax
  800420491d:	48 89 90 50 03 00 00 	mov    %rdx,0x350(%rax)
                    break;
  8004204924:	eb 01                	jmp    8004204927 <_dwarf_attr_init+0x61a>
                default:
                    break;
  8004204926:	90                   	nop
                }
        }
        ret_die->die_attr[ret_die->die_attr_count++] = atref;
  8004204927:	48 8b 85 50 ff ff ff 	mov    -0xb0(%rbp),%rax
  800420492e:	0f b6 90 58 03 00 00 	movzbl 0x358(%rax),%edx
  8004204935:	0f b6 c2             	movzbl %dl,%eax
  8004204938:	48 8b b5 50 ff ff ff 	mov    -0xb0(%rbp),%rsi
  800420493f:	48 63 c8             	movslq %eax,%rcx
  8004204942:	48 89 c8             	mov    %rcx,%rax
  8004204945:	48 01 c0             	add    %rax,%rax
  8004204948:	48 01 c8             	add    %rcx,%rax
  800420494b:	48 c1 e0 05          	shl    $0x5,%rax
  800420494f:	48 01 f0             	add    %rsi,%rax
  8004204952:	48 05 70 03 00 00    	add    $0x370,%rax
  8004204958:	48 8b 8d 70 ff ff ff 	mov    -0x90(%rbp),%rcx
  800420495f:	48 89 08             	mov    %rcx,(%rax)
  8004204962:	48 8b 8d 78 ff ff ff 	mov    -0x88(%rbp),%rcx
  8004204969:	48 89 48 08          	mov    %rcx,0x8(%rax)
  800420496d:	48 8b 4d 80          	mov    -0x80(%rbp),%rcx
  8004204971:	48 89 48 10          	mov    %rcx,0x10(%rax)
  8004204975:	48 8b 4d 88          	mov    -0x78(%rbp),%rcx
  8004204979:	48 89 48 18          	mov    %rcx,0x18(%rax)
  800420497d:	48 8b 4d 90          	mov    -0x70(%rbp),%rcx
  8004204981:	48 89 48 20          	mov    %rcx,0x20(%rax)
  8004204985:	48 8b 4d 98          	mov    -0x68(%rbp),%rcx
  8004204989:	48 89 48 28          	mov    %rcx,0x28(%rax)
  800420498d:	48 8b 4d a0          	mov    -0x60(%rbp),%rcx
  8004204991:	48 89 48 30          	mov    %rcx,0x30(%rax)
  8004204995:	48 8b 4d a8          	mov    -0x58(%rbp),%rcx
  8004204999:	48 89 48 38          	mov    %rcx,0x38(%rax)
  800420499d:	48 8b 4d b0          	mov    -0x50(%rbp),%rcx
  80042049a1:	48 89 48 40          	mov    %rcx,0x40(%rax)
  80042049a5:	48 8b 4d b8          	mov    -0x48(%rbp),%rcx
  80042049a9:	48 89 48 48          	mov    %rcx,0x48(%rax)
  80042049ad:	48 8b 4d c0          	mov    -0x40(%rbp),%rcx
  80042049b1:	48 89 48 50          	mov    %rcx,0x50(%rax)
  80042049b5:	48 8b 4d c8          	mov    -0x38(%rbp),%rcx
  80042049b9:	48 89 48 58          	mov    %rcx,0x58(%rax)
  80042049bd:	83 c2 01             	add    $0x1,%edx
  80042049c0:	48 8b 85 50 ff ff ff 	mov    -0xb0(%rbp),%rax
  80042049c7:	88 90 58 03 00 00    	mov    %dl,0x358(%rax)
    }

    return (ret);
  80042049cd:	8b 45 fc             	mov    -0x4(%rbp),%eax
}
  80042049d0:	c9                   	leaveq 
  80042049d1:	c3                   	retq   

00000080042049d2 <dwarf_search_die_within_cu>:

int
dwarf_search_die_within_cu(Dwarf_Debug dbg, Dwarf_CU cu, uint64_t offset, Dwarf_Die *ret_die, int search_sibling)
{
  80042049d2:	55                   	push   %rbp
  80042049d3:	48 89 e5             	mov    %rsp,%rbp
  80042049d6:	48 81 ec d0 03 00 00 	sub    $0x3d0,%rsp
  80042049dd:	48 89 bd 88 fc ff ff 	mov    %rdi,-0x378(%rbp)
  80042049e4:	48 89 b5 80 fc ff ff 	mov    %rsi,-0x380(%rbp)
  80042049eb:	48 89 95 78 fc ff ff 	mov    %rdx,-0x388(%rbp)
  80042049f2:	89 8d 74 fc ff ff    	mov    %ecx,-0x38c(%rbp)
    uint64_t abnum;
    uint64_t die_offset;
    int ret, level;
    int i;

    assert(dbg);
  80042049f8:	48 83 bd 88 fc ff ff 	cmpq   $0x0,-0x378(%rbp)
  80042049ff:	00 
  8004204a00:	75 35                	jne    8004204a37 <dwarf_search_die_within_cu+0x65>
  8004204a02:	48 b9 48 9f 20 04 80 	movabs $0x8004209f48,%rcx
  8004204a09:	00 00 00 
  8004204a0c:	48 ba ba 9d 20 04 80 	movabs $0x8004209dba,%rdx
  8004204a13:	00 00 00 
  8004204a16:	be 88 02 00 00       	mov    $0x288,%esi
  8004204a1b:	48 bf cf 9d 20 04 80 	movabs $0x8004209dcf,%rdi
  8004204a22:	00 00 00 
  8004204a25:	b8 00 00 00 00       	mov    $0x0,%eax
  8004204a2a:	49 b8 9b 01 20 04 80 	movabs $0x800420019b,%r8
  8004204a31:	00 00 00 
  8004204a34:	41 ff d0             	callq  *%r8
    //assert(cu);
    assert(ret_die);
  8004204a37:	48 83 bd 78 fc ff ff 	cmpq   $0x0,-0x388(%rbp)
  8004204a3e:	00 
  8004204a3f:	75 35                	jne    8004204a76 <dwarf_search_die_within_cu+0xa4>
  8004204a41:	48 b9 4c 9f 20 04 80 	movabs $0x8004209f4c,%rcx
  8004204a48:	00 00 00 
  8004204a4b:	48 ba ba 9d 20 04 80 	movabs $0x8004209dba,%rdx
  8004204a52:	00 00 00 
  8004204a55:	be 8a 02 00 00       	mov    $0x28a,%esi
  8004204a5a:	48 bf cf 9d 20 04 80 	movabs $0x8004209dcf,%rdi
  8004204a61:	00 00 00 
  8004204a64:	b8 00 00 00 00       	mov    $0x0,%eax
  8004204a69:	49 b8 9b 01 20 04 80 	movabs $0x800420019b,%r8
  8004204a70:	00 00 00 
  8004204a73:	41 ff d0             	callq  *%r8

    level = 1;
  8004204a76:	c7 45 fc 01 00 00 00 	movl   $0x1,-0x4(%rbp)

    while (offset < cu.cu_next_offset && offset < dbg->dbg_info_size) {
  8004204a7d:	e9 15 02 00 00       	jmpq   8004204c97 <dwarf_search_die_within_cu+0x2c5>

        die_offset = offset;
  8004204a82:	48 8b 85 80 fc ff ff 	mov    -0x380(%rbp),%rax
  8004204a89:	48 89 45 f0          	mov    %rax,-0x10(%rbp)

        abnum = _dwarf_read_uleb128((uint8_t *)dbg->dbg_info_offset_elf, &offset);
  8004204a8d:	48 8b 85 88 fc ff ff 	mov    -0x378(%rbp),%rax
  8004204a94:	48 8b 40 08          	mov    0x8(%rax),%rax
  8004204a98:	48 8d 95 80 fc ff ff 	lea    -0x380(%rbp),%rdx
  8004204a9f:	48 89 d6             	mov    %rdx,%rsi
  8004204aa2:	48 89 c7             	mov    %rax,%rdi
  8004204aa5:	48 b8 68 39 20 04 80 	movabs $0x8004203968,%rax
  8004204aac:	00 00 00 
  8004204aaf:	ff d0                	callq  *%rax
  8004204ab1:	48 89 45 e8          	mov    %rax,-0x18(%rbp)

        if (abnum == 0) {
  8004204ab5:	48 83 7d e8 00       	cmpq   $0x0,-0x18(%rbp)
  8004204aba:	75 22                	jne    8004204ade <dwarf_search_die_within_cu+0x10c>
            if (level == 0 || !search_sibling) {
  8004204abc:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  8004204ac0:	74 09                	je     8004204acb <dwarf_search_die_within_cu+0xf9>
  8004204ac2:	83 bd 74 fc ff ff 00 	cmpl   $0x0,-0x38c(%rbp)
  8004204ac9:	75 0a                	jne    8004204ad5 <dwarf_search_die_within_cu+0x103>
                //No more entry
                return (DW_DLE_NO_ENTRY);
  8004204acb:	b8 04 00 00 00       	mov    $0x4,%eax
  8004204ad0:	e9 f2 01 00 00       	jmpq   8004204cc7 <dwarf_search_die_within_cu+0x2f5>
            }
            /*
             * Return to previous DIE level.
             */
            level--;
  8004204ad5:	83 6d fc 01          	subl   $0x1,-0x4(%rbp)
            continue;
  8004204ad9:	e9 b9 01 00 00       	jmpq   8004204c97 <dwarf_search_die_within_cu+0x2c5>
        }

        if ((ret = _dwarf_abbrev_find(dbg, cu, abnum, &ab)) != DW_DLE_NONE)
  8004204ade:	48 8d 95 b0 fc ff ff 	lea    -0x350(%rbp),%rdx
  8004204ae5:	48 8b 4d e8          	mov    -0x18(%rbp),%rcx
  8004204ae9:	48 8b 85 88 fc ff ff 	mov    -0x378(%rbp),%rax
  8004204af0:	48 8b 75 10          	mov    0x10(%rbp),%rsi
  8004204af4:	48 89 34 24          	mov    %rsi,(%rsp)
  8004204af8:	48 8b 75 18          	mov    0x18(%rbp),%rsi
  8004204afc:	48 89 74 24 08       	mov    %rsi,0x8(%rsp)
  8004204b01:	48 8b 75 20          	mov    0x20(%rbp),%rsi
  8004204b05:	48 89 74 24 10       	mov    %rsi,0x10(%rsp)
  8004204b0a:	48 8b 75 28          	mov    0x28(%rbp),%rsi
  8004204b0e:	48 89 74 24 18       	mov    %rsi,0x18(%rsp)
  8004204b13:	48 8b 75 30          	mov    0x30(%rbp),%rsi
  8004204b17:	48 89 74 24 20       	mov    %rsi,0x20(%rsp)
  8004204b1c:	48 8b 75 38          	mov    0x38(%rbp),%rsi
  8004204b20:	48 89 74 24 28       	mov    %rsi,0x28(%rsp)
  8004204b25:	48 8b 75 40          	mov    0x40(%rbp),%rsi
  8004204b29:	48 89 74 24 30       	mov    %rsi,0x30(%rsp)
  8004204b2e:	48 89 ce             	mov    %rcx,%rsi
  8004204b31:	48 89 c7             	mov    %rax,%rdi
  8004204b34:	48 b8 db 41 20 04 80 	movabs $0x80042041db,%rax
  8004204b3b:	00 00 00 
  8004204b3e:	ff d0                	callq  *%rax
  8004204b40:	89 45 e4             	mov    %eax,-0x1c(%rbp)
  8004204b43:	83 7d e4 00          	cmpl   $0x0,-0x1c(%rbp)
  8004204b47:	74 08                	je     8004204b51 <dwarf_search_die_within_cu+0x17f>
            return (ret);
  8004204b49:	8b 45 e4             	mov    -0x1c(%rbp),%eax
  8004204b4c:	e9 76 01 00 00       	jmpq   8004204cc7 <dwarf_search_die_within_cu+0x2f5>
        ret_die->die_offset = die_offset;
  8004204b51:	48 8b 85 78 fc ff ff 	mov    -0x388(%rbp),%rax
  8004204b58:	48 8b 55 f0          	mov    -0x10(%rbp),%rdx
  8004204b5c:	48 89 10             	mov    %rdx,(%rax)
        ret_die->die_abnum  = abnum;
  8004204b5f:	48 8b 85 78 fc ff ff 	mov    -0x388(%rbp),%rax
  8004204b66:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  8004204b6a:	48 89 50 10          	mov    %rdx,0x10(%rax)
        ret_die->die_ab  = ab;
  8004204b6e:	48 8b 85 78 fc ff ff 	mov    -0x388(%rbp),%rax
  8004204b75:	48 8d 78 20          	lea    0x20(%rax),%rdi
  8004204b79:	48 8d 95 b0 fc ff ff 	lea    -0x350(%rbp),%rdx
  8004204b80:	b8 66 00 00 00       	mov    $0x66,%eax
  8004204b85:	48 89 d6             	mov    %rdx,%rsi
  8004204b88:	48 89 c1             	mov    %rax,%rcx
  8004204b8b:	f3 48 a5             	rep movsq %ds:(%rsi),%es:(%rdi)
        ret_die->die_attr_count = 0;
  8004204b8e:	48 8b 85 78 fc ff ff 	mov    -0x388(%rbp),%rax
  8004204b95:	c6 80 58 03 00 00 00 	movb   $0x0,0x358(%rax)
        ret_die->die_tag = ab.ab_tag;
  8004204b9c:	48 8b 95 b8 fc ff ff 	mov    -0x348(%rbp),%rdx
  8004204ba3:	48 8b 85 78 fc ff ff 	mov    -0x388(%rbp),%rax
  8004204baa:	48 89 50 18          	mov    %rdx,0x18(%rax)
        //ret_die->die_cu  = cu;
        //ret_die->die_dbg = cu->cu_dbg;

        for(i=0; i < ab.ab_atnum; i++)
  8004204bae:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%rbp)
  8004204bb5:	e9 8e 00 00 00       	jmpq   8004204c48 <dwarf_search_die_within_cu+0x276>
        {
            if ((ret = _dwarf_attr_init(dbg, &offset, &cu, ret_die, &ab.ab_attrdef[i], ab.ab_attrdef[i].ad_form, 0)) != DW_DLE_NONE)
  8004204bba:	8b 45 f8             	mov    -0x8(%rbp),%eax
  8004204bbd:	48 63 d0             	movslq %eax,%rdx
  8004204bc0:	48 89 d0             	mov    %rdx,%rax
  8004204bc3:	48 01 c0             	add    %rax,%rax
  8004204bc6:	48 01 d0             	add    %rdx,%rax
  8004204bc9:	48 c1 e0 03          	shl    $0x3,%rax
  8004204bcd:	48 01 e8             	add    %rbp,%rax
  8004204bd0:	48 2d 18 03 00 00    	sub    $0x318,%rax
  8004204bd6:	48 8b 08             	mov    (%rax),%rcx
  8004204bd9:	8b 45 f8             	mov    -0x8(%rbp),%eax
  8004204bdc:	48 63 d0             	movslq %eax,%rdx
  8004204bdf:	48 89 d0             	mov    %rdx,%rax
  8004204be2:	48 01 c0             	add    %rax,%rax
  8004204be5:	48 01 d0             	add    %rdx,%rax
  8004204be8:	48 c1 e0 03          	shl    $0x3,%rax
  8004204bec:	48 8d 95 b0 fc ff ff 	lea    -0x350(%rbp),%rdx
  8004204bf3:	48 83 c2 30          	add    $0x30,%rdx
  8004204bf7:	48 8d 3c 02          	lea    (%rdx,%rax,1),%rdi
  8004204bfb:	48 8b 95 78 fc ff ff 	mov    -0x388(%rbp),%rdx
  8004204c02:	48 8d b5 80 fc ff ff 	lea    -0x380(%rbp),%rsi
  8004204c09:	48 8b 85 88 fc ff ff 	mov    -0x378(%rbp),%rax
  8004204c10:	c7 04 24 00 00 00 00 	movl   $0x0,(%rsp)
  8004204c17:	49 89 c9             	mov    %rcx,%r9
  8004204c1a:	49 89 f8             	mov    %rdi,%r8
  8004204c1d:	48 89 d1             	mov    %rdx,%rcx
  8004204c20:	48 8d 55 10          	lea    0x10(%rbp),%rdx
  8004204c24:	48 89 c7             	mov    %rax,%rdi
  8004204c27:	48 b8 0d 43 20 04 80 	movabs $0x800420430d,%rax
  8004204c2e:	00 00 00 
  8004204c31:	ff d0                	callq  *%rax
  8004204c33:	89 45 e4             	mov    %eax,-0x1c(%rbp)
  8004204c36:	83 7d e4 00          	cmpl   $0x0,-0x1c(%rbp)
  8004204c3a:	74 08                	je     8004204c44 <dwarf_search_die_within_cu+0x272>
                return (ret);
  8004204c3c:	8b 45 e4             	mov    -0x1c(%rbp),%eax
  8004204c3f:	e9 83 00 00 00       	jmpq   8004204cc7 <dwarf_search_die_within_cu+0x2f5>
        ret_die->die_attr_count = 0;
        ret_die->die_tag = ab.ab_tag;
        //ret_die->die_cu  = cu;
        //ret_die->die_dbg = cu->cu_dbg;

        for(i=0; i < ab.ab_atnum; i++)
  8004204c44:	83 45 f8 01          	addl   $0x1,-0x8(%rbp)
  8004204c48:	8b 45 f8             	mov    -0x8(%rbp),%eax
  8004204c4b:	48 63 d0             	movslq %eax,%rdx
  8004204c4e:	48 8b 85 d8 fc ff ff 	mov    -0x328(%rbp),%rax
  8004204c55:	48 39 c2             	cmp    %rax,%rdx
  8004204c58:	0f 82 5c ff ff ff    	jb     8004204bba <dwarf_search_die_within_cu+0x1e8>
        {
            if ((ret = _dwarf_attr_init(dbg, &offset, &cu, ret_die, &ab.ab_attrdef[i], ab.ab_attrdef[i].ad_form, 0)) != DW_DLE_NONE)
                return (ret);
        }

        ret_die->die_next_off = offset;
  8004204c5e:	48 8b 95 80 fc ff ff 	mov    -0x380(%rbp),%rdx
  8004204c65:	48 8b 85 78 fc ff ff 	mov    -0x388(%rbp),%rax
  8004204c6c:	48 89 50 08          	mov    %rdx,0x8(%rax)
        if (search_sibling && level > 0) {
  8004204c70:	83 bd 74 fc ff ff 00 	cmpl   $0x0,-0x38c(%rbp)
  8004204c77:	74 17                	je     8004204c90 <dwarf_search_die_within_cu+0x2be>
  8004204c79:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  8004204c7d:	7e 11                	jle    8004204c90 <dwarf_search_die_within_cu+0x2be>
            //dwarf_dealloc(dbg, die, DW_DLA_DIE);
            if (ab.ab_children == DW_CHILDREN_yes) {
  8004204c7f:	0f b6 85 c0 fc ff ff 	movzbl -0x340(%rbp),%eax
  8004204c86:	3c 01                	cmp    $0x1,%al
  8004204c88:	75 0d                	jne    8004204c97 <dwarf_search_die_within_cu+0x2c5>
                /* Advance to next DIE level. */
                level++;
  8004204c8a:	83 45 fc 01          	addl   $0x1,-0x4(%rbp)
        }

        ret_die->die_next_off = offset;
        if (search_sibling && level > 0) {
            //dwarf_dealloc(dbg, die, DW_DLA_DIE);
            if (ab.ab_children == DW_CHILDREN_yes) {
  8004204c8e:	eb 07                	jmp    8004204c97 <dwarf_search_die_within_cu+0x2c5>
                /* Advance to next DIE level. */
                level++;
            }
        } else {
            //*ret_die = die;
            return (DW_DLE_NONE);
  8004204c90:	b8 00 00 00 00       	mov    $0x0,%eax
  8004204c95:	eb 30                	jmp    8004204cc7 <dwarf_search_die_within_cu+0x2f5>
    //assert(cu);
    assert(ret_die);

    level = 1;

    while (offset < cu.cu_next_offset && offset < dbg->dbg_info_size) {
  8004204c97:	48 8b 55 30          	mov    0x30(%rbp),%rdx
  8004204c9b:	48 8b 85 80 fc ff ff 	mov    -0x380(%rbp),%rax
  8004204ca2:	48 39 c2             	cmp    %rax,%rdx
  8004204ca5:	76 1b                	jbe    8004204cc2 <dwarf_search_die_within_cu+0x2f0>
  8004204ca7:	48 8b 85 88 fc ff ff 	mov    -0x378(%rbp),%rax
  8004204cae:	48 8b 50 10          	mov    0x10(%rax),%rdx
  8004204cb2:	48 8b 85 80 fc ff ff 	mov    -0x380(%rbp),%rax
  8004204cb9:	48 39 c2             	cmp    %rax,%rdx
  8004204cbc:	0f 87 c0 fd ff ff    	ja     8004204a82 <dwarf_search_die_within_cu+0xb0>
            //*ret_die = die;
            return (DW_DLE_NONE);
        }
    }

    return (DW_DLE_NO_ENTRY);
  8004204cc2:	b8 04 00 00 00       	mov    $0x4,%eax
}
  8004204cc7:	c9                   	leaveq 
  8004204cc8:	c3                   	retq   

0000008004204cc9 <dwarf_offdie>:

//Return 0 on success
int
dwarf_offdie(Dwarf_Debug dbg, uint64_t offset, Dwarf_Die *ret_die, Dwarf_CU cu)
{
  8004204cc9:	55                   	push   %rbp
  8004204cca:	48 89 e5             	mov    %rsp,%rbp
  8004204ccd:	48 83 ec 70          	sub    $0x70,%rsp
  8004204cd1:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
  8004204cd5:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
  8004204cd9:	48 89 55 d8          	mov    %rdx,-0x28(%rbp)
    int ret;

    assert(dbg);
  8004204cdd:	48 83 7d e8 00       	cmpq   $0x0,-0x18(%rbp)
  8004204ce2:	75 35                	jne    8004204d19 <dwarf_offdie+0x50>
  8004204ce4:	48 b9 48 9f 20 04 80 	movabs $0x8004209f48,%rcx
  8004204ceb:	00 00 00 
  8004204cee:	48 ba ba 9d 20 04 80 	movabs $0x8004209dba,%rdx
  8004204cf5:	00 00 00 
  8004204cf8:	be c6 02 00 00       	mov    $0x2c6,%esi
  8004204cfd:	48 bf cf 9d 20 04 80 	movabs $0x8004209dcf,%rdi
  8004204d04:	00 00 00 
  8004204d07:	b8 00 00 00 00       	mov    $0x0,%eax
  8004204d0c:	49 b8 9b 01 20 04 80 	movabs $0x800420019b,%r8
  8004204d13:	00 00 00 
  8004204d16:	41 ff d0             	callq  *%r8
    assert(ret_die);
  8004204d19:	48 83 7d d8 00       	cmpq   $0x0,-0x28(%rbp)
  8004204d1e:	75 35                	jne    8004204d55 <dwarf_offdie+0x8c>
  8004204d20:	48 b9 4c 9f 20 04 80 	movabs $0x8004209f4c,%rcx
  8004204d27:	00 00 00 
  8004204d2a:	48 ba ba 9d 20 04 80 	movabs $0x8004209dba,%rdx
  8004204d31:	00 00 00 
  8004204d34:	be c7 02 00 00       	mov    $0x2c7,%esi
  8004204d39:	48 bf cf 9d 20 04 80 	movabs $0x8004209dcf,%rdi
  8004204d40:	00 00 00 
  8004204d43:	b8 00 00 00 00       	mov    $0x0,%eax
  8004204d48:	49 b8 9b 01 20 04 80 	movabs $0x800420019b,%r8
  8004204d4f:	00 00 00 
  8004204d52:	41 ff d0             	callq  *%r8

    /* First search the current CU. */
	if (offset < cu.cu_next_offset) {
  8004204d55:	48 8b 45 30          	mov    0x30(%rbp),%rax
  8004204d59:	48 3b 45 e0          	cmp    -0x20(%rbp),%rax
  8004204d5d:	76 66                	jbe    8004204dc5 <dwarf_offdie+0xfc>
		ret = dwarf_search_die_within_cu(dbg, cu, offset, ret_die, 0);
  8004204d5f:	48 8b 55 d8          	mov    -0x28(%rbp),%rdx
  8004204d63:	48 8b 75 e0          	mov    -0x20(%rbp),%rsi
  8004204d67:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004204d6b:	48 8b 4d 10          	mov    0x10(%rbp),%rcx
  8004204d6f:	48 89 0c 24          	mov    %rcx,(%rsp)
  8004204d73:	48 8b 4d 18          	mov    0x18(%rbp),%rcx
  8004204d77:	48 89 4c 24 08       	mov    %rcx,0x8(%rsp)
  8004204d7c:	48 8b 4d 20          	mov    0x20(%rbp),%rcx
  8004204d80:	48 89 4c 24 10       	mov    %rcx,0x10(%rsp)
  8004204d85:	48 8b 4d 28          	mov    0x28(%rbp),%rcx
  8004204d89:	48 89 4c 24 18       	mov    %rcx,0x18(%rsp)
  8004204d8e:	48 8b 4d 30          	mov    0x30(%rbp),%rcx
  8004204d92:	48 89 4c 24 20       	mov    %rcx,0x20(%rsp)
  8004204d97:	48 8b 4d 38          	mov    0x38(%rbp),%rcx
  8004204d9b:	48 89 4c 24 28       	mov    %rcx,0x28(%rsp)
  8004204da0:	48 8b 4d 40          	mov    0x40(%rbp),%rcx
  8004204da4:	48 89 4c 24 30       	mov    %rcx,0x30(%rsp)
  8004204da9:	b9 00 00 00 00       	mov    $0x0,%ecx
  8004204dae:	48 89 c7             	mov    %rax,%rdi
  8004204db1:	48 b8 d2 49 20 04 80 	movabs $0x80042049d2,%rax
  8004204db8:	00 00 00 
  8004204dbb:	ff d0                	callq  *%rax
  8004204dbd:	89 45 fc             	mov    %eax,-0x4(%rbp)
		return ret;
  8004204dc0:	8b 45 fc             	mov    -0x4(%rbp),%eax
  8004204dc3:	eb 05                	jmp    8004204dca <dwarf_offdie+0x101>
	}

    /*TODO: Search other CU*/
    return DW_DLV_OK;
  8004204dc5:	b8 00 00 00 00       	mov    $0x0,%eax
}
  8004204dca:	c9                   	leaveq 
  8004204dcb:	c3                   	retq   

0000008004204dcc <_dwarf_attr_find>:

Dwarf_Attribute*
_dwarf_attr_find(Dwarf_Die *die, uint16_t attr)
{
  8004204dcc:	55                   	push   %rbp
  8004204dcd:	48 89 e5             	mov    %rsp,%rbp
  8004204dd0:	48 83 ec 20          	sub    $0x20,%rsp
  8004204dd4:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
  8004204dd8:	89 f0                	mov    %esi,%eax
  8004204dda:	66 89 45 e4          	mov    %ax,-0x1c(%rbp)
    Dwarf_Attribute *myat = NULL;
  8004204dde:	48 c7 45 f8 00 00 00 	movq   $0x0,-0x8(%rbp)
  8004204de5:	00 
    int i;
    
    for(i=0; i < die->die_attr_count; i++)
  8004204de6:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%rbp)
  8004204ded:	eb 57                	jmp    8004204e46 <_dwarf_attr_find+0x7a>
    {
        if (die->die_attr[i].at_attrib == attr)
  8004204def:	48 8b 4d e8          	mov    -0x18(%rbp),%rcx
  8004204df3:	8b 45 f4             	mov    -0xc(%rbp),%eax
  8004204df6:	48 63 d0             	movslq %eax,%rdx
  8004204df9:	48 89 d0             	mov    %rdx,%rax
  8004204dfc:	48 01 c0             	add    %rax,%rax
  8004204dff:	48 01 d0             	add    %rdx,%rax
  8004204e02:	48 c1 e0 05          	shl    $0x5,%rax
  8004204e06:	48 01 c8             	add    %rcx,%rax
  8004204e09:	48 05 80 03 00 00    	add    $0x380,%rax
  8004204e0f:	48 8b 10             	mov    (%rax),%rdx
  8004204e12:	0f b7 45 e4          	movzwl -0x1c(%rbp),%eax
  8004204e16:	48 39 c2             	cmp    %rax,%rdx
  8004204e19:	75 27                	jne    8004204e42 <_dwarf_attr_find+0x76>
        {
            myat = &(die->die_attr[i]);
  8004204e1b:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004204e1f:	48 8d 88 70 03 00 00 	lea    0x370(%rax),%rcx
  8004204e26:	8b 45 f4             	mov    -0xc(%rbp),%eax
  8004204e29:	48 63 d0             	movslq %eax,%rdx
  8004204e2c:	48 89 d0             	mov    %rdx,%rax
  8004204e2f:	48 01 c0             	add    %rax,%rax
  8004204e32:	48 01 d0             	add    %rdx,%rax
  8004204e35:	48 c1 e0 05          	shl    $0x5,%rax
  8004204e39:	48 01 c8             	add    %rcx,%rax
  8004204e3c:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
            break;
  8004204e40:	eb 17                	jmp    8004204e59 <_dwarf_attr_find+0x8d>
_dwarf_attr_find(Dwarf_Die *die, uint16_t attr)
{
    Dwarf_Attribute *myat = NULL;
    int i;
    
    for(i=0; i < die->die_attr_count; i++)
  8004204e42:	83 45 f4 01          	addl   $0x1,-0xc(%rbp)
  8004204e46:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004204e4a:	0f b6 80 58 03 00 00 	movzbl 0x358(%rax),%eax
  8004204e51:	0f b6 c0             	movzbl %al,%eax
  8004204e54:	3b 45 f4             	cmp    -0xc(%rbp),%eax
  8004204e57:	7f 96                	jg     8004204def <_dwarf_attr_find+0x23>
            myat = &(die->die_attr[i]);
            break;
        }
    }

    return myat;
  8004204e59:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
}
  8004204e5d:	c9                   	leaveq 
  8004204e5e:	c3                   	retq   

0000008004204e5f <dwarf_siblingof>:

//Return 0 on success
int
dwarf_siblingof(Dwarf_Debug dbg, Dwarf_Die *die, Dwarf_Die *ret_die,
    Dwarf_CU *cu)
{
  8004204e5f:	55                   	push   %rbp
  8004204e60:	48 89 e5             	mov    %rsp,%rbp
  8004204e63:	48 83 c4 80          	add    $0xffffffffffffff80,%rsp
  8004204e67:	48 89 7d d8          	mov    %rdi,-0x28(%rbp)
  8004204e6b:	48 89 75 d0          	mov    %rsi,-0x30(%rbp)
  8004204e6f:	48 89 55 c8          	mov    %rdx,-0x38(%rbp)
  8004204e73:	48 89 4d c0          	mov    %rcx,-0x40(%rbp)
    Dwarf_Attribute *at;
    uint64_t offset;
    int ret, search_sibling;

    assert(dbg);
  8004204e77:	48 83 7d d8 00       	cmpq   $0x0,-0x28(%rbp)
  8004204e7c:	75 35                	jne    8004204eb3 <dwarf_siblingof+0x54>
  8004204e7e:	48 b9 48 9f 20 04 80 	movabs $0x8004209f48,%rcx
  8004204e85:	00 00 00 
  8004204e88:	48 ba ba 9d 20 04 80 	movabs $0x8004209dba,%rdx
  8004204e8f:	00 00 00 
  8004204e92:	be ee 02 00 00       	mov    $0x2ee,%esi
  8004204e97:	48 bf cf 9d 20 04 80 	movabs $0x8004209dcf,%rdi
  8004204e9e:	00 00 00 
  8004204ea1:	b8 00 00 00 00       	mov    $0x0,%eax
  8004204ea6:	49 b8 9b 01 20 04 80 	movabs $0x800420019b,%r8
  8004204ead:	00 00 00 
  8004204eb0:	41 ff d0             	callq  *%r8
    assert(ret_die);
  8004204eb3:	48 83 7d c8 00       	cmpq   $0x0,-0x38(%rbp)
  8004204eb8:	75 35                	jne    8004204eef <dwarf_siblingof+0x90>
  8004204eba:	48 b9 4c 9f 20 04 80 	movabs $0x8004209f4c,%rcx
  8004204ec1:	00 00 00 
  8004204ec4:	48 ba ba 9d 20 04 80 	movabs $0x8004209dba,%rdx
  8004204ecb:	00 00 00 
  8004204ece:	be ef 02 00 00       	mov    $0x2ef,%esi
  8004204ed3:	48 bf cf 9d 20 04 80 	movabs $0x8004209dcf,%rdi
  8004204eda:	00 00 00 
  8004204edd:	b8 00 00 00 00       	mov    $0x0,%eax
  8004204ee2:	49 b8 9b 01 20 04 80 	movabs $0x800420019b,%r8
  8004204ee9:	00 00 00 
  8004204eec:	41 ff d0             	callq  *%r8
    assert(cu);
  8004204eef:	48 83 7d c0 00       	cmpq   $0x0,-0x40(%rbp)
  8004204ef4:	75 35                	jne    8004204f2b <dwarf_siblingof+0xcc>
  8004204ef6:	48 b9 54 9f 20 04 80 	movabs $0x8004209f54,%rcx
  8004204efd:	00 00 00 
  8004204f00:	48 ba ba 9d 20 04 80 	movabs $0x8004209dba,%rdx
  8004204f07:	00 00 00 
  8004204f0a:	be f0 02 00 00       	mov    $0x2f0,%esi
  8004204f0f:	48 bf cf 9d 20 04 80 	movabs $0x8004209dcf,%rdi
  8004204f16:	00 00 00 
  8004204f19:	b8 00 00 00 00       	mov    $0x0,%eax
  8004204f1e:	49 b8 9b 01 20 04 80 	movabs $0x800420019b,%r8
  8004204f25:	00 00 00 
  8004204f28:	41 ff d0             	callq  *%r8

    /* Application requests the first DIE in this CU. */
    if (die == NULL)
  8004204f2b:	48 83 7d d0 00       	cmpq   $0x0,-0x30(%rbp)
  8004204f30:	75 65                	jne    8004204f97 <dwarf_siblingof+0x138>
        return (dwarf_offdie(dbg, cu->cu_die_offset, ret_die, *cu));
  8004204f32:	48 8b 45 c0          	mov    -0x40(%rbp),%rax
  8004204f36:	48 8b 70 28          	mov    0x28(%rax),%rsi
  8004204f3a:	48 8b 55 c8          	mov    -0x38(%rbp),%rdx
  8004204f3e:	48 8b 4d d8          	mov    -0x28(%rbp),%rcx
  8004204f42:	48 8b 45 c0          	mov    -0x40(%rbp),%rax
  8004204f46:	48 8b 38             	mov    (%rax),%rdi
  8004204f49:	48 89 3c 24          	mov    %rdi,(%rsp)
  8004204f4d:	48 8b 78 08          	mov    0x8(%rax),%rdi
  8004204f51:	48 89 7c 24 08       	mov    %rdi,0x8(%rsp)
  8004204f56:	48 8b 78 10          	mov    0x10(%rax),%rdi
  8004204f5a:	48 89 7c 24 10       	mov    %rdi,0x10(%rsp)
  8004204f5f:	48 8b 78 18          	mov    0x18(%rax),%rdi
  8004204f63:	48 89 7c 24 18       	mov    %rdi,0x18(%rsp)
  8004204f68:	48 8b 78 20          	mov    0x20(%rax),%rdi
  8004204f6c:	48 89 7c 24 20       	mov    %rdi,0x20(%rsp)
  8004204f71:	48 8b 78 28          	mov    0x28(%rax),%rdi
  8004204f75:	48 89 7c 24 28       	mov    %rdi,0x28(%rsp)
  8004204f7a:	48 8b 40 30          	mov    0x30(%rax),%rax
  8004204f7e:	48 89 44 24 30       	mov    %rax,0x30(%rsp)
  8004204f83:	48 89 cf             	mov    %rcx,%rdi
  8004204f86:	48 b8 c9 4c 20 04 80 	movabs $0x8004204cc9,%rax
  8004204f8d:	00 00 00 
  8004204f90:	ff d0                	callq  *%rax
  8004204f92:	e9 0a 01 00 00       	jmpq   80042050a1 <dwarf_siblingof+0x242>

    /*
     * If the DIE doesn't have any children, its sibling sits next
     * right to it.
     */
    search_sibling = 0;
  8004204f97:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%rbp)
    if (die->die_ab.ab_children == DW_CHILDREN_no)
  8004204f9e:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  8004204fa2:	0f b6 40 30          	movzbl 0x30(%rax),%eax
  8004204fa6:	84 c0                	test   %al,%al
  8004204fa8:	75 0e                	jne    8004204fb8 <dwarf_siblingof+0x159>
        offset = die->die_next_off;
  8004204faa:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  8004204fae:	48 8b 40 08          	mov    0x8(%rax),%rax
  8004204fb2:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
  8004204fb6:	eb 6b                	jmp    8004205023 <dwarf_siblingof+0x1c4>
    else {
        /*
         * Look for DW_AT_sibling attribute for the offset of
         * its sibling.
         */
        if ((at = _dwarf_attr_find(die, DW_AT_sibling)) != NULL) {
  8004204fb8:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  8004204fbc:	be 01 00 00 00       	mov    $0x1,%esi
  8004204fc1:	48 89 c7             	mov    %rax,%rdi
  8004204fc4:	48 b8 cc 4d 20 04 80 	movabs $0x8004204dcc,%rax
  8004204fcb:	00 00 00 
  8004204fce:	ff d0                	callq  *%rax
  8004204fd0:	48 89 45 e8          	mov    %rax,-0x18(%rbp)
  8004204fd4:	48 83 7d e8 00       	cmpq   $0x0,-0x18(%rbp)
  8004204fd9:	74 35                	je     8004205010 <dwarf_siblingof+0x1b1>
            if (at->at_form != DW_FORM_ref_addr)
  8004204fdb:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004204fdf:	48 8b 40 18          	mov    0x18(%rax),%rax
  8004204fe3:	48 83 f8 10          	cmp    $0x10,%rax
  8004204fe7:	74 19                	je     8004205002 <dwarf_siblingof+0x1a3>
                offset = at->u[0].u64 + cu->cu_offset;
  8004204fe9:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004204fed:	48 8b 50 28          	mov    0x28(%rax),%rdx
  8004204ff1:	48 8b 45 c0          	mov    -0x40(%rbp),%rax
  8004204ff5:	48 8b 40 30          	mov    0x30(%rax),%rax
  8004204ff9:	48 01 d0             	add    %rdx,%rax
  8004204ffc:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
  8004205000:	eb 21                	jmp    8004205023 <dwarf_siblingof+0x1c4>
            else
                offset = at->u[0].u64;
  8004205002:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004205006:	48 8b 40 28          	mov    0x28(%rax),%rax
  800420500a:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
  800420500e:	eb 13                	jmp    8004205023 <dwarf_siblingof+0x1c4>
        } else {
            offset = die->die_next_off;
  8004205010:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  8004205014:	48 8b 40 08          	mov    0x8(%rax),%rax
  8004205018:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
            search_sibling = 1;
  800420501c:	c7 45 f4 01 00 00 00 	movl   $0x1,-0xc(%rbp)
        }
    }

    ret = dwarf_search_die_within_cu(dbg, *cu, offset, ret_die, search_sibling);
  8004205023:	8b 4d f4             	mov    -0xc(%rbp),%ecx
  8004205026:	48 8b 55 c8          	mov    -0x38(%rbp),%rdx
  800420502a:	48 8b 75 f8          	mov    -0x8(%rbp),%rsi
  800420502e:	48 8b 7d d8          	mov    -0x28(%rbp),%rdi
  8004205032:	48 8b 45 c0          	mov    -0x40(%rbp),%rax
  8004205036:	4c 8b 00             	mov    (%rax),%r8
  8004205039:	4c 89 04 24          	mov    %r8,(%rsp)
  800420503d:	4c 8b 40 08          	mov    0x8(%rax),%r8
  8004205041:	4c 89 44 24 08       	mov    %r8,0x8(%rsp)
  8004205046:	4c 8b 40 10          	mov    0x10(%rax),%r8
  800420504a:	4c 89 44 24 10       	mov    %r8,0x10(%rsp)
  800420504f:	4c 8b 40 18          	mov    0x18(%rax),%r8
  8004205053:	4c 89 44 24 18       	mov    %r8,0x18(%rsp)
  8004205058:	4c 8b 40 20          	mov    0x20(%rax),%r8
  800420505c:	4c 89 44 24 20       	mov    %r8,0x20(%rsp)
  8004205061:	4c 8b 40 28          	mov    0x28(%rax),%r8
  8004205065:	4c 89 44 24 28       	mov    %r8,0x28(%rsp)
  800420506a:	48 8b 40 30          	mov    0x30(%rax),%rax
  800420506e:	48 89 44 24 30       	mov    %rax,0x30(%rsp)
  8004205073:	48 b8 d2 49 20 04 80 	movabs $0x80042049d2,%rax
  800420507a:	00 00 00 
  800420507d:	ff d0                	callq  *%rax
  800420507f:	89 45 e4             	mov    %eax,-0x1c(%rbp)


    if (ret == DW_DLE_NO_ENTRY) {
  8004205082:	83 7d e4 04          	cmpl   $0x4,-0x1c(%rbp)
  8004205086:	75 07                	jne    800420508f <dwarf_siblingof+0x230>
        return (DW_DLV_NO_ENTRY);
  8004205088:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  800420508d:	eb 12                	jmp    80042050a1 <dwarf_siblingof+0x242>
    } else if (ret != DW_DLE_NONE)
  800420508f:	83 7d e4 00          	cmpl   $0x0,-0x1c(%rbp)
  8004205093:	74 07                	je     800420509c <dwarf_siblingof+0x23d>
        return (DW_DLV_ERROR);
  8004205095:	b8 01 00 00 00       	mov    $0x1,%eax
  800420509a:	eb 05                	jmp    80042050a1 <dwarf_siblingof+0x242>


    return (DW_DLV_OK);
  800420509c:	b8 00 00 00 00       	mov    $0x0,%eax
}
  80042050a1:	c9                   	leaveq 
  80042050a2:	c3                   	retq   

00000080042050a3 <dwarf_child>:

int
dwarf_child(Dwarf_Debug dbg, Dwarf_CU *cu, Dwarf_Die *die, Dwarf_Die *ret_die)
{
  80042050a3:	55                   	push   %rbp
  80042050a4:	48 89 e5             	mov    %rsp,%rbp
  80042050a7:	48 83 ec 70          	sub    $0x70,%rsp
  80042050ab:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
  80042050af:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
  80042050b3:	48 89 55 d8          	mov    %rdx,-0x28(%rbp)
  80042050b7:	48 89 4d d0          	mov    %rcx,-0x30(%rbp)
    int ret;

    assert(die);
  80042050bb:	48 83 7d d8 00       	cmpq   $0x0,-0x28(%rbp)
  80042050c0:	75 35                	jne    80042050f7 <dwarf_child+0x54>
  80042050c2:	48 b9 57 9f 20 04 80 	movabs $0x8004209f57,%rcx
  80042050c9:	00 00 00 
  80042050cc:	48 ba ba 9d 20 04 80 	movabs $0x8004209dba,%rdx
  80042050d3:	00 00 00 
  80042050d6:	be 1e 03 00 00       	mov    $0x31e,%esi
  80042050db:	48 bf cf 9d 20 04 80 	movabs $0x8004209dcf,%rdi
  80042050e2:	00 00 00 
  80042050e5:	b8 00 00 00 00       	mov    $0x0,%eax
  80042050ea:	49 b8 9b 01 20 04 80 	movabs $0x800420019b,%r8
  80042050f1:	00 00 00 
  80042050f4:	41 ff d0             	callq  *%r8
    assert(ret_die);
  80042050f7:	48 83 7d d0 00       	cmpq   $0x0,-0x30(%rbp)
  80042050fc:	75 35                	jne    8004205133 <dwarf_child+0x90>
  80042050fe:	48 b9 4c 9f 20 04 80 	movabs $0x8004209f4c,%rcx
  8004205105:	00 00 00 
  8004205108:	48 ba ba 9d 20 04 80 	movabs $0x8004209dba,%rdx
  800420510f:	00 00 00 
  8004205112:	be 1f 03 00 00       	mov    $0x31f,%esi
  8004205117:	48 bf cf 9d 20 04 80 	movabs $0x8004209dcf,%rdi
  800420511e:	00 00 00 
  8004205121:	b8 00 00 00 00       	mov    $0x0,%eax
  8004205126:	49 b8 9b 01 20 04 80 	movabs $0x800420019b,%r8
  800420512d:	00 00 00 
  8004205130:	41 ff d0             	callq  *%r8
    assert(dbg);
  8004205133:	48 83 7d e8 00       	cmpq   $0x0,-0x18(%rbp)
  8004205138:	75 35                	jne    800420516f <dwarf_child+0xcc>
  800420513a:	48 b9 48 9f 20 04 80 	movabs $0x8004209f48,%rcx
  8004205141:	00 00 00 
  8004205144:	48 ba ba 9d 20 04 80 	movabs $0x8004209dba,%rdx
  800420514b:	00 00 00 
  800420514e:	be 20 03 00 00       	mov    $0x320,%esi
  8004205153:	48 bf cf 9d 20 04 80 	movabs $0x8004209dcf,%rdi
  800420515a:	00 00 00 
  800420515d:	b8 00 00 00 00       	mov    $0x0,%eax
  8004205162:	49 b8 9b 01 20 04 80 	movabs $0x800420019b,%r8
  8004205169:	00 00 00 
  800420516c:	41 ff d0             	callq  *%r8
    assert(cu);
  800420516f:	48 83 7d e0 00       	cmpq   $0x0,-0x20(%rbp)
  8004205174:	75 35                	jne    80042051ab <dwarf_child+0x108>
  8004205176:	48 b9 54 9f 20 04 80 	movabs $0x8004209f54,%rcx
  800420517d:	00 00 00 
  8004205180:	48 ba ba 9d 20 04 80 	movabs $0x8004209dba,%rdx
  8004205187:	00 00 00 
  800420518a:	be 21 03 00 00       	mov    $0x321,%esi
  800420518f:	48 bf cf 9d 20 04 80 	movabs $0x8004209dcf,%rdi
  8004205196:	00 00 00 
  8004205199:	b8 00 00 00 00       	mov    $0x0,%eax
  800420519e:	49 b8 9b 01 20 04 80 	movabs $0x800420019b,%r8
  80042051a5:	00 00 00 
  80042051a8:	41 ff d0             	callq  *%r8

    if (die->die_ab.ab_children == DW_CHILDREN_no)
  80042051ab:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  80042051af:	0f b6 40 30          	movzbl 0x30(%rax),%eax
  80042051b3:	84 c0                	test   %al,%al
  80042051b5:	75 0a                	jne    80042051c1 <dwarf_child+0x11e>
        return (DW_DLE_NO_ENTRY);
  80042051b7:	b8 04 00 00 00       	mov    $0x4,%eax
  80042051bc:	e9 84 00 00 00       	jmpq   8004205245 <dwarf_child+0x1a2>

    ret = dwarf_search_die_within_cu(dbg, *cu, die->die_next_off, ret_die, 0);
  80042051c1:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  80042051c5:	48 8b 70 08          	mov    0x8(%rax),%rsi
  80042051c9:	48 8b 55 d0          	mov    -0x30(%rbp),%rdx
  80042051cd:	48 8b 7d e8          	mov    -0x18(%rbp),%rdi
  80042051d1:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  80042051d5:	48 8b 08             	mov    (%rax),%rcx
  80042051d8:	48 89 0c 24          	mov    %rcx,(%rsp)
  80042051dc:	48 8b 48 08          	mov    0x8(%rax),%rcx
  80042051e0:	48 89 4c 24 08       	mov    %rcx,0x8(%rsp)
  80042051e5:	48 8b 48 10          	mov    0x10(%rax),%rcx
  80042051e9:	48 89 4c 24 10       	mov    %rcx,0x10(%rsp)
  80042051ee:	48 8b 48 18          	mov    0x18(%rax),%rcx
  80042051f2:	48 89 4c 24 18       	mov    %rcx,0x18(%rsp)
  80042051f7:	48 8b 48 20          	mov    0x20(%rax),%rcx
  80042051fb:	48 89 4c 24 20       	mov    %rcx,0x20(%rsp)
  8004205200:	48 8b 48 28          	mov    0x28(%rax),%rcx
  8004205204:	48 89 4c 24 28       	mov    %rcx,0x28(%rsp)
  8004205209:	48 8b 40 30          	mov    0x30(%rax),%rax
  800420520d:	48 89 44 24 30       	mov    %rax,0x30(%rsp)
  8004205212:	b9 00 00 00 00       	mov    $0x0,%ecx
  8004205217:	48 b8 d2 49 20 04 80 	movabs $0x80042049d2,%rax
  800420521e:	00 00 00 
  8004205221:	ff d0                	callq  *%rax
  8004205223:	89 45 fc             	mov    %eax,-0x4(%rbp)

    if (ret == DW_DLE_NO_ENTRY) {
  8004205226:	83 7d fc 04          	cmpl   $0x4,-0x4(%rbp)
  800420522a:	75 07                	jne    8004205233 <dwarf_child+0x190>
        DWARF_SET_ERROR(dbg, error, DW_DLE_NO_ENTRY);
        return (DW_DLV_NO_ENTRY);
  800420522c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  8004205231:	eb 12                	jmp    8004205245 <dwarf_child+0x1a2>
    } else if (ret != DW_DLE_NONE)
  8004205233:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  8004205237:	74 07                	je     8004205240 <dwarf_child+0x19d>
        return (DW_DLV_ERROR);
  8004205239:	b8 01 00 00 00       	mov    $0x1,%eax
  800420523e:	eb 05                	jmp    8004205245 <dwarf_child+0x1a2>

    return (DW_DLV_OK);
  8004205240:	b8 00 00 00 00       	mov    $0x0,%eax
}
  8004205245:	c9                   	leaveq 
  8004205246:	c3                   	retq   

0000008004205247 <_dwarf_find_section_enhanced>:


int  _dwarf_find_section_enhanced(Dwarf_Section *ds)
{
  8004205247:	55                   	push   %rbp
  8004205248:	48 89 e5             	mov    %rsp,%rbp
  800420524b:	48 83 ec 20          	sub    $0x20,%rsp
  800420524f:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
    Dwarf_Section *secthdr = _dwarf_find_section(ds->ds_name);
  8004205253:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004205257:	48 8b 00             	mov    (%rax),%rax
  800420525a:	48 89 c7             	mov    %rax,%rdi
  800420525d:	48 b8 e8 85 20 04 80 	movabs $0x80042085e8,%rax
  8004205264:	00 00 00 
  8004205267:	ff d0                	callq  *%rax
  8004205269:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
    ds->ds_data = secthdr->ds_data;//(Dwarf_Small*)((uint8_t *)elf_base_ptr + secthdr->sh_offset);
  800420526d:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8004205271:	48 8b 50 08          	mov    0x8(%rax),%rdx
  8004205275:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004205279:	48 89 50 08          	mov    %rdx,0x8(%rax)
    ds->ds_addr = secthdr->ds_addr;
  800420527d:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8004205281:	48 8b 50 10          	mov    0x10(%rax),%rdx
  8004205285:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004205289:	48 89 50 10          	mov    %rdx,0x10(%rax)
    ds->ds_size = secthdr->ds_size;
  800420528d:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8004205291:	48 8b 50 18          	mov    0x18(%rax),%rdx
  8004205295:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004205299:	48 89 50 18          	mov    %rdx,0x18(%rax)
    return 0;
  800420529d:	b8 00 00 00 00       	mov    $0x0,%eax

}
  80042052a2:	c9                   	leaveq 
  80042052a3:	c3                   	retq   

00000080042052a4 <_dwarf_frame_params_init>:
int  _dwarf_find_section_enhanced(Dwarf_Section *ds);


void
_dwarf_frame_params_init(Dwarf_Debug dbg)
{
  80042052a4:	55                   	push   %rbp
  80042052a5:	48 89 e5             	mov    %rsp,%rbp
  80042052a8:	48 83 ec 08          	sub    $0x8,%rsp
  80042052ac:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)

        /* Initialise call frame related parameters. */
        dbg->dbg_frame_rule_table_size = DW_FRAME_LAST_REG_NUM;
  80042052b0:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  80042052b4:	66 c7 40 40 42 00    	movw   $0x42,0x40(%rax)
        dbg->dbg_frame_rule_initial_value = DW_FRAME_REG_INITIAL_VALUE;
  80042052ba:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  80042052be:	66 c7 40 42 0b 04    	movw   $0x40b,0x42(%rax)
        dbg->dbg_frame_cfa_value = DW_FRAME_CFA_COL3;
  80042052c4:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  80042052c8:	66 c7 40 44 9c 05    	movw   $0x59c,0x44(%rax)
        dbg->dbg_frame_same_value = DW_FRAME_SAME_VAL;
  80042052ce:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  80042052d2:	66 c7 40 46 0b 04    	movw   $0x40b,0x46(%rax)
        dbg->dbg_frame_undefined_value = DW_FRAME_UNDEFINED_VAL;
  80042052d8:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  80042052dc:	66 c7 40 48 0a 04    	movw   $0x40a,0x48(%rax)
}
  80042052e2:	c9                   	leaveq 
  80042052e3:	c3                   	retq   

00000080042052e4 <dwarf_get_fde_at_pc>:


int
dwarf_get_fde_at_pc(Dwarf_Addr pc,
    Dwarf_Addr *lopc, Dwarf_Addr *hipc, struct _Dwarf_Fde *ret_fde, Dwarf_Cie cie, Dwarf_Error *error)
{
  80042052e4:	55                   	push   %rbp
  80042052e5:	48 89 e5             	mov    %rsp,%rbp
  80042052e8:	48 83 ec 40          	sub    $0x40,%rsp
  80042052ec:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
  80042052f0:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
  80042052f4:	48 89 55 d8          	mov    %rdx,-0x28(%rbp)
  80042052f8:	48 89 4d d0          	mov    %rcx,-0x30(%rbp)
  80042052fc:	4c 89 45 c8          	mov    %r8,-0x38(%rbp)
  8004205300:	4c 89 4d c0          	mov    %r9,-0x40(%rbp)
    Dwarf_Fde fde = ret_fde;
  8004205304:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  8004205308:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
	memset(fde, 0, sizeof(struct _Dwarf_Fde));
  800420530c:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8004205310:	ba 80 00 00 00       	mov    $0x80,%edx
  8004205315:	be 00 00 00 00       	mov    $0x0,%esi
  800420531a:	48 89 c7             	mov    %rax,%rdi
  800420531d:	48 b8 5b 2e 20 04 80 	movabs $0x8004202e5b,%rax
  8004205324:	00 00 00 
  8004205327:	ff d0                	callq  *%rax
	fde->fde_cie = cie;
  8004205329:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  800420532d:	48 8b 55 c8          	mov    -0x38(%rbp),%rdx
  8004205331:	48 89 50 08          	mov    %rdx,0x8(%rax)
	
        if (ret_fde == NULL || lopc == NULL || hipc == NULL) {
  8004205335:	48 83 7d d0 00       	cmpq   $0x0,-0x30(%rbp)
  800420533a:	74 12                	je     800420534e <dwarf_get_fde_at_pc+0x6a>
  800420533c:	48 83 7d e0 00       	cmpq   $0x0,-0x20(%rbp)
  8004205341:	74 0b                	je     800420534e <dwarf_get_fde_at_pc+0x6a>
  8004205343:	48 83 7d d8 00       	cmpq   $0x0,-0x28(%rbp)
  8004205348:	0f 85 a3 00 00 00    	jne    80042053f1 <dwarf_get_fde_at_pc+0x10d>
                return (DW_DLV_ERROR);
  800420534e:	b8 01 00 00 00       	mov    $0x1,%eax
  8004205353:	e9 ca 00 00 00       	jmpq   8004205422 <dwarf_get_fde_at_pc+0x13e>
        }

        while(dbg->dbg_eh_offset < dbg->dbg_eh_size) {
                if (_dwarf_get_next_fde(dbg, is_eh_frame, error, fde) < 0)
  8004205358:	48 b8 00 b6 21 04 80 	movabs $0x800421b600,%rax
  800420535f:	00 00 00 
  8004205362:	8b 30                	mov    (%rax),%esi
  8004205364:	48 b8 c8 b5 21 04 80 	movabs $0x800421b5c8,%rax
  800420536b:	00 00 00 
  800420536e:	48 8b 00             	mov    (%rax),%rax
  8004205371:	48 8b 4d f8          	mov    -0x8(%rbp),%rcx
  8004205375:	48 8b 55 c0          	mov    -0x40(%rbp),%rdx
  8004205379:	48 89 c7             	mov    %rax,%rdi
  800420537c:	48 b8 52 75 20 04 80 	movabs $0x8004207552,%rax
  8004205383:	00 00 00 
  8004205386:	ff d0                	callq  *%rax
  8004205388:	85 c0                	test   %eax,%eax
  800420538a:	79 0a                	jns    8004205396 <dwarf_get_fde_at_pc+0xb2>
				{
		    		return DW_DLV_NO_ENTRY;
  800420538c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  8004205391:	e9 8c 00 00 00       	jmpq   8004205422 <dwarf_get_fde_at_pc+0x13e>
				}
                if (pc >= fde->fde_initloc && pc < fde->fde_initloc +
  8004205396:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  800420539a:	48 8b 40 30          	mov    0x30(%rax),%rax
  800420539e:	48 3b 45 e8          	cmp    -0x18(%rbp),%rax
  80042053a2:	77 4e                	ja     80042053f2 <dwarf_get_fde_at_pc+0x10e>
  80042053a4:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  80042053a8:	48 8b 50 30          	mov    0x30(%rax),%rdx
                    fde->fde_adrange) {
  80042053ac:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  80042053b0:	48 8b 40 38          	mov    0x38(%rax),%rax
        while(dbg->dbg_eh_offset < dbg->dbg_eh_size) {
                if (_dwarf_get_next_fde(dbg, is_eh_frame, error, fde) < 0)
				{
		    		return DW_DLV_NO_ENTRY;
				}
                if (pc >= fde->fde_initloc && pc < fde->fde_initloc +
  80042053b4:	48 01 d0             	add    %rdx,%rax
  80042053b7:	48 3b 45 e8          	cmp    -0x18(%rbp),%rax
  80042053bb:	76 35                	jbe    80042053f2 <dwarf_get_fde_at_pc+0x10e>
                    fde->fde_adrange) {
                        *lopc = fde->fde_initloc;
  80042053bd:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  80042053c1:	48 8b 50 30          	mov    0x30(%rax),%rdx
  80042053c5:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  80042053c9:	48 89 10             	mov    %rdx,(%rax)
                        *hipc = fde->fde_initloc + fde->fde_adrange - 1;
  80042053cc:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  80042053d0:	48 8b 50 30          	mov    0x30(%rax),%rdx
  80042053d4:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  80042053d8:	48 8b 40 38          	mov    0x38(%rax),%rax
  80042053dc:	48 01 d0             	add    %rdx,%rax
  80042053df:	48 8d 50 ff          	lea    -0x1(%rax),%rdx
  80042053e3:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  80042053e7:	48 89 10             	mov    %rdx,(%rax)

                        return (DW_DLV_OK);
  80042053ea:	b8 00 00 00 00       	mov    $0x0,%eax
  80042053ef:	eb 31                	jmp    8004205422 <dwarf_get_fde_at_pc+0x13e>
	
        if (ret_fde == NULL || lopc == NULL || hipc == NULL) {
                return (DW_DLV_ERROR);
        }

        while(dbg->dbg_eh_offset < dbg->dbg_eh_size) {
  80042053f1:	90                   	nop
  80042053f2:	48 b8 c8 b5 21 04 80 	movabs $0x800421b5c8,%rax
  80042053f9:	00 00 00 
  80042053fc:	48 8b 00             	mov    (%rax),%rax
  80042053ff:	48 8b 50 30          	mov    0x30(%rax),%rdx
  8004205403:	48 b8 c8 b5 21 04 80 	movabs $0x800421b5c8,%rax
  800420540a:	00 00 00 
  800420540d:	48 8b 00             	mov    (%rax),%rax
  8004205410:	48 8b 40 38          	mov    0x38(%rax),%rax
  8004205414:	48 39 c2             	cmp    %rax,%rdx
  8004205417:	0f 82 3b ff ff ff    	jb     8004205358 <dwarf_get_fde_at_pc+0x74>
                        return (DW_DLV_OK);
                }
        }

        DWARF_SET_ERROR(dbg, error, DW_DLE_NO_ENTRY);
        return (DW_DLV_NO_ENTRY);
  800420541d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
  8004205422:	c9                   	leaveq 
  8004205423:	c3                   	retq   

0000008004205424 <_dwarf_frame_regtable_copy>:

int
_dwarf_frame_regtable_copy(Dwarf_Debug dbg, Dwarf_Regtable3 **dest,
    Dwarf_Regtable3 *src, Dwarf_Error *error)
{
  8004205424:	55                   	push   %rbp
  8004205425:	48 89 e5             	mov    %rsp,%rbp
  8004205428:	48 83 ec 30          	sub    $0x30,%rsp
  800420542c:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
  8004205430:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
  8004205434:	48 89 55 d8          	mov    %rdx,-0x28(%rbp)
  8004205438:	48 89 4d d0          	mov    %rcx,-0x30(%rbp)
        int i;

        assert(dest != NULL);
  800420543c:	48 83 7d e0 00       	cmpq   $0x0,-0x20(%rbp)
  8004205441:	75 35                	jne    8004205478 <_dwarf_frame_regtable_copy+0x54>
  8004205443:	48 b9 6a 9f 20 04 80 	movabs $0x8004209f6a,%rcx
  800420544a:	00 00 00 
  800420544d:	48 ba 77 9f 20 04 80 	movabs $0x8004209f77,%rdx
  8004205454:	00 00 00 
  8004205457:	be 63 00 00 00       	mov    $0x63,%esi
  800420545c:	48 bf 8c 9f 20 04 80 	movabs $0x8004209f8c,%rdi
  8004205463:	00 00 00 
  8004205466:	b8 00 00 00 00       	mov    $0x0,%eax
  800420546b:	49 b8 9b 01 20 04 80 	movabs $0x800420019b,%r8
  8004205472:	00 00 00 
  8004205475:	41 ff d0             	callq  *%r8
        assert(src != NULL);
  8004205478:	48 83 7d d8 00       	cmpq   $0x0,-0x28(%rbp)
  800420547d:	75 35                	jne    80042054b4 <_dwarf_frame_regtable_copy+0x90>
  800420547f:	48 b9 a2 9f 20 04 80 	movabs $0x8004209fa2,%rcx
  8004205486:	00 00 00 
  8004205489:	48 ba 77 9f 20 04 80 	movabs $0x8004209f77,%rdx
  8004205490:	00 00 00 
  8004205493:	be 64 00 00 00       	mov    $0x64,%esi
  8004205498:	48 bf 8c 9f 20 04 80 	movabs $0x8004209f8c,%rdi
  800420549f:	00 00 00 
  80042054a2:	b8 00 00 00 00       	mov    $0x0,%eax
  80042054a7:	49 b8 9b 01 20 04 80 	movabs $0x800420019b,%r8
  80042054ae:	00 00 00 
  80042054b1:	41 ff d0             	callq  *%r8

        if (*dest == NULL) {
  80042054b4:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  80042054b8:	48 8b 00             	mov    (%rax),%rax
  80042054bb:	48 85 c0             	test   %rax,%rax
  80042054be:	75 39                	jne    80042054f9 <_dwarf_frame_regtable_copy+0xd5>
		*dest = &global_rt_table_shadow;
  80042054c0:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  80042054c4:	48 ba 40 bd 21 04 80 	movabs $0x800421bd40,%rdx
  80042054cb:	00 00 00 
  80042054ce:	48 89 10             	mov    %rdx,(%rax)
                /*if ((*dest = malloc(sizeof(Dwarf_Regtable3))) == NULL) {
                        DWARF_SET_ERROR(dbg, error, DW_DLE_MEMORY);
                        return (DW_DLE_MEMORY);
                }*/
                (*dest)->rt3_reg_table_size = src->rt3_reg_table_size;
  80042054d1:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  80042054d5:	48 8b 00             	mov    (%rax),%rax
  80042054d8:	48 8b 55 d8          	mov    -0x28(%rbp),%rdx
  80042054dc:	0f b7 52 18          	movzwl 0x18(%rdx),%edx
  80042054e0:	66 89 50 18          	mov    %dx,0x18(%rax)
		(*dest)->rt3_rules = global_rules_shadow;
  80042054e4:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  80042054e8:	48 8b 00             	mov    (%rax),%rax
  80042054eb:	48 ba e0 bd 21 04 80 	movabs $0x800421bde0,%rdx
  80042054f2:	00 00 00 
  80042054f5:	48 89 50 20          	mov    %rdx,0x20(%rax)
                        DWARF_SET_ERROR(dbg, error, DW_DLE_MEMORY);
                        return (DW_DLE_MEMORY);
                }*/
        }

        memcpy(&(*dest)->rt3_cfa_rule, &src->rt3_cfa_rule,
  80042054f9:	48 8b 4d d8          	mov    -0x28(%rbp),%rcx
  80042054fd:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  8004205501:	48 8b 00             	mov    (%rax),%rax
  8004205504:	ba 18 00 00 00       	mov    $0x18,%edx
  8004205509:	48 89 ce             	mov    %rcx,%rsi
  800420550c:	48 89 c7             	mov    %rax,%rdi
  800420550f:	48 b8 fd 2f 20 04 80 	movabs $0x8004202ffd,%rax
  8004205516:	00 00 00 
  8004205519:	ff d0                	callq  *%rax
            sizeof(Dwarf_Regtable_Entry3));

        for (i = 0; i < (*dest)->rt3_reg_table_size &&
  800420551b:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%rbp)
  8004205522:	eb 5a                	jmp    800420557e <_dwarf_frame_regtable_copy+0x15a>
             i < src->rt3_reg_table_size; i++)
                memcpy(&(*dest)->rt3_rules[i], &src->rt3_rules[i],
  8004205524:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  8004205528:	48 8b 48 20          	mov    0x20(%rax),%rcx
  800420552c:	8b 45 fc             	mov    -0x4(%rbp),%eax
  800420552f:	48 63 d0             	movslq %eax,%rdx
  8004205532:	48 89 d0             	mov    %rdx,%rax
  8004205535:	48 01 c0             	add    %rax,%rax
  8004205538:	48 01 d0             	add    %rdx,%rax
  800420553b:	48 c1 e0 03          	shl    $0x3,%rax
  800420553f:	48 01 c1             	add    %rax,%rcx
  8004205542:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  8004205546:	48 8b 00             	mov    (%rax),%rax
  8004205549:	48 8b 70 20          	mov    0x20(%rax),%rsi
  800420554d:	8b 45 fc             	mov    -0x4(%rbp),%eax
  8004205550:	48 63 d0             	movslq %eax,%rdx
  8004205553:	48 89 d0             	mov    %rdx,%rax
  8004205556:	48 01 c0             	add    %rax,%rax
  8004205559:	48 01 d0             	add    %rdx,%rax
  800420555c:	48 c1 e0 03          	shl    $0x3,%rax
  8004205560:	48 01 f0             	add    %rsi,%rax
  8004205563:	ba 18 00 00 00       	mov    $0x18,%edx
  8004205568:	48 89 ce             	mov    %rcx,%rsi
  800420556b:	48 89 c7             	mov    %rax,%rdi
  800420556e:	48 b8 fd 2f 20 04 80 	movabs $0x8004202ffd,%rax
  8004205575:	00 00 00 
  8004205578:	ff d0                	callq  *%rax

        memcpy(&(*dest)->rt3_cfa_rule, &src->rt3_cfa_rule,
            sizeof(Dwarf_Regtable_Entry3));

        for (i = 0; i < (*dest)->rt3_reg_table_size &&
             i < src->rt3_reg_table_size; i++)
  800420557a:	83 45 fc 01          	addl   $0x1,-0x4(%rbp)
        }

        memcpy(&(*dest)->rt3_cfa_rule, &src->rt3_cfa_rule,
            sizeof(Dwarf_Regtable_Entry3));

        for (i = 0; i < (*dest)->rt3_reg_table_size &&
  800420557e:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  8004205582:	48 8b 00             	mov    (%rax),%rax
  8004205585:	0f b7 40 18          	movzwl 0x18(%rax),%eax
  8004205589:	0f b7 c0             	movzwl %ax,%eax
  800420558c:	3b 45 fc             	cmp    -0x4(%rbp),%eax
  800420558f:	7e 46                	jle    80042055d7 <_dwarf_frame_regtable_copy+0x1b3>
             i < src->rt3_reg_table_size; i++)
  8004205591:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  8004205595:	0f b7 40 18          	movzwl 0x18(%rax),%eax
  8004205599:	0f b7 c0             	movzwl %ax,%eax
        }

        memcpy(&(*dest)->rt3_cfa_rule, &src->rt3_cfa_rule,
            sizeof(Dwarf_Regtable_Entry3));

        for (i = 0; i < (*dest)->rt3_reg_table_size &&
  800420559c:	3b 45 fc             	cmp    -0x4(%rbp),%eax
  800420559f:	7f 83                	jg     8004205524 <_dwarf_frame_regtable_copy+0x100>
             i < src->rt3_reg_table_size; i++)
                memcpy(&(*dest)->rt3_rules[i], &src->rt3_rules[i],
                    sizeof(Dwarf_Regtable_Entry3));

        for (; i < (*dest)->rt3_reg_table_size; i++)
  80042055a1:	eb 34                	jmp    80042055d7 <_dwarf_frame_regtable_copy+0x1b3>
                (*dest)->rt3_rules[i].dw_regnum =
  80042055a3:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  80042055a7:	48 8b 00             	mov    (%rax),%rax
  80042055aa:	48 8b 48 20          	mov    0x20(%rax),%rcx
  80042055ae:	8b 45 fc             	mov    -0x4(%rbp),%eax
  80042055b1:	48 63 d0             	movslq %eax,%rdx
  80042055b4:	48 89 d0             	mov    %rdx,%rax
  80042055b7:	48 01 c0             	add    %rax,%rax
  80042055ba:	48 01 d0             	add    %rdx,%rax
  80042055bd:	48 c1 e0 03          	shl    $0x3,%rax
  80042055c1:	48 8d 14 01          	lea    (%rcx,%rax,1),%rdx
                    dbg->dbg_frame_undefined_value;
  80042055c5:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  80042055c9:	0f b7 40 48          	movzwl 0x48(%rax),%eax
             i < src->rt3_reg_table_size; i++)
                memcpy(&(*dest)->rt3_rules[i], &src->rt3_rules[i],
                    sizeof(Dwarf_Regtable_Entry3));

        for (; i < (*dest)->rt3_reg_table_size; i++)
                (*dest)->rt3_rules[i].dw_regnum =
  80042055cd:	66 89 42 02          	mov    %ax,0x2(%rdx)
        for (i = 0; i < (*dest)->rt3_reg_table_size &&
             i < src->rt3_reg_table_size; i++)
                memcpy(&(*dest)->rt3_rules[i], &src->rt3_rules[i],
                    sizeof(Dwarf_Regtable_Entry3));

        for (; i < (*dest)->rt3_reg_table_size; i++)
  80042055d1:	83 45 fc 01          	addl   $0x1,-0x4(%rbp)
  80042055d5:	eb 01                	jmp    80042055d8 <_dwarf_frame_regtable_copy+0x1b4>
  80042055d7:	90                   	nop
  80042055d8:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  80042055dc:	48 8b 00             	mov    (%rax),%rax
  80042055df:	0f b7 40 18          	movzwl 0x18(%rax),%eax
  80042055e3:	0f b7 c0             	movzwl %ax,%eax
  80042055e6:	3b 45 fc             	cmp    -0x4(%rbp),%eax
  80042055e9:	7f b8                	jg     80042055a3 <_dwarf_frame_regtable_copy+0x17f>
                (*dest)->rt3_rules[i].dw_regnum =
                    dbg->dbg_frame_undefined_value;

        return (DW_DLE_NONE);
  80042055eb:	b8 00 00 00 00       	mov    $0x0,%eax
}
  80042055f0:	c9                   	leaveq 
  80042055f1:	c3                   	retq   

00000080042055f2 <_dwarf_frame_run_inst>:

static int
_dwarf_frame_run_inst(Dwarf_Debug dbg, Dwarf_Regtable3 *rt, uint8_t *insts,
    Dwarf_Unsigned len, Dwarf_Unsigned caf, Dwarf_Signed daf, Dwarf_Addr pc,
    Dwarf_Addr pc_req, Dwarf_Addr *row_pc, Dwarf_Error *error)
{
  80042055f2:	55                   	push   %rbp
  80042055f3:	48 89 e5             	mov    %rsp,%rbp
  80042055f6:	53                   	push   %rbx
  80042055f7:	48 81 ec 88 00 00 00 	sub    $0x88,%rsp
  80042055fe:	48 89 7d 98          	mov    %rdi,-0x68(%rbp)
  8004205602:	48 89 75 90          	mov    %rsi,-0x70(%rbp)
  8004205606:	48 89 55 88          	mov    %rdx,-0x78(%rbp)
  800420560a:	48 89 4d 80          	mov    %rcx,-0x80(%rbp)
  800420560e:	4c 89 85 78 ff ff ff 	mov    %r8,-0x88(%rbp)
  8004205615:	4c 89 8d 70 ff ff ff 	mov    %r9,-0x90(%rbp)

#ifdef FRAME_DEBUG
        printf("frame_run_inst: (caf=%ju, daf=%jd)\n", caf, daf);
#endif

        ret = DW_DLE_NONE;
  800420561c:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%rbp)
        init_rt = saved_rt = NULL;
  8004205623:	48 c7 45 a8 00 00 00 	movq   $0x0,-0x58(%rbp)
  800420562a:	00 
  800420562b:	48 8b 45 a8          	mov    -0x58(%rbp),%rax
  800420562f:	48 89 45 b0          	mov    %rax,-0x50(%rbp)
        *row_pc = pc;
  8004205633:	48 8b 45 20          	mov    0x20(%rbp),%rax
  8004205637:	48 8b 55 10          	mov    0x10(%rbp),%rdx
  800420563b:	48 89 10             	mov    %rdx,(%rax)

        /* Save a copy of the table as initial state. */
        _dwarf_frame_regtable_copy(dbg, &init_rt, rt, error);
  800420563e:	48 8b 55 90          	mov    -0x70(%rbp),%rdx
  8004205642:	48 8b 4d 28          	mov    0x28(%rbp),%rcx
  8004205646:	48 8d 75 b0          	lea    -0x50(%rbp),%rsi
  800420564a:	48 8b 45 98          	mov    -0x68(%rbp),%rax
  800420564e:	48 89 c7             	mov    %rax,%rdi
  8004205651:	48 b8 24 54 20 04 80 	movabs $0x8004205424,%rax
  8004205658:	00 00 00 
  800420565b:	ff d0                	callq  *%rax
        p = insts;
  800420565d:	48 8b 45 88          	mov    -0x78(%rbp),%rax
  8004205661:	48 89 45 a0          	mov    %rax,-0x60(%rbp)
        pe = p + len;
  8004205665:	48 8b 45 a0          	mov    -0x60(%rbp),%rax
  8004205669:	48 03 45 80          	add    -0x80(%rbp),%rax
  800420566d:	48 89 45 e0          	mov    %rax,-0x20(%rbp)

        while (p < pe) {
  8004205671:	e9 7c 0d 00 00       	jmpq   80042063f2 <_dwarf_frame_run_inst+0xe00>

#ifdef FRAME_DEBUG
                printf("p=%p pe=%p pc=%#jx pc_req=%#jx\n", p, pe, pc, pc_req);
#endif

                if (*p == DW_CFA_nop) {
  8004205676:	48 8b 45 a0          	mov    -0x60(%rbp),%rax
  800420567a:	0f b6 00             	movzbl (%rax),%eax
  800420567d:	84 c0                	test   %al,%al
  800420567f:	75 11                	jne    8004205692 <_dwarf_frame_run_inst+0xa0>
#ifdef FRAME_DEBUG
                        printf("DW_CFA_nop\n");
#endif
                        p++;
  8004205681:	48 8b 45 a0          	mov    -0x60(%rbp),%rax
  8004205685:	48 83 c0 01          	add    $0x1,%rax
  8004205689:	48 89 45 a0          	mov    %rax,-0x60(%rbp)
                        continue;
  800420568d:	e9 60 0d 00 00       	jmpq   80042063f2 <_dwarf_frame_run_inst+0xe00>
                }

                high2 = *p & 0xc0;
  8004205692:	48 8b 45 a0          	mov    -0x60(%rbp),%rax
  8004205696:	0f b6 00             	movzbl (%rax),%eax
  8004205699:	83 e0 c0             	and    $0xffffffc0,%eax
  800420569c:	88 45 df             	mov    %al,-0x21(%rbp)
                low6 = *p & 0x3f;
  800420569f:	48 8b 45 a0          	mov    -0x60(%rbp),%rax
  80042056a3:	0f b6 00             	movzbl (%rax),%eax
  80042056a6:	83 e0 3f             	and    $0x3f,%eax
  80042056a9:	88 45 de             	mov    %al,-0x22(%rbp)
                p++;
  80042056ac:	48 8b 45 a0          	mov    -0x60(%rbp),%rax
  80042056b0:	48 83 c0 01          	add    $0x1,%rax
  80042056b4:	48 89 45 a0          	mov    %rax,-0x60(%rbp)

                if (high2 > 0) {
  80042056b8:	80 7d df 00          	cmpb   $0x0,-0x21(%rbp)
  80042056bc:	0f 84 a1 01 00 00    	je     8004205863 <_dwarf_frame_run_inst+0x271>
                        switch (high2) {
  80042056c2:	0f b6 45 df          	movzbl -0x21(%rbp),%eax
  80042056c6:	3d 80 00 00 00       	cmp    $0x80,%eax
  80042056cb:	74 37                	je     8004205704 <_dwarf_frame_run_inst+0x112>
  80042056cd:	3d c0 00 00 00       	cmp    $0xc0,%eax
  80042056d2:	0f 84 00 01 00 00    	je     80042057d8 <_dwarf_frame_run_inst+0x1e6>
  80042056d8:	83 f8 40             	cmp    $0x40,%eax
  80042056db:	0f 85 70 01 00 00    	jne    8004205851 <_dwarf_frame_run_inst+0x25f>
                        case DW_CFA_advance_loc:
                                pc += low6 * caf;
  80042056e1:	0f b6 45 de          	movzbl -0x22(%rbp),%eax
  80042056e5:	48 0f af 85 78 ff ff 	imul   -0x88(%rbp),%rax
  80042056ec:	ff 
  80042056ed:	48 01 45 10          	add    %rax,0x10(%rbp)
#ifdef FRAME_DEBUG
                                printf("DW_CFA_advance_loc(%#jx(%u))\n", pc,
                                    low6);
#endif
                                if (pc_req < pc)
  80042056f1:	48 8b 45 18          	mov    0x18(%rbp),%rax
  80042056f5:	48 3b 45 10          	cmp    0x10(%rbp),%rax
  80042056f9:	0f 83 5e 01 00 00    	jae    800420585d <_dwarf_frame_run_inst+0x26b>
                                        goto program_done;
  80042056ff:	e9 ff 0c 00 00       	jmpq   8004206403 <_dwarf_frame_run_inst+0xe11>
                                break;
                        case DW_CFA_offset:
                                *row_pc = pc;
  8004205704:	48 8b 45 20          	mov    0x20(%rbp),%rax
  8004205708:	48 8b 55 10          	mov    0x10(%rbp),%rdx
  800420570c:	48 89 10             	mov    %rdx,(%rax)
                                CHECK_TABLE_SIZE(low6);
  800420570f:	0f b6 55 de          	movzbl -0x22(%rbp),%edx
  8004205713:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  8004205717:	0f b7 40 18          	movzwl 0x18(%rax),%eax
  800420571b:	66 39 c2             	cmp    %ax,%dx
  800420571e:	72 0c                	jb     800420572c <_dwarf_frame_run_inst+0x13a>
  8004205720:	c7 45 ec 18 00 00 00 	movl   $0x18,-0x14(%rbp)
  8004205727:	e9 d7 0c 00 00       	jmpq   8004206403 <_dwarf_frame_run_inst+0xe11>
                                RL[low6].dw_offset_relevant = 1;
  800420572c:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  8004205730:	48 8b 48 20          	mov    0x20(%rax),%rcx
  8004205734:	0f b6 55 de          	movzbl -0x22(%rbp),%edx
  8004205738:	48 89 d0             	mov    %rdx,%rax
  800420573b:	48 01 c0             	add    %rax,%rax
  800420573e:	48 01 d0             	add    %rdx,%rax
  8004205741:	48 c1 e0 03          	shl    $0x3,%rax
  8004205745:	48 01 c8             	add    %rcx,%rax
  8004205748:	c6 00 01             	movb   $0x1,(%rax)
                                RL[low6].dw_value_type = DW_EXPR_OFFSET;
  800420574b:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  800420574f:	48 8b 48 20          	mov    0x20(%rax),%rcx
  8004205753:	0f b6 55 de          	movzbl -0x22(%rbp),%edx
  8004205757:	48 89 d0             	mov    %rdx,%rax
  800420575a:	48 01 c0             	add    %rax,%rax
  800420575d:	48 01 d0             	add    %rdx,%rax
  8004205760:	48 c1 e0 03          	shl    $0x3,%rax
  8004205764:	48 01 c8             	add    %rcx,%rax
  8004205767:	c6 40 01 00          	movb   $0x0,0x1(%rax)
                                RL[low6].dw_regnum = dbg->dbg_frame_cfa_value;
  800420576b:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  800420576f:	48 8b 48 20          	mov    0x20(%rax),%rcx
  8004205773:	0f b6 55 de          	movzbl -0x22(%rbp),%edx
  8004205777:	48 89 d0             	mov    %rdx,%rax
  800420577a:	48 01 c0             	add    %rax,%rax
  800420577d:	48 01 d0             	add    %rdx,%rax
  8004205780:	48 c1 e0 03          	shl    $0x3,%rax
  8004205784:	48 8d 14 01          	lea    (%rcx,%rax,1),%rdx
  8004205788:	48 8b 45 98          	mov    -0x68(%rbp),%rax
  800420578c:	0f b7 40 44          	movzwl 0x44(%rax),%eax
  8004205790:	66 89 42 02          	mov    %ax,0x2(%rdx)
                                RL[low6].dw_offset_or_block_len =
  8004205794:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  8004205798:	48 8b 48 20          	mov    0x20(%rax),%rcx
  800420579c:	0f b6 55 de          	movzbl -0x22(%rbp),%edx
  80042057a0:	48 89 d0             	mov    %rdx,%rax
  80042057a3:	48 01 c0             	add    %rax,%rax
  80042057a6:	48 01 d0             	add    %rdx,%rax
  80042057a9:	48 c1 e0 03          	shl    $0x3,%rax
  80042057ad:	48 8d 1c 01          	lea    (%rcx,%rax,1),%rbx
                                    _dwarf_decode_uleb128(&p) * daf;
  80042057b1:	48 8d 45 a0          	lea    -0x60(%rbp),%rax
  80042057b5:	48 89 c7             	mov    %rax,%rdi
  80042057b8:	48 b8 82 3a 20 04 80 	movabs $0x8004203a82,%rax
  80042057bf:	00 00 00 
  80042057c2:	ff d0                	callq  *%rax
  80042057c4:	48 8b 95 70 ff ff ff 	mov    -0x90(%rbp),%rdx
  80042057cb:	48 0f af c2          	imul   %rdx,%rax
                                *row_pc = pc;
                                CHECK_TABLE_SIZE(low6);
                                RL[low6].dw_offset_relevant = 1;
                                RL[low6].dw_value_type = DW_EXPR_OFFSET;
                                RL[low6].dw_regnum = dbg->dbg_frame_cfa_value;
                                RL[low6].dw_offset_or_block_len =
  80042057cf:	48 89 43 08          	mov    %rax,0x8(%rbx)
                                    _dwarf_decode_uleb128(&p) * daf;
#ifdef FRAME_DEBUG
                                printf("DW_CFA_offset(%jd)\n",
                                    RL[low6].dw_offset_or_block_len);
#endif
                                break;
  80042057d3:	e9 86 00 00 00       	jmpq   800420585e <_dwarf_frame_run_inst+0x26c>
                        case DW_CFA_restore:
                                *row_pc = pc;
  80042057d8:	48 8b 45 20          	mov    0x20(%rbp),%rax
  80042057dc:	48 8b 55 10          	mov    0x10(%rbp),%rdx
  80042057e0:	48 89 10             	mov    %rdx,(%rax)
                                CHECK_TABLE_SIZE(low6);
  80042057e3:	0f b6 55 de          	movzbl -0x22(%rbp),%edx
  80042057e7:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  80042057eb:	0f b7 40 18          	movzwl 0x18(%rax),%eax
  80042057ef:	66 39 c2             	cmp    %ax,%dx
  80042057f2:	72 0c                	jb     8004205800 <_dwarf_frame_run_inst+0x20e>
  80042057f4:	c7 45 ec 18 00 00 00 	movl   $0x18,-0x14(%rbp)
  80042057fb:	e9 03 0c 00 00       	jmpq   8004206403 <_dwarf_frame_run_inst+0xe11>
                                memcpy(&RL[low6], &INITRL[low6],
  8004205800:	48 8b 45 b0          	mov    -0x50(%rbp),%rax
  8004205804:	48 8b 48 20          	mov    0x20(%rax),%rcx
  8004205808:	0f b6 55 de          	movzbl -0x22(%rbp),%edx
  800420580c:	48 89 d0             	mov    %rdx,%rax
  800420580f:	48 01 c0             	add    %rax,%rax
  8004205812:	48 01 d0             	add    %rdx,%rax
  8004205815:	48 c1 e0 03          	shl    $0x3,%rax
  8004205819:	48 01 c1             	add    %rax,%rcx
  800420581c:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  8004205820:	48 8b 70 20          	mov    0x20(%rax),%rsi
  8004205824:	0f b6 55 de          	movzbl -0x22(%rbp),%edx
  8004205828:	48 89 d0             	mov    %rdx,%rax
  800420582b:	48 01 c0             	add    %rax,%rax
  800420582e:	48 01 d0             	add    %rdx,%rax
  8004205831:	48 c1 e0 03          	shl    $0x3,%rax
  8004205835:	48 01 f0             	add    %rsi,%rax
  8004205838:	ba 18 00 00 00       	mov    $0x18,%edx
  800420583d:	48 89 ce             	mov    %rcx,%rsi
  8004205840:	48 89 c7             	mov    %rax,%rdi
  8004205843:	48 b8 fd 2f 20 04 80 	movabs $0x8004202ffd,%rax
  800420584a:	00 00 00 
  800420584d:	ff d0                	callq  *%rax
                                    sizeof(Dwarf_Regtable_Entry3));
#ifdef FRAME_DEBUG
                                printf("DW_CFA_restore(%u)\n", low6);
#endif
                                break;
  800420584f:	eb 0d                	jmp    800420585e <_dwarf_frame_run_inst+0x26c>
                        default:
                                DWARF_SET_ERROR(dbg, error,
                                    DW_DLE_FRAME_INSTR_EXEC_ERROR);
                                ret = DW_DLE_FRAME_INSTR_EXEC_ERROR;
  8004205851:	c7 45 ec 15 00 00 00 	movl   $0x15,-0x14(%rbp)
                                goto program_done;
  8004205858:	e9 a6 0b 00 00       	jmpq   8004206403 <_dwarf_frame_run_inst+0xe11>
                                printf("DW_CFA_advance_loc(%#jx(%u))\n", pc,
                                    low6);
#endif
                                if (pc_req < pc)
                                        goto program_done;
                                break;
  800420585d:	90                   	nop
                                    DW_DLE_FRAME_INSTR_EXEC_ERROR);
                                ret = DW_DLE_FRAME_INSTR_EXEC_ERROR;
                                goto program_done;
                        }

                        continue;
  800420585e:	e9 8f 0b 00 00       	jmpq   80042063f2 <_dwarf_frame_run_inst+0xe00>
                }

                switch (low6) {
  8004205863:	0f b6 45 de          	movzbl -0x22(%rbp),%eax
  8004205867:	83 f8 16             	cmp    $0x16,%eax
  800420586a:	0f 87 72 0b 00 00    	ja     80042063e2 <_dwarf_frame_run_inst+0xdf0>
  8004205870:	89 c0                	mov    %eax,%eax
  8004205872:	48 8d 14 c5 00 00 00 	lea    0x0(,%rax,8),%rdx
  8004205879:	00 
  800420587a:	48 b8 d8 9f 20 04 80 	movabs $0x8004209fd8,%rax
  8004205881:	00 00 00 
  8004205884:	48 01 d0             	add    %rdx,%rax
  8004205887:	48 8b 00             	mov    (%rax),%rax
  800420588a:	ff e0                	jmpq   *%rax
                case DW_CFA_set_loc:
			printf("dbg pointersize :%x\n",dbg->dbg_pointer_size);
  800420588c:	48 8b 45 98          	mov    -0x68(%rbp),%rax
  8004205890:	8b 40 28             	mov    0x28(%rax),%eax
  8004205893:	89 c6                	mov    %eax,%esi
  8004205895:	48 bf ae 9f 20 04 80 	movabs $0x8004209fae,%rdi
  800420589c:	00 00 00 
  800420589f:	b8 00 00 00 00       	mov    $0x0,%eax
  80042058a4:	48 ba 22 16 20 04 80 	movabs $0x8004201622,%rdx
  80042058ab:	00 00 00 
  80042058ae:	ff d2                	callq  *%rdx
                        pc = dbg->decode(&p, dbg->dbg_pointer_size);
  80042058b0:	48 8b 45 98          	mov    -0x68(%rbp),%rax
  80042058b4:	48 8b 48 20          	mov    0x20(%rax),%rcx
  80042058b8:	48 8b 45 98          	mov    -0x68(%rbp),%rax
  80042058bc:	8b 50 28             	mov    0x28(%rax),%edx
  80042058bf:	48 8d 45 a0          	lea    -0x60(%rbp),%rax
  80042058c3:	89 d6                	mov    %edx,%esi
  80042058c5:	48 89 c7             	mov    %rax,%rdi
  80042058c8:	ff d1                	callq  *%rcx
  80042058ca:	48 89 45 10          	mov    %rax,0x10(%rbp)
#ifdef FRAME_DEBUG
                        printf("DW_CFA_set_loc(pc=%#jx)\n", pc);
#endif
                        if (pc_req < pc)
  80042058ce:	48 8b 45 18          	mov    0x18(%rbp),%rax
  80042058d2:	48 3b 45 10          	cmp    0x10(%rbp),%rax
  80042058d6:	0f 83 26 0b 00 00    	jae    8004206402 <_dwarf_frame_run_inst+0xe10>
				printf("Program done\n");
  80042058dc:	48 bf c3 9f 20 04 80 	movabs $0x8004209fc3,%rdi
  80042058e3:	00 00 00 
  80042058e6:	b8 00 00 00 00       	mov    $0x0,%eax
  80042058eb:	48 ba 22 16 20 04 80 	movabs $0x8004201622,%rdx
  80042058f2:	00 00 00 
  80042058f5:	ff d2                	callq  *%rdx
                                goto program_done;
  80042058f7:	e9 06 0b 00 00       	jmpq   8004206402 <_dwarf_frame_run_inst+0xe10>
                        break;
                case DW_CFA_advance_loc1:
                        pc += dbg->decode(&p, 1) * caf;
  80042058fc:	48 8b 45 98          	mov    -0x68(%rbp),%rax
  8004205900:	48 8b 50 20          	mov    0x20(%rax),%rdx
  8004205904:	48 8d 45 a0          	lea    -0x60(%rbp),%rax
  8004205908:	be 01 00 00 00       	mov    $0x1,%esi
  800420590d:	48 89 c7             	mov    %rax,%rdi
  8004205910:	ff d2                	callq  *%rdx
  8004205912:	48 0f af 85 78 ff ff 	imul   -0x88(%rbp),%rax
  8004205919:	ff 
  800420591a:	48 01 45 10          	add    %rax,0x10(%rbp)
#ifdef FRAME_DEBUG
                        printf("DW_CFA_set_loc1(pc=%#jx)\n", pc);
#endif
                        if (pc_req < pc)
  800420591e:	48 8b 45 18          	mov    0x18(%rbp),%rax
  8004205922:	48 3b 45 10          	cmp    0x10(%rbp),%rax
  8004205926:	0f 83 bf 0a 00 00    	jae    80042063eb <_dwarf_frame_run_inst+0xdf9>
                                goto program_done;
  800420592c:	e9 d2 0a 00 00       	jmpq   8004206403 <_dwarf_frame_run_inst+0xe11>
                        break;
                case DW_CFA_advance_loc2:
                        pc += dbg->decode(&p, 2) * caf;
  8004205931:	48 8b 45 98          	mov    -0x68(%rbp),%rax
  8004205935:	48 8b 50 20          	mov    0x20(%rax),%rdx
  8004205939:	48 8d 45 a0          	lea    -0x60(%rbp),%rax
  800420593d:	be 02 00 00 00       	mov    $0x2,%esi
  8004205942:	48 89 c7             	mov    %rax,%rdi
  8004205945:	ff d2                	callq  *%rdx
  8004205947:	48 0f af 85 78 ff ff 	imul   -0x88(%rbp),%rax
  800420594e:	ff 
  800420594f:	48 01 45 10          	add    %rax,0x10(%rbp)
#ifdef FRAME_DEBUG
                        printf("DW_CFA_set_loc2(pc=%#jx)\n", pc);
#endif
                        if (pc_req < pc)
  8004205953:	48 8b 45 18          	mov    0x18(%rbp),%rax
  8004205957:	48 3b 45 10          	cmp    0x10(%rbp),%rax
  800420595b:	0f 83 8d 0a 00 00    	jae    80042063ee <_dwarf_frame_run_inst+0xdfc>
                                goto program_done;
  8004205961:	e9 9d 0a 00 00       	jmpq   8004206403 <_dwarf_frame_run_inst+0xe11>
                        break;
                case DW_CFA_advance_loc4:
                        pc += dbg->decode(&p, 4) * caf;
  8004205966:	48 8b 45 98          	mov    -0x68(%rbp),%rax
  800420596a:	48 8b 50 20          	mov    0x20(%rax),%rdx
  800420596e:	48 8d 45 a0          	lea    -0x60(%rbp),%rax
  8004205972:	be 04 00 00 00       	mov    $0x4,%esi
  8004205977:	48 89 c7             	mov    %rax,%rdi
  800420597a:	ff d2                	callq  *%rdx
  800420597c:	48 0f af 85 78 ff ff 	imul   -0x88(%rbp),%rax
  8004205983:	ff 
  8004205984:	48 01 45 10          	add    %rax,0x10(%rbp)
#ifdef FRAME_DEBUG
                        printf("DW_CFA_set_loc4(pc=%#jx)\n", pc);
#endif
                        if (pc_req < pc)
  8004205988:	48 8b 45 18          	mov    0x18(%rbp),%rax
  800420598c:	48 3b 45 10          	cmp    0x10(%rbp),%rax
  8004205990:	0f 83 5b 0a 00 00    	jae    80042063f1 <_dwarf_frame_run_inst+0xdff>
                                goto program_done;
  8004205996:	e9 68 0a 00 00       	jmpq   8004206403 <_dwarf_frame_run_inst+0xe11>
                        break;
                case DW_CFA_offset_extended:
                        *row_pc = pc;
  800420599b:	48 8b 45 20          	mov    0x20(%rbp),%rax
  800420599f:	48 8b 55 10          	mov    0x10(%rbp),%rdx
  80042059a3:	48 89 10             	mov    %rdx,(%rax)
                        reg = _dwarf_decode_uleb128(&p);
  80042059a6:	48 8d 45 a0          	lea    -0x60(%rbp),%rax
  80042059aa:	48 89 c7             	mov    %rax,%rdi
  80042059ad:	48 b8 82 3a 20 04 80 	movabs $0x8004203a82,%rax
  80042059b4:	00 00 00 
  80042059b7:	ff d0                	callq  *%rax
  80042059b9:	48 89 45 d0          	mov    %rax,-0x30(%rbp)
                        uoff = _dwarf_decode_uleb128(&p);
  80042059bd:	48 8d 45 a0          	lea    -0x60(%rbp),%rax
  80042059c1:	48 89 c7             	mov    %rax,%rdi
  80042059c4:	48 b8 82 3a 20 04 80 	movabs $0x8004203a82,%rax
  80042059cb:	00 00 00 
  80042059ce:	ff d0                	callq  *%rax
  80042059d0:	48 89 45 c8          	mov    %rax,-0x38(%rbp)
                        CHECK_TABLE_SIZE(reg);
  80042059d4:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  80042059d8:	0f b7 40 18          	movzwl 0x18(%rax),%eax
  80042059dc:	0f b7 c0             	movzwl %ax,%eax
  80042059df:	48 3b 45 d0          	cmp    -0x30(%rbp),%rax
  80042059e3:	77 0c                	ja     80042059f1 <_dwarf_frame_run_inst+0x3ff>
  80042059e5:	c7 45 ec 18 00 00 00 	movl   $0x18,-0x14(%rbp)
  80042059ec:	e9 12 0a 00 00       	jmpq   8004206403 <_dwarf_frame_run_inst+0xe11>
                        RL[reg].dw_offset_relevant = 1;
  80042059f1:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  80042059f5:	48 8b 48 20          	mov    0x20(%rax),%rcx
  80042059f9:	48 8b 55 d0          	mov    -0x30(%rbp),%rdx
  80042059fd:	48 89 d0             	mov    %rdx,%rax
  8004205a00:	48 01 c0             	add    %rax,%rax
  8004205a03:	48 01 d0             	add    %rdx,%rax
  8004205a06:	48 c1 e0 03          	shl    $0x3,%rax
  8004205a0a:	48 01 c8             	add    %rcx,%rax
  8004205a0d:	c6 00 01             	movb   $0x1,(%rax)
                        RL[reg].dw_value_type = DW_EXPR_OFFSET;
  8004205a10:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  8004205a14:	48 8b 48 20          	mov    0x20(%rax),%rcx
  8004205a18:	48 8b 55 d0          	mov    -0x30(%rbp),%rdx
  8004205a1c:	48 89 d0             	mov    %rdx,%rax
  8004205a1f:	48 01 c0             	add    %rax,%rax
  8004205a22:	48 01 d0             	add    %rdx,%rax
  8004205a25:	48 c1 e0 03          	shl    $0x3,%rax
  8004205a29:	48 01 c8             	add    %rcx,%rax
  8004205a2c:	c6 40 01 00          	movb   $0x0,0x1(%rax)
                        RL[reg].dw_regnum = dbg->dbg_frame_cfa_value;
  8004205a30:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  8004205a34:	48 8b 48 20          	mov    0x20(%rax),%rcx
  8004205a38:	48 8b 55 d0          	mov    -0x30(%rbp),%rdx
  8004205a3c:	48 89 d0             	mov    %rdx,%rax
  8004205a3f:	48 01 c0             	add    %rax,%rax
  8004205a42:	48 01 d0             	add    %rdx,%rax
  8004205a45:	48 c1 e0 03          	shl    $0x3,%rax
  8004205a49:	48 8d 14 01          	lea    (%rcx,%rax,1),%rdx
  8004205a4d:	48 8b 45 98          	mov    -0x68(%rbp),%rax
  8004205a51:	0f b7 40 44          	movzwl 0x44(%rax),%eax
  8004205a55:	66 89 42 02          	mov    %ax,0x2(%rdx)
                        RL[reg].dw_offset_or_block_len = uoff * daf;
  8004205a59:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  8004205a5d:	48 8b 48 20          	mov    0x20(%rax),%rcx
  8004205a61:	48 8b 55 d0          	mov    -0x30(%rbp),%rdx
  8004205a65:	48 89 d0             	mov    %rdx,%rax
  8004205a68:	48 01 c0             	add    %rax,%rax
  8004205a6b:	48 01 d0             	add    %rdx,%rax
  8004205a6e:	48 c1 e0 03          	shl    $0x3,%rax
  8004205a72:	48 8d 14 01          	lea    (%rcx,%rax,1),%rdx
  8004205a76:	48 8b 85 70 ff ff ff 	mov    -0x90(%rbp),%rax
  8004205a7d:	48 0f af 45 c8       	imul   -0x38(%rbp),%rax
  8004205a82:	48 89 42 08          	mov    %rax,0x8(%rdx)
#ifdef FRAME_DEBUG
                        printf("DW_CFA_offset_extended(reg=%ju,uoff=%ju)\n",
                            reg, uoff);
#endif
                        break;
  8004205a86:	e9 67 09 00 00       	jmpq   80042063f2 <_dwarf_frame_run_inst+0xe00>
                case DW_CFA_restore_extended:
                        *row_pc = pc;
  8004205a8b:	48 8b 45 20          	mov    0x20(%rbp),%rax
  8004205a8f:	48 8b 55 10          	mov    0x10(%rbp),%rdx
  8004205a93:	48 89 10             	mov    %rdx,(%rax)
                        reg = _dwarf_decode_uleb128(&p);
  8004205a96:	48 8d 45 a0          	lea    -0x60(%rbp),%rax
  8004205a9a:	48 89 c7             	mov    %rax,%rdi
  8004205a9d:	48 b8 82 3a 20 04 80 	movabs $0x8004203a82,%rax
  8004205aa4:	00 00 00 
  8004205aa7:	ff d0                	callq  *%rax
  8004205aa9:	48 89 45 d0          	mov    %rax,-0x30(%rbp)
                        CHECK_TABLE_SIZE(reg);
  8004205aad:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  8004205ab1:	0f b7 40 18          	movzwl 0x18(%rax),%eax
  8004205ab5:	0f b7 c0             	movzwl %ax,%eax
  8004205ab8:	48 3b 45 d0          	cmp    -0x30(%rbp),%rax
  8004205abc:	77 0c                	ja     8004205aca <_dwarf_frame_run_inst+0x4d8>
  8004205abe:	c7 45 ec 18 00 00 00 	movl   $0x18,-0x14(%rbp)
  8004205ac5:	e9 39 09 00 00       	jmpq   8004206403 <_dwarf_frame_run_inst+0xe11>
                        memcpy(&RL[reg], &INITRL[reg],
  8004205aca:	48 8b 45 b0          	mov    -0x50(%rbp),%rax
  8004205ace:	48 8b 48 20          	mov    0x20(%rax),%rcx
  8004205ad2:	48 8b 55 d0          	mov    -0x30(%rbp),%rdx
  8004205ad6:	48 89 d0             	mov    %rdx,%rax
  8004205ad9:	48 01 c0             	add    %rax,%rax
  8004205adc:	48 01 d0             	add    %rdx,%rax
  8004205adf:	48 c1 e0 03          	shl    $0x3,%rax
  8004205ae3:	48 01 c1             	add    %rax,%rcx
  8004205ae6:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  8004205aea:	48 8b 70 20          	mov    0x20(%rax),%rsi
  8004205aee:	48 8b 55 d0          	mov    -0x30(%rbp),%rdx
  8004205af2:	48 89 d0             	mov    %rdx,%rax
  8004205af5:	48 01 c0             	add    %rax,%rax
  8004205af8:	48 01 d0             	add    %rdx,%rax
  8004205afb:	48 c1 e0 03          	shl    $0x3,%rax
  8004205aff:	48 01 f0             	add    %rsi,%rax
  8004205b02:	ba 18 00 00 00       	mov    $0x18,%edx
  8004205b07:	48 89 ce             	mov    %rcx,%rsi
  8004205b0a:	48 89 c7             	mov    %rax,%rdi
  8004205b0d:	48 b8 fd 2f 20 04 80 	movabs $0x8004202ffd,%rax
  8004205b14:	00 00 00 
  8004205b17:	ff d0                	callq  *%rax
                            sizeof(Dwarf_Regtable_Entry3));
#ifdef FRAME_DEBUG
                        printf("DW_CFA_restore_extended(%ju)\n", reg);
#endif
                        break;
  8004205b19:	e9 d4 08 00 00       	jmpq   80042063f2 <_dwarf_frame_run_inst+0xe00>
                case DW_CFA_undefined:
                        *row_pc = pc;
  8004205b1e:	48 8b 45 20          	mov    0x20(%rbp),%rax
  8004205b22:	48 8b 55 10          	mov    0x10(%rbp),%rdx
  8004205b26:	48 89 10             	mov    %rdx,(%rax)
                        reg = _dwarf_decode_uleb128(&p);
  8004205b29:	48 8d 45 a0          	lea    -0x60(%rbp),%rax
  8004205b2d:	48 89 c7             	mov    %rax,%rdi
  8004205b30:	48 b8 82 3a 20 04 80 	movabs $0x8004203a82,%rax
  8004205b37:	00 00 00 
  8004205b3a:	ff d0                	callq  *%rax
  8004205b3c:	48 89 45 d0          	mov    %rax,-0x30(%rbp)
                        CHECK_TABLE_SIZE(reg);
  8004205b40:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  8004205b44:	0f b7 40 18          	movzwl 0x18(%rax),%eax
  8004205b48:	0f b7 c0             	movzwl %ax,%eax
  8004205b4b:	48 3b 45 d0          	cmp    -0x30(%rbp),%rax
  8004205b4f:	77 0c                	ja     8004205b5d <_dwarf_frame_run_inst+0x56b>
  8004205b51:	c7 45 ec 18 00 00 00 	movl   $0x18,-0x14(%rbp)
  8004205b58:	e9 a6 08 00 00       	jmpq   8004206403 <_dwarf_frame_run_inst+0xe11>
                        RL[reg].dw_offset_relevant = 0;
  8004205b5d:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  8004205b61:	48 8b 48 20          	mov    0x20(%rax),%rcx
  8004205b65:	48 8b 55 d0          	mov    -0x30(%rbp),%rdx
  8004205b69:	48 89 d0             	mov    %rdx,%rax
  8004205b6c:	48 01 c0             	add    %rax,%rax
  8004205b6f:	48 01 d0             	add    %rdx,%rax
  8004205b72:	48 c1 e0 03          	shl    $0x3,%rax
  8004205b76:	48 01 c8             	add    %rcx,%rax
  8004205b79:	c6 00 00             	movb   $0x0,(%rax)
                        RL[reg].dw_regnum = dbg->dbg_frame_undefined_value;
  8004205b7c:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  8004205b80:	48 8b 48 20          	mov    0x20(%rax),%rcx
  8004205b84:	48 8b 55 d0          	mov    -0x30(%rbp),%rdx
  8004205b88:	48 89 d0             	mov    %rdx,%rax
  8004205b8b:	48 01 c0             	add    %rax,%rax
  8004205b8e:	48 01 d0             	add    %rdx,%rax
  8004205b91:	48 c1 e0 03          	shl    $0x3,%rax
  8004205b95:	48 8d 14 01          	lea    (%rcx,%rax,1),%rdx
  8004205b99:	48 8b 45 98          	mov    -0x68(%rbp),%rax
  8004205b9d:	0f b7 40 48          	movzwl 0x48(%rax),%eax
  8004205ba1:	66 89 42 02          	mov    %ax,0x2(%rdx)
#ifdef FRAME_DEBUG
                        printf("DW_CFA_undefined(%ju)\n", reg);
#endif
                        break;
  8004205ba5:	e9 48 08 00 00       	jmpq   80042063f2 <_dwarf_frame_run_inst+0xe00>
                case DW_CFA_same_value:
                        reg = _dwarf_decode_uleb128(&p);
  8004205baa:	48 8d 45 a0          	lea    -0x60(%rbp),%rax
  8004205bae:	48 89 c7             	mov    %rax,%rdi
  8004205bb1:	48 b8 82 3a 20 04 80 	movabs $0x8004203a82,%rax
  8004205bb8:	00 00 00 
  8004205bbb:	ff d0                	callq  *%rax
  8004205bbd:	48 89 45 d0          	mov    %rax,-0x30(%rbp)
                        CHECK_TABLE_SIZE(reg);
  8004205bc1:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  8004205bc5:	0f b7 40 18          	movzwl 0x18(%rax),%eax
  8004205bc9:	0f b7 c0             	movzwl %ax,%eax
  8004205bcc:	48 3b 45 d0          	cmp    -0x30(%rbp),%rax
  8004205bd0:	77 0c                	ja     8004205bde <_dwarf_frame_run_inst+0x5ec>
  8004205bd2:	c7 45 ec 18 00 00 00 	movl   $0x18,-0x14(%rbp)
  8004205bd9:	e9 25 08 00 00       	jmpq   8004206403 <_dwarf_frame_run_inst+0xe11>
                        RL[reg].dw_offset_relevant = 0;
  8004205bde:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  8004205be2:	48 8b 48 20          	mov    0x20(%rax),%rcx
  8004205be6:	48 8b 55 d0          	mov    -0x30(%rbp),%rdx
  8004205bea:	48 89 d0             	mov    %rdx,%rax
  8004205bed:	48 01 c0             	add    %rax,%rax
  8004205bf0:	48 01 d0             	add    %rdx,%rax
  8004205bf3:	48 c1 e0 03          	shl    $0x3,%rax
  8004205bf7:	48 01 c8             	add    %rcx,%rax
  8004205bfa:	c6 00 00             	movb   $0x0,(%rax)
                        RL[reg].dw_regnum = dbg->dbg_frame_same_value;
  8004205bfd:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  8004205c01:	48 8b 48 20          	mov    0x20(%rax),%rcx
  8004205c05:	48 8b 55 d0          	mov    -0x30(%rbp),%rdx
  8004205c09:	48 89 d0             	mov    %rdx,%rax
  8004205c0c:	48 01 c0             	add    %rax,%rax
  8004205c0f:	48 01 d0             	add    %rdx,%rax
  8004205c12:	48 c1 e0 03          	shl    $0x3,%rax
  8004205c16:	48 8d 14 01          	lea    (%rcx,%rax,1),%rdx
  8004205c1a:	48 8b 45 98          	mov    -0x68(%rbp),%rax
  8004205c1e:	0f b7 40 46          	movzwl 0x46(%rax),%eax
  8004205c22:	66 89 42 02          	mov    %ax,0x2(%rdx)
#ifdef FRAME_DEBUG
                        printf("DW_CFA_same_value(%ju)\n", reg);
#endif
                        break;
  8004205c26:	e9 c7 07 00 00       	jmpq   80042063f2 <_dwarf_frame_run_inst+0xe00>
                case DW_CFA_register:
                        *row_pc = pc;
  8004205c2b:	48 8b 45 20          	mov    0x20(%rbp),%rax
  8004205c2f:	48 8b 55 10          	mov    0x10(%rbp),%rdx
  8004205c33:	48 89 10             	mov    %rdx,(%rax)
                        reg = _dwarf_decode_uleb128(&p);
  8004205c36:	48 8d 45 a0          	lea    -0x60(%rbp),%rax
  8004205c3a:	48 89 c7             	mov    %rax,%rdi
  8004205c3d:	48 b8 82 3a 20 04 80 	movabs $0x8004203a82,%rax
  8004205c44:	00 00 00 
  8004205c47:	ff d0                	callq  *%rax
  8004205c49:	48 89 45 d0          	mov    %rax,-0x30(%rbp)
                        reg2 = _dwarf_decode_uleb128(&p);
  8004205c4d:	48 8d 45 a0          	lea    -0x60(%rbp),%rax
  8004205c51:	48 89 c7             	mov    %rax,%rdi
  8004205c54:	48 b8 82 3a 20 04 80 	movabs $0x8004203a82,%rax
  8004205c5b:	00 00 00 
  8004205c5e:	ff d0                	callq  *%rax
  8004205c60:	48 89 45 c0          	mov    %rax,-0x40(%rbp)
                        CHECK_TABLE_SIZE(reg);
  8004205c64:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  8004205c68:	0f b7 40 18          	movzwl 0x18(%rax),%eax
  8004205c6c:	0f b7 c0             	movzwl %ax,%eax
  8004205c6f:	48 3b 45 d0          	cmp    -0x30(%rbp),%rax
  8004205c73:	77 0c                	ja     8004205c81 <_dwarf_frame_run_inst+0x68f>
  8004205c75:	c7 45 ec 18 00 00 00 	movl   $0x18,-0x14(%rbp)
  8004205c7c:	e9 82 07 00 00       	jmpq   8004206403 <_dwarf_frame_run_inst+0xe11>
                        RL[reg].dw_offset_relevant = 0;
  8004205c81:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  8004205c85:	48 8b 48 20          	mov    0x20(%rax),%rcx
  8004205c89:	48 8b 55 d0          	mov    -0x30(%rbp),%rdx
  8004205c8d:	48 89 d0             	mov    %rdx,%rax
  8004205c90:	48 01 c0             	add    %rax,%rax
  8004205c93:	48 01 d0             	add    %rdx,%rax
  8004205c96:	48 c1 e0 03          	shl    $0x3,%rax
  8004205c9a:	48 01 c8             	add    %rcx,%rax
  8004205c9d:	c6 00 00             	movb   $0x0,(%rax)
                        RL[reg].dw_regnum = reg2;
  8004205ca0:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  8004205ca4:	48 8b 48 20          	mov    0x20(%rax),%rcx
  8004205ca8:	48 8b 55 d0          	mov    -0x30(%rbp),%rdx
  8004205cac:	48 89 d0             	mov    %rdx,%rax
  8004205caf:	48 01 c0             	add    %rax,%rax
  8004205cb2:	48 01 d0             	add    %rdx,%rax
  8004205cb5:	48 c1 e0 03          	shl    $0x3,%rax
  8004205cb9:	48 8d 14 01          	lea    (%rcx,%rax,1),%rdx
  8004205cbd:	48 8b 45 c0          	mov    -0x40(%rbp),%rax
  8004205cc1:	66 89 42 02          	mov    %ax,0x2(%rdx)
#ifdef FRAME_DEBUG
                        printf("DW_CFA_register(reg=%ju,reg2=%ju)\n", reg,
                            reg2);
#endif
                        break;
  8004205cc5:	e9 28 07 00 00       	jmpq   80042063f2 <_dwarf_frame_run_inst+0xe00>
                case DW_CFA_remember_state:
                        _dwarf_frame_regtable_copy(dbg, &saved_rt, rt, error);
  8004205cca:	48 8b 55 90          	mov    -0x70(%rbp),%rdx
  8004205cce:	48 8b 4d 28          	mov    0x28(%rbp),%rcx
  8004205cd2:	48 8d 75 a8          	lea    -0x58(%rbp),%rsi
  8004205cd6:	48 8b 45 98          	mov    -0x68(%rbp),%rax
  8004205cda:	48 89 c7             	mov    %rax,%rdi
  8004205cdd:	48 b8 24 54 20 04 80 	movabs $0x8004205424,%rax
  8004205ce4:	00 00 00 
  8004205ce7:	ff d0                	callq  *%rax
#ifdef FRAME_DEBUG
                        printf("DW_CFA_remember_state\n");
#endif
                        break;
  8004205ce9:	e9 04 07 00 00       	jmpq   80042063f2 <_dwarf_frame_run_inst+0xe00>
                case DW_CFA_restore_state:
                        *row_pc = pc;
  8004205cee:	48 8b 45 20          	mov    0x20(%rbp),%rax
  8004205cf2:	48 8b 55 10          	mov    0x10(%rbp),%rdx
  8004205cf6:	48 89 10             	mov    %rdx,(%rax)
                        _dwarf_frame_regtable_copy(dbg, &rt, saved_rt, error);
  8004205cf9:	48 8b 55 a8          	mov    -0x58(%rbp),%rdx
  8004205cfd:	48 8b 4d 28          	mov    0x28(%rbp),%rcx
  8004205d01:	48 8d 75 90          	lea    -0x70(%rbp),%rsi
  8004205d05:	48 8b 45 98          	mov    -0x68(%rbp),%rax
  8004205d09:	48 89 c7             	mov    %rax,%rdi
  8004205d0c:	48 b8 24 54 20 04 80 	movabs $0x8004205424,%rax
  8004205d13:	00 00 00 
  8004205d16:	ff d0                	callq  *%rax
#ifdef FRAME_DEBUG
                        printf("DW_CFA_restore_state\n");
#endif
                        break;
  8004205d18:	e9 d5 06 00 00       	jmpq   80042063f2 <_dwarf_frame_run_inst+0xe00>
                case DW_CFA_def_cfa:
                        *row_pc = pc;
  8004205d1d:	48 8b 45 20          	mov    0x20(%rbp),%rax
  8004205d21:	48 8b 55 10          	mov    0x10(%rbp),%rdx
  8004205d25:	48 89 10             	mov    %rdx,(%rax)
                        reg = _dwarf_decode_uleb128(&p);
  8004205d28:	48 8d 45 a0          	lea    -0x60(%rbp),%rax
  8004205d2c:	48 89 c7             	mov    %rax,%rdi
  8004205d2f:	48 b8 82 3a 20 04 80 	movabs $0x8004203a82,%rax
  8004205d36:	00 00 00 
  8004205d39:	ff d0                	callq  *%rax
  8004205d3b:	48 89 45 d0          	mov    %rax,-0x30(%rbp)
                        uoff = _dwarf_decode_uleb128(&p);
  8004205d3f:	48 8d 45 a0          	lea    -0x60(%rbp),%rax
  8004205d43:	48 89 c7             	mov    %rax,%rdi
  8004205d46:	48 b8 82 3a 20 04 80 	movabs $0x8004203a82,%rax
  8004205d4d:	00 00 00 
  8004205d50:	ff d0                	callq  *%rax
  8004205d52:	48 89 45 c8          	mov    %rax,-0x38(%rbp)
                        CFA.dw_offset_relevant = 1;
  8004205d56:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  8004205d5a:	c6 00 01             	movb   $0x1,(%rax)
                        CFA.dw_value_type = DW_EXPR_OFFSET;
  8004205d5d:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  8004205d61:	c6 40 01 00          	movb   $0x0,0x1(%rax)
                        CFA.dw_regnum = reg;
  8004205d65:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  8004205d69:	48 8b 55 d0          	mov    -0x30(%rbp),%rdx
  8004205d6d:	66 89 50 02          	mov    %dx,0x2(%rax)
                        CFA.dw_offset_or_block_len = uoff;
  8004205d71:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  8004205d75:	48 8b 55 c8          	mov    -0x38(%rbp),%rdx
  8004205d79:	48 89 50 08          	mov    %rdx,0x8(%rax)
#ifdef FRAME_DEBUG
                        printf("DW_CFA_def_cfa(reg=%ju,uoff=%ju)\n", reg, uoff);
#endif
                        break;
  8004205d7d:	e9 70 06 00 00       	jmpq   80042063f2 <_dwarf_frame_run_inst+0xe00>
                case DW_CFA_def_cfa_register:
                        *row_pc = pc;
  8004205d82:	48 8b 45 20          	mov    0x20(%rbp),%rax
  8004205d86:	48 8b 55 10          	mov    0x10(%rbp),%rdx
  8004205d8a:	48 89 10             	mov    %rdx,(%rax)
                        reg = _dwarf_decode_uleb128(&p);
  8004205d8d:	48 8d 45 a0          	lea    -0x60(%rbp),%rax
  8004205d91:	48 89 c7             	mov    %rax,%rdi
  8004205d94:	48 b8 82 3a 20 04 80 	movabs $0x8004203a82,%rax
  8004205d9b:	00 00 00 
  8004205d9e:	ff d0                	callq  *%rax
  8004205da0:	48 89 45 d0          	mov    %rax,-0x30(%rbp)
                        CFA.dw_regnum = reg;
  8004205da4:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  8004205da8:	48 8b 55 d0          	mov    -0x30(%rbp),%rdx
  8004205dac:	66 89 50 02          	mov    %dx,0x2(%rax)
                         * here.
                         */
#ifdef FRAME_DEBUG
                        printf("DW_CFA_def_cfa_register(%ju)\n", reg);
#endif
                        break;
  8004205db0:	e9 3d 06 00 00       	jmpq   80042063f2 <_dwarf_frame_run_inst+0xe00>
                case DW_CFA_def_cfa_offset:
                        *row_pc = pc;
  8004205db5:	48 8b 45 20          	mov    0x20(%rbp),%rax
  8004205db9:	48 8b 55 10          	mov    0x10(%rbp),%rdx
  8004205dbd:	48 89 10             	mov    %rdx,(%rax)
                        uoff = _dwarf_decode_uleb128(&p);
  8004205dc0:	48 8d 45 a0          	lea    -0x60(%rbp),%rax
  8004205dc4:	48 89 c7             	mov    %rax,%rdi
  8004205dc7:	48 b8 82 3a 20 04 80 	movabs $0x8004203a82,%rax
  8004205dce:	00 00 00 
  8004205dd1:	ff d0                	callq  *%rax
  8004205dd3:	48 89 45 c8          	mov    %rax,-0x38(%rbp)
                        CFA.dw_offset_relevant = 1;
  8004205dd7:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  8004205ddb:	c6 00 01             	movb   $0x1,(%rax)
                        CFA.dw_value_type = DW_EXPR_OFFSET;
  8004205dde:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  8004205de2:	c6 40 01 00          	movb   $0x0,0x1(%rax)
                        CFA.dw_offset_or_block_len = uoff;
  8004205de6:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  8004205dea:	48 8b 55 c8          	mov    -0x38(%rbp),%rdx
  8004205dee:	48 89 50 08          	mov    %rdx,0x8(%rax)
#ifdef FRAME_DEBUG
                        printf("DW_CFA_def_cfa_offset(%ju)\n", uoff);
#endif
                        break;
  8004205df2:	e9 fb 05 00 00       	jmpq   80042063f2 <_dwarf_frame_run_inst+0xe00>
                case DW_CFA_def_cfa_expression:
                        *row_pc = pc;
  8004205df7:	48 8b 45 20          	mov    0x20(%rbp),%rax
  8004205dfb:	48 8b 55 10          	mov    0x10(%rbp),%rdx
  8004205dff:	48 89 10             	mov    %rdx,(%rax)
                        CFA.dw_offset_relevant = 0;
  8004205e02:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  8004205e06:	c6 00 00             	movb   $0x0,(%rax)
                        CFA.dw_value_type = DW_EXPR_EXPRESSION;
  8004205e09:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  8004205e0d:	c6 40 01 02          	movb   $0x2,0x1(%rax)
                        CFA.dw_offset_or_block_len = _dwarf_decode_uleb128(&p);
  8004205e11:	48 8b 5d 90          	mov    -0x70(%rbp),%rbx
  8004205e15:	48 8d 45 a0          	lea    -0x60(%rbp),%rax
  8004205e19:	48 89 c7             	mov    %rax,%rdi
  8004205e1c:	48 b8 82 3a 20 04 80 	movabs $0x8004203a82,%rax
  8004205e23:	00 00 00 
  8004205e26:	ff d0                	callq  *%rax
  8004205e28:	48 89 43 08          	mov    %rax,0x8(%rbx)
                        CFA.dw_block_ptr = p;
  8004205e2c:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  8004205e30:	48 8b 55 a0          	mov    -0x60(%rbp),%rdx
  8004205e34:	48 89 50 10          	mov    %rdx,0x10(%rax)
                        p += CFA.dw_offset_or_block_len;
  8004205e38:	48 8b 55 a0          	mov    -0x60(%rbp),%rdx
  8004205e3c:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  8004205e40:	48 8b 40 08          	mov    0x8(%rax),%rax
  8004205e44:	48 01 d0             	add    %rdx,%rax
  8004205e47:	48 89 45 a0          	mov    %rax,-0x60(%rbp)
#ifdef FRAME_DEBUG
                        printf("DW_CFA_def_cfa_expression\n");
#endif
                        break;
  8004205e4b:	e9 a2 05 00 00       	jmpq   80042063f2 <_dwarf_frame_run_inst+0xe00>
                case DW_CFA_expression:
                        *row_pc = pc;
  8004205e50:	48 8b 45 20          	mov    0x20(%rbp),%rax
  8004205e54:	48 8b 55 10          	mov    0x10(%rbp),%rdx
  8004205e58:	48 89 10             	mov    %rdx,(%rax)
                        reg = _dwarf_decode_uleb128(&p);
  8004205e5b:	48 8d 45 a0          	lea    -0x60(%rbp),%rax
  8004205e5f:	48 89 c7             	mov    %rax,%rdi
  8004205e62:	48 b8 82 3a 20 04 80 	movabs $0x8004203a82,%rax
  8004205e69:	00 00 00 
  8004205e6c:	ff d0                	callq  *%rax
  8004205e6e:	48 89 45 d0          	mov    %rax,-0x30(%rbp)
                        CHECK_TABLE_SIZE(reg);
  8004205e72:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  8004205e76:	0f b7 40 18          	movzwl 0x18(%rax),%eax
  8004205e7a:	0f b7 c0             	movzwl %ax,%eax
  8004205e7d:	48 3b 45 d0          	cmp    -0x30(%rbp),%rax
  8004205e81:	77 0c                	ja     8004205e8f <_dwarf_frame_run_inst+0x89d>
  8004205e83:	c7 45 ec 18 00 00 00 	movl   $0x18,-0x14(%rbp)
  8004205e8a:	e9 74 05 00 00       	jmpq   8004206403 <_dwarf_frame_run_inst+0xe11>
                        RL[reg].dw_offset_relevant = 0;
  8004205e8f:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  8004205e93:	48 8b 48 20          	mov    0x20(%rax),%rcx
  8004205e97:	48 8b 55 d0          	mov    -0x30(%rbp),%rdx
  8004205e9b:	48 89 d0             	mov    %rdx,%rax
  8004205e9e:	48 01 c0             	add    %rax,%rax
  8004205ea1:	48 01 d0             	add    %rdx,%rax
  8004205ea4:	48 c1 e0 03          	shl    $0x3,%rax
  8004205ea8:	48 01 c8             	add    %rcx,%rax
  8004205eab:	c6 00 00             	movb   $0x0,(%rax)
                        RL[reg].dw_value_type = DW_EXPR_EXPRESSION;
  8004205eae:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  8004205eb2:	48 8b 48 20          	mov    0x20(%rax),%rcx
  8004205eb6:	48 8b 55 d0          	mov    -0x30(%rbp),%rdx
  8004205eba:	48 89 d0             	mov    %rdx,%rax
  8004205ebd:	48 01 c0             	add    %rax,%rax
  8004205ec0:	48 01 d0             	add    %rdx,%rax
  8004205ec3:	48 c1 e0 03          	shl    $0x3,%rax
  8004205ec7:	48 01 c8             	add    %rcx,%rax
  8004205eca:	c6 40 01 02          	movb   $0x2,0x1(%rax)
                        RL[reg].dw_offset_or_block_len =
  8004205ece:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  8004205ed2:	48 8b 48 20          	mov    0x20(%rax),%rcx
  8004205ed6:	48 8b 55 d0          	mov    -0x30(%rbp),%rdx
  8004205eda:	48 89 d0             	mov    %rdx,%rax
  8004205edd:	48 01 c0             	add    %rax,%rax
  8004205ee0:	48 01 d0             	add    %rdx,%rax
  8004205ee3:	48 c1 e0 03          	shl    $0x3,%rax
  8004205ee7:	48 8d 1c 01          	lea    (%rcx,%rax,1),%rbx
                            _dwarf_decode_uleb128(&p);
  8004205eeb:	48 8d 45 a0          	lea    -0x60(%rbp),%rax
  8004205eef:	48 89 c7             	mov    %rax,%rdi
  8004205ef2:	48 b8 82 3a 20 04 80 	movabs $0x8004203a82,%rax
  8004205ef9:	00 00 00 
  8004205efc:	ff d0                	callq  *%rax
                        *row_pc = pc;
                        reg = _dwarf_decode_uleb128(&p);
                        CHECK_TABLE_SIZE(reg);
                        RL[reg].dw_offset_relevant = 0;
                        RL[reg].dw_value_type = DW_EXPR_EXPRESSION;
                        RL[reg].dw_offset_or_block_len =
  8004205efe:	48 89 43 08          	mov    %rax,0x8(%rbx)
                            _dwarf_decode_uleb128(&p);
                        RL[reg].dw_block_ptr = p;
  8004205f02:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  8004205f06:	48 8b 48 20          	mov    0x20(%rax),%rcx
  8004205f0a:	48 8b 55 d0          	mov    -0x30(%rbp),%rdx
  8004205f0e:	48 89 d0             	mov    %rdx,%rax
  8004205f11:	48 01 c0             	add    %rax,%rax
  8004205f14:	48 01 d0             	add    %rdx,%rax
  8004205f17:	48 c1 e0 03          	shl    $0x3,%rax
  8004205f1b:	48 8d 14 01          	lea    (%rcx,%rax,1),%rdx
  8004205f1f:	48 8b 45 a0          	mov    -0x60(%rbp),%rax
  8004205f23:	48 89 42 10          	mov    %rax,0x10(%rdx)
                        p += RL[reg].dw_offset_or_block_len;
  8004205f27:	48 8b 4d a0          	mov    -0x60(%rbp),%rcx
  8004205f2b:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  8004205f2f:	48 8b 70 20          	mov    0x20(%rax),%rsi
  8004205f33:	48 8b 55 d0          	mov    -0x30(%rbp),%rdx
  8004205f37:	48 89 d0             	mov    %rdx,%rax
  8004205f3a:	48 01 c0             	add    %rax,%rax
  8004205f3d:	48 01 d0             	add    %rdx,%rax
  8004205f40:	48 c1 e0 03          	shl    $0x3,%rax
  8004205f44:	48 01 f0             	add    %rsi,%rax
  8004205f47:	48 8b 40 08          	mov    0x8(%rax),%rax
  8004205f4b:	48 01 c8             	add    %rcx,%rax
  8004205f4e:	48 89 45 a0          	mov    %rax,-0x60(%rbp)
#ifdef FRAME_DEBUG
                        printf("DW_CFA_expression\n");
#endif
                        break;
  8004205f52:	e9 9b 04 00 00       	jmpq   80042063f2 <_dwarf_frame_run_inst+0xe00>
                case DW_CFA_offset_extended_sf:
                        *row_pc = pc;
  8004205f57:	48 8b 45 20          	mov    0x20(%rbp),%rax
  8004205f5b:	48 8b 55 10          	mov    0x10(%rbp),%rdx
  8004205f5f:	48 89 10             	mov    %rdx,(%rax)
                        reg = _dwarf_decode_uleb128(&p);
  8004205f62:	48 8d 45 a0          	lea    -0x60(%rbp),%rax
  8004205f66:	48 89 c7             	mov    %rax,%rdi
  8004205f69:	48 b8 82 3a 20 04 80 	movabs $0x8004203a82,%rax
  8004205f70:	00 00 00 
  8004205f73:	ff d0                	callq  *%rax
  8004205f75:	48 89 45 d0          	mov    %rax,-0x30(%rbp)
                        soff = _dwarf_decode_sleb128(&p);
  8004205f79:	48 8d 45 a0          	lea    -0x60(%rbp),%rax
  8004205f7d:	48 89 c7             	mov    %rax,%rdi
  8004205f80:	48 b8 e9 39 20 04 80 	movabs $0x80042039e9,%rax
  8004205f87:	00 00 00 
  8004205f8a:	ff d0                	callq  *%rax
  8004205f8c:	48 89 45 b8          	mov    %rax,-0x48(%rbp)
                        CHECK_TABLE_SIZE(reg);
  8004205f90:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  8004205f94:	0f b7 40 18          	movzwl 0x18(%rax),%eax
  8004205f98:	0f b7 c0             	movzwl %ax,%eax
  8004205f9b:	48 3b 45 d0          	cmp    -0x30(%rbp),%rax
  8004205f9f:	77 0c                	ja     8004205fad <_dwarf_frame_run_inst+0x9bb>
  8004205fa1:	c7 45 ec 18 00 00 00 	movl   $0x18,-0x14(%rbp)
  8004205fa8:	e9 56 04 00 00       	jmpq   8004206403 <_dwarf_frame_run_inst+0xe11>
                        RL[reg].dw_offset_relevant = 1;
  8004205fad:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  8004205fb1:	48 8b 48 20          	mov    0x20(%rax),%rcx
  8004205fb5:	48 8b 55 d0          	mov    -0x30(%rbp),%rdx
  8004205fb9:	48 89 d0             	mov    %rdx,%rax
  8004205fbc:	48 01 c0             	add    %rax,%rax
  8004205fbf:	48 01 d0             	add    %rdx,%rax
  8004205fc2:	48 c1 e0 03          	shl    $0x3,%rax
  8004205fc6:	48 01 c8             	add    %rcx,%rax
  8004205fc9:	c6 00 01             	movb   $0x1,(%rax)
                        RL[reg].dw_value_type = DW_EXPR_OFFSET;
  8004205fcc:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  8004205fd0:	48 8b 48 20          	mov    0x20(%rax),%rcx
  8004205fd4:	48 8b 55 d0          	mov    -0x30(%rbp),%rdx
  8004205fd8:	48 89 d0             	mov    %rdx,%rax
  8004205fdb:	48 01 c0             	add    %rax,%rax
  8004205fde:	48 01 d0             	add    %rdx,%rax
  8004205fe1:	48 c1 e0 03          	shl    $0x3,%rax
  8004205fe5:	48 01 c8             	add    %rcx,%rax
  8004205fe8:	c6 40 01 00          	movb   $0x0,0x1(%rax)
                        RL[reg].dw_regnum = dbg->dbg_frame_cfa_value;
  8004205fec:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  8004205ff0:	48 8b 48 20          	mov    0x20(%rax),%rcx
  8004205ff4:	48 8b 55 d0          	mov    -0x30(%rbp),%rdx
  8004205ff8:	48 89 d0             	mov    %rdx,%rax
  8004205ffb:	48 01 c0             	add    %rax,%rax
  8004205ffe:	48 01 d0             	add    %rdx,%rax
  8004206001:	48 c1 e0 03          	shl    $0x3,%rax
  8004206005:	48 8d 14 01          	lea    (%rcx,%rax,1),%rdx
  8004206009:	48 8b 45 98          	mov    -0x68(%rbp),%rax
  800420600d:	0f b7 40 44          	movzwl 0x44(%rax),%eax
  8004206011:	66 89 42 02          	mov    %ax,0x2(%rdx)
                        RL[reg].dw_offset_or_block_len = soff * daf;
  8004206015:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  8004206019:	48 8b 48 20          	mov    0x20(%rax),%rcx
  800420601d:	48 8b 55 d0          	mov    -0x30(%rbp),%rdx
  8004206021:	48 89 d0             	mov    %rdx,%rax
  8004206024:	48 01 c0             	add    %rax,%rax
  8004206027:	48 01 d0             	add    %rdx,%rax
  800420602a:	48 c1 e0 03          	shl    $0x3,%rax
  800420602e:	48 8d 14 01          	lea    (%rcx,%rax,1),%rdx
  8004206032:	48 8b 85 70 ff ff ff 	mov    -0x90(%rbp),%rax
  8004206039:	48 0f af 45 b8       	imul   -0x48(%rbp),%rax
  800420603e:	48 89 42 08          	mov    %rax,0x8(%rdx)
#ifdef FRAME_DEBUG
                        printf("DW_CFA_offset_extended_sf(reg=%ju,soff=%jd)\n",
                            reg, soff);
#endif
                        break;
  8004206042:	e9 ab 03 00 00       	jmpq   80042063f2 <_dwarf_frame_run_inst+0xe00>
                case DW_CFA_def_cfa_sf:
                        *row_pc = pc;
  8004206047:	48 8b 45 20          	mov    0x20(%rbp),%rax
  800420604b:	48 8b 55 10          	mov    0x10(%rbp),%rdx
  800420604f:	48 89 10             	mov    %rdx,(%rax)
                        reg = _dwarf_decode_uleb128(&p);
  8004206052:	48 8d 45 a0          	lea    -0x60(%rbp),%rax
  8004206056:	48 89 c7             	mov    %rax,%rdi
  8004206059:	48 b8 82 3a 20 04 80 	movabs $0x8004203a82,%rax
  8004206060:	00 00 00 
  8004206063:	ff d0                	callq  *%rax
  8004206065:	48 89 45 d0          	mov    %rax,-0x30(%rbp)
                        soff = _dwarf_decode_sleb128(&p);
  8004206069:	48 8d 45 a0          	lea    -0x60(%rbp),%rax
  800420606d:	48 89 c7             	mov    %rax,%rdi
  8004206070:	48 b8 e9 39 20 04 80 	movabs $0x80042039e9,%rax
  8004206077:	00 00 00 
  800420607a:	ff d0                	callq  *%rax
  800420607c:	48 89 45 b8          	mov    %rax,-0x48(%rbp)
                        CFA.dw_offset_relevant = 1;
  8004206080:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  8004206084:	c6 00 01             	movb   $0x1,(%rax)
                        CFA.dw_value_type = DW_EXPR_OFFSET;
  8004206087:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  800420608b:	c6 40 01 00          	movb   $0x0,0x1(%rax)
                        CFA.dw_regnum = reg;
  800420608f:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  8004206093:	48 8b 55 d0          	mov    -0x30(%rbp),%rdx
  8004206097:	66 89 50 02          	mov    %dx,0x2(%rax)
                        CFA.dw_offset_or_block_len = soff * daf;
  800420609b:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  800420609f:	48 8b 95 70 ff ff ff 	mov    -0x90(%rbp),%rdx
  80042060a6:	48 0f af 55 b8       	imul   -0x48(%rbp),%rdx
  80042060ab:	48 89 50 08          	mov    %rdx,0x8(%rax)
#ifdef FRAME_DEBUG
                        printf("DW_CFA_def_cfa_sf(reg=%ju,soff=%jd)\n", reg,
                            soff);
#endif
                        break;
  80042060af:	e9 3e 03 00 00       	jmpq   80042063f2 <_dwarf_frame_run_inst+0xe00>
                case DW_CFA_def_cfa_offset_sf:
                        *row_pc = pc;
  80042060b4:	48 8b 45 20          	mov    0x20(%rbp),%rax
  80042060b8:	48 8b 55 10          	mov    0x10(%rbp),%rdx
  80042060bc:	48 89 10             	mov    %rdx,(%rax)
                        soff = _dwarf_decode_sleb128(&p);
  80042060bf:	48 8d 45 a0          	lea    -0x60(%rbp),%rax
  80042060c3:	48 89 c7             	mov    %rax,%rdi
  80042060c6:	48 b8 e9 39 20 04 80 	movabs $0x80042039e9,%rax
  80042060cd:	00 00 00 
  80042060d0:	ff d0                	callq  *%rax
  80042060d2:	48 89 45 b8          	mov    %rax,-0x48(%rbp)
                        CFA.dw_offset_relevant = 1;
  80042060d6:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  80042060da:	c6 00 01             	movb   $0x1,(%rax)
                        CFA.dw_value_type = DW_EXPR_OFFSET;
  80042060dd:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  80042060e1:	c6 40 01 00          	movb   $0x0,0x1(%rax)
                        CFA.dw_offset_or_block_len = soff * daf;
  80042060e5:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  80042060e9:	48 8b 95 70 ff ff ff 	mov    -0x90(%rbp),%rdx
  80042060f0:	48 0f af 55 b8       	imul   -0x48(%rbp),%rdx
  80042060f5:	48 89 50 08          	mov    %rdx,0x8(%rax)
#ifdef FRAME_DEBUG
                        printf("DW_CFA_def_cfa_offset_sf(soff=%jd)\n", soff);
#endif
                        break;
  80042060f9:	e9 f4 02 00 00       	jmpq   80042063f2 <_dwarf_frame_run_inst+0xe00>
                case DW_CFA_val_offset:
                        *row_pc = pc;
  80042060fe:	48 8b 45 20          	mov    0x20(%rbp),%rax
  8004206102:	48 8b 55 10          	mov    0x10(%rbp),%rdx
  8004206106:	48 89 10             	mov    %rdx,(%rax)
                        reg = _dwarf_decode_uleb128(&p);
  8004206109:	48 8d 45 a0          	lea    -0x60(%rbp),%rax
  800420610d:	48 89 c7             	mov    %rax,%rdi
  8004206110:	48 b8 82 3a 20 04 80 	movabs $0x8004203a82,%rax
  8004206117:	00 00 00 
  800420611a:	ff d0                	callq  *%rax
  800420611c:	48 89 45 d0          	mov    %rax,-0x30(%rbp)
                        uoff = _dwarf_decode_uleb128(&p);
  8004206120:	48 8d 45 a0          	lea    -0x60(%rbp),%rax
  8004206124:	48 89 c7             	mov    %rax,%rdi
  8004206127:	48 b8 82 3a 20 04 80 	movabs $0x8004203a82,%rax
  800420612e:	00 00 00 
  8004206131:	ff d0                	callq  *%rax
  8004206133:	48 89 45 c8          	mov    %rax,-0x38(%rbp)
                        CHECK_TABLE_SIZE(reg);
  8004206137:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  800420613b:	0f b7 40 18          	movzwl 0x18(%rax),%eax
  800420613f:	0f b7 c0             	movzwl %ax,%eax
  8004206142:	48 3b 45 d0          	cmp    -0x30(%rbp),%rax
  8004206146:	77 0c                	ja     8004206154 <_dwarf_frame_run_inst+0xb62>
  8004206148:	c7 45 ec 18 00 00 00 	movl   $0x18,-0x14(%rbp)
  800420614f:	e9 af 02 00 00       	jmpq   8004206403 <_dwarf_frame_run_inst+0xe11>
                        RL[reg].dw_offset_relevant = 1;
  8004206154:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  8004206158:	48 8b 48 20          	mov    0x20(%rax),%rcx
  800420615c:	48 8b 55 d0          	mov    -0x30(%rbp),%rdx
  8004206160:	48 89 d0             	mov    %rdx,%rax
  8004206163:	48 01 c0             	add    %rax,%rax
  8004206166:	48 01 d0             	add    %rdx,%rax
  8004206169:	48 c1 e0 03          	shl    $0x3,%rax
  800420616d:	48 01 c8             	add    %rcx,%rax
  8004206170:	c6 00 01             	movb   $0x1,(%rax)
                        RL[reg].dw_value_type = DW_EXPR_VAL_OFFSET;
  8004206173:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  8004206177:	48 8b 48 20          	mov    0x20(%rax),%rcx
  800420617b:	48 8b 55 d0          	mov    -0x30(%rbp),%rdx
  800420617f:	48 89 d0             	mov    %rdx,%rax
  8004206182:	48 01 c0             	add    %rax,%rax
  8004206185:	48 01 d0             	add    %rdx,%rax
  8004206188:	48 c1 e0 03          	shl    $0x3,%rax
  800420618c:	48 01 c8             	add    %rcx,%rax
  800420618f:	c6 40 01 01          	movb   $0x1,0x1(%rax)
                        RL[reg].dw_regnum = dbg->dbg_frame_cfa_value;
  8004206193:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  8004206197:	48 8b 48 20          	mov    0x20(%rax),%rcx
  800420619b:	48 8b 55 d0          	mov    -0x30(%rbp),%rdx
  800420619f:	48 89 d0             	mov    %rdx,%rax
  80042061a2:	48 01 c0             	add    %rax,%rax
  80042061a5:	48 01 d0             	add    %rdx,%rax
  80042061a8:	48 c1 e0 03          	shl    $0x3,%rax
  80042061ac:	48 8d 14 01          	lea    (%rcx,%rax,1),%rdx
  80042061b0:	48 8b 45 98          	mov    -0x68(%rbp),%rax
  80042061b4:	0f b7 40 44          	movzwl 0x44(%rax),%eax
  80042061b8:	66 89 42 02          	mov    %ax,0x2(%rdx)
                        RL[reg].dw_offset_or_block_len = uoff * daf;
  80042061bc:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  80042061c0:	48 8b 48 20          	mov    0x20(%rax),%rcx
  80042061c4:	48 8b 55 d0          	mov    -0x30(%rbp),%rdx
  80042061c8:	48 89 d0             	mov    %rdx,%rax
  80042061cb:	48 01 c0             	add    %rax,%rax
  80042061ce:	48 01 d0             	add    %rdx,%rax
  80042061d1:	48 c1 e0 03          	shl    $0x3,%rax
  80042061d5:	48 8d 14 01          	lea    (%rcx,%rax,1),%rdx
  80042061d9:	48 8b 85 70 ff ff ff 	mov    -0x90(%rbp),%rax
  80042061e0:	48 0f af 45 c8       	imul   -0x38(%rbp),%rax
  80042061e5:	48 89 42 08          	mov    %rax,0x8(%rdx)
#ifdef FRAME_DEBUG
                        printf("DW_CFA_val_offset(reg=%ju,uoff=%ju)\n", reg,
                            uoff);
#endif
                        break;
  80042061e9:	e9 04 02 00 00       	jmpq   80042063f2 <_dwarf_frame_run_inst+0xe00>
                case DW_CFA_val_offset_sf:
                        *row_pc = pc;
  80042061ee:	48 8b 45 20          	mov    0x20(%rbp),%rax
  80042061f2:	48 8b 55 10          	mov    0x10(%rbp),%rdx
  80042061f6:	48 89 10             	mov    %rdx,(%rax)
                        reg = _dwarf_decode_uleb128(&p);
  80042061f9:	48 8d 45 a0          	lea    -0x60(%rbp),%rax
  80042061fd:	48 89 c7             	mov    %rax,%rdi
  8004206200:	48 b8 82 3a 20 04 80 	movabs $0x8004203a82,%rax
  8004206207:	00 00 00 
  800420620a:	ff d0                	callq  *%rax
  800420620c:	48 89 45 d0          	mov    %rax,-0x30(%rbp)
                        soff = _dwarf_decode_sleb128(&p);
  8004206210:	48 8d 45 a0          	lea    -0x60(%rbp),%rax
  8004206214:	48 89 c7             	mov    %rax,%rdi
  8004206217:	48 b8 e9 39 20 04 80 	movabs $0x80042039e9,%rax
  800420621e:	00 00 00 
  8004206221:	ff d0                	callq  *%rax
  8004206223:	48 89 45 b8          	mov    %rax,-0x48(%rbp)
                        CHECK_TABLE_SIZE(reg);
  8004206227:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  800420622b:	0f b7 40 18          	movzwl 0x18(%rax),%eax
  800420622f:	0f b7 c0             	movzwl %ax,%eax
  8004206232:	48 3b 45 d0          	cmp    -0x30(%rbp),%rax
  8004206236:	77 0c                	ja     8004206244 <_dwarf_frame_run_inst+0xc52>
  8004206238:	c7 45 ec 18 00 00 00 	movl   $0x18,-0x14(%rbp)
  800420623f:	e9 bf 01 00 00       	jmpq   8004206403 <_dwarf_frame_run_inst+0xe11>
                        RL[reg].dw_offset_relevant = 1;
  8004206244:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  8004206248:	48 8b 48 20          	mov    0x20(%rax),%rcx
  800420624c:	48 8b 55 d0          	mov    -0x30(%rbp),%rdx
  8004206250:	48 89 d0             	mov    %rdx,%rax
  8004206253:	48 01 c0             	add    %rax,%rax
  8004206256:	48 01 d0             	add    %rdx,%rax
  8004206259:	48 c1 e0 03          	shl    $0x3,%rax
  800420625d:	48 01 c8             	add    %rcx,%rax
  8004206260:	c6 00 01             	movb   $0x1,(%rax)
                        RL[reg].dw_value_type = DW_EXPR_VAL_OFFSET;
  8004206263:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  8004206267:	48 8b 48 20          	mov    0x20(%rax),%rcx
  800420626b:	48 8b 55 d0          	mov    -0x30(%rbp),%rdx
  800420626f:	48 89 d0             	mov    %rdx,%rax
  8004206272:	48 01 c0             	add    %rax,%rax
  8004206275:	48 01 d0             	add    %rdx,%rax
  8004206278:	48 c1 e0 03          	shl    $0x3,%rax
  800420627c:	48 01 c8             	add    %rcx,%rax
  800420627f:	c6 40 01 01          	movb   $0x1,0x1(%rax)
                        RL[reg].dw_regnum = dbg->dbg_frame_cfa_value;
  8004206283:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  8004206287:	48 8b 48 20          	mov    0x20(%rax),%rcx
  800420628b:	48 8b 55 d0          	mov    -0x30(%rbp),%rdx
  800420628f:	48 89 d0             	mov    %rdx,%rax
  8004206292:	48 01 c0             	add    %rax,%rax
  8004206295:	48 01 d0             	add    %rdx,%rax
  8004206298:	48 c1 e0 03          	shl    $0x3,%rax
  800420629c:	48 8d 14 01          	lea    (%rcx,%rax,1),%rdx
  80042062a0:	48 8b 45 98          	mov    -0x68(%rbp),%rax
  80042062a4:	0f b7 40 44          	movzwl 0x44(%rax),%eax
  80042062a8:	66 89 42 02          	mov    %ax,0x2(%rdx)
                        RL[reg].dw_offset_or_block_len = soff * daf;
  80042062ac:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  80042062b0:	48 8b 48 20          	mov    0x20(%rax),%rcx
  80042062b4:	48 8b 55 d0          	mov    -0x30(%rbp),%rdx
  80042062b8:	48 89 d0             	mov    %rdx,%rax
  80042062bb:	48 01 c0             	add    %rax,%rax
  80042062be:	48 01 d0             	add    %rdx,%rax
  80042062c1:	48 c1 e0 03          	shl    $0x3,%rax
  80042062c5:	48 8d 14 01          	lea    (%rcx,%rax,1),%rdx
  80042062c9:	48 8b 85 70 ff ff ff 	mov    -0x90(%rbp),%rax
  80042062d0:	48 0f af 45 b8       	imul   -0x48(%rbp),%rax
  80042062d5:	48 89 42 08          	mov    %rax,0x8(%rdx)
#ifdef FRAME_DEBUG
                        printf("DW_CFA_val_offset_sf(reg=%ju,soff=%jd)\n", reg,
                            soff);
#endif
                        break;
  80042062d9:	e9 14 01 00 00       	jmpq   80042063f2 <_dwarf_frame_run_inst+0xe00>
                case DW_CFA_val_expression:
                        *row_pc = pc;
  80042062de:	48 8b 45 20          	mov    0x20(%rbp),%rax
  80042062e2:	48 8b 55 10          	mov    0x10(%rbp),%rdx
  80042062e6:	48 89 10             	mov    %rdx,(%rax)
                        reg = _dwarf_decode_uleb128(&p);
  80042062e9:	48 8d 45 a0          	lea    -0x60(%rbp),%rax
  80042062ed:	48 89 c7             	mov    %rax,%rdi
  80042062f0:	48 b8 82 3a 20 04 80 	movabs $0x8004203a82,%rax
  80042062f7:	00 00 00 
  80042062fa:	ff d0                	callq  *%rax
  80042062fc:	48 89 45 d0          	mov    %rax,-0x30(%rbp)
                        CHECK_TABLE_SIZE(reg);
  8004206300:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  8004206304:	0f b7 40 18          	movzwl 0x18(%rax),%eax
  8004206308:	0f b7 c0             	movzwl %ax,%eax
  800420630b:	48 3b 45 d0          	cmp    -0x30(%rbp),%rax
  800420630f:	77 0c                	ja     800420631d <_dwarf_frame_run_inst+0xd2b>
  8004206311:	c7 45 ec 18 00 00 00 	movl   $0x18,-0x14(%rbp)
  8004206318:	e9 e6 00 00 00       	jmpq   8004206403 <_dwarf_frame_run_inst+0xe11>
                        RL[reg].dw_offset_relevant = 0;
  800420631d:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  8004206321:	48 8b 48 20          	mov    0x20(%rax),%rcx
  8004206325:	48 8b 55 d0          	mov    -0x30(%rbp),%rdx
  8004206329:	48 89 d0             	mov    %rdx,%rax
  800420632c:	48 01 c0             	add    %rax,%rax
  800420632f:	48 01 d0             	add    %rdx,%rax
  8004206332:	48 c1 e0 03          	shl    $0x3,%rax
  8004206336:	48 01 c8             	add    %rcx,%rax
  8004206339:	c6 00 00             	movb   $0x0,(%rax)
                        RL[reg].dw_value_type = DW_EXPR_VAL_EXPRESSION;
  800420633c:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  8004206340:	48 8b 48 20          	mov    0x20(%rax),%rcx
  8004206344:	48 8b 55 d0          	mov    -0x30(%rbp),%rdx
  8004206348:	48 89 d0             	mov    %rdx,%rax
  800420634b:	48 01 c0             	add    %rax,%rax
  800420634e:	48 01 d0             	add    %rdx,%rax
  8004206351:	48 c1 e0 03          	shl    $0x3,%rax
  8004206355:	48 01 c8             	add    %rcx,%rax
  8004206358:	c6 40 01 03          	movb   $0x3,0x1(%rax)
                        RL[reg].dw_offset_or_block_len =
  800420635c:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  8004206360:	48 8b 48 20          	mov    0x20(%rax),%rcx
  8004206364:	48 8b 55 d0          	mov    -0x30(%rbp),%rdx
  8004206368:	48 89 d0             	mov    %rdx,%rax
  800420636b:	48 01 c0             	add    %rax,%rax
  800420636e:	48 01 d0             	add    %rdx,%rax
  8004206371:	48 c1 e0 03          	shl    $0x3,%rax
  8004206375:	48 8d 1c 01          	lea    (%rcx,%rax,1),%rbx
                            _dwarf_decode_uleb128(&p);
  8004206379:	48 8d 45 a0          	lea    -0x60(%rbp),%rax
  800420637d:	48 89 c7             	mov    %rax,%rdi
  8004206380:	48 b8 82 3a 20 04 80 	movabs $0x8004203a82,%rax
  8004206387:	00 00 00 
  800420638a:	ff d0                	callq  *%rax
                        *row_pc = pc;
                        reg = _dwarf_decode_uleb128(&p);
                        CHECK_TABLE_SIZE(reg);
                        RL[reg].dw_offset_relevant = 0;
                        RL[reg].dw_value_type = DW_EXPR_VAL_EXPRESSION;
                        RL[reg].dw_offset_or_block_len =
  800420638c:	48 89 43 08          	mov    %rax,0x8(%rbx)
                            _dwarf_decode_uleb128(&p);
                        RL[reg].dw_block_ptr = p;
  8004206390:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  8004206394:	48 8b 48 20          	mov    0x20(%rax),%rcx
  8004206398:	48 8b 55 d0          	mov    -0x30(%rbp),%rdx
  800420639c:	48 89 d0             	mov    %rdx,%rax
  800420639f:	48 01 c0             	add    %rax,%rax
  80042063a2:	48 01 d0             	add    %rdx,%rax
  80042063a5:	48 c1 e0 03          	shl    $0x3,%rax
  80042063a9:	48 8d 14 01          	lea    (%rcx,%rax,1),%rdx
  80042063ad:	48 8b 45 a0          	mov    -0x60(%rbp),%rax
  80042063b1:	48 89 42 10          	mov    %rax,0x10(%rdx)
                        p += RL[reg].dw_offset_or_block_len;
  80042063b5:	48 8b 4d a0          	mov    -0x60(%rbp),%rcx
  80042063b9:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  80042063bd:	48 8b 70 20          	mov    0x20(%rax),%rsi
  80042063c1:	48 8b 55 d0          	mov    -0x30(%rbp),%rdx
  80042063c5:	48 89 d0             	mov    %rdx,%rax
  80042063c8:	48 01 c0             	add    %rax,%rax
  80042063cb:	48 01 d0             	add    %rdx,%rax
  80042063ce:	48 c1 e0 03          	shl    $0x3,%rax
  80042063d2:	48 01 f0             	add    %rsi,%rax
  80042063d5:	48 8b 40 08          	mov    0x8(%rax),%rax
  80042063d9:	48 01 c8             	add    %rcx,%rax
  80042063dc:	48 89 45 a0          	mov    %rax,-0x60(%rbp)
#ifdef FRAME_DEBUG
                        printf("DW_CFA_val_expression\n");
#endif
                        break;
  80042063e0:	eb 10                	jmp    80042063f2 <_dwarf_frame_run_inst+0xe00>
                default:
                        DWARF_SET_ERROR(dbg, error,
                            DW_DLE_FRAME_INSTR_EXEC_ERROR);
                        ret = DW_DLE_FRAME_INSTR_EXEC_ERROR;
  80042063e2:	c7 45 ec 15 00 00 00 	movl   $0x15,-0x14(%rbp)
                        goto program_done;
  80042063e9:	eb 18                	jmp    8004206403 <_dwarf_frame_run_inst+0xe11>
#ifdef FRAME_DEBUG
                        printf("DW_CFA_set_loc1(pc=%#jx)\n", pc);
#endif
                        if (pc_req < pc)
                                goto program_done;
                        break;
  80042063eb:	90                   	nop
  80042063ec:	eb 04                	jmp    80042063f2 <_dwarf_frame_run_inst+0xe00>
#ifdef FRAME_DEBUG
                        printf("DW_CFA_set_loc2(pc=%#jx)\n", pc);
#endif
                        if (pc_req < pc)
                                goto program_done;
                        break;
  80042063ee:	90                   	nop
  80042063ef:	eb 01                	jmp    80042063f2 <_dwarf_frame_run_inst+0xe00>
#ifdef FRAME_DEBUG
                        printf("DW_CFA_set_loc4(pc=%#jx)\n", pc);
#endif
                        if (pc_req < pc)
                                goto program_done;
                        break;
  80042063f1:	90                   	nop
        /* Save a copy of the table as initial state. */
        _dwarf_frame_regtable_copy(dbg, &init_rt, rt, error);
        p = insts;
        pe = p + len;

        while (p < pe) {
  80042063f2:	48 8b 45 a0          	mov    -0x60(%rbp),%rax
  80042063f6:	48 3b 45 e0          	cmp    -0x20(%rbp),%rax
  80042063fa:	0f 82 76 f2 ff ff    	jb     8004205676 <_dwarf_frame_run_inst+0x84>
  8004206400:	eb 01                	jmp    8004206403 <_dwarf_frame_run_inst+0xe11>
#ifdef FRAME_DEBUG
                        printf("DW_CFA_set_loc(pc=%#jx)\n", pc);
#endif
                        if (pc_req < pc)
				printf("Program done\n");
                                goto program_done;
  8004206402:	90                   	nop
        free(init_rt);
        if (saved_rt) {
                free(saved_rt->rt3_rules);
                free(saved_rt);
        }*/
        return (ret);
  8004206403:	8b 45 ec             	mov    -0x14(%rbp),%eax
#undef  CFA
#undef  INITCFA
#undef  RL
#undef  INITRL
#undef  CHECK_TABLE_SIZE
}
  8004206406:	48 81 c4 88 00 00 00 	add    $0x88,%rsp
  800420640d:	5b                   	pop    %rbx
  800420640e:	5d                   	pop    %rbp
  800420640f:	c3                   	retq   

0000008004206410 <_dwarf_frame_get_internal_table>:


int
_dwarf_frame_get_internal_table(Dwarf_Fde fde, Dwarf_Addr pc_req,
    Dwarf_Regtable3 **ret_rt, Dwarf_Addr *ret_row_pc, Dwarf_Error *error)
{
  8004206410:	55                   	push   %rbp
  8004206411:	48 89 e5             	mov    %rsp,%rbp
  8004206414:	48 83 c4 80          	add    $0xffffffffffffff80,%rsp
  8004206418:	48 89 7d c8          	mov    %rdi,-0x38(%rbp)
  800420641c:	48 89 75 c0          	mov    %rsi,-0x40(%rbp)
  8004206420:	48 89 55 b8          	mov    %rdx,-0x48(%rbp)
  8004206424:	48 89 4d b0          	mov    %rcx,-0x50(%rbp)
  8004206428:	4c 89 45 a8          	mov    %r8,-0x58(%rbp)
        Dwarf_Cie cie;
        Dwarf_Regtable3 *rt;
        Dwarf_Addr row_pc;
        int i, ret;

        assert(ret_rt != NULL);
  800420642c:	48 83 7d b8 00       	cmpq   $0x0,-0x48(%rbp)
  8004206431:	75 35                	jne    8004206468 <_dwarf_frame_get_internal_table+0x58>
  8004206433:	48 b9 90 a0 20 04 80 	movabs $0x800420a090,%rcx
  800420643a:	00 00 00 
  800420643d:	48 ba 77 9f 20 04 80 	movabs $0x8004209f77,%rdx
  8004206444:	00 00 00 
  8004206447:	be 01 02 00 00       	mov    $0x201,%esi
  800420644c:	48 bf 8c 9f 20 04 80 	movabs $0x8004209f8c,%rdi
  8004206453:	00 00 00 
  8004206456:	b8 00 00 00 00       	mov    $0x0,%eax
  800420645b:	49 b8 9b 01 20 04 80 	movabs $0x800420019b,%r8
  8004206462:	00 00 00 
  8004206465:	41 ff d0             	callq  *%r8

        //dbg = fde->fde_dbg;
        assert(dbg != NULL);
  8004206468:	48 b8 c8 b5 21 04 80 	movabs $0x800421b5c8,%rax
  800420646f:	00 00 00 
  8004206472:	48 8b 00             	mov    (%rax),%rax
  8004206475:	48 85 c0             	test   %rax,%rax
  8004206478:	75 35                	jne    80042064af <_dwarf_frame_get_internal_table+0x9f>
  800420647a:	48 b9 9f a0 20 04 80 	movabs $0x800420a09f,%rcx
  8004206481:	00 00 00 
  8004206484:	48 ba 77 9f 20 04 80 	movabs $0x8004209f77,%rdx
  800420648b:	00 00 00 
  800420648e:	be 04 02 00 00       	mov    $0x204,%esi
  8004206493:	48 bf 8c 9f 20 04 80 	movabs $0x8004209f8c,%rdi
  800420649a:	00 00 00 
  800420649d:	b8 00 00 00 00       	mov    $0x0,%eax
  80042064a2:	49 b8 9b 01 20 04 80 	movabs $0x800420019b,%r8
  80042064a9:	00 00 00 
  80042064ac:	41 ff d0             	callq  *%r8

        rt = dbg->dbg_internal_reg_table;
  80042064af:	48 b8 c8 b5 21 04 80 	movabs $0x800421b5c8,%rax
  80042064b6:	00 00 00 
  80042064b9:	48 8b 00             	mov    (%rax),%rax
  80042064bc:	48 8b 40 50          	mov    0x50(%rax),%rax
  80042064c0:	48 89 45 f0          	mov    %rax,-0x10(%rbp)

        /* Clear the content of regtable from previous run. */
        memset(&rt->rt3_cfa_rule, 0, sizeof(Dwarf_Regtable_Entry3));
  80042064c4:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  80042064c8:	ba 18 00 00 00       	mov    $0x18,%edx
  80042064cd:	be 00 00 00 00       	mov    $0x0,%esi
  80042064d2:	48 89 c7             	mov    %rax,%rdi
  80042064d5:	48 b8 5b 2e 20 04 80 	movabs $0x8004202e5b,%rax
  80042064dc:	00 00 00 
  80042064df:	ff d0                	callq  *%rax
        memset(rt->rt3_rules, 0, rt->rt3_reg_table_size *
  80042064e1:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  80042064e5:	0f b7 40 18          	movzwl 0x18(%rax),%eax
  80042064e9:	0f b7 d0             	movzwl %ax,%edx
  80042064ec:	48 89 d0             	mov    %rdx,%rax
  80042064ef:	48 01 c0             	add    %rax,%rax
  80042064f2:	48 01 d0             	add    %rdx,%rax
  80042064f5:	48 c1 e0 03          	shl    $0x3,%rax
  80042064f9:	48 89 c2             	mov    %rax,%rdx
  80042064fc:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8004206500:	48 8b 40 20          	mov    0x20(%rax),%rax
  8004206504:	be 00 00 00 00       	mov    $0x0,%esi
  8004206509:	48 89 c7             	mov    %rax,%rdi
  800420650c:	48 b8 5b 2e 20 04 80 	movabs $0x8004202e5b,%rax
  8004206513:	00 00 00 
  8004206516:	ff d0                	callq  *%rax
            sizeof(Dwarf_Regtable_Entry3));

        /* Set rules to initial values. */
        for (i = 0; i < rt->rt3_reg_table_size; i++)
  8004206518:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%rbp)
  800420651f:	eb 38                	jmp    8004206559 <_dwarf_frame_get_internal_table+0x149>
                rt->rt3_rules[i].dw_regnum = dbg->dbg_frame_rule_initial_value;
  8004206521:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8004206525:	48 8b 48 20          	mov    0x20(%rax),%rcx
  8004206529:	8b 45 fc             	mov    -0x4(%rbp),%eax
  800420652c:	48 63 d0             	movslq %eax,%rdx
  800420652f:	48 89 d0             	mov    %rdx,%rax
  8004206532:	48 01 c0             	add    %rax,%rax
  8004206535:	48 01 d0             	add    %rdx,%rax
  8004206538:	48 c1 e0 03          	shl    $0x3,%rax
  800420653c:	48 8d 14 01          	lea    (%rcx,%rax,1),%rdx
  8004206540:	48 b8 c8 b5 21 04 80 	movabs $0x800421b5c8,%rax
  8004206547:	00 00 00 
  800420654a:	48 8b 00             	mov    (%rax),%rax
  800420654d:	0f b7 40 42          	movzwl 0x42(%rax),%eax
  8004206551:	66 89 42 02          	mov    %ax,0x2(%rdx)
        memset(&rt->rt3_cfa_rule, 0, sizeof(Dwarf_Regtable_Entry3));
        memset(rt->rt3_rules, 0, rt->rt3_reg_table_size *
            sizeof(Dwarf_Regtable_Entry3));

        /* Set rules to initial values. */
        for (i = 0; i < rt->rt3_reg_table_size; i++)
  8004206555:	83 45 fc 01          	addl   $0x1,-0x4(%rbp)
  8004206559:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  800420655d:	0f b7 40 18          	movzwl 0x18(%rax),%eax
  8004206561:	0f b7 c0             	movzwl %ax,%eax
  8004206564:	3b 45 fc             	cmp    -0x4(%rbp),%eax
  8004206567:	7f b8                	jg     8004206521 <_dwarf_frame_get_internal_table+0x111>
                rt->rt3_rules[i].dw_regnum = dbg->dbg_frame_rule_initial_value;

        /* Run initial instructions in CIE. */
        cie = fde->fde_cie;
  8004206569:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
  800420656d:	48 8b 40 08          	mov    0x8(%rax),%rax
  8004206571:	48 89 45 e8          	mov    %rax,-0x18(%rbp)
        assert(cie != NULL);
  8004206575:	48 83 7d e8 00       	cmpq   $0x0,-0x18(%rbp)
  800420657a:	75 35                	jne    80042065b1 <_dwarf_frame_get_internal_table+0x1a1>
  800420657c:	48 b9 ab a0 20 04 80 	movabs $0x800420a0ab,%rcx
  8004206583:	00 00 00 
  8004206586:	48 ba 77 9f 20 04 80 	movabs $0x8004209f77,%rdx
  800420658d:	00 00 00 
  8004206590:	be 13 02 00 00       	mov    $0x213,%esi
  8004206595:	48 bf 8c 9f 20 04 80 	movabs $0x8004209f8c,%rdi
  800420659c:	00 00 00 
  800420659f:	b8 00 00 00 00       	mov    $0x0,%eax
  80042065a4:	49 b8 9b 01 20 04 80 	movabs $0x800420019b,%r8
  80042065ab:	00 00 00 
  80042065ae:	41 ff d0             	callq  *%r8
        ret = _dwarf_frame_run_inst(dbg, rt, cie->cie_initinst,
            cie->cie_instlen, cie->cie_caf, cie->cie_daf, 0, ~0ULL,
  80042065b1:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
                rt->rt3_rules[i].dw_regnum = dbg->dbg_frame_rule_initial_value;

        /* Run initial instructions in CIE. */
        cie = fde->fde_cie;
        assert(cie != NULL);
        ret = _dwarf_frame_run_inst(dbg, rt, cie->cie_initinst,
  80042065b5:	4c 8b 48 40          	mov    0x40(%rax),%r9
            cie->cie_instlen, cie->cie_caf, cie->cie_daf, 0, ~0ULL,
  80042065b9:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
                rt->rt3_rules[i].dw_regnum = dbg->dbg_frame_rule_initial_value;

        /* Run initial instructions in CIE. */
        cie = fde->fde_cie;
        assert(cie != NULL);
        ret = _dwarf_frame_run_inst(dbg, rt, cie->cie_initinst,
  80042065bd:	4c 8b 40 38          	mov    0x38(%rax),%r8
            cie->cie_instlen, cie->cie_caf, cie->cie_daf, 0, ~0ULL,
  80042065c1:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
                rt->rt3_rules[i].dw_regnum = dbg->dbg_frame_rule_initial_value;

        /* Run initial instructions in CIE. */
        cie = fde->fde_cie;
        assert(cie != NULL);
        ret = _dwarf_frame_run_inst(dbg, rt, cie->cie_initinst,
  80042065c5:	48 8b 48 70          	mov    0x70(%rax),%rcx
  80042065c9:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  80042065cd:	48 8b 50 68          	mov    0x68(%rax),%rdx
  80042065d1:	48 b8 c8 b5 21 04 80 	movabs $0x800421b5c8,%rax
  80042065d8:	00 00 00 
  80042065db:	48 8b 00             	mov    (%rax),%rax
  80042065de:	48 8b 75 f0          	mov    -0x10(%rbp),%rsi
  80042065e2:	48 8b 7d a8          	mov    -0x58(%rbp),%rdi
  80042065e6:	48 89 7c 24 18       	mov    %rdi,0x18(%rsp)
  80042065eb:	48 8d 7d d8          	lea    -0x28(%rbp),%rdi
  80042065ef:	48 89 7c 24 10       	mov    %rdi,0x10(%rsp)
  80042065f4:	48 c7 44 24 08 ff ff 	movq   $0xffffffffffffffff,0x8(%rsp)
  80042065fb:	ff ff 
  80042065fd:	48 c7 04 24 00 00 00 	movq   $0x0,(%rsp)
  8004206604:	00 
  8004206605:	48 89 c7             	mov    %rax,%rdi
  8004206608:	48 b8 f2 55 20 04 80 	movabs $0x80042055f2,%rax
  800420660f:	00 00 00 
  8004206612:	ff d0                	callq  *%rax
  8004206614:	89 45 e4             	mov    %eax,-0x1c(%rbp)
            cie->cie_instlen, cie->cie_caf, cie->cie_daf, 0, ~0ULL,
            &row_pc, error);
        if (ret != DW_DLE_NONE)
  8004206617:	83 7d e4 00          	cmpl   $0x0,-0x1c(%rbp)
  800420661b:	74 08                	je     8004206625 <_dwarf_frame_get_internal_table+0x215>
                return (ret);
  800420661d:	8b 45 e4             	mov    -0x1c(%rbp),%eax
  8004206620:	e9 a1 00 00 00       	jmpq   80042066c6 <_dwarf_frame_get_internal_table+0x2b6>
        /* Run instructions in FDE. */
        if (pc_req >= fde->fde_initloc) {
  8004206625:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
  8004206629:	48 8b 40 30          	mov    0x30(%rax),%rax
  800420662d:	48 3b 45 c0          	cmp    -0x40(%rbp),%rax
  8004206631:	77 78                	ja     80042066ab <_dwarf_frame_get_internal_table+0x29b>
                ret = _dwarf_frame_run_inst(dbg, rt, fde->fde_inst,
                    fde->fde_instlen, cie->cie_caf, cie->cie_daf,
                    fde->fde_initloc, pc_req, &row_pc, error);
  8004206633:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
            &row_pc, error);
        if (ret != DW_DLE_NONE)
                return (ret);
        /* Run instructions in FDE. */
        if (pc_req >= fde->fde_initloc) {
                ret = _dwarf_frame_run_inst(dbg, rt, fde->fde_inst,
  8004206637:	48 8b 78 30          	mov    0x30(%rax),%rdi
                    fde->fde_instlen, cie->cie_caf, cie->cie_daf,
  800420663b:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
            &row_pc, error);
        if (ret != DW_DLE_NONE)
                return (ret);
        /* Run instructions in FDE. */
        if (pc_req >= fde->fde_initloc) {
                ret = _dwarf_frame_run_inst(dbg, rt, fde->fde_inst,
  800420663f:	4c 8b 48 40          	mov    0x40(%rax),%r9
                    fde->fde_instlen, cie->cie_caf, cie->cie_daf,
  8004206643:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
            &row_pc, error);
        if (ret != DW_DLE_NONE)
                return (ret);
        /* Run instructions in FDE. */
        if (pc_req >= fde->fde_initloc) {
                ret = _dwarf_frame_run_inst(dbg, rt, fde->fde_inst,
  8004206647:	4c 8b 50 38          	mov    0x38(%rax),%r10
                    fde->fde_instlen, cie->cie_caf, cie->cie_daf,
  800420664b:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
            &row_pc, error);
        if (ret != DW_DLE_NONE)
                return (ret);
        /* Run instructions in FDE. */
        if (pc_req >= fde->fde_initloc) {
                ret = _dwarf_frame_run_inst(dbg, rt, fde->fde_inst,
  800420664f:	48 8b 48 58          	mov    0x58(%rax),%rcx
  8004206653:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
  8004206657:	48 8b 50 50          	mov    0x50(%rax),%rdx
  800420665b:	48 b8 c8 b5 21 04 80 	movabs $0x800421b5c8,%rax
  8004206662:	00 00 00 
  8004206665:	48 8b 00             	mov    (%rax),%rax
  8004206668:	48 8b 75 f0          	mov    -0x10(%rbp),%rsi
  800420666c:	4c 8b 45 a8          	mov    -0x58(%rbp),%r8
  8004206670:	4c 89 44 24 18       	mov    %r8,0x18(%rsp)
  8004206675:	4c 8d 45 d8          	lea    -0x28(%rbp),%r8
  8004206679:	4c 89 44 24 10       	mov    %r8,0x10(%rsp)
  800420667e:	4c 8b 45 c0          	mov    -0x40(%rbp),%r8
  8004206682:	4c 89 44 24 08       	mov    %r8,0x8(%rsp)
  8004206687:	48 89 3c 24          	mov    %rdi,(%rsp)
  800420668b:	4d 89 d0             	mov    %r10,%r8
  800420668e:	48 89 c7             	mov    %rax,%rdi
  8004206691:	48 b8 f2 55 20 04 80 	movabs $0x80042055f2,%rax
  8004206698:	00 00 00 
  800420669b:	ff d0                	callq  *%rax
  800420669d:	89 45 e4             	mov    %eax,-0x1c(%rbp)
                    fde->fde_instlen, cie->cie_caf, cie->cie_daf,
                    fde->fde_initloc, pc_req, &row_pc, error);
                if (ret != DW_DLE_NONE)
  80042066a0:	83 7d e4 00          	cmpl   $0x0,-0x1c(%rbp)
  80042066a4:	74 05                	je     80042066ab <_dwarf_frame_get_internal_table+0x29b>
                        return (ret);
  80042066a6:	8b 45 e4             	mov    -0x1c(%rbp),%eax
  80042066a9:	eb 1b                	jmp    80042066c6 <_dwarf_frame_get_internal_table+0x2b6>
        }

        *ret_rt = rt;
  80042066ab:	48 8b 45 b8          	mov    -0x48(%rbp),%rax
  80042066af:	48 8b 55 f0          	mov    -0x10(%rbp),%rdx
  80042066b3:	48 89 10             	mov    %rdx,(%rax)
        *ret_row_pc = row_pc;
  80042066b6:	48 8b 55 d8          	mov    -0x28(%rbp),%rdx
  80042066ba:	48 8b 45 b0          	mov    -0x50(%rbp),%rax
  80042066be:	48 89 10             	mov    %rdx,(%rax)

        return (DW_DLE_NONE);
  80042066c1:	b8 00 00 00 00       	mov    $0x0,%eax
}
  80042066c6:	c9                   	leaveq 
  80042066c7:	c3                   	retq   

00000080042066c8 <dwarf_get_fde_info_for_all_regs>:


int
dwarf_get_fde_info_for_all_regs(Dwarf_Fde fde, Dwarf_Addr pc_requested,
    Dwarf_Regtable *reg_table, Dwarf_Addr *row_pc, Dwarf_Error *error)
{
  80042066c8:	55                   	push   %rbp
  80042066c9:	48 89 e5             	mov    %rsp,%rbp
  80042066cc:	48 83 ec 50          	sub    $0x50,%rsp
  80042066d0:	48 89 7d d8          	mov    %rdi,-0x28(%rbp)
  80042066d4:	48 89 75 d0          	mov    %rsi,-0x30(%rbp)
  80042066d8:	48 89 55 c8          	mov    %rdx,-0x38(%rbp)
  80042066dc:	48 89 4d c0          	mov    %rcx,-0x40(%rbp)
  80042066e0:	4c 89 45 b8          	mov    %r8,-0x48(%rbp)
        Dwarf_Regtable3 *rt;
        Dwarf_Addr pc;
        Dwarf_Half cfa;
        int i, ret;

        if (fde == NULL || reg_table == NULL || row_pc == NULL) {
  80042066e4:	48 83 7d d8 00       	cmpq   $0x0,-0x28(%rbp)
  80042066e9:	74 0e                	je     80042066f9 <dwarf_get_fde_info_for_all_regs+0x31>
  80042066eb:	48 83 7d c8 00       	cmpq   $0x0,-0x38(%rbp)
  80042066f0:	74 07                	je     80042066f9 <dwarf_get_fde_info_for_all_regs+0x31>
  80042066f2:	48 83 7d c0 00       	cmpq   $0x0,-0x40(%rbp)
  80042066f7:	75 15                	jne    800420670e <dwarf_get_fde_info_for_all_regs+0x46>
                DWARF_SET_ERROR(dbg, error, DW_DLE_ARGUMENT);
				*(int*) 0 =0;
  80042066f9:	b8 00 00 00 00       	mov    $0x0,%eax
  80042066fe:	c7 00 00 00 00 00    	movl   $0x0,(%rax)
                return (DW_DLV_ERROR);
  8004206704:	b8 01 00 00 00       	mov    $0x1,%eax
  8004206709:	e9 35 02 00 00       	jmpq   8004206943 <dwarf_get_fde_info_for_all_regs+0x27b>
        }

        assert(dbg != NULL);
  800420670e:	48 b8 c8 b5 21 04 80 	movabs $0x800421b5c8,%rax
  8004206715:	00 00 00 
  8004206718:	48 8b 00             	mov    (%rax),%rax
  800420671b:	48 85 c0             	test   %rax,%rax
  800420671e:	75 35                	jne    8004206755 <dwarf_get_fde_info_for_all_regs+0x8d>
  8004206720:	48 b9 9f a0 20 04 80 	movabs $0x800420a09f,%rcx
  8004206727:	00 00 00 
  800420672a:	48 ba 77 9f 20 04 80 	movabs $0x8004209f77,%rdx
  8004206731:	00 00 00 
  8004206734:	be 39 02 00 00       	mov    $0x239,%esi
  8004206739:	48 bf 8c 9f 20 04 80 	movabs $0x8004209f8c,%rdi
  8004206740:	00 00 00 
  8004206743:	b8 00 00 00 00       	mov    $0x0,%eax
  8004206748:	49 b8 9b 01 20 04 80 	movabs $0x800420019b,%r8
  800420674f:	00 00 00 
  8004206752:	41 ff d0             	callq  *%r8

        if (pc_requested < fde->fde_initloc ||
  8004206755:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  8004206759:	48 8b 40 30          	mov    0x30(%rax),%rax
  800420675d:	48 3b 45 d0          	cmp    -0x30(%rbp),%rax
  8004206761:	77 19                	ja     800420677c <dwarf_get_fde_info_for_all_regs+0xb4>
            pc_requested >= fde->fde_initloc + fde->fde_adrange) {
  8004206763:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  8004206767:	48 8b 50 30          	mov    0x30(%rax),%rdx
  800420676b:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  800420676f:	48 8b 40 38          	mov    0x38(%rax),%rax
  8004206773:	48 01 d0             	add    %rdx,%rax
                return (DW_DLV_ERROR);
        }

        assert(dbg != NULL);

        if (pc_requested < fde->fde_initloc ||
  8004206776:	48 3b 45 d0          	cmp    -0x30(%rbp),%rax
  800420677a:	77 15                	ja     8004206791 <dwarf_get_fde_info_for_all_regs+0xc9>
            pc_requested >= fde->fde_initloc + fde->fde_adrange) {
                DWARF_SET_ERROR(dbg, error, DW_DLE_PC_NOT_IN_FDE_RANGE);
				*(int*) 0 =0;
  800420677c:	b8 00 00 00 00       	mov    $0x0,%eax
  8004206781:	c7 00 00 00 00 00    	movl   $0x0,(%rax)
                return (DW_DLV_ERROR);
  8004206787:	b8 01 00 00 00       	mov    $0x1,%eax
  800420678c:	e9 b2 01 00 00       	jmpq   8004206943 <dwarf_get_fde_info_for_all_regs+0x27b>
        }

        ret = _dwarf_frame_get_internal_table(fde, pc_requested, &rt, &pc,
  8004206791:	48 8b 7d b8          	mov    -0x48(%rbp),%rdi
  8004206795:	48 8d 4d e0          	lea    -0x20(%rbp),%rcx
  8004206799:	48 8d 55 e8          	lea    -0x18(%rbp),%rdx
  800420679d:	48 8b 75 d0          	mov    -0x30(%rbp),%rsi
  80042067a1:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  80042067a5:	49 89 f8             	mov    %rdi,%r8
  80042067a8:	48 89 c7             	mov    %rax,%rdi
  80042067ab:	48 b8 10 64 20 04 80 	movabs $0x8004206410,%rax
  80042067b2:	00 00 00 
  80042067b5:	ff d0                	callq  *%rax
  80042067b7:	89 45 f8             	mov    %eax,-0x8(%rbp)
            error);
        if (ret != DW_DLE_NONE)
  80042067ba:	83 7d f8 00          	cmpl   $0x0,-0x8(%rbp)
  80042067be:	74 15                	je     80042067d5 <dwarf_get_fde_info_for_all_regs+0x10d>
		{

				*(int*)0 = 0;
  80042067c0:	b8 00 00 00 00       	mov    $0x0,%eax
  80042067c5:	c7 00 00 00 00 00    	movl   $0x0,(%rax)
                return (DW_DLV_ERROR);
  80042067cb:	b8 01 00 00 00       	mov    $0x1,%eax
  80042067d0:	e9 6e 01 00 00       	jmpq   8004206943 <dwarf_get_fde_info_for_all_regs+0x27b>
        /*
         * Copy the CFA rule to the column intended for holding the CFA,
         * if it's within the range of regtable.
         */
#define CFA rt->rt3_cfa_rule
        cfa = dbg->dbg_frame_cfa_value;
  80042067d5:	48 b8 c8 b5 21 04 80 	movabs $0x800421b5c8,%rax
  80042067dc:	00 00 00 
  80042067df:	48 8b 00             	mov    (%rax),%rax
  80042067e2:	0f b7 40 44          	movzwl 0x44(%rax),%eax
  80042067e6:	66 89 45 f6          	mov    %ax,-0xa(%rbp)
        if (cfa < DW_REG_TABLE_SIZE) {
  80042067ea:	66 83 7d f6 41       	cmpw   $0x41,-0xa(%rbp)
  80042067ef:	77 5a                	ja     800420684b <dwarf_get_fde_info_for_all_regs+0x183>
                reg_table->rules[cfa].dw_offset_relevant =
  80042067f1:	0f b7 4d f6          	movzwl -0xa(%rbp),%ecx
                   CFA.dw_offset_relevant;
  80042067f5:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  80042067f9:	0f b6 00             	movzbl (%rax),%eax
         * if it's within the range of regtable.
         */
#define CFA rt->rt3_cfa_rule
        cfa = dbg->dbg_frame_cfa_value;
        if (cfa < DW_REG_TABLE_SIZE) {
                reg_table->rules[cfa].dw_offset_relevant =
  80042067fc:	48 8b 55 c8          	mov    -0x38(%rbp),%rdx
  8004206800:	48 63 c9             	movslq %ecx,%rcx
  8004206803:	48 c1 e1 04          	shl    $0x4,%rcx
  8004206807:	48 01 ca             	add    %rcx,%rdx
  800420680a:	88 02                	mov    %al,(%rdx)
                   CFA.dw_offset_relevant;
                reg_table->rules[cfa].dw_regnum = CFA.dw_regnum;
  800420680c:	0f b7 4d f6          	movzwl -0xa(%rbp),%ecx
  8004206810:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004206814:	0f b7 40 02          	movzwl 0x2(%rax),%eax
  8004206818:	48 8b 55 c8          	mov    -0x38(%rbp),%rdx
  800420681c:	48 63 c9             	movslq %ecx,%rcx
  800420681f:	48 c1 e1 04          	shl    $0x4,%rcx
  8004206823:	48 01 ca             	add    %rcx,%rdx
  8004206826:	66 89 42 02          	mov    %ax,0x2(%rdx)
                reg_table->rules[cfa].dw_offset = CFA.dw_offset_or_block_len;
  800420682a:	0f b7 4d f6          	movzwl -0xa(%rbp),%ecx
  800420682e:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004206832:	48 8b 40 08          	mov    0x8(%rax),%rax
  8004206836:	48 8b 55 c8          	mov    -0x38(%rbp),%rdx
  800420683a:	48 63 c9             	movslq %ecx,%rcx
  800420683d:	48 c1 e1 04          	shl    $0x4,%rcx
  8004206841:	48 01 ca             	add    %rcx,%rdx
  8004206844:	48 83 c2 08          	add    $0x8,%rdx
  8004206848:	48 89 02             	mov    %rax,(%rdx)
        }

        /*
         * Copy other columns.
         */
        for (i = 0; i < DW_REG_TABLE_SIZE && i < dbg->dbg_frame_rule_table_size;
  800420684b:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%rbp)
  8004206852:	e9 b9 00 00 00       	jmpq   8004206910 <dwarf_get_fde_info_for_all_regs+0x248>
             i++) {

                /* Do not overwrite CFA column */
                if (i == cfa)
  8004206857:	0f b7 45 f6          	movzwl -0xa(%rbp),%eax
  800420685b:	3b 45 fc             	cmp    -0x4(%rbp),%eax
  800420685e:	0f 84 a7 00 00 00    	je     800420690b <dwarf_get_fde_info_for_all_regs+0x243>
                        continue;

                reg_table->rules[i].dw_offset_relevant =
                    rt->rt3_rules[i].dw_offset_relevant;
  8004206864:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004206868:	48 8b 48 20          	mov    0x20(%rax),%rcx
  800420686c:	8b 45 fc             	mov    -0x4(%rbp),%eax
  800420686f:	48 63 d0             	movslq %eax,%rdx
  8004206872:	48 89 d0             	mov    %rdx,%rax
  8004206875:	48 01 c0             	add    %rax,%rax
  8004206878:	48 01 d0             	add    %rdx,%rax
  800420687b:	48 c1 e0 03          	shl    $0x3,%rax
  800420687f:	48 01 c8             	add    %rcx,%rax
  8004206882:	0f b6 00             	movzbl (%rax),%eax

                /* Do not overwrite CFA column */
                if (i == cfa)
                        continue;

                reg_table->rules[i].dw_offset_relevant =
  8004206885:	48 8b 55 c8          	mov    -0x38(%rbp),%rdx
  8004206889:	8b 4d fc             	mov    -0x4(%rbp),%ecx
  800420688c:	48 63 c9             	movslq %ecx,%rcx
  800420688f:	48 c1 e1 04          	shl    $0x4,%rcx
  8004206893:	48 01 ca             	add    %rcx,%rdx
  8004206896:	88 02                	mov    %al,(%rdx)
                    rt->rt3_rules[i].dw_offset_relevant;
                reg_table->rules[i].dw_regnum = rt->rt3_rules[i].dw_regnum;
  8004206898:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  800420689c:	48 8b 48 20          	mov    0x20(%rax),%rcx
  80042068a0:	8b 45 fc             	mov    -0x4(%rbp),%eax
  80042068a3:	48 63 d0             	movslq %eax,%rdx
  80042068a6:	48 89 d0             	mov    %rdx,%rax
  80042068a9:	48 01 c0             	add    %rax,%rax
  80042068ac:	48 01 d0             	add    %rdx,%rax
  80042068af:	48 c1 e0 03          	shl    $0x3,%rax
  80042068b3:	48 01 c8             	add    %rcx,%rax
  80042068b6:	0f b7 40 02          	movzwl 0x2(%rax),%eax
  80042068ba:	48 8b 55 c8          	mov    -0x38(%rbp),%rdx
  80042068be:	8b 4d fc             	mov    -0x4(%rbp),%ecx
  80042068c1:	48 63 c9             	movslq %ecx,%rcx
  80042068c4:	48 c1 e1 04          	shl    $0x4,%rcx
  80042068c8:	48 01 ca             	add    %rcx,%rdx
  80042068cb:	66 89 42 02          	mov    %ax,0x2(%rdx)
                reg_table->rules[i].dw_offset =
                    rt->rt3_rules[i].dw_offset_or_block_len;
  80042068cf:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  80042068d3:	48 8b 48 20          	mov    0x20(%rax),%rcx
  80042068d7:	8b 45 fc             	mov    -0x4(%rbp),%eax
  80042068da:	48 63 d0             	movslq %eax,%rdx
  80042068dd:	48 89 d0             	mov    %rdx,%rax
  80042068e0:	48 01 c0             	add    %rax,%rax
  80042068e3:	48 01 d0             	add    %rdx,%rax
  80042068e6:	48 c1 e0 03          	shl    $0x3,%rax
  80042068ea:	48 01 c8             	add    %rcx,%rax
  80042068ed:	48 8b 40 08          	mov    0x8(%rax),%rax
                        continue;

                reg_table->rules[i].dw_offset_relevant =
                    rt->rt3_rules[i].dw_offset_relevant;
                reg_table->rules[i].dw_regnum = rt->rt3_rules[i].dw_regnum;
                reg_table->rules[i].dw_offset =
  80042068f1:	48 8b 55 c8          	mov    -0x38(%rbp),%rdx
  80042068f5:	8b 4d fc             	mov    -0x4(%rbp),%ecx
  80042068f8:	48 63 c9             	movslq %ecx,%rcx
  80042068fb:	48 c1 e1 04          	shl    $0x4,%rcx
  80042068ff:	48 01 ca             	add    %rcx,%rdx
  8004206902:	48 83 c2 08          	add    $0x8,%rdx
  8004206906:	48 89 02             	mov    %rax,(%rdx)
  8004206909:	eb 01                	jmp    800420690c <dwarf_get_fde_info_for_all_regs+0x244>
        for (i = 0; i < DW_REG_TABLE_SIZE && i < dbg->dbg_frame_rule_table_size;
             i++) {

                /* Do not overwrite CFA column */
                if (i == cfa)
                        continue;
  800420690b:	90                   	nop

        /*
         * Copy other columns.
         */
        for (i = 0; i < DW_REG_TABLE_SIZE && i < dbg->dbg_frame_rule_table_size;
             i++) {
  800420690c:	83 45 fc 01          	addl   $0x1,-0x4(%rbp)
        }

        /*
         * Copy other columns.
         */
        for (i = 0; i < DW_REG_TABLE_SIZE && i < dbg->dbg_frame_rule_table_size;
  8004206910:	83 7d fc 41          	cmpl   $0x41,-0x4(%rbp)
  8004206914:	7f 1d                	jg     8004206933 <dwarf_get_fde_info_for_all_regs+0x26b>
  8004206916:	48 b8 c8 b5 21 04 80 	movabs $0x800421b5c8,%rax
  800420691d:	00 00 00 
  8004206920:	48 8b 00             	mov    (%rax),%rax
  8004206923:	0f b7 40 40          	movzwl 0x40(%rax),%eax
  8004206927:	0f b7 c0             	movzwl %ax,%eax
  800420692a:	3b 45 fc             	cmp    -0x4(%rbp),%eax
  800420692d:	0f 8f 24 ff ff ff    	jg     8004206857 <dwarf_get_fde_info_for_all_regs+0x18f>
                reg_table->rules[i].dw_regnum = rt->rt3_rules[i].dw_regnum;
                reg_table->rules[i].dw_offset =
                    rt->rt3_rules[i].dw_offset_or_block_len;
        }

        *row_pc = pc;
  8004206933:	48 8b 55 e0          	mov    -0x20(%rbp),%rdx
  8004206937:	48 8b 45 c0          	mov    -0x40(%rbp),%rax
  800420693b:	48 89 10             	mov    %rdx,(%rax)

        return (DW_DLV_OK);
  800420693e:	b8 00 00 00 00       	mov    $0x0,%eax
}
  8004206943:	c9                   	leaveq 
  8004206944:	c3                   	retq   

0000008004206945 <_dwarf_frame_read_lsb_encoded>:

static int
_dwarf_frame_read_lsb_encoded(Dwarf_Debug dbg, uint64_t *val, uint8_t *data,
    uint64_t *offsetp, uint8_t encode, Dwarf_Addr pc, Dwarf_Error *error)
{
  8004206945:	55                   	push   %rbp
  8004206946:	48 89 e5             	mov    %rsp,%rbp
  8004206949:	48 83 ec 40          	sub    $0x40,%rsp
  800420694d:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
  8004206951:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
  8004206955:	48 89 55 d8          	mov    %rdx,-0x28(%rbp)
  8004206959:	48 89 4d d0          	mov    %rcx,-0x30(%rbp)
  800420695d:	44 89 c0             	mov    %r8d,%eax
  8004206960:	4c 89 4d c0          	mov    %r9,-0x40(%rbp)
  8004206964:	88 45 cc             	mov    %al,-0x34(%rbp)
	uint8_t application;

	if (encode == DW_EH_PE_omit)
  8004206967:	80 7d cc ff          	cmpb   $0xff,-0x34(%rbp)
  800420696b:	75 0a                	jne    8004206977 <_dwarf_frame_read_lsb_encoded+0x32>
		return (DW_DLE_NONE);
  800420696d:	b8 00 00 00 00       	mov    $0x0,%eax
  8004206972:	e9 05 02 00 00       	jmpq   8004206b7c <_dwarf_frame_read_lsb_encoded+0x237>

	application = encode & 0xf0;
  8004206977:	0f b6 45 cc          	movzbl -0x34(%rbp),%eax
  800420697b:	83 e0 f0             	and    $0xfffffff0,%eax
  800420697e:	88 45 ff             	mov    %al,-0x1(%rbp)
	encode &= 0x0f;
  8004206981:	80 65 cc 0f          	andb   $0xf,-0x34(%rbp)

	switch (encode) {
  8004206985:	0f b6 45 cc          	movzbl -0x34(%rbp),%eax
  8004206989:	83 f8 0c             	cmp    $0xc,%eax
  800420698c:	0f 87 91 01 00 00    	ja     8004206b23 <_dwarf_frame_read_lsb_encoded+0x1de>
  8004206992:	89 c0                	mov    %eax,%eax
  8004206994:	48 8d 14 c5 00 00 00 	lea    0x0(,%rax,8),%rdx
  800420699b:	00 
  800420699c:	48 b8 b8 a0 20 04 80 	movabs $0x800420a0b8,%rax
  80042069a3:	00 00 00 
  80042069a6:	48 01 d0             	add    %rdx,%rax
  80042069a9:	48 8b 00             	mov    (%rax),%rax
  80042069ac:	ff e0                	jmpq   *%rax
	case DW_EH_PE_absptr:
		*val = dbg->read(data, offsetp, dbg->dbg_pointer_size);
  80042069ae:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  80042069b2:	4c 8b 40 18          	mov    0x18(%rax),%r8
  80042069b6:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  80042069ba:	8b 50 28             	mov    0x28(%rax),%edx
  80042069bd:	48 8b 4d d0          	mov    -0x30(%rbp),%rcx
  80042069c1:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  80042069c5:	48 89 ce             	mov    %rcx,%rsi
  80042069c8:	48 89 c7             	mov    %rax,%rdi
  80042069cb:	41 ff d0             	callq  *%r8
  80042069ce:	48 8b 55 e0          	mov    -0x20(%rbp),%rdx
  80042069d2:	48 89 02             	mov    %rax,(%rdx)
		break;
  80042069d5:	e9 50 01 00 00       	jmpq   8004206b2a <_dwarf_frame_read_lsb_encoded+0x1e5>
	case DW_EH_PE_uleb128:
		*val = _dwarf_read_uleb128(data, offsetp);
  80042069da:	48 8b 55 d0          	mov    -0x30(%rbp),%rdx
  80042069de:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  80042069e2:	48 89 d6             	mov    %rdx,%rsi
  80042069e5:	48 89 c7             	mov    %rax,%rdi
  80042069e8:	48 b8 68 39 20 04 80 	movabs $0x8004203968,%rax
  80042069ef:	00 00 00 
  80042069f2:	ff d0                	callq  *%rax
  80042069f4:	48 8b 55 e0          	mov    -0x20(%rbp),%rdx
  80042069f8:	48 89 02             	mov    %rax,(%rdx)
		break;
  80042069fb:	e9 2a 01 00 00       	jmpq   8004206b2a <_dwarf_frame_read_lsb_encoded+0x1e5>
	case DW_EH_PE_udata2:
		*val = dbg->read(data, offsetp, 2);
  8004206a00:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004206a04:	4c 8b 40 18          	mov    0x18(%rax),%r8
  8004206a08:	48 8b 4d d0          	mov    -0x30(%rbp),%rcx
  8004206a0c:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  8004206a10:	ba 02 00 00 00       	mov    $0x2,%edx
  8004206a15:	48 89 ce             	mov    %rcx,%rsi
  8004206a18:	48 89 c7             	mov    %rax,%rdi
  8004206a1b:	41 ff d0             	callq  *%r8
  8004206a1e:	48 8b 55 e0          	mov    -0x20(%rbp),%rdx
  8004206a22:	48 89 02             	mov    %rax,(%rdx)
		break;
  8004206a25:	e9 00 01 00 00       	jmpq   8004206b2a <_dwarf_frame_read_lsb_encoded+0x1e5>
	case DW_EH_PE_udata4:
		*val = dbg->read(data, offsetp, 4);
  8004206a2a:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004206a2e:	4c 8b 40 18          	mov    0x18(%rax),%r8
  8004206a32:	48 8b 4d d0          	mov    -0x30(%rbp),%rcx
  8004206a36:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  8004206a3a:	ba 04 00 00 00       	mov    $0x4,%edx
  8004206a3f:	48 89 ce             	mov    %rcx,%rsi
  8004206a42:	48 89 c7             	mov    %rax,%rdi
  8004206a45:	41 ff d0             	callq  *%r8
  8004206a48:	48 8b 55 e0          	mov    -0x20(%rbp),%rdx
  8004206a4c:	48 89 02             	mov    %rax,(%rdx)
		break;
  8004206a4f:	e9 d6 00 00 00       	jmpq   8004206b2a <_dwarf_frame_read_lsb_encoded+0x1e5>
	case DW_EH_PE_udata8:
		*val = dbg->read(data, offsetp, 8);
  8004206a54:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004206a58:	4c 8b 40 18          	mov    0x18(%rax),%r8
  8004206a5c:	48 8b 4d d0          	mov    -0x30(%rbp),%rcx
  8004206a60:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  8004206a64:	ba 08 00 00 00       	mov    $0x8,%edx
  8004206a69:	48 89 ce             	mov    %rcx,%rsi
  8004206a6c:	48 89 c7             	mov    %rax,%rdi
  8004206a6f:	41 ff d0             	callq  *%r8
  8004206a72:	48 8b 55 e0          	mov    -0x20(%rbp),%rdx
  8004206a76:	48 89 02             	mov    %rax,(%rdx)
		break;
  8004206a79:	e9 ac 00 00 00       	jmpq   8004206b2a <_dwarf_frame_read_lsb_encoded+0x1e5>
	case DW_EH_PE_sleb128:
		*val = _dwarf_read_sleb128(data, offsetp);
  8004206a7e:	48 8b 55 d0          	mov    -0x30(%rbp),%rdx
  8004206a82:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  8004206a86:	48 89 d6             	mov    %rdx,%rsi
  8004206a89:	48 89 c7             	mov    %rax,%rdi
  8004206a8c:	48 b8 c0 38 20 04 80 	movabs $0x80042038c0,%rax
  8004206a93:	00 00 00 
  8004206a96:	ff d0                	callq  *%rax
  8004206a98:	48 89 c2             	mov    %rax,%rdx
  8004206a9b:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  8004206a9f:	48 89 10             	mov    %rdx,(%rax)
		break;
  8004206aa2:	e9 83 00 00 00       	jmpq   8004206b2a <_dwarf_frame_read_lsb_encoded+0x1e5>
	case DW_EH_PE_sdata2:
		*val = (int16_t) dbg->read(data, offsetp, 2);
  8004206aa7:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004206aab:	4c 8b 40 18          	mov    0x18(%rax),%r8
  8004206aaf:	48 8b 4d d0          	mov    -0x30(%rbp),%rcx
  8004206ab3:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  8004206ab7:	ba 02 00 00 00       	mov    $0x2,%edx
  8004206abc:	48 89 ce             	mov    %rcx,%rsi
  8004206abf:	48 89 c7             	mov    %rax,%rdi
  8004206ac2:	41 ff d0             	callq  *%r8
  8004206ac5:	48 0f bf d0          	movswq %ax,%rdx
  8004206ac9:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  8004206acd:	48 89 10             	mov    %rdx,(%rax)
		break;
  8004206ad0:	eb 58                	jmp    8004206b2a <_dwarf_frame_read_lsb_encoded+0x1e5>
	case DW_EH_PE_sdata4:
		*val = (int32_t) dbg->read(data, offsetp, 4);
  8004206ad2:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004206ad6:	4c 8b 40 18          	mov    0x18(%rax),%r8
  8004206ada:	48 8b 4d d0          	mov    -0x30(%rbp),%rcx
  8004206ade:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  8004206ae2:	ba 04 00 00 00       	mov    $0x4,%edx
  8004206ae7:	48 89 ce             	mov    %rcx,%rsi
  8004206aea:	48 89 c7             	mov    %rax,%rdi
  8004206aed:	41 ff d0             	callq  *%r8
  8004206af0:	48 63 d0             	movslq %eax,%rdx
  8004206af3:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  8004206af7:	48 89 10             	mov    %rdx,(%rax)
		break;
  8004206afa:	eb 2e                	jmp    8004206b2a <_dwarf_frame_read_lsb_encoded+0x1e5>
	case DW_EH_PE_sdata8:
		*val = dbg->read(data, offsetp, 8);
  8004206afc:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004206b00:	4c 8b 40 18          	mov    0x18(%rax),%r8
  8004206b04:	48 8b 4d d0          	mov    -0x30(%rbp),%rcx
  8004206b08:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  8004206b0c:	ba 08 00 00 00       	mov    $0x8,%edx
  8004206b11:	48 89 ce             	mov    %rcx,%rsi
  8004206b14:	48 89 c7             	mov    %rax,%rdi
  8004206b17:	41 ff d0             	callq  *%r8
  8004206b1a:	48 8b 55 e0          	mov    -0x20(%rbp),%rdx
  8004206b1e:	48 89 02             	mov    %rax,(%rdx)
		break;
  8004206b21:	eb 07                	jmp    8004206b2a <_dwarf_frame_read_lsb_encoded+0x1e5>
	default:
		DWARF_SET_ERROR(dbg, error, DW_DLE_FRAME_AUGMENTATION_UNKNOWN);
		return (DW_DLE_FRAME_AUGMENTATION_UNKNOWN);
  8004206b23:	b8 14 00 00 00       	mov    $0x14,%eax
  8004206b28:	eb 52                	jmp    8004206b7c <_dwarf_frame_read_lsb_encoded+0x237>
	}

	if (application == DW_EH_PE_pcrel) {
  8004206b2a:	80 7d ff 10          	cmpb   $0x10,-0x1(%rbp)
  8004206b2e:	75 47                	jne    8004206b77 <_dwarf_frame_read_lsb_encoded+0x232>
		/*
		 * Value is relative to .eh_frame section virtual addr.
		 */
		switch (encode) {
  8004206b30:	0f b6 45 cc          	movzbl -0x34(%rbp),%eax
  8004206b34:	83 f8 01             	cmp    $0x1,%eax
  8004206b37:	7c 3d                	jl     8004206b76 <_dwarf_frame_read_lsb_encoded+0x231>
  8004206b39:	83 f8 04             	cmp    $0x4,%eax
  8004206b3c:	7e 0a                	jle    8004206b48 <_dwarf_frame_read_lsb_encoded+0x203>
  8004206b3e:	83 e8 09             	sub    $0x9,%eax
  8004206b41:	83 f8 03             	cmp    $0x3,%eax
  8004206b44:	77 30                	ja     8004206b76 <_dwarf_frame_read_lsb_encoded+0x231>
  8004206b46:	eb 17                	jmp    8004206b5f <_dwarf_frame_read_lsb_encoded+0x21a>
		case DW_EH_PE_uleb128:
		case DW_EH_PE_udata2:
		case DW_EH_PE_udata4:
		case DW_EH_PE_udata8:
			*val += pc;
  8004206b48:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  8004206b4c:	48 8b 00             	mov    (%rax),%rax
  8004206b4f:	48 89 c2             	mov    %rax,%rdx
  8004206b52:	48 03 55 c0          	add    -0x40(%rbp),%rdx
  8004206b56:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  8004206b5a:	48 89 10             	mov    %rdx,(%rax)
			break;
  8004206b5d:	eb 18                	jmp    8004206b77 <_dwarf_frame_read_lsb_encoded+0x232>
		case DW_EH_PE_sleb128:
		case DW_EH_PE_sdata2:
		case DW_EH_PE_sdata4:
		case DW_EH_PE_sdata8:
			*val = pc + (int64_t) *val;
  8004206b5f:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  8004206b63:	48 8b 00             	mov    (%rax),%rax
  8004206b66:	48 89 c2             	mov    %rax,%rdx
  8004206b69:	48 03 55 c0          	add    -0x40(%rbp),%rdx
  8004206b6d:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  8004206b71:	48 89 10             	mov    %rdx,(%rax)
			break;
  8004206b74:	eb 01                	jmp    8004206b77 <_dwarf_frame_read_lsb_encoded+0x232>
		default:
			/* DW_EH_PE_absptr is absolute value. */
			break;
  8004206b76:	90                   	nop
		}
	}

	/* XXX Applications other than DW_EH_PE_pcrel are not handled. */

	return (DW_DLE_NONE);
  8004206b77:	b8 00 00 00 00       	mov    $0x0,%eax
}
  8004206b7c:	c9                   	leaveq 
  8004206b7d:	c3                   	retq   

0000008004206b7e <_dwarf_frame_parse_lsb_cie_augment>:

static int
_dwarf_frame_parse_lsb_cie_augment(Dwarf_Debug dbg, Dwarf_Cie cie,
    Dwarf_Error *error)
{
  8004206b7e:	55                   	push   %rbp
  8004206b7f:	48 89 e5             	mov    %rsp,%rbp
  8004206b82:	48 83 ec 60          	sub    $0x60,%rsp
  8004206b86:	48 89 7d c8          	mov    %rdi,-0x38(%rbp)
  8004206b8a:	48 89 75 c0          	mov    %rsi,-0x40(%rbp)
  8004206b8e:	48 89 55 b8          	mov    %rdx,-0x48(%rbp)
	uint8_t *aug_p, *augdata_p;
	uint64_t val, offset;
	uint8_t encode;
	int ret;

	assert(cie->cie_augment != NULL && *cie->cie_augment == 'z');
  8004206b92:	48 8b 45 c0          	mov    -0x40(%rbp),%rax
  8004206b96:	48 8b 40 28          	mov    0x28(%rax),%rax
  8004206b9a:	48 85 c0             	test   %rax,%rax
  8004206b9d:	74 0f                	je     8004206bae <_dwarf_frame_parse_lsb_cie_augment+0x30>
  8004206b9f:	48 8b 45 c0          	mov    -0x40(%rbp),%rax
  8004206ba3:	48 8b 40 28          	mov    0x28(%rax),%rax
  8004206ba7:	0f b6 00             	movzbl (%rax),%eax
  8004206baa:	3c 7a                	cmp    $0x7a,%al
  8004206bac:	74 35                	je     8004206be3 <_dwarf_frame_parse_lsb_cie_augment+0x65>
  8004206bae:	48 b9 20 a1 20 04 80 	movabs $0x800420a120,%rcx
  8004206bb5:	00 00 00 
  8004206bb8:	48 ba 77 9f 20 04 80 	movabs $0x8004209f77,%rdx
  8004206bbf:	00 00 00 
  8004206bc2:	be c0 02 00 00       	mov    $0x2c0,%esi
  8004206bc7:	48 bf 8c 9f 20 04 80 	movabs $0x8004209f8c,%rdi
  8004206bce:	00 00 00 
  8004206bd1:	b8 00 00 00 00       	mov    $0x0,%eax
  8004206bd6:	49 b8 9b 01 20 04 80 	movabs $0x800420019b,%r8
  8004206bdd:	00 00 00 
  8004206be0:	41 ff d0             	callq  *%r8
	/*
	 * Here we're only interested in the presence of augment 'R'
	 * and associated CIE augment data, which describes the
	 * encoding scheme of FDE PC begin and range.
	 */
	aug_p = &cie->cie_augment[1];
  8004206be3:	48 8b 45 c0          	mov    -0x40(%rbp),%rax
  8004206be7:	48 8b 40 28          	mov    0x28(%rax),%rax
  8004206beb:	48 83 c0 01          	add    $0x1,%rax
  8004206bef:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
	augdata_p = cie->cie_augdata;
  8004206bf3:	48 8b 45 c0          	mov    -0x40(%rbp),%rax
  8004206bf7:	48 8b 40 58          	mov    0x58(%rax),%rax
  8004206bfb:	48 89 45 f0          	mov    %rax,-0x10(%rbp)
	while (*aug_p != '\0') {
  8004206bff:	e9 a2 00 00 00       	jmpq   8004206ca6 <_dwarf_frame_parse_lsb_cie_augment+0x128>
		switch (*aug_p) {
  8004206c04:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8004206c08:	0f b6 00             	movzbl (%rax),%eax
  8004206c0b:	0f b6 c0             	movzbl %al,%eax
  8004206c0e:	83 f8 50             	cmp    $0x50,%eax
  8004206c11:	74 11                	je     8004206c24 <_dwarf_frame_parse_lsb_cie_augment+0xa6>
  8004206c13:	83 f8 52             	cmp    $0x52,%eax
  8004206c16:	74 6d                	je     8004206c85 <_dwarf_frame_parse_lsb_cie_augment+0x107>
  8004206c18:	83 f8 4c             	cmp    $0x4c,%eax
  8004206c1b:	75 7d                	jne    8004206c9a <_dwarf_frame_parse_lsb_cie_augment+0x11c>
		case 'L':
			/* Skip one augment in augment data. */
			augdata_p++;
  8004206c1d:	48 83 45 f0 01       	addq   $0x1,-0x10(%rbp)
			break;
  8004206c22:	eb 7d                	jmp    8004206ca1 <_dwarf_frame_parse_lsb_cie_augment+0x123>
		case 'P':
			/* Skip two augments in augment data. */
			encode = *augdata_p++;
  8004206c24:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8004206c28:	0f b6 00             	movzbl (%rax),%eax
  8004206c2b:	88 45 ef             	mov    %al,-0x11(%rbp)
  8004206c2e:	48 83 45 f0 01       	addq   $0x1,-0x10(%rbp)
			offset = 0;
  8004206c33:	48 c7 45 d8 00 00 00 	movq   $0x0,-0x28(%rbp)
  8004206c3a:	00 
			ret = _dwarf_frame_read_lsb_encoded(dbg, &val,
  8004206c3b:	44 0f b6 45 ef       	movzbl -0x11(%rbp),%r8d
  8004206c40:	48 8d 4d d8          	lea    -0x28(%rbp),%rcx
  8004206c44:	48 8b 55 f0          	mov    -0x10(%rbp),%rdx
  8004206c48:	48 8d 75 e0          	lea    -0x20(%rbp),%rsi
  8004206c4c:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
  8004206c50:	48 8b 7d b8          	mov    -0x48(%rbp),%rdi
  8004206c54:	48 89 3c 24          	mov    %rdi,(%rsp)
  8004206c58:	41 b9 00 00 00 00    	mov    $0x0,%r9d
  8004206c5e:	48 89 c7             	mov    %rax,%rdi
  8004206c61:	48 b8 45 69 20 04 80 	movabs $0x8004206945,%rax
  8004206c68:	00 00 00 
  8004206c6b:	ff d0                	callq  *%rax
  8004206c6d:	89 45 e8             	mov    %eax,-0x18(%rbp)
			    augdata_p, &offset, encode, 0, error);
			if (ret != DW_DLE_NONE)
  8004206c70:	83 7d e8 00          	cmpl   $0x0,-0x18(%rbp)
  8004206c74:	74 05                	je     8004206c7b <_dwarf_frame_parse_lsb_cie_augment+0xfd>
				return (ret);
  8004206c76:	8b 45 e8             	mov    -0x18(%rbp),%eax
  8004206c79:	eb 3f                	jmp    8004206cba <_dwarf_frame_parse_lsb_cie_augment+0x13c>
			augdata_p += offset;
  8004206c7b:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  8004206c7f:	48 01 45 f0          	add    %rax,-0x10(%rbp)
			break;
  8004206c83:	eb 1c                	jmp    8004206ca1 <_dwarf_frame_parse_lsb_cie_augment+0x123>
		case 'R':
			cie->cie_fde_encode = *augdata_p++;
  8004206c85:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8004206c89:	0f b6 10             	movzbl (%rax),%edx
  8004206c8c:	48 8b 45 c0          	mov    -0x40(%rbp),%rax
  8004206c90:	88 50 60             	mov    %dl,0x60(%rax)
  8004206c93:	48 83 45 f0 01       	addq   $0x1,-0x10(%rbp)
			break;
  8004206c98:	eb 07                	jmp    8004206ca1 <_dwarf_frame_parse_lsb_cie_augment+0x123>
		default:
			DWARF_SET_ERROR(dbg, error,
			    DW_DLE_FRAME_AUGMENTATION_UNKNOWN);
			return (DW_DLE_FRAME_AUGMENTATION_UNKNOWN);
  8004206c9a:	b8 14 00 00 00       	mov    $0x14,%eax
  8004206c9f:	eb 19                	jmp    8004206cba <_dwarf_frame_parse_lsb_cie_augment+0x13c>
		}
		aug_p++;
  8004206ca1:	48 83 45 f8 01       	addq   $0x1,-0x8(%rbp)
	 * and associated CIE augment data, which describes the
	 * encoding scheme of FDE PC begin and range.
	 */
	aug_p = &cie->cie_augment[1];
	augdata_p = cie->cie_augdata;
	while (*aug_p != '\0') {
  8004206ca6:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8004206caa:	0f b6 00             	movzbl (%rax),%eax
  8004206cad:	84 c0                	test   %al,%al
  8004206caf:	0f 85 4f ff ff ff    	jne    8004206c04 <_dwarf_frame_parse_lsb_cie_augment+0x86>
			return (DW_DLE_FRAME_AUGMENTATION_UNKNOWN);
		}
		aug_p++;
	}

	return (DW_DLE_NONE);
  8004206cb5:	b8 00 00 00 00       	mov    $0x0,%eax
}
  8004206cba:	c9                   	leaveq 
  8004206cbb:	c3                   	retq   

0000008004206cbc <_dwarf_frame_set_cie>:


static int
_dwarf_frame_set_cie(Dwarf_Debug dbg, Dwarf_Section *ds,
    Dwarf_Unsigned *off, Dwarf_Cie ret_cie, Dwarf_Error *error)
{
  8004206cbc:	55                   	push   %rbp
  8004206cbd:	48 89 e5             	mov    %rsp,%rbp
  8004206cc0:	48 83 ec 60          	sub    $0x60,%rsp
  8004206cc4:	48 89 7d c8          	mov    %rdi,-0x38(%rbp)
  8004206cc8:	48 89 75 c0          	mov    %rsi,-0x40(%rbp)
  8004206ccc:	48 89 55 b8          	mov    %rdx,-0x48(%rbp)
  8004206cd0:	48 89 4d b0          	mov    %rcx,-0x50(%rbp)
  8004206cd4:	4c 89 45 a8          	mov    %r8,-0x58(%rbp)
	Dwarf_Cie cie;
	uint64_t length;
	int dwarf_size, ret;
	char *p;

	assert(ret_cie);
  8004206cd8:	48 83 7d b0 00       	cmpq   $0x0,-0x50(%rbp)
  8004206cdd:	75 35                	jne    8004206d14 <_dwarf_frame_set_cie+0x58>
  8004206cdf:	48 b9 55 a1 20 04 80 	movabs $0x800420a155,%rcx
  8004206ce6:	00 00 00 
  8004206ce9:	48 ba 77 9f 20 04 80 	movabs $0x8004209f77,%rdx
  8004206cf0:	00 00 00 
  8004206cf3:	be f1 02 00 00       	mov    $0x2f1,%esi
  8004206cf8:	48 bf 8c 9f 20 04 80 	movabs $0x8004209f8c,%rdi
  8004206cff:	00 00 00 
  8004206d02:	b8 00 00 00 00       	mov    $0x0,%eax
  8004206d07:	49 b8 9b 01 20 04 80 	movabs $0x800420019b,%r8
  8004206d0e:	00 00 00 
  8004206d11:	41 ff d0             	callq  *%r8
	cie = ret_cie;
  8004206d14:	48 8b 45 b0          	mov    -0x50(%rbp),%rax
  8004206d18:	48 89 45 e8          	mov    %rax,-0x18(%rbp)

	cie->cie_dbg = dbg;
  8004206d1c:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004206d20:	48 8b 55 c8          	mov    -0x38(%rbp),%rdx
  8004206d24:	48 89 10             	mov    %rdx,(%rax)
	cie->cie_offset = *off;
  8004206d27:	48 8b 45 b8          	mov    -0x48(%rbp),%rax
  8004206d2b:	48 8b 10             	mov    (%rax),%rdx
  8004206d2e:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004206d32:	48 89 50 10          	mov    %rdx,0x10(%rax)

	length = dbg->read(ds->ds_data, off, 4);
  8004206d36:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
  8004206d3a:	4c 8b 40 18          	mov    0x18(%rax),%r8
  8004206d3e:	48 8b 45 c0          	mov    -0x40(%rbp),%rax
  8004206d42:	48 8b 40 08          	mov    0x8(%rax),%rax
  8004206d46:	48 8b 4d b8          	mov    -0x48(%rbp),%rcx
  8004206d4a:	ba 04 00 00 00       	mov    $0x4,%edx
  8004206d4f:	48 89 ce             	mov    %rcx,%rsi
  8004206d52:	48 89 c7             	mov    %rax,%rdi
  8004206d55:	41 ff d0             	callq  *%r8
  8004206d58:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
	if (length == 0xffffffff) {
  8004206d5c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  8004206d61:	48 39 45 f8          	cmp    %rax,-0x8(%rbp)
  8004206d65:	75 2f                	jne    8004206d96 <_dwarf_frame_set_cie+0xda>
		dwarf_size = 8;
  8004206d67:	c7 45 f4 08 00 00 00 	movl   $0x8,-0xc(%rbp)
		length = dbg->read(ds->ds_data, off, 8);
  8004206d6e:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
  8004206d72:	4c 8b 40 18          	mov    0x18(%rax),%r8
  8004206d76:	48 8b 45 c0          	mov    -0x40(%rbp),%rax
  8004206d7a:	48 8b 40 08          	mov    0x8(%rax),%rax
  8004206d7e:	48 8b 4d b8          	mov    -0x48(%rbp),%rcx
  8004206d82:	ba 08 00 00 00       	mov    $0x8,%edx
  8004206d87:	48 89 ce             	mov    %rcx,%rsi
  8004206d8a:	48 89 c7             	mov    %rax,%rdi
  8004206d8d:	41 ff d0             	callq  *%r8
  8004206d90:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
  8004206d94:	eb 07                	jmp    8004206d9d <_dwarf_frame_set_cie+0xe1>
	} else
		dwarf_size = 4;
  8004206d96:	c7 45 f4 04 00 00 00 	movl   $0x4,-0xc(%rbp)

	if (length > ds->ds_size - *off) {
  8004206d9d:	48 8b 45 c0          	mov    -0x40(%rbp),%rax
  8004206da1:	48 8b 50 18          	mov    0x18(%rax),%rdx
  8004206da5:	48 8b 45 b8          	mov    -0x48(%rbp),%rax
  8004206da9:	48 8b 00             	mov    (%rax),%rax
  8004206dac:	48 89 d1             	mov    %rdx,%rcx
  8004206daf:	48 29 c1             	sub    %rax,%rcx
  8004206db2:	48 89 c8             	mov    %rcx,%rax
  8004206db5:	48 3b 45 f8          	cmp    -0x8(%rbp),%rax
  8004206db9:	73 0a                	jae    8004206dc5 <_dwarf_frame_set_cie+0x109>
		DWARF_SET_ERROR(dbg, error, DW_DLE_DEBUG_FRAME_LENGTH_BAD);
		return (DW_DLE_DEBUG_FRAME_LENGTH_BAD);
  8004206dbb:	b8 12 00 00 00       	mov    $0x12,%eax
  8004206dc0:	e9 66 03 00 00       	jmpq   800420712b <_dwarf_frame_set_cie+0x46f>
	}

	(void) dbg->read(ds->ds_data, off, dwarf_size); /* Skip CIE id. */
  8004206dc5:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
  8004206dc9:	4c 8b 40 18          	mov    0x18(%rax),%r8
  8004206dcd:	48 8b 45 c0          	mov    -0x40(%rbp),%rax
  8004206dd1:	48 8b 40 08          	mov    0x8(%rax),%rax
  8004206dd5:	8b 55 f4             	mov    -0xc(%rbp),%edx
  8004206dd8:	48 8b 4d b8          	mov    -0x48(%rbp),%rcx
  8004206ddc:	48 89 ce             	mov    %rcx,%rsi
  8004206ddf:	48 89 c7             	mov    %rax,%rdi
  8004206de2:	41 ff d0             	callq  *%r8
	cie->cie_length = length;
  8004206de5:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004206de9:	48 8b 55 f8          	mov    -0x8(%rbp),%rdx
  8004206ded:	48 89 50 18          	mov    %rdx,0x18(%rax)

	cie->cie_version = dbg->read(ds->ds_data, off, 1);
  8004206df1:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
  8004206df5:	4c 8b 40 18          	mov    0x18(%rax),%r8
  8004206df9:	48 8b 45 c0          	mov    -0x40(%rbp),%rax
  8004206dfd:	48 8b 40 08          	mov    0x8(%rax),%rax
  8004206e01:	48 8b 4d b8          	mov    -0x48(%rbp),%rcx
  8004206e05:	ba 01 00 00 00       	mov    $0x1,%edx
  8004206e0a:	48 89 ce             	mov    %rcx,%rsi
  8004206e0d:	48 89 c7             	mov    %rax,%rdi
  8004206e10:	41 ff d0             	callq  *%r8
  8004206e13:	89 c2                	mov    %eax,%edx
  8004206e15:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004206e19:	66 89 50 20          	mov    %dx,0x20(%rax)
	if (cie->cie_version != 1 && cie->cie_version != 3 &&
  8004206e1d:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004206e21:	0f b7 40 20          	movzwl 0x20(%rax),%eax
  8004206e25:	66 83 f8 01          	cmp    $0x1,%ax
  8004206e29:	74 26                	je     8004206e51 <_dwarf_frame_set_cie+0x195>
  8004206e2b:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004206e2f:	0f b7 40 20          	movzwl 0x20(%rax),%eax
  8004206e33:	66 83 f8 03          	cmp    $0x3,%ax
  8004206e37:	74 18                	je     8004206e51 <_dwarf_frame_set_cie+0x195>
	    cie->cie_version != 4) {
  8004206e39:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004206e3d:	0f b7 40 20          	movzwl 0x20(%rax),%eax

	(void) dbg->read(ds->ds_data, off, dwarf_size); /* Skip CIE id. */
	cie->cie_length = length;

	cie->cie_version = dbg->read(ds->ds_data, off, 1);
	if (cie->cie_version != 1 && cie->cie_version != 3 &&
  8004206e41:	66 83 f8 04          	cmp    $0x4,%ax
  8004206e45:	74 0a                	je     8004206e51 <_dwarf_frame_set_cie+0x195>
	    cie->cie_version != 4) {
		DWARF_SET_ERROR(dbg, error, DW_DLE_FRAME_VERSION_BAD);
		return (DW_DLE_FRAME_VERSION_BAD);
  8004206e47:	b8 16 00 00 00       	mov    $0x16,%eax
  8004206e4c:	e9 da 02 00 00       	jmpq   800420712b <_dwarf_frame_set_cie+0x46f>
	}

	cie->cie_augment = ds->ds_data + *off;
  8004206e51:	48 8b 45 c0          	mov    -0x40(%rbp),%rax
  8004206e55:	48 8b 50 08          	mov    0x8(%rax),%rdx
  8004206e59:	48 8b 45 b8          	mov    -0x48(%rbp),%rax
  8004206e5d:	48 8b 00             	mov    (%rax),%rax
  8004206e60:	48 01 c2             	add    %rax,%rdx
  8004206e63:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004206e67:	48 89 50 28          	mov    %rdx,0x28(%rax)
	p = (char *) ds->ds_data;
  8004206e6b:	48 8b 45 c0          	mov    -0x40(%rbp),%rax
  8004206e6f:	48 8b 40 08          	mov    0x8(%rax),%rax
  8004206e73:	48 89 45 e0          	mov    %rax,-0x20(%rbp)
	while (p[(*off)++] != '\0')
  8004206e77:	90                   	nop
  8004206e78:	48 8b 45 b8          	mov    -0x48(%rbp),%rax
  8004206e7c:	48 8b 00             	mov    (%rax),%rax
  8004206e7f:	48 89 c2             	mov    %rax,%rdx
  8004206e82:	48 03 55 e0          	add    -0x20(%rbp),%rdx
  8004206e86:	0f b6 12             	movzbl (%rdx),%edx
  8004206e89:	84 d2                	test   %dl,%dl
  8004206e8b:	0f 95 c2             	setne  %dl
  8004206e8e:	48 8d 48 01          	lea    0x1(%rax),%rcx
  8004206e92:	48 8b 45 b8          	mov    -0x48(%rbp),%rax
  8004206e96:	48 89 08             	mov    %rcx,(%rax)
  8004206e99:	84 d2                	test   %dl,%dl
  8004206e9b:	75 db                	jne    8004206e78 <_dwarf_frame_set_cie+0x1bc>
		;

	/* We only recognize normal .dwarf_frame and GNU .eh_frame sections. */
	if (*cie->cie_augment != 0 && *cie->cie_augment != 'z') {
  8004206e9d:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004206ea1:	48 8b 40 28          	mov    0x28(%rax),%rax
  8004206ea5:	0f b6 00             	movzbl (%rax),%eax
  8004206ea8:	84 c0                	test   %al,%al
  8004206eaa:	74 48                	je     8004206ef4 <_dwarf_frame_set_cie+0x238>
  8004206eac:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004206eb0:	48 8b 40 28          	mov    0x28(%rax),%rax
  8004206eb4:	0f b6 00             	movzbl (%rax),%eax
  8004206eb7:	3c 7a                	cmp    $0x7a,%al
  8004206eb9:	74 39                	je     8004206ef4 <_dwarf_frame_set_cie+0x238>
		*off = cie->cie_offset + ((dwarf_size == 4) ? 4 : 12) +
  8004206ebb:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004206ebf:	48 8b 50 10          	mov    0x10(%rax),%rdx
  8004206ec3:	83 7d f4 04          	cmpl   $0x4,-0xc(%rbp)
  8004206ec7:	75 07                	jne    8004206ed0 <_dwarf_frame_set_cie+0x214>
  8004206ec9:	b8 04 00 00 00       	mov    $0x4,%eax
  8004206ece:	eb 05                	jmp    8004206ed5 <_dwarf_frame_set_cie+0x219>
  8004206ed0:	b8 0c 00 00 00       	mov    $0xc,%eax
  8004206ed5:	48 01 c2             	add    %rax,%rdx
		    cie->cie_length;
  8004206ed8:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004206edc:	48 8b 40 18          	mov    0x18(%rax),%rax
	while (p[(*off)++] != '\0')
		;

	/* We only recognize normal .dwarf_frame and GNU .eh_frame sections. */
	if (*cie->cie_augment != 0 && *cie->cie_augment != 'z') {
		*off = cie->cie_offset + ((dwarf_size == 4) ? 4 : 12) +
  8004206ee0:	48 01 c2             	add    %rax,%rdx
  8004206ee3:	48 8b 45 b8          	mov    -0x48(%rbp),%rax
  8004206ee7:	48 89 10             	mov    %rdx,(%rax)
		    cie->cie_length;
		return (DW_DLE_NONE);
  8004206eea:	b8 00 00 00 00       	mov    $0x0,%eax
  8004206eef:	e9 37 02 00 00       	jmpq   800420712b <_dwarf_frame_set_cie+0x46f>
	}

	/* Optional EH Data field for .eh_frame section. */
	if (strstr((char *)cie->cie_augment, "eh") != NULL)
  8004206ef4:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004206ef8:	48 8b 40 28          	mov    0x28(%rax),%rax
  8004206efc:	48 be 5d a1 20 04 80 	movabs $0x800420a15d,%rsi
  8004206f03:	00 00 00 
  8004206f06:	48 89 c7             	mov    %rax,%rdi
  8004206f09:	48 b8 82 32 20 04 80 	movabs $0x8004203282,%rax
  8004206f10:	00 00 00 
  8004206f13:	ff d0                	callq  *%rax
  8004206f15:	48 85 c0             	test   %rax,%rax
  8004206f18:	74 2c                	je     8004206f46 <_dwarf_frame_set_cie+0x28a>
		cie->cie_ehdata = dbg->read(ds->ds_data, off,
  8004206f1a:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
  8004206f1e:	4c 8b 40 18          	mov    0x18(%rax),%r8
	    dbg->dbg_pointer_size);
  8004206f22:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
		return (DW_DLE_NONE);
	}

	/* Optional EH Data field for .eh_frame section. */
	if (strstr((char *)cie->cie_augment, "eh") != NULL)
		cie->cie_ehdata = dbg->read(ds->ds_data, off,
  8004206f26:	8b 50 28             	mov    0x28(%rax),%edx
  8004206f29:	48 8b 45 c0          	mov    -0x40(%rbp),%rax
  8004206f2d:	48 8b 40 08          	mov    0x8(%rax),%rax
  8004206f31:	48 8b 4d b8          	mov    -0x48(%rbp),%rcx
  8004206f35:	48 89 ce             	mov    %rcx,%rsi
  8004206f38:	48 89 c7             	mov    %rax,%rdi
  8004206f3b:	41 ff d0             	callq  *%r8
  8004206f3e:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  8004206f42:	48 89 42 30          	mov    %rax,0x30(%rdx)
	    dbg->dbg_pointer_size);

	cie->cie_caf = _dwarf_read_uleb128(ds->ds_data, off);
  8004206f46:	48 8b 45 c0          	mov    -0x40(%rbp),%rax
  8004206f4a:	48 8b 40 08          	mov    0x8(%rax),%rax
  8004206f4e:	48 8b 55 b8          	mov    -0x48(%rbp),%rdx
  8004206f52:	48 89 d6             	mov    %rdx,%rsi
  8004206f55:	48 89 c7             	mov    %rax,%rdi
  8004206f58:	48 b8 68 39 20 04 80 	movabs $0x8004203968,%rax
  8004206f5f:	00 00 00 
  8004206f62:	ff d0                	callq  *%rax
  8004206f64:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  8004206f68:	48 89 42 38          	mov    %rax,0x38(%rdx)
	cie->cie_daf = _dwarf_read_sleb128(ds->ds_data, off);
  8004206f6c:	48 8b 45 c0          	mov    -0x40(%rbp),%rax
  8004206f70:	48 8b 40 08          	mov    0x8(%rax),%rax
  8004206f74:	48 8b 55 b8          	mov    -0x48(%rbp),%rdx
  8004206f78:	48 89 d6             	mov    %rdx,%rsi
  8004206f7b:	48 89 c7             	mov    %rax,%rdi
  8004206f7e:	48 b8 c0 38 20 04 80 	movabs $0x80042038c0,%rax
  8004206f85:	00 00 00 
  8004206f88:	ff d0                	callq  *%rax
  8004206f8a:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  8004206f8e:	48 89 42 40          	mov    %rax,0x40(%rdx)

	/* Return address register. */
	if (cie->cie_version == 1)
  8004206f92:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004206f96:	0f b7 40 20          	movzwl 0x20(%rax),%eax
  8004206f9a:	66 83 f8 01          	cmp    $0x1,%ax
  8004206f9e:	75 2c                	jne    8004206fcc <_dwarf_frame_set_cie+0x310>
		cie->cie_ra = dbg->read(ds->ds_data, off, 1);
  8004206fa0:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
  8004206fa4:	4c 8b 40 18          	mov    0x18(%rax),%r8
  8004206fa8:	48 8b 45 c0          	mov    -0x40(%rbp),%rax
  8004206fac:	48 8b 40 08          	mov    0x8(%rax),%rax
  8004206fb0:	48 8b 4d b8          	mov    -0x48(%rbp),%rcx
  8004206fb4:	ba 01 00 00 00       	mov    $0x1,%edx
  8004206fb9:	48 89 ce             	mov    %rcx,%rsi
  8004206fbc:	48 89 c7             	mov    %rax,%rdi
  8004206fbf:	41 ff d0             	callq  *%r8
  8004206fc2:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  8004206fc6:	48 89 42 48          	mov    %rax,0x48(%rdx)
  8004206fca:	eb 26                	jmp    8004206ff2 <_dwarf_frame_set_cie+0x336>
	else
		cie->cie_ra = _dwarf_read_uleb128(ds->ds_data, off);
  8004206fcc:	48 8b 45 c0          	mov    -0x40(%rbp),%rax
  8004206fd0:	48 8b 40 08          	mov    0x8(%rax),%rax
  8004206fd4:	48 8b 55 b8          	mov    -0x48(%rbp),%rdx
  8004206fd8:	48 89 d6             	mov    %rdx,%rsi
  8004206fdb:	48 89 c7             	mov    %rax,%rdi
  8004206fde:	48 b8 68 39 20 04 80 	movabs $0x8004203968,%rax
  8004206fe5:	00 00 00 
  8004206fe8:	ff d0                	callq  *%rax
  8004206fea:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  8004206fee:	48 89 42 48          	mov    %rax,0x48(%rdx)

	/* Optional CIE augmentation data for .eh_frame section. */
	if (*cie->cie_augment == 'z') {
  8004206ff2:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004206ff6:	48 8b 40 28          	mov    0x28(%rax),%rax
  8004206ffa:	0f b6 00             	movzbl (%rax),%eax
  8004206ffd:	3c 7a                	cmp    $0x7a,%al
  8004206fff:	0f 85 90 00 00 00    	jne    8004207095 <_dwarf_frame_set_cie+0x3d9>
		cie->cie_auglen = _dwarf_read_uleb128(ds->ds_data, off);
  8004207005:	48 8b 45 c0          	mov    -0x40(%rbp),%rax
  8004207009:	48 8b 40 08          	mov    0x8(%rax),%rax
  800420700d:	48 8b 55 b8          	mov    -0x48(%rbp),%rdx
  8004207011:	48 89 d6             	mov    %rdx,%rsi
  8004207014:	48 89 c7             	mov    %rax,%rdi
  8004207017:	48 b8 68 39 20 04 80 	movabs $0x8004203968,%rax
  800420701e:	00 00 00 
  8004207021:	ff d0                	callq  *%rax
  8004207023:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  8004207027:	48 89 42 50          	mov    %rax,0x50(%rdx)
		cie->cie_augdata = ds->ds_data + *off;
  800420702b:	48 8b 45 c0          	mov    -0x40(%rbp),%rax
  800420702f:	48 8b 50 08          	mov    0x8(%rax),%rdx
  8004207033:	48 8b 45 b8          	mov    -0x48(%rbp),%rax
  8004207037:	48 8b 00             	mov    (%rax),%rax
  800420703a:	48 01 c2             	add    %rax,%rdx
  800420703d:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004207041:	48 89 50 58          	mov    %rdx,0x58(%rax)
		*off += cie->cie_auglen;
  8004207045:	48 8b 45 b8          	mov    -0x48(%rbp),%rax
  8004207049:	48 8b 10             	mov    (%rax),%rdx
  800420704c:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004207050:	48 8b 40 50          	mov    0x50(%rax),%rax
  8004207054:	48 01 c2             	add    %rax,%rdx
  8004207057:	48 8b 45 b8          	mov    -0x48(%rbp),%rax
  800420705b:	48 89 10             	mov    %rdx,(%rax)
		/*
		 * XXX Use DW_EH_PE_absptr for default FDE PC start/range,
		 * in case _dwarf_frame_parse_lsb_cie_augment fails to
		 * find out the real encode.
		 */
		cie->cie_fde_encode = DW_EH_PE_absptr;
  800420705e:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004207062:	c6 40 60 00          	movb   $0x0,0x60(%rax)
		ret = _dwarf_frame_parse_lsb_cie_augment(dbg, cie, error);
  8004207066:	48 8b 55 a8          	mov    -0x58(%rbp),%rdx
  800420706a:	48 8b 4d e8          	mov    -0x18(%rbp),%rcx
  800420706e:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
  8004207072:	48 89 ce             	mov    %rcx,%rsi
  8004207075:	48 89 c7             	mov    %rax,%rdi
  8004207078:	48 b8 7e 6b 20 04 80 	movabs $0x8004206b7e,%rax
  800420707f:	00 00 00 
  8004207082:	ff d0                	callq  *%rax
  8004207084:	89 45 dc             	mov    %eax,-0x24(%rbp)
		if (ret != DW_DLE_NONE)
  8004207087:	83 7d dc 00          	cmpl   $0x0,-0x24(%rbp)
  800420708b:	74 08                	je     8004207095 <_dwarf_frame_set_cie+0x3d9>
			return (ret);
  800420708d:	8b 45 dc             	mov    -0x24(%rbp),%eax
  8004207090:	e9 96 00 00 00       	jmpq   800420712b <_dwarf_frame_set_cie+0x46f>
	}

	/* CIE Initial instructions. */
	cie->cie_initinst = ds->ds_data + *off;
  8004207095:	48 8b 45 c0          	mov    -0x40(%rbp),%rax
  8004207099:	48 8b 50 08          	mov    0x8(%rax),%rdx
  800420709d:	48 8b 45 b8          	mov    -0x48(%rbp),%rax
  80042070a1:	48 8b 00             	mov    (%rax),%rax
  80042070a4:	48 01 c2             	add    %rax,%rdx
  80042070a7:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  80042070ab:	48 89 50 68          	mov    %rdx,0x68(%rax)
	if (dwarf_size == 4)
  80042070af:	83 7d f4 04          	cmpl   $0x4,-0xc(%rbp)
  80042070b3:	75 2d                	jne    80042070e2 <_dwarf_frame_set_cie+0x426>
		cie->cie_instlen = cie->cie_offset + 4 + length - *off;
  80042070b5:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  80042070b9:	48 8b 40 10          	mov    0x10(%rax),%rax
  80042070bd:	48 89 c2             	mov    %rax,%rdx
  80042070c0:	48 03 55 f8          	add    -0x8(%rbp),%rdx
  80042070c4:	48 8b 45 b8          	mov    -0x48(%rbp),%rax
  80042070c8:	48 8b 00             	mov    (%rax),%rax
  80042070cb:	48 89 d1             	mov    %rdx,%rcx
  80042070ce:	48 29 c1             	sub    %rax,%rcx
  80042070d1:	48 89 c8             	mov    %rcx,%rax
  80042070d4:	48 8d 50 04          	lea    0x4(%rax),%rdx
  80042070d8:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  80042070dc:	48 89 50 70          	mov    %rdx,0x70(%rax)
  80042070e0:	eb 2b                	jmp    800420710d <_dwarf_frame_set_cie+0x451>
	else
		cie->cie_instlen = cie->cie_offset + 12 + length - *off;
  80042070e2:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  80042070e6:	48 8b 40 10          	mov    0x10(%rax),%rax
  80042070ea:	48 89 c2             	mov    %rax,%rdx
  80042070ed:	48 03 55 f8          	add    -0x8(%rbp),%rdx
  80042070f1:	48 8b 45 b8          	mov    -0x48(%rbp),%rax
  80042070f5:	48 8b 00             	mov    (%rax),%rax
  80042070f8:	48 89 d1             	mov    %rdx,%rcx
  80042070fb:	48 29 c1             	sub    %rax,%rcx
  80042070fe:	48 89 c8             	mov    %rcx,%rax
  8004207101:	48 8d 50 0c          	lea    0xc(%rax),%rdx
  8004207105:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004207109:	48 89 50 70          	mov    %rdx,0x70(%rax)

	*off += cie->cie_instlen;
  800420710d:	48 8b 45 b8          	mov    -0x48(%rbp),%rax
  8004207111:	48 8b 10             	mov    (%rax),%rdx
  8004207114:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004207118:	48 8b 40 70          	mov    0x70(%rax),%rax
  800420711c:	48 01 c2             	add    %rax,%rdx
  800420711f:	48 8b 45 b8          	mov    -0x48(%rbp),%rax
  8004207123:	48 89 10             	mov    %rdx,(%rax)
	    cie->cie_daf, *off);

	printf("%x %lx\n", (unsigned int)cie->cie_ra, (unsigned long)cie->cie_initinst);
#endif

	return (DW_DLE_NONE);
  8004207126:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800420712b:	c9                   	leaveq 
  800420712c:	c3                   	retq   

000000800420712d <_dwarf_frame_set_fde>:

static int
_dwarf_frame_set_fde(Dwarf_Debug dbg, Dwarf_Fde retfde, Dwarf_Section *ds,
    Dwarf_Unsigned *off, int eh_frame, Dwarf_Cie cie, Dwarf_Error *error)
{
  800420712d:	55                   	push   %rbp
  800420712e:	48 89 e5             	mov    %rsp,%rbp
  8004207131:	48 83 ec 70          	sub    $0x70,%rsp
  8004207135:	48 89 7d c8          	mov    %rdi,-0x38(%rbp)
  8004207139:	48 89 75 c0          	mov    %rsi,-0x40(%rbp)
  800420713d:	48 89 55 b8          	mov    %rdx,-0x48(%rbp)
  8004207141:	48 89 4d b0          	mov    %rcx,-0x50(%rbp)
  8004207145:	44 89 45 ac          	mov    %r8d,-0x54(%rbp)
  8004207149:	4c 89 4d a0          	mov    %r9,-0x60(%rbp)
	Dwarf_Fde fde;
	Dwarf_Unsigned cieoff;
	uint64_t length, val;
	int dwarf_size, ret;

	fde = retfde;
  800420714d:	48 8b 45 c0          	mov    -0x40(%rbp),%rax
  8004207151:	48 89 45 e8          	mov    %rax,-0x18(%rbp)

	fde->fde_dbg = dbg;
  8004207155:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004207159:	48 8b 55 c8          	mov    -0x38(%rbp),%rdx
  800420715d:	48 89 10             	mov    %rdx,(%rax)
	fde->fde_addr = ds->ds_data + *off;
  8004207160:	48 8b 45 b8          	mov    -0x48(%rbp),%rax
  8004207164:	48 8b 50 08          	mov    0x8(%rax),%rdx
  8004207168:	48 8b 45 b0          	mov    -0x50(%rbp),%rax
  800420716c:	48 8b 00             	mov    (%rax),%rax
  800420716f:	48 01 c2             	add    %rax,%rdx
  8004207172:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004207176:	48 89 50 10          	mov    %rdx,0x10(%rax)
	fde->fde_offset = *off;
  800420717a:	48 8b 45 b0          	mov    -0x50(%rbp),%rax
  800420717e:	48 8b 10             	mov    (%rax),%rdx
  8004207181:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004207185:	48 89 50 18          	mov    %rdx,0x18(%rax)

	length = dbg->read(ds->ds_data, off, 4);
  8004207189:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
  800420718d:	4c 8b 40 18          	mov    0x18(%rax),%r8
  8004207191:	48 8b 45 b8          	mov    -0x48(%rbp),%rax
  8004207195:	48 8b 40 08          	mov    0x8(%rax),%rax
  8004207199:	48 8b 4d b0          	mov    -0x50(%rbp),%rcx
  800420719d:	ba 04 00 00 00       	mov    $0x4,%edx
  80042071a2:	48 89 ce             	mov    %rcx,%rsi
  80042071a5:	48 89 c7             	mov    %rax,%rdi
  80042071a8:	41 ff d0             	callq  *%r8
  80042071ab:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
	if (length == 0xffffffff) {
  80042071af:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  80042071b4:	48 39 45 f8          	cmp    %rax,-0x8(%rbp)
  80042071b8:	75 2f                	jne    80042071e9 <_dwarf_frame_set_fde+0xbc>
		dwarf_size = 8;
  80042071ba:	c7 45 f4 08 00 00 00 	movl   $0x8,-0xc(%rbp)
		length = dbg->read(ds->ds_data, off, 8);
  80042071c1:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
  80042071c5:	4c 8b 40 18          	mov    0x18(%rax),%r8
  80042071c9:	48 8b 45 b8          	mov    -0x48(%rbp),%rax
  80042071cd:	48 8b 40 08          	mov    0x8(%rax),%rax
  80042071d1:	48 8b 4d b0          	mov    -0x50(%rbp),%rcx
  80042071d5:	ba 08 00 00 00       	mov    $0x8,%edx
  80042071da:	48 89 ce             	mov    %rcx,%rsi
  80042071dd:	48 89 c7             	mov    %rax,%rdi
  80042071e0:	41 ff d0             	callq  *%r8
  80042071e3:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
  80042071e7:	eb 07                	jmp    80042071f0 <_dwarf_frame_set_fde+0xc3>
	} else
		dwarf_size = 4;
  80042071e9:	c7 45 f4 04 00 00 00 	movl   $0x4,-0xc(%rbp)

	if (length > ds->ds_size - *off) {
  80042071f0:	48 8b 45 b8          	mov    -0x48(%rbp),%rax
  80042071f4:	48 8b 50 18          	mov    0x18(%rax),%rdx
  80042071f8:	48 8b 45 b0          	mov    -0x50(%rbp),%rax
  80042071fc:	48 8b 00             	mov    (%rax),%rax
  80042071ff:	48 89 d1             	mov    %rdx,%rcx
  8004207202:	48 29 c1             	sub    %rax,%rcx
  8004207205:	48 89 c8             	mov    %rcx,%rax
  8004207208:	48 3b 45 f8          	cmp    -0x8(%rbp),%rax
  800420720c:	73 0a                	jae    8004207218 <_dwarf_frame_set_fde+0xeb>
		DWARF_SET_ERROR(dbg, error, DW_DLE_DEBUG_FRAME_LENGTH_BAD);
		return (DW_DLE_DEBUG_FRAME_LENGTH_BAD);
  800420720e:	b8 12 00 00 00       	mov    $0x12,%eax
  8004207213:	e9 d1 02 00 00       	jmpq   80042074e9 <_dwarf_frame_set_fde+0x3bc>
	}

	fde->fde_length = length;
  8004207218:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  800420721c:	48 8b 55 f8          	mov    -0x8(%rbp),%rdx
  8004207220:	48 89 50 20          	mov    %rdx,0x20(%rax)

	if (eh_frame) {
  8004207224:	83 7d ac 00          	cmpl   $0x0,-0x54(%rbp)
  8004207228:	74 62                	je     800420728c <_dwarf_frame_set_fde+0x15f>
		fde->fde_cieoff = dbg->read(ds->ds_data, off, 4);
  800420722a:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
  800420722e:	4c 8b 40 18          	mov    0x18(%rax),%r8
  8004207232:	48 8b 45 b8          	mov    -0x48(%rbp),%rax
  8004207236:	48 8b 40 08          	mov    0x8(%rax),%rax
  800420723a:	48 8b 4d b0          	mov    -0x50(%rbp),%rcx
  800420723e:	ba 04 00 00 00       	mov    $0x4,%edx
  8004207243:	48 89 ce             	mov    %rcx,%rsi
  8004207246:	48 89 c7             	mov    %rax,%rdi
  8004207249:	41 ff d0             	callq  *%r8
  800420724c:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  8004207250:	48 89 42 28          	mov    %rax,0x28(%rdx)
		cieoff = *off - (4 + fde->fde_cieoff);
  8004207254:	48 8b 45 b0          	mov    -0x50(%rbp),%rax
  8004207258:	48 8b 10             	mov    (%rax),%rdx
  800420725b:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  800420725f:	48 8b 40 28          	mov    0x28(%rax),%rax
  8004207263:	48 89 d1             	mov    %rdx,%rcx
  8004207266:	48 29 c1             	sub    %rax,%rcx
  8004207269:	48 89 c8             	mov    %rcx,%rax
  800420726c:	48 83 e8 04          	sub    $0x4,%rax
  8004207270:	48 89 45 e0          	mov    %rax,-0x20(%rbp)
		/* This delta should never be 0. */
		if (cieoff == fde->fde_offset) {
  8004207274:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004207278:	48 8b 40 18          	mov    0x18(%rax),%rax
  800420727c:	48 3b 45 e0          	cmp    -0x20(%rbp),%rax
  8004207280:	75 3e                	jne    80042072c0 <_dwarf_frame_set_fde+0x193>
			DWARF_SET_ERROR(dbg, error, DW_DLE_NO_CIE_FOR_FDE);
			return (DW_DLE_NO_CIE_FOR_FDE);
  8004207282:	b8 13 00 00 00       	mov    $0x13,%eax
  8004207287:	e9 5d 02 00 00       	jmpq   80042074e9 <_dwarf_frame_set_fde+0x3bc>
		}
	} else {
		fde->fde_cieoff = dbg->read(ds->ds_data, off, dwarf_size);
  800420728c:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
  8004207290:	4c 8b 40 18          	mov    0x18(%rax),%r8
  8004207294:	48 8b 45 b8          	mov    -0x48(%rbp),%rax
  8004207298:	48 8b 40 08          	mov    0x8(%rax),%rax
  800420729c:	8b 55 f4             	mov    -0xc(%rbp),%edx
  800420729f:	48 8b 4d b0          	mov    -0x50(%rbp),%rcx
  80042072a3:	48 89 ce             	mov    %rcx,%rsi
  80042072a6:	48 89 c7             	mov    %rax,%rdi
  80042072a9:	41 ff d0             	callq  *%r8
  80042072ac:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  80042072b0:	48 89 42 28          	mov    %rax,0x28(%rdx)
		cieoff = fde->fde_cieoff;
  80042072b4:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  80042072b8:	48 8b 40 28          	mov    0x28(%rax),%rax
  80042072bc:	48 89 45 e0          	mov    %rax,-0x20(%rbp)
	}

	if (eh_frame) {
  80042072c0:	83 7d ac 00          	cmpl   $0x0,-0x54(%rbp)
  80042072c4:	0f 84 c3 00 00 00    	je     800420738d <_dwarf_frame_set_fde+0x260>
		/*
		 * The FDE PC start/range for .eh_frame is encoded according
		 * to the LSB spec's extension to DWARF2.
		 */
		ret = _dwarf_frame_read_lsb_encoded(dbg, &val, ds->ds_data,
		    off, cie->cie_fde_encode, ds->ds_addr + *off, error);
  80042072ca:	48 8b 45 b8          	mov    -0x48(%rbp),%rax
  80042072ce:	48 8b 50 10          	mov    0x10(%rax),%rdx
  80042072d2:	48 8b 45 b0          	mov    -0x50(%rbp),%rax
  80042072d6:	48 8b 00             	mov    (%rax),%rax
	if (eh_frame) {
		/*
		 * The FDE PC start/range for .eh_frame is encoded according
		 * to the LSB spec's extension to DWARF2.
		 */
		ret = _dwarf_frame_read_lsb_encoded(dbg, &val, ds->ds_data,
  80042072d9:	4c 8d 0c 02          	lea    (%rdx,%rax,1),%r9
		    off, cie->cie_fde_encode, ds->ds_addr + *off, error);
  80042072dd:	48 8b 45 a0          	mov    -0x60(%rbp),%rax
  80042072e1:	0f b6 40 60          	movzbl 0x60(%rax),%eax
	if (eh_frame) {
		/*
		 * The FDE PC start/range for .eh_frame is encoded according
		 * to the LSB spec's extension to DWARF2.
		 */
		ret = _dwarf_frame_read_lsb_encoded(dbg, &val, ds->ds_data,
  80042072e5:	44 0f b6 c0          	movzbl %al,%r8d
  80042072e9:	48 8b 45 b8          	mov    -0x48(%rbp),%rax
  80042072ed:	48 8b 50 08          	mov    0x8(%rax),%rdx
  80042072f1:	48 8b 4d b0          	mov    -0x50(%rbp),%rcx
  80042072f5:	48 8d 75 d0          	lea    -0x30(%rbp),%rsi
  80042072f9:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
  80042072fd:	48 8b 7d 10          	mov    0x10(%rbp),%rdi
  8004207301:	48 89 3c 24          	mov    %rdi,(%rsp)
  8004207305:	48 89 c7             	mov    %rax,%rdi
  8004207308:	48 b8 45 69 20 04 80 	movabs $0x8004206945,%rax
  800420730f:	00 00 00 
  8004207312:	ff d0                	callq  *%rax
  8004207314:	89 45 dc             	mov    %eax,-0x24(%rbp)
		    off, cie->cie_fde_encode, ds->ds_addr + *off, error);
		if (ret != DW_DLE_NONE)
  8004207317:	83 7d dc 00          	cmpl   $0x0,-0x24(%rbp)
  800420731b:	74 08                	je     8004207325 <_dwarf_frame_set_fde+0x1f8>
			return (ret);
  800420731d:	8b 45 dc             	mov    -0x24(%rbp),%eax
  8004207320:	e9 c4 01 00 00       	jmpq   80042074e9 <_dwarf_frame_set_fde+0x3bc>
		fde->fde_initloc = val;
  8004207325:	48 8b 55 d0          	mov    -0x30(%rbp),%rdx
  8004207329:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  800420732d:	48 89 50 30          	mov    %rdx,0x30(%rax)
		/*
		 * FDE PC range should not be relative value to anything.
		 * So pass 0 for pc value.
		 */
		ret = _dwarf_frame_read_lsb_encoded(dbg, &val, ds->ds_data,
		    off, cie->cie_fde_encode, 0, error);
  8004207331:	48 8b 45 a0          	mov    -0x60(%rbp),%rax
  8004207335:	0f b6 40 60          	movzbl 0x60(%rax),%eax
		fde->fde_initloc = val;
		/*
		 * FDE PC range should not be relative value to anything.
		 * So pass 0 for pc value.
		 */
		ret = _dwarf_frame_read_lsb_encoded(dbg, &val, ds->ds_data,
  8004207339:	44 0f b6 c0          	movzbl %al,%r8d
  800420733d:	48 8b 45 b8          	mov    -0x48(%rbp),%rax
  8004207341:	48 8b 50 08          	mov    0x8(%rax),%rdx
  8004207345:	48 8b 4d b0          	mov    -0x50(%rbp),%rcx
  8004207349:	48 8d 75 d0          	lea    -0x30(%rbp),%rsi
  800420734d:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
  8004207351:	48 8b 7d 10          	mov    0x10(%rbp),%rdi
  8004207355:	48 89 3c 24          	mov    %rdi,(%rsp)
  8004207359:	41 b9 00 00 00 00    	mov    $0x0,%r9d
  800420735f:	48 89 c7             	mov    %rax,%rdi
  8004207362:	48 b8 45 69 20 04 80 	movabs $0x8004206945,%rax
  8004207369:	00 00 00 
  800420736c:	ff d0                	callq  *%rax
  800420736e:	89 45 dc             	mov    %eax,-0x24(%rbp)
		    off, cie->cie_fde_encode, 0, error);
		if (ret != DW_DLE_NONE)
  8004207371:	83 7d dc 00          	cmpl   $0x0,-0x24(%rbp)
  8004207375:	74 08                	je     800420737f <_dwarf_frame_set_fde+0x252>
			return (ret);
  8004207377:	8b 45 dc             	mov    -0x24(%rbp),%eax
  800420737a:	e9 6a 01 00 00       	jmpq   80042074e9 <_dwarf_frame_set_fde+0x3bc>
		fde->fde_adrange = val;
  800420737f:	48 8b 55 d0          	mov    -0x30(%rbp),%rdx
  8004207383:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004207387:	48 89 50 38          	mov    %rdx,0x38(%rax)
  800420738b:	eb 58                	jmp    80042073e5 <_dwarf_frame_set_fde+0x2b8>
	} else {
		fde->fde_initloc = dbg->read(ds->ds_data, off,
  800420738d:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
  8004207391:	4c 8b 40 18          	mov    0x18(%rax),%r8
		    dbg->dbg_pointer_size);
  8004207395:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
		    off, cie->cie_fde_encode, 0, error);
		if (ret != DW_DLE_NONE)
			return (ret);
		fde->fde_adrange = val;
	} else {
		fde->fde_initloc = dbg->read(ds->ds_data, off,
  8004207399:	8b 50 28             	mov    0x28(%rax),%edx
  800420739c:	48 8b 45 b8          	mov    -0x48(%rbp),%rax
  80042073a0:	48 8b 40 08          	mov    0x8(%rax),%rax
  80042073a4:	48 8b 4d b0          	mov    -0x50(%rbp),%rcx
  80042073a8:	48 89 ce             	mov    %rcx,%rsi
  80042073ab:	48 89 c7             	mov    %rax,%rdi
  80042073ae:	41 ff d0             	callq  *%r8
  80042073b1:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  80042073b5:	48 89 42 30          	mov    %rax,0x30(%rdx)
		    dbg->dbg_pointer_size);
		fde->fde_adrange = dbg->read(ds->ds_data, off,
  80042073b9:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
  80042073bd:	4c 8b 40 18          	mov    0x18(%rax),%r8
		    dbg->dbg_pointer_size);
  80042073c1:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
			return (ret);
		fde->fde_adrange = val;
	} else {
		fde->fde_initloc = dbg->read(ds->ds_data, off,
		    dbg->dbg_pointer_size);
		fde->fde_adrange = dbg->read(ds->ds_data, off,
  80042073c5:	8b 50 28             	mov    0x28(%rax),%edx
  80042073c8:	48 8b 45 b8          	mov    -0x48(%rbp),%rax
  80042073cc:	48 8b 40 08          	mov    0x8(%rax),%rax
  80042073d0:	48 8b 4d b0          	mov    -0x50(%rbp),%rcx
  80042073d4:	48 89 ce             	mov    %rcx,%rsi
  80042073d7:	48 89 c7             	mov    %rax,%rdi
  80042073da:	41 ff d0             	callq  *%r8
  80042073dd:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  80042073e1:	48 89 42 38          	mov    %rax,0x38(%rdx)
		    dbg->dbg_pointer_size);
	}

	/* Optional FDE augmentation data for .eh_frame section. (ignored) */
	if (eh_frame && *cie->cie_augment == 'z') {
  80042073e5:	83 7d ac 00          	cmpl   $0x0,-0x54(%rbp)
  80042073e9:	74 68                	je     8004207453 <_dwarf_frame_set_fde+0x326>
  80042073eb:	48 8b 45 a0          	mov    -0x60(%rbp),%rax
  80042073ef:	48 8b 40 28          	mov    0x28(%rax),%rax
  80042073f3:	0f b6 00             	movzbl (%rax),%eax
  80042073f6:	3c 7a                	cmp    $0x7a,%al
  80042073f8:	75 59                	jne    8004207453 <_dwarf_frame_set_fde+0x326>
		fde->fde_auglen = _dwarf_read_uleb128(ds->ds_data, off);
  80042073fa:	48 8b 45 b8          	mov    -0x48(%rbp),%rax
  80042073fe:	48 8b 40 08          	mov    0x8(%rax),%rax
  8004207402:	48 8b 55 b0          	mov    -0x50(%rbp),%rdx
  8004207406:	48 89 d6             	mov    %rdx,%rsi
  8004207409:	48 89 c7             	mov    %rax,%rdi
  800420740c:	48 b8 68 39 20 04 80 	movabs $0x8004203968,%rax
  8004207413:	00 00 00 
  8004207416:	ff d0                	callq  *%rax
  8004207418:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  800420741c:	48 89 42 40          	mov    %rax,0x40(%rdx)
		fde->fde_augdata = ds->ds_data + *off;
  8004207420:	48 8b 45 b8          	mov    -0x48(%rbp),%rax
  8004207424:	48 8b 50 08          	mov    0x8(%rax),%rdx
  8004207428:	48 8b 45 b0          	mov    -0x50(%rbp),%rax
  800420742c:	48 8b 00             	mov    (%rax),%rax
  800420742f:	48 01 c2             	add    %rax,%rdx
  8004207432:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004207436:	48 89 50 48          	mov    %rdx,0x48(%rax)
		*off += fde->fde_auglen;
  800420743a:	48 8b 45 b0          	mov    -0x50(%rbp),%rax
  800420743e:	48 8b 10             	mov    (%rax),%rdx
  8004207441:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004207445:	48 8b 40 40          	mov    0x40(%rax),%rax
  8004207449:	48 01 c2             	add    %rax,%rdx
  800420744c:	48 8b 45 b0          	mov    -0x50(%rbp),%rax
  8004207450:	48 89 10             	mov    %rdx,(%rax)
	}

	fde->fde_inst = ds->ds_data + *off;
  8004207453:	48 8b 45 b8          	mov    -0x48(%rbp),%rax
  8004207457:	48 8b 50 08          	mov    0x8(%rax),%rdx
  800420745b:	48 8b 45 b0          	mov    -0x50(%rbp),%rax
  800420745f:	48 8b 00             	mov    (%rax),%rax
  8004207462:	48 01 c2             	add    %rax,%rdx
  8004207465:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004207469:	48 89 50 50          	mov    %rdx,0x50(%rax)
	if (dwarf_size == 4)
  800420746d:	83 7d f4 04          	cmpl   $0x4,-0xc(%rbp)
  8004207471:	75 2d                	jne    80042074a0 <_dwarf_frame_set_fde+0x373>
		fde->fde_instlen = fde->fde_offset + 4 + length - *off;
  8004207473:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004207477:	48 8b 40 18          	mov    0x18(%rax),%rax
  800420747b:	48 89 c2             	mov    %rax,%rdx
  800420747e:	48 03 55 f8          	add    -0x8(%rbp),%rdx
  8004207482:	48 8b 45 b0          	mov    -0x50(%rbp),%rax
  8004207486:	48 8b 00             	mov    (%rax),%rax
  8004207489:	48 89 d1             	mov    %rdx,%rcx
  800420748c:	48 29 c1             	sub    %rax,%rcx
  800420748f:	48 89 c8             	mov    %rcx,%rax
  8004207492:	48 8d 50 04          	lea    0x4(%rax),%rdx
  8004207496:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  800420749a:	48 89 50 58          	mov    %rdx,0x58(%rax)
  800420749e:	eb 2b                	jmp    80042074cb <_dwarf_frame_set_fde+0x39e>
	else
		fde->fde_instlen = fde->fde_offset + 12 + length - *off;
  80042074a0:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  80042074a4:	48 8b 40 18          	mov    0x18(%rax),%rax
  80042074a8:	48 89 c2             	mov    %rax,%rdx
  80042074ab:	48 03 55 f8          	add    -0x8(%rbp),%rdx
  80042074af:	48 8b 45 b0          	mov    -0x50(%rbp),%rax
  80042074b3:	48 8b 00             	mov    (%rax),%rax
  80042074b6:	48 89 d1             	mov    %rdx,%rcx
  80042074b9:	48 29 c1             	sub    %rax,%rcx
  80042074bc:	48 89 c8             	mov    %rcx,%rax
  80042074bf:	48 8d 50 0c          	lea    0xc(%rax),%rdx
  80042074c3:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  80042074c7:	48 89 50 58          	mov    %rdx,0x58(%rax)

	*off += fde->fde_instlen;
  80042074cb:	48 8b 45 b0          	mov    -0x50(%rbp),%rax
  80042074cf:	48 8b 10             	mov    (%rax),%rdx
  80042074d2:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  80042074d6:	48 8b 40 58          	mov    0x58(%rax),%rax
  80042074da:	48 01 c2             	add    %rax,%rdx
  80042074dd:	48 8b 45 b0          	mov    -0x50(%rbp),%rax
  80042074e1:	48 89 10             	mov    %rdx,(%rax)
	printf("\tfde_offset=%ju fde_length=%ju fde_cieoff=%ju"
	    " fde_instlen=%ju off=%ju\n", fde->fde_offset, fde->fde_length,
	    fde->fde_cieoff, fde->fde_instlen, *off);
#endif

	return (DW_DLE_NONE);
  80042074e4:	b8 00 00 00 00       	mov    $0x0,%eax
}
  80042074e9:	c9                   	leaveq 
  80042074ea:	c3                   	retq   

00000080042074eb <_dwarf_frame_interal_table_init>:


int
_dwarf_frame_interal_table_init(Dwarf_Debug dbg, Dwarf_Error *error)
{
  80042074eb:	55                   	push   %rbp
  80042074ec:	48 89 e5             	mov    %rsp,%rbp
  80042074ef:	48 83 ec 20          	sub    $0x20,%rsp
  80042074f3:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
  80042074f7:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
        Dwarf_Regtable3 *rt = &global_rt_table;
  80042074fb:	48 b8 00 bd 21 04 80 	movabs $0x800421bd00,%rax
  8004207502:	00 00 00 
  8004207505:	48 89 45 f8          	mov    %rax,-0x8(%rbp)

        if (dbg->dbg_internal_reg_table != NULL)
  8004207509:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  800420750d:	48 8b 40 50          	mov    0x50(%rax),%rax
  8004207511:	48 85 c0             	test   %rax,%rax
  8004207514:	74 07                	je     800420751d <_dwarf_frame_interal_table_init+0x32>
                return (DW_DLE_NONE);
  8004207516:	b8 00 00 00 00       	mov    $0x0,%eax
  800420751b:	eb 33                	jmp    8004207550 <_dwarf_frame_interal_table_init+0x65>
        /*if ((rt = calloc(1, sizeof(Dwarf_Regtable3))) == NULL) {
                DWARF_SET_ERROR(dbg, error, DW_DLE_MEMORY);
                return (DW_DLE_MEMORY);
        }*/

        rt->rt3_reg_table_size = dbg->dbg_frame_rule_table_size;
  800420751d:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004207521:	0f b7 50 40          	movzwl 0x40(%rax),%edx
  8004207525:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8004207529:	66 89 50 18          	mov    %dx,0x18(%rax)

	//assert(!strcmp(section_info[0].ds_name,".debug_info"));
	//cprintf("Table size:%x\n", rt->rt3_reg_table_size);

	rt->rt3_rules = global_rules;
  800420752d:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8004207531:	48 ba 20 c4 21 04 80 	movabs $0x800421c420,%rdx
  8004207538:	00 00 00 
  800420753b:	48 89 50 20          	mov    %rdx,0x20(%rax)
                free(rt);
                DWARF_SET_ERROR(dbg, error, DW_DLE_MEMORY);
                return (DW_DLE_MEMORY);
        }*/

        dbg->dbg_internal_reg_table = rt;
  800420753f:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004207543:	48 8b 55 f8          	mov    -0x8(%rbp),%rdx
  8004207547:	48 89 50 50          	mov    %rdx,0x50(%rax)

        return (DW_DLE_NONE);
  800420754b:	b8 00 00 00 00       	mov    $0x0,%eax
}
  8004207550:	c9                   	leaveq 
  8004207551:	c3                   	retq   

0000008004207552 <_dwarf_get_next_fde>:


static int
_dwarf_get_next_fde(Dwarf_Debug dbg,
                    int eh_frame, Dwarf_Error *error, Dwarf_Fde ret_fde)
{
  8004207552:	55                   	push   %rbp
  8004207553:	48 89 e5             	mov    %rsp,%rbp
  8004207556:	48 83 ec 60          	sub    $0x60,%rsp
  800420755a:	48 89 7d c8          	mov    %rdi,-0x38(%rbp)
  800420755e:	89 75 c4             	mov    %esi,-0x3c(%rbp)
  8004207561:	48 89 55 b8          	mov    %rdx,-0x48(%rbp)
  8004207565:	48 89 4d b0          	mov    %rcx,-0x50(%rbp)
	Dwarf_Section *ds = &debug_frame_sec; 
  8004207569:	48 b8 e0 b5 21 04 80 	movabs $0x800421b5e0,%rax
  8004207570:	00 00 00 
  8004207573:	48 89 45 e8          	mov    %rax,-0x18(%rbp)
	uint64_t length, offset, cie_id, entry_off;
	int dwarf_size, i, ret=-1;
  8004207577:	c7 45 f0 ff ff ff ff 	movl   $0xffffffff,-0x10(%rbp)

	offset = dbg->dbg_eh_offset;
  800420757e:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
  8004207582:	48 8b 40 30          	mov    0x30(%rax),%rax
  8004207586:	48 89 45 d8          	mov    %rax,-0x28(%rbp)
	if (offset < ds->ds_size) {
  800420758a:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  800420758e:	48 8b 50 18          	mov    0x18(%rax),%rdx
  8004207592:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  8004207596:	48 39 c2             	cmp    %rax,%rdx
  8004207599:	0f 86 04 02 00 00    	jbe    80042077a3 <_dwarf_get_next_fde+0x251>
		entry_off = offset;
  800420759f:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  80042075a3:	48 89 45 d0          	mov    %rax,-0x30(%rbp)
		length = dbg->read(ds->ds_data, &offset, 4);
  80042075a7:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
  80042075ab:	4c 8b 40 18          	mov    0x18(%rax),%r8
  80042075af:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  80042075b3:	48 8b 40 08          	mov    0x8(%rax),%rax
  80042075b7:	48 8d 4d d8          	lea    -0x28(%rbp),%rcx
  80042075bb:	ba 04 00 00 00       	mov    $0x4,%edx
  80042075c0:	48 89 ce             	mov    %rcx,%rsi
  80042075c3:	48 89 c7             	mov    %rax,%rdi
  80042075c6:	41 ff d0             	callq  *%r8
  80042075c9:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
		if (length == 0xffffffff) {
  80042075cd:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  80042075d2:	48 39 45 f8          	cmp    %rax,-0x8(%rbp)
  80042075d6:	75 2f                	jne    8004207607 <_dwarf_get_next_fde+0xb5>
			dwarf_size = 8;
  80042075d8:	c7 45 f4 08 00 00 00 	movl   $0x8,-0xc(%rbp)
			length = dbg->read(ds->ds_data, &offset, 8);
  80042075df:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
  80042075e3:	4c 8b 40 18          	mov    0x18(%rax),%r8
  80042075e7:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  80042075eb:	48 8b 40 08          	mov    0x8(%rax),%rax
  80042075ef:	48 8d 4d d8          	lea    -0x28(%rbp),%rcx
  80042075f3:	ba 08 00 00 00       	mov    $0x8,%edx
  80042075f8:	48 89 ce             	mov    %rcx,%rsi
  80042075fb:	48 89 c7             	mov    %rax,%rdi
  80042075fe:	41 ff d0             	callq  *%r8
  8004207601:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
  8004207605:	eb 07                	jmp    800420760e <_dwarf_get_next_fde+0xbc>
		} else
			dwarf_size = 4;
  8004207607:	c7 45 f4 04 00 00 00 	movl   $0x4,-0xc(%rbp)

		if (length > ds->ds_size - offset ||
  800420760e:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004207612:	48 8b 50 18          	mov    0x18(%rax),%rdx
  8004207616:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  800420761a:	48 89 d1             	mov    %rdx,%rcx
  800420761d:	48 29 c1             	sub    %rax,%rcx
  8004207620:	48 89 c8             	mov    %rcx,%rax
  8004207623:	48 3b 45 f8          	cmp    -0x8(%rbp),%rax
  8004207627:	72 0d                	jb     8004207636 <_dwarf_get_next_fde+0xe4>
  8004207629:	48 83 7d f8 00       	cmpq   $0x0,-0x8(%rbp)
  800420762e:	75 10                	jne    8004207640 <_dwarf_get_next_fde+0xee>
		    (length == 0 && !eh_frame)) {
  8004207630:	83 7d c4 00          	cmpl   $0x0,-0x3c(%rbp)
  8004207634:	75 0a                	jne    8004207640 <_dwarf_get_next_fde+0xee>
			DWARF_SET_ERROR(dbg, error,
			    DW_DLE_DEBUG_FRAME_LENGTH_BAD);
			return (DW_DLE_DEBUG_FRAME_LENGTH_BAD);
  8004207636:	b8 12 00 00 00       	mov    $0x12,%eax
  800420763b:	e9 68 01 00 00       	jmpq   80042077a8 <_dwarf_get_next_fde+0x256>
		}

		/* Check terminator for .eh_frame */
		if (eh_frame && length == 0)
  8004207640:	83 7d c4 00          	cmpl   $0x0,-0x3c(%rbp)
  8004207644:	74 11                	je     8004207657 <_dwarf_get_next_fde+0x105>
  8004207646:	48 83 7d f8 00       	cmpq   $0x0,-0x8(%rbp)
  800420764b:	75 0a                	jne    8004207657 <_dwarf_get_next_fde+0x105>
			return(-1);
  800420764d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  8004207652:	e9 51 01 00 00       	jmpq   80042077a8 <_dwarf_get_next_fde+0x256>

		cie_id = dbg->read(ds->ds_data, &offset, dwarf_size);
  8004207657:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
  800420765b:	4c 8b 40 18          	mov    0x18(%rax),%r8
  800420765f:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004207663:	48 8b 40 08          	mov    0x8(%rax),%rax
  8004207667:	8b 55 f4             	mov    -0xc(%rbp),%edx
  800420766a:	48 8d 4d d8          	lea    -0x28(%rbp),%rcx
  800420766e:	48 89 ce             	mov    %rcx,%rsi
  8004207671:	48 89 c7             	mov    %rax,%rdi
  8004207674:	41 ff d0             	callq  *%r8
  8004207677:	48 89 45 e0          	mov    %rax,-0x20(%rbp)

		if (eh_frame) {
  800420767b:	83 7d c4 00          	cmpl   $0x0,-0x3c(%rbp)
  800420767f:	74 79                	je     80042076fa <_dwarf_get_next_fde+0x1a8>
			/* GNU .eh_frame use CIE id 0. */
			if (cie_id == 0)
  8004207681:	48 83 7d e0 00       	cmpq   $0x0,-0x20(%rbp)
  8004207686:	75 32                	jne    80042076ba <_dwarf_get_next_fde+0x168>
				ret = _dwarf_frame_set_cie(dbg, ds,
				    &entry_off, ret_fde->fde_cie, error);
  8004207688:	48 8b 45 b0          	mov    -0x50(%rbp),%rax
		cie_id = dbg->read(ds->ds_data, &offset, dwarf_size);

		if (eh_frame) {
			/* GNU .eh_frame use CIE id 0. */
			if (cie_id == 0)
				ret = _dwarf_frame_set_cie(dbg, ds,
  800420768c:	48 8b 48 08          	mov    0x8(%rax),%rcx
  8004207690:	48 8b 7d b8          	mov    -0x48(%rbp),%rdi
				    &entry_off, ret_fde->fde_cie, error);
  8004207694:	48 8d 55 d0          	lea    -0x30(%rbp),%rdx
		cie_id = dbg->read(ds->ds_data, &offset, dwarf_size);

		if (eh_frame) {
			/* GNU .eh_frame use CIE id 0. */
			if (cie_id == 0)
				ret = _dwarf_frame_set_cie(dbg, ds,
  8004207698:	48 8b 75 e8          	mov    -0x18(%rbp),%rsi
  800420769c:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
  80042076a0:	49 89 f8             	mov    %rdi,%r8
  80042076a3:	48 89 c7             	mov    %rax,%rdi
  80042076a6:	48 b8 bc 6c 20 04 80 	movabs $0x8004206cbc,%rax
  80042076ad:	00 00 00 
  80042076b0:	ff d0                	callq  *%rax
  80042076b2:	89 45 f0             	mov    %eax,-0x10(%rbp)
  80042076b5:	e9 c8 00 00 00       	jmpq   8004207782 <_dwarf_get_next_fde+0x230>
				    &entry_off, ret_fde->fde_cie, error);
			else
				ret = _dwarf_frame_set_fde(dbg,ret_fde, ds,
				    &entry_off, 1, ret_fde->fde_cie, error);
  80042076ba:	48 8b 45 b0          	mov    -0x50(%rbp),%rax
			/* GNU .eh_frame use CIE id 0. */
			if (cie_id == 0)
				ret = _dwarf_frame_set_cie(dbg, ds,
				    &entry_off, ret_fde->fde_cie, error);
			else
				ret = _dwarf_frame_set_fde(dbg,ret_fde, ds,
  80042076be:	4c 8b 40 08          	mov    0x8(%rax),%r8
				    &entry_off, 1, ret_fde->fde_cie, error);
  80042076c2:	48 8d 4d d0          	lea    -0x30(%rbp),%rcx
			/* GNU .eh_frame use CIE id 0. */
			if (cie_id == 0)
				ret = _dwarf_frame_set_cie(dbg, ds,
				    &entry_off, ret_fde->fde_cie, error);
			else
				ret = _dwarf_frame_set_fde(dbg,ret_fde, ds,
  80042076c6:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  80042076ca:	48 8b 75 b0          	mov    -0x50(%rbp),%rsi
  80042076ce:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
  80042076d2:	48 8b 7d b8          	mov    -0x48(%rbp),%rdi
  80042076d6:	48 89 3c 24          	mov    %rdi,(%rsp)
  80042076da:	4d 89 c1             	mov    %r8,%r9
  80042076dd:	41 b8 01 00 00 00    	mov    $0x1,%r8d
  80042076e3:	48 89 c7             	mov    %rax,%rdi
  80042076e6:	48 b8 2d 71 20 04 80 	movabs $0x800420712d,%rax
  80042076ed:	00 00 00 
  80042076f0:	ff d0                	callq  *%rax
  80042076f2:	89 45 f0             	mov    %eax,-0x10(%rbp)
  80042076f5:	e9 88 00 00 00       	jmpq   8004207782 <_dwarf_get_next_fde+0x230>
				    &entry_off, 1, ret_fde->fde_cie, error);
		} else {
			/* .dwarf_frame use CIE id ~0 */
			if ((dwarf_size == 4 && cie_id == ~0U) ||
  80042076fa:	83 7d f4 04          	cmpl   $0x4,-0xc(%rbp)
  80042076fe:	75 0b                	jne    800420770b <_dwarf_get_next_fde+0x1b9>
  8004207700:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  8004207705:	48 39 45 e0          	cmp    %rax,-0x20(%rbp)
  8004207709:	74 0d                	je     8004207718 <_dwarf_get_next_fde+0x1c6>
  800420770b:	83 7d f4 08          	cmpl   $0x8,-0xc(%rbp)
  800420770f:	75 36                	jne    8004207747 <_dwarf_get_next_fde+0x1f5>
			    (dwarf_size == 8 && cie_id == ~0ULL))
  8004207711:	48 83 7d e0 ff       	cmpq   $0xffffffffffffffff,-0x20(%rbp)
  8004207716:	75 2f                	jne    8004207747 <_dwarf_get_next_fde+0x1f5>
				ret = _dwarf_frame_set_cie(dbg, ds,
				    &entry_off, ret_fde->fde_cie, error);
  8004207718:	48 8b 45 b0          	mov    -0x50(%rbp),%rax
				    &entry_off, 1, ret_fde->fde_cie, error);
		} else {
			/* .dwarf_frame use CIE id ~0 */
			if ((dwarf_size == 4 && cie_id == ~0U) ||
			    (dwarf_size == 8 && cie_id == ~0ULL))
				ret = _dwarf_frame_set_cie(dbg, ds,
  800420771c:	48 8b 48 08          	mov    0x8(%rax),%rcx
  8004207720:	48 8b 7d b8          	mov    -0x48(%rbp),%rdi
				    &entry_off, ret_fde->fde_cie, error);
  8004207724:	48 8d 55 d0          	lea    -0x30(%rbp),%rdx
				    &entry_off, 1, ret_fde->fde_cie, error);
		} else {
			/* .dwarf_frame use CIE id ~0 */
			if ((dwarf_size == 4 && cie_id == ~0U) ||
			    (dwarf_size == 8 && cie_id == ~0ULL))
				ret = _dwarf_frame_set_cie(dbg, ds,
  8004207728:	48 8b 75 e8          	mov    -0x18(%rbp),%rsi
  800420772c:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
  8004207730:	49 89 f8             	mov    %rdi,%r8
  8004207733:	48 89 c7             	mov    %rax,%rdi
  8004207736:	48 b8 bc 6c 20 04 80 	movabs $0x8004206cbc,%rax
  800420773d:	00 00 00 
  8004207740:	ff d0                	callq  *%rax
  8004207742:	89 45 f0             	mov    %eax,-0x10(%rbp)
  8004207745:	eb 3b                	jmp    8004207782 <_dwarf_get_next_fde+0x230>
				    &entry_off, ret_fde->fde_cie, error);
			else
				ret = _dwarf_frame_set_fde(dbg, ret_fde, ds,
				    &entry_off, 0, ret_fde->fde_cie, error);
  8004207747:	48 8b 45 b0          	mov    -0x50(%rbp),%rax
			if ((dwarf_size == 4 && cie_id == ~0U) ||
			    (dwarf_size == 8 && cie_id == ~0ULL))
				ret = _dwarf_frame_set_cie(dbg, ds,
				    &entry_off, ret_fde->fde_cie, error);
			else
				ret = _dwarf_frame_set_fde(dbg, ret_fde, ds,
  800420774b:	4c 8b 40 08          	mov    0x8(%rax),%r8
				    &entry_off, 0, ret_fde->fde_cie, error);
  800420774f:	48 8d 4d d0          	lea    -0x30(%rbp),%rcx
			if ((dwarf_size == 4 && cie_id == ~0U) ||
			    (dwarf_size == 8 && cie_id == ~0ULL))
				ret = _dwarf_frame_set_cie(dbg, ds,
				    &entry_off, ret_fde->fde_cie, error);
			else
				ret = _dwarf_frame_set_fde(dbg, ret_fde, ds,
  8004207753:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  8004207757:	48 8b 75 b0          	mov    -0x50(%rbp),%rsi
  800420775b:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
  800420775f:	48 8b 7d b8          	mov    -0x48(%rbp),%rdi
  8004207763:	48 89 3c 24          	mov    %rdi,(%rsp)
  8004207767:	4d 89 c1             	mov    %r8,%r9
  800420776a:	41 b8 00 00 00 00    	mov    $0x0,%r8d
  8004207770:	48 89 c7             	mov    %rax,%rdi
  8004207773:	48 b8 2d 71 20 04 80 	movabs $0x800420712d,%rax
  800420777a:	00 00 00 
  800420777d:	ff d0                	callq  *%rax
  800420777f:	89 45 f0             	mov    %eax,-0x10(%rbp)
				    &entry_off, 0, ret_fde->fde_cie, error);
		}

		if (ret != DW_DLE_NONE)
  8004207782:	83 7d f0 00          	cmpl   $0x0,-0x10(%rbp)
  8004207786:	74 07                	je     800420778f <_dwarf_get_next_fde+0x23d>
			return(-1);
  8004207788:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  800420778d:	eb 19                	jmp    80042077a8 <_dwarf_get_next_fde+0x256>

		offset = entry_off;
  800420778f:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  8004207793:	48 89 45 d8          	mov    %rax,-0x28(%rbp)
		dbg->dbg_eh_offset = offset;
  8004207797:	48 8b 55 d8          	mov    -0x28(%rbp),%rdx
  800420779b:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
  800420779f:	48 89 50 30          	mov    %rdx,0x30(%rax)
	}

	return (0);
  80042077a3:	b8 00 00 00 00       	mov    $0x0,%eax
}
  80042077a8:	c9                   	leaveq 
  80042077a9:	c3                   	retq   

00000080042077aa <dwarf_set_frame_cfa_value>:


Dwarf_Half
dwarf_set_frame_cfa_value(Dwarf_Debug dbg, Dwarf_Half value)
{
  80042077aa:	55                   	push   %rbp
  80042077ab:	48 89 e5             	mov    %rsp,%rbp
  80042077ae:	48 83 ec 20          	sub    $0x20,%rsp
  80042077b2:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
  80042077b6:	89 f0                	mov    %esi,%eax
  80042077b8:	66 89 45 e4          	mov    %ax,-0x1c(%rbp)
        Dwarf_Half old_value;

        old_value = dbg->dbg_frame_cfa_value;
  80042077bc:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  80042077c0:	0f b7 40 44          	movzwl 0x44(%rax),%eax
  80042077c4:	66 89 45 fe          	mov    %ax,-0x2(%rbp)
        dbg->dbg_frame_cfa_value = value;
  80042077c8:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  80042077cc:	0f b7 55 e4          	movzwl -0x1c(%rbp),%edx
  80042077d0:	66 89 50 44          	mov    %dx,0x44(%rax)

        return (old_value);
  80042077d4:	0f b7 45 fe          	movzwl -0x2(%rbp),%eax
}
  80042077d8:	c9                   	leaveq 
  80042077d9:	c3                   	retq   

00000080042077da <_dwarf_frame_section_load_eh>:

int
_dwarf_frame_section_load_eh(Dwarf_Debug dbg, Dwarf_Error *error)
{
  80042077da:	55                   	push   %rbp
  80042077db:	48 89 e5             	mov    %rsp,%rbp
  80042077de:	48 83 ec 20          	sub    $0x20,%rsp
  80042077e2:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
  80042077e6:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
	int status;
	Dwarf_Section *ds = &debug_frame_sec;
  80042077ea:	48 b8 e0 b5 21 04 80 	movabs $0x800421b5e0,%rax
  80042077f1:	00 00 00 
  80042077f4:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
        status  = _dwarf_find_section_enhanced(&debug_frame_sec);
  80042077f8:	48 bf e0 b5 21 04 80 	movabs $0x800421b5e0,%rdi
  80042077ff:	00 00 00 
  8004207802:	48 b8 47 52 20 04 80 	movabs $0x8004205247,%rax
  8004207809:	00 00 00 
  800420780c:	ff d0                	callq  *%rax
  800420780e:	89 45 f4             	mov    %eax,-0xc(%rbp)
        return (DW_DLE_NONE);
  8004207811:	b8 00 00 00 00       	mov    $0x0,%eax
}
  8004207816:	c9                   	leaveq 
  8004207817:	c3                   	retq   

0000008004207818 <dwarf_init_eh_section>:


int
dwarf_init_eh_section(Dwarf_Debug dbg,
                      Dwarf_Error *error)
{
  8004207818:	55                   	push   %rbp
  8004207819:	48 89 e5             	mov    %rsp,%rbp
  800420781c:	48 83 ec 10          	sub    $0x10,%rsp
  8004207820:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
  8004207824:	48 89 75 f0          	mov    %rsi,-0x10(%rbp)

        if (dbg == NULL) {
  8004207828:	48 83 7d f8 00       	cmpq   $0x0,-0x8(%rbp)
  800420782d:	75 07                	jne    8004207836 <dwarf_init_eh_section+0x1e>
                DWARF_SET_ERROR(dbg, error, DW_DLE_ARGUMENT);
                return (DW_DLV_ERROR);
  800420782f:	b8 01 00 00 00       	mov    $0x1,%eax
  8004207834:	eb 7e                	jmp    80042078b4 <dwarf_init_eh_section+0x9c>
        }

        if (dbg->dbg_internal_reg_table == NULL) {
  8004207836:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  800420783a:	48 8b 40 50          	mov    0x50(%rax),%rax
  800420783e:	48 85 c0             	test   %rax,%rax
  8004207841:	75 25                	jne    8004207868 <dwarf_init_eh_section+0x50>
                if (_dwarf_frame_interal_table_init(dbg, error) != DW_DLE_NONE)
  8004207843:	48 8b 55 f0          	mov    -0x10(%rbp),%rdx
  8004207847:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  800420784b:	48 89 d6             	mov    %rdx,%rsi
  800420784e:	48 89 c7             	mov    %rax,%rdi
  8004207851:	48 b8 eb 74 20 04 80 	movabs $0x80042074eb,%rax
  8004207858:	00 00 00 
  800420785b:	ff d0                	callq  *%rax
  800420785d:	85 c0                	test   %eax,%eax
  800420785f:	74 07                	je     8004207868 <dwarf_init_eh_section+0x50>
                        return (DW_DLV_ERROR);
  8004207861:	b8 01 00 00 00       	mov    $0x1,%eax
  8004207866:	eb 4c                	jmp    80042078b4 <dwarf_init_eh_section+0x9c>
	}

	if (_dwarf_frame_section_load_eh(dbg, error) != DW_DLE_NONE)
  8004207868:	48 8b 55 f0          	mov    -0x10(%rbp),%rdx
  800420786c:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8004207870:	48 89 d6             	mov    %rdx,%rsi
  8004207873:	48 89 c7             	mov    %rax,%rdi
  8004207876:	48 b8 da 77 20 04 80 	movabs $0x80042077da,%rax
  800420787d:	00 00 00 
  8004207880:	ff d0                	callq  *%rax
  8004207882:	85 c0                	test   %eax,%eax
  8004207884:	74 07                	je     800420788d <dwarf_init_eh_section+0x75>
		return (DW_DLV_ERROR);
  8004207886:	b8 01 00 00 00       	mov    $0x1,%eax
  800420788b:	eb 27                	jmp    80042078b4 <dwarf_init_eh_section+0x9c>

	dbg->dbg_eh_size = debug_frame_sec.ds_size;
  800420788d:	48 b8 e0 b5 21 04 80 	movabs $0x800421b5e0,%rax
  8004207894:	00 00 00 
  8004207897:	48 8b 50 18          	mov    0x18(%rax),%rdx
  800420789b:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  800420789f:	48 89 50 38          	mov    %rdx,0x38(%rax)
	dbg->dbg_eh_offset = 0;
  80042078a3:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  80042078a7:	48 c7 40 30 00 00 00 	movq   $0x0,0x30(%rax)
  80042078ae:	00 

    return (DW_DLV_OK);
  80042078af:	b8 00 00 00 00       	mov    $0x0,%eax
}
  80042078b4:	c9                   	leaveq 
  80042078b5:	c3                   	retq   
	...

00000080042078b8 <_dwarf_lineno_run_program>:


static int
_dwarf_lineno_run_program(Dwarf_CU *cu, Dwarf_LineInfo li, uint8_t *p,
    uint8_t *pe, Dwarf_Addr pc, Dwarf_Error *error)
{
  80042078b8:	55                   	push   %rbp
  80042078b9:	48 89 e5             	mov    %rsp,%rbp
  80042078bc:	48 81 ec a0 00 00 00 	sub    $0xa0,%rsp
  80042078c3:	48 89 7d 98          	mov    %rdi,-0x68(%rbp)
  80042078c7:	48 89 75 90          	mov    %rsi,-0x70(%rbp)
  80042078cb:	48 89 55 88          	mov    %rdx,-0x78(%rbp)
  80042078cf:	48 89 4d 80          	mov    %rcx,-0x80(%rbp)
  80042078d3:	4c 89 85 78 ff ff ff 	mov    %r8,-0x88(%rbp)
  80042078da:	4c 89 8d 70 ff ff ff 	mov    %r9,-0x90(%rbp)
    uint64_t address, file, line, column, isa, opsize;
    int is_stmt, basic_block, end_sequence;
    int prologue_end, epilogue_begin;
    int ret;

	ln = &li->li_line;
  80042078e1:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  80042078e5:	48 83 c0 48          	add    $0x48,%rax
  80042078e9:	48 89 45 c8          	mov    %rax,-0x38(%rbp)

    /*
     *   ln->ln_li     = li;             \
     * Set registers to their default values.
     */
    RESET_REGISTERS;
  80042078ed:	48 c7 45 f8 00 00 00 	movq   $0x0,-0x8(%rbp)
  80042078f4:	00 
  80042078f5:	48 c7 45 f0 01 00 00 	movq   $0x1,-0x10(%rbp)
  80042078fc:	00 
  80042078fd:	48 c7 45 e8 01 00 00 	movq   $0x1,-0x18(%rbp)
  8004207904:	00 
  8004207905:	48 c7 45 e0 00 00 00 	movq   $0x0,-0x20(%rbp)
  800420790c:	00 
  800420790d:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  8004207911:	0f b6 40 19          	movzbl 0x19(%rax),%eax
  8004207915:	0f b6 c0             	movzbl %al,%eax
  8004207918:	89 45 dc             	mov    %eax,-0x24(%rbp)
  800420791b:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%rbp)
  8004207922:	c7 45 d4 00 00 00 00 	movl   $0x0,-0x2c(%rbp)
  8004207929:	c7 45 c4 00 00 00 00 	movl   $0x0,-0x3c(%rbp)
  8004207930:	c7 45 c0 00 00 00 00 	movl   $0x0,-0x40(%rbp)

    /*
     * Start line number program.
     */
    while (p < pe) {
  8004207937:	e9 cf 04 00 00       	jmpq   8004207e0b <_dwarf_lineno_run_program+0x553>
        if (*p == 0) {
  800420793c:	48 8b 45 88          	mov    -0x78(%rbp),%rax
  8004207940:	0f b6 00             	movzbl (%rax),%eax
  8004207943:	84 c0                	test   %al,%al
  8004207945:	0f 85 47 01 00 00    	jne    8004207a92 <_dwarf_lineno_run_program+0x1da>

            /*
             * Extended Opcodes.
             */

            p++;
  800420794b:	48 8b 45 88          	mov    -0x78(%rbp),%rax
  800420794f:	48 83 c0 01          	add    $0x1,%rax
  8004207953:	48 89 45 88          	mov    %rax,-0x78(%rbp)
            opsize = _dwarf_decode_uleb128(&p);
  8004207957:	48 8d 45 88          	lea    -0x78(%rbp),%rax
  800420795b:	48 89 c7             	mov    %rax,%rdi
  800420795e:	48 b8 82 3a 20 04 80 	movabs $0x8004203a82,%rax
  8004207965:	00 00 00 
  8004207968:	ff d0                	callq  *%rax
  800420796a:	48 89 45 b8          	mov    %rax,-0x48(%rbp)
            switch (*p) {
  800420796e:	48 8b 45 88          	mov    -0x78(%rbp),%rax
  8004207972:	0f b6 00             	movzbl (%rax),%eax
  8004207975:	0f b6 c0             	movzbl %al,%eax
  8004207978:	83 f8 02             	cmp    $0x2,%eax
  800420797b:	74 74                	je     80042079f1 <_dwarf_lineno_run_program+0x139>
  800420797d:	83 f8 03             	cmp    $0x3,%eax
  8004207980:	0f 84 a7 00 00 00    	je     8004207a2d <_dwarf_lineno_run_program+0x175>
  8004207986:	83 f8 01             	cmp    $0x1,%eax
  8004207989:	0f 85 f2 00 00 00    	jne    8004207a81 <_dwarf_lineno_run_program+0x1c9>
            case DW_LNE_end_sequence:
                p++;
  800420798f:	48 8b 45 88          	mov    -0x78(%rbp),%rax
  8004207993:	48 83 c0 01          	add    $0x1,%rax
  8004207997:	48 89 45 88          	mov    %rax,-0x78(%rbp)
                end_sequence = 1;
  800420799b:	c7 45 d4 01 00 00 00 	movl   $0x1,-0x2c(%rbp)
                RESET_REGISTERS;
  80042079a2:	48 c7 45 f8 00 00 00 	movq   $0x0,-0x8(%rbp)
  80042079a9:	00 
  80042079aa:	48 c7 45 f0 01 00 00 	movq   $0x1,-0x10(%rbp)
  80042079b1:	00 
  80042079b2:	48 c7 45 e8 01 00 00 	movq   $0x1,-0x18(%rbp)
  80042079b9:	00 
  80042079ba:	48 c7 45 e0 00 00 00 	movq   $0x0,-0x20(%rbp)
  80042079c1:	00 
  80042079c2:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  80042079c6:	0f b6 40 19          	movzbl 0x19(%rax),%eax
  80042079ca:	0f b6 c0             	movzbl %al,%eax
  80042079cd:	89 45 dc             	mov    %eax,-0x24(%rbp)
  80042079d0:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%rbp)
  80042079d7:	c7 45 d4 00 00 00 00 	movl   $0x0,-0x2c(%rbp)
  80042079de:	c7 45 c4 00 00 00 00 	movl   $0x0,-0x3c(%rbp)
  80042079e5:	c7 45 c0 00 00 00 00 	movl   $0x0,-0x40(%rbp)
                break;
  80042079ec:	e9 1a 04 00 00       	jmpq   8004207e0b <_dwarf_lineno_run_program+0x553>
            case DW_LNE_set_address:
                p++;
  80042079f1:	48 8b 45 88          	mov    -0x78(%rbp),%rax
  80042079f5:	48 83 c0 01          	add    $0x1,%rax
  80042079f9:	48 89 45 88          	mov    %rax,-0x78(%rbp)
                address = dbg->decode(&p, cu->addr_size);
  80042079fd:	48 b8 c8 b5 21 04 80 	movabs $0x800421b5c8,%rax
  8004207a04:	00 00 00 
  8004207a07:	48 8b 00             	mov    (%rax),%rax
  8004207a0a:	48 8b 48 20          	mov    0x20(%rax),%rcx
  8004207a0e:	48 8b 45 98          	mov    -0x68(%rbp),%rax
  8004207a12:	0f b6 40 0a          	movzbl 0xa(%rax),%eax
  8004207a16:	0f b6 d0             	movzbl %al,%edx
  8004207a19:	48 8d 45 88          	lea    -0x78(%rbp),%rax
  8004207a1d:	89 d6                	mov    %edx,%esi
  8004207a1f:	48 89 c7             	mov    %rax,%rdi
  8004207a22:	ff d1                	callq  *%rcx
  8004207a24:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
                break;
  8004207a28:	e9 de 03 00 00       	jmpq   8004207e0b <_dwarf_lineno_run_program+0x553>
            case DW_LNE_define_file:
                p++;
  8004207a2d:	48 8b 45 88          	mov    -0x78(%rbp),%rax
  8004207a31:	48 83 c0 01          	add    $0x1,%rax
  8004207a35:	48 89 45 88          	mov    %rax,-0x78(%rbp)
                ret = _dwarf_lineno_add_file(li, &p, NULL,
  8004207a39:	48 b8 c8 b5 21 04 80 	movabs $0x800421b5c8,%rax
  8004207a40:	00 00 00 
  8004207a43:	48 8b 08             	mov    (%rax),%rcx
  8004207a46:	48 8b 95 70 ff ff ff 	mov    -0x90(%rbp),%rdx
  8004207a4d:	48 8d 75 88          	lea    -0x78(%rbp),%rsi
  8004207a51:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  8004207a55:	49 89 c8             	mov    %rcx,%r8
  8004207a58:	48 89 d1             	mov    %rdx,%rcx
  8004207a5b:	ba 00 00 00 00       	mov    $0x0,%edx
  8004207a60:	48 89 c7             	mov    %rax,%rdi
  8004207a63:	48 b8 25 7e 20 04 80 	movabs $0x8004207e25,%rax
  8004207a6a:	00 00 00 
  8004207a6d:	ff d0                	callq  *%rax
  8004207a6f:	89 45 b4             	mov    %eax,-0x4c(%rbp)
                    error, dbg);
                if (ret != DW_DLE_NONE)
  8004207a72:	83 7d b4 00          	cmpl   $0x0,-0x4c(%rbp)
  8004207a76:	0f 84 8e 03 00 00    	je     8004207e0a <_dwarf_lineno_run_program+0x552>
                    goto prog_fail;
  8004207a7c:	e9 9f 03 00 00       	jmpq   8004207e20 <_dwarf_lineno_run_program+0x568>
                break;
            default:
                /* Unrecognized extened opcodes. */
                p += opsize;
  8004207a81:	48 8b 45 88          	mov    -0x78(%rbp),%rax
  8004207a85:	48 03 45 b8          	add    -0x48(%rbp),%rax
  8004207a89:	48 89 45 88          	mov    %rax,-0x78(%rbp)
  8004207a8d:	e9 79 03 00 00       	jmpq   8004207e0b <_dwarf_lineno_run_program+0x553>
            }

        } else if (*p > 0 && *p < li->li_opbase) {
  8004207a92:	48 8b 45 88          	mov    -0x78(%rbp),%rax
  8004207a96:	0f b6 00             	movzbl (%rax),%eax
  8004207a99:	84 c0                	test   %al,%al
  8004207a9b:	0f 84 2f 02 00 00    	je     8004207cd0 <_dwarf_lineno_run_program+0x418>
  8004207aa1:	48 8b 45 88          	mov    -0x78(%rbp),%rax
  8004207aa5:	0f b6 10             	movzbl (%rax),%edx
  8004207aa8:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  8004207aac:	0f b6 40 1c          	movzbl 0x1c(%rax),%eax
  8004207ab0:	38 c2                	cmp    %al,%dl
  8004207ab2:	0f 83 18 02 00 00    	jae    8004207cd0 <_dwarf_lineno_run_program+0x418>

            /*
             * Standard Opcodes.
             */

            switch (*p++) {
  8004207ab8:	48 8b 45 88          	mov    -0x78(%rbp),%rax
  8004207abc:	0f b6 10             	movzbl (%rax),%edx
  8004207abf:	0f b6 d2             	movzbl %dl,%edx
  8004207ac2:	48 83 c0 01          	add    $0x1,%rax
  8004207ac6:	48 89 45 88          	mov    %rax,-0x78(%rbp)
  8004207aca:	83 fa 0c             	cmp    $0xc,%edx
  8004207acd:	0f 87 f7 01 00 00    	ja     8004207cca <_dwarf_lineno_run_program+0x412>
  8004207ad3:	89 d0                	mov    %edx,%eax
  8004207ad5:	48 8d 14 c5 00 00 00 	lea    0x0(,%rax,8),%rdx
  8004207adc:	00 
  8004207add:	48 b8 60 a1 20 04 80 	movabs $0x800420a160,%rax
  8004207ae4:	00 00 00 
  8004207ae7:	48 01 d0             	add    %rdx,%rax
  8004207aea:	48 8b 00             	mov    (%rax),%rax
  8004207aed:	ff e0                	jmpq   *%rax
            case DW_LNS_copy:
                APPEND_ROW;
  8004207aef:	48 8b 85 78 ff ff ff 	mov    -0x88(%rbp),%rax
  8004207af6:	48 3b 45 f8          	cmp    -0x8(%rbp),%rax
  8004207afa:	73 0a                	jae    8004207b06 <_dwarf_lineno_run_program+0x24e>
  8004207afc:	b8 00 00 00 00       	mov    $0x0,%eax
  8004207b01:	e9 1d 03 00 00       	jmpq   8004207e23 <_dwarf_lineno_run_program+0x56b>
  8004207b06:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
  8004207b0a:	48 8b 55 f8          	mov    -0x8(%rbp),%rdx
  8004207b0e:	48 89 10             	mov    %rdx,(%rax)
  8004207b11:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
  8004207b15:	48 c7 40 08 00 00 00 	movq   $0x0,0x8(%rax)
  8004207b1c:	00 
  8004207b1d:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
  8004207b21:	48 8b 55 f0          	mov    -0x10(%rbp),%rdx
  8004207b25:	48 89 50 10          	mov    %rdx,0x10(%rax)
  8004207b29:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
  8004207b2d:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  8004207b31:	48 89 50 18          	mov    %rdx,0x18(%rax)
  8004207b35:	48 8b 55 e0          	mov    -0x20(%rbp),%rdx
  8004207b39:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
  8004207b3d:	48 89 50 20          	mov    %rdx,0x20(%rax)
  8004207b41:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
  8004207b45:	8b 55 d8             	mov    -0x28(%rbp),%edx
  8004207b48:	89 50 28             	mov    %edx,0x28(%rax)
  8004207b4b:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
  8004207b4f:	8b 55 dc             	mov    -0x24(%rbp),%edx
  8004207b52:	89 50 2c             	mov    %edx,0x2c(%rax)
  8004207b55:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
  8004207b59:	8b 55 d4             	mov    -0x2c(%rbp),%edx
  8004207b5c:	89 50 30             	mov    %edx,0x30(%rax)
  8004207b5f:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  8004207b63:	48 8b 80 80 00 00 00 	mov    0x80(%rax),%rax
  8004207b6a:	48 8d 50 01          	lea    0x1(%rax),%rdx
  8004207b6e:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  8004207b72:	48 89 90 80 00 00 00 	mov    %rdx,0x80(%rax)
                basic_block = 0;
  8004207b79:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%rbp)
                prologue_end = 0;
  8004207b80:	c7 45 c4 00 00 00 00 	movl   $0x0,-0x3c(%rbp)
                epilogue_begin = 0;
  8004207b87:	c7 45 c0 00 00 00 00 	movl   $0x0,-0x40(%rbp)
                break;
  8004207b8e:	e9 38 01 00 00       	jmpq   8004207ccb <_dwarf_lineno_run_program+0x413>
            case DW_LNS_advance_pc:
                address += _dwarf_decode_uleb128(&p) *
  8004207b93:	48 8d 45 88          	lea    -0x78(%rbp),%rax
  8004207b97:	48 89 c7             	mov    %rax,%rdi
  8004207b9a:	48 b8 82 3a 20 04 80 	movabs $0x8004203a82,%rax
  8004207ba1:	00 00 00 
  8004207ba4:	ff d0                	callq  *%rax
                    li->li_minlen;
  8004207ba6:	48 8b 55 90          	mov    -0x70(%rbp),%rdx
  8004207baa:	0f b6 52 18          	movzbl 0x18(%rdx),%edx
                basic_block = 0;
                prologue_end = 0;
                epilogue_begin = 0;
                break;
            case DW_LNS_advance_pc:
                address += _dwarf_decode_uleb128(&p) *
  8004207bae:	0f b6 d2             	movzbl %dl,%edx
  8004207bb1:	48 0f af c2          	imul   %rdx,%rax
  8004207bb5:	48 01 45 f8          	add    %rax,-0x8(%rbp)
                    li->li_minlen;
                break;
  8004207bb9:	e9 0d 01 00 00       	jmpq   8004207ccb <_dwarf_lineno_run_program+0x413>
            case DW_LNS_advance_line:
                line += _dwarf_decode_sleb128(&p);
  8004207bbe:	48 8d 45 88          	lea    -0x78(%rbp),%rax
  8004207bc2:	48 89 c7             	mov    %rax,%rdi
  8004207bc5:	48 b8 e9 39 20 04 80 	movabs $0x80042039e9,%rax
  8004207bcc:	00 00 00 
  8004207bcf:	ff d0                	callq  *%rax
  8004207bd1:	48 01 45 e8          	add    %rax,-0x18(%rbp)
                break;
  8004207bd5:	e9 f1 00 00 00       	jmpq   8004207ccb <_dwarf_lineno_run_program+0x413>
            case DW_LNS_set_file:
                file = _dwarf_decode_uleb128(&p);
  8004207bda:	48 8d 45 88          	lea    -0x78(%rbp),%rax
  8004207bde:	48 89 c7             	mov    %rax,%rdi
  8004207be1:	48 b8 82 3a 20 04 80 	movabs $0x8004203a82,%rax
  8004207be8:	00 00 00 
  8004207beb:	ff d0                	callq  *%rax
  8004207bed:	48 89 45 f0          	mov    %rax,-0x10(%rbp)
                break;
  8004207bf1:	e9 d5 00 00 00       	jmpq   8004207ccb <_dwarf_lineno_run_program+0x413>
            case DW_LNS_set_column:
                column = _dwarf_decode_uleb128(&p);
  8004207bf6:	48 8d 45 88          	lea    -0x78(%rbp),%rax
  8004207bfa:	48 89 c7             	mov    %rax,%rdi
  8004207bfd:	48 b8 82 3a 20 04 80 	movabs $0x8004203a82,%rax
  8004207c04:	00 00 00 
  8004207c07:	ff d0                	callq  *%rax
  8004207c09:	48 89 45 e0          	mov    %rax,-0x20(%rbp)
                break;
  8004207c0d:	e9 b9 00 00 00       	jmpq   8004207ccb <_dwarf_lineno_run_program+0x413>
            case DW_LNS_negate_stmt:
                is_stmt = !is_stmt;
  8004207c12:	83 7d dc 00          	cmpl   $0x0,-0x24(%rbp)
  8004207c16:	0f 94 c0             	sete   %al
  8004207c19:	0f b6 c0             	movzbl %al,%eax
  8004207c1c:	89 45 dc             	mov    %eax,-0x24(%rbp)
                break;
  8004207c1f:	e9 a7 00 00 00       	jmpq   8004207ccb <_dwarf_lineno_run_program+0x413>
            case DW_LNS_set_basic_block:
                basic_block = 1;
  8004207c24:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%rbp)
                break;
  8004207c2b:	e9 9b 00 00 00       	jmpq   8004207ccb <_dwarf_lineno_run_program+0x413>
            case DW_LNS_const_add_pc:
                address += ADDRESS(255);
  8004207c30:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  8004207c34:	0f b6 40 1c          	movzbl 0x1c(%rax),%eax
  8004207c38:	0f b6 c0             	movzbl %al,%eax
  8004207c3b:	ba ff 00 00 00       	mov    $0xff,%edx
  8004207c40:	89 d1                	mov    %edx,%ecx
  8004207c42:	29 c1                	sub    %eax,%ecx
  8004207c44:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  8004207c48:	0f b6 40 1b          	movzbl 0x1b(%rax),%eax
  8004207c4c:	0f b6 c0             	movzbl %al,%eax
  8004207c4f:	89 85 6c ff ff ff    	mov    %eax,-0x94(%rbp)
  8004207c55:	89 c8                	mov    %ecx,%eax
  8004207c57:	89 c2                	mov    %eax,%edx
  8004207c59:	c1 fa 1f             	sar    $0x1f,%edx
  8004207c5c:	f7 bd 6c ff ff ff    	idivl  -0x94(%rbp)
  8004207c62:	89 c2                	mov    %eax,%edx
  8004207c64:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  8004207c68:	0f b6 40 18          	movzbl 0x18(%rax),%eax
  8004207c6c:	0f b6 c0             	movzbl %al,%eax
  8004207c6f:	0f af c2             	imul   %edx,%eax
  8004207c72:	48 98                	cltq   
  8004207c74:	48 01 45 f8          	add    %rax,-0x8(%rbp)
                break;
  8004207c78:	eb 51                	jmp    8004207ccb <_dwarf_lineno_run_program+0x413>
            case DW_LNS_fixed_advance_pc:
                address += dbg->decode(&p, 2);
  8004207c7a:	48 b8 c8 b5 21 04 80 	movabs $0x800421b5c8,%rax
  8004207c81:	00 00 00 
  8004207c84:	48 8b 00             	mov    (%rax),%rax
  8004207c87:	48 8b 50 20          	mov    0x20(%rax),%rdx
  8004207c8b:	48 8d 45 88          	lea    -0x78(%rbp),%rax
  8004207c8f:	be 02 00 00 00       	mov    $0x2,%esi
  8004207c94:	48 89 c7             	mov    %rax,%rdi
  8004207c97:	ff d2                	callq  *%rdx
  8004207c99:	48 01 45 f8          	add    %rax,-0x8(%rbp)
                break;
  8004207c9d:	eb 2c                	jmp    8004207ccb <_dwarf_lineno_run_program+0x413>
            case DW_LNS_set_prologue_end:
                prologue_end = 1;
  8004207c9f:	c7 45 c4 01 00 00 00 	movl   $0x1,-0x3c(%rbp)
                break;
  8004207ca6:	eb 23                	jmp    8004207ccb <_dwarf_lineno_run_program+0x413>
            case DW_LNS_set_epilogue_begin:
                epilogue_begin = 1;
  8004207ca8:	c7 45 c0 01 00 00 00 	movl   $0x1,-0x40(%rbp)
                break;
  8004207caf:	eb 1a                	jmp    8004207ccb <_dwarf_lineno_run_program+0x413>
            case DW_LNS_set_isa:
                isa = _dwarf_decode_uleb128(&p);
  8004207cb1:	48 8d 45 88          	lea    -0x78(%rbp),%rax
  8004207cb5:	48 89 c7             	mov    %rax,%rdi
  8004207cb8:	48 b8 82 3a 20 04 80 	movabs $0x8004203a82,%rax
  8004207cbf:	00 00 00 
  8004207cc2:	ff d0                	callq  *%rax
  8004207cc4:	48 89 45 a8          	mov    %rax,-0x58(%rbp)
                break;
  8004207cc8:	eb 01                	jmp    8004207ccb <_dwarf_lineno_run_program+0x413>
            default:
                /* Unrecognized extened opcodes. What to do? */
                break;
  8004207cca:	90                   	nop
            }

        } else {
  8004207ccb:	e9 3b 01 00 00       	jmpq   8004207e0b <_dwarf_lineno_run_program+0x553>

            /*
             * Special Opcodes.
             */

            line += LINE(*p);
  8004207cd0:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  8004207cd4:	0f b6 40 1a          	movzbl 0x1a(%rax),%eax
  8004207cd8:	0f be c8             	movsbl %al,%ecx
  8004207cdb:	48 8b 45 88          	mov    -0x78(%rbp),%rax
  8004207cdf:	0f b6 00             	movzbl (%rax),%eax
  8004207ce2:	0f b6 d0             	movzbl %al,%edx
  8004207ce5:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  8004207ce9:	0f b6 40 1c          	movzbl 0x1c(%rax),%eax
  8004207ced:	0f b6 c0             	movzbl %al,%eax
  8004207cf0:	29 c2                	sub    %eax,%edx
  8004207cf2:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  8004207cf6:	0f b6 40 1b          	movzbl 0x1b(%rax),%eax
  8004207cfa:	0f b6 f0             	movzbl %al,%esi
  8004207cfd:	89 d0                	mov    %edx,%eax
  8004207cff:	89 c2                	mov    %eax,%edx
  8004207d01:	c1 fa 1f             	sar    $0x1f,%edx
  8004207d04:	f7 fe                	idiv   %esi
  8004207d06:	89 d0                	mov    %edx,%eax
  8004207d08:	01 c8                	add    %ecx,%eax
  8004207d0a:	48 98                	cltq   
  8004207d0c:	48 01 45 e8          	add    %rax,-0x18(%rbp)
            address += ADDRESS(*p);
  8004207d10:	48 8b 45 88          	mov    -0x78(%rbp),%rax
  8004207d14:	0f b6 00             	movzbl (%rax),%eax
  8004207d17:	0f b6 d0             	movzbl %al,%edx
  8004207d1a:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  8004207d1e:	0f b6 40 1c          	movzbl 0x1c(%rax),%eax
  8004207d22:	0f b6 c0             	movzbl %al,%eax
  8004207d25:	89 d1                	mov    %edx,%ecx
  8004207d27:	29 c1                	sub    %eax,%ecx
  8004207d29:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  8004207d2d:	0f b6 40 1b          	movzbl 0x1b(%rax),%eax
  8004207d31:	0f b6 c0             	movzbl %al,%eax
  8004207d34:	89 85 6c ff ff ff    	mov    %eax,-0x94(%rbp)
  8004207d3a:	89 c8                	mov    %ecx,%eax
  8004207d3c:	89 c2                	mov    %eax,%edx
  8004207d3e:	c1 fa 1f             	sar    $0x1f,%edx
  8004207d41:	f7 bd 6c ff ff ff    	idivl  -0x94(%rbp)
  8004207d47:	89 c2                	mov    %eax,%edx
  8004207d49:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  8004207d4d:	0f b6 40 18          	movzbl 0x18(%rax),%eax
  8004207d51:	0f b6 c0             	movzbl %al,%eax
  8004207d54:	0f af c2             	imul   %edx,%eax
  8004207d57:	48 98                	cltq   
  8004207d59:	48 01 45 f8          	add    %rax,-0x8(%rbp)
            APPEND_ROW;
  8004207d5d:	48 8b 85 78 ff ff ff 	mov    -0x88(%rbp),%rax
  8004207d64:	48 3b 45 f8          	cmp    -0x8(%rbp),%rax
  8004207d68:	73 0a                	jae    8004207d74 <_dwarf_lineno_run_program+0x4bc>
  8004207d6a:	b8 00 00 00 00       	mov    $0x0,%eax
  8004207d6f:	e9 af 00 00 00       	jmpq   8004207e23 <_dwarf_lineno_run_program+0x56b>
  8004207d74:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
  8004207d78:	48 8b 55 f8          	mov    -0x8(%rbp),%rdx
  8004207d7c:	48 89 10             	mov    %rdx,(%rax)
  8004207d7f:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
  8004207d83:	48 c7 40 08 00 00 00 	movq   $0x0,0x8(%rax)
  8004207d8a:	00 
  8004207d8b:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
  8004207d8f:	48 8b 55 f0          	mov    -0x10(%rbp),%rdx
  8004207d93:	48 89 50 10          	mov    %rdx,0x10(%rax)
  8004207d97:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
  8004207d9b:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  8004207d9f:	48 89 50 18          	mov    %rdx,0x18(%rax)
  8004207da3:	48 8b 55 e0          	mov    -0x20(%rbp),%rdx
  8004207da7:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
  8004207dab:	48 89 50 20          	mov    %rdx,0x20(%rax)
  8004207daf:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
  8004207db3:	8b 55 d8             	mov    -0x28(%rbp),%edx
  8004207db6:	89 50 28             	mov    %edx,0x28(%rax)
  8004207db9:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
  8004207dbd:	8b 55 dc             	mov    -0x24(%rbp),%edx
  8004207dc0:	89 50 2c             	mov    %edx,0x2c(%rax)
  8004207dc3:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
  8004207dc7:	8b 55 d4             	mov    -0x2c(%rbp),%edx
  8004207dca:	89 50 30             	mov    %edx,0x30(%rax)
  8004207dcd:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  8004207dd1:	48 8b 80 80 00 00 00 	mov    0x80(%rax),%rax
  8004207dd8:	48 8d 50 01          	lea    0x1(%rax),%rdx
  8004207ddc:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  8004207de0:	48 89 90 80 00 00 00 	mov    %rdx,0x80(%rax)
            basic_block = 0;
  8004207de7:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%rbp)
            prologue_end = 0;
  8004207dee:	c7 45 c4 00 00 00 00 	movl   $0x0,-0x3c(%rbp)
            epilogue_begin = 0;
  8004207df5:	c7 45 c0 00 00 00 00 	movl   $0x0,-0x40(%rbp)
            p++;
  8004207dfc:	48 8b 45 88          	mov    -0x78(%rbp),%rax
  8004207e00:	48 83 c0 01          	add    $0x1,%rax
  8004207e04:	48 89 45 88          	mov    %rax,-0x78(%rbp)
  8004207e08:	eb 01                	jmp    8004207e0b <_dwarf_lineno_run_program+0x553>
                p++;
                ret = _dwarf_lineno_add_file(li, &p, NULL,
                    error, dbg);
                if (ret != DW_DLE_NONE)
                    goto prog_fail;
                break;
  8004207e0a:	90                   	nop
    RESET_REGISTERS;

    /*
     * Start line number program.
     */
    while (p < pe) {
  8004207e0b:	48 8b 45 88          	mov    -0x78(%rbp),%rax
  8004207e0f:	48 3b 45 80          	cmp    -0x80(%rbp),%rax
  8004207e13:	0f 82 23 fb ff ff    	jb     800420793c <_dwarf_lineno_run_program+0x84>
            epilogue_begin = 0;
            p++;
        }
    }

    return (DW_DLE_NONE);
  8004207e19:	b8 00 00 00 00       	mov    $0x0,%eax
  8004207e1e:	eb 03                	jmp    8004207e23 <_dwarf_lineno_run_program+0x56b>

prog_fail:

    return (ret);
  8004207e20:	8b 45 b4             	mov    -0x4c(%rbp),%eax

#undef  RESET_REGISTERS
#undef  APPEND_ROW
#undef  LINE
#undef  ADDRESS
}
  8004207e23:	c9                   	leaveq 
  8004207e24:	c3                   	retq   

0000008004207e25 <_dwarf_lineno_add_file>:

static int
_dwarf_lineno_add_file(Dwarf_LineInfo li, uint8_t **p, const char *compdir,
    Dwarf_Error *error, Dwarf_Debug dbg)
{
  8004207e25:	55                   	push   %rbp
  8004207e26:	48 89 e5             	mov    %rsp,%rbp
  8004207e29:	53                   	push   %rbx
  8004207e2a:	48 83 ec 48          	sub    $0x48,%rsp
  8004207e2e:	48 89 7d d8          	mov    %rdi,-0x28(%rbp)
  8004207e32:	48 89 75 d0          	mov    %rsi,-0x30(%rbp)
  8004207e36:	48 89 55 c8          	mov    %rdx,-0x38(%rbp)
  8004207e3a:	48 89 4d c0          	mov    %rcx,-0x40(%rbp)
  8004207e3e:	4c 89 45 b8          	mov    %r8,-0x48(%rbp)
    char *fname;
    //const char *dirname;
    uint8_t *src;
    int slen;

    src = *p;
  8004207e42:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  8004207e46:	48 8b 00             	mov    (%rax),%rax
  8004207e49:	48 89 45 e0          	mov    %rax,-0x20(%rbp)
        DWARF_SET_ERROR(dbg, error, DW_DLE_MEMORY);
        return (DW_DLE_MEMORY);
    }
*/  
    //lf->lf_fullpath = NULL;
    fname = (char *) src;
  8004207e4d:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  8004207e51:	48 89 45 e8          	mov    %rax,-0x18(%rbp)
    src += strlen(fname) + 1;
  8004207e55:	48 8b 5d e0          	mov    -0x20(%rbp),%rbx
  8004207e59:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004207e5d:	48 89 c7             	mov    %rax,%rdi
  8004207e60:	48 b8 58 2b 20 04 80 	movabs $0x8004202b58,%rax
  8004207e67:	00 00 00 
  8004207e6a:	ff d0                	callq  *%rax
  8004207e6c:	48 98                	cltq   
  8004207e6e:	48 83 c0 01          	add    $0x1,%rax
  8004207e72:	48 01 d8             	add    %rbx,%rax
  8004207e75:	48 89 45 e0          	mov    %rax,-0x20(%rbp)
    _dwarf_decode_uleb128(&src);
  8004207e79:	48 8d 45 e0          	lea    -0x20(%rbp),%rax
  8004207e7d:	48 89 c7             	mov    %rax,%rdi
  8004207e80:	48 b8 82 3a 20 04 80 	movabs $0x8004203a82,%rax
  8004207e87:	00 00 00 
  8004207e8a:	ff d0                	callq  *%rax
            snprintf(lf->lf_fullpath, slen, "%s/%s", dirname,
                lf->lf_fname);
        }
    }
*/
    _dwarf_decode_uleb128(&src);
  8004207e8c:	48 8d 45 e0          	lea    -0x20(%rbp),%rax
  8004207e90:	48 89 c7             	mov    %rax,%rdi
  8004207e93:	48 b8 82 3a 20 04 80 	movabs $0x8004203a82,%rax
  8004207e9a:	00 00 00 
  8004207e9d:	ff d0                	callq  *%rax
    _dwarf_decode_uleb128(&src);
  8004207e9f:	48 8d 45 e0          	lea    -0x20(%rbp),%rax
  8004207ea3:	48 89 c7             	mov    %rax,%rdi
  8004207ea6:	48 b8 82 3a 20 04 80 	movabs $0x8004203a82,%rax
  8004207ead:	00 00 00 
  8004207eb0:	ff d0                	callq  *%rax
    //STAILQ_INSERT_TAIL(&li->li_lflist, lf, lf_next);
    //li->li_lflen++;

    *p = src;
  8004207eb2:	48 8b 55 e0          	mov    -0x20(%rbp),%rdx
  8004207eb6:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  8004207eba:	48 89 10             	mov    %rdx,(%rax)

    return (DW_DLE_NONE);
  8004207ebd:	b8 00 00 00 00       	mov    $0x0,%eax
}
  8004207ec2:	48 83 c4 48          	add    $0x48,%rsp
  8004207ec6:	5b                   	pop    %rbx
  8004207ec7:	5d                   	pop    %rbp
  8004207ec8:	c3                   	retq   

0000008004207ec9 <_dwarf_lineno_init>:

int     
_dwarf_lineno_init(Dwarf_Die *die, uint64_t offset, Dwarf_LineInfo linfo, Dwarf_Addr pc, Dwarf_Error *error)
{   
  8004207ec9:	55                   	push   %rbp
  8004207eca:	48 89 e5             	mov    %rsp,%rbp
  8004207ecd:	53                   	push   %rbx
  8004207ece:	48 81 ec 08 01 00 00 	sub    $0x108,%rsp
  8004207ed5:	48 89 bd 18 ff ff ff 	mov    %rdi,-0xe8(%rbp)
  8004207edc:	48 89 b5 10 ff ff ff 	mov    %rsi,-0xf0(%rbp)
  8004207ee3:	48 89 95 08 ff ff ff 	mov    %rdx,-0xf8(%rbp)
  8004207eea:	48 89 8d 00 ff ff ff 	mov    %rcx,-0x100(%rbp)
  8004207ef1:	4c 89 85 f8 fe ff ff 	mov    %r8,-0x108(%rbp)
    Dwarf_Section myds = {.ds_name = ".debug_line"};
  8004207ef8:	48 c7 45 90 00 00 00 	movq   $0x0,-0x70(%rbp)
  8004207eff:	00 
  8004207f00:	48 c7 45 98 00 00 00 	movq   $0x0,-0x68(%rbp)
  8004207f07:	00 
  8004207f08:	48 c7 45 a0 00 00 00 	movq   $0x0,-0x60(%rbp)
  8004207f0f:	00 
  8004207f10:	48 c7 45 a8 00 00 00 	movq   $0x0,-0x58(%rbp)
  8004207f17:	00 
  8004207f18:	48 b8 c8 a1 20 04 80 	movabs $0x800420a1c8,%rax
  8004207f1f:	00 00 00 
  8004207f22:	48 89 45 90          	mov    %rax,-0x70(%rbp)
	Dwarf_Section *ds = &myds;
  8004207f26:	48 8d 45 90          	lea    -0x70(%rbp),%rax
  8004207f2a:	48 89 45 d0          	mov    %rax,-0x30(%rbp)
    //Dwarf_LineFile lf, tlf;
    uint64_t length, hdroff, endoff;
    uint8_t *p;
    int dwarf_size, i, ret;
            
    cu = die->cu_header;
  8004207f2e:	48 8b 85 18 ff ff ff 	mov    -0xe8(%rbp),%rax
  8004207f35:	48 8b 80 60 03 00 00 	mov    0x360(%rax),%rax
  8004207f3c:	48 89 45 c8          	mov    %rax,-0x38(%rbp)
    assert(cu != NULL); 
  8004207f40:	48 83 7d c8 00       	cmpq   $0x0,-0x38(%rbp)
  8004207f45:	75 35                	jne    8004207f7c <_dwarf_lineno_init+0xb3>
  8004207f47:	48 b9 d4 a1 20 04 80 	movabs $0x800420a1d4,%rcx
  8004207f4e:	00 00 00 
  8004207f51:	48 ba df a1 20 04 80 	movabs $0x800420a1df,%rdx
  8004207f58:	00 00 00 
  8004207f5b:	be 17 01 00 00       	mov    $0x117,%esi
  8004207f60:	48 bf f4 a1 20 04 80 	movabs $0x800420a1f4,%rdi
  8004207f67:	00 00 00 
  8004207f6a:	b8 00 00 00 00       	mov    $0x0,%eax
  8004207f6f:	49 b8 9b 01 20 04 80 	movabs $0x800420019b,%r8
  8004207f76:	00 00 00 
  8004207f79:	41 ff d0             	callq  *%r8
    assert(dbg != NULL);
  8004207f7c:	48 b8 c8 b5 21 04 80 	movabs $0x800421b5c8,%rax
  8004207f83:	00 00 00 
  8004207f86:	48 8b 00             	mov    (%rax),%rax
  8004207f89:	48 85 c0             	test   %rax,%rax
  8004207f8c:	75 35                	jne    8004207fc3 <_dwarf_lineno_init+0xfa>
  8004207f8e:	48 b9 0b a2 20 04 80 	movabs $0x800420a20b,%rcx
  8004207f95:	00 00 00 
  8004207f98:	48 ba df a1 20 04 80 	movabs $0x800420a1df,%rdx
  8004207f9f:	00 00 00 
  8004207fa2:	be 18 01 00 00       	mov    $0x118,%esi
  8004207fa7:	48 bf f4 a1 20 04 80 	movabs $0x800420a1f4,%rdi
  8004207fae:	00 00 00 
  8004207fb1:	b8 00 00 00 00       	mov    $0x0,%eax
  8004207fb6:	49 b8 9b 01 20 04 80 	movabs $0x800420019b,%r8
  8004207fbd:	00 00 00 
  8004207fc0:	41 ff d0             	callq  *%r8

    if ((_dwarf_find_section_enhanced(ds)) != 0)
  8004207fc3:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  8004207fc7:	48 89 c7             	mov    %rax,%rdi
  8004207fca:	48 b8 47 52 20 04 80 	movabs $0x8004205247,%rax
  8004207fd1:	00 00 00 
  8004207fd4:	ff d0                	callq  *%rax
  8004207fd6:	85 c0                	test   %eax,%eax
  8004207fd8:	74 0a                	je     8004207fe4 <_dwarf_lineno_init+0x11b>
        return (DW_DLE_NONE);
  8004207fda:	b8 00 00 00 00       	mov    $0x0,%eax
  8004207fdf:	e9 7d 04 00 00       	jmpq   8004208461 <_dwarf_lineno_init+0x598>

	li = linfo;
  8004207fe4:	48 8b 85 08 ff ff ff 	mov    -0xf8(%rbp),%rax
  8004207feb:	48 89 45 c0          	mov    %rax,-0x40(%rbp)
            break;
        }
    }
     */

    length = dbg->read(ds->ds_data, &offset, 4);
  8004207fef:	48 b8 c8 b5 21 04 80 	movabs $0x800421b5c8,%rax
  8004207ff6:	00 00 00 
  8004207ff9:	48 8b 00             	mov    (%rax),%rax
  8004207ffc:	4c 8b 40 18          	mov    0x18(%rax),%r8
  8004208000:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  8004208004:	48 8b 40 08          	mov    0x8(%rax),%rax
  8004208008:	48 8d 8d 10 ff ff ff 	lea    -0xf0(%rbp),%rcx
  800420800f:	ba 04 00 00 00       	mov    $0x4,%edx
  8004208014:	48 89 ce             	mov    %rcx,%rsi
  8004208017:	48 89 c7             	mov    %rax,%rdi
  800420801a:	41 ff d0             	callq  *%r8
  800420801d:	48 89 45 e8          	mov    %rax,-0x18(%rbp)
    if (length == 0xffffffff) {
  8004208021:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  8004208026:	48 39 45 e8          	cmp    %rax,-0x18(%rbp)
  800420802a:	75 3b                	jne    8004208067 <_dwarf_lineno_init+0x19e>
        dwarf_size = 8;
  800420802c:	c7 45 e4 08 00 00 00 	movl   $0x8,-0x1c(%rbp)
        length = dbg->read(ds->ds_data, &offset, 8);
  8004208033:	48 b8 c8 b5 21 04 80 	movabs $0x800421b5c8,%rax
  800420803a:	00 00 00 
  800420803d:	48 8b 00             	mov    (%rax),%rax
  8004208040:	4c 8b 40 18          	mov    0x18(%rax),%r8
  8004208044:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  8004208048:	48 8b 40 08          	mov    0x8(%rax),%rax
  800420804c:	48 8d 8d 10 ff ff ff 	lea    -0xf0(%rbp),%rcx
  8004208053:	ba 08 00 00 00       	mov    $0x8,%edx
  8004208058:	48 89 ce             	mov    %rcx,%rsi
  800420805b:	48 89 c7             	mov    %rax,%rdi
  800420805e:	41 ff d0             	callq  *%r8
  8004208061:	48 89 45 e8          	mov    %rax,-0x18(%rbp)
  8004208065:	eb 07                	jmp    800420806e <_dwarf_lineno_init+0x1a5>
    } else
        dwarf_size = 4;
  8004208067:	c7 45 e4 04 00 00 00 	movl   $0x4,-0x1c(%rbp)

    if (length > ds->ds_size - offset) {
  800420806e:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  8004208072:	48 8b 50 18          	mov    0x18(%rax),%rdx
  8004208076:	48 8b 85 10 ff ff ff 	mov    -0xf0(%rbp),%rax
  800420807d:	48 89 d1             	mov    %rdx,%rcx
  8004208080:	48 29 c1             	sub    %rax,%rcx
  8004208083:	48 89 c8             	mov    %rcx,%rax
  8004208086:	48 3b 45 e8          	cmp    -0x18(%rbp),%rax
  800420808a:	73 0a                	jae    8004208096 <_dwarf_lineno_init+0x1cd>
        DWARF_SET_ERROR(dbg, error, DW_DLE_DEBUG_LINE_LENGTH_BAD);
        return (DW_DLE_DEBUG_LINE_LENGTH_BAD);
  800420808c:	b8 0f 00 00 00       	mov    $0xf,%eax
  8004208091:	e9 cb 03 00 00       	jmpq   8004208461 <_dwarf_lineno_init+0x598>
    }
    /*
     * Read in line number program header.
     */
    li->li_length = length;
  8004208096:	48 8b 45 c0          	mov    -0x40(%rbp),%rax
  800420809a:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  800420809e:	48 89 10             	mov    %rdx,(%rax)
    endoff = offset + length;
  80042080a1:	48 8b 85 10 ff ff ff 	mov    -0xf0(%rbp),%rax
  80042080a8:	48 03 45 e8          	add    -0x18(%rbp),%rax
  80042080ac:	48 89 45 b8          	mov    %rax,-0x48(%rbp)
    li->li_version = dbg->read(ds->ds_data, &offset, 2); /* FIXME: verify version */
  80042080b0:	48 b8 c8 b5 21 04 80 	movabs $0x800421b5c8,%rax
  80042080b7:	00 00 00 
  80042080ba:	48 8b 00             	mov    (%rax),%rax
  80042080bd:	4c 8b 40 18          	mov    0x18(%rax),%r8
  80042080c1:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  80042080c5:	48 8b 40 08          	mov    0x8(%rax),%rax
  80042080c9:	48 8d 8d 10 ff ff ff 	lea    -0xf0(%rbp),%rcx
  80042080d0:	ba 02 00 00 00       	mov    $0x2,%edx
  80042080d5:	48 89 ce             	mov    %rcx,%rsi
  80042080d8:	48 89 c7             	mov    %rax,%rdi
  80042080db:	41 ff d0             	callq  *%r8
  80042080de:	89 c2                	mov    %eax,%edx
  80042080e0:	48 8b 45 c0          	mov    -0x40(%rbp),%rax
  80042080e4:	66 89 50 08          	mov    %dx,0x8(%rax)
    li->li_hdrlen = dbg->read(ds->ds_data, &offset, dwarf_size);
  80042080e8:	48 b8 c8 b5 21 04 80 	movabs $0x800421b5c8,%rax
  80042080ef:	00 00 00 
  80042080f2:	48 8b 00             	mov    (%rax),%rax
  80042080f5:	4c 8b 40 18          	mov    0x18(%rax),%r8
  80042080f9:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  80042080fd:	48 8b 40 08          	mov    0x8(%rax),%rax
  8004208101:	8b 55 e4             	mov    -0x1c(%rbp),%edx
  8004208104:	48 8d 8d 10 ff ff ff 	lea    -0xf0(%rbp),%rcx
  800420810b:	48 89 ce             	mov    %rcx,%rsi
  800420810e:	48 89 c7             	mov    %rax,%rdi
  8004208111:	41 ff d0             	callq  *%r8
  8004208114:	48 8b 55 c0          	mov    -0x40(%rbp),%rdx
  8004208118:	48 89 42 10          	mov    %rax,0x10(%rdx)
    hdroff = offset;
  800420811c:	48 8b 85 10 ff ff ff 	mov    -0xf0(%rbp),%rax
  8004208123:	48 89 45 b0          	mov    %rax,-0x50(%rbp)
    li->li_minlen = dbg->read(ds->ds_data, &offset, 1);
  8004208127:	48 b8 c8 b5 21 04 80 	movabs $0x800421b5c8,%rax
  800420812e:	00 00 00 
  8004208131:	48 8b 00             	mov    (%rax),%rax
  8004208134:	4c 8b 40 18          	mov    0x18(%rax),%r8
  8004208138:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  800420813c:	48 8b 40 08          	mov    0x8(%rax),%rax
  8004208140:	48 8d 8d 10 ff ff ff 	lea    -0xf0(%rbp),%rcx
  8004208147:	ba 01 00 00 00       	mov    $0x1,%edx
  800420814c:	48 89 ce             	mov    %rcx,%rsi
  800420814f:	48 89 c7             	mov    %rax,%rdi
  8004208152:	41 ff d0             	callq  *%r8
  8004208155:	89 c2                	mov    %eax,%edx
  8004208157:	48 8b 45 c0          	mov    -0x40(%rbp),%rax
  800420815b:	88 50 18             	mov    %dl,0x18(%rax)
    li->li_defstmt = dbg->read(ds->ds_data, &offset, 1);
  800420815e:	48 b8 c8 b5 21 04 80 	movabs $0x800421b5c8,%rax
  8004208165:	00 00 00 
  8004208168:	48 8b 00             	mov    (%rax),%rax
  800420816b:	4c 8b 40 18          	mov    0x18(%rax),%r8
  800420816f:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  8004208173:	48 8b 40 08          	mov    0x8(%rax),%rax
  8004208177:	48 8d 8d 10 ff ff ff 	lea    -0xf0(%rbp),%rcx
  800420817e:	ba 01 00 00 00       	mov    $0x1,%edx
  8004208183:	48 89 ce             	mov    %rcx,%rsi
  8004208186:	48 89 c7             	mov    %rax,%rdi
  8004208189:	41 ff d0             	callq  *%r8
  800420818c:	89 c2                	mov    %eax,%edx
  800420818e:	48 8b 45 c0          	mov    -0x40(%rbp),%rax
  8004208192:	88 50 19             	mov    %dl,0x19(%rax)
    li->li_lbase = dbg->read(ds->ds_data, &offset, 1);
  8004208195:	48 b8 c8 b5 21 04 80 	movabs $0x800421b5c8,%rax
  800420819c:	00 00 00 
  800420819f:	48 8b 00             	mov    (%rax),%rax
  80042081a2:	4c 8b 40 18          	mov    0x18(%rax),%r8
  80042081a6:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  80042081aa:	48 8b 40 08          	mov    0x8(%rax),%rax
  80042081ae:	48 8d 8d 10 ff ff ff 	lea    -0xf0(%rbp),%rcx
  80042081b5:	ba 01 00 00 00       	mov    $0x1,%edx
  80042081ba:	48 89 ce             	mov    %rcx,%rsi
  80042081bd:	48 89 c7             	mov    %rax,%rdi
  80042081c0:	41 ff d0             	callq  *%r8
  80042081c3:	89 c2                	mov    %eax,%edx
  80042081c5:	48 8b 45 c0          	mov    -0x40(%rbp),%rax
  80042081c9:	88 50 1a             	mov    %dl,0x1a(%rax)
    li->li_lrange = dbg->read(ds->ds_data, &offset, 1);
  80042081cc:	48 b8 c8 b5 21 04 80 	movabs $0x800421b5c8,%rax
  80042081d3:	00 00 00 
  80042081d6:	48 8b 00             	mov    (%rax),%rax
  80042081d9:	4c 8b 40 18          	mov    0x18(%rax),%r8
  80042081dd:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  80042081e1:	48 8b 40 08          	mov    0x8(%rax),%rax
  80042081e5:	48 8d 8d 10 ff ff ff 	lea    -0xf0(%rbp),%rcx
  80042081ec:	ba 01 00 00 00       	mov    $0x1,%edx
  80042081f1:	48 89 ce             	mov    %rcx,%rsi
  80042081f4:	48 89 c7             	mov    %rax,%rdi
  80042081f7:	41 ff d0             	callq  *%r8
  80042081fa:	89 c2                	mov    %eax,%edx
  80042081fc:	48 8b 45 c0          	mov    -0x40(%rbp),%rax
  8004208200:	88 50 1b             	mov    %dl,0x1b(%rax)
    li->li_opbase = dbg->read(ds->ds_data, &offset, 1);
  8004208203:	48 b8 c8 b5 21 04 80 	movabs $0x800421b5c8,%rax
  800420820a:	00 00 00 
  800420820d:	48 8b 00             	mov    (%rax),%rax
  8004208210:	4c 8b 40 18          	mov    0x18(%rax),%r8
  8004208214:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  8004208218:	48 8b 40 08          	mov    0x8(%rax),%rax
  800420821c:	48 8d 8d 10 ff ff ff 	lea    -0xf0(%rbp),%rcx
  8004208223:	ba 01 00 00 00       	mov    $0x1,%edx
  8004208228:	48 89 ce             	mov    %rcx,%rsi
  800420822b:	48 89 c7             	mov    %rax,%rdi
  800420822e:	41 ff d0             	callq  *%r8
  8004208231:	89 c2                	mov    %eax,%edx
  8004208233:	48 8b 45 c0          	mov    -0x40(%rbp),%rax
  8004208237:	88 50 1c             	mov    %dl,0x1c(%rax)
    //STAILQ_INIT(&li->li_lflist);
    //STAILQ_INIT(&li->li_lnlist);

    if ((int)li->li_hdrlen - 5 < li->li_opbase - 1) {
  800420823a:	48 8b 45 c0          	mov    -0x40(%rbp),%rax
  800420823e:	48 8b 40 10          	mov    0x10(%rax),%rax
  8004208242:	8d 50 fb             	lea    -0x5(%rax),%edx
  8004208245:	48 8b 45 c0          	mov    -0x40(%rbp),%rax
  8004208249:	0f b6 40 1c          	movzbl 0x1c(%rax),%eax
  800420824d:	0f b6 c0             	movzbl %al,%eax
  8004208250:	83 e8 01             	sub    $0x1,%eax
  8004208253:	39 c2                	cmp    %eax,%edx
  8004208255:	7d 0c                	jge    8004208263 <_dwarf_lineno_init+0x39a>
        ret = DW_DLE_DEBUG_LINE_LENGTH_BAD;
  8004208257:	c7 45 dc 0f 00 00 00 	movl   $0xf,-0x24(%rbp)
        DWARF_SET_ERROR(dbg, error, ret);
        goto fail_cleanup;
  800420825e:	e9 fb 01 00 00       	jmpq   800420845e <_dwarf_lineno_init+0x595>
    }

    li->li_oplen = global_std_op;
  8004208263:	48 8b 45 c0          	mov    -0x40(%rbp),%rax
  8004208267:	48 ba 60 ca 21 04 80 	movabs $0x800421ca60,%rdx
  800420826e:	00 00 00 
  8004208271:	48 89 50 20          	mov    %rdx,0x20(%rax)

    /*
     * Read in std opcode arg length list. Note that the first
     * element is not used.
     */
    for (i = 1; i < li->li_opbase; i++)
  8004208275:	c7 45 e0 01 00 00 00 	movl   $0x1,-0x20(%rbp)
  800420827c:	eb 45                	jmp    80042082c3 <_dwarf_lineno_init+0x3fa>
        li->li_oplen[i] = dbg->read(ds->ds_data, &offset, 1);
  800420827e:	48 8b 45 c0          	mov    -0x40(%rbp),%rax
  8004208282:	48 8b 50 20          	mov    0x20(%rax),%rdx
  8004208286:	8b 45 e0             	mov    -0x20(%rbp),%eax
  8004208289:	48 98                	cltq   
  800420828b:	48 8d 1c 02          	lea    (%rdx,%rax,1),%rbx
  800420828f:	48 b8 c8 b5 21 04 80 	movabs $0x800421b5c8,%rax
  8004208296:	00 00 00 
  8004208299:	48 8b 00             	mov    (%rax),%rax
  800420829c:	4c 8b 40 18          	mov    0x18(%rax),%r8
  80042082a0:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  80042082a4:	48 8b 40 08          	mov    0x8(%rax),%rax
  80042082a8:	48 8d 8d 10 ff ff ff 	lea    -0xf0(%rbp),%rcx
  80042082af:	ba 01 00 00 00       	mov    $0x1,%edx
  80042082b4:	48 89 ce             	mov    %rcx,%rsi
  80042082b7:	48 89 c7             	mov    %rax,%rdi
  80042082ba:	41 ff d0             	callq  *%r8
  80042082bd:	88 03                	mov    %al,(%rbx)

    /*
     * Read in std opcode arg length list. Note that the first
     * element is not used.
     */
    for (i = 1; i < li->li_opbase; i++)
  80042082bf:	83 45 e0 01          	addl   $0x1,-0x20(%rbp)
  80042082c3:	48 8b 45 c0          	mov    -0x40(%rbp),%rax
  80042082c7:	0f b6 40 1c          	movzbl 0x1c(%rax),%eax
  80042082cb:	0f b6 c0             	movzbl %al,%eax
  80042082ce:	3b 45 e0             	cmp    -0x20(%rbp),%eax
  80042082d1:	7f ab                	jg     800420827e <_dwarf_lineno_init+0x3b5>
        li->li_oplen[i] = dbg->read(ds->ds_data, &offset, 1);

    /*
     * Check how many strings in the include dir string array.
     */
    length = 0;
  80042082d3:	48 c7 45 e8 00 00 00 	movq   $0x0,-0x18(%rbp)
  80042082da:	00 
    p = ds->ds_data + offset;
  80042082db:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  80042082df:	48 8b 50 08          	mov    0x8(%rax),%rdx
  80042082e3:	48 8b 85 10 ff ff ff 	mov    -0xf0(%rbp),%rax
  80042082ea:	48 01 d0             	add    %rdx,%rax
  80042082ed:	48 89 85 28 ff ff ff 	mov    %rax,-0xd8(%rbp)
    while (*p != '\0') {
  80042082f4:	eb 24                	jmp    800420831a <_dwarf_lineno_init+0x451>
        while (*p++ != '\0')
  80042082f6:	90                   	nop
  80042082f7:	48 8b 85 28 ff ff ff 	mov    -0xd8(%rbp),%rax
  80042082fe:	0f b6 10             	movzbl (%rax),%edx
  8004208301:	84 d2                	test   %dl,%dl
  8004208303:	0f 95 c2             	setne  %dl
  8004208306:	48 83 c0 01          	add    $0x1,%rax
  800420830a:	48 89 85 28 ff ff ff 	mov    %rax,-0xd8(%rbp)
  8004208311:	84 d2                	test   %dl,%dl
  8004208313:	75 e2                	jne    80042082f7 <_dwarf_lineno_init+0x42e>
            ;
        length++;
  8004208315:	48 83 45 e8 01       	addq   $0x1,-0x18(%rbp)
    /*
     * Check how many strings in the include dir string array.
     */
    length = 0;
    p = ds->ds_data + offset;
    while (*p != '\0') {
  800420831a:	48 8b 85 28 ff ff ff 	mov    -0xd8(%rbp),%rax
  8004208321:	0f b6 00             	movzbl (%rax),%eax
  8004208324:	84 c0                	test   %al,%al
  8004208326:	75 ce                	jne    80042082f6 <_dwarf_lineno_init+0x42d>
        while (*p++ != '\0')
            ;
        length++;
    }
    li->li_inclen = length;
  8004208328:	48 8b 45 c0          	mov    -0x40(%rbp),%rax
  800420832c:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  8004208330:	48 89 50 30          	mov    %rdx,0x30(%rax)

    /* Sanity check. */
    if (p - ds->ds_data > (int) ds->ds_size) {
  8004208334:	48 8b 85 28 ff ff ff 	mov    -0xd8(%rbp),%rax
  800420833b:	48 89 c2             	mov    %rax,%rdx
  800420833e:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  8004208342:	48 8b 40 08          	mov    0x8(%rax),%rax
  8004208346:	48 29 c2             	sub    %rax,%rdx
  8004208349:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  800420834d:	48 8b 40 18          	mov    0x18(%rax),%rax
  8004208351:	48 98                	cltq   
  8004208353:	48 39 c2             	cmp    %rax,%rdx
  8004208356:	7e 0c                	jle    8004208364 <_dwarf_lineno_init+0x49b>
        ret = DW_DLE_DEBUG_LINE_LENGTH_BAD;
  8004208358:	c7 45 dc 0f 00 00 00 	movl   $0xf,-0x24(%rbp)
        DWARF_SET_ERROR(dbg, error, ret);
        goto fail_cleanup;
  800420835f:	e9 fa 00 00 00       	jmpq   800420845e <_dwarf_lineno_init+0x595>
        li->li_incdirs[i++] = (char *) p;
        while (*p++ != '\0')
            ;
    }
*/
    p++;
  8004208364:	48 8b 85 28 ff ff ff 	mov    -0xd8(%rbp),%rax
  800420836b:	48 83 c0 01          	add    $0x1,%rax
  800420836f:	48 89 85 28 ff ff ff 	mov    %rax,-0xd8(%rbp)

    /*
     * Process file list.
     */
    while (*p != '\0') {
  8004208376:	eb 3c                	jmp    80042083b4 <_dwarf_lineno_init+0x4eb>
        ret = _dwarf_lineno_add_file(li, &p, NULL, error, dbg);
  8004208378:	48 b8 c8 b5 21 04 80 	movabs $0x800421b5c8,%rax
  800420837f:	00 00 00 
  8004208382:	48 8b 08             	mov    (%rax),%rcx
  8004208385:	48 8b 95 f8 fe ff ff 	mov    -0x108(%rbp),%rdx
  800420838c:	48 8d b5 28 ff ff ff 	lea    -0xd8(%rbp),%rsi
  8004208393:	48 8b 45 c0          	mov    -0x40(%rbp),%rax
  8004208397:	49 89 c8             	mov    %rcx,%r8
  800420839a:	48 89 d1             	mov    %rdx,%rcx
  800420839d:	ba 00 00 00 00       	mov    $0x0,%edx
  80042083a2:	48 89 c7             	mov    %rax,%rdi
  80042083a5:	48 b8 25 7e 20 04 80 	movabs $0x8004207e25,%rax
  80042083ac:	00 00 00 
  80042083af:	ff d0                	callq  *%rax
  80042083b1:	89 45 dc             	mov    %eax,-0x24(%rbp)
    p++;

    /*
     * Process file list.
     */
    while (*p != '\0') {
  80042083b4:	48 8b 85 28 ff ff ff 	mov    -0xd8(%rbp),%rax
  80042083bb:	0f b6 00             	movzbl (%rax),%eax
  80042083be:	84 c0                	test   %al,%al
  80042083c0:	75 b6                	jne    8004208378 <_dwarf_lineno_init+0x4af>
        ret = _dwarf_lineno_add_file(li, &p, NULL, error, dbg);
		//p++;
    }

    p++;
  80042083c2:	48 8b 85 28 ff ff ff 	mov    -0xd8(%rbp),%rax
  80042083c9:	48 83 c0 01          	add    $0x1,%rax
  80042083cd:	48 89 85 28 ff ff ff 	mov    %rax,-0xd8(%rbp)
    /* Sanity check. */
    if (p - ds->ds_data - hdroff != li->li_hdrlen) {
  80042083d4:	48 8b 85 28 ff ff ff 	mov    -0xd8(%rbp),%rax
  80042083db:	48 89 c2             	mov    %rax,%rdx
  80042083de:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  80042083e2:	48 8b 40 08          	mov    0x8(%rax),%rax
  80042083e6:	48 89 d1             	mov    %rdx,%rcx
  80042083e9:	48 29 c1             	sub    %rax,%rcx
  80042083ec:	48 89 c8             	mov    %rcx,%rax
  80042083ef:	48 89 c2             	mov    %rax,%rdx
  80042083f2:	48 2b 55 b0          	sub    -0x50(%rbp),%rdx
  80042083f6:	48 8b 45 c0          	mov    -0x40(%rbp),%rax
  80042083fa:	48 8b 40 10          	mov    0x10(%rax),%rax
  80042083fe:	48 39 c2             	cmp    %rax,%rdx
  8004208401:	74 09                	je     800420840c <_dwarf_lineno_init+0x543>
        ret = DW_DLE_DEBUG_LINE_LENGTH_BAD;
  8004208403:	c7 45 dc 0f 00 00 00 	movl   $0xf,-0x24(%rbp)
        DWARF_SET_ERROR(dbg, error, ret);
        goto fail_cleanup;
  800420840a:	eb 52                	jmp    800420845e <_dwarf_lineno_init+0x595>
    }

    /*
     * Process line number program.
     */
    ret = _dwarf_lineno_run_program(cu, li, p, ds->ds_data + endoff, pc,
  800420840c:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  8004208410:	48 8b 40 08          	mov    0x8(%rax),%rax
  8004208414:	48 89 c1             	mov    %rax,%rcx
  8004208417:	48 03 4d b8          	add    -0x48(%rbp),%rcx
  800420841b:	48 8b 95 28 ff ff ff 	mov    -0xd8(%rbp),%rdx
  8004208422:	4c 8b 85 f8 fe ff ff 	mov    -0x108(%rbp),%r8
  8004208429:	48 8b bd 00 ff ff ff 	mov    -0x100(%rbp),%rdi
  8004208430:	48 8b 75 c0          	mov    -0x40(%rbp),%rsi
  8004208434:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
  8004208438:	4d 89 c1             	mov    %r8,%r9
  800420843b:	49 89 f8             	mov    %rdi,%r8
  800420843e:	48 89 c7             	mov    %rax,%rdi
  8004208441:	48 b8 b8 78 20 04 80 	movabs $0x80042078b8,%rax
  8004208448:	00 00 00 
  800420844b:	ff d0                	callq  *%rax
  800420844d:	89 45 dc             	mov    %eax,-0x24(%rbp)
        error);
    if (ret != DW_DLE_NONE)
  8004208450:	83 7d dc 00          	cmpl   $0x0,-0x24(%rbp)
  8004208454:	75 07                	jne    800420845d <_dwarf_lineno_init+0x594>
        goto fail_cleanup;

    //cu->cu_lineinfo = li;

    return (DW_DLE_NONE);
  8004208456:	b8 00 00 00 00       	mov    $0x0,%eax
  800420845b:	eb 04                	jmp    8004208461 <_dwarf_lineno_init+0x598>
     * Process line number program.
     */
    ret = _dwarf_lineno_run_program(cu, li, p, ds->ds_data + endoff, pc,
        error);
    if (ret != DW_DLE_NONE)
        goto fail_cleanup;
  800420845d:	90                   	nop
fail_cleanup:

    /*if (li->li_oplen)
        free(li->li_oplen);*/

    return (ret);
  800420845e:	8b 45 dc             	mov    -0x24(%rbp),%eax
}
  8004208461:	48 81 c4 08 01 00 00 	add    $0x108,%rsp
  8004208468:	5b                   	pop    %rbx
  8004208469:	5d                   	pop    %rbp
  800420846a:	c3                   	retq   

000000800420846b <dwarf_srclines>:

int
dwarf_srclines(Dwarf_Die *die, Dwarf_Line linebuf, Dwarf_Addr pc, Dwarf_Error *error)
{
  800420846b:	55                   	push   %rbp
  800420846c:	48 89 e5             	mov    %rsp,%rbp
  800420846f:	48 81 ec b0 00 00 00 	sub    $0xb0,%rsp
  8004208476:	48 89 bd 68 ff ff ff 	mov    %rdi,-0x98(%rbp)
  800420847d:	48 89 b5 60 ff ff ff 	mov    %rsi,-0xa0(%rbp)
  8004208484:	48 89 95 58 ff ff ff 	mov    %rdx,-0xa8(%rbp)
  800420848b:	48 89 8d 50 ff ff ff 	mov    %rcx,-0xb0(%rbp)
    _Dwarf_LineInfo li;
    Dwarf_Attribute *at;

	assert(die);
  8004208492:	48 83 bd 68 ff ff ff 	cmpq   $0x0,-0x98(%rbp)
  8004208499:	00 
  800420849a:	75 35                	jne    80042084d1 <dwarf_srclines+0x66>
  800420849c:	48 b9 17 a2 20 04 80 	movabs $0x800420a217,%rcx
  80042084a3:	00 00 00 
  80042084a6:	48 ba df a1 20 04 80 	movabs $0x800420a1df,%rdx
  80042084ad:	00 00 00 
  80042084b0:	be ae 01 00 00       	mov    $0x1ae,%esi
  80042084b5:	48 bf f4 a1 20 04 80 	movabs $0x800420a1f4,%rdi
  80042084bc:	00 00 00 
  80042084bf:	b8 00 00 00 00       	mov    $0x0,%eax
  80042084c4:	49 b8 9b 01 20 04 80 	movabs $0x800420019b,%r8
  80042084cb:	00 00 00 
  80042084ce:	41 ff d0             	callq  *%r8
	assert(linebuf);
  80042084d1:	48 83 bd 60 ff ff ff 	cmpq   $0x0,-0xa0(%rbp)
  80042084d8:	00 
  80042084d9:	75 35                	jne    8004208510 <dwarf_srclines+0xa5>
  80042084db:	48 b9 1b a2 20 04 80 	movabs $0x800420a21b,%rcx
  80042084e2:	00 00 00 
  80042084e5:	48 ba df a1 20 04 80 	movabs $0x800420a1df,%rdx
  80042084ec:	00 00 00 
  80042084ef:	be af 01 00 00       	mov    $0x1af,%esi
  80042084f4:	48 bf f4 a1 20 04 80 	movabs $0x800420a1f4,%rdi
  80042084fb:	00 00 00 
  80042084fe:	b8 00 00 00 00       	mov    $0x0,%eax
  8004208503:	49 b8 9b 01 20 04 80 	movabs $0x800420019b,%r8
  800420850a:	00 00 00 
  800420850d:	41 ff d0             	callq  *%r8

	memset(&li, 0, sizeof(_Dwarf_LineInfo));
  8004208510:	48 8d 85 70 ff ff ff 	lea    -0x90(%rbp),%rax
  8004208517:	ba 88 00 00 00       	mov    $0x88,%edx
  800420851c:	be 00 00 00 00       	mov    $0x0,%esi
  8004208521:	48 89 c7             	mov    %rax,%rdi
  8004208524:	48 b8 5b 2e 20 04 80 	movabs $0x8004202e5b,%rax
  800420852b:	00 00 00 
  800420852e:	ff d0                	callq  *%rax

    if ((at = _dwarf_attr_find(die, DW_AT_stmt_list)) == NULL) {
  8004208530:	48 8b 85 68 ff ff ff 	mov    -0x98(%rbp),%rax
  8004208537:	be 10 00 00 00       	mov    $0x10,%esi
  800420853c:	48 89 c7             	mov    %rax,%rdi
  800420853f:	48 b8 cc 4d 20 04 80 	movabs $0x8004204dcc,%rax
  8004208546:	00 00 00 
  8004208549:	ff d0                	callq  *%rax
  800420854b:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
  800420854f:	48 83 7d f8 00       	cmpq   $0x0,-0x8(%rbp)
  8004208554:	75 0a                	jne    8004208560 <dwarf_srclines+0xf5>
        DWARF_SET_ERROR(dbg, error, DW_DLE_NO_ENTRY);
        return (DW_DLV_NO_ENTRY);
  8004208556:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  800420855b:	e9 84 00 00 00       	jmpq   80042085e4 <dwarf_srclines+0x179>
    }

    if (_dwarf_lineno_init(die, at->u[0].u64, &li, pc, error) !=
  8004208560:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8004208564:	48 8b 70 28          	mov    0x28(%rax),%rsi
  8004208568:	48 8b bd 50 ff ff ff 	mov    -0xb0(%rbp),%rdi
  800420856f:	48 8b 8d 58 ff ff ff 	mov    -0xa8(%rbp),%rcx
  8004208576:	48 8d 95 70 ff ff ff 	lea    -0x90(%rbp),%rdx
  800420857d:	48 8b 85 68 ff ff ff 	mov    -0x98(%rbp),%rax
  8004208584:	49 89 f8             	mov    %rdi,%r8
  8004208587:	48 89 c7             	mov    %rax,%rdi
  800420858a:	48 b8 c9 7e 20 04 80 	movabs $0x8004207ec9,%rax
  8004208591:	00 00 00 
  8004208594:	ff d0                	callq  *%rax
  8004208596:	85 c0                	test   %eax,%eax
  8004208598:	74 07                	je     80042085a1 <dwarf_srclines+0x136>
        DW_DLE_NONE)
	{
          return (DW_DLV_ERROR);
  800420859a:	b8 01 00 00 00       	mov    $0x1,%eax
  800420859f:	eb 43                	jmp    80042085e4 <dwarf_srclines+0x179>
	}
    *linebuf = li.li_line;
  80042085a1:	48 8b 85 60 ff ff ff 	mov    -0xa0(%rbp),%rax
  80042085a8:	48 8b 55 b8          	mov    -0x48(%rbp),%rdx
  80042085ac:	48 89 10             	mov    %rdx,(%rax)
  80042085af:	48 8b 55 c0          	mov    -0x40(%rbp),%rdx
  80042085b3:	48 89 50 08          	mov    %rdx,0x8(%rax)
  80042085b7:	48 8b 55 c8          	mov    -0x38(%rbp),%rdx
  80042085bb:	48 89 50 10          	mov    %rdx,0x10(%rax)
  80042085bf:	48 8b 55 d0          	mov    -0x30(%rbp),%rdx
  80042085c3:	48 89 50 18          	mov    %rdx,0x18(%rax)
  80042085c7:	48 8b 55 d8          	mov    -0x28(%rbp),%rdx
  80042085cb:	48 89 50 20          	mov    %rdx,0x20(%rax)
  80042085cf:	48 8b 55 e0          	mov    -0x20(%rbp),%rdx
  80042085d3:	48 89 50 28          	mov    %rdx,0x28(%rax)
  80042085d7:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  80042085db:	48 89 50 30          	mov    %rdx,0x30(%rax)

    return (DW_DLV_OK);
  80042085df:	b8 00 00 00 00       	mov    $0x0,%eax
}
  80042085e4:	c9                   	leaveq 
  80042085e5:	c3                   	retq   
	...

00000080042085e8 <_dwarf_find_section>:
uintptr_t
read_section_headers(uintptr_t, uintptr_t);

Dwarf_Section *
_dwarf_find_section(const char *name)
{
  80042085e8:	55                   	push   %rbp
  80042085e9:	48 89 e5             	mov    %rsp,%rbp
  80042085ec:	48 83 ec 20          	sub    $0x20,%rsp
  80042085f0:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
    Dwarf_Section *ret=NULL;
  80042085f4:	48 c7 45 f8 00 00 00 	movq   $0x0,-0x8(%rbp)
  80042085fb:	00 
    int i;

    for(i=0; i < NDEBUG_SECT; i++) {
  80042085fc:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%rbp)
  8004208603:	eb 57                	jmp    800420865c <_dwarf_find_section+0x74>
        if(!strcmp(section_info[i].ds_name, name)) {
  8004208605:	48 b8 20 b6 21 04 80 	movabs $0x800421b620,%rax
  800420860c:	00 00 00 
  800420860f:	8b 55 f4             	mov    -0xc(%rbp),%edx
  8004208612:	48 63 d2             	movslq %edx,%rdx
  8004208615:	48 c1 e2 05          	shl    $0x5,%rdx
  8004208619:	48 01 d0             	add    %rdx,%rax
  800420861c:	48 8b 00             	mov    (%rax),%rax
  800420861f:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  8004208623:	48 89 d6             	mov    %rdx,%rsi
  8004208626:	48 89 c7             	mov    %rax,%rdi
  8004208629:	48 b8 1f 2d 20 04 80 	movabs $0x8004202d1f,%rax
  8004208630:	00 00 00 
  8004208633:	ff d0                	callq  *%rax
  8004208635:	85 c0                	test   %eax,%eax
  8004208637:	75 1f                	jne    8004208658 <_dwarf_find_section+0x70>
            ret = (section_info + i);
  8004208639:	8b 45 f4             	mov    -0xc(%rbp),%eax
  800420863c:	48 98                	cltq   
  800420863e:	48 89 c2             	mov    %rax,%rdx
  8004208641:	48 c1 e2 05          	shl    $0x5,%rdx
  8004208645:	48 b8 20 b6 21 04 80 	movabs $0x800421b620,%rax
  800420864c:	00 00 00 
  800420864f:	48 01 d0             	add    %rdx,%rax
  8004208652:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
            break;
  8004208656:	eb 0a                	jmp    8004208662 <_dwarf_find_section+0x7a>
_dwarf_find_section(const char *name)
{
    Dwarf_Section *ret=NULL;
    int i;

    for(i=0; i < NDEBUG_SECT; i++) {
  8004208658:	83 45 f4 01          	addl   $0x1,-0xc(%rbp)
  800420865c:	83 7d f4 04          	cmpl   $0x4,-0xc(%rbp)
  8004208660:	7e a3                	jle    8004208605 <_dwarf_find_section+0x1d>
            ret = (section_info + i);
            break;
        }
    }

    return ret;
  8004208662:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
}
  8004208666:	c9                   	leaveq 
  8004208667:	c3                   	retq   

0000008004208668 <find_debug_sections>:

void find_debug_sections(uintptr_t elf) 
{
  8004208668:	55                   	push   %rbp
  8004208669:	48 89 e5             	mov    %rsp,%rbp
  800420866c:	48 83 ec 40          	sub    $0x40,%rsp
  8004208670:	48 89 7d c8          	mov    %rdi,-0x38(%rbp)
    Elf *ehdr = (Elf *)elf;
  8004208674:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
  8004208678:	48 89 45 e8          	mov    %rax,-0x18(%rbp)
    uintptr_t debug_address = USTABDATA;
  800420867c:	48 c7 45 f8 00 00 20 	movq   $0x200000,-0x8(%rbp)
  8004208683:	00 
    Secthdr *sh = (Secthdr *)(((uint8_t *)ehdr + ehdr->e_shoff));
  8004208684:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004208688:	48 8b 40 28          	mov    0x28(%rax),%rax
  800420868c:	48 03 45 e8          	add    -0x18(%rbp),%rax
  8004208690:	48 89 45 f0          	mov    %rax,-0x10(%rbp)
    Secthdr *shstr_tab = sh + ehdr->e_shstrndx;
  8004208694:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004208698:	0f b7 40 3e          	movzwl 0x3e(%rax),%eax
  800420869c:	0f b7 c0             	movzwl %ax,%eax
  800420869f:	48 c1 e0 06          	shl    $0x6,%rax
  80042086a3:	48 03 45 f0          	add    -0x10(%rbp),%rax
  80042086a7:	48 89 45 e0          	mov    %rax,-0x20(%rbp)
    Secthdr* esh = sh + ehdr->e_shnum;
  80042086ab:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  80042086af:	0f b7 40 3c          	movzwl 0x3c(%rax),%eax
  80042086b3:	0f b7 c0             	movzwl %ax,%eax
  80042086b6:	48 c1 e0 06          	shl    $0x6,%rax
  80042086ba:	48 03 45 f0          	add    -0x10(%rbp),%rax
  80042086be:	48 89 45 d8          	mov    %rax,-0x28(%rbp)
    for(;sh < esh; sh++) {
  80042086c2:	e9 48 02 00 00       	jmpq   800420890f <find_debug_sections+0x2a7>
        char* name = (char*)((uint8_t*)elf + shstr_tab->sh_offset) + sh->sh_name;
  80042086c7:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  80042086cb:	8b 00                	mov    (%rax),%eax
  80042086cd:	89 c2                	mov    %eax,%edx
  80042086cf:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  80042086d3:	48 8b 40 18          	mov    0x18(%rax),%rax
  80042086d7:	48 03 45 c8          	add    -0x38(%rbp),%rax
  80042086db:	48 01 d0             	add    %rdx,%rax
  80042086de:	48 89 45 d0          	mov    %rax,-0x30(%rbp)
		if(!strcmp(name, ".debug_info")) {
  80042086e2:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  80042086e6:	48 be 23 a2 20 04 80 	movabs $0x800420a223,%rsi
  80042086ed:	00 00 00 
  80042086f0:	48 89 c7             	mov    %rax,%rdi
  80042086f3:	48 b8 1f 2d 20 04 80 	movabs $0x8004202d1f,%rax
  80042086fa:	00 00 00 
  80042086fd:	ff d0                	callq  *%rax
  80042086ff:	85 c0                	test   %eax,%eax
  8004208701:	75 4b                	jne    800420874e <find_debug_sections+0xe6>
            section_info[DEBUG_INFO].ds_data = (uint8_t*)debug_address;
  8004208703:	48 8b 55 f8          	mov    -0x8(%rbp),%rdx
  8004208707:	48 b8 20 b6 21 04 80 	movabs $0x800421b620,%rax
  800420870e:	00 00 00 
  8004208711:	48 89 50 08          	mov    %rdx,0x8(%rax)
			section_info[DEBUG_INFO].ds_addr = debug_address;
  8004208715:	48 b8 20 b6 21 04 80 	movabs $0x800421b620,%rax
  800420871c:	00 00 00 
  800420871f:	48 8b 55 f8          	mov    -0x8(%rbp),%rdx
  8004208723:	48 89 50 10          	mov    %rdx,0x10(%rax)
			section_info[DEBUG_INFO].ds_size = sh->sh_size;
  8004208727:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  800420872b:	48 8b 50 20          	mov    0x20(%rax),%rdx
  800420872f:	48 b8 20 b6 21 04 80 	movabs $0x800421b620,%rax
  8004208736:	00 00 00 
  8004208739:	48 89 50 18          	mov    %rdx,0x18(%rax)
            debug_address += sh->sh_size;
  800420873d:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8004208741:	48 8b 40 20          	mov    0x20(%rax),%rax
  8004208745:	48 01 45 f8          	add    %rax,-0x8(%rbp)
  8004208749:	e9 bc 01 00 00       	jmpq   800420890a <find_debug_sections+0x2a2>
        } else if(!strcmp(name, ".debug_abbrev")) {
  800420874e:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  8004208752:	48 be 2f a2 20 04 80 	movabs $0x800420a22f,%rsi
  8004208759:	00 00 00 
  800420875c:	48 89 c7             	mov    %rax,%rdi
  800420875f:	48 b8 1f 2d 20 04 80 	movabs $0x8004202d1f,%rax
  8004208766:	00 00 00 
  8004208769:	ff d0                	callq  *%rax
  800420876b:	85 c0                	test   %eax,%eax
  800420876d:	75 4b                	jne    80042087ba <find_debug_sections+0x152>
            section_info[DEBUG_ABBREV].ds_data = (uint8_t*)debug_address;
  800420876f:	48 8b 55 f8          	mov    -0x8(%rbp),%rdx
  8004208773:	48 b8 20 b6 21 04 80 	movabs $0x800421b620,%rax
  800420877a:	00 00 00 
  800420877d:	48 89 50 28          	mov    %rdx,0x28(%rax)
			section_info[DEBUG_ABBREV].ds_addr = debug_address;
  8004208781:	48 b8 20 b6 21 04 80 	movabs $0x800421b620,%rax
  8004208788:	00 00 00 
  800420878b:	48 8b 55 f8          	mov    -0x8(%rbp),%rdx
  800420878f:	48 89 50 30          	mov    %rdx,0x30(%rax)
			section_info[DEBUG_ABBREV].ds_size = sh->sh_size;
  8004208793:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8004208797:	48 8b 50 20          	mov    0x20(%rax),%rdx
  800420879b:	48 b8 20 b6 21 04 80 	movabs $0x800421b620,%rax
  80042087a2:	00 00 00 
  80042087a5:	48 89 50 38          	mov    %rdx,0x38(%rax)
            debug_address += sh->sh_size;
  80042087a9:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  80042087ad:	48 8b 40 20          	mov    0x20(%rax),%rax
  80042087b1:	48 01 45 f8          	add    %rax,-0x8(%rbp)
  80042087b5:	e9 50 01 00 00       	jmpq   800420890a <find_debug_sections+0x2a2>
        } else if(!strcmp(name, ".debug_line")){
  80042087ba:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  80042087be:	48 be 47 a2 20 04 80 	movabs $0x800420a247,%rsi
  80042087c5:	00 00 00 
  80042087c8:	48 89 c7             	mov    %rax,%rdi
  80042087cb:	48 b8 1f 2d 20 04 80 	movabs $0x8004202d1f,%rax
  80042087d2:	00 00 00 
  80042087d5:	ff d0                	callq  *%rax
  80042087d7:	85 c0                	test   %eax,%eax
  80042087d9:	75 4b                	jne    8004208826 <find_debug_sections+0x1be>
            section_info[DEBUG_LINE].ds_data = (uint8_t*)debug_address;
  80042087db:	48 8b 55 f8          	mov    -0x8(%rbp),%rdx
  80042087df:	48 b8 20 b6 21 04 80 	movabs $0x800421b620,%rax
  80042087e6:	00 00 00 
  80042087e9:	48 89 50 68          	mov    %rdx,0x68(%rax)
			section_info[DEBUG_LINE].ds_addr = debug_address;
  80042087ed:	48 b8 20 b6 21 04 80 	movabs $0x800421b620,%rax
  80042087f4:	00 00 00 
  80042087f7:	48 8b 55 f8          	mov    -0x8(%rbp),%rdx
  80042087fb:	48 89 50 70          	mov    %rdx,0x70(%rax)
			section_info[DEBUG_LINE].ds_size = sh->sh_size;
  80042087ff:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8004208803:	48 8b 50 20          	mov    0x20(%rax),%rdx
  8004208807:	48 b8 20 b6 21 04 80 	movabs $0x800421b620,%rax
  800420880e:	00 00 00 
  8004208811:	48 89 50 78          	mov    %rdx,0x78(%rax)
            debug_address += sh->sh_size;
  8004208815:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8004208819:	48 8b 40 20          	mov    0x20(%rax),%rax
  800420881d:	48 01 45 f8          	add    %rax,-0x8(%rbp)
  8004208821:	e9 e4 00 00 00       	jmpq   800420890a <find_debug_sections+0x2a2>
        } else if(!strcmp(name, ".eh_frame")){
  8004208826:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  800420882a:	48 be 3d a2 20 04 80 	movabs $0x800420a23d,%rsi
  8004208831:	00 00 00 
  8004208834:	48 89 c7             	mov    %rax,%rdi
  8004208837:	48 b8 1f 2d 20 04 80 	movabs $0x8004202d1f,%rax
  800420883e:	00 00 00 
  8004208841:	ff d0                	callq  *%rax
  8004208843:	85 c0                	test   %eax,%eax
  8004208845:	75 53                	jne    800420889a <find_debug_sections+0x232>
            section_info[DEBUG_FRAME].ds_data = (uint8_t*)sh->sh_addr;
  8004208847:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  800420884b:	48 8b 40 10          	mov    0x10(%rax),%rax
  800420884f:	48 89 c2             	mov    %rax,%rdx
  8004208852:	48 b8 20 b6 21 04 80 	movabs $0x800421b620,%rax
  8004208859:	00 00 00 
  800420885c:	48 89 50 48          	mov    %rdx,0x48(%rax)
			section_info[DEBUG_FRAME].ds_addr = sh->sh_addr;
  8004208860:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8004208864:	48 8b 50 10          	mov    0x10(%rax),%rdx
  8004208868:	48 b8 20 b6 21 04 80 	movabs $0x800421b620,%rax
  800420886f:	00 00 00 
  8004208872:	48 89 50 50          	mov    %rdx,0x50(%rax)
			section_info[DEBUG_FRAME].ds_size = sh->sh_size;
  8004208876:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  800420887a:	48 8b 50 20          	mov    0x20(%rax),%rdx
  800420887e:	48 b8 20 b6 21 04 80 	movabs $0x800421b620,%rax
  8004208885:	00 00 00 
  8004208888:	48 89 50 58          	mov    %rdx,0x58(%rax)
            debug_address += sh->sh_size;
  800420888c:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8004208890:	48 8b 40 20          	mov    0x20(%rax),%rax
  8004208894:	48 01 45 f8          	add    %rax,-0x8(%rbp)
  8004208898:	eb 70                	jmp    800420890a <find_debug_sections+0x2a2>
        } else if(!strcmp(name, ".debug_str")) {
  800420889a:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  800420889e:	48 be 53 a2 20 04 80 	movabs $0x800420a253,%rsi
  80042088a5:	00 00 00 
  80042088a8:	48 89 c7             	mov    %rax,%rdi
  80042088ab:	48 b8 1f 2d 20 04 80 	movabs $0x8004202d1f,%rax
  80042088b2:	00 00 00 
  80042088b5:	ff d0                	callq  *%rax
  80042088b7:	85 c0                	test   %eax,%eax
  80042088b9:	75 4f                	jne    800420890a <find_debug_sections+0x2a2>
            section_info[DEBUG_STR].ds_data = (uint8_t*)debug_address;
  80042088bb:	48 8b 55 f8          	mov    -0x8(%rbp),%rdx
  80042088bf:	48 b8 20 b6 21 04 80 	movabs $0x800421b620,%rax
  80042088c6:	00 00 00 
  80042088c9:	48 89 90 88 00 00 00 	mov    %rdx,0x88(%rax)
			section_info[DEBUG_STR].ds_addr = debug_address;
  80042088d0:	48 b8 20 b6 21 04 80 	movabs $0x800421b620,%rax
  80042088d7:	00 00 00 
  80042088da:	48 8b 55 f8          	mov    -0x8(%rbp),%rdx
  80042088de:	48 89 90 90 00 00 00 	mov    %rdx,0x90(%rax)
			section_info[DEBUG_STR].ds_size = sh->sh_size;
  80042088e5:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  80042088e9:	48 8b 50 20          	mov    0x20(%rax),%rdx
  80042088ed:	48 b8 20 b6 21 04 80 	movabs $0x800421b620,%rax
  80042088f4:	00 00 00 
  80042088f7:	48 89 90 98 00 00 00 	mov    %rdx,0x98(%rax)
            debug_address += sh->sh_size;
  80042088fe:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8004208902:	48 8b 40 20          	mov    0x20(%rax),%rax
  8004208906:	48 01 45 f8          	add    %rax,-0x8(%rbp)
    Elf *ehdr = (Elf *)elf;
    uintptr_t debug_address = USTABDATA;
    Secthdr *sh = (Secthdr *)(((uint8_t *)ehdr + ehdr->e_shoff));
    Secthdr *shstr_tab = sh + ehdr->e_shstrndx;
    Secthdr* esh = sh + ehdr->e_shnum;
    for(;sh < esh; sh++) {
  800420890a:	48 83 45 f0 40       	addq   $0x40,-0x10(%rbp)
  800420890f:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8004208913:	48 3b 45 d8          	cmp    -0x28(%rbp),%rax
  8004208917:	0f 82 aa fd ff ff    	jb     80042086c7 <find_debug_sections+0x5f>
			section_info[DEBUG_STR].ds_size = sh->sh_size;
            debug_address += sh->sh_size;
        }
    }

}
  800420891d:	c9                   	leaveq 
  800420891e:	c3                   	retq   

000000800420891f <read_section_headers>:

uint64_t
read_section_headers(uintptr_t elfhdr, uintptr_t to_va)
{
  800420891f:	55                   	push   %rbp
  8004208920:	48 89 e5             	mov    %rsp,%rbp
  8004208923:	48 81 ec 60 01 00 00 	sub    $0x160,%rsp
  800420892a:	48 89 bd a8 fe ff ff 	mov    %rdi,-0x158(%rbp)
  8004208931:	48 89 b5 a0 fe ff ff 	mov    %rsi,-0x160(%rbp)
    Secthdr* secthdr_ptr[20] = {0};
  8004208938:	48 8d b5 c0 fe ff ff 	lea    -0x140(%rbp),%rsi
  800420893f:	b8 00 00 00 00       	mov    $0x0,%eax
  8004208944:	ba 14 00 00 00       	mov    $0x14,%edx
  8004208949:	48 89 f7             	mov    %rsi,%rdi
  800420894c:	48 89 d1             	mov    %rdx,%rcx
  800420894f:	f3 48 ab             	rep stos %rax,%es:(%rdi)
    char* kvbase = ROUNDUP((char*)to_va, SECTSIZE);
  8004208952:	48 c7 45 e8 00 02 00 	movq   $0x200,-0x18(%rbp)
  8004208959:	00 
  800420895a:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  800420895e:	48 8b 95 a0 fe ff ff 	mov    -0x160(%rbp),%rdx
  8004208965:	48 01 d0             	add    %rdx,%rax
  8004208968:	48 83 e8 01          	sub    $0x1,%rax
  800420896c:	48 89 45 e0          	mov    %rax,-0x20(%rbp)
  8004208970:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  8004208974:	ba 00 00 00 00       	mov    $0x0,%edx
  8004208979:	48 f7 75 e8          	divq   -0x18(%rbp)
  800420897d:	48 89 d0             	mov    %rdx,%rax
  8004208980:	48 8b 55 e0          	mov    -0x20(%rbp),%rdx
  8004208984:	48 89 d1             	mov    %rdx,%rcx
  8004208987:	48 29 c1             	sub    %rax,%rcx
  800420898a:	48 89 c8             	mov    %rcx,%rax
  800420898d:	48 89 45 d8          	mov    %rax,-0x28(%rbp)
    uint64_t kvoffset = 0;
  8004208991:	48 c7 85 b8 fe ff ff 	movq   $0x0,-0x148(%rbp)
  8004208998:	00 00 00 00 
	char *orig_secthdr = (char*)kvbase;
  800420899c:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  80042089a0:	48 89 45 d0          	mov    %rax,-0x30(%rbp)
    char * secthdr = NULL;
  80042089a4:	48 c7 45 c8 00 00 00 	movq   $0x0,-0x38(%rbp)
  80042089ab:	00 
    uint64_t offset;
    if(elfhdr == KELFHDR)
  80042089ac:	48 b8 00 00 01 04 80 	movabs $0x8004010000,%rax
  80042089b3:	00 00 00 
  80042089b6:	48 39 85 a8 fe ff ff 	cmp    %rax,-0x158(%rbp)
  80042089bd:	75 11                	jne    80042089d0 <read_section_headers+0xb1>
        offset = ((Elf*)elfhdr)->e_shoff;
  80042089bf:	48 8b 85 a8 fe ff ff 	mov    -0x158(%rbp),%rax
  80042089c6:	48 8b 40 28          	mov    0x28(%rax),%rax
  80042089ca:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
  80042089ce:	eb 26                	jmp    80042089f6 <read_section_headers+0xd7>
    else
        offset = ((Elf*)elfhdr)->e_shoff + (elfhdr - KERNBASE);
  80042089d0:	48 8b 85 a8 fe ff ff 	mov    -0x158(%rbp),%rax
  80042089d7:	48 8b 40 28          	mov    0x28(%rax),%rax
  80042089db:	48 89 c2             	mov    %rax,%rdx
  80042089de:	48 03 95 a8 fe ff ff 	add    -0x158(%rbp),%rdx
  80042089e5:	48 b8 00 00 00 fc 7f 	movabs $0xffffff7ffc000000,%rax
  80042089ec:	ff ff ff 
  80042089ef:	48 01 d0             	add    %rdx,%rax
  80042089f2:	48 89 45 f8          	mov    %rax,-0x8(%rbp)

    int numSectionHeaders = ((Elf*)elfhdr)->e_shnum;
  80042089f6:	48 8b 85 a8 fe ff ff 	mov    -0x158(%rbp),%rax
  80042089fd:	0f b7 40 3c          	movzwl 0x3c(%rax),%eax
  8004208a01:	0f b7 c0             	movzwl %ax,%eax
  8004208a04:	89 45 c4             	mov    %eax,-0x3c(%rbp)
	int sizeSections = ((Elf*)elfhdr)->e_shentsize;
  8004208a07:	48 8b 85 a8 fe ff ff 	mov    -0x158(%rbp),%rax
  8004208a0e:	0f b7 40 3a          	movzwl 0x3a(%rax),%eax
  8004208a12:	0f b7 c0             	movzwl %ax,%eax
  8004208a15:	89 45 c0             	mov    %eax,-0x40(%rbp)
	char *nametab;
	int i;
	uint64_t temp;
	char *name;

	Elf *ehdr = (Elf *)elfhdr;
  8004208a18:	48 8b 85 a8 fe ff ff 	mov    -0x158(%rbp),%rax
  8004208a1f:	48 89 45 b8          	mov    %rax,-0x48(%rbp)
	Secthdr *sec_name;  

	readseg((uint64_t)orig_secthdr , numSectionHeaders * sizeSections,
  8004208a23:	8b 45 c4             	mov    -0x3c(%rbp),%eax
  8004208a26:	0f af 45 c0          	imul   -0x40(%rbp),%eax
  8004208a2a:	48 63 f0             	movslq %eax,%rsi
  8004208a2d:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  8004208a31:	48 8d 8d b8 fe ff ff 	lea    -0x148(%rbp),%rcx
  8004208a38:	48 8b 55 f8          	mov    -0x8(%rbp),%rdx
  8004208a3c:	48 89 c7             	mov    %rax,%rdi
  8004208a3f:	48 b8 53 90 20 04 80 	movabs $0x8004209053,%rax
  8004208a46:	00 00 00 
  8004208a49:	ff d0                	callq  *%rax
             offset, &kvoffset);
	secthdr = (char*)orig_secthdr + (offset - ROUNDDOWN(offset, SECTSIZE));
  8004208a4b:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8004208a4f:	48 89 45 b0          	mov    %rax,-0x50(%rbp)
  8004208a53:	48 8b 45 b0          	mov    -0x50(%rbp),%rax
  8004208a57:	48 89 c2             	mov    %rax,%rdx
  8004208a5a:	48 81 e2 00 fe ff ff 	and    $0xfffffffffffffe00,%rdx
  8004208a61:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8004208a65:	48 29 d0             	sub    %rdx,%rax
  8004208a68:	48 03 45 d0          	add    -0x30(%rbp),%rax
  8004208a6c:	48 89 45 c8          	mov    %rax,-0x38(%rbp)
	for (i = 0; i < numSectionHeaders; i++)
  8004208a70:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%rbp)
  8004208a77:	eb 21                	jmp    8004208a9a <read_section_headers+0x17b>
	{
		 secthdr_ptr[i] = (Secthdr*)(secthdr) + i;
  8004208a79:	8b 45 f4             	mov    -0xc(%rbp),%eax
  8004208a7c:	48 98                	cltq   
  8004208a7e:	48 c1 e0 06          	shl    $0x6,%rax
  8004208a82:	48 89 c2             	mov    %rax,%rdx
  8004208a85:	48 03 55 c8          	add    -0x38(%rbp),%rdx
  8004208a89:	8b 45 f4             	mov    -0xc(%rbp),%eax
  8004208a8c:	48 98                	cltq   
  8004208a8e:	48 89 94 c5 c0 fe ff 	mov    %rdx,-0x140(%rbp,%rax,8)
  8004208a95:	ff 
	Secthdr *sec_name;  

	readseg((uint64_t)orig_secthdr , numSectionHeaders * sizeSections,
             offset, &kvoffset);
	secthdr = (char*)orig_secthdr + (offset - ROUNDDOWN(offset, SECTSIZE));
	for (i = 0; i < numSectionHeaders; i++)
  8004208a96:	83 45 f4 01          	addl   $0x1,-0xc(%rbp)
  8004208a9a:	8b 45 f4             	mov    -0xc(%rbp),%eax
  8004208a9d:	3b 45 c4             	cmp    -0x3c(%rbp),%eax
  8004208aa0:	7c d7                	jl     8004208a79 <read_section_headers+0x15a>
	{
		 secthdr_ptr[i] = (Secthdr*)(secthdr) + i;
	}
	
	sec_name = secthdr_ptr[ehdr->e_shstrndx]; 
  8004208aa2:	48 8b 45 b8          	mov    -0x48(%rbp),%rax
  8004208aa6:	0f b7 40 3e          	movzwl 0x3e(%rax),%eax
  8004208aaa:	0f b7 c0             	movzwl %ax,%eax
  8004208aad:	48 98                	cltq   
  8004208aaf:	48 8b 84 c5 c0 fe ff 	mov    -0x140(%rbp,%rax,8),%rax
  8004208ab6:	ff 
  8004208ab7:	48 89 45 a8          	mov    %rax,-0x58(%rbp)
	temp = kvoffset;
  8004208abb:	48 8b 85 b8 fe ff ff 	mov    -0x148(%rbp),%rax
  8004208ac2:	48 89 45 a0          	mov    %rax,-0x60(%rbp)
	readseg((uint64_t)((char *)kvbase + kvoffset), sec_name->sh_size,
            sec_name->sh_offset, &kvoffset);
  8004208ac6:	48 8b 45 a8          	mov    -0x58(%rbp),%rax
		 secthdr_ptr[i] = (Secthdr*)(secthdr) + i;
	}
	
	sec_name = secthdr_ptr[ehdr->e_shstrndx]; 
	temp = kvoffset;
	readseg((uint64_t)((char *)kvbase + kvoffset), sec_name->sh_size,
  8004208aca:	48 8b 50 18          	mov    0x18(%rax),%rdx
  8004208ace:	48 8b 45 a8          	mov    -0x58(%rbp),%rax
  8004208ad2:	48 8b 70 20          	mov    0x20(%rax),%rsi
  8004208ad6:	48 8b 85 b8 fe ff ff 	mov    -0x148(%rbp),%rax
  8004208add:	48 03 45 d8          	add    -0x28(%rbp),%rax
  8004208ae1:	48 8d 8d b8 fe ff ff 	lea    -0x148(%rbp),%rcx
  8004208ae8:	48 89 c7             	mov    %rax,%rdi
  8004208aeb:	48 b8 53 90 20 04 80 	movabs $0x8004209053,%rax
  8004208af2:	00 00 00 
  8004208af5:	ff d0                	callq  *%rax
            sec_name->sh_offset, &kvoffset);
	nametab = (char *)((char *)kvbase + temp) + OFFSET_CORRECT(sec_name->sh_offset);	
  8004208af7:	48 8b 45 a8          	mov    -0x58(%rbp),%rax
  8004208afb:	48 8b 50 18          	mov    0x18(%rax),%rdx
  8004208aff:	48 8b 45 a8          	mov    -0x58(%rbp),%rax
  8004208b03:	48 8b 40 18          	mov    0x18(%rax),%rax
  8004208b07:	48 89 45 98          	mov    %rax,-0x68(%rbp)
  8004208b0b:	48 8b 45 98          	mov    -0x68(%rbp),%rax
  8004208b0f:	48 25 00 fe ff ff    	and    $0xfffffffffffffe00,%rax
  8004208b15:	48 89 d7             	mov    %rdx,%rdi
  8004208b18:	48 29 c7             	sub    %rax,%rdi
  8004208b1b:	48 89 f8             	mov    %rdi,%rax
  8004208b1e:	48 03 45 a0          	add    -0x60(%rbp),%rax
  8004208b22:	48 03 45 d8          	add    -0x28(%rbp),%rax
  8004208b26:	48 89 45 90          	mov    %rax,-0x70(%rbp)

    
	for (i = 0; i < numSectionHeaders; i++)
  8004208b2a:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%rbp)
  8004208b31:	e9 01 05 00 00       	jmpq   8004209037 <read_section_headers+0x718>
    {
		name = (char *)(nametab + secthdr_ptr[i]->sh_name);
  8004208b36:	8b 45 f4             	mov    -0xc(%rbp),%eax
  8004208b39:	48 98                	cltq   
  8004208b3b:	48 8b 84 c5 c0 fe ff 	mov    -0x140(%rbp,%rax,8),%rax
  8004208b42:	ff 
  8004208b43:	8b 00                	mov    (%rax),%eax
  8004208b45:	89 c0                	mov    %eax,%eax
  8004208b47:	48 03 45 90          	add    -0x70(%rbp),%rax
  8004208b4b:	48 89 45 88          	mov    %rax,-0x78(%rbp)
        assert(kvoffset % SECTSIZE == 0);
  8004208b4f:	48 8b 85 b8 fe ff ff 	mov    -0x148(%rbp),%rax
  8004208b56:	25 ff 01 00 00       	and    $0x1ff,%eax
  8004208b5b:	48 85 c0             	test   %rax,%rax
  8004208b5e:	74 35                	je     8004208b95 <read_section_headers+0x276>
  8004208b60:	48 b9 5e a2 20 04 80 	movabs $0x800420a25e,%rcx
  8004208b67:	00 00 00 
  8004208b6a:	48 ba 77 a2 20 04 80 	movabs $0x800420a277,%rdx
  8004208b71:	00 00 00 
  8004208b74:	be 87 00 00 00       	mov    $0x87,%esi
  8004208b79:	48 bf 8c a2 20 04 80 	movabs $0x800420a28c,%rdi
  8004208b80:	00 00 00 
  8004208b83:	b8 00 00 00 00       	mov    $0x0,%eax
  8004208b88:	49 b8 9b 01 20 04 80 	movabs $0x800420019b,%r8
  8004208b8f:	00 00 00 
  8004208b92:	41 ff d0             	callq  *%r8
        temp = kvoffset;
  8004208b95:	48 8b 85 b8 fe ff ff 	mov    -0x148(%rbp),%rax
  8004208b9c:	48 89 45 a0          	mov    %rax,-0x60(%rbp)
#ifdef DWARF_DEBUG
        cprintf("SectName: %s\n", name);
#endif
		if(!strcmp(name, ".debug_info"))
  8004208ba0:	48 8b 45 88          	mov    -0x78(%rbp),%rax
  8004208ba4:	48 be 23 a2 20 04 80 	movabs $0x800420a223,%rsi
  8004208bab:	00 00 00 
  8004208bae:	48 89 c7             	mov    %rax,%rdi
  8004208bb1:	48 b8 1f 2d 20 04 80 	movabs $0x8004202d1f,%rax
  8004208bb8:	00 00 00 
  8004208bbb:	ff d0                	callq  *%rax
  8004208bbd:	85 c0                	test   %eax,%eax
  8004208bbf:	0f 85 d8 00 00 00    	jne    8004208c9d <read_section_headers+0x37e>
		{
			readseg((uint64_t)((char *)kvbase + kvoffset), secthdr_ptr[i]->sh_size, 
                    secthdr_ptr[i]->sh_offset, &kvoffset);	
  8004208bc5:	8b 45 f4             	mov    -0xc(%rbp),%eax
  8004208bc8:	48 98                	cltq   
  8004208bca:	48 8b 84 c5 c0 fe ff 	mov    -0x140(%rbp,%rax,8),%rax
  8004208bd1:	ff 
#ifdef DWARF_DEBUG
        cprintf("SectName: %s\n", name);
#endif
		if(!strcmp(name, ".debug_info"))
		{
			readseg((uint64_t)((char *)kvbase + kvoffset), secthdr_ptr[i]->sh_size, 
  8004208bd2:	48 8b 50 18          	mov    0x18(%rax),%rdx
  8004208bd6:	8b 45 f4             	mov    -0xc(%rbp),%eax
  8004208bd9:	48 98                	cltq   
  8004208bdb:	48 8b 84 c5 c0 fe ff 	mov    -0x140(%rbp,%rax,8),%rax
  8004208be2:	ff 
  8004208be3:	48 8b 70 20          	mov    0x20(%rax),%rsi
  8004208be7:	48 8b 85 b8 fe ff ff 	mov    -0x148(%rbp),%rax
  8004208bee:	48 03 45 d8          	add    -0x28(%rbp),%rax
  8004208bf2:	48 8d 8d b8 fe ff ff 	lea    -0x148(%rbp),%rcx
  8004208bf9:	48 89 c7             	mov    %rax,%rdi
  8004208bfc:	48 b8 53 90 20 04 80 	movabs $0x8004209053,%rax
  8004208c03:	00 00 00 
  8004208c06:	ff d0                	callq  *%rax
                    secthdr_ptr[i]->sh_offset, &kvoffset);	
			section_info[DEBUG_INFO].ds_data = (uint8_t *)((char *)kvbase + temp) + OFFSET_CORRECT(secthdr_ptr[i]->sh_offset);
  8004208c08:	8b 45 f4             	mov    -0xc(%rbp),%eax
  8004208c0b:	48 98                	cltq   
  8004208c0d:	48 8b 84 c5 c0 fe ff 	mov    -0x140(%rbp,%rax,8),%rax
  8004208c14:	ff 
  8004208c15:	48 8b 50 18          	mov    0x18(%rax),%rdx
  8004208c19:	8b 45 f4             	mov    -0xc(%rbp),%eax
  8004208c1c:	48 98                	cltq   
  8004208c1e:	48 8b 84 c5 c0 fe ff 	mov    -0x140(%rbp,%rax,8),%rax
  8004208c25:	ff 
  8004208c26:	48 8b 40 18          	mov    0x18(%rax),%rax
  8004208c2a:	48 89 45 80          	mov    %rax,-0x80(%rbp)
  8004208c2e:	48 8b 45 80          	mov    -0x80(%rbp),%rax
  8004208c32:	48 25 00 fe ff ff    	and    $0xfffffffffffffe00,%rax
  8004208c38:	48 89 d1             	mov    %rdx,%rcx
  8004208c3b:	48 29 c1             	sub    %rax,%rcx
  8004208c3e:	48 89 c8             	mov    %rcx,%rax
  8004208c41:	48 03 45 a0          	add    -0x60(%rbp),%rax
  8004208c45:	48 89 c2             	mov    %rax,%rdx
  8004208c48:	48 03 55 d8          	add    -0x28(%rbp),%rdx
  8004208c4c:	48 b8 20 b6 21 04 80 	movabs $0x800421b620,%rax
  8004208c53:	00 00 00 
  8004208c56:	48 89 50 08          	mov    %rdx,0x8(%rax)
			section_info[DEBUG_INFO].ds_addr = (uintptr_t)section_info[DEBUG_INFO].ds_data;
  8004208c5a:	48 b8 20 b6 21 04 80 	movabs $0x800421b620,%rax
  8004208c61:	00 00 00 
  8004208c64:	48 8b 40 08          	mov    0x8(%rax),%rax
  8004208c68:	48 89 c2             	mov    %rax,%rdx
  8004208c6b:	48 b8 20 b6 21 04 80 	movabs $0x800421b620,%rax
  8004208c72:	00 00 00 
  8004208c75:	48 89 50 10          	mov    %rdx,0x10(%rax)
			section_info[DEBUG_INFO].ds_size = secthdr_ptr[i]->sh_size;
  8004208c79:	8b 45 f4             	mov    -0xc(%rbp),%eax
  8004208c7c:	48 98                	cltq   
  8004208c7e:	48 8b 84 c5 c0 fe ff 	mov    -0x140(%rbp,%rax,8),%rax
  8004208c85:	ff 
  8004208c86:	48 8b 50 20          	mov    0x20(%rax),%rdx
  8004208c8a:	48 b8 20 b6 21 04 80 	movabs $0x800421b620,%rax
  8004208c91:	00 00 00 
  8004208c94:	48 89 50 18          	mov    %rdx,0x18(%rax)
  8004208c98:	e9 96 03 00 00       	jmpq   8004209033 <read_section_headers+0x714>
		}
		else if(!strcmp(name, ".debug_abbrev"))
  8004208c9d:	48 8b 45 88          	mov    -0x78(%rbp),%rax
  8004208ca1:	48 be 2f a2 20 04 80 	movabs $0x800420a22f,%rsi
  8004208ca8:	00 00 00 
  8004208cab:	48 89 c7             	mov    %rax,%rdi
  8004208cae:	48 b8 1f 2d 20 04 80 	movabs $0x8004202d1f,%rax
  8004208cb5:	00 00 00 
  8004208cb8:	ff d0                	callq  *%rax
  8004208cba:	85 c0                	test   %eax,%eax
  8004208cbc:	0f 85 de 00 00 00    	jne    8004208da0 <read_section_headers+0x481>
		{
			readseg((uint64_t)((char *)kvbase + kvoffset), secthdr_ptr[i]->sh_size, 
                    secthdr_ptr[i]->sh_offset, &kvoffset);	
  8004208cc2:	8b 45 f4             	mov    -0xc(%rbp),%eax
  8004208cc5:	48 98                	cltq   
  8004208cc7:	48 8b 84 c5 c0 fe ff 	mov    -0x140(%rbp,%rax,8),%rax
  8004208cce:	ff 
			section_info[DEBUG_INFO].ds_addr = (uintptr_t)section_info[DEBUG_INFO].ds_data;
			section_info[DEBUG_INFO].ds_size = secthdr_ptr[i]->sh_size;
		}
		else if(!strcmp(name, ".debug_abbrev"))
		{
			readseg((uint64_t)((char *)kvbase + kvoffset), secthdr_ptr[i]->sh_size, 
  8004208ccf:	48 8b 50 18          	mov    0x18(%rax),%rdx
  8004208cd3:	8b 45 f4             	mov    -0xc(%rbp),%eax
  8004208cd6:	48 98                	cltq   
  8004208cd8:	48 8b 84 c5 c0 fe ff 	mov    -0x140(%rbp,%rax,8),%rax
  8004208cdf:	ff 
  8004208ce0:	48 8b 70 20          	mov    0x20(%rax),%rsi
  8004208ce4:	48 8b 85 b8 fe ff ff 	mov    -0x148(%rbp),%rax
  8004208ceb:	48 03 45 d8          	add    -0x28(%rbp),%rax
  8004208cef:	48 8d 8d b8 fe ff ff 	lea    -0x148(%rbp),%rcx
  8004208cf6:	48 89 c7             	mov    %rax,%rdi
  8004208cf9:	48 b8 53 90 20 04 80 	movabs $0x8004209053,%rax
  8004208d00:	00 00 00 
  8004208d03:	ff d0                	callq  *%rax
                    secthdr_ptr[i]->sh_offset, &kvoffset);	
			section_info[DEBUG_ABBREV].ds_data = (uint8_t *)((char *)kvbase + temp) + OFFSET_CORRECT(secthdr_ptr[i]->sh_offset);
  8004208d05:	8b 45 f4             	mov    -0xc(%rbp),%eax
  8004208d08:	48 98                	cltq   
  8004208d0a:	48 8b 84 c5 c0 fe ff 	mov    -0x140(%rbp,%rax,8),%rax
  8004208d11:	ff 
  8004208d12:	48 8b 50 18          	mov    0x18(%rax),%rdx
  8004208d16:	8b 45 f4             	mov    -0xc(%rbp),%eax
  8004208d19:	48 98                	cltq   
  8004208d1b:	48 8b 84 c5 c0 fe ff 	mov    -0x140(%rbp,%rax,8),%rax
  8004208d22:	ff 
  8004208d23:	48 8b 40 18          	mov    0x18(%rax),%rax
  8004208d27:	48 89 85 78 ff ff ff 	mov    %rax,-0x88(%rbp)
  8004208d2e:	48 8b 85 78 ff ff ff 	mov    -0x88(%rbp),%rax
  8004208d35:	48 25 00 fe ff ff    	and    $0xfffffffffffffe00,%rax
  8004208d3b:	48 89 d7             	mov    %rdx,%rdi
  8004208d3e:	48 29 c7             	sub    %rax,%rdi
  8004208d41:	48 89 f8             	mov    %rdi,%rax
  8004208d44:	48 03 45 a0          	add    -0x60(%rbp),%rax
  8004208d48:	48 89 c2             	mov    %rax,%rdx
  8004208d4b:	48 03 55 d8          	add    -0x28(%rbp),%rdx
  8004208d4f:	48 b8 20 b6 21 04 80 	movabs $0x800421b620,%rax
  8004208d56:	00 00 00 
  8004208d59:	48 89 50 28          	mov    %rdx,0x28(%rax)
			section_info[DEBUG_ABBREV].ds_addr = (uintptr_t)section_info[DEBUG_ABBREV].ds_data;
  8004208d5d:	48 b8 20 b6 21 04 80 	movabs $0x800421b620,%rax
  8004208d64:	00 00 00 
  8004208d67:	48 8b 40 28          	mov    0x28(%rax),%rax
  8004208d6b:	48 89 c2             	mov    %rax,%rdx
  8004208d6e:	48 b8 20 b6 21 04 80 	movabs $0x800421b620,%rax
  8004208d75:	00 00 00 
  8004208d78:	48 89 50 30          	mov    %rdx,0x30(%rax)
			section_info[DEBUG_ABBREV].ds_size = secthdr_ptr[i]->sh_size;
  8004208d7c:	8b 45 f4             	mov    -0xc(%rbp),%eax
  8004208d7f:	48 98                	cltq   
  8004208d81:	48 8b 84 c5 c0 fe ff 	mov    -0x140(%rbp,%rax,8),%rax
  8004208d88:	ff 
  8004208d89:	48 8b 50 20          	mov    0x20(%rax),%rdx
  8004208d8d:	48 b8 20 b6 21 04 80 	movabs $0x800421b620,%rax
  8004208d94:	00 00 00 
  8004208d97:	48 89 50 38          	mov    %rdx,0x38(%rax)
  8004208d9b:	e9 93 02 00 00       	jmpq   8004209033 <read_section_headers+0x714>
		}
		else if(!strcmp(name, ".debug_line"))
  8004208da0:	48 8b 45 88          	mov    -0x78(%rbp),%rax
  8004208da4:	48 be 47 a2 20 04 80 	movabs $0x800420a247,%rsi
  8004208dab:	00 00 00 
  8004208dae:	48 89 c7             	mov    %rax,%rdi
  8004208db1:	48 b8 1f 2d 20 04 80 	movabs $0x8004202d1f,%rax
  8004208db8:	00 00 00 
  8004208dbb:	ff d0                	callq  *%rax
  8004208dbd:	85 c0                	test   %eax,%eax
  8004208dbf:	0f 85 de 00 00 00    	jne    8004208ea3 <read_section_headers+0x584>
		{
			readseg((uint64_t)((char *)kvbase + kvoffset), secthdr_ptr[i]->sh_size, 
                    secthdr_ptr[i]->sh_offset, &kvoffset);	
  8004208dc5:	8b 45 f4             	mov    -0xc(%rbp),%eax
  8004208dc8:	48 98                	cltq   
  8004208dca:	48 8b 84 c5 c0 fe ff 	mov    -0x140(%rbp,%rax,8),%rax
  8004208dd1:	ff 
			section_info[DEBUG_ABBREV].ds_addr = (uintptr_t)section_info[DEBUG_ABBREV].ds_data;
			section_info[DEBUG_ABBREV].ds_size = secthdr_ptr[i]->sh_size;
		}
		else if(!strcmp(name, ".debug_line"))
		{
			readseg((uint64_t)((char *)kvbase + kvoffset), secthdr_ptr[i]->sh_size, 
  8004208dd2:	48 8b 50 18          	mov    0x18(%rax),%rdx
  8004208dd6:	8b 45 f4             	mov    -0xc(%rbp),%eax
  8004208dd9:	48 98                	cltq   
  8004208ddb:	48 8b 84 c5 c0 fe ff 	mov    -0x140(%rbp,%rax,8),%rax
  8004208de2:	ff 
  8004208de3:	48 8b 70 20          	mov    0x20(%rax),%rsi
  8004208de7:	48 8b 85 b8 fe ff ff 	mov    -0x148(%rbp),%rax
  8004208dee:	48 03 45 d8          	add    -0x28(%rbp),%rax
  8004208df2:	48 8d 8d b8 fe ff ff 	lea    -0x148(%rbp),%rcx
  8004208df9:	48 89 c7             	mov    %rax,%rdi
  8004208dfc:	48 b8 53 90 20 04 80 	movabs $0x8004209053,%rax
  8004208e03:	00 00 00 
  8004208e06:	ff d0                	callq  *%rax
                    secthdr_ptr[i]->sh_offset, &kvoffset);	
			section_info[DEBUG_LINE].ds_data = (uint8_t *)((char *)kvbase + temp) + OFFSET_CORRECT(secthdr_ptr[i]->sh_offset);
  8004208e08:	8b 45 f4             	mov    -0xc(%rbp),%eax
  8004208e0b:	48 98                	cltq   
  8004208e0d:	48 8b 84 c5 c0 fe ff 	mov    -0x140(%rbp,%rax,8),%rax
  8004208e14:	ff 
  8004208e15:	48 8b 50 18          	mov    0x18(%rax),%rdx
  8004208e19:	8b 45 f4             	mov    -0xc(%rbp),%eax
  8004208e1c:	48 98                	cltq   
  8004208e1e:	48 8b 84 c5 c0 fe ff 	mov    -0x140(%rbp,%rax,8),%rax
  8004208e25:	ff 
  8004208e26:	48 8b 40 18          	mov    0x18(%rax),%rax
  8004208e2a:	48 89 85 70 ff ff ff 	mov    %rax,-0x90(%rbp)
  8004208e31:	48 8b 85 70 ff ff ff 	mov    -0x90(%rbp),%rax
  8004208e38:	48 25 00 fe ff ff    	and    $0xfffffffffffffe00,%rax
  8004208e3e:	48 89 d1             	mov    %rdx,%rcx
  8004208e41:	48 29 c1             	sub    %rax,%rcx
  8004208e44:	48 89 c8             	mov    %rcx,%rax
  8004208e47:	48 03 45 a0          	add    -0x60(%rbp),%rax
  8004208e4b:	48 89 c2             	mov    %rax,%rdx
  8004208e4e:	48 03 55 d8          	add    -0x28(%rbp),%rdx
  8004208e52:	48 b8 20 b6 21 04 80 	movabs $0x800421b620,%rax
  8004208e59:	00 00 00 
  8004208e5c:	48 89 50 68          	mov    %rdx,0x68(%rax)
			section_info[DEBUG_LINE].ds_addr = (uintptr_t)section_info[DEBUG_LINE].ds_data;
  8004208e60:	48 b8 20 b6 21 04 80 	movabs $0x800421b620,%rax
  8004208e67:	00 00 00 
  8004208e6a:	48 8b 40 68          	mov    0x68(%rax),%rax
  8004208e6e:	48 89 c2             	mov    %rax,%rdx
  8004208e71:	48 b8 20 b6 21 04 80 	movabs $0x800421b620,%rax
  8004208e78:	00 00 00 
  8004208e7b:	48 89 50 70          	mov    %rdx,0x70(%rax)
			section_info[DEBUG_LINE].ds_size = secthdr_ptr[i]->sh_size;
  8004208e7f:	8b 45 f4             	mov    -0xc(%rbp),%eax
  8004208e82:	48 98                	cltq   
  8004208e84:	48 8b 84 c5 c0 fe ff 	mov    -0x140(%rbp,%rax,8),%rax
  8004208e8b:	ff 
  8004208e8c:	48 8b 50 20          	mov    0x20(%rax),%rdx
  8004208e90:	48 b8 20 b6 21 04 80 	movabs $0x800421b620,%rax
  8004208e97:	00 00 00 
  8004208e9a:	48 89 50 78          	mov    %rdx,0x78(%rax)
  8004208e9e:	e9 90 01 00 00       	jmpq   8004209033 <read_section_headers+0x714>
		}
		else if(!strcmp(name, ".eh_frame"))
  8004208ea3:	48 8b 45 88          	mov    -0x78(%rbp),%rax
  8004208ea7:	48 be 3d a2 20 04 80 	movabs $0x800420a23d,%rsi
  8004208eae:	00 00 00 
  8004208eb1:	48 89 c7             	mov    %rax,%rdi
  8004208eb4:	48 b8 1f 2d 20 04 80 	movabs $0x8004202d1f,%rax
  8004208ebb:	00 00 00 
  8004208ebe:	ff d0                	callq  *%rax
  8004208ec0:	85 c0                	test   %eax,%eax
  8004208ec2:	75 65                	jne    8004208f29 <read_section_headers+0x60a>
		{
			section_info[DEBUG_FRAME].ds_data = (uint8_t *)secthdr_ptr[i]->sh_addr;
  8004208ec4:	8b 45 f4             	mov    -0xc(%rbp),%eax
  8004208ec7:	48 98                	cltq   
  8004208ec9:	48 8b 84 c5 c0 fe ff 	mov    -0x140(%rbp,%rax,8),%rax
  8004208ed0:	ff 
  8004208ed1:	48 8b 40 10          	mov    0x10(%rax),%rax
  8004208ed5:	48 89 c2             	mov    %rax,%rdx
  8004208ed8:	48 b8 20 b6 21 04 80 	movabs $0x800421b620,%rax
  8004208edf:	00 00 00 
  8004208ee2:	48 89 50 48          	mov    %rdx,0x48(%rax)
			section_info[DEBUG_FRAME].ds_addr = (uintptr_t)section_info[DEBUG_FRAME].ds_data;
  8004208ee6:	48 b8 20 b6 21 04 80 	movabs $0x800421b620,%rax
  8004208eed:	00 00 00 
  8004208ef0:	48 8b 40 48          	mov    0x48(%rax),%rax
  8004208ef4:	48 89 c2             	mov    %rax,%rdx
  8004208ef7:	48 b8 20 b6 21 04 80 	movabs $0x800421b620,%rax
  8004208efe:	00 00 00 
  8004208f01:	48 89 50 50          	mov    %rdx,0x50(%rax)
			section_info[DEBUG_FRAME].ds_size = secthdr_ptr[i]->sh_size;
  8004208f05:	8b 45 f4             	mov    -0xc(%rbp),%eax
  8004208f08:	48 98                	cltq   
  8004208f0a:	48 8b 84 c5 c0 fe ff 	mov    -0x140(%rbp,%rax,8),%rax
  8004208f11:	ff 
  8004208f12:	48 8b 50 20          	mov    0x20(%rax),%rdx
  8004208f16:	48 b8 20 b6 21 04 80 	movabs $0x800421b620,%rax
  8004208f1d:	00 00 00 
  8004208f20:	48 89 50 58          	mov    %rdx,0x58(%rax)
  8004208f24:	e9 0a 01 00 00       	jmpq   8004209033 <read_section_headers+0x714>
		}
		else if(!strcmp(name, ".debug_str"))
  8004208f29:	48 8b 45 88          	mov    -0x78(%rbp),%rax
  8004208f2d:	48 be 53 a2 20 04 80 	movabs $0x800420a253,%rsi
  8004208f34:	00 00 00 
  8004208f37:	48 89 c7             	mov    %rax,%rdi
  8004208f3a:	48 b8 1f 2d 20 04 80 	movabs $0x8004202d1f,%rax
  8004208f41:	00 00 00 
  8004208f44:	ff d0                	callq  *%rax
  8004208f46:	85 c0                	test   %eax,%eax
  8004208f48:	0f 85 e5 00 00 00    	jne    8004209033 <read_section_headers+0x714>
		{
			readseg((uint64_t)((char *)kvbase + kvoffset), secthdr_ptr[i]->sh_size, 
                    secthdr_ptr[i]->sh_offset, &kvoffset);	
  8004208f4e:	8b 45 f4             	mov    -0xc(%rbp),%eax
  8004208f51:	48 98                	cltq   
  8004208f53:	48 8b 84 c5 c0 fe ff 	mov    -0x140(%rbp,%rax,8),%rax
  8004208f5a:	ff 
			section_info[DEBUG_FRAME].ds_addr = (uintptr_t)section_info[DEBUG_FRAME].ds_data;
			section_info[DEBUG_FRAME].ds_size = secthdr_ptr[i]->sh_size;
		}
		else if(!strcmp(name, ".debug_str"))
		{
			readseg((uint64_t)((char *)kvbase + kvoffset), secthdr_ptr[i]->sh_size, 
  8004208f5b:	48 8b 50 18          	mov    0x18(%rax),%rdx
  8004208f5f:	8b 45 f4             	mov    -0xc(%rbp),%eax
  8004208f62:	48 98                	cltq   
  8004208f64:	48 8b 84 c5 c0 fe ff 	mov    -0x140(%rbp,%rax,8),%rax
  8004208f6b:	ff 
  8004208f6c:	48 8b 70 20          	mov    0x20(%rax),%rsi
  8004208f70:	48 8b 85 b8 fe ff ff 	mov    -0x148(%rbp),%rax
  8004208f77:	48 03 45 d8          	add    -0x28(%rbp),%rax
  8004208f7b:	48 8d 8d b8 fe ff ff 	lea    -0x148(%rbp),%rcx
  8004208f82:	48 89 c7             	mov    %rax,%rdi
  8004208f85:	48 b8 53 90 20 04 80 	movabs $0x8004209053,%rax
  8004208f8c:	00 00 00 
  8004208f8f:	ff d0                	callq  *%rax
                    secthdr_ptr[i]->sh_offset, &kvoffset);	
			section_info[DEBUG_STR].ds_data = (uint8_t *)((char *)kvbase + temp) + OFFSET_CORRECT(secthdr_ptr[i]->sh_offset);
  8004208f91:	8b 45 f4             	mov    -0xc(%rbp),%eax
  8004208f94:	48 98                	cltq   
  8004208f96:	48 8b 84 c5 c0 fe ff 	mov    -0x140(%rbp,%rax,8),%rax
  8004208f9d:	ff 
  8004208f9e:	48 8b 50 18          	mov    0x18(%rax),%rdx
  8004208fa2:	8b 45 f4             	mov    -0xc(%rbp),%eax
  8004208fa5:	48 98                	cltq   
  8004208fa7:	48 8b 84 c5 c0 fe ff 	mov    -0x140(%rbp,%rax,8),%rax
  8004208fae:	ff 
  8004208faf:	48 8b 40 18          	mov    0x18(%rax),%rax
  8004208fb3:	48 89 85 68 ff ff ff 	mov    %rax,-0x98(%rbp)
  8004208fba:	48 8b 85 68 ff ff ff 	mov    -0x98(%rbp),%rax
  8004208fc1:	48 25 00 fe ff ff    	and    $0xfffffffffffffe00,%rax
  8004208fc7:	48 89 d7             	mov    %rdx,%rdi
  8004208fca:	48 29 c7             	sub    %rax,%rdi
  8004208fcd:	48 89 f8             	mov    %rdi,%rax
  8004208fd0:	48 03 45 a0          	add    -0x60(%rbp),%rax
  8004208fd4:	48 89 c2             	mov    %rax,%rdx
  8004208fd7:	48 03 55 d8          	add    -0x28(%rbp),%rdx
  8004208fdb:	48 b8 20 b6 21 04 80 	movabs $0x800421b620,%rax
  8004208fe2:	00 00 00 
  8004208fe5:	48 89 90 88 00 00 00 	mov    %rdx,0x88(%rax)
			section_info[DEBUG_STR].ds_addr = (uintptr_t)section_info[DEBUG_STR].ds_data;
  8004208fec:	48 b8 20 b6 21 04 80 	movabs $0x800421b620,%rax
  8004208ff3:	00 00 00 
  8004208ff6:	48 8b 80 88 00 00 00 	mov    0x88(%rax),%rax
  8004208ffd:	48 89 c2             	mov    %rax,%rdx
  8004209000:	48 b8 20 b6 21 04 80 	movabs $0x800421b620,%rax
  8004209007:	00 00 00 
  800420900a:	48 89 90 90 00 00 00 	mov    %rdx,0x90(%rax)
			section_info[DEBUG_STR].ds_size = secthdr_ptr[i]->sh_size;
  8004209011:	8b 45 f4             	mov    -0xc(%rbp),%eax
  8004209014:	48 98                	cltq   
  8004209016:	48 8b 84 c5 c0 fe ff 	mov    -0x140(%rbp,%rax,8),%rax
  800420901d:	ff 
  800420901e:	48 8b 50 20          	mov    0x20(%rax),%rdx
  8004209022:	48 b8 20 b6 21 04 80 	movabs $0x800421b620,%rax
  8004209029:	00 00 00 
  800420902c:	48 89 90 98 00 00 00 	mov    %rdx,0x98(%rax)
	readseg((uint64_t)((char *)kvbase + kvoffset), sec_name->sh_size,
            sec_name->sh_offset, &kvoffset);
	nametab = (char *)((char *)kvbase + temp) + OFFSET_CORRECT(sec_name->sh_offset);	

    
	for (i = 0; i < numSectionHeaders; i++)
  8004209033:	83 45 f4 01          	addl   $0x1,-0xc(%rbp)
  8004209037:	8b 45 f4             	mov    -0xc(%rbp),%eax
  800420903a:	3b 45 c4             	cmp    -0x3c(%rbp),%eax
  800420903d:	0f 8c f3 fa ff ff    	jl     8004208b36 <read_section_headers+0x217>
			section_info[DEBUG_STR].ds_addr = (uintptr_t)section_info[DEBUG_STR].ds_data;
			section_info[DEBUG_STR].ds_size = secthdr_ptr[i]->sh_size;
		}
    }
	
    return ((uintptr_t)kvbase + kvoffset);
  8004209043:	48 8b 55 d8          	mov    -0x28(%rbp),%rdx
  8004209047:	48 8b 85 b8 fe ff ff 	mov    -0x148(%rbp),%rax
  800420904e:	48 01 d0             	add    %rdx,%rax
}
  8004209051:	c9                   	leaveq 
  8004209052:	c3                   	retq   

0000008004209053 <readseg>:

// Read 'count' bytes at 'offset' from kernel into physical address 'pa'.
// Might copy more than asked
void
readseg(uint64_t pa, uint64_t count, uint64_t offset, uint64_t* kvoffset)
{
  8004209053:	55                   	push   %rbp
  8004209054:	48 89 e5             	mov    %rsp,%rbp
  8004209057:	48 83 ec 30          	sub    $0x30,%rsp
  800420905b:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
  800420905f:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
  8004209063:	48 89 55 d8          	mov    %rdx,-0x28(%rbp)
  8004209067:	48 89 4d d0          	mov    %rcx,-0x30(%rbp)
	uint64_t end_pa;
	uint64_t orgoff = offset;
  800420906b:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  800420906f:	48 89 45 f8          	mov    %rax,-0x8(%rbp)

	end_pa = pa + count;
  8004209073:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  8004209077:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  800420907b:	48 01 d0             	add    %rdx,%rax
  800420907e:	48 89 45 f0          	mov    %rax,-0x10(%rbp)

	assert(pa % SECTSIZE == 0);	
  8004209082:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8004209086:	25 ff 01 00 00       	and    $0x1ff,%eax
  800420908b:	48 85 c0             	test   %rax,%rax
  800420908e:	74 35                	je     80042090c5 <readseg+0x72>
  8004209090:	48 b9 9a a2 20 04 80 	movabs $0x800420a29a,%rcx
  8004209097:	00 00 00 
  800420909a:	48 ba 77 a2 20 04 80 	movabs $0x800420a277,%rdx
  80042090a1:	00 00 00 
  80042090a4:	be c1 00 00 00       	mov    $0xc1,%esi
  80042090a9:	48 bf 8c a2 20 04 80 	movabs $0x800420a28c,%rdi
  80042090b0:	00 00 00 
  80042090b3:	b8 00 00 00 00       	mov    $0x0,%eax
  80042090b8:	49 b8 9b 01 20 04 80 	movabs $0x800420019b,%r8
  80042090bf:	00 00 00 
  80042090c2:	41 ff d0             	callq  *%r8
	// round down to sector boundary
	pa &= ~(SECTSIZE - 1);
  80042090c5:	48 81 65 e8 00 fe ff 	andq   $0xfffffffffffffe00,-0x18(%rbp)
  80042090cc:	ff 

	// translate from bytes to sectors, and kernel starts at sector 1
	offset = (offset / SECTSIZE) + 1;
  80042090cd:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  80042090d1:	48 c1 e8 09          	shr    $0x9,%rax
  80042090d5:	48 83 c0 01          	add    $0x1,%rax
  80042090d9:	48 89 45 d8          	mov    %rax,-0x28(%rbp)

	// If this is too slow, we could read lots of sectors at a time.
	// We'd write more to memory than asked, but it doesn't matter --
	// we load in increasing order.
	while (pa < end_pa) {
  80042090dd:	eb 3c                	jmp    800420911b <readseg+0xc8>
		readsect((uint8_t*) pa, offset);
  80042090df:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  80042090e3:	48 8b 55 d8          	mov    -0x28(%rbp),%rdx
  80042090e7:	48 89 d6             	mov    %rdx,%rsi
  80042090ea:	48 89 c7             	mov    %rax,%rdi
  80042090ed:	48 b8 e8 91 20 04 80 	movabs $0x80042091e8,%rax
  80042090f4:	00 00 00 
  80042090f7:	ff d0                	callq  *%rax
		pa += SECTSIZE;
  80042090f9:	48 81 45 e8 00 02 00 	addq   $0x200,-0x18(%rbp)
  8004209100:	00 
		*kvoffset += SECTSIZE;
  8004209101:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  8004209105:	48 8b 00             	mov    (%rax),%rax
  8004209108:	48 8d 90 00 02 00 00 	lea    0x200(%rax),%rdx
  800420910f:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  8004209113:	48 89 10             	mov    %rdx,(%rax)
		offset++;
  8004209116:	48 83 45 d8 01       	addq   $0x1,-0x28(%rbp)
	offset = (offset / SECTSIZE) + 1;

	// If this is too slow, we could read lots of sectors at a time.
	// We'd write more to memory than asked, but it doesn't matter --
	// we load in increasing order.
	while (pa < end_pa) {
  800420911b:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  800420911f:	48 3b 45 f0          	cmp    -0x10(%rbp),%rax
  8004209123:	72 ba                	jb     80042090df <readseg+0x8c>
		pa += SECTSIZE;
		*kvoffset += SECTSIZE;
		offset++;
	}

	if(((orgoff % SECTSIZE) + count) > SECTSIZE)
  8004209125:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8004209129:	25 ff 01 00 00       	and    $0x1ff,%eax
  800420912e:	48 03 45 e0          	add    -0x20(%rbp),%rax
  8004209132:	48 3d 00 02 00 00    	cmp    $0x200,%rax
  8004209138:	76 2f                	jbe    8004209169 <readseg+0x116>
	{
		readsect((uint8_t*) pa, offset);
  800420913a:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  800420913e:	48 8b 55 d8          	mov    -0x28(%rbp),%rdx
  8004209142:	48 89 d6             	mov    %rdx,%rsi
  8004209145:	48 89 c7             	mov    %rax,%rdi
  8004209148:	48 b8 e8 91 20 04 80 	movabs $0x80042091e8,%rax
  800420914f:	00 00 00 
  8004209152:	ff d0                	callq  *%rax
		*kvoffset += SECTSIZE;
  8004209154:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  8004209158:	48 8b 00             	mov    (%rax),%rax
  800420915b:	48 8d 90 00 02 00 00 	lea    0x200(%rax),%rdx
  8004209162:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  8004209166:	48 89 10             	mov    %rdx,(%rax)
	}
	assert(*kvoffset % SECTSIZE == 0);
  8004209169:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  800420916d:	48 8b 00             	mov    (%rax),%rax
  8004209170:	25 ff 01 00 00       	and    $0x1ff,%eax
  8004209175:	48 85 c0             	test   %rax,%rax
  8004209178:	74 35                	je     80042091af <readseg+0x15c>
  800420917a:	48 b9 ad a2 20 04 80 	movabs $0x800420a2ad,%rcx
  8004209181:	00 00 00 
  8004209184:	48 ba 77 a2 20 04 80 	movabs $0x800420a277,%rdx
  800420918b:	00 00 00 
  800420918e:	be d7 00 00 00       	mov    $0xd7,%esi
  8004209193:	48 bf 8c a2 20 04 80 	movabs $0x800420a28c,%rdi
  800420919a:	00 00 00 
  800420919d:	b8 00 00 00 00       	mov    $0x0,%eax
  80042091a2:	49 b8 9b 01 20 04 80 	movabs $0x800420019b,%r8
  80042091a9:	00 00 00 
  80042091ac:	41 ff d0             	callq  *%r8
}
  80042091af:	c9                   	leaveq 
  80042091b0:	c3                   	retq   

00000080042091b1 <waitdisk>:

void
waitdisk(void)
{
  80042091b1:	55                   	push   %rbp
  80042091b2:	48 89 e5             	mov    %rsp,%rbp
  80042091b5:	53                   	push   %rbx
  80042091b6:	48 83 ec 18          	sub    $0x18,%rsp
	// wait for disk reaady
	while ((inb(0x1F7) & 0xC0) != 0x40)
  80042091ba:	c7 45 f4 f7 01 00 00 	movl   $0x1f7,-0xc(%rbp)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  80042091c1:	8b 55 f4             	mov    -0xc(%rbp),%edx
  80042091c4:	89 55 e4             	mov    %edx,-0x1c(%rbp)
  80042091c7:	8b 55 e4             	mov    -0x1c(%rbp),%edx
  80042091ca:	ec                   	in     (%dx),%al
  80042091cb:	89 c3                	mov    %eax,%ebx
  80042091cd:	88 5d f3             	mov    %bl,-0xd(%rbp)
	return data;
  80042091d0:	0f b6 45 f3          	movzbl -0xd(%rbp),%eax
  80042091d4:	0f b6 c0             	movzbl %al,%eax
  80042091d7:	25 c0 00 00 00       	and    $0xc0,%eax
  80042091dc:	83 f8 40             	cmp    $0x40,%eax
  80042091df:	75 d9                	jne    80042091ba <waitdisk+0x9>
		/* do nothing */;
}
  80042091e1:	48 83 c4 18          	add    $0x18,%rsp
  80042091e5:	5b                   	pop    %rbx
  80042091e6:	5d                   	pop    %rbp
  80042091e7:	c3                   	retq   

00000080042091e8 <readsect>:

void
readsect(void *dst, uint64_t offset)
{
  80042091e8:	55                   	push   %rbp
  80042091e9:	48 89 e5             	mov    %rsp,%rbp
  80042091ec:	41 54                	push   %r12
  80042091ee:	53                   	push   %rbx
  80042091ef:	48 83 ec 60          	sub    $0x60,%rsp
  80042091f3:	48 89 7d 98          	mov    %rdi,-0x68(%rbp)
  80042091f7:	48 89 75 90          	mov    %rsi,-0x70(%rbp)
	// wait for disk to be ready
	waitdisk();
  80042091fb:	48 b8 b1 91 20 04 80 	movabs $0x80042091b1,%rax
  8004209202:	00 00 00 
  8004209205:	ff d0                	callq  *%rax
  8004209207:	c7 45 ec f2 01 00 00 	movl   $0x1f2,-0x14(%rbp)
  800420920e:	c6 45 eb 01          	movb   $0x1,-0x15(%rbp)
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  8004209212:	0f b6 45 eb          	movzbl -0x15(%rbp),%eax
  8004209216:	8b 55 ec             	mov    -0x14(%rbp),%edx
  8004209219:	ee                   	out    %al,(%dx)

	outb(0x1F2, 1);		// count = 1
	outb(0x1F3, offset);
  800420921a:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  800420921e:	0f b6 c0             	movzbl %al,%eax
  8004209221:	c7 45 e4 f3 01 00 00 	movl   $0x1f3,-0x1c(%rbp)
  8004209228:	88 45 e3             	mov    %al,-0x1d(%rbp)
  800420922b:	0f b6 45 e3          	movzbl -0x1d(%rbp),%eax
  800420922f:	8b 55 e4             	mov    -0x1c(%rbp),%edx
  8004209232:	ee                   	out    %al,(%dx)
	outb(0x1F4, offset >> 8);
  8004209233:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  8004209237:	48 c1 e8 08          	shr    $0x8,%rax
  800420923b:	0f b6 c0             	movzbl %al,%eax
  800420923e:	c7 45 dc f4 01 00 00 	movl   $0x1f4,-0x24(%rbp)
  8004209245:	88 45 db             	mov    %al,-0x25(%rbp)
  8004209248:	0f b6 45 db          	movzbl -0x25(%rbp),%eax
  800420924c:	8b 55 dc             	mov    -0x24(%rbp),%edx
  800420924f:	ee                   	out    %al,(%dx)
	outb(0x1F5, offset >> 16);
  8004209250:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  8004209254:	48 c1 e8 10          	shr    $0x10,%rax
  8004209258:	0f b6 c0             	movzbl %al,%eax
  800420925b:	c7 45 d4 f5 01 00 00 	movl   $0x1f5,-0x2c(%rbp)
  8004209262:	88 45 d3             	mov    %al,-0x2d(%rbp)
  8004209265:	0f b6 45 d3          	movzbl -0x2d(%rbp),%eax
  8004209269:	8b 55 d4             	mov    -0x2c(%rbp),%edx
  800420926c:	ee                   	out    %al,(%dx)
	outb(0x1F6, (offset >> 24) | 0xE0);
  800420926d:	48 8b 45 90          	mov    -0x70(%rbp),%rax
  8004209271:	48 c1 e8 18          	shr    $0x18,%rax
  8004209275:	83 c8 e0             	or     $0xffffffe0,%eax
  8004209278:	0f b6 c0             	movzbl %al,%eax
  800420927b:	c7 45 cc f6 01 00 00 	movl   $0x1f6,-0x34(%rbp)
  8004209282:	88 45 cb             	mov    %al,-0x35(%rbp)
  8004209285:	0f b6 45 cb          	movzbl -0x35(%rbp),%eax
  8004209289:	8b 55 cc             	mov    -0x34(%rbp),%edx
  800420928c:	ee                   	out    %al,(%dx)
  800420928d:	c7 45 c4 f7 01 00 00 	movl   $0x1f7,-0x3c(%rbp)
  8004209294:	c6 45 c3 20          	movb   $0x20,-0x3d(%rbp)
  8004209298:	0f b6 45 c3          	movzbl -0x3d(%rbp),%eax
  800420929c:	8b 55 c4             	mov    -0x3c(%rbp),%edx
  800420929f:	ee                   	out    %al,(%dx)
	outb(0x1F7, 0x20);	// cmd 0x20 - read sectors

	// wait for disk to be ready
	waitdisk();
  80042092a0:	48 b8 b1 91 20 04 80 	movabs $0x80042091b1,%rax
  80042092a7:	00 00 00 
  80042092aa:	ff d0                	callq  *%rax
  80042092ac:	c7 45 bc f0 01 00 00 	movl   $0x1f0,-0x44(%rbp)
  80042092b3:	48 8b 45 98          	mov    -0x68(%rbp),%rax
  80042092b7:	48 89 45 b0          	mov    %rax,-0x50(%rbp)
  80042092bb:	c7 45 ac 80 00 00 00 	movl   $0x80,-0x54(%rbp)
}

static __inline void
insl(int port, void *addr, int cnt)
{
	__asm __volatile("cld\n\trepne\n\tinsl"			:
  80042092c2:	8b 45 bc             	mov    -0x44(%rbp),%eax
  80042092c5:	48 8b 4d b0          	mov    -0x50(%rbp),%rcx
  80042092c9:	8b 55 ac             	mov    -0x54(%rbp),%edx
  80042092cc:	49 89 cc             	mov    %rcx,%r12
  80042092cf:	89 d3                	mov    %edx,%ebx
  80042092d1:	4c 89 e7             	mov    %r12,%rdi
  80042092d4:	89 d9                	mov    %ebx,%ecx
  80042092d6:	89 c2                	mov    %eax,%edx
  80042092d8:	fc                   	cld    
  80042092d9:	f2 6d                	repnz insl (%dx),%es:(%rdi)
  80042092db:	89 cb                	mov    %ecx,%ebx
  80042092dd:	49 89 fc             	mov    %rdi,%r12
  80042092e0:	4c 89 65 b0          	mov    %r12,-0x50(%rbp)
  80042092e4:	89 5d ac             	mov    %ebx,-0x54(%rbp)

	// read a sector
	insl(0x1F0, dst, SECTSIZE/4);
}
  80042092e7:	48 83 c4 60          	add    $0x60,%rsp
  80042092eb:	5b                   	pop    %rbx
  80042092ec:	41 5c                	pop    %r12
  80042092ee:	5d                   	pop    %rbp
  80042092ef:	c3                   	retq   

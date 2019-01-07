!
! SYS_SIZE is the number of clicks (16 bytes) to be loaded.
! 0x3000 is 0x30000 bytes = 196kB, more than enough for current
! versions of linux
!
SYSSIZE = 0x3000
!
!	bootsect.s		(C) 1991 Linus Torvalds
!
! bootsect.s is loaded at 0x7c00 by the bios-startup routines, and moves
! iself out of the way to address 0x90000, and jumps there.
!
! It then loads 'setup' directly after itself (0x90200), and the system
! at 0x10000, using BIOS interrupts. 
!
! NOTE! currently system is at most 8*65536 bytes long. This should be no
! problem, even in the future. I want to keep it simple. This 512 kB
! kernel size should be enough, especially as this doesn't contain the
! buffer cache as in minix
!
! The loader has been made as simple as possible, and continuos
! read errors will result in a unbreakable loop. Reboot by hand. It
! loads pretty fast by getting whole sectors at a time whenever possible.
!此段程序的作用是将4个扇区的数据拷贝到0x9020:0000处拷贝4个扇区，并将剩下的数据拷贝到0x1000:0000处
.globl begtext, begdata, begbss, endtext, enddata, endbss
.text
begtext:
.data
begdata:
.bss
begbss:
.text
!段地址左移4位加上IP的值得到的是当前程序运行的地址
SETUPLEN = 4				! nr of setup-sectors
BOOTSEG  = 0x07c0			! original address of boot-sector 		引导程序的起始地址
INITSEG  = 0x9000			! we move boot here - out of the way	初始化程序的地址
SETUPSEG = 0x9020			! setup starts here						启动程序的地址
SYSSEG   = 0x1000			! system loaded at 0x10000 (65536).		系统的加载位置
ENDSEG   = SYSSEG + SYSSIZE		! where to stop loading				程序结束的位置0x4000

! ROOT_DEV:	0x000 - same type of floppy as boot.
!			0x301 - first partition on first drive etc
ROOT_DEV = 0x306													!设置系统所在的设备号（设备号=主设备号*256+次设备号）
!主设备号：1内存；2磁盘；3硬盘；4 ttyx;5 tty;6并行口；7非命名管道								

entry start															!告知连接程序程序的开始执行处
start:
	mov	ax,#BOOTSEG
	mov	ds,ax
	mov	ax,#INITSEG
	mov	es,ax
	mov	cx,#256
	sub	si,si
	sub	di,di
	rep																!重复执行下面的操作
	movw															!将BOOTSEG的内容复制到INITSEG复制256个字(2 byte)
	jmpi	go,INITSEG												!跳转到INITSEG处的go处进行执行 CS=0X9000 IP=go
go:	mov	ax,cs														!设置ax,ds,es的值为cs的值0x9000
	mov	ds,ax
	mov	es,ax
! put stack at 0x9ff00.
	mov	ss,ax														!设置栈顶为0x9ff00
	mov	sp,#0xFF00		! arbitrary value >>512

! load the setup-sectors directly after the bootblock.
! Note that 'es' is already set up.
!这里有对Int 13进行完整的解释 https://en.wikipedia.org/wiki/INT_13H
!从磁盘进行读取数据读取4个扇区
load_setup:												
	mov	dx,#0x0000		! drive 0, head 0							!设置dx的值为0,cx的值为2,bx的值为0x200,ax的值为0x200+4
	mov	cx,#0x0002		! sector 2, track 0							!从软盘的第二个扇区开始读取4个扇区的数据到0x90200处
	mov	bx,#0x0200		! address = 512, in INITSEG
	mov	ax,#0x0200+SETUPLEN	! service 2, nr of sectors
	int	0x13			! read it			
	jnc	ok_load_setup		! ok - continue							!如果C位为0跳转至ok_load_setup
	mov	dx,#0x0000
	mov	ax,#0x0000		! reset the diskette
	int	0x13
	j	load_setup

ok_load_setup:

! Get disk drive parameters, specifically nr of sectors/track
!使用中断13进行获取软盘的参数
	mov	dl,#0x00
	mov	ax,#0x0800		! AH=8 is get drive parameters					
	int	0x13
	mov	ch,#0x00
	seg cs															!指定下一条语句使用的段寄存器
	mov	sectors,cx													!将磁盘的每个磁道的扇区数写入sectors中
	mov	ax,#INITSEG													!设置ax的值为0x9000	
	mov	es,ax														!设置ex的值为0x9000

! Print some inane message
!使用中断0x10获取光标的位置和形状
	mov	ah,#0x03		! read cursor pos
	xor	bh,bh
	int	0x10
!使用中断0x10设置屏幕上显示的内容	
	mov	cx,#24														!设置字符串长度
	mov	bx,#0x0007		! page 0, attribute 7 (normal)				!设置写的页号和颜色为灰色
	mov	bp,#msg1													!设置需要打印的字符
	mov	ax,#0x1301		! write string, move cursor					!设置为在屏幕上输出且为写模式
	int	0x10

! ok, we've written the message, now
! we want to load the system (at 0x10000)

	mov	ax,#SYSSEG													!设置ax的值为0x1000
	mov	es,ax		! segment of 0x010000							!设置es的值
	call	read_it													!调用函数read_it
	call	kill_motor												!调用函数kill_motor

! After that we check which root-device to use. If the device is
! defined (!= 0), nothing is done and the given device is used.
! Otherwise, either /dev/PS0 (2,28) or /dev/at0 (2,8), depending
! on the number of sectors that the BIOS reports currently.
!判断磁盘类型，如果定义了使用定义的磁盘作为文件系统反之根据软盘来确定根文件系统
	seg cs
	mov	ax,root_dev
	cmp	ax,#0
	jne	root_defined
	seg cs
	mov	bx,sectors
	mov	ax,#0x0208		! /dev/ps0 - 1.2Mb
	cmp	bx,#15
	je	root_defined
	mov	ax,#0x021c		! /dev/PS0 - 1.44Mb
	cmp	bx,#18
	je	root_defined
undef_root:
	jmp undef_root
root_defined:
	seg cs
	mov	root_dev,ax

! after that (everyting loaded), we jump to
! the setup-routine loaded directly after
! the bootblock:

	jmpi	0,SETUPSEG

! This routine loads the system at address 0x10000, making sure
! no 64kB boundaries are crossed. We try to load it as fast as
! possible, loading whole tracks whenever we can.
!
! in:	es - starting address segment (normally 0x1000)
!
sread:	.word 1+SETUPLEN	! sectors read of current track			!设置
head:	.word 0			! current head								!设置头为当前头
track:	.word 0			! current track								!设置磁道为当前磁道

read_it:
	mov ax,es														！设置ax的参数值
	test ax,#0x0fff													!执行逻辑与操作判断地址是否是64k地址对齐，如果是对齐的则ZF位为1
die:	jne die			! es must be at 64kB boundary				!判断是否是64k地址对齐，如果不对齐循环执行
	xor bx,bx		! bx is starting address within segment
rp_read:
	mov ax,es														!将es的值传入ax
	cmp ax,#ENDSEG		! have we loaded all yet?					!判断ax的值是否与0x4000的值相等
	jb ok1_read														!如果ax的值于0x4000的值不相等跳转到ok1_read,不相等时跳转
	ret
ok1_read:
	seg cs						
	mov ax,sectors													!将扇区的数量写入ax中
	sub ax,sread													!获取未读的扇区数量
	mov cx,ax					
	shl cx,#9														!cx逻辑左移9位
	add cx,bx														!cx的值加上当前的段内偏移
	jnc ok2_read													!如果没有超过64k跳转至ok2_read，jnc没有进位
	je ok2_read														
	xor ax,ax
	sub ax,bx
	shr ax,#9
ok2_read:
	call read_track													!调用读磁盘函数
	mov cx,ax
	add ax,sread													!设置ax的值为软盘的扇区总数
	seg cs
	cmp ax,sectors													!判断ax的值是否与sectors中的数据相等
	jne ok3_read
	mov ax,#1
	sub ax,head
	jne ok4_read
	inc track
ok4_read:
	mov head,ax
	xor ax,ax
ok3_read:
	mov sread,ax
	shl cx,#9
	add bx,cx
	jnc rp_read
	mov ax,es
	add ax,#0x1000
	mov es,ax
	xor bx,bx
	jmp rp_read
!读取整个剩余的扇区
read_track:
	push ax							
	push bx
	push cx
	push dx
	mov dx,track												!设置dx的值为0
	mov cx,sread												!设置cx的值为当前已经读取的扇区数量
	inc cx														!设置开始读取的扇区
	mov ch,dl													!设置轨道号
	mov dx,head													!设置dx的值为head
	mov dh,dl			
	mov dl,#0
	and dx,#0x0100												!设置磁头号不能大于0
	mov ah,#2
	int 0x13
	jc bad_rt
	pop dx
	pop cx
	pop bx
	pop ax
	ret
bad_rt:	mov ax,#0
	mov dx,#0
	int 0x13
	pop dx
	pop cx
	pop bx
	pop ax
	jmp read_track

/*
 * This procedure turns off the floppy drive motor, so
 * that we enter the kernel in a known state, and
 * don't have to worry about it later.
 */
kill_motor:
	push dx
	mov dx,#0x3f2
	mov al,#0
	outb
	pop dx
	ret

sectors:
	.word 0

msg1:
	.byte 13,10
	.ascii "Loading system ..."
	.byte 13,10,13,10

.org 508
root_dev:
	.word ROOT_DEV
boot_flag:
	.word 0xAA55

.text
endtext:
.data
enddata:
.bss
endbss:

/*
 *  linux/lib/open.c
 *
 *  (C) 1991  Linus Torvalds
 */

#define __LIBRARY__
#include <unistd.h>
#include <stdarg.h>
/**
 * 打开文件
 * filename是文件名
 * flag是打开类型
 * 剩下的是打开模式*/
int open(const char * filename, int flag, ...)
{
	register int res;
	va_list arg;

	va_start(arg,flag);
	__asm__("int $0x80"
		:"=a" (res)										//output
		:"0" (__NR_open),"b" (filename),"c" (flag),		//input
		"d" (va_arg(arg,int)));							//被修改的寄存器
	if (res>=0)
	{
		return res;
	}
	errno = -res;
	return -1;
}

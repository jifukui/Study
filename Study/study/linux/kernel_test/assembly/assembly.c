#include <stdio.h>
int main()
{
	int a=10,b=2;
	__asm__(
			"movl %1,%%eax\r\n"
			"movl %%eax,%0\r\n"
			:"=r"(b)
			:"r"(a)
			:"%eax"
			);
	printf("The Result:%d ,%d \n",a,b);
	return 0;
}

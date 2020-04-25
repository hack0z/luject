#include "sub.h"

int sub(int a, int b)
{
    return a + b;
}
#if !defined(_WIN32)
void __attribute__ ((constructor)) sub_init(void)
{
    printf("sub: injected ok!\n");
}
#endif

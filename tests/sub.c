#include "sub.h"
#include <stdio.h>

int sub(int a, int b)
{
    return a + b;
}
#if defined(_WIN32)
#include <windows.h>
BOOL WINAPI DllMain(HINSTANCE hinstDLL, DWORD fdwReason, PVOID lpReserved)
{
    printf("sub: injected ok!\n");
    return TRUE;
}
#else
void __attribute__ ((constructor)) sub_init(void)
{
    printf("sub: injected ok!\n");
}
#endif

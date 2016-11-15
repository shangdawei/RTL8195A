#include "rtl8195a.h"

#if defined (RTL8710)
#define SYSCLK_FREQ  83333333
#else
#define SYSCLK_FREQ  166666666
#endif

uint32_t SystemCoreClock = SYSCLK_FREQ;

extern uint32_t __vector_table;

void SetSysClock( void ){}

void SystemInit( void )
{
  SetSysClock();

  SCB->VTOR = (uint32_t)&__vector_table;
}

void SystemCoreClockUpdate( void )
{
  SystemCoreClock = SYSCLK_FREQ;
}

#include "cmsis_os2.h"
#include "rtl8195a.h"

void HPTask( void * Arg )
{
  while ( 1 )
  {
    osDelay( 50 );
  }
}

void LPTask( void * Arg )
{
  while ( 1 )
  {
    osDelay( 200 );
  }
}


int main( void )
{
  SystemCoreClockUpdate();

  osKernelInitialize();

  osThreadNew( LPTask, NULL, NULL );
  osThreadNew( HPTask, NULL, NULL );

  if ( osKernelGetState() == osKernelReady )
    osKernelStart();

  while ( 1 )
  {
  }
}
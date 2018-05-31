#include "printf.h"

void main()
{
   uint16_t val = 0;
   uint8_t i;

   for (i=0; i<20; ++i)
   {
      printfHex16(val);
      printf("\n");
      val = ((val<<1) + (val>>15)) ^ 0x4321;
   }

   // Infinite loop
   while(1)
   {
   }

} // end of main

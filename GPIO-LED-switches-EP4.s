@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@ PRACTICE DESIGN QUESTION 4
@@
@@ Use GPIO to accept input and send to LEDs,
@@ provide output based on switches
@@ pins 0 9 are input, but only ODD pins display
@@ to LEDs
@@ pins 10 to 19 are output, but only EVEN pins
@@ write data from switches
@@
@@ Written by John McLeod, 2022 04 06
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ CONSTANTS
.text
  .equ LED_BASE,      0xFF200000
  .equ SW_BASE,       0xFF200040
  .equ GPIO_BASE,     0xFF200060
  .equ EVEN_BIT_MASK, 0b0101010101
  .equ ODD_BIT_MASK,  0b1010101010
  .equ ALL_BIT_MASK,  0b1111111111
  
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ MAIN PROGRAM
.global _start
_start:
  
  @ get GPIO pointer
  ldr r4, =GPIO_BASE
  @ get LED pointer
  ldr r5, =LED_BASE
  @ get switch pointer
  ldr r6, =SW_BASE
  
  @ set bottom 10 pins for input
  @ first get mask that is all 1s except bottom 10 bits are 0
  ldr r7, =ALL_BIT_MASK
  mvn r7, r7
  @ get current state of GPIO
  ldr r1, [ r4, #4 ]
  @ clear bottom 10 bits, leave others as-is
  and r1, r7  
  @ now set next 10 pins as output
  @ get bitmask again  
  ldr r7, =ALL_BIT_MASK
  @ shift over by 10
  lsl r7, #10
  @ reuse old GPIO state in r1, set next 10 as output
  orr r1, r7
  @ write everything back to GPIO
  str r1, [ r4, #4 ]
  
  @ load mask for odd bits for input
  ldr r8, =ODD_BIT_MASK
  @ load mask for even bits for output
  ldr r9, =EVEN_BIT_MASK
  
  @ invert bitmask in r0 for use later
  mvn r7, r7
  
_loop:
  @ read input from GPIO
  ldr r0, [ r4 ]
  @ mask everything except odd bits in first 10
  and r1, r0, r8
  @ write to LEDs
  str r1, [ r5 ]
  
  @ read input from switches
  ldr r1, [ r6 ]
  @ mask input except for even bits
  and r1, r9
  @ shift over by 10
  lsl r1, #10
  @ reuse GPIO state from r0
  @ clear everything except bits 19..10
  @ appropriate bitmask is still in r7
  and r0, r7
  @ add switch data for output
  orr r0, r1
  @ write to GPIO
  str r0, [ r4 ]
  
  b _loop
  
  
  
  
//////////////////////////////////////////////////////
// PRACTICE DESIGN QUESTION 5
//
// Turns ARM into countdown timer
// Any key (except "enter") pressed in JTAG UART will 
// be displayed in ASCII code in binary on LED
//
// Pressing "enter" will start countdown in 
//  100 ms intervals
//
// As a design choice (this wasn't completely specified
// in problem statement) everything entered in JTAG UART
// while countdown is in progress is silently ignored
//
// Written by John McLeod, 2022 04 06
//////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////
// CONSTANTS
.text
  .equ LED_BASE,             0xFF200000
  .equ JTAG_UART_BASE,       0xFF201000
  .equ TIMER_BASE,           0xFF202000
  .equ ASCII_ENTER,          0x0A
  
////////////////////////////////////////////////////////////////////////
// MAIN PROGRAM
.global _start
_start:

  // set up timer, first get timer address
  ldr r4, =TIMER_BASE
  // 100 ms at 100 MHz
  ldr r0, =10000000
  // write to low period
  str r0, [ r4, #8 ]
  // shift right by 16 bits and write to high period
  lsr r0, #16
  str r0, [ r4, #12 ]
  
  // initialize counter
  mov r3, #0  
  
  // pointer to UART
  ldr r5, =JTAG_UART_BASE
  // pointer to LEDs
  ldr r6, =LED_BASE
  
  // main loop
_loop:
  // read from UART
  ldr r0, [ r5 ]
  // check if this is valid data; is bit 15 set?
  mov r1, #0x8000
  ands r1, r0
  // if yes, eliminated everything except bottom 8 bits
  andne r2, r0, #0xFF  
  
  // check if timer is counting and had timeout
  ldr r0, [ r4 ]
  mov r1, #1
  ands r0, r1
  // if yes, decrement counter
  subne r3, #1
  // clear time-out flag
  strne r1, [ r4 ]
  // otherwise timer is still counting
  // update LEDs
  streq r3, [ r6 ]
  
  // check if LED count is below zero
  cmp r3, #0
  // if yes, turn off timer
  movmi r1, #8
  strmi r1, [ r4, #4 ]
  
  // get timer status again
  ldr r0, [ r4 ]
  // if it is done counting, process UART data
  cmp r0, #0
  // if not done counting, loop back
  bne _loop
  // otherwise check if 'enter' was pressed
  // UART data still in r2
  ldr r0, =ASCII_ENTER
  cmp r2, r0
  // if 'enter' pressed, start timer
  moveq r0, #6
  streq r0, [ r4, #4 ]
  // otherwise use UART data as new counter
  movne r3, r2
  
  b _loop


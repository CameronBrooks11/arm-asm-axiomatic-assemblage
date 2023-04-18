////////////////////////////////////////////////
// INTERRUPT VECTOR TABLE
// as described in the appendix
.section .vectors, "a"
  .word unused          // IRQ 0
  .word unused          // IRQ 1
  .word unused          // IRQ 2
  .word unused          // IRQ 3  
  .word unused          // IRQ 4
  .word unused          // IRQ 5
  .word unused          // IRQ 6
  .word unused          // IRQ 7
  .word timer_isr       // IRQ 8
  .word unused          // IRQ 9
  .word unused          // IRQ 10
  .word unused          // IRQ 11
  .word unused          // IRQ 12
  .word adc_isr         // IRQ 13
  .word unused          // IRQ 14
  .word unused          // IRQ 15

//////////////////////////////////////////////// 
// GLOBAL VARIABLES
.data
// used to store the number of clock cycles 
// for the on-time
// (off-time is then 1000 - high_period)
  .word high_period     500
// used to indicate whether output is 
// currently 0 or 1  
  .word output_level    1

////////////////////////////////////////////////
// CONSTANTS
.text
  .equ TIMER_BASE,  0x6400
  .equ ADC_BASE,    0x7000
  .equ GPIOA_BASE,  0x6000
  .equ UART_BASE,   0x7400

////////////////////////////////////////////////
// MAIN PROGRAM
.global _start
_start:
  
  // turn on interrupts for IRQ 8 and 13
  // timer A and ADC, respectively
  ldr r0, =0x2100
  msr irqen, r0
  
  // configure the ADC for interrupts
  ldr r0, =ADC_BASE
  mov r1, #1
  // enable interrupts
  // manual doesn't specify whether or not
  // ADC is byte-addressable, so I'll assume
  // it is
  strb r1, [ r0, #1 ]
  
  // configure the timer for interrupts
  ldr r0, =TIMER_BASE
  str r1, [ r0, #4 ]
  
  // configure UART for 8-0-1 and 9600 baud
  mov r0, =UART_BASE
  // from appendix, 8-0-1 and 9600 baud and
  // no interrupts is
  // 0b00xx 0x01 xx10 xx10
  // where x is don't care, I'll treat x = 0
  ldr r1, =0x0122  
  str r1, [ r0, #2 ] 
  
  // use pin 0 of GPIO port A, set to output
  ldr r0, =GPIOA_BASE
  mov r1, #1
  str r1, [ r0, #2 ]
  // set output to 1
  str r1, [ r0 ]
  
  // assume this whole thing starts on a rising
  // edge with 50-50 duty cycle  
  ldr r0, =TIMER_BASE
  ldr r1, adr_high_period
  ldr r2, [ r1 ]
  // start timer
  str r2, [ r0 ]
  
  // do nothing and watch interrupt magic happen
_loop:
  b loop
  
////////////////////////////////////////////////
// INTERRUPT SERVICE ROUTINES
// note that since:
//  - the main program does nothing
//  - interrupts are not nested
//  - my ISRs don't call any nested subroutines
// I do not preserve the state of any registers
// using the stack
// I also do not preserve cpsr for the same reason
timer_isr:
  // get current part of cycle
  ldr r4, adr_output_level
  ldr r1, [ r4 ]
  cmp r1, #0
  beq _rising_edge
_falling_edge:
  // set output pin to low
  mov r1, #0
  ldr r0, =GPIOA_BASE
  mov r1, [ r0 ]
  // record low output to memory
  str r1, [ r4 ]
  // get low period
  ldr r2, adr_high_period
  ldr r1, =1000
  sub r1, r2
  // start timer for low period
  ldr r0, =TIMER_BASE
  str r1, [ r0 ]
  // start ADC sampling on channel 0
  ldr r0, =ADC_BASE
  // again write as a byte to avoid
  // changing interrupt
  strb r1, [ r0 ]
  b _exit_timer_isr
_rising_edge:
  // set output pin to high_period
  mov r1, #1
  ldr r0, =GPIOA_BASE
  mov r1, [ r0 ]
  // record high output to memory
  str r1, [ r4 ]
  // get high period
  ldr r1, adr_high_period
  // start timer for high period
  ldr r0, =TIMER_BASE
  str r1, [ r0 ]
  // write high period to UART
  // first divide high period by 4 
  // because UART only writes one byte
  lsr r1, #2 
  ldr r0, =UART_BASE
  str r1, [ r0, #6 ]
_exit_timer_isr:
  // clear interrupts on timer
  // write any value to status register
  ldr r0, =TIMER_BASE
  mov r1, #1
  str r1, [ r0, #2 ]
  // exit
  subs pc, lr, #2
 
adc_isr:
  // read from channel 0
  ldr r0, =ADC_BASE
  ldr r1, [ r0, #4 ]
  
  // cap value at 250
  cmp r1, #250
  movgt r1, #250
  // multiply value by 4 to make it between
  // 0 and 1000
  lsl r1, #4
  // save to memory
  ldr r0, adr_high_period
  str r1, [ r0 ]
  
  // Appendix doesn't describe clearing interrupts
  // from ADC, so I guess they are automatically cleared?
  // (Or I forgot to mention it when I wrote the Appendix...)
  
  subs pc, lr, #2
    
////////////////////////////////////////////////
// ADDRESSES
adr_high_period:
  .word high_period
adr_output_level:
  .word output_level
  

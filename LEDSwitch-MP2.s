/*
Write a subroutine in Assembly that toggles the LEDs 
- i.e. flips all on LEDs to off, and all off LEDs to on. 
This subroutine accepts no parameters and does not return anything.
*/

// main program
// this was not requested by the question but is
// needed to help test the code
.global _start
_start:

  // set up LEDs with some pattern
  ldr r0, =0xFF200000
  mov r1, #0xA6
  str r1, [r0]

  // main loop
loop:

  // loop a bunch of times to delay CPU
  // so we can see pattern change
  // if you are stepping through code
  // line-by-line then delete this
  // delay
  ldr r4, =100000
delay:
  subs r4, #1
  bne delay

  // toggle LEDs
  bl toggle_LEDs 

  // repeat
  b loop

////////////////////////////////
// subroutine to toggle state of LEDs
// accepts nothing, returns nothing
toggle_LEDs:
  // does not preserve state because
  // only uses registers r0 - r3
  // and doesn't have any nested subroutines

  // get LED address
  ldr r0, =0xFF200000
  // get current LED pattern
  ldr r1, [r0]

  // toggle it by XOR with ten 1's
  // note that ten 1's is larger than 8-bits
  // so either use movw (can handle up to 16-bits)
  // or 'ldr r2, =0x3FF'
  movw r2, #0x3FF
  eor r1, r2

  // write back to LEDs
  str r1, [r0]

  // done
  bx lr
////////////////////////////////
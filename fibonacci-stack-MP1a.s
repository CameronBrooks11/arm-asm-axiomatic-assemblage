/*
Write a subroutine in Assembly that preserves state 
(i.e. pushes/pops registers from stack) to write the first 
10 Fibonacci numbers to memory, starting at the address 
given in register r0.
*/

// main program
// this was not requested by the question but is
// needed to help test the code
.global _start
_start:
  // initialize some memory address into r0
  ldr r0, =0x0400

  // write fibonnaci numbers
  bl fibonnaci_10

  // dead loop
idle:
  b idle

////////////////////////////////
// subroutine to calculate the first
// 10 fibonnaci numbers
// store them to memory starting at
// address in r0
fibonnaci_10:
  // preserve state
  push {r4, r5, lr}

  // memory address is in r0,
  // but I want to use that register
  // move address somewhere else
  mov r4, r0


  // first get first two numbers
  mov r0, #1
  mov r1, #0

  // write first numbers
  str r1, [r4, #4]!
  str r0, [r4, #4]!

  // initialize counter
  // first two already written
  // so only need to write 8 more
  mov r5, #8

loop:
  // calculate next number
  bl next_fibonnaci

  // now next number is in r0
  // write number
  str r0, [r4, #4]!

  // decrement counter
  subs r5, #1
  // loop is done when 
  // counter is zero
  bne loop
 
  // restore state 
  pop {r4, r5, lr}

  // return
  bx lr
////////////////////////////////

////////////////////////////////
// subroutine to calculate the
// next fibonnaci number f(N+1)
// expects f(N) to be in r0
// and f(N-1) to be in r1
next_fibonnaci:
  // back up copy of f(N)
  mov r2, r0
  // calculate f(N+1)
  add r0, r1
  // move f(N) to r1
  mov r1, r2  
  // return
  bx lr
////////////////////////////////
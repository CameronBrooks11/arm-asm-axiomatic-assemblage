//////////////////////////////////////////////////////
// PRACTICE DESIGN QUESTION 3
//
// Count up to 100 on the ARM in 1 s intervals
// Current count displayed on seven-segment display
//
// As a design choice (this wasn't completely specified
// in problem statement) after count reaches 99 it wraps
// around back to 0 and repeats
// (technically 0 to 99 is a 100-count)
//
// Written by John McLeod, 2022 04 06
//////////////////////////////////////////////////////

//////////////////////////////////////////////////////
// DATA

// codes for seven-segment display
.data
hex_codes:
  .word 0x3F // 0 on seven-segment
  .word 0x06 // 1
  .word 0x5B // 2
  .word 0x4F // 3
  .word 0x66 // 4
  .word 0x6D // 5
  .word 0x7D // 6
  .word 0x07 // 7
  .word 0x7F // 8
  .word 0x6F // 9
  .word 0x77 // A
  .word 0x7C // B
  .word 0x39 // C
  .word 0xE5 // D
  .word 0x79 // E
  .word 0x71 // F
  
//////////////////////////////////////////////////////
// MAIN PROGRAM
.text
.global _start

_start:

  // set up timer, first get timer address
  ldr r4, =0xFF202000
  // 1 s at 100 MHz
  ldr r0, =100000000
  // write to low period
  str r0, [ r4, #8 ]
  // shift right by 16 bits and write to high period
  lsr r0, #16
  str r0, [ r4, #12 ]
  // start timer for countdown and repeat
  mov r0, #6
  str r0, [ r4, #4 ]
  
  // initialize counter
  mov r5, #0
  
  // main loop
_loop:
  // move counter to r0
  mov r0, r5
  // display on seven segment
  bl display_hex
  
  // check if timer is counting and has had a timeout
  ldr r0, [ r4 ]
  ands r0, #1
  beq _loop
  // increment count
  add r5, #1
  // clear timeout flag
  mov r0, #1
  str r0, [ r4 ]
  
  // roll-over counter if necessary
  cmp r5, #100
  moveq r5, #0

  b _loop
  
//////////////////////////////////////////////////////
// SUBROUTINES

// this subroutine writes 2-digit decimal to
// seven-segment display
// expects value to be in r0
display_hex:
  // preserve state
  push { r4 - r8, lr }
  
  // seven-segment address
  ldr r4, =0xFF200020
  // get address of hex codes
  ldr r5, adr_codes
  // copy number
  mov r6, r0
  
  // get 1s place value
  bl modulo_10
  // multiply by 4 to get byte address offset
  mov r1, r0, lsl #2
  // get hex code
  ldr r8, [ r5, r1 ]
  
  // get 10s place value
  mov r0, r6
  bl divide_by_10
  // copy this
  mov r6, r0
  bl modulo_10
  // multiply by 4 to get byte address offset
  mov r1, r0, lsl #2
  // get hex code
  ldr r7, [ r5, r1 ]
  // add to existing code
  add r8, r7, lsl #8
  
  // display on seven-segment
  str r8, [ r4 ]
  
  // restore state
  pop { r4 - r8, lr }
  // return
  bx lr
  
// this subroutine divides by 10 as an integer
// expects the value to be in r0
// this avoids using any division mnemonic
// basic idea:
// x / 10 = x / 8 * (4/5)
//        = x / 8 * (1 - 1/5)
//        = 1 / 8 * (x - x/5)
//        = 1 / 8 * (x - x/4 * 4/5)
//        = 1 / 8 * (x - 1/4 * ( x - x/5 ))
//        = 1 / 8 * (x - 1/4 * ( x - 1/4* (x - x/5 ))
// etc.
// eventually error is too small to be retained as an integer
// division by powers of 2 is easily done by logical shifts right
divide_by_10:
  // preserve state
  push { r4, r5 }
  // copy number over to r4
  mov r4, r0
  // divide by 4 three times is sufficient
  mov r5, #3
_divide_by_10_loop:
  // divide by 4
  lsr r4, #2
  // subtract from original value
  subs r4, r0, r4
  subs r5, #1
  bne _divide_by_10_loop
  
  // divide final result by 8
  lsr r4, #3
  // move result to r0
  mov r0, r4
  
  // restore state
  pop { r4, r5 }
  // return
  bx lr
 
// this subroutine multiplies by 10
// avoiding using any multiplication mnemonics
// expects the value to be in r0
// 10 x = 8 x + 2 x
// multiplying by 8 and 2 are just logical shifts left
// there are other ways to implement a division using "magic numbers",
// but I came up with this way BY MYSELF and am very proud of it
multiply_by_10:
  // preserve state
  push { r4 }
  // multiply by 8
  lsl r4, r0, #3
  // add result multiplied by 2
  add r4, r0, lsl #1
  
  // move result to r0
  mov r0, r4
  // restore state
  pop { r4 }
  // return
  bx lr
  
// this subroutine divides by 10 and keeps the remainder
// expects the value to be in r0
modulo_10:
  // preserve state
  push { r4, lr }
  
  // copy value
  mov r4, r0
  
  // divide by 10 as integer
  bl divide_by_10
  // multiply by 10
  bl multiply_by_10
  
  // difference is the remainder
  // x % 10 = x - 10 * int(x/10)
  sub r0, r4, r0
  
  // restore state
  pop { r4, lr }
  // return
  bx lr
  
//////////////////////////////////////////////////////
// data addresses 
adr_codes:
  .word hex_codes
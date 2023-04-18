@ main program
@ this was not requested by the question but is
@ needed to help test the code
.global _start
_start:
  @ initialize some memory address into r0
  ldr r0, =0x0600

  @ write fibonnaci numbers
  bl fibonnaci_10

  @ dead loop
idle:
  b idle

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ subroutine to calculate the first
@ 10 fibonnaci numbers
@ store them to memory starting at
@ address in r0
fibonnaci_10:
  @ no need to preserve state because
  @ this doesn't use any registers
  @ above r1

  @ get F(0)
  mov r1, #0
  str r1, [r0, #4]

  @ get F(1)
  mov r1, #1
  str r1, [r0, #8]

  @ get F(2)
  mov r1, #1
  str r1, [r0, #12]

  @ get F(3)
  mov r1, #2
  str r1, [r0, #16]

  @ get F(4)
  mov r1, #3
  str r1, [r0, #20]

  @ get F(5)
  mov r1, #5
  str r1, [r0, #24]

  @ get F(6)
  mov r1, #8
  str r1, [r0, #28]

  @ get F(7)
  mov r1, #13
  str r1, [r0, #32]

  @ get F(8)
  mov r1, #21
  str r1, [r0, #36]

  @ get F(9)
  mov r1, #34
  str r1, [r0, #40]

  @ all done!
  bx lr
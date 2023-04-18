@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@ PRACTICE DESIGN QUESTION 7
@@
@@ Watch pin 16 on GPIO 1
@@ On rising edge start timer, and time how long it takes
@@ until it goes low again
@@
@@ show time in 1/100ths second on 7-segment
@@
@@ Written by John McLeod, 2022 04 06
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ DATA

@ codes for seven-segment display
.data
hex_codes:
  .word 0x3F @ 0 on seven-segment
  .word 0x06 @ 1
  .word 0x5B @ 2
  .word 0x4F @ 3
  .word 0x66 @ 4
  .word 0x6D @ 5
  .word 0x7D @ 6
  .word 0x07 @ 7
  .word 0x7F @ 8
  .word 0x6F @ 9
  .word 0x77 @ A
  .word 0x7C @ B
  .word 0x39 @ C
  .word 0xE5 @ D
  .word 0x79 @ E
  .word 0x71 @ F
@ variables to store time
@ I am too lazy to write a subroutine to divide
@ one number into mm:ss:cc, so I'll store each digit
@ separately
sec_time:
  .word 0x0
min_time:
  .word 0x0

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ CONSTANTS
.text
  .equ SS03_BASE,     0xFF200020
  .equ SS45_BASE,     0xFF200030
  .equ TIMER_BASE,    0xFF202000
  .equ GPIO_BASE,     0xFF200060

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ MAIN PROGRAM
.text
.global _start

_start:

  @ set up timer, first get timer address
  ldr r4, =TIMER_BASE
  @ 10 ms at 100 MHz
  ldr r0, =1000000
  @ write to low period
  str r0, [ r4, #8 ]
  @ shift right by 16 bits and write to high period
  lsr r0, #16
  str r0, [ r4, #12 ]
  @ don't start timer yet
  
  @ configure GPIO pin 16 for input
  ldr r5, =GPIO_BASE
  ldr r0, [ r5, #4 ]  
  @ prepare mask for pin 16
  mov r1, #1
  mvn r1, r1, lsl #16
  @ apply mask
  and r0, r1
  @ write to GPIO
  str r0, [ r5, #4 ]
  
  @ invert mask and move to new register
  mvn r6, r1
  @ get initial GPIO value
  ldr r7, [ r5 ]
  and r7, r6

_loop:
  @ get new GPIO value
  ldr r8, [ r5 ]
  and r8, r6
  
  @ check if it went low-to-high
  subs r1, r7, r8
  @ reset clock if low-to-high
  bllt reset_gpio_clock
  @ start timer if low-to-high
  movlt r0, #6
  strlt r0, [ r4, #4 ]
  @ stop clock if high-to-low
  movgt r0, #8
  strgt r0, [ r4, #4 ]
  
  @ check if timer has timeout
  ldr r0, [ r4 ]
  tst r0, #1
  @ cleart timeout
  strne r0, [ r4 ]
  @ increment count if timeout
  blne increment_gpio_clock
  
  @ record new state
  mov r7, r8
  
  @ write to seven-segment
  bl write_time
  
  b _loop
  
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ SUBROUTINES

@ this subroutine clears the time stored in memory
reset_gpio_clock:  
  @ get seconds time from memory
  ldr r0, adr_sec
  @ wipe it
  mov r1, #0
  str r1, [ r0 ]
  @ get minutes time from memory
  ldr r0, adr_min
  @ wipe it
  str r1, [ r0 ]
  
  bx lr
  
@ this subroutine increments the time stored in memory
increment_gpio_clock:
  @ get seconds time from memory
  ldr r2, adr_sec
  @ get minuts time from memory
  ldr r3, adr_min
  
_increment_cs:
  @ add 1/100s to time
  ldrb r0, [ r2 ]
  add r0, #1
  @ check if >= 10
  cmp r0, #10 
  beq _increment_ds
  @ save back to memory if <= 10
  strb r0, [ r2 ]
  b _exit_increment_gpio_clock

_increment_ds:
  @ otherwise clear and carry
  mov r0, #0
  strb r0, [ r2 ]
  @ get 1/10s
  ldrb r0, [ r2, #1 ]
  add r0, #1
  @ check if >= 10
  cmp r0, #10  
  beq _increment_s
  @ save back to memory if <= 10
  strb r0, [ r2, #1 ]
  b _exit_increment_gpio_clock

_increment_s:
  @ otherwise clear and carry
  mov r0, #0
  strb r0, [ r2, #1 ]
  @ get 1s
  ldrb r0, [ r2, #2 ]
  add r0, #1
  @ check if >= 10
  cmp r0, #10  
  beq _increment_Ds
  @ save back to memory if <= 10
  strb r0, [ r2, #2 ]
  b _exit_increment_gpio_clock

_increment_Ds:
  @ otherwise clear and carry
  mov r0, #0
  strb r0, [ r2, #2 ]
  @ get 10s
  ldrb r0, [ r2, #3 ]
  add r0, #1
  @ check if >= 6
  cmp r0, #6  
  beq _increment_m
  @ save back to memory if <= 6
  strb r0, [ r2, #3 ]
  b _exit_increment_gpio_clock
 
_increment_m:
  @ otherwise clear and carry
  mov r0, #0
  strb r0, [ r2, #3 ]
  @ get 1m
  ldrb r0, [ r3 ]
  add r0, #1
  @ check if >= 10
  cmp r0, #10 
  beq _increment_Dm
  @ save back to memory if <= 10
  strb r0, [ r3 ]
  b _exit_increment_gpio_clock
  
_increment_Dm:  
  @ otherwise clear and carry
  mov r0, #0
  strb r0, [ r3 ]
  @ get 1m
  ldrb r0, [ r3, #1 ]
  add r0, #1
  @ check if >= 6
  cmp r0, #6  
  beq _increment_h
  @ save back to memory if <= 10
  strb r0, [ r3, #1 ]
  b _exit_increment_gpio_clock

_increment_h:
  @ otherwise time > 1 hr, clear 
  mov r0, #0
  strb r0, [ r3, #1 ]
  
_exit_increment_gpio_clock:  
  bx lr
  
@ this subroutine writes mm:ss:cc-time to
@ seven-segment display
@ uses global variables to access time stored
@ digit-by-digit in memory
write_time:
  @ preserve state
  push { r4 - r12, lr }

  @ seven-segment address
  ldr r7, =SS03_BASE
  @ get address of hex codes
  ldr r8, adr_codes

  @ blank out register to store time hex codes 
  mov r2, #0  
  
  @ get seconds part of time, byte-by-byte
  ldr r4, adr_sec  
  @ need to count to 4 for ss:cc digits
  mov r0, #0
_display_seconds_loop:  
  ldrb r1, [ r4, r0 ]
  @ multiply by 4 to get address offset
  lsl r1, #2
  @ get hex code
  ldr r6, [ r8, r1 ]
  @ multiply counter by 8 for bit offset
  lsl r1, r0, #3
  @ shift hex code over by that amount
  lsl r6, r1
  @ add to hex display
  add r2, r6
  @ increment counter
  add r0, #1
  cmp r0, #4
  bne _display_seconds_loop

  @ display seconds
  str r2, [ r7 ]
  
  @ seven-segment address
  ldr r7, =SS45_BASE
  @ blank out register to store time hex codes 
  mov r2, #0  
  
  @ get minutes part of time, byte-by-byte
  ldr r4, adr_min  
  @ need to count to 2 for mm digits
  mov r0, #0
_display_minutes_loop:  
  ldrb r1, [ r4, r0 ]
  @ multiply by 4 to get address offset
  lsl r1, #2
  @ get hex code
  ldr r6, [ r8, r1 ]
  @ multiply counter by 8 for bit offset
  lsl r1, r0, #3
  @ shift hex code over by that amount
  lsl r6, r1
  @ add to hex display
  add r2, r6
  @ increment counter
  add r0, #1
  cmp r0, #2
  bne _display_minutes_loop

  @ display minutes
  str r2, [ r7 ]
  
  @ restore state
  pop { r4 - r12, lr }
  @ return
  bx lr

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ data addresses 
adr_codes:
  .word hex_codes
adr_sec:
  .word sec_time
adr_min:
  .word min_time
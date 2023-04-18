.text

@ lets use labels for the addresses
.equ LED_BASE,       0xFF200000
.equ SWITCH_BASE,    0xFF200040
.equ GPIO_BASE,      0xFF200060

@ lets also use labels for the masks
.equ PIN_12_15_MASK, 0xFFFF0FFF
.equ SW_6_9_MASK,    0x000003C0

.global _start
_start:
  @ get the state of the switches
  ldr r0, =SWITCH_BASE
  ldr r1, [r0]

  @ get SW0 and SW1 into r2
  and r2, r1, #11

  @ check state
  @ SW0 = 0 and SW1 = 0 means
  @ clear LEDs and GPIO pins
  cmp r2, #0
  beq clear_everything

  @ SW0 = 1 and SW1 = 0 means
  @ send switch data to LEDs
  cmp r2, #1
  beq switch_to_leds

  @ SW0 = 0 and SW1 = 1 means
  @ send switch data to GPIO
  cmp r2, #2
  beq switch_to_output

  @ SW0 = 1 and SW1 = 1 means
  @ send GPIO data to LEDs
  @ if we got this far, this must
  @ me the case so no need to do 
  @ a comparison
  
  @ GPIO input mask
  ldr r2, =PIN_12_15_MASK
  @ get pin direction
  ldr r0, =GPIO_BASE
  ldr r1, [r0, #4]
  @ apply mask to force pins 12-15
  @ to input
  and r1, r2
  @ write back to port
  str r1, [r0, #4]
  @ read pin data
  ldr r1, [r0]
  @ invert mask
  mvn r2, r2
  @ apply to data to remove all other pins
  and r1, r2
  @ shift over to zeroth bit
  lsr r1, #12
  @ write to LEDs
  ldr r0, =LED_BASE
  str r1, [r0]

  @loop back
  b _start

@ clear LEDs and GPIO pins (if output)
clear_everything:
  @ clear LEDs
  ldr r0, =LED_BASE
  mov r1, #0
  str r1, [r0]

  @ clear GPIO pins
  @ if they are already input this won't
  @ do anything
  ldr r0, =GPIO_BASE
  @ GPIO input mask
  ldr r2, =PIN_12_15_MASK
  @ get current state of pins
  ldr r1, [r0]
  @ apply mask
  and r1, r2
  @ write to GPIO
  str r1, [r0]
  @ note that using the mask means this 
  @ ONLY clears output on pins 12 to 15

  @loop back
  b _start

@ send switch data to LEDs
switch_to_leds:
  @ get switch data
  ldr r0, =SWITCH_BASE
  ldr r1, [r0]
  @ switch mask
  ldr r2, =SW_6_9_MASK
  @ apply mask
  and r1, r2
  @ shift over to zeroth bit
  lsr r1, #6
  @ write to LEDs
  ldr r0, =LED_BASE
  str r1, [r0]

  @ loop back
  b _start

@ send switch data to GPIO
switch_to_output:
  @ get switch data
  ldr r0, =SWITCH_BASE
  ldr r1, [r0]
  @ switch mask
  ldr r2, =SW_6_9_MASK
  @ apply mask
  and r1, r2
  @ shift over to twelveth bit
  @ and save in r4
  lsl r4, r1, #6
  

  @ get GPIO direction
  ldr r0, =GPIO_BASE
  ldr r1, [r0, #4]
  @ GPIO output mask
  ldr r2, =PIN_12_15_MASK
  mvn r2, r2
  @ set pins to output
  orr r1, r2
  str r1, [r0, #4]

  @ write to GPIO
  str r4, [r0]

  @ loop back
  b _start
  
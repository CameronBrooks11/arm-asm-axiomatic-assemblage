@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ Q14 of the "2022 Practice Exam"
@ Funk O Meter Thing
@
@
@ I write this using DE10 Standard hardware so it will compile in simulator
@ Changing to DE13 would be a matter of changing how registers are initialized
@ 
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ Basic flow of program
@
@ 1. Initialize the Private Timer to count down for 2.5s
@ 2. Check if the Private Timer has timed out
@ 2a. If no, continue to an ADC subroutine
@ 2b. If yes, display the "average value"
@
@ ADC subroutine:
@ 1. Initialize an interval timer to count down from 4.5mS
@ 2. If it has not timed out, continue to loop
@ 3. If it has timed out, read the ADC value
@ 4. Basically, continue to read from 2 ADC channels until both have proper status bit
@ 5. If they have proper status bit, take first 8 bits from both channels
@ (this is to simulate how the question asks for a 16 bit value, but only provides 8 bit ADC hardware)
@ 6. LSL channel 1 bits by 8, and add it will channel 0
@ 7. Add this value to a running total
@ 8. Approximate the division of 556 as 512. Thus, RSL the result by 9
@ 9. Return this value in r2


.global _start
_start:

@ r0 will hold running total
ldr r0, =0

@counter for debugging
ldr r12, =0

@ ensure timeout is cleared
ldr r4, =0xfffec600
ldr r5, =1
str r5, [r4,#12]

	
main_loop:


bl start_clock1
@ start the 2.5s clock

ldr r4, =0xfffec600
@ load 2.5 clock address
ldr r5, [r4,#12]
and r5, #1
cmp r5, #1
@ compare bit one of status register

blne ADC_clock
@ if it has not timed out, got to ADC clock

@ if it has timed out, display the value
ldr r8, = 0xff200000
str r0, [r8]
@ random address to store avg value
@ it is the LEDs in this case, for no reason whatsover

@ then, reset timeout flag of 2.5s clock
ldr r8, =1
str r8, [r4,#12]

@ write 1 to timeout flag

@ debug
add r12, #1


b main_loop


start_clock1:
push {r4 - r12}

ldr r4, =0xfffec600
@ load Private Timer 1 Address

ldr r5, =0x1DCD6500
str r5, [r4]
@ send 1s time interval (200e6 Hz * 1s) to load reg

ldr r5, =1
str r5, [r4, #8]
@ start clock, counting down

pop {r4 - r12}
bx lr

ADC_clock:
push {r4-r12}

ldr r4, =0xff202020
@ load Interval Timer 1 Address


ldr r5, =0xDDD0
str r5, [r4, #8]
ldr r5, = 0x6
str r5, [r4, #12]
@ store 0x6DDD0 to interval register
@ = 4.5 ms at 100 MHz


ldr r5, =0b100
str r5, [r4, #4]
@ turn on interval timer 

ldr r5, [r4]
and r5, #1
cmp r5, #1
bne ADC_clock
@ check if 4.5mS clock timed out. If not, repeat

@ if yes, reset the timeout flag
ldr r5, =1
str r5, [r4]

pop {r4-r12}
bleq readADC
@ if it has timed out, go to readADC

readADC:
push {r4-r12}

add r1, #1
@ increase sample count

ldr r4, =0xff204000
@ load base address of ADC

ldr r5, =1
str r5, [r4,#4]
@ write to ADC channel to autoupdate

@ assume first 8 bits written to channel 0
@ next 8 bits on channel 1

ldr r5, [r4]
ldr r7, = 0xffff
and r5, r7
@ load first 16 bits from channel 0 to r5

ldr r6, [r4, #4]
and r6, r7
@ load first 16 bits from channel 0 to r5

ldr r7, =0x80
and r8, r5, r7
and r9, r6, r7
@ check the status bit of both channels
and r8, r9
@ and status bits. Will only be 1 if both status bits are one
cmp r8, #1
bne readADC
@ check if both ADCs have finished. If not, restart readADC

ldr r7, =0xff
and r5, r7
and r6, r7
@ if not, take first 8 bits from both ADC channels
lsl r6, #8
@ shift channel 1 value by 8 bits

add r5, r6
@ add channel values together

add r0, r5
@ add value to running total
@ hopefully this does not produce overflow (i.e. value exceeds 2^32 after 2.5s/4.5mS samples added)
@ since I do not know how the funk checker reads, I will assume this is fine

pop {r4-r12}
bx lr





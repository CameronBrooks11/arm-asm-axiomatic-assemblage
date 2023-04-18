@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ PRACTICE DESIGN QUESTION 1
@
@ Calculate the first 10 Fibonnaci numbers and store to 
@ memory, to the stack, and on the seven-segment display
@
@ this code narrowly completes the problem as defined, with
@ a lot of hard-coded values
@ it is not portable or very reusable, but it does solve the
@ problem 
@ see "Practice_2.s" for more portable code
@
@ Written by John Mcleod, 2021 04 19
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
.global _start

_start:
	@ arbitrary memory address for storing data
	ldr r8, =0x0000A000
	@ address of 7-segment display
	ldr r7, =0xFF200020	

	@ Fibonnaci sequence is 0, 1, 1, 2, 3, 5, 8, 13, 21, 34
	@ first number
	mov r0, #0
	@ seven-segment code for "0"
	mov r1, #0b00111111
	@ write to memory
	str r0, [r8], #4
	@ push to stack
	push {r0}
	@ put on seven-segment display
	str r1, [r7]
	@ delay
	bl delay_loop

	@ second number
	mov r0, #1
	@ seven-segment code for "1"
	mov r1, #0b00000110
	@ write to memory
	str r0, [r8], #4
	@ push to stack
	push {r0}
	@ put on seven-segment display
	str r1, [r7]
	@ delay
	bl delay_loop

	@ third number
	mov r0, #1
	@ seven-segment code for "1"
	mov r1, #0b00000110
	@ write to memory
	str r0, [r8], #4
	@ push to stack
	push {r0}
	@ put on seven-segment display
	str r1, [r7]
	@ delay
	bl delay_loop

	@ fourth number
	mov r0, #2
	@ seven-segment code for "2"
	mov r1, #0b01011011
	@ write to memory
	str r0, [r8], #4
	@ push to stack
	push {r0}
	@ put on seven-segment display
	str r1, [r7]
	@ delay
	bl delay_loop

	@ fifth number
	mov r0, #3
	@ seven-segment code for "3""
	mov r1, #0b01001111
	@ write to memory
	str r0, [r8], #4
	@ push to stack
	push {r0}
	@ put on seven-segment display
	str r1, [r7]
	@ delay
	bl delay_loop

	@ sixth number
	mov r0, #5
	@ seven-segment code for "5"
	mov r1, #0b01101101
	@ write to memory
	str r0, [r8], #4
	@ push to stack
	push {r0}
	@ put on seven-segment display
	str r1, [r7]
	@ delay
	bl delay_loop

	@ seventh number
	mov r0, #8
	@ seven-segment code for "8"
	mov r1, #0b01111111
	@ write to memory
	str r0, [r8], #4
	@ push to stack
	push {r0}
	@ put on seven-segment display
	str r1, [r7]
	@ delay
	bl delay_loop

	@ eighth number
	mov r0, #13
	@ seven-segment code for "13"
	@ this is 0b00000110 01001111
	ldr r1, =0x064F
	@ write to memory
	str r0, [r8], #4
	@ push to stack
	push {r0}
	@ put on seven-segment display
	str r1, [r7]
	@ delay
	bl delay_loop

	@ ninth number
	mov r0, #21
	@ seven-segment code for "21"
	@ this is 0b0b01011011 00000110
	ldr r1, =0x5B06
	@ write to memory
	str r0, [r8], #4
	@ push to stack
	push {r0}
	@ put on seven-segment display
	str r1, [r7]
	@ delay
	bl delay_loop

	@ tenth number
	mov r0, #34
	@ seven-segment code for "34"
	@ this is 0b01001111 01100110
	ldr r1, =0x4F66
	@ write to memory
	str r0, [r8], #4
	@ push to stack
	push {r0}
	@ put on seven-segment display
	str r1, [r7]
	@ delay
	bl delay_loop

	@ and loop back to start
	b _start

@ hard-coded delay loop
@ I could use a timer - I SHOULD use a timer,
@ but nobody told me to, so I won't
delay_loop:
	push {r0-r7, lr}
	@ just jam some large number here and loop
	@ how long will it loop for? long enough,
	@ that's how long!
	ldr r0, =0x400000
sub_loop:
	subs r0, #1
	bne sub_loop
	pop {r0-r7, lr}
	bx lr
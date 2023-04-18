@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ PRACTICE DESIGN QUESTION 2
@
@ Calculate the first N Fibonnaci numbers and store to 
@ memory
@ this is all done in subroutine "fib_N"
@
@ a main program was added to display these numbers on
@ seven-segment display
@
@ as an example, N = 25 is used and Fibonnaci numbers
@ are stored starting at 0x0000A000 in memory
@ (this wasn't specified in the problem, the problem
@ was just to implement the subroutine)
@
@ Written by John Mcleod, 2021 04 19
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
.global _start

.data
@ to set timer for 1 s
timer_interval:	.word	100000000

.text
_start:
	@ initialize the timer for 100 ms count
	ldr r6, =0xFF202000
	ldr r7, adr_timer_int
	ldr r8, [r7]
	str r8, [r6, #8]
	lsr r8, #16
	str r8, [r6, #12]

	@ define N as 25, why not
	mov r0, #25
	ldr r1, =0x0000A000
	@ calculate numbers, store in memory
	bl fib_N

	@ start timer now, countdown and repeat
	mov r7, #6
	str r7, [r6, #4]

	@ now loop through all numbers
	@ hold on display for 100 ms
	@ first move counter up to r4
	mov r4, r0
main_loop:
	@ get fibonnaci number
	ldr r0, [r1], #4
	@ display number
	bl ss_disp
timer_pause:
	@ check if timeout occurred
	ldr r2, [r6]
	cmp r2, #3
	bne timer_pause
	@ clear timeout
	str r2, [r6]
	@ decrement fibonnaci counter
	subs r4, #1
	@ loop to next number
	bne main_loop

	@ all done! return to beginning
	b _start
		
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ subroutine for calculating Fibonnaci sequence
@ up to N
@ assume N is in r0
@ assume address for memory storage is in r1
fib_N:
	@ preserve state of system
	push {r0-r7, lr}
	@ first two Fibonnaci numbers are 0 and 1
	mov r2, #0
	mov r3, #1
	@ make sure N is not 0
	cmp r0, #0
	beq fib_exit
	@ if N is 1 or greater, write first number
	strhs r2, [r1], #4
	@ decrement counter
	subs r0, #1
	@ exit if N = 1
	beq fib_exit
	@ loop to find remainder
fib_loop :
	@ find next number
	add r4, r2, r3
	@ shift everything down in registers
	mov r2, r3
	mov r3, r4
	@ write next number to memory
	str r2, [r1], #4
	@ decrement counter
	subs r0, #1
	@ exit if counter at zero
	beq fib_exit
	b fib_loop
fib_exit :
	pop {r0-r7, lr}
	bx lr

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@	
@ subroutine for displaying on seven-segment
@ goes up to 4 digits
@ anything more is silently ignored
@ assume number is in r0
ss_disp:
	@ preserve state of system
	push {r0-r7, lr}

	@ get address of bottom 4 panels
	ldr r7, =0xFF200020

	@ move number up to r4
	mov r4, r0

	@ counter in r1
	@ this is to count bottom 4 panels
	mov r1, #4	

	@ this is to hold the ss display code
	mov r6, #0
	@ this is to hold bit shift
	mov r5, #0

disp_loop_a:
	@ get bottom digit as: x%10
	@ equivalent to int(x/10)*10
	@ 
	@ but this is tricky because ARMv7 doesn't
	@ have a division command
	@ subroutine mod_10 does x%10
	mov r0, r4
	bl mod_10
	mov r2, r0
	bl dec_code
	@ add code to display code
	add r6, r0, lsl r5

	@ divide by 10 to proceed to next
	@ lowest digit
	@
	@ again this is tricky because ARMv7 doesn't
	@ have a division command
	@ subroutine div_10 does x/10
	mov r0, r4
	bl div_10
	mov r4, r0
	@ increment shift for code
	add r5, #8
	@ decrement panel counter
	subs r1, #1
	@ loop back if not done
	bne disp_loop_a

	@ display on seven segment
	str r6, [r7]

	@ restore context
	pop {r0-r7, lr}
	bx lr

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ return decimal code for seven-segment
@ assume number is in r0
@ return value in r0 as well
dec_code:
	cmp r0, #0
	moveq r0, #0b00111111
	bxeq lr
	cmp r0, #1
	moveq r0, #0b00000110
	bxeq lr
	cmp r0, #2
	moveq r0, #0b01011011
	bxeq lr
	cmp r0, #3
	moveq r0, #0b01001111
	bxeq lr
	cmp r0, #4
	moveq r0, #0b01100110
	bxeq lr
	cmp r0, #5
	moveq r0, #0b01101101
	bxeq lr
	cmp r0, #6
	moveq r0, #0b01111101
	bxeq lr
	cmp r0, #7
	moveq r0, #0b00000111
	bxeq lr
	cmp r0, #8
	moveq r0, #0b01111111
	bxeq lr
	cmp r0, #9
	moveq r0, #0b01101111
	bxeq lr
	@ not a valid number, return 0
	moveq r0, #0
	bx lr

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@	
@ perform integer division by 10
@ this involves a lot of "magic numbers", and honestly
@ I had to look it up from disassembled code from a C
@ program
div_10:
	push {r1-r7,lr}
	ldr r7, =0x66666667
	smull r2, r3, r0, r7
	asr r5, r0, #31
	rsb r5, r5, r3, asr #2
	add r1, r5, r5, lsl #2
	sub r1, r0, r1, lsl #1
	mov r0, r5
	pop {r1-r7,lr}
	bx lr

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@	
@ perform modular arithmetic by 10
@ this involves a lot of "magic numbers", and honestly
@ I had to look it up from disassembled code from a C
@ program
mod_10:
	push {r1-r7,lr}
	ldr r7, =0x66666667
	smull r2, r3, r0, r7
	asr r5, r0, #31
	rsb r5, r5, r3, asr #2
	add r1, r5, r5, lsl #2
	sub r1, r0, r1, lsl #1
	mov r0, r1
	pop {r1-r7,lr}
	bx lr

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@	
adr_timer_int:	.word timer_interval

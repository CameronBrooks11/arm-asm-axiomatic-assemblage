@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ 2021 Part 3 - Design Question
@ Owen Hahn
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@
@ Overall Flow of Program:
@ 
@ 1. ADC reads input. Throws interrupt when done reading value
@ 2. ADC places read value into global variable
@ 3. Main loop constantly converts ADC value to appropriate period of square wave
@ 4. Main loop polls an "off timer" and delays until it times out.
@ 5. Turns on a GPIO port 
@ 6. Polls "on timer" until it times out, turns off GPIO port
@ 7. Reinitializes "off timer" and sends duty cylce through UART
@ 8. Restarts
@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@




@ arbitrary location to store global variables
GLOBAL_ADC: .word = 0x00001000
UPCOUNTS:	.word = 0x00004000
OFF_COUNTS: .word = 0x00002000
ON_COUNTS: 	.word = 0x00003000

@ initialize upcount value so program can start
@ 50% duty cycle w/ 512 stored
ldr r0, =512
ldr r1, =UPCOUNTS
str r0,[r1]

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ ENABLE INTERRUPTS
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

@ Enable interrupts from ADC (IRQ #13) to CPU
@ 13th bit
ldr r0, =8192
@ msr irqen, r0

/* @ Initialize IVT
.section .vectors , " a "
	.word unused @ IRQ 0
	.word unused @ IRQ 1
	.word unused @ IRQ 2
	.word unused @ IRQ 3
	.word unused @ IRQ 4
	.word unused @ IRQ 5
	.word unused @ IRQ 6
	.word unused @ IRQ 7
	.word unused @ IRQ 8
	.word unused @ IRQ 9
	.word unused @ IRQ 10
	.word unused @ IRQ 11
	.word unused @ IRQ 12
	.word ADC_isr @ IRQ 13
	.word unused @ IRQ 14
	.word unused @ IRQ 15
*/	
@ interrupts from overall system are now enabled
@ enable interrupts from ADC

ldr r0, =0x7000
@ 8th bit is 1
ldr r1, =0x80
@ load control register of ADC
ldr r2, [r0]
@ bitmask so 8th bit flips to 1. Interrupts enabled from ADC now
orr r2, r1
str r2, [r0]

@ now interrupts are enabled
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@




@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ INITIALIZE UART
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
init_UART:
push {r4-r12}

@ load UART address
ldr r4, =0x7400
@ need to write 0b0000000100100010 to control reg
@ 0b00 (no interrupts) 00 0 (1 stop pulse) 0 01 (9600 baud) 00 10 (even parity) 00 10 (8 bit data)
ldr r5, =0b0000000100100010
@ write value to control reg
str r5, [r4,#2]

@ exit. UART is now initialized
pop {r4-r12}
b init_GPIO
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ 
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@


@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ INITIALIZE GPIO
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ initialize an arbitrary GPIO pin to serve as output of PWM
init_GPIO:
push {r4-r12}

@ load GPIO A base address
ldr r4, =0x6000
@ make pin 0 an output
@ we only need one pin, so this should suffice
ldr r5, =1
str r5, [r4,#2]


pop {r4-r12}
b main_loop

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ 
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@


@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ MAIN LOOP
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
main_loop:

@ a subroutine that turns a GPIO output to low
bl low
@ a subroutine that waits for the low period counts
bl off_timer
@ a subroutine that turns a GPIO output to high
bl high
@ a subroutine that waits for the high period counts
bl on_timer
@ restart main loop

b main_loop

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ LOW
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

low:
push {r4-r12}

@ load GPIO address
ldr r4, =0x6000
@ write 0 to pin 0
ldr r5, =0
str r5, [r4]

pop {r4-r12}
bx lr

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ HIGH
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

high:
push {r4-r12}

@ load GPIO address
ldr r4, =0x6000
@ write 1 to pin 0
ldr r5, =1
str r5, [r4]


pop {r4-r12}
bx lr

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ OFF TIMER
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

off_timer:
push {r4-r12}

@ load timer A base address
ldr r4, =0x6400

@ determine the counts for how long to be off
@ off = 1024 - on (since we are using 1024 counts, slightly inaccurate)
ldr r5, =UPCOUNTS
ldr r6, =1024
sub r5, r6

@ write interval to timer data register
@ clock starts, counts down from 1024-UPCOUNTS counts at 1MHz
str r5, [r4]

off_loop:
@ get status bit from status register
ldr r5, [r4,#2]
ldr r6, #1
and r5, r6

@ compare with 1 to see if the timer has timed out
@ keep looping if not
cmp r5, #1
bne off_loop

pop {r4-r12}
bx lr

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ ON TIMER
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

on_timer:
push {r4-r12}

@ load timer B base address
ldr r4, =0x6420

@ determine the counts for how long to be on
@ stored in upcounts
ldr r5, =UPCOUNTS


@ write interval to timer data register
@ clock starts, counts down from 1024-UPCOUNTS counts at 1MHz
str r5, [r4]

on_loop:
@ get status bit from status register
ldr r5, [r4,#2]
ldr r6, #1
and r5, r6

@ compare with 1 to see if the timer has timed out
@ keep looping if not
cmp r5, #1
bne on_loop

pop {r4-r12}
bx lr

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ 
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@



@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@



@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ ISRS
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
ADC_isr:
push {r0-r12,lr,sp}

@ load current adc value
ldr r0, =0x7000
ldr r1, [r0,#4]

@ send this value out on the UART
ldr r2, =0x7400
@ write ADC value (as an 8-bit proportional scalar) to the UART transmit reg
str r1, [r2,#6]
@ also write raw ADC value to permanent memory location (debugging var)
ldr r3, GLOBAL_ADC
str r1, [r3]

transmit_wait:
@ check the status bit of the UART
ldr r3, [r2]
ldr r4, =1
and r3, r4
@ gets first bit of status reg. Now compare to 1
cmp r3, #1
@ if not 1, keep waiting
bne transmit_wait

@ THIS SHOULD SEND THE CURRENT DUTY CYCLE AS AN APPROPRIATE VALUE TO THE UART
@ NOW, WE NEED TO CONVERT IT TO CLOCK COUNTS FOR THE UP AND DOWN CYCLE

@ CALCULATIONS:
@ 1kHz wave at 1MHz clock speed = 1000 counts per period
@ maximum time of 1000 counts, minimum of zero
@ uptime + downtime = 1000
@ since this will be an 8 bit #, maximum value is 256
@ thus, the uptime counts could be approximated by multiplying the ADC value by 4 (technically 1024, but close enough)

ldr r7,=4
mul r1, r7
@ now r1 will hold the number of counts the cycle should stay high for
@ 1024 - r1 will be low time
@ small up bias, but this is good enough for the application

@ store value in global memory location
ldr r2, =UPCOUNT
str r1, [r2]

@ restart ADC on channel zero by bitmasking 0 to the control register
ldr r1, =3
mvn r1, r1
@ 0b11...100
ldr r2, [r0]
@ now, first two bits flipped to zero
and r2, r1
@ store result at control register to restart ADC
str r2, [r0]

@ exit by popping all vars, and exiting the subroutine using given code
pop {r0-r12,sp,lr}
subs pc, lr, #2


unused:

b unused

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ 
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
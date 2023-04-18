@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ Assembly Code for Section II, 2021 Exam
@ All code was written in 32 bit instead of 16 bit
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@


.global _start
_start:
	
@ Q1: a)
@ Configure GPIO to have pins 2-5 input, 10-13 output
config_gpio:
@ push to stack, retain context
push {r4-r12}

@ load base address of GPIO A
ldr r4, =0x6000
@ load current control register state
ldr r5, [r4,#2]
@ bit mask to turn bits 2-5 to 0
ldr r6, =0b1111111111000011
and r6, r5

@ bit mask to turn bits 10-13 to 1
ldr r5, =0b11110000000000
orr r6, r5

@ write back to control register
str r6, [r4,#2]

@ pop stack and return to link register
pop {r4-r12}
bx lr


@ Q1: b)
@ Read from pins 2-5, store as 4 bit number
read_gpio:

push {r4-r12}

@ load base address of GPIO A
ldr r4, =0x6000
@ load data register of GPIO A
ldr r5, [r4]
@ bit mask to only read pins 2-5, shit to left by 2 to put in LSB
ldr r6, =0b1111111111000011
mvn r6, r6
and r6, r5, lsl #2

@ return value to r0
mov r6, r0

pop {r4-r12}
bx lr

@ Q1: c)
@ Write lowest four bits of some number to pins 10-13
write_gpio:
push {r4-r12}
@ assume the value to write is passed in r0

@ load base address of GPIO A
ldr r4, =0x6000

@ bitmask r0 to get lowest four bits, LSR by 10 bits to align to GPIO bits 10-13
ldr r5, =0b1111
and r5, r0, lsr #10
@ I BELIEVE MCLEOD MADE A MISTAKE HERE. HE LSLs

@ load current contents of GPIO A data register. ORR with r5 to update bits 10-13
ldr r6, [r4]
orr r6, r5

@ write updated data register values to data register
str r6, [r4]

pop {r4-r12}
bx lr

@ Q2:
@ Idle for 4s using the interval timer
idle_4s:
@ MINOR ERROR...4E6 > 2^16 SO I WOULD HAVE TO MAKE IT IDLE FOR 50ms AND THEN COUNT 8 OF THOSE PERIODS
push {r4-r12}

@ load base address for clock A
ldr r4, =0x6400

@ load 4s interval into r5
@ interval = 1e6 Hz * 4s = 4e6, since it is a 1MHz down counter
@ this also starts the clock
ldr r5, =40000000
str r5, [r4]

@ reset timeout flag, to ensure clock restarts
ldr r5, =1
str r5, [r4,#2]


wait_loop:
@ load status bit from clock
ldr r6, [r4,#2]
@ AND to ensure only first bit is read
and r6, #0b1

@ check if clock has timed out
cmp r6, #1
@ if not, keep waiting
bne wait_loop

@ if clock has timed out, simply exit subroutine using lr
@ do not need to reset timeout flag because we will reset it when we start clock

pop {r4-r12}

bx lr

@ Q3: using the input capture to record when pin 7 went high
capture_p7:
push {r4-r12}

@ load address of GPIO pin B
ldr r4, =0x6020
@ load current control register of GPIO B. Bit mask so that pin 7 is set to input
ldr r5, [r4,#2]
@ 2^7 -> bit 7 high
ldr r6, =128
@ now only bit 7 low
mvn r6, r6
@ bit 7 is low (input) not. All other bits not affected
and r6, r5
@ re-write to control register
str r6, [r4,#2]
@ Now GPIO pin 7 is input

@ load input capture base address
ldr r4, =0x6C20

@ clear timer by writing 0 to status register
@ this is potentially redundant, but makes program more stable
@ if for some reason, the previous time was not cleared from data register
ldr r5, =0
str r5, [r4,#4]

@ setup input capture to pin 7
@ pins 8-10 are set to 7 (0b111)
ldr r5, =0b111 
lsr r5, #8
@ write to control register using bitmasking
@ load current control register
ldr r6, [r4,#2]
@ flip bits 8-10 to 1
orr r6, r5
@ write back to control register
str r6, [r4,#2]

@ setup input capture to check for a high value
@ load control register
ldr r5,[r4,#2]
@ get a 1 to place in bit 0
ldr r6, =1
orr r6, r5
@ write back to control register
str r6, [r4,#2]
@ now input capture is looking for a high input

@ turn on input capture clock
@ load control register
ldr r5,[r4,#2]
@ get a 1 to place in bit 6
ldr r6, =1
lsr r6, #6
orr r6, r5
@ write back to control register
str r6, [r4,#2]
@ now input capture clock is on

input_wait:
@ load status register
ldr r5,[r4,#2]
@ bitmask to only read bit 0
ldr r6, =1
and r6, r5
@ compare to see if input flag is tripped
@ if not, reset loop
cmp r6, #1
bne input_wait

@ if flag is tripped
@ place time value into r0 to return to main program
ldr r0, [r4]

@ clear timer by writing 0 to status register
ldr r5, =0
str r5, [r4,#4]

pop {r4-r12}
bx lr


@ Q4:
@ a) Make a code to start sampling channel 0 w/o modifying interrupt enable bit
@ b) Make a code to idle until ADC is complete
ADC0_start:
push {r4-r12}

@ load base address of ADC
ldr r4, =0x7000

@ write 00 to control register (bitmasked) to start sampling channel 0
ldr r5, =0b11
mvn r5, r5
@ now, 0b111...100 is stored in r5
ldr r6, [r4]
@ only bits 0 and 1 flipped to 0
and r6, r5
@ re-write to control register
str r6, [r4]

@ Q4 b)
ADC0_wait:
@ load status bit
ldr r5, [r4,#2]
@ bitmask with 1 to ensure only bit 0 is read
ldr r6, =1
and r6, r5
@ compare with 1
cmp r6, #1
@ if 1, convesion not completed. Keep waiting
beq ADC0_wait

@ if not 1 (i.e. 0), conversion complete
@ return value in data register to r0

ldr r0, [r4,#4]

@ pop and exit to lr
pop {r4-r12}
bx lr

@ Q5:
@ a) Configure the UART to 7-1-1 at 4800 baud
@ b) Write code to send one frame of data to the UART from r0

UART_config:
push {r4-r12}

@ load base address of UART
ldr r4, =0x7400
@ 16 bit bitmask to setup the control register for:
@ 7 bits (01 in bits 0 to 1)
@ odd parity (11 in bits 4 to 5)
@ 4800 baud (00 in bits 8 to 9)
@ 1 stop pulse (0 in bit 11)
@ 7 bits (01 in bits 0 to 1)
@ interrupts disabled (0 in bits 14 to 15)
ldr r5, =0b0011010011111101

@ THIS IS SLIGHTLY DIFFERENT THAN MCLEOD
@ I BITMASK CUZ I AM A HARDO, SO ALL THE UNUSED BITS ARE 1 INSTEAD OF 0
@ I THINK IT IS GOOD STILL THOUGH

@ load control register of UART
ldr r6, [r4,#2]
@ bitmask desired values and write back
and r6, r5
str r6, [r4,#2]
@ pop and exit subroutine
pop {r4-r12}
bx lr

UART_send:
push {r4-r12}

@ load address of UART
ldr r4, =0x7400

@ bitmask r0 so only first 7 bits sent to UART
ldr r5, =0b1111111
and r0, r5

@ write value to UART. Will also clear status flag
str r0,[r4,#6]

@ load status bit to see if sent correctly
ldr r5,[r4]
and r5, #1
cmp r5, #1
@ if the status bit is not 1, retry to send
bne UART_send

@otherwise, pop and exit to lr
pop {r4-r12}
bx lr

@ Q6:
@ Write a snippet of code to enable interrupts from pin 11 of GPIO port A
GPIO_enableI11:
push {r4-r12}

@ enable IRQ #2 to enable interrupts from GPIO A
@ then enable interrupts for pin 11 by writing 1 to bit 11 of interrupt control register in GPIO A (0x6000 + 0x04)

@ 1. Enable CPU interrupts for IRQ 2
ldr r5, =0b100
msr irqen , r5

@ 2. Set up IVT for interrupt 2, call it GPIO_A ISR
.section .vectors , " a "
	.word unused @ IRQ 0
	.word unused @ IRQ 1
	.word GPIO_A @ IRQ 2
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
	.word unused @ IRQ 13
	.word unused @ IRQ 14
	.word unused @ IRQ 15

@ Now setup pin 11to input, and for interrupts
ldr r4, =0x6000
@ bitmask: 1 in bit 11. 2048 = 2^11
ldr r5, =2048
@ load interrupt control register
ldr r6, [r4,#4]
@ turn bit 11 to 1
orr r6, r5
@ write back to interrupt control register 
str r6, [r4,#4]

@ now load control register, and do same thing, except set bit 11 to 0 (input)
ldr r6, [r4,#2]
@ only bit 11 is 0
mvn r5, r5
@ and with control register, only bit 11 is 0
and r6, r5
@ write back to control register
str r6, [r4,#2]


pop {r4-r12}
bx lr

GPIO_A:
@ Whatever happens during the ISR
subs pc, lr, #2


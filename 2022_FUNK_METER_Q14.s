.global _start

.data
LOOK_UP_TABLE:  .hword 0b0000000000000000, 0b0000000000000011, 0b0000000000001111, 0b0000000000111111, 0b0000000011111111, 0b0000001111111111, 0b0000111111111111, 0b0011111111111111, 

.text
_start:

//INITIALIZATION
ldr r11, =0x0C000600	//address for timer to read funkiness every 4.5ms
ldr r12, =0x0C000640	//address for the timer to average the 16 bit value using lookup table


//period for first clock to count at 4.5ms
ldr r3, =0x4F1A
str r3, [r11, #4]

//starting timer 2
mov r4, #0
str r4, [r11, #12]
mov r4, #1
str r4, [r11, #8]

//--------------------------------------

//period for first clock to count at 2.5s
ldr r3, =0xABA950
str r3, [r12, #4]

//starting timer 2 
mov r4, #0
str r4, [r12, #12]
mov r4, #1
str r4, [r12, #8]




//main loop
_main_funk_loop:

//CHECK TO SEE IF TIMER 1 IS DONE COUNTING
ldr r6, [r11, #12]
cmp r6, #0
bleq _ADC_READ_CH0


//CHECK TO SEE IF TIMER 1 IS DONE COUNTING
ldr r6, [r12, #12]
cmp r6, #0
bleq _AVERAGE_ADC_VALUE


//r0 will hold the averaged values

b _main_funk_loop






@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@              sub routines


_ADC_READ_CH0:
push {r4 - r9, lr} @ pushing registers to stack

ldr r0, =0x0C000F00 @ loading base address of ADC

@ setting r4 to be one and lsl by 15 to use for bitmasking
mov r4, #1
lsl r4 , #15 @ bit mask for bit 15

adc0_loop:
ldr r2 , [ r0 ] @ read ch0
and r3 , r2 , r4 @ check bit 15
cmp r3 , r4
bne adc0_loop @ conversion not done yet

sub r2 , r4 @ remove bit 15 from data

@ r2 now holds the read data from the ADC
@ do something with this but idk yet

pop {r4 - r9, lr}   @ popping original registers back off before returning to main loop
bx lr




_AVERAGE_ADC_VALUE:
push {r4 - r9, lr} @ pushing registers to stack

//look up table to average the value 8 but to 16 bit
ldr r10, =LOOK_UP_TABLE
mov r6, r2

//scaling the 8 bit number for a 3 bit number (8 possible states)
and r6, #0b11100000
lsr r6, #5

//shifting over to access lookup table properly
lsl r6, #1

//getting a scaled value from the loopup table
ldrh r2, [r1, r6]

//average value is now in r2

pop {r4 - r9, lr}   @ popping original registers back off before returning to main loop
bx lr
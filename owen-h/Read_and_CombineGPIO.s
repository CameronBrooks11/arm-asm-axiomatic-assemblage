.global _start
_start:
.global _start
_start:
	
.global _start
_start:

ldr r5, =0

main_loop:

bl set_GPIO
bl read_GPIO

b main_loop

set_GPIO:
push {r0-r12}
Ldr r0, =0xff200060
Ldr r1, =0xff200070
@ load parallel port addresses

Ldr r2, =0xFFFFFFF0
@ set first 28 pins as output, rest as input

Str r2, [r0,#4]
Str r2, [r1,#4]
@ set both GPIOs as input on all pins
pop {r0-r12}
bx lr

read_GPIO:
Ldr r0, =0xff200060
Ldr r1, =0xff200070
@ load parallel port addressespush {r0-r12}

ldr r2, = 0xF
@ bitmask for first 4 bits, 0b0000 0000 0000 0000 0000 0000 1111 1111
ldr r3, [r0]
ldr r4, [r1]
@ load in values of GPIO ports

and r3, r2
and r4, r2
lsl r4, #4
@ bitmask for first 4 bits
@ left shift r4 by 4 bits

add r3, r4
@ registers together

ldr r4, =0xff200000
@ memory location to store results
@ in this case, LEDs

str r3, [r4]
@ store GPIO value

pop {r0-r12}
bx lr
	
	
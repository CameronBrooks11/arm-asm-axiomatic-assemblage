.global _start
_start:

ldr r5, =0

main_loop:

bl start_timer

b main_loop

start_timer:
push {r0-r12}
Ldr r0, =0xfffec600
Ldr r1, =0x000DBBA0
Str r1, [r0]
@ write to controller to set interval to 4.5s
@ 4.5ms * 200e6 Hz converted to hex

Ldr r1, =1
Str r1, [r0, #8]
@ write 001 to control register
@ start counting
b wait

wait:
Ldr r1, [r0,#12]
@ load status bit
And r1, #1
@ bitmask for bit 0 only
Cmp r1, #1
@ check if timeout flag is set
bne wait
@ if not, restart loop

Ldr r1, =1
str r1, [r0,#12]
@ reset timeout flag by writing 1 to timeout register
add r5, #1
@ return to main
bx lr
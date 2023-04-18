.section .vectors, "ax"
b _start // jump to reset vector
b dead_loop // jump to undefined instruction vector
b dead_loop // jump to software interrupt vector
b dead_loop // jump to aborted prefetch vector
b dead_loop // jump to aborted data vector
.word 0 // unused vector
b _service_irq // jump to IRQ interrupt vector
b dead_loop // jump to FIQ interrupt vector

// start of main code
.text
.global _start
_start:
// set up stack pointers; these can be anything as long as interrupt and main stacks aren't at the same place in memory
// first set up stack for interrupt (IRQ) modes
mov r1, #0b11010010 // set r1 to interrupt mode with interrupts masked
msr cpsr_c, r1 // switch to IRQ mode with interrupts masked
ldr sp, =0xFFFFFFFF - 3 // set IRQ stack to A9 onchip memory
// now set up stack for main (SVC) mode
mov r1, #0b11010011 // set r1 to supervisor mode with interrupts masked
msr cpsr_c, r1 // switch to supervisor mode with interrupts masked
ldr sp, =0x3FFFFFFF - 3 // set SVC stack to top of DDR3 memory

// now finish setting up interrupts in software by configuring ARM GIC
bl config_gic
// set up hardware, making sure interrupts are enabled in hardware
bl _config_timer
// now turn on interrupts in CPSR
mov r0, #0b01010011 // set r0 to supervisor mode with IRQ unmasked
msr cpsr_c, r0 // switch to supervisor mode with IRQ unmasked

// main program is just an idle loop
main_loop:
// display "A"
mov r5, #0x77
ldr r6, =0xff200020
str r5, [r6]
b main_loop

// configure GIC
config_gic:
// preserve state
push { lr }

// repeat the following code for each IRQ number and A9 private timer ("timer", IRQ #29)
// the IRQ number must be in register r0, the processor target must be in register r1
// here we don't care about the processor so use 1 for both
// set up GIC for A9 private timer
mov r0, #29
mov r1, #1
bl config_interrupt

// configure the GIC CPU Interface
ldr r0, =0xFFFEC100 // base address of CPU Interface
ldr r1, =0xFFFF // enable interrupts of all priorities levels
str r1, [r0, #0x04]
mov r1, #1
str r1, [r0]
ldr r0, =0xFFFED000
mov r1, #1
str r1, [R0]

// all done, restore state
pop { lr }
// return
bx lr

// configure interrupt
config_interrupt:
// preserve state
push { r4 - r8, lr }

// configure Interrupt Set-Enable Registers (ICDISERn)
// register offset = 4 * int(N / 32)
// bit in register = 1 << (N mod 32)
lsr r4, r0, #3 // divide by 2^3 = 8
bic r4, r4, #3 // bit clear least sig 3 bits to ensure divisible by 32
ldr r2, =0xFFED100
add r4, r2, r4 // load in offset to base
and r2, r0, #0x1f // n mod 32 (1f = 0001 1111) stores bit offset

0x1f = 0001 1111) stores bit offset
mov r5, #1 // enable
lsl r2, r5, r2 // r2 = bit_offset
// using the register address in r4 and the value in r2, set the correct bit in the GIC register
ldr r3, [r4] // read current register value
orr r3, r3, r2 // set the enable bit
str r3, [r4] // store the new register value

// configure interrupt processor targets register (ICDIPTRN)
// register offset = 4 * int(n / 4)
// byte in register = n mod 4
bic r4, r0, #3 // r4 = reg_offset
ldr r2, =0xFFFED800
add r4, r2, r4 // r4 = word address of ICDIPTR
and r2, r0, #0x3 // n mod 4
add r4, r2, r4 // r4 = byte address in ICDIPTR
// using register address in r4 and the value in r1, write to (only) the appropriate byte
strb r1, [r4]

// restore state
pop { r4 - r8, lr }
// return
bx lr

// configure the timer
_config_timer:
ldr r0, =0xFFFEC600 // load timer address
ldr r1, =30000000 // set for 3 s count at 100 MHz
str r1, [r0] // Base = load period
ldr r1, =20
lsl r1, #8
add r1, #0b0101 // add control bits, no rollover
str r1, [r0, #0x08] // enable, interrupts all set with prescaler
bx lr

// use this for all error-catching
dead_loop:
b dead_loop

// set in the vectors
_service_irq:
// preserve state
push { r0 - r12, lr }

// get IRQ# from ICCIAR
ldr r5, =0xFFFEC100
ldr r4, [r5, #0x0C]

// check if timer interrupt was generated
cmp r4, #29
bleq _timer_isr

// clear interrupt by writing to ICCEOIR
str r4, [r5, #0x10]

// restore state
pop { r0 - r12, lr }
subs pc, lr, #4 // return from interrupt service routine

// interrupt service routine for timer
// this is specific to the program and needs to be written for each specific use
_timer_isr:
// preserve state
push { r4 - r12, lr }

// store something else
mov r8, #0x88
ldr r9, =0xff200020
str r8, [r9]

// get timer address
ldr r0, =0xFFFEC600
ldr r1, =50000000 // 5 seconds more
str r1, [r0] // load 5 more seconds onto base

// if this code is running, we know a timeout occurred - so no need to check
// clear timeouts
mov r1, #1
str r1, [r0, #0x0C]

// restore state
pop { r4 - r12, lr }
// return
bx lr
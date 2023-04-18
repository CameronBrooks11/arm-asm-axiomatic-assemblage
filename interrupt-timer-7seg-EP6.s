@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@ PRACTICE DESIGN QUESTION 6
@@
@@ Count up to 100 on the ARM in 1 s intervals
@@ Current count displayed on seven-segment display
@@
@@ This uses an interrupt-enabled timer
@@ Interrupt code adapted from Altera
@@ example code provided in "Using the ARM Generic 
@@ Interrupt Controller" tutorial, at
@@ https:@@software.intel.com@content@www@us@en@develop@topics@fpga-academic@materials-tutorials.html
@@
@@ As a design choice (this wasn't completely specified
@@ in problem statement) after count reaches 99 it wraps
@@ around back to 0 and repeats
@@ (technically 0 to 99 is a 100-count)
@@
@@ Written by John McLeod, 2022 04 06
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ DATA

@ codes for seven-segment display
.data
hex_codes:
  .word 0x3F @ 0 on seven-segment
  .word 0x06 @ 1
  .word 0x5B @ 2
  .word 0x4F @ 3
  .word 0x66 @ 4
  .word 0x6D @ 5
  .word 0x7D @ 6
  .word 0x07 @ 7
  .word 0x7F @ 8
  .word 0x6F @ 9
  .word 0x77 @ A
  .word 0x7C @ B
  .word 0x39 @ C
  .word 0xE5 @ D
  .word 0x79 @ E
  .word 0x71 @ F
@ global variable for timer count
timer_count:
  .word 0x0

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ INTERRUPT VECTOR TABLE
@ copied from code provided by Altera
.section .vectors, "ax"
  B     _start             @@ reset vector
  B     SERVICE_UND        @@ undefined instruction vector
  B     SERVICE_SVC        @@ software interrrupt vector
  B     SERVICE_ABT_INST   @@ aborted prefetch vector
  B     SERVICE_ABT_DATA   @@ aborted data vector
  .word 0                  @@ unused vector
  B     SERVICE_IRQ        @@ IRQ interrupt vector
  B     SERVICE_FIQ        @@ FIQ interrupt vector

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ MAIN PROGRAM
@ copied and modified from code provided by Altera
.text
.global  _start
_start:
  @ Set up stack pointers for IRQ and SVC processor modes
  MOV    R1, #0b11010010         @@ interrupts masked, MODE = IRQ
  MSR    CPSR_c, R1              @@ change to IRQ mode
  LDR    SP, =0xFFFFFFFF - 3     @@ set IRQ stack to A9 onchip memory
  @*Change to SVC (supervisor) mode with interrupts disabled*@
  MOV    R1, #0b11010011         @@ interrupts masked, MODE = SVC
  MSR    CPSR, R1                @@ change to supervisor mode
  LDR    SP, =0x3FFFFFFF - 3     @@ set SVC stack to top of DDR3 memory

  BL     CONFIG_GIC              @@ configure the ARM GIC

  @@ enable IRQ interrupts in the processor
  MOV    R0, #0b01010011         @@ IRQ unmasked, MODE = SVC
  MSR    CPSR_c, R0
  
  @@@ code written by me
  @ set up timer for 1 s intervals
  @ first get timer address
  ldr r4, =0xFF202000
  @ 1 s at 100 MHz
  ldr r0, =100000000
  @ write to low period
  str r0, [ r4, #8 ]
  @ shift right by 16 bits and write to high period
  lsr r0, #16
  str r0, [ r4, #12 ]
  @ start timer for countdown and repeat, and enable interrupts
  mov r0, #7
  str r0, [ r4, #4 ]

IDLE:
  B      IDLE                    @@ main program simply idles


@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ INTERRUPT-RELATED SUBROUTINES
@ copied from code provided by Altera
@*Define the exception service routines*@
@*--- Undefined instructions --------------------------------------------------*@
SERVICE_UND:
  B SERVICE_UND
@*--- Software interrupts -----------------------------------------------------*@
SERVICE_SVC:
  B SERVICE_SVC
@*--- Aborted data reads ------------------------------------------------------*@
SERVICE_ABT_DATA:
  B SERVICE_ABT_DATA
@*--- Aborted instruction fetch -----------------------------------------------*@
SERVICE_ABT_INST:
  B SERVICE_ABT_INST
@*--- IRQ ---------------------------------------------------------------------*@
@ I changed this code from the original one to use timer interrupts (IRQ #72)
SERVICE_IRQ:
  PUSH    {R0-R7, LR}

  @*Read the ICCIAR from the CPU Interface*@
  LDR    R4, =0xFFFEC100
  LDR    R5, [R4, #0x0C]        @@ read from ICCIAR

FPGA_IRQ1_HANDLER:
  CMP    R5, #72 
UNEXPECTED:
  BNE    UNEXPECTED             @@ if not recognized, stop here

  BL      timer_isr
EXIT_IRQ:
  @*Write to the End of Interrupt Register (ICCEOIR)*@
  STR    R5, [R4, #0x10]        @@ write to ICCEOIR

  POP    {R0-R7, LR}
  SUBS    PC, LR, #4

@*--- FIQ ---------------------------------------------------------------------*@
SERVICE_FIQ:
  B  SERVICE_FIQ

@**Configure the Generic Interrupt Controller (GIC)*@
.global CONFIG_GIC
CONFIG_GIC:
  PUSH   {LR}
  @*To configure the FPGA KEYS interrupt (ID 73):
  @ *1. set the target to cpu0 in the ICDIPTRn register
  @ *2. enable the interrupt in the ICDISERn register*@
  @*CONFIG_INTERRUPT (int_ID (R0), CPU_target (R1));*@
  
  @ here I modified the original code (which used push button interrupts)
  @ to turn on interrupts for the timer (IRQ 72)
  MOV    R0, #72         @@ timer
  MOV    R1, #1          @@ this field is a bit-mask; bit 0 targets cpu0
  BL     CONFIG_INTERRUPT

  @*configure the GIC CPU Interface*@
  LDR    R0, =0xFFFEC100  @@ base address of CPU Interface
  @*Set Interrupt Priority Mask Register (ICCPMR)*@
  LDR    R1, =0xFFFF      @@ enable interrupts of all priorities levels
  STR    R1, [R0, #0x04]
  @*Set the enable bit in the CPU Interface Control Register (ICCICR).
  @ *This allows interrupts to be forwarded to the CPU(s)*@
  MOV    R1, #1
  STR    R1, [R0]

  @*Set the enable bit in the Distributor Control Register (ICDDCR).
  @ *This enables forwarding of interrupts to the CPU Interface(s)*@
  LDR    R0, =0xFFFED000
  STR    R1, [R0]
  POP    {PC}

@*
@ *Configure registers in the GIC for an individual Interrupt ID
@ *We configure only the Interrupt Set Enable Registers (ICDISERn) and
@ *Interrupt Processor Target Registers (ICDIPTRn). The default (reset)
@ *values are used for other registers in the GIC
@ *Arguments: R0 = Interrupt ID, N
@ *       R1 = CPU target
@*
CONFIG_INTERRUPT:
  PUSH   {R4-R5, LR}

  @*Configure Interrupt Set-Enable Registers (ICDISERn).
  @ *reg_offset = (integer_div(N @ 32)*4
  @ *value = 1 << (N mod 32)*@
  LSR    R4, R0, #3         @@ calculate reg_offset
  BIC    R4, R4, #3         @@ R4 = reg_offset
  LDR    R2, =0xFFFED100
  ADD    R4, R2, R4         @@ R4 = address of ICDISER

  AND    R2, R0, #0x1F      @@ N mod 32
  MOV    R5, #1             @@ enable
  LSL    R2, R5, R2         @@ R2 = value

  @*Using the register address in R4 and the value in R2 set the
  @ *correct bit in the GIC register*@
  LDR    R3, [R4]           @@ read current register value
  ORR    R3, R3, R2         @@ set the enable bit
  STR    R3, [R4]           @@ store the new register value

  @*Configure Interrupt Processor Targets Register (ICDIPTRn)
  @ *reg_offset = integer_div(N @ 4)*4
  @ *index = N mod 4*@
  BIC    R4, R0, #3         @@ R4 = reg_offset
  LDR    R2, =0xFFFED800
  ADD    R4, R2, R4         @@ R4 = word address of ICDIPTR
  AND    R2, R0, #0x3       @@ N mod 4
  ADD    R4, R2, R4         @@ R4 = byte address in ICDIPTR

  @*Using register address in R4 and the value in R2 write to
  @ *(only) the appropriate byte*@
  STRB   R1, [R4]

  POP {R4-R5, PC}
 
@ this is the timer ISR, written by m
timer_isr:
  push { r4 - r8, lr }
  @ get timer address
  ldr r4, =0xFF202000
  @ get counter
  ldr r6, adr_count
  ldr r5, [ r6 ]
  mov r0, r5
  @ display on seven segment
  bl display_hex
  @ increment count
  add r5, #1  
  @ clear timeout flag
  mov r1, #1
  str r1, [ r4 ]  
  @ roll-over counter if necessary
  cmp r5, #100
  moveq r5, #0
  @ save count back to memory
  str r5, [ r6 ]

  @ done
  pop { r4 - r8, lr }
  bx lr
 
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ NORMAL SUBROUTINES
@ these are normal subroutines written by me
@ note that they are called in IRQ mode from the timer_isr
@ but otherwise behave normally; accepting and returning parameters

@ this subroutine writes 2-digit decimal to
@ seven-segment display
@ expects value to be in r0
display_hex:
  @ preserve state
  push { r4 - r8, lr }
  
  @ seven-segment address
  ldr r4, =0xFF200020
  @ get address of hex codes
  ldr r5, adr_codes
  @ copy number
  mov r6, r0
  
  @ get 1s place value
  bl modulo_10
  @ multiply by 4 to get byte address offset
  mov r1, r0, lsl #2
  @ get hex code
  ldr r8, [ r5, r1 ]
  
  @ get 10s place value
  mov r0, r6
  bl divide_by_10
  @ copy this
  mov r6, r0
  bl modulo_10
  @ multiply by 4 to get byte address offset
  mov r1, r0, lsl #2
  @ get hex code
  ldr r7, [ r5, r1 ]
  @ add to existing code
  add r8, r7, lsl #8
  
  @ display on seven-segment
  str r8, [ r4 ]
  
  @ restore state
  pop { r4 - r8, lr }
  @ return
  bx lr
  
@ this subroutine divides by 10 as an integer
@ expects the value to be in r0
@ this avoids using any division mnemonic
@ basic idea:
@ x / 10 = x / 8 * (4/5)
@        = x / 8 * (1 - 1/5)
@        = 1 / 8 * (x - x/5)
@        = 1 / 8 * (x - x/4 * 4/5)
@        = 1 / 8 * (x - 1/4 * ( x - x/5 ))
@        = 1 / 8 * (x - 1/4 * ( x - 1/4* (x - x/5 ))
@ etc.
@ eventually error is too small to be retained as an integer
@ division by powers of 2 is easily done by logical shifts right
divide_by_10:
  @ preserve state
  push { r4, r5 }
  @ copy number over to r4
  mov r4, r0
  @ divide by 4 three times is sufficient
  mov r5, #3
_divide_by_10_loop:
  @ divide by 4
  lsr r4, #2
  @ subtract from original value
  subs r4, r0, r4
  subs r5, #1
  bne _divide_by_10_loop
  
  @ divide final result by 8
  lsr r4, #3
  @ move result to r0
  mov r0, r4
  
  @ restore state
  pop { r4, r5 }
  @ return
  bx lr
 
@ this subroutine multiplies by 10
@ avoiding using any multiplication mnemonics
@ expects the value to be in r0
@ 10 x = 8 x + 2 x
@ multiplying by 8 and 2 are just logical shifts left
@ there are other ways to implement a division using "magic numbers",
@ but I came up with this way BY MYSELF and am very proud of it
multiply_by_10:
  @ preserve state
  push { r4 }
  @ multiply by 8
  lsl r4, r0, #3
  @ add result multiplied by 2
  add r4, r0, lsl #1
  
  @ move result to r0
  mov r0, r4
  @ restore state
  pop { r4 }
  @ return
  bx lr
  
@ this subroutine divides by 10 and keeps the remainder
@ expects the value to be in r0
modulo_10:
  @ preserve state
  push { r4, lr }
  
  @ copy value
  mov r4, r0
  
  @ divide by 10 as integer
  bl divide_by_10
  @ multiply by 10
  bl multiply_by_10
  
  @ difference is the remainder
  @ x % 10 = x - 10 * int(x/10)
  sub r0, r4, r0
  
  @ restore state
  pop { r4, lr }
  @ return
  bx lr
    
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ data addresses 
adr_codes:
  .word hex_codes
adr_count:
  .word timer_count
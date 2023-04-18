_ADC_subroutine:
// Load address of the peripheral register to r0
ldr r0, =0xBLAH
// Load the value at the address in r0 to r1
ldr r1, [r0]
// Move the binary value 0b10 to r2
mov r2, #0b10
// Perform bitwise AND operation between r1 and r2, store the result in r1
and r1, r2
// Store the result in r1 back to the address in r0
str r1, [r0]

_loop:
// Load the value at the address (r0 + 2) to r1
ldr r1, [r0, #2]
// Test if the least significant bit of r1 is set
tst r1, #1
// If the least significant bit is set (not equal to zero), branch to _loop
bne _loop
// Load the value at the address (r0 + 4) to r1
ldr r1, [r0, #4]
// Return from subroutine
bx lr

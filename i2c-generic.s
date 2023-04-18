send_to_I2C:
// Load the target address "T" into r1
ldr r1, =0xT
// Store r1 at the address (r0 + 0x04)
str r1, [r0, #0x04]
// Load the value 0x400 into r1
ldr r1, =0x400
// Load the hex value for pin "Y" into r2
ldr r2, =0xY
// Perform bitwise OR operation between r1 and r2, store the result in r2
orr r2, r1
// Store r2 at the address (r0 + 0x10)
str r2, [r0, #0x10]
// Move the value for byte "X" into r1
mov r1, #X
// Load the value at the address (r0 + 0x10) into r1
ldr r1, [r0, #0x10]
// Return from subroutine
bx lr
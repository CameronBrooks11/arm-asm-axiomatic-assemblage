// This program sets up a timer and calculates the number of cycles per millisecond.

timer_subroutine: // This subroutine sets up the timer
// Move the value 0 into register r2
mov r2, #0
// Store the value of r2 into the control register
str r2, [r0,#8]
// Move the value of 100000 (number of cycles per millisecond) into register r2
mov r2, #100000
// Set the number of cycles for the timer to run by storing it into the period register
str r2, [r0,#4]
// Move the binary value of 0001 to allow us to store bit 0 as 1 and send it to the control register
mov r2, #0b0001
// Start the timer running by storing it into the control register
str r2, [r0,#8]

_wait_for_timer: // This loop waits for the timer to finish
// Load the status register to see if the timer has timed out or not
ldr r2, [r0,#12]
// Check the status by comparing it to 1
tst r2, #1
// Keep running through the loop until the timer has finished
bne _wait_for_timer
// Decrement the counter
subs r1, #1
// Check if r1 is equal to 0
cmp r1, #0

// Branch back to the timer subroutine if the counter is not equal to 0
bne timer_subroutine
// Exit the program
bx lr

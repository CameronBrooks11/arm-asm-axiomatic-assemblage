// Input:
// - X: The word to send over the JTAG UART
// Output:
// None
// Registers modified:
// - r0, r1, r2, r3

SEND_WORD_TO_JTAG_UART:
// Convert the word to two bytes
mov r1, #0xff00 // Mask for the MSB
and r2, r1, X, lsl #8 // Extract the MSB
mov r1, #0xff // Mask for the LSB
and r3, r1, X // Extract the LSB

// Send the MSB over the UART
mov r0, #8          // Loop counter for 8 bits
mov r1, r2          // Load the MSB into r1

// Loop over each bit
LOOP_MSB:
    // Shift the current bit to the LSB and mask it
    lsr r1, r1, #1
    and r1, r1, #1
    
    // Write the bit to the UART
    ldr r2, =UART_BASE  // Load the UART base address
    ldr r2, [r2]        // Load the UART control register
    tst r2, #UART_TX_BUSY   // Check if the UART TX buffer is full
    bne $-4             // Wait if the buffer is full
    str r1, [r2, #UART_TX_DATA]  // Write the bit to the UART TX buffer
    
    // Increment the bit counter and check for termination
    subs r0, r0, #1
    bne LOOP_MSB

// Send the LSB over the UART
mov r0, #8          // Loop counter for 8 bits
mov r1, r3          // Load the LSB into r1

// Loop over each bit
LOOP_LSB:
    // Shift the current bit to the LSB and mask it
    lsr r1, r1, #1
    and r1, r1, #1
    
    // Write the bit to the UART
    ldr r2, =UART_BASE  // Load the UART base address
    ldr r2, [r2]        // Load the UART control register
    tst r2, #UART_TX_BUSY   // Check if the UART TX buffer is full
    bne $-4             // Wait if the buffer is full
    str r1, [r2, #UART_TX_DATA]  // Write the bit to the UART TX buffer
    
    // Increment the bit counter and check for termination
    subs r0, r0, #1
    bne LOOP_LSB

// Return from the subroutine
bx lr

// Input:
//   None
// Output:
//   - X: The byte read from the JTAG UART, or 0 if there is nothing to read
// Registers modified:
//   - r0, r1, r2, r3

READ_BYTE_FROM_JTAG_UART:
    // Initialize the return value to 0
    mov r0, #0
    mov r1, #8          // Loop counter for 8 bits
    
    // Loop over each bit
    LOOP:
        // Read the UART control register to check if there is data available
        ldr r2, =UART_BASE  // Load the UART base address
        ldr r2, [r2]        // Load the UART control register
        tst r2, #UART_RX_DATA_READY  // Check if there is data available
        beq NO_DATA         // If there is no data available, exit the loop
        
        // Read the bit from the UART
        ldr r2, [r2, #UART_RX_DATA]  // Read the data from the UART RX buffer
        lsl r2, r2, #31     // Shift the bit to the MSB position
        orr r0, r0, r2      // Write the bit to the return value
        
        // Decrement the bit counter and check for termination
        subs r1, r1, #1
        bne LOOP
    
    // Return the byte read from the UART, or 0 if there is nothing to read
    bx lr
    NO_DATA:
        bx lr

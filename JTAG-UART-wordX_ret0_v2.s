.text
  .equ JTAG_UART_BASE,       0xFF201000
  .equ JTAG_UART_DATA_RDY,   0x8000
  
.global read_jtag_uart
read_jtag_uart:

  // Save registers
  push {r4, lr}

  // Load JTAG UART base address
  ldr r4, =JTAG_UART_BASE

  // Read from JTAG UART
  ldr r0, [r4]

  // Check if data is ready; is bit 15 set?
  tst r0, #JTAG_UART_DATA_RDY
  // If not, return 0
  moveq r0, #0
  // If data is ready, keep only the lower 8 bits
  andne r0, r0, #0xFF

  // Restore registers
  pop {r4, lr}

  // Return
  bx lr

.global _start
_start:


READ_ALL_GPIO:
push {r4 - r12, lr}

//getting the address of the gpio ports
ldr  r9, =GPIO_0
ldr r10, =GPIO_1
ldr r11, =GPIO_2
ldr r12, =GPIO_3

//the register that will be returned later
mov r3, #0

ldr r6, [r9] //get value from gpio_x
orr r3, r6
lsl r3, #8 //lsl to move it over before getting next gpio values

ldr r6, [r10] //get value from gpio_x
orr r3, r6
lsl r3, #8 //lsl to move it over before getting next gpio values

ldr r6, [r11] //get value from gpio_x
orr r3, r6
lsl r3, #8 //lsl to move it over before getting next gpio values

ldr r6, [12] //get value from gpio_x
orr r3, r6

pop {r4 - r12, lr}
bx lr
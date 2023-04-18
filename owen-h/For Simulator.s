.global _start
_start:

ldr r0, =0xa4
ldr r1, =0x05
ldr r2, =0xb9
ldr r3, =0x000010c1
ldr r4, =0x10
ldr sp, =0xffffff84

ldr r5, =0x000010bf
ldrb r6, =0x3a
strb r6, [r5]
ldrb r6, =0x23
strb r6, [r5,#1]
ldrb r6, =0xfd
strb r6, [r5,#2]
ldrb r6, =0x50
strb r6, [r5,#3]
ldrb r6, =0x34
strb r6, [r5,#4]
ldrb r6, =0x8c
strb r6, [r5,#5]


push {r1, r4}
strb r0 , [r3 , #3]
ldrb r2 , [r3 , #2 ]!
strb r4 , [r3] , #-3
cmn r0 , r1
subgt r0 , r4
add r4 , r1 , lsl #6
pop {r1}

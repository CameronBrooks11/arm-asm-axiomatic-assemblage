.global _start
_start:


ldr r1, =0xfffec600
mov r2, #5
bl TIMER_SET_INTERVAL

//deadloop
deadloop:
b deadloop


TIMER_SET_INTERVAL:
push {r4 - r10, lr}
//pushing to save the state of the registers

//r1 = address of the GPIO port
//r2 = timer interval in [ms] is a literal (assuming a literal and right units)

mov r3, =200000//000  off three 0's since the given interval time is in miliseconds to avoid using decimal numbers in assembly
mul r4, r2, r3		//multiplying and storing in r4
str r4, [r1, #4] //storing the number calculated above and storing to base address + 4 to store the coutn interval


//popping off to return out of the function
pop {r4 - r10 , lr}
bx lr
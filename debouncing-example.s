ldr r0 , adr_button @ memory address for button
/* assume we have a timer peripheral that is
initialized to a 100 us interval */
@ some threshold for the button
ldr r5 , push_threshold
@ loop until button is pressed
push_button_input:
@ initialize counter
mov r1 , #0
25
/* code to start timer */
/* timer starts counting to 100 us */
timer_loop:
@ read button
ldr r3 , [ r0 ]
@ isolate button state ( bit 6 )
and r3 , #64 @ 2 ^ 6=64
lsr r3 , #6
@ add button state to counter
add r1 , r3
/* loop until timer is done */
/* need to check timer status register
to see when 100 us is done */
bne timer_loop
@ now check if button was pushed enough
cmp r1 , r5
blo push_button_input
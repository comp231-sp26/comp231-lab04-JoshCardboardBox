/* COMP231 LAB 4, PART 2 - Joshua Hwang
 * Honor Code: I pledge that I have neither given nor received unauthorized aid. */
	.text
	.global _start

_start:	
	mov	r0, #-1	//reset (design wants this to be 0, this is -1 so the lights shows 0 first)
	b	LOOP




/* Register Key
 *	[r0 - number] [r1 - input address's value] [r2 - input address]
 *	
 *	[r3 - display address]		<r4 - temp/misc.>
 *	DIGITS [r6, r7 - 1's 10's]
 *	PAUSE/RUN [r12: 0 run, 1 pause]
 */


LOOP: 
	//grab data from that input register so we can process it
	ldr	r2, =0xFF20005C
	ldr	r1, [r2]

	// if keys 0-3 are pressed, toggle pause / run
	cmp	r1, #1
	addeq	r12, #1
	bleq	INPUT_RESET
	
	cmp	r1, #2
	addeq	r12, #1
	bleq	INPUT_RESET
	
	cmp	r1, #4
	addeq	r12, #1
	bleq	INPUT_RESET
	
	cmp	r1, #8
	addeq	r12, #1
	bleq	INPUT_RESET
	
	
	//toggle r12 (if not 1, set to 0)
	cmp	r12, #1
	movgt	r12, #0

	//toggle pause/run
	cmp	r12, #0
	bne	LOOP	//if 1+, pause. Else, go to delay

	
	add	r0, #1
	//make sure numbers are in right range, from 0-99
	cmp	r0, #0
	movlt	r0, #0	//if negative, make it 0
	cmp	r0, #99
	movgt	r0, #0	//if 99+, make it 0
		
	
	
	//display (should be AFTER add, to remove appearance of input delay)
	bl	DISPLAY

//pause program for 0.25s
DO_DELAY:
	ldr	r4, =200000000	// delay counter
SUB_LOOP:
	//if r4 is 0, then go to LOOP_END
	subs	r4, r4, #1	// subtract one, set status
	bne	SUB_LOOP	
	
	//go back to LOOP
	b	LOOP


END:	b	END




/* Reset edge capture */
INPUT_RESET:
	ldr	r4, =0xffffffff
	str	r4, [r2]	//put new nothing-burger in address (empty it)
	bx	lr
	



/* Function for displaying numbers, plus the bit_codes to put into the address (that's stored in r8). */
DISPLAY:
	push	{r0,lr}

	ldr	r3, =0xff200020 // base address of hex3-hex0
	mov	r4, #0	//for what we put in address
	
	//fetch 1's and 10's via the DIVIDE function
	bl	DIVIDE
	mov	r6, r0	//store 1's
	mov	r7, r1	//store 10's
	
	
	mov	r0, r6		//load in 1's
	bl	seg7_code 	// returns r0 converted to a bit code in r0
	orr	r4, r4, r0
	
	mov	r0, r7		//load in 10's
	bl	seg7_code 	// returns r0 converted to a bit code in r0
	orr	r4, r4, r0, lsl #8
	
	//store changes for display
	str	r4, [r3]

	//exit function
	pop	{r0,lr}
	bx	lr

	
bit_codes:	.byte	0b00111111, 0b00000110, 0b01011011, 0b01001111, 0b01100110
		.byte	0b01101101, 0b01111101, 0b00000111, 0b01111111, 0b01100111
		.skip	2 // pad with 2 bytes to maintain word alignment


seg7_code:
	ldr	r1, =bit_codes
	ldrb	r0, [r1, r0]
	bx	lr



/* The division subroutine, only for base 10 */
// Parameter(s): r0		Returns: r0, r1
DIVIDE:	
	mov	r1, #0	//reset r1
DIVIDE_CONT:
	//keep lowering r0 until it's below divisor
	cmp	r0, #10
	blt	DIVIDE_END
	sub	r0, #10
	add	r1, #1
	b	DIVIDE_CONT
DIVIDE_END:
	bx	lr




//for stack-pointer shenanigans
.data
.skip 500
stack:

.end

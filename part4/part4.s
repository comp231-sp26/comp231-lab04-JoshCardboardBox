/* COMP231 LAB 4, PART 4 - Joshua Hwang
 * Honor Code: I pledge that I have neither given nor received unauthorized aid. */
	.text
	.global _start

_start:	
	mov	r0, #0	//reset
	mov	r6, #0
	mov	r7, #0
	mov	r8, #0
	mov	r9, #0
	
	mov	r12, #1	//toggled off by default

	bl	DISPLAY
	
	
	//set up clock for incrementing
	ldr	r10, =0xFFFEC600	//get load
	ldr	r11, =2000000		//value for 0.1 (for timer)	Note: 200000000 is 1s
	str	r11, [r10]		//write value to load

		//begin count down
		ldr	r10, =0xFFFEC608	//get control
		ldr	r11, [r10]		//get value of control
		orr	r11, r11, #3		
		str	r11, [r10]		//set e-bit to 1

	
	//go to LOOP
	b	LOOP




/* Register Key
 *	[r0 - number] [r1 - input address's value] [r2 - input address]
 *	
 *	[r3 - display address]		<r4 - temp/misc.>
 *	DIGITS [r6, r7, r8, r9 - 0.01|0.10|1|10 seconds]
 *	PAUSE/RUN [r12: 0 run, 1 pause]
 *	CLOCK [r10 - temp address storer] [r11 - misc]
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
	bne	LOOP	//if 1+, pause. 
		ldrne	r10, =0xFFFEC60C	//then, put in the interrupt bit
		movne	r11, #1
		strne	r11, [r10]		//toggle it (set a 1 to it to pause it)	
	
	
	//make sure numbers are in right range, from 0-5999
	cmp	r0, #0
	movlt	r0, #0	//if negative, make it 0

	ldr	r4, =6000
	cmp	r0, r4
	movgt	r0, #0	//if 60:00 or greater, make it 0
		
	
	
	//display (should be AFTER add, to remove appearance of input delay)
	bl	DISPLAY


/* Pause program for 0.25s */
CLOCK_CHECK:
	ldr	r10, =0xFFFEC60C	//get interrupt bit
	ldr	r11, [r10] 		//get value
	
	//if interrupt bit, then reload clock
	cmp	r11, #1
	addeq	r0, #1	//increment
	moveq	r11, #1
	streq	r11, [r10]	//remove the interrupt bit
		
	b	LOOP



END:	b	END




/* Reset edge capture */
INPUT_RESET:
	ldr	r4, =0xffffffff
	str	r4, [r2]	//put new nothing-burger in address (empty it)
	bx	lr
	



/* Function for displaying numbers, plus the bit_codes to put into the address. */
DISPLAY:
	push	{r0,lr}

	//step 1: fetch all numbers via the DIVIDE function (top down, from most to least significant digit, e.g., 1000 to 100...)
	mov	r4, #1000	//set divisor to 1000
	bl	DIVIDE		
	mov	r9, r1	//store 10's
	
	mov	r4, #100	//set divisor to 100
	bl	DIVIDE		
	mov	r8, r1	//store 1's

	mov	r4, #10		//set divisor to 10
	bl	DIVIDE		
	mov	r7, r1	//store 0.10's
	mov	r6, r0	//store 0.01's
	

	//step 2: set up input for display address
	ldr	r3, =0xff200020 // base address of hex3-hex0
	mov	r4, #0	//for what we put in address
		
	
	mov	r0, r6		//load in 0.01's
	bl	seg7_code 	// returns r0 converted to a bit code in r0
	orr	r4, r4, r0
	
	mov	r0, r7		//load in 0.10's
	bl	seg7_code 	// returns r0 converted to a bit code in r0
	orr	r4, r4, r0, lsl #8
	
	mov	r0, r8		//load in 1s
	bl	seg7_code 	// returns r0 converted to a bit code in r0
	orr	r4, r4, r0, lsl #16
	
	mov	r0, r9		//load in 10's
	bl	seg7_code 	// returns r0 converted to a bit code in r0
	orr	r4, r4, r0, lsl #24
	
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
// Parameter(s): r0, r4		Returns: r0, r1
DIVIDE:	
	mov	r1, #0	//reset r1
DIVIDE_CONT:
	//keep lowering r0 until it's below divisor
	cmp	r0, r4
	blt	DIVIDE_END
	sub	r0, r4
	add	r1, #1
	b	DIVIDE_CONT
DIVIDE_END:
	bx	lr




//for stack-pointer shenanigans
.data
.skip 500
stack:

.end


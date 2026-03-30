
/* COMP231 LAB 4, PART 2 - Joshua Hwang
 * Honor Code: I pledge that I have neither given nor received unauthorized aid. */
	.text
	.global _start

_start:	
	mov	r0, #0	//reset
	b	LOOP




/* Register Key
 *	[r0 - number] [r1 - input address's value] [r2 - input address]
 *	
 *	[r3 - display address]		<r4 - temp/misc.>
 *	DIGITS [r6, r7 - 1's 10's]
 *	TOGGLE SCREEN [r12]
 */


LOOP: 
	//grab data from that input register so we can process it
	ldr	r2, =0xFF20005C
	ldr	r1, [r2]

	// if key 0 is pressed, set r0 to 0.
	cmp	r1, #1
	moveq	r0, #0
	bleq	INPUT_RESET
	// if key 1 is pressed, increment r0
	cmp	r1, #2
	addeq	r0, #5
	bleq	INPUT_RESET
	// if key 2 is pressed, decrement r0
	cmp	r1, #4
	subeq	r0, #5
	bleq	INPUT_RESET
	// if key 3 is pressed, display nothing. Not a 0. No lights should be on.
	cmp	r1, #8
	addeq	r12, #1	//idea is for it to constantly toggle between 1 and 0
	bleq	INPUT_RESET
	

	//make sure numbers are in right range, from 0-99
	cmp	r0, #0
	movlt	r0, #0	//if negative, make it 0
	cmp	r0, #99
	movge	r0, #0	//if 99+, make it 0

	//if r12 is not 1, make it 0
	cmp	r12, #1
	movgt	r12, #0

	//if r12 == 1, hide display
	cmp	r12, #1
	ldreq	r4, =0xff200020
	moveq	r3, #0
	streq	r3, [r4]
	bleq	INPUT_RESET
	bleq	CHECK_KEYDOWN
	//if r12 == 0, don't hide display
	cmp	r12, #0
	bleq	DISPLAY
	
	bl	CHECK_KEYDOWN

	add	r0, #1	//increment
	

DO_DELAY:
	ldr	r4, =200000000	// delay counter
SUB_LOOP:
	subs	r4, r4, #1	// subtract one, set status
	bne	SUB_LOOP	
	
	b	LOOP


END:	b	END




/* Reset edge capture */
INPUT_RESET:
	ldr	r4, =0xffffffff
	str	r4, [r2]	//put new nothing-burger in address (empty it)
	bx	lr
	

/* Freeze the program for as long as a key is pressed. 
 * This is so adds/subtracts don't continuously occur (need to release button per +/-) */
// uses r#: r1
CHECK_KEYDOWN:
	//keep checking that r1 for button being continuously pressed
	ldr	r1, =0xFF200050
	ldr	r1, [r1]

	//if NOT 0, loop back on itself. else hop off.
	cmp	r1, #0
	bne	CHECK_KEYDOWN
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


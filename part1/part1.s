
/* COMP231 LAB 4, PART 1 - Joshua Hwang
 * Honor Code: I pledge that I have neither given nor received unauthorized aid. */
	.text
	.global _start

_start:	
	b	LOOP



/* ðeez loops are cool. */
// uses r#: r1, r0
LOOP: 
	//grab data from that input register so we can process it
	ldr	r1, =0xFF200050
	ldr	r1, [r1]
	and	r0, #0xF	//note: it'll reset automatically when button's released, so u don't need to AND it, per say.

	
	// if key 0 is pressed, set r0 to 0.
	cmp	r1, #1
	bleq	COND_RESET
	// if key 1 is pressed, increment r0
	cmp	r1, #2
	bleq	COND_ADD
	// if key 2 is pressed, decrement r0
	cmp	r1, #4
	bleq	COND_SUBTRACT
	// if key 3 is pressed, display nothing. Not a 0. No lights should be on.
	cmp	r1, #8
	bleq	COND_NOTHING
	
	b	LOOP


END:	b	END


/* Condition-Input Functions */
// uses r#: r1, r0, r7, r8
COND_RESET:
	//first, push lr so we can go back to LOOP later
	push	{lr}
	
	mov	r0, #0
	bl	DISPLAY
	bl	CHECK_KEYDOWN
	
	//go back to loop
	pop	{lr}
	bx	lr
COND_ADD:
	//first, push lr so we can go back to LOOP later
	push	{lr}
	
	add	r0, #1
	bl	DISPLAY
	bl	CHECK_KEYDOWN
	
	//go back to loop
	pop	{lr}
	bx	lr
COND_SUBTRACT:
	//first, push lr so we can go back to LOOP later
	push	{lr}
	
	//before subtracting, check if it's going into negatives
	cmp	r0, #0
	subgt	r0, #1
	blgt	DISPLAY
	
	bl	CHECK_KEYDOWN
	
	//go back to loop
	pop	{lr}
	bx	lr
COND_NOTHING:
	//first, push lr so we can go back to LOOP later
	push	{lr}
	
	ldr	r8, =0xff200020
	mov	r7, #0
	str	r7, [r8]

	//go back to loop
	pop	{lr}
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
// uses r#: r8, r0
DISPLAY:
	ldr	r8, =0xff200020 // base address of hex3-hex0
	push	{r0,lr}
	bl	seg7_code // returns r0 converted to a bit code in r0
	str	r0, [r8]
	pop	{r0,lr}
	bx	lr

	
bit_codes:	.byte	0b00111111, 0b00000110, 0b01011011, 0b01001111, 0b01100110
		.byte	0b01101101, 0b01111101, 0b00000111, 0b01111111, 0b01100111
		.skip	2 // pad with 2 bytes to maintain word alignment


seg7_code:
	ldr	r1, =bit_codes
	ldrb	r0, [r1, r0]
	bx	lr




//for stack-pointer shenanigans
.data
.skip 500
stack:

.end

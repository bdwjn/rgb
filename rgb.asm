BITS 64

SECTION .note.GNU-stack noalloc noexec nowrite progbits

GLOBAL process_N_pixels

SECTION .data

ALIGN 16
	_00f_00f:       dq 0x0000FF0000FF0000, 0x00FF0000FF0000FF,     0x0000FF0000FF0000, 0x00FF0000FF0000FF
	_f00_0f0:       dq 0x00FF0000FF0000FF, 0xFF0000FF0000FF00,     0xFF0000FF0000FF00, 0x0000FF0000FF0000
	_0f0_f00:       dq 0xFF0000FF0000FF00, 0x0000FF0000FF0000,     0x00FF0000FF0000FF, 0xFF0000FF0000FF00

	_00ff:          dq 0x00FF00FF00FF00FF, 0x00FF00FF00FF00FF,     0x00FF00FF00FF00FF, 0x00FF00FF00FF00FF
	_ff00:          dq 0xFF00FF00FF00FF00, 0xFF00FF00FF00FF00,     0xFF00FF00FF00FF00, 0xFF00FF00FF00FF00

	mask1:          db  0, 0, 0, 3, 3, 3, 6, 6, 6, 9, 9, 9,12,12,12,15,   14, 1, 1, 1, 4, 4, 4, 7, 7, 7,10,10,10,13,13,13
	mask2:          db 15,15, 2, 2, 2, 5, 5, 5, 8, 8, 8,11,11,11,14,14,   15,15, 2, 2, 2, 5, 5, 5, 8, 8, 8,11,11,11,14,14
	mask3:          db 14, 1, 1, 1, 4, 4, 4, 7, 7, 7,10,10,10,13,13,13,    0, 0, 0, 3, 3, 3, 6, 6, 6, 9, 9, 9,12,12,12,15

	shift_right_w:  db  1,-1, 3,-1, 5,-1, 7,-1, 9,-1,11,-1,13,-1,15,-1,    1,-1, 3,-1, 5,-1, 7,-1, 9,-1,11,-1,13,-1,15,-1

	fix_mask_G:     db  1, 2, 3, 4, 5, 6, 7, 8, 9,10,11,12,13,14,15, 0,    2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15,  0, 1
	fix_mask_B:     db  2, 3, 4, 5, 6, 7, 8, 9,10,11,12,13,14,15, 0, 1,    1, 2, 3, 4, 5, 6, 7, 8,  9, 10, 11, 12, 13, 14, 15, 0

	div3:           dw 0xAAAB

SECTION .text



; void process_N_pixels(uint8_t *rgb, int nBytes)
process_N_pixels:

vpbroadcastw   ymm15, [div3]
vmovdqu        ymm12, [_00f_00f]
vmovdqu        ymm13, [_f00_0f0]
vmovdqu        ymm14, [_0f0_f00]
vmovdqu        ymm11, [_00ff]
vmovdqu        ymm10, [mask3]
vmovdqu        ymm9,  [mask2]
vmovdqu        ymm8,  [mask1]
vmovdqu        ymm7,  [fix_mask_G]
vmovdqu        ymm6,  [fix_mask_B]

add            rsi, rdi                ; rsi = end of buffer

.process_32_pixels:

	vmovdqu    ymm0, [rdi+48]
	vmovdqu    ymm2, [rdi+32]          ; ymm2 = CD = b10 r11 g11 ... b15  |  r16 g16 b16 ... r21
	vmovdqu    ymm1, [rdi+64]
	movdqu     xmm0, [rdi+16]          ; ymm0 = BE =  g5  b5  r6 ... g10  |  g21 b21 r22 ... g26
	movdqu     xmm1, [rdi]             ; ymm1 = AF =  r0  g0  b0 ...  r5  |  b26 r27 g27 ... b31

	vpand      ymm3, ymm0, ymm12       ; _00f_00f    red | red
	vpand      ymm5, ymm0, ymm13       ; _f00_0f0    green | blue
	vpand      ymm4, ymm1, ymm14       ; _0f0_f00
	vpor       ymm5, ymm5, ymm4
	vpand      ymm4, ymm1, ymm13       ; _f00_0f0
	vpor       ymm3, ymm3, ymm4
	vpand      ymm4, ymm2, ymm14       ; _0f0_f00
	vpor       ymm3, ymm3, ymm4        ; ymm3      =  r0 r11  r6 ...  r5  |  r16 r27 r22 ... r21

	vpand      ymm4, ymm2, ymm12       ; _00f_00f
	vpor       ymm5, ymm5, ymm4        ; ymm4      =  g5  g0 g11 ... g10  |  b26 b21 b16 ... b31
	vpshufb    ymm4, ymm5, ymm7        ; ymm4      =  g0 g11  g6 ...  g5  |  b16 b27 b22 ... b21

	vpand      ymm5, ymm0, ymm14       ; _0f0_f00    blue | green
	vpand      ymm0, ymm1, ymm12       ; _00f_00f
	vpor       ymm5, ymm5, ymm0
	vpand      ymm0, ymm2, ymm13       ; _f00_0f0
	vpor       ymm5, ymm5, ymm0        ; ymm5      = b10  b5  b0 ... b15  |  g21 g16 g27 ... g26
	vpshufb    ymm5, ymm5, ymm6        ; ymm5      =  b0 b11  b6 ...  b5  |  g16 g27 g22 ... g21

	; (r+g+b) / 3 needs 16 bits, so mask out the upper bytes first to process the "even" pixels
	vpand      ymm0, ymm3, ymm11       ; ymm0 = r0 r6 r12 r2 r8 r14 r4 r10 | r16 r22 r28 r18 r24 r30 r20 r26
	vpand      ymm1, ymm4, ymm11       ; ymm1 = g0 g6 g12 ...
	vpaddw     ymm0, ymm0, ymm1
	vpand      ymm1, ymm5, ymm11       ; ymm1 = b0 r6 b12 ...
	vpaddw     ymm0, ymm0, ymm1        ; ymm0 = (r + g + b)
	; and divide by 3 (= multiply by 43691 >> 17)
	vpmulhuw   ymm0, ymm0, ymm15
	vpsrlw     ymm0, ymm0, 1           ; ymm0 = (r + g + b) / 3
	
	add        rdi, 96

	; For the odd pixels, right-shift each WORD by 8 bits
	vpsrlw     ymm1, ymm3, 8           ; ymm1 = r11 r1 r7 r13 r3 r9 r15 r5 | r27 r17 r23 r29 r19 r25 r31 r21
	
	vpshufb ymm2, ymm4, [shift_right_w] ; (= vpsrlw ymm2, ymm4, 8)

	vpaddw     ymm1, ymm1, ymm2
	vpsrlw     ymm2, ymm5, 8
	vpaddw     ymm1, ymm1, ymm2        ; ymm1 = (r+g+b)
	; and divide by 3 again, this time shifting the result into the upper byte
	vpmulhuw   ymm1, ymm1, ymm15 
	vpsllw     ymm1, ymm1, 7           ; ymm1 = (r+g+b) / 3
	vpand      ymm1, ymm1, [_ff00]     ; mask out the fractional part
 
	vpor       ymm0, ymm0, ymm1        ; ymm0 = all averages
 
	vpshufb    ymm1, ymm0, ymm8        ; gather AF
	vpshufb    ymm2, ymm0, ymm9        ; gather BE
	vpshufb    ymm3, ymm0, ymm10       ; gather CD
	
	
	vmovdqu    [rdi-96], ymm1 ; AF----
	vmovdqu    [rdi-80], ymm2 ; ABE---
	vmovdqu    [rdi-32], ymm1 ; ABE-AF
	vmovdqu    [rdi-48], ymm2 ; ABEBEF
	vmovdqu    [rdi-64], ymm3 ; ABCDEF

cmp    rdi, rsi
jne    .process_32_pixels

ret

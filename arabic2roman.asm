; =============================================================================
; 
; arabic2roman.asm
; takes an arabic number from input and prints it in roman numerals
;
; Franziska Niemeyer
; 
; =============================================================================

;;; system calls
%define SYS_WRITE	1
%define SYS_EXIT	60
;;; file ids
%define STDOUT		1

;;; start of data section
section .data
;;; a newline character
newline:		db 0x0a
;;; space character
blank:			db 0x20
;;; decimals in ASCII
ascii0:			db 48
ascii9: 		db 57
;;; roman numerals
numeral1: 		db 'I'
numeral5: 		db 'V'
numeral10: 		db 'X'
numeral50: 		db 'L'
numeral100: 	db 'C'
numeral500: 	db 'D'
numeral1000: 	db 'M'
;;; error messages
NaN_input:		db 0x0a, '>> Input is not a number!', 0x0a
NaN_msglen:		equ $-NaN_input

;;; start of code section
section	.text
;; this symbol has to be defined as entry point of the program
global _start


;;;----------------------------------------------------------------------------
;;; subroutine print_digit
;;;----------------------------------------------------------------------------
;;; prints a value given in r9 in roman numerals
;;; r11 contains char for one, r12 char for five, r13 char for ten

print_digit:
	push	r8
	push 	r9
	push	r15
	mov		r8, 1			; length of chars to write always one, except error
	cmp 	r9, 9			; digit is a nine
	je 		nine
	cmp 	r9, 4			; digit is between 5 and 8
	jg 		greater4
	cmp 	r9, 4
	je 		equal2_4
	cmp 	r9, 4
	jl 		smaller_4
	; NaN
	mov 	r10, NaN_input
	mov		r8, NaN_msglen
	call 	write_stdout
	ret

nine:
	mov 	r10, r11
	call 	write_stdout
	mov 	r10, r13
	call 	write_stdout
	jmp 	exit_block

; digit between 5 and 8
greater4:
	mov 	r10, r12
	call 	write_stdout
	cmp 	r9, 5
	je 		exit_block
; digit between 6 and 8
greater4_loop:
	mov 	r10, r11
	call 	write_stdout
	dec 	r9
	cmp 	r9, 6
	jge 	greater4_loop
	jmp 	exit_block

; digit equal to 4
equal2_4:
	mov 	r10, r11
	call 	write_stdout
	mov 	r10, r12
	call 	write_stdout

smaller_4:
	mov 	r10, r11
smaller_4_loop:
	cmp 	r9, 0
	jle 	exit_block		; exit when 0 reached
	call 	write_stdout
	dec 	r9
	jmp 	smaller_4_loop

exit_block:
	pop		r15
	pop 	r9
	pop		r8
	ret


;;;----------------------------------------------------------------------------
;;; subroutine converting_tree
;;;----------------------------------------------------------------------------
;;; evaluates the input-length given in r8 and calls the corresponding
;;; subroutines, value to print given in r15
;;; r11 contains the char for one, r12 char for five, r13 char for ten

converting_tree:
	push 	r14

thousands:
	mov 	rdx, 0
	mov 	rax, r15
	mov 	r14, 1000
	div 	r14					; r15/1000, division rest in rdx
	cmp 	rax, 0
	je		hundereds

	mov 	r9, rax				; store digit to print into r9
	mov 	r10, numeral1000
thousands_loop:
	mov		r8, 1
	call 	write_stdout
	dec 	r9
	jnz 	thousands_loop

hundereds:						; number range 100..900
	mov 	rax, rdx			; rdx contains the division rest (modulo)
	mov 	rdx, 0
	mov 	r14, 100
	div 	r14					; rdx/100
	cmp 	rax, 0
	je 		tens

	mov 	r9, rax				; ratio in rax
	mov 	r11, numeral100
	mov 	r12, numeral500
	mov 	r13, numeral1000
	call 	print_digit

tens:							; number range 10..90
	mov 	rax, rdx			; rdx contains the division rest (modulo)
	mov 	rdx, 0
	mov 	r14, 10
	div 	r14					; rdx/10
	cmp 	rax, 0
	je 		one_digit

	mov 	r9, rax
	mov 	r11, numeral10
	mov 	r12, numeral50
	mov 	r13, numeral100
	call 	print_digit

one_digit:						; number range 1..9
	mov 	r9, rdx
	mov 	r11, numeral1
	mov 	r12, numeral5
	mov 	r13, numeral10
	call 	print_digit

exit_tree:
	pop 	r14
	ret


;;;----------------------------------------------------------------------------
;;; subroutine write_stdout
;;;----------------------------------------------------------------------------
;;; writes a string stored in r10 to stdout, length given in r8

write_stdout:
	;; save registers that are used in the code
	push	rax
	push	rdi
	push	rsi
	push	rdx
    push    r15
	;; prepare arguments for write syscall
	mov	    rax, SYS_WRITE	; write syscall
	mov	    rdi, STDOUT		; file descriptor = 1 (stdout)
	mov	    rsi, r10		; character to write
	mov	    rdx, r8			; length
	syscall				    ; system call
	;; restore registers (in opposite order)
    pop     r15
	pop	    rdx
	pop	    rsi
	pop	    rdi
	pop	    rax
	ret


;;;--------------------------------------------------------------------------
;;; subroutine stoi
;;;--------------------------------------------------------------------------
;;; converts a string given in rsi to int/decimal and stores it in r15

stoi:
	push 	rsi
	push 	rax
	push 	r14
	mov 	r14, 0
	mov 	r15, 0					; r15 will contain the converted number
	mov 	rax, 0

convert_stoi:
	cmp 	[rsi], byte 0
	je 		exit_stoi				; end of string found
	cmp 	byte [rsi], 48			; decimal < 0 ? -> not a number
	jl 		not_a_number
	cmp 	byte [rsi], 57			; decimal > 9 ? -> not a number
	jg 		not_a_number

	; digit between 0 and 9
	mov 	r15, rax
	mov 	rax, 0
	sub 	byte [rsi], 48			; convert char to decimal
	mov 	al, byte [rsi]			; store digit in lower part of rax
	add 	r15, rax				; add result of r15*10 to shift to next pos
	mov 	rax, r15
	mov 	r14, 10
	mul 	r14						; next digit -> mul rax, 10 -> nextD*10 in rax
	inc 	rsi						; next position in string
	jmp 	convert_stoi

not_a_number:
	mov 	r15, -1					; result -1 if input not a number
	pop 	r14
	pop 	rax
	pop 	rsi
	ret

exit_stoi:
	pop 	r14
	pop 	rax
	pop 	rsi
	ret								; resulting int is stored in r15


;;;--------------------------------------------------------------------------
;;; main entry
;;;--------------------------------------------------------------------------

_start:
	pop		rbx						; argc (>= 1 guaranteed)
	pop		rsi						; argv[j] -> programm name
	dec 	rbx
	jz 		exit

read_args:
	;; print command line arguments
	pop		rsi						; argv[j]
	call 	stoi					; convert given string to int and store it in r15
	cmp		r15, -1					; input not a number
	je		input_NaN
	call	converting_tree			; start converting

	mov 	r10, newline			; add a newline in the end
	mov		r8, 1					; length of string to write (single char)
	call	write_stdout
	
	dec		rbx						; dec arg-index
	jnz		read_args				; continue until last argument was printed
	jmp 	exit					; exit program with exit code 0

input_NaN:
	;; print error message
	mov		r10, NaN_input
	mov		r8, NaN_msglen
	call 	write_stdout

exit:
	;; exit program via syscall
	mov		rax, SYS_EXIT			; exit syscall
	mov		rdi, 0					; exit code 0 (= "ok")
	syscall 						; system call

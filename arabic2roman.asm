; =============================================================================
; 
; schraeg.asm --
; prints command line arguments at an angle
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
newline:
 	db 0x0a
;;; space character
blank:
    db 0x20
;;; begin decimals in ASCII
ascii0:
	db 48
;;; end decimals in ASCII
ascii9:
	db 57
;;; roman numerals
numeral1: 		db 'I'
numeral5: 		db 'V'
numeral10: 		db 'X'
numeral50: 		db 'L'
numeral100: 	db 'C'
numeral500: 	db 'D'
numeral1000: 	db 'M'

;;; start of code section
section	.text
	;; this symbol has to be defined as entry point of the program
	global _start


;;;----------------------------------------------------------------------------
;;; subroutine string_len
;;;----------------------------------------------------------------------------
;;; stores the length of a string in rsi into r8

string_len:
	mov r8, 0
until_0byte_found:
	inc r8
	cmp [rsi], byte 0	; end of string?
	jnz until_0byte_found
	ret


;;;----------------------------------------------------------------------------
;;; subroutine print_digit
;;;----------------------------------------------------------------------------
;;; prints a value given in r15 in roman numerals
;;; r11 contains char for one, r12 char for five, r13 char for ten

print_digit:
	push r8
	push r15
	cmp r8, 9			; digit is a nine
	je nine
	cmp r8, 4			; digit is between 5 and 8
	jg greater4
	cmp r8, 4
	je equal2_4

nine:
	mov r10, r11
	call write_char
	mov r10, r13

greater4:				; digit between 5 and 8
	mov r10, r12
	call write_char
	cmp r15, 5
	je exit_block
greater4_loop:
	mov r10, r11
	call write_char
	dec r15
	cmp r15, 6
	jge greater4_loop
	jmp exit_block

equal2_4:				; digit equal to 4
	mov r10, r11
	call write_char
	mov r10, r12
	call write_char

exit_block:
	pop r15
	pop r8
	ret


;;;----------------------------------------------------------------------------
;;; subroutine converting_tree
;;;----------------------------------------------------------------------------
;;; evaluates the input-length given in r8 and calls the corresponding
;;; subroutines, value to print given in r9
;;; r11 contains char for one, r12 char for five, r13 char for ten

converting_tree:
	cmp r8, 4
	je thousands
	cmp r8, 3
	je hundreds
	cmp r8, 2
	je tens

thousands:				; prints thousands
	mov r10, numeral1000
	call write_char
	
	mov r11, numeral100
	mov r12, numeral500
	mov r13, numeral1000
	call print_digit
						; ToDo: print number range 100..900

hundreds:
	mov r11, numeral10
	mov r12, numeral50
	mov r13, numeral100
	call print_digit

tens:
	mov r11, numeral1
	mov r12, numeral5
	mov r13, numeral10
	call print_digit


;;;----------------------------------------------------------------------------
;;; subroutine write_char
;;;----------------------------------------------------------------------------
;;; writes a single character stored in r10 to stdout

write_char:
	;; save registers that are used in the code
	push	rax
	push	rdi
	push	rsi
	push	rdx
    push    r10
	push    rcx
	;; prepare arguments for write syscall
	mov	rax, SYS_WRITE	; write syscall
	mov	rdi, STDOUT		; fd = 1 (stdout)
	mov	rsi, r10		; character to write
	mov	rdx, 1			; length
	syscall				; system call
	;; restore registers (in opposite order)
	pop rcx
    pop r10
	pop	rdx
	pop	rsi
	pop	rdi
	pop	rax
	ret


;;;--------------------------------------------------------------------------
;;; subroutine atoi
;;;--------------------------------------------------------------------------
;;; converts a string given in rsi to int/decimal

atoi:
	push rsi
	push rax
	push r14
	mov r15, 0

convert_atoi:
	cmp [rsi], byte 0
	je exit_atoi
	cmp rsi, ascii0			; decimal < 0 ? -> not a number
	jl not_a_number
	cmp rsi, ascii9			; decimal > 9 ? -> not a number
	jg not_a_number

	; digit between 0 and 9
	sub rsi, ascii0			; convert char to decimal
	mov rax, rsi
	mov r14, 10
	mul r14					; next digit
	add r15, rax			; store next digit in r15
	inc rsi					; next position in string
	jmp convert_atoi

not_a_number:
	pop rsi
	mov r15, -1				; result -1 if input not a number
	ret

exit_atoi:
	pop r14
	pop rax
	pop rsi
	ret						; resulting int is stored in r15


;;;--------------------------------------------------------------------------
;;; main entry
;;;--------------------------------------------------------------------------

_start:
	pop	rbx		; argc (>= 1 guaranteed)
	pop	rsi		; argv[j]
	dec rbx
	jz exit
read_args:
	;; print command line arguments
	pop	rsi					; argv[j]
	call	string_len		; get string length
	call 	atoi			; convert given string to int and store it in r15
	mov r10, r15
	call	write_char
	call	converting_tree	; start converting
	dec	rbx					; dec arg-index
	jnz	read_args			; continue until last argument was printed
exit:
	;; exit program via syscall exit (necessary!)
	mov	rax, SYS_EXIT		; exit syscall
	mov	rdi, 0				; exit code 0 (= "ok")
	syscall 				; kernel interrupt: system call

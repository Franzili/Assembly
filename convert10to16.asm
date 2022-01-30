; =============================================================================
; 
; convert10to16.asm
; Converts numbers from base 10 to base 16
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

;;; messages to print during excecution
deci_msg:
    db 'decimal number = '
len_deci_msg equ $ - deci_msg

hexa_msg:
    db 'hexadecimal number = '
len_hexa_msg equ $ - hexa_msg

input_invalid:
    db 'input invalid'
len_inval_msg equ $ -input_invalid


;;; start of code section
section	.text
;; this symbol has to be defined as entry point of the program
global _start


;;;----------------------------------------------------------------------------
;;; subroutine write_char
;;;----------------------------------------------------------------------------
;;; writes a character to stdout

write_string:
	;; save registers that are used in the code
	push	rax
	push	rdi
	push	rsi
	push	rdx
    push    rcx
    push    r9
    push    r8
	;; prepare arguments for write syscall
	mov		rax, SYS_WRITE	        ; write syscall
	mov		rdi, STDOUT	            ; fd = 1 (stdout)
	mov		rsi, r8                 ; string to write
	mov		rdx, r9		            ; length
	syscall			            	; system call
	;; restore registers (in opposite order)
    pop 	r8
    pop 	r9
    pop 	rcx
	pop		rdx
	pop		rsi
	pop		rdi
	pop		rax
	ret
    

;;;--------------------------------------------------------------------------
;;; subroutine stoi
;;;--------------------------------------------------------------------------
;;; converts a strint to an integer (taken from arabic2roman.asm)

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
	pop		rbx			; argc (>= 1 guaranteed)
	pop		rsi			; argv[j]
	dec 	rbx     	; decrement argc
	jz 		exit     	; no arguments given to convert? -> exit
read_args:
	;; read input
	pop		rsi			; argv[j]
	call	stoi		; convert string input to integer -> r15
	dec		rbx		    ; dec arg-index
	jnz 	read_args	; continue until last argument was printed
exit:
	;; exit program via syscall exit (necessary!)
	mov	rax, SYS_EXIT	; exit syscall
	mov	rdi, 0			; exit code 0 (= "ok")
	syscall 			; kernel interrupt: system call

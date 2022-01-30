; =============================================================================
; 
; schraeg.asm
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
newline:			db 0x0a
;;; space character
blank:				db 0x20

;;; start of code section
section	.text
;; this symbol has to be defined as entry point of the program
global _start


;;;----------------------------------------------------------------------------
;;; subroutine write_char
;;;----------------------------------------------------------------------------
;;; writes a character to stdout

write_char:
	;; save registers that are used in the code
	push	rax
	push	rdi
	push	rsi
	push	rdx
    push    r9
    push    r8
	push    rcx
	;; prepare arguments for write syscall
	mov		rax, SYS_WRITE	; write syscall
	mov		rdi, STDOUT		; file descriptor = 1 (stdout)
	mov		rsi, r8			; character to write
	mov		rdx, 1			; length
	syscall				; system call
	;; restore registers (in opposite order)
	pop 	rcx
    pop 	r8
    pop 	r9
	pop		rdx
	pop		rsi
	pop		rdi
	pop		rax
	ret


;;;--------------------------------------------------------------------------
;;; subroutine write_string
;;;--------------------------------------------------------------------------

write_string:
	push	rax
	push	rdi
	push	rdx
    mov 	rcx, 0  		; position in string
    push    rcx
    push    r9  			; inner loop variable

writing_loop:
    cmp 	[rsi], byte 0
    je 		eos_found
    mov 	r8, blank
    mov 	r9, 0   			; inner loop variable

blank_loop:
    cmp 	r9, rcx
    jge 	write_one_char
    call 	write_char
    inc 	r9
    jmp 	blank_loop

write_one_char:
    mov 	r8, rsi
    call 	write_char
    mov 	r8, newline    	; newline
    call 	write_char
    inc 	rcx     		; current position in string
	inc		rdx				; count
	inc		rsi				; next position in string
    jmp 	writing_loop

eos_found:
	;; here rdx contains the string length
    pop 	r9
    pop 	rcx
    pop		rdx
	pop		rdi
	pop		rax
	ret


;;;--------------------------------------------------------------------------
;;; main entry
;;;--------------------------------------------------------------------------

_start:
	pop		rbx					; argc (>= 1 guaranteed)
	pop		rsi					; argv[j]
	dec 	rbx
	jz 		exit

read_args:
	pop		rsi					; argv[j]
	call	write_string		; string in rsi is written to stdout
	dec		rbx					; dec arg-index
	jnz		read_args			; continue until last argument was printed

exit:
	;; exit program via syscall
	mov		rax, SYS_EXIT		; exit syscall
	mov		rdi, 0				; exit code 0 (= "ok")
	syscall 					; system call

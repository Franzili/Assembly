; =============================================================================
; 
; sgrep.asm --
; Similar functionality as Unix 'grep'
;
; Franziska Niemeyer
; 
; =============================================================================

;;; system calls
%define SYS_READ    0
%define SYS_WRITE	1
%define SYS_EXIT	60
;;; file ids
%define STDOUT		1
%define STDIN       0

;;; start of data section
section .data
;;; a newline character
newline:        db 0x0a
;;; space character
blank:          db 0x20
;;; linebuffer of size (2^31 - 1) to fit into 32-bit int
buffer:         resb 2147483647
;;; debugging prints
debug:			db '*'

;;; start of code section
section	.text
	;; this symbol has to be defined as entry point of the program
	global _start


;;;--------------------------------------------------------------------------
;;; subroutine read_line
;;;--------------------------------------------------------------------------
;;; reads a line from STDIN and stores it in the linebuffer

read_line:

read_one_char:
	;; save registers that are used in the code
	push	rax
	push	rdi
	push	rsi
	push	rdx
	;; prepare arguments for write syscall
	mov	rax, SYS_READ	; write syscall
	mov	rdi, STDIN		; file descriptor = 0 (stdin)
	mov	rsi, r10		; character to write
	mov	rdx, 1			; length
	syscall				; system call
	;; restore registers (in opposite order)
	pop	rdx
	pop	rsi
	pop	rdi
	pop	rax
	ret



;;;--------------------------------------------------------------------------
;;; main entry
;;;--------------------------------------------------------------------------

_start:
	pop	rbx					; argc (>= 1 guaranteed)
	pop	rsi					; argv[j]
	dec rbx
	jz exit

read_args:
	;; print command line arguments
	pop	rsi					; argv[j]
	call	string_len		; get string length and store it in r8
	call 	stoi			; convert given string to int and store it in r15
	call	converting_tree	; start converting
	dec	rbx					; dec arg-index
	jnz	read_args			; continue until last argument was printed

	mov r10, newline		; add a newline in the end
	call	write_char

exit:
	;; exit program via syscall
	mov	rax, SYS_EXIT		; exit syscall
	mov	rdi, 0				; exit code 0 (= "ok")
	syscall 				; kernel interrupt: system call
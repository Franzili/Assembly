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
;;; debugging prints
debug:			db '*'

section .bss
;;; linebuffer of size 128 byte to store 128 ASCII characters
buffer:         resb 128

;;; start of code section
section	.text
	;; this symbol has to be defined as entry point of the program
	global _start


;;;--------------------------------------------------------------------------
;;; subroutine read_line
;;;--------------------------------------------------------------------------
;;; reads a line from STDIN and stores it in the linebuffer
;;; store pointer to begin of linebuffer in r8

read_line:
    mov r8, buffer      ; pointer to begin of line buffer

read_one_char:
	;; save registers that are used in the code
	push	rax
	push	rdi
	push	rsi
	push	rdx
	;; prepare arguments for write syscall
	mov	rax, SYS_READ	; write syscall
	mov	rdi, STDIN		; file descriptor = 0 (stdin)
	mov	rsi, buffer		; set pointer to next position in linebuffer
	mov	rdx, 1			; length -> one character
	syscall				; system call
	;; restore registers (in opposite order)
	pop	rdx
	pop	rsi
	pop	rdi
	pop	rax
	ret


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
	;; prepare arguments for write syscall
	mov	rax, SYS_WRITE	; write syscall
	mov	rdi, STDOUT		; file descriptor = 1 (stdout)
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
    call read_line
	dec	rbx					; dec arg-index
	jnz	read_args			; continue until last argument was printed

	mov r10, newline		; add a newline in the end
	call	write_char

exit:
	;; exit program via syscall
	mov	rax, SYS_EXIT		; exit syscall
	mov	rdi, 0				; exit code 0 (= "ok")
	syscall 				; kernel interrupt: system call
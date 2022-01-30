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

;;; start of data section
section .data
;;; a newline character
newline:        db 0x0a
;;; space character
blank:          db 0x20
;;; roman numerals
numeral1: 		db 'I'
numeral5: 		db 'V'
numeral10: 		db 'X'
numeral50: 		db 'L'
numeral100: 	db 'C'
numeral500: 	db 'D'
numeral1000: 	db 'M'
;;; debugging prints
debug:			db '*'

;;; start of code section
section	.text
	;; this symbol has to be defined as entry point of the program
	global _start





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
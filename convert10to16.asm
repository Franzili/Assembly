; =============================================================================
; 
; convert10to16.asm --
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
	mov	rax, SYS_WRITE	; write syscall
	mov	rdi, STDOUT	; fd = 1 (stdout)
    mov r8, deci_msg
	mov	rsi, r8	; character to write
	mov	rdx, len_deci_msg		; length
	syscall			; system call
	;; restore registers (in opposite order)
	pop rcx
    pop r8
    pop r9
	pop	rdx
	pop	rsi
	pop	rdi
	pop	rax
	ret


;;;--------------------------------------------------------------------------
;;; subroutine write_string
;;;--------------------------------------------------------------------------

write_string:
    call write_char


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
	pop	rsi		; argv[j]
	call	write_string	; string in rsi is written to stdout
	dec	rbx		; dec arg-index
	jnz	read_args	; continue until last argument was printed
exit:
	;; exit program via syscall exit (necessary!)
	mov	rax, SYS_EXIT	; exit syscall
	mov	rdi, 0		; exit code 0 (= "ok")
	syscall 		; kernel interrupt: system call

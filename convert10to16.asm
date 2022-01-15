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
	mov	rax, SYS_WRITE	        ; write syscall
	mov	rdi, STDOUT	            ; fd = 1 (stdout)
	mov	rsi, r8                 ; string to write
	mov	rdx, r9		            ; length
	syscall			            ; system call
	;; restore registers (in opposite order)
    pop r8
    pop r9
    pop rcx
	pop	rdx
	pop	rsi
	pop	rdi
	pop	rax
	ret
    

;;;--------------------------------------------------------------------------
;;; subroutine stoi
;;;--------------------------------------------------------------------------
;;; converts a strint to an integer

stoi:
    push r8
    push r9
    push r10
    push rsi
    mov r10, 0       ; accumulator
next_char:
    inc rsi
    cmp [rsi], byte 0
    je eos_found
    cmp rsi, $ '0'
    jb invalid_input
    cmp rsi, $ '9'
    ja input_invalid

invalid_input:
    mov r8, input_invalid
    mov r9, len_inval_msg
    call write_string

eos_found:
    pop rsi
    pop r10
    pop r9
    pop r8



;;;--------------------------------------------------------------------------
;;; main entry
;;;--------------------------------------------------------------------------

_start:
	pop	rbx		; argc (>= 1 guaranteed)
	pop	rsi		; argv[j]
	dec rbx     ; decrement argc
	jz exit     ; no arguments given to convert? -> exit
read_args:
	;; read input
	pop	rsi		            ; argv[j]
    call check_input        ; check input
	call	write_string	; string in rsi is written to stdout
	dec	rbx		            ; dec arg-index
	jnz	read_args	        ; continue until last argument was printed
exit:
	;; exit program via syscall exit (necessary!)
	mov	rax, SYS_EXIT	; exit syscall
	mov	rdi, 0		; exit code 0 (= "ok")
	syscall 		; kernel interrupt: system call

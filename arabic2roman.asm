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
;;; roman numerals
num1: db 'I'
num5: db 'V'
mum10: db 'X'
num50: db 'L'
num100: db 'C'
num500: db 'D'
num1000: db 'M'
num5000: db 'v'

;;; start of code section
section	.text
	;; this symbol has to be defined as entry point of the program
	global _start


;;;----------------------------------------------------------------------------
;;; subroutine get_len
;;;----------------------------------------------------------------------------
;;; stores the length of a string in rsi into r8

string_len:
	mov r8, 0
until_0byte:
	inc r8
	cmp [rsi], byte 0 ; end of string?
	jnz until_0byte
	ret


;;;----------------------------------------------------------------------------
;;; subroutine print_thousands
;;;----------------------------------------------------------------------------
;;; prints thousands

print_thousands:


;;;----------------------------------------------------------------------------
;;; subroutine print_one
;;;----------------------------------------------------------------------------
;;; prints a one to stdout

print_one:
	mov r9, one
	call write_char
	ret


;;;----------------------------------------------------------------------------
;;; subroutine converting_tree
;;;----------------------------------------------------------------------------
;;; evaluates the input-length in r8 and calls the corresponding subroutines

converting_tree:
	cmp r8, 9
	je 
	cmp r8, 1
	je print_one
	cmp r8



;;;--------------------------------------------------------------------------
;;; subroutine write_string
;;;--------------------------------------------------------------------------

write_string:
	push	rax
	push	rdi
	push	rdx
    mov rcx, 0  ; position in string
    push    rcx
    push    r9  ; inner loop variable
writing_loop:
    cmp [rsi], byte 0
    je eos_found
    mov r8, blank
    mov r9, 0   ; inner loop variable
blank_loop:
    cmp r9, rcx
    jge write_one_char
    call write_char
    inc r9
    jmp blank_loop
write_one_char:
    mov r8, rsi
    call write_char
    mov r8, newline    ; newline
    call write_char
    inc rcx     ; current position in string
	inc	rdx		; count
	inc	rsi		; next position in string
    jmp writing_loop
eos_found:
	;; here rdx contains the string length
    pop r9
    pop rcx
    pop	rdx
	pop	rdi
	pop	rax
	ret


;;;----------------------------------------------------------------------------
;;; subroutine write_char
;;;----------------------------------------------------------------------------
;;; writes a character stored in r9 to stdout

write_char:
	;; save registers that are used in the code
	push	rax
	push	rdi
	push	rsi
	push	rdx
    push    r9
	push    rcx
	;; prepare arguments for write syscall
	mov	rax, SYS_WRITE	; write syscall
	mov	rdi, STDOUT		; fd = 1 (stdout)
	mov	rsi, r9			; character to write
	mov	rdx, 1			; length
	syscall				; system call
	;; restore registers (in opposite order)
	pop rcx
    pop r9
	pop	rdx
	pop	rsi
	pop	rdi
	pop	rax
	ret


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
	
	call	write_string	; string in rsi is written to stdout
	dec	rbx					; dec arg-index
	jnz	read_args			; continue until last argument was printed
exit:
	;; exit program via syscall exit (necessary!)
	mov	rax, SYS_EXIT		; exit syscall
	mov	rdi, 0				; exit code 0 (= "ok")
	syscall 				; kernel interrupt: system call

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
blankspace:
    db 0x20

;;; start of code section
section	.text
	;; this symbol has to be defined as entry point of the program
	global _start

;;;----------------------------------------------------------------------------
;;; subroutine write_newline
;;;----------------------------------------------------------------------------
;;; writes a newline character to stdout
	
write_newline:
	;; save registers that are used in the code
	push	rax
	push	rdi
	push	rsi
	push	rdx
	;; prepare arguments for write syscall
	mov	rax, SYS_WRITE	; write syscall
	mov	rdi, STDOUT	; fd = 1 (stdout)
	mov	rsi, newline	; string
	mov	rdx, 1		; length
	syscall			; system call
	;; restore registers (in opposite order)
	pop	rdx
	pop	rsi
	pop	rdi
	pop	rax
	ret

;;;----------------------------------------------------------------------------
;;; subroutine write_blankspace
;;;----------------------------------------------------------------------------
;;; writes a newline character to stdout
	
write_blankspace:
	;; save registers that are used in the code
	push	rax
	push	rdi
	push	rsi
	push	rdx
	;; prepare arguments for write syscall
	mov	rax, SYS_WRITE	; write syscall
	mov	rdi, STDOUT	; fd = 1 (stdout)
	mov	rsi, blankspace	; string
	mov	rdx, 1		; length
	syscall			; system call
	;; restore registers (in opposite order)
	pop	rdx
	pop	rsi
	pop	rdi
	pop	rax
	ret
	
;;;--------------------------------------------------------------------------
;;; subroutine write_string
;;;--------------------------------------------------------------------------
;;; address of 0-terminated string passed in rsi
;;; operation: determines length of string and writes it in ONE write
;;; (plus a second write that appends a new-line character)

write_string:
	;; save registers that are used in the code
	push	rax
	push	rdi
	push	rdx
    push    rcx
	;; prepare arguments for write syscall
	mov	rax, SYS_WRITE	; write syscall
	mov	rdi, STDOUT	; fd = 1 (stdout)
	mov	rdx, 0		; count bytes
    mov rcx, 0      ; keep current position in string (number of spaces)
	push	rsi		; keep starting address of string
search_eos:
	;; here we have to specify the string size (byte) 
	cmp	[rsi], byte 0	; end of string (0) reached?
	je	eos_found	; yes, end of loop
    push rcx
print_blanks:
    cmp rcx, 0      ; if its the first char of the string
    je search_eos2  ; continue
    call write_blankspace   ; else: write space char
    dec rcx ; remaining number of spaces to print
    jnz print_blanks    ; loop
search_eos2:
    pop rcx
    inc rcx     ; current position in string
	inc	rdx		; count
	inc	rsi		; next position in string
	jmp	search_eos	; loop
eos_found:
	pop	rsi		; restore starting address of string
	;; here rdx contains the string length
	syscall			; system call
	;; restore registers (in opposite order)
	;;  6. Oct 14 (rm): corrected bug: was pop rsi:
    pop rcx
	pop	rdx
	pop	rdi
	pop	rax
	ret
    
    


	
;;;--------------------------------------------------------------------------
;;; main entry
;;;--------------------------------------------------------------------------

_start:
	pop	rbx		; argc (>= 1 guaranteed)
read_args:
	;; print command line arguments
	pop	rsi		; argv[j]
	call	write_string	; string in rsi is written to stdout
	call	write_newline	; a newline character is written to stdout
	dec	rbx		; dec arg-index
	jnz	read_args	; continue until last argument was printed

	;; exit program via syscall exit (necessary!)
	mov	rax, SYS_EXIT	; exit syscall
	mov	rdi, 0		; exit code 0 (= "ok")
	syscall 		; kernel interrupt: system call

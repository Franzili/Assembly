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
%define EOF         -1

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
;;; subroutine read_input
;;;--------------------------------------------------------------------------
;;; reads STDIN until EOF reached and stores it in the linebuffer
;;; store pointer to begin of linebuffer in r8

read_input:
    push r9

read_one_line:
    call    read_line           ; pointer to begin of linebuffer in r8
    cmp     r9, -1              ; 
    je      exit_input
    call    write_buf_content
    

exit_input:
    pop r9
    ret


;;;--------------------------------------------------------------------------
;;; subroutine read_line
;;;--------------------------------------------------------------------------
;;; reads a line from STDIN and stores it in the linebuffer
;;; store pointer to begin of linebuffer in r8

read_line:
    ;; save registers that are used in the code
	push	rax
	push	rdi
	push	rsi
	push	rdx
    xor     r9, r9          ; r9 will contain -1 if EOF reached
    mov     r8, buffer      ; reminder pointer to begin of line buffer
    mov     rsi, buffer     ; initialize rsi as pointer to linebuffer
    ;; prepare arguments for write syscall
	mov	    rdi, STDIN		; file descriptor = 0 (stdin)
	mov	    rdx, 1			; length -> one character

read_one_char:
    mov	    rax, SYS_READ	; write syscall
	syscall				    ; system call
    inc     rsi             ; next position in linebuffer
    mov     r9, newline
    cmp     rax, 0          ; end of file reached?
    je      eof_reached     ; yes? -> set r9 to -1
    cmp     [rsi], r9       ; end of line reached?
    jne     read_one_char   ; no? -> loop until newline found

eof_reached:
    mov     r9, -1
    pop	    rdx
	pop	    rsi
	pop	    rdi
	pop	    rax
    ret

exit_read:
    ;; restore registers (in opposite order)
    pop	    rdx
	pop	    rsi
	pop	    rdi
	pop	    rax
    ret


;;;----------------------------------------------------------------------------
;;; subroutine write_buf_content
;;;----------------------------------------------------------------------------
;;; writes the linebuffer content (pointer to start in r8) to STOUT

write_buf_content:
    ;; save registers that are used in the code
    push	rax
	push	rdi
	push	rsi
	push	rdx
    push    r8
    mov     rsi, r8         ; set rsi to begin of linebuffer
    ;; prepare arguments for write syscall
	mov	    rdi, STDOUT		; file descriptor = 1 (stdout)
	mov	    rdx, 1			; length

writing_loop:
    cmp     [rsi], byte 0   ; end of line reached?
    je      exit_write      ; exit
    mov	    rax, SYS_WRITE	; write syscall
	syscall				    ; system call
    inc     rsi             ; next position in linebuffer
    jmp     writing_loop

exit_write:
	;; restore registers (in opposite order)
    pop     r8
	pop	    rdx
	pop	    rsi
	pop	    rdi
	pop	    rax
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
	mov	    rax, SYS_WRITE	; write syscall
	mov	    rdi, STDOUT		; file descriptor = 1 (stdout)
	mov	    rsi, r10		; character to write
	mov	    rdx, 1			; length
	syscall				    ; system call
	;; restore registers (in opposite order)
	pop	    rdx
	pop	    rsi
	pop	    rdi
	pop	    rax
	ret


;;;--------------------------------------------------------------------------
;;; main entry
;;;--------------------------------------------------------------------------

_start:
	pop	    rbx                 ; argc (>= 1 guaranteed)
	pop	    rsi                 ; argv[j]
	dec     rbx
	jz      exit

read_args:
	;; print command line arguments
	pop	    rsi					; argv[j]
    call    read_input
	dec	    rbx					; dec arg-index
	jnz	    read_args			; continue until last argument was printed

	mov     r10, newline		; add a newline in the end
	call	write_char

exit:
	;; exit program via syscall
	mov	    rax, SYS_EXIT		; exit syscall
	mov	    rdi, 0				; exit code 0 (= "ok")
	syscall 				    ; kernel interrupt: system call
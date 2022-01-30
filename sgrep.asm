; =============================================================================
; 
; sgrep.asm
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
newline:            db 0x0a
;;; debugging prints
debug:			    db '*'
debug2:             db '-'

section .bss
;;; linebuffer of size 128 byte to store 128 ASCII characters
buffer:             resb 128
;;; pointer buffer with pointers to begin of lines
pointers_to_lines:  resb 128

;;; start of code section
section	.text
;; this symbol has to be defined as entry point of the program
global _start


;;;--------------------------------------------------------------------------
;;; subroutine read_input
;;;--------------------------------------------------------------------------
;;; reads input from STDIN and stores it in the linebuffer
;;; store pointer to begin of linebuffer in r8

read_input:
    ;; save registers that are used in the code
	push	rax
	push	rdi
	push	rsi
	push	rdx
    mov     r8, buffer      ; reminder pointer to begin of string buffer
    mov     rsi, buffer     ; initialize rsi as pointer to linebuffer
    ;; prepare arguments for write syscall
	mov	    rdi, STDIN		; file descriptor = 0 (stdin)
	mov	    rdx, 1			; length -> one character

read_one_char:
    mov	    rax, SYS_READ	; write syscall
	syscall				    ; system call
    inc     rsi             ; next position in linebuffer
    cmp     rax, 0          ; end of file reached?
    jne     read_one_char   ; no? -> loop

eof_reached:
    pop	    rdx
	pop	    rsi
	pop	    rdi
	pop	    rax
    ret


;;;----------------------------------------------------------------------------
;;; subroutine write_buf_content
;;;----------------------------------------------------------------------------
;;; writes the linebuffer content, from r9 to next newline char, to STOUT

write_buf_content:
    ;; save registers that are used in the code
    push	rax
	push	rdi
	push	rsi
	push	rdx
    push    r8
    push    r9
    inc     r9              ; next char after newline
    mov     rsi, r9         ; set rsi to begin of line
    xor     r8, r8
    ;; prepare arguments for write syscall
	mov	    rdi, STDOUT		; file descriptor = 1 (stdout)
	mov	    rdx, 1			; length

writing_loop:
    mov     r8b, byte [rsi]
    cmp     r8b, byte 0     ; end reached?
    je      exit_write      ; exit
    cmp     r8b, byte 0x0a  ; next newline reached?
    je      exit_write      ; exit
    mov	    rax, SYS_WRITE	; write syscall
	syscall				    ; system call
    inc     rsi             ; next position in linebuffer
    jmp     writing_loop

exit_write:
	;; restore registers (in opposite order)
    pop     r9
    pop     r8
	pop	    rdx
	pop	    rsi
	pop	    rdi
	pop	    rax
	ret


;;;----------------------------------------------------------------------------
;;; subroutine sgrep
;;;----------------------------------------------------------------------------
;;; searches for the given comandline argument (stored in [rsi]) in a given line
;;; r8 contains pointer to begin of string buffer
;;; r9 contains pointer to last newline character

sgrep:
    push    rsi
    push    r9
    push    r10
    push    r11
    push    r12
    push    r13
    ; prepare registers
    mov     r9, r11             ; will contain pointer to last newline in buffer
    mov     r10, rsi            ; pointer to begin of word to search for
    mov     r11, r8             ; r11 contains current position in string buffer
    xor     r12, r12            ; contains the number of matched chars
    xor     r13, r13

search_word:
    mov     r13b, [r10]         ; next char in word to search for
    mov     r14b, [r11]         ; next char in string buffer
    cmp     r13b, byte 0        ; complete word found?
    je      word_found
    cmp     r14b, byte 0        ; word not found
    je      not_found
    cmp     r14b, r13b          ; chars match?
    je      chars_match
    cmp     r14b, byte 0x0a     ; newline found
    je      newline_found
    ; no match
    mov     r10, rsi            ; reset pointer to begin of word to search for
    sub     r11, r12            ; jump back in string buffer
    xor     r12, r12            ; reset number of matched chars
    jmp     search_word

chars_match:
    inc     r10                 ; next position in word to search for
    inc     r11                 ; next position in string buffer
    inc     r12                 ; increment number of matched chars
    jmp     search_word

newline_found:
    mov     r9, rsi
    inc     r11
    jmp     search_word

word_found:
    mov     r10, debug
    call    write_char
    call    write_buf_content   ; write line containing the word
    jmp     exit_sgrep

not_found:
    mov     r10, debug2
    call    write_char
    jmp     exit_sgrep

exit_sgrep:
    pop     r13
    pop     r12
    pop     r11
    pop     r10
    pop     r9
    pop     rsi
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
	pop	    rsi                 ; programm name
	dec     rbx
	jz      exit

read_args:
    pop	    rsi					; argv[j]
    call    read_input          ; read input into buffer
    call    sgrep
	dec	    rbx					; dec arg-index
	jnz	    read_args			; continue until last argument was printed

	mov     r10, newline		; add a newline in the end
	call	write_char

exit:
	;; exit program via syscall
	mov	    rax, SYS_EXIT		; exit syscall
	mov	    rdi, 0				; exit code 0 (= "ok")
	syscall 				    ; kernel interrupt: system call
    
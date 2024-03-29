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
;;; messages
welcome:            db 0x0a, ">> Input a text to search in:", 0x0a
welcome_len:        equ $-welcome
word_not_found:     db 0x0a, ">> String not found", 0x0a
word_not_found_len: equ $-word_not_found
found:              db 0x0a, ">> String was found in the following line:", 0x0a
found_len:          equ $-found

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
    mov	    rax, SYS_READ	; read syscall
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
    mov     rsi, r9         ; set rsi to begin of line
    xor     r8, r8          ; set to 0

writing_loop:
    mov     r8b, byte [rsi]
    cmp     r8b, byte 0     ; end reached?
    je      exit_write      ; exit
    cmp     r8b, byte 0x0a  ; next newline reached?
    je      exit_write      ; exit
    ;; prepare arguments for write syscall
    mov	    rax, SYS_WRITE	; write syscall
	mov	    rdi, STDOUT		; file descriptor = 1 (stdout)
	mov	    rdx, 1			; length
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
;;; r9 contains pointer to the char after the last newline character or to the
;;; begin of the string buffer, if word was found in first line

sgrep:
    push    rsi                 ; contains pointer to begin of word to search for
    push    r10                 ; will contain char to compare from searched word
    push    r11                 ; will contain current position in string buffer
    push    r12                 ; will contain the number of matched chars
    push    r13                 ; will contain next char in word to search for
    ; prepare registers
    mov     r10, rsi            ; pointer to begin of word to search for
    mov     r11, r8             ; r8 contains current position in string buffer
    mov     r9, r8              ; if word is in first line, pointer to begin
    xor     r12, r12            ; set to 0
    xor     r13, r13            ; set to 0

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
    inc     r11                 ; one position further
    xor     r12, r12            ; reset number of matched chars to 0
    jmp     search_word

chars_match:
    inc     r10                 ; next position in word to search for
    inc     r11                 ; next position in string buffer
    inc     r12                 ; increment number of matched chars
    jmp     search_word

newline_found:
    inc     r11
    mov     r9, r11
    jmp     search_word

word_found:
    mov     r10, found
    mov     r15, found_len      ; length of string to write
    call    write_stdout
    call    write_buf_content   ; write line containing the word
    jmp     exit_sgrep

not_found:
    mov     r10, word_not_found
    mov     r15, word_not_found_len
    call    write_stdout
    jmp     exit_sgrep

exit_sgrep:
    pop     r13
    pop     r12
    pop     r11
    pop     r10
    pop     rsi
    ret


;;;----------------------------------------------------------------------------
;;; subroutine write_stdout
;;;----------------------------------------------------------------------------
;;; writes a string stored in r10 to stdout, length given in r15

write_stdout:
	;; save registers that are used in the code
	push	rax
	push	rdi
	push	rsi
	push	rdx
    push    r15
	;; prepare arguments for write syscall
	mov	    rax, SYS_WRITE	; write syscall
	mov	    rdi, STDOUT		; file descriptor = 1 (stdout)
	mov	    rsi, r10		; character to write
	mov	    rdx, r15		; length
	syscall				    ; system call
	;; restore registers (in opposite order)
    pop     r15
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
    mov     r10, welcome
    mov     r15, welcome_len    ; length of string to write
    call    write_stdout
    pop	    rsi					; argv[j]
    call    read_input          ; read input into buffer
    call    sgrep
	dec	    rbx					; dec arg-index
	jnz	    read_args			; continue until last argument was printed

	mov     r10, newline		; add a newline in the end
    mov     r15, 1              ; length of string to write (single char)
	call	write_stdout

exit:
	;; exit program via syscall
	mov	    rax, SYS_EXIT		; exit syscall
	mov	    rdi, 0				; exit code 0 (= "ok")
	syscall 				    ; kernel interrupt: system call
    
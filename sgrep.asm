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
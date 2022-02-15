;;; Bitte lassen Sie diese Einbindung unverändert.
%include "support_lsbsort.asm"
	
;;;=========================================================================
;;; initialisierte Daten
;;;=========================================================================

	section .data

;;; Platz für Ihre initialisierten Daten
	
;;;=========================================================================
;;; nicht initialisierte Daten
;;;=========================================================================

	section .bss

;;; Platz für Ihre nicht initialisierten Daten
	
;;;=========================================================================
;;; Code
;;;=========================================================================

	section .text

;;; Platz für Ihren Code
;;; Ihr Unterprogramm zur LSB-Sortierung muss die symbolische Adresse
;;; lsbsort haben.
;;; Ihr Unterprogramm darf weitere Unterprogramme nutzen, die ebenfalls
;;; hier untergebracht werden müssen.
	
;;;-------------------------------------------------------------------------
;;; lsbsort
;;;-------------------------------------------------------------------------

;;; clobbers: rax, rbx, rcx

;;; Wichtig:
;;; Ihr Unterprogramm muss den Vektor data unverändert lassen!
;;; Die sortierten Daten sind im Vektor sorted_data abzulegen!

lsbsort:
	;; ***** Ersetzen Sie diesen Code durch Ihre Implementation *****

	;; momentan nur Platzhalter:
	;; kopiert Vektor data auf Vektor sorted_data
	mov	rcx, 0
lsbsort_copy:
	mov	rax, [data + 8 * rcx]
	mov	[sorted_data + 8 * rcx], rax
	inc	rcx
	cmp	rcx, ELEMS
	jb 	lsbsort_copy

	ret
	

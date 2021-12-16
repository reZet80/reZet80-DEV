;===========================================================================
; reZet80 - Z80-based retrocomputing and retrogaming
; (c) copyright 2016-2021 Adrian H. Hilgarth (all rights reserved)
; 7-segment LED driver (_7segment.asm) [last modified: 2021-02-02]
; indentation setting: tab size = 8
;===========================================================================
_7_seg_out:	ld de, _7_seg_dat
		add a, e
		jr nc, _7_seg_out_
		inc d			; crossed 256-byte boundary
_7_seg_out_:	ld e, a
		ld a, (de)
		out (c), a
		dec b			; next digit to the right
		ret
;---------------------------------------------------------------------------
; --A--		bit 0: A
; |   |		bit 1: B
; F   B		bit 2: C
; |   |		bit 3: D
; --G--		bit 4: E
; |   |		bit 5: F
; E   C		bit 6: G
; |   |		bit 7: DP
; --D-- DP
;---------------------------------------------------------------------------
; 0: F + E + D + C + B + A
; 1: C + B
; 2: G + E + D + B + A
; 3: G + D + C + B + A
; 4: G + F + C + B
; 5: G + F + D + C + A
; 6: G + F + E + D + C + A
; 7: C + B + A
; 8: G + F + E + D + C + B + A
; 9: G + F + D + C + B + A
; A: G + F + E + C + B + A
; b: G + F + E + D + C
; C: F + E + D + A
; d: G + E + D + C + B
; E: G + F + E + D + A
; F: G + F + E + A
; H: G + F + E + C + B
; L: F + E + D
;---------------------------------------------------------------------------
; common cathode
if _7_SEG_CC
_7_seg_dat:
_7seg_0:	db 3fh			; 00111111b
_7seg_1:	db 06h			; 00000110b
_7seg_2:	db 5bh			; 01011011b
_7seg_3:	db 4fh			; 01001111b
_7seg_4:	db 66h			; 01100110b
_7seg_5:	db 6dh			; 01101101b
_7seg_6:	db 7dh			; 01111101b
_7seg_7:	db 07h			; 00000111b	
_7seg_8:	db 7fh			; 01111111b
_7seg_9:	db 6fh			; 01101111b
_7seg_a:	db 77h			; 01110111b
_7seg_b:	db 7ch			; 01111100b
_7seg_c:	db 39h			; 00111001b
_7seg_d:	db 5eh			; 01011110b
_7seg_e:	db 79h			; 01111001b
_7seg_f:	db 71h			; 01110001b
_7seg_blank:	db 00h			; 00000000b
_7seg_h:	db 76h			; 01110110b
_7seg_l:	db 38h			; 00111000b
_seg_dp:	db 80h                  ; 10000000b
endif
;---------------------------------------------------------------------------
; common anode
if _7_SEG_CA
_7_seg_dat:
_7seg_0:	db 0c0h			; 11000000b
_7seg_1:	db 0f9h			; 11111001b
_7seg_2:	db 0a4h			; 10100100b
_7seg_3:	db 0b0h			; 10110000b
_7seg_4:	db 99h			; 10011001b
_7seg_5:	db 92h			; 10010010b
_7seg_6:	db 82h			; 10000010b
_7seg_7:	db 0f8h			; 11111000b	
_7seg_8:	db 80h			; 10000000b
_7seg_9:	db 90h			; 10010000b
_7seg_a:	db 88h			; 10001000b
_7seg_b:	db 83h			; 10000011b
_7seg_c:	db 0c6h			; 11000110b
_7seg_d:	db 0a1h			; 10100001b
_7seg_e:	db 86h			; 10000110b
_7seg_f:	db 8eh			; 10001110b
_7seg_blank:	db 0ffh			; 11111111b
_7seg_h:	db 89h			; 10001001b
_7seg_l:	db 0c7h			; 11000111b
_seg_dp:	db 7fh			; 01111111b
endif
;===========================================================================

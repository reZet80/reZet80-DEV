;===========================================================================
; reZet80 - high-end retro arcade gaming and computing
; (c) copyright 2016-2020 Adrian H. Hilgarth (all rights reserved)
; keypad 16 driver (_keypad16.asm) [last modified: 2020-01-16]
; indentation setting: tab size = 8
;===========================================================================
_key_check:	ld b, 04h
_key_next:	rrca
		ret c
		inc d
		djnz _key_next
		ret
;---------------------------------------------------------------------------
_key_scan:	ld d, 00h		; d = pressed key (0...F)
		ld a, 01h		; 0001b
		ld c, a			; c = active key row
		out (_KEY_OUT), a
		in a, (_KEY_IN)
		call _key_check
		ret c
		ld a, 02h		; 0010b
		ld c, a
		out (_KEY_OUT), a
		in a, (_KEY_IN)
		call _key_check
		ret c
		ld a, 04h		; 0100b
		ld c, a
		out (_KEY_OUT), a
		in a, (_KEY_IN)
		call _key_check
		ret c
		ld a, 08h		; 1000b
		ld c, a
		out (_KEY_OUT), a
		in a, (_KEY_IN)
		call _key_check
		ret c
		jr _key_scan		; waits for a key press
;---------------------------------------------------------------------------
_key_in:	call _key_scan
_key_rel:	ld a, c			; load key row
		out (_KEY_OUT), a
		in a, (_KEY_IN)
		and 0fh
		jr nz, _key_rel		; waits as long as the key is pressed
		ret			; all keys in row are back up
;===========================================================================

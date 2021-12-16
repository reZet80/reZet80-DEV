;===========================================================================
; reZet80 - Z80-based retrocomputing and retrogaming
; (c) copyright 2016-2021 Adrian H. Hilgarth (all rights reserved)
; reZet80 deMon (_demon.asm) [last modified: 2021-02-17]
; indentation setting: tab size = 8
;===========================================================================
; deMon = debug Monitor
; DP means waiting for input via keypad
if _7_SEG
; output amount of ROM and RAM on debug display
		ld c, _DBG_IO
		ld b, 07h		; 1st digit on the left
		exx
		ld a, b
		exx
		call _show_KiB		; amount of ROM in KiB
		ld a, 11h		; 'H' for hex
		call _7_seg_out
		ld a, 10h		; blank
		call _7_seg_out
		exx
		ld a, c
		exx
		call _show_KiB		; amount of RAM in KiB
		ld a, 11h		; 'H'
		call _7_seg_out
		ld a, 13h		; DP
		call _7_seg_out
;---------------------------------------------------------------------------
; output date and time on debug display
		call _key_in		; press any key to continue
		call _rtc_date		; get and show date
		call _show_date
		call _key_in		; press any key to continue
		call _rtc_time		; get and show time
		call _show_time
		call _key_in		; press any key to continue
		call _clr		; clear screen and prompt
;		call _rtc_int		; enable 1s RTC interrupt
;---------------------------------------------------------------------------
_loop_0:	ld hl, _buffer		; command loop
_loop:		call _key_in		; wait for keypress
		cp 10h			; 0-F ?
		jr nc, _loop_1
		ld (hl), a		; save
		inc hl
		call _7_seg_out
		jr _loop
_loop_1:	jr nz, _loop_2		; ENTER ?
		ld a, 0ffh		; string terminator
		ld (hl), a
		jr _loop_eval
_loop_2:	cp 13h			; BACK ?
		jr nz, _loop_3
		ld a, l			; leftmost position ?
		or a
		jr z, _loop		; then continue
		dec hl			; delete last digit
		ld a, 13h		; DP
		inc b			; update 7-segment
		call _7_seg_out
		inc b
		jr _loop
_loop_3:	cp 12h			; ESC ?
		jr nz, _loop
_loop_end_:	call _key_in		; press any key to continue
_loop_end:	call _clr		; clear screen
		jr _loop_0		; start again
;---------------------------------------------------------------------------
; available commands:
; 0:		goto 0000h (soft reset)
; 0xxxx:	goto xxxxh (jump to address)
; 1:		show date
; 1WYYMMDD:	set date (day of week W, year 20YY, month MM, day DD)
;		day of week: 0 = Sunday, 1 = Monday, ..., 6 = Saturday
; 2:		show time
; 2HHMMSS:	set time (hour HH, minute MM, second SS, 24-hour format)
; Axxxx:	alter memory from address xxxxh on
;#Dxxxx:	disassemble from address xxxxh
; E:		examine memory from address 0000h on
; Exxxx:	examine memory from address xxxxh on
_loop_eval:	ld hl, _buffer		; command evaluation
		ld a, (hl)
		and a			; '0' ?
		jr nz, _loop_eval_1
		call _str_term		; string terminator ?
		jp z, _0000h		; soft reset
		call _calc_addr		; calculate address
		call _str_term		; string terminator ?
		jr nz, _loop_end
		ex de, hl
		jp (hl)			; jump to address
;---------------------------------------------------------------------------
_loop_eval_1:	cp 01h			; '1' ?
		jr nz, _loop_eval_2
		call _str_term		; string terminator ?
		jr nz, _loop_eval_11
		call _rtc_date		; get and show date
		call _show_date
		jr _loop_end_
_loop_eval_11:	call _load_params	; set date
		call _rtc_set_date
		jr _loop_end
;---------------------------------------------------------------------------
_loop_eval_2:	cp 02h			; '2' ?
		jr nz, _loop_eval_a
		call _str_term		; string terminator ?
		jr nz, _loop_eval_22
		call _rtc_time		; get and show time
		call _show_time
		jr _loop_end_
_loop_eval_22:	call _load_param	; set time
		call _rtc_set_time
		jr _loop_end
;---------------------------------------------------------------------------
_loop_eval_a:	cp 0ah			; 'A' ?
		jr nz, _loop_eval_d
		call _calc_addr		; calculate address
_loop_eval_aa_:	; print address (4 digits)
		; load byte
		; print byte
		; print DP DP
		call _key_in		; wait for key press
		; ESC -> exit
		; 0-F: print byte (max 2) + advance
		; BACK: delete last byte
		; ENTER -> if<2 bytes do nothing
		; ENTER -> if=2 bytes convert+write+inc address+jr to [print address]
		; #wie normale eingabe fuer 2 digits !!!#
		jr _loop_end
;---------------------------------------------------------------------------
_loop_eval_d:	cp 0dh			; 'D' ?
		jr nz, _loop_eval_e
		call _calc_addr		; calculate address
		;TODO
		jr _loop_end
;---------------------------------------------------------------------------
_loop_eval_e:	cp 0eh			; 'E' ?
		jr nz, _loop_end
		ld de, 0000h
		call _str_term		; string terminator ?
		jr z, _loop_eval_ee_
		call _calc_addr		; calculate address
		jr nz, _loop_end
_loop_eval_ee_:	; print address (4 digits)
		; print space
		; load byte
		; print byte
		; print DP
		call _key_in		; wait for key press
		; ESC -> exit
		; ENTER -> jr to [print address]
		jr _loop_end
;---------------------------------------------------------------------------
_str_term:	inc hl			; is next char string terminator ?
		ld a, (hl)
		dec hl
		cp 0ffh
		ret
;---------------------------------------------------------------------------
_calc_addr:	call _calc_addr_	; calculate address out of 4 digits
		ld d, a
_calc_addr_:	inc hl
		ld a, (hl)
		rlca
		rlca
		rlca
		rlca
		inc hl
		or (hl)
		ld e, a
		ret
;---------------------------------------------------------------------------
_load_params:	ex af, af'
		inc hl
		ld a, (hl)
		ex af, af'
_load_param:	inc hl
		ld a, (hl)
		exx
		ld b, a
		exx
		inc hl
		ld a, (hl)
		exx
		ld c, a
		exx
		inc hl
		ld a, (hl)
		exx
		ld d, a
		exx
		inc hl
		ld a, (hl)
		exx
		ld e, a
		exx
		inc hl
		ld a, (hl)
		exx
		ld h, a
		exx
		inc hl
		ld a, (hl)
		exx
		ld l, a
		exx
		ret
;---------------------------------------------------------------------------
_show_KiB:	sla a
		sla a			; 4 KiB per page
		ld i, a			; save original
		srl a
		srl a
		srl a
		srl a			; bits 4-7
		call _7_seg_out
		ld a, i
		and 0fh			; bits 0-3
		call _7_seg_out
		ret
;---------------------------------------------------------------------------
_clr:		ld a, 08h		; clear 8 digits
		ld b, 07h		; 1st digit on the left
_prompt:	ex af, af'
		ld a, 13h		; DP
		call _7_seg_out
		ex af, af'
		dec a
		jr nz, _prompt
		ret
;---------------------------------------------------------------------------
_show_date:	ld b, 07h		; 1st digit on the left
		ld c, _DBG_IO
		ld a, 02h		; 2
		call _7_seg_out
		xor a			; 0
		call _7_seg_out
_show_6:	exx
		ld a, b			; Y | H
		exx
		call _7_seg_out
		exx
		ld a, c			; Y | H
		exx
		call _7_seg_out
		exx
		ld a, d			; M | M
		exx
		call _7_seg_out
		exx
		ld a, e			; M | M
		exx
		call _7_seg_out
		exx
		ld a, h			; D | S
		exx
		call _7_seg_out
		exx
		ld a, l			; D | S
		exx
		call _7_seg_out
		ret
;---------------------------------------------------------------------------
_show_time:	ld b, 07h		; 1st digit on the left
		ld c, _DBG_IO
		call _show_6
		ld a, 13h		; DP
		call _7_seg_out
		ld a, 13h		; DP
		call _7_seg_out
		ret
;---------------------------------------------------------------------------

endif
;===========================================================================

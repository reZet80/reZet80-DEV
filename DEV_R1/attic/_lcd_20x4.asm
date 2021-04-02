;===========================================================================
; reZet80 - Z80-based retrocomputing and retrogaming 
; (c) copyright 2016-2020 Adrian H. Hilgarth (all rights reserved)
; HD44780 LCD 20x4 driver (_lcd_20x4.asm) [last modified: 2020-10-26]
; indentation setting: tab size = 8
;===========================================================================
; include this in "_dev.asm"
;_LCD_20x4:	equ 1
; 70h-7fh: LCD
;_LCD_CMD:	equ 71h			; LCD command
;_LCD_DAT:	equ 70h			; LCD characters
;---------------------------------------------------------------------------
; include this in "_dev.asm"
;if _LCD_20x4
;include "_lcd_20x4.asm"
;endif
;---------------------------------------------------------------------------
; to init call this first
;if _LCD_20x4
;		call _lcd_init_8	; set 8-bit LCD interface
;endif
;---------------------------------------------------------------------------
; and later this
;if _LCD_20x4
;		call _lcd_init		; finish LCD initialization
;endif
;---------------------------------------------------------------------------
; all this does is show amount of ROM and RAM, display date and time and
; provide us with a prompt to enter new date / time
		ld bc, 0100h
		call _lcd_line		; pos=0,2
		exx
		ld a, b
		exx
		call _conv_kib
		ld hl, _dat_rom		; output amount of ROM
		call _text
		ld bc, 0200h
		call _lcd_line		; pos=0,3
		exx
		ld a, c
		exx
		call _conv_kib
		ld hl, _dat_ram		; output amount of RAM
		call _text
		ld bc, 0300h
		call _lcd_line		; pos=0,4
		call _rtc_date		; get date
		push hl
		push de
		push bc
		ld hl, _dat_weekday	; output day of week
		ld de, 0004h
_day_week:	and a
		jr z, _day_week_done
		add hl, de
		dec a
		jr _day_week
_day_week_done:	call _text
		ld hl, _dat_2k		; output '20'
		call _text
		pop bc			; output year
		ld a, c
		call _to_ascii
		ld a, b
		call _to_ascii
		call _lcd_dash		; output a '-'
		pop de			; output month
		ld a, d
		call _to_ascii
		ld a, e
		call _to_ascii
		call _lcd_dash		; output a '-'
		pop hl			; output day
		ld a, h
		call _to_ascii
		ld a, l
		call _to_ascii
		ld bc, 020ch
		call _lcd_line		; pos=12,3
		call _rtc_time		; get time
		push hl
		push de
		ld a, c
		call _to_ascii		; output hour
		ld a, b
		call _to_ascii
		call _lcd_colon		; output a ':'
		pop de			; output minute
		ld a, d
		call _to_ascii
		ld a, e
		call _to_ascii
		call _lcd_colon		; output a ':'
		pop hl			; output second
		ld a, h
		call _to_ascii
		ld a, l
		call _to_ascii
		ld bc, 0313h
		call _lcd_line		; pos=20,4
		ld hl, _dat_next	; output an arrow
		call _text
		call _key_in		; wait for keypress
		call _lcd_clear		; clear screen
		call _lcd_prompt	; at last a prompt
_loop_begin:	ld e, 00h		; key count
		ld hl, _buffer
_loop:		call _key_in		; wait for keypress
		ld a, d
		cp 10h			; extra key ENTER pressed ?
		jr nz, _loop_next_1
		ld c, 3ch		; '<' means enter
		call _lcd_dat		; output '<'
		jr _loop_eval
_loop_next_1:	cp 11h			; extra key BACK pressed ?
		jr nz, _loop_next_2
		ld a, e
		and a			; first key press ?
		jr z, _loop
		dec hl			; one char back
		dec e			; no of chars - 1
		call _lcd_back		; move 1 position to the left on LCD
		ld c, 20h		; blank
		call _lcd_dat		; overwrite last char
		call _lcd_back		; and left again
		jr _loop
_loop_next_2:	ld (hl), a		; save key
		inc hl
		inc e
		ld c, 20h		; blank
		cp 12h			; extra key SPACE pressed ?
		jr z, _loop_out
		ld c, 23h		; '#'
		cp 13h			; 4th extra key pressed ?
		jr z, _loop_out
		call _to_ascii		; output
_loop_next:	ld a, e
		cp 12h			; 18 chars max
		jr nz, _loop
_loop_eval:	ld hl, _buffer
		ld a, (hl)
		inc hl
		cp 0dh			; 'D' ?
		jr nz, _loop_end	; if no start again
; DWYYMMDDHHMMSS : set date time (W 20YY-MM-DD HH:MM:SS) [W=day of the week]
		ld a, (hl)		; no checks done
		inc hl
		ex af, af'		; day of the week
		ld b, (hl)		; Y
		inc hl
		ld c, (hl)		; Y
		inc hl
		ld d, (hl)		; M
		inc hl
		ld e, (hl)		; M
		inc hl
		ld a, (hl)
		inc hl
		push hl
		ld l, (hl)		; D
		ld h, a			; D
		exx
		pop hl
		inc hl
		ld b, (hl)		; H
		inc hl
		ld c, (hl)		; H
		inc hl
		ld d, (hl)		; M
		inc hl
		ld e, (hl)		; M
		inc hl
		ld a, (hl)
		inc hl
		ld l, (hl)		; S
		ld h, a			; S
		call _rtc_set		; set new time/date
_loop_end:	call _lcd_clear		; clear screen
		call _lcd_prompt	; prompt again
		jr _loop_begin
_loop_out:	call _lcd_dat
		jr _loop_next
;---------------------------------------------------------------------------
_lcd_ready:	in a, (_LCD_CMD)	; read busy flag
		rlca			; bit 7 set ?
		jr c, _lcd_ready	; if yes, wait until cleared
		ld a, c
		ret
;---------------------------------------------------------------------------
_lcd_colon:	ld c, ':'
		jr _lcd_dat
;---------------------------------------------------------------------------
_lcd_dash:	ld c, '-'
		jr _lcd_dat
;---------------------------------------------------------------------------
_lcd_prompt:	ld c, '>'		; LCD uses ASCII
;---------------------------------------------------------------------------
_lcd_dat:	call _lcd_ready
		out (_LCD_DAT), a
		ret
;---------------------------------------------------------------------------
_lcd_cmd:	call _lcd_ready
		out (_LCD_CMD), a
		ret
;---------------------------------------------------------------------------
_lcd_clear:	ld c, 01h		; 00000001b clear display|address=00h
		jr _lcd_cmd
;---------------------------------------------------------------------------
_lcd_back:	in a, (_LCD_CMD)
		and 7fh			; bits 0-6
		dec a			; back 1 position
		or 80h			; 1xxxxxxxb set address
		ld c, a
		jr _lcd_cmd
;---------------------------------------------------------------------------
_lcd_init_8:	ld bc, 0300h
_lcd_init_3:	dec c			; 4*256 + 12*255 + 7 T
		jr nz, _lcd_init_3	; delay ~ 0,2 ms @ 20 MHz
		ld a, 30h		; 00110000b set 8-bit interface
		out (_LCD_CMD), a
		djnz _lcd_init_3	; repeat for reliable 8-bit init
		ret
;---------------------------------------------------------------------------
_lcd_init:	ld hl, _dat_lcd_init
		ld b, (hl)
		inc hl
_lcd_init_r:	ld c, (hl)
		inc hl
		call _lcd_cmd
		djnz _lcd_init_r
		ret
;---------------------------------------------------------------------------
_lcd_line:	ld de, _dat_lcd_line
		ld a, b
		add a, e
		ld e, a
		ld a, (de)
		add c
		or 80h			; 1xxxxxxxb set address
		ld c, a
		jr _lcd_cmd
;---------------------------------------------------------------------------
_dat_lcd_line:	db 00h, 40h, 14h, 54h	; line address
;---------------------------------------------------------------------------
_dat_lcd_init:	db 04h			; 4 commands
		db 38h			; 00111000b 8-bit|2 lines|5x7 dots
		db 06h			; 00000110b address inc|no shift
		db 0ch			; 00001100b display on|cursor off|blink off
		db 01h			; 00000001b clear display|address=0
;---------------------------------------------------------------------------
_dat_hi:	db 'reZet80 DEV R0', 00h
_dat_rom:	db 'H KiB ROM', 00h
_dat_ram:	db 'H KiB RAM', 00h
_dat_next:	db 7eh, 00h
;===========================================================================

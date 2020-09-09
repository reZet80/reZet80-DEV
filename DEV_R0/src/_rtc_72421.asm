;===========================================================================
; reZet80 - high-end retro arcade gaming and computing
; (c) copyright 2016-2020 Adrian H. Hilgarth (all rights reserved)
; RTC-72421 driver (_rtc_72421.asm) [last modified: 2020-01-16]
; indentation setting: tab size = 8
;===========================================================================
; 4-bit RTC | 16 registers | time & date in BCD | int
;---------------------------------------------------------------------------
_rtc_ready:	in a, (_RTC_D)		; read register D
		or 01h			; set HOLD bit
		out (_RTC_D), a
		in a, (_RTC_D)
		and 02h			; BUSY bit set ?
		ret z			; leave with HOLD bit set
		call _rtc_hold
		jr _rtc_ready
;---------------------------------------------------------------------------
_rtc_time:	call _rtc_ready
		in a, (_RTC_5)
		and 03h			; bits 0 - 1 | AMPM ignored
		ld c, a			; c = HOUR_10
		in a, (_RTC_4)
		and 0fh			; bits 0 - 3
		ld b, a			; b = HOUR_1
		in a, (_RTC_3)
		and 07h			; bits 0 - 2
		ld d, a			; d = MIN_10
		in a, (_RTC_2)
		and 0fh			; bits 0 - 3
		ld e, a			; e = MIN_1
		in a, (_RTC_1)
		and 07h			; bits 0 - 2
		ld h, a			; h = SEC_10
		in a, (_RTC_0)
		and 0fh			; bits 0 - 3
		ld l, a			; l = SEC_1
_rtc_hold:	in a, (_RTC_D)
		and 0eh			; clear HOLD bit
		out (_RTC_D), a
		ret			; cb:de:hl (HH:MM:SS)
;---------------------------------------------------------------------------
_rtc_date:	call _rtc_ready
		in a, (_RTC_B)
		and 0fh			; bits 0 - 3
		ld c, a			; c = YEAR_10
		in a, (_RTC_A)
		and 0fh			; bits 0 - 3
		ld b, a			; b = YEAR_1
		in a, (_RTC_9)
		and 01h			; bit 0
		ld d, a			; d = MONTH_10
		in a, (_RTC_8)
		and 0fh			; bits 0 - 3
		ld e, a			; e = MONTH_1
		in a, (_RTC_7)
		and 03h			; bits 0 - 1
		ld h, a			; h = DAY_10
		in a, (_RTC_6)
		and 0fh			; bits 0 - 3
		ld l, a			; l = DAY_1
		in a, (_RTC_C)
		and 07h			; bits 0 - 2 | a = WEEK_DAY
		ex af, af'
		call _rtc_hold
		ex af, af'
		ret			; a 20cb-de-hl (DW 20YY-MM-DD)
;---------------------------------------------------------------------------
_rtc_set:	ld a, 04h		; 0100b TEST|2412|STOP|RESET
		out (_RTC_F), a
		xor a			; 0000b T1|T0|INT|MASK
		out (_RTC_E), a
		out (_RTC_D), a		; 0000b 30ADJ|IRQ|BUSY|HOLD
		call _rtc_ready
		ld a, 07h		; 0111b TEST|2412|STOP|RESET
		out (_RTC_F), a
		ld a, b			; write registers 0 - 5
		out (_RTC_5), a		; bc:de:hl (HH:MM:SS)
		ld a, c
		out (_RTC_4), a
		ld a, d
		out (_RTC_3), a
		ld a, e
		out (_RTC_2), a
		ld a, h
		out (_RTC_1), a
		ld a, l
		out (_RTC_0), a
		ex af, af'		; write registers 6 - C
		out (_RTC_C), a
		exx
		ld a, b			; a 20bc-de-hl (DW 20YY-MM-DD)
		out (_RTC_B), a
		ld a, c
		out (_RTC_A), a
		ld a, d
		out (_RTC_9), a
		ld a, e
		out (_RTC_8), a
		ld a, h
		out (_RTC_7), a
		ld a, l
		out (_RTC_6), a
		ld a, 04h		; same as first step
		out (_RTC_F), a
		xor a
		out (_RTC_E), a
		out (_RTC_D), a
		ret
;---------------------------------------------------------------------------
_dat_weekday:	db 'SUN', 00h		; = 0
		db 'MON', 00h		; = 1
		db 'TUE', 00h		; = 2
		db 'WED', 00h		; = 3
		db 'THU', 00h		; = 4
		db 'FRI', 00h		; = 5
		db 'SAT', 00h		; = 6
_dat_2k:	db ' 20', 00h
;===========================================================================

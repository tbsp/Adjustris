;******************************************************************************
;* 
;* Adjustris - Block dropping puzzle game for Gameboy
;*
;* Written in 2017 by Dave VanEe (tbsp) dave.vanee@gmail.com
;* 
;* To the extent possible under law, the author(s) have dedicated all copyright 
;* and related and neighboring rights to this software to the public domain 
;* worldwide. This software is distributed without any warranty.
;*   
;* You should have received a copy of the CC0 Public Domain Dedication along with 
;* this software. If not, see <http://creativecommons.org/publicdomain/zero/1.0/>.
;*
;******************************************************************************

SECTION "Sound Player",ROM0

MS_sfxM1:
		ld		a,[hli]
		ldh		[MS_M1tmr],a
		ld		a,[hli]
		ldh		[$10],a
		ld		a,[hli]
		ldh		[$11],a
		ld		a,[hli]
		ldh		[$12],a
		ld		a,[hli]
		ldh		[$13],a
		ld		a,[hl]
		ldh		[$14],a
		ldh		a,[$25]
		or		%00010001
		ldh		[$25],a
		ret

MS_sfxM2:
		ld		a,[hli]
		ldh		[MS_M2tmr],a
		ld		a,[hli]
		ldh		[$16],a
		ld		a,[hli]
		ldh		[$17],a
		ld		a,[hli]
		ldh		[$18],a
		ld		a,[hl]
		ldh		[$19],a
		ldh		a,[$25]
		or		%00100010
		ldh		[$25],a
		ret

MS_sfxM3:
		ld		a,[hli]
		ldh		[MS_M3tmr],a
		xor		a
		ldh		[$1E],a
		ld		a,$80		
		ldh		[$1A],a
		ld		a,[hli]
		ldh		[$1B],a
		ld		a,[hli]
		ldh		[$1C],a
		ld		a,[hli]
		ldh		[$1D],a
		ld		a,[hl]
		ldh		[$1E],a
		or		$80
		ldh		[$1E],a
		ld		hl,MS_wavedata  ; leave hl hanging and include wavedata with each effect
		ld		de,$FF30
		ld		bc,$0010
		call	mem_Copy
		ldh		a,[$25]
		or		%01000100
		ldh		[$25],a
		ret

MS_sfxM4:
		ld		a,[hli]
		ldh		[MS_M4tmr],a
		ld		a,[hli]
		ldh		[$20],a
		ld		a,[hli]
		ldh		[$21],a
		ld		a,[hli]
		ldh		[$22],a
		ld		a,[hl]
		ldh		[$23],a
		ldh		a,[$25]
		or		%10001000
		ldh		[$25],a
		ret

MS_player:
		ldh		a,[MS_M1tmr]
		cp		0
		jr		z,.m2t
		dec		a
		ldh		[MS_M1tmr],a
.m2t
		ldh		a,[MS_M2tmr]
		cp		0
		jr		z,.m3t
		dec		a
		ldh		[MS_M2tmr],a
.m3t
		ldh		a,[MS_M3tmr]
		cp		0
		jr		z,.m4t
		dec		a
		ldh		[MS_M3tmr],a
.m4t
		ldh		a,[MS_M4tmr]
		cp		0
		jr		z,.mdt
		dec		a
		ldh		[MS_M4tmr],a
.mdt
		ldh		a,[MS_M1tmr]
		cp		0
		jr		nz,.play_M2
		ldh		a,[$25]
		res		0,a
		res		4,a
		;xor		%00010001
		ldh		[$25],a
.play_M2
		ldh		a,[MS_M2tmr]
		cp		0
		jr		nz,.play_M3
		ldh		a,[$25]
		res		1,a
		res		5,a
		;xor		%00100010
		ldh		[$25],a
.play_M3
		ldh		a,[MS_M3tmr]
		cp		0
		jr		nz,.play_M4
		ldh		a,[$25]
		res		2,a
		res		6,a
		;xor		%01000100
		ldh		[$25],a
.play_M4
		ldh		a,[MS_M4tmr]
		cp		0
		jr		nz,.done_cycle
		ldh		a,[$25]
		res		3,a
		res		7,a
		;xor		%10001000
		ldh		[$25],a
.done_cycle
		ret

MS_setup_sound:
		ld		a,%10000000
		ldh		[$26],a
		ld		a,%01110111
		ldh		[$24],a
		ld		a,%10000000
		ldh		[$1A],a
		xor		a
		ldh		[$25],a
		;ld		hl,MS_wavedata
		;ld		de,$FF30
		;ld		bc,$0010
		;call	mem_Copy
		ret

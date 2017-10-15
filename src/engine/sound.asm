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

INCLUDE "gbhw.inc"

SECTION "Sound HiRAM", HRAM[$FFCD]

MS_M1tmr:   ds 1
MS_M2tmr:   ds 1
MS_M3tmr:   ds 1
MS_M4tmr:   ds 1

;MS_song			=	$C0	; [2]
;MS_patterns		=	$C2	; [2]
;MS_tempo		=	$C4
;MS_tempotimer	=	$C5
;MS_sngLoc		=	$C6 ; 2 bytes H/L
;MS_sngPatE		=	$C8
;MS_M1pat		=	$C9
;MS_M2pat		=	$CA
;MS_M3pat		=	$CB
;MS_M4pat		=	$CC
;MS_M1tmr		=	$CD
;MS_M2tmr		=	$CE
;MS_M3tmr		=	$CF
;MS_M4tmr		=	$D0


SECTION "Sound Effects", ROM0


; ====== SOUND ======

FX_menuMove:
		DB 18,$A8,$F1,$BF,$C4
FX_menuSelect:
		DB 18,$4A,$F1,$BF,$C4
FX_gamelaser:
		DB 18,$1F,$80,$F1,$FF,$87
FX_gameGuns:
		DB 18,$2A,$F7,$78,$C0
FX_gameMove:
        DB 18,$BC,$F1,$BF,$C6
FX_gameRotate:
        DB 18,$7D,$9F,$F1,$3F,$C7
FX_gameBomb:
		DB 18,$20,$F4,$5E,$C0
FX_statsLongExplode:
		DB 48,$00,$F3,$57,$80

FX_editMove:
        DB 18,$A8,$F1,$BF,$C4
FX_editConfirm:
		DB 18,$4A,$F1,$BF,$C4
FX_editCancel:
		DB 18,$9F,$F4,$BB,$C3
        		
FX_gamenoID:
		DB 18,$19,$40,$A2,$FF,$81
FX_gameID:
		DB 18,$13,$80,$F7,$0F,$80

MS_wavedata:
		DB $9B,$CD,$EE,$FF,$FE,$ED,$CB,$A8,$76,$43,$21,$10,$00,$11,$23,$46
		
song_Menu:
song_patterns_Menu:
instruments:
		

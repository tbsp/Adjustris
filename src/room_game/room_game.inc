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

;******************************************************************************
;**                                   Defines                                **
;******************************************************************************

StartDropSpeed  EQU $40
MinDropSpeed    EQU $04
Width		    EQU $0A    ; Playing Field Width
HoldPause       EQU $0C
HoldDelay       EQU $06 ; 4
LineLimitGoal   EQU $000A
LevelIncrement  EQU $000A  ; lines per level
ROM_Set_Count   EQU 4

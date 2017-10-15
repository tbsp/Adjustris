;********************************************************************
;*                                                                  *
;*                          HISCORE.Z80                             *
;*                                                                  *
;*                           Version 1                              *
;*                                                                  *
;*                   Copyright H. Mulder, 1999                      *
;*                                                                  *
;*                                                                  *
;* This unit was made to give a ready-to-use solution for Hiscores. *
;*                                                                  *
;* HiScores (ie: the number of points a player has scored) have a   *
;* tendency to be quite large, making calculations and displaying   *
;* not easy when operating in a 8-bit environment. On the other     *
;* hand, not much is done with a Hiscore: points are added to it,   *
;* it needs to be displayed, and some ranking is needed, but that's *
;* about it.                                                        *
;*                                                                  *
;* This unit introduces a special data-type, called a HiScore:      *
;*                                                                  *
;*  A HiScore is a set of bytes, whereby each byte represents one   *
;*  digit in the decimal number, with the highest digit on the      *
;*  left. If the contained number is smaller than the allocated     *
;*  space, it is filled up with $80 on the left side.               *
;*                                                                  *
;* Some examples (the size of a HiScore is 8):                      *
;*                                                                  *
;*       100  = 80 80 80 80 80 01 00 00                             *
;*     30510  = 80 80 80 03 00 05 01 00                             *
;*  99999999  = 09 09 09 09 09 09 09 09                             *
;*                                                                  *
;*                                                                  *
;* Notes:                                                           *
;*                                                                  *
;* The default size of a Hiscore is 8, but this can be changed by   *
;* changing the value of HiScoreLength in HISCORE.INC. It's value   *
;* can be between 6 and 255. Note that ALL Hiscores in your program *
;* use this size, and this size alone.                              *
;*                                                                  *
;* If a HiScore overflows, it will keep on counting, ignoring the   *
;* overflow. so, adding 4 to 99999999 will result in 00000003.      *
;*                                                                  *
;*                                                                  *
;* Functions:                                                       *
;*                                                                  *
;*  ResetHiScore                                                    *
;*                                                                  *
;*    Use this function to reset a Hiscore to 0. Always reset a     *
;*    Hiscore before using it.                                      *
;*                                                                  *
;*                                                                  *
;*  AddHiScore                                                      *
;*                                                                  *
;*    This function will add one Hiscore to another.                *
;*                                                                  *
;*                                                                  *
;*  AddBCHiScore                                                    *
;*                                                                  *
;*    This function will add the value of BC to a Hiscore.          *
;*                                                                  *
;*                                                                  *
;*  CpHiScore                                                       *
;*                                                                  *
;*    Use this function to compare two Hiscores.                    *
;*                                                                  *
;*                                                                  *
;* Extra info:                                                      *
;*                                                                  *
;* This unit is Public Domain; you can use it in any way you want.  *
;* Use this unit at your own peril; I cannot be blamed for any      *
;* damage resulting in it's use.                                    *
;* You are free to redistribute it, as long as you do so using the  *
;* original package.                                                *
;*                                                                  *
;* I can be contacted via hpmulder@casema.net. Goto my site at      *
;* http://www.casema.net/~hpmulder for more info about Gameboy      *
;* programming.                                                     *
;*                                                                  *
;*                                                                  *
;* History:                                                         *
;*                                                                  *
;*  7 March 1999        Initial release                             *
;*                                                                  *
;********************************************************************




;INCLUDE "hiscore.inc"

HiScoreLength EQU 6

SECTION "HiScore", ROM0


ResetHiScore:
;********************************************************
;*                                                      *
;* Resets the Hiscore at location HL to 0. Always reset *
;* a HiScore before usage.                              *  
;*                                                      *
;*  Parameters:                                         *
;*                                                      *
;*   [hl] = Destination (should be RAM)                 *
;*                                                      *
;*  Destroys:                                           *
;*   af                                                 *
;*                                                      *
;********************************************************

  push hl
  push bc

  ld c,HiScoreLength-1
  ld a, $80             ; Set to empty
.L1:ld [hl+],a
    dec c
  jr nz, .L1

  xor a                 ; last should be "0"
  ld [hl],a

  pop bc
  pop hl

ret




AddHiScore:
;***********************************************************
;*                                                         *
;*  Adds HiScore at location DE to HiScore at location HL. *
;*                                                         *
;*  Parameters:                                            *
;*                                                         *
;*   [hl] = Destination (should be RAM)                    *
;*   [de] = Source                                         *
;*                                                         *
;*  Destroys:                                              *
;*   af                                                    *
;*                                                         *
;***********************************************************


  push hl
  push de
  push bc
  
  ld bc, HiScoreLength-1
  add hl,bc                     ; set to right-most number

  push hl
  ld h,d
  ld l,e
  add hl,bc                     ; set to right-most number
  ld e,l
  ld d,h
  pop hl

  inc c                         ; c = HiScoreLength
                                ; b = 0 = no residue

.L1:ld a,[de]                   ; addition
    and $7F                     ; set empty to 0

    call IntHiScore
    dec de

  dec c
  jr nz, .L1

  pop bc
  pop de
  pop hl

ret



AddBCHiScore:
;***********************************************************
;*                                                         *
;*  Adds value of BC to HiScore at location HL.            *
;*                                                         *
;*  Parameters:                                            *
;*                                                         *
;*   [hl] = Destination (should be RAM)                    *
;*   bc   = Value to add                                   *
;*                                                         *
;*  Destroys:                                              *
;*   af                                                    *
;*                                                         *
;***********************************************************

  push hl
  push de
  push bc

  ld de, HiScoreLength-1
  add hl,de                     ; set to right-most number

  ld de,IntHiScoreTable         ; internal bin2dec table

.L1:srl b
    rr c                        ; bc >> 1
    jr nc, .L5

      ; bit is set; add value from table
      push hl
      push bc

      ld bc,$0005               ; b = no addition, c = table-entry length
.L3:    ld a,[de]
        inc de
        call IntHiScore         ; add table-entry
      dec c
      jr nz, .L3

      ld c,HiScoreLength-5
.L4:    xor a
        call IntHiScore         ; add possible residue
      dec c
      jr nz, .L4

      pop bc
      pop hl

    jr .L2

.L5:  ; bit not set, next table entry
      inc de
      inc de
      inc de
      inc de
      inc de

.L2:ld a,c
    or b                        ; bc = 0 ?
    jr nz, .L1

  pop bc
  pop de
  pop hl

ret



CpHiScore:
;*************************************************
;*                                               *
;*  Compares HiScore at location DE with HiScore *
;*  at location HL.                              *
;*                                               *
;*  Parameters:                                  *
;*                                               *
;*   [hl] = Destination                          *
;*   [de] = Source                               *
;*                                               *
;*  Returns:                                     *
;*                                               *
;*   CF   = [hl] is lower than [de]              *
;*   NCF  = [hl] is equal or higher than [de]    *
;*                                               *
;*  Destroys:                                    *
;*   af                                          *
;*                                               *
;*************************************************

  push hl
  push de
  push bc

  ld c, HiScoreLength
.L1:ld a,[de]
    and $7F
    inc de
    ld b,a              ; b = number in Source

    ld a,[hl+]
    and $7F             ; a = number in dest

    cp b
    ;jr c, .L2           ; a < b =>  [hl] < [de]
    jr nz,.L2           ; at least one non-zero, highest 10s place w/ diff #'s is the deciding place

  dec c
  jr nz, .L1

.L2:
  pop bc
  pop de
  pop hl

ret


;**********   INTERNAL SUPPORT   ************

IntHiScore:
; [Internal function]
; a    = number to add
; b    = residue from previous call
; [hl] = number to add to

    add b               ; add residue

    ld b,a
    ld a,[hl]           ; base
    and $7F             ; set empty to 0
    add b               ; add total addition
    ld b,0              ; clear residue

    jr nz, .L3          ; jump if number <> "0"

      ld a,[hl]         ; current number empty ?
      and $80           ; Yes/No
      jr .L2

.L3:cp 10
    jr c, .L2           ; jump if number < 10

      sub 10            ; correct number
      inc b             ; setup residue

.L2:ld [hl-],a          ; write number
ret



IntHiScoreTable:
; bin2dec lookup table
  db 1,0,0,0,0
  db 2,0,0,0,0
  db 4,0,0,0,0
  db 8,0,0,0,0
  db 6,1,0,0,0
  db 2,3,0,0,0
  db 4,6,0,0,0
  db 8,2,1,0,0
  db 6,5,2,0,0
  db 2,1,5,0,0
  db 4,2,0,1,0
  db 8,4,0,2,0
  db 6,9,0,4,0
  db 2,9,1,8,0
  db 4,8,3,6,1
  db 8,6,7,2,3


;* End of HISCORE.Z80 *


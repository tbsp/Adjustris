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
INCLUDE "joypad.inc"
INCLUDE "room_credits.inc"

;******************************************************************************
;**                                  Variables                               **
;******************************************************************************

SECTION "Room Credits Variables",WRAM0

credits_exit:   ds 1


SECTION "Room Credits Code/Data", ROM0


Credits_Loop:
    call    Credits_Input
    call    Credits_Scroller
    call    Credits_UpdateSprites
    call    RandomNumber
    halt
    nop
    jr      Credits_Loop
  
Credits_Input:
    call    ReadJoyPad    
    ldh     a,[hPadPressed]
    and     BUTTON_A|BUTTON_B|BUTTON_START
    jr      nz,.Button_Pressed
    ret
.Button_Pressed
    pop     hl
    ret
 
Credits_Scroller:
    ldh     a,[CR_ScrollCount]
    dec     a
    cp      0
    jr      z,.go
    ldh     [CR_ScrollCount],a
    ret
.go
    ld      a,CR_ScrollDelay
    ldh     [CR_ScrollCount],a

    ldh     a,[rSCX]        ; ues CR_ScrollPixel instead of SCX?
    inc     a
    ldh     [rSCX],a
    and     %00000111
    cp      0
    ret     nz

    ; only adjust vram every 8 pixels
    ldh     a,[CR_ScrollChar]
    inc     a
    cp      CR_Text_End-CR_Text
    jr      nz,.ok
    xor     a
.ok
    ldh     [CR_ScrollChar],a

    ld      hl,CR_Text             ; get next character
    ld      d,0
    ld      e,a
    add     hl,de
    ld      a,[hl]
    ldh     [CR_NextChar],a

    ldh     a,[CR_VRAMPos]        ; step VRAM addy
    inc     a
    cp      $20
    jr      nz,.ok2
    xor     a
.ok2
    ldh     [CR_VRAMPos],a

    ret
  
Credits_UpdateSprites:
    ldh     a,[CR_PieceX]
    dec     a
    dec     a
    cp      $BE
    jr      nz,.no_loop
    call    Credits_GenerateNewPiece
    ld      a,160
.no_loop
    ldh     [CR_PieceX],a

    ldh     a,[CR_PieceYidx]
    inc     a
    and     $7F
    ldh     [CR_PieceYidx],a
    ld      hl,CR_Sine
    ld      d,0
    ld      e,a
    add     hl,de
    ld      a,[hl]
    ldh     [CR_Temp],a

    ld      hl,$C000
    ld      de,YX+1
    inc     de
    ld      a,[de]         ; get block count
    inc     de
    inc     de            ; skip rot pair
    inc     de
    ld      b,a
.lp
    ld      a,[de]
    inc     de
    add     a,a
    add     a,a
    add     a,a
    ld      c,a
    ldh     a,[CR_Temp]
    add     a,c
    add     a,$18
    ld      [hli],a
    ld      a,[de]
    inc     de
    add     a,a
    add     a,a
    add     a,a
    add     a,$18
    ld      c,a
    ldh     a,[CR_PieceX]
    add     a,c
    ld      [hli],a
    ld      a,[YX+1]
    ld      [hli],a
    ld      a,$80
    ld      [hli],a
    dec     b
    jr      nz,.lp
    ret

    ret
  
Credits_GenerateNewPiece:  
    call    RandomNumber
    ld      c,a
    ldh     a,[CR_PieceCount]   ; get # of pieces in set
    ld      e,a
    call    Unsigned_Multiply
    ld      a,h                    ; only use high byte
    ldh     [CR_Piece],a

    ld      hl,CR_FullSet
    ld      b,a
.lpPiece
    inc     hl        ; skip flag byte
    inc     hl        ; skip tile byte
    ld      a,[hli]    ; get block count
    inc     hl
    inc     hl        ; skip rotation pair
.lpBlocks
    inc     hl
    inc     hl
    dec     a
    jr      nz,.lpBlocks
    dec     b
    jr      nz,.lpPiece
.block0
    ld      a,[hli]    ; get flag byte
    ld      de,YX
    ld      [de],a     ; include flag byte
    inc     de
    ld      a,[hli]
    ld      [de],a     ; include tile byte
    inc     de
    ld      a,[hli]
    ld      [de],a     ; include block count
    inc     de
    inc     a         ; increment to include rotation pair
    ld      b,a
.lp
    ld      a,[hli]
    ld      [de],a
    inc     de
    ld      a,[hli]
    ld      [de],a
    inc     de
    dec     b
    jr      nz,.lp

    ret



Credits_Init:
    xor     a                   ; Clear VRAM
    ld      hl,$8000
    ld      bc,$2000
    call    mem_Set
    ld      hl,$C000             ; Clear OAM Table
    ld      bc,$00A0
    call    mem_Set

    ld      a,23
    ld      [hli],a
    ld      [hli],a
    ld      [hli],a

    ld      hl,Tiles_Numbers   ; Load Numerical Tiles (Move to masterInit?)
    ld      de,$9300
    ld      bc,$00A0
    call    mem_Copy
    ld      hl,Tiles_Letters
    ld      de,$9410           ; Load Alphabet Tiles
    ld      bc,$01A0
    call    mem_Copy
    ld      hl,Global_TextSymbols
    ld      bc,16*8
    call    mem_Copy         ; Additional Symbols

    ld      hl,Global_Blocks
    ld      de,$8000
    ld      bc,16*16
    call    mem_Copy

    ; load tetris set (all sets?) plus 4 custom sets into easy-to-read format for effect
    ld      hl,ROM_Piece_Sets+1
    ld      de,CR_FullSet

    xor     a
    ldh     [CR_PieceCount],a         ; zero total piece count

    ld      b,4
.lpSet
    push    bc
    ld      a,[hli]            ; get piece count in set
    ld      c,a
.lpPiece
    ld      a,[hli]            ; flags
    ld      [de],a
    inc     de
    ld      a,[hli]
    ld      [de],a             ; tile
    inc     de
    ld      a,[hli]
    ld      [de],a             ; block count
    inc     de
    inc     a                 ; add rot pair
    ld      b,a
.lpBlocks
    ld      a,[hli]
    ld      [de],a
    inc     de
    ld      a,[hli]
    ld      [de],a
    inc     de
    dec     b
    jr      nz,.lpBlocks
    ldh     a,[CR_PieceCount]
    inc     a
    ldh     [CR_PieceCount],a
    dec     c
    jr      nz,.lpPiece
    pop     bc
    inc     hl                ; skip $FE
    dec     b
    jr      nz,.lpSet

    call    Credits_GenerateNewPiece

    xor     a
    ldh     [CR_ScrollChar],a
    ldh     [CR_PieceYidx],a

    ldh     [rSCY],a
    ldh     [rSCX],a
    ld      a,160
    ldh     [CR_PieceX],a
    ld      a,CR_ScrollDelay
    ldh     [CR_ScrollCount],a
    ld      a,$14
    ldh     [CR_VRAMPos],a
    ld      a,$80
    ldh     [CR_NextChar],a

    ld      a,%10000011
    ldh     [rLCDC],a

    ret



Credits_Text:
  db "CODE GRAPHICS SOUND"
  db "DAVE VANEE"
  db "CONCEPT"
  db "DUO"
  db "THANKS"
  db "DUO KOJOTE LORD_NIGH #GAMEBOY"
  
CR_Text:
  db " "
  db "CODEaGRAPHICSaSOUND] TBSP          "
  db "CONCEPT] DUO          "
  db "GREETS GO OUT TO] DUOa BEWAREa KOJOTEa LORD_NIGHa DOXa PH0Xa BIGREDPMPa JOSHUAa LORDGOAT AND EVERYONE ELSE IN ^GAMEBOY ON EFNET          "
  db "THANKS FOR PLAYINGb      ```     "
CR_Text_End:


CR_Sine:
  db 56,59,61,64,67,70,72,75,77,80,82,85,87,89,92,94,96,97,99,101,103,104,105,107,108,109,110,110,111,111,112,112,112,112,112,111,111,110,110,109,108,107,105,104,103,101,99,97,96,94,92,89,87,85,82,80,77,75,72,70,67,64,61,59,56,53,51,48,45,42,40,37,35,32,30,27,25,23,20,18,16,15,13,11,9,8,7,5,4,3,2,2,1,1,0,0,0,0,0,1,1,2,2,3,4,5,7,8,9,11,13,15,16,18,20,23,25,27,30,32,35,37,40,42,45,48,51,53

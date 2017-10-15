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
INCLUDE "engine.inc"

;******************************************************************************
;**                                  Variables                               **
;******************************************************************************

SECTION "Room Hiscores Variables",WRAM0

hiscores_exit:      ds 1


SECTION "Room Hiscores Code/Data",ROM0


Hiscores_Loop:
    call    Hiscores_Input
    call    Hiscores_UpdateSprites
    halt
    nop
    jr      Hiscores_Loop
  
Hiscores_UpdateSprites:
    ld      hl,$C000
    ld      a,$68
    ld      [hli],a
    ld      a,$78
    ld      [hli],a
    xor     a
    ld      [hli],a
    ld      [hli],a

    ld      a,$68
    ld      [hli],a
    ld      a,$89
    ld      [hli],a
    xor     a
    ld      [hli],a
    ld      a,%00100000
    ld      [hli],a
    ret
  
Hiscores_Input:
    ldh     a,[MenuDelay]
    cp      0
    jr      z,.ok
    dec     a
    ldh     [MenuDelay],a
    ret
.ok
    call    ReadJoyPad

    ldh     a,[hPadPressed]
    and     BUTTON_A
    jr      nz,.Button_Pressed
    ldh     a,[hPadPressed]
    and     BUTTON_B
    jr      nz,.Button_Pressed
    ldh     a,[hPadPressed]
    and     BUTTON_START
    jr      nz,.Button_Pressed
    
    ldh     a,[hPadPressed]
    and     BUTTON_LEFT
    jr      nz,.Left_Pressed
    ldh     a,[hPadHeld]
    and     BUTTON_LEFT
    jr      nz,.Left_Pressed

    ldh     a,[hPadPressed]
    and     BUTTON_RIGHT
    jr      nz,.Right_Pressed
    ldh     a,[hPadHeld]
    and     BUTTON_RIGHT
    jr      nz,.Right_Pressed
    ret
.Button_Pressed
    pop     hl
    ret
.Right_Pressed
    ld      hl,FX_menuMove
    call    MS_sfxM2
    ld      a,GUIDelay
    ldh     [MenuDelay],a
    ldh     a,[HI_CurrentSet]
    inc     a
    cp      8
    jr      nz,.RightLeft_step
    xor     a
.RightLeft_step
    ldh     [HI_CurrentSet],a
    ld      a,1
    ldh     [HI_UpdateScores],a
    ret
.Left_Pressed
    ld      hl,FX_menuMove
    call    MS_sfxM2
    ld      a,GUIDelay
    ldh     [MenuDelay],a
    ldh     a,[HI_CurrentSet]
    dec     a
    cp      $FF
    jr      nz,.RightLeft_step
    ld      a,7
    jr      .RightLeft_step



Hiscores_Init:
    xor     a                   ; Clear VRAM
    ld      hl,$8000
    ld      bc,$2000
    call    mem_Set
    ld      hl,$C000             ; Clear OAM Table
    ld      bc,$00A0
    call    mem_Set

    ld      hl,Tiles_Numbers   ; Load Numerical Tiles (Move to masterInit?)
    ld      de,$9000
    ld      bc,$00A0
    call    mem_Copy
    ld      hl,Tiles_Letters
    ld      de,$9410           ; Load Alphabet Tiles
    ld      bc,$01A0
    call    mem_Copy
    ld      hl,Global_TextSymbols
    ld      bc,16*8
    call    mem_Copy         ; Additional Symbols

    ld      hl,PieceEditorUI
    ld      de,$9100
    ld      bc,16*16
    call    mem_Copy

    ld      hl,PE_CursorTiles
    ld      de,$8000
    ld      bc,$0010
    call    mem_Copy

    ld      a,$80                ; 'blank' background  
    ld      hl,$9800
    ld      bc,$0400
    call    mem_Set

    ld      a,$15
    ld      hl,$9840
    ld      bc,20
    call    mem_Set
    ld      a,$14
    ld      hl,$99A0
    ld      bc,20
    call    mem_Set

    ; draw background
    ld      hl,Hiscores_Text
    ld      de,$9820
    ld      bc,20
    call    mem_Copy
    ld      de,$9964
    ld      bc,9
    call    mem_Copy
    ld      de,$9885
    ld      bc,3
    call    mem_Copy
    ld      de,$98C5
    ld      bc,3
    call    mem_Copy
    ld      de,$9905
    ld      bc,3
    call    mem_Copy

    xor     a
    ldh     [HI_CurrentSet],a ; start at set 0 (1)
    inc     a
    ldh     [HI_UpdateScores],a

    ld      a,%10000011
    ldh     [rLCDC],a

    ret



Hiscores_Text:
  db "ADJUSTRIS HIGHSCORES"
  db "PIECE SET"
  db 1,"ST"
  db 2,"ND"
  db 3,"RD"

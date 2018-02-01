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

SECTION "Room Title Code/Data",ROM0

RoomTitle::

    ldh     a,[rLCDC]       ; Turn off screen (for quick loading)
    cp      0
    jr      z,.screenOff
.waitForLY
    ldh     a,[rLY]
    cp      $90
    jr      c,.waitForLY
    xor     a
    ldh     [rLCDC],a
.screenOff

    ld      a,$A8
    ldh     [rWX],a
    xor     a
    ldh     [rSCY],a
    ldh     [rSCX],a
    ldh     [rWY],a
    ldh     [MenuPosition],a
    ld      a,$FF
    ldh     [GameMode],a

    ld      a,$80
    ld      hl,LinesCleared       ; Clear HiScores (to prevent menu artifacts)
    ld      bc,$0012
    call    mem_Set

    xor     a                 ; Clear VRAM
    ld      hl,$8000
    ld      bc,$2000
    call    mem_Set
    ld      hl,$C000
    ld      bc,$00A0
    call    mem_Set          ; Clear OAM Table

    ld      hl,Tiles_Numbers   ; Load Numerical Tiles 
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
    ld      hl,tiles_adjustris_logo
    ld      de,$8800
    ld      bc,16*151
    call    mem_Copy

    ld      hl,PE_CursorTiles
    ld      de,$8000
    ld      bc,$0080
    call    mem_Copy
    ld      hl,PE_Icons
    ld      de,$9210
    ld      bc,$00B0
    call    mem_Copy

    ; Logo Map
    ; pre-wipe
    ld      a,$80
    ld      hl,$9800
    ld      bc,$0234
    call    mem_Set
    ld      hl,mapbank0_adjustris_logo
    ld      de,$9802
    ld      b,18
.Logo_Loop
    push    bc
    ld      bc,16
    call    mem_Copy
    push    hl
    ld      hl,16
    add     hl,de
    ld      d,h
    ld      e,l
    pop     hl
    pop     bc
    dec     b
    jr      nz,.Logo_Loop
  
.lpCopy
    ld      hl,$9C00
    ld      a,$18
    ld      [hli],a
    ld      a,$16
    ld      b,$12
.lpHSb0
    ld      [hli],a
    dec     b
    jr      nz,.lpHSb0
    ld      a,$19
    ld      [hl],a
    ld      a,$14

    ld      hl,$9C20
    ld      b,$10
.lpHSb1
    ld      de,$0013
    ld      [hl],a
    add     hl,de
    inc     a
    ld      [hl],a
    dec     a
    ld      de,$000D
    add     hl,de
    dec     b
    jr      nz,.lpHSb1

    ld      hl,$9E20
    ld      a,$1A
    ld      [hli],a
    ld      a,$17
    ld      b,$12
.lpHSb2
    ld      [hli],a
    dec     b
    jr      nz,.lpHSb2
    ld      a,$1B
    ld      [hl],a
    ld      a,$14

    ld      a,GUIDelay
    ldh     [MenuDelay],a  ; GUI input delay

    xor     a
    ldh     [SelectedSet],a   ; start on set 0 (1)

    xor     a
    ldh     [$0F],a
    ld      a,%11100011
    ldh     [rLCDC],a
    ld      a,%00000001
    ldh     [$FF],a   ; Enable VBlank

.MenuLoop
    call    UpdateMenuCursor
    call    MenuInput
    halt
    nop
    ldh     a,[GameMode]
    cp      $FF
    jr      z,.MenuLoop
    ret


UpdateMenuCursor:
    ld      hl,$C000
    ld      a,$90
    ld      [hli],a
    ld      a,$47
    ld      [hli],a
    xor     a
    ld      [hli],a
    xor     a
    ld      [hli],a

    ld      a,$90
    ld      [hli],a
    ld      a,$A1
    ld      [hli],a
    xor     a
    ld      [hli],a
    ld      a,%00100000
    ld      [hli],a

    ldh     a,[MenuPosition]
    cp      0
    jr      nz,.not_play
    ld      a,$88
    ld      [hli],a
    ld      a,$98
    ld      [hli],a
    ld      a,7
    ld      [hli],a
    xor     a
    ld      [hli],a

    ld      a,$99
    ld      [hli],a
    ld      a,$98
    ld      [hli],a
    ld      a,7
    ld      [hli],a
    ld      a,%01000000
    ld      [hli],a
    ret
  
.not_play
    xor     a
    ld      bc,8
    call    mem_Set

    ret



MenuInput:
    ldh     a,[MenuDelay]
    cp      0
    jr      z,.ok
    dec     a
    ldh     [MenuDelay],a
    ret
.ok
    call    ReadJoyPad
    call    RandomNumber
    
    ldh     a,[hPadPressed]
    and     BUTTON_UP
    jr      nz,.UpPressed
    ldh     a,[hPadHeld]
    and     BUTTON_UP
    jr      nz,.UpPressed

    ldh     a,[hPadPressed]
    and     BUTTON_DOWN
    jr      nz,.DownPressed
    ldh     a,[hPadHeld]
    and     BUTTON_DOWN
    jr      nz,.DownPressed

    ldh     a,[hPadPressed]
    and     BUTTON_LEFT
    jr      nz,.LeftPressed
    ldh     a,[hPadHeld]
    and     BUTTON_LEFT
    jr      nz,.LeftPressed

    ldh     a,[hPadPressed]
    and     BUTTON_RIGHT
    jr      nz,.RightPressed
    ldh     a,[hPadHeld]
    and     BUTTON_RIGHT
    jr      nz,.RightPressed

    ldh     a,[hPadPressed]
    and     BUTTON_A|BUTTON_START
    jr    nz,.ConfirmPressed

    ret  
.LeftPressed
    ld      hl,FX_menuMove
    call    MS_sfxM2
    ld      a,GUIDelay
    ldh     [MenuDelay],a
    ldh     a,[MenuPosition]
    dec     a
    cp      $FF
    jr      nz,.DoneMove
    ld      a,3
.DoneMove
    ldh     [MenuPosition],a
    ret
.RightPressed
    ld      hl,FX_menuMove
    call    MS_sfxM2
    ld      a,GUIDelay
    ldh     [MenuDelay],a
    ldh     a,[MenuPosition]
    inc     a
    cp      4
    jr      nz,.DoneMove
    xor     a
    jr      .DoneMove
.DownPressed
    ldh     a,[MenuPosition]
    cp      0
    jr      nz,.SkipSet
    ld      hl,FX_menuMove     ; different FX?
    call    MS_sfxM2
    ld      a,GUIDelay
    ldh     [MenuDelay],a
    ldh     a,[SelectedSet]
    dec     a
    cp      $FF
    jr      nz,.DoneSet
    ld      a,7
.DoneSet
    ldh     [SelectedSet],a
.SkipSet
    ret
.UpPressed
    ldh     a,[MenuPosition]
    cp      0
    jr      nz,.SkipSet
    ld      hl,FX_menuMove     ; different FX?
    call    MS_sfxM2
    ld      a,GUIDelay
    ldh     [MenuDelay],a
    ldh     a,[SelectedSet]
    inc     a
    cp      8
    jr      nz,.DoneSet
    xor     a
    jr      .DoneSet
.ConfirmPressed
    ld      hl,FX_menuSelect
    call    MS_sfxM2
    ld      a,GUIDelay
    ldh     [MenuDelay],a
    ldh     a,[MenuPosition]
    cp      0
    jr      z,.ConfirmInfinite
    cp      1
    jr      z,.ConfirmPieceEditor
    cp      2
    jr      z,.ConfirmHiScores
    cp      3
    jr      z,.ConfirmCredits
    ;HiScore
    ld      a,$07
    ldh     [rWX],a
    ld      a,%11100001
    ldh     [rLCDC],a
.HiScoreLoop
    ldh     a,[MenuDelay]
    cp      0
    jr      z,.Hiok
    dec     a
    ldh     [MenuDelay],a
    jr      .skip
.Hiok
    call    ReadJoyPad
    ldh     a,[hPadPressed]
    and     BUTTON_B|BUTTON_START
    jr      nz,.HiScoreReturn
.skip
    halt
    nop
    jr      .HiScoreLoop
.HiScoreReturn
    ld      a,$A8
    ldh     [rWX],a  
    ld      a,%11100011
    ldh     [rLCDC],a
.ConfirmDone
    ret  
.ConfirmInfinite
    ldh     [GameMode],a
    jr      .ConfirmDone
.ConfirmPieceEditor
    ldh     [GameMode],a
    jr      .ConfirmDone
.ConfirmHiScores
    ldh     [GameMode],a
    jr      .ConfirmDone
.ConfirmCredits
    ldh     [GameMode],a
    jr      .ConfirmDone



MenuText:
  db "PLAY SET  "
  db "EDIT SETS "
  db "HIGHSCORES"
  db " CREDITS  "

  INCLUDE "adjustris_logo_inverted.z80"

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
INCLUDE "room_game.inc"
INCLUDE "engine.inc"
INCLUDE "joypad.inc"
INCLUDE "room_editor.inc"

;******************************************************************************
;**                                  Variables                               **
;******************************************************************************

SECTION "Room Editor Variables",WRAM0

editor_exit:    ds 1


SECTION "Room Editor Code/Data", ROM0
  
PE_Init:
    xor     a                   ; Clear VRAM
    ld      hl,$8000
    ld      bc,$2000
    call    mem_Set
    ld      hl,$C000             ; Clear OAM Table
    ld      bc,$00A0
    call    mem_Set
    ld      hl,$C400             ; Clear WRAM area used for temp storage
    ld      bc,$0C00
    call    mem_Set

    ld      hl,PieceEditorUI
    ld      de,$9010
    ld      bc,16*21
    call    mem_Copy
    ld      hl,PE_CursorTiles
    ld      de,$8000
    ld      bc,16*7
    call    mem_Copy

    ld      hl,PE_Icons
    ld      de,$8C00
    ld      bc,16*4*9
    call    mem_Copy

    ld      hl,Global_Blocks
    ld      de,$8800
    ld      bc,16*16
    call    mem_Copy

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

    ; object copy of numbers
    ld      hl,Tiles_Numbers   ; Load Numerical Tiles (Move to masterInit?)
    ld      de,$8700
    ld      bc,$00A0
    call    mem_Copy
    ld      hl,Tiles_Letters
    ld      de,$8410           ; Load Alphabet Tiles
    ld      bc,$01A0
    call    mem_Copy

    ld      hl,PieceEditorBGMap
    ld      de,$9820-12
    ld      b,12
.lp
    push    bc
    push    hl
    ld      hl,12
    add     hl,de
    ld      d,h
    ld      e,l
    pop     hl
    ld      bc,20
    call    mem_Copy
    pop     bc
    dec     b
    jr      nz,.lp
    
    ; Instructions
    ld      hl,PE_Instructions
    ld      de,$9A00
    ld      bc,$0014
    call    mem_Copy
    ld      de,$9A20
    ld      bc,$0014
    call    mem_Copy

    ; Purge PE_Set
    xor     a
    ld      hl,PE_Set
    ld      bc,$0E00           ; real max is $DC0, overflow incase
    call    mem_Set

    ; start with set made of a single, empty, piece
    ld      a,1
    ldh     [PE_PieceCount],a
    xor     a
    ldh     [PE_ActivePiece],a
    ldh     [PE_ActiveTile],a
    ld      a,%10100000
    ldh     [PE_ActiveFlags],a
    ld      a,2
    ldh     [PE_ActiveRotY],a
    ldh     [PE_ActiveRotX],a

    xor     a
    ldh     [PE_CursorY],a
    ldh     [PE_CursorX],a

    ldh     [PE_MenuType],a   ; start in main menu (0)
    ldh     [MenuPosition],a

    ld      a,%10000011
    ldh     [rLCDC],a

    ret


PE_Loop:
    call    PE_Input
    call    PE_UpdateSprite
    halt
    nop
    jr      PE_Loop
    ret
  
PE_UpdateSprite:
    xor     a
    ld      hl,$C000
    ld      bc,4*40
    call    mem_Set

    ld      hl,$C000

    ldh     a,[PE_MenuType]
    cp      0
    jr      z,.Main
    cp      1
    jr      z,.Edit
    cp      3
    jr      z,.Tile
    cp      4
    jp      z,.Rotation
    cp      7
    jr      z,.Save
    cp      8
    jr      z,.Load
    cp      9
    jp      z,.Exit
    ret
  
.Main
    ld      a,$5F
    ld      [hli],a
    ldh     a,[MenuPosition]
    add     a,1
    sla     a
    sla     a
    sla     a
    sla     a
    dec     a
    ld      c,a
    ld      [hli],a
    ld      a,3
    ld      [hli],a
    xor     a
    ld      [hli],a

    ld      a,$5F
    ld      [hli],a
    ld      a,c
    add     a,10
    ld      [hli],a
    ld      a,3
    ld      [hli],a
    ld      a,%00100000
    ld      [hli],a

    ld      a,$69
    ld      [hli],a
    ld      a,c
    ld      [hli],a
    ld      a,3
    ld      [hli],a
    ld      a,%01000000
    ld      [hli],a

    ld      a,$69
    ld      [hli],a
    ld      a,c
    add     a,10
    ld      [hli],a
    ld      a,3
    ld      [hli],a
    ld      a,%01100000
    ld      [hli],a

    jp      .shared
  
.Edit
    ; cursor
    ldh     a,[PE_CursorY]
    add     a,PE_EditAreaY        ; Edit Area Offset
    add     a,2                   ; Sprite Y Offset
    sla     a
    sla     a
    sla     a                     ; a*8
    ld      [hli],a
    ldh     a,[PE_CursorX]
    add     a,PE_EditAreaX
    inc     a
    sla     a
    sla     a
    sla     a
    ld      [hli],a
    ld      a,1
    ld      [hli],a
    xor     a
    ld      [hli],a
    jr      .shared
 
.Tile
    ld      a,$50
    ld      [hli],a
    ld      a,$83
    ld      [hli],a
    xor     a
    ld      [hli],a
    ld      [hli],a

    ld      a,$50
    ld      [hli],a
    ld      a,$95
    ld      [hli],a
    xor     a
    ld      [hli],a
    ld      a,%00100000
    ld      [hli],a
    jr      .shared
  
.Save
.Load
    ld      a,$81
    ld      [hli],a
    ld      a,$4C
    ld      [hli],a
    xor     a
    ld      [hli],a
    ld      [hli],a

    ld      a,$81
    ld      [hli],a
    ld      a,$5D
    ld      [hli],a
    xor     a
    ld      [hli],a
    ld      a,%00100000
    ld      [hli],a

    ld      a,$81
    ld      [hli],a
    ld      a,$54
    ld      [hli],a
    ldh     a,[PE_SaveSlot]
    add     a,$75
    ld      [hli],a
    xor     a
    ld      [hli],a
    jr      .shared
  
.Exit
    ld      a,$81
    ld      [hli],a
    ld      a,$4C
    ld      [hli],a
    xor     a
    ld      [hli],a
    ld      [hli],a

    ld      a,$81
    ld      [hli],a
    ld      a,$5D
    ld      [hli],a
    xor     a
    ld      [hli],a
    ld      a,%00100000
    ld      [hli],a

    ld      a,$81
    ld      [hli],a
    ld      a,$54
    ld      [hli],a
    ldh     a,[PE_SaveSlot]
    bit     0,a
    jr      z,.Exit_No
    ld      a,"Y"
    jr      .Exit_Set
.Exit_No
    ld      a,"N"
.Exit_Set
    ld      [hli],a
    xor     a
    ld      [hli],a
    jr      .shared

.shared
.Rotation
    ; rotation centre
    ldh     a,[PE_ActiveRotY]
    add     a,PE_EditAreaY        ; Edit Area Offset
    add     a,2                   ; Sprite Y Offset
    sla     a
    sla     a
    sla     a                      ; a*8
    ld      [hli],a
    ldh     a,[PE_ActiveRotX]
    add     a,PE_EditAreaX
    inc     a
    sla     a
    sla     a
    sla     a
    ld      [hli],a
    ld      a,2
    ld      [hli],a
    xor     a
    ld      [hli],a

    ; rotation type
    ld      a,$40
    ld      [hli],a
    ld      a,$8C
    ld      [hli],a
    ldh     a,[PE_ActiveFlags]
    bit     7,a
    jr      z,.no_rot
    ld      a,6
    jr      .rot_dn
.no_rot
    ld      a,5
.rot_dn
    ld      [hli],a
    ldh     a,[PE_ActiveFlags]
    bit     6,a
    jr      nz,.cw
    ld      a,%00100000
    jr      .rot_dn2
.cw
    xor     a
.rot_dn2
    ld      [hli],a

    ; spin?
    ld      a,$48
    ld      [hli],a
    ld      a,$8C
    ld      [hli],a
    ldh     a,[PE_ActiveFlags]
    bit     5,a
    jr      nz,.spin
    ld      a,5
    jr      .spin_dn
.spin
    ld      a,4
.spin_dn
    ld      [hli],a
    xor     a
    ld      [hli],a

    ; tile
    ld      a,$50
    ld      [hli],a
    ld      a,$8C
    ld      [hli],a
    ldh     a,[PE_ActiveTile]
    add     a,$80
    ld      [hli],a
    xor     a
    ld      [hli],a
    ret
  
PE_Input:
    ldh     a,[MenuDelay]
    cp      0
    jr      z,.ok
    dec     a
    ldh     [MenuDelay],a
    ret
.ok
    call    ReadJoyPad

    ldh     a,[hPadHeld]
    and     BUTTON_SELECT
    jp      nz,.SelectHeld
    
    ldh     a,[hPadPressed]
    and     BUTTON_START
    call    nz,.StartPressed

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
    jp      nz,.LeftPressed
    ldh     a,[hPadHeld]
    and     BUTTON_LEFT
    jp      nz,.LeftPressed

    ldh     a,[hPadPressed]
    and     BUTTON_RIGHT
    jr      nz,.RightPressed
    ldh     a,[hPadHeld]
    and     BUTTON_RIGHT
    jr      nz,.RightPressed
    
    ldh     a,[hPadPressed]
    and     BUTTON_A
    call    nz,.APressed
    ldh     a,[hPadPressed]
    and     BUTTON_B
    call    nz,.BPressed

    ret  
.UpPressed
    ld      a,GUIDelay
    ldh     [MenuDelay],a
    ldh     a,[PE_MenuType]
    cp      1
    jr      z,.Up_Edit
    cp      4
    jr      z,.Up_Rotation
    ret
.Up_Edit
    ldh     a,[PE_CursorY]
    dec     a
    cp      $FF
    jr      nz,.DoneMoveY
    xor     a
.DoneMoveY
    ldh     [PE_CursorY],a
    ret
.Up_Rotation
    ldh     a,[PE_ActiveRotY]
    dec     a
    cp      $FF
    jr      nz,.DoneRotY
    xor     a
.DoneRotY
    ldh     [PE_ActiveRotY],a
    ret
.DownPressed
    ld      a,GUIDelay
    ldh     [MenuDelay],a
    ldh     a,[PE_MenuType]
    cp      1
    jr      z,.Down_Edit
    cp      4
    jr      z,.Down_Rotation
    ret
.Down_Edit
    ldh     a,[PE_CursorY]
    inc     a
    cp      PE_EditAreaHeight
    jr      nz,.DoneMoveY
    ld      a,PE_EditAreaHeight-1
    jr      .DoneMoveY
.Down_Rotation
    ldh     a,[PE_ActiveRotY]
    inc     a
    cp      PE_EditAreaHeight
    jr      nz,.DoneRotY
    ld      a,PE_EditAreaHeight-1
    jr      .DoneRotY
.RightPressed
    ld      a,GUIDelay
    ldh     [MenuDelay],a
    ldh     a,[PE_MenuType]
    cp      0
    jr      z,.Right_Main
    cp      2
    jr      z,.Right_Piece
    cp      3
    jr      z,.Right_Tile
    cp      4
    jr      z,.Right_Rotation
    cp      7
    jr      z,.Right_Save
    cp      8
    jr      z,.Right_Load
    cp      9
    jr      z,.RightLeft_Exit
    ldh     a,[PE_CursorX]
    inc     a
    cp      PE_EditAreaWidth
    jr      nz,.DoneMoveX
    ld      a,PE_EditAreaWidth-1
.DoneMoveX
    ldh     [PE_CursorX],a
    ret
.Right_Save
.Right_Load
    ld      hl,FX_editMove
    call    MS_sfxM2
    ldh     a,[PE_SaveSlot]
    inc     a
    cp      4
    jr      nz,.DoneSaveSlot
    xor     a
.DoneSaveSlot
    ldh     [PE_SaveSlot],a
    ret
.RightLeft_Exit
    ldh     a,[PE_SaveSlot]
    xor     %00000001
    ldh     [PE_SaveSlot],a
    ret
.Right_Rotation
    ldh     a,[PE_ActiveRotX]
    inc     a
    cp      PE_EditAreaWidth
    jr      nz,.DoneRotX
    ld      a,PE_EditAreaWidth-1
.DoneRotX
    ldh     [PE_ActiveRotX],a
    ret
.Right_Main
    ldh     a,[MenuPosition]
    inc     a
    cp      9
    jr      nz,.Right_Main_Step
    xor     a
.Right_Main_Step
    ldh     [MenuPosition],a
    ld      hl,FX_editMove
    call    MS_sfxM2
    ret
.Right_Piece
    ret
.Right_Tile
    ldh     a,[PE_ActiveTile]
    inc     a
    cp      $10
    jr      nz,.DoneTile
    xor     a
    jr      .DoneTile
  
.LeftPressed
    ld      a,GUIDelay
    ldh     [MenuDelay],a
    ldh     a,[PE_MenuType]
    cp      0
    jr      z,.Left_Main
    cp      2
    jr      z,.Left_Piece
    cp      3
    jr      z,.Left_Tile
    cp      4
    jr      z,.Left_Rotation
    cp      7
    jr      z,.Left_Save
    cp      8
    jr      z,.Left_Load
    cp      9
    jr      z,.RightLeft_Exit
    ldh     a,[PE_CursorX]
    dec     a
    cp      $FF
    jr      nz,.DoneMoveX
    xor     a
    jr      .DoneMoveX
.Left_Save
.Left_Load
    ld      hl,FX_editMove
    call    MS_sfxM2
    ldh     a,[PE_SaveSlot]
    dec     a
    cp      $FF
    jr      nz,.DoneSaveSlot
    ld      a,3
    jr      .DoneSaveSlot
.Left_Rotation
    ldh     a,[PE_ActiveRotX]
    dec     a
    cp      $FF
    jr      nz,.DoneRotX
    xor     a
    jr      .DoneRotX
.Left_Main
    ldh     a,[MenuPosition]
    dec     a
    cp      $FF
    jr      nz,.Left_Main_Step
    ld      a,8
.Left_Main_Step
    ldh     [MenuPosition],a
    ld      hl,FX_editMove
    call    MS_sfxM2
    ret
.Left_Piece
    ret
.Left_Tile
    ldh     a,[PE_ActiveTile]
    dec     a
    cp      $FF
    jr      nz,.DoneTile
    ld      a,$0F
.DoneTile
    ldh     [PE_ActiveTile],a
    ; refresh piece display source
    add     a,$80
    ld      c,a
    ld      hl,YX
    ld      b,25
.DoneTile_lp
    ld      a,[hl]
    cp      0
    jr      z,.DoneTile_next
    ld      a,c
    ld      [hl],a
.DoneTile_next
    inc     hl
    dec     b
    jr      nz,.DoneTile_lp
    ld      hl,FX_editMove
    call    MS_sfxM2
    ret

.APressed
    ldh     a,[PE_MenuType]
    cp      0
    jr      z,.A_Main
    cp      1
    jr      z,.A_Edit
    cp      2
    jp      z,.A_Piece
    cp      3
    jp      z,.A_Tile
    cp      4
    jp      z,.A_Rotation
    cp      7
    jp      z,.A_Save
    cp      8
    jp      z,.A_Load
    cp      9
    jp      z,.A_Exit
    ret

.A_Edit
    ; toggle block
    ld      hl,FX_editConfirm
    call    MS_sfxM2
    ldh     a,[PE_CursorY]            ; get Y
    inc     a
    ld      c,a
    ld      a,-5
.lpY
    add     a,5
    dec     c
    jr      nz,.lpY
    ld      c,a
    ldh     a,[PE_CursorX]            ; get X
    add     a,c
    ld      e,a
    ld      d,0
    ld      hl,YX
    add     hl,de
    ld      a,[hl]
    cp      0
    jr      z,.A_set
    xor     a
    jr      .A_done  
.A_set
    ldh     a,[PE_ActiveTile]
    add     a,$80
.A_done
    ld      [hl],a
    jr      .A_done2
  
.A_Main
    ldh     a,[MenuPosition]
    cp      0
    jr      z,.A_Main_Edit
    cp      1
    jr      z,.A_Main_Rotation
    cp      2
    jr      z,.A_Main_RotationDirection
    cp      3
    jr      z,.A_Main_Wobble
    cp      4
    jr      z,.A_Main_Tile
    cp      5
    jr      z,.A_Main_Add
    cp      6
    jp      z,.A_Main_Remove
    cp      7
    jp      z,.A_Main_Save
    cp      8
    jp      z,.A_Main_Load
.A_done2
    ret
  
.A_Main_Edit
    ld      a,1
    ldh     [PE_MenuType],a
    ld      hl,FX_editConfirm
    call    MS_sfxM2
    jr      .A_done2
.A_Main_Rotation
    ld      a,4
    ldh     [PE_MenuType],a
    ld      hl,FX_editConfirm
    call    MS_sfxM2
    ldh     a,[PE_ActiveRotY]
    ldh     [PE_OldRotY],a
    ldh     a,[PE_ActiveRotX]
    ldh     [PE_OldRotX],a
    jr      .A_done2
.A_Main_RotationDirection
    ld      hl,FX_gameRotate
    call    MS_sfxM1
    ldh     a,[PE_ActiveFlags]
    bit     7,a
    jr      z,.A_Main_Rotation_Rot
    bit     6,a
    jr      z,.A_Main_Rotation_Halt
    res     6,a
    jr      .A_Main_Rotation_done
.A_Main_Rotation_Halt
    res     7,a
    jr      .A_Main_Rotation_done
.A_Main_Rotation_Rot
    set     7,a               ; flag as rotating
    set     6,a               ; CW
.A_Main_Rotation_done
    ldh     [PE_ActiveFlags],a
    jr      .A_done2
  
.A_Main_Wobble
    ld      hl,FX_gameRotate
    call    MS_sfxM1
    ldh     a,[PE_ActiveFlags]
    xor     %00100000
    ldh     [PE_ActiveFlags],a
    jr      .A_done2
.A_Main_Tile
    ld      a,3
    ldh     [PE_MenuType],a
    ld      hl,FX_editConfirm
    call    MS_sfxM2
    ldh     a,[PE_ActiveTile]
    ldh     [PE_OldTile],a
    jr      .A_done2
.A_Main_Add
    ldh     a,[PE_PieceCount]
    cp      PE_Max_Pieces
    jr      z,.A_done2             ; max pieces reached
    inc     a
    ldh     [PE_PieceCount],a
    ld      hl,FX_editConfirm
    call    MS_sfxM2
    ; save current, shift existing pieces down
    call    PE_SaveActivePiece
    call    PE_InsertNewPiece

    xor     a                     ; clear new piece
    ld      hl,YX
    ld      bc,25
    call    mem_Set
    ldh     [PE_ActiveTile],a
    ld      a,%10100000
    ldh     [PE_ActiveFlags],a
    ld      a,2
    ldh     [PE_ActiveRotY],a
    ldh     [PE_ActiveRotX],a

    ldh     a,[PE_ActivePiece]    ; step to inserted piece (inserted after current)
    inc     a
    ldh     [PE_ActivePiece],a

    jp      .A_done2
.A_Main_Remove
    ldh     a,[PE_PieceCount]
    dec     a
    cp      0
    jp      z,.A_done2             ; can't have less than 1 piece
    push    af
    call    PE_DeleteCurrentPiece
    pop     af
    ldh     [PE_PieceCount],a     ; don't adjust until after deletion
    ld      hl,FX_editCancel
    call    MS_sfxM2  
    ldh     a,[PE_ActivePiece]    ; change active piece if deleted was the last
    ld      c,a
    ldh     a,[PE_PieceCount]
    cp      c
    jr      nz,.wasnt_last
    dec     a
    ldh     [PE_ActivePiece],a
.wasnt_last
    call    PE_LoadActivePiece

    jp      .A_done2
.A_Main_Save
    ; save set to SRAM
    ; for now just save to first 'slot'
    ; SRAM format:
    ; $FE, -set-
    ; $FE, -set- ... repeat ...
    ; first build up 'sram copy' version in RAM (to get size, and speed up SRAM dump)

    ld      a,7
    ldh     [PE_MenuType],a
    xor     a
    ldh     [PE_SaveSlot],a
    ld      hl,FX_editConfirm
    call    MS_sfxM2
    jp      .A_done2
  
.A_Main_Load
    ld      a,8
    ldh     [PE_MenuType],a
    xor     a
    ldh     [PE_SaveSlot],a
    ld      hl,FX_editConfirm
    call    MS_sfxM2
    jp      .A_done2
  
.A_Piece
    jp      .A_done2

.A_Tile
    xor     a
    ldh     [PE_MenuType],a       ; drop back to main menu
    ld      hl,FX_editConfirm
    call    MS_sfxM2
    jp      .A_done2
  
.A_Rotation
    xor     a
    ldh     [PE_MenuType],a       ; drop back to main menu
    ld      hl,FX_editConfirm
    call    MS_sfxM2
    jp      .A_done2
  
.A_Save
    ; save active piece first
    ld      hl,FX_editConfirm
    call    MS_sfxM2
    call    PE_SaveActivePiece

    ld      de,PE_Set
    ld      hl,PE_TempSet

    ldh     a,[PE_PieceCount]
    ld      [hli],a
    ld      b,a
.A_Save_PLoop
    push    bc
    push    de
    ld      a,[de]
    inc     de
    ld      [hli],a        ; flags
    ld      a,[de]
    inc     de
    ld      [hli],a        ; tile
    push    hl           ; save block count location
    inc     hl
    ld      a,[de]
    inc     de
    ld      [hli],a        ; RotY
    ld      a,[de]
    inc     de
    ld      [hli],a        ; RotX

    xor     a
    ldh     [PE_Temp],a
    ld      b,0
.A_Save_lp1
    ld      c,0
.A_Save_lp0
    ld      a,[de]
    inc     de
    cp      0
    jr      z,.A_Save_next
    ldh     a,[PE_Temp]
    inc     a
    ldh     [PE_Temp],a
    ld      a,b
    ld      [hli],a        ; Y
    ld      a,c
    ld      [hli],a        ; X
.A_Save_next
    inc     c
    ld      a,c
    cp      5
    jr      nz,.A_Save_lp0
    inc     b
    ld      a,b
    cp      5
    jr      nz,.A_Save_lp1

    ldh     a,[PE_Temp]
    cp      0
    jr      nz,.A_Save_AtLeastOne
    ; do something, no blocks in piece!
    ld      a,2
    ld      [hli],a            ; add a block at 2,2
    ld      [hli],a
    ld      a,1
.A_Save_AtLeastOne
    ld      b,h
    ld      c,l
    pop     hl
    ld      [hl],a         ; block count
    ld      h,b
    ld      l,c

    pop     de
    pop     bc
    push    hl
    ld      hl,29
    add     hl,de
    ld      d,h
    ld      e,l
    pop     hl

    dec     b
    jr      nz,.A_Save_PLoop

    ld      a,h
    sub     $D4           ; mem address high byte
    ld      b,a
    ld      c,l            ; length of set in SRAM format (bc)

    di
    ld      a,$0A
    ld      [$00],a        ; enable sram

    ldh     a,[PE_SaveSlot]   ; set # to store as
    ld      d,a
    ld      hl,SavedSets+1 ; skip first $FE
    cp      0

    jr      z,.A_Save_Set0
.A_Save_Seek
    ld      a,[hli]
    cp      $FE
    jr      nz,.A_Save_Seek
    dec     d
    jr      nz,.A_Save_Seek

.A_Save_Set0
    push    hl           ; save destination address (of set being saved)
 
.A_Save_Seek1  ; find following set
    ld      a,[hli]
    cp      $FE
    jr      nz,.A_Save_Seek1
    ld      a,h            ; make negative, store in de
    cpl
    ld      d,a
    ld      a,l
    cpl
    ld      e,a
    inc     de

.A_Save_Seek2  ; find end of sets
    ld      a,[hli]
    cp      $FD
    jr      nz,.A_Save_Seek2
    dec     hl

    ld      a,h
    ldh     [PE_Temp],a
    ld      a,l
    ldh     [PE_Temp+1],a

    add     hl,de         ; length of block to be shifted
    inc     hl            ; offset from $FE stuff... meh
    inc     hl            ; include $FD

    ld      d,h
    ld      e,l
    pop     hl            ; recover start of set being saved address
    push    hl
    push    bc

    add     hl,bc         ; add set being saved length
    add     hl,de         ; add sets being shifted length
    dec     hl            ; drop back to $FD

    ldh     a,[PE_Temp]
    ld      b,a
    ldh     a,[PE_Temp+1]
    ld      c,a

    ; copy 'de' bytes from [bc] to [hl] (backwards)
    inc     d
    inc     e
    jr      .A_Save_Shift_Skip
.A_Save_Shift_Loop
    ld      a,[bc]
    dec     bc
    ld      [hld],a
.A_Save_Shift_Skip
    dec     e
    jr      nz,.A_Save_Shift_Loop
    dec     d
    jr      nz,.A_Save_Shift_Loop

    pop     bc            ; recover length of set being saved
    pop     de            ; recover destination address of start of set being saved
    ld      hl,PE_TempSet
    call    mem_Copy

    xor     a
    ld      [$00],a        ; disable sram
    ei

.A_Save_skip
    xor     a
    ldh     [PE_MenuType],a       ; drop back to main menu

    jp      .A_done2
  
.A_Load
    ; clear PE_Set ram
    ld      hl,FX_editConfirm
    call    MS_sfxM2

    xor     a
    ld      hl,PE_Set
    ld      bc,$0400
    call    mem_Set

    ldh     a,[PE_SaveSlot]       ; slot to load from
    ld      b,a

    di
    ld      a,$0A
    ld      [$00],a                ; activate SRAM

    ld      hl,SavedSets+1
    ld      a,b
    cp      0
    jr      z,.A_Load_Set0
.A_Load_Seek
    ld      a,[hli]
    cp      $FE
    jr      nz,.A_Load_Seek
    dec     b
    jr      nz,.A_Load_Seek
.A_Load_Set0
  
    ld      de,PE_Set
    ld      a,[hli]
    ldh     [PE_PieceCount],a
    ld      b,a
.A_Load_PieceLoop
    push    bc
    ld      a,[hli]
    ld      [de],a     ; flags
    inc     de
    ld      a,[hli]
    ld      [de],a     ; tile
    inc     de
    add     a,$80
    ld      b,a
    ld      a,[hli]
    ld      c,a        ; block count
    ld      a,[hli]
    ld      [de],a     ; RotY
    inc     de
    ld      a,[hli]
    ld      [de],a     ; RotX
    inc     de
  
.A_Load_BlockLoop
    push    de
    ld      a,[hli]
    cp      0
    jr      z,.A_Load_Yzero
    push    hl
    ld      h,d
    ld      l,e
    ld      de,5
.A_Load_Y
    add     hl,de
    dec     a
    jr      nz,.A_Load_Y
    ld      d,h
    ld      e,l
    pop     hl
.A_Load_Yzero
    ld      a,[hli]
    push    hl
    ld      h,0
    ld      l,a
    add     hl,de
    ld      d,h
    ld      e,l
    pop     hl
    ld      a,b
    ld      [de],a     ; set block to tile
    pop     de
    dec     c
    jr      nz,.A_Load_BlockLoop

    push    hl
    ld      hl,25
    add     hl,de
    ld      d,h
    ld      e,l
    pop     hl

    pop     bc
    dec     b
    jr      nz,.A_Load_PieceLoop

    xor     a
    ld      [$00],a            ; disable sram
    ei

    ldh     [PE_ActivePiece],a
    ld      hl,PE_Set
    ld      a,[hli]
    ldh     [PE_ActiveFlags],a
    ld      a,[hli]
    ldh     [PE_ActiveTile],a
    ld      a,[hli]
    ldh     [PE_ActiveRotY],a
    ldh     [PE_OldRotY],a
    ld      a,[hli]
    ldh     [PE_ActiveRotX],a
    ldh     [PE_OldRotX],a

    call    PE_LoadActivePiece

    xor     a
    ldh     [PE_MenuType],a   ; drop back to main
    jp      .A_done2
  
.A_Exit
    ldh     a,[PE_SaveSlot]
    bit     0,a
    jr      nz,.A_Exit_Exit
    xor     a
    ldh     [PE_MenuType],a   ; drop back to main
    ld      hl,FX_editCancel
    call    MS_sfxM2
    jp      .A_done2
.A_Exit_Exit
    ld      hl,FX_editConfirm
    call    MS_sfxM2
    pop     hl
    pop     hl
    ret
  
.BPressed
    ldh     a,[PE_MenuType]
    cp      1
    jr      z,.B_Edit
    cp      3
    jr      z,.B_Tile
    cp      4
    jr      z,.B_Rotation
    cp      7
    jr      z,.B_Save
    cp      8
    jr      z,.B_Load
    cp      9
    jr      z,.B_Exit
.B_done
    ret
.B_Edit
    ld      hl,FX_editCancel
    call    MS_sfxM2
    xor     a
    ldh     [PE_MenuType],a       ; drop back to main
    jr      .B_done
.B_Tile
    ld      hl,FX_editCancel
    call    MS_sfxM2
    xor     a
    ldh     [PE_MenuType],a       ; drop back to main
    ldh     a,[PE_OldTile]
    ldh     [PE_ActiveTile],a
    add     a,$80
    ld      c,a
    ld      hl,YX
    ld      b,25
.B_Tile_lp
    ld      a,[hl]
    cp      0
    jr      z,.B_Tile_next
    ld      a,c
    ld      [hl],a
.B_Tile_next
    inc     hl
    dec     b
    jr      nz,.B_Tile_lp
    jr      .B_done
.B_Rotation
    ld      hl,FX_editCancel
    call    MS_sfxM2
    xor     a
    ldh     [PE_MenuType],a
    ldh     a,[PE_OldRotY]
    ldh     [PE_ActiveRotY],a
    ldh     a,[PE_OldRotX]
    ldh     [PE_ActiveRotX],a
    jr      .B_done
.B_Save
    ld      hl,FX_editCancel
    call    MS_sfxM2
    xor     a
    ldh     [PE_MenuType],a       ; drop back to main
    jr      .B_done
.B_Load
    ld      hl,FX_editCancel
    call    MS_sfxM2
    xor     a
    ldh     [PE_MenuType],a       ; drop back to main
    jr      .B_done
.B_Exit
    ld      hl,FX_editCancel
    call    MS_sfxM2
    xor     a
    ldh     [PE_MenuType],a       ; drop back to main
    jr      .B_done
  
.SelectHeld
    ld      a,GUIDelay
    ldh     [MenuDelay],a
    
    ldh		a,[hPadPressed]
    and		a,BUTTON_LEFT
    jr  	nz,.Select_Left
    ldh		a,[hPadHeld]
    and		a,BUTTON_LEFT
    jr  	nz,.Select_Left

    ldh		a,[hPadPressed]
    and		a,BUTTON_RIGHT
    jr  	nz,.Select_Right
    ldh		a,[hPadHeld]
    and		a,BUTTON_RIGHT
    jr  	nz,.Select_Right

    ; clear left/right presses/holds
    ldh     a,[hPadPressed]
    res     4,a
    res     5,a
    ldh     [hPadPressed],a
    ldh     a,[hPadHeld]
    res     4,a
    res     5,a
    ldh     [hPadHeld],a
    
.Select_done
    ret
.Select_Left
    call    PE_SaveActivePiece

    ldh     a,[PE_ActivePiece]
    dec     a
    cp      $FF
    jr      nz,.Select_Left_step
    ldh     a,[PE_PieceCount]
    dec     a
.Select_Left_step
    ldh     [PE_ActivePiece],a
    ld      hl,FX_editMove
    call    MS_sfxM2
    call    PE_LoadActivePiece
    ret
  
.Select_Right
    call    PE_SaveActivePiece

    ldh     a,[PE_ActivePiece]
    inc     a
    ld      c,a
    ldh     a,[PE_PieceCount]
    cp      c
    ld      a,c
    jr      nz,.Select_Right_step
    xor     a
.Select_Right_step
    ldh     [PE_ActivePiece],a
    ld      hl,FX_editMove
    call    MS_sfxM2
    call    PE_LoadActivePiece
    ret
  
.StartPressed
    ldh     a,[PE_MenuType]
    cp      9
    jp      z,.StartPressed_Confirm
    ld      a,9
    ldh     [PE_MenuType],a
    xor     a                 ; default to no
    ldh     [PE_SaveSlot],a
    ld      hl,FX_editConfirm
    call    MS_sfxM2 
    ret
.StartPressed_Confirm
    jp      .A_Exit
  
PE_SaveActivePiece:
    ld      hl,PE_Set-29
    ld      de,29              ; (flags, tile, rotY, rotX, 25 blocks)
    ldh     a,[PE_ActivePiece]
    inc     a
    ld      b,a
.lpOffset
    add     hl,de
    dec     b
    jr      nz,.lpOffset
    ldh     a,[PE_ActiveFlags]
    ld      [hli],a
    ldh     a,[PE_ActiveTile]
    ld      [hli],a
    ldh     a,[PE_ActiveRotY]
    ld      [hli],a
    ldh     a,[PE_ActiveRotX]
    ld      [hli],a
    ld      d,h
    ld      e,l
    ld      bc,25
    ld      hl,YX
    call    mem_Copy
    ret
  
PE_LoadActivePiece:
    ld      hl,PE_Set-29
    ld      de,29
    ldh     a,[PE_ActivePiece]
    inc     a
    ld      b,a
.lpOffset
    add     hl,de
    dec     b
    jr      nz,.lpOffset
    ld      a,[hli]
    ldh     [PE_ActiveFlags],a
    ld      a,[hli]
    ldh     [PE_ActiveTile],a
    ld      a,[hli]
    ldh     [PE_ActiveRotY],a
    ld      a,[hli]
    ldh     [PE_ActiveRotX],a
    ld      de,YX
    ld      bc,25
    call    mem_Copy
    ret
  
PE_InsertNewPiece:
    ldh     a,[PE_ActivePiece]
    inc     a
    ld      c,a
    ldh     a,[PE_PieceCount]
    ld      b,a
    cp      c
    jr      z,.last_piece
    sub     c
    ld      c,a                ; number of pieces to be shifted

    push    bc
    ld      hl,PE_Set
    ld      de,29
.lpOffset
    add     hl,de
    dec     b
    jr      nz,.lpOffset
    dec     hl                ; source
    push    hl
    add     hl,de
    ld      d,h                ; destination
    ld      e,l
    pop     hl
    pop     bc
    
.lpCopyPiece
    ld      b,29
.lpCopyByte
    ld      a,[hld]
    ld      [de],a
    dec     de
    dec     b
    jr      nz,.lpCopyByte
    dec     c
    jr      nz,.lpCopyPiece
  
.last_piece             ; at last piece, no need to initialize ram
    ret
  
PE_DeleteCurrentPiece:
    ldh     a,[PE_ActivePiece]
    inc     a
    ld      c,a
    ldh     a,[PE_PieceCount]
    cp      c
    jr      z,.last_piece
    sub     c
    ld      b,a

    ld      hl,PE_Set-29
    ld      de,29
.lpOffset
    add     hl,de
    dec     c
    jr      nz,.lpOffset
    ld      d,h
    ld      e,l
    push    de               ; save destination
    ld      de,29
    add     hl,de
    pop     de
  
.lpCopyPiece
    ld      c,29
.lpCopyByte
    ld      a,[hli]
    ld      [de],a
    inc     de
    dec     c
    jr      nz,.lpCopyByte
    dec     b
    jr      nz,.lpCopyPiece
  
.last_piece             ; to delete the last piece we just ignore it
    ret
  
PE_ExtractPiece:
    ; ignore a for now (set #), use once sets are stored/indexed properly
    ld      hl,Active_Piece_Set
    ld      a,b                ; get piece number
    inc     hl                ; skip piece count
    cp      0
    jr      z,.first_piece
.lpPieces
    inc     hl                ; skip flags
    inc     hl                ; skip tile #
    ld      a,[hli]            ; get block count
    inc     hl
    inc     hl                ; skip rot pair
    ld      c,a
.lpBlocks
    inc     hl
    inc     hl
    dec     c
    jr      nz,.lpBlocks
    dec     b
    jr      nz,.lpPieces
.first_piece
    ld      a,[hli]            ; read flags
    ldh     [PE_ActiveFlags],a
    ld      a,[hli]            ; read tile #
    ldh     [PE_ActiveTile],a
    ld      a,[hli]            ; read # of blocks
    ld      b,a
    ld      a,[hli]            ; read rotation Y
    ldh     [PE_ActiveRotY],a
    ld      a,[hli]            ; read rotation X
    ldh     [PE_ActiveRotX],a
.lp
    ld      a,[hli]            ; get Y
    inc     a
    ld      c,a
    ld      a,-5
.lpY
    add     a,5
    dec     c
    jr      nz,.lpY
    ld      c,a
    ld      a,[hli]
    add     a,c
    ld      e,a
    ld      d,0
    push    hl
    ld      hl,YX
    add     hl,de
    ld      a,$80                ; use some sort of base offset, pair a tile to each piece type?
    ld      [hl],a
    pop     hl
    dec     b
    jr      nz,.lp
    ret


CopyPieceSet:
    ld      de,Active_Piece_Set
    cp      ROM_Set_Count
    push    af
    jr      nc,.SRAM_Set
    ; ROM Set
    ld      hl,ROM_Piece_Sets
    jr      .copy_set
.SRAM_Set
    sub     ROM_Set_Count
    ld      hl,SavedSets
    push    af
    di
    ld      a,$0A
    ld      [$00],a   ; activate SRAM
    pop     af
.copy_set
    inc     hl        ; skip first header byte
    ld      c,a
    cp      0
    jr      z,.Set0
    ; loop through pieces/blocks of every set to reach target set
.lpSetsF
    ld      a,[hli]
    cp      $FE
    jr      nz,.lpSetsF
    dec     c
    jr      nz,.lpSetsF
.Set0
    ld      a,[hli]
    ld      [de],a     ; copy # of pieces
    inc     de
    ldh         [PiecesInActiveSet],a
    ld      b,a
.lpPieces
    push    bc
    ld      a,[hli]
    ld      [de],a     ; copy flags
    inc     de
    ld      a,[hli]
    ld      [de],a     ; copy tile type
    inc     de
    ld      a,[hli]
    ld      [de],a     ; copy piece count
    inc     de
    ld      b,a
    ld      a,[hli]
    ld      [de],a     ; copy Y of rotation point
    inc     de
    ld      a,[hli]
    ld      [de],a     ; copy X of rotation point
    inc     de
.lpBlocks
    ld      a,[hli]
    ld      [de],a     ; copy Y of block
    inc     de
    ld      a,[hli]
    ld      [de],a     ; copy X of block
    inc     de
    dec     b
    jr      nz,.lpBlocks
    pop     bc
    dec     b
    jr      nz,.lpPieces

    pop     af
    cp      ROM_Set_Count      ; needed again?
    jr      nc,.SRAM_Stop
    ret
.SRAM_Stop
    xor     a
    ld      [$00],a
    ei
    ret








Null_Piece_Set:
    db $FE,1
    
    db %10000000, 0, 1, 2,2, 2,2




ROM_Piece_Sets::
    ;   Bit 7: Rotate?
    ;   Bit 6: Counter-Clockwise? (CW if unset)
    ;   Bit 5: Spin? (just toggles back/forth if unset)
    ;   Bit 1-4: Block count in piece
    
    db $FE
    db 7                            ; number of pieces
    
    db %01000000, 0, 4, 0,0, 0,0,1,0,0,1,1,1  
    db %11000000, 1, 4, 0,1, 0,0,0,1,0,2,0,3  
    db %10000000, 2, 4, 0,1, 0,0,0,1,1,1,1,2  
    db %11000000, 3, 4, 0,1, 0,2,0,1,1,1,1,0    ; ?? (not a rotation)  
    db %10100000, 4, 4, 0,1, 0,0,0,1,0,2,1,0 
    db %10100000, 5, 4, 0,1, 0,0,0,1,0,2,1,2   
    db %10100000, 6, 4, 0,1, 0,0,0,1,0,2,1,1 

;ROM_Pentris_Piece_Set:
    db $FE
    db 16
    
    db %10000000, 0, 5, 0,2, 0,0,0,1,0,2,0,3,0,4
    db %10100000, 1, 5, 0,1, 0,0,0,1,0,2,0,3,1,0
    db %10100000, 2, 5, 1,1, 0,0,1,0,1,1,1,2,1,3
    db %10100000, 3, 5, 0,1, 0,0,0,1,0,2,0,3,1,1
    db %10100000, 4, 5, 0,1, 0,1,1,0,1,1,1,2,1,3
    db %10100000, 5, 5, 1,1, 0,0,0,1,1,1,1,2,2,2
    db %10100000, 6, 5, 1,1, 0,2,1,2,1,1,1,0,2,0
    db %10100000, 7, 5, 1,1, 0,0,0,1,1,0,1,1,1,2
    db %10100000, 8, 5, 0,1, 0,0,0,1,0,2,1,0,1,1
    db %10100000, 9, 5, 1,1, 0,0,0,1,0,2,1,1,2,1
    db %10100000, 10, 5, 1,1, 0,1,1,0,1,1,1,2,2,0
    db %10100000, 11, 5, 1,1, 0,0,1,0,1,1,1,2,2,1
    db %10100000, 12, 5, 1,1, 0,1,1,0,1,1,1,2,2,1
    db %10100000, 13, 5, 1,1, 0,2,1,2,1,1,2,1,2,0
    db %10100000, 14, 5, 1,1, 0,0,0,1,1,1,1,2,2,2
    db %10100000, 15, 5, 1,1, 0,2,1,2,2,2,2,1,2,0

    db $FE
    
    db 5
    
    db %10100000, 15, 3, 0,2, 0,0,0,1,0,3
    db %10100000, 14, 3, 0,0, 0,0,0,1,1,0
    db %10100000, 13, 3, 0,1, 0,0,0,1,1,2
    db %10100000, 12, 3, 0,1, 0,1,0,2,1,0
    db %10100000, 11, 3, 0,1, 0,0,1,1,0,2
    
    db $FE
    
    ; really hard set to play...
    
    db 12
    
    db %10100000, 0, 4, 0,1, 0,1,0,2,0,3,1,0
    db %10100000, 1, 4, 0,2, 0,0,0,1,0,2,1,3
    db %10100000, 2, 4, 0,1, 0,0,1,1,0,2,0,3
    db %10100000, 3, 4, 0,2, 0,0,0,1,1,2,0,3
    db %10100000, 4, 4, 1,1, 0,0,1,0,2,1,1,2
    db %10100000, 5, 4, 1,1, 1,0,2,1,1,2,0,2
    db %10100000, 6, 4, 0,1, 0,0,1,0,1,1,0,2
    db %10100000, 7, 4, 0,1, 0,0,1,1,1,2,0,2
    
    db %10100000, 8, 4, 1,1, 1,0,1,1,2,1,0,2
    db %10100000, 9, 4, 1,1, 0,0,1,1,2,1,1,2
    db %10000000,10, 4, 1,1, 0,1,1,1,2,0,3,0
    db %10000000,11, 4, 1,0, 0,0,1,0,2,1,3,1



PE_Prompts:
  db "    EDIT PIECE    "
  db "CENTER OF ROTATION"
  db "ROTATION DIRECTION"
  db "  SPIN OR WOBBLE  "
  db "   CHANGE TILE    "
  db "   INSERT PIECE   "
  db "   DELETE PIECE   "
  db "     SAVE SET     "
  db "     LOAD SET     "

PE_ExitPrompt:
  db " EXIT SET EDITOR  "
  
PE_Instructions:
  db "SELECT] CHANGE PIECE"
  db " START] EXIT        "

PieceEditorBGMap:
  ;db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
  db 0,0,0,0,"P","I","E","C","E",0,"E","D","I","T","O","R",0,0,0,0
  db 6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6
  db 0,9,13,13,13,13,13,10,1,5,5,5,5,5,5,5,5,5,2,0
  db 0,15,0,0,0,0,0,16,7,"P","I","E","C","E","S",0,0,0,8,0
  db 0,15,0,0,0,0,0,16,7,"A","C","T","I","V","E",0,0,0,8,0
  db 0,15,0,0,0,0,0,16,7,"R","O","T","A","T","E",0,0,0,8,0
  db 0,15,0,0,0,0,0,16,7,"S","P","I","N",0,0,0,0,0,8,0
  db 0,15,0,0,0,0,0,16,7,"T","I","L","E",0,0,0,0,0,8,0
  db 0,11,14,14,14,14,14,12,3,6,6,6,6,6,6,6,6,6,4,0
  db 0,$C0,$C2,$C4,$C6,$C8,$CA,$CC,$CE,$D0,$D2,$D4,$D6,$D8,$DA,$DC,$DE,$E0,$E2,0
  db 0,$C1,$C3,$C5,$C7,$C9,$CB,$CD,$CF,$D1,$D3,$D5,$D7,$D9,$DB,$DD,$DF,$E1,$E3,0
  db 5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5
  ;db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
  ;db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
  ;db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
  ;db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
  ;db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0


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

INCLUDE "engine.inc"
INCLUDE "gbhw.inc"
INCLUDE "joypad.inc"
INCLUDE "room_game.inc"

INCLUDE "debug.inc"

;******************************************************************************
;**                                  Variables                               **
;******************************************************************************

SECTION "Room Game Variables",WRAM0

game_exit:      ds 1


;******************************************************************************
;**                                    Data                                  **
;*****************************************************************************

SECTION "Room Game Code/Data", ROM0

BACKGROUND_TILES:
    INCBIN  "background.bin"

SPRITE_TILES:
    INCBIN  "sprites.bin"

;******************************************************************************
;**                                    Code                                  **
;*****************************************************************************

; ===== Game Loop =====
RoomGame::
    call    AlterPiece       ; Input and Movement
    call    DropPiece        ; Automatic Movement
    call    GameLogic        ; Score Additions, GameMode Completion Checks
    call    UpdateSprite     ; Sprite Updates
    call    RandomNumber

    ldh     a,[FrameCounter]
    inc     a
    cp      60
    jr      nz,.NoReset
    xor     a
.NoReset
    ldh     [FrameCounter],a

    halt                  ; Wait for VBlank Interrupt
    nop
    jr      RoomGame
    
    
GameInit:
    xor     a                   ; Clear VRAM
    ld      hl,$8000
    ld      bc,$2000
    call    mem_Set
    ld      hl,$C000
    ld      bc,$00A0
    call    mem_Set
    ld      hl,$C0A3
    ld      bc,$0F5D
    call    mem_Set

    ld      hl,PieceEditorUI
    ld      de,$9010
    ld      bc,16*21
    call    mem_Copy

    ld      hl,Global_Blocks
    ld      de,$8800
    ld      bc,16*16
    call    mem_Copy
    ld      hl,Global_Blocks
    ld      de,$8000
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
    ldh     a,[SelectedSet]
    call    CopyPieceSet

    ld      hl,LinesCleared  ; Initialize HiScores
    call    ResetHiScore
    ld      hl,BlocksUsed
    call    ResetHiScore
    ld      hl,TargetLines
    call    ResetHiScore
    ld      hl,CurrentScore
    call    ResetHiScore
    ld      hl,LinesToLvl
    call    ResetHiScore
    ld      hl,Level
    call    ResetHiScore

    ld      hl,TargetLines
    ld      bc,LineLimitGoal
    call    AddBCHiScore
    ld      hl,LinesToLvl   ; 10 Lines per level
    ld      bc,LevelIncrement
    call    AddBCHiScore
    ld      hl,Level
    ld      bc,$0001
    call    AddBCHiScore

    ld      a,StartDropSpeed
    ldh     [DropSet],a
    ldh     [DropCounter],a
    ld      a,40
    ldh     [ClearDelay],a
    xor     a
    ldh     [NextPiece],a  ; Make random later...or something
    xor     a
    ldh     [UpdateHalf],a
    ldh     [LineCount],a
    ldh     [BlockCount],a
    ldh     [TileUpdate],a
    ldh     [BlocksInLastPiece],a

    call    RandomNumber
    call    RandomNumber

    ; Draw Basic Screen Layout
    ld      hl,$9801           ; side walls
    ld      de,$0020
    ld      a,$0F
    ld      b,$12
.bglp0
    ld      [hl],a
    add     hl,de
    dec     b
    jr      nz,.bglp0
    ld      hl,$980C
    ld      de,$0020
    ld      a,$10
    ld      b,$12
.bglp1
    ld      [hl],a
    add     hl,de
    dec     b
    jr      nz,.bglp1

    ld      hl,$980D           ; next piece box
    ld      de,$001A
    ld      [hl],1
    inc     hl
    ld      a,5
    ld      b,5
.bglp2
    ld      [hli],a
    dec     b
    jr      nz,.bglp2
    ld      [hl],2
    add     hl,de
    ld      b,5
.bglp3
    ld      [hl],7
    inc     hl
    inc     hl
    inc     hl
    inc     hl
    inc     hl
    inc     hl
    ld      [hl],8  
    add     hl,de
    dec     b
    jr      nz,.bglp3
    ld      [hl],3
    inc     hl
    ld      a,6
    ld      b,5
.bglp4
    ld      [hli],a
    dec     b
    jr      nz,.bglp4
    ld      [hl],4

    ; score/lines/level boxes
    ld      hl,$98ED
    ld      de,$0020
    ld      a,1
    ld      [hl],a
    add     hl,de  
    ld      a,7
    ld      [hl],a
    add     hl,de
    ld      [hl],a
    add     hl,de
    ld      a,$13
    ld      [hl],a
    add     hl,de
    ld      a,7
    ld      [hl],a
    add     hl,de
    ld      [hl],a
    add     hl,de
    ld      a,$13
    ld      [hl],a
    add     hl,de
    ld      a,7
    ld      [hl],a
    add     hl,de
    ld      [hl],a
    add     hl,de
    ld      a,3
    ld      [hl],a

    ld      hl,$98F3
    ld      a,2
    ld      [hl],a
    add     hl,de
    ld      a,8
    ld      [hl],a
    add     hl,de
    ld      [hl],a
    add     hl,de
    ld      a,$14
    ld      [hl],a
    add     hl,de
    ld      a,8
    ld      [hl],a
    add     hl,de
    ld      [hl],a
    add     hl,de
    ld      a,$14
    ld      [hl],a
    add     hl,de
    ld      a,8
    ld      [hl],a
    add     hl,de
    ld      [hl],a
    add     hl,de
    ld      a,4
    ld      [hl],a

    ld      hl,$98EE
    ld      a,5
    ld      bc,5
    call    mem_Set
    ld      hl,$994E
    ld      a,$15
    ld      bc,5
    call    mem_Set
    ld      hl,$99AE
    ld      bc,5
    call    mem_Set
    ld      hl,$9A0E
    ld      a,6
    ld      bc,5
    call    mem_Set


    ; Score/Lines/Level
    ld      hl,Gameplay_Text
    ld      de,$990E
    ld      bc,5
    call    mem_Copy
    ld      de,$996E
    ld      bc,5
    call    mem_Copy
    ld      de,$99CE
    ld      bc,5
    call    mem_Copy

    ; Draw Window Map
    ld      a,1
    ld      hl,$9C42
    ld      [hli],a
    ld      a,5
    ld      bc,15
    call    mem_Set
    ld      a,2
    ld      [hl],a

    ld      a,3
    ld      hl,$9DA2
    ld      [hli],a
    ld      a,6
    ld      bc,15
    call    mem_Set
    ld      a,4
    ld      [hl],a

    ld      a,7
    ld      hl,$9C62
    ld      de,$20
    ld      b,10
.win0lp
    ld      [hl],a
    add     hl,de
    dec     b
    jr      nz,.win0lp

    inc     a
    ld      hl,$9C72
    ld      b,10
.win1lp
    ld      [hl],a
    add     hl,de
    dec     b
    jr      nz,.win1lp

    ld      hl,PauseText
    ld      de,$9C87
    ld      bc,6
    call    mem_Copy
    ld      de,$9CE5
    ld      bc,11
    call    mem_Copy
    ld      de,$9D05
    ld      bc,11
    call    mem_Copy
    ld      de,$9D44
    ld      bc,13
    call    mem_Copy
    ld      de,$9D67
    ld      bc,7
    call    mem_Copy

    call    GenerateBlock
    call    GenerateBlock
    call    GenerateNextBlockMap

    ld      a,%00000001
    ldh     [$FF],a   ; Enable VBlank Interrupt

    ld      a,%11100011
    ldh     [rLCDC],a		; Turn on LCD

    ret


  
AlterPiece:
    call    ReadJoyPad
    call    RandomNumber

    ldh     a,[hPadPressed]
    and     BUTTON_DOWN
    call    nz,.DownPressed
    ldh     a,[hPadHeld]
    and     BUTTON_DOWN
    call    nz,.DownHeld

    ldh     a,[hPadPressed]
    and     BUTTON_LEFT
    call    nz,.LeftPressed
    ldh     a,[hPadHeld]
    and     BUTTON_LEFT
    call    nz,.LeftHeld

    ldh     a,[hPadPressed]
    and     BUTTON_RIGHT
    call    nz,.RightPressed
    ldh     a,[hPadHeld]
    and     BUTTON_RIGHT
    call    nz,.RightHeld

    ldh     a,[hPadPressed]
    and     BUTTON_A
    jp      nz,.APressed
    ldh     a,[hPadPressed]
    and     BUTTON_B
    jp      nz,.BPressed

    ldh     a,[hPadPressed]
    and     BUTTON_START
    jr      nz,.StartPressed

    ret
.StartPressed
    ld      a,%11100001  ; kill sprites
    ldh     [rLCDC],a
    ld      a,GUIDelay
    ldh     [MenuDelay],a
    ld      a,7
    ldh     [rWX],a
.StartWait
    ldh     a,[MenuDelay]
    cp      0
    jr      z,.Startok
    dec     a
    ldh     [MenuDelay],a
    jr      .skip
.Startok
    call    ReadJoyPad
    
    ldh     a,[hPadPressed]
    and     BUTTON_START
    jr      nz,.StartOut
    ldh     a,[hPadPressed]
    and     BUTTON_SELECT
    jr      nz,.GiveUp

.skip
    halt
    nop
    jr      .StartWait
.StartOut
    ld      a,%00000001
    ldh     [$FF],a
    ld      a,%11100011
    ldh     [rLCDC],a
    ld      a,$A7
    ldh     [rWX],a
    ret
.GiveUp
    ;pop     hl
    pop     hl
    ret
.DownPressed
    push    af
    ld      a,1
.DownMove  
    ldh     [DHCount],a
    ld      b,1
    ld      c,0
    call    GenerateBlockPhantom
    call    TestBlockPhantom
    cp      0
    jr      nz,.dnmv
    call    ConfirmBlockPhantom
    ld      hl,FX_gameMove
    call    MS_sfxM2
    pop     af
    ret
.DownHeld
    push    af
    ldh     a,[DHCount]
    dec     a
    ldh     [DHCount],a
    jr      nz,.dnmv
    ld      a,1
    ldh     [DHCount],a
.RushDrop
    ldh     a,[DropCounter]
    cp      3
    jr      c,.dnmv
    ld      a,3
    ldh     [DropCounter],a
    jr      .dnmv
.RightPressed
    push    af
    ld      a,HoldPause
.RightMove
    ldh     [RHCount],a
    ld      b,0
    ld      c,1
    call    GenerateBlockPhantom
    call    TestBlockPhantom
    cp      0
    jr      nz,.dnmv
    call    ConfirmBlockPhantom
    ld      hl,FX_gameMove
    call    MS_sfxM2
.dnmv
    pop     af
    ret
.RightHeld
    push    af
    ldh     a,[RHCount]
    dec     a
    ldh     [RHCount],a
    jr      nz,.dnmv
    ld      a,HoldDelay
    jr      .RightMove
.LeftPressed
    push    af
    ld      a,HoldPause
.LeftMove
    ldh     [LHCount],a
    ld      b,0
    ld      c,255
    call    GenerateBlockPhantom
    call    TestBlockPhantom
    cp      0
    jr      nz,.dnmv
    call    ConfirmBlockPhantom
    ld      hl,FX_gameMove
    call    MS_sfxM2
    pop     af
    ret
.LeftHeld
    push    af
    ldh     a,[LHCount]
    dec     a
    ldh     [LHCount],a
    jr      nz,.dnmv
    ld      a,HoldDelay
    jr      .LeftMove
.BPressed
    push    af
    ld      bc,$0000
    call    GenerateBlockPhantom
    ld      c,0    ; normal
    call    RotateBlockPhantom
    call    TestBlockPhantom
    cp      0
    jr      nz,.dnmv
.cbrok
    call    ConfirmBlockPhantom
    ld      hl,FX_gameRotate
    call    MS_sfxM1
    pop     af
    ret
.APressed
    push    af
    ld      bc,$0000
    call    GenerateBlockPhantom
    ld      c,1    ; opposite
    call    RotateBlockPhantom
    call    TestBlockPhantom
    cp      0
    jp      nz,.dnmv
.cblok
    call    ConfirmBlockPhantom
    ld      hl,FX_gameRotate
    call    MS_sfxM1
    pop     af
    ret




UpdateSprite:
    ld      hl,$C000
    ld      de,YX+1
    ld      a,[de]         ; get tile #
    ld      c,a
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
    add     a,$10
    ld      [hli],a
    ld      a,[de]
    inc     de
    add     a,a
    add     a,a
    add     a,a
    add     a,$18
    ld      [hli],a
    ld      a,c
    ld      [hli],a
    ld      a,$85
    ld      [hli],a
    dec     b
    jr      nz,.lp
    ret




UpdateTiles:
    ldh     a,[UpdateHalf]
    inc     a
    ldh     [UpdateHalf],a
    bit     0,a
    jr      nz,.Bottom
    ; Top
    ld      hl,$9802
    ld      de,Grid           ; 3
    jr      .past
.Bottom
    ld      hl,$9922
    ld      de,Grid+9*10      ; 3
    xor     a
    ldh     [TileUpdate],a
.past
    ; 9 loops
    ld bc,$0016          ; x

    ld a,[de]            ; 2
    inc e                ; 2
    ld [hli],a           ; 2
    ld a,[de]            ; 2
    inc e                ; 1
    ld [hli],a           ; 2
    ld a,[de]            ; 2
    inc e                ; 1
    ld [hli],a           ; 2
    ld a,[de]            ; 2
    inc e                ; 1
    ld [hli],a           ; 2
    ld a,[de]            ; 2
    inc e                ; 1
    ld [hli],a           ; 2
    ld a,[de]            ; 2
    inc e                ; 1
    ld [hli],a           ; 2
    ld a,[de]            ; 2
    inc e                ; 1
    ld [hli],a           ; 2
    ld a,[de]            ; 2
    inc e                ; 1
    ld [hli],a           ; 2
    ld a,[de]            ; 2
    inc e                ; 1
    ld [hli],a           ; 2
    ld a,[de]            ; 2
    inc e                ; 1
    ld [hli],a           ; 2
    add hl,bc

    ld a,[de]            ; 2
    inc e                ; 2
    ld [hli],a           ; 2
    ld a,[de]            ; 2
    inc e                ; 1
    ld [hli],a           ; 2
    ld a,[de]            ; 2
    inc e                ; 1
    ld [hli],a           ; 2
    ld a,[de]            ; 2
    inc e                ; 1
    ld [hli],a           ; 2
    ld a,[de]            ; 2
    inc e                ; 1
    ld [hli],a           ; 2
    ld a,[de]            ; 2
    inc e                ; 1
    ld [hli],a           ; 2
    ld a,[de]            ; 2
    inc e                ; 1
    ld [hli],a           ; 2
    ld a,[de]            ; 2
    inc e                ; 1
    ld [hli],a           ; 2
    ld a,[de]            ; 2
    inc e                ; 1
    ld [hli],a           ; 2
    ld a,[de]            ; 2
    inc e                ; 1
    ld [hli],a           ; 2
    add hl,bc

    ld a,[de]            ; 2
    inc e                ; 2
    ld [hli],a           ; 2
    ld a,[de]            ; 2
    inc e                ; 1
    ld [hli],a           ; 2
    ld a,[de]            ; 2
    inc e                ; 1
    ld [hli],a           ; 2
    ld a,[de]            ; 2
    inc e                ; 1
    ld [hli],a           ; 2
    ld a,[de]            ; 2
    inc e                ; 1
    ld [hli],a           ; 2
    ld a,[de]            ; 2
    inc e                ; 1
    ld [hli],a           ; 2
    ld a,[de]            ; 2
    inc e                ; 1
    ld [hli],a           ; 2
    ld a,[de]            ; 2
    inc e                ; 1
    ld [hli],a           ; 2
    ld a,[de]            ; 2
    inc e                ; 1
    ld [hli],a           ; 2
    ld a,[de]            ; 2
    inc e                ; 1
    ld [hli],a           ; 2
    add hl,bc

    ld a,[de]            ; 2
    inc e                ; 2
    ld [hli],a           ; 2
    ld a,[de]            ; 2
    inc e                ; 1
    ld [hli],a           ; 2
    ld a,[de]            ; 2
    inc e                ; 1
    ld [hli],a           ; 2
    ld a,[de]            ; 2
    inc e                ; 1
    ld [hli],a           ; 2
    ld a,[de]            ; 2
    inc e                ; 1
    ld [hli],a           ; 2
    ld a,[de]            ; 2
    inc e                ; 1
    ld [hli],a           ; 2
    ld a,[de]            ; 2
    inc e                ; 1
    ld [hli],a           ; 2
    ld a,[de]            ; 2
    inc e                ; 1
    ld [hli],a           ; 2
    ld a,[de]            ; 2
    inc e                ; 1
    ld [hli],a           ; 2
    ld a,[de]            ; 2
    inc e                ; 1
    ld [hli],a           ; 2
    add hl,bc

    ld a,[de]            ; 2
    inc e                ; 2
    ld [hli],a           ; 2
    ld a,[de]            ; 2
    inc e                ; 1
    ld [hli],a           ; 2
    ld a,[de]            ; 2
    inc e                ; 1
    ld [hli],a           ; 2
    ld a,[de]            ; 2
    inc e                ; 1
    ld [hli],a           ; 2
    ld a,[de]            ; 2
    inc e                ; 1
    ld [hli],a           ; 2
    ld a,[de]            ; 2
    inc e                ; 1
    ld [hli],a           ; 2
    ld a,[de]            ; 2
    inc e                ; 1
    ld [hli],a           ; 2
    ld a,[de]            ; 2
    inc e                ; 1
    ld [hli],a           ; 2
    ld a,[de]            ; 2
    inc e                ; 1
    ld [hli],a           ; 2
    ld a,[de]            ; 2
    inc e                ; 1
    ld [hli],a           ; 2
    add hl,bc

    ld a,[de]            ; 2
    inc e                ; 2
    ld [hli],a           ; 2
    ld a,[de]            ; 2
    inc e                ; 1
    ld [hli],a           ; 2
    ld a,[de]            ; 2
    inc e                ; 1
    ld [hli],a           ; 2
    ld a,[de]            ; 2
    inc e                ; 1
    ld [hli],a           ; 2
    ld a,[de]            ; 2
    inc e                ; 1
    ld [hli],a           ; 2
    ld a,[de]            ; 2
    inc e                ; 1
    ld [hli],a           ; 2
    ld a,[de]            ; 2
    inc e                ; 1
    ld [hli],a           ; 2
    ld a,[de]            ; 2
    inc e                ; 1
    ld [hli],a           ; 2
    ld a,[de]            ; 2
    inc e                ; 1
    ld [hli],a           ; 2
    ld a,[de]            ; 2
    inc e                ; 1
    ld [hli],a           ; 2
    add hl,bc

    ld a,[de]            ; 2
    inc e                ; 2
    ld [hli],a           ; 2
    ld a,[de]            ; 2
    inc e                ; 1
    ld [hli],a           ; 2
    ld a,[de]            ; 2
    inc e                ; 1
    ld [hli],a           ; 2
    ld a,[de]            ; 2
    inc e                ; 1
    ld [hli],a           ; 2
    ld a,[de]            ; 2
    inc e                ; 1
    ld [hli],a           ; 2
    ld a,[de]            ; 2
    inc e                ; 1
    ld [hli],a           ; 2
    ld a,[de]            ; 2
    inc e                ; 1
    ld [hli],a           ; 2
    ld a,[de]            ; 2
    inc e                ; 1
    ld [hli],a           ; 2
    ld a,[de]            ; 2
    inc e                ; 1
    ld [hli],a           ; 2
    ld a,[de]            ; 2
    inc e                ; 1
    ld [hli],a           ; 2
    add hl,bc

    ld a,[de]            ; 2
    inc e                ; 2
    ld [hli],a           ; 2
    ld a,[de]            ; 2
    inc e                ; 1
    ld [hli],a           ; 2
    ld a,[de]            ; 2
    inc e                ; 1
    ld [hli],a           ; 2
    ld a,[de]            ; 2
    inc e                ; 1
    ld [hli],a           ; 2
    ld a,[de]            ; 2
    inc e                ; 1
    ld [hli],a           ; 2
    ld a,[de]            ; 2
    inc e                ; 1
    ld [hli],a           ; 2
    ld a,[de]            ; 2
    inc e                ; 1
    ld [hli],a           ; 2
    ld a,[de]            ; 2
    inc e                ; 1
    ld [hli],a           ; 2
    ld a,[de]            ; 2
    inc e                ; 1
    ld [hli],a           ; 2
    ld a,[de]            ; 2
    inc e                ; 1
    ld [hli],a           ; 2
    add hl,bc

    ld a,[de]            ; 2
    inc e                ; 2
    ld [hli],a           ; 2
    ld a,[de]            ; 2
    inc e                ; 1
    ld [hli],a           ; 2
    ld a,[de]            ; 2
    inc e                ; 1
    ld [hli],a           ; 2
    ld a,[de]            ; 2
    inc e                ; 1
    ld [hli],a           ; 2
    ld a,[de]            ; 2
    inc e                ; 1
    ld [hli],a           ; 2
    ld a,[de]            ; 2
    inc e                ; 1
    ld [hli],a           ; 2
    ld a,[de]            ; 2
    inc e                ; 1
    ld [hli],a           ; 2
    ld a,[de]            ; 2
    inc e                ; 1
    ld [hli],a           ; 2
    ld a,[de]            ; 2
    inc e                ; 1
    ld [hli],a           ; 2
    ld a,[de]            ; 2
    inc e                ; 1
    ld [hli],a           ; 2
    ret



UpdateScoreTiles:
    ldh     a,[GameMode]
    cp      $F0
    ret     nc                ; modes over $F0 have no score displayed
    ld      hl,$998E          ; 3
    ld      de,LinesCleared+1   ; 3
    ld      b,5               ; 2
.lpS0
    ld      a,[de]            ; 2 (*6)
    add     a,$30            ; 2 (*6)
    inc     de               ; 2 (*6)
    ld      [hli],a           ; 2 (*6)
    dec     b                ; 1 (*6)
    jr      nz,.lpS0          ; 3 (3*5+2)
                         ; = XX clocks
    ld      de,CurrentScore+1   ; 3
    ld      hl,$992E          ; 3
    ld      b,5               ; 2
.lpS1
    ld      a,[de]            ; 2
    add     a,$30            ; 2
    inc     de               ; 2
    ld      [hli],a           ; 2
    dec     b                ; 1
    jr      nz,.lpS1          ; 3
                       ; = 79 clocks
    ld      hl,$99F1
    ld      de,Level+4
    ld      a,[de]
    add     a,$30
    ld      [hli],a
    inc     de
    ld      a,[de]
    add     a,$30
    ld      [hl],a
    ret


GameLogic:
    ldh     a,[GameMode]
    cp      0
    jr      z,.Infinite
    ret
.Infinite
    ldh     a,[LineCount]
    ; new math (just cases)
    cp      0
    jr      z,.Inf0
    cp      1
    jr      z,.Inf1
    cp      2
    jr      z,.Inf2
    cp      3
    jr      z,.Inf3
    cp      4
    jr      z,.Inf4
    ;5
    ld      hl,2000
    jr      .InfGS
.Inf4
    ld      hl,1200
    jr      .InfGS
.Inf3
    ld      hl,600
    jr      .InfGS
.Inf2
    ld      hl,200
    jr      .InfGS
.Inf1
    ld      hl,80
    jr      .InfGS
.Inf0
    ld      hl,0
.InfGS 
    ldh     a,[BlocksInLastPiece]
    add     a,l
    ld      b,h
    ld      c,a
    ld      hl,CurrentScore
    call    AddBCHiScore

    ldh     a,[LineCount]
    cp      0
    jr      z,.InfiniteBlocks
    ld      hl,LinesCleared
    ld      b,0
    ld      c,a
    call    AddBCHiScore
    ld      a,b
    ldh     [LineCount],a
.InfiniteBlocks
    ldh     a,[BlockCount]
    cp      0
    jr      z,.InfiniteDone
    ld      hl,BlocksUsed
    ld      b,0
    ld      c,a
    call    AddBCHiScore
    ld      hl,LinesCleared
    ld      de,LinesToLvl
    call    CpHiScore
    jr      c,.InfNoLevelUp
    ld      hl,LinesToLvl
    ld      bc,LevelIncrement
    call    AddBCHiScore
    ld      hl,FX_gamelaser
    call    MS_sfxM1
    ld      hl,Level
    ld      bc,$0001
    call    AddBCHiScore
    ldh     a,[DropSet]
    cp      MinDropSpeed
    jr      z,.InfNoLevelUp
    dec     a
    dec     a
    dec     a
    ldh     [DropSet],a
.InfNoLevelUp
    ld      a,b
    ldh     [BlockCount],a
    ldh     [BlocksInLastPiece],a
.InfiniteDone
    ret
.LineLimit
    ldh     a,[LineCount]
    cp      0
    jr      z,.LineLimitBlocks
    ld      hl,LinesCleared
    ld      b,0
    ld      c,a
    call    AddBCHiScore
    ld      a,b
    ldh     [LineCount],a
    ld      hl,LinesCleared
    ld      de,TargetLines
    call    CpHiScore
    jr      c,.LineLimitBlocks
    ld      a,1
    ldh     [BeatMode],a
    pop     hl
    ret
.LineLimitBlocks
    ldh     a,[BlockCount]
    cp      0
    jr      z,.LineLimitDone
    ld      hl,BlocksUsed
    ld      b,0
    ld      c,a
    call    AddBCHiScore
    ld      hl,LinesCleared
    ld      de,LinesToLvl
    call    CpHiScore
    jr      c,.LineLimitNoLevelUp
    ld      hl,LinesToLvl
    ld      bc,LevelIncrement
    call    AddBCHiScore
    ld      hl,Level
    ld      bc,$0001
    call    AddBCHiScore
    ldh     a,[DropSet]
    cp      MinDropSpeed
    jr      z,.LineLimitNoLevelUp
    dec     a
    dec     a
    dec     a
    ldh     [DropSet],a
.LineLimitNoLevelUp
    ld      a,b
    ldh     [BlockCount],a
.LineLimitDone
    ret


CalcSetChecksum:
    cp      ROM_Set_Count
    push    af
    jr      nc,.SRAM_Set
    ;       ROM Set
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
    ; at the start of the set
    ld      d,0            ; clear checksum
    ld      a,[hli]
    ld      b,a
    add     a,d
    ld      d,a            ; include block count
.lpPieces
    push    bc
    ld      a,[hli]        ; include flags
    add     a,d
    ld      d,a
    inc     hl            ; skip tile type
    ld      a,[hli]        ; include block count
    ld      b,a
    add     a,d
    ld      d,a
    ld      a,[hli]        ; include RotY
    add     a,d
    ld      d,a
    ld      a,[hli]        ; include RotX
    add     a,d
    ld      d,a
.lpBlocks
    ld      a,[hli]        ; include Y
    add     a,d
    ld      d,a
    ld      a,[hli]        ; include X
    add     a,d
    ld      d,a
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

    ; d = checksum on return
    ret


HiScoreHandler:
    ; Infinite
    ; offset to hiscore set of interest
    ld      hl,SavedScores-19
    ld      de,19
    ldh     a,[SelectedSet]
    inc     a
.lpOffset
    add     hl,de
    dec     a
    jr      nz,.lpOffset

    ; calculate set checksum
    push    hl
    ldh     a,[SelectedSet]
    Call    CalcSetChecksum
    pop     hl

    di
    ld      a,$0A
    ld      [$00],a            ; enable sram

    ld      a,[hl]
    cp      d
    jr      z,.SetUnchanged
    ; set has been modified, clear old scores
    ld      [hl],d
    push    hl
    inc     hl
    ld      a,$80
    ld      bc,18
    call    mem_Set          ; initialize highscores for set
    pop     hl
.SetUnchanged
    inc     hl

    xor     a
    ld      [$00],a            ; disable sram
    ei

    ld      a,2
    ld      de,TempScore
    push    hl
    call    ReadHiScore
    ld      hl,TempScore
    ld      de,CurrentScore
    call    CpHiScore
    jr      nc,.InfEx1Higher
    ld      a,1
    ld      de,TempScore
    pop     hl
    push    hl
    call    ReadHiScore
    ld      hl,TempScore
    ld      de,CurrentScore
    call    CpHiScore
    jr      nc,.NotThatHigh2
.k
    xor     a
    ld      de,TempScore
    pop     hl
    push    hl
    call    ReadHiScore
    ld      hl,TempScore
    ld      de,CurrentScore
    call    CpHiScore
    jr      nc,.NotThatHigh1
.l
    ; 1st
    ld      a,1
    ld      de,TempScore
    pop     hl
    push    hl
    push    de
    call    ReadHiScore      ; read score 1
    pop     de
    ld      a,2
    pop     hl
    push    hl
    push    de
    call    SaveHiScore      ; save as score 2
    pop     de
    xor     a
    pop     hl
    push    hl
    push    de
    call    ReadHiScore      ; read score 0
    pop     de
    ld      a,1
    pop     hl
    push    hl
    call    SaveHiScore      ; save as score 1
    xor     a
    pop     hl
    push    hl
    jr      .ji
.NotThatHigh1
    ; 2nd
    ld      a,1
    ld      de,TempScore
    pop     hl
    push    hl
    push    de
    call    ReadHiScore      ; read score 1
    pop     de
    ld      a,2
    pop     hl
    push    hl
    call    SaveHiScore      ; save as score 2
    ld      a,1
    pop     hl
    push    hl
    jr      .ji
.NotThatHigh2
    ; 3rd
    ld      a,2
.ji
    ld      de,CurrentScore
    pop     hl
    call    SaveHiScore
    push    hl
.InfEx1Higher
    pop     hl
    ret



FillGrid:
    xor     a
    ld      hl,$C000
    ld      bc,$0020
    call    mem_Set

    ld      hl,Grid
    ld      d,$12
.lpWipe
    push    de
    ld      a,$12
    ld      bc,$000A
    call    mem_Set
    ld      a,1
    ldh     [TileUpdate],a
    halt
    nop
    halt
    nop
    pop     de
    dec     d
    jr      nz,.lpWipe
    ret


ClearLines:
    ld      hl,Grid+10*17
    ld      c,$12
.Blp0
    push    hl
    ld      b,$0A
.Blp1
    ld      a,[hli]
    cp      0
    jr      z,.BNextLine
    dec     b
    jr      nz,.Blp1
    dec     hl
    ld      d,h
    ld      e,l
    ld      hl,FX_gameID
    call    MS_sfxM1
    pop     hl
    push    hl
    push    bc
    ld      a,$11
    ld      b,$0A
.BFillLine
    ld      [hli],a
    dec     b
    jr      nz,.BFillLine
    ldh     a,[GameMode]
    ldh     [temp],a
    ld      a,$FE
    ldh     [GameMode],a
    ld      a,1
    ldh     [TileUpdate],a
    ldh     a,[ClearDelay]
    ld      b,a
.BVBL
    halt
    nop
    dec     b
    jr      nz,.BVBL
    ldh     a,[temp]
    ldh     [GameMode],a
    ld      a,1
    ldh     [TileUpdate],a
    pop     bc
    pop     hl
    push    hl
    dec     hl
    push    bc
    dec     c
.BDropBlock
    ld      b,$0A
.BDropLine
    ld      a,[hld]
    ld      [de],a
    dec     de
    dec     b
    jr      nz,.BDropLine
    dec     c
    jr      nz,.BDropBlock
    xor     a
    inc     hl
    ld      b,$0A
.BClearLine  
    ld      [hli],a
    dec     b
    jr      nz,.BClearLine
    push    hl
    ldh     a,[LineCount]
    inc     a
    ldh     [LineCount],a
    ld      hl,$C010           ; clear OAM... alter to be block count dynamic
    ld      bc,$10
    xor     a
    call    mem_Set
    pop     hl
    pop     bc
    pop     hl
    inc     c
    jr      .BNoPop
.BNextLine
    pop     hl
    ld      de,$FFF6       ; -10
    add     hl,de
.BNoPop
    dec     c
    jr      nz,.Blp0
    ret

DropPiece:
    ldh     a,[DropCounter]
    dec     a
    ldh     [DropCounter],a
    cp      0
    ret     nz
    ldh     a,[DropSet]
    DBGMSG  "Read DropSet as: %a%"
    ldh     [DropCounter],a

    ld      hl,MoveArray+2
    ld      a,[hli]
    ld      b,a
    ld      a,[hl]
    ld      c,a
    call    GenerateBlockPhantom
    call    TestBlockPhantom
    cp      0
    jr      z,.drop
    ld      hl,FX_gameBomb
    call    MS_sfxM4
    call    UpdateSprite          ; Ensure proper cover sprite location
    ld      a,[BlockCount]
    inc     a
    ldh     [BlockCount],a
    ld      a,1
    ldh     [TileUpdate],a
    ld      a,[YX+2]                   ; skip flags and tile
    ldh     [BlocksInLastPiece],a     ; store # of blocks for scoring
    call    FreezeBlock

    ld      a,$FF           ; block (greatly delay) dropping after a piece is frozen
    ldh     [DHCount],a

    halt
    nop
    halt
    nop
    xor a
    ld      hl,$C000
    ld      bc,25*4
    call    mem_Set
    call    ClearLines
    call    GenerateBlock         ; Next Block
    call    GenerateNextBlockMap
    ld      bc,$00
    call    GenerateBlockPhantom
    call    TestBlockPhantom
    jr      z,.NoEndGame            ; Start space is blocked
    pop     hl                     ; Clear Stack
.NoEndGame  
    ret
.drop
    call    ConfirmBlockPhantom
    ret




UpdateNextPiece:
    ldh     a,[GameMode]
    cp      $FF
    ret     z
    ld      hl,NextBlockMap
    ld      de,$982E
    ld      bc,5
    call    mem_Copy
    ld      de,$984E
    ld      bc,5
    call    mem_Copy
    ld      de,$986E
    ld      bc,5
    call    mem_Copy
    ld      de,$988E
    ld      bc,5
    call    mem_Copy
    ld      de,$98AE
    ld      bc,5
    call    mem_Copy
    ret                  ; 4

GenerateNextBlockMap:
    ; clear current map
    xor     a
    ld      hl,NextBlockMap
    ld      bc,25
    call    mem_Set

    ld      hl,Active_Piece_Set+1      ; skip piece count
    ldh     a,[NextPiece]
    cp      0
    jr      z,.block0
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
    inc     hl        ; skip flag byte
    ld      a,[hli]
    add     a,$80
    ld      c,a        ; store tile byte
    ld      a,[hli]
    ld      b,a        ; store block count
    inc     hl        ; skip rotation pair
    inc     hl
  
    ld      de,NextBlockMap
.BlockLoop
    push    de
    ld      a,[hli]
    cp      0
    jr      z,.Yzero
    push    hl
    ld      h,d
    ld      l,e
    ld      de,5
.Y
    add     hl,de
    dec     a
    jr      nz,.Y
    ld      d,h
    ld      e,l
    pop     hl
.Yzero
    ld      a,[hli]
    push    hl
    ld      h,0
    ld      l,a
    add     hl,de
    ld      d,h
    ld      e,l
    pop     hl
    ld      a,c
    ld      [de],a     ; set block to tile
    pop     de
    dec     b
    jr      nz,.BlockLoop

    ret
  
  
GenerateBlock:
    ldh     a,[NextPiece]
    ldh     [BlockType],a
.TryAgain
    ; get next piece
    call    RandomNumber
    ld      c,a
    ld      a,[Active_Piece_Set]   ; get # of pieces in set
    cp      1
    jr      z,.single_piece_set
    ld      e,a
    call    Unsigned_Multiply
    ld      a,h                    ; only use high byte
    jr      .GotShape
.single_piece_set
    xor     a
.GotShape
    ldh     [NextPiece],a
    ld      hl,Active_Piece_Set
    inc     hl        ; skip piece count
    ldh     a,[BlockType]
    cp      0
    jr      z,.block0
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
    add     3         ; calc X offset?
    ld      [de],a
    inc     de
    dec     b
    jr      nz,.lp
    xor     a
    ldh     [BlockRotate],a
.noLoop
    ret

; Input: B=dY, C=dX
GenerateBlockPhantom:
    ld      hl,YX+2        ; skip flags and tile type
    ld      de,YXt
    ld      a,b
    ldh     [temp],a
    ld      a,[hli]        ; get block count
    inc     a             ; include rotation pair
    ld      b,a
.lp
    push    bc
    ldh     a,[temp]
    ld      b,a

    ld      a,[hli]
    add     a,b
    ld      [de],a
    inc     de
    ld      a,[hli]
    add     a,c
    ld      [de],a
    inc     de

    pop     bc
    dec     b
    jr      nz,.lp
    ret

TestBlockPhantom:
    ld      a,[YX+2]         ; get block count
    ld      d,a
    ld      hl,YXt+2       ; skip testing of rotation pair
.lp
    ld      a,[hli]
    cp      18
    ret     z
    ld      b,a
    ld      a,[hli]
    cp      Width
    ret     z
    cp      255
    ret     z
    ld      c,a
    push    hl
    push    de
    call    TestYX
    pop     de
    pop     hl
    cp      0
    ret     nz
    dec     d
    jr      nz,.lp
    ret

ConfirmBlockPhantom:
    ld      hl,YX+2            ; skip flags and tile type
    ld      de,YXt
    ld      a,[hli]
    inc     a                 ; include block phantom
    sla     a                 ; a*2
    ld      b,a
.lp
    ld      a,[de]
    inc     de
    ld      [hli],a
    dec     b
    jr      nz,.lp
    ret

FreezeBlock:
    ld      hl,YX+2
    ld      a,[hli]
    inc     hl
    inc     hl                ; skip rot pair
    ld      d,a
.lp
    ld      a,[hli]
    ld      b,a
    ld      a,[hli]
    ld      c,a
    push    hl
    push    de
    call    SetYX
    pop     de
    pop     hl
    dec     d
    jr      nz,.lp
    ret

RotateBlockPhantom:
    ; for CW rotations:
    ; y2=(x1-x0)+y0
    ; x2=-(y1-y0)+x0

    ; setup x0,y0 pivot in de
    ld      hl,YXt
    ld      a,[hli]
    ld      d,a        ; get y0
    ld      a,[hli]
    ld      e,a        ; get x0

    ; adjust for bits
    ld      a,[YX]     ; get flags byte
    bit     7,a
    ret     z         ; return if flagged not to rotate
    bit     5,a
    jr      nz,.spin
    bit     4,a
    jr      z,.not_done_yet
    res     4,a
    ld      [YX],a     ; store spin flag
    bit     6,a
    jr      z,.cw
    jr      .ccw
.not_done_yet
    set     4,a
    ld      [YX],a     ; store spin flag
    bit     6,a
    jr      z,.ccw
    jr      .cw
.spin
    bit     6,a
    jr      z,.ccw
.cw
    ld      a,c
    cp      0
    jr      nz,.ccw1
.cw1
    ld      a,[YX+2]   ; get block count
    ld      b,a
.lpcw
    ld      a,[hli]    ; get y1
    sub     d         ; -y0
    sub     e         ; -x0
    cpl           ; invert
    inc     a
    ldh     [temp],a  ; store x2 for a bit
    ld      a,[hl]     ; get x1
    ld      c,a        ; store x1 for a bit
    ldh     a,[temp]
    ld      [hld],a    ; save x2
    ld      a,c        ; get x1 back
    sub     e         ; -x0
    add     d         ; +y0
    ld      [hli],a    ; save y2
    inc     hl        ; skip x
    dec     b
    jr      nz,.lpcw
    ret
.ccw
    ld      a,c
    cp      0
    jr      nz,.cw1
.ccw1
    ld      a,[YX+2]   ; get block count
    ld      b,a
.lpccw
    ld      a,[hli]    ; get y1
    sub     d         ; -y0
    add     e         ; +x0
    ldh     [temp],a  ; store x2 for a bit
    ld      a,[hl]     ; get x1
    ld      c,a        ; store x1 for a bit
    ldh     a,[temp]
    ld      [hld],a    ; save x2
    ld      a,c        ; get x1 back
    cpl           ; invert
    inc     a
    add     e         ; +x0
    add     d         ; +y0
    ld      [hli],a    ; save y2
    inc     hl        ; skip x
    dec     b
    jr      nz,.lpccw
    ret

; Input:  B=Y, C=X
; Output: A=0 or 1
TestYX:
    ld      hl,Grid
    ld      de,Width
    inc     b
.lp0
    dec     b
    jr      z,.X
    add     hl,de
    jr      .lp0
.X
    ld      e,c
    add     hl,de
    ld      a,[hl]
    ret

SetYX:
    ld      hl,Grid
    ld      de,Width
    inc     b
.lp0
    dec     b
    jr      z,.X
    add     hl,de
    jr      .lp0
.X
    ld      e,c
    add     hl,de
    ld      a,[YX+1]
    set     7,a       ; use $80 base tiles
    ld      [hl],a
    ret




MoveArray:
  db 0,1,1,0,0,$FF,$FF,0,0,1,1,0


Gameplay_Text:
  db "SCORE"
  db "LINES"
  db "LEVEL"

PauseText:
  db "PAUSED"
  db "PRESS START"
  db "TO CONTINUE"
  db "PRESS  SELECT"
  db "TO QUIT"

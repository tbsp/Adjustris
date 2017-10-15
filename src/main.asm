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
INCLUDE "room_editor.inc"
INCLUDE "gbhw.inc"

;******************************************************************************
;**                                  Variables                               **
;******************************************************************************

SECTION "General HiRAM",HRAM

;Keys        = $90
;g_anButtons = $91 ; 8 bytes
;g_nPadData  = $99
TileUpdate::    ds 1
UpdateHalf::    ds 1
GameMode::      ds 1
FrameCounter::  ds 1
MenuPosition::  ds 1
BeatMode::      ds 1
SystemType::    ds 1  ; 0 = DMG, 1 = CGB
MenuDelay::     ds 1
SelectedSet::   ds 1


SECTION "General Variables",WRAM0

Seed:		    ds 3
LinesCleared:   ds 6
CurrentScore:   ds 6
Clock:          ds 6
BlocksUsed:     ds 6
LinesToLvl:     ds 6
TempScore:      ds 6
TargetLines:    ds 6
Level:          ds 6

BorderTiles:    ds 20

SECTION "GRID",WRAM0[$C200]
Grid:           ds $100 ; to $C3FF (16x16, $100)

SECTION "Active_Piece_Set",WRAM0[$C400]
Active_Piece_Set: ds $400 ; Variable size (used to store currently used set of pieces)

SECTION "YX",WRAM0[$C800]
YX:               ds $100 ; YX of active piece

SECTION "YXt",WRAM0[$C900]
YXt:              ds $100 ; YX of test piece (during rotations/movement)

SECTION "NextBlock",WRAM0[$CA00]
NextBlockMap:     ds 25 ; 25 bytes

SECTION "CR_Full",WRAM0[$CB00]
CR_FullSet:       ds $400 ; could be huge

SECTION "PE_Set",WRAM0[$D000]
PE_Set:           ds $03A1 ; piece editor set, max size of 929 ($03A1), 32 pieces

SECTION "PE_TempSet",WRAM0[$D400]
PE_TempSet:       ds $400 ; pre-generated copy of SRAM set (before saving)


;******************************************************************************
;**                                   Saving                                 **
;******************************************************************************

SECTION "Saved Data",SRAM

SaveID:         ds 4    ; 4 Bytes
SavedScores:    ds 152  ; 152 Bytes (6 digits, 3 scores, 8 sets (1 Checksum per set)) - 4 ROM, 4 SRAM
;SavedSets       = $A09C ; Variable and large ($6E1 per set (32 pieces, 5x5 filled pieces))
SavedSets:      ds 7049
    
; SavedSets format:
; FE (1) to indicate new saved set
; PieceCount (1)
; Per piece:
;  flags (1)
;  tile (1)
;  block count (1)
;  rotY (1)
;  rotX (1)
;  Per block:
;    x (1)
;    y (1)

; FD (1) to indicate end of data

; Max set size: 1 + 1 + 32 * (5 + 2 * 5 * 5) = 1762
; 4 saved sets: 4 * 1762 + 1 = 7049 = $1B89



SECTION "Main", ROM0

;******************************************************************************
;**                                  Main Loop                               **
;******************************************************************************

Main::

MainLoop:
    call    RoomTitle

    ; turn off LCD
    call    waitvbl
    xor     a
    ldh     [rLCDC],a

    ldh     a,[GameMode]
    cp      0
    jr      z,.GamePlay
    cp      1
    jr      z,.PieceEditor
    cp      2
    jr      z,.HiScores
    cp      3
    jr      z,.Credits

    ld      a,1
    ldh     [rLCDC],a

.Returned_From_Mode
    xor     a
    ldh     [GameMode],a
    jr      MainLoop

  
.GamePlay
    call    GameInit
    call    RoomGame

    ld      hl,FX_statsLongExplode
    call    MS_sfxM4

    call    FillGrid
    call    HiScoreHandler

    jr      .Returned_From_Mode
  
.PieceEditor
    call    PE_Init
    call    PE_Loop
    jr      .Returned_From_Mode

.HiScores
    call    Hiscores_Init
    call    Hiscores_Loop
    jr      .Returned_From_Mode

.Credits
    call    Credits_Init
    call    Credits_Loop
    jr      .Returned_From_Mode



vblank:
    push    af
    push    hl
    push    bc
    push    de
    call    $FF80
    ldh     a,[GameMode]
    cp      1
    jp      z,.PE_VBlank
    cp      $FF
    jr      z,.Menu_VBlank
    cp      2
    jr      z,.Hiscores_VBlank
    cp      3
    jp      z,.Credits_VBlank
    ldh     a,[TileUpdate]
    cp      0
    jr      z,.done
    call    UpdateTiles
    jr      .done_VBlank
.done
    ldh     a,[FrameCounter]
    and     1
    cp      0
    jr      nz,.second
    call    UpdateScoreTiles
    jr      .done_VBlank
.second
    call    UpdateNextPiece
;.NoScore
.done_VBlank
    pop     de
    pop     bc
    pop     hl
    pop     af
    reti

.Menu_VBlank
    ldh     a,[MenuPosition]
    inc     a
    ld      hl,MenuText-10
    ld      de,10
.Menu_V_lp
    add     hl,de
    dec     a
    jr      nz,.Menu_V_lp
    ld      de,$9A09
    ld      bc,10
    call    mem_Copy

    ldh     a,[MenuPosition]
    cp      0
    jr      nz,.Menu_V_NotPlay
    ld      hl,$9A12
    ldh     a,[SelectedSet]
    add     a,$31
    ld      [hl],a
.Menu_V_NotPlay
    jr      .done_VBlank

.Hiscores_VBlank
    ldh     a,[HI_UpdateScores]
    cp      0
    jr      z,.Hiscores_V_done
    xor     a
    ldh     [HI_UpdateScores],a

    ldh     a,[HI_CurrentSet]
    inc     a
    ld      hl,SavedScores-19
    ld      de,19
.Hiscores_V_offset
    add     hl,de
    dec     a
    jr      nz,.Hiscores_V_offset
    inc     hl            ; skip checksum

    ld      a,$0A
    ld      [$00],a        ; enable sram

    ld      de,$9889
    ld      bc,6
    call    mem_Copy
    ld      de,$98C9
    ld      bc,6
    call    mem_Copy
    ld      de,$9909
    ld      bc,6
    call    mem_Copy

    xor     a
    ld      [$00],a        ; disable sram

    ldh     a,[HI_CurrentSet]
    inc     a
    ld      hl,$996F
    ld      [hl],a

.Hiscores_V_done
    jr      .done_VBlank

  
.Credits_VBlank
    ld      h,$99
    ldh     a,[CR_VRAMPos]
    ld      l,a
    ldh     a,[CR_NextChar]
    ld      [hl],a
    jr      .done_VBlank

  
.PE_VBlank
    ld      hl,YX
    ld      de,$9800+(PE_EditAreaY)*32+PE_EditAreaX
    ld      bc,5
    call    mem_Copy
    ld      de,$9800+(PE_EditAreaY+1)*32+PE_EditAreaX
    ld      bc,5
    call    mem_Copy
    ld      de,$9800+(PE_EditAreaY+2)*32+PE_EditAreaX
    ld      bc,5
    call    mem_Copy
    ld      de,$9800+(PE_EditAreaY+3)*32+PE_EditAreaX
    ld      bc,5
    call    mem_Copy
    ld      de,$9800+(PE_EditAreaY+4)*32+PE_EditAreaX
    ld      bc,5
    call    mem_Copy

    ldh     a,[PE_MenuType]
    cp      9
    jr      nz,.PE_V_NotExitPrompt
    ld      hl,PE_ExitPrompt
    jr      .PE_V_Prompt_Copy
.PE_V_NotExitPrompt
    ldh     a,[MenuPosition]
    inc     a
    ld      hl,PE_Prompts-18
    ld      de,18
.PE_V_Prompt_Loop
    add     hl,de
    dec     a
    jr      nz,.PE_V_Prompt_Loop
  
.PE_V_Prompt_Copy
    ld      de,$99A1
    ld      bc,18
    call    mem_Copy

    ; pieces in set
    ld      hl,$9890
    ld      b,0
    ldh     a,[PE_PieceCount]
.PE_V_10lp
    cp      10
    jr      c,.PE_V_lt10
    sub     10
    inc     b
    jr      .PE_V_10lp
.PE_V_lt10
    ld      c,a
    ld      a,b
    cp      0
    jr      nz,.PE_V_NotZero
    ld      a,-$30
.PE_V_NotZero
    add     a,$30
    ld      [hli],a
    ld      a,c
    add     a,$30
    ld      [hli],a

    ; active piece
    ld      hl,$98B0
    ld      b,0
    ldh     a,[PE_ActivePiece]
    inc     a
.PE_V_10lp1
    cp      10
    jr      c,.PE_V_lt101
    sub     10
    inc     b
    jr      .PE_V_10lp1
.PE_V_lt101
    ld      c,a
    ld      a,b
    cp      0
    jr      nz,.PE_V_NotZero1
    ld      a,-$30
.PE_V_NotZero1
    add     a,$30
    ld      [hli],a
    ld      a,c
    add     a,$30
    ld      [hli],a

    jp  .done_VBlank



;* Random # - Calculate as you go *
; (Allocate 3 bytes of ram labeled 'Seed')
; Exit: A = 0-255, random number
RandomNumber:
    ld      hl,Seed
    ld      a,[hl+]
    sra     a
    sra     a
    sra     a
    xor     [hl]
    inc     hl
    rra
    rl      [hl]
    dec     hl
    rl      [hl]
    dec     hl
    rl      [hl]
    ldh     a,[$04]          ; get divider register to increase randomness
    add     [hl]
    ret


; a = target# (0-5)
; de = source
SaveHiScore:
    cp      0
    jr      z,.zero
.lpOffset
    inc     hl
    inc     hl
    inc     hl
    inc     hl
    inc     hl
    inc     hl
    dec     a
    jr      nz,.lpOffset
.zero
    ld      b,6
    di
    ld      a,$0A
    ld      [$00],a
.lp
    ld      a,[de]
    ld      [hli],a
    inc     de
    dec     b
    jr      nz,.lp
    xor     a
    ld      [$00],a
    ei
    ret

; a = source# (0-5)
; de = target
ReadHiScore:
    cp      0
    jr      z,.zero
.lpOffset
    inc     hl
    inc     hl
    inc     hl
    inc     hl
    inc     hl
    inc     hl
    dec     a
    jr      nz,.lpOffset
.zero
    ld      b,6
    di
    ld      a,$0A
    ld      [$00],a
.lp
    ld      a,[hli]
    ld      [de],a
    inc     de
    dec     b
    jr      nz,.lp
    xor     a
    ld      [$00],a
    ei
    ret


; Unsigned Multiply routine by Free Bird
; Input : C and E
; Output : HL = C*E
; Destroys : A will be 0, C will be 0 and off course the flags

Unsigned_Multiply:
	sub     a           ;Flush a
	ld      h,a         ;Flush h since a=0
	ld      l,a         ;Flush l since a=0
	ld      d,a         ;Flush d since a=0
	cp      c           ;Check if multiplied by 0
Actual_Code:
	ret     z           ;Return if c=0
	add     hl,de       ;Adds e to hl since d=0
	dec     c           ;End of loop so one step less left
	jp      Actual_Code ;Start loop again



SaveRef:
  db $12,$81,$17,$01


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
INCLUDE "memory.inc"

INCLUDE "engine.inc"

;******************************************************************************
;**                                   IRQs                                   **
;******************************************************************************

SECTION "VBLANK IRQ",ROM0[$0040]
    jp vblank

SECTION "LCDC IRQ",ROM0[$0048]
    reti

SECTION "TIMER IRQ",ROM0[$0050]
    reti

SECTION "SERIAL IRQ",ROM0[$0058]
    reti

SECTION "HILO IRQ",ROM0[$0060]
    reti


;******************************************************************************
;**                              Program Start                               **
;******************************************************************************


SECTION "Init",ROM0[$0150]

Start::
    di

    push    af
    call    waitvbl
    xor     a
    ldh     [rLCDC],a   ; Turn off screen (for quick loading)
    pop     af

    xor     a           ; Clear RAM
    ld      hl,$8000
    ld      bc,$2000
    call    mem_Set
    ld      hl,$C000
    ld      bc,$1000
    call    mem_Set
    ld      hl,$FF90
    ld      bc,$0050
    call    mem_Set
  
    ld      a,%11100100 ; Set Palettes
    ldh     [rBGP],a
    ldh     [rOBP0],a
    ldh     [rOBP1],a

    call    InitSRAM

    xor     a
    ldh     [rIF],a
    ld      a,%01000000
    ldh     [rSTAT],a
    ld      a,9        ; Set STAT Match LY
    ldh     [rLYC],a
  
    call    MS_setup_sound

	call    InitSpriteDMA

  
    xor     a
    ldh     [TileUpdate],a		; thanks bgb (beware)
    ldh     [FrameCounter],a	; thanks bgb (beware)
    ldh     [GameMode],a
  
    ld      a,40        ; Initialize random number generator
    ld      [Seed],a
    ld      [Seed+1],a
    ld      [Seed+2],a
  
    ld      a,%00000001
    ldh     [$FF],a
    ld      a,%10000000 ; turn on the LCD
    ldh     [rLCDC],a
    
    ei
    
    halt
    nop
    
    call    Main



InitSRAM:
    ld      hl,SaveID
    ld      de,SaveRef

    xor     a
    ld      [$4000],a   ; set to ram bank 0
    ld      a,$0A
    ld      [$00],a     ; enable SRAM access
    ld      b,4
.lp
    ld      a,[de]
    inc     de
    ld      c,a
    ld      a,[hli]
    cp      c
    jr      nz,.NoSaveExists
    dec     b
    jr      nz,.lp
    jr      .SaveExists
    
.NoSaveExists
    ld      hl,SaveID              ; copy save reference to SRAM
    ld      de,SaveRef
    ld      a,[de]
    ld      [hli],a
    inc     de
    ld      a,[de]
    ld      [hli],a
    inc     de
    ld      a,[de]
    ld      [hli],a
    inc     de
    ld      a,[de]
    ld      [hli],a
    ld      hl,SavedScores
    ld      a,$80                  ; initialize hiscores
    ld      bc,152                 ; ((6*3)+1)*8
    call    mem_Set
    ld      hl,Null_Piece_Set
    ld      de,SavedSets
    ld      bc,9
    call    mem_Copy
    ld      hl,Null_Piece_Set
    ld      bc,9
    call    mem_Copy
    ld      hl,Null_Piece_Set
    ld      bc,9
    call    mem_Copy
    ld      hl,Null_Piece_Set
    ld      bc,9
    call    mem_Copy
    ld      a,$FD
    ld      [de],a                 ; termination byte
  
.SaveExists
    xor     a
    ld      [$00],a     ; disable SRAM access
  
    ret

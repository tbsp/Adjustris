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


SECTION "SpriteTable",WRAM0[$C000]

Sprite_Table: DS $A0


SECTION "Video",ROM0

InitSpriteDMA::
    ; copy spritedma routine into hiram
    ld      hl,SpriteDMA
    ld      de,$FF80
    ld      bc,SpriteDMAEnd - SpriteDMA
    call    mem_Copy
    ret

; SpriteDMA routine (copied to HiRAM at $FF80)
SpriteDMA:
    ld      a,$C0
    ldh     [rDMA],a
    ld      a,$28
.lp
    dec     a
    jr      nz,.lp
    ret
SpriteDMAEnd:


LCDC_irq::
    reti

  
VBlank_irq::
    push    af
    call    $FF80
    pop     af
    reti


waitvbl::
    push    af
.lp
    ldh     a,[rSTAT]
    and     3
    cp      1
    jr      nz,.lp
    pop     af
    ret


; A = Palette Starting Addy
; B = Bytes (8=one full pallete)
; HL = Palette Source
SetPalBG:
    or      %10000000
    ldh     [rBCPS],a
.lp
    ld      a,[hli]
    ldh     [rBCPD],a
    dec     b
    jr      nz,.lp
    ret

; A = Palette Starting Addy
; B = Bytes (8=one full pallete)
; HL = Palette Source
SetPalOBJ:
    or      %10000000
    ldh     [rOCPS],a
.lp
    ld      a,[hli]
    ldh     [rOCPD],a
    dec     b
    jr      nz,.lp
    ret



SECTION "SpriteDMA",HRAM[$FF80]

SpriteDMA_HRAM: DS (SpriteDMAEnd - SpriteDMA)

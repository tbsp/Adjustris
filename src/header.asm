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

;******************************************************************************
;**                                   Header                                 **
;******************************************************************************

SECTION "Header",ROM0[$0100]
    nop
    jp    Start
    
    NINTENDO_LOGO
    
    db    "ADJUSTRIS V1.1 "
    ;     "123456789012345" <- Title must be exactly that long, in caps
    ;     Colour Compatibility Code ($80 : yes, $00 : no)
    db    $0
    ;     Maker Code
    db    0,0
    ;     Game Unit Code (00=Gameboy, 03=Super Gameboy functions)
    db    0
    ;     Cartridge type:
    db    $13
    ;     Rom Size:
    db    0
    ;     External Ram Size:
    db    2
    ;     Destination code (0 - Japanese, 1 - Non-Japanese)
    db    1
    ;     Old Licensee code (33 - Check Maker Code)
    db    $33
    ;     Mask ROM Version
    db    0
    ;     Complement check
    db    $0
    ;     Checksum
    db    0,0

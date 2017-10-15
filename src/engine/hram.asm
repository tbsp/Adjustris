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

SECTION "Shared HiRAM",HRAM[$FFA8]

UNION
; Gameplay defines (local to gameplay mode)
DropCounter:    ds 1
DropSet:        ds 1
BlockType:      ds 1
BlockRotate:    ds 1
temp:           ds 5
Direction:      ds 1
NextPiece:      ds 1
UHCount:        ds 1
DHCount:        ds 1
LHCount:        ds 1
RHCount:        ds 1
LineCount:      ds 1
BlockCount:     ds 1
ClearDelay:     ds 1
PiecesInActiveSet: ds 1
BlocksInLastPiece: ds 1
NEXTU

CR_ScrollChar:  ds 1
CR_ScrollCount: ds 1
CR_VRAMPos:     ds 1
CR_NextChar:    ds 1
CR_UpdateChar:  ds 1
CR_Temp:        ds 1
CR_PieceCount:  ds 1
CR_Piece:       ds 1
CR_PieceX:      ds 1
CR_PieceYidx:   ds 1

NEXTU
PE_CursorY:     ds 1
PE_CursorX:     ds 1
PE_ActiveFlags: ds 1
PE_ActiveTile:  ds 1
PE_ActiveRotY:  ds 1
PE_ActiveRotX:  ds 1
PE_PieceCount:  ds 1
PE_ActivePiece: ds 1
PE_MenuType:    ds 1
PE_OldRotY:     ds 1
PE_OldRotX:     ds 1
PE_OldTile:     ds 1
PE_Temp:        ds 2
PE_SaveSlot:    ds 1

NEXTU
HI_CurrentSet:      ds 1
HI_UpdateScores:    ds 1

NEXTU


ENDU

# Adjustris

This game was made as an entry for the PDRoms Coding Competition 3.33.

The game takes a common game type and adds the ability to edit sets of pieces that can then be used in the main game.

To play the game, simply download the latest release and run it in any Game Boy emulator. You can find the latest release of the game here:

    https://github.com/tbsp/Adjustris/releases
    
This game has been tested on real hardware and works great!

## Gameplay

### Main Game

The main game is just as you might expect.  Pieces fall and must be moved and rotated to form complete horizontal lines which are then cleared.  A new level is reached after every 10 lines and the drop speed increases with every level.

To start the main game select "Play Set X" from the title screen.  The set used can be selected by pressing up/down on the D-Pad.  Sets 1-4 are the included piece sets.  Sets 5-8 can be edited in the piece editor and start out as a single piece made of a single block.

#### Gameplay Controls

```
D-Pad  - Move piece
A      - Rotate primary direction
B      - Rotate opposite direction
Start  - Pause the game
Select - Exits to the title screen when paused
```

### Piece Editor

The piece editor is used to edit sets of pieces to be used in the main game.  Sets 1-4 are stored in ROM and cannot be edited.  Sets 5-8 are stored in battery-backed RAM and can be edited.

To start the editor select "Edit Sets" from the title screen.

#### Editor Controls

```
D-Pad  - Move cursor (actual movement depends on location in editor)
A      - Confirm selections and toggle blocks in the piece grid
B      - Cancel actions
Start  - Exit the editor (you will be asked if you want to exit, data will not be saved)
Select - When holding Select press left/right to change the active piece in the set
```

#### Editor Icons

```
Edit Piece         - Allows you to edit the blocks of the current piece (A toggles blocks on/off)
Center of Rotation - Allows you to move the point at which the piece will rotate about
Rotation Direction - Changes the piece rotation from Counter-Clockwise, Clockwise and No Rotation (X)
Spin or Wobble     - Sets if the piece will spin (rotate 4 times) or wobble (rotate once, then rotate back)
Change Tile        - Changes the tile that will be used for this piece (16 tile to choose from)
Insert Piece       - Inserts a piece into the set after the current piece (and make it active)
Delete Piece       - Deletes the current piece (no confirmation)
Save Set           - Saves the set in one of the RAM slots (5-8)
Load Set           - Loads a set from one of the RAM slots (5-8)
```

### High Scores

There is a 1st, 2nd and 3rd place for every piece set.  Any changes made to a saved set (except for changing tile types) will result in the old highscores for that set being cleared once the set is played.


## Prerequisites

You'll require RGBDS in order to build Adjustris for yourself.

A Make implementation is also required, on Microsoft Windows [https://www.msys2.org/](msys2) can be used.

## Building

To build, simply run:

```
make
```

## Authors 

* Written in 2005 by **Dave VanEe** [tbsp](https://github.com/tbsp)
* Refactored in 2017 by **Dave VanEe**

## License

To the extent possible under law, the author(s) have dedicated all copyright and related and neighboring rights to this software to the public domain worldwide. This software is distributed without any warranty.
You should have received a copy of the CC0 Public Domain Dedication along with this software. If not, see <http://creativecommons.org/publicdomain/zero/1.0/>.

## Acknowledgments

* Thanks to beware for BGB
* Thanks to H. Mulder for the hiscore library

## Tools Used

* RGBDS
* BGB
* GB Tile Designer
* GBITOOL (pcx2gbi)

## Version History

* v1.0 Initial Release (2005-07-17)
* v1.1 Refactor and Source Release (2017-10-15)

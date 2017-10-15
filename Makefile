RGBASM = rgbasm
RGBLINK = rgblink
RGBFIX = rgbfix

NAME = adjustris
EXT = gb

EMULATOR = wine ../../Utilities/bgb1.5.4/bgb.exe

SOURCE = src gfx inc

SOURCE_DIRS = $(shell find $(SOURCE) -type d -print)
SOURCES = $(foreach dir,$(SOURCE_DIRS),$(wildcard $(dir)/*.asm))

INCLUDES = $(foreach dir,$(SOURCE_DIRS),-i$(CURDIR)/$(dir)/)

OBJECTS = $(SOURCES:%.asm=%.o)

all: $(NAME)

clean:
	@rm -f $(OBJECTS) $(BIN) $(NAME).sym $(NAME).map

run:
	$(EMULATOR) $(NAME).gb

$(NAME): $(OBJECTS)
	$(RGBLINK) -w -o $@.gb -p 0xFF -m $(NAME).map -n $@.sym $(OBJECTS)
	$(RGBFIX) -v -p 0xFF $@.gb

%.o: %.asm
	$(RGBASM) $(INCLUDES) -E -o $@ $<

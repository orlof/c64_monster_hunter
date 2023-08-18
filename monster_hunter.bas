OPTION FASTINTERRUPT

INCLUDE "ext/lib_types.bas"
INCLUDE "ext/lib_color.bas"
INCLUDE "ext/lib_joy.bas"
INCLUDE "ext/lib_random.bas"

SHARED CONST LAST_MONSTER = 15
SHARED CONST SCRMEM = $c000
SHARED CONST SPR_OFFSET_X = 12
SHARED CONST SPR_OFFSET_Y = 10

DIM SHARED PlayerX AS LONG
PlayerX = 160
DIM SHARED PlayerY AS LONG
PlayerY = 80

DIM SHARED PlayerDirection AS BYTE
PlayerDirection = 0

DIM SHARED MonsterSpeed AS BYTE
MonsterSpeed = 16

INCLUDE "monster.bas"

DIM HERO_OFFSET_X(16) AS INT @ _HERO_OFFSET_X
DIM HERO_OFFSET_Y(16) AS INT @ _HERO_OFFSET_Y

DIM SHARED MONSTERS(16) AS MONSTER
FOR i AS BYTE = 0 TO LAST_MONSTER
    'CALL MONSTERS(i).Init()
NEXT i

DIM ZP_B0 AS BYTE FAST
DIM ZP_W0 AS WORD FAST

'INCLUDE "ext/lib_memory.bas"

'INCLUDE "ext/lib_char.bas"
'INCLUDE "ext/lib_scr.bas"
'INCLUDE "ext/lib_hires.bas"

'INCLUDE "ext/lib_irq.bas"
'INCLUDE "ext/lib_sid.bas"
'INCLUDE "ext/lib_spr.bas"
'INCLUDE "ext/lib_spr_shape.bas"
'INCLUDE "ext/lib_spr_draw.bas"

'INCLUDE "ext/lib_sfx.bas"

'INCLUDE "title.bas"

DECLARE FUNCTION ShowTitleBitmap AS BYTE () SHARED STATIC
DECLARE FUNCTION ShowTitleAnimation AS BYTE () SHARED STATIC
DECLARE SUB InitGraphics() SHARED STATIC
DECLARE SUB PlaySID() SHARED STATIC
DECLARE SUB WaitRasterLine256() SHARED STATIC
DECLARE SUB UpdateHero() SHARED STATIC
DECLARE SUB ShowTitle() SHARED STATIC

RANDOMIZE TI()

CALL InitGraphics()
CALL ShowTitle()
END

SUB ShowTitle() SHARED STATIC
    CALL PlaySID()

    MEMSET $c000, 1000, 32
    ' GRASS
    FOR ZP_B0 = 0 TO 50
        ZP_W0 = random16(0, 799)
        POKE $c000 + ZP_W0, 64
        'POKE $d800 + ZP_W0, 13
    NEXT

    PlayerDirection = 0

    DIM mode AS BYTE
    mode = 0

    DO
        IF mode = 0 THEN
            _ = ShowTitleBitmap()
        ELSE
            _ = ShowTitleAnimation()
        END IF

        mode = mode XOR 1
    LOOP
END SUB


FUNCTION ShowTitleBitmap AS BYTE() SHARED STATIC
    BORDER COLOR_BLACK
    BACKGROUND COLOR_BLACK

    MEMCPY $c800, $d800, 1000

    ASM
        ; BITMAP 1, SCRMEM 1
        lda #%00011000
        sta $d018

        ; Bitmap mode on
        lda $d011
        and #%01111111
        ora #%00100000
        sta $d011
    END ASM

    FOR t AS WORD = 0 TO 10000
        CALL Joy2.Update()
        IF Joy2.ButtonOn() = TRUE THEN RETURN TRUE
    NEXT t

    RETURN FALSE
END FUNCTION

FUNCTION ShowTitleAnimation AS BYTE() SHARED STATIC
    BORDER COLOR_MIDDLEGRAY
    BACKGROUND COLOR_MIDDLEGRAY
    MEMSET $d800, 1000, %1101

    SPRITE 0 ON
    SPRITE 1 ON
    CALL UpdateHero()

    ASM
        ; SCRMEM 0, FONTS 3
        lda #%00000110
        sta $d018

        ; Text mode on
        lda $d011
        and #%01011111
        sta $d011
    END ASM

    ShowTitleAnimation = FALSE

    FOR ZP_W0 = 0 TO 511
        CALL WaitRasterLine256()

        ZP_B0 = ZP_W0 AND $f
        IF MONSTERS(ZP_B0).Alive = FALSE THEN
            CALL MONSTERS(ZP_B0).Init()
        ELSE
            CALL MONSTERS(ZP_B0).Move()
        END IF

        CALL Joy2.Update()

        PlayerDirection = PlayerDirection - Joy2.XAxis()
        IF Joy2.North() = TRUE THEN
            PlayerY = PlayerY
        END IF
        CALL UpdateHero()

        IF Joy2.ButtonOn() = TRUE THEN
            ShowTitleAnimation = TRUE
            EXIT FOR
        END IF
    NEXT

    SPRITE 0 OFF
    SPRITE 1 OFF
END FUNCTION

SUB InitGraphics() SHARED STATIC
    ASM
        ; Extra background color #1 Black
        lda #0
        sta $d022
        ; Extra background color #2 Red
        lda #2
        sta $d023

        ; Vic Bank 3
        lda $dd00
        and #%11111100
        sta $dd00

        ; Multicolor mode on
        lda $d016
        ora #%00010000
        sta $d016

        ; Sprite extra color #1
        lda #11
        sta $d025
        ; Sprite extra color #2
        lda #9
        sta $d026
    END ASM

    SCREEN 0

    SPRITE 0 HIRES COLOR 0
    SPRITE 1 MULTI COLOR 7

END SUB

SUB PlaySID() SHARED STATIC
    ASM
        lda #0
        jsr $1800
    END ASM

    ON RASTER 256 GOSUB IRQSidPlayer
    SYSTEM INTERRUPT OFF
    RASTER INTERRUPT ON

    EXIT SUB

IRQSidPlayer:
    ASM
        jsr $1806
    END ASM
    RETURN
END SUB


SUB WaitRasterLine256() SHARED STATIC
    ASM
wait1:  bit $d011
        bmi wait1
wait2:  bit $d011
        bpl wait2
    END ASM
END SUB

SUB UpdateHero() SHARED STATIC
    ASM
        lda {PlayerDirection}
        and #%11110000
        lsr
        lsr
        lsr
        tax

        clc
        adc #64 ; sprite 1 fp
        sta $c3f9
        adc #1  ; sprite 0 fp
        sta $c3f8

sprxy_y
        clc                     ; spr_reg_xy(SprNr).y = y + 50 - 10
        lda {PlayerY}+1
        adc #40

        clc
        adc {HERO_OFFSET_Y},x

        sta $d001 ; Sprite #0 Y-coordinate
        sta $d003 ; Sprite #1 Y-coordinate

sprxy_x
        clc                     ; spr_reg_xy(SprNr).x = x + 24 - 12
        lda {HERO_OFFSET_X},x
        adc #12

        clc
        adc {PlayerX}+1

        sta $d000 ; Sprite #0 X-coordinate (only bits #0-#7)
        sta $d002 ; Sprite #1 X-coordinate (only bits #0-#7)

        lda {PlayerX}+2
        adc #0
        bne sprxy_hi1

        lda $d010
        and #%11111100
        jmp sprxy_exit

sprxy_hi1
        lda $d010
        ora #%00000011

sprxy_exit
        sta $d010 ; Sprite #0 X-coordinate (only bit #8)
    END ASM
END SUB

ORIGIN $1800
INCBIN "data/bg_music.bin"

ORIGIN $230a

DIM CurrentMonster AS BYTE
    CurrentMonster = 0

GameLoop:
    ' MOVE MONSTERS
    CALL MONSTERS(CurrentMonster).Move()
    CurrentMonster = CurrentMonster + 1
    IF CurrentMonster > LAST_MONSTER THEN CurrentMonster = 0

    ' WAIT
    GOTO GameLoop

    END

_HERO_OFFSET_X:
    DATA AS INT 5, 6,  5,  3,  1, -2, -2, -3, -5, -5, -4, -3, -1, 1, 2, 3

_HERO_OFFSET_Y:
    DATA AS INT 2, 0, -1, -3, -4, -4, -4, -2, -2,  1,  1,  4,  5, 5, 5, 3

REM HERO FORWARD
DATA AS INT 100, 0
DATA AS INT 92, 38
DATA AS INT 71, 71
DATA AS INT 38, 92
DATA AS INT 0, 100
DATA AS INT -38, 92
DATA AS INT -71, 71
DATA AS INT -92, 38
DATA AS INT -100, 0
DATA AS INT -92, -38
DATA AS INT -71, -71
DATA AS INT -38, -92
DATA AS INT 0, -100
DATA AS INT 38, -92
DATA AS INT 71, -71
DATA AS INT 92, -38
DATA AS INT 100, 0
REM HERO BACKWARD
DATA AS INT 50, 0
DATA AS INT 46, 19
DATA AS INT 35, 35
DATA AS INT 19, 46
DATA AS INT 0, 50
DATA AS INT -19, 46
DATA AS INT -35, 35
DATA AS INT -46, 19
DATA AS INT -50, 0
DATA AS INT -46, -19
DATA AS INT -35, -35
DATA AS INT -19, -46
DATA AS INT 0, -50
DATA AS INT 19, -46
DATA AS INT 35, -35
DATA AS INT 46, -19
DATA AS INT 50, 0
REM BULLET FORWARD
DATA AS INT 200, 0
DATA AS INT 185, 77
DATA AS INT 141, 141
DATA AS INT 77, 185
DATA AS INT 0, 200
DATA AS INT -77, 185
DATA AS INT -141, 141
DATA AS INT -185, 77
DATA AS INT -200, 0
DATA AS INT -185, -77
DATA AS INT -141, -141
DATA AS INT -77, -185
DATA AS INT 0, -200
DATA AS INT 77, -185
DATA AS INT 141, -141
DATA AS INT 185, -77
DATA AS INT 200, 0

OPTION FASTINTERRUPT

INCLUDE "ext/lib_types.bas"
INCLUDE "ext/lib_color.bas"
INCLUDE "ext/lib_joy.bas"
INCLUDE "ext/lib_random.bas"

' DIFFICULTY LEVEL
' TotalMonsters
' MonsterSpeed
' RespawnDelay

SHARED CONST LAST_MONSTER = 15
SHARED CONST SCRMEM = $c000
SHARED CONST SPR_OFFSET_X = 12
SHARED CONST SPR_OFFSET_Y = 10
SHARED CONST MODE_PLAY = 0
SHARED CONST MODE_GAME_OVER = 1

SHARED CONST TILE_EMPTY = 80
SHARED CONST TILE_BUSH  = 64

DIM SHARED PlayerX AS LONG @ _PlayerX
DIM SHARED PlayerY AS LONG @ _PlayerY
DIM SHARED PlayerXi AS INT @ _PlayerXi
DIM SHARED PlayerYi AS INT @ _PlayerYi
DIM SHARED PlayerDirection AS BYTE

DIM SHARED BulletAlive AS BYTE
DIM SHARED BulletX AS LONG @ _BulletX
DIM SHARED BulletY AS LONG @ _BulletY
DIM SHARED BulletXi AS INT @ _BulletXi
DIM SHARED BulletYi AS INT @ _BulletYi
DIM SHARED BulletDirection AS BYTE

DIM HERO_FWD_X(16) AS LONG @ _HERO_FWD_X
DIM HERO_FWD_Y(16) AS LONG @ _HERO_FWD_Y
DIM HERO_BWD_X(16) AS LONG @ _HERO_BWD_X
DIM HERO_BWD_Y(16) AS LONG @ _HERO_BWD_Y
DIM BULLET_FWD_X(16) AS LONG @ _BULLET_FWD_X
DIM BULLET_FWD_Y(16) AS LONG @ _BULLET_FWD_Y

PlayerDirection = 0

DIM SHARED MonsterSpeed AS BYTE
MonsterSpeed = 32
DIM SHARED GameMode AS BYTE
DIM SHARED RespawnDelay AS BYTE
RespawnDelay = 32
DIM SHARED RespawnTimer AS BYTE

INCLUDE "monster.bas"

DIM HERO_OFFSET_X(16) AS INT @ _HERO_OFFSET_X
DIM HERO_OFFSET_Y(16) AS INT @ _HERO_OFFSET_Y

DIM SHARED MONSTERS(16) AS MONSTER

DIM ZP_B0 AS BYTE FAST
DIM TickCounter AS BYTE FAST

DECLARE FUNCTION ShowTitleBitmap AS BYTE () SHARED STATIC
DECLARE FUNCTION ShowTitleAnimation AS BYTE () SHARED STATIC
DECLARE SUB InitGraphics() SHARED STATIC
DECLARE SUB InitGame() SHARED STATIC
DECLARE SUB PlaySID() SHARED STATIC
DECLARE SUB StopSID() SHARED STATIC
DECLARE SUB WaitRasterLine256() SHARED STATIC
DECLARE SUB UpdateHero() SHARED STATIC
DECLARE SUB ShowTitle() SHARED STATIC
DECLARE SUB PlayGame() SHARED STATIC
DECLARE SUB ShowGameScreen() SHARED STATIC
DECLARE SUB MoveMonsters() SHARED STATIC
DECLARE SUB MoveHeroHuman() SHARED STATIC
DECLARE SUB MoveHeroDemo() SHARED STATIC
DECLARE SUB Shoot() SHARED STATIC
DECLARE SUB MoveBullet() SHARED STATIC
DECLARE SUB UpdateBullet() SHARED STATIC
DECLARE SUB CheckBulletCollision() SHARED STATIC
DECLARE SUB CheckHeroCollision() SHARED STATIC

RANDOMIZE TI()

CALL InitGraphics()

DO
    CALL ShowTitle()
    CALL PlayGame()
LOOP

SUB PlayGame() SHARED STATIC
    CALL InitGame()
    CALL ShowGameScreen()

    GameMode = MODE_PLAY
    DO
        CALL WaitRasterLine256()

        CALL MoveMonsters()
        CALL MoveHeroHuman()
        CALL UpdateHero()
        CALL CheckHeroCollision()

        IF BulletAlive THEN
            CALL MoveBullet()
            IF BulletAlive THEN
                CALL UpdateBullet()
                CALL CheckBulletCollision()
            END IF
        END IF
        TickCounter = TickCounter + 1
    LOOP UNTIL GameMode = MODE_GAME_OVER

    BulletAlive = FALSE
    SPRITE 0 OFF
    SPRITE 1 OFF
    SPRITE 2 OFF

END SUB

SUB ShowTitle() SHARED STATIC
    CALL PlaySID()
    CALL InitGame()

    DIM TitleScene AS BYTE
    TitleScene = 0
    DO
        IF TitleScene = 0 THEN
            IF ShowTitleBitmap() THEN EXIT DO
        ELSE
            IF ShowTitleAnimation() THEN EXIT DO
        END IF

        TitleScene = TitleScene XOR 1
    LOOP

    CALL StopSID()
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

    FOR T AS BYTE = 0 TO 255
        CALL WaitRasterLine256()
        CALL Joy2.Update()
        IF Joy2.ButtonOn() = TRUE THEN RETURN TRUE
    NEXT

    RETURN FALSE
END FUNCTION

SUB InitGame() SHARED STATIC
    FOR ZP_B0 = 0 TO LAST_MONSTER
        MONSTERS(ZP_B0).Alive = FALSE
    NEXT

    PlayerX = $00a000 ' 160
    PlayerY = $005000 ' 80
    PlayerDirection = 0
    BulletAlive = FALSE
    RespawnTimer = 0

    MEMSET $c000, 960, TILE_EMPTY
    MEMSET $c3c0, 40, 32

    ' GRASS
    FOR ZP_B0 = 0 TO 50
        POKE $c000 + random16(0, 959), TILE_BUSH
        'POKE $d800 + ZP_W0, 13
    NEXT
END SUB

SUB Shoot() SHARED STATIC
    BulletAlive = TRUE
    BulletX = PlayerX
    BulletY = PlayerY
    BulletDirection = SHR(PlayerDirection, 4)
    SPRITE 2 ON
END SUB

SUB MoveBullet() SHARED STATIC
    BulletX = BulletX + BULLET_FWD_X(BulletDirection)
    BulletY = BulletY + BULLET_FWD_Y(BulletDirection)
    IF BulletXi < 0 OR BulletXi > 319 OR BulletYi < 0 OR BulletYi > 191 THEN
        BulletAlive = FALSE
        SPRITE 2 OFF
    END IF
END SUB

SUB MoveHeroDemo() SHARED STATIC
    IF BulletAlive = FALSE THEN
        IF PlayerDirection = 0 OR PlayerDirection = 128 OR RNDB() < 8 THEN
            CALL Shoot()
        END IF
    END IF
    PlayerDirection = PlayerDirection + 1
END SUB

SUB ShowGameScreen() SHARED STATIC
    BORDER COLOR_MIDDLEGRAY
    BACKGROUND COLOR_MIDDLEGRAY

    MEMSET $d800, 960, MCOLOR_GREEN
    MEMSET $dbc0, 40, COLOR_BLACK

    ASM
        ; SCRMEM 0, FONTS 3
        lda #%00000110
        sta $d018

        ; Text mode on
        lda $d011
        and #%01011111
        sta $d011
    END ASM

    CALL UpdateHero()

    SPRITE 0 ON
    SPRITE 1 ON
    IF BulletAlive = TRUE THEN SPRITE 2 ON
END SUB

SUB MoveMonsters() SHARED STATIC
    DIM MonsterIndex AS BYTE
    MonsterIndex = TickCounter AND $f

    IF MONSTERS(MonsterIndex).Alive THEN
        CALL MONSTERS(MonsterIndex).Move()
    ELSE
        IF RespawnTimer = 0 THEN
            CALL MONSTERS(MonsterIndex).Init()
            RespawnTimer = RespawnDelay
        END IF
    END IF

    IF RespawnTimer > 0 THEN RespawnTimer = RespawnTimer - 1

    ' ANIMATE MONSTER
    MonsterIndex = (MonsterIndex XOR 8)
    IF MONSTERS(MonsterIndex).Alive THEN
        MonsterAddress = MONSTERS(MonsterIndex).Address
        CALL ChangeCostume()
    END IF
END SUB

SUB MoveHeroHuman() SHARED STATIC
    CALL Joy2.Update()

    PlayerDirection = PlayerDirection - SHL(Joy2.XAxis(), 1)
    DIM Direction AS BYTE
    IF Joy2.North() THEN
        Direction = SHR(PlayerDirection, 4)
        PlayerX = PlayerX + HERO_FWD_X(Direction)
        IF PlayerX < 0 THEN PlayerX = 0
        IF PlayerX > $013f00 THEN PlayerX = $013f00
        PlayerY = PlayerY + HERO_FWD_Y(Direction)
        IF PlayerY < 0 THEN PlayerY = 0
        IF PlayerY > $00b700 THEN PlayerY = $00b700
    ELSE
        IF Joy2.South() THEN
            Direction = SHR(PlayerDirection, 4)
            PlayerX = PlayerX + HERO_BWD_X(Direction)
            IF PlayerX < 0 THEN PlayerX = 0
            IF PlayerX > $013f00 THEN PlayerX = $013f00
            PlayerY = PlayerY + HERO_BWD_Y(Direction)
            IF PlayerY < 0 THEN PlayerY = 0
            IF PlayerY > $00b700 THEN PlayerY = $00b700
        END IF
    END IF
    IF Joy2.Button() THEN
        IF BulletAlive = FALSE THEN
            CALL Shoot()
        END IF
    END IF
END SUB

SUB CheckBulletCollision() SHARED STATIC
    DIM Icon AS BYTE
    DIM Address AS WORD
    Address = $c000 + 40 * SHR(BulletYi, 3) + SHR(BulletXi, 3)
    Icon = PEEK(Address)
    IF (Icon > 127) AND (Icon < 192) THEN
        FOR ZP_B0 = 0 TO 15
            IF MONSTERS(ZP_B0).Alive = FALSE THEN CONTINUE FOR
            MonsterAddress = MONSTERS(ZP_B0).Address
            IF (MonsterAddress = Address) OR ((MonsterAddress+1) = Address) _
                OR ((MonsterAddress+40) = Address) OR ((MonsterAddress+41) = Address) THEN
                    CALL MONSTERS(ZP_B0).Explode()
                    EXIT SUB
            END IF
        NEXT
    END IF
END SUB

SUB CheckHeroCollision() SHARED STATIC
    DIM Icon AS BYTE
    DIM Address AS WORD
    Address = $c000 + CWORD(40 * SHR(PlayerYi, 3) + SHR(PlayerXi, 3))
    Icon = PEEK(Address)
    IF (Icon > 127) AND (Icon < 192) THEN
        GameMode = MODE_GAME_OVER
    END IF
END SUB

FUNCTION ShowTitleAnimation AS BYTE() SHARED STATIC
    CALL ShowGameScreen()

    ShowTitleAnimation = FALSE

    FOR TickCounter = 0 TO 255
        CALL WaitRasterLine256()

        CALL MoveMonsters()
        CALL MoveHeroDemo()
        CALL UpdateHero()

        IF BulletAlive = TRUE THEN
            CALL MoveBullet()
            IF BulletAlive = TRUE THEN
                CALL UpdateBullet()
                CALL CheckBulletCollision()
            END IF
        END IF

        CALL Joy2.Update()
        IF Joy2.ButtonOn() = TRUE THEN
            ShowTitleAnimation = TRUE
            EXIT FOR
        END IF
    NEXT

    SPRITE 0 OFF
    SPRITE 1 OFF
    SPRITE 2 OFF
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
    SPRITE 2 HIRES COLOR 1 SHAPE 48

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

'IRQGameArea:
'    ASM
'        lda #0
'        sta $d020
'    END ASM
'    ON RASTER 256 GOSUB IRQSidPlayer
'    RETURN

IRQSidPlayer:
'    IF SplitScreen = 100 THEN
'        ASM
'            lda #1
'            sta $d020
'        END ASM
'        ON RASTER 210 GOSUB IRQGameArea
'    END IF
    ASM
        jsr $1806
    END ASM
    RETURN
END SUB

SUB StopSID() SHARED STATIC
    RASTER INTERRUPT OFF

    ASM
        ; Reset SID
        lda #$ff
stop_sid_loop:
        ldx #$17
stop_sid_0:
        sta $d400,x
        dex
        bpl stop_sid_0
        tax
        bpl stop_sid_1
        lda #$08
        bpl stop_sid_loop
stop_sid_1:
stop_sid_2:
        bit $d011
        bpl stop_sid_2
stop_sid_3:
        bit $d011
        bmi stop_sid_3
        eor #$08
        beq stop_sid_loop

        lda #$0f
        sta $d418
    END ASM
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

SUB UpdateBullet() SHARED STATIC
    ASM
bullet_y
        clc                     ; spr_reg_xy(SprNr).y = y + 50 - 10
        lda {BulletY}+1
        adc #40

        sta $d005 ; Sprite #2 Y-coordinate

bullet_x
        clc                     ; spr_reg_xy(SprNr).x = x + 24 - 12
        lda {BulletX}+1
        adc #12

        sta $d004 ; Sprite #0 X-coordinate (only bits #0-#7)

        lda {BulletX}+2
        adc #0
        bne bullet_hi1

        lda $d010
        and #%11111011
        jmp bullet_exit

bullet_hi1
        lda $d010
        ora #%00000100

bullet_exit
        sta $d010 ; Sprite #0 X-coordinate (only bit #8)
    END ASM
END SUB

ORIGIN $1800
INCBIN "data/bg_music.bin"

ORIGIN $230a

_HERO_OFFSET_X:
    DATA AS INT 5, 6,  5,  3,  1, -2, -2, -3, -5, -5, -4, -3, -1, 1, 2, 3

_HERO_OFFSET_Y:
    DATA AS INT 2, 0, -1, -3, -4, -4, -4, -2, -2,  1,  1,  4,  5, 5, 5, 3

_PlayerX:
    DATA AS BYTE 0
_PlayerXi:
    DATA AS BYTE 0, 0
_PlayerY:
    DATA AS BYTE 0
_PlayerYi:
    DATA AS BYTE 0, 0

_BulletX:
    DATA AS BYTE 0
_BulletXi:
    DATA AS BYTE 0, 0
_BulletY:
    DATA AS BYTE 0
_BulletYi:
    DATA AS BYTE 0, 0

REM HERO FORWARD
_HERO_FWD_X:
    DATA AS LONG 100, 92, 71, 38, 0, -38, -71, -92, -100, -92, -71, -38, 0, 38, 71, 92
_HERO_FWD_Y:
    DATA AS LONG 0, -38, -71, -92, -100, -92, -71, -38, 0, 38, 71, 92, 100, 92, 71, 38
REM HERO BACKWARD
_HERO_BWD_X:
    DATA AS LONG -50, -46, -35, -19, 0, 19, 35, 46, 50, 46, 35, 19, 0, -19, -35, -46
_HERO_BWD_Y:
    DATA AS LONG 0, 19, 35, 46, 50, 46, 35, 19, 0, -19, -35, -46, -50, -46, -35, -19
REM BULLET FORWARD
_BULLET_FWD_X:
    DATA AS LONG 512, 473, 362, 196, 0, -196, -362, -473, -512, -473, -362, -196, 0, 196, 362, 473
_BULLET_FWD_Y:
    DATA AS LONG 0, -196, -362, -473, -512, -473, -362, -196, 0, 196, 362, 473, 512, 473, 362, 196
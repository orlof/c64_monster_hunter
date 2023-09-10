DIM SHARED MonsterAddress AS WORD FAST

SUB ChangeCostume() STATIC SHARED
    ASM
        ldy #0
        lda ({MonsterAddress}),y
        eor #2
        sta ({MonsterAddress}),y
        iny
        lda ({MonsterAddress}),y
        eor #2
        sta ({MonsterAddress}),y
        ldy #40
        lda ({MonsterAddress}),y
        eor #2
        sta ({MonsterAddress}),y
        iny
        lda ({MonsterAddress}),y
        eor #2
        sta ({MonsterAddress}),y
    END ASM
END SUB

FUNCTION AddBlood AS BYTE(bg AS BYTE) STATIC
    ASM
        ldy {bg}
        tya
        and #%11
        cmp #%11
        beq NoMoreBlood
        iny
NoMoreBlood:
        sty {AddBlood}
    END ASM
END FUNCTION

FUNCTION Collision AS BYTE() STATIC
    ASM
        ldy #0
        lda ({MonsterAddress}),y
        cmp #128
        bcc NoCollision0
        jmp Collision0
NoCollision0:
        iny
        lda ({MonsterAddress}),y
        cmp #128
        bcc NoCollision1
        jmp Collision0
NoCollision1:
        ldy #40
        lda ({MonsterAddress}),y
        cmp #128
        bcc NoCollision2
        jmp Collision0
NoCollision2:
        iny
        lda ({MonsterAddress}),y
        cmp #128
        bcc NoCollision3

Collision0:
        lda #$ff          ; Collision
        .byte $2c
NoCollision3:
        lda #00

        sta {Collision}
    END ASM
END FUNCTION

TYPE MONSTER
    Alive AS BYTE
    x AS INT
    y AS INT

    Address AS WORD

    bg0 AS BYTE
    bg1 AS BYTE
    bg2 AS BYTE
    bg3 AS BYTE

    SUB Draw() STATIC
        THIS.bg0 = PEEK(THIS.Address)
        THIS.bg1 = PEEK(THIS.Address + 1)
        THIS.bg2 = PEEK(THIS.Address + 40)
        THIS.bg3 = PEEK(THIS.Address + 41)

        POKE THIS.Address, 128
        POKE THIS.Address + 1, 129
        POKE THIS.Address + 40, 144
        POKE THIS.Address + 41, 145
    END SUB

    SUB Clear() STATIC
        POKE THIS.Address, THIS.bg0
        POKE THIS.Address + 1, THIS.bg1
        POKE THIS.Address + 40, THIS.bg2
        POKE THIS.Address + 41, THIS.bg3
    END SUB

    SUB Explode() STATIC
        POKE THIS.Address, AddBlood(THIS.bg0)
        POKE THIS.Address + 1, AddBlood(THIS.bg1)
        POKE THIS.Address + 40, AddBlood(THIS.bg2)
        POKE THIS.Address + 41, AddBlood(THIS.bg3)

        THIS.Alive = FALSE
    END SUB

    SUB Init() STATIC
        DO
            DIM Side AS BYTE
            Side = random(0, 3)

            SELECT CASE Side
                CASE 0
                    ' TOP
                    THIS.x = random(0, 38)
                    THIS.y = 0
                CASE 1
                    ' LEFT
                    THIS.x = 0
                    THIS.y = random(0, 22)
                CASE 2
                    ' BOTTOM
                    THIS.x = random(0, 38)
                    THIS.y = 22
                CASE 3
                    ' RIGHT
                    THIS.x = 38
                    THIS.y = random(0, 22)
            END SELECT

            MonsterAddress = SCRMEM + THIS.x + THIS.y * 40
        LOOP WHILE Collision()

        THIS.Address = MonsterAddress
        THIS.Alive = TRUE

        CALL THIS.Draw()
    END SUB

    SUB Update(dx AS INT, dy AS INT) STATIC
        THIS.x = THIS.x + dx
        THIS.y = THIS.y + dy

        'CALL THIS.Clear()
        THIS.Address = MonsterAddress
        CALL THIS.Draw()
    END SUB

    SUB Move() STATIC
        IF RNDB() >= MonsterSpeed THEN
            EXIT SUB
        END IF

        DIM dx AS INT
        DIM dy AS INT

        dx = SGN(SHR(PlayerXi, 3) - THIS.x)
        dy = SGN(SHR(PlayerYi, 3) - THIS.y)

        MonsterAddress = THIS.Address + 40 * dy + dx
        CALL THIS.Clear()

        IF Collision() THEN
            MonsterAddress = THIS.Address + dx
            IF Collision() THEN
                MonsterAddress = THIS.Address + 40 * dy
                IF Collision() THEN
                    MonsterAddress = THIS.Address
                    CALL THIS.Update(0, 0)
                ELSE
                    CALL THIS.Update(0, dy)
                END IF
            ELSE
                CALL THIS.Update(dx, 0)
            END IF
        ELSE
            CALL THIS.Update(dx, dy)
        END IF
    END SUB
END TYPE

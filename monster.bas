FUNCTION AddBlood AS BYTE(bg AS BYTE) STATIC
    IF (bg = 196) OR (bg = 212) THEN
        RETURN bg
    END IF
    RETURN bg + 1
END FUNCTION


TYPE MONSTER
    Alive AS BYTE
    x AS INT
    y AS INT

    Address AS WORD
    NextAddress AS WORD

    bg0 AS BYTE
    bg1 AS BYTE
    bg2 AS BYTE
    bg3 AS BYTE

    FUNCTION Collision AS BYTE() STATIC
        IF PEEK(THIS.NextAddress) < 192 THEN RETURN TRUE
        IF PEEK(THIS.NextAddress + 1) < 192 THEN RETURN TRUE
        IF PEEK(THIS.NextAddress + 40) < 192 THEN RETURN TRUE
        IF PEEK(THIS.NextAddress + 41) < 192 THEN RETURN TRUE
        RETURN FALSE
    END FUNCTION

    SUB ChangeCostume() STATIC
        POKE THIS.Address, PEEK(THIS.Address) XOR 2
        POKE THIS.Address+1, PEEK(THIS.Address+1) XOR 2
        POKE THIS.Address+40, PEEK(THIS.Address+40) XOR 2
        POKE THIS.Address+41, PEEK(THIS.Address+41) XOR 2
    END SUB

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
                    THIS.y = random(0, 18)
                CASE 2
                    ' BOTTOM
                    THIS.x = random(0, 38)
                    THIS.y = 18
                CASE 3
                    ' RIGHT
                    THIS.x = 38
                    THIS.y = random(0, 18)
            END SELECT

            THIS.NextAddress = SCRMEM + THIS.x + THIS.y * 40
        LOOP WHILE THIS.Collision() = TRUE

        THIS.Address = THIS.NextAddress
        THIS.Alive = TRUE

        CALL THIS.Draw()
    END SUB

    SUB Update(dx AS INT, dy AS INT) STATIC
        THIS.x = THIS.x + dx
        THIS.y = THIS.y + dy

        'CALL THIS.Clear()
        THIS.Address = THIS.NextAddress
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

        THIS.NextAddress = THIS.Address + 40 * dy + dx
        CALL THIS.Clear()

        IF THIS.Collision() = FALSE THEN
            CALL THIS.Update(dx, dy)
        ELSE
            THIS.NextAddress = THIS.Address + dx
            IF THIS.Collision() = FALSE THEN
                CALL THIS.Update(dx, 0)
            ELSE
                THIS.NextAddress = THIS.Address + 40 * dy
                IF THIS.Collision() = FALSE THEN
                    CALL THIS.Update(0, dy)
                ELSE
                    THIS.NextAddress = THIS.Address
                    CALL THIS.Update(0, 0)
                END IF
            END IF
        END IF
    END SUB
END TYPE

'INCLUDE "lib_memory.bas"
'INCLUDE "lib_types.bas"
'INCLUDE "lib_irq.bas"

DIM SHARED spr_vic_bank_ptr AS BYTE
DIM SHARED spr_vic_bank_addr AS WORD

DIM spr_x_coll(MAX_NUM_SPRITES) AS BYTE
DIM spr_x_lo(MAX_NUM_SPRITES) AS BYTE
DIM spr_x_hi(MAX_NUM_SPRITES) AS BYTE
DIM spr_y(MAX_NUM_SPRITES) AS BYTE SHARED

SUB SprInit(VicBankPtr AS BYTE, ScreenMemPtr AS BYTE) SHARED STATIC
    ASM
        ;-----------------------------
        ;init sprite properties
        ldx #MAXSPR

spr_init_loop
        dex
        bmi spr_init_end

        lda #0
        sta {spr_x_coll},x
        sta {Spr_EdgeWest},x
        sta {Spr_EdgeNorth},x
        sta {SprCollision},x

        lda #12
        sta {Spr_EdgeEast},x

        lda #21
        sta {Spr_EdgeSouth},x

        jmp spr_init_loop
spr_init_end
    END ASM
END SUB

SUB SprXY(SprNr AS BYTE, x AS INT, y AS INT) SHARED STATIC
    ASM
        ldx {SprNr}

sprxy_y
        clc                     ; spr_reg_xy(SprNr).y = y + 50
        lda {y}
        adc #40
        sta {y}

        lda {y}+1
        adc #0
        sta {y}+1
        bne sprxy_oob

        lda {y}
        ;cmp #30
        ;bcc sprxy_oob

        ;cmp #200
        ;bcs sprxy_oob

        sta {spr_y},x

sprxy_x
        clc                     ; spr_reg_xy(SprNr).y = y + 50
        lda {x}
        adc #12
        sta {spr_x_lo},x

        lda {x}+1
        adc #0
        sta {spr_x_hi},x

        beq sprxy_x_ok
        cmp #1
        bne sprxy_oob

        lda {spr_x_lo},x
        cmp #88
        bcs sprxy_oob

sprxy_x_ok
        lda {spr_x_hi},x
        lsr
        lda {spr_x_lo},x
        ror
        sta {spr_x_coll},x

        jmp sprxy_end

sprxy_oob
        lda #$ff
        sta {spr_y},x

sprxy_end
    END ASM
END SUB

FUNCTION SprRecordCollisions AS BYTE(SprNr AS BYTE) SHARED STATIC
    ASM
        lda #0
        sta {SprRecordCollisions}

        ldy {SprNr}
        ldx #MAXSPR
        dex
        lda {spr_y},y
        cmp #$ff
        bne spr_collision_loop

        lda #0
spr_collision_disabled_loop:
        sta {SprCollision},x
        dex
        bpl spr_collision_disabled_loop

        jmp spr_collision_end

spr_collision_loop:
        lda {spr_y},x
        cmp #$ff
        beq spr_collision_false

spr_collision_check_y:
        sec
        ;lda {spr_y},x                       ; Load Enemy Y position
        sbc {spr_y},y                       ; Subtract Player Y position
        bcs spr_collision_enemy_is_lower    ; enemy_y >= player_y
        eor #$ff                            ; Negate result
        adc #1                              ; carry must be clear
                                            ; - absolute distance from top-left to top-left is in a
                                            ; - player is right from enemy
spr_collision_enemy_is_higher
        sec
        sbc {Spr_EdgeSouth},x
        bcc spr_collision_check_x
        sbc {Spr_EdgeNorth},y
        bcs spr_collision_false
        bcc spr_collision_check_x

spr_collision_enemy_is_lower
        sec
        sbc {Spr_EdgeNorth},x
        bcc spr_collision_check_x
        sbc {Spr_EdgeSouth},y
        bcs spr_collision_false

spr_collision_check_x
        sec
        lda {spr_x_coll},x                       ; Enemy X coordinate
        sbc {spr_x_coll},y                       ; Player X coordinate
        bcs spr_collision_enemy_is_right
        eor #$ff                            ; Negate result
        adc #1

spr_collision_enemy_is_left
        sec
        sbc {Spr_EdgeEast},x
        bcc spr_collision_true
        sbc {Spr_EdgeWest},y
        bcs spr_collision_false
        bcc spr_collision_true

spr_collision_enemy_is_right
        sec
        sbc {Spr_EdgeWest},x
        bcc spr_collision_true
        sbc {Spr_EdgeEast},y
        bcs spr_collision_false

spr_collision_true:
        lda #$ff
        dc.b $2c                            ; BIT instruction that skips next LDA

spr_collision_false:
        lda #$00
        sta {SprCollision},x

        ora {SprRecordCollisions}
        sta {SprRecordCollisions}

        dex                                 ; Goes to next sprite
        bpl spr_collision_loop

spr_collision_end:
        lda #0
        sta {SprCollision},y
    END ASM
END FUNCTION

REM **************************************
REM Spritemultiplexer adaptation
REM
REM Based on:
REM Spritemultiplexing example V2.1
REM by Lasse Öörni (loorni@gmail.com)
REM Available at http://cadaver.github.io
REM **************************************

SUB SprUpdate(Blocking AS BYTE) SHARED STATIC
    ASM
waitloop1:      lda {sprupdateflag}         ;Wait until the flag turns back
                bne waitloop1               ;to zero
                inc {sprupdateflag}         ;Signal to IRQ: sort the
                lda {blocking}              ;sprites
                beq non_blocking
waitloop2:      lda {sprupdateflag}         ;Wait until the flag turns back
                bne waitloop2               ;to zero
non_blocking:
    END ASM
END SUB
'INCLUDE "lib_color.bas"
'INCLUDE "lib_memory.bas"
'INCLUDE "lib_char.bas"

DECLARE SUB WaitRasterLine256() SHARED STATIC

DIM text_y_tbl_hi(25) AS BYTE @49152
DIM text_y_tbl_lo(25) AS BYTE @49177

TYPE ScreenText
    BorderColor AS BYTE
    ScreenColor AS BYTE

    vic_bank_ptr AS BYTE
    vic_bank_addr AS WORD
    scr_mem_ptr AS BYTE
    scr_mem_addr AS WORD

    char_mem_ptr AS BYTE
    char_mem_addr AS WORD

    SUB Init(VicBankPtr AS BYTE, ScreenMemPtr AS BYTE, CharMemPtr AS BYTE) STATIC OVERLOAD
        THIS.vic_bank_ptr = VicBankPtr
        THIS.scr_mem_ptr = ScreenMemPtr
        THIS.char_mem_ptr = CharMemPtr
        THIS.BorderColor = COLOR_LIGHTBLUE
        THIS.ScreenColor = COLOR_BLUE

        ASM
            lda #0
            sta {ZP_W0}
            sta {ZP_W1}
            sta {ZP_W2}

            lda {VicBankPtr}        ;16384 * CWORD(VicBankPtr)
            lsr
            ror
            ror
            sta {ZP_W0}+1

            lda {CharMemPtr}
            asl
            asl
            asl

            clc
            adc {ZP_W0}+1
            sta {ZP_W1}+1

            lda {ScreenMemPtr}      ;vic_bank_addr + 1024 * ScreenMemPtr
            asl
            asl

            clc
            adc {ZP_W0}+1
            sta {ZP_W2}+1
        END ASM

        THIS.vic_bank_addr = ZP_W0
        THIS.scr_mem_addr = ZP_W2
        THIS.char_mem_addr = ZP_W1
    END SUB

    SUB Init() STATIC OVERLOAD
        CALL THIS.Init(0, 1, 2)
    END SUB

    SUB Focus() STATIC
        ZP_W0 = THIS.scr_mem_addr
        ASM
            ldy #0
text_focus_loop
            lda {ZP_W0}
            sta {text_y_tbl_lo},y
            lda {ZP_W0}+1
            sta {text_y_tbl_hi},y

            clc
            lda {ZP_W0}
            adc #40
            sta {ZP_W0}
            lda {ZP_W0}+1
            adc #0
            sta {ZP_W0}+1

            iny
            cmp #25
            bne text_focus_loop
        END ASM
    END SUB

    SUB UseCharSet(CharacterSet AS TypeCharSet) STATIC
        ' Activate charmem from "addr" relative to VIC bank
        IF CharacterSet.vic_bank_ptr <> THIS.vic_bank_ptr THEN ERROR 100
        THIS.char_mem_ptr = CharacterSet.char_mem_ptr
        THIS.char_mem_addr = CharacterSet.char_mem_addr
    END SUB

    SUB Show() STATIC
        CALL WaitRasterLine256()

        ZP_B0 = THIS.vic_bank_ptr
        ZP_B1 = THIS.scr_mem_ptr
        ZP_B2 = THIS.char_mem_ptr

        ASM
            ; REM Vic Bank
            ; POKE $dd00, (PEEK($dd00) AND %11111100) OR (THIS.vic_bank_ptr XOR %11)
            lda $dd00
            and #%11111100
            ora {ZP_B0}
            eor #%00000011
            sta $dd00

            ; REM -- Bitmap mode off
            ; POKE $d011, %00011011
            lda #%00011011
            sta $d011

            ; REM -- Screen address
            ; POKE $d018, SHL(THIS.scr_mem_ptr, 4) OR SHL(THIS.char_mem_ptr, 1)
            lda {ZP_B1}
            asl
            asl
            asl
            asl
            sta {ZP_B1}
            lda {ZP_B2}
            asl
            ora {ZP_B1}
            sta $d018

            ; REM -- Multicolor mode
            ; POKE $d016, %11001000
            lda #%11001000
            sta $d016
        END ASM

        RegBorderColor = THIS.BorderColor
        RegScreenColor = THIS.ScreenColor

    END SUB

    SUB Fill(Char AS BYTE, InkColor AS BYTE) STATIC
        MEMSET THIS.scr_mem_addr, 1000, Char
        MEMSET $D800, 1000, InkColor
    END SUB

    SUB Clear() STATIC
        CALL THIS.Fill(32, COLOR_LIGHTBLUE)
    END SUB

    SUB Import(ScrAddr AS WORD, ColorAddr AS WORD) STATIC
        MEMCPY ScrAddr, THIS.scr_mem_addr, 1000
        MEMCPY ColorAddr, $d800, 1000
    END SUB

    SUB CharacterAt(x AS BYTE, y AS BYTE, Char AS BYTE, InkColor AS BYTE) STATIC OVERLOAD
        ZP_W0 = 40 * CWORD(y) + x
        POKE THIS.scr_mem_addr + ZP_W0, Char
        POKE $d800 + ZP_W0, InkColor
    END SUB

    SUB CharacterAt(x AS BYTE, y AS BYTE, Char AS BYTE) STATIC OVERLOAD
        POKE THIS.scr_mem_addr + 40 * CWORD(y) + x, Char
    END SUB

    FUNCTION CharacterAt AS BYTE(x AS BYTE, y AS BYTE) STATIC OVERLOAD
        RETURN PEEK(THIS.scr_mem_addr + 40 * CWORD(y) + x)
    END FUNCTION

    FUNCTION ColorAt AS BYTE(x AS BYTE, y AS BYTE) STATIC OVERLOAD
        RETURN PEEK($d800 + 40 * CWORD(y) + x)
    END FUNCTION

    SUB CentreText(y AS BYTE, s AS STRING * 40) STATIC
        ASM
            ldy {y}
            lda {text_y_tbl_lo},y
            sta {ZP_W0}
            lda {text_y_tbl_hi},y
            sta {ZP_W0}+1
            
            sec
            lda #40
            sbc {s}
            lsr

            clc
            adc {ZP_W0}
            sta {ZP_W0}

            lda {ZP_W0}+1
            adc #0
            sta {ZP_W0}+1

            ldy {s}
text_centre_text_loop
            cpy #0
            beq text_centre_text_end

            lda {s}+1,y
            sta {ZP_W0},y

            dey
            jmp text_centre_text_loop

text_centre_text_end
        END ASM
    END SUB
END TYPE

SUB WaitRasterLine256() SHARED STATIC
    ASM
wait1:  bit $d011
        bmi wait1
wait2:  bit $d011
        bpl wait2
    END ASM
END SUB


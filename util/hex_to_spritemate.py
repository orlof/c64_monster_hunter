import re
import json

def apply_rules(input_list):
    result = []
    i = 0
    while i < len(input_list):
        if i+1 < len(input_list):
            if input_list[i] == 0 and input_list[i+1] == 0:
                result.extend([0, 0])
            elif input_list[i] == 0 and input_list[i+1] == 1:
                result.extend([1, 0])
            elif input_list[i] == 1 and input_list[i+1] == 0:
                result.extend([2, 0])
            elif input_list[i] == 1 and input_list[i+1] == 1:
                result.extend([3, 0])
            i += 2
        else:
            raise Exception("Error: input_list has odd length.")
    return result

def merge_consecutive_lists(list_of_lists):
    merged_lists = []
    for i in range(0, len(list_of_lists), 3):
        merged_inner_list = []
        for inner_list in list_of_lists[i:i+3]:
            merged_inner_list.extend(inner_list)
        merged_lists.append(merged_inner_list)
    return merged_lists

def extract_bits(byte):
    return [int(bit) for bit in f"{byte:08b}"]

def parse_costume(data):
    #costume_data = re.findall(r"\$([0-9a-fA-F]{2})", data)
    pixels = [extract_bits(int(byte, 16)) for byte in data]
    pixels = merge_consecutive_lists(pixels)

    new_pixels = []
    for pixel in pixels:
        new_pixels.append(apply_rules(pixel))

    return new_pixels

costume_data = """
_costume_hero_e:
    .byte $00,$00,$00,$00,$00,$00,$00,$00
    .byte $00,$00,$00,$00,$00,$00,$00,$0f
    .byte $40,$00,$3f,$d0,$00,$d7,$f4,$00
    .byte $d5,$7d,$00,$55,$0f,$00,$55,$03
    .byte $80,$55,$a9,$a8,$d6,$aa,$a8,$da
    .byte $f4,$00,$ff,$d0,$00,$1f,$40,$00
    .byte $05,$00,$00,$00,$00,$00,$00,$00
    .byte $00,$00,$00,$00,$00,$00,$00,$00
_costume_hero_se:
    .byte $00,$00,$00,$03,$40,$00,$05,$f0
    .byte $00,$35,$74,$00,$15,$7d,$00,$d5
    .byte $7f,$00,$d5,$47,$00,$d5,$43,$00
    .byte $76,$63,$00,$3f,$ab,$00,$1f,$fb
    .byte $80,$0f,$49,$80,$05,$02,$00,$00
    .byte $02,$40,$00,$00,$80,$00,$00,$90
    .byte $00,$00,$20,$00,$00,$20,$00,$00
    .byte $00,$00,$00,$00,$00,$00,$00,$00
_costume_hero_s:
    .byte $00,$d7,$00,$00,$d7,$00,$03,$55
    .byte $40,$03,$55,$c0,$07,$55,$c0,$07
    .byte $95,$d0,$07,$a7,$f0,$07,$e7,$f0
    .byte $03,$e1,$f0,$01,$e1,$d0,$01,$e3
    .byte $c0,$00,$63,$40,$00,$2f,$00,$00
    .byte $25,$00,$00,$28,$00,$00,$28,$00
    .byte $00,$20,$00,$00,$20,$00,$00,$20
    .byte $00,$00,$20,$00,$00,$00,$00,$00
_costume_hero_sw:
    .byte $00,$00,$00,$00,$01,$c0,$00,$0f
    .byte $50,$00,$1d,$50,$00,$1d,$54,$00
    .byte $3a,$54,$00,$39,$54,$00,$39,$54
    .byte $00,$18,$5c,$00,$28,$3c,$00,$20
    .byte $74,$00,$21,$f0,$00,$9f,$d0,$01
    .byte $bf,$40,$02,$24,$00,$06,$20,$00
    .byte $08,$00,$00,$08,$00,$00,$00,$00
    .byte $00,$00,$00,$00,$00,$00,$00,$00
_costume_hero_w:
    .byte $00,$00,$00,$00,$00,$00,$00,$00
    .byte $00,$00,$00,$00,$00,$00,$50,$00
    .byte $01,$f4,$00,$07,$ff,$00,$1f,$a7
    .byte $2a,$aa,$97,$2a,$6a,$55,$02,$c0
    .byte $55,$00,$f0,$55,$00,$7d,$57,$00
    .byte $1f,$d7,$00,$07,$fc,$00,$01,$f0
    .byte $00,$00,$00,$00,$00,$00,$00,$00
    .byte $00,$00,$00,$00,$00,$00,$00,$00
_costume_hero_nw:
    .byte $00,$00,$00,$00,$00,$00,$00,$00
    .byte $00,$08,$00,$00,$08,$00,$00,$06
    .byte $00,$00,$02,$00,$00,$01,$80,$00
    .byte $00,$80,$50,$02,$61,$f0,$02,$ef
    .byte $f4,$00,$ea,$fc,$00,$c9,$9d,$00
    .byte $c1,$57,$00,$d1,$57,$00,$fd,$57
    .byte $00,$7d,$54,$00,$1d,$5c,$00,$0f
    .byte $50,$00,$01,$c0,$00,$00,$00,$00
_costume_hero_n:
    .byte $00,$00,$00,$00,$08,$00,$00,$08
    .byte $00,$00,$08,$00,$00,$08,$00,$00
    .byte $28,$00,$00,$28,$00,$00,$58,$00
    .byte $00,$f8,$00,$01,$c9,$00,$03,$cb
    .byte $40,$07,$4b,$40,$0f,$4b,$c0,$0f
    .byte $db,$d0,$0f,$da,$d0,$07,$56,$d0
    .byte $03,$55,$d0,$03,$55,$c0,$01,$55
    .byte $c0,$00,$d7,$00,$00,$d7,$00,$00
_costume_hero_ne:
    .byte $00,$00,$00,$00,$00,$00,$00,$00
    .byte $00,$00,$00,$20,$00,$00,$20,$00
    .byte $08,$90,$00,$18,$80,$01,$fe,$40
    .byte $07,$f6,$00,$0f,$48,$00,$1d,$08
    .byte $00,$3c,$28,$00,$35,$24,$00,$15
    .byte $6c,$00,$15,$6c,$00,$15,$ac,$00
    .byte $15,$74,$00,$05,$74,$00,$05,$f0
    .byte $00,$03,$40,$00,$00,$00,$00,$00
"""

costume_names = [
    "_costume_hero_e",
    "_costume_hero_se",
    "_costume_hero_s",
    "_costume_hero_sw",
    "_costume_hero_w",
    "_costume_hero_nw",
    "_costume_hero_n",
    "_costume_hero_ne"
]

sprites = []

costume_data = re.findall(r"\$([0-9a-fA-F]{2})", costume_data)
print("Costume data length: " + str(len(costume_data)))
start = 0

for name in costume_names:
    sprite_data = parse_costume(costume_data[start:start+64])
    sprite_data = sprite_data[0:21]
    start += 64
    sprites.append({
        "name": name,
        "color": 11,
        "multicolor": True,
        "double_x": False,
        "double_y": False,
        "overlay": False,
        "pixels": sprite_data
    })

spritemate_data = {
    "version": 1.3,
    "colors": {
        "0": 8,
        "2": 0,
        "3": 5
    },
    "sprites": sprites,
    "current_sprite": 1,
    "pen": 1
}

with open("combined_sprites.spm", "w") as file:
    json.dump(spritemate_data, file, indent=2)

print("Combined SpriteMate JSON file created!")

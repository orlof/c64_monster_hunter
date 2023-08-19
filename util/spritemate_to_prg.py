import json

address = 0xcc00

def load_spritemate_file(filename):
    with open(filename, "r") as file:
        spritemate_data = json.load(file)
    return spritemate_data

def extract_pixels_arrays(spritemate_data):
    pixels_arrays = []
    sprites = spritemate_data.get("sprites", [])
    for sprite in sprites:
        pixels = sprite.get("pixels", [])
        pixels_arrays.append(pixels)
    return pixels_arrays

def convert_to_bytes(bits_list):
    bytes_list = []
    for i in range(0, len(bits_list), 8):
        byte_bits = bits_list[i:i+8]
        byte_value = 0
        for bit in byte_bits:
            byte_value = (byte_value << 1) | bit
        bytes_list.append(byte_value)
    return bytes_list

# Example usage
filename = "data/mysprites (1).spm"  # Replace with your desired filename
loaded_data = load_spritemate_file(filename)

all_bytes = []

for sprite in loaded_data.get("sprites", []):
    if sprite.get("multicolor"):
        pixels = sprite.get("pixels")
        for row in pixels:
            row = row[0:24:2]  # Remove every other pixel
            pix = []
            for pixel in row:
                if pixel == 0:
                    pix.append(0)
                    pix.append(0)
                elif pixel == 1:
                    pix.append(0)
                    pix.append(1)
                elif pixel == 2:
                    pix.append(1)
                    pix.append(0)
                elif pixel == 3:
                    pix.append(1)
                    pix.append(1)
            all_bytes.extend(convert_to_bytes(pix))
    else:
        pixels = sprite.get("pixels")
        for row in pixels:
            all_bytes.extend(convert_to_bytes(row))
    all_bytes.append(0)  # Add a zero byte between sprites

if any(map(lambda x: x > 255, all_bytes)):
    raise Exception("Error: sprite data contains values > 255.")

data = bytes((address % 256, address // 256)) + bytes(all_bytes)

with open("data/sprite_data.prg", "wb") as output_file:
    output_file.write(data)

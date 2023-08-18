import sys
import os

def read_sid_file(file_path):
    with open(file_path, "rb") as f:
        data = f.read()

    if data[:4] != b'PSID':
        raise ValueError("Not a valid SID file.")

    version = int.from_bytes(data[0x4:0x6], byteorder='big')
    header_length = 0x76 if version == 1 else 0x7c

    # base_address = int.from_bytes(data[0x7C:0x7E], byteorder='little')
    init_vector = int.from_bytes(data[0x0A:0x0C], byteorder='big')
    play_vector = int.from_bytes(data[0x0C:0x0E], byteorder='big')

    prg_data = data[header_length:]

    return init_vector, play_vector, prg_data

def write_prg_file(output_path, data):
    with open(output_path, "wb") as f:
        f.write(data)

def main(sid_file_path):
    if not sid_file_path.lower().endswith('.sid'):
        print("Input file must have a .sid extension.")
        return

    output_prg_file_path = sid_file_path[:-4] + ".prg"
    output_bin_file_path = sid_file_path[:-4] + ".bin"

    try:
        init_vector, play_vector, prg_data = read_sid_file(sid_file_path)

        write_prg_file(output_prg_file_path, prg_data)
        write_prg_file(output_bin_file_path, prg_data[2:])

        base = int.from_bytes(prg_data[0:2], byteorder='little')

        print("Memory:", hex(base), "-", hex(base + (len(prg_data)-2)))
        print("Init Vector:", hex(init_vector))
        print("Play Vector:", hex(play_vector))
        print(f"PRG file written without SID header: {output_prg_file_path}")
    except Exception as e:
        print(f"An error occurred: {e}")

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python script.py <sid_file_path>")
        sys.exit(1)
    sid_file_path = sys.argv[1]
    main(sid_file_path)

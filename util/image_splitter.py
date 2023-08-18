import sys

def main(input_filename, bitmap, screenram, colorram):
    # Read input file
    with open(input_filename, "rb") as input_file:
        idata = input_file.read()

    # Extract data for each output file
    ptr = 1024 * bitmap
    data = bytes((ptr % 256, ptr // 256)) + idata[:8000]  # Prepend bytes $00 and $E0
    with open("data/title_bitmap.prg", "wb") as output_file:
        output_file.write(data)

    ptr = 1024 * screenram
    data = bytes((ptr % 256, ptr // 256)) + idata[8000:9000]
    with open("data/title_screenram.prg", "wb") as output_file:
        output_file.write(data)

    ptr = 1024 * colorram
    data = bytes((ptr % 256, ptr // 256)) + idata[9000:10000]
    with open("data/title_colorram.prg", "wb") as output_file:
        output_file.write(data)

    # Print last two bytes as hex values
    print("0xd020:", format(idata[-2], "02X"))
    print("0xd021:", format(idata[-1], "02X"))

if __name__ == "__main__":
    if len(sys.argv) != 5:
        print("Usage: python program.py input_filename bitmap screenram colorram")
        sys.exit(1)

    input_filename = sys.argv[1]
    bitmap = int(sys.argv[2])
    screenram = int(sys.argv[3])
    colorram = int(sys.argv[4])

    main(input_filename, bitmap, screenram, colorram)

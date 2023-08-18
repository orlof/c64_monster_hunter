FUNCTION random AS BYTE(min AS BYTE, max AS BYTE) SHARED STATIC
    STATIC range AS BYTE: range = max - min

    STATIC mask AS BYTE: mask = 1
    DO
        if range < mask THEN EXIT DO
        mask = SHL(mask, 1)
    LOOP UNTIL mask = 0

    mask = mask - 1

    DO
        random = RNDB() AND mask
    LOOP UNTIL random <= range
    random = random + min
END FUNCTION

FUNCTION random16 AS WORD(min AS WORD, max AS WORD) SHARED STATIC
    STATIC range AS WORD: range = max - min

    STATIC mask AS WORD: mask = 1
    DO
        if range < mask THEN EXIT DO
        mask = SHL(mask, 1)
    LOOP UNTIL mask = 0

    mask = mask - 1

    DO
        random16 = RNDW() AND mask
    LOOP UNTIL random16 <= range
    random16 = random16 + min
END FUNCTION

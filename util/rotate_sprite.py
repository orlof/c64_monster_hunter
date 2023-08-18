import math
import json

class Point:
    def __init__(self, x, y, weight):
        self.x = x
        self.y = y
        self.weight = weight


data = [
[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,0,0,0,0,0,0],
[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,0,0,0,0,0,0],
[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,0,0,0,0,0,0,0],
[0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,0,0,0,0,0,0,0],
[0,0,0,0,0,0,0,0,1,1,0,0,0,0,1,1,0,0,0,0,0,0,0,0],
[0,0,0,0,0,0,0,1,0,0,0,1,1,1,1,1,0,0,0,0,0,0,0,0],
[0,0,0,0,0,0,1,0,0,0,1,0,0,1,1,0,0,0,0,0,0,0,0,0],
[0,0,0,0,0,1,0,0,0,1,0,0,0,1,1,0,0,0,0,0,0,0,0,0],
[0,0,0,0,0,1,0,0,1,1,0,0,1,1,1,1,0,0,0,0,0,0,0,0],
[0,0,0,0,0,1,0,1,0,0,1,1,1,1,0,1,0,0,0,0,0,0,0,0],
[0,0,0,0,0,1,1,0,0,0,0,1,1,0,0,1,0,0,0,0,0,0,0,0],
[0,0,0,0,0,0,1,0,0,0,0,1,1,0,1,0,0,0,0,0,0,0,0,0],
[0,0,0,0,0,0,1,1,0,0,1,1,0,0,1,0,0,0,0,0,0,0,0,0],
[0,0,0,0,0,0,0,1,1,1,0,0,0,0,1,0,0,0,0,0,0,0,0,0],
[0,0,0,0,0,0,0,1,0,0,0,0,1,1,0,0,0,0,0,0,0,0,0,0],
[0,0,0,0,0,0,0,0,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0],
[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
]

def rotate_point(x, y, angle_deg):
    angle_rad = math.radians(angle_deg)
    new_x = x * math.cos(angle_rad) - y * math.sin(angle_rad)
    new_y = x * math.sin(angle_rad) + y * math.cos(angle_rad)
    return new_x, new_y

def rotate_sprite(data, degrees):
    num_points = 0

    y = 20
    result = [[0.0] * 100 for _ in range(100)]

    for row in data:
        x = 0
        for col in row:
            val = data[y][x]
            if val == 1:
                num_points += 1
                new_x, new_y = rotate_point(x, y, degrees)
                new_x += 50
                new_y += 50
                new_x_lo = int(new_x)
                new_x_hi = new_x_lo + 1
                new_x_lo_weight = 1 - (new_x - new_x_lo)
                new_x_hi_weight = new_x - new_x_lo
                new_y_lo = int(new_y)
                new_y_hi = new_y_lo + 1
                new_y_lo_weight = 1 - (new_y - new_y_lo)
                new_y_hi_weight = new_y - new_y_lo

                result[new_y_lo][new_x_lo] += new_x_lo_weight * new_y_lo_weight
                result[new_y_lo][new_x_hi] += new_x_hi_weight * new_y_lo_weight
                result[new_y_hi][new_x_lo] += new_x_lo_weight * new_y_hi_weight
                result[new_y_hi][new_x_hi] += new_x_hi_weight * new_y_hi_weight
            x += 1
        y -= 1

    points = []

    x_min, y_min = 100, 100
    for y in range(0, 100):
        for x in range(0, 100):
            if result[y][x] > 0:
                if x < x_min:
                    x_min = x
                if y < y_min:
                    y_min = y
                points.append(Point(x, y, result[y][x]))

    x_max, y_max = x_min + 21, y_min + 24

    points.sort(key=lambda p: p.weight, reverse=True)

    rotated = [[0] * 24 for _ in range(21)]

    while points and points[0].weight >= 0.4:
        num_points -= 1
        p = points.pop(0)
        if p.x >= x_min and p.x < x_max and p.y >= y_min and p.y < y_max:
            rotated[p.y - y_min][p.x - x_min] = 1

    print(json.dumps(rotated))


rotate_sprite(data, 90)
rotate_sprite(data, 180)
rotate_sprite(data, 270)


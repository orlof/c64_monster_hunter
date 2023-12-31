import math

def calculate_coordinates(angle_degrees, distance):
    angle_radians = math.radians(angle_degrees)
    x = distance * math.cos(angle_radians)
    y = distance * math.sin(angle_radians)
    return x, y

def print_table(distance, title, angle=0.0):
    step = 22.5
    cur_angle = 0.0
    xs = []
    ys = []
    while cur_angle < 360.0:
        x, y = calculate_coordinates(-(angle + cur_angle), distance)  # Using distance 100
        x_rounded = round(x)
        y_rounded = round(y)
        xs.append(x_rounded)
        ys.append(y_rounded)
        cur_angle += step
    print(f"_{title}_X:")
    print("    DATA AS LONG %s" % ", ".join([str(x) for x in xs]))
    print(f"_{title}_Y:")
    print("    DATA AS LONG %s" % ", ".join([str(y) for y in ys]))

print("REM HERO FORWARD")
print_table(100, "HERO_FWD")
print("REM HERO BACKWARD")
print_table(50, "HERO_BWD", 180)
print("REM BULLET FORWARD")
print_table(512, "BULLET_FWD")


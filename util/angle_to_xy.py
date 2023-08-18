import math

def calculate_coordinates(angle_degrees, distance):
    angle_radians = math.radians(angle_degrees)
    x = distance * math.cos(angle_radians)
    y = distance * math.sin(angle_radians)
    return x, y

def print_table(distance):
    step = 22.5
    angle = 0.0
    while angle <= 360.0:
        x, y = calculate_coordinates(angle, distance)  # Using distance 100
        x_rounded = round(x)
        y_rounded = round(y)
        print(f"DATA AS INT {x_rounded}, {y_rounded}")
        angle += step

print("REM HERO FORWARD")
print_table(100)
print("REM HERO BACKWARD")
print_table(50)
print("REM BULLET FORWARD")
print_table(200)


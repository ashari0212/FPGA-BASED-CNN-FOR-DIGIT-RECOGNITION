import numpy as np
import cv2

pixels = []
with open("in_32.hex", "r") as f:
    for line in f:
        line = line.strip()
        if len(line) == 8:
            # Unpack the 4 pixels (2 hex chars each) from the 32-bit line
            pixels.append(int(line[0:2], 16))
            pixels.append(int(line[2:4], 16))
            pixels.append(int(line[4:6], 16))
            pixels.append(int(line[6:8], 16))

# Reshape back to 32x32 and save as an image
img = np.array(pixels, dtype=np.uint8).reshape(32, 32)
cv2.imwrite("what_the_fpga_saw.png", img)
print("Saved! Open what_the_fpga_saw.png to see the digit.")

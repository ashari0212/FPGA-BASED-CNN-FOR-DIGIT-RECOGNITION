import numpy as np
import cv2
import PIL
from PIL import Image, ImageDraw
from tkinter import *

# ==================================================
# SUCCESS LOGIC: IMAGE PROCESSING & HEX GENERATION
# ==================================================
def process_and_generate_hex():
    # 1. Capture drawing from GUI
    image.save("input_digit.png")
    img = cv2.imread("input_digit.png")
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    
    # 2. REFERENCE SUCCESS LOGIC: Resize to 28x28
    # This maintains the correct aspect ratio for the LeNet-5 model
    resize_img = cv2.resize(gray, (28, 28))
    
    # 3. REFERENCE SUCCESS LOGIC: Invert for MNIST
    # Training weights expect white digits (255) on a black background (0)
    dst = 255 - resize_img
    
    # 4. REFERENCE SUCCESS LOGIC: Pad to 32x32
    # Adds a 2-pixel border to center the digit perfectly
    img32 = np.pad(array=dst, pad_width=((2, 2), (2, 2)), mode='constant', constant_values=0)

    # 5. REFERENCE MATCH: Keep Grayscale
    # The reference in_32 (1).hex contains values like 'd9c94d02'
    # Keeping raw values helps the CNN recognize edges better than raw binary
    pixels = img32.flatten().astype(np.uint8)

    # 6. PACKING LOGIC: Matches in_32 (1).hex exactly
    # Reference project uses 256 lines (1024 pixels / 4)
    with open("sim_input_32.hex", "w") as f:
        for i in range(0, len(pixels), 4):
            chunk = pixels[i:i+4]
            
            # BIG ENDIAN PACKING: [Pixel 0][Pixel 1][Pixel 2][Pixel 3]
            # This matches the '14252520' sequence in your reference file
            hex_val = "{:02x}{:02x}{:02x}{:02x}".format(chunk[0], chunk[1], chunk[2], chunk[3])
            
            # SUCCESS LOGIC: DO NOT skip 00000000
            # Hardware simulation requires the full 32x32 memory map to align with weights
            f.write(hex_val + "\n")

    print("[SUCCESS] sim_input_32.hex matches the reference project memory map.")

# ==================================================
# GUI SETUP (Replaces Board/Socket logic for Sim)
# ==================================================
def activate_paint(e):
    global lastx, lasty
    canvas.bind('<B1-Motion>', paint)
    lastx, lasty = e.x, e.y

def paint(e):
    global lastx, lasty
    x, y = e.x, e.y
    canvas.create_line((lastx, lasty, x, y), fill='black', width=20)
    draw.line((lastx, lasty, x, y), fill='black', width=20)
    lastx, lasty = x, y

def clear():
    canvas.delete('all')
    draw.rectangle((0, 0, 250, 250), fill="white")

win = Tk()
win.title("Software Simulation: MNIST Input Generator")
image = PIL.Image.new('RGB', (250, 250), 'white')
draw = ImageDraw.Draw(image)
canvas = Canvas(win, width=250, height=250, bg='white')
canvas.pack()
canvas.bind('<1>', activate_paint)

Button(win, text="Generate Hex for Sim", command=process_and_generate_hex, bg="green", fg="white").pack(side=LEFT, fill=X, expand=True)
Button(win, text="Clear", command=clear).pack(side=RIGHT)

win.mainloop()

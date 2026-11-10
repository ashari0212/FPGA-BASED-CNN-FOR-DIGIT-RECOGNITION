"""
PC-only Receiver + Image Preprocessing
FPGA interaction REMOVED
Used ONLY to generate image.hex for Vivado simulation
"""

import socket
import tqdm
import os
import numpy as np
import cv2
import time

LABELS = ['0','1','2','3','4','5','6','7','8','9']

# --------------------------------------------------
# IMAGE PREPROCESSING (Vivado-compatible)
# --------------------------------------------------
def extract_data():
    print("[INFO] Processing image...")

    time.sleep(1)
    img = cv2.imread("./image.jpg")

    if img is None:
        print("[ERROR] image.jpg not found")
        return

    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)

    # Resize to MNIST size
    resize_img = cv2.resize(gray, (28, 28))

    # Invert (MNIST style)
    dst = 255 - resize_img

    # Pad to 32x32
    arr_2d = np.pad(dst, ((2,2),(2,2)), mode='constant')

    # Flatten
    arr_flat = arr_2d.flatten()

    # Save decimal (optional debug)
    np.savetxt("image_dec.mem", arr_flat, fmt="%d")

    # Convert to HEX
    hex_data = ['{:02x}'.format(v) for v in arr_flat]

    with open("image.hex", "w") as f:
        for val in hex_data:
            f.write(val + "\n")

    print("[INFO] image.hex generated (for Vivado BRAM)")

# --------------------------------------------------
# SOCKET RECEIVER
# --------------------------------------------------
def sckt():
    SERVER_HOST = "0.0.0.0"
    SERVER_PORT = 5001
    BUFFER_SIZE = 4096
    SEPARATOR = "<SEPARATOR>"

    s = socket.socket()
    s.bind((SERVER_HOST, SERVER_PORT))
    s.listen(5)

    print(f"[*] Listening on {SERVER_HOST}:{SERVER_PORT}")
    client_socket, address = s.accept()
    print(f"[+] Connected from {address}")

    received = client_socket.recv(BUFFER_SIZE).decode()
    filename, filesize = received.split(SEPARATOR)
    filename = os.path.basename(filename)
    filesize = int(filesize)

    progress = tqdm.tqdm(
        range(filesize),
        f"Receiving {filename}",
        unit="B",
        unit_scale=True,
        unit_divisor=1024
    )

    with open(filename, "wb") as f:
        while True:
            bytes_read = client_socket.recv(BUFFER_SIZE)
            if not bytes_read:
                break
            f.write(bytes_read)
            progress.update(len(bytes_read))

    client_socket.close()
    s.close()
    print("[INFO] File received successfully")

# --------------------------------------------------
# MAIN LOOP
# --------------------------------------------------
if __name__ == "__main__":
    while True:
        sckt()          # Receive image.jpg
        extract_data()  # Convert → image.hex

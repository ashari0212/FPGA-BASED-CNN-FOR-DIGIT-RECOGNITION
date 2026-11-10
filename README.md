# FPGA-Based CNN for Digit Recognition

A Verilog implementation of a convolutional neural network (CNN) for handwritten-digit recognition, with a Python drawing/preprocessing utility and a Vivado simulation flow targeting a Zynq-7000 development platform.

> **Project status:** The repository contains RTL and simulation assets, but the checked-in software does not currently demonstrate a complete PC-to-FPGA UART inference path. The Python GUI creates a simulation input file; the socket server is documented as a simulation helper. Verify the hardware integration and memory-file formats before describing this as a working real-time FPGA deployment.

## Repository contents

- `rtl/` — Verilog CNN and supporting processing/memory modules.
- `tb/` — testbench used to exercise the CNN in simulation.
- `software/` — Python drawing GUI and image preprocessing utilities.
- `test_inputs/` — sample input and memory initialization data.
- Vivado project files — project metadata and block-design sources.

## CNN architecture

The RTL datapath is organized into five main stages:

1. Convolution layer 1 followed by pooling
2. Convolution layer 2 followed by pooling
3. Convolution layer 3
4. Fully connected layer 1
5. Fully connected layer 2, producing the digit prediction

The processing element uses signed 8-bit input and weight values with a 32-bit accumulator. The RTL also includes optional ReLU and quantization logic.

## Software input flow

The Tkinter drawing application in `software/main1.py` lets a user draw a digit and prepares it for simulation:

1. Convert the drawing to grayscale.
2. Resize it to 28 × 28 pixels.
3. Invert and pad it to a 32 × 32 input.
4. Pack four pixel bytes into each 32-bit word.
5. Write the packed words to a HEX memory file.

The testbench loads the input and layer weight files from HEX files, runs the CNN, and prints the predicted digit.

## Running the Python utility

Use Python 3 and install the packages listed in `requirements.txt`. Tkinter is part of Python's standard library on many systems; on some Linux distributions it must be installed separately.

From the repository root:

```bash
python -m venv .venv
source .venv/bin/activate
python -m pip install --upgrade pip
pip install -r requirements.txt
python software/main1.py
```

On Windows, activate the environment with `.venv\\Scripts\\activate` instead.

## Running the Vivado simulation

1. Open the checked-in Vivado project in the Vivado version recorded by the project metadata (2025.2).
2. Confirm that the simulation top is `cnn_tb`.
3. Check that all HEX initialization files referenced by the testbench are available at the expected paths.
4. Run behavioral simulation and inspect the simulator transcript for the completion message and predicted digit.

The testbench expects the following weight files:

- `out_conv1_32.hex`
- `out_conv2_32.hex`
- `out_conv3_32.hex`
- `out_fc1_32.hex`
- `out_fc2_32.hex`

It also loads the packed input file `test_inputs/in_32.hex`. Adjust file paths in the testbench or Vivado simulation working directory if your local setup differs.

## Important validation items

- The Python socket server writes memory data in a different representation from the packed 32-bit words consumed by the testbench. Do not assume these files are interchangeable without checking the expected memory layout.
- The GUI currently prepares a HEX file; it does not itself establish a UART connection to the FPGA.
- Review the Zynq block-design top-level interface, RTL wrapper ports, and XDC pin/clock constraints together before programming a board. In particular, confirm the actual clock frequency and that the constrained ports match the selected hardware top.
- Check simulator warnings about HEX files containing more words than the target memory expects. Confirm the intended data depth and file contents before relying on the prediction.

## Target platform

The Vivado project metadata identifies a Zynq-7000 device, `xc7z020clg484-1`. Confirm your exact board and constraints before implementation or bitstream generation.

## License

No license information is currently specified. Add a license file if you intend others to reuse or distribute this project.

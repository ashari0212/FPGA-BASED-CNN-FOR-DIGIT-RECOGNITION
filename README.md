# FPGA-Based CNN for Handwritten Digit Recognition

A Verilog-based CNN accelerator project for handwritten-digit classification on a Xilinx Zynq-7000 platform. The repository includes the CNN RTL, a Vivado simulation testbench, memory initialization files, and a Python drawing utility for preparing digit images.

> **Current scope:** The repository provides RTL and simulation-related assets. The Python GUI prepares an input HEX file for simulation; a complete, verified PC-to-FPGA UART inference workflow is not currently demonstrated by the checked-in code.

## Overview

The project explores implementing a quantized CNN datapath in hardware. A user can draw a digit in the Python application, convert it into the format used by the simulation, and run the Verilog testbench to obtain a predicted digit.

### CNN datapath

The RTL is organized into these stages:

1. Convolution 1 and pooling
2. Convolution 2 and pooling
3. Convolution 3
4. Fully connected layer 1
5. Fully connected layer 2 and output prediction

The processing element operates on signed 8-bit input and weight values and uses a 32-bit accumulator. ReLU and quantization logic are also present in the RTL.

## Project structure

| Path | Description |
|---|---|
| `rtl/` | Verilog CNN, processing-element and memory modules |
| `tb/` | CNN simulation testbench |
| `software/` | Python drawing and image-preprocessing utilities |
| `test_inputs/` | Sample input and memory initialization data |
| Vivado project files | Vivado project and block-design sources |

## Software: prepare a digit image

The Tkinter application in `software/main1.py` provides a canvas for drawing a digit. Its input-preparation flow:

1. Converts the drawing to grayscale.
2. Resizes the image to 28 × 28 pixels.
3. Inverts and pads the image to 32 × 32 pixels.
4. Packs four pixel bytes into each 32-bit word.
5. Writes the packed words to a HEX file for simulation.

### Requirements

- Python 3
- NumPy
- OpenCV
- Pillow
- tqdm
- Tkinter (included with many Python installations; on some Linux systems it must be installed separately)

### Setup

Run these commands from the repository root.

**macOS / Linux**

```bash
python3 -m venv .venv
source .venv/bin/activate
python -m pip install --upgrade pip
pip install -r requirements.txt
python software/main1.py
```

**Windows (PowerShell)**

```powershell
py -m venv .venv
.venv\Scripts\Activate.ps1
python -m pip install --upgrade pip
pip install -r requirements.txt
python software/main1.py
```

## Hardware simulation with Vivado

The project metadata identifies Vivado 2025.2 and the Zynq-7000 device `xc7z020clg484-1`.

1. Open the Vivado project.
2. Check that `cnn_tb` is selected as the simulation top.
3. Confirm that the testbench can locate the input and weight HEX files.
4. Run behavioral simulation.
5. Review the simulator transcript for the completion message and predicted digit.

The testbench uses these layer-weight files:

- `out_conv1_32.hex`
- `out_conv2_32.hex`
- `out_conv3_32.hex`
- `out_fc1_32.hex`
- `out_fc2_32.hex`

The sample input file is `test_inputs/in_32.hex`. Depending on the Vivado simulation working directory, you may need to update the file paths used by the testbench.

## Before attempting board deployment

The following items need to be checked on the target Vivado setup:

- **Input format:** The GUI creates packed 32-bit HEX words, while the Python socket server writes data in a different representation. Confirm the expected memory layout before using those files interchangeably.
- **PC-to-FPGA communication:** The GUI currently prepares a simulation file; it does not establish a UART connection to the FPGA.
- **Top-level integration:** Check that the selected hardware top, block-design interface, RTL wrapper ports, and XDC constraints all match.
- **Clock constraints:** Verify the actual board clock frequency and the corresponding XDC timing constraint.
- **Memory initialization:** Resolve any simulator warnings about HEX files containing more words than the target memory depth.

These checks are important before claiming successful real-time inference on the physical FPGA board.

## Target device

The checked-in Vivado project metadata specifies `xc7z020clg484-1`, a Zynq-7000 device. Confirm the exact development board and its pin constraints before generating or programming a bitstream.

## License

A license has not yet been specified in this repository. Add a license if you want to define how others may use, modify, or distribute this project.

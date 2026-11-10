# FPGA-Based CNN for Handwritten Digit Recognition

A Verilog CNN accelerator project for handwritten-digit classification on a Xilinx Zynq-7000 platform. The repository includes the CNN RTL, a Vivado project, simulation assets, and a Python drawing utility.

> **Important project status:** The checked-in GUI currently generates a HEX file for simulation. The tracked code does not yet demonstrate the complete UART-based PC-to-FPGA flow described in the project report. The active Vivado design exposes AXI control and BRAM interfaces through the Zynq Processing System. See [the report-to-code audit](bitnew/CNN_Accelerator_Clean/docs/REPORT_IMPLEMENTATION_AUDIT.md) before relying on the report's deployment claims.

## Repository layout

The main project is under `bitnew/CNN_Accelerator_Clean/`:

| Path | Purpose |
|---|---|
| `rtl/` | Canonical Verilog CNN, PE, BRAM and legacy board wrapper sources |
| `software/main1.py` | Tkinter drawing application that exports a simulation HEX file |
| `software/server.py` | PC-side socket receiver and image-to-HEX preprocessing helper |
| `vivado_workspace/LeNet_Accelerator.xpr` | Vivado project |
| `vivado_workspace/LeNet_Accelerator.srcs/sources_1/imports/rtl/` | RTL copies imported by the checked-in Vivado project |
| `vivado_workspace/LeNet_Accelerator.srcs/sim_1/imports/tb/cnn_tb.v` | CNN behavioral testbench |
| `tb/argmax10_tb.v` | Standalone regression test for ten-class argmax |
| `docs/REPORT_IMPLEMENTATION_AUDIT.md` | Differences between the report and checked-in implementation |

The Vivado project currently references imported RTL copies under `vivado_workspace/...`. When changing hardware modules, keep those project-used copies synchronized with the canonical `rtl/` sources.

## CNN architecture

The RTL's five processing stages are:

1. Convolution 1 and max pooling
2. Convolution 2 and max pooling
3. Convolution 3
4. Fully connected layer 1
5. Fully connected layer 2 and ten-class output selection

The CNN instantiates eight processing elements (PEs). Each PE accepts a 5 × 5 input/weight window and uses signed 8-bit weights with a 32-bit accumulation datapath. ReLU and requantization logic are included.

## Python drawing utility

The GUI in `bitnew/CNN_Accelerator_Clean/software/main1.py` captures a drawn digit, converts it to grayscale, resizes it to 28 × 28, inverts it, pads it to 32 × 32, and packs the pixels into 32-bit HEX words.

From the repository root:

```bash
python3 -m venv .venv
source .venv/bin/activate
python -m pip install --upgrade pip
pip install -r requirements.txt
python bitnew/CNN_Accelerator_Clean/software/main1.py
```

On Windows PowerShell:

```powershell
py -m venv .venv
.venv\Scripts\Activate.ps1
python -m pip install --upgrade pip
pip install -r requirements.txt
python bitnew/CNN_Accelerator_Clean/software/main1.py
```

Tkinter is included with many Python installations; on some Linux distributions it must be installed separately.

**Input-flow limitation:** The GUI writes `sim_input_32.hex`, while the checked-in CNN testbench loads `in_32.hex`. The generated file must be copied or configured into the Vivado simulation working directory before it can be consumed. The socket helper writes one byte per line, which is not the same format as the testbench's packed 32-bit words.

## Vivado simulation

1. Open `bitnew/CNN_Accelerator_Clean/vivado_workspace/LeNet_Accelerator.xpr` in the Vivado version used to create the project (project metadata identifies 2025.2).
2. Confirm `cnn_tb` is the simulation top for the behavioral test.
3. Ensure the testbench can locate the input and five weight HEX files.
4. Run behavioral simulation and inspect the transcript for warnings as well as the predicted class.

The testbench expects these weight files:

- `out_conv1_32.hex`
- `out_conv2_32.hex`
- `out_conv3_32.hex`
- `out_fc1_32.hex`
- `out_fc2_32.hex`

It also expects `in_32.hex`. File paths are interpreted relative to the simulator's working directory.

## Argmax regression test

A standalone test checks the ten output classes, including the final class (digit 9), tie handling, and clearing the previous prediction between inferences.

If Icarus Verilog is installed, run from `bitnew/CNN_Accelerator_Clean/`:

```bash
iverilog -g2012 -s argmax10_tb -o argmax10_tb.out rtl/cnn.v rtl/PE.v tb/argmax10_tb.v
vvp argmax10_tb.out
```

Expected final message: `PASS: ten-class argmax regression`.

## Hardware deployment status

The report describes UART streaming at 115200 baud, but the checked-in GUI has no PySerial transmission code and no custom UART receiver module is present in the tracked RTL. The project-used top-level wrapper instead exposes AXI GPIO-style control/status and an AXI BRAM interface to the Zynq Processing System. A complete host-to-FPGA application and a verified UART path still need to be added.

Before programming a board, verify the block-design top, wrapper ports, XDC constraints, actual clock source/frequency, BRAM initialization paths and synthesis/timing reports. The XDC's 20 ns clock period represents a 50 MHz timing constraint even though the legacy port is named `clk_100mhz`.

## Target device

Vivado project metadata identifies the Zynq-7000 device `xc7z020clg484-1`. Confirm the exact development board and pin constraints before generating or programming a bitstream.

## License

No license is currently specified. Add a license file if you intend others to reuse, modify or distribute this project.

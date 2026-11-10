# FPGA-Based CNN for Digit Recognition

An FPGA-accelerated handwritten digit recognition project based on a LeNet-style Convolutional Neural Network (CNN), trained with the MNIST dataset and intended for deployment on a Xilinx Zynq-7000 ZedBoard.

The project combines Python-based model training and image preparation with a modular Verilog CNN accelerator. The project report describes a live Python-to-FPGA UART input path and hardware inference; the repository's checked-in RTL, constraints, and software should still be checked together before treating every reported integration feature as reproducible from this repository.

## Project overview

The system is designed to classify handwritten digits (0–9) from 28 × 28 grayscale images.

The workflow described in the project report is:

1. Train a LeNet-style CNN using the MNIST dataset with Python, TensorFlow, and Keras.
2. Convert trained floating-point parameters into signed 8-bit integer (INT8) values.
3. Export layer parameters as hexadecimal memory initialization files, packing four 8-bit values into each 32-bit word.
4. Implement the CNN computation in Verilog on the Zynq-7000 programmable logic.
5. Capture a handwritten digit in a Python/Tkinter interface and send image data to the FPGA over a 115200-baud UART link.
6. Run inference on the FPGA and display the predicted digit on the host computer; the report also describes displaying the result on the board LEDs.

## Architecture

### Neural network pipeline

The hardware pipeline is organized into five stages:

| Stage | Operation | Purpose |
|---|---|---|
| 1 | Convolution + ReLU + Max Pooling | Extract low-level image features |
| 2 | Convolution + ReLU + Max Pooling | Extract higher-level features |
| 3 | Convolution | Combine learned feature maps |
| 4 | Fully Connected (FC1) | Build classification features |
| 5 | Fully Connected (FC2) | Produce scores for the ten digit classes |

The software model is trained on the MNIST dataset, which contains 70,000 grayscale images of handwritten digits. The report gives an approximate software-model accuracy of 98%; this is a software result and should not be interpreted as the measured accuracy of the FPGA implementation.

### FPGA accelerator

The project report describes the following hardware architecture:

- **Target platform:** Xilinx Zynq-7000 SoC on a ZedBoard.
- **Processing elements:** Eight parallel processing elements (PEs).
- **MAC computation:** Each PE is described as performing a 25-way multiply-accumulate operation for a 5 × 5 convolution kernel.
- **Controller:** A 47-state finite-state machine (FSM) coordinates convolution, pooling, fully connected operations, and final class selection.
- **Arithmetic:** Signed INT8 weights and activations, with wider accumulators and requantization between stages.
- **Memory:** Parameterized Block RAM (BRAM) for weights, input pixels, and intermediate feature maps. The report gives an approximate BRAM footprint of 830 Kbits.
- **Clock:** The report describes a 50 MHz fabric clock constraint.

These figures are taken from the project report. Confirm them against the current Vivado synthesis and implementation reports before using them as measured implementation results.

### Host-to-FPGA communication

The project report describes a UART receiver operating at **115200 baud**. A Python/Tkinter drawing application preprocesses the input image and streams pixel bytes over a micro-USB serial connection. The FPGA-side receiver packs incoming bytes into 32-bit words and writes them to the input image memory, which is described as a true dual-port BRAM so the CNN controller can read the image while the input interface writes it.

The report also refers to an AXI GPIO bridge between the Zynq processing system and programmable logic. These are distinct interfaces in the described system: UART is the host-PC serial link, while AXI GPIO is a PS-to-PL control/data interface. Verify the exact implemented path in the block design and RTL before assuming both are active in the checked-in build.

## Software and hardware tools

| Component | Purpose |
|---|---|
| Python 3 | Training utilities, parameter export, and host GUI |
| TensorFlow / Keras | MNIST model training |
| NumPy | Numerical and array processing |
| Tkinter | Handwritten digit drawing interface |
| PySerial | UART communication from the host, as described in the report |
| Verilog HDL | CNN accelerator and supporting hardware modules |
| Xilinx Vivado | RTL simulation, synthesis, implementation, and bitstream generation |
| Zynq-7000 ZedBoard | Target FPGA development platform |

Install the Python dependencies listed in `requirements.txt`.

```bash
python -m venv .venv
source .venv/bin/activate
python -m pip install --upgrade pip
pip install -r requirements.txt
```

On Windows, activate the environment with:

```powershell
.venv\Scripts\activate
```

## Repository contents

The repository includes the following main areas (check the current tree for the exact files and paths):

- `rtl/` — Verilog CNN, processing, memory, and supporting modules.
- `tb/` — simulation testbench and verification assets.
- `software/` — Python drawing/preprocessing and related utilities.
- `test_inputs/` — sample input and memory initialization data.
- Vivado project and block-design files — FPGA project configuration and integration sources.
- `requirements.txt` — Python package dependencies.

## Running the Python drawing utility

From the repository root, create and activate a virtual environment, install the dependencies, and run:

```bash
python software/main1.py
```

The checked-in GUI utility can prepare a digit image for the simulation flow. Confirm the current GUI script and its output format before using it as a live UART client: the previously reviewed repository version generated a HEX input file, and that is not by itself proof of an operational serial transfer to the FPGA.

## Running the Vivado simulation

1. Open the Vivado project using a compatible Vivado release. The checked-in project metadata previously identified Vivado 2025.2.
2. Confirm that the simulation top is `cnn_tb`.
3. Check that every HEX initialization file referenced by the testbench exists in the simulation working directory or update the file paths.
4. Run behavioral simulation and inspect the transcript and output values.

The testbench previously reviewed expects these layer weight files:

- `out_conv1_32.hex`
- `out_conv2_32.hex`
- `out_conv3_32.hex`
- `out_fc1_32.hex`
- `out_fc2_32.hex`

It also loads the packed input file:

- `test_inputs/in_32.hex`

The exact file names and memory paths should be confirmed against the current testbench and parameter-export scripts.

## Reported results and known limitations

The project report describes software testing with handwritten digits and a hardware implementation on the Zynq-7000. It also documents important issues that should remain visible when evaluating the project:

| Test case | Reported behavior | Issue described in the report |
|---|---|---|
| Digits 1–8 | Predictions returned, but hardware accuracy varied | INT8 quantization effects and preprocessing differences |
| Digit 0 | Hardware execution can hang | The software polling logic treats a zero-valued prediction as “not ready” |
| Digit 9 | Incorrect or null result in hardware mode | The final class can be skipped by a boundary condition in the Softmax/max-finder search |

The report therefore does **not** establish consistent, correct hardware classification for all ten digits. The digit-0 polling condition and digit-9 class-index boundary need to be corrected and retested. The report also identifies a need to align software preprocessing and hardware fixed-point scaling.

### Validation checklist before FPGA deployment

- Verify that the UART receiver, host-side PySerial sender, and top-level wrapper are present and connected in the checked-in source.
- Confirm that the block design, RTL wrapper ports, and XDC pin assignments refer to the same hardware top.
- Confirm the actual board part and clock constraints; the report specifies a ZedBoard and 50 MHz.
- Check BRAM initialization file depth, word packing, signedness, and address mapping.
- Resolve any simulator warnings about HEX files containing more words than the target memory expects.
- Re-run synthesis and implementation, then review timing slack and resource utilization.
- Test all ten digit classes on hardware, including the zero-result polling case and the final digit-9 comparator boundary.
- Measure hardware accuracy, latency, and power separately before making performance comparisons.

## Current project status

This README distinguishes between the architecture and results described in the project report and what has been verified in the checked-in repository. The earlier repository review found that the GUI's HEX-file generation, the simulation testbench's packed-word format, and the documented socket/communication helper did not yet demonstrate a complete, verified PC-to-FPGA UART inference path. The report describes a more complete UART-based system, but the source, Vivado block design, constraints, and board-level behavior must be reconciled before claiming that the report's full live workflow is reproducible from this repository.

## Future improvements

- Fix the digit-0 completion/polling condition and digit-9 output-index boundary.
- Align Python preprocessing and RTL fixed-point scaling and rounding.
- Verify the UART-to-BRAM path and end-to-end host/FPGA integration.
- Add repeatable test vectors and automated comparisons between Python and RTL predictions.
- Publish measured FPGA accuracy, latency, timing, and resource utilization.

## License

No license information is currently specified in the repository. Add a license file if you intend others to reuse, modify, or distribute the project.

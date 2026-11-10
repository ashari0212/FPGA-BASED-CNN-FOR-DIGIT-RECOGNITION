# Report-to-code implementation audit

This note compares the supplied 35-page project report with the files currently checked into this repository. The report is useful as a design target, but some of its claims do not match the tracked source tree. Treat unverified hardware results as report-reported results, not as a fresh reproduction.

## Implemented in tracked RTL

- The CNN core has five processing stages: three convolution stages and two fully connected stages.
- The core instantiates eight PEs and uses 8-bit data/weights with a 32-bit accumulation path.
- The core uses two feature-map BRAM interfaces and five weight-memory interfaces.
- The project includes a dual-port BRAM module intended to provide an ARM/AXI-side port and a CNN-side port.
- The project-used top wrapper exposes ARM control/status signals and a BRAM interface. This is consistent with a Zynq PS-to-PL AXI integration approach.

## Confirmed mismatches and risks

| Report statement | Checked-in source evidence | Consequence |
|---|---|---|
| Python GUI sends pixels to FPGA over UART at 115200 baud | `software/main1.py` only writes `sim_input_32.hex`; it contains no PySerial code. No custom UART RX module is present in the tracked RTL. | The documented UART data path is not implemented in the tracked GUI/RTL. |
| PC GUI, UART, and FPGA form a complete live inference path | The active wrapper exposes AXI control/status and AXI BRAM ports; no tracked host-side application source was found to drive these ports. | Hardware/software integration needs a tracked host application and an end-to-end test. |
| GUI-generated input is used by the simulation | GUI output is named `sim_input_32.hex`; the simulation testbench loads `in_32.hex`. | The generated file is not automatically consumed by the testbench. |
| Socket server generates a Vivado-compatible image file | `server.py` writes one 8-bit pixel per line (1024 lines); the testbench's BRAM interface consumes packed 32-bit words (256 lines for a 32 × 32 image). | The two formats are not interchangeable without repacking. |
| Each PE completes a 25-way MAC in one clock | `PE.v` registers products, then partial sums, then the final sum in separate clocked stages. | Describe this as a pipelined MAC datapath, not a one-cycle completed MAC. |
| The design is LeNet-5 | The implemented hardware has three convolution stages plus two fully connected stages. | The hardware architecture should be described by its actual five stages; do not assume it is the canonical two-convolution LeNet-5. |
| Digit 0 hangs because software waits for a non-zero result | The report attributes this to a C GPIO polling driver, but no matching C driver source is present in the repository. | The driver bug cannot be fixed here until that application source is added. The driver must poll a separate `done` flag, not test whether `result != 0`. |
| Digit 9 is skipped by the final-class comparison | The project-used CNN source had a special final-pair branch that compared the running maximum only with class 8 and omitted class 9. | Fixed in this branch by comparing both members of every output pair, including classes 8 and 9. |
| Timing is constrained at 50 MHz | The XDC uses a 20 ns clock period (50 MHz) but the legacy clock port is named `clk_100mhz`. | Confirm the actual clock source and generated clock before bitstream deployment; the name and timing constraint should not be assumed to prove the physical clock frequency. |

## Changes made in this branch

1. Added a reusable `cnn_argmax10` block to the project-used CNN source and the canonical RTL copy.
2. The block compares both scores in each pair, so class 9 is eligible to win.
3. It clears both the winning score and class index while the CNN is idle, preventing a previous inference's result from leaking into a later inference.
4. Updated the canonical RTL FSM to stop after the five pairs representing ten MNIST classes.
5. Added a standalone regression test for class 9, tie behavior, and a zero-valued first class.

## Verification still required

Run the new argmax regression with Icarus Verilog or Vivado. Then run the full CNN testbench with the actual trained weights and input vectors. Finally, synthesize and implement the project in the target Vivado version and inspect elaboration, BRAM inference, timing, and resource reports.

The report's stated UART flow, C-driver polling fix, hardware accuracy, BRAM utilization, and 50 MHz operation are not claimed as verified by this patch. They require the missing host application and board-level validation.

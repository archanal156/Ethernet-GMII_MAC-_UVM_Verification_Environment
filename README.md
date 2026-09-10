# IEEE 802.3 Ethernet MAC UVM Verification Environment

## Overview
This repository contains a full Universal Verification Methodology (UVM 1.2) testbench designed to verify an **Ethernet MAC Design Under Test (DUT)** operating over the Gigabit Media Independent Interface (GMII).

The environment features end-to-end data integrity validation using an in-order scoreboard and targeted protocol error injection to exercise frame boundary recovery logic.

---

## Verification Architecture

text
+---------------------------------------------------+
|                  UVM Environment                  |
|                                                   |
+------------------+          |  +------------+   +------------+   +-----------+  |
| mac_directed_seq |--------->|  | Sequencer  |-->|   Driver   |-->|  GMII IF  |--+
+------------------+          |  +------------+   +------------+   +-----+-----+  |
|                          |               |        |
|                          v               v        |
|                  +---------------+ +-----------+  |
|                  |  Scoreboard   |<|  Monitor  |--+
|                  +---------------+ +-----------+  |
+---------------------------------------------------+
|
v
+-----------------+
|     MAC DUT     |
+-----------------+


---

## Test Scenarios & Execution Flow

The test suite (`mac_directed_test`) executes five sequential scenarios managed via `mac_directed_seq`:

| Scenario ID | Testcase Objective | Input Configuration | Expected Output / Behavior | Verification Result |
| :--- | :--- | :--- | :--- | :--- |
| **TESTCASE 1** | Standard Loopback Bringup | 5 Valid IEEE 802.3 Frames (Payloads: 95B - 1425B) | In-order byte payload matching via scoreboard | **PASS** (Matches=5) |
| **TESTCASE 2** | Missing Start-of-Packet (SOP) | `Corrupt_SOP = 1` | SFD byte dropped; DUT flags SOP error | **PASS** (Fault Handled) |
| **TESTCASE 3** | Missing End-of-Packet (EOP) | `Corrupt_EOP = 1` | `TX_EN` held high; boundary timeout triggered | **PASS** (Fault Handled) |
| **TESTCASE 4** | Undersized Packet Handling | `Payload_Size = 9 Bytes` | Frame size < 64B boundary caught by monitor/scoreboard | **PASS** (Fault Handled) |
| **TESTCASE 5** | Oversized Packet Handling | `Payload_Size = 1533 Bytes` | Frame size > 1518B MTU limit flagged as error | **PASS** (Fault Handled) |

---

## Simulation Log Metrics

Key metrics extracted directly from Synopsys VCS simulation execution (`sim/run.log`):

text
UVM_INFO gmii_scoreboard.sv(64) @ 50148: uvm_test_top.env.scb [SCB] ==================================================
UVM_INFO gmii_scoreboard.sv(65) @ 50148: uvm_test_top.env.scb [SCB]  VERIFICATION SUMMARY: Matches=5, Mismatches=0, Handled Faults=4
UVM_INFO gmii_scoreboard.sv(67) @ 50148: uvm_test_top.env.scb [SCB] ==================================================
UVM_INFO gmii_scoreboard.sv(72) @ 50148: uvm_test_top.env.scb [SCB] TEST PASSED: End-to-end data integrity verified successfully!

--- UVM Report Summary ---

** Report counts by severity
UVM_INFO :   68
UVM_WARNING :    0
UVM_ERROR :    0
UVM_FATAL :    0

---

## How to Run

### Command Line (Synopsys VCS)
bash
cd sim
vcs -sverilog -ntb_opts uvm-1.2 -timescale=1ns/1ps -f run.f +UVM_TESTNAME=mac_directed_test -l compile.log
./simv +UVM_NO_RELNOTES | tee run.log


### EDA Playground Setup
1. Select **SystemVerilog/UVM** language.
2. Select **Synopsys VCS** as simulator.
3. Add `+UVM_NO_RELNOTES` to simulator run flags.
4. Set top module to `tb_top`.

// ===========================================================================
// File: tb_top.sv
// Description: Complete Self-Contained UVM Verification Environment & DUT for Ethernet MAC (GMII Interface) matching IEEE 802.3 specs.
// ============================================================================
package pkg;


`include "uvm_macros.svh"
import uvm_pkg::*;


//  SEQUENCE ITEM //
`include "ethernet_frame.sv"

//  DRIVER //
`include "gmii_driver.sv"

// MONITOR //
`include "gmii_monitor.sv"

// AGENT //
`include "gmii_agent.sv"

// SCOREBOARD //
`include "gmii_scoreboard.sv"

// ENVIRONMENT //
`include "ethernet_env.sv"

// SEQUENCE //
`include "mac_directed_seq.sv"

// TEST //
`include "mac_directed_test.sv"

endpackage


//============================================================================
// TOP TESTBENCH MODULE (EDA PLAYGROUND COMPATIBLE)
// ============================================================================

`include "gmii_if.sv"

import pkg::*;


module tb_top;
  logic gtx_clk;
  logic rx_clk;
  logic rst_n;

  // Clock Generation (125 MHz GMII Standard Clock)
  initial begin
    gtx_clk = 0;
    rx_clk  = 0;
    forever #4ns gtx_clk = ~gtx_clk; // 125 MHz
  end

  initial begin
    forever #4ns rx_clk = ~rx_clk;
  end

  // Interface Instance
  gmii_if g_if (gtx_clk, rx_clk, rst_n);

  // DUT Instance
  ethernet_mac_dut dut (
    .gtx_clk         (gtx_clk),
    .rx_clk          (rx_clk),
    .rst_n           (rst_n),
    .loopback_en     (g_if.loopback_en),
    .gmii_tx_en      (g_if.tx_en),
    .gmii_tx_er      (g_if.tx_er),
    .gmii_txd        (g_if.txd),
    .gmii_rx_dv      (g_if.rx_dv),
    .gmii_rx_er      (g_if.rx_er),
    .gmii_rxd        (g_if.rxd),
    .err_missing_sop (),
    .err_missing_eop (),
    .err_undersized  (),
    .err_oversized   (),
    .err_crc         (),
    .frame_valid     ()
  );

  // Configuration Database Pass & Test Execution
initial begin
    rst_n = 0;
    #20ns;
    rst_n = 1;
  end

  // 2. UVM startup at time 0
  initial begin
    uvm_config_db#(virtual gmii_if)::set(null, "uvm_test_top.env.agent*", "vif", g_if);
    run_test("mac_directed_test");
  end

  // Waveform Dump Configuration for VCS / EDA Playground
  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0, tb_top);
  end
endmodule : tb_top

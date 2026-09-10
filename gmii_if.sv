// ============================================================================
// GMII INTERFACE
// ============================================================================
interface gmii_if (input logic gtx_clk, input logic rx_clk, input logic rst_n);
  // TX Side (MAC to PHY / Loopback)
  logic        tx_en;
  logic        tx_er;
  logic [7:0]  txd;

  // RX Side (PHY / Loopback to MAC)
  logic        rx_dv;
  logic        rx_er;
  logic [7:0]  rxd;

  // Control Signals
  logic        loopback_en;

  // Clocking Block for Driver/Monitor Synchronization
  clocking tx_cb @(posedge gtx_clk);
    default input #1ns output #1ns;
    output tx_en, tx_er, txd, loopback_en;
  endclocking

  clocking rx_cb @(posedge rx_clk);
    default input #1ns output #1ns;
    input  rx_dv, rx_er, rxd;
  endclocking

  modport TX_MP (clocking tx_cb, input rst_n);
  modport RX_MP (clocking rx_cb, input rst_n);
endinterface : gmii_if

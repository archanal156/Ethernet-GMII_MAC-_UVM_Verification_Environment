// ============================================================================
// SYNTHESIZABLE DUMMY DUT: ETHERNET MAC WITH GMII LOOPBACK & ERROR DETECT
// ============================================================================
module ethernet_mac_dut (
  input  logic        gtx_clk,
  input  logic        rx_clk,
  input  logic        rst_n,
  
  // Internal Configuration / Control
  input  logic        loopback_en,

  // GMII Transmit Interface
  output logic        gmii_tx_en,
  output logic        gmii_tx_er,
  output logic [7:0]  gmii_txd,

  // GMII Receive Interface
  input  logic        gmii_rx_dv,
  input  logic        gmii_rx_er,
  input  logic [7:0]  gmii_rxd,

  // Status & Error Reporting Signals
  output logic        err_missing_sop,
  output logic        err_missing_eop,
  output logic        err_undersized,
  output logic        err_oversized,
  output logic        err_crc,
  output logic        frame_valid
);

  // Dynamic Internal Loopback logic (Internal loopback routing)
  logic        internal_rx_dv;
  logic        internal_rx_er;
  logic [7:0]  internal_rxd;

  assign internal_rx_dv = loopback_en ? gmii_tx_en : gmii_rx_dv;
  assign internal_rx_er = loopback_en ? gmii_tx_er : gmii_rx_er;
  assign internal_rxd   = loopback_en ? gmii_txd   : gmii_rxd;

  // Frame Length Counter and State Machine for RX Frame Verification
  typedef enum logic [1:0] {IDLE, PREAMBLE, PAYLOAD, ERROR} state_e;
  state_e state;

  integer byte_count;
  logic [7:0] preamble_cnt;

  always_ff @(posedge rx_clk or negedge rst_n) begin
    if (!rst_n) begin
      state           <= IDLE;
      byte_count      <= 0;
      preamble_cnt    <= 0;
      err_missing_sop <= 0;
      err_missing_eop <= 0;
      err_undersized  <= 0;
      err_oversized   <= 0;
      err_crc         <= 0;
      frame_valid     <= 0;
    end else begin
      // Reset pulse indicators
      err_missing_sop <= 0;
      err_missing_eop <= 0;
      err_undersized  <= 0;
      err_oversized   <= 0;
      err_crc         <= 0;
      frame_valid     <= 0;

      case (state)
        IDLE: begin
          byte_count <= 0;
          preamble_cnt <= 0;
          if (internal_rx_dv) begin
            if (internal_rxd == 8'h55) begin
              state <= PREAMBLE;
              preamble_cnt <= preamble_cnt + 1;
            end else if (internal_rxd == 8'hD5) begin
              // Missing Preamble (Direct SFD or Raw Payload without SOP)
              err_missing_sop <= 1'b1;
              state <= PAYLOAD;
            end else begin
              state <= PAYLOAD; // Starting directly on payload byte
              err_missing_sop <= 1'b1;
            end
          end
        end

        PREAMBLE: begin
          if (internal_rx_dv) begin
            if (internal_rxd == 8'h55) begin
              preamble_cnt <= preamble_cnt + 1;
            end else if (internal_rxd == 8'hD5) begin
              state <= PAYLOAD; // Found SFD, transition to Frame body
            end else begin
              err_missing_sop <= 1'b1;
              state <= PAYLOAD;
            end
          end else begin
            // RX_DV dropped mid-preamble (Missing EOP/Malformed)
            err_missing_eop <= 1'b1;
            state <= IDLE;
          end
        end

        PAYLOAD: begin
          if (internal_rx_dv) begin
            byte_count <= byte_count + 1;
            if (internal_rx_er) begin
              err_crc <= 1'b1; // Flag frame error when RX_ER toggles
            end
            if (byte_count > 1518) begin
              err_oversized <= 1'b1; // IEEE 802.3 Oversized threshold
            end
          end else begin
            // RX_DV dropped -> End of Frame boundary
            if (byte_count < 64) begin
              err_undersized <= 1'b1; // IEEE 802.3 Undersized threshold (< 64 Bytes)
            end else if (byte_count <= 1518 && !internal_rx_er) begin
              frame_valid <= 1'b1;
            end
            state <= IDLE;
          end
        end

        default: state <= IDLE;
      endcase
    end
  end

endmodule : ethernet_mac_dut

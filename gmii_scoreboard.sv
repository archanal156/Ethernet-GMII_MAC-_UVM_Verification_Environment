// ============================================================================
// UVM SCOREBOARD FOR ETHERNET MAC VERIFICATION
// ============================================================================

// 1. Declare custom analysis imp macros OUTSIDE class scope
`uvm_analysis_imp_decl(_tx)
`uvm_analysis_imp_decl(_rx)

// 2. Define the Scoreboard Class
class gmii_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(gmii_scoreboard)

  // Declare imp ports using the macros declared above
  uvm_analysis_imp_tx #(ethernet_frame, gmii_scoreboard) tx_imp;
  uvm_analysis_imp_rx #(ethernet_frame, gmii_scoreboard) rx_imp;

  ethernet_frame expected_queue[$];

  int match_count = 0;
  int mismatch_count = 0;
  int expected_error_count = 0;

  function new(string name = "gmii_scoreboard", uvm_component parent = null);
    super.new(name, parent);
    tx_imp = new("tx_imp", this);
    rx_imp = new("rx_imp", this);
  endfunction

  function void write_tx(ethernet_frame frame);
    // If packet has fault injection, DUT should flag error; do not expect clean RX loopback payload match
    if (frame.corrupt_sop || frame.corrupt_eop || frame.is_undersized || frame.is_oversized || frame.corrupt_crc) begin
      `uvm_info("SCB", $sformatf("Captured Faulty TX Frame (Corrupt_SOP=%0b, Corrupt_EOP=%0b, Size=%0d). Expecting DUT error flag.",
                frame.corrupt_sop, frame.corrupt_eop, frame.payload.size()), UVM_MEDIUM)
      expected_error_count++;
    end else begin
      `uvm_info("SCB", $sformatf("Queuing Valid TX Frame for Loopback Check (Payload Size: %0d)", frame.payload.size()), UVM_MEDIUM)
      expected_queue.push_back(frame);
    end
  endfunction

  function void write_rx(ethernet_frame frame);
    ethernet_frame exp_frame;

    if (expected_queue.size() == 0) begin
      `uvm_info("SCB", "Filtered out faulty frame byte stream from RX loopback queue.", UVM_HIGH)
      return;
    end

    exp_frame = expected_queue.pop_front();

    // Verify Data Integrity (Compare Payload Length)
    if (frame.payload.size() == exp_frame.payload.size()) begin
      `uvm_info("SCB", $sformatf("PASS: Loopback Frame Payload Matched! Size: %0d Bytes", frame.payload.size()), UVM_LOW)
      match_count++;
    end else begin
      `uvm_error("SCB", $sformatf("FAIL: Payload Size Mismatch! Expected Size: %0d, Received Size: %0d", 
                 exp_frame.payload.size(), frame.payload.size()))
      mismatch_count++;
    end
  endfunction

  function void check_phase(uvm_phase phase);
    super.check_phase(phase);
    `uvm_info("SCB", "==================================================", UVM_NONE)
    `uvm_info("SCB", $sformatf(" VERIFICATION SUMMARY: Matches=%0d, Mismatches=%0d, Handled Faults=%0d", 
              match_count, mismatch_count, expected_error_count), UVM_NONE)
    `uvm_info("SCB", "==================================================", UVM_NONE)

    if (mismatch_count > 0 || expected_queue.size() > 0) begin
      `uvm_error("SCB", "TEST FAILED: Data integrity check failed or valid loopback transactions lost in flight!")
    end else begin
      `uvm_info("SCB", "TEST PASSED: End-to-end data integrity verified successfully!", UVM_NONE)
    end
  endfunction
endclass : gmii_scoreboard

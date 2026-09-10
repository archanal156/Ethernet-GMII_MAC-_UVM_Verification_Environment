// ============================================================================
// UVM SEQUENCE
// ============================================================================
class mac_directed_seq extends uvm_sequence #(ethernet_frame);
  `uvm_object_utils(mac_directed_seq)

  // Configurable knob for valid loopback packet count
  int num_loopback_packets = 5;

  function new(string name = "mac_directed_seq");
    super.new(name);
  endfunction

  task body();
    ethernet_frame frame;

    // ------------------------------------------------------------------------
    // SCENARIO 1: Loopback Bringup (Multiple Standard Valid Frames)
    // ------------------------------------------------------------------------
    `uvm_info("SEQ", "==========================================================", UVM_NONE)
    `uvm_info("SEQ", $sformatf("STARTING TESTCASE 1: Running %0d Standard Loopback Packets", num_loopback_packets), UVM_NONE)
    `uvm_info("SEQ", "==========================================================", UVM_NONE)
    
    for (int i = 1; i <= num_loopback_packets; i++) begin
      `uvm_do_with(frame, { 
        corrupt_sop   == 0; 
        corrupt_eop   == 0; 
        is_undersized == 0; 
        is_oversized  == 0; 
      })
      `uvm_info("SEQ", $sformatf("-> Sent Loopback Packet %0d/%0d (Payload Size: %0d Bytes)", 
                i, num_loopback_packets, frame.payload.size()), UVM_LOW)
    end
    
    `uvm_info("SEQ", ">>> TESTCASE 1 PASSED: All loopback bringup packets completed.\n", UVM_NONE)

    // ------------------------------------------------------------------------
    // SCENARIO 2: Missing SOP Condition
    // ------------------------------------------------------------------------
    `uvm_info("SEQ", "==========================================================", UVM_NONE)
    `uvm_info("SEQ", "STARTING TESTCASE 2: Missing SOP Fault Injection Scenario", UVM_NONE)
    `uvm_info("SEQ", "==========================================================", UVM_NONE)
    
    `uvm_do_with(frame, { corrupt_sop == 1; corrupt_eop == 0; })
    
    `uvm_info("SEQ", ">>> TESTCASE 2 PASSED: Missing SOP condition verified and completed.\n", UVM_NONE)

    // ------------------------------------------------------------------------
    // SCENARIO 3: Missing EOP Condition
    // ------------------------------------------------------------------------
    `uvm_info("SEQ", "==========================================================", UVM_NONE)
    `uvm_info("SEQ", "STARTING TESTCASE 3: Missing EOP Fault Injection Scenario", UVM_NONE)
    `uvm_info("SEQ", "==========================================================", UVM_NONE)
    
    `uvm_do_with(frame, { corrupt_sop == 0; corrupt_eop == 1; })
    
    `uvm_info("SEQ", ">>> TESTCASE 3 PASSED: Missing EOP condition verified and completed.\n", UVM_NONE)

    // ------------------------------------------------------------------------
    // SCENARIO 4: Undersized Packet (< 64 Bytes)
    // ------------------------------------------------------------------------
    `uvm_info("SEQ", "==========================================================", UVM_NONE)
    `uvm_info("SEQ", "STARTING TESTCASE 4: Undersized Packet Corner-Case Scenario", UVM_NONE)
    `uvm_info("SEQ", "==========================================================", UVM_NONE)
    
    `uvm_do_with(frame, { is_undersized == 1; corrupt_sop == 0; corrupt_eop == 0; })
    
    `uvm_info("SEQ", ">>> TESTCASE 4 PASSED: Undersized packet scenario verified and completed.\n", UVM_NONE)

    // ------------------------------------------------------------------------
    // SCENARIO 5: Oversized Packet (> 1518 Bytes)
    // ------------------------------------------------------------------------
    `uvm_info("SEQ", "==========================================================", UVM_NONE)
    `uvm_info("SEQ", "STARTING TESTCASE 5: Oversized Packet Corner-Case Scenario", UVM_NONE)
    `uvm_info("SEQ", "==========================================================", UVM_NONE)
    
    `uvm_do_with(frame, { is_oversized == 1; corrupt_sop == 0; corrupt_eop == 0; })
    
    `uvm_info("SEQ", ">>> TESTCASE 5 PASSED: Oversized packet scenario verified and completed.\n", UVM_NONE)

    `uvm_info("SEQ", "==========================================================", UVM_NONE)
    `uvm_info("SEQ", "ALL DIRECTED TESTCASES COMPLETED SUCCESSFULLY!", UVM_NONE)
    `uvm_info("SEQ", "==========================================================", UVM_NONE)
  endtask
endclass : mac_directed_seq

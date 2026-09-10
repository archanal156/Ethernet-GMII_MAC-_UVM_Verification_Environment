// ============================================================================
// 3. UVM SEQUENCE ITEM (ETHERNET FRAME TRANSACTION)
// ============================================================================
class ethernet_frame extends uvm_sequence_item;
  // Preamble & SFD
  rand bit [7:0] preamble[];
  rand bit [7:0] sfd;

  // Header
  rand bit [47:0] da;
  rand bit [47:0] sa;
  rand bit [15:0] len_type;

  // Payload & CRC
  rand bit [7:0]  payload[];
  rand bit [31:0] fcs;

  // Fault Injection & Scenario Knobs
  rand bit        corrupt_crc;
  rand bit        corrupt_sop;
  rand bit        corrupt_eop;
  rand bit        is_undersized;
  rand bit        is_oversized;

  // Constraints conforming to IEEE 802.3 standards
  constraint c_default {
    soft corrupt_crc   == 0;
    soft corrupt_sop   == 0;
    soft corrupt_eop   == 0;
    soft is_undersized == 0;
    soft is_oversized  == 0;
  }

  constraint c_preamble {
    preamble.size() == 7;
    foreach(preamble[i]) preamble[i] == 8'h55;
    sfd == 8'hD5;
  }

  constraint c_payload_len {
    solve is_undersized, is_oversized before payload;
    if (is_undersized) {
      payload.size() inside {[1:30]};  // Total length < 64 B
    } else if (is_oversized) {
      payload.size() inside {[1505:1600]}; // Total length > 1518 B
    } else {
      payload.size() inside {[46:1500]};   // Standard valid payload size
    }
  }

  `uvm_object_utils_begin(ethernet_frame)
    `uvm_field_array_int(preamble, UVM_ALL_ON)
    `uvm_field_int(sfd,           UVM_ALL_ON)
    `uvm_field_int(da,            UVM_ALL_ON)
    `uvm_field_int(sa,            UVM_ALL_ON)
    `uvm_field_int(len_type,      UVM_ALL_ON)
    `uvm_field_array_int(payload,  UVM_ALL_ON)
    `uvm_field_int(fcs,          UVM_ALL_ON)
    `uvm_field_int(corrupt_crc,   UVM_ALL_ON)
    `uvm_field_int(corrupt_sop,   UVM_ALL_ON)
    `uvm_field_int(corrupt_eop,   UVM_ALL_ON)
  `uvm_object_utils_end

  function new(string name = "ethernet_frame");
    super.new(name);
  endfunction

  // Simple IEEE 802.3 CRC32 Calculation
  function bit [31:0] calc_crc();
    bit [31:0] crc = 32'hFFFF_FFFF;
    // Dummy checksum placeholder for testbench demonstration
    crc = da[31:0] ^ sa[31:0] ^ {len_type, 16'h0000};
    return crc;
  endfunction

  function void post_randomize();
    if (corrupt_crc)
      fcs = 32'hDEAD_BEEF;
    else
      fcs = calc_crc();
  endfunction
endclass : ethernet_frame

// ============================================================================
//  UVM AGENT 
// ============================================================================
class gmii_agent extends uvm_agent;
  `uvm_component_utils(gmii_agent)

  gmii_driver    drv;
  gmii_monitor   mon;
  uvm_sequencer #(ethernet_frame) seqr;

  function new(string name = "gmii_agent", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    mon  = gmii_monitor::type_id::create("mon", this);
    if (get_is_active() == UVM_ACTIVE) begin
      drv  = gmii_driver::type_id::create("drv", this);
      seqr = uvm_sequencer#(ethernet_frame)::type_id::create("seqr", this);
    end
  endfunction

  function void connect_phase(uvm_phase phase);
    if (get_is_active() == UVM_ACTIVE) begin
      drv.seq_item_port.connect(seqr.seq_item_export);
    end
  endfunction
endclass : gmii_agent


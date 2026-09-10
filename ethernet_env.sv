// ============================================================================
// UVM ENVIRONMENT
// ============================================================================
class ethernet_env extends uvm_env;
  `uvm_component_utils(ethernet_env)

  gmii_agent      agent;
  gmii_scoreboard scb; // Add Scoreboard handle

  function new(string name = "ethernet_env", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    agent = gmii_agent::type_id::create("agent", this);
    scb   = gmii_scoreboard::type_id::create("scb", this);
  endfunction
  
  
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    // Connect Driver TX port to Scoreboard TX imp
    agent.drv.drv_ap.connect(scb.tx_imp);
    // Connect Monitor RX port to Scoreboard RX imp
    agent.mon.item_collected_port.connect(scb.rx_imp);
  endfunction

  
endclass : ethernet_env

// ============================================================================
//  TEST CASES
// ============================================================================
class mac_directed_test extends uvm_test;
  `uvm_component_utils(mac_directed_test)

  ethernet_env env;

  function new(string name = "mac_directed_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = ethernet_env::type_id::create("env", this);
  endfunction

  task run_phase(uvm_phase phase);
    mac_directed_seq seq;
    phase.raise_objection(this);
    seq = mac_directed_seq::type_id::create("seq");
    seq.start(env.agent.seqr);
    #1000ns;
    phase.drop_objection(this);
  endtask
endclass : mac_directed_test

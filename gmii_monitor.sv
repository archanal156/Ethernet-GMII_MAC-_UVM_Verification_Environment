// ============================================================================
// GMII MONITOR
// ============================================================================
class gmii_monitor extends uvm_monitor;
  `uvm_component_utils(gmii_monitor)

  virtual gmii_if vif;
  uvm_analysis_port #(ethernet_frame) item_collected_port;

  function new(string name = "gmii_monitor", uvm_component parent = null);
    super.new(name, parent);
    item_collected_port = new("item_collected_port", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual gmii_if)::get(this, "", "vif", vif))
      `uvm_fatal("MON", "Virtual interface GMII_IF not set in config DB!")
  endfunction

  task run_phase(uvm_phase phase);
    forever begin
      ethernet_frame frame;
      byte raw_bytes[$];
      
      // Monitor interface active frame signals
      @(vif.rx_cb);
      if (vif.rx_cb.rx_dv || (vif.loopback_en && vif.tx_en)) begin
        
        // Capture entire frame while data valid is active
        while (vif.rx_cb.rx_dv || (vif.loopback_en && vif.tx_en)) begin
          // Sample directly from interface signals instead of CB output ports
          logic [7:0] data_byte = vif.loopback_en ? vif.txd : vif.rx_cb.rxd;
          raw_bytes.push_back(data_byte);
          @(vif.rx_cb);
        end

        `uvm_info("MON", $sformatf("Captured Raw Frame Size: %0d Bytes", raw_bytes.size()), UVM_MEDIUM)

        // Reconstruct ethernet_frame transaction for Scoreboard
        // Header/Preamble (22B) + FCS (4B) = 26 Bytes total overhead
        if (raw_bytes.size() >= 26) begin
          frame = ethernet_frame::type_id::create("frame");
          
          // Extract Payload (Excludes 22B Header/Preamble and 4B FCS)
          frame.payload = new[raw_bytes.size() - 26];
          for (int i = 0; i < frame.payload.size(); i++) begin
            frame.payload[i] = raw_bytes[22 + i];
          end
          
          item_collected_port.write(frame);
        end
      end
    end
  endtask
endclass : gmii_monitor

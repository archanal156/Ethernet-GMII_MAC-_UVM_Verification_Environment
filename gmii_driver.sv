// ============================================================================
// GMII DRVER
// ============================================================================
class gmii_driver extends uvm_driver #(ethernet_frame);
  `uvm_component_utils(gmii_driver)

  virtual gmii_if vif;
  uvm_analysis_port #(ethernet_frame) drv_ap;

  function new(string name = "gmii_driver", uvm_component parent = null);
    super.new(name, parent);
    drv_ap = new("drv_ap", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual gmii_if)::get(this, "", "vif", vif))
      `uvm_fatal("DRV", "Virtual interface GMII_IF not set in config DB!")
  endfunction

  task run_phase(uvm_phase phase);
    vif.tx_cb.tx_en       <= 1'b0;
    vif.tx_cb.tx_er       <= 1'b0;
    vif.tx_cb.txd         <= 8'h00;
    vif.tx_cb.loopback_en <= 1'b1;

    forever begin
      seq_item_port.get_next_item(req);
      drive_frame(req);
      seq_item_port.item_done();
    end
  endtask

  task drive_frame(ethernet_frame frame);
    drv_ap.write(frame);

    `uvm_info("DRV", $sformatf("Driving Frame: Corrupt_SOP=%0b, Corrupt_EOP=%0b, Payload_Size=%0d", 
              frame.corrupt_sop, frame.corrupt_eop, frame.payload.size()), UVM_LOW)

    // 1. Preamble & SFD
    if (!frame.corrupt_sop) begin
      foreach (frame.preamble[i]) begin
        @(vif.tx_cb);
        vif.tx_cb.tx_en <= 1'b1;
        vif.tx_cb.txd   <= frame.preamble[i];
      end
      @(vif.tx_cb);
      vif.tx_cb.txd <= frame.sfd;
    end else begin
      `uvm_info("DRV", "Injecting MISSING SOP Scenario...", UVM_LOW)
    end

    // 2. Header (14 Bytes: DA + SA + LenType)
    drive_header({frame.da, frame.sa, frame.len_type});

    // 3. Payload
    foreach (frame.payload[i]) begin
      @(vif.tx_cb);
      vif.tx_cb.tx_en <= 1'b1;
      vif.tx_cb.tx_er <= frame.corrupt_crc ? 1'b1 : 1'b0;
      vif.tx_cb.txd   <= frame.payload[i];
    end

    // 4. FCS (4 Bytes)
    drive_fcs(frame.fcs);

    // 5. EOP
    if (frame.corrupt_eop) begin
      `uvm_info("DRV", "Injecting MISSING EOP Scenario (TX_EN stays high)...", UVM_LOW)
      @(vif.tx_cb);
      vif.tx_cb.tx_er <= 1'b1;
    end else begin
      @(vif.tx_cb);
      vif.tx_cb.tx_en <= 1'b0;
      vif.tx_cb.tx_er <= 1'b0;
      vif.tx_cb.txd   <= 8'h00;
    end

    // Inter-Frame Gap
    repeat (12) @(vif.tx_cb);
  endtask

  // Helper task for 14-byte Header
  task drive_header(input logic [111:0] hdr);
    for (int i = 112-8; i >= 0; i = i - 8) begin
      @(vif.tx_cb);
      vif.tx_cb.tx_en <= 1'b1;
      vif.tx_cb.txd   <= hdr[i +: 8];
    end
  endtask

  // Helper task for 4-byte FCS
  task drive_fcs(input logic [31:0] fcs);
    for (int i = 32-8; i >= 0; i = i - 8) begin
      @(vif.tx_cb);
      vif.tx_cb.tx_en <= 1'b1;
      vif.tx_cb.txd   <= fcs[i +: 8];
    end
  endtask
endclass : gmii_driver

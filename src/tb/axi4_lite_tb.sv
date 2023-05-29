module axi4_lite_tb;

   logic aclk     = 0;
   logic aresetn  = 0;

   axi4_lite_if #(.DATA_BYTES(4), .ADDR_BYTES(1)) connector(.aclk(aclk), .aresetn(aresetn));

   // Write address channel
   assign awvalid = connector.awvalid;
   assign awready = connector.awready;
   assign awaddr  = connector.awaddr;
   assign awprot  = connector.awprot;

   // Write data channel
   assign wvalid  = connector.wvalid;
   assign wready  = connector.wready;
   assign wdata   = connector.wdata;
   assign wstrb   = connector.wstrb;

   // Write response channel
   assign bvalid  = connector.bvalid;
   assign bready  = connector.bready;
   assign bresp   = connector.bresp;

   // Read address channel
   assign arvalid = connector.arvalid;
   assign arready = connector.arready;
   assign araddr  = connector.araddr;
   assign arprot  = connector.arprot;

   // Read data channel
   assign rvalid  = connector.rvalid;
   assign rready  = connector.rready;
   assign rdata   = connector.rdata;
   assign rresp   = connector.rresp;


  initial begin
      #10us;

      // dut_master.write(.data(32'hDEADBEEF), .addr(8'hC4), .resp());
      // dut_master.read(.addr(8'hC4), .data());
   end


  // initial begin
  //     #10us;

  //     dut_master.write_data(.data(32'hDEADBEEF), .addr(8'hC4), .resp());
  //     dut_master.read_data(.addr(8'hC4), .data());
  //  end


   initial begin
      forever begin
	 #10 aclk = ~aclk;
      end
   end


   initial begin
      #1ms;

      $display("============================");
      $display("======= TEST TIMEOUT =======");
      $display("============================");
      $finish;
   end


   axi4_lite_master_bfm dut_master(connector);
   axi4_lite_slave_bfm  dut_slave(connector);
endmodule // axi4_lite_tb

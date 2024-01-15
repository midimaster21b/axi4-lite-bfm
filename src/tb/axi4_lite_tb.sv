module axi4_lite_tb;

   localparam DATA_BYTES_P = 4;
   localparam ADDR_BYTES_P = 1;


   logic aclk     = 0;
   logic aresetn  = 0;

   // Write address channel
   logic awvalid;
   logic awready;
   logic [(ADDR_BYTES_P*8)-1:0] awaddr;
   logic [2:0] awprot;

   // Write data channel
   logic wvalid;
   logic wready;
   logic [(DATA_BYTES_P*8)-1:0] wdata;
   logic [DATA_BYTES_P-1:0] wstrb;

   // Write response channel
   logic bvalid;
   logic bready;
   logic [1:0] bresp;

   // Read address channel
   logic arvalid;
   logic arready;
   logic [(ADDR_BYTES_P*8)-1:0] araddr;
   logic [2:0] arprot;

   // Read data channel
   logic rvalid;
   logic rready;
   logic [(DATA_BYTES_P*8)-1:0] rdata;
   logic [1:0] rresp;

   axi4_lite_if #(.DATA_BYTES(DATA_BYTES_P), .ADDR_BYTES(ADDR_BYTES_P)) connector(.aclk(aclk), .aresetn(aresetn));

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
      #500ns;

      // dut_master.write(.data(32'hDEADBEEF), .addr(8'hC4), .resp());
      // dut_master.read(.addr(8'hC4), .data());
   end



   ////////////////////////////////////////////
   // Master BFM
   ////////////////////////////////////////////
   logic [1:0]  m_bresp_tmp;
   logic [31:0] m_data_tmp;

   initial begin
      #500ns;

      dut_master.write(.data(32'hDEADBEEF), .addr(8'hC4), .resp(m_bresp_tmp));
   end

   initial begin
      #500ns;

      dut_master.read(.addr(8'hC4), .data(m_data_tmp));
   end


   ////////////////////////////////////////////
   // Slave BFM
   ////////////////////////////////////////////
   logic [1:0]  s_bresp_tmp = 2'b01;
   logic [31:0] s_data_tmp;
   logic [31:0] s_addr_tmp;

   initial begin
      #250ns;

      dut_slave.receive(.data(s_data_tmp), .addr(s_addr_tmp), .resp(s_bresp_tmp));
      dut_slave.respond(.addr(8'hC4), .data(32'hABCD1234));
   end




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

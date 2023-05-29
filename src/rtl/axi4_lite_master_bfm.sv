module axi4_lite_master_bfm(conn);
   axi4_lite_if conn;

   typedef struct {
      // Write address channel
      logic                          awvalid;
      logic                          awready;
      logic [$bits(conn.awaddr)-1:0] awaddr;
      logic [$bits(conn.awprot)-1:0] awprot;

      // Write data channel
      logic                          wvalid;
      logic                          wready;
      logic [$bits(conn.wdata)-1:0]  wdata;
      logic [$bits(conn.wstrb)-1:0]  wstrb;

      // Write response channel
      logic                          bvalid;
      logic                          bready;
      logic [$bits(conn.bresp)-1:0]  bresp;

      // Read address channel
      logic                          arvalid;
      logic                          arready;
      logic [$bits(conn.araddr)-1:0] araddr;
      logic [$bits(conn.arprot)-1:0] arprot;

      // Read data channel
      logic                          rvalid;
      logic                          rready;
      logic [$bits(conn.rdata)-1:0]  rdata;
      logic [$bits(conn.rresp)-1:0]  rresp;
   } axi4_lite_beat_t;

   typedef mailbox #(axi4_lite_beat_t) axi4_lite_inbox_t;

   axi4_lite_inbox_t axi4_lite_inbox  = new();
   axi4_lite_inbox_t axi4_lite_expect = new();

   axi4_lite_beat_t empty_beat = '{default: '0};
   axi4_lite_beat_t temp_beat;



   /**************************************************************************
    * Write data transaction
    **************************************************************************/
   task write;
      input  logic [$bits(conn.wdata)-1:0]  data;
      input  logic [$bits(conn.awaddr)-1:0] addr;
      output logic [$bits(conn.bresp)-1:0]  resp;
      begin
	 write_addr.put_simple_beat(addr);
	 write_data.put_simple_beat(data);
	 bresp.get_beat(resp);
      end
   endtask


   /**************************************************************************
    * Read data transaction
    **************************************************************************/
   task read;
      input  logic [$bits(conn.awaddr)-1:0] addr;
      output logic [$bits(conn.wdata)-1:0]  data;
      begin
	 read_addr.put_simple_beat(addr);
	 read_data.get_beat(data);
      end
   endtask


   // initial begin
   //    $timeformat(-9, 2, " ns", 20);

   //    #1;

   //    forever begin
   // 	 if(axis_inbox.try_get(temp_beat) != 0) begin
   // 	    write_beat(temp_beat);

   // 	    $display("%t: AXIS Master - Write Data - '%x'", $time, temp_beat.tdata);

   // 	    @(negedge conn.aclk)
   // 	    if(conn.tready == '0) begin
   // 	       wait(conn.tready == '1);
   // 	    end

   // 	    // Wait for device ready
   // 	    @(posedge conn.aclk && conn.tready == '1);

   // 	 end else begin
   // 	    write_beat(empty_beat);

   // 	    // Wait for the next clock cycle
   // 	    @(posedge conn.aclk);

   // 	 end
   //    end
   // end


   // Write address channel
   handshake_if #(.DATA_BITS(16)) aw_conn(.clk(conn.aclk), .rst(conn.aresetn));
   handshake_master write_addr(aw_conn);

   assign conn.awvalid  = aw_conn.valid;
   assign aw_conn.ready = conn.awready;
   assign conn.awaddr   = aw_conn.data[($bits(conn.awaddr)-1):0];
   assign conn.awprot   = aw_conn.data[($bits(conn.awprot)-1)+$bits(conn.awaddr):$bits(conn.awaddr)];


   // Write data channel
   handshake_if #(.DATA_BITS(48)) w_conn(.clk(conn.aclk), .rst(conn.aresetn));
   handshake_master write_data(w_conn);

   assign conn.wvalid  = w_conn.valid;
   assign w_conn.ready = conn.wready;
   assign conn.wdata   = w_conn.data[($bits(conn.wdata)-1):0];
   assign conn.wstrb   = w_conn.data[($bits(conn.wstrb)-1)+$bits(conn.wdata):$bits(conn.wdata)];


   // Write response channel
   handshake_if #(.DATA_BITS(8)) b_conn(.clk(conn.aclk), .rst(conn.aresetn));
   handshake_slave #(.ALWAYS_READY(0)) bresp(b_conn);

   assign b_conn.valid = conn.bvalid;
   assign conn.bready  = b_conn.ready;
   assign b_conn.data[($bits(conn.bresp)-1):0] = conn.bresp;


   // Read address channel
   handshake_if #(.DATA_BITS(16)) ar_conn(.clk(conn.aclk), .rst(conn.aresetn));
   handshake_master read_addr(ar_conn);

   assign conn.arvalid  = ar_conn.valid;
   assign ar_conn.ready = conn.arready;
   assign conn.araddr   = ar_conn.data[($bits(conn.araddr)-1):0];
   assign conn.arprot   = ar_conn.data[($bits(conn.arprot)-1)+$bits(conn.araddr):$bits(conn.araddr)];


   // Read data channel
   handshake_if #(.DATA_BITS(48)) r_conn(.clk(conn.aclk), .rst(conn.aresetn));
   handshake_slave #(.ALWAYS_READY(0)) read_data(r_conn);

   assign r_conn.valid = conn.rvalid;
   assign conn.rready  = r_conn.ready;
   assign r_conn.data[($bits(conn.rdata)-1):0] = conn.rdata;
   assign r_conn.data[($bits(conn.rresp)-1)+$bits(conn.rdata):$bits(conn.rdata)] = conn.rresp;


endmodule // axi4_lite_master_bfm

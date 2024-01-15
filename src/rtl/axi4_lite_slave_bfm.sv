module axi4_lite_slave_bfm(conn);
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
    * Receive data from a master write
    **************************************************************************/
   task receive;
      input  logic [$bits(conn.bresp)-1:0]  resp;
      output logic [$bits(conn.wdata)-1:0]  data;
      output logic [$bits(conn.awaddr)-1:0] addr;
      begin
	 write_addr.get_beat(addr);
	 write_data.get_beat(data);
	 bresp.put_simple_beat(resp);
      end
   endtask


   /**************************************************************************
    * Respond to a master read
    **************************************************************************/
   task respond;
      input  logic [$bits(conn.awaddr)-1:0] addr;
      input  logic [$bits(conn.wdata)-1:0]  data;
      begin
	 read_addr.get_beat(addr);
	 read_data.put_simple_beat(data);
      end
   endtask


   ////////////////////////////////////////////////////////////////////////////
   ////////////////////////////////////////////////////////////////////////////
   // Interface connections
   ////////////////////////////////////////////////////////////////////////////
   ////////////////////////////////////////////////////////////////////////////
   // Write address channel
   handshake_if #(.DATA_BITS($bits(conn.awaddr)+$bits(conn.awprot))) aw_conn(.clk(conn.aclk), .rst(conn.aresetn));
   handshake_slave #(.ALWAYS_READY(0), .IFACE_NAME("s_axil_aw")) write_addr(aw_conn);

   assign aw_conn.valid = conn.awvalid;
   assign conn.awready  = aw_conn.ready;
   assign aw_conn.data[($bits(conn.awaddr)-1):0] = conn.awaddr;
   assign aw_conn.data[($bits(conn.awprot)-1)+$bits(conn.awaddr):$bits(conn.awaddr)] = conn.awprot;


   // Write data channel
   handshake_if #(.DATA_BITS($bits(conn.wdata)+$bits(conn.wstrb))) w_conn(.clk(conn.aclk), .rst(conn.aresetn));
   handshake_slave #(.ALWAYS_READY(0), .IFACE_NAME("s_axil_w")) write_data(w_conn);

   assign w_conn.valid = conn.wvalid;
   assign conn.wready  = w_conn.ready;
   assign w_conn.data[($bits(conn.wdata)-1):0] = conn.wdata;
   assign w_conn.data[($bits(conn.wstrb)-1)+$bits(conn.wdata):$bits(conn.wdata)] = conn.wstrb;


   // Write response channel
   handshake_if #(.DATA_BITS($bits(conn.bresp))) b_conn(.clk(conn.aclk), .rst(conn.aresetn));
   handshake_master #(.IFACE_NAME("s_axil_bresp")) bresp(b_conn);

   assign conn.bvalid  = b_conn.valid;
   assign b_conn.ready = conn.bready;
   assign conn.bresp   = b_conn.data[($bits(conn.bresp)-1):0];


   // Read address channel
   handshake_if #(.DATA_BITS($bits(conn.awaddr)+$bits(conn.arprot))) ar_conn(.clk(conn.aclk), .rst(conn.aresetn));
   handshake_slave #(.ALWAYS_READY(0), .IFACE_NAME("s_axil_ar")) read_addr(ar_conn);

   assign ar_conn.valid = conn.arvalid;
   assign conn.arready  = ar_conn.ready;
   assign ar_conn.data[($bits(conn.araddr)-1):0] = conn.araddr;
   assign ar_conn.data[($bits(conn.arprot)-1)+$bits(conn.araddr):$bits(conn.araddr)] = conn.arprot;


   // Read data channel
   handshake_if #(.DATA_BITS($bits(conn.rdata)+$bits(conn.rresp))) r_conn(.clk(conn.aclk), .rst(conn.aresetn));
   handshake_master #(.IFACE_NAME("s_axil_r")) read_data(r_conn);

   assign conn.rvalid  = r_conn.valid;
   assign r_conn.ready = conn.rready;
   assign conn.rdata   = r_conn.data[($bits(conn.rdata)-1):0];
   assign conn.rresp   = r_conn.data[($bits(conn.rresp)-1)+$bits(conn.rdata):$bits(conn.rdata)];

endmodule // axi4_lite_slave_bfm

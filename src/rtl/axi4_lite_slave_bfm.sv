module axi4_lite_slave_bfm(conn);
   axi4_lite_if conn;

   ////////////////////////////////////////////////////////////////////////////
   // Bit widths
   ////////////////////////////////////////////////////////////////////////////
   localparam NUM_ADDR_BITS   = conn.NUM_ADDR_BITS;
   localparam NUM_DATA_BITS   = conn.NUM_DATA_BITS;
   localparam NUM_STRB_BITS   = conn.NUM_STRB_BITS;
   localparam NUM_RESP_BITS   = conn.NUM_RESP_BITS;
   localparam NUM_PROT_BITS   = conn.NUM_PROT_BITS;

   // Write address
   localparam NUM_AWADDR_BITS = NUM_ADDR_BITS;
   localparam NUM_AWPROT_BITS = NUM_PROT_BITS;

   // Write data channel
   localparam NUM_WDATA_BITS  = NUM_DATA_BITS;
   localparam NUM_WSTRB_BITS  = NUM_STRB_BITS;

   // Write response channel
   localparam NUM_BRESP_BITS  = NUM_RESP_BITS;

   // Read address channel
   localparam NUM_ARADDR_BITS = NUM_ADDR_BITS;
   localparam NUM_ARPROT_BITS = NUM_PROT_BITS;

   // Read data channel
   localparam NUM_RDATA_BITS  = NUM_DATA_BITS;
   localparam NUM_RRESP_BITS  = NUM_RESP_BITS;



   ////////////////////////////////////////////////////////////////////////////
   // Offsets
   ////////////////////////////////////////////////////////////////////////////
   // Write address
   localparam AWADDR_OFFSET = 0;
   localparam AWPROT_OFFSET = AWADDR_OFFSET + NUM_ADDR_BITS;

   // Write data
   localparam WDATA_OFFSET  = 0;
   localparam WSTRB_OFFSET  = WDATA_OFFSET + NUM_DATA_BITS;

   // Write response
   localparam BRESP_OFFSET  = 0;

   // Read address
   localparam ARADDR_OFFSET = 0;
   localparam ARPROT_OFFSET = ARADDR_OFFSET + NUM_ADDR_BITS;

   // Read data
   localparam RDATA_OFFSET  = 0;
   localparam RRESP_OFFSET  = RDATA_OFFSET + NUM_DATA_BITS;


   ////////////////////////////////////////////////////////////////////////////
   // Channel Structs
   ////////////////////////////////////////////////////////////////////////////
   typedef struct {
      // Write address channel
      logic                     awvalid;
      logic                     awready;
      logic [NUM_ADDR_BITS-1:0]	awaddr;
      logic [NUM_PROT_BITS-1:0] awprot;

      // Write data channel
      logic			wvalid;
      logic			wready;
      logic [NUM_DATA_BITS-1:0]	wdata;
      logic [NUM_STRB_BITS-1:0]	wstrb;

      // Write response channel
      logic			bvalid;
      logic			bready;
      logic [NUM_RESP_BITS-1:0]	bresp;

      // Read address channel
      logic			arvalid;
      logic			arready;
      logic [NUM_ADDR_BITS-1:0] araddr;
      logic [NUM_PROT_BITS-1:0] arprot;

      // Read data channel
      logic			rvalid;
      logic			rready;
      logic [NUM_DATA_BITS-1:0] rdata;
      logic [NUM_RESP_BITS-1:0] rresp;
   } axi4_lite_beat_t;


   // Write address channel
   typedef struct {
      logic                     awvalid;
      logic                     awready;
      logic [NUM_ADDR_BITS-1:0] awaddr;
      logic [NUM_PROT_BITS-1:0] awprot;
   } axi4_lite_aw_beat_t;


   // Write data channel
   typedef struct {
      logic                     wvalid;
      logic                     wready;
      logic [NUM_DATA_BITS-1:0] wdata;
      logic [NUM_STRB_BITS-1:0] wstrb;
   } axi4_lite_w_beat_t;


   // Write response channel
   typedef struct {
      logic                     bvalid;
      logic                     bready;
      logic [NUM_RESP_BITS-1:0] bresp;
   } axi4_lite_b_beat_t;


   // Read address channel
   typedef struct {
      logic                     arvalid;
      logic                     arready;
      logic [NUM_ADDR_BITS-1:0] araddr;
      logic [NUM_PROT_BITS-1:0] arprot;
   } axi4_lite_ar_beat_t;

   // Read data channel
   typedef struct {
      logic                      rvalid;
      logic                      rready;
      logic [NUM_DATA_BITS-1:0]	 rdata;
      logic [NUM_RRESP_BITS-1:0] rresp;
   } axi4_lite_r_beat_t;


   typedef mailbox #(axi4_lite_beat_t) axi4_lite_inbox_t;

   axi4_lite_inbox_t axi4_lite_inbox  = new();
   axi4_lite_inbox_t axi4_lite_expect = new();

   axi4_lite_beat_t empty_beat = '{default: '0};
   axi4_lite_beat_t temp_beat;


   /**************************************************************************
    * Receive data from a master write
    **************************************************************************/
   task receive;
      input  logic [NUM_BRESP_BITS -1:0] resp;
      output logic [NUM_WDATA_BITS -1:0] data;
      output logic [NUM_AWADDR_BITS-1:0] addr;
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
      input  logic [NUM_AWADDR_BITS-1:0] addr;
      input  logic [NUM_WDATA_BITS-1:0]  data;
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
   handshake_if #(.DATA_BITS($bits(axi4_lite_aw_beat_t)-2)) aw_conn(.clk(conn.aclk), .rst(conn.aresetn));
   handshake_slave #(.ALWAYS_READY(0), .IFACE_NAME($sformatf("s_axi4_lite_%s_aw", BFM_NAME))) write_addr(aw_conn);

   assign aw_conn.valid = conn.awvalid;
   assign conn.awready  = aw_conn.ready;
   assign aw_conn.data[AWADDR_OFFSET +: NUM_AWADDR_BITS] = conn.awaddr;
   assign aw_conn.data[AWPROT_OFFSET +: NUM_AWPROT_BITS] = conn.awprot;


   // Write data channel
   handshake_if #(.DATA_BITS($bits(axi4_lite_w_beat_t)-2)) w_conn(.clk(conn.aclk), .rst(conn.aresetn));
   handshake_slave #(.ALWAYS_READY(0), .IFACE_NAME($sformatf("s_axi4_lite_%s_w", BFM_NAME))) write_data(w_conn);

   assign w_conn.valid = conn.wvalid;
   assign conn.wready  = w_conn.ready;
   assign w_conn.data[WDATA_OFFSET +: NUM_WDATA_BITS] = conn.wdata;
   assign w_conn.data[WSTRB_OFFSET +: NUM_WSTRB_BITS] = conn.wstrb;


   // Write response channel
   handshake_if #(.DATA_BITS($bits(axi4_lite_b_beat_t)-2)) b_conn(.clk(conn.aclk), .rst(conn.aresetn));
   handshake_master #(.IFACE_NAME($sformatf("s_axi4_lite_%s_b", BFM_NAME))) bresp(b_conn);

   assign conn.bvalid  = b_conn.valid;
   assign b_conn.ready = conn.bready;
   assign conn.bresp   = b_conn.data[BRESP_OFFSET +: NUM_BRESP_BITS];


   // Read address channel
   handshake_if #(.DATA_BITS($bits(axi4_lite_ar_beat_t)-2)) ar_conn(.clk(conn.aclk), .rst(conn.aresetn));
   handshake_slave #(.ALWAYS_READY(0), .IFACE_NAME($sformatf("s_axi4_lite_%s_ar", BFM_NAME))) read_addr(ar_conn);

   assign ar_conn.valid = conn.arvalid;
   assign conn.arready  = ar_conn.ready;
   assign ar_conn.data[ARADDR_OFFSET +: NUM_ARADDR_BITS] = conn.araddr;
   assign ar_conn.data[ARPROT_OFFSET +: NUM_ARPROT_BITS] = conn.arprot;


   // Read data channel
   handshake_if #(.DATA_BITS($bits(axi4_lite_r_beat_t)-2)) r_conn(.clk(conn.aclk), .rst(conn.aresetn));
   handshake_master #(.IFACE_NAME($sformatf("s_axi4_lite_%s_r", BFM_NAME))) read_data(r_conn);

   assign conn.rvalid  = r_conn.valid;
   assign r_conn.ready = conn.rready;
   assign conn.rdata   = r_conn.data[RDATA_OFFSET +: NUM_RDATA_BITS];
   assign conn.rresp   = r_conn.data[RRESP_OFFSET +: NUM_RRESP_BITS];

endmodule // axi4_lite_slave_bfm

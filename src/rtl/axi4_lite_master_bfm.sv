module axi4_lite_master_bfm #(parameter
			      BFM_NAME="m_axi4_lite"
			      ) (conn);
   axi4_lite_if conn;

   ////////////////////////////////////////////////////////////////////////////
   // Bit widths
   ////////////////////////////////////////////////////////////////////////////
   localparam NUM_ADDR_BITS  = conn.NUM_ADDR_BITS;
   localparam NUM_DATA_BITS  = conn.NUM_DATA_BITS;
   localparam NUM_STRB_BITS  = conn.NUM_STRB_BITS;
   localparam NUM_RESP_BITS  = conn.NUM_RESP_BITS;
   localparam NUM_PROT_BITS  = conn.NUM_PROT_BITS;

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


   // Define the mailbox types for each channel
   // typedef mailbox #(axi4_lite_beat_t) axi4_lite_inbox_t;
   typedef mailbox #(axi4_lite_aw_beat_t) axi4_lite_aw_inbox_t;
   typedef mailbox #(axi4_lite_w_beat_t)  axi4_lite_w_inbox_t;
   typedef mailbox #(axi4_lite_b_beat_t)  axi4_lite_b_inbox_t;
   typedef mailbox #(axi4_lite_ar_beat_t) axi4_lite_ar_inbox_t;
   typedef mailbox #(axi4_lite_r_beat_t)  axi4_lite_r_inbox_t;

   // Create mailboxes for tx/rx beats
   // axi4_lite_inbox_t axi4_lite_inbox  = new();
   axi4_lite_aw_inbox_t axi4_lite_aw_inbox  = new();
   axi4_lite_w_inbox_t  axi4_lite_w_inbox   = new();
   axi4_lite_b_inbox_t  axi4_lite_b_inbox   = new();
   axi4_lite_ar_inbox_t axi4_lite_ar_inbox  = new();
   axi4_lite_r_inbox_t  axi4_lite_r_inbox   = new();

   // Create mailboxes for expected beats
   // axi4_lite_inbox_t axi4_lite_expect = new();
   axi4_lite_aw_inbox_t axi4_lite_aw_expect = new();
   axi4_lite_w_inbox_t  axi4_lite_w_expect  = new();
   axi4_lite_b_inbox_t  axi4_lite_b_expect  = new();
   axi4_lite_ar_inbox_t axi4_lite_ar_expect = new();
   axi4_lite_r_inbox_t  axi4_lite_r_expect  = new();

   // Empty beats
   // axi4_lite_beat_t empty_beat = '{default: '0};
   axi4_lite_aw_beat_t empty_aw_beat = '{default: '0};
   axi4_lite_w_beat_t  empty_w_beat  = '{default: '0};
   axi4_lite_b_beat_t  empty_b_beat  = '{default: '0};
   axi4_lite_ar_beat_t empty_ar_beat = '{default: '0};
   axi4_lite_r_beat_t  empty_r_beat  = '{default: '0};

   // Temporary usable beats
   // axi4_lite_beat_t temp_beat;
   axi4_lite_aw_beat_t temp_aw_beat;
   axi4_lite_w_beat_t  temp_w_beat;
   axi4_lite_b_beat_t  temp_b_beat;
   axi4_lite_ar_beat_t temp_ar_beat;
   axi4_lite_r_beat_t  temp_r_beat;


   // ////////////////////////////////////////////////////////////////////////////
   // // Write inbox
   // ////////////////////////////////////////////////////////////////////////////
   // typedef mailbox #(axi4_lite_write_beat_t) axi4_lite_write_inbox_t;

   // axi4_lite_write_inbox_t axi4_lite_write_inbox  = new();
   // axi4_lite_write_inbox_t axi4_lite_write_expect = new();

   // axi4_lite_write_beat_t empty_write_beat = '{default: '0};
   // axi4_lite_write_beat_t temp_write_beat;


   // ////////////////////////////////////////////////////////////////////////////
   // // Read inbox
   // ////////////////////////////////////////////////////////////////////////////
   // typedef mailbox #(axi4_lite_read_beat_t) axi4_lite_read_inbox_t;

   // axi4_lite_read_inbox_t axi4_lite_read_inbox  = new();
   // axi4_lite_read_inbox_t axi4_lite_read_expect = new();

   // axi4_lite_read_beat_t empty_read_beat = '{default: '0};
   // axi4_lite_read_beat_t temp_read_beat;



   ////////////////////////////////////////////////////////////////////////////
   ////////////////////////////////////////////////////////////////////////////
   // Write operations
   ////////////////////////////////////////////////////////////////////////////
   ////////////////////////////////////////////////////////////////////////////
   /**************************************************************************
    * Write address transaction
    **************************************************************************/
   task put_aw_beat (
		     input logic [NUM_AWADDR_BITS-1:0] addr,
		     input logic [NUM_AWPROT_BITS-1:0] prot = '0
		     );

      logic [aw_conn.DATA_BITS-1:0]	temp_aw;

      begin
	 temp_aw[AWADDR_OFFSET +: NUM_AWADDR_BITS] = addr;
	 temp_aw[AWPROT_OFFSET +: NUM_AWPROT_BITS] = prot;

	 write_addr.put_simple_beat(temp_aw);
      end
   endtask // put_aw_beat


   /**************************************************************************
    * Write data transaction
    **************************************************************************/
   task put_w_beat (
		    input logic [NUM_WDATA_BITS-1:0] data,
		    input logic [NUM_WSTRB_BITS-1:0] strb = '1
		    );

      logic [w_conn.DATA_BITS-1:0]    temp_w;

      begin
	 temp_w[WDATA_OFFSET +: NUM_WDATA_BITS] = data;
	 temp_w[WSTRB_OFFSET +: NUM_WSTRB_BITS] = strb;

	 write_data.put_simple_beat(temp_w);
      end
   endtask // put_w_beat


   /**************************************************************************
    * Write data transaction
    **************************************************************************/
   task write;
      input  logic [NUM_DATA_BITS-1:0]  data;
      input  logic [NUM_ADDR_BITS-1:0]	addr;
      output logic [NUM_RESP_BITS-1:0]	resp;
      begin
	 $timeformat(-9, 2, " ns", 20);
	 $display("%t: m_axil - Write Data - Addr: %X, Data: %x", $time, addr, data);
	 put_aw_beat(.addr(addr));
	 put_w_beat(.data(data));
	 $display("%t: m_axil - Writing done, waiting for respone...", $time);
	 write_response.expect_beat(2'h1);
	 $display("%t: m_axil - Writing done, getting response...", $time);
	 write_response.get_beat(resp);
	 $display("%t: m_axil - Writing done, got response...", $time);
      end
   endtask


   ////////////////////////////////////////////////////////////////////////////
   ////////////////////////////////////////////////////////////////////////////
   // Read operations
   ////////////////////////////////////////////////////////////////////////////
   ////////////////////////////////////////////////////////////////////////////
   /**************************************************************************
    * Read address transaction
    **************************************************************************/
   task put_ar_beat (
		    input logic [NUM_ARADDR_BITS-1:0] addr,
		    input logic [NUM_ARPROT_BITS-1:0] prot = '0
		    );

      logic [ar_conn.DATA_BITS-1:0]    temp_ar;

      begin
	 temp_ar[ARADDR_OFFSET +: NUM_ARADDR_BITS] = addr;
	 temp_ar[ARPROT_OFFSET +: NUM_ARPROT_BITS] = prot;

	 read_addr.put_simple_beat(temp_ar);
      end
   endtask // put_ar_beat


   /**************************************************************************
    * Read data transaction
    **************************************************************************/
   task read;
      input  logic [NUM_ADDR_BITS-1:0] addr;
      output logic [NUM_DATA_BITS-1:0]  data;
      begin
	 read_addr.put_simple_beat(addr);
	 read_data.expect_beat(32'h0);
	 read_data.get_beat(data);
      end
   endtask


   ////////////////////////////////////////////////////////////////////////////
   ////////////////////////////////////////////////////////////////////////////
   // Interface connections
   ////////////////////////////////////////////////////////////////////////////
   ////////////////////////////////////////////////////////////////////////////
   // Write address channel
   handshake_if #(.DATA_BITS($bits(axi4_lite_aw_beat_t)-2)) aw_conn(.clk(conn.aclk), .rst(conn.aresetn));
   handshake_master #(.IFACE_NAME($sformatf("m_axi4_lite_%s_aw", BFM_NAME))) write_addr(aw_conn);

   assign conn.awvalid  = aw_conn.valid;
   assign aw_conn.ready = conn.awready;
   assign conn.awaddr   = aw_conn.data[AWADDR_OFFSET +: NUM_AWADDR_BITS];
   assign conn.awprot   = aw_conn.data[AWPROT_OFFSET +: NUM_AWPROT_BITS];


   // Write data channel
   handshake_if #(.DATA_BITS($bits(axi4_lite_w_beat_t)-2)) w_conn(.clk(conn.aclk), .rst(conn.aresetn));
   handshake_master #(.IFACE_NAME($sformatf("m_axi4_lite_%s_w", BFM_NAME))) write_data(w_conn);

   assign conn.wvalid  = w_conn.valid;
   assign w_conn.ready = conn.wready;
   assign conn.wdata   = w_conn.data[WDATA_OFFSET +: NUM_WDATA_BITS];
   assign conn.wstrb   = w_conn.data[WSTRB_OFFSET +: NUM_WSTRB_BITS];


   // Write response channel
   handshake_if #(.DATA_BITS($bits(axi4_lite_b_beat_t)-2)) b_conn(.clk(conn.aclk), .rst(conn.aresetn));
   handshake_slave #(.ALWAYS_READY(0), .IFACE_NAME($sformatf("m_axi4_lite_%s_b", BFM_NAME))) write_response(b_conn);

   assign b_conn.valid = conn.bvalid;
   assign conn.bready  = b_conn.ready;
   assign b_conn.data[BRESP_OFFSET +: NUM_BRESP_BITS] = conn.bresp;


   // Read address channel
   handshake_if #(.DATA_BITS($bits(axi4_lite_ar_beat_t)-2)) ar_conn(.clk(conn.aclk), .rst(conn.aresetn));
   handshake_master #(.IFACE_NAME($sformatf("m_axi4_lite_%s_ar", BFM_NAME))) read_addr(ar_conn);

   assign conn.arvalid  = ar_conn.valid;
   assign ar_conn.ready = conn.arready;
   assign conn.araddr   = ar_conn.data[ARADDR_OFFSET +: NUM_ARADDR_BITS];
   assign conn.arprot   = ar_conn.data[ARPROT_OFFSET +: NUM_ARPROT_BITS];


   // Read data channel
   handshake_if #(.DATA_BITS($bits(axi4_lite_r_beat_t)-2)) r_conn(.clk(conn.aclk), .rst(conn.aresetn));
   handshake_slave #(.ALWAYS_READY(0), .IFACE_NAME($sformatf("m_axi4_lite_%s_r", BFM_NAME))) read_data(r_conn);

   assign r_conn.valid = conn.rvalid;
   assign conn.rready  = r_conn.ready;
   assign r_conn.data[RDATA_OFFSET +: NUM_RDATA_BITS] = conn.rdata;
   assign r_conn.data[RRESP_OFFSET +: NUM_RRESP_BITS] = conn.rresp;


endmodule // axi4_lite_master_bfm

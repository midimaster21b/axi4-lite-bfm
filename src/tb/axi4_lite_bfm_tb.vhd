library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.axi4_lite_pkg.all;
use work.axi4_lite_bfm_pkg.all;

entity axi4_lite_bfm_tb is
end entity axi4_lite_bfm_tb;

architecture tb of axi4_lite_bfm_tb is
  -- Constants
  constant CLK_PERIOD : time := 10 ns;
  constant ADDR_WIDTH : integer := 32;
  constant DATA_WIDTH : integer := 32;
  constant MAX_QUEUE_SIZE : integer := 16;

  -- Clock and Reset signals
  signal clk   : std_logic := '0';
  signal rst_n : std_logic := '0';

  -- AXI4-Lite signals between master and slave
  signal axi_m2s : axi4_lite_m2s_t(
    aw (
      awaddr(ADDR_WIDTH-1 downto 0)
      ),
    w (
      wdata(DATA_WIDTH-1 downto 0),
      wstrb((DATA_WIDTH/8)-1 downto 0)
      ),
    ar (
      araddr(ADDR_WIDTH-1 downto 0)
      )
    );
  signal axi_s2m : axi4_lite_s2m_t(
    r (
      rdata(DATA_WIDTH-1 downto 0)
      )
    );

  -- Master BFM control signals
  signal write_queue_full  : std_logic;
  signal read_queue_full   : std_logic;
  signal write_queue_empty : std_logic;
  signal read_queue_empty  : std_logic;

  signal write_queue : write_queue_t(MAX_QUEUE_SIZE-1 downto 0)(
    addr(ADDR_WIDTH-1 downto 0),
    data(DATA_WIDTH-1 downto 0),
    strb((DATA_WIDTH/8)-1 downto 0)
    );
  signal read_queue  : read_queue_t(MAX_QUEUE_SIZE-1 downto 0)(
    addr(ADDR_WIDTH-1 downto 0)
    );
  signal write_tail  : integer := 0;
  signal read_tail   : integer := 0;
  signal write_count : integer := 0;
  signal read_count  : integer := 0;

  -- Test control signals
  signal test_done : boolean := false;

begin
  -- Clock generation
  clk <= not clk after CLK_PERIOD/2;

  -- Reset generation
  rst_n <= '0', '1' after 100 ns;

  -- Instantiate master BFM
  master_bfm : entity work.axi4_lite_master_bfm
    generic map (
      ADDR_WIDTH => ADDR_WIDTH,
      DATA_WIDTH => DATA_WIDTH
    )
    port map (
      clk     => clk,
      rst_n   => rst_n,
      axi_m2s => axi_m2s,
      axi_s2m => axi_s2m,
      write_queue_full  => write_queue_full,
      read_queue_full   => read_queue_full,
      write_queue_empty => write_queue_empty,
      read_queue_empty  => read_queue_empty
    );

  -- Instantiate slave BFM
  slave_bfm : entity work.axi4_lite_slave_bfm
    generic map (
      ADDR_WIDTH => ADDR_WIDTH,
      DATA_WIDTH => DATA_WIDTH
    )
    port map (
      clk     => clk,
      rst_n   => rst_n,
      s_axi_awvalid => axi_m2s.aw.awvalid,
      s_axi_awready => axi_s2m.aw.awready,
      s_axi_awaddr  => axi_m2s.aw.awaddr,
      s_axi_awprot  => axi_m2s.aw.awprot,
      s_axi_wvalid  => axi_m2s.w.wvalid,
      s_axi_wready  => axi_s2m.w.wready,
      s_axi_wdata   => axi_m2s.w.wdata,
      s_axi_wstrb   => axi_m2s.w.wstrb,
      s_axi_bvalid  => axi_s2m.b.bvalid,
      s_axi_bready  => axi_m2s.b.bready,
      s_axi_bresp   => axi_s2m.b.bresp,
      s_axi_arvalid => axi_m2s.ar.arvalid,
      s_axi_arready => axi_s2m.ar.arready,
      s_axi_araddr  => axi_m2s.ar.araddr,
      s_axi_arprot  => axi_m2s.ar.arprot,
      s_axi_rvalid  => axi_s2m.r.rvalid,
      s_axi_rready  => axi_m2s.r.rready,
      s_axi_rdata   => axi_s2m.r.rdata,
      s_axi_rresp   => axi_s2m.r.rresp
    );

  -- Test process
  test_proc : process
    -- Test data
    constant TEST_ADDR : std_logic_vector(ADDR_WIDTH-1 downto 0) := x"0000_1000";
    constant TEST_DATA : std_logic_vector(DATA_WIDTH-1 downto 0) := x"DEAD_BEEF";
    constant TEST_STRB : std_logic_vector(DATA_WIDTH/8-1 downto 0) := (others => '1');
    constant TEST_PROT : std_logic_vector(2 downto 0) := "000";

    -- Wait for a number of clock cycles
    procedure wait_cycles(n : integer) is
    begin
      for i in 1 to n loop
        wait until rising_edge(clk);
      end loop;
    end procedure;

  begin
    -- Wait for reset to complete
    wait until rst_n = '1';
    wait_cycles(5);

    -- Test write transaction
    report "Starting write transaction test...";
    wait until write_queue_empty = '1';
    wait_cycles(2);

    -- Queue write transaction
    queue_write(
      queue => write_queue,
      tail  => write_tail,
      count => write_count,
      addr => TEST_ADDR,
      data => TEST_DATA,
      strb => TEST_STRB,
      prot => TEST_PROT
    );

    -- Wait for write to complete
    wait until write_queue_empty = '1';
    wait_cycles(5);

    -- Test read transaction
    report "Starting read transaction test...";
    wait until read_queue_empty = '1';
    wait_cycles(2);

    -- Queue read transaction
    queue_read(
      queue => read_queue,
      tail => read_tail,
      count => read_count,
      addr => TEST_ADDR,
      prot => TEST_PROT
    );

    -- Wait for read to complete
    wait until read_queue_empty = '1';
    wait_cycles(5);

    -- Test complete
    report "Test completed successfully!";
    test_done <= true;
    wait;
  end process;

  -- End simulation when test is done
  end_sim : process
  begin
    wait until test_done;
    wait for 1 us;
    std.env.finish;
  end process;

end architecture tb;

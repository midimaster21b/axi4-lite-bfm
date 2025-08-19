library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.axi4_lite_pkg.all;
use work.axi4_lite_bfm_pkg.all;

entity axi4_lite_master_bfm is
  generic (
    ADDR_WIDTH : integer := 32;
    DATA_WIDTH : integer := 32;
    MAX_QUEUE_SIZE : integer := 16
  );
  port (
    -- Clock and Reset
    clk     : in  std_logic;
    rst_n   : in  std_logic;

    -- AXI4-Lite Interface
    axi_m2s : out axi4_lite_m2s_t;
    axi_s2m : in  axi4_lite_s2m_t;

    -- Queue Status
    write_queue_full  : out std_logic;
    read_queue_full   : out std_logic;
    write_queue_empty : out std_logic;
    read_queue_empty  : out std_logic
  );
end entity;

architecture rtl of axi4_lite_master_bfm is
  -- Queue signals
  signal write_queue : write_queue_t(MAX_QUEUE_SIZE-1 downto 0)(
    addr(ADDR_WIDTH-1 downto 0),
    data(DATA_WIDTH-1 downto 0),
    strb((DATA_WIDTH/8)-1 downto 0)
  );
  signal read_queue  : read_queue_t(MAX_QUEUE_SIZE-1 downto 0)(
    addr(ADDR_WIDTH-1 downto 0)
  );
  signal write_head, write_tail : integer range 0 to MAX_QUEUE_SIZE-1;
  signal read_head, read_tail   : integer range 0 to MAX_QUEUE_SIZE-1;
  signal write_count, read_count : integer range 0 to MAX_QUEUE_SIZE;

  -- State machine states
  type write_state_t is (IDLE, ADDR_PHASE, DATA_PHASE, RESP_PHASE);
  type read_state_t is (IDLE, ADDR_PHASE, DATA_PHASE);

  signal write_state : write_state_t;
  signal read_state  : read_state_t;

  -- Internal signals
  signal current_write : write_transaction_t(
    addr(ADDR_WIDTH-1 downto 0),
    data(DATA_WIDTH-1 downto 0),
    strb((DATA_WIDTH/8)-1 downto 0)
  );
  signal current_read  : read_transaction_t(
    addr(ADDR_WIDTH-1 downto 0)
  );

  ----------------------------------------------------------------------------
  -- Queue Management Functions
  ----------------------------------------------------------------------------
  -- Queue a write transaction
  impure function axi_queue_write(
    addr : std_logic_vector(ADDR_WIDTH-1 downto 0);
    data : std_logic_vector(DATA_WIDTH-1 downto 0);
    strb : std_logic_vector((DATA_WIDTH/8)-1 downto 0);
    prot : std_logic_vector(2 downto 0)
  ) return boolean is
  begin
    if write_count < MAX_QUEUE_SIZE then
      -- Call the package procedure to handle signal assignments
      queue_write(
        queue => write_queue,
        tail => write_tail,
        count => write_count,
        addr => addr,
        data => data,
        strb => strb,
        prot => prot
      );
      return true;
    else
      return false;
    end if;
  end function;

  -- Queue a read transaction
  impure function axi_queue_read(
    addr : std_logic_vector(ADDR_WIDTH-1 downto 0);
    prot : std_logic_vector(2 downto 0)
  ) return boolean is
  begin
    if read_count < MAX_QUEUE_SIZE then
      -- Call the package procedure to handle signal assignments
      queue_read(
        queue => read_queue,
        tail => read_tail,
        count => read_count,
        addr => addr,
        prot => prot
      );
      return true;
    else
      return false;
    end if;
  end function;

begin
  -- Queue status outputs
  write_queue_full  <= '1' when write_count = MAX_QUEUE_SIZE else '0';
  read_queue_full   <= '1' when read_count = MAX_QUEUE_SIZE else '0';
  write_queue_empty <= '1' when write_count = 0 else '0';
  read_queue_empty  <= '1' when read_count = 0 else '0';

  -- Write channel state machine
  write_proc : process(clk, rst_n)
  begin
    if rst_n = '0' then
      write_state <= IDLE;
      write_head <= 0;
      write_tail <= 0;
      write_count <= 0;

      axi_m2s.aw.awvalid <= '0';
      axi_m2s.aw.awaddr <= (others => '0');
      axi_m2s.aw.awprot <= (others => '0');

      axi_m2s.w.wvalid <= '0';
      axi_m2s.w.wdata <= (others => '0');
      axi_m2s.w.wstrb <= (others => '0');

      axi_m2s.b.bready <= '0';

    elsif rising_edge(clk) then
      case write_state is
        when IDLE =>
          if write_count > 0 then
            current_write <= write_queue(write_head);
            write_state <= ADDR_PHASE;
            axi_m2s.aw.awvalid <= '1';
            axi_m2s.aw.awaddr <= write_queue(write_head).addr;
            axi_m2s.aw.awprot <= write_queue(write_head).prot;
          end if;

        when ADDR_PHASE =>
          if axi_s2m.aw.awready = '1' then
            axi_m2s.aw.awvalid <= '0';
            write_state <= DATA_PHASE;
            axi_m2s.w.wvalid <= '1';
            axi_m2s.w.wdata <= current_write.data;
            axi_m2s.w.wstrb <= current_write.strb;
          end if;

        when DATA_PHASE =>
          if axi_s2m.w.wready = '1' then
            axi_m2s.w.wvalid <= '0';
            write_state <= RESP_PHASE;
          end if;

        when RESP_PHASE =>
          if axi_s2m.b.bvalid = '1' then
            if write_head = MAX_QUEUE_SIZE-1 then
              write_head <= 0;
            else
              write_head <= write_head + 1;
            end if;
            write_count <= write_count - 1;
            write_state <= IDLE;
          end if;
      end case;
    end if;
  end process;

  -- Read channel state machine
  read_proc : process(clk, rst_n)
  begin
    if rst_n = '0' then
      read_state <= IDLE;
      read_head <= 0;
      read_tail <= 0;
      read_count <= 0;
      axi_m2s.ar.arvalid <= '0';
      axi_m2s.ar.araddr  <= (others => '0');
      axi_m2s.ar.arprot  <= (others => '0');
      axi_m2s.r.rready   <= '1';
    elsif rising_edge(clk) then
      case read_state is
        when IDLE =>
          if read_count > 0 then
            current_read <= read_queue(read_head);
            read_state <= ADDR_PHASE;
            axi_m2s.ar.arvalid <= '1';
            axi_m2s.ar.araddr <= read_queue(read_head).addr;
            axi_m2s.ar.arprot <= read_queue(read_head).prot;
          end if;

        when ADDR_PHASE =>
          if axi_s2m.ar.arready = '1' then
            axi_m2s.ar.arvalid <= '0';
            read_state <= DATA_PHASE;
          end if;

        when DATA_PHASE =>
          if axi_s2m.r.rvalid = '1' then
            if read_head = MAX_QUEUE_SIZE-1 then
              read_head <= 0;
            else
              read_head <= read_head + 1;
            end if;
            read_count <= read_count - 1;
            read_state <= IDLE;
          end if;
      end case;
    end if;
  end process;

end architecture;

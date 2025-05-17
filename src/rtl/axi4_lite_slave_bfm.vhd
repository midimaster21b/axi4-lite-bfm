library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library work;
use work.axi4_lite_pkg.all;

entity axi4_lite_slave_bfm is
  generic (
    -- AXI4-Lite interface parameters
    ADDR_WIDTH : integer := 32;
    DATA_WIDTH : integer := 32;
    -- Response delay parameters (in clock cycles)
    MIN_RESP_DELAY : integer := 0;
    MAX_RESP_DELAY : integer := 5
  );
  port (
    -- Clock and Reset
    clk     : in  std_logic;
    rst_n   : in  std_logic;

    -- AXI4-Lite Write Address Channel
    s_axi_awvalid : in  std_logic;
    s_axi_awready : out std_logic;
    s_axi_awaddr  : in  std_logic_vector(ADDR_WIDTH-1 downto 0);
    s_axi_awprot  : in  std_logic_vector(2 downto 0);

    -- AXI4-Lite Write Data Channel
    s_axi_wvalid  : in  std_logic;
    s_axi_wready  : out std_logic;
    s_axi_wdata   : in  std_logic_vector(DATA_WIDTH-1 downto 0);
    s_axi_wstrb   : in  std_logic_vector((DATA_WIDTH/8)-1 downto 0);

    -- AXI4-Lite Write Response Channel
    s_axi_bvalid  : out std_logic;
    s_axi_bready  : in  std_logic;
    s_axi_bresp   : out std_logic_vector(1 downto 0);

    -- AXI4-Lite Read Address Channel
    s_axi_arvalid : in  std_logic;
    s_axi_arready : out std_logic;
    s_axi_araddr  : in  std_logic_vector(ADDR_WIDTH-1 downto 0);
    s_axi_arprot  : in  std_logic_vector(2 downto 0);

    -- AXI4-Lite Read Data Channel
    s_axi_rvalid  : out std_logic;
    s_axi_rready  : in  std_logic;
    s_axi_rdata   : out std_logic_vector(DATA_WIDTH-1 downto 0);
    s_axi_rresp   : out std_logic_vector(1 downto 0)
  );
end entity axi4_lite_slave_bfm;

architecture rtl of axi4_lite_slave_bfm is
  -- Constants for AXI4-Lite responses
  constant AXI_RESP_OKAY   : std_logic_vector(1 downto 0) := "00";
  constant AXI_RESP_EXOKAY : std_logic_vector(1 downto 0) := "01";
  constant AXI_RESP_SLVERR : std_logic_vector(1 downto 0) := "10";
  constant AXI_RESP_DECERR : std_logic_vector(1 downto 0) := "11";

  -- Internal state machine states
  type write_state_t is (IDLE, WAIT_DATA, SEND_RESP);
  type read_state_t is (IDLE, SEND_DATA);

  -- Write channel state and signals
  signal write_state : write_state_t;
  signal write_delay : integer range 0 to MAX_RESP_DELAY;

  -- Read channel state and signals
  signal read_state : read_state_t;
  signal read_delay : integer range 0 to MAX_RESP_DELAY;

  -- Random number generation

  impure function random_delay return integer is
    variable rand : real;
    variable seed1, seed2 : integer := 1;
  begin
    uniform(seed1, seed2, rand);
    return integer(rand * real(MAX_RESP_DELAY - MIN_RESP_DELAY + 1)) + MIN_RESP_DELAY;
  end function;

  impure function random_data return std_logic_vector is
    variable rand : real;
    variable result : std_logic_vector(DATA_WIDTH-1 downto 0);
    variable seed1, seed2 : integer := 1;
  begin
    for i in 0 to DATA_WIDTH-1 loop
      uniform(seed1, seed2, rand);
      result(i) := '1' when rand > 0.5 else '0';
    end loop;
    return result;
  end function;

begin
  -- Write channel FSM
  write_fsm : process(clk, rst_n)
  begin
    if rst_n = '0' then
      write_state <= IDLE;
      s_axi_awready <= '0';
      s_axi_wready <= '0';
      s_axi_bvalid <= '0';
      s_axi_bresp <= AXI_RESP_OKAY;
      write_delay <= 0;
    elsif rising_edge(clk) then
      case write_state is
        when IDLE =>
          s_axi_awready <= '1';
          s_axi_wready <= '0';
          s_axi_bvalid <= '0';

          if s_axi_awvalid = '1' then
            s_axi_awready <= '0';
            write_state <= WAIT_DATA;
          end if;

        when WAIT_DATA =>
          s_axi_wready <= '1';

          if s_axi_wvalid = '1' then
            s_axi_wready <= '0';
            write_delay <= random_delay;
            write_state <= SEND_RESP;
          end if;

        when SEND_RESP =>
          if write_delay = 0 then
            s_axi_bvalid <= '1';
            s_axi_bresp <= AXI_RESP_OKAY;

            if s_axi_bready = '1' then
              s_axi_bvalid <= '0';
              write_state <= IDLE;
            end if;
          else
            write_delay <= write_delay - 1;
          end if;
      end case;
    end if;
  end process;

  -- Read channel FSM
  read_fsm : process(clk, rst_n)
  begin
    if rst_n = '0' then
      read_state <= IDLE;
      s_axi_arready <= '0';
      s_axi_rvalid <= '0';
      s_axi_rdata <= (others => '0');
      s_axi_rresp <= AXI_RESP_OKAY;
      read_delay <= 0;
    elsif rising_edge(clk) then
      case read_state is
        when IDLE =>
          s_axi_arready <= '1';
          s_axi_rvalid <= '0';

          if s_axi_arvalid = '1' then
            s_axi_arready <= '0';
            read_delay <= random_delay;
            read_state <= SEND_DATA;
          end if;

        when SEND_DATA =>
          if read_delay = 0 then
            s_axi_rvalid <= '1';
            s_axi_rdata <= random_data;
            s_axi_rresp <= AXI_RESP_OKAY;

            if s_axi_rready = '1' then
              s_axi_rvalid <= '0';
              read_state <= IDLE;
            end if;
          else
            read_delay <= read_delay - 1;
          end if;
      end case;
    end if;
  end process;

end architecture rtl;

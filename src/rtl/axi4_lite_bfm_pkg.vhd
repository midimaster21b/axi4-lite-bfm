library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.axi4_lite_pkg.all;

package axi4_lite_bfm_pkg is
  -- Transaction record types
  type write_transaction_t is record
    addr : std_logic_vector;
    data : std_logic_vector;
    strb : std_logic_vector;
    prot : std_logic_vector(2 downto 0);
  end record;

  type read_transaction_t is record
    addr : std_logic_vector;
    prot : std_logic_vector(2 downto 0);
  end record;

  -- Transaction queues
  type write_queue_t is array (integer range <>) of write_transaction_t;
  type read_queue_t is array (integer range <>) of read_transaction_t;

end package;

package body axi4_lite_bfm_pkg is
end package body axi4_lite_bfm_pkg;

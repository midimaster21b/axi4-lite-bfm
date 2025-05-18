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

  -- User interface procedures
  procedure queue_write(
    signal queue : inout write_queue_t;
    signal tail : inout integer;
    signal count : inout integer;
    addr : in std_logic_vector;
    data : in std_logic_vector;
    strb : in std_logic_vector;
    prot : in std_logic_vector(2 downto 0)
  );

  procedure queue_read(
    signal queue : inout read_queue_t;
    signal tail : inout integer;
    signal count : inout integer;
    addr : in std_logic_vector;
    prot : in std_logic_vector(2 downto 0)
  );

end package;

package body axi4_lite_bfm_pkg is
  -- User interface procedures
  procedure queue_write(
    signal queue : inout write_queue_t;
    signal tail : inout integer;
    signal count : inout integer;
    addr : in std_logic_vector;
    data : in std_logic_vector;
    strb : in std_logic_vector;
    prot : in std_logic_vector(2 downto 0)
  ) is
  begin
    if count < queue'length then
      queue(tail) <= (addr => addr, data => data, strb => strb, prot => prot);
      if tail = queue'high then
        tail <= queue'low;
      else
        tail <= tail + 1;
      end if;
      count <= count + 1;
    end if;
  end procedure;

  procedure queue_read(
    signal queue : inout read_queue_t;
    signal tail : inout integer;
    signal count : inout integer;
    addr : in std_logic_vector;
    prot : in std_logic_vector(2 downto 0)
  ) is
  begin
    if count < queue'length then
      queue(tail) <= (addr => addr, prot => prot);
      if tail = queue'high then
        tail <= queue'low;
      else
        tail <= tail + 1;
      end if;
      count <= count + 1;
    end if;
  end procedure;

end package body;

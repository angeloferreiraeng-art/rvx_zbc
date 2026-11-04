//-----------------------------------------------------------------------------
// tb_multiplier_io.sv
// Standalone self-checking testbench for the simple-IO multiplier / CLMUL
// accelerator (multiplier_io). No ariane_pkg / config_pkg.
//-----------------------------------------------------------------------------
`timescale 1ns/1ps

module tb_multiplier_io;

  // ---- DUT parameters ------------------------------------------------------
  localparam int unsigned XLEN       = 32;
  localparam int unsigned ID_W       = 4;
  localparam time         CLK_PERIOD = 10ns;
  localparam int unsigned POLL_LIMIT = 1000;   // max STATUS polls per op
  localparam int unsigned RESP_LIMIT = 16;     // max cycles to wait for a response

  // Op encoding (must match multiplier)
  localparam logic [3:0] OP_MUL    = 4'd0;
  localparam logic [3:0] OP_MULH   = 4'd1;
  localparam logic [3:0] OP_MULHU  = 4'd2;
  localparam logic [3:0] OP_MULHSU = 4'd3;
  localparam logic [3:0] OP_MULW   = 4'd4;
  localparam logic [3:0] OP_CLMUL  = 4'd5;
  localparam logic [3:0] OP_CLMULH = 4'd6;
  localparam logic [3:0] OP_CLMULR = 4'd7;

  // Register offsets
  localparam logic [4:0] REG_CTRL   = 5'h00;
  localparam logic [4:0] REG_STATUS = 5'h04;
  localparam logic [4:0] REG_OP_A   = 5'h08;
  localparam logic [4:0] REG_OP_B   = 5'h0C;
  localparam logic [4:0] REG_RES_LO = 5'h10;
  localparam logic [4:0] REG_RES_HI = 5'h14;

  // ---- DUT signals ---------------------------------------------------------
  logic        clock, reset_n;

  logic [ 4:0] rw_address;
  logic [31:0] read_data;
  logic        read_request;
  logic        read_response;
  logic [31:0] write_data;
  logic [ 3:0] write_strobe;
  logic        write_request;
  logic        write_response;

  // ---- Clock / reset -------------------------------------------------------
  initial clock = 1'b0;
  always #(CLK_PERIOD/2) clock = ~clock;

  initial begin
    reset_n = 1'b0;
    repeat (5) @(posedge clock);
    reset_n <= 1'b1;
  end

  // ---- DUT -----------------------------------------------------------------
  rvx_clmul #(
      .XLEN (XLEN),
      .ID_W (ID_W)
  ) dut (
      .clock          (clock),
      .reset_n        (reset_n),
      .rw_address     (rw_address),
      .read_data      (read_data),
      .read_request   (read_request),
      .read_response  (read_response),
      .write_data     (write_data),
      .write_strobe   (write_strobe),
      .write_request  (write_request),
      .write_response (write_response)
  );

  // ---- Scoreboard ----------------------------------------------------------
  int unsigned errors    = 0;
  int unsigned tests_run = 0;

  task automatic check(input string name,
                       input logic [XLEN-1:0] got,
                       input logic [XLEN-1:0] exp);
    tests_run++;
    if (got !== exp) begin
      errors++;
      $error("[CHECK FAIL] %s: got 0x%08h, expected 0x%08h", name, got, exp);
    end else begin
      $display("[CHECK OK  ] %s: 0x%08h", name, got);
    end
  endtask

  // ---- Bus BFM -------------------------------------------------------------
  // Convention: drive with non-blocking assignments right after a posedge.
  // A request is held for exactly one cycle. The response (and read data)
  // appear one cycle after the request is sampled by the DUT.

  task automatic bus_write(input logic [4:0]  addr,
                           input logic [31:0] data,
                           input logic [3:0]  strb = 4'hF);
    int unsigned wait_cycles;

    @(posedge clock);
    rw_address    <= addr;
    write_data    <= data;
    write_strobe  <= strb;
    write_request <= 1'b1;

    @(posedge clock);                   // DUT samples the request here
    write_request <= 1'b0;

    wait_cycles = 0;
    while (!write_response && wait_cycles < RESP_LIMIT) begin
      @(posedge clock);
      wait_cycles++;
    end
    if (!write_response) begin
      errors++;
      $error("[BUS] write 0x%02h: no write_response", addr);
    end
  endtask

  task automatic bus_read(input  logic [4:0]  addr,
                          output logic [31:0] data);
    int unsigned wait_cycles;

    @(posedge clock);
    rw_address   <= addr;
    read_request <= 1'b1;

    @(posedge clock);                   // DUT samples the request here
    read_request <= 1'b0;

    wait_cycles = 0;
    while (!read_response && wait_cycles < RESP_LIMIT) begin
      @(posedge clock);
      wait_cycles++;
    end
    if (!read_response) begin
      errors++;
      $error("[BUS] read 0x%02h: no read_response", addr);
    end
    data = read_data;                   // sampled on the response cycle
  endtask

  // ---- Golden reference model ---------------------------------------------
  // All arithmetic is done at 2*XLEN bits.
  function automatic logic [XLEN-1:0] ref_mul(input logic [3:0]      op,
                                              input logic [XLEN-1:0] a,
                                              input logic [XLEN-1:0] b);
    logic signed [2*XLEN-1:0] sa, sb, sbu, sp;
    logic        [2*XLEN-1:0] ua, ub, up, cl;

    sa  = $signed(a);              // sign-extended
    sb  = $signed(b);
    sbu = {{XLEN{1'b0}}, b};       // zero-extended, treated as signed
    ua  = {{XLEN{1'b0}}, a};
    ub  = {{XLEN{1'b0}}, b};
    up  = ua * ub;
    cl  = '0;
    for (int i = 0; i < XLEN; i++)
      if (b[i]) cl ^= (ua << i);

    case (op)
      OP_MUL:    return up[XLEN-1:0];
      OP_MULH:   begin sp = sa * sb;  return sp[2*XLEN-1:XLEN]; end
      OP_MULHU:  return up[2*XLEN-1:XLEN];
      OP_MULHSU: begin sp = sa * sbu; return sp[2*XLEN-1:XLEN]; end
      OP_MULW:   return XLEN'($signed(up[31:0]));      // sign-extend low word
      OP_CLMUL:  return cl[XLEN-1:0];
      OP_CLMULH: return cl[2*XLEN-1:XLEN];
      OP_CLMULR: return cl[2*XLEN-2:XLEN-1];
      default:   return '0;
    endcase
  endfunction

  // ---- Drive-and-check helper ---------------------------------------------
  task automatic run_mult(input logic [3:0]      op,
                          input logic [XLEN-1:0] a,
                          input logic [XLEN-1:0] b,
                          input logic [XLEN-1:0] exp);
    logic [31:0] rd;
    logic [31:0] ctrl;
    int unsigned polls;

    bus_write(REG_OP_A, a);
    bus_write(REG_OP_B, b);

    ctrl               = 32'h0;
    ctrl[0]            = 1'b1;          // start
    ctrl[4:1]          = op;
    ctrl[4+ID_W:5]     = 4'hA;          // transaction ID
    bus_write(REG_CTRL, ctrl);

    // poll done, with timeout
    polls = 0;
    do begin
      bus_read(REG_STATUS, rd);
      polls++;
    end while (!rd[0] && polls < POLL_LIMIT);

    if (!rd[0]) begin
      errors++;
      tests_run++;
      $error("[TIMEOUT] op=%0d a=0x%08h b=0x%08h never set STATUS.done", op, a, b);
      return;
    end

    bus_read(REG_RES_LO, rd);
    check($sformatf("op=%0d a=0x%08h b=0x%08h", op, a, b), rd[XLEN-1:0], exp);
  endtask

  // ---- Main -----------------------------------------------------------------
  logic [31:0] rd;
  logic [31:0] rd_pair [2];

  initial begin
    // Init master
    rw_address    = '0;
    write_data    = '0;
    write_strobe  = '0;
    write_request = 1'b0;
    read_request  = 1'b0;

    wait (reset_n);
    repeat (3) @(posedge clock);

    // ---- TEST 1: register read/write ----
    $display("\n===== TEST 1: register read/write =====");
    bus_write(REG_OP_A, 32'hDEAD_BEEF);
    bus_read (REG_OP_A, rd);
    check("OP_A readback", rd, 32'hDEAD_BEEF);

    bus_write(REG_OP_B, 32'hCAFE_F00D);
    bus_read (REG_OP_B, rd);
    check("OP_B readback", rd, 32'hCAFE_F00D);

    bus_read (REG_STATUS, rd);
    check("STATUS idle", rd[1:0], 2'b00);

    // ---- TEST 1b: byte strobes ----
    $display("\n===== TEST 1b: byte-strobe merge =====");
    bus_write(REG_OP_A, 32'hFFFF_FFFF);
    bus_write(REG_OP_A, 32'h1122_3344, 4'b0011);   // only low 2 bytes
    bus_read (REG_OP_A, rd);
    check("OP_A strobe 0011", rd, 32'hFFFF_3344);

    bus_write(REG_OP_A, 32'hAABB_CCDD, 4'b1000);   // only top byte
    bus_read (REG_OP_A, rd);
    check("OP_A strobe 1000", rd, 32'hAAFF_3344);

    bus_write(REG_OP_A, 32'h0000_0000, 4'b0000);   // no bytes: no change
    bus_read (REG_OP_A, rd);
    check("OP_A strobe 0000", rd, 32'hAAFF_3344);

    // ---- TEST 2: directed multiplications (hard-coded golden values) ----
    $display("\n===== TEST 2: directed multiplications =====");
    run_mult(OP_MUL,    32'd6,         32'd7,         32'd42);
    run_mult(OP_MUL,    32'hFFFF_FFFF, 32'hFFFF_FFFF, 32'h0000_0001);
    run_mult(OP_MULH,   32'hFFFF_FFFF, 32'h0000_0002, 32'hFFFF_FFFF); // -1*2 = -2 -> hi = -1
    run_mult(OP_MULHU,  32'hFFFF_FFFF, 32'hFFFF_FFFF, 32'hFFFF_FFFE);
    run_mult(OP_MULHSU, 32'hFFFF_FC18, 32'h0000_03E8, 32'hFFFF_FFFF); // -1000*1000 -> hi = -1
    run_mult(OP_MULW,   32'h7FFF_FFFF, 32'h0000_0002, 32'hFFFF_FFFE);

    // ---- TEST 3: CLMUL family ----
    $display("\n===== TEST 3: CLMUL family =====");
    run_mult(OP_CLMUL,  32'h0000_0003, 32'h0000_0005, 32'h0000_000F);  // 011 (x) 101 = 1111
    run_mult(OP_CLMUL,  32'hFFFF_FFFF, 32'hFFFF_FFFF, 32'h5555_5555);
    run_mult(OP_CLMULH, 32'hFFFF_FFFF, 32'hFFFF_FFFF, 32'h5555_5555);
    run_mult(OP_CLMULR, 32'hFFFF_FFFF, 32'hFFFF_FFFF, 32'hAAAA_AAAA);
    // model-checked
    run_mult(OP_CLMUL,  32'hDEAD_BEEF, 32'hCAFE_F00D, ref_mul(OP_CLMUL,  32'hDEAD_BEEF, 32'hCAFE_F00D));
    run_mult(OP_CLMULH, 32'hDEAD_BEEF, 32'hCAFE_F00D, ref_mul(OP_CLMULH, 32'hDEAD_BEEF, 32'hCAFE_F00D));
    run_mult(OP_CLMULR, 32'hDEAD_BEEF, 32'hCAFE_F00D, ref_mul(OP_CLMULR, 32'hDEAD_BEEF, 32'hCAFE_F00D));

    // ---- TEST 4: randomized regression (all ops, including CLMUL family) ----
    $display("\n===== TEST 4: randomized regression =====");
    for (int i = 0; i < 200; i++) begin
      logic [XLEN-1:0] a, b, e;
      logic [3:0]      op;
      a  = $urandom;
      b  = $urandom;
      op = 4'($urandom_range(0, 7));
      e  = ref_mul(op, a, b);
      run_mult(op, a, b, e);
    end

    // ---- TEST 5: back-to-back reads (one request per cycle) ----
    $display("\n===== TEST 5: back-to-back reads =====");
    bus_write(REG_OP_A, 32'h1234_5678);
    bus_write(REG_OP_B, 32'h9ABC_DEF0);

    fork
      begin : issue_rd
        @(posedge clock);
        rw_address   <= REG_OP_A;
        read_request <= 1'b1;
        @(posedge clock);
        rw_address   <= REG_OP_B;       // request stays high: second read
        @(posedge clock);
        read_request <= 1'b0;
      end
      begin : collect_rd
        for (int k = 0; k < 2; k++) begin
          do @(posedge clock); while (!read_response);
          rd_pair[k] = read_data;
        end
      end
    join
    check("back-to-back OP_A", rd_pair[0], 32'h1234_5678);
    check("back-to-back OP_B", rd_pair[1], 32'h9ABC_DEF0);

    // ---- Final report ----
    repeat (5) @(posedge clock);
    $display("\n=============================================");
    $display("  TESTS RUN : %0d", tests_run);
    $display("  ERRORS    : %0d", errors);
    if (errors == 0) $display("  *** TEST PASSED ***");
    else             $display("  *** TEST FAILED ***");
    $display("=============================================\n");
    $finish;
  end

  // Watchdog
  initial begin
    #5_000_000;
    errors++;
    $error("[WATCHDOG] simulation timeout");
    $display("  *** TEST FAILED (timeout) ***");
    $finish;
  end

  // VCD dump
  initial begin
    if ($test$plusargs("dump")) begin
      $dumpfile("tb_multiplier_io.vcd");
      $dumpvars(0, tb_multiplier_io);
    end
  end

endmodule

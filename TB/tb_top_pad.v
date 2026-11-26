//-----------------------------------------------------------------------------
// tb_top_pad_rvx.sv
// System-level self-checking testbench: whole RISC-V CPU (top_pad_rvx) with the
// rvx_clmul accelerator reached through the SoC's internal AXI fabric.
//
// top_pad_rvx only exposes clock/reset, UART, SPI, GPIO and I2C pins, so the
// testbench works as follows:
//   1. build an RV32I test program in SV (mini assembler below) performing the
//      SAME tests as the block-level TB (register R/W, byte strobes, directed
//      mults, CLMUL family, 200 random ops, back-to-back reads),
//   2. BACKDOOR-load it into the SoC's internal RAM through a hierarchical path
//      (`MEM_PATH`) shortly after time 0, before reset is released,
//   3. let the CPU run; the program stores every observed value into a result
//      buffer in RAM and finally writes a DONE magic word,
//   4. the TB polls the DONE word through the backdoor, then compares the result
//      buffer against the golden model (ref_mul) and hard-coded values.
//
// ASSUMPTIONS - edit the "SoC backdoor" section and the memory map:
//   * The CPU starts fetching at MEM_BASE from a RAM that the TB can overwrite
//     (i.e. no ROM bootloader that jumps elsewhere / copies from SPI or UART).
//   * That RAM is 32-bit-word addressable via `MEM_PATH`[word_index]. If it is
//     byte-wide or wider, change dbg_read/dbg_write only.
//   * rvx_clmul is mapped at CLMUL_BASE (32-byte aligned window) in the SoC.
//   * Any D-cache is write-through/disabled so stores reach RAM.
//-----------------------------------------------------------------------------
`timescale 1ns/1ps
 
module tb_top_pad_rvx;
 
  // ---- Parameters ----------------------------------------------------------
  localparam int unsigned XLEN       = 32;
  localparam int unsigned ID_W       = 4;
  localparam time         CLK_PERIOD = 10ns;
  localparam int unsigned POLL_LIMIT = 1000;        // SW poll iterations per op
  localparam int unsigned N_RANDOM   = 200;
  localparam int unsigned TIMEOUT_CYCLES = 20_000_000;
 
  // ---- Memory map (EDIT to match the SoC) ----------------------------------
  localparam logic [31:0] MEM_BASE   = 32'h0000_0000;   // RAM base = boot address
  localparam int unsigned MEM_BYTES  = 32'h0002_0000;   // 128 KB
  localparam int unsigned MEM_WORDS  = MEM_BYTES / 4;
  localparam int unsigned CODE_WORDS = 16384;           // code lives in first 64 KB
  localparam logic [31:0] RES_BASE   = MEM_BASE + 32'h0001_0000; // result buffer
  localparam logic [31:0] DONE_ADDR  = MEM_BASE + 32'h0001_FFF0;
  localparam logic [31:0] DONE_MAGIC = 32'h600D_F00D;
  localparam logic [31:0] CLMUL_BASE = 32'h4000_0000;   // accelerator window
 
  // Op encoding (must match multiplier)
  localparam logic [3:0] OP_MUL    = 4'd0;
  localparam logic [3:0] OP_MULH   = 4'd1;
  localparam logic [3:0] OP_MULHU  = 4'd2;
  localparam logic [3:0] OP_MULHSU = 4'd3;
  localparam logic [3:0] OP_MULW   = 4'd4;
  localparam logic [3:0] OP_CLMUL  = 4'd5;
  localparam logic [3:0] OP_CLMULH = 4'd6;
  localparam logic [3:0] OP_CLMULR = 4'd7;
 
  // Register offsets inside the accelerator window
  localparam logic [11:0] REG_CTRL   = 12'h000;
  localparam logic [11:0] REG_STATUS = 12'h004;
  localparam logic [11:0] REG_OP_A   = 12'h008;
  localparam logic [11:0] REG_OP_B   = 12'h00C;
  localparam logic [11:0] REG_RES_LO = 12'h010;
  localparam logic [11:0] REG_RES_HI = 12'h014;
 
  // Registers used by the generated program
  localparam logic [4:0] X0   = 5'd0;
  localparam logic [4:0] XBASE = 5'd5;    // t0 : CLMUL_BASE
  localparam logic [4:0] XTMP  = 5'd6;    // t1 : scratch / operands
  localparam logic [4:0] XRES  = 5'd7;    // t2 : read-back value
  localparam logic [4:0] XPTR  = 5'd28;   // t3 : result-buffer write pointer
  localparam logic [4:0] XSTAT = 5'd29;   // t4 : polled status
  localparam logic [4:0] XCNT  = 5'd30;   // t5 : poll counter / scratch
  localparam logic [4:0] XRES2 = 5'd31;   // t6 : 2nd read-back (back-to-back)
 
  // ---- Clock / reset -------------------------------------------------------
  logic clock, reset_n;
 
  initial clock = 1'b0;
  always #(CLK_PERIOD/2) clock = ~clock;
 
  initial begin
    reset_n = 1'b0;
    repeat (10) @(posedge clock);
    reset_n <= 1'b1;
  end
 
  // ---- Pins of top_pad_rvx ---------------------------------------------------
  logic        uart_rx;
  wire         uart_tx;
  wire         sclk, mosi, cs;
  logic        miso;
  tri1  [7:0]  gpio;        // pulled up (idle) - nothing drives them
  tri1         i2c_sda;
  tri1         i2c_scl;
 
  initial begin
    uart_rx = 1'b1;         // UART idle
    miso    = 1'b0;
  end
 
  // ---- DUT ------------------------------------------------------------------
  top_pad_rvx dut (
      .clock   (clock),
      .reset_n (reset_n),
      .uart_rx (uart_rx),
      .uart_tx (uart_tx),
      .sclk    (sclk),
      .mosi    (mosi),
      .miso    (miso),
      .cs      (cs),
      .gpio    (gpio),
      .i2c_sda (i2c_sda),
      .i2c_scl (i2c_scl)
  );
 
  // ---- SoC backdoor (EDIT THESE) ----------------------------------------------
  // Hierarchical path to the RAM array that the CPU boots from / uses as data RAM.
  `ifndef MEM_PATH
    `define MEM_PATH dut.u_core.          // <-- EDIT: e.g. dut.<soc>.<ram>.<array>
  `endif
  localparam int unsigned MEM_ARRAY_OFFSET = 0;   // word index of MEM_BASE inside the array
 
  function automatic void dbg_write(input int unsigned widx, input logic [31:0] data);
    `MEM_PATH[widx + MEM_ARRAY_OFFSET] = data;
  endfunction
 
  function automatic logic [31:0] dbg_read(input int unsigned widx);
    return `MEM_PATH[widx + MEM_ARRAY_OFFSET];
  endfunction
 
  // Program image bookkeeping (used by the assembler below)
  int unsigned pc_w = 0;                       // next code word index
 
  // Expected-result queues; slot i of the result buffer <-> entry i
  logic [31:0] exp_q  [$];
  logic [31:0] mask_q [$];
  string       name_q [$];
 
  // ---- Local image of the program (built at time 0, loaded at 1 ns) ------------
  logic [31:0] mem [MEM_WORDS];
  logic        done_seen = 1'b0;
 
  // Load AFTER any $readmemh done by the RTL at time 0, BEFORE reset is released.
  task automatic load_program();
    for (int i = 0; i < pc_w; i++) dbg_write(i, mem[i]);
    // clear the DONE flag and the result buffer region used by this test
    dbg_write((DONE_ADDR - MEM_BASE) / 4, 32'h0);
    for (int i = 0; i < exp_q.size() + 4; i++)
      dbg_write((RES_BASE - MEM_BASE) / 4 + i, 32'h0);
    $display("[TB] program loaded into SoC RAM (%0d words)", pc_w);
  endtask
 
  // Detect completion by polling the DONE word through the backdoor
  always @(posedge clock) begin
    if (reset_n && !done_seen &&
        dbg_read((DONE_ADDR - MEM_BASE) / 4) === DONE_MAGIC)
      done_seen <= 1'b1;
  end
 
  // ---- Scoreboard ----------------------------------------------------------
  int unsigned errors    = 0;
  int unsigned tests_run = 0;
 
  task automatic check(input string name,
                       input logic [XLEN-1:0] got,
                       input logic [XLEN-1:0] exp,
                       input logic [XLEN-1:0] mask = '1);
    tests_run++;
    if ((got & mask) !== (exp & mask)) begin
      errors++;
      $error("[CHECK FAIL] %s: got 0x%08h, expected 0x%08h", name, got, exp);
    end else begin
      $display("[CHECK OK  ] %s: 0x%08h", name, got);
    end
  endtask
 
  // ---- Golden reference model (unchanged from block-level TB) ---------------
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
 
  // ---- Mini RV32I assembler ------------------------------------------------
 
  function automatic logic [31:0] enc_u(input logic [19:0] imm20,
                                        input logic [4:0]  rd,
                                        input logic [6:0]  opc);
    return {imm20, rd, opc};
  endfunction
 
  function automatic logic [31:0] enc_i(input logic [11:0] imm,
                                        input logic [4:0]  rs1,
                                        input logic [2:0]  f3,
                                        input logic [4:0]  rd,
                                        input logic [6:0]  opc);
    return {imm, rs1, f3, rd, opc};
  endfunction
 
  function automatic logic [31:0] enc_s(input logic [11:0] imm,
                                        input logic [4:0]  rs2,
                                        input logic [4:0]  rs1,
                                        input logic [2:0]  f3);
    return {imm[11:5], rs2, rs1, f3, imm[4:0], 7'b0100011};
  endfunction
 
  function automatic logic [31:0] enc_b(input int           off,
                                        input logic [4:0]   rs2,
                                        input logic [4:0]   rs1,
                                        input logic [2:0]   f3);
    logic [12:0] o;
    o = off[12:0];
    return {o[12], o[10:5], rs2, rs1, f3, o[4:1], o[11], 7'b1100011};
  endfunction
 
  task automatic emit(input logic [31:0] w);
    if (pc_w >= CODE_WORDS) $fatal(1, "program too large (CODE_WORDS=%0d)", CODE_WORDS);
    mem[pc_w] = w;
    pc_w++;
  endtask
 
  task automatic emit_li(input logic [4:0] rd, input logic [31:0] val);
    logic [31:0] hi;
    hi = val + 32'h800;                                   // compensate addi sign-extension
    emit(enc_u(hi[31:12], rd, 7'b0110111));               // lui
    emit(enc_i(val[11:0], rd, 3'b000, rd, 7'b0010011));   // addi
  endtask
 
  task automatic emit_lw(input logic [4:0] rd, input logic [4:0] rs1, input logic [11:0] imm);
    emit(enc_i(imm, rs1, 3'b010, rd, 7'b0000011));
  endtask
 
  task automatic emit_sw(input logic [4:0] rs2, input logic [4:0] rs1, input logic [11:0] imm);
    emit(enc_s(imm, rs2, rs1, 3'b010));
  endtask
 
  task automatic emit_sh(input logic [4:0] rs2, input logic [4:0] rs1, input logic [11:0] imm);
    emit(enc_s(imm, rs2, rs1, 3'b001));
  endtask
 
  task automatic emit_sb(input logic [4:0] rs2, input logic [4:0] rs1, input logic [11:0] imm);
    emit(enc_s(imm, rs2, rs1, 3'b000));
  endtask
 
  // Store register `rs` into the next result slot and register the expectation
  task automatic emit_record(input logic [4:0]  rs,
                             input string       name,
                             input logic [31:0] exp,
                             input logic [31:0] mask = '1);
    emit_sw(rs, XPTR, 12'h000);
    emit(enc_i(12'd4, XPTR, 3'b000, XPTR, 7'b0010011));   // addi ptr, ptr, 4
    exp_q.push_back(exp);
    mask_q.push_back(mask);
    name_q.push_back(name);
  endtask
 
  // ---- Program-level helpers (equivalents of bus_write / run_mult) ---------
  task automatic emit_reg_write(input logic [11:0] off, input logic [31:0] data);
    emit_li(XTMP, data);
    emit_sw(XTMP, XBASE, off);
  endtask
 
  task automatic emit_reg_read_record(input logic [11:0] off,
                                      input string       name,
                                      input logic [31:0] exp,
                                      input logic [31:0] mask = '1);
    emit_lw(XRES, XBASE, off);
    emit_record(XRES, name, exp, mask);
  endtask
 
  task automatic emit_mult(input logic [3:0]      op,
                           input logic [XLEN-1:0] a,
                           input logic [XLEN-1:0] b,
                           input logic [XLEN-1:0] exp);
    logic [31:0] ctrl;
    string       nm;
 
    emit_reg_write(REG_OP_A, a);
    emit_reg_write(REG_OP_B, b);
 
    ctrl           = 32'h0;
    ctrl[0]        = 1'b1;          // start
    ctrl[4:1]      = op;
    ctrl[4+ID_W:5] = 4'hA;          // transaction ID
    emit_reg_write(REG_CTRL, ctrl);
 
    // poll STATUS.done with a software timeout
    emit_li(XCNT, POLL_LIMIT);
    emit_lw(XSTAT, XBASE, REG_STATUS);                    // L:
    emit(enc_i(12'd1, XSTAT, 3'b111, XSTAT, 7'b0010011)); //    andi stat, stat, 1
    emit(enc_b(12, X0, XSTAT, 3'b001));                   //    bne  stat, x0, +12 (-> after loop)
    emit(enc_i(-12'sd1, XCNT, 3'b000, XCNT, 7'b0010011)); //    addi cnt, cnt, -1
    emit(enc_b(-16, X0, XCNT, 3'b001));                   //    bne  cnt, x0, L
    // stat==1 on success, 0 on timeout
 
    nm = $sformatf("op=%0d a=0x%08h b=0x%08h STATUS.done (0 = TIMEOUT)", op, a, b);
    emit_record(XSTAT, nm, 32'h1, 32'h1);
 
    emit_lw(XRES, XBASE, REG_RES_LO);
    nm = $sformatf("op=%0d a=0x%08h b=0x%08h", op, a, b);
    emit_record(XRES, nm, exp);
  endtask
 
  // ---- Build the whole test program ----------------------------------------
  task automatic build_program();
    int unsigned seed;
    logic [XLEN-1:0] a, b;
    logic [3:0]      op;
 
    if ($value$plusargs("seed=%d", seed)) begin
      void'($urandom(seed));
      $display("[TB] random seed = %0d", seed);
    end
 
    for (int i = 0; i < MEM_WORDS; i++) mem[i] = 32'h0000_0013;   // NOP fill
 
    // prologue
    emit_li(XBASE, CLMUL_BASE);
    emit_li(XPTR,  RES_BASE);
 
    // ---- TEST 1: register read/write ----
    emit_reg_write(REG_OP_A, 32'hDEAD_BEEF);
    emit_reg_read_record(REG_OP_A, "T1 OP_A readback", 32'hDEAD_BEEF);
 
    emit_reg_write(REG_OP_B, 32'hCAFE_F00D);
    emit_reg_read_record(REG_OP_B, "T1 OP_B readback", 32'hCAFE_F00D);
 
    emit_reg_read_record(REG_STATUS, "T1 STATUS idle", 32'h0, 32'h3);
 
    // ---- TEST 1b: byte strobes (generated by sh / sb) ----
    emit_reg_write(REG_OP_A, 32'hFFFF_FFFF);
    emit_li(XTMP, 32'h0000_3344);
    emit_sh(XTMP, XBASE, REG_OP_A);                       // strobe 0011
    emit_reg_read_record(REG_OP_A, "T1b OP_A strobe 0011 (sh)", 32'hFFFF_3344);
 
    emit_li(XTMP, 32'h0000_00AA);
    emit_sb(XTMP, XBASE, REG_OP_A + 12'd3);               // strobe 1000
    emit_reg_read_record(REG_OP_A, "T1b OP_A strobe 1000 (sb)", 32'hAAFF_3344);
    // NOTE: strobe 0000 cannot be produced by a load/store instruction.
 
    // ---- TEST 2: directed multiplications ----
    emit_mult(OP_MUL,    32'd6,         32'd7,         32'd42);
    emit_mult(OP_MUL,    32'hFFFF_FFFF, 32'hFFFF_FFFF, 32'h0000_0001);
    emit_mult(OP_MULH,   32'hFFFF_FFFF, 32'h0000_0002, 32'hFFFF_FFFF);
    emit_mult(OP_MULHU,  32'hFFFF_FFFF, 32'hFFFF_FFFF, 32'hFFFF_FFFE);
    emit_mult(OP_MULHSU, 32'hFFFF_FC18, 32'h0000_03E8, 32'hFFFF_FFFF);
    emit_mult(OP_MULW,   32'h7FFF_FFFF, 32'h0000_0002, 32'hFFFF_FFFE);
 
    // ---- TEST 3: CLMUL family ----
    emit_mult(OP_CLMUL,  32'h0000_0003, 32'h0000_0005, 32'h0000_000F);
    emit_mult(OP_CLMUL,  32'hFFFF_FFFF, 32'hFFFF_FFFF, 32'h5555_5555);
    emit_mult(OP_CLMULH, 32'hFFFF_FFFF, 32'hFFFF_FFFF, 32'h5555_5555);
    emit_mult(OP_CLMULR, 32'hFFFF_FFFF, 32'hFFFF_FFFF, 32'hAAAA_AAAA);
    emit_mult(OP_CLMUL,  32'hDEAD_BEEF, 32'hCAFE_F00D, ref_mul(OP_CLMUL,  32'hDEAD_BEEF, 32'hCAFE_F00D));
    emit_mult(OP_CLMULH, 32'hDEAD_BEEF, 32'hCAFE_F00D, ref_mul(OP_CLMULH, 32'hDEAD_BEEF, 32'hCAFE_F00D));
    emit_mult(OP_CLMULR, 32'hDEAD_BEEF, 32'hCAFE_F00D, ref_mul(OP_CLMULR, 32'hDEAD_BEEF, 32'hCAFE_F00D));
 
    // ---- TEST 4: randomized regression ----
    for (int i = 0; i < N_RANDOM; i++) begin
      a  = $urandom;
      b  = $urandom;
      op = 4'($urandom_range(0, 7));
      emit_mult(op, a, b, ref_mul(op, a, b));
    end
 
    // ---- TEST 5: back-to-back reads (consecutive loads) ----
    emit_reg_write(REG_OP_A, 32'h1234_5678);
    emit_reg_write(REG_OP_B, 32'h9ABC_DEF0);
    emit_lw(XRES,  XBASE, REG_OP_A);           // two loads with no gap; the CPU/AXI
    emit_lw(XRES2, XBASE, REG_OP_B);           // fabric decide how tightly they issue
    emit_record(XRES,  "T5 back-to-back OP_A", 32'h1234_5678);
    emit_record(XRES2, "T5 back-to-back OP_B", 32'h9ABC_DEF0);
 
    // epilogue: signal completion, then spin
    emit_li(XTMP, DONE_MAGIC);
    emit_li(XCNT, DONE_ADDR);
    emit_sw(XTMP, XCNT, 12'h000);
    emit(32'h0000_006F);                       // jal x0, 0  (infinite loop)
 
    $display("[TB] program: %0d instructions, %0d checks queued", pc_w, exp_q.size());
  endtask
 
  initial begin
    build_program();         // completes at time 0
    #1ns;
    load_program();          // overwrite RAM after any time-0 init, before reset ends
  end
 
  // ---- Main -----------------------------------------------------------------
  initial begin
    wait (reset_n);
    $display("[TB] reset released, CPU running");
 
    wait (done_seen);
    repeat (5) @(posedge clock);
    $display("[TB] CPU signalled DONE, checking %0d results", exp_q.size());
 
    for (int i = 0; i < exp_q.size(); i++)
      check(name_q[i], dbg_read((RES_BASE - MEM_BASE) / 4 + i), exp_q[i], mask_q[i]);
 
    $display("\n=============================================");
    $display("  TESTS RUN : %0d", tests_run);
    $display("  ERRORS    : %0d", errors);
    if (errors == 0) $display("  *** TEST PASSED ***");
    else             $display("  *** TEST FAILED ***");
    $display("=============================================\n");
    $finish;
  end
 
  // Watchdog (CPU hangs / never reaches DONE)
  initial begin
    #(CLK_PERIOD * TIMEOUT_CYCLES);
    errors++;
    $error("[WATCHDOG] simulation timeout - CPU never wrote DONE");
    $display("  *** TEST FAILED (timeout) ***");
    $finish;
  end
 
  // VCD dump
  initial begin
    if ($test$plusargs("dump")) begin
      $dumpfile("tb_top_pad_rvx.vcd");
      $dumpvars(0, tb_top_pad_rvx);
    end
  end
 
endmodule


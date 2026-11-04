//-----------------------------------------------------------------------------
// rvx_clmul.v
// Register-interface wrapper + multiplier / CLMUL unit, consolidated into a
// single Verilog-2001 module.
//
// Bus protocol (single-cycle request, single-cycle response, no backpressure):
//   Write: assert write_request with rw_address / write_data / write_strobe for
//          one cycle. write_response pulses high in the following cycle.
//   Read:  assert read_request with rw_address for one cycle. read_data is
//          valid and read_response pulses high in the following cycle.
//
// Register map (byte addresses):
//   0x00 CTRL       RW  [0]=start (write-only pulse), [4:1]=op, [4+ID_W:5]=trans_id
//   0x04 STATUS     RO  [0]=done (sticky), [1]=busy
//   0x08 OP_A       RW  operand A (low XLEN bits, max 32 accessible)
//   0x0C OP_B       RW  operand B (low XLEN bits, max 32 accessible)
//   0x10 RES_LO     RO  result low bits
//   0x14 RES_HI     RO  mirror of result (debug)
//
// Operations (CTRL[4:1]):
//   0 MUL   1 MULH   2 MULHU   3 MULHSU   4 MULW
//   5 CLMUL 6 CLMULH 7 CLMULR
//-----------------------------------------------------------------------------
`timescale 1ns/1ps
 
module rvx_clmul #(
    parameter integer XLEN = 32,
    parameter integer ID_W = 4,
    parameter         RVB  = 1'b1        // enable bitmanip (CLMUL family)
) (
    // Global signals
    input  wire        clock,
    input  wire        reset_n,
 
    // IO interface
    input  wire [ 4:0] rw_address,
    output reg  [31:0] read_data,
    input  wire        read_request,
    output reg         read_response,
    input  wire [31:0] write_data,
    input  wire [ 3:0] write_strobe,
    input  wire        write_request,
    output reg         write_response
);
 
  localparam integer DATA_W = 32;
  // Number of operand bits reachable over the 32-bit bus
  localparam integer LOW_W  = (XLEN < DATA_W) ? XLEN : DATA_W;
 
  // ---- Elaboration check (Verilog-2001 has no $error) ----------------------
  generate
    if ((ID_W + 5) > DATA_W) begin : g_chk_idw
      // synthesis translate_off
      initial begin
        $display("rvx_clmul: CTRL fields (ID_W+5 bits) do not fit in 32-bit data");
        $finish;
      end
      // synthesis translate_on
    end
  endgenerate
 
  // ---- Register offsets ----------------------------------------------------
  localparam [4:0] REG_CTRL   = 5'h00;
  localparam [4:0] REG_STATUS = 5'h04;
  localparam [4:0] REG_OP_A   = 5'h08;
  localparam [4:0] REG_OP_B   = 5'h0C;
  localparam [4:0] REG_RES_LO = 5'h10;
  localparam [4:0] REG_RES_HI = 5'h14;
 
  // ---- Operation encoding --------------------------------------------------
  localparam [3:0] OP_MUL     = 4'd0;
  localparam [3:0] OP_MULH    = 4'd1;
  localparam [3:0] OP_MULHU   = 4'd2;
  localparam [3:0] OP_MULHSU  = 4'd3;
  localparam [3:0] OP_MULW    = 4'd4;
  localparam [3:0] OP_CLMUL   = 4'd5;
  localparam [3:0] OP_CLMULH  = 4'd6;
  localparam [3:0] OP_CLMULR  = 4'd7;
 
  // ---- Register file state -------------------------------------------------
  reg                ctrl_start_q;
  reg  [3:0]         ctrl_op_q;
  reg  [ID_W-1:0]    ctrl_id_q;
  reg  [XLEN-1:0]    op_a_q, op_b_q;
  reg                status_done_q, status_busy_q;
  reg  [XLEN-1:0]    result_lo_q, result_hi_q;
 
  // Byte-strobe merge helper.
  function automatic [DATA_W-1:0] apply_strb;
    input [DATA_W-1:0]   old_val;
    input [DATA_W-1:0]   new_val;
    input [DATA_W/8-1:0] strb;
    integer b;
    begin
      for (b = 0; b < DATA_W/8; b = b + 1)
        apply_strb[b*8 +: 8] = strb[b] ? new_val[b*8 +: 8] : old_val[b*8 +: 8];
    end
  endfunction
 
  // ---- Write decode --------------------------------------------------------
  // Every register merges new bytes into its current value so a partial write
  // does not clobber unrelated fields.
  wire [DATA_W-1:0] ctrl_cur    = {ctrl_id_q, ctrl_op_q, 1'b0};   // zero-extended
  wire [DATA_W-1:0] op_a_cur    = op_a_q;                         // zero-ext / trunc
  wire [DATA_W-1:0] op_b_cur    = op_b_q;
 
  wire [DATA_W-1:0] ctrl_wr_val = apply_strb(ctrl_cur, write_data, write_strobe);
  wire [DATA_W-1:0] op_a_wr     = apply_strb(op_a_cur, write_data, write_strobe);
  wire [DATA_W-1:0] op_b_wr     = apply_strb(op_b_cur, write_data, write_strobe);
 
  wire ctrl_wr_en = write_request && (rw_address == REG_CTRL);
  wire op_a_wr_en = write_request && (rw_address == REG_OP_A);
  wire op_b_wr_en = write_request && (rw_address == REG_OP_B);
  wire start_req  = ctrl_wr_en & ctrl_wr_val[0];   // start requested by this write
 
  always @(posedge clock or negedge reset_n) begin
    if (!reset_n) begin
      ctrl_start_q <= 1'b0;
      ctrl_op_q    <= 4'd0;
      ctrl_id_q    <= {ID_W{1'b0}};
    end else begin
      ctrl_start_q <= 1'b0;                 // self-clearing pulse
      if (ctrl_wr_en) begin
        ctrl_start_q <= ctrl_wr_val[0];
        ctrl_op_q    <= ctrl_wr_val[4:1];
        ctrl_id_q    <= ctrl_wr_val[4+ID_W:5];
      end
    end
  end
 
  always @(posedge clock or negedge reset_n) begin
    if (!reset_n) begin
      op_a_q <= {XLEN{1'b0}};
      op_b_q <= {XLEN{1'b0}};
    end else begin
      // Only the bits reachable over the 32-bit bus are written; any upper
      // bits (XLEN > 32) are left untouched.
      if (op_a_wr_en) op_a_q[LOW_W-1:0] <= op_a_wr[LOW_W-1:0];
      if (op_b_wr_en) op_b_q[LOW_W-1:0] <= op_b_wr[LOW_W-1:0];
    end
  end
 
  // ---- Write response: one cycle after the request -------------------------
  always @(posedge clock or negedge reset_n) begin
    if (!reset_n) write_response <= 1'b0;
    else          write_response <= write_request;
  end
 
  //===========================================================================
  // Multiplier core (formerly the separate `multiplier` module)
  // Inputs : ctrl_start_q, ctrl_op_q, op_a_q, op_b_q
  // Outputs: mult_result (combinational from operator_q), mult_valid
  //===========================================================================
 
  // ---- Carry-less multiply -------------------------------------------------
  wire clmul_rmode = RVB && (ctrl_op_q == OP_CLMULR);
  wire clmul_hmode = RVB && (ctrl_op_q == OP_CLMULH);
  wire clmul_rev   = clmul_rmode | clmul_hmode;
 
  reg  [XLEN-1:0] op_a_rev, op_b_rev;
  reg  [XLEN-1:0] clmul_d, clmulr_d;
  reg  [XLEN-1:0] clmul_q, clmulr_q;
  integer         i;
 
  always @* begin
    for (i = 0; i < XLEN; i = i + 1) begin
      op_a_rev[i] = op_a_q[(XLEN-1)-i];
      op_b_rev[i] = op_b_q[(XLEN-1)-i];
    end
  end
 
  wire [XLEN-1:0] clmul_a = clmul_rev ? op_a_rev : op_a_q;
  wire [XLEN-1:0] clmul_b = clmul_rev ? op_b_rev : op_b_q;
 
  integer k;
  always @* begin
    clmul_d = {XLEN{1'b0}};
    if (RVB) begin
      for (k = 0; k < XLEN; k = k + 1) begin
        if (clmul_b[k])
          clmul_d = clmul_d ^ (clmul_a << k);
      end
    end
  end
 
  integer m;
  always @* begin
    for (m = 0; m < XLEN; m = m + 1)
      clmulr_d[m] = clmul_d[(XLEN-1)-m];
  end
 
  always @(posedge clock or negedge reset_n) begin
    if (!reset_n) begin
      clmul_q  <= {XLEN{1'b0}};
      clmulr_q <= {XLEN{1'b0}};
    end else begin
      clmul_q  <= clmul_d;
      clmulr_q <= clmulr_d;
    end
  end
 
  // ---- Sign selection ------------------------------------------------------
  wire sign_a = (ctrl_op_q == OP_MULH) | (ctrl_op_q == OP_MULHSU);
  wire sign_b = (ctrl_op_q == OP_MULH);
 
  // ---- Multiply ------------------------------------------------------------
  wire signed [XLEN:0]     mul_a_s = {op_a_q[XLEN-1] & sign_a, op_a_q};
  wire signed [XLEN:0]     mul_b_s = {op_b_q[XLEN-1] & sign_b, op_b_q};
  wire signed [2*XLEN-1:0] mult_result_d = mul_a_s * mul_b_s;
 
  // ---- Output pipeline -----------------------------------------------------
  // Accept the start pulse only for defined operations (0..7).
  wire mult_start = ctrl_start_q && (ctrl_op_q <= OP_CLMULR);
 
  reg                 mult_valid_q;
  reg  [3:0]          operator_q;
  reg  [2*XLEN-1:0]   mult_result_q;
 
  always @(posedge clock or negedge reset_n) begin
    if (!reset_n) begin
      mult_valid_q  <= 1'b0;
      operator_q    <= OP_MUL;
      mult_result_q <= {2*XLEN{1'b0}};
    end else begin
      mult_valid_q  <= mult_start;
      operator_q    <= ctrl_op_q;
      mult_result_q <= mult_result_d;
    end
  end
 
  wire mult_valid = mult_valid_q;
 
  // ---- Result mux ----------------------------------------------------------
  reg [XLEN-1:0] mult_result;
 
  always @* begin
    case (operator_q)
      OP_MULH,
      OP_MULHU,
      OP_MULHSU: mult_result = mult_result_q[2*XLEN-1:XLEN];
      OP_CLMUL:  mult_result = clmul_q;
      OP_CLMULH: mult_result = clmulr_q >> 1;
      OP_CLMULR: mult_result = clmulr_q;
      default: begin
        if (operator_q == OP_MULW && XLEN == 64)
          // Sign-extend the low 32 bits (over-wide replicate is truncated to XLEN)
          mult_result = {{XLEN{mult_result_q[31]}}, mult_result_q[31:0]};
        else
          mult_result = mult_result_q[XLEN-1:0];
      end
    endcase
  end
 
  //===========================================================================
  // Status / result capture
  //===========================================================================
  // busy/done are updated from start_req (the CTRL write itself) rather than
  // the delayed ctrl_start_q pulse, so they are already correct by the time
  // write_response is visible. Priority: a fresh start wins over a same-cycle
  // valid.
  always @(posedge clock or negedge reset_n) begin
    if (!reset_n) begin
      status_done_q <= 1'b0;
      status_busy_q <= 1'b0;
      result_lo_q   <= {XLEN{1'b0}};
      result_hi_q   <= {XLEN{1'b0}};
    end else begin
      if (start_req)         status_done_q <= 1'b0;
      else if (mult_valid)   status_done_q <= 1'b1;
 
      if (start_req)         status_busy_q <= 1'b1;
      else if (mult_valid)   status_busy_q <= 1'b0;
 
      if (mult_valid) begin
        result_lo_q <= mult_result;
        result_hi_q <= mult_result;
      end
    end
  end
 
  // ---- Read path: register data, respond one cycle after the request -------
  reg [DATA_W-1:0] rdata_mux;
 
  always @* begin
    case (rw_address)
      REG_CTRL:   rdata_mux = {ctrl_id_q, ctrl_op_q, 1'b0};
      REG_STATUS: rdata_mux = {status_busy_q, status_done_q};
      REG_OP_A:   rdata_mux = op_a_q;
      REG_OP_B:   rdata_mux = op_b_q;
      REG_RES_LO: rdata_mux = result_lo_q;
      REG_RES_HI: rdata_mux = result_hi_q;
      default:    rdata_mux = {DATA_W{1'b0}};
    endcase
  end
 
  always @(posedge clock or negedge reset_n) begin
    if (!reset_n) begin
      read_response <= 1'b0;
      read_data     <= {DATA_W{1'b0}};
    end else begin
      read_response <= read_request;
      if (read_request) read_data <= rdata_mux;
    end
  end
 
endmodule


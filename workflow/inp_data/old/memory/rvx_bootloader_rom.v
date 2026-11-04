// SPDX-License-Identifier: MIT
// Copyright (c) 2020-2026 RVX Project Contributors

// RVX Bootloader Read-Only Memory (ROM) Module
module rvx_bootloader_rom #(

    // Size of the memory in bytes
    parameter SIZE_IN_BYTES = 2048

) (

    // Global signals
    input wire clock,
    input wire reset_n,

    // Read-only port
    input  wire [31:0] address,
    output reg  [31:0] rdata,
    input  wire        rrequest,
    output reg         rresponse

);

  wire [31:0] rom [0:SIZE_IN_BYTES/4-1];

  assign rom[0]   = 32'h7C0026F3;
  assign rom[1]   = 32'h40003737;
  assign rom[2]   = 32'h00072223;
  assign rom[3]   = 32'h00300793;
  assign rom[4]   = 32'h00F72623;
  assign rom[5]   = 32'h0106D593;
  assign rom[6]   = 32'h0086D613;
  assign rom[7]   = 32'h01472783;
  assign rom[8]   = 32'h0017F793;
  assign rom[9]   = 32'hFE079CE3;
  assign rom[10]  = 32'h0FF5F793;
  assign rom[11]  = 32'h00F72623;
  assign rom[12]  = 32'h40003737;
  assign rom[13]  = 32'h01472783;
  assign rom[14]  = 32'h0017F793;
  assign rom[15]  = 32'hFE079CE3;
  assign rom[16]  = 32'h0FF67793;
  assign rom[17]  = 32'h00F72623;
  assign rom[18]  = 32'h40003737;
  assign rom[19]  = 32'h01472783;
  assign rom[20]  = 32'h0017F793;
  assign rom[21]  = 32'hFE079CE3;
  assign rom[22]  = 32'h0FF6F693;
  assign rom[23]  = 32'h00D72623;
  assign rom[24]  = 32'h400037B7;
  assign rom[25]  = 32'h0147A583;
  assign rom[26]  = 32'h0015F593;
  assign rom[27]  = 32'hFE059CE3;
  assign rom[28]  = 32'h00000613;
  assign rom[29]  = 32'h400037B7;
  assign rom[30]  = 32'h02000513;
  assign rom[31]  = 32'h0007A623;
  assign rom[32]  = 32'h0147A683;
  assign rom[33]  = 32'h0016F693;
  assign rom[34]  = 32'hFE069CE3;
  assign rom[35]  = 32'h0107A703;
  assign rom[36]  = 32'h0FF77713;
  assign rom[37]  = 32'h00C71733;
  assign rom[38]  = 32'h00860613;
  assign rom[39]  = 32'h00E5E5B3;
  assign rom[40]  = 32'hFCA61EE3;
  assign rom[41]  = 32'h00000513;
  assign rom[42]  = 32'h400037B7;
  assign rom[43]  = 32'h02000813;
  assign rom[44]  = 32'h0007A623;
  assign rom[45]  = 32'h0147A603;
  assign rom[46]  = 32'h00167613;
  assign rom[47]  = 32'hFE061CE3;
  assign rom[48]  = 32'h0107A703;
  assign rom[49]  = 32'h0FF77713;
  assign rom[50]  = 32'h00A71733;
  assign rom[51]  = 32'h00850513;
  assign rom[52]  = 32'h00E6E6B3;
  assign rom[53]  = 32'hFD051EE3;
  assign rom[54]  = 32'h00000813;
  assign rom[55]  = 32'h40003737;
  assign rom[56]  = 32'h02000893;
  assign rom[57]  = 32'h00072623;
  assign rom[58]  = 32'h01472783;
  assign rom[59]  = 32'h0017F793;
  assign rom[60]  = 32'hFE079CE3;
  assign rom[61]  = 32'h01072503;
  assign rom[62]  = 32'h0FF57513;
  assign rom[63]  = 32'h01051533;
  assign rom[64]  = 32'h00880813;
  assign rom[65]  = 32'h00A66633;
  assign rom[66]  = 32'hFD181EE3;
  assign rom[67]  = 32'h00000813;
  assign rom[68]  = 32'h40003537;
  assign rom[69]  = 32'h02000893;
  assign rom[70]  = 32'h00052623;
  assign rom[71]  = 32'h01452703;
  assign rom[72]  = 32'h00177713;
  assign rom[73]  = 32'hFE071CE3;
  assign rom[74]  = 32'h01052703;
  assign rom[75]  = 32'h0FF77713;
  assign rom[76]  = 32'h01071733;
  assign rom[77]  = 32'h00880813;
  assign rom[78]  = 32'h00E7E7B3;
  assign rom[79]  = 32'hFD181EE3;
  assign rom[80]  = 32'hADA9D737;
  assign rom[81]  = 32'hCCE70713;
  assign rom[82]  = 32'h00E585B3;
  assign rom[83]  = 32'h08059C63;
  assign rom[84]  = 32'hADA9A737;
  assign rom[85]  = 32'h7CC70713;
  assign rom[86]  = 32'h00E787B3;
  assign rom[87]  = 32'h525635B7;
  assign rom[88]  = 32'h52566737;
  assign rom[89]  = 32'h83470713;
  assign rom[90]  = 32'h33258593;
  assign rom[91]  = 32'h06079C63;
  assign rom[92]  = 32'h00001337;
  assign rom[93]  = 32'h00B32023;
  assign rom[94]  = 32'h00D32223;
  assign rom[95]  = 32'h00C32423;
  assign rom[96]  = 32'h00E32623;
  assign rom[97]  = 32'h01000813;
  assign rom[98]  = 32'h40003737;
  assign rom[99]  = 32'h02000893;
  assign rom[100] = 32'h04D87263;
  assign rom[101] = 32'h00000593;
  assign rom[102] = 32'h00000513;
  assign rom[103] = 32'h00072623;
  assign rom[104] = 32'h01472783;
  assign rom[105] = 32'h0017F793;
  assign rom[106] = 32'hFE079CE3;
  assign rom[107] = 32'h01072783;
  assign rom[108] = 32'h0FF7F793;
  assign rom[109] = 32'h00B797B3;
  assign rom[110] = 32'h00858593;
  assign rom[111] = 32'h00F56533;
  assign rom[112] = 32'hFD159EE3;
  assign rom[113] = 32'h010307B3;
  assign rom[114] = 32'h00A7A023;
  assign rom[115] = 32'h00480813;
  assign rom[116] = 32'hFCD862E3;
  assign rom[117] = 32'h400037B7;
  assign rom[118] = 32'h00100713;
  assign rom[119] = 32'h00E7A223;
  assign rom[120] = 32'h00060067;
  assign rom[121] = 32'h400037B7;
  assign rom[122] = 32'h00100713;
  assign rom[123] = 32'h00E7A223;
  assign rom[124] = 32'h000017B7;
  assign rom[125] = 32'h0007A583;
  assign rom[126] = 32'h00478693;
  assign rom[127] = 32'h00878613;
  assign rom[128] = 32'h00C78713;
  assign rom[129] = 32'hADA9D7B7;
  assign rom[130] = 32'h0006A683;
  assign rom[131] = 32'hCCE78793;
  assign rom[132] = 32'h00062603;
  assign rom[133] = 32'h00072703;
  assign rom[134] = 32'h00F587B3;
  assign rom[135] = 32'h02079663;
  assign rom[136] = 32'hADA9A7B7;
  assign rom[137] = 32'h7CC78793;
  assign rom[138] = 32'h00F707B3;
  assign rom[139] = 32'h00079E63;
  assign rom[140] = 32'h00060067;
  assign rom[141] = 32'h52566737;
  assign rom[142] = 32'h525635B7;
  assign rom[143] = 32'h83470713;
  assign rom[144] = 32'h33258593;
  assign rom[145] = 32'hF2DFF06F;
  assign rom[146] = 32'h5B90006F;
  assign rom[147] = 32'hF25FF06F;

  genvar i;
  generate
    for (i = 148; i < SIZE_IN_BYTES / 4; i = i + 1) begin : rom_pad
      assign rom[i] = 32'h00000000;
    end
  endgenerate


  // verilator lint_off UNUSEDSIGNAL
  wire [31:0] effective_address;
  // verilator lint_on UNUSEDSIGNAL

  wire        invalid_address;

  assign invalid_address = $unsigned(address) >= $unsigned(SIZE_IN_BYTES);
  assign effective_address = $unsigned(address[31:0] >> 2);

  always @(posedge clock) begin
    if (!reset_n | invalid_address) rdata <= 32'h00000000;
    else rdata <= rom[effective_address];
  end

  always @(posedge clock) begin
    if (!reset_n) rresponse <= 1'b0;
    else rresponse <= rrequest;
  end

endmodule

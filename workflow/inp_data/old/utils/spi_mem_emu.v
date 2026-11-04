module spi_mem_emu#(

    parameter SIZE_IN_BYTES = 8192,

    parameter INIT_FILE_PATH = "",
    parameter BASE_ADDRESS = 32'h00000000
    ) (
    input wire clk,      // SPI Serial Clock
    input wire cs_n,     // Chip Select (Active Low)
    input wire mosi,     // Master Out Slave In
    output reg miso      // Master In Slave Out
);

    reg [7:0] mem [BASE_ADDRESS : BASE_ADDRESS + SIZE_IN_BYTES - 1];

    // Internal tracking registers
    reg [2:0] bit_cnt;
    reg [7:0] shift_in;
    reg [7:0] cmd;
    reg [23:0] addr;         // Expanded to 24-bit addressing
    reg [1:0] addr_byte_cnt; // Tracks the 3 incoming address bytes
    reg [1:0] id_byte_cnt;   // Tracks JEDEC ID bytes (for 0x9F)

    // State machine parameters
    localparam STATE_CMD  = 2'b00;
    localparam STATE_ADDR = 2'b01;
    localparam STATE_DATA = 2'b10;
    reg [1:0] state;

    // Hardcoded JEDEC ID definition (for 0x9F command compliance)
    reg [7:0] jedec_id [0:2];

    integer i;
    initial begin
        // JEDEC Default IDs
        jedec_id[0] = 8'hEF; 
        jedec_id[1] = 8'h40; 
        jedec_id[2] = 8'h15;
        
        for (i = BASE_ADDRESS; i < BASE_ADDRESS + SIZE_IN_BYTES; i = i + 1) mem[i] = 8'h00;
        if (INIT_FILE_PATH != "") $readmemh(INIT_FILE_PATH, mem);
    end

    // --- Input Processing (Sample on Rising Edge) ---
    always @(posedge clk or posedge cs_n) begin
        if (cs_n) begin
            bit_cnt       <= 3'd0;
            state         <= STATE_CMD;
            cmd           <= 8'd0;
            addr          <= 24'd0;
            addr_byte_cnt <= 2'd0;
            id_byte_cnt   <= 2'd0;
            shift_in      <= 8'd0;
        end else begin
            shift_in <= {shift_in[6:0], mosi};
            bit_cnt  <= bit_cnt + 1'b1;

            case (state)
                STATE_CMD: begin
                    if (bit_cnt == 3'd7) begin
                        // Assigning cmd register safely
                        cmd <= {shift_in[6:0], mosi};
                        
                        // Inline check replaces the illegal wire declaration
                        if ({shift_in[6:0], mosi} == 8'h9F) begin
                            state <= STATE_DATA; 
                            id_byte_cnt <= 2'd0;
                        end else begin
                            state <= STATE_ADDR;
                            addr_byte_cnt <= 2'd0;
                        end
                    end
                end

                STATE_ADDR: begin
                    if (bit_cnt == 3'd7) begin
                        addr <= {addr[15:0], shift_in[6:0], mosi};
                        
                        if (addr_byte_cnt == 2'd2) begin
                            state <= STATE_DATA;
                        end else begin
                            addr_byte_cnt <= addr_byte_cnt + 1'b1;
                        end
                    end
                end

                STATE_DATA: begin
                    if (bit_cnt == 3'd7) begin
                        if (cmd == 8'h02) begin        // Page Write
                            mem[addr[11:0]] <= {shift_in[6:0], mosi}; 
                            addr <= addr + 1'b1;
                        end else if (cmd == 8'h03) begin // Read Data
                            addr <= addr + 1'b1;        
                        end else if (cmd == 8'h9F) begin // JEDEC Read
                            id_byte_cnt <= (id_byte_cnt == 2'd2) ? 2'd0 : id_byte_cnt + 1'b1;
                        end
                    end
                end
            endcase
        end
    end

    // --- Output Processing (Drive MISO on Falling Edge) ---
    always @(negedge clk or posedge cs_n) begin
        if (cs_n) begin
            miso <= 1'bz;
        end else begin
            if (state == STATE_DATA) begin
                if (cmd == 8'h03) begin
                    miso <= mem[addr[11:0]][3'd7 - bit_cnt];
                end else if (cmd == 8'h9F) begin
                    miso <= jedec_id[id_byte_cnt][3'd7 - bit_cnt];
                end else begin
                    miso <= 1'bz; 
                end
            end else begin
                miso <= 1'bz;
            end
        end
    end

endmodule
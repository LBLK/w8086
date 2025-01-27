// FIFO (First In First Out)
// Repo: https://github.com/openx86/w8086
// Author: cw1997 [changwei1006@gmail.com] & [https://changwei.me]
// Datetime: 2021-04-17 20:11:09

interface interface_FIFO #(
    WIDTH_DATA = 8,
    DEPTH = 8
);

    localparam WIDTH_ADDR = $clog2(DEPTH);

    logic                  clock;
    logic                  reset;
    logic                  read_enable;
    logic [WIDTH_DATA-1:0] read_data;
    logic                  write_enable;
    logic [WIDTH_DATA-1:0] write_data;
    logic                  is_empty;
    logic                  is_full;
    logic [WIDTH_ADDR-1:0] length;

    modport master (
        input clock, reset, read_enable, write_enable, write_data,
        output read_data, is_empty, is_full, length
    );
    modport slave (
        output read_enable, write_enable, write_data,
        input  clock, reset, read_data, is_empty, is_full, length
    );
endinterface: interface_FIFO

module FIFO #(
    WIDTH_DATA = 8,
    DEPTH = 8
) (
    interface_FIFO.master port
);

localparam WIDTH_ADDR = $clog2(DEPTH);

reg [WIDTH_ADDR-1:0] read_address, write_address;
reg [WIDTH_DATA-1:0] ram [0:DEPTH-1];
reg [WIDTH_ADDR-1:0] counter;

assign port.is_empty = ( counter == 0 );
assign port.is_full  = ( counter == (DEPTH - 1) );

assign port.length = 
(read_address < write_address) ? (write_address - read_address) : 
(read_address > write_address) ? (DEPTH - 1) - read_address + write_address : 
0;
// dont use 'always' block because some synthesizers will build latch for the logic below
// always_latch begin
//     if (read_address < write_address) begin
//         port.length <= write_address - read_address;
//     end else if (read_address > write_address) begin
//         port.length <= (DEPTH - 1) - read_address + write_address;
//     end else if (read_address == write_address) begin
//         port.length <= 0;
//     end
// end

always_ff @(posedge port.clock or posedge port.reset) begin

    if (port.reset) begin
        counter <= 0;
    end else begin
        case ({port.read_enable, port.write_enable})
            2'b10: begin // read
                counter <= counter - 1;
            end
            2'b01: begin // write
                counter <= counter + 1;
            end
            default: begin // idle
                counter <= counter;
            end
        endcase
    end

    if (port.reset) begin
        port.read_data <= 0;
        read_address <= 0;
    end else begin
        if (port.read_enable) begin
            port.read_data <= ram[read_address];
            read_address <= ( read_address == DEPTH - 1 ) ? 0 : (read_address + 1);
        end
    end

    if (port.reset) begin
        write_address <= 0;
    end else begin
        if (port.write_enable) begin
            ram[write_address] <= port.write_data;
            write_address <= ( write_address == DEPTH - 1 ) ? 0 : (write_address + 1);
        end
    end

end
    
endmodule

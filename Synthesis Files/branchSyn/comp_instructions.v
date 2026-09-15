module comp_instructions(
    input  [3:0]  opcode,
    input  [15:0] rs_data,  
    input  [15:0] rt_data,  
    input  [3:0]  immediate,
    output reg [15:0] result,
    output reg [2:0]  flag_out
);

    wire [15:0] add_result = rs_data + rt_data;
    wire [15:0] sub_result = rs_data - rt_data;

    // Overflow detection (signed)
    wire add_ovfl = (~rs_data[15] & ~rt_data[15] & add_result[15]) | (rs_data[15] & rt_data[15] & ~add_result[15]);
    wire sub_ovfl = (~rs_data[15] & rt_data[15] & sub_result[15]) | (rs_data[15] & ~rt_data[15] & ~sub_result[15]);

    // PADDSB (signed 4-bit add with saturation to [-4, 3])
    function [3:0] sat_add4;
        input [3:0] a, b;
        reg signed [4:0] sum;
        begin
            sum = $signed({a[3], a}) + $signed({b[3], b});
            if (sum > 3) sat_add4 = 4'sd3;
            else if (sum < -4) sat_add4 = -4'sd4;
            else sat_add4 = sum[3:0];
        end
    endfunction

    wire [15:0] paddsb_result = {
        sat_add4(rs_data[15:12], rt_data[15:12]),
        sat_add4(rs_data[11:8],  rt_data[11:8]),
        sat_add4(rs_data[7:4],   rt_data[7:4]),
        sat_add4(rs_data[3:0],   rt_data[3:0])
    };

    // RED (sum 8 nibbles and sign extend to 16 bits)
    wire signed [4:0] sum0 = $signed({1'b0, rs_data[15:12]}) + $signed({1'b0, rt_data[15:12]});
    wire signed [4:0] sum1 = $signed({1'b0, rs_data[11:8]})  + $signed({1'b0, rt_data[11:8]});
    wire signed [4:0] sum2 = $signed({1'b0, rs_data[7:4]})   + $signed({1'b0, rt_data[7:4]});
    wire signed [4:0] sum3 = $signed({1'b0, rs_data[3:0]})   + $signed({1'b0, rt_data[3:0]});
    wire signed [15:0] red_result = $signed(sum0 + sum1 + sum2 + sum3);

    // Logical shift left
    wire [15:0] sll_result = rs_data << immediate;

    // Arithmetic shift right
    wire [15:0] sra_result = $signed(rs_data) >>> immediate;

    // Rotate right (ROR)
    wire [15:0] ror_result = (rs_data >> immediate) | (rs_data << (16 - immediate));

    always @(*) begin
        flag_out = 3'b000;
        case (opcode)
            4'b0000: begin  // ADD
                result = add_ovfl ? (rs_data[15] ? 16'h8000 : 16'h7FFF) : add_result;
                flag_out = {result[15], result == 0, add_ovfl};
            end
            4'b0001: begin  // SUB
                result = sub_ovfl ? 16'h7FFF : sub_result;
                flag_out = {result[15], result == 0, sub_ovfl};
            end
            4'b0010: begin  // XOR
                result = rs_data ^ rt_data;
                flag_out = {1'b0, result == 0, 1'b0};
            end
            4'b0011: begin  // RED
                result = red_result;
                flag_out = {1'b0, result == 0, result[15]};
            end
            4'b0100: begin  // SLL
                result = sll_result;
                flag_out = {1'b0, result == 0, result[15]};
            end
            4'b0101: begin  // SRA
                result = sra_result;
                flag_out = {1'b0, result == 0, result[15]};
            end
            4'b0110: begin  // ROR
                result = ror_result;
                flag_out = {1'b0, result == 0, result[15]};
            end
            4'b0111: begin  // PADDSB
                result = paddsb_result;
                flag_out = {1'b0, result == 0, result[15]};
            end
            default: begin
                result = 16'h0000;
                flag_out = 3'b000;
            end
        endcase
    end
endmodule

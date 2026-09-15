//process compute instructions
// ADD, SUB, XOR, RED, SLL, SRA, ROR, PADDSB
module comp_instructions( opcode, //opcodes 0000-0111
    rs_data,  
    rt_data,  
    immediate,
    result,
    flag_out  //V, Z, N Overflow, Zero, Negative
);

    input  [3:0]  opcode;
    input  [15:0] rs_data;  
    input  [15:0] rt_data;  
    input  [3:0]  immediate;
    output reg [15:0] result;
    output reg [2:0]  flag_out;
    // addsub for ADD and SUB (can use same one to reduce area, but for testing purposes create 2 copies)
    wire [15:0] add_result, sub_result;
    wire add_ovfl, sub_ovfl;
    
    addsub16bit iADD1 (
        .A(rs_data),
        .B(rt_data),
        .sub(1'b0),
        .Sum(add_result),
        .Ovfl(add_ovfl)
    );
    
    addsub16bit iSUB1 (
        .A(rs_data),
        .B(rt_data),
        .sub(1'b1),
        .Sum(sub_result),
        .Ovfl(sub_ovfl)
    );
    
    //red and paddsb modules
    wire [15:0] paddsb_result;
    padDSB pad_inst (
        .result(paddsb_result),
        .rs(rs_data),
        .rt(rt_data)
    );
    
    wire [15:0] red_result;
    red red_inst (
        .rd(red_result),
        .rs(rs_data),
        .rt(rt_data)
    );


    //SLR/SRA/ROR shifter modules
    wire [15:0] shift_result;
    wire shift_mode;
    assign shift_mode = (opcode == 4'b0101);  //1 for SRA 0 for SLL otherwise output not used
    Shifter shift_inst(
        .Shift_Out(shift_result),
        .Shift_In(rs_data),
        .Shift_Val(immediate),
        .Mode(shift_mode)
    );
    

    wire [15:0] ror_result;
    wire err;
    ror16bit iROR1 (
        .out(ror_result),
        .in(rs_data),
        .shift(immediate),
        .err(err)
    );
    
    //assign data and flag datapaths from opcode
    always @(*) begin
        
        flag_out = 3'b000;
        casex (opcode)
            4'b000?: begin  // ADD/SUB 
                result = (opcode[0] == 1'b0) ?
                    (add_ovfl ? ((add_result[15] == 1'b0) ? 16'h7FFF : 16'h8000) : add_result) :
                    (sub_ovfl ? 16'h7FFF : sub_result);
                    
                flag_out[1] = (result == 16'b0);  //zero flag
                flag_out[2] = result[15];         //negative flag
                flag_out[0] = (opcode[0] == 1'b1) ? sub_ovfl : add_ovfl; //overflow flag
            end

            4'b0010: begin  // XOR
                result = rs_data ^ rt_data;
                flag_out[1] = (result == 16'b0);
                flag_out[2] = result[15];
                flag_out[0] = 1'b0;
            end
            4'b0011: begin  // RED
                result = red_result;
                flag_out[1] = (result == 16'b0);
                flag_out[2] = result[15];
                flag_out[0] = 1'b0;
            end
            4'b010?: begin  // SLL/SRA
                result = shift_result;
                flag_out[1] = (result == 16'b0);
                flag_out[2] = result[15];
                flag_out[0] = 1'b0;
            end
        
            4'b0110: begin  // ROR
                result = ror_result;
                flag_out[1] = (result == 16'b0);
                flag_out[2] = result[15];
                flag_out[0] = 1'b0;
            end
            4'b0111: begin  // PADDSB
                result = paddsb_result;
                flag_out[1] = (result == 16'b0);
                flag_out[2] = result[15];
                flag_out[0] = 1'b0;
            end
            default: begin //dont care case output
                result = 16'b0;
                flag_out = 3'b000;
            end
        endcase
    end
endmodule

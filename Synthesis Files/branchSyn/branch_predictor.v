module branch_predictor (
    input clk,
    input rst_n,
    input [15:0] PC,
    input update,
    input actual_taken,
    output predicted_taken
);

    reg [1:0] bp_table [0:63];
    wire [5:0] index = PC[7:2];

    assign predicted_taken = (bp_table[index] >= 2'b10);

    integer i;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < 64; i = i + 1)
                bp_table[i] <= 2'b01;
        end else if (update) begin
            case ({actual_taken, bp_table[index]})
                3'b100: bp_table[index] <= 2'b01;
                3'b101: bp_table[index] <= 2'b10;
                3'b110: bp_table[index] <= 2'b11;
                3'b111: bp_table[index] <= 2'b11;
                3'b000: bp_table[index] <= 2'b00;
                3'b001: bp_table[index] <= 2'b00;
                3'b010: bp_table[index] <= 2'b01;
                3'b011: bp_table[index] <= 2'b10;
            endcase
        end
    end

endmodule

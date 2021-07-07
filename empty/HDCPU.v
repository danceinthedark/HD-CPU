module HDCPU(
    input CLR,
    input T3,
    input C,
    input Z,
    input[2:0] SW,
    input [7:4] IR,
    input [3:1] W,
    output reg LDC,
    output reg LDZ,
    output reg CIN,
    output reg [3:0] S,
    output reg [3:0] SEL,
    output reg M,
    output reg ABUS,
    output reg DRW,
    output reg PCINC,
    output reg LPC,
    output reg LAR,
    output reg PCADD,
    output reg ARINC,
    output reg SELCTL,
    output reg MEMW,
    output reg STOP,
    output reg LIR,
    output reg SBUS,
    output reg MBUS,
    output reg SHORT,
    output reg LONG,
    output reg[3:0] count,
    output reg [3:0] x
    );

    reg [2:0] flag;
	
    always @(T3)
    begin
		case(count)
			3'b001:begin
				count = count + 2;
				x = count;
			end
			3'b000:
			begin
				count = count + 1;
				x = count;
				end
		endcase
    end
endmodule
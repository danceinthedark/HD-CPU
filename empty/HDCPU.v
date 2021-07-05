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
    output reg LONG
    );

    reg [2:0] flag;

    always @(flag,W)
    begin
        flag = 0;
        ABUS = 0;
        CIN = 0;
        PCINC = 0;
        case (SW)
            3'b001: begin
                {M,S,CIN,LDC,LDZ}=0;
                {M,S,CIN,LDC,LDZ}=~{M,S,CIN,LDC,LDZ};
                if(W[1])begin
                if(ABUS==0) ABUS = 1;
                //else ABUS = 0;
                end
            end
            3'b010: begin
                {LIR,STOP,MEMW,LAR,ARINC,LPC,PCINC,DRW} = 0;
                {LIR,STOP,MEMW,LAR,ARINC,LPC,PCINC,DRW}=~{LIR,STOP,MEMW,LAR,ARINC,LPC,PCINC,DRW};
            end
            3'b100: begin
                SEL=4'b1111;
            end
            default:
                begin
                    {LDC, LDZ, CIN, M, ABUS, DRW, PCINC, LPC, LAR, PCADD, ARINC, SELCTL, MEMW, STOP, LIR, SBUS, MBUS, SHORT, LONG, S, SEL}=0;
                end
        endcase
    end
endmodule
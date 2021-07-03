module HDCPU(CLR,
             T3,
             C,
             Z,
             SW,
             IR,
             W,
             LDC,
             LDZ,
             CIN,
             S,
             SEL,
             M,
             ABUS,
             DRW,
             PCINC,
             LPC,
             LAR,
             PCADD,
             ARINC,
             SELCTL,
             MEMW,
             STOP,
             LIR,
             SBUS,
             MBUS,
             SHORT,
             LONG);
    input CLR, T3, C, Z;
    input[2:0] SW;
    input [7:4] IR;
    input [3:1] W;
    output [3:0] S;
    output [3:0] SEL;
    output LDC, LDZ, CIN, M, ABUS,DRW, PCINC, LPC, LAR, PCADD, ARINC,SELCTL,MEMW, STOP, LIR, SBUS, MBUS, SHORT, LONG;
    reg LDC, LDZ, CIN, M, ABUS,DRW, PCINC, LPC, LAR, PCADD, ARINC,SELCTL,MEMW, STOP, LIR, SBUS, MBUS, SHORT, LONG;
    reg [3:0] S;
    reg [3:0] SEL;
    
    reg ST0,SST0;
    always @(SW,W,CLR,T3,IR)//?是否需要把T3专门写成脉冲形式
    begin
        {LDC, LDZ, CIN, M, ABUS,DRW, PCINC, LPC, LAR, PCADD, ARINC,SELCTL,MEMW, STOP, LIR, SBUS, MBUS, SHORT, LONG,S,SEL} = 0;
        if (CLR == 0)
        begin
            ST0  <= 0;
            SST0 <= 0;
        end
        else
        begin
            if (T3 == 0)//这里有大坑，不确定是不是这样写，而且这个if 没有对应的else 
            begin
                if (SST0 == 1'b1)
                    ST0 <= SST0;
                else
                    ST0 <= ST0;
            end
            
            case (SW)
                3'b001:
                begin
                    LAR    = W[1] && !ST0;
                    MEMW   = W[1] && ST0;
                    ARINC  = W[1] && ST0;
                    SBUS   = W[1];
                    STOP   = W[1];
                    SHORT  = W[1];
                    SELCTL = W[1];
                    SST0   = W[1];
                end
                3'b010:
                begin
                    SBUS   = W[1]&&!ST0;
                    LAR    = W[1]&&!ST0;
                    SST0   = W[1]&&!ST0;
                    MBUS   = W[1]&&ST0;
                    ARINC  = W[1]&&ST0;
                    STOP   = W[1];
                    SHORT  = W[1];
                    SELCTL = W[1];
                end
                3'b011:
                begin
                    SEL[3] = W[2];
                    SEL[2] = 0;
                    SEL[1] = W[2];
                    SEL[0] = W[1] || W[2];
                    SELCTL = W[1] || W[2];
                    STOP   = W[1] || W[2];
                end
                3'b100:
                begin
                    SBUS   = W[1]||W[2];
                    SELCTL = W[1]||W[2];
                    DRW    = W[1]||W[2];
                    STOP   = W[1]||W[2];
                    SST0   = !ST0&&W[2];
                    SEL[3] = ST0;
                    SEL[2] = W[2];
                    SEL[1] = (!ST0&&W[1])||(ST0 && W[2]);
                    SEL[1] = W[1];
                end
                3'b000:
                begin
                    //开始执行SW == 000的情况--->
                    LIR=W[1];
                    PCINC=W[1];
                    case (IR)
                        4'b0001:begin//ADD
                            S=4'b1001;
                            CIN = W[2];
                            ABUS=W[2];
                            DRW=W[2];
                            LDZ=W[2];
                            LDC=W[2];    
                        end
                        4'b0010:begin//SUB
                            S=4'b0110;
                            ABUS=W[2];
                            DRW=W[2];
                            LDZ=W[2];
                            LDC=W[2];
                        end
                        4'b0011:begin//AND
                            M=W[2];
                            S=4'b1011;
                            ABUS=W[2];
                            DRW=W[2];
                            LDZ=W[2];
                        end
                        4'b0100:begin//INC
                            S=4'b0000;
                            ABUS=W[2];
                            DRW=W[2];
                            LDZ=W[2];
                            LDC=W[2];
                        end
                        4'b0101:begin//LD
                            M=W[2];
                            S=4'b1010;
                            ABUS=W[2];
                            LAR=W[2];
                            LONG=W[2];
                            DRW=W[3];
                            MBUS=W[3];
                        end
                        4'b0110:begin//ST
                            M=W[2];
                            S={1,W[2],1,W[2]};
                            ABUS=W[2] | W[3];
                            LAR=W[2];
                            LONG=W[2];
                            MEMW=W[3];
                        end
                        4'b0111://JC
                            if (C==1) PCADD=W[2];
                        4'b1000://JZ
                            if (Z==1) PCADD=W[2];
                        4'b1001:begin//JMP
                            M=W[2];
                            S=4'b1111;
                            ABUS=W[2];
                            LPC=W[2];
                        end
                        4'b1110:begin//STP
                            STOP=W[2];
                        end
                        //额外指令
                        4'b1010:begin//OUT
                            M=W[2];
                            S=4'b1010;
                            ABUS=W[2];
                        end
                        4'b1011:begin//XOR
                            M=W[2];
                            S=4'b0110;
                            ABUS=W[2];
                            DRW=W[2];
                            LDZ=W[2];
                        end
                        4'b1100:begin//OR
                            M=W[2];
                            S=4'b1110;
                            ABUS=W[2];
                            DRW=W[2];
                            LDZ=W[2];
                        end
                        default:begin
                            
                        end
                    endcase
                    //<---SW == 000的情况执行完毕
                end
                //default:
            endcase
            
        end
    end
endmodule

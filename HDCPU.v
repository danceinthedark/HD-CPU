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
    always @(SW,W, CLR, T3,IR)//?是否需要把T3专门写成脉冲形式
    begin
        {LDC, LDZ, CIN, M, ABUS,DRW, PCINC, LPC, LAR, PCADD, ARINC,SELCTL,MEMW, STOP, LIR, SBUS, MBUS, SHORT, LONG,S,SEL} = 0;
        if (CLR == 0)
        begin
            ST0  <= 0;
            SST0 <= 0;
        end
        else
        begin
            if (T3 == 0)//ST0和SST0会在每个W的T3下降沿刷新
            begin
                if (SST0 == 1'b1)//有SST0 == 1就立刻ST0 = 1
                    ST0 <= SST0;
                    // else //SST0 == 1就在最后一个W把ST0 = 0
                    // begin
                    //     if ((W[1]&&SHORT)||(W[2]&&!LONG))//不应该涉及W[3]
                    //         ST0 <= 0;
                    //     else
                    //         ST0 <= ST0;
                    // end
                
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
                    SELCTL = W[1] || W[2];
                    STOP   = W[1] || W[2];
                    SEL[3] = W[2];
                    SEL[2] = 0;
                    SEL[1] = W[2];
                    SEL[0] = W[1] || W[2];
                end
                3'b100:
                begin
                    SBUS   <= W[1]||W[2];
                    SELCTL <= W[1]||W[2];
                    DRW    <= W[1]||W[2];
                    STOP   <= W[1]||W[2];
                    SST0   <= !ST0&&W[2];
                    SEL[3] <= ST0;
                    SEL[2] <= W[2];
                    SEL[1] <= (!ST0&&W[1])||(ST0 && W[2]);
                    SEL[0] <= W[1];
                end
                3'b000:
                begin
                    //开始执行SW == 000的情况--->
                    
                    //<---SW == 000的情况执行完毕
                end
                //default:
            endcase
            
        end
    end
endmodule

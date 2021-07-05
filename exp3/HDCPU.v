module HDCPU(
    input CLR,
    input T3,
    input C,
    input Z,
    input [2:0] SW,
    input [7:4] IR,
    input [3:1] W,
    input PULSE,
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

    reg EI;
    reg SST0;
    reg ST0;
    reg [2:0] count;
    reg [2:0] flag;
    reg [2:0] fflag;
    reg [7:0] SELF_IR;
    reg [7:0] SELF_PC;
    reg [7:0] SELF_R0;

    always @(negedge T3, negedge CLR)
    begin
        if (!CLR) begin
            ST0 = 0;
            flag = 0;
        end
        else if (!T3) begin
            flag = fflag;
            if (SST0 == 1'b1) begin
                ST0 = SST0; // 有SST0 == 1就立刻ST0    = 1
            end
            else if (SW == 3'b100 && ST0 && W[2])
                ST0 = 0;
        end
    end

    always @(W, CLR, PULSE) // ?是否需要把T3专门写成脉冲形式
    begin
        {LDC, LDZ, CIN, M, ABUS, DRW, PCINC, LPC, LAR, PCADD, ARINC, SELCTL, MEMW, STOP, LIR, SBUS, MBUS, SHORT, LONG, S, SEL} = 0;

        if (!CLR) begin
            count = 0;
            fflag = 0;
            EI = 1;
            SELF_IR = 0;
            SELF_PC = 0;
            SELF_R0 = 0;
            SST0 = 0;
            S = 0;
        end
        else begin
            case (SW)
                3'b001: begin
                    LAR    = W[1] && !ST0;
                    MEMW   = W[1] && ST0;
                    ARINC  = W[1] && ST0;
                    SBUS   = W[1];
                    STOP   = W[1];
                    SHORT  = W[1];
                    SELCTL = W[1];
                    SST0   = W[1];
                end
                3'b010: begin
                    SBUS   = W[1] && !ST0;
                    LAR    = W[1] && !ST0;
                    SST0   = W[1] && !ST0;
                    MBUS   = W[1] && ST0;
                    ARINC  = W[1] && ST0;
                    STOP   = W[1];
                    SHORT  = W[1];
                    SELCTL = W[1];
                end
                3'b011: begin
                    SELCTL = W[1] || W[2];
                    STOP   = W[1] || W[2];
                    SEL[3] = W[2];
                    SEL[2] = 0;
                    SEL[1] = W[2];
                    SEL[0] = W[1] || W[2];
                end
                3'b100: begin
                    SBUS   = W[1] || W[2];
                    SELCTL = W[1] || W[2];
                    DRW    = W[1] || W[2];
                    STOP   = W[1] || W[2];
                    SST0   = !ST0&&W[2];
                    SEL[3] = ST0;
                    SEL[2] = W[2];
                    SEL[1] = (!ST0&&W[1])||(ST0 && W[2]);
                    SEL[0] = W[1];
                end
                3'b000: 
                if(ST0==0)begin 
                        LPC=W[1];
                        SBUS=W[1];
                        SST0=W[1];
                        SHORT=W[1];
                        STOP=W[1];
                    end
                else 
                begin
                    // 开始执行SW == 000的情况--->
                    case (flag)
                        // 取指令执行指令
                        3'b000: begin
                            if (PULSE && EI) begin
                                EI = 0;
                                SBUS = 1;
                                LPC = 1;
                                SHORT = 1;
                            end
                            else begin
                                LIR   = W[1];
                                PCINC = W[1];
                                if (EI)
                                    SELF_PC = SELF_PC + 1;
                                case (IR)
                                    4'b0001: begin // ADD
                                        S    = 4'b1001;
                                        CIN  = W[2];
                                        ABUS = W[2];
                                        DRW  = W[2];
                                        LDZ  = W[2];
                                        LDC  = W[2];
                                    end
                                    4'b0010: begin // SUB
                                        S    = 4'b0110;
                                        ABUS = W[2];
                                        DRW  = W[2];
                                        LDZ  = W[2];
                                        LDC  = W[2];
                                    end
                                    4'b0011: begin // AND
                                        M    = W[2];
                                        S    = 4'b1011;
                                        ABUS = W[2];
                                        DRW  = W[2];
                                        LDZ  = W[2];
                                    end
                                    4'b0100: begin // INC
                                        S    = 0;
                                        ABUS = W[2];
                                        DRW  = W[2];
                                        LDZ  = W[2];
                                        LDC  = W[2];
                                    end
                                    4'b0101: begin // LD
                                        M    = W[2];
                                        S    = 4'b1010;
                                        ABUS = W[2];
                                        LAR  = W[2];
                                        LONG = W[2];
                                        DRW  = W[3];
                                        MBUS = W[3];
                                    end
                                    4'b0110: begin // ST
                                        M    = W[2] || W[3];
                                        S    = (W[2]) ? 4'b1111 : 4'b1010;
                                        ABUS = W[2] || W[3];
                                        LAR  = W[2];
                                        LONG = W[2];
                                        MEMW = W[3];
                                    end
                                    4'b0111: begin // JC
                                        if (C == 1) begin
                                            PCADD = W[2];
                                            if(EI) begin
                                                ABUS = W[2];
                                                SEL[3] = !W[2];
                                                SEL[2] = !W[2];
                                                S = 4'b1100;
                                                SELCTL = W[2];
                                                CIN = W[2];
                                                DRW = W[2];
                                                LDZ = W[2];
                                                LDC = W[2];
                                                if(W[2])
                                                    fflag = 1;
                                            end
                                        end
                                    end
                                    4'b1000:// JZ
                                        if (Z == 1) begin
                                            PCADD = W[2];
                                            if(EI) begin
                                                ABUS = W[2];
                                                SEL[3] = !W[2];
                                                SEL[2] = !W[2];
                                                S = 4'b1100;
                                                SELCTL = W[2];
                                                CIN = W[2];
                                                DRW = W[2];
                                                LDZ = W[2];
                                                LDC = W[2];
                                                if(W[2])
                                                    fflag = 1;
                                            end
                                        end
                                    4'b1001: begin // JMP
                                        M    = W[2];
                                        S    = 4'b1111;
                                        ABUS = W[2];
                                        LPC  = W[2];
                                        // TODO: SELF_PC同步
                                    end
                                    // 额外指令
                                    4'b1010: begin // OUT
                                        M    = W[2];
                                        S    = 4'b1010;
                                        ABUS = W[2];
                                    end
                                    4'b1011: begin // IRET
                                        SHORT = W[1];
                                        fflag = 5;
                                    end
                                    4'b1100: begin // OR
                                        M    = W[2];
                                        S    = 4'b1110;
                                        ABUS = W[2];
                                        DRW  = W[2];
                                        LDZ  = W[2];
                                    end
                                    4'b1101: begin // XOR
                                        M    = W[2];
                                        S    = 4'b0110;
                                        ABUS = W[2];
                                        DRW  = W[2];
                                        LDZ  = W[2];
                                    end
                                    4'b1110: begin // STP
                                        STOP = W[2];
                                    end
                                    default: S = 4'b0000;
                                endcase
                                // <---SW == 000的情况执行完毕
                            end
                        end
                        // flag1将SELF_R0寄存器提取并保存至软件
                        // flag3将SELF_R0寄存器提取至软件
                        3'b0?1: begin
                            SELF_R0 = (SELF_R0 << 1) + C;
                            SHORT = W[1];
                            if (count < 7) begin
                                count = count + 1;
                                ABUS = W[1];
                                SEL[3] = !W[1];
                                SEL[2] = !W[1];
                                S = 4'b1100;
                                SELCTL = W[1];
                                CIN = W[1];
                                DRW = W[1];
                                LDZ = W[1];
                                LDC = W[1];
                            end
                            else begin
                                if (fflag == 3)begin
                                    SELF_PC = SELF_PC + SELF_IR & 8'h0f;
                                    if (SELF_IR >= 8)
                                        SELF_PC = SELF_PC - 16;
                                end
                                fflag = fflag + 1;
                                count = 0;
                            end
                        end
                        // 将SELF_PC提取至SELF_R0寄存器
                        3'b010: begin
                            if (count < 8) begin
                                count = count + 1;
                                ABUS = W[1];
                                SEL[3] = !W[1];
                                SEL[2] = !W[1];
                                SELCTL = W[1];
                                S = 4'b1100;
                                CIN = W[1];
                                DRW = W[1];
                                LDZ = W[1];
                                LDC = W[1];
                                if (SELF_PC[8-count]) begin
                                    SELCTL = W[2];
                                    SEL[3] = !W[2];
                                    SEL[2] = !W[2];
                                    S = 4'b0000;
                                    ABUS = W[2];
                                    DRW = W[2];
                                    LDZ = W[2];
                                    LDC = W[2];
                                end
                                else
                                    SHORT = W[1];
                            end
                            else begin
                                count = 0;
                                SELCTL = 1;
                                SEL[3] = 0;
                                SEL[2] = 0;
                                SEL[1] = 0;
                                SEL[0] = 0;
                                M = W[1];
                                S = W[1] ? 4'b1010 : 4'b1100;
                                ABUS = W[1] || W[3];
                                LAR = W[1];
                                MBUS = W[2];
                                DRW = W[2] || W[3];
                                LONG = W[2];
                                CIN = W[3];
                                LDZ = W[3];
                                LDC = W[3];
                                if (W[3])
                                    fflag = 3;
                            end
                        end

                        // 恢复SELF_R0初始值
                        3'b100: begin
                            if (count < 8) begin
                                count = count + 1;
                                ABUS = W[1];
                                SEL[3] = !W[1];
                                SEL[2] = !W[1];
                                SELCTL = W[1];
                                S = 4'b1100;
                                CIN = W[1];
                                DRW = W[1];
                                LDZ = W[1];
                                LDC = W[1];
                                if (SELF_R0[8-count]) begin
                                    SELCTL = W[2];
                                    SEL[3] = !W[2];
                                    SEL[2] = !W[2];
                                    S = 4'b0000;
                                    ABUS = W[2];
                                    DRW = W[2];
                                    LDZ = W[2];
                                    LDC = W[2];
                                end
                                else
                                    SHORT = W[1];
                            end
                            else begin
                                count = 0;
                                SHORT = W[1];
                                fflag = 0;
                            end
                        end
                        // 恢复SELF_PC初始值
                        3'b101: begin
                            if (count < 8) begin
                                count = count + 1;
                                ABUS = W[1];
                                SEL[3] = !W[1];
                                SEL[2] = !W[1];
                                SELCTL = W[1];
                                S = 4'b1100;
                                CIN = W[1];
                                DRW = W[1];
                                LDZ = W[1];
                                LDC = W[1];
                                if (SELF_PC[8-count]) begin
                                    SELCTL = W[2];
                                    SEL[3] = !W[2];
                                    SEL[2] = !W[2];
                                    S = 4'b0000;
                                    ABUS = W[2];
                                    DRW = W[2];
                                    LDZ = W[2];
                                    LDC = W[2];
                                end
                                else
                                    SHORT = W[1];
                            end
                            else begin
                                count = 0;
                                SHORT =1;
                                fflag = 0;
                                SELCTL = 1;
                                SEL[1] = 0;
                                SEL[0] = 0;
                                M = 1;
                                S = 4'b1010;
                                ABUS = 1;
                                LPC = 1;
                                EI = 1;
                            end
                        end
                    endcase
                end
                // default:
            endcase
        end
    end
endmodule
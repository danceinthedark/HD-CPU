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
    reg ST0,MIDDLE;
    reg [2:0] count;
    reg [2:0] flag;
    reg [2:0] fflag;
    reg [7:0] SELF_IR,SELF_PC,SELF_R0;
    reg [1:0] SELF_C,SELF_Z,jmp_flag,iret_flag;
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

    always @(CLR, PULSE) // ?是否需要把T3专门写成脉冲形式
    begin
        {LDC, LDZ, CIN, M, ABUS, DRW, PCINC, LPC, LAR, PCADD, ARINC, SELCTL, MEMW, STOP, LIR, SBUS, MBUS, SHORT, LONG, S, SEL, SST0} = 0;

        if (!CLR) begin
            count = 0;
            fflag = 0;
            EI = 1;
            SELF_IR = 0;
            SELF_PC = 0;
            SELF_R0 = 0;
            SELF_C = 0;
            SELF_Z = 0;
        end
        else begin
            case (SW)
                3'b001: begin //写存储器
                    LAR    = W[1] && !ST0;
                    MEMW   = W[1] && ST0;
                    ARINC  = W[1] && ST0;
                    SBUS   = W[1];
                    STOP   = W[1];
                    SHORT  = W[1];
                    SELCTL = W[1];
                    SST0   = W[1];
                end
                3'b010: begin //读存储器
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
                3'b100: begin //写寄存器
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
                        LPC = W[1];
                        SBUS = W[1];
                        SST0 = W[1];
                        SHORT = W[1];
                        STOP = W[1];
                    end
                else 
                begin
                    // 开始执行SW == 000的情况--->
                    case (flag)
                        // 取指令执行指令
                        3'b000: begin
                            if (PULSE && EI) begin
                                EI = !W[1];
                                SBUS = W[1];
                                LPC = W[1];
                                SHORT = W[1];
                            end
                            else begin
                                LIR   = W[1];
                                PCINC = W[1];
                                if (EI)
                                    SELF_PC = SELF_PC + 1;
                                case (IR)
                                    4'b0001,4'b0010: begin // ADD & SUB
                                        S    = (IR==4'b0001) ? 4'b1001 : 4'b0110;
                                        CIN  = W[2] && (IR == 4'b0001);
                                        ABUS = W[2];
                                        DRW  = W[2];
                                        LDZ  = W[2];
                                        LDC  = W[2];
                                        SELF_C = 0;
                                        SELF_Z = 0;
                                    end
                                    4'b0011,4'b1100,4'b1101: begin // AND
                                        M    = W[2];
                                        case (IR)
                                            4'b0011:S = 4'b1011;//AND
                                            4'b1100:S = 4'b1110;//OR 
                                            default:S = 4'b0110;//XOR
                                        endcase
                                        ABUS = W[2];
                                        DRW  = W[2];
                                        LDZ  = W[2];
                                        SELF_C = 0;
                                        SELF_Z = 0;
                                    end
                                    4'b0100: begin // INC
                                        S    = 0;
                                        ABUS = W[2];
                                        DRW  = W[2];
                                        LDZ  = W[2];
                                        LDC  = W[2];
                                        SELF_C = 0;
                                        SELF_Z = 0;
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
                                    4'b0111,4'b1000: begin // JC && JZ
                                        if ((IR==4'b0111 && ((SELF_C==0 && C) || SELF_C==2'b11))
                                        || (IR==4'b1000 && ((SELF_Z==0 && Z) || SELF_Z==2'b11))) begin
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
                                                fflag = W[2];
                                                if (W[2])begin
                                                    if (!SELF_C) SELF_C = {1'b1,C};
                                                    if (!SELF_Z) SELF_Z = {1'b1,Z};
                                                end
                                            end
                                        end
                                    end
                                    4'b1001,4'b1010: begin // JMP && IRET
                                        ABUS = W[2];
                                        SEL[3] = !W[2];
                                        SEL[2] = !W[2];
                                        S = 4'b1100;
                                        SELCTL = W[2];
                                        CIN = W[2];
                                        DRW = W[2];
                                        LDZ = W[2];
                                        LDC = W[2];
                                        if (IR==4'b1001) jmp_flag = W[2];
                                        else iret_flag = W[2];
                                        fflag = W[2];
                                        if (W[2])begin
                                            if (!SELF_C) SELF_C={1'b1,C};
                                            if (!SELF_Z) SELF_Z={1'b1,Z};
                                        end
                                    end
                                    4'b1010: begin // OUT
                                        M    = W[2];
                                        S    = 4'b1010;
                                        ABUS = W[2];
                                    end
                                    4'b1110: begin // STP
                                        STOP = W[2];
                                    end
                                    default: S = 4'b0000;
                                endcase
                                // <---SW == 000的情况执行完毕
                            end
                        end
                        // flag==1 将SELF_R0寄存器提取并保存至软件
                        // flag==3 将SELF_R0寄存器提取至软件
                        3'b001,3'b011: begin
                            if (flag == 3'b001) SELF_R0 = (SELF_R0 << 1) + C;
                            else SELF_IR = (SELF_IR << 1) + C;
                            SHORT = W[1];
                            if (count < 7) begin
                                count = count + 1;
                                SELCTL = W[1];
                                SEL[3] = !W[1];
                                SEL[2] = !W[1];
                                S = 4'b1100;
                                ABUS = W[1];
                                DRW = W[1];
                                LDZ = W[1];
                                LDC = W[1];
                                CIN = W[1];
                            end
                            else begin
                                if (flag == 3'b001) begin
                                    if (iret_flag) fflag = 5;
                                    if (jmp_flag) fflag = 2;
                                end
                                else begin
                                    fflag = 4;
                                    if (jmp_flag == 0)begin
                                        SELF_PC = SELF_PC + SELF_IR[3:0]; 
                                        if (SELF_IR[3]) SELF_PC = SELF_PC - 5'b10000;
                                    end
                                    else if (jmp_flag == 1)begin
                                        fflag = 6;
                                    end
                                    else if (jmp_flag == 2)begin
                                        SELF_PC = SELF_IR;
                                    end
                                end
                                count = 0;
                            end
                        end
                        // flag==2 将SELF_PC提取至SELF_R0寄存器
                        // flag==4 恢复SELF_R0初始值
                        // flag==5 IRET将SELF_PC打入PC
                        3'b010,3'b101,3'b100: begin
                            if (count < 8) begin
                                count = count + 1;
                                MIDDLE = (IR==3'b100)?SELF_R0[8-count]:SELF_PC[8-count]; 

                                SELCTL = W[1] || (W[2] && MIDDLE);
                                SEL[3] = !(W[1] || (W[2] && MIDDLE));
                                SEL[2] = !(W[1] || (W[2] && MIDDLE));
                                S = (W[1])?4'b1100:4'b0000;
                                ABUS = W[1] || (W[2] && MIDDLE);
                                DRW = W[1] || (W[2] && MIDDLE);
                                LDZ = W[1] || (W[2] && MIDDLE);
                                LDC = W[1] || (W[2] && MIDDLE);
                                CIN = W[1];
                            end
                            else begin
                                case (flag)
                                    3'b010:begin 
                                        SELCTL = W[1] || W[2] || W[3];
                                        SEL[3] = !(W[2] || W[3]);
                                        SEL[2] = !(W[2] || W[3]);
                                        SEL[1] = W[1];
                                        SEL[0] = W[1];
                                        M = W[1];
                                        if (W[1]) S=4'b1010;
                                        else if (W[3]) S=4'b1100;
                                        ABUS = W[1] || W[3];
                                        LAR = W[1];
                                        MBUS = W[2];
                                        DRW = W[2] || W[3];
                                        LONG = W[2];
                                        LDZ = W[3];
                                        LDC = W[3];
                                        CIN = W[3];
                                        if (W[3])begin
                                            fflag = 3;
                                            count = 0;
                                        end
                                    end 
                                    3'b101:begin
                                        count = 0;
                                        SHORT = W[1];
                                        SEL[1] = !W[1];
                                        SEL[0] = !W[1];
                                        M = W[1];
                                        S = 4'b1010;
                                        ABUS = W[1];
                                        LPC = W[1];
                                        fflag = 4;
                                    end
                                    3'b100:begin
                                        count = 0;
                                        SHORT = W[1];
                                        EI = 1;
                                        iret_flag = 0;
                                        jmp_flag = 0;
                                        fflag = 0;
                                    end 
                                endcase
                            end
                        end
                        3'b110://将Rx传至R0或直接将SELF_PC赋值为SELF_R0(Rx=R0)
                            if (SELF_IR&2'h0c==2'h0c)begin
                                SELCTL = W[1] || W[2];
                                SEL[3] = !(W[1] || W[2]);
                                SEL[2] = !(W[1] || W[2]);
                                SEL[1] = SELF_IR[3];
                                SEL[0] = SELF_IR[2];
                                S = (W[1])?4'b1010:4'b1100;
                                ABUS = W[1] || W[2];
                                DRW = W[1] || W[2];
                                M = W[1];
                                LDZ = W[2];
                                LDC = W[2];
                                CIN = W[2];
                                jmp_flag = 2;
                                fflag = 3;
                            end
                            else
                            begin
                                SHORT = W[1];
                                jmp_flag = 2;
                                fflag = 4;
                                SELF_PC = SELF_R0;
                            end
                    endcase
                end
                // default:
            endcase
        end
    end
endmodule
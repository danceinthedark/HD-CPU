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
    output reg LONG,
    output reg[3:0] count,
    output reg[3:0] ccount
    );
    reg EI,EEI;
    reg SST0;
    reg ST0,MIDDLE,jmp_flag,jjmp_flag;
    reg [2:0] flag,fflag;
    reg [7:0] SELF_IR,SELF_R0;
    reg [7:0] SSELF_IR,SSELF_R0;
    always @(negedge T3, negedge CLR)
    begin
        if (!CLR) begin
            EI = 0;
            SELF_IR = 0;
            SELF_R0 = 0;
            ST0 = 0;
            count = 0;
            flag = 0;
            jmp_flag = 0;
        end
        else if (!T3) begin
            EI = EEI;
            SELF_IR = SSELF_IR;
            SELF_R0 = SSELF_R0;
            count = ccount;
            flag = fflag;
            jmp_flag = jjmp_flag;
            if (SST0 == 1'b1) begin
                ST0 = SST0;
            end
            else if (SW == 3'b100 && ST0 && W[2])
                ST0 = 0;
        end
    end

    always @(CLR, PULSE)
    begin
        {LDC, LDZ, CIN, M, ABUS, DRW, PCINC, LPC, LAR, PCADD, ARINC, SELCTL, MEMW, STOP, LIR, SBUS, MBUS, SHORT, LONG, S, SEL, SST0} = 0;

        if (!CLR) begin
            EEI = 0;
            SSELF_IR = 0;
            SSELF_R0 = 0;
            ccount = 0;
            fflag = 0;
        end
        else begin
            case (SW)
                3'b001: begin // Write RAM
                    if(W[1]) begin
                        ARINC  = ST0;
                        LAR    = !ST0;
                        MEMW   = ST0;
                        SBUS   = 1;
                        SELCTL = 1;
                        SHORT  = 1;
                        SST0   = 1;
                        STOP   = 1;
                    end
                end
                3'b010: begin // Read RAM
                    if(W[1]) begin
                        ARINC  = ST0;
                        LAR    = !ST0;
                        MBUS   = ST0;
                        SBUS   = !ST0;
                        SELCTL = 1;
                        SHORT  = 1;
                        SST0   = !ST0;
                        STOP   = 1;
                    end
                end
                3'b011: begin // Read Register
                    if(W[1]) begin
                        SEL = 4'b0001;
                        SELCTL = 1;
                        STOP   = 1;
                    end
                    else if (W[2]) begin
                        SEL = 4'b1011;
                        SELCTL = 1;
                        STOP   = 1;
                    end
                end
                3'b100: begin // Write Register
                    if(W[1]) begin
                        DRW    = 1;
                        SBUS   = 1;
                        SEL = {ST0, 1'b0, !ST0, 1'b1};
                        SELCTL = 1;
                        SST0   = 0;
                        STOP   = 1;
                    end
                    else if(W[2]) begin
                        DRW    = 1;
                        SBUS   = 1;
                        SEL = {ST0, 1'b1, ST0, 1'b0};
                        SELCTL = 1;
                        SST0   = !ST0;
                        STOP   = 1;
                    end
                end
                3'b000: // Execute Instructions
                if(ST0 == 0) begin
                    if(W[1]) begin
                        DRW = 1;
                        S = 4'b1010;
                        SBUS = 1;
                        SEL = 4'b1111;
                        SELCTL = 1;
                        SST0 = 0;
                        STOP = 1;
                    end
                    else if(W[2]) begin
                        ABUS = 1;
                        LPC = 1;
                        M = 1;
                        S = 4'b1010;
                        SEL = 4'b1111;
                        SELCTL = 1;
                        SST0 = 1;
                    end
                end
                else begin
                    case (flag)
                        3'b000: begin
                            if (PULSE && !EI) begin
                                if(W[1]) begin
                                    DRW = 1;
                                    EEI = 1;
                                    S = 4'b1010;
                                    SBUS = 1;
                                    SEL = 4'b1111;
                                    SELCTL = 1;
                                    STOP = 1;
                                end
                                else if(W[2]) begin
                                    ABUS = 1;
                                    EEI = 1;
                                    LPC = 1;
                                    M = 1;
                                    S = 4'b1010;
                                    SEL = 4'b1111;
                                    SELCTL = 1;
                                end
                            end
                            else begin
                                if(W[1]) begin
                                    LIR   = 1;
                                    PCINC = 1;
                                    if (!EI) begin
                                        ABUS = 1;
                                        DRW = 1;
                                        S = 4'b0000;
                                        SEL = 4'b1100;
                                        SELCTL = 1;
                                    end
                                end
                                else begin
                                    case (IR)
                                        // ADD, SUB
                                        4'b0001, 4'b0010: begin
                                            if(W[2]) begin
                                                ABUS = 1;
                                                CIN  = (IR == 4'b0001);
                                                DRW  = 1;
                                                LDC  = 1;
                                                LDZ  = 1;
                                                S    = (IR==4'b0001) ? 4'b1001 : 4'b0110;
                                            end
                                        end
                                        4'b0011, 4'b1100, 4'b1101: begin
                                            if(W[2]) begin
                                                ABUS = 1;
                                                DRW  = 1;
                                                LDZ  = 1;
                                                M    = 1;
                                                case (IR)
                                                    // AND
                                                    4'b0011: S = 4'b1011;
                                                    // OR
                                                    4'b1100: S = 4'b1110;
                                                    // XOR
                                                    4'b1101: S = 4'b0110;
                                                endcase
                                            end
                                        end
                                        // INC
                                        4'b0100: begin
                                            if(W[2]) begin
                                                ABUS = 1;
                                                DRW  = 1;
                                                LDC  = 1;
                                                LDZ  = 1;
                                            end
                                        end
                                        // LD
                                        4'b0101: begin
                                            if(W[2]) begin
                                                ABUS = 1;
                                                LAR  = 1;
                                                LONG = 1;
                                                M    = 1;
                                                S    = 4'b1010;
                                            end
                                            else if(W[3]) begin
                                                DRW  = 1;
                                                MBUS = 1;
                                            end
                                        end
                                        // ST
                                        4'b0110: begin
                                            if(W[2]) begin
                                                ABUS = 1;
                                                LAR  = 1;
                                                LONG = 1;
                                                M    = 1;
                                                S    = 4'b1111;
                                            end
                                            else if(W[3]) begin
                                                ABUS = 1;
                                                M    = 1;
                                                MEMW = 1;
                                                S    = 4'b1010;
                                            end
                                        end
                                        // JC, JZ
                                        4'b0111, 4'b1000:
                                            if ((flag == 4'b0111 && C) || (flag == 4'b1000 && Z)) begin
                                                if(W[2]) begin
                                                    PCADD = 1;
                                                    if(!EI) begin
                                                        ABUS = 1;
                                                        CIN = 1;
                                                        DRW = 1;
                                                        LDC = 1;
                                                        LDZ = 1;
                                                        S = 4'b1100;
                                                        SELCTL = 1;
                                                        ccount = 1;
                                                        fflag = 1;
                                                    end
                                                end
                                                else if(W[3]) begin
                                                    if(!EI) begin
                                                        S = 4'b1100;
                                                        SEL[2] = 1;
                                                        SEL[3] = 1;
                                                        ccount = 1;
                                                        fflag = 0;
                                                    end
                                                end
                                            end
                                        // JMP
                                        4'b1001: begin
                                            if(W[2]) begin
                                                ABUS = 1;
                                                LPC = 1;
                                                M = 1;
                                                S = 4'b1111;
                                                LONG = !EI;
                                            end
                                            else if(W[3]) begin
                                                ABUS = 1;
                                                CIN = 1;
                                                DRW = 1;
                                                LDC = 1;
                                                LDZ = 1;
                                                S = 4'b1100;
                                                SELCTL = 1;
                                                ccount = 1;
                                                fflag = 1;
                                                jjmp_flag = 1;
                                            end
                                        end
                                        // IRET
                                        4'b1011:
                                        begin
                                            if(W[2]) begin
                                                ABUS = 1;
                                                LPC = 1;
                                                M = 1;
                                                S = 4'b1010;
                                                SEL = 4'b0011;
                                                SELCTL = 1;
                                            end
                                        end
                                        4'b1101: begin
                                            EEI = 1;
                                        end
                                        // OUT
                                        4'b1010: begin
                                            if(W[2]) begin
                                                ABUS = 1;
                                                M    = 1;
                                                S    = 4'b1010;
                                            end
                                        end
                                        // STP
                                        4'b1110: begin
                                            if(W[2]) begin
                                                STOP = 1;
                                            end
                                        end
                                        default: S = 4'b0000;
                                    endcase
                                end
                            end
                        end
                        // flag = 1 ??R0????????????PC->AR->R0
                        // flag = 2 ??????????????????
                        3'b001,3'b010: begin
                            if (flag == 1)
                                SSELF_R0 = (SELF_R0 << 1) + C;
                            else
                                SSELF_IR = (SELF_IR << 1) + C;

                            if (count != 8) begin
                                if(W[1]) begin
                                    ccount = count + 1;
                                    ABUS = 1;
                                    CIN = 1;
                                    DRW = 1;
                                    LDC = 1;
                                    LDZ = 1;
                                    S = 4'b1100;
                                    SELCTL = 1;
                                    SHORT = 1;
                                end
                            end
                            else begin
                                if (flag == 1) begin
                                    if(W[1]) begin
                                        ABUS = 1;
                                        CIN = 1;
                                        LAR = 1;
                                        S = 4'b1111;
                                        SEL = 4'b1100;
                                        SELCTL = 1;
                                    end
                                    else if(W[2]) begin
                                        DRW = 1;
                                        LONG = 1;
                                        MBUS = 1;
                                        S = 4'b1100;
                                        SELCTL = 1;
                                    end
                                    else if(W[3]) begin
                                        ABUS = 1;
                                        CIN = 1;
                                        DRW = 1;
                                        LDC = 1;
                                        LDZ = 1;
                                        S = 4'b1100;
                                        SEL = 4'b0000;
                                        SELCTL = 1;
                                        ccount = 1;
                                        fflag = 2;
                                    end
                                end
                                else begin
                                    if (jmp_flag) begin
                                        if(SELF_IR[3:2]) begin
                                            if(W[1]) begin
                                                ABUS = 1;
                                                DRW = 1;
                                                M = 1;
                                                S = 4'b1010;
                                                SEL = {1'b1, 1'b1, SELF_IR[3], SELF_IR[2]};
                                                SELCTL = 1;
                                                SHORT = 1;
                                                fflag = 4;
                                            end
                                        end
                                        else begin
                                            if(W[1]) begin
                                                SHORT = 1;
                                                fflag = 4;
                                            end
                                        end
                                    end
                                    else begin
                                        if(W[1]) begin
                                            SHORT = 1;
                                            fflag = 3;
                                        end
                                    end
                                    ccount = 0;
                                end
                            end
                        end
                        // flag = 3, ??????????????????R0, ????R3(PC)????
                        // flag = 4, ????R0
                        3'b011,3'b100: begin
                            if (count !=8) begin
                                if(W[1]) begin
                                    SHORT= 1;
                                    ccount = count + 1;
                                end
                                ABUS = 1;
                                CIN = !((flag == 3 && count>=4 && SELF_IR[7-count]) ||
                                    (flag == 4 && SELF_R0[7-count]));
                                DRW = 1;
                                S = 4'b1100;
                                SEL = {1'b0, 1'b0, 1'b0, 1'b0};
                                SELCTL = 1;
                            end
                            else begin
                                SHORT = W[1];
                                if (flag == 3) begin
                                    ABUS = W[1];
                                    CIN = W[1];
                                    DRW = W[1];
                                    S = 4'b1001;
                                    SEL = {1'b1, 1'b1, 1'b0, 1'b0};
                                    SELCTL = W[1];
                                    fflag = 4;
                                end
                                else begin
                                    if (jmp_flag && SELF_IR[3:2]==2'b00)
                                    begin
                                        ABUS = W[1];
                                        DRW = W[1];
                                        M = W[1];
                                        S = 4'b1010;
                                        SEL = {1'b1, 1'b1, 1'b0, 1'b0};
                                        SELCTL = W[1];
                                    end
                                    EEI = 0;
                                    fflag = 0;
                                    jjmp_flag = 0;
                                end
                                ccount = 0;
                            end
                        end
                    endcase
                end
            endcase
        end
    end
endmodule
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
	reg [2:0] fflag;
    reg [2:0] ccount;
    reg EI,EEI;
    reg SST0;
    reg ST0,MIDDLE;
    reg [2:0] count;
    reg [2:0] flag;
    reg [7:0] SELF_IR,SELF_PC,SELF_R0;
    reg [7:0] SSELF_IR,SSELF_PC,SSELF_R0;
    reg [1:0] SELF_C,SELF_Z,jmp_flag,iret_flag;
    reg [1:0] SSELF_C,SSELF_Z,jjmp_flag,iiret_flag;
    always @(negedge T3, negedge CLR)
    begin
        if (!CLR) begin
            ST0 = 0;
            flag = 0;
            count = 0;
            SELF_IR = 0;
            SELF_PC = 0;
            SELF_R0 = 0;
            SELF_Z = 0;
            SELF_C = 0;
            jmp_flag = 0;
            iret_flag = 0;
            EI = 1;
        end
        else if (!T3) begin
            flag = fflag;
            count = ccount;
            SELF_IR = SSELF_IR;
            SELF_PC = SSELF_PC;
            SELF_R0 = SSELF_R0;
            SELF_C = SSELF_C;
            SELF_Z = SSELF_Z;
            jmp_flag = jjmp_flag;
            iret_flag = iiret_flag;
            EI = EEI;
            if (SST0 == 1'b1) begin
                ST0 = SST0; // ¨¦????¡è??¡¦SST0 == 1¨¦????¡è??¡¦¨¦????¡è??¡¦¨¦????¡è??¡¦ST0    = 1
            end
            else if (SW == 3'b100 && ST0 && W[2])
                ST0 = 0;
        end
    end

    always @(CLR, PULSE) // ?¨¦???¡ì???¡è??¡¦¨¦????¡è??¡¦???¨¦????¡è??¡¦T3???¨¦????¡è??¡¦???¨¦????¡è??¡¦¨¦????¡è??¡¦¨¦????¡è??¡¦¨¦????¡è??¡¦???
    begin
        {LDC, LDZ, CIN, M, ABUS, DRW, PCINC, LPC, LAR, PCADD, ARINC, SELCTL, MEMW, STOP, LIR, SBUS, MBUS, SHORT, LONG, S, SEL, SST0} = 0;

        if (!CLR) begin
            ccount = 0;
            fflag = 0;
            EEI = 1;
            SSELF_IR = 0;
            SSELF_PC = 0;
            SSELF_R0 = 0;
            SSELF_C = 0;
            SSELF_Z = 0;
            iiret_flag = 0;
            jjmp_flag = 0;
        end
        else begin
            case (SW)
                3'b001: begin //???¨¦???????¡§¨¦????¡è???
                    LAR    = W[1] && !ST0;
                    MEMW   = W[1] && ST0;
                    ARINC  = W[1] && ST0;
                    SBUS   = W[1];
                    STOP   = W[1];
                    SHORT  = W[1];
                    SELCTL = W[1];
                    SST0   = W[1];
                end
                3'b010: begin //¨¦????¡è??¡¦¨¦???????¡§¨¦????¡è???
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
                3'b100: begin //???¨¦??????????¡¦¨¦????¡è??¡¦
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
                    // ¨¦????¡è??¡¦?¡ì???¡ì¨¦????¡è??¡¦SW == 000¨¦????¡è??¡¦¨¦????¡è??¡¦¨¦???-->
                    case (flag)
                        // ??????¨¦????¡è??¡¦??¡ì¨¦????¡è??¡¦???¨¦????¡è???
                        3'b000: begin
                            if (PULSE && EI) begin
                                EEI = !W[1];
                                SBUS = W[1];
                                LPC = W[1];
                                SHORT = W[1];
                            end
                            else begin
                                LIR   = W[1];
                                PCINC = W[1];
                                SSELF_PC = SELF_PC + (EI && W[1]);
                                case (IR)
                                    4'b0001,4'b0010,4'b0100,
                                    4'b0011,4'b1100,4'b1101:begin
                                        case (IR)
                                            4'b0001:S = 4'b1001;//ADD
                                            4'b0010:S = 4'b0110;//SUB
                                            4'b0100:S = 4'b0000;//INC
                                            4'b0011:S = 4'b1011;//AND
                                            4'b1100:S = 4'b1110;//OR
                                            4'b1101:S = 4'b0110;//XOR
                                            default:S = 4'b0000;
                                        endcase
                                        CIN = W[2] && (IR == 4'b0001);
                                        ABUS = W[2];
                                        DRW = W[2];
                                        LDZ = W[2];
                                        LDC = W[2] && (IR<4'b0101 && IR!=4'b0011);
                                        SSELF_C = (IR<4'b0101 && IR!=4'b0011) ? 0 : SELF_C;
                                        M = W[2] && !(IR<4'b0101 && IR!=4'b0011);
                                        SSELF_Z = 0;
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
                                    4'b0111,4'b1000,4'b1001,4'b1011: begin // JC && JZ && JMP && IRET
                                        if ((IR==4'b0111 && ((SELF_C==0 && C) || SELF_C==2'b11))
                                        || (IR==4'b1000 && ((SELF_Z==0 && Z) || SELF_Z==2'b11))
                                        || IR>8) begin
                                            PCADD = W[2] && (IR<=8);
                                            ABUS = (EI || IR>8) && W[2];
                                            SEL[3] = EI && !W[2];
                                            SEL[2] = EI && !W[2];
                                            S = 4'b1100;
                                            SELCTL = (EI || IR>8) && W[2];
                                            CIN = (EI || IR>8) && W[2];
                                            DRW = (EI || IR>8) && W[2];
                                            LDZ = (EI || IR>8) && W[2];
                                            LDC = (EI || IR>8) && W[2];
                                            fflag = (EI || IR>8) && W[2];
                                            case(IR)
                                                4'b1001:jjmp_flag = W[2];
                                                4'b1010:iiret_flag = W[2];
                                            endcase
                                            SSELF_C = (!SELF_C && (EI || IR>8) && W[2]) ? {1'b1,C} : SELF_C;
                                            SSELF_Z = (!SELF_Z && (EI || IR>8) && W[2]) ? {1'b1,Z} : SELF_Z;
                                            ccount = 1;
                                        end
                                    end
                                    4'b1010: begin // OUT
                                        M    = W[2];
                                        S    = 4'b1010;
                                        ABUS = W[2];
                                    end
                                    4'b1110:STOP = W[2];// STP
                                    default: S = 4'b0000;
                                endcase
                                // <---SW == 000¨¦????¡è??¡¦¨¦????¡è??¡¦¨¦??????????¡¦¨¦????¡è??¡¦¨¦????¡è??¡¦
                            end
                        end
                        // flag==1 ¨¦????¡è??¡¦SELF_R0¨¦??????????¡¦¨¦????¡è??¡¦¨¦????¡è??¡¦???¨¦????¡è??¡¦¨¦????¡è??¡¦¨¦????¡è??¡¦¨¦????¡è??¡¦¨¦????¡è??¡¦¨¦????¡è???
                        // flag==3 ¨¦????¡è??¡¦SELF_R0¨¦??????????¡¦¨¦????¡è??¡¦¨¦????¡è??¡¦???¨¦????¡è??¡¦¨¦????¡è??¡¦¨¦????¡è??¡¦
                        // flag==2 ¨¦????¡è??¡¦SELF_PC¨¦????¡è??¡¦???¨¦????¡è??¡¦SELF_R0¨¦??????????¡¦¨¦????¡è???
                        // flag==4 ¨¦?????¨¦????¡¦SELF_R0¨¦????¡è??¡¦?¡ì????
                        // flag==5 IRET¨¦????¡è??¡¦SELF_PC¨¦????¡è??¡¦¨¦????¡è??¡¦PC
                        3'b001,3'b010,3'b011,3'b100,3'b101: begin
                            ccount = count + W[1];
                            if (W[1])
								if (flag == 1) SSELF_R0 = (SELF_R0 << 1) + C;
								else if (flag== 3)SSELF_IR = (SELF_IR << 1) + C;

                            if (flag==1 || flag==3)MIDDLE = W[1];
                            else MIDDLE = (W[1] || (W[2] &&
                            ((flag == 4) ? SELF_R0[7-count] : SELF_PC[7-count])));

                            SELCTL = (count >= 8) || MIDDLE;
                            SEL[3] = (count < 8) && !MIDDLE;
                            SEL[2] = (count < 8) && !MIDDLE;
                            S = (W[1])?4'b1100:4'b0000;
                            ABUS = (count < 8) && MIDDLE;
                            DRW = (count < 8) && MIDDLE;
                            LDZ = (count < 8) && MIDDLE;
                            LDC = (count < 8) && MIDDLE;
                            CIN = (count < 8) && W[1];

                            if (count>=8)
                            begin
                                case (flag)
                                    3'b010:begin
                                        SEL[3] = W[1];
                                        SEL[2] = W[1];
                                        SEL[1] = !W[1];
                                        SEL[0] = !W[1];
                                        M = W[1];
                                        S=(W[1])?4'b1010:4'b1100;
                                        ABUS =!W[2];
                                        LAR = W[1];
                                        MBUS = W[2];
                                        DRW = !W[1];
                                        LONG = W[2];
                                        LDZ = W[3];
                                        LDC = W[3];
                                        CIN = W[3];
                                        fflag = (W[3])?3:flag;
                                        ccount = (W[3])?0:count;
                                    end
                                    3'b101:begin
                                        ccount = 0;
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
                                        ccount = 0;
                                        SHORT = W[1];
                                        EEI = 1;
                                        iiret_flag = 0;
                                        jjmp_flag = 0;
                                        fflag = 0;
                                    end
                                    3'b001:begin
                                        SHORT = W[1];
                                        fflag = (iret_flag)?5:2;
                                        ccount = 0;
                                    end
                                    3'b011:begin
                                        SHORT = W[1];
                                        fflag = (jmp_flag == 1)?6:4;
                                        case (jmp_flag)
                                            0:SSELF_PC = SELF_PC + SELF_IR[3:0] - (((SELF_IR[3])?16:0));
                                            2:SSELF_PC = SELF_IR;
                                        endcase
                                        ccount = 0;
                                    end
                                endcase

                            end
                        end
                        3'b110://¨¦????¡è??¡¦Rx¨¦????¡è??¡¦¨¦????¡è??¡¦R0¨¦????¡è??¡¦???¨¦???????¡è??¡¦SELF_PC¨¦????¡è??¡¦??????SELF_R0(Rx=R0)
                        begin
                            SELCTL = (W[1] || W[2]) && (SELF_IR&4'hc);
                            SEL[3] = !(W[1] || W[2]) && (SELF_IR&4'hc);
                            SEL[2] = !(W[1] || W[2]) && (SELF_IR&4'hc);
                            SEL[1] = SELF_IR[3] && (SELF_IR&4'hc);
                            SEL[0] = SELF_IR[2] && (SELF_IR&4'hc);
                            S = (W[1])?4'b1010:4'b1100;
                            ABUS = (W[1] || W[2])&& (SELF_IR&4'hc);
                            DRW = (W[1] || W[2])&& (SELF_IR&4'hc);
                            M = W[1] && (SELF_IR&4'hc);
                            LDZ = W[2]&& (SELF_IR&4'hc);
                            LDC = W[2]&& (SELF_IR&4'hc);
                            CIN = W[2]&& (SELF_IR&4'hc);
                            SHORT = W[1] && !(SELF_IR&4'hc);
                            jjmp_flag = (SELF_IR&4'hc && !W[2]) ? jmp_flag : 2;
                            fflag = (SELF_IR&4'hc && !W[2]) ? flag : ((SELF_IR&4'hc) ? 3 : 4);;
                            SSELF_PC = (!(SELF_IR&4'hc)) ? SELF_R0 : SELF_PC;
                        end
                    endcase
                end
                // default:
            endcase
        end
    end
endmodule
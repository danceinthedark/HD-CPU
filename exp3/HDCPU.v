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
    output reg [2:0] fflag,
    output reg [2:0] ccount,
    output reg EI,
    output reg EEI,
    output reg[2:0] count,
    output reg [2:0] flag,
    output reg [7:0] SELF_R0
    );
    reg SST0;
    reg ST0;
    reg[1:0] iiret_flag,iret_flag;
    
    reg [7:0] SELF_IR,SELF_PC;//,SELF_R0;
    reg [7:0] SSELF_IR,SSELF_PC,SSELF_R0;
    reg [1:0] SELF_C,SELF_Z,jmp_flag;
    reg [1:0] SSELF_C,SSELF_Z,jjmp_flag;
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
                ST0 = SST0; // ????????????SST0 == 1????????????????????????????????????ST0    = 1
            end
            else if (SW == 3'b100 && ST0 && W[2])
                ST0 = 0;
        end
    end

    always @(CLR, PULSE) // ????????????????????????????????????????????T3?????????????????????????????????????????????????????????????????????
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
                3'b001: begin //?????????????????????????
                    LAR    = W[1] && !ST0;
                    MEMW   = W[1] && ST0;
                    ARINC  = W[1] && ST0;
                    SBUS   = W[1];
                    STOP   = W[1];
                    SHORT  = W[1];
                    SELCTL = W[1];
                    SST0   = W[1];
                end
                3'b010: begin //??????????????????????????????????
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
                3'b100: begin //?????????????????????????????
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
                    // ??????????????????????????????SW == 000?????????????????????????????-->
                    case (flag)
                        // ??????????????????????????????????????????????
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
                                        S[3] = IR[7] ^ IR[4];
                                        S[2] = IR[7] || (IR[5] && !IR[4]);
                                        S[1] = IR[7] || IR[5];
                                        S[0] = !IR[7] && IR[4];
                                        CIN = W[2] && (IR == 4'b0001);
                                        ABUS = W[2];
                                        DRW = W[2];
                                        LDZ = W[2];
                                        LDC = W[2] && (!IR[7] && (!IR[5]||!IR[4]));
                                        SSELF_C = ((!IR[7] && (!IR[5]||!IR[4]))) ? 0 : SELF_C;
                                        M = W[2] && !(!IR[7] && (!IR[5]||!IR[4]));
                                        SSELF_Z = 0;
                                    end

                                    4'b0101: begin // LD
                                        M    = W[2];
                                        S[2]=0;
                                        S[1]=0;
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
                                // <---SW == 000??????????????????????????????????????????????????????????????
                            end
                        end
                        // flag==1 ????????????SELF_R0????????????????????????????????????????????????????????????????????????????????????????????????????????????????
                        // flag==3 ????????????SELF_R0?????????????????????????????????????????????????????????????????????????????
                        // flag==2 ????????????SELF_PC???????????????????????????SELF_R0?????????????????????????
                        // flag==4 ???????????????SELF_R0???????????????????
                        // flag==5 IRET????????????SELF_PC????????????????????????PC
                        3'b001,3'b010,3'b011,3'b100,3'b101: begin
                            ccount = (W[3])?1:count+W[1];
                            if (W[1])
								if (!flag[2]&&!flag[1]&&flag[0]) SSELF_R0 = (SELF_R0 << 1) | C;
								else if (!flag[2]&&flag[1]&&flag[0])SSELF_IR = (SELF_IR << 1) | C;
							//software judge
							if((flag[2] && !flag[1] && !flag[0] && count[2] && count[1] && count[0] && W[1]))
							EEI=1;
							if(flag[2]&&!flag[1]&&!flag[0] && count[2] && count[1] && count[0] && W[1])
							begin
							iiret_flag = 0;
							jjmp_flag = 0;
							end
							if(!flag[2]&&flag[1]&&flag[0] && count[2]&&count[1]&&count[0])
							begin
							case (jmp_flag)
							0:SSELF_PC = SELF_PC + SELF_IR[3:0] - (SELF_IR[3]?16:0);
							2:SSELF_PC = SELF_IR;
							endcase
							end
							SELCTL=!(count[2]&&count[1]&&count[0]&&((!flag[2]&&!flag[1]&&flag[0]) || (!flag[2] && flag[1] && flag[0]) || (flag[2] && !flag[1] && !flag[0])));								
							S[3] = ((!count[2] || !count[1] || !count[0] && W[1]) ||
									(count[2] && count[1] && count[0] &&(
									(!flag[2] && flag[1] && !flag[0] && (W[1] || W[3])) || 
									(flag[2] && !flag[1] && flag[0] && W[1])))
									);
							S[2]=(
								(!count[2] || !count[1] || !count[0] && W[1]) ||
								(count[2] && count[1] && count[0] && !flag[2] && flag[1] && !flag[0] && W[3])
								);
							S[1]=((count[2] && count[1] && count[0]) &&(
								(!flag[2] && flag[1] && !flag[0] && W[1]) || (flag[2] && !flag[1] && flag[0] && W[1]))
								);
							S[0] = 0;
							ABUS=!(
								(!flag[2] && !flag[1] && flag[0] && count[2] && count[1] && count[0] && W[1]) ||
								(!flag[2] && flag[1] && !flag[0] && count[2] && count[1] && count[0] && W[2]) ||
								(!flag[2] && flag[1] && flag[0]  && count[2] && count[1] && count[0] && W[1]) ||
								(flag[2] && !flag[1] && !flag[0] && count[2] && count[1] && count[0] && W[1])
								);
							DRW=!(
								(count[2] && count[1] && count[0] && W[1])
								);
							LDZ=!(
								(count[2] && count[1] && count[0] && W[1]) || 
								(!flag[2] && flag[1] && !flag[0] && count[2] && count[1] && count[0] && W[2])
								);
							LDC=!(
								(count[2] && count[1] && count[0] && W[1]) || 
								(!flag[2] && flag[1] && !flag[0] && count[2] && count[1] && count[0] && W[2])
								);
							CIN=(
								(!count[2] || !count[1] || !count[0] && W[1]) ||  
								(!flag[2] && flag[1] && !flag[0] && count[2] && count[1] && count[0] && W[3])
								);
							SHORT=(W[1]&&(
								(!flag[2] && flag[0]) || 
								(!flag[2] && flag[1] && !flag[0] && (!count[2] || !count[1] || !count[0]) && !(((!flag[2] && flag[1] && !flag[0]) || (flag[2] && !flag[1] && !flag[0]))?SELF_PC[7-count]:SELF_R0[7-count])) ||
								(flag[2] && !flag[1] && ((count[2] && count[1] && count[0] && W[1]) || (!(((!flag[2] && flag[1] && !flag[0]) || (flag[2] && !flag[1] && !flag[0]))?SELF_PC[7-count]:SELF_R0[7-count])) ))
								));
							if((count[2] && count[1] && count[0] && (flag[2]||!flag[1]||flag[0]) && W[1]) || (count[2] & count[1] && count[0] && !flag[2]&&flag[1]&&!flag[0]&&W[3]))
							begin
							fflag[2]=(
									(!flag[2] && !flag[1] && flag[0] && iret_flag && W[1]) || 
									(!flag[2] && flag[1] && flag[0] && W[1]) || 
									(flag[2] && !flag[1] && flag[0] && W[1])
									);
							fflag[1] =(
									(!flag[2] && !flag[1] && flag[0] && !iret_flag && W[1]) || 
									(!flag[2] && flag[1] && !flag[0] && W[3]) || 
									(!flag[2] && flag[1] && flag[0] && jmp_flag && W[1])
									);
							fflag[0] = (
									(!flag[2] && !flag[1] && flag[0] && iret_flag && W[1]) || 
									(!flag[2] && flag[1] && !flag[0] && W[3])
									);
							end
							LONG=(
							(!flag[2] && flag[1] && !flag[0] && count[2] && count[1] && count[0] && W[2])
							);
							M=(
							(!flag[2] && flag[1] && !flag[0] && count[2] && count[1] && count[0] && W[1]) ||
							(flag[2] && !flag[1] && flag[0]  && count[2] && count[1] && count[0] && W[1])
							);
							LAR
							=(
							(!flag[2] && flag[1] && !flag[0] && count[2] && count[1] && count[0] && W[1])
							);
							MBUS
							=(
							(!flag[2] && flag[1] && !flag[0] && count[2] && count[1] && count[0] && W[2])
							);
							LPC
							=(
							(flag[2] && !flag[1] && flag[0] && count[2] && count[1] && count[0] && W[1])
							);				
                        end
                        3'b110://????????????Rx????????????????????????R0??????????????????????????????SELF_PC??????????????????SELF_R0(Rx=R0)
                        begin
							if(SELF_IR[3] || SELF_IR[2])
							begin
							SELCTL = 1;
							ABUS = 1;
							DRW = 1;
							M = W[1];
							LDZ = W[2];
							LDC = W[2];
							CIN = W[2];
							jjmp_flag = (!W[2]) ? jmp_flag : 2;
							fflag = (W[1]) ? flag : 3;
							end
							else begin
							fflag = 4;
							SSELF_PC = SELF_R0;
							end
                            SEL[1:0] = SELF_IR[3:2];
                            S[3] = 1;S[2] = W[1];
                            S[1] = !W[1];S[0] = 0; 
                        end
                    endcase
                end
                // default:
            endcase
        end
    end
endmodule
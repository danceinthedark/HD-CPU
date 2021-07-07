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

    reg EI,EEI;
    reg SST0;
    reg ST0,MIDDLE,jmp_flag,jjmp_flag;
    reg [3:0] count,ccount;
    reg [2:0] flag,fflag;
    reg [7:0] SELF_IR,SELF_R0;
    reg [7:0] SSELF_IR,SSELF_R0;
    always @(negedge T3, negedge CLR)
    begin
        if (!CLR) begin
            ST0 = 0;
            flag = 0;
            SELF_R0 = 0;
            SELF_IR = 0;
            count = 0;
            jmp_flag = 0;
            EI = 0;
        end
        else if (!T3) begin
            EI = EEI;
            flag = fflag;
            count = ccount;
            SELF_IR = SSELF_IR;
            SSELF_R0 = SSELF_IR;
            jmp_flag = jjmp_flag;
            if (SST0 == 1'b1) begin
                ST0 = SST0; // ��SST0 == 1������ST0    = 1
            end
            else if (SW == 3'b100 && ST0 && W[2])
                ST0 = 0;
        end
    end

    always @(CLR, PULSE) // ?�Ƿ���Ҫ��T3ר��д��������ʽ
    begin
        {LDC, LDZ, CIN, M, ABUS, DRW, PCINC, LPC, LAR, PCADD, ARINC, SELCTL, MEMW, STOP, LIR, SBUS, MBUS, SHORT, LONG, S, SEL, SST0} = 0;

        if (!CLR) begin
            ccount = 0;
            fflag = 0;
            EEI = 0;
            SSELF_IR = 0;
            SSELF_R0 = 0;
        end
        else begin
            case (SW)
                3'b001: begin //д�洢��
                    LAR    = W[1] && !ST0;
                    MEMW   = W[1] && ST0;
                    ARINC  = W[1] && ST0;
                    SBUS   = W[1];
                    STOP   = W[1];
                    SHORT  = W[1];
                    SELCTL = W[1];
                    SST0   = W[1];
                end
                3'b010: begin //���洢��
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
                3'b100: begin //д�Ĵ���
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
                    case (flag)
                        3'b000: begin
                            if (PULSE && !EI) begin
                                EEI = 1;
                                SBUS = W[1];
                                LPC = W[1];
                                SHORT = W[1];
                                STOP = W[1];
                            end
                            else begin
                                LIR   = W[1];
                                PCINC = W[1];
                                if (W[1])begin
                                    if (!EI)begin
                                        SELCTL = 1;
                                        SEL[3] = 1;
                                        SEL[2] = 0;
                                        S= 4'b0000;
                                        ABUS = 1;
                                        DRW = 1;
                                    end
                                end
                                else
                                begin
                                    case (IR)
                                        4'b0001,4'b0010: begin // ADD & SUB
                                            S    = (IR==4'b0001) ? 4'b1001 : 4'b0110;
                                            CIN  = W[2] && (IR == 4'b0001);
                                            ABUS = W[2];
                                            DRW  = W[2];
                                            LDZ  = W[2];
                                            LDC  = W[2];
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
                                        4'b0111,4'b1000: begin // JC && JZ
                                            PCADD = W[2];
                                            if(!EI) begin
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
                                                ccount = 1;
                                            end
                                        end
                                        4'b1001: begin // JMP
                                            ABUS = W[2];
                                            SEL[3] = 0;
                                            SEL[2] = 0;
                                            S = 4'b1100;
                                            SELCTL = W[2];
                                            CIN = W[2];
                                            DRW = W[2];
                                            LDZ = W[2];
                                            LDC = W[2];
                                            jjmp_flag = W[2];
                                            fflag = W[2];
                                            ccount = 1;
                                        end
                                        4'b1011://IRET
                                        begin
                                            ABUS = W[2];
                                            S = 4'b1010;
                                            M = W[2];
                                            SELCTL = W[2];
                                            SEL[1] = 1;
                                            SEL[0] = 1;
                                            LPC = W[2];
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
                                end
                                // <---SW == 000�����ִ�����
                            end
                        end
                        //flag=1 ����R0������
                        //flag=2 ����ָ�R0���ٴ�R0��ȡ��������
                        3'b001,3'b010: begin
                            if (flag==1) SSELF_R0 = (SELF_R0 << 1) + C;
                            else SSELF_IR = (SELF_R0 << 1) + C;
                            if (count !=8) begin
                                ccount = count + 1;
                                SELCTL = W[1];
                                SEL[3] = !W[1];
                                SEL[2] = !W[1];
                                S = 4'b1100;
                                ABUS = W[1];
                                DRW = W[1];
                                LDZ = W[1];
                                LDC = W[1];
                                CIN = W[1];
                                SHORT = W[1];
                            end
                            else begin
                                if (flag==1)begin
                                    ABUS = !W[2];
                                    S = (W[1])?4'b1010:4'b1100;
                                    M = W[1];
                                    SELCTL = 1;
                                    SEL[3] = 0;
                                    SEL[2] = 0;
                                    SEL[1] = 1;
                                    SEL[0] = 1;
                                    LAR = W[1];

                                    MBUS = W[2];  
                                    DRW = W[2];
                                    LONG = W[2];

                                    DRW = W[3];
                                    LDZ = W[3];
                                    LDC = W[3];
                                    CIN = W[3];

                                    if (W[3])begin
                                        fflag = 2;
                                        ccount = 1;
                                    end
                                end
                                else
                                begin
                                    if (jmp_flag)begin
                                        SHORT = W[1];
                                        SELCTL = W[1];
                                        SEL[3] = 1;
                                        SEL[2] = 1;
                                        SEL[1] = SELF_IR[3];
                                        SEL[0] = SELF_IR[2];
                                        S = 4'b1010;
                                        ABUS = W[1];
                                        DRW = W[1];
                                        M = W[1];
                                        fflag = 4;
                                    end
                                    else begin
                                        SHORT = W[1];
                                        fflag = 3;
                                    end
                                    ccount = 0;
                                end
                            end
                        end
                        //flag=3 ��IR�ĺ���λ����R0��Ȼ��PC(R3)+=R0
                        //flag=4 �ָ�R0
                        3'b011,3'b100: begin
                            if (count !=8) begin
                                ccount = count + W[1];
                                SELCTL = 1;
                                SEL[3] = 0;
                                SEL[2] = 0;
                                S = (W[1])?4'b1100:4'b0000;
                                ABUS = 1;
                                DRW = 1;
                                CIN = W[1];
                                if (!((flag==3 && count>=4 && SELF_IR[7-count]) || 
                                    (flag==4 && SELF_R0[7-count]))) SHORT=W[1];
                            end
                            else begin
                                SHORT = W[1];
                                ccount = 0;
                                if (flag==3)begin
                                    SELCTL = W[1];
                                    SEL[3] = 1;
                                    SEL[2] = 1;
                                    SEL[1] = 0;
                                    SEL[0] = 0;
                                    S = 4'b1001;
                                    CIN = W[1];
                                    ABUS = W[1];
                                    DRW = W[1];
                                    fflag = 4;
                                end
                                else begin
                                    jjmp_flag = 0;
                                    EEI = 0;
                                    fflag = 0;
                                end
                            end
                        end
                    endcase
                end
                // default:
            endcase
        end
    end
endmodule
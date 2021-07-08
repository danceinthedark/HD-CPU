/*
 测试功能：数据从硬件到软件的转换
 */
module HDCPU(input CLR,
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
            output reg [7:0] num,
            output reg setNum,
            output reg [3:0] count,
            output reg countAdd,
            output reg countCLR,
            output reg ST1,
            output reg SST1);
    
    reg ST0  = 0;
    reg SST0 = 0;
    
    always @(posedge T3, negedge CLR)
    begin
      if(!CLR)begin
        if(SW==3'b111)begin
          //初始化值
          num<=8'b10101010;
        end
        else begin
          num <= num;
        end
    end
    else if(T3) begin
      if(setNum)begin
            num[8-count]=C;
      end
    end
    end
    
    
    
    always @(negedge T3, negedge CLR)
    begin
        if (!CLR) begin
            ST0 <= 0;
            count<=0;
        end
        else if (!T3) begin
        if (SST0 == 1'b1)
            ST0 = SST0; // 有SST0 == 1就立刻ST0 = 1
        else if (SW == 3'b100 && ST0 && W[2])
            ST0      = 0;
            else ST0 = ST0;
        
        if (countAdd == 1'b1)begin
            count      = count+1;
        end
        else if(countCLR)begin
            count = 0;
        end
        else begin
            count = count;
        end
        
        end

    end
        
        always @(W, CLR)
        begin
            {LDC, LDZ, CIN, M, ABUS, DRW, PCINC, LPC, LAR, PCADD, ARINC, SELCTL, MEMW, STOP, LIR, SBUS, MBUS, SHORT, LONG, S, SEL, SST0,setNum,countAdd,countCLR} = 0;
            if (CLR == 0)begin
                
            end
            
            else begin
            case (SW)
                3'b001: begin //写存储器
                    LAR    <= W[1] && !ST0;
                    MEMW   <= W[1] && ST0;
                    ARINC  <= W[1] && ST0;
                    SBUS   <= W[1];
                    STOP   <= W[1];
                    SHORT  <= W[1];
                    SELCTL <= W[1];
                    SST0   <= W[1];
                end
                3'b010: begin //写存储器
                    SBUS   <= W[1]&&!ST0;
                    LAR    <= W[1]&&!ST0;
                    SST0   <= W[1]&&!ST0;
                    MBUS   <= W[1]&&ST0;
                    ARINC  <= W[1]&&ST0;
                    STOP   <= W[1];
                    SHORT  <= W[1];
                    SELCTL <= W[1];
                end
                3'b011: begin //读寄存器
                    SELCTL <= W[1] || W[2];
                    STOP   <= W[1] || W[2];
                    SEL[3] <= W[2];
                    SEL[2] <= 0;
                    SEL[1] <= W[2];
                    SEL[0] <= W[1] || W[2];
                end
                3'b100: begin //写寄存器
                    
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
                3'b101:begin //显示内部变量的值
                    {LIR,STOP,MEMW,LAR,ARINC,LPC,PCINC,DRW} = num;
                end
                3'b110:begin //将R3的值存入内部
                    SELCTL   <= W[1]&&(count <= 7);
                    SEL[3]   <= W[1]&&(count <= 7);
                    SEL[2]   <= W[1]&&(count <= 7);
                    SEL[1]   <= W[1]&&(count <= 7);
                    SEL[0]   <= W[1]&&(count <= 7);
                    S        <= {W[1],W[1],1'b0,1'b0};
                    ABUS     <= W[1]&&(count <= 7);
                    DRW      <= W[1]&&(count <= 7);
                    LDZ      <= W[1]&&(count <= 7);
                    LDC      <= W[1]&&(count <= 7);
                    CIN      <= W[1]&&(count <= 7);
                    SHORT    <= W[1];
                    countAdd <= W[1]&&(count <= 7);
                    countCLR <= W[1]&&(count==8);
                    setNum  <=W[1]&&((1<=count)&&(count<=8));
                    STOP    <=W[1]&&(count==8);

                end
                3'b111:begin
                    
                end
                3'b000: //运行程序
                if (ST0 == 0)begin
                    LPC   = W[1];
                    SBUS  = W[1];
                    SST0  = W[1];
                    SHORT = W[1];
                    STOP  = W[1];
                end
                else
                begin
                    // 开始执行SW == 000的情况--->
                    LIR   = W[1]&&(IR!=4'b1010||(count==8));
                    PCINC = W[1]&&(IR!=4'b1010||(count==8));
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
                            S    = 4'b0000;
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
                            M    = W[2] ||W[3];
                            S    = {1'b1,W[2],1'b1,W[2]};
                            ABUS = W[2] || W[3];
                            LAR  = W[2];
                            LONG = W[2];
                            MEMW = W[3];
                        end
                        4'b0111: // JC
                        if (C == 1) PCADD = W[2];
                        4'b1000: // JZ
                        if (Z == 1) PCADD = W[2];
                        4'b1001: begin // JMP
                            M    = W[2];
                            S    = 4'b1111;
                            ABUS = W[2];
                            LPC  = W[2];
                        end
                        4'b1110: begin // STP
                            STOP = W[2];
                        end
                        // 额外指令
                        4'b1010: begin //把num输入到双操作数寄存器(A)
                          S<={W[2],W[2],2'b00};
                          ABUS<=W[2]&&(count<=7);
                          DRW<=W[2]&&(count<=7);
                          CIN<=!(W[2]&&num[7-count]);
                          STOP<=W[2]&&(count==8);
                          countAdd<=W[2]&&(count<=7);
                          countCLR<=W[1]&&(count==8);
                          SHORT<=(count==8);
                        end
                        4'b1011: begin  //把双操作数存到num (B)
                        // S        <= {W[2],W[2],1'b0,1'b0};
                        // ABUS     <= W[2]&&(count <= 7);
                        // DRW      <= W[2]&&(count <= 7);
                        // LDZ      <= W[2]&&(count <= 7);
                        // LDC      <= W[2]&&(count <= 7);
                        // CIN      <= W[2]&&(count <= 7);
                        // countAdd <= W[2]&&(count <= 7);
                        // countCLR <= W[2]&&(count==8);
                        // setNum  <=W[2]&&((1<=count)&&(count<=8));
                        // STOP    <=W[2]&&(count==8);
               
                        end
                        4'b1100: begin 
            
                        end
                        default: S = 4'b0000;
                    endcase
                    // <---SW == 000的情况执行完毕
                end
                // default:
            endcase
        end
    end
endmodule

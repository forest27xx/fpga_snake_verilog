
/*******************************************************
 * FPGA-Based 贪吃蛇
  * School:CSU
 * Class: 自动化 T2101
 * Students: 刘凯-8210211913, 吴森林-8212211224
 * Instructor: 罗旗舞
 *******************************************************/
//红外线解码模块
//最开始用的是持续高电平，导致按键冲突，比如按下左，其他就按不了
module decode_rcv(
    input sys_clk,
    input sys_rst_n,
    input [7:0]data,
    output reg [6:0]key2,
    output reg [1:0]diff
);

reg [12:0] counter; // 
reg pulse_start; // 标记是否开始计数

always @(posedge sys_clk or negedge sys_rst_n) begin
    if (!sys_rst_n) begin
        key2 <= 7'b0;
        diff<=1;
        counter <= 0;
        pulse_start <= 0;
    end else begin
        // 检测data并启动脉冲
        if (pulse_start == 0) begin
            case (data)
                8'h46: if(key2==7'b0000001) begin key2<=0; end  else begin key2 <= 7'b0000001; pulse_start <= 1; end//注意红外线会发射重复码，需要屏蔽
                8'h15: if(key2==7'b0000010) begin key2<=0; end  else begin key2 <= 7'b0000010; pulse_start <= 1; end
                8'h44: if(key2==7'b0000100) begin key2<=0; end  else begin key2 <= 7'b0000100; pulse_start <= 1; end
                8'h43: if(key2==7'b0001000) begin key2<=0; end  else begin key2 <= 7'b0001000; pulse_start <= 1; end
                8'h42:  begin key2 <= 7'b0010000; pulse_start <= 1; end
                8'h4a:  begin key2 <= 7'b0100000; pulse_start <= 1; end
                8'h40:  begin key2 <= 7'b1000000; pulse_start <= 1; end
                8'h16:  begin diff <= 1; pulse_start <= 1; end
                8'h19:  begin diff <= 2; pulse_start <= 1; end
                8'hd:   begin diff <= 3; pulse_start <= 1; end
                
                default: begin key2 <= 7'b0; end
            endcase
        end
        
        // 计数保持脉冲
        if (pulse_start) begin//1ms脉冲
            if (counter < 5000) begin
                counter <= counter + 1;
            end else begin
                pulse_start <= 0;
                counter <= 0;
                key2 <= 7'b0; // 保持时间结束后清零key2
                diff<=diff;
            end
        end
    end
end

endmodule


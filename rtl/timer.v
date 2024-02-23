module timer(
			  input					clk,
			  input					rst,
			  input					tone_en,	
			  input					start_stop,
			  input			[2:0]	flag,//通过Beeper块中的flag标志位控制同步切换
			  
			  output	reg [127:0] out_1,
			  output	reg [127:0] out_2
			  );
reg [3:0] second_ge;
reg [3:0] second_shi;
reg [1:0] minute;
reg		  ss;
reg [2:0] flag_pre;//存储前一步的flag状态，与现在flag相比较，如果发生变化则切换计时
reg [23:0]count;
always@(posedge clk or negedge rst) begin
	if(!tone_en) begin
		count <= count; 
		end
	else if(!rst) begin
		minute <= 2'd1; 
		second_ge <= 1'b0;
		second_shi <= 1'b0;
		flag_pre <= 3'd1;
		count <= 1'b0; end
	else if(flag_pre != flag) begin
		case(flag)
			3'd1:	begin second_ge <= 1'b0;second_shi <= 1'b0;minute <= 2'd1; end
			3'd2:	begin second_ge <= 4'd2;second_shi <= 1'b0;minute <= 2'd2; end
			3'd3:	begin second_ge <= 4'd2;second_shi <= 4'd1;minute <= 2'd1; end
		endcase
		flag_pre <= flag;
		count <= 1'b0;
		end
	else if(!ss) begin
		count <= count; 
		end
	else if((count >= 24'd12000000)&&(second_ge == 4'd0)&&(second_shi != 4'd0)) begin
		second_ge <= 4'd9;
		second_shi <= second_shi - 1'b1;
		count <= 1'b0;
		end
	else if((count >= 24'd12000000)&&(second_ge == 4'd0)&&(second_shi == 4'd0)&&(minute !=2'd0)) begin
		second_ge <= 4'd9;
		second_shi <= 4'd5;
		minute <= minute - 1'b1;
		count <= 1'b0;
		end
	else if((count >= 24'd12000000)&&(second_ge == 4'd0)&&(second_shi == 4'd0)&&(minute ==2'd0)) begin
		second_ge <= 1'b0; 
		second_shi <= 1'b0;  
		minute <= 1'b0;
		count <= 1'b0; end
	else if(count >= 24'd12000000) begin
		count <= 1'b0;
		second_ge <= second_ge - 1'b1; end
	else begin count <= count + 1'b1; end
end

always@(posedge clk or negedge rst) begin
	if(!rst) begin		
		ss <= 1'b0; end
	else if(start_stop) begin
		ss <= ~ss;end
	else
		begin ss <= ss; end
end

always@(posedge clk) begin //将时间译码，显示到OLED上
	case(minute)
		2'd0:	begin out_1[127:120] <= 8'h21;
					  out_2[127:120] <= 8'h22; end
		2'd1:	begin out_1[127:120] <= 8'h23;
					  out_2[127:120] <= 8'h24; end
		2'd2:	begin out_1[127:120] <= 8'h25;
					  out_2[127:120] <= 8'h26; end
		default:begin out_1[127:120] <= 8'h00;
					  out_2[127:120] <= 8'h00; end
	endcase
	out_1[119:112] <= 8'h37;
	out_2[119:112] <= 8'h38;
	case(second_shi)
		4'd0:	begin out_1[111:104] <= 8'h21;
					  out_2[111:104] <= 8'h22; end
		4'd1:	begin out_1[111:104] <= 8'h23;
					  out_2[111:104] <= 8'h24; end
		4'd2:	begin out_1[111:104] <= 8'h25;
					  out_2[111:104] <= 8'h26; end
		4'd3:	begin out_1[111:104] <= 8'h27;
					  out_2[111:104] <= 8'h28; end
		4'd4:	begin out_1[111:104] <= 8'h29;
					  out_2[111:104] <= 8'h2a; end
		4'd5:	begin out_1[111:104] <= 8'h2b;
					  out_2[111:104] <= 8'h2c; end
		default:begin out_1[111:104] <= 8'h00;
					  out_2[111:104] <= 8'h00; end
	endcase
	case(second_ge)
		4'd0:	begin out_1[103:96] <= 8'h21;
					  out_2[103:96] <= 8'h22; end
		4'd1:	begin out_1[103:96] <= 8'h23;
					  out_2[103:96] <= 8'h24; end 
		4'd2:	begin out_1[103:96] <= 8'h25;
					  out_2[103:96] <= 8'h26; end
		4'd3:	begin out_1[103:96] <= 8'h27;
					  out_2[103:96] <= 8'h28; end
		4'd4:	begin out_1[103:96] <= 8'h29;
					  out_2[103:96] <= 8'h2a; end
		4'd5:	begin out_1[103:96] <= 8'h2b;
					  out_2[103:96] <= 8'h2c; end
		4'd6:	begin out_1[103:96] <= 8'h2d;
					  out_2[103:96] <= 8'h2e; end
		4'd7:	begin out_1[103:96] <= 8'h2f;
					  out_2[103:96] <= 8'h30; end
		4'd8:	begin out_1[103:96] <= 8'h31;
					  out_2[103:96] <= 8'h32; end
		4'd9:	begin out_1[103:96] <= 8'h33;
					  out_2[103:96] <= 8'h34; end
		default:begin out_1[103:96] <= 8'h00;
					  out_2[103:96] <= 8'h00; end
	endcase
	out_1[95:0] <= 96'h0000_0000_0000_0000_0000_0000;
	out_2[95:0] <= 96'h0000_0000_0000_0000_0000_0000;
end
endmodule
module Beeper 
(
input					clk_in,		//系统时钟
input					rst_n_in,	//系统复位，低有效
input					tone_en,	//蜂鸣器使能信号
input					chose_up,	//上一首
input					chose_down,	//下一首
input					start_stop, //暂停和开始
output	reg	[2:0]		flag,		//确定当前播放歌曲
output	reg				piano_out	//蜂鸣器控制输出
);
reg [4:0] note [553:0];//音符表
reg [4:0] beat [553:0];//节拍表，音符表和节拍表一一对应
reg [4:0] tone;		//蜂鸣器音节控制 
reg [4:0] tcon;		//蜂鸣器节拍控制
reg [9:0] num;      //用于控制节拍和音频
reg 	  s_s;		//暂停开始标志位
/*
无源蜂鸣器可以发出不同的音节，与蜂鸣器震动的频率（等于蜂鸣器控制信号的频率）相关，
为了让蜂鸣器控制信号产生不同的频率，我们使用计数器计数（分频）实现，不同的音节控制对应不同的计数终值（分频系数）
计数器根据计数终值计数并分频，产生蜂鸣器控制信号
*/
reg [15:0] time_end;//用于控制频率 
reg [27:0] time_delay;//用于控制时间
reg [25:0] cnt_delay;
reg [17:0] time_cnt;

//根据不同的音节控制，选择对应的计数终值（分频系数）
//低音1的频率为261.6Hz，蜂鸣器控制信号周期应为12MHz/261.6Hz = 45871.5，
//因为本设计中蜂鸣器控制信号是按计数器周期翻转的，所以几种终值 = 45871.5/2 = 22936
//需要计数22936个，计数范围为0 ~ (22936-1)，所以time_end = 22935
always@(tone) begin
	case(tone)
		5'd1:	time_end =	16'd22935;	//L1,
		5'd2:	time_end =	16'd20428;	//L2,
		5'd3:	time_end =	16'd18203;	//L3,
		5'd4:	time_end =	16'd17181;	//L4,
		5'd5:	time_end =	16'd15305;	//L5,
		5'd6:	time_end =	16'd13635;	//L6,
		5'd7:	time_end =	16'd12147;	//L7,
		5'd8:	time_end =	16'd11464;	//M1,
		5'd9:	time_end =	16'd10215;	//M2,
		5'd10:	time_end =	16'd9100;	//M3,
		5'd11:	time_end =	16'd8589;	//M4,
		5'd12:	time_end =	16'd7652;	//M5,
		5'd13:	time_end =	16'd6817;	//M6,
		5'd14:	time_end =	16'd6073;	//M7,
		5'd15:	time_end =	16'd5740;	//H1,
		5'd16:	time_end =	16'd5107;	//H2,
		5'd17:	time_end =	16'd4549;	//H3,
		5'd18:	time_end =	16'd4294;	//H4,
		5'd19:	time_end =	16'd3825;	//H5,
		5'd20:	time_end =	16'd3408;	//H6,
		5'd21:	time_end =	16'd3036;	//H7,
		default:time_end =	16'd65535;	
	endcase
end

always@(tcon or flag) begin
	if(flag == 3'd1) begin
	case(tcon)//奇迹再现，一小节四排，拍速为160拍/分钟
		5'd 1:	time_delay =	28'd1125000;//四分之一拍
		5'd 2:	time_delay =	28'd2250000;//半拍
		5'd 3:	time_delay =	28'd3375000;//四分之三拍
		5'd 4:	time_delay =	28'd4500000;//一拍
		5'd 6:	time_delay =	28'd6750000;//一拍半
		5'd 8:	time_delay =	28'd9000000;//两拍
		5'd12:	time_delay =	28'd1200000;//三拍
		5'd16:	time_delay =	28'd18000000;//四拍
		5'd24:	time_delay =	28'd24000000;//八拍
		default:time_delay =	28'd0;	
	endcase
end

else if(flag == 3'd2) begin
	case(tcon)//相思，一小节三拍，拍速为100拍/分钟
		5'd 1:	time_delay =	28'd1800000;//四分之一拍
		5'd 2:	time_delay =	28'd3600000;//半拍
		5'd 3:	time_delay =	28'd5400000;//四分之三拍
		5'd 4:	time_delay =	28'd7200000;//一拍
		5'd 6:	time_delay =	28'd10800000;//一拍半
		5'd 8:	time_delay =	28'd14400000;//两拍
		5'd12:	time_delay =	28'd21600000;//三拍
		5'd16:	time_delay =	28'd28800000;//四拍
		5'd24:	time_delay =	28'd57600000;//八拍
		default:time_delay =	28'd0;	
	endcase
end

else if(flag == 3'd3) begin
	case(tcon)//大鱼，一小节四拍，拍速为80拍/分钟
		5'd 1:	time_delay =	28'd2250000;//四分之一拍
		5'd 2:	time_delay =	28'd4500000;//半拍
		5'd 3:	time_delay =	28'd6750000;//四分之三拍
		5'd 4:	time_delay =	28'd9000000;//一拍
		5'd 6:	time_delay =	28'd13500000;//一拍半
		5'd 8:	time_delay =	28'd18000000;//两拍
		5'd12:	time_delay =	28'd27000000;//三拍
		5'd16:	time_delay =	28'd36000000;//四拍
		5'd24:	time_delay =	28'd72000000;//八拍
		default:time_delay =	28'd0;	
	endcase
end

end
		
//当蜂鸣器使能时，计数器按照计数终值（分频系数）计数
always@(posedge clk_in or negedge rst_n_in) begin
	if(!rst_n_in) begin
		time_cnt <= 1'b0;
	end else if(!tone_en) begin
		time_cnt <= 1'b0;
	end else if(!s_s) begin
		time_cnt <= 1'b0;
	end else if(time_cnt>=time_end) begin
		time_cnt <= 1'b0;
	end else begin
		time_cnt <= time_cnt + 1'b1;
	end
end
 
//根据计数器的周期，翻转蜂鸣器控制信号
always@(posedge clk_in or negedge rst_n_in) begin
	if(!rst_n_in) begin
		piano_out <= 1'b0;
	end else if(tone==5'd0) begin
		piano_out <= 1'b0;
	end else if(time_cnt==time_end) begin
		piano_out <= ~piano_out;	//蜂鸣器控制输出翻转，两次翻转为1Hz
	end else begin
		piano_out <= piano_out;
	end
end

always@(posedge clk_in or negedge rst_n_in) begin//音符和节拍控制
	if(!rst_n_in) begin
		tone <= 1'b0;
		tcon <= 1'b0;
	end else if(!tone_en) begin
		tone <= tone;
		tcon <= tcon;
	end else begin
		tone <= note[num];
		tcon <= beat[num];
	end
end	

always@(posedge clk_in or negedge rst_n_in) begin//用标志位控制暂停和开始
	if(!rst_n_in) begin		
		s_s <= 1'b0; end
	else if(start_stop) begin
		s_s <= ~s_s;end
	else
		begin s_s <= s_s; end
end

always@(posedge clk_in or negedge rst_n_in) begin	//时间控制,上一首或者下一首切换歌曲(手动或者自动)
	if(!rst_n_in) begin
		cnt_delay <= 1'b0; num <= 1'b0; flag <= 3'd1; end
	else if(!tone_en) begin
		cnt_delay <= cnt_delay; end
	else if(chose_up) begin
		case(flag)
			3'd1:	begin flag <= 3'd3;num <= 10'd435; end
			3'd2:	begin flag <= 3'd1;num <= 1'b0; end
			3'd3:	begin flag <= 3'd2;num <= 10'd215; end
			default:begin flag <= 3'd1;num <= 1'b0; end
		endcase
	end
	else if(chose_down) begin//按键消抖后会输出一个相反的脉冲，不用!chose_up，下面chose_down同理
		case(flag)
			3'd1:	begin flag <= 3'd2;num <= 10'd215; end
			3'd2:	begin flag <= 3'd3;num <= 10'd435; end
			3'd3:	begin flag <= 3'd1;num <= 1'b0; end
			default:begin flag <= 3'd1;num <= 1'b0; end
		endcase
	end
	else if(!s_s) begin
		cnt_delay <= cnt_delay; end
	else if(cnt_delay >= time_delay) begin
		cnt_delay <= 1'b0;
		case(num)
			10'd  0:	begin flag <= 3'd1;num <= num+1'b1; end
			10'd215:	begin flag <= 3'd2;num <= num+1'b1; end
			10'd435:	begin flag <= 3'd3;num <= num+1'b1; end
			10'd553:	begin flag <= 3'd1;num <= 1'b0; end
			default:	begin num <= num+1'b1; end
		endcase
	end
	else begin cnt_delay <= cnt_delay + 1'b1; end
end

always@(posedge rst_n_in) begin//音符表
	//奇迹再现
	note[  0] = {5'd 0};
	note[  1] = {5'd 6};
	note[  2] = {5'd 6};
	//第一小节
	note[  3] = {5'd 6};
	note[  4] = {5'd 8};
	note[  5] = {5'd13};
	note[  6] = {5'd12};
	note[  7] = {5'd12};
	note[  8] = {5'd11};
	note[  9] = {5'd 0};
	//第二小节
	note[ 10] = {5'd10};
	note[ 11] = {5'd11};
	note[ 12] = {5'd10};
	note[ 13] = {5'd10};
	note[ 14] = {5'd 9};
	note[ 15] = {5'd 8};
	note[ 16] = {5'd 9};
	//第三小节
	note[ 17] = {5'd 6};
	note[ 18] = {5'd 8};
	note[ 19] = {5'd13};
	note[ 20] = {5'd12};
	note[ 21] = {5'd12};
	note[ 22] = {5'd11};
	note[ 23] = {5'd 0};
	//第四小节
	note[ 24] = {5'd10};
	note[ 25] = {5'd11};
	note[ 26] = {5'd10};
	note[ 27] = {5'd 9};
	note[ 28] = {5'd 9};
	note[ 29] = {5'd 6};
	//第五小节
	note[ 30] = {5'd 6};
	note[ 31] = {5'd 8};
	note[ 32] = {5'd13};
	note[ 33] = {5'd12};
	note[ 34] = {5'd12};
	note[ 35] = {5'd11};
	note[ 36] = {5'd 0};
	note[ 37] = {5'd10};
	//第六小节
	note[ 38] = {5'd10};
	note[ 39] = {5'd11};
	note[ 40] = {5'd10};
	note[ 41] = {5'd10};
	note[ 42] = {5'd 9};
	note[ 43] = {5'd 8};
	note[ 44] = {5'd 9};
	//第七小节
	note[ 45] = {5'd 6};
	note[ 46] = {5'd 8};
	note[ 47] = {5'd13};
	note[ 48] = {5'd12};
	note[ 49] = {5'd12};
	note[ 50] = {5'd11};
	note[ 51] = {5'd 0};
	//第八小节
	note[ 52] = {5'd10};
	note[ 53] = {5'd11};
	note[ 54] = {5'd11};
	note[ 55] = {5'd13};
	note[ 56] = {5'd13};
	note[ 57] = {5'd13};
	note[ 58] = {5'd13};
	note[ 59] = {5'd13};
	//第九小节
	note[ 60] = {5'd 0};
	note[ 61] = {5'd 8};
	note[ 62] = {5'd 6};
	note[ 63] = {5'd 7};
	note[ 64] = {5'd 8};	
	note[ 65] = {5'd 0};
	//第十小节
	note[ 66] = {5'd 9};
	note[ 67] = {5'd 8};
	note[ 68] = {5'd 7};
	note[ 69] = {5'd 7};
	note[ 70] = {5'd 8};
	//十一小节
	note[ 71] = {5'd 0};
	note[ 72] = {5'd 8};
	note[ 73] = {5'd 6};
	note[ 74] = {5'd 7};
	note[ 75] = {5'd 8};
	note[ 76] = {5'd 0};
	//十二小节
	note[ 77] = {5'd10};
	note[ 78] = {5'd 9};
	note[ 79] = {5'd 9};
	note[ 80] = {5'd 9};
	note[ 81] = {5'd10};
	//十三小节
	note[ 82] = {5'd 0};
	note[ 83] = {5'd 8};
	note[ 84] = {5'd 5};
	note[ 85] = {5'd 7};
	note[ 86] = {5'd 8};
	note[ 87] = {5'd 0};
	//十四小节
	note[ 88] = {5'd10};
	note[ 89] = {5'd 8};
	note[ 90] = {5'd 8};
	note[ 91] = {5'd 8};
	note[ 92] = {5'd 9};
	note[ 93] = {5'd 7};
	//十五小节
	note[ 94] = {5'd 7};
	//十六小节
	note[ 95] = {5'd21};
	note[ 96] = {5'd19};
	note[ 97] = {5'd16};
	note[ 98] = {5'd15};
	note[ 99] = {5'd15};
	//十七小节
	note[100] = {5'd 0};
	note[101] = {5'd 8};
	note[102] = {5'd 6};
	note[103] = {5'd 7};
	note[104] = {5'd 8};
	note[105] = {5'd 0};
	//十八小节
	note[106] = {5'd 9};
	note[107] = {5'd 8};
	note[108] = {5'd 7};
	note[109] = {5'd 7};
	note[110] = {5'd 8};
	//十九小节
	note[111] = {5'd 0};
	note[112] = {5'd 8};
	note[113] = {5'd 6};
	note[114] = {5'd 7};
	note[115] = {5'd 8};
	note[116] = {5'd 0};
	//二十小节
	note[117] = {5'd10};
	note[118] = {5'd 9};
	note[119] = {5'd 9};
	note[120] = {5'd 9};
	note[121] = {5'd10};
	//二十一小节
	note[122] = {5'd 0};
	note[123] = {5'd 9};
	note[124] = {5'd 5};
	note[125] = {5'd 7};
	note[126] = {5'd 8};
	note[127] = {5'd 0};
	//二十二小节
	note[128] = {5'd10};
	note[129] = {5'd 8};
	note[130] = {5'd 8};
	note[131] = {5'd 8};
	note[132] = {5'd 9};
	note[133] = {5'd 7};
	//二十三小节
	note[134] = {5'd 7};
	note[135] = {5'd12};
	note[136] = {5'd 9};
	note[137] = {5'd13};
	note[138] = {5'd 9};
	note[139] = {5'd17};
	//二十四小节
	note[140] = {5'd17};
	note[141] = {5'd10};
	note[142] = {5'd11};
	//二十五小节
	note[143] = {5'd 8};
	note[144] = {5'd 8};
	note[145] = {5'd 8};
	note[146] = {5'd10};
	note[147] = {5'd10};
	//二十六小节
	note[148] = {5'd10};
	note[149] = {5'd 9};
	note[150] = {5'd 0};
	note[151] = {5'd 5};
	note[152] = {5'd 5};
	//二十七小节
	note[153] = {5'd10};
	note[154] = {5'd10};
	note[155] = {5'd10};
	note[156] = {5'd 9};
	note[157] = {5'd 9};
	//二十八小节
	note[158] = {5'd 9};
	note[159] = {5'd 8};
	note[160] = {5'd 8};
	note[161] = {5'd 7};
	note[162] = {5'd 6};
	//二十九小节
	note[163] = {5'd 6};
	note[164] = {5'd 8};
	note[165] = {5'd 8};
	note[166] = {5'd 7};
	note[167] = {5'd 5};
	//三十小节
	note[168] = {5'd 5};
	note[169] = {5'd 8};
	note[170] = {5'd 0};
	note[171] = {5'd 8};
	note[172] = {5'd 8};
	//三十一小节
	note[173] = {5'd 9};
	note[174] = {5'd 6};
	note[175] = {5'd 7};
	note[176] = {5'd 8};
	note[177] = {5'd 7};
	//三十二小节
	note[178] = {5'd 7};
	//三十三小节
	note[179] = {5'd 8};
	note[180] = {5'd 8};
	note[181] = {5'd 8};
	note[182] = {5'd10};
	note[183] = {5'd10};
	//三十四小节
	note[184] = {5'd10};
	note[185] = {5'd 9};
	note[186] = {5'd 0};
	note[187] = {5'd 5};
	note[188] = {5'd 5};
	//三十五小节
	note[189] = {5'd10};
	note[190] = {5'd10};
	note[191] = {5'd10};
	note[192] = {5'd 9};
	note[193] = {5'd 9};
	//三十六小节
	note[194] = {5'd 9};
	note[195] = {5'd 8};
	note[196] = {5'd 8};
	note[197] = {5'd 7};
	note[198] = {5'd 6};
	//三十七小节
	note[199] = {5'd 6};
	note[200] = {5'd 8};
	note[201] = {5'd 8};
	note[202] = {5'd 7};
	note[203] = {5'd 5};
	//三十八小节
	note[204] = {5'd 5};
	note[205] = {5'd 8};
	note[206] = {5'd 0};
	note[207] = {5'd 8};
	note[208] = {5'd 8};
	//三十九小节
	note[209] = {5'd 8};
	note[210] = {5'd 6};
	note[211] = {5'd 7};
	note[212] = {5'd 8};
	note[213] = {5'd 7};
	//四十小节
	note[214] = {5'd 7};
	
	//相思
	//第一小节
	note[215] = {5'd13};
	note[216] = {5'd10};
	note[217] = {5'd13};
	note[218] = {5'd14};
	note[219] = {5'd15};
	//第二小节
	note[220] = {5'd16};
	note[221] = {5'd15};
	note[222] = {5'd14};
	//第三小节
	note[223] = {5'd13};
	note[224] = {5'd12};
	//第四小节
	note[225] = {5'd10};
	note[226] = {5'd12};
	//第五小节
	note[227] = {5'd13};
	note[228] = {5'd10};
	note[229] = {5'd13};
	note[230] = {5'd14};
	note[231] = {5'd15};
	//第六小节
	note[232] = {5'd16};
	note[233] = {5'd15};
	note[234] = {5'd14};
	//第七小节
	note[235] = {5'd13};
	note[236] = {5'd12};
	//第八小节
	note[237] = {5'd13};
	//第九小节
	note[238] = {5'd 0};
	note[239] = {5'd 0};
	note[240] = {5'd 0};
	//第十小节
	note[241] = {5'd13};
	note[242] = {5'd 9};
	note[243] = {5'd 9};
	note[244] = {5'd 8};
	//十一小节
	note[245] = {5'd10};
	note[246] = {5'd 0};
	note[247] = {5'd 8};
	//十二小节
	note[248] = {5'd 9};
	note[249] = {5'd 9};
	note[250] = {5'd 8};
	note[251] = {5'd 9};
	note[252] = {5'd10};
	//十三小节
	note[253] = {5'd10};
	note[254] = {5'd 6};
	note[255] = {5'd13};
	//十四小节
	note[256] = {5'd13};
	note[257] = {5'd 9};
	note[258] = {5'd 9};
	note[259] = {5'd 8};
	//十五小节
	note[260] = {5'd10};
	note[261] = {5'd 0};
	note[262] = {5'd 8};
	//十六小节
	note[263] = {5'd 9};
	note[264] = {5'd13};
	note[265] = {5'd 9};
	//十七小节
	note[266] = {5'd 9};
	note[267] = {5'd10};
	//十八小节
	note[268] = {5'd13};
	note[269] = {5'd10};
	note[270] = {5'd 9};
	note[271] = {5'd 8};
	//十九小节
	note[272] = {5'd 9};
	note[273] = {5'd 0};
	//二十小节
	note[274] = {5'd 8};
	note[275] = {5'd 9};
	note[276] = {5'd10};
	//二十一小节
	note[277] = {5'd10};
	note[278] = {5'd 6};
	note[279] = {5'd 6};
	//二十二小节
	note[280] = {5'd13};
	note[281] = {5'd10};
	note[282] = {5'd13};
	//二十三小节
	note[283] = {5'd14};
	note[284] = {5'd10};
	note[285] = {5'd14};
	//二十四小节
	note[286] = {5'd15};
	note[287] = {5'd16};
	//二十五小节
	note[288] = {5'd14};
	note[289] = {5'd14};
	note[290] = {5'd14};
	//二十六小节
	note[291] = {5'd14};
	//二十七小节
	note[292] = {5'd10};
	note[293] = {5'd13};
	note[294] = {5'd13};
	note[295] = {5'd10};
	//二十八小节
	note[296] = {5'd10};
	note[297] = {5'd14};
	note[298] = {5'd14};
	note[299] = {5'd 0};
	note[300] = {5'd10};
	//二十九小节
	note[301] = {5'd16};
	note[302] = {5'd15};
	note[303] = {5'd14};
	note[304] = {5'd13};
	note[305] = {5'd12};
	note[306] = {5'd13};
	//三十小节
	note[307] = {5'd13};
	note[308] = {5'd10};
	note[309] = {5'd10};
	note[310] = {5'd 0};
	//三十一小节
	note[311] = {5'd10};
	note[312] = {5'd13};
	note[313] = {5'd13};
	note[314] = {5'd10};
	//三十二小节
	note[315] = {5'd14};
	note[316] = {5'd13};
	note[317] = {5'd 0};
	note[318] = {5'd10};
	//三十三小节
	note[319] = {5'd 9};
	note[320] = {5'd 8};
	note[321] = {5'd 9};
	//三十四小节
	note[322] = {5'd10};
	note[323] = {5'd 0};
	//三十五小节
	note[324] = {5'd10};
	note[325] = {5'd13};
	note[326] = {5'd13};
	note[327] = {5'd10};
	//三十六小节
	note[328] = {5'd10};
	note[329] = {5'd14};
	note[330] = {5'd14};
	note[331] = {5'd 0};
	note[332] = {5'd10};
	//三十七小节
	note[333] = {5'd16};
	note[334] = {5'd15};
	note[335] = {5'd14};
	note[336] = {5'd13};
	note[337] = {5'd12};
	note[338] = {5'd13};
	//三十八小节
	note[339] = {5'd13};
	note[340] = {5'd10};
	note[341] = {5'd10};
	note[342] = {5'd 0};
	//三十九小节
	note[343] = {5'd10};
	note[344] = {5'd13};
	note[345] = {5'd13};
	note[346] = {5'd10};
	//四十小节
	note[347] = {5'd17};
	note[348] = {5'd16};
	note[349] = {5'd17};
	//四十一小节
	note[350] = {5'd15};
	note[351] = {5'd14};
	//四十二小节
	note[352] = {5'd13};
	note[353] = {5'd13};
	//四十三小节
	note[354] = {5'd10};
	note[355] = {5'd13};
	note[356] = {5'd13};
	note[357] = {5'd10};
	//四十四小节
	note[358] = {5'd10};
	note[359] = {5'd14};
	note[360] = {5'd14};
	note[361] = {5'd 0};
	note[362] = {5'd10};
	//四十五小节
	note[363] = {5'd16};
	note[364] = {5'd15};
	note[365] = {5'd14};
	note[366] = {5'd13};
	note[367] = {5'd12};
	note[368] = {5'd13};
	//四十六小节
	note[369] = {5'd13};
	note[370] = {5'd10};
	note[371] = {5'd 0};
	//四十七小节
	note[372] = {5'd10};
	note[373] = {5'd13};
	note[374] = {5'd13};
	note[375] = {5'd10};
	//四十八小节
	note[376] = {5'd14};
	note[377] = {5'd13};
	note[378] = {5'd 0};
	note[379] = {5'd10};
	//四十九小节
	note[380] = {5'd 9};
	note[381] = {5'd 8};
	note[382] = {5'd 9};
	//五十小节
	note[383] = {5'd10};
	note[384] = {5'd 0};
	//五十一小节
	note[385] = {5'd10};
	note[386] = {5'd13};
	note[387] = {5'd13};
	note[388] = {5'd10};
	//五十二小节
	note[389] = {5'd10};
	note[390] = {5'd14};
	note[391] = {5'd14};
	note[392] = {5'd 0};
	note[393] = {5'd10};
	//五十三小节
	note[394] = {5'd16};
	note[395] = {5'd15};
	note[396] = {5'd14};
	note[397] = {5'd13};
	note[398] = {5'd12};
	note[399] = {5'd12};
	//五十四小节
	note[400] = {5'd13};
	note[401] = {5'd10};
	note[402] = {5'd 0};
	//五十五小节
	note[403] = {5'd10};
	note[404] = {5'd13};
	note[405] = {5'd13};
	note[406] = {5'd10};
	//五十六小节
	note[407] = {5'd17};
	note[408] = {5'd16};
	note[409] = {5'd17};
	//五十七小节
	note[410] = {5'd15};
	note[411] = {5'd14};
	//五十八小节
	note[412] = {5'd13};
	//五十九小节
	note[413] = {5'd13};
	//六十小节
	note[414] = {5'd10};
	note[415] = {5'd13};
	note[416] = {5'd13};
	note[417] = {5'd10};
	//六十一小节
	note[418] = {5'd17};
	note[419] = {5'd16};
	note[420] = {5'd17};
	//六十二小节
	note[421] = {5'd15};
	//六十三小节
	note[422] = {5'd14};
	note[423] = {5'd13};
	//六十四小节
	note[424] = {5'd13};
	note[425] = {5'd10};
	note[426] = {5'd13};
	note[427] = {5'd14};
	note[428] = {5'd15};
	//六十五小节
	note[429] = {5'd16};
	note[430] = {5'd15};
	note[431] = {5'd14};
	//六十六小节
	note[432] = {5'd13};
	note[433] = {5'd12};
	//六十七小节
	note[434] = {5'd13};
	
	//大鱼
	//第一小节
	note[435] = {5'd 6};
	note[436] = {5'd 8};
	note[437] = {5'd 8};
	note[438] = {5'd 9};
	note[439] = {5'd 9};
	note[440] = {5'd10};
	note[441] = {5'd10};
	note[442] = {5'd12};
	note[443] = {5'd13};
	//第二小节
	note[444] = {5'd12};
	note[445] = {5'd10};
	note[446] = {5'd 9};
	//第三小节
	note[447] = {5'd 6};
	note[448] = {5'd 8};
	note[449] = {5'd 8};
	note[450] = {5'd 9};
	note[451] = {5'd 9};
	note[452] = {5'd10};
	note[453] = {5'd10};
	//第四小节
	note[454] = {5'd 6};
	note[455] = {5'd 5};
	//第五小节
	note[456] = {5'd 6};
	note[457] = {5'd 8};
	note[458] = {5'd 8};
	note[459] = {5'd 9};
	note[460] = {5'd 9};
	note[461] = {5'd10};
	note[462] = {5'd10};
	note[463] = {5'd12};
	note[464] = {5'd13};
	//第六小节
	note[465] = {5'd12};
	note[466] = {5'd10};
	note[467] = {5'd 9};
	//第七小节
	note[468] = {5'd 9};
	note[469] = {5'd10};
	note[470] = {5'd 6};
	note[471] = {5'd 9};
	note[472] = {5'd10};
	note[473] = {5'd 6};
	note[474] = {5'd 5};
	//第八小节
	note[475] = {5'd 6};
	note[476] = {5'd 6};
	note[477] = {5'd 8};
	//第九小节
	note[478] = {5'd 9};
	note[479] = {5'd 8};
	note[480] = {5'd 6};
	note[481] = {5'd 6};
	note[482] = {5'd 8};
	//第十小节
	note[483] = {5'd 9};
	note[484] = {5'd 8};
	note[485] = {5'd10};
	note[486] = {5'd10};
	note[487] = {5'd12};
	//十一小节
	note[488] = {5'd13};
	note[489] = {5'd13};
	note[490] = {5'd12};
	note[491] = {5'd10};
	note[492] = {5'd 9};
	note[493] = {5'd 8};
	//十二小节
	note[494] = {5'd 9};
	note[495] = {5'd10};
	note[496] = {5'd 6};
	note[497] = {5'd 8};
	//十三小节
	note[498] = {5'd 9};
	note[499] = {5'd 8};
	note[500] = {5'd 6};
	note[501] = {5'd 6};
	note[502] = {5'd 8};
	//十四小节
	note[503] = {5'd 9};
	note[504] = {5'd 8};
	note[505] = {5'd10};
	//十五小节
	note[506] = {5'd 9};
	note[507] = {5'd10};
	note[508] = {5'd 6};
	note[509] = {5'd 9};
	note[510] = {5'd10};
	note[511] = {5'd 6};
	note[512] = {5'd 5};
	//十六小节
	note[513] = {5'd 6};
	note[514] = {5'd10};
	note[515] = {5'd12};
	//十七小节
	note[516] = {5'd15};
	note[517] = {5'd14};
	note[518] = {5'd10};
	note[519] = {5'd10};
	note[520] = {5'd 9};
	//十八小节
	note[521] = {5'd 8};
	note[522] = {5'd 8};
	note[523] = {5'd 9};
	note[524] = {5'd10};
	note[525] = {5'd10};
	note[526] = {5'd 9};
	//十九小节
	note[527] = {5'd 8};
	note[528] = {5'd13};
	note[529] = {5'd15};
	note[530] = {5'd14};
	note[531] = {5'd13};
	note[532] = {5'd12};
	note[533] = {5'd 9};
	//二十小节
	note[534] = {5'd10};
	note[535] = {5'd10};
	note[536] = {5'd12};
	//二十一小节
	note[537] = {5'd15};
	note[538] = {5'd14};
	note[539] = {5'd10};
	note[540] = {5'd10};
	note[541] = {5'd 9};
	//二十二小节
	note[542] = {5'd 8};
	note[543] = {5'd 8};
	note[544] = {5'd 9};
	note[545] = {5'd10};
	//二十三小节
	note[546] = {5'd 9};
	note[547] = {5'd10};
	note[548] = {5'd 6};
	note[549] = {5'd 9};
	note[550] = {5'd10};
	note[551] = {5'd 6};
	note[552] = {5'd 5};
	//二十四小节
	note[553] = {5'd 6};
	
	
	end
always@(posedge rst_n_in) begin//节拍表
	//奇迹再现
	beat[  0] = {5'd 2};
	beat[  1] = {5'd 2};
	beat[  2] = {5'd 4};
	//第一小节
	beat[  3] = {5'd 2};
	beat[  4] = {5'd 2};
	beat[  5] = {5'd 2};
	beat[  6] = {5'd 2};
	beat[  7] = {5'd 2};
	beat[  8] = {5'd 2};
	beat[  9] = {5'd 4};
	//第二小节
	beat[ 10] = {5'd 4};
	beat[ 11] = {5'd 2};
	beat[ 12] = {5'd 2};
	beat[ 13] = {5'd 2};
	beat[ 14] = {5'd 2};
	beat[ 15] = {5'd 2};
	beat[ 16] = {5'd 2};
	//第三小节
	beat[ 17] = {5'd 2};
	beat[ 18] = {5'd 2};
	beat[ 19] = {5'd 2};
	beat[ 20] = {5'd 2};
	beat[ 21] = {5'd 2};
	beat[ 22] = {5'd 2};
	beat[ 23] = {5'd 4};
	//第四小节
	beat[ 24] = {5'd 2};
	beat[ 25] = {5'd 2};
	beat[ 26] = {5'd 2};
	beat[ 27] = {5'd 2};
	beat[ 28] = {5'd 6};
	beat[ 29] = {5'd 2};
	//第五小节
	beat[ 30] = {5'd 2};
	beat[ 31] = {5'd 2};
	beat[ 32] = {5'd 2};
	beat[ 33] = {5'd 2};
	beat[ 34] = {5'd 2};
	beat[ 35] = {5'd 2};
	beat[ 36] = {5'd 2};
	beat[ 37] = {5'd 2};
	//第六小节
	beat[ 38] = {5'd 4};
	beat[ 39] = {5'd 2};
	beat[ 40] = {5'd 2};
	beat[ 41] = {5'd 2};
	beat[ 42] = {5'd 2};
	beat[ 43] = {5'd 2};
	beat[ 44] = {5'd 2};
	//第七小节
	beat[ 45] = {5'd 2};
	beat[ 46] = {5'd 2};
	beat[ 47] = {5'd 2};
	beat[ 48] = {5'd 2};
	beat[ 49] = {5'd 2};
	beat[ 50] = {5'd 2};
	beat[ 51] = {5'd 4};
	//第八小节
	beat[ 52] = {5'd 2};
	beat[ 53] = {5'd 2};
	beat[ 54] = {5'd 2};
	beat[ 55] = {5'd 2};
	beat[ 56] = {5'd 2};
	beat[ 57] = {5'd 2};
	beat[ 58] = {5'd 1};
	beat[ 59] = {5'd 3};
	//第九小节
	beat[ 60] = {5'd 4};
	beat[ 61] = {5'd 2};
	beat[ 62] = {5'd 2};
	beat[ 63] = {5'd 2};
	beat[ 64] = {5'd 2};
	beat[ 65] = {5'd 4};
	//第十小节
	beat[ 66] = {5'd 4};
	beat[ 67] = {5'd 2};
	beat[ 68] = {5'd 2};
	beat[ 69] = {5'd 2};
	beat[ 70] = {5'd 6};
	//十一小节
	beat[ 71] = {5'd 4};
	beat[ 72] = {5'd 2};
	beat[ 73] = {5'd 2};
	beat[ 74] = {5'd 2};
	beat[ 75] = {5'd 2};
	beat[ 76] = {5'd 4};
	//十二小节
	beat[ 77] = {5'd 4};
	beat[ 78] = {5'd 2};
	beat[ 79] = {5'd 2};
	beat[ 80] = {5'd 2};
	beat[ 81] = {5'd 6};
	//十三小节
	beat[ 82] = {5'd 4};
	beat[ 83] = {5'd 2};
	beat[ 84] = {5'd 2};
	beat[ 85] = {5'd 2};
	beat[ 86] = {5'd 2};
	beat[ 87] = {5'd 4};
	//十四小节
	beat[ 88] = {5'd 4};
	beat[ 89] = {5'd 2};
	beat[ 90] = {5'd 2};
	beat[ 91] = {5'd 2};
	beat[ 92] = {5'd 4};
	beat[ 93] = {5'd 2};
	//十五小节
	beat[ 94] = {5'd16};
	//十六小节
	beat[ 95] = {5'd 2};
	beat[ 96] = {5'd 2};
	beat[ 97] = {5'd 2};
	beat[ 98] = {5'd 2};
	beat[ 99] = {5'd 8};
	//十七小节
	beat[100] = {5'd 4};
	beat[101] = {5'd 2};
	beat[102] = {5'd 2};
	beat[103] = {5'd 2};
	beat[104] = {5'd 2};
	beat[105] = {5'd 4};
	//十八小节
	beat[106] = {5'd 4};
	beat[107] = {5'd 2};
	beat[108] = {5'd 2};
	beat[109] = {5'd 2};
	beat[110] = {5'd 6};
	//十九小节
	beat[111] = {5'd 4};
	beat[112] = {5'd 2};
	beat[113] = {5'd 2};
	beat[114] = {5'd 2};
	beat[115] = {5'd 2};
	beat[116] = {5'd 4};
	//二十小节
	beat[117] = {5'd 4};
	beat[118] = {5'd 2};
	beat[119] = {5'd 2};
	beat[120] = {5'd 2};
	beat[121] = {5'd 6};
	//二十一小节
	beat[122] = {5'd 4};
	beat[123] = {5'd 2};
	beat[124] = {5'd 2};
	beat[125] = {5'd 2};
	beat[126] = {5'd 2};
	beat[127] = {5'd 4};
	//二十二小节
	beat[128] = {5'd 4};
	beat[129] = {5'd 2};
	beat[130] = {5'd 2};
	beat[131] = {5'd 2};
	beat[132] = {5'd 4};
	beat[133] = {5'd 2};
	//二十三小节
	beat[134] = {5'd 4};
	beat[135] = {5'd 2};
	beat[136] = {5'd 2};
	beat[137] = {5'd 2};
	beat[138] = {5'd 4};
	beat[139] = {5'd 2};
	//二十四小节
	beat[140] = {5'd12};
	beat[141] = {5'd 2};
	beat[142] = {5'd 2};
	//二十五小节
	beat[143] = {5'd 4};
	beat[144] = {5'd 4};
	beat[145] = {5'd 4};
	beat[146] = {5'd 2};
	beat[147] = {5'd 2};
	//二十六小节
	beat[148] = {5'd 2};
	beat[149] = {5'd 6};
	beat[150] = {5'd 4};
	beat[151] = {5'd 2};
	beat[152] = {5'd 2};
	//二十七小节
	beat[153] = {5'd 4};
	beat[154] = {5'd 4};
	beat[155] = {5'd 4};
	beat[156] = {5'd 2};
	beat[157] = {5'd 2};
	//二十八小节
	beat[158] = {5'd 2};
	beat[159] = {5'd 6};
	beat[160] = {5'd 4};
	beat[161] = {5'd 2};
	beat[162] = {5'd 2};
	//二十九小节
	beat[163] = {5'd 2};
	beat[164] = {5'd 6};
	beat[165] = {5'd 4};
	beat[166] = {5'd 2};
	beat[167] = {5'd 2};
	//三十小节
	beat[168] = {5'd 2};
	beat[169] = {5'd 6};
	beat[170] = {5'd 4};
	beat[171] = {5'd 2};
	beat[172] = {5'd 2};
	//三十一小节
	beat[173] = {5'd 4};
	beat[174] = {5'd 4};
	beat[175] = {5'd 2};
	beat[176] = {5'd 4};
	beat[177] = {5'd 2};
	//三十二小节
	beat[178] = {5'd16};
	//三十三小节
	beat[179] = {5'd 4};
	beat[180] = {5'd 4};
	beat[181] = {5'd 4};
	beat[182] = {5'd 2};
	beat[183] = {5'd 2};
	//三十四小节
	beat[184] = {5'd 2};
	beat[185] = {5'd 6};
	beat[186] = {5'd 4};
	beat[187] = {5'd 2};
	beat[188] = {5'd 2};
	//三十五小节
	beat[189] = {5'd 4};
	beat[190] = {5'd 4};
	beat[191] = {5'd 4};
	beat[192] = {5'd 2};
	beat[193] = {5'd 2};
	//三十六小节
	beat[194] = {5'd 2};
	beat[195] = {5'd 6};
	beat[196] = {5'd 4};
	beat[197] = {5'd 2};
	beat[198] = {5'd 2};
	//三十七小节
	beat[199] = {5'd 2};
	beat[200] = {5'd 6};
	beat[201] = {5'd 4};
	beat[202] = {5'd 2};
	beat[203] = {5'd 2};
	//三十八小节
	beat[204] = {5'd 2};
	beat[205] = {5'd 6};
	beat[206] = {5'd 4};
	beat[207] = {5'd 2};
	beat[208] = {5'd 2};
	//三十九小节
	beat[209] = {5'd 4};
	beat[210] = {5'd 4};
	beat[211] = {5'd 2};
	beat[212] = {5'd 4};
	beat[213] = {5'd 2};
	//四十小节
	beat[214] = {5'd24};
	
	//相思
	//第一小节
	beat[215] = {5'd 2};
	beat[216] = {5'd 2};
	beat[217] = {5'd 2};
	beat[218] = {5'd 2};
	beat[219] = {5'd 4};
	//第二小节
	beat[220] = {5'd 4};
	beat[221] = {5'd 4};
	beat[222] = {5'd 4};
	//第三小节
	beat[223] = {5'd 8};
	beat[224] = {5'd 4};
	//第四小节
	beat[225] = {5'd 8};
	beat[226] = {5'd 4};
	//第五小节
	beat[227] = {5'd 2};
	beat[228] = {5'd 2};
	beat[229] = {5'd 2};
	beat[230] = {5'd 2};
	beat[231] = {5'd 4};
	//第六小节
	beat[232] = {5'd 4};
	beat[233] = {5'd 4};
	beat[234] = {5'd 4};
	//第七小节
	beat[235] = {5'd 8};
	beat[236] = {5'd 4};
	//第八小节
	beat[237] = {5'd 12};
	//第九小节
	beat[238] = {5'd 4};
	beat[239] = {5'd 4};
	beat[240] = {5'd 4};
	//第十小节
	beat[241] = {5'd 4};
	beat[242] = {5'd 4};
	beat[243] = {5'd 2};
	beat[244] = {5'd 2};
	//十一小节
	beat[245] = {5'd 8};
	beat[246] = {5'd 2};
	beat[247] = {5'd 2};
	//十二小节
	beat[248] = {5'd 4};
	beat[249] = {5'd 2};
	beat[250] = {5'd 2};
	beat[251] = {5'd 2};
	beat[252] = {5'd 2};
	//十三小节
	beat[253] = {5'd 2};
	beat[254] = {5'd 2};
	beat[255] = {5'd 8};
	//十四小节
	beat[256] = {5'd 4};
	beat[257] = {5'd 4};
	beat[258] = {5'd 2};
	beat[259] = {5'd 2};
	//十五小节
	beat[260] = {5'd 8};
	beat[261] = {5'd 2};
	beat[262] = {5'd 2};
	//十六小节
	beat[263] = {5'd 4};
	beat[264] = {5'd 6};
	beat[265] = {5'd 2};
	//十七小节
	beat[266] = {5'd 4};
	beat[267] = {5'd 8};
	//十八小节
	beat[268] = {5'd 4};
	beat[269] = {5'd 4};
	beat[270] = {5'd 2};
	beat[271] = {5'd 2};
	//十九小节
	beat[272] = {5'd 8};
	beat[273] = {5'd 4};
	//二十小节
	beat[274] = {5'd 4};
	beat[275] = {5'd 6};
	beat[276] = {5'd 2};
	//二十一小节
	beat[277] = {5'd 2};
	beat[278] = {5'd 2};
	beat[279] = {5'd 8};
	//二十二小节
	beat[280] = {5'd 4};
	beat[281] = {5'd 4};
	beat[282] = {5'd 4};
	//二十三小节
	beat[283] = {5'd 4};
	beat[284] = {5'd 4};
	beat[285] = {5'd 4};
	//二十四小节
	beat[286] = {5'd 4};
	beat[287] = {5'd 8};
	//二十五小节
	beat[288] = {5'd 6};
	beat[289] = {5'd 2};
	beat[290] = {5'd 4};
	//二十六小节
	beat[291] = {5'd12};
	//二十七小节
	beat[292] = {5'd 2};
	beat[293] = {5'd 2};
	beat[294] = {5'd 6};
	beat[295] = {5'd 2};
	//二十八小节
	beat[296] = {5'd 2};
	beat[297] = {5'd 2};
	beat[298] = {5'd 4};
	beat[299] = {5'd 2};
	beat[300] = {5'd 2};
	//二十九小节
	beat[301] = {5'd 2};
	beat[302] = {5'd 2};
	beat[303] = {5'd 2};
	beat[304] = {5'd 2};
	beat[305] = {5'd 2};
	beat[306] = {5'd 2};
	//三十小节
	beat[307] = {5'd 2};
	beat[308] = {5'd 2};
	beat[309] = {5'd 4};
	beat[310] = {5'd 4};
	//三十一小节
	beat[311] = {5'd 2};
	beat[312] = {5'd 2};
	beat[313] = {5'd 6};
	beat[314] = {5'd 2};
	//三十二小节
	beat[315] = {5'd 4};
	beat[316] = {5'd 4};
	beat[317] = {5'd 2};
	beat[318] = {5'd 2};
	//三十三小节
	beat[319] = {5'd 4};
	beat[320] = {5'd 4};
	beat[321] = {5'd 4};
	//三十四小节
	beat[322] = {5'd 8};
	beat[323] = {5'd 4};
	//三十五小节
	beat[324] = {5'd 2};
	beat[325] = {5'd 2};
	beat[326] = {5'd 6};
	beat[327] = {5'd 2};
	//三十六小节
	beat[328] = {5'd 2};
	beat[329] = {5'd 2};
	beat[330] = {5'd 4};
	beat[331] = {5'd 2};
	beat[332] = {5'd 2};
	//三十七小节
	beat[333] = {5'd 2};
	beat[334] = {5'd 2};
	beat[335] = {5'd 2};
	beat[336] = {5'd 2};
	beat[337] = {5'd 2};
	beat[338] = {5'd 2};
	//三十八小节
	beat[339] = {5'd 2};
	beat[340] = {5'd 2};
	beat[341] = {5'd 4};
	beat[342] = {5'd 4};
	//三十九小节
	beat[343] = {5'd 2};
	beat[344] = {5'd 2};
	beat[345] = {5'd 6};
	beat[346] = {5'd 2};
	//四十小节
	beat[347] = {5'd 4};
	beat[348] = {5'd 6};
	beat[349] = {5'd 2};
	//四十一小节
	beat[350] = {5'd 8};
	beat[351] = {5'd 4};
	//四十二小节
	beat[352] = {5'd12};
	beat[353] = {5'd12};
	//四十三小节
	beat[354] = {5'd 2};
	beat[355] = {5'd 2};
	beat[356] = {5'd 6};
	beat[357] = {5'd 2};
	//四十四小节
	beat[358] = {5'd 2};
	beat[359] = {5'd 2};
	beat[360] = {5'd 4};
	beat[361] = {5'd 2};
	beat[362] = {5'd 2};
	//四十五小节
	beat[363] = {5'd 2};
	beat[364] = {5'd 2};
	beat[365] = {5'd 2};
	beat[366] = {5'd 2};
	beat[367] = {5'd 2};
	beat[368] = {5'd 2};
	//四十六小节
	beat[369] = {5'd 4};
	beat[370] = {5'd 4};
	beat[371] = {5'd 4};
	//四十七小节
	beat[372] = {5'd 2};
	beat[373] = {5'd 2};
	beat[374] = {5'd 6};
	beat[375] = {5'd 2};
	//四十八小节
	beat[376] = {5'd 4};
	beat[377] = {5'd 4};
	beat[378] = {5'd 2};
	beat[379] = {5'd 2};
	//四十九小节
	beat[380] = {5'd 4};
	beat[381] = {5'd 4};
	beat[382] = {5'd 4};
	//五十小节
	beat[383] = {5'd 8};
	beat[384] = {5'd 4};
	//五十一小节
	beat[385] = {5'd 2};
	beat[386] = {5'd 2};
	beat[387] = {5'd 6};
	beat[388] = {5'd 2};
	//五十二小节
	beat[389] = {5'd 2};
	beat[390] = {5'd 2};
	beat[391] = {5'd 4};
	beat[392] = {5'd 2};
	beat[393] = {5'd 2};
	//五十三小节
	beat[394] = {5'd 3};
	beat[395] = {5'd 1};
	beat[396] = {5'd 2};
	beat[397] = {5'd 2};
	beat[398] = {5'd 2};
	beat[399] = {5'd 2};
	//五十四小节
	beat[400] = {5'd 4};
	beat[401] = {5'd 4};
	beat[402] = {5'd 4};
	//五十五小节
	beat[403] = {5'd 2};
	beat[404] = {5'd 2};
	beat[405] = {5'd 6};
	beat[406] = {5'd 2};
	//五十六小节
	beat[407] = {5'd 4};
	beat[408] = {5'd 6};
	beat[409] = {5'd 2};
	//五十七小节
	beat[410] = {5'd 8};
	beat[411] = {5'd 4};
	//五十八小节
	beat[412] = {5'd12};
	//五十九小节
	beat[413] = {5'd12};
	//六十小节
	beat[414] = {5'd 2};
	beat[415] = {5'd 2};
	beat[416] = {5'd 6};
	beat[417] = {5'd 2};
	//六十一小节
	beat[418] = {5'd 4};
	beat[419] = {5'd 6};
	beat[420] = {5'd 2};
	//六十二小节
	beat[421] = {5'd12};
	//六十三小节
	beat[422] = {5'd 4};
	beat[423] = {5'd 8};
	//六十四小节
	beat[424] = {5'd 2};
	beat[425] = {5'd 2};
	beat[426] = {5'd 2};
	beat[427] = {5'd 2};
	beat[428] = {5'd 4};
	//六十五小节
	beat[429] = {5'd 4};
	beat[430] = {5'd 4};
	beat[431] = {5'd 4};
	//六十六小节
	beat[432] = {5'd 8};
	beat[433] = {5'd 4};
	//六十七小节
	beat[434] = {5'd12};
	
	//大鱼
	//第一小节
	beat[435] = {5'd 2};
	beat[436] = {5'd 2};
	beat[437] = {5'd 2};
	beat[438] = {5'd 2};
	beat[439] = {5'd 2};
	beat[440] = {5'd 2};
	beat[441] = {5'd 2};
	beat[442] = {5'd 1};
	beat[443] = {5'd 1};
	//第二小节
	beat[444] = {5'd 6};
	beat[445] = {5'd 2};
	beat[446] = {5'd 8};
	//第三小节
	beat[447] = {5'd 2};
	beat[448] = {5'd 2};
	beat[449] = {5'd 2};
	beat[450] = {5'd 2};
	beat[451] = {5'd 2};
	beat[452] = {5'd 2};
	beat[453] = {5'd 4};
	//第四小节
	beat[454] = {5'd 4};
	beat[455] = {5'd12};
	//第五小节
	beat[456] = {5'd 2};
	beat[457] = {5'd 2};
	beat[458] = {5'd 2};
	beat[459] = {5'd 2};
	beat[460] = {5'd 2};
	beat[461] = {5'd 2};
	beat[462] = {5'd 2};
	beat[463] = {5'd 1};
	beat[464] = {5'd 1};
	//第六小节
	beat[465] = {5'd 6};
	beat[466] = {5'd 2};
	beat[467] = {5'd 8};
	//第七小节
	beat[468] = {5'd 2};
	beat[469] = {5'd 2};
	beat[470] = {5'd 4};
	beat[471] = {5'd 2};
	beat[472] = {5'd 2};
	beat[473] = {5'd 2};
	beat[474] = {5'd 2};
	//第八小节
	beat[475] = {5'd12};
	beat[476] = {5'd 2};
	beat[477] = {5'd 2};
	//第九小节
	beat[478] = {5'd 6};
	beat[479] = {5'd 2};
	beat[480] = {5'd 4};
	beat[481] = {5'd 2};
	beat[482] = {5'd 2};
	//第十小节
	beat[483] = {5'd 6};
	beat[484] = {5'd 2};
	beat[485] = {5'd 4};
	beat[486] = {5'd 2};
	beat[487] = {5'd 2};
	//十一小节
	beat[488] = {5'd 4};
	beat[489] = {5'd 2};
	beat[490] = {5'd 2};
	beat[491] = {5'd 2};
	beat[492] = {5'd 2};
	beat[493] = {5'd 4};
	//十二小节
	beat[494] = {5'd 4};
	beat[495] = {5'd 8};
	beat[496] = {5'd 2};
	beat[497] = {5'd 2};
	//十三小节
	beat[498] = {5'd 6};
	beat[499] = {5'd 2};
	beat[500] = {5'd 4};
	beat[501] = {5'd 2};
	beat[502] = {5'd 2};
	//十四小节
	beat[503] = {5'd 4};
	beat[504] = {5'd 4};
	beat[505] = {5'd 8};
	//十五小节
	beat[506] = {5'd 2};
	beat[507] = {5'd 2};
	beat[508] = {5'd 4};
	beat[509] = {5'd 2};
	beat[510] = {5'd 2};
	beat[511] = {5'd 2};
	beat[512] = {5'd 2};
	//十六小节
	beat[513] = {5'd12};
	beat[514] = {5'd 2};
	beat[515] = {5'd 2};
	//十七小节
	beat[516] = {5'd 6};
	beat[517] = {5'd 2};
	beat[518] = {5'd 4};
	beat[519] = {5'd 2};
	beat[520] = {5'd 2};
	//十八小节
	beat[521] = {5'd 4};
	beat[522] = {5'd 2};
	beat[523] = {5'd 2};
	beat[524] = {5'd 4};
	beat[525] = {5'd 2};
	beat[526] = {5'd 2};
	//十九小节
	beat[527] = {5'd 4};
	beat[528] = {5'd 2};
	beat[529] = {5'd 2};
	beat[530] = {5'd 2};
	beat[531] = {5'd 2};
	beat[532] = {5'd 2};
	beat[533] = {5'd 2};
	//二十小节
	beat[534] = {5'd12};
	beat[535] = {5'd 4};
	beat[536] = {5'd 4};
	//二十一小节
	beat[537] = {5'd 6};
	beat[538] = {5'd 2};
	beat[539] = {5'd 4};
	beat[540] = {5'd 2};
	beat[541] = {5'd 2};
	//二十二小节
	beat[542] = {5'd 4};
	beat[543] = {5'd 2};
	beat[544] = {5'd 2};
	beat[545] = {5'd 8};
	//二十三小节
	beat[546] = {5'd 2};
	beat[547] = {5'd 2};
	beat[548] = {5'd 4};
	beat[549] = {5'd 2};
	beat[550] = {5'd 2};
	beat[551] = {5'd 2};
	beat[552] = {5'd 2};
	//二十四小节
	beat[553] = {5'd16};
	end
endmodule
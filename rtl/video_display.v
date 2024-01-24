/*******************************************************
 * FPGA-Based ̰����
  * School:CSU
 * Class: �Զ��� T2101
 * Students: ����-8210211913, ��ɭ��-8212211224
 * Instructor: ������
 *******************************************************/



module  video_display(
    input             pixel_clk,                  //VGA����ʱ��
    input             sys_rst_n,                //��λ�ź�
    input      [5:0]   speed_change,
    input      [10:0] pixel_xpos,               //���ص������
    input      [10:0] pixel_ypos,               //���ص�������   
    input       [5:0]key,//������������
    input	 [2:0]	state_1,//�˵�״̬
    output reg [23:0] pixel_data                //���ص�����
    );    

//parameter define    
parameter  H_DISP  = 11'd1280;                  //�ֱ���--��
parameter  V_DISP  = 11'd720;                   //�ֱ���--��

localparam SIDE_W  = 11'd40;                    //��Ļ�߿���
localparam BLOCK_W = 11'd20;                    //������
localparam BLUE    = 24'b00000000_00000000_11111111;    // ��ɫ
localparam WHITE   = 24'b11111111_11111111_11111111;    // ��ɫ
localparam BLACK   = 24'b00000000_00000000_00000000;    // ��ɫ
localparam RED    = 24'b11111111_00000000_00000000; // ��ɫ
localparam GREEN  = 24'b00000000_11111111_00000000; // ��ɫ
localparam Crimson = 24'hDC143C;//���ɫ
//�������ʵ������ɫ
localparam FOOD_COLOR =Crimson ;
localparam SNAKE_COLOR =GREEN ;
localparam CHAR_COLOR =BLACK ;
localparam BACKGROUND_COLOR =WHITE ;
//�����ʼλ�ã����ִ�С
localparam INI_X =11'd640 ;//��ʼλ��
localparam INI_Y =11'd320 ;
localparam StandardF =20'd742500;
localparam HanZiSize =32 ;


//����ͼƬ              
localparam PIC_X_START = 11'd1;      //ͼƬ��ʼ�������
localparam PIC_Y_START = 11'd1;      //ͼƬ��ʼ��������
localparam PIC_WIDTH   = 11'd100;    //ͼƬ���
localparam PIC_HEIGHT  = 11'd100;    //ͼƬ�߶�

//����ʳ��
localparam FOOD_W =11'd20 ;//ʳ���С
localparam FOOD_X=11'd360 ;
localparam FOOD_Y=11'd400 ;
reg [10:0]Food_Array[1:0];
reg FoodGene;
    //����ʳ�������
wire  [9:0]RandomX;
wire [9:0]RandomY;

//��������״̬
parameter game_start	= 3'b001;  //��Ϸ����Ŀ�ʼѡ��
parameter game_back		= 3'b010;  //��Ϸ����ķ���ѡ��
parameter game			= 3'b100;  //��Ϸ��
//reg define
reg   [13:0]  rom_addr  ;  //ROM��ַ
reg [10:0] block_x = INI_X ;                             //�������ϽǺ�����
reg [10:0] block_y = INI_Y ;                             //�������Ͻ�������

//������
reg [3:0] SnakeSize=3;//�����߳���
localparam MaxSize =10 ;//16
reg [10:0] Snake_Array[MaxSize-1:0][1:0]; // �����ߵ�ÿ�ڵ���������
reg [1:0]speed=1;

//������������ڸ����ߵ��ٶ�
reg [22:0] div_cnt;                             //ʱ�ӷ�Ƶ������
reg        h_direct;                            //����ˮƽ�ƶ�����1�����ƣ�0������
reg        v_direct;                            //������ֱ�ƶ�����1�����£�0������
reg [1:0]direction;

//����ROM
wire          rom_rd_en ;  //ROM��ʹ���ź�
wire  [23:0]  rom_rd_data ;//ROM����

//����ʹ�ܶ�
wire move_en;                                   //�����ƶ�ʹ���źţ�Ƶ��Ϊ100hz
reg MOEN;                                       //�����ƶ�����
reg GAME_EN=0;//��Ϸʹ��
assign move_en = (div_cnt == StandardF*10/speed) ? 1'b1 : 1'b0;//�ƶ��ٶ�ʹ�ܱ�־
assign  rom_rd_en = 1'b1;                  //��ʹ�����ߣ���һֱ��ROM����

//���������
//rng_custom_range Ran1(pixel_clk,sys_rst_n,FoodGene,11'd100,11'd1000,RandomX);
//rng_custom_range Ran2(pixel_clk,sys_rst_n,FoodGene,11'd100,11'd600,RandomY);

//���������2

// �������������Ϊ�������
reg  [10:0] random_seed_x=11'd135;
reg  [10:0] random_seed_y=11'd246;
reg generate_food_signal=0;
// ÿ����Ҫ����ʳ��ʱ�����������
always @(posedge pixel_clk) begin
    random_seed_x <= (random_seed_x + 1'b1) ^ {3'b101, random_seed_x[10:3]}; // LFSR�߼�
    random_seed_y <= (random_seed_y + 1'b1) ^ {3'b010, random_seed_y[10:3]}; // 
end
// ʹ�������������ʳ��λ��


//�����л�
always @(posedge pixel_clk) 
begin
        if (!sys_rst_n||dead) begin
            MOEN=0;direction=0;
        end
        if(GAME_EN==1)//��Ϸ������ܽ��и��ķ��򣬷�ֹ��Ϸ����֮ǰ���г����Լ�����
        begin
            if (key[0] == 1) 
                begin  // ��
                    if(!(direction==1))
                        begin
                            direction=0;
                        end
                    if(direction==1)
                        begin   
                            direction=direction;
                        end
                    if(Snake_Array[0][1]==Snake_Array[1][1]+BLOCK_W)//��ͷ���£�����������
                        begin
                            direction=direction;
                        end
                    MOEN=1;
                end
            else if (key[1] == 1) 
                begin  // ��
                    if(!(direction==0))
                        begin
                            direction=1;
                        end
                    if(direction==0)
                        begin
                            direction=direction;
                        end
                    if(Snake_Array[0][1]==Snake_Array[1][1]-BLOCK_W)//��ͷ���ϣ�����������
                        begin
                            direction=direction;
                        end
                    MOEN=1;
                end
            else if (key[2] == 1) 
                begin  // ��
                    if(MOEN==0)//��ʼ��������
                    begin
                        direction=3;
                    end
                    else
                    begin
                        if(!(direction==3))
                            begin
                                direction=2;
                            end
                        if(direction==3)
                            begin
                                direction=direction;
                            end
                        if(Snake_Array[0][0]==Snake_Array[1][0]+BLOCK_W)//��ͷ���ң�����������
                            begin
                                direction=direction;
                            end
                    end
                    MOEN=1;
                end
            else if (key[3] == 1) 
                begin  // ��
                    if(!(direction==2'd2))
                    begin
                       direction=2'd3;
                    end
                    if(direction==2'd2)
                    begin
                        direction=2'd2;
                    end
                    if(Snake_Array[0][0]==Snake_Array[1][0]-BLOCK_W)//��ͷ���󣬲���������
                        begin
                            direction=direction;
                        end
                    MOEN=1;
                end
        end
end

//ͨ����vga����ʱ�Ӽ�����ʵ��ʱ�ӷ�Ƶ���Ӷ�ʵ���ٶȶ���
always @(posedge pixel_clk ) begin         
    if (!sys_rst_n)
        div_cnt <= 0;
    else begin
        if(div_cnt < StandardF*10/speed) 
            div_cnt <= div_cnt + 1'b1;
        else
            div_cnt <= 0;                   //���������޺�����
    end
end

//�л��ٶ�
always @(posedge speed_change[0]) begin
    if(speed<3)
    begin
        speed=speed+1;
    end
    else if(speed)
    begin
        speed=1;
    end
    else begin
        speed=speed;
    end
end

//����һ����ʱ�������������verilog������ֱ�Ӵ���
integer index0;
integer index1;
integer index2;
integer index3;
integer index4;
integer index5;//�ж���ײ������־
reg dead=0;//������־

//���ƶ�ģ�飬���ݷ����ƶ����򣬸ı����ݺ�����
always @(posedge pixel_clk ) begin  
    //    Ӧ�÷ŵ�EN���棬����ᵼ����ת������������֮��
    //�л��������߼���0
    if(state_1==game_start)
        begin
            dead=0;
        end
    if(!dead)  
        begin
            if (!sys_rst_n||!GAME_EN) 
                begin
                    SnakeSize=3;
                    for(index0=0; index0<MaxSize; index0=index0+1) //��Ϊforѭ�������޲�����Ϊ�����������ۺϣ���ֻ���ö�ֵ���ɶ��±�����ж��Ƿ���Ͻ��ޣ��Ӷ�ʵ��ɨ��
                        begin
                            if(index0<SnakeSize)
                                begin
                                    Snake_Array[index0][0] = INI_X - index0 * BLOCK_W;
                                    Snake_Array[index0][1] = INI_Y;
                                end
                            else
                            begin
                                Snake_Array[index0][0] = 0;
                                Snake_Array[index0][1] = 0;
                            end
                        end
                    Food_Array[0] <= 11'd360; // ����ĳ�ʼX����
                    Food_Array[1] <= 11'd400; // ����ĳ�ʼY����
                end
            if (move_en&&MOEN&&GAME_EN) 
                begin
                    case (direction)//���ݷ���Ĳ�ͬ�����в�ͬ����λ����
                        2'd0:
                        begin
                            for(index1=MaxSize-1; index1>0; index1=index1-1) begin//����forѭ������ʽ���Ӻ�����ǰ��ݽ�
                                if(index1<SnakeSize)begin
                                Snake_Array[index1][0] = Snake_Array[index1-1][0];
                                Snake_Array[index1][1] = Snake_Array[index1-1][1];
                                end
                            end
                            Snake_Array[0][1] = Snake_Array[0][1] -BLOCK_W;//����Ҫע���Ǽ�BLOCK_W,֮ǰ��Ϊ1���������غϳ�һ�������ˡ�����Ϊ�����ƶ���drawƵ�ʵ�����
                        end
                        2'b1:
                        begin
                            for(index2=MaxSize-1; index2>0; index2=index2-1) begin
                                if(index2<SnakeSize)begin
                                Snake_Array[index2][0] = Snake_Array[index2-1][0];
                                Snake_Array[index2][1] = Snake_Array[index2-1][1];
                                end
                            end
                            Snake_Array[0][1] = Snake_Array[0][1] + BLOCK_W;
                        end
                        2'd2:
                        begin
                            for(index3=MaxSize-1; index3>0; index3=index3-1) begin
                                if(index3<SnakeSize)begin
                                Snake_Array[index3][0] = Snake_Array[index3-1][0];
                                Snake_Array[index3][1] = Snake_Array[index3-1][1];
                                end
                            end
                            Snake_Array[0][0] = Snake_Array[0][0] -BLOCK_W; // ����Ϊx����
                        end
                        2'd3:
                        begin
                            for(index4=MaxSize-1; index4>0; index4=index4-1) begin
                                if(index4<SnakeSize)begin
                                Snake_Array[index4][0] = Snake_Array[index4-1][0]; // ������������
                                Snake_Array[index4][1] = Snake_Array[index4-1][1];
                                end
                            end
                            Snake_Array[0][0] = Snake_Array[0][0] + BLOCK_W; // ����Ϊx����
                        end
                    endcase
                    //��ײ�����߼�
                    for(index5=1;index5<MaxSize&&dead==0; index5=index5+1) begin
                                if(index5<SnakeSize)
                                    begin
                                        if(Snake_Array[0][0]==Snake_Array[index5][0]&&Snake_Array[0][1]==Snake_Array[index5][1])                                  
                                        //if((Snake_Array[0][0]>=Snake_Array[index5][0])&&(Snake_Array[0][0]<Snake_Array[index5][0]+SnakeSize)&&(Snake_Array[0][1]>=Snake_Array[index5][1])&&(Snake_Array[0][1]<Snake_Array[index5][1]+SnakeSize))
                                            dead=1;
                                    end
                                end
                    if(((Snake_Array[0][0] < SIDE_W) || (Snake_Array[0][0] >= H_DISP - SIDE_W)|| (Snake_Array[0][1] < SIDE_W) || (Snake_Array[0][1] >= V_DISP - SIDE_W))&&dead==0)
                        begin
                            dead=1;
                        // GAME_EN=0;
                        end
                    //�Ե�ʳ��,ʳ������߼�        
                    if((Snake_Array[0][0]>=Food_Array[0])&&(Snake_Array[0][0]<Food_Array[0]+FOOD_W)&&(Snake_Array[0][1]>=Food_Array[1])&&(Snake_Array[0][1]<Food_Array[1]+FOOD_W))
                        begin
                            if(SnakeSize<MaxSize)
                            begin
                                SnakeSize=SnakeSize+1;
                            end
                            else 
                            begin
                                SnakeSize=MaxSize;
                            end
                            //     // �����µ�ʳ��λ��
                            // Food_Array[0]=100+((Snake_Array[0][0]*13+Snake_Array[1][0]*7+Snake_Array[2][0]*2+234)%((1200-100)/20))*20;
                            // Food_Array[1]=100+((Snake_Array[0][1]*13+Snake_Array[1][1]*7+Snake_Array[2][1]*2+Food_Array[0]+123)%((600-100)/20))*20;
                        
                            Food_Array[0] <= 40 + ((Snake_Array[0][0]*13+Snake_Array[1][0]*7+Snake_Array[2][0]*2+random_seed_x + 234) % ((1240 - 40) / 20)) * 20;
                            Food_Array[1] <= 40 + ((Snake_Array[0][1]*13+Snake_Array[1][1]*7+Snake_Array[2][1]*2+random_seed_y + 123) % ((680 - 40) / 20)) * 20;
                        end
                end
        end
end

//��Ϸ�����ַ�
localparam array_gameover_x = 640-2*HanZiSize;//�ַ�x����
localparam array_gameover_y = 360-1*HanZiSize;//�ַ�y����
localparam size_gameover =4 ;
reg     [159:0] array_gameover    [31:0]  ;   //�ַ���160 ����32
//�ַ�����Ϸ������
always@(posedge pixel_clk)
    begin
        array_gameover[0] <= 128'h00000000000000000000000000000000;
        array_gameover[1] <= 128'h00000000000000000000000000000000;
        array_gameover[2] <= 128'h003007000000e0000003c00000003c00;
        array_gameover[3] <= 128'h1e3c0f800000f0000003e00000003e00;
        array_gameover[4] <= 128'h0f1e0f000000f7000183c000381c3c00;
        array_gameover[5] <= 128'h0f9f0e000000f7c001e3c0003ffe7800;
        array_gameover[6] <= 128'h078f1e180018f3e001e3c0003c1e7800;
        array_gameover[7] <= 128'h078e1c3c003cf1f003c3c1c03c1c7018;
        array_gameover[8] <= 128'h03c7dffe7ffef0f003c3c3e03dfc703c;
        array_gameover[9] <= 128'h00fff800383cf07803fffff03dfcfffe;
        array_gameover[10] <= 128'h71fc38380038703c0383c0003ddce0e0;
        array_gameover[11] <= 128'h7d9c7ffc00787ffe0703c0003dddf0e0;
        array_gameover[12] <= 128'h3d9c7e7c307fffc0070380003dddf1e0;
        array_gameover[13] <= 128'h1f9cc0f03c7ff8600e0380003dddf1e0;
        array_gameover[14] <= 128'h1f9fe3e01e7078700e0380383ddfb1c0;
        array_gameover[15] <= 128'h031de3c00ff078f80c03807c3ddf31c0;
        array_gameover[16] <= 128'h073dc3c007f038f83ffffffe3ddf39c0;
        array_gameover[17] <= 128'h073dc3c003e039f03c07e0003ddc3bc0;
        array_gameover[18] <= 128'h0739c3dc01e03fe00007e0003fdc3b80;
        array_gameover[19] <= 128'h0e39fffe01f03fc0000770003f9c1f80;
        array_gameover[20] <= 128'h7e39fbc003f83f80000f78003f9c1f80;
        array_gameover[21] <= 128'h7e39c3c003f81f0c000f38003ff81f00;
        array_gameover[22] <= 128'h3e71c3c007fc1e0c001e3c003ff80f00;
        array_gameover[23] <= 128'h1e71c3c0073c3f0c001e1e00373e1f00;
        array_gameover[24] <= 128'h1ef1c3c00e1c7f8c003c0f000f1e3f80;
        array_gameover[25] <= 128'h1ee3c3c01e1df7cc00780f800e0e3fc0;
        array_gameover[26] <= 128'h1de383c01c03e3fc00f007e01e0efbf0;
        array_gameover[27] <= 128'h1dff83c0380783fc03e003f83c05e1f8;
        array_gameover[28] <= 128'h1f9f9fc0701f01fc078001fe7803c0fe;
        array_gameover[29] <= 128'h070f0780e03c007e1f0000fe700f807e;
        array_gameover[30] <= 128'h060c03800030001e78000038401e0018;
        array_gameover[31] <= 128'h00000000000000000000000000000000;
    end
 
integer index_draw;
reg found_match = 0; // ���һ����־��ָʾ�Ƿ��ҵ�ƥ��

// ����ͬ��������Ʋ�ͬ����ɫ
always @(posedge pixel_clk) 
begin
    case (state_1)
        game_start: begin
            GAME_EN=0;
                // ����ͼƬ
            if((pixel_xpos >= PIC_X_START) && (pixel_xpos < PIC_X_START + PIC_WIDTH)&& (pixel_ypos >= PIC_Y_START)&&(pixel_ypos < PIC_Y_START + PIC_HEIGHT))
                pixel_data <= rom_rd_data ;  //��ʾͼƬ
            else
                begin
                    pixel_data <= BACKGROUND_COLOR; // ����������ʾ������ɫ
                end
        end
        // game_back: begin
        //     GAME_EN=0;
        //   if(pixel_xpos[9:4] >=40 && pixel_xpos[9:4] < 50 && pixel_ypos[9:4] >= 20 && pixel_ypos[9:4] < 22&& char[char_y][159-char_x] == 1'b1) begin
        // 			pixel_data<= BLACK; end//��ʾ����ѡ���Ѷȡ� �ַ�
                    
        // 		  else if(pixel_xpos[9:4] >=42 && pixel_xpos[9:4] < 43 && pixel_ypos[9:4] >= 40 && pixel_ypos[9:4] < 41) begin
        // 			pixel_data<= GREEN;end//��ʾ�����ס����̷���
                    
        // 		  else if(pixel_xpos[9:4] >=44 && pixel_xpos[9:4] < 45 && pixel_ypos[9:4] >= 40 && pixel_ypos[9:4] < 41)begin
        // 			pixel_data<= BLUE;end//��ʾ���еȡ��ĻƷ���
                    
        // 	   	else if(pixel_xpos[9:4] >=46 && pixel_xpos[9:4] < 47 && pixel_ypos[9:4] >= 40 && pixel_ypos[9:4] < 41)begin
        // 			pixel_data<= RED;end//��ʾ�����ѡ��ĺ췽��
        // else begin
        //       pixel_data <= BACKGROUND_COLOR; // ����������ʾ������ɫ
        //   end 
        // end

        game: begin
            GAME_EN=1;
            if ((pixel_xpos < SIDE_W) || (pixel_xpos >= H_DISP - SIDE_W)
                || (pixel_ypos < SIDE_W) || (pixel_ypos >= V_DISP - SIDE_W)) 
                begin
                    pixel_data <= BLUE; // ������Ļ�߿�Ϊ��ɫ
                end 
            else 
                begin 
                    found_match = 0; // ��ÿ������ʱ�ӵı�Ե���ñ�־
                    for (index_draw =MaxSize-1; index_draw>=0 && !found_match; index_draw = index_draw-1)
                        begin
                            if(index_draw<SnakeSize)
                            begin
                                if (((pixel_xpos >= Snake_Array[index_draw][0]) && (pixel_xpos < Snake_Array[index_draw][0] + BLOCK_W))
                                    && ((pixel_ypos >= Snake_Array[index_draw][1]) && (pixel_ypos < Snake_Array[index_draw][1] + BLOCK_W))) 
                                    begin
                                        pixel_data <= SNAKE_COLOR; // ������
                                        found_match = 1; // ����ҵ�ƥ�䣬��ֹ��pixel_data����ΪWHITE
                                    end
                                    
                                    //���Ʊ���
                            end
                        end
                    //����ʳ��
                    if(!found_match)
                    begin
                        if((pixel_xpos>=Food_Array[0])&&(pixel_xpos<Food_Array[0]+FOOD_W)&&(pixel_ypos>=Food_Array[1])&&(pixel_ypos<Food_Array[1]+FOOD_W))
                        begin
                            pixel_data<=FOOD_COLOR;
                            found_match = 1;
                        end
                         else
                            pixel_data <= BACKGROUND_COLOR; // ���û���ҵ�ƥ�䣬����Ʊ���Ϊ��ɫ
                    end
                end

                    // if (!found_match) 
                    //    begin
                    //         if((pixel_xpos>=Food_Array[0])&&(pixel_xpos<Food_Array[0]+FOOD_W)&&(pixel_ypos>=Food_Array[1])&&(pixel_ypos<Food_Array[1]+FOOD_W))
                    //             begin
                    //                 pixel_data<=FOOD_COLOR;
                    //             end
                    //         else
                    //             pixel_data <= BACKGROUND_COLOR; // ���û���ҵ�ƥ�䣬����Ʊ���Ϊ��ɫ
                    //     end

            //������ʾ
            if(dead==1)
                begin
                    if(pixel_ypos-array_gameover_y>=0&&pixel_ypos-array_gameover_y<32&&size_gameover*HanZiSize-pixel_xpos+array_gameover_x-1>=0&&size_gameover*HanZiSize-pixel_xpos+array_gameover_x-1<size_gameover*HanZiSize)
                    begin
                    
                    if(array_gameover[pixel_ypos-array_gameover_y][size_gameover*HanZiSize-pixel_xpos+array_gameover_x-1])
                    begin
                        pixel_data<=CHAR_COLOR;
                    end
                    end
                    // GAME_EN=0;
                end
        end
    endcase
end

//���ݵ�ǰɨ���ĺ�������ΪROM��ַ��ֵ

always @(posedge pixel_clk)
begin
   if(!sys_rst_n)

         rom_addr <= 14'd0;

     //����������λ��ͼƬ��ʾ����ʱ���ۼ�ROM��ַ   

     else if((pixel_ypos >= PIC_Y_START) && (pixel_ypos < PIC_Y_START + PIC_HEIGHT)

         && (pixel_xpos >= PIC_X_START) && (pixel_xpos < PIC_X_START + PIC_WIDTH))

         rom_addr <= rom_addr + 1'b1;

     //����������λ��ͼƬ�������һ�����ص�ʱ��ROM��ַ����   

     else if((pixel_ypos >= PIC_Y_START + PIC_HEIGHT))

         rom_addr <= 14'd0;

 end


 //ROM���洢ͼƬ

 blk_mem_gen u_blk_mem_gen (

   .clka(pixel_clk), // input clka

   .ena(rom_rd_en), // input ena

   .wea(wea), // input [3 : 0] wea

   .addra(rom_addr), // input [31 : 0] addra

   .dina(dina), // input [31 : 0] dina

   .douta(rom_rd_data) // output [31 : 0] douta

 );

endmodule 
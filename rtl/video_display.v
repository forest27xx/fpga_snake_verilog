/*******************************************************
 * FPGA-Based 贪吃蛇
  * School:CSU
 * Class: 自动化 T2101
 * Students: 刘凯-8210211913, 吴森林-8212211224
 * Instructor: 罗旗舞
 *******************************************************/



module  video_display(
    input             pixel_clk,                  //VGA驱动时钟
    input             sys_rst_n,                //复位信号
    input      [5:0]   speed_change,
    input      [10:0] pixel_xpos,               //像素点横坐标
    input      [10:0] pixel_ypos,               //像素点纵坐标   
    input       [5:0]key,//控制上下左右
    input	 [2:0]	state_1,//菜单状态
    input [1:0]difficulty,
    output reg [23:0] pixel_data,                //像素点数据
    output reg [5:0]Score
    );    

//parameter define    
parameter  H_DISP  = 11'd1280;                  //分辨率--行
parameter  V_DISP  = 11'd720;                   //分辨率--列

localparam SIDE_W  = 11'd40;                    //屏幕边框宽度
localparam BLOCK_W = 11'd20;                    //方块宽度
localparam BLUE    = 24'b00000000_00000000_11111111;    // 蓝色
localparam WHITE   = 24'b11111111_11111111_11111111;    // 白色
localparam BLACK   = 24'b00000000_00000000_00000000;    // 黑色
localparam RED    = 24'b11111111_00000000_00000000; // 红色
localparam GREEN  = 24'b00000000_11111111_00000000; // 绿色
localparam Crimson = 24'hDC143C;//赤红色
localparam PURPLE=24'h800080;
//定义各种实例化颜色
localparam FOOD_COLOR =Crimson ;
localparam SNAKE_COLOR =GREEN ;
localparam CHAR_COLOR =BLACK ;
localparam BACKGROUND_COLOR =WHITE ;
//定义初始位置，汉字大小
localparam INI_X =11'd640 ;//初始位置
localparam INI_Y =11'd320 ;
localparam StandardF =20'd742500;
localparam HanZiSize =32 ;




//定义食物
localparam FOOD_W =11'd20 ;//食物大小
localparam FOOD_X=11'd360 ;
localparam FOOD_Y=11'd400 ;
reg [10:0]Food_Array[1:0];
reg FoodGene;
    //定义食物随机数
wire  [9:0]RandomX;
wire [9:0]RandomY;

//定义三个状态
parameter game_start	= 3'b001;  //游戏界面的开始选项
parameter game_back		= 3'b010;  //游戏界面的返回选项
parameter game			= 3'b100;  //游戏中
//reg define
reg   [13:0]  rom_addr  ;  //ROM地址
reg [10:0] block_x = INI_X ;                             //方块左上角横坐标
reg [10:0] block_y = INI_Y ;                             //方块左上角纵坐标

//定义蛇
reg [3:0] SnakeSize=3;//定义蛇长度
localparam MaxSize =10 ;//16
reg [10:0] Snake_Array[MaxSize-1:0][1:0]; // 定义蛇的每节的坐标数组
reg [1:0]speed=1;

//定义计数，用于更改蛇的速度
reg [25:0] div_cnt;                             //时钟分频计数器
reg        h_direct;                            //方块水平移动方向，1：右移，0：左移
reg        v_direct;                            //方块竖直移动方向，1：向下，0：右移
reg [1:0]direction;

//定义ROM
wire          rom_rd_en ;  //ROM读使能信号
wire  [23:0]  rom_rd_data ;//ROM数据

//定义使能端
wire move_en;                                   //方块移动使能信号，频率为100hz
reg MOEN;                                       //按键移动是能
reg GAME_EN=0;//游戏使能
assign move_en = (div_cnt == StandardF*10/(difficulty)) ? 1'b1 : 1'b0;//移动速度使能标志
assign  rom_rd_en = 1'b1;                  //读使能拉高，即一直读ROM数据

//随机数生成
//rng_custom_range Ran1(pixel_clk,sys_rst_n,FoodGene,11'd100,11'd1000,RandomX);
//rng_custom_range Ran2(pixel_clk,sys_rst_n,FoodGene,11'd100,11'd600,RandomY);

//随机数生成2

// 随机数生成器作为随机种子
reg  [10:0] random_seed_x=11'd135;
reg  [10:0] random_seed_y=11'd246;
reg generate_food_signal=0;
// 每次需要生成食物时更新随机种子
always @(posedge pixel_clk) begin
    random_seed_x <= (random_seed_x + 1'b1) ^ {3'b101, random_seed_x[10:3]}; // LFSR逻辑
    random_seed_y <= (random_seed_y + 1'b1) ^ {3'b010, random_seed_y[10:3]}; // 
end
// 使用随机种子生成食物位置



//按键切换
always @(posedge pixel_clk) 
begin
        if (!sys_rst_n||dead) begin
            MOEN=0;direction=0;
        end
        if(GAME_EN==1)//游戏进入才能进行更改方向，防止游戏进入之前就有初速以及方向
        begin
            if (key[0] == 1) 
                begin  // 上
                    if(!(direction==1))
                        begin
                            direction=0;
                        end
                    if(direction==1)
                        begin   
                            direction=direction;
                        end
                    if(Snake_Array[0][1]==Snake_Array[1][1]+BLOCK_W)//蛇头在下，不允许向上
                        begin
                            direction=direction;
                        end
                    MOEN=1;
                end
            else if (key[1] == 1) 
                begin  // 下
                    if(!(direction==0))
                        begin
                            direction=1;
                        end
                    if(direction==0)
                        begin
                            direction=direction;
                        end
                    if(Snake_Array[0][1]==Snake_Array[1][1]-BLOCK_W)//蛇头在上，不允许向下
                        begin
                            direction=direction;
                        end
                    MOEN=1;
                end
            else if (key[2] == 1) 
                begin  // 左
                    if(MOEN==0)//初始不能往左
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
                        if(Snake_Array[0][0]==Snake_Array[1][0]+BLOCK_W)//蛇头在右，不允许向左
                            begin
                                direction=direction;
                            end
                    end
                    MOEN=1;
                end
            else if (key[3] == 1) 
                begin  // 右
                    if(!(direction==2'd2))
                    begin
                       direction=2'd3;
                    end
                    if(direction==2'd2)
                    begin
                        direction=2'd2;
                    end
                    if(Snake_Array[0][0]==Snake_Array[1][0]-BLOCK_W)//蛇头在左，不允许向右
                        begin
                            direction=direction;
                        end
                    MOEN=1;
                end
        end
end

//通过对vga驱动时钟计数，实现时钟分频，从而实现速度定义
always @(posedge pixel_clk ) begin         
    if (!sys_rst_n)
        div_cnt <= 0;
    else begin
        if(div_cnt < StandardF*10/(difficulty)) //这里要加，否则速度改变不了
            div_cnt <= div_cnt + 1'b1;
        else
            div_cnt <= 0;                   //计数达上限后清零
    end
end

//切换速度
always @(posedge pixel_clk) begin
    if(speed_change[0]==1)
    begin
        if(speed<=3)
        begin
            speed=speed+1;
        end
        else
        begin
            speed=1;
        end
    end
end

//定义一堆临时变量，珍妮天的verilog，不能直接创建
integer index0;
integer index1;
integer index2;
integer index3;
integer index4;
integer index5;//判断相撞死亡标志
reg dead=0;//死亡标志

//蛇移动模块，根据方块移动方向，改变其纵横坐标
always @(posedge pixel_clk ) begin  
    //    应该放到EN外面，否则会导致跳转不出死亡界面之外
    //切换则死亡逻辑变0
    if(state_1==game_start)
        begin
            dead=0;
        end
    if(!dead)  
        begin
            if (!sys_rst_n||!GAME_EN) 
                begin
                    SnakeSize=3;
                    for(index0=0; index0<MaxSize; index0=index0+1) //因为for循环的上限不能设为变量（不可综合），只能用定值，可对下标进行判断是否符合界限，从而实现扫描
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
                    Food_Array[0] <= 11'd360; // 假设的初始X坐标
                    Food_Array[1] <= 11'd400; // 假设的初始Y坐标
                end
            if (move_en&&MOEN&&GAME_EN) 
                begin
                    case (direction)//根据方向的不同，进行不同的移位策略
                        2'd0:
                        begin
                            for(index1=MaxSize-1; index1>0; index1=index1-1) begin//采用for循环的形式，从后面往前面递进
                                if(index1<SnakeSize)begin
                                Snake_Array[index1][0] = Snake_Array[index1-1][0];
                                Snake_Array[index1][1] = Snake_Array[index1-1][1];
                                end
                            end
                            Snake_Array[0][1] = Snake_Array[0][1] -BLOCK_W;//这里要注意是加BLOCK_W,之前设为1，导致蛇重合成一个方块了。还以为是蛇移动和draw频率的问题
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
                            Snake_Array[0][0] = Snake_Array[0][0] -BLOCK_W; // 修正为x坐标
                        end
                        2'd3:
                        begin
                            for(index4=MaxSize-1; index4>0; index4=index4-1) begin
                                if(index4<SnakeSize)begin
                                Snake_Array[index4][0] = Snake_Array[index4-1][0]; // 修正变量名称
                                Snake_Array[index4][1] = Snake_Array[index4-1][1];
                                end
                            end
                            Snake_Array[0][0] = Snake_Array[0][0] + BLOCK_W; // 修正为x坐标
                        end
                    endcase
                    //相撞死亡逻辑
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
                    //吃到食物,食物更新逻辑        
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
                            //     // 生成新的食物位置
                            // Food_Array[0]=100+((Snake_Array[0][0]*13+Snake_Array[1][0]*7+Snake_Array[2][0]*2+234)%((1200-100)/20))*20;
                            // Food_Array[1]=100+((Snake_Array[0][1]*13+Snake_Array[1][1]*7+Snake_Array[2][1]*2+Food_Array[0]+123)%((600-100)/20))*20;
                        
                            Food_Array[0] <= 40 + ((Snake_Array[0][0]*13+Snake_Array[1][0]*7+Snake_Array[2][0]*2+random_seed_x + 234) % ((1240 - 40) / 20)) * 20;
                            Food_Array[1] <= 40 + ((Snake_Array[0][1]*13+Snake_Array[1][1]*7+Snake_Array[2][1]*2+random_seed_y + 123) % ((680 - 40) / 20)) * 20;
                        end
                end
        end
end

//定义文字相关参数
localparam Gap =40 ;
localparam xcenter =600 ;
localparam ycenter =360 ;
//定义图片              
localparam PIC_X_START = xcenter-50;      //图片起始点横坐标
localparam PIC_Y_START = ycenter+Gap*(-7);      //图片起始点纵坐标
localparam PIC_WIDTH   = 11'd100;    //图片宽度
localparam PIC_HEIGHT  = 11'd100;    //图片高度
reg [7:0] gray_value; // 用于存储计算出的灰度值
//游戏结束字符
localparam array_gameover_size =4 ;
localparam array_gameover_x = xcenter-(array_gameover_size/2)*HanZiSize;//字符x坐标
localparam array_gameover_y = ycenter-1*HanZiSize;//字符y坐标
reg     [127:0] array_gameover    [31:0]  ;   //字符宽160 ，高32

localparam array_title_size =6 ;
localparam array_title_x = xcenter-(array_title_size/2)*HanZiSize;//字符x坐标
localparam array_title_y = (ycenter+Gap*(-3))-1*HanZiSize;//字符y坐标
reg     [191:0] array_title    [31:0]  ;   //字符宽160 ，高32
//字符“游戏结束”//测试
localparam array_easy_size =2 ;
localparam array_easy_x = xcenter-(array_easy_size/2)*HanZiSize;//字符x坐标
localparam array_easy_y = (ycenter+Gap*(-1))-1*HanZiSize;//字符y坐标
reg     [63:0] array_easy    [31:0]  ;   //字符宽160 ，高32

localparam array_normal_size =2 ;
localparam array_normal_x = xcenter-(array_normal_size/2)*HanZiSize;//字符x坐标
localparam array_normal_y = (ycenter+Gap*(0))-1*HanZiSize;//字符y坐标
reg     [63:0] array_normal    [31:0]  ;   //字符宽160 ，高32

//字符难
localparam array_hard_size =2 ;
localparam array_hard_x = xcenter-(array_hard_size/2)*HanZiSize;//字符x坐标
localparam array_hard_y = (ycenter+Gap*(1))-1*HanZiSize;//字符y坐标
reg     [63:0] array_hard    [31:0]  ;   //字符宽160 ，高32

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


always@(posedge pixel_clk)
    begin
    array_title[4] <= 192'h001fc0000000f00003800f000003800001f1e00001e03bc0;
    array_title[5] <= 192'h001ee0000000f00003800f000003800001e1c00001c039f0;
    array_title[6] <= 192'h003f78003871e018038187000003800001c3c03801c038f0;
    array_title[7] <= 192'h007fbe003ff9c03c0381871c0003800003c3807c01c338f0;
    array_title[8] <= 192'h01f3df803873fffe0381fffe000380380387fffe01c7b870;
    array_title[9] <= 192'h03e3cffe38738000339f801e0003807c0787700001fff838;
    array_title[10] <= 192'h0f81cffe387700003fff80387ffffffe078f700001c0383c;
    array_title[11] <= 192'h3fffff7c387f00003bbf8038380380000fce700001c03ffe;
    array_title[12] <= 192'h79c03e00387e00003bbff0300003c0000fdc700001cfff00;
    array_title[13] <= 192'h60007c00387c03c03bbc78000003c0001f9c706001c73c20;
    array_title[14] <= 192'h0000f800387fffe03bbc70300007c0001fb870f001c03c78;
    array_title[15] <= 192'h0380f380387707c03bbc70780007e0003bf07ff801c03c7c;
    array_title[16] <= 192'h03ffffc038700f803bbc70f80007e0003be0700039ce1cf8;
    array_title[17] <= 192'h03c0078038701f003bbc71f000077000738070003fff1cf0;
    array_title[18] <= 192'h03c3078038701e003bbc73e0000f700063807000380e1cf0;
    array_title[19] <= 192'h03c3c78038703c003ffc7f80000f780003807000380e1de0;
    array_title[20] <= 192'h03c3c7803ff078003bbc7e00000e380003807030380e1fc0;
    array_title[21] <= 192'h03c387803870f01833a07800001e1c0003807078380e1fc0;
    array_title[22] <= 192'h03c787803871f01803f8701c001c1e0003807ffc380e0f8c;
    array_title[23] <= 192'h03c787803871e01803bc701c003c0f0003807000380e0f8c;
    array_title[24] <= 192'h03c707803803c018039c701c0078078003807000380e1f9c;
    array_title[25] <= 192'h038ffc000007801803fe701c00f007e003807000380e3f9c;
    array_title[26] <= 192'h001e7fc00007803c3ffe701c01e003f0038070003ffe7bfc;
    array_title[27] <= 192'h003c0ff00007803e7f0e701c03c001fe03807000380ff1fc;
    array_title[28] <= 192'h01f803f80007fffe780c7ffe0f8000fe03807000380fe0fc;
    array_title[29] <= 192'h07e000f80003fffc30007ffe3e00003803807000380f807c;
    array_title[30] <= 192'h3f00007800000000000000007800000003807000001e003e;
    array_title[31] <= 192'h000000000000000000000000000000000000000000000000;
    end



//字符“简单”
always@(posedge pixel_clk)
    begin
    array_easy[0] <= 64'h0000000000000000;
    array_easy[1] <= 64'h0000000000000000;
    array_easy[2] <= 64'h0380380000e00e00;
    array_easy[3] <= 64'h03c07c0000781f00;
    array_easy[4] <= 64'h07877838003c1e00;
    array_easy[5] <= 64'h07fffffc003c3c00;
    array_easy[6] <= 64'h0ff0ef00001c3800;
    array_easy[7] <= 64'h1e79c780071c71c0;
    array_easy[8] <= 64'h3c7b878007ffffe0;
    array_easy[9] <= 64'h7bfb0300078381e0;
    array_easy[10] <= 64'h71e00070078381c0;
    array_easy[11] <= 64'h0dfffff8078381c0;
    array_easy[12] <= 64'h0ff70078078381c0;
    array_easy[13] <= 64'h0fe0007007ffffc0;
    array_easy[14] <= 64'h0e183870078381c0;
    array_easy[15] <= 64'h0e1ffc70078381c0;
    array_easy[16] <= 64'h0e1c3c70078381c0;
    array_easy[17] <= 64'h0e1c3870078381c0;
    array_easy[18] <= 64'h0e1c387007ffffc0;
    array_easy[19] <= 64'h0e1c3870078381c0;
    array_easy[20] <= 64'h0e1ff870078381b8;
    array_easy[21] <= 64'h0e1c38700603807c;
    array_easy[22] <= 64'h0e1c38707ffffffe;
    array_easy[23] <= 64'h0e1c387030038000;
    array_easy[24] <= 64'h0e1ff87000038000;
    array_easy[25] <= 64'h0e1c387000038000;
    array_easy[26] <= 64'h0e1c307000038000;
    array_easy[27] <= 64'h0e000ff000038000;
    array_easy[28] <= 64'h0e000ff000038000;
    array_easy[29] <= 64'h0e0001f000038000;
    array_easy[30] <= 64'h0e0000e000038000;
    array_easy[31] <= 64'h0000000000000000;
    end


//字符“普通”
always@(posedge pixel_clk)
    begin
        array_normal[0] <= 64'h0000000000000000;
        array_normal[1] <= 64'h0000000000000000;
        array_normal[2] <= 64'h00700e00000000e0;
        array_normal[3] <= 64'h003c1f001c1ffff0;
        array_normal[4] <= 64'h003e1e001e0e03f0;
        array_normal[5] <= 64'h001e3c300f01e7c0;
        array_normal[6] <= 64'h001e78780f00ff00;
        array_normal[7] <= 64'h1ffffffc07007c00;
        array_normal[8] <= 64'h0e1e7980071c3c78;
        array_normal[9] <= 64'h071e79e0001ffff8;
        array_normal[10] <= 64'h03de79e0001c3878;
        array_normal[11] <= 64'h01fe7bc0001c3878;
        array_normal[12] <= 64'h01fe7b80039c3878;
        array_normal[13] <= 64'h01fe7f187fdffff8;
        array_normal[14] <= 64'h00de7e3c7f9c3878;
        array_normal[15] <= 64'hfffffffe079c3878;
        array_normal[16] <= 64'h70000000079c3878;
        array_normal[17] <= 64'h00000000079c3878;
        array_normal[18] <= 64'h01c00780079ffff8;
        array_normal[19] <= 64'h01ffffc0079c3878;
        array_normal[20] <= 64'h01e00780079c3878;
        array_normal[21] <= 64'h01e00780079c3878;
        array_normal[22] <= 64'h01e00780079c3878;
        array_normal[23] <= 64'h01ffff80079c3ff8;
        array_normal[24] <= 64'h01e007800f9c3ff0;
        array_normal[25] <= 64'h01e007801ffc30f0;
        array_normal[26] <= 64'h01e007807cf80060;
        array_normal[27] <= 64'h01e00780787fffff;
        array_normal[28] <= 64'h01ffff80781ffffc;
        array_normal[29] <= 64'h01e007803007fff8;
        array_normal[30] <= 64'h01e0070000000000;
        array_normal[31] <= 64'h0000000000000000;
    end


//字符“困难”
always@(posedge pixel_clk)
    begin
       array_hard[0] <= 64'h0000000000000000;
        array_hard[1] <= 64'h0000000000000000;
        array_hard[2] <= 64'h1c0000700000ee00;
        array_hard[3] <= 64'h1ffffff80000ff00;
        array_hard[4] <= 64'h1e03c0780000f780;
        array_hard[5] <= 64'h1e03e0780000f780;
        array_hard[6] <= 64'h1e03c078003de398;
        array_hard[7] <= 64'h1e03c0783fffe33c;
        array_hard[8] <= 64'h1e03c3781c3dfffc;
        array_hard[9] <= 64'h1e03c7f80039c700;
        array_hard[10] <= 64'h1ffffff8303bc700;
        array_hard[11] <= 64'h1fc7c078387bc700;
        array_hard[12] <= 64'h1e0fc0781c7fc730;
        array_hard[13] <= 64'h1e0fc0780e77c778;
        array_hard[14] <= 64'h1e1ff0780f7ffffc;
        array_hard[15] <= 64'h1e1ffc7807ffc700;
        array_hard[16] <= 64'h1e3ffe7803fdc700;
        array_hard[17] <= 64'h1e3bdf7801f9c700;
        array_hard[18] <= 64'h1e7bcff801e1c700;
        array_hard[19] <= 64'h1ef3c7f803f1c730;
        array_hard[20] <= 64'h1fe3c7f803f1c778;
        array_hard[21] <= 64'h1fc3c37807f9fffc;
        array_hard[22] <= 64'h1f83c0780739c700;
        array_hard[23] <= 64'h1e03c0780e3dc700;
        array_hard[24] <= 64'h1e03c0781e3dc700;
        array_hard[25] <= 64'h1e03c0783c19c718;
        array_hard[26] <= 64'h1e0300787819c73c;
        array_hard[27] <= 64'h1e000078f001fffe;
        array_hard[28] <= 64'h1ffffff8c001c000;
        array_hard[29] <= 64'h1e0000780001c000;
        array_hard[30] <= 64'h1e0000700001c000;
        array_hard[31] <= 64'h0000000000000000;
    end

localparam array_select_size =1 ;

localparam array_select_x = xcenter-(array_select_size/2)*HanZiSize-Gap*3;//字符x坐标
// wire array_select_y;
// assign array_select_y = ((difficulty == 3) ? array_hard_y :
//                         ((difficulty == 2) ? array_normal_y :
//                         array_easy_y)); // 注意：这里使用array_select_y可能导致逻辑错误，除非它之前已被赋值
reg array_select_y;
always @(posedge pixel_clk or negedge sys_rst_n) 
begin
    if(!sys_rst_n)
    begin
        array_select_y=array_easy_y;
    end
    else 
    begin
    case(difficulty)
        1:array_select_y=array_easy_y;
        2:array_select_y=array_normal_y;
        3:array_select_y=array_hard_y;
        default:array_select_y=array_easy_y;
    endcase
    end
end


reg     [63:0] array_select    [31:0]  ;   //字符宽160 ，高32

//字符“@”
always@(posedge pixel_clk)
    begin
       array_select[0] <= 32'h00000000;
        array_select[1] <= 32'h00000000;
        array_select[2] <= 32'h001ffc00;
        array_select[3] <= 32'h007fff00;
        array_select[4] <= 32'h01f80f80;
        array_select[5] <= 32'h03e003e0;
        array_select[6] <= 32'h07c001e0;
        array_select[7] <= 32'h0f8000f0;
        array_select[8] <= 32'h1f000078;
        array_select[9] <= 32'h1e000038;
        array_select[10] <= 32'h3c07c038;
        array_select[11] <= 32'h3c1ff818;
        array_select[12] <= 32'h3c3ef81c;
        array_select[13] <= 32'h387c781c;
        array_select[14] <= 32'h78787818;
        array_select[15] <= 32'h78f07038;
        array_select[16] <= 32'h78f0f038;
        array_select[17] <= 32'h78f0f038;
        array_select[18] <= 32'h38f0f070;
        array_select[19] <= 32'h3cf1e070;
        array_select[20] <= 32'h3cf1e0e0;
        array_select[21] <= 32'h3c7be3e0;
        array_select[22] <= 32'h3e7fffc0;
        array_select[23] <= 32'h1f1eff00;
        array_select[24] <= 32'h0f000000;
        array_select[25] <= 32'h0f8000e0;
        array_select[26] <= 32'h07e001e0;
        array_select[27] <= 32'h03f807c0;
        array_select[28] <= 32'h00ffff80;
        array_select[29] <= 32'h003ffe00;
        array_select[30] <= 32'h0003c000;
        array_select[31] <= 32'h00000000;
    end
integer index_draw;
reg found_match = 0; // 添加一个标志来指示是否找到匹配

// 给不同的区域绘制不同的颜色
always @(posedge pixel_clk) 
begin
    case (state_1)
        game_start: 
        begin
            GAME_EN=0;
                // 绘制图片
            if((pixel_xpos >= PIC_X_START) && (pixel_xpos < PIC_X_START + PIC_WIDTH)&& (pixel_ypos >= PIC_Y_START)&&(pixel_ypos < PIC_Y_START + PIC_HEIGHT))
              if(key[3]== 0 )
                pixel_data <= rom_rd_data ;  //显示图片
              else begin
					      gray_value = (rom_rd_data[23:16]*30 + rom_rd_data[15:8]*59 + rom_rd_data[7:0]*11) / 100;//灰度计算
                pixel_data <= {gray_value, gray_value, gray_value};     
						    end
            else  if(pixel_ypos-array_title_y>=0&&pixel_ypos-array_title_y<32&&array_title_size*HanZiSize-pixel_xpos+array_title_x>=0&&array_title_size*HanZiSize-pixel_xpos+array_title_x<array_title_size*HanZiSize)
                    begin
                    
                    if(array_title[pixel_ypos-array_title_y][array_title_size*HanZiSize-pixel_xpos+array_title_x])
                    begin
                        pixel_data<=CHAR_COLOR;
                    end
                    else begin
                        pixel_data<=BACKGROUND_COLOR;
                    end
                    end
            else  if(pixel_ypos-array_easy_y>=0&&pixel_ypos-array_easy_y<32&&array_easy_size*HanZiSize-pixel_xpos+array_easy_x>=0&&array_easy_size*HanZiSize-pixel_xpos+array_easy_x<array_easy_size*HanZiSize)
                    begin
                    
                    if(array_easy[pixel_ypos-array_easy_y][array_easy_size*HanZiSize-pixel_xpos+array_easy_x])
                    begin
                        pixel_data<=GREEN;
                    end
                    else begin
                        pixel_data<=BACKGROUND_COLOR;
                    end
                    end
            else  if(pixel_ypos-array_normal_y>=0&&pixel_ypos-array_normal_y<32&&array_normal_size*HanZiSize-pixel_xpos+array_normal_x>=0&&array_normal_size*HanZiSize-pixel_xpos+array_normal_x<array_normal_size*HanZiSize)
                    begin
                    
                    if(array_normal[pixel_ypos-array_normal_y][array_normal_size*HanZiSize-pixel_xpos+array_normal_x])
                    begin
                        pixel_data<=BLUE;
                    end
                    else begin
                        pixel_data<=BACKGROUND_COLOR;
                    end
                    end
             else  if(pixel_ypos-array_hard_y>=0&&pixel_ypos-array_hard_y<32&&array_hard_size*HanZiSize-pixel_xpos+array_hard_x>=0&&array_hard_size*HanZiSize-pixel_xpos+array_hard_x<array_hard_size*HanZiSize)
                    begin
                    
                    if(array_hard[pixel_ypos-array_hard_y][array_hard_size*HanZiSize-pixel_xpos+array_hard_x])
                    begin
                        pixel_data<=RED;
                    end
                    else begin
                        pixel_data<=BACKGROUND_COLOR;
                    end
                    end
            else  if((pixel_ypos-array_easy_y>=0&&pixel_ypos-array_easy_y<32&&array_select_size*HanZiSize-pixel_xpos+array_select_x>=0&&array_select_size*HanZiSize-pixel_xpos+array_select_x<array_select_size*HanZiSize)||(pixel_ypos-array_normal_y>=0&&pixel_ypos-array_normal_y<32&&array_select_size*HanZiSize-pixel_xpos+array_select_x>=0&&array_select_size*HanZiSize-pixel_xpos+array_select_x<array_select_size*HanZiSize)||(pixel_ypos-array_hard_y>=0&&pixel_ypos-array_hard_y<32&&array_select_size*HanZiSize-pixel_xpos+array_select_x>=0&&array_select_size*HanZiSize-pixel_xpos+array_select_x<array_select_size*HanZiSize))
                    begin
                    case (difficulty)
                        1: begin
                             if((array_select[pixel_ypos-array_easy_y][array_select_size*HanZiSize-pixel_xpos+array_select_x])&&(pixel_ypos-array_easy_y>=0&&pixel_ypos-array_easy_y<32&&array_select_size*HanZiSize-pixel_xpos+array_select_x>=0&&array_select_size*HanZiSize-pixel_xpos+array_select_x<array_select_size*HanZiSize))
                                begin
                                    pixel_data<=RED;
                                end
                                else begin
                                    pixel_data<=BACKGROUND_COLOR;
                                end
                             end
                         2: begin
                             if((array_select[pixel_ypos-array_normal_y][array_select_size*HanZiSize-pixel_xpos+array_select_x])&&(pixel_ypos-array_normal_y>=0&&pixel_ypos-array_normal_y<32&&array_select_size*HanZiSize-pixel_xpos+array_select_x>=0&&array_select_size*HanZiSize-pixel_xpos+array_select_x<array_select_size*HanZiSize))
                                begin
                                    pixel_data<=RED;
                                end
                                else begin
                                    pixel_data<=BACKGROUND_COLOR;
                                end
                             end
                         3: begin
                             if((array_select[pixel_ypos-array_hard_y][array_select_size*HanZiSize-pixel_xpos+array_select_x])&&(pixel_ypos-array_hard_y>=0&&pixel_ypos-array_hard_y<32&&array_select_size*HanZiSize-pixel_xpos+array_select_x>=0&&array_select_size*HanZiSize-pixel_xpos+array_select_x<array_select_size*HanZiSize))
                                begin
                                    pixel_data<=RED;
                                end
                                else begin
                                    pixel_data<=BACKGROUND_COLOR;
                                end
                             end
                        default: begin
                             if((array_select[pixel_ypos-array_easy_y][array_select_size*HanZiSize-pixel_xpos+array_select_x])&&(pixel_ypos-array_easy_y>=0&&pixel_ypos-array_easy_y<32&&array_select_size*HanZiSize-pixel_xpos+array_select_x>=0&&array_select_size*HanZiSize-pixel_xpos+array_select_x<array_select_size*HanZiSize))
                                begin
                                    pixel_data<=RED;
                                end
                                else begin
                                    pixel_data<=BACKGROUND_COLOR;
                                end
                             end
                    endcase
                   
                    end
            else
                begin
                    pixel_data <= BACKGROUND_COLOR; // 其他区域显示背景颜色
                end
        end
        // game_back: begin
        //     GAME_EN=0;
        //   if(pixel_xpos[9:4] >=40 && pixel_xpos[9:4] < 50 && pixel_ypos[9:4] >= 20 && pixel_ypos[9:4] < 22&& char[char_y][159-char_x] == 1'b1) begin
        // 			pixel_data<= BLACK; end//显示“请选择难度” 字符
                    
        // 		  else if(pixel_xpos[9:4] >=42 && pixel_xpos[9:4] < 43 && pixel_ypos[9:4] >= 40 && pixel_ypos[9:4] < 41) begin
        // 			pixel_data<= GREEN;end//显示“容易”的绿方块
                    
        // 		  else if(pixel_xpos[9:4] >=44 && pixel_xpos[9:4] < 45 && pixel_ypos[9:4] >= 40 && pixel_ypos[9:4] < 41)begin
        // 			pixel_data<= BLUE;end//显示“中等”的黄方块
                    
        // 	   	else if(pixel_xpos[9:4] >=46 && pixel_xpos[9:4] < 47 && pixel_ypos[9:4] >= 40 && pixel_ypos[9:4] < 41)begin
        // 			pixel_data<= RED;end//显示“困难”的红方块
        // else begin
        //       pixel_data <= BACKGROUND_COLOR; // 其他区域显示背景颜色
        //   end 
        // end

        game: begin
            GAME_EN=1;
            if ((pixel_xpos < SIDE_W) || (pixel_xpos >= H_DISP - SIDE_W)
                || (pixel_ypos < SIDE_W) || (pixel_ypos >= V_DISP - SIDE_W)) 
                begin
                    pixel_data <= PURPLE; // 绘制屏幕边框为蓝色
                end 
            else 
                begin 
                    found_match = 0; // 在每次像素时钟的边缘重置标志
                    for (index_draw =MaxSize-1; index_draw>=0 && !found_match; index_draw = index_draw-1)
                        begin
                            if(index_draw<SnakeSize)
                            begin
                                if (((pixel_xpos >= Snake_Array[index_draw][0]) && (pixel_xpos < Snake_Array[index_draw][0] + BLOCK_W))
                                    && ((pixel_ypos >= Snake_Array[index_draw][1]) && (pixel_ypos < Snake_Array[index_draw][1] + BLOCK_W))) 
                                    begin
                                        pixel_data <= SNAKE_COLOR; // 绘制蛇
                                        found_match = 1; // 标记找到匹配，防止将pixel_data设置为WHITE
                                    end
                                    
                                    //绘制背景
                            end
                        end
                    //绘制食物
                    if(!found_match)
                    begin
                        if((pixel_xpos>=Food_Array[0])&&(pixel_xpos<Food_Array[0]+FOOD_W)&&(pixel_ypos>=Food_Array[1])&&(pixel_ypos<Food_Array[1]+FOOD_W))
                        begin
                            pixel_data<=FOOD_COLOR;
                            found_match = 1;
                        end
                         else
                            pixel_data <= BACKGROUND_COLOR; // 如果没有找到匹配，则绘制背景为白色
                    end
                end

                    // if (!found_match) 
                    //    begin
                    //         if((pixel_xpos>=Food_Array[0])&&(pixel_xpos<Food_Array[0]+FOOD_W)&&(pixel_ypos>=Food_Array[1])&&(pixel_ypos<Food_Array[1]+FOOD_W))
                    //             begin
                    //                 pixel_data<=FOOD_COLOR;
                    //             end
                    //         else
                    //             pixel_data <= BACKGROUND_COLOR; // 如果没有找到匹配，则绘制背景为白色
                    //     end

            //死亡提示
            if(dead==1)
                begin
                    if(pixel_ypos-array_gameover_y>=0&&pixel_ypos-array_gameover_y<32&&array_gameover_size*HanZiSize-pixel_xpos+array_gameover_x-1>=0&&array_gameover_size*HanZiSize-pixel_xpos+array_gameover_x-1<array_gameover_size*HanZiSize)
                    begin
                    
                    if(array_gameover[pixel_ypos-array_gameover_y][array_gameover_size*HanZiSize-pixel_xpos+array_gameover_x-1])
                    begin
                        pixel_data<=CHAR_COLOR;
                    end
                    end
                    // GAME_EN=0;
                end
        end
    endcase
end

//根据当前扫描点的横纵坐标为ROM地址赋值

always @(posedge pixel_clk)
begin
   if(!sys_rst_n)

         rom_addr <= 14'd0;

     //当横纵坐标位于图片显示区域时，累加ROM地址   

     else if((pixel_ypos >= PIC_Y_START) && (pixel_ypos < PIC_Y_START + PIC_HEIGHT)

         && (pixel_xpos >= PIC_X_START) && (pixel_xpos < PIC_X_START + PIC_WIDTH))

         rom_addr <= rom_addr + 1'b1;

     //当横纵坐标位于图片区域最后一个像素点时，ROM地址清零   

     else if((pixel_ypos >= PIC_Y_START + PIC_HEIGHT))

         rom_addr <= 14'd0;
 end


 //ROM：存储图片

 blk_mem_gen u_blk_mem_gen (

   .clka(pixel_clk), // input clka

   .ena(rom_rd_en), // input ena

   .wea(wea), // input [3 : 0] wea

   .addra(rom_addr), // input [31 : 0] addra

   .dina(dina), // input [31 : 0] dina

   .douta(rom_rd_data) // output [31 : 0] douta

 );

always @(posedge pixel_clk or negedge sys_rst_n) 
begin
    if(!sys_rst_n||key[5]==1)
        begin
            Score<=0;
        end
    else 
        begin
            Score<=(SnakeSize-3)*difficulty*5;
        end
end    
endmodule 
/*******************************************************
 * FPGA-Based ̰����
  * School:CSU
 * Class: �Զ��� T2101
 * Students: ����-8210211913, ��ɭ��-8212211224
 * Instructor: ������
 *******************************************************/
//hdmi��ʾģ��

module  hdmi_block_move_top(
    input        sys_clk,
    input        sys_rst_n,
    input       speed_change,
    input       [5:0]key_in,//������������
 	 
    output       tmds_clk_p,    // TMDS ʱ��ͨ��
    output       tmds_clk_n,
    output [2:0] tmds_data_p,   // TMDS ����ͨ��
    output [2:0] tmds_data_n,
    output    [5:0]  seg_sel,       // �����λѡ�ź�
    output    [7:0]  seg_led          // ����ܶ�ѡ�ź�
);

//wire define
wire  [10:0]  pixel_xpos_w;
wire  [10:0]  pixel_ypos_w;
wire  [23:0]  pixel_data_w;
wire          video_hs;
wire          video_vs;
wire          video_de;
wire  [23:0]  video_rgb;
wire[2:0]	state_1;//�˵�״̬
wire [5:0]key;
wire [4:0]speed_useless;
wire [5:0]speed_use;
//����ܲ���
wire [5:0]Score;
//*****************************************************
//**                    main code
//*****************************************************

//������Ƶ��ʾ����ģ��
video_driver u_video_driver(
    .pixel_clk      (tx_pclk),
    .sys_rst_n      (sys_rst_n),

    .video_hs       (video_hs),      //���ź�
    .video_vs       (video_vs),      //���ź�
    .video_de       (video_de),      //����ʹ��
    .video_rgb      (video_rgb),     //���ص���ɫ�������

    .pixel_xpos     (pixel_xpos_w),  //���ص������
    .pixel_ypos     (pixel_ypos_w),  //���ص�������
    .pixel_data     (pixel_data_w)   //���ص���ɫ��������
    );

//������Ƶ��ʾģ��
video_display  u_video_display(
    .pixel_clk      (tx_pclk),
    .sys_rst_n      (sys_rst_n),
    .speed_change   (speed_use),
    .key            (key),
    .state_1        (state_1),
    .pixel_xpos     (pixel_xpos_w),
    .pixel_ypos     (pixel_ypos_w),
    .pixel_data     (pixel_data_w),
    .Score          (Score)
    );

//�˵�״̬
state u_state(
   .pixel_clk      (tx_pclk),
   .sys_rst_n      (sys_rst_n), 
   .key            (key),
   .state_1        (state_1),
   .state_2        (state_2)
   );	  

debounce u_debounce(
   .pixel_clk      (tx_pclk),
   .sys_rst_n      (sys_rst_n), 
   .key_in            (key_in),
   .key_out            (key)
);
debounce speed_debounce(
   .pixel_clk      (tx_pclk),
   .sys_rst_n      (sys_rst_n), 
   .key_in            ({speed_useless,speed_change}),
   .key_out            ({speed_use})
);

rgbtodvi_top u_rgbtodvi_top (
  .sys_clk     (sys_clk),
  .blue_din    (video_rgb[7:0]),
  .green_din   (video_rgb[15:8]),
  .red_din     (video_rgb[23:16]),
  .hsync       (video_hs),
  .vsync       (video_vs),
  .de          (video_de),	 

  .pclk        (tx_pclk),  
  .TMDS_CLK    (tmds_clk_p),          // TMDS ʱ��ͨ��
  .TMDS_CLKB   (tmds_clk_n),	  
  .TMDS        (tmds_data_p),         // TMDS ����ͨ��
  .TMDSB       (tmds_data_n)
 );
 //����ܶ�̬��ʾģ��
seg_led u_seg_led(
    .clk           (tx_pclk),       // ʱ���ź�
    .rst_n         (sys_rst_n),       // ��λ�ź�

    .data          (Score     ),       // ��ʾ����ֵ
    .point         (6'b000000),       // С���������ʾ��λ��,�ߵ�ƽ��Ч
    .en            (1),       // �����ʹ���ź�
    .sign          (0),       // ����λ���ߵ�ƽ��ʾ����(-)
    
    .seg_sel       (seg_sel),       // λѡ
    .seg_led       (seg_led)        // ��ѡ
);
endmodule 
/*******************************************************
 * FPGA-Based ̰����
  * School:CSU
 * Class: �Զ��� T2101
 * Students: ����-8210211913, ��ɭ��-8212211224
 * Instructor: ������
 *******************************************************/
//״̬���л�
module state(
  input             pixel_clk,                  //VGA����ʱ��
  input             sys_rst_n,                //��λ�ź�
  input       [5:0]key,//������������
	input   wire flag,
	output	reg[2:0]		state_1,
	output	reg[1:0]		state_2,
  output reg [1:0]difficulty
);	   

parameter one	= 2'b01;			//�Ѷ�Ϊ1
parameter two 	= 2'b10;			//�Ѷ�Ϊ2
parameter three = 2'b11;			//�Ѷ�Ϊ3

parameter game_start	= 3'b001;  //��Ϸ����Ŀ�ʼѡ��
parameter game_back		= 3'b010;  //��Ϸ����ķ���ѡ��
parameter game			= 3'b100;  //��Ϸ��
reg [2:0]ls;
reg [2:0]ns;
//state_1
always@(posedge pixel_clk or negedge sys_rst_n)begin//֮ǰûдBegin��end
if(sys_rst_n==0)
	ns<=game_start;
else  begin
     
  case(state_1)
    game_start:	if(key[4] ==1)//������Ϸ
          ns<=game;
        else if(key[5] == 1)//�˳���Ϸ
          ns<=game_start;
        else
          ns<=game_start;
    // game_back:	if(key[4] == 1)//������Ϸ
    //       ns<=game;
		// 	 else if(key[5] == 1)//���ز˵�
    //       ns<=game_start;
    //     else
    //       ns<=game_back;
    game:		if(key[4] == 1)//��Ϸ
          ns<=game;
        else if(key[5]==1)
          ns<=game_start;
        else
          ns<=game;
    default:
    ns<=game_start;
  endcase
      end
end

always@(posedge pixel_clk )
begin
  state_1<=ns;
end
always @(posedge pixel_clk or negedge sys_rst_n) begin
  if(!sys_rst_n)
    begin
      difficulty=1;
    end
  else 
  begin
      if(state_1==game_start)
        begin
        if(key[0]==1)
          begin
            if(difficulty>0)
            begin
              difficulty=difficulty-1;
            end
            else
            begin
              difficulty=3;
            end
          end
        else if(key[1]==1)
          begin
            if(difficulty<3)
              begin
                difficulty=difficulty+1;
              end
              else
              begin
                difficulty=1;
              end
          end
        else
          difficulty=difficulty;
        end
      else
        begin
          difficulty=difficulty;
        end
  end
end
endmodule
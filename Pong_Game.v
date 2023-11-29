// http://tinyvga.com/vga-timing/640x480@60Hz

module Pong_Game
#( 
parameter 		TOTAL_COL = 800, 		// Visible Area = 640, Front Porch = 16, Sync Pulse = 96, Back Porch = 48, Total = 800 (640 + 16 + 96 + 48)
parameter 		TOTAL_ROW = 525, 		// Visible Area = 480, Front Porch = 10, Sync Pulse = 2, Back Porch = 33, Total = 525 (480 + 10 + 2 + 33)
parameter 		ACTIVE_COL = 640,
parameter 		ACTIVE_ROW = 480
)

(
input 			i_Clock, 		// 50 MHz Clock
input				i_Reset, 		// Reset for the game
input				i_ps2d, 		   // PS2 Data In
input				i_ps2c,			// PS2 Clock In
output			o_VSync,			// VSync
output 			o_HSync,			// HSync
output 			o_Sync,
output 			o_Blank,			// Blacks out areas on monitor. When active HIGH, video is enabled.
output [7:0] 	o_Red,			// VGA Red
output [7:0] 	o_Green,			// VGA Green
output [7:0] 	o_Blue,			// VGA Blue
output 			o_VGA_Clock,		// VGA Clock (25MHz Clock)
output [6:0] HEX0,HEX2

);
///////////////////////////////////////////////////////////////////////////////////////////
parameter 		Pos_X_Max = 774;
parameter 		Pos_X_Min = 153;
parameter		Pos_Y_Max = 485;
parameter 		Pos_Y_Min = 65; 					// Game play area

//----------------------Game Settings-----------------------------//
parameter		Paddle_Speed 	= 80000; 		// Paddle Speed. Lower settings = higher speed
parameter 		Ball_Speed		= 150000; 		// Ball Speed 
parameter		Paddle_Width	= 10;	
parameter		Paddle_Length	= 45;
parameter		Ball_Size		= 7;				// Paddle and ball sizes. Higher number = larger paddles or ball
//---------------------------------------------------------------//
parameter 		Paddle_1_X_Pos = 273;
parameter 		Paddle_1_Y_Pos = 272;
parameter 		Paddle_2_X_Pos = 673;
parameter 		Paddle_2_Y_Pos = 272; 			// Origin point for paddles, centered in screen
parameter 		Ball_X_Pos		= 473;
parameter		Ball_Y_Pos		= 272; 			// Origin point for Ball
	

//ASCII definitions for keys	
parameter character_lowercase_w = 8'h77;
parameter character_lowercase_a = 8'h61; 
parameter character_lowercase_s = 8'h73;		
parameter character_lowercase_d = 8'h64;		// Player 1 keys (WASD)

parameter character_lowercase_i = 8'h69;
parameter character_lowercase_j = 8'h6A;
parameter character_lowercase_k = 8'h6B;
parameter character_lowercase_l = 8'h6C;		// Player 2 keys (IJKL)

parameter character_space = 8'h20;				// Game start button (Space Bar)

//Signal Declaration

wire	[3:0]		w_Button;
wire	[3:0]		w_Button_2;						// WASD, IJKL buttons.

wire 	[10:0]	o_Col_Count;
wire 	[10:0] 	o_Row_Count;
wire 				r_Clock_25MHz;

wire 				Paddle_1_En;
wire 				Paddle_2_En;					// Enable for drawing paddle

wire				Paddle_Hit;
wire				Paddle_1_Hit;
wire				Paddle_2_Hit;
wire				w_Direction;					// Conditions for if paddle is hit, & signal to change ball direction

wire				P1_Win;
wire				P2_Win;
wire				Win;								// Win conditions


reg 	[10:0]	contvidh; 						// Horizontal counter, total columns
reg 	[10:0]	contvidv; 						// Vertical counter, total rows

wire 	[10:0]	P_x; 								// Paddle 1 x position, draw +10 and -10 on sides
wire 	[10:0]	P_y; 								// Paddle 1 y position, draw +30 and -30 on sides

	
wire 	[10:0] 	P_x_2; 							// Paddle 2 x position, draw +10 and -10 on sides
wire 	[10:0] 	P_y_2; 							// Paddle 2 y position, draw +30 and -30 on sides

wire  [10:0]   P_x_Ball;
wire	[10:0]	P_y_Ball; 						// Ball X and Y positions.

	
wire [7:0] scan_code;			
wire rx_done_tick;
wire w_Space;
reg [3:0] p1_score,p2_score;
// 11/29 added




wire [27:0] oSeg;
reg [13:0] enSeg,enSeg1;
wire displaynum1,displaynum2,displaynum;
//wire [10:0] h,v;

parameter hstart = 350, vstart = 50, hstart1 = 600, vstart1 = 50,height = 26, width = 8;

//assign h = contvidh;
//assign v = contvidv;
		

////////////////////////////////////////////////////////////////////////////////////////////

wire	[7:0]	ascii_code;
wire			HSync = (contvidh < 96) ? 1'b0 : 1'b1;
wire			VSync = (contvidv < 2) ? 1'b0 : 1'b1;
wire			vid_blank = (contvidv > 35 && contvidv < 515 && contvidh > 143 && contvidh < 784)? 1'b1 : 1'b0; // Addresable video range, 640 by 480
wire			clrvidh = (contvidh <= 800) ? 1'b0 : 1'b1;
wire  		clrvidv = (contvidv <= 525) ? 1'b0 : 1'b1;

assign 		o_Blank = vid_blank;
assign 		o_VSync = VSync;
assign		o_HSync = HSync;
assign 		o_VGA_Clock = r_Clock_25MHz;

assign		P1_Win = ((P_x_Ball - Paddle_Width) == Pos_X_Min) ? 1'b1 : 1'b0;
assign		P2_Win = ((P_x_Ball + Paddle_Width) == Pos_X_Max) ? 1'b1 : 1'b0;
assign		Win = (P1_Win || P2_Win) ? 1'b1 : 1'b0;


assign		Paddle_1_Hit = ((((P_x_Ball - Ball_Size) == (P_x + Paddle_Width)) && (((P_y_Ball + Ball_Size) >= (P_y - Paddle_Length)) && ((P_y_Ball - Ball_Size) <= (P_y + Paddle_Length)))) && (w_Direction == 1'b0)) ? 1'b1 : 1'b0;
assign		Paddle_2_Hit = ((((P_x_Ball + Ball_Size) == (P_x_2 - Paddle_Width)) && (((P_y_Ball + Ball_Size)>= (P_y_2 - Paddle_Length)) && ((P_y_Ball - Ball_Size) <= (P_y_2 + Paddle_Length)))) && (w_Direction == 1'b1)) ? 1'b1 : 1'b0;
assign 		Paddle_Hit = (Paddle_1_Hit || Paddle_2_Hit) ? 1'b1 : 1'b0;
////////////////////////////////////////////////////////////////////////////////////////////

// always@(posedge i_Clock)
always@(posedge r_Clock_25MHz)
begin
if (i_Reset) begin p1_score <= 4'd0; p2_score <= 4'd0;end
else
begin
if (P1_Win) p1_score <= p1_score + 1;
if (P2_Win) p2_score <= p2_score + 1;

end

end

Clock_Div Clock_25MHz (
								.i_Clock(i_Clock), .o_Clock(r_Clock_25MHz) //Clock divider to get 25MHz Clock
							 );
							 



	
	// Instantiate PS2 Keyboard reciever 
ps2_rx ps2_rx_unit (.clk(i_Clock), .reset(i_Reset), .rx_en(1'b1), .ps2d(i_ps2d), .ps2c(i_ps2c), .rx_done_tick(rx_done_tick), .rx_data(scan_code));					
//   PS2_Controller ps2 (.CLOCK_50(iClock),.reset(i_Reset),
//	.PS2_CLK(i_ps2c),					// PS2 Clock
// 	.PS2_DAT(i_ps2d),					// PS2 Data
//
//	.received_data(scan_code),
//	.received_data_en(rx_done_tick)		// If 1 - new data has been received
//);
//	
	// Instantiate key-to-ascii code conversion circuit	
key2ascii 		k2a_unit (.scan_code(scan_code), .ascii_code(ascii_code));


//Instantiate key checks for WASD, IJKL, and Space bar	
							
Check_Key 						#(	.KEY1(character_lowercase_a),
										.KEY2(character_lowercase_d)
									 ) 
					A_D_KEYS 
									(
										.i_Clock(i_Clock),
										.i_ASCII_Code(ascii_code),
										.rx_done_tick(rx_done_tick),
										.o_Key1(w_Button[1]),
										.o_Key2(w_Button[0]),
										.o_Space(w_Space) 		// Check if space bar is pressed, and released
									);
						 
Check_Key 						#(	.KEY1(character_lowercase_w),
										.KEY2(character_lowercase_s)
									 ) 
					W_S_KEYS 
									(
										.i_Clock(i_Clock),
										.i_ASCII_Code(ascii_code),
										.rx_done_tick(rx_done_tick),
										.o_Key1(w_Button[3]),
										.o_Key2(w_Button[2]),
										.o_Space()
									);
									
Check_Key 						#(	.KEY1(character_lowercase_j),
										.KEY2(character_lowercase_l)
									 ) 
					J_L_KEYS 
									(
										.i_Clock(i_Clock),
										.i_ASCII_Code(ascii_code),
										.rx_done_tick(rx_done_tick),
										.o_Key1(w_Button_2[1]),
										.o_Key2(w_Button_2[0]),
										.o_Space()
									);
						 
Check_Key 						#(	.KEY1(character_lowercase_i),
										.KEY2(character_lowercase_k)
									 ) 
					I_K_KEYS 
									(
										.i_Clock(i_Clock),
										.i_ASCII_Code(ascii_code),
										.rx_done_tick(rx_done_tick),
										.o_Key1(w_Button_2[3]),
										.o_Key2(w_Button_2[2]),
										.o_Space()
									);

// Instantiate modules to determine the paddles and ball positions									
Paddle_Position 				#( .pos_MAX(Pos_X_Max),
									   .pos_MIN(Pos_X_Min),
									   .origin(Paddle_1_X_Pos),
									   .Paddle_Speed(Paddle_Speed)
									 )
					Paddle_1_X
									 (
										.i_Clock(r_Clock_25MHz),
										.i_Switch(w_Button[1:0]),
										.o_New_Pos(P_x)
									 );
									 
Paddle_Position 				#( .pos_MAX(Pos_Y_Max),
									   .pos_MIN(Pos_Y_Min),
									   .origin(Paddle_1_Y_Pos),
									   .Paddle_Speed(Paddle_Speed)
									 )
					Paddle_1_Y
									 (
										.i_Clock(r_Clock_25MHz),
										.i_Switch(w_Button[3:2]),
										.o_New_Pos(P_y)										
									 );
									 
Paddle_Position				#( .pos_MAX(Pos_X_Max),
									   .pos_MIN(Pos_X_Min),
									   .origin(Paddle_2_X_Pos),
									   .Paddle_Speed(Paddle_Speed)
									 )
				  Paddle_2_X
									 (
										.i_Clock(r_Clock_25MHz),
										.i_Switch(w_Button_2[1:0]),
										.o_New_Pos(P_x_2)
									 );
									 
Paddle_Position			   #( .pos_MAX(Pos_Y_Max),
									   .pos_MIN(Pos_Y_Min),
									   .origin(Paddle_2_Y_Pos),
									   .Paddle_Speed(Paddle_Speed)
									 )
					Paddle_2_Y
									 (
										.i_Clock(r_Clock_25MHz),
										.i_Switch(w_Button_2[3:2]),
										.o_New_Pos(P_y_2)
									 );
									 
Ball_Position					#( .pos_MAX(Pos_X_Max),
									   .pos_MIN(Pos_X_Min),
									   .origin(Ball_X_Pos),
									   .Ball_Speed(Ball_Speed)
									 )
					Ball_X
									 (
										.i_Clock(r_Clock_25MHz),
										.i_Reset(i_Reset),
										.i_Paddle_Hit(Paddle_Hit),
								 		.i_Win(Win),
										.i_Space(w_Space),
										.o_Direction(w_Direction),
										.o_Pos(P_x_Ball)
									 );
									 
Ball_Position					#( .pos_MAX(Pos_Y_Max),
									   .pos_MIN(Pos_Y_Min),
									   .origin(Ball_Y_Pos),
									   .Ball_Speed(Ball_Speed)
									 )
					Ball_Y
									 (
									   .i_Clock(r_Clock_25MHz),
									   .i_Reset(i_Reset),
									   .i_Paddle_Hit(1'b0), // Pass 0 value for Y position check, only reverses in X position. Keeps Y momentum
										.i_Win(Win),
										.i_Space(w_Space),
									   .o_Direction(),
									   .o_Pos(P_y_Ball)
									 );
									 


always @ (posedge r_Clock_25MHz)
begin 
// Horizontal Counter
		if(clrvidh) 					// At pixel 800
		begin
		contvidh <= 0; 				// Reset counter
		end
		
		else
		begin
		contvidh <= contvidh + 1;	// Else increment counter
		end
end

always @ (posedge r_Clock_25MHz)

begin 
// Vertical Counter
		if (clrvidv) 					// At pixel 525 for vertical
		begin
		contvidv <= 0; 				// Reset counter
		end
		
		else
		begin
			if
			(contvidh == 800) 		// Else increment vertical counter, when at end of horizontal counter
			begin
			contvidv <= contvidv + 1; 
			end
		end
end

// Get the draw enable signal for Ball, and Paddles, to signal where to draw the objects on the specific frame
assign Ball_En		 = ((contvidh >= (P_x_Ball - Ball_Size)) && (contvidh <= (P_x_Ball + Ball_Size)) && (contvidv >= (P_y_Ball - Ball_Size)) && (contvidv <= (P_y_Ball + Ball_Size))) ? 1'b1 : 1'b0; 	// Draws Ball, 14 by 14 Pixel.
assign Paddle_1_En = ((contvidh >= (P_x - Paddle_Width)) && (contvidh <= (P_x + Paddle_Width)) &&  (contvidv >= (P_y - Paddle_Length)) && (contvidv <= (P_y + Paddle_Length))) ? 1'b1 : 1'b0; 			// Draws 20 by 90 Pixel Paddle
assign Paddle_2_En = ((contvidh >= (P_x_2 - Paddle_Width)) && (contvidh <= (P_x_2 + Paddle_Width)) &&  (contvidv >= (P_y_2 - Paddle_Length)) && (contvidv <= (P_y_2 + Paddle_Length)))	? 1'b1 : 1'b0;	// Draws 20 by 90 Pixel Paddle		 	
	
//assign o_Red = 	(vid_blank == 1'b1 && (Paddle_1_En || Paddle_2_En || Ball_En)) ? 8'b11111111 : 8'b00000000; 
//assign o_Green =  (vid_blank == 1'b1 && (Paddle_1_En || Paddle_2_En || Ball_En)) ? 8'b11111111 : 8'b00000000;
//assign o_Blue = 	(vid_blank == 1'b1 && (Paddle_1_En || Paddle_2_En || Ball_En)) ? 8'b11111111 : 8'b00000000;		//Draw Paddle 1, Paddle 2, and Ball. Drawn in white.


// 11/29 added




assign oSeg[0] = ((contvidh>=hstart) && (contvidh<hstart+height) && (contvidv>=vstart) && (contvidv<vstart+width));
assign oSeg[1] = ((contvidh>=hstart+height-width) && (contvidh< hstart+height) && (contvidv>= vstart+width) && (contvidv<vstart+width+height));
assign oSeg[2] = ((contvidh>=hstart+height-width) && (contvidh<hstart+height) && (contvidv>=vstart+2*width+height) && (contvidv<vstart+2*width+2*height));
assign oSeg[3] = ((contvidh>=hstart) && (contvidh<hstart+height) && (contvidv>=vstart++2*width+2*height) && (contvidv< vstart+2*height+3*width));
assign oSeg[4] = ((contvidh>=hstart) && (contvidh<hstart+width) && (contvidv>=vstart+2*width+height) && (contvidv<vstart+2*width+2*height));
assign oSeg[5] = ((contvidh>=hstart) && (contvidh<hstart+width) && (contvidv>= vstart+width) && (contvidv<vstart+width+height));
assign oSeg[6] = ((contvidh>=hstart) && (contvidh<hstart+height) && (contvidv>=vstart+height+width) && (contvidv<vstart+height+2*width));


assign oSeg[7] = ((contvidh>=hstart+40) && (contvidh<hstart+40+height) && (contvidv>=vstart) && (contvidv<vstart+width));
assign oSeg[8] = ((contvidh>=hstart+40+height-width) && (contvidh< hstart+40+height) && (contvidv>= vstart+width) && (contvidv<vstart+width+height));
assign oSeg[9] = ((contvidh>=hstart+40+height-width) && (contvidh<hstart+40+height) && (contvidv>=vstart+2*width+height) && (contvidv<vstart+2*width+2*height));
assign oSeg[10] = ((contvidh>=hstart+40) && (contvidh<hstart+40+height) && (contvidv>=vstart++2*width+2*height) && (contvidv< vstart+2*height+3*width));
assign oSeg[11] = ((contvidh>=hstart+40) && (contvidh<hstart+40+width) && (contvidv>=vstart+2*width+height) && (contvidv<vstart+2*width+2*height));
assign oSeg[12] = ((contvidh>=hstart+40) && (contvidh<hstart+40+width) && (contvidv>= vstart+width) && (contvidv<vstart+width+height));
assign oSeg[13] = ((contvidh>=hstart+40) && (contvidh<hstart+40+height) && (contvidv>=vstart+height+width) && (contvidv<vstart+height+2*width));

assign oSeg[14] = ((contvidh>=hstart1) && (contvidh<hstart1+height) && (contvidv>=vstart1) && (contvidv<vstart1+width));
assign oSeg[15] = ((contvidh>=hstart1+height-width) && (contvidh< hstart1+height) && (contvidv>= vstart1+width) && (contvidv<vstart1+width+height));
assign oSeg[16] = ((contvidh>=hstart1+height-width) && (contvidh<hstart1+height) && (contvidv>=vstart1+2*width+height) && (contvidv<vstart1+2*width+2*height));
assign oSeg[17] = ((contvidh>=hstart1) && (contvidh<hstart1+height) && (contvidv>=vstart1++2*width+2*height) && (contvidv< vstart1+2*height+3*width));
assign oSeg[18] = ((contvidh>=hstart1) && (contvidh<hstart1+width) && (contvidv>=vstart1+2*width+height) && (contvidv<vstart1+2*width+2*height));
assign oSeg[19] = ((contvidh>=hstart1) && (contvidh<hstart1+width) && (contvidv>= vstart1+width) && (contvidv<vstart1+width+height));
assign oSeg[20] = ((contvidh>=hstart1) && (contvidh<hstart1+height) && (contvidv>=vstart1+height+width) && (contvidv<vstart1+height+2*width));


assign oSeg[21] = ((contvidh>=hstart1+40) && (contvidh<hstart1+40+height) && (contvidv>=vstart1) && (contvidv<vstart1+width));
assign oSeg[22] = ((contvidh>=hstart1+40+height-width) && (contvidh< hstart1+40+height) && (contvidv>= vstart1+width) && (contvidv<vstart1+width+height));
assign oSeg[23] = ((contvidh>=hstart1+40+height-width) && (contvidh<hstart1+40+height) && (contvidv>=vstart1+2*width+height) && (contvidv<vstart1+2*width+2*height));
assign oSeg[24] = ((contvidh>=hstart1+40) && (contvidh<hstart1+40+height) && (contvidv>=vstart1++2*width+2*height) && (contvidv< vstart1+2*height+3*width));
assign oSeg[25] = ((contvidh>=hstart1+40) && (contvidh<hstart1+40+width) && (contvidv>=vstart1+2*width+height) && (contvidv<vstart1+2*width+2*height));
assign oSeg[26] = ((contvidh>=hstart1+40) && (contvidh<hstart1+40+width) && (contvidv>= vstart1+width) && (contvidv<vstart1+width+height));
assign oSeg[27] = ((contvidh>=hstart1+40) && (contvidh<hstart1+40+height) && (contvidv>=vstart1+height+width) && (contvidv<vstart1+height+2*width));

always@(posedge r_Clock_25MHz)
begin
case(p2_score)
4'd0: enSeg[13:0] <= 14'b01111110111111;
4'd1: enSeg[13:0] <= 14'b00001100111111;
4'd2: enSeg[13:0] <= 14'b10110110111111;
4'd3: enSeg[13:0] <= 14'b10011110111111;
4'd4: enSeg[13:0] <= 14'b11001100111111;
4'd5: enSeg[13:0] <= 14'b11011010111111;
4'd6: enSeg[13:0] <= 14'b11111010111111;
4'd7: enSeg[13:0] <= 14'b00001110111111;
4'd8: enSeg[13:0] <= 14'b11111110111111;
4'd9: enSeg[13:0] <= 14'b11011110111111;
4'd10: enSeg[13:0] <= 14'b01111110000110;
4'd11: enSeg[13:0] <= 14'b00001100000110;
default: enSeg[13:0] <= 14'b01111110111111;
endcase
end


always@(posedge r_Clock_25MHz)
begin
case(p1_score)
4'd0: enSeg1[13:0] <= 14'b01111110111111;
4'd1: enSeg1[13:0] <= 14'b00001100111111;
4'd2: enSeg1[13:0] <= 14'b10110110111111;
4'd3: enSeg1[13:0] <= 14'b10011110111111;
4'd4: enSeg1[13:0] <= 14'b11001100111111;
4'd5: enSeg1[13:0] <= 14'b11011010111111;
4'd6: enSeg1[13:0] <= 14'b11111010111111;
4'd7: enSeg1[13:0] <= 14'b00001110111111;
4'd8: enSeg1[13:0] <= 14'b11111110111111;
4'd9: enSeg1[13:0] <= 14'b11011110111111;
4'd10: enSeg1[13:0] <= 14'b01111110000110;
4'd11: enSeg1[13:0] <= 14'b00001100000110;
default: enSeg1[13:0] <= 14'b01111110111111;

endcase
end


assign displaynum1 = ((oSeg[0]&&enSeg[0]) || (oSeg[1]&&enSeg[1]) || (oSeg[2]&&enSeg[2]) || (oSeg[3]&&enSeg[3]) ||
(oSeg[4]&&enSeg[4]) || (oSeg[5]&&enSeg[5]) || (oSeg[6]&&enSeg[6]) || (oSeg[7]&&enSeg[7]) || (oSeg[8]&&enSeg[8])
|| (oSeg[9]&&enSeg[9]) || (oSeg[10]&&enSeg[10]) || (oSeg[11]&&enSeg[11]) || (oSeg[12]&&enSeg[12]) || (oSeg[13]&&enSeg[13]));

assign displaynum2 = ((oSeg[14]&&enSeg1[0]) || (oSeg[15]&&enSeg1[1]) || (oSeg[16]&&enSeg1[2]) || (oSeg[17]&&enSeg1[3]) || (oSeg[18]&&enSeg1[4])
|| (oSeg[19]&&enSeg1[5]) || (oSeg[20]&&enSeg1[6]) || (oSeg[21]&&enSeg1[7]) || (oSeg[22]&&enSeg1[8]) || (oSeg[23]&&enSeg1[9])
|| (oSeg[24]&&enSeg1[10]) || (oSeg[25]&&enSeg1[11]) || (oSeg[26]&&enSeg1[12]) || (oSeg[27]&&enSeg1[13]));

assign displaynum = displaynum1 || displaynum2;

assign o_Red = 	(vid_blank == 1'b1 && (Ball_En || displaynum)) ? 8'b11111111 : 8'b00000000; 
assign o_Green =  (vid_blank == 1'b1 && (Paddle_1_En || displaynum)) ? 8'b11111111 : 8'b00000000;
assign o_Blue = 	(vid_blank == 1'b1 && (Paddle_2_En || displaynum)) ? 8'b11111111 : 8'b00000000;		//Draw Paddle 1, Paddle 2, and Ball. Drawn in white.

//hex_decoder display (p1_score/2,HEX0);
//hex_decoder display2 (p2_score/2,HEX2);


hex_decoder display (p1_score,HEX0);
hex_decoder display2 (p2_score,HEX2);

endmodule

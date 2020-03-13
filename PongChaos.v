
module PongChaos(

//SW[0] and SW[1] in use
	CLOCK_50,
	CLOCK2_50,
	CLOCK3_50,
	KEY,
	SW,
	VGA_B,
	VGA_BLANK_N,
	VGA_CLK,
	VGA_G,
	VGA_HS,
	VGA_R,
	VGA_SYNC_N,
	VGA_VS 
);
input CLOCK_50;
input CLOCK2_50;
input CLOCK3_50;
input [3:0] KEY;
input [17:0] SW;
output [7:0] VGA_B;
output VGA_BLANK_N;
output VGA_CLK;
output [7:0] VGA_G;
output	VGA_HS;
output [7:0] VGA_R;
output VGA_SYNC_N;
output VGA_VS;
reg	aresetPll = 0;
wire pixelClock;

//Used for traversal of the screen to draw

wire [10:0] XPixelPosition;
wire [10:0] YPixelPosition; 
reg	[7:0] redValue;
reg	[7:0] greenValue;
reg	[7:0] blueValue;
reg	[2:0] hmovement = 0;
reg [2:0] vmovement = 0;
reg	[3:0] tool = 0;
reg [10:0] r = 10; //Radius of the ball??
reg [10:0] speed = 1;
reg [10:0] P1_paddle_len = 125;
reg [10:0] P2_paddle_len = 125;
reg [10:0] P3_paddle_len = 125;
reg [10:0] P4_paddle_len = 125;
reg [10:0] P1_paddle_speed = 5;
reg [10:0] P2_paddle_speed = 5;
reg [10:0] P3_paddle_speed = 5;
reg [10:0] P4_paddle_speed = 5;
reg [20:0] slowClockCounter = 0;
wire slowClock;
reg [20:0] fastClockCounter = 0;
wire fastClock;
reg	[10:0] X1DotPosition = 500;
reg	[10:0] Y1DotPosition = 500; 
reg	[10:0] X2DotPosition = 750;
reg	[10:0] Y2DotPosition = 450;
reg	[10:0] P1x = 225;
reg	[10:0] P1y = 500;
reg	[10:0] P2x = 1030;
reg	[10:0] P2y = 500;
reg [10:0] P3x = 567; //midpoint of the field is 630 and paddle length is 125 -> 630 - (125/2) ~= 567
reg [10:0] P3y = 195; //upper bound drawn at y = 125
reg [10:0] P4x = 567;
reg [10:0] P4y = 815; //lower bound drawn at y = 895 
reg [3:0] P1Score = 0;
reg	[3:0] P2Score = 0;
reg [3:0] P3Score = 0;
reg [3:0] P4Score = 0;
reg game =1; //Game control signal
reg	[2:0] printer = 0;
wire [9:0] randX;
wire [9:0] randY;
reg [9:0] itemX = 640;
reg [9:0] itemY = 512;
reg [27:0] clock;
wire [3:0] rtool;
wire [7:0] color1;
wire [7:0] color2;
wire [7:0] color3;
reg [7:0] col1;
reg [7:0] col2;
reg [7:0] col3;
reg [3:0] randomtool = 2;
reg [1:0] drawItem;

assign VGA_BLANK_N = 1'b1;
assign VGA_SYNC_N = 1'b1;			
assign VGA_CLK = pixelClock;


RandomPoint ran(VGA_CLK, randX, randY);
RandomTool rant(VGA_CLK, rtool, color1, color2, color3);

assign slowClock = slowClockCounter[16];

//Set the counter with slow speed by the CLOCK_50
always@ (posedge CLOCK_50)
begin
	slowClockCounter <= slowClockCounter + 1;
end

//Set the counter with fast speed by the CLOCK_50
assign fastClock = fastClockCounter[17];

always@ (posedge CLOCK_50)
begin
	fastClockCounter <= fastClockCounter + 1;
end

//-------------------------------------------------------------------------------------------------------------------------------
//Controlling player movement
//Controls the left paddle.
//always@(posedge fastClock)
//begin
//	if (SW[0] == 1'b1 && game == 1) 
//		begin
//			if (KEY[2] == 1'b0 && KEY[3] == 1'b0) 
//				P1y <= P1y;
//			else if (KEY[2] == 1'b0)
//				begin
//					if (P1y+P1_paddle_len >= 895) //Paddle makes it to the bottom of the area
//						P1y <= 895-P1_paddle_len;
//					else
//						P1y <= P1y + P1_paddle_speed;
//				end
//
//			else if (KEY[3] == 1'b0) 
//				begin
//					if(P1y <= 125) //Paddle makes it to the top of the area
//						P1y <= 125;
//					else
//						P1y <= P1y - P1_paddle_speed;
//				end
//		end
//	
//	else if (SW[0] == 1'b0) //Reset
//		P1y <= 500;
//end
//
////it controls the right paddle
//always@(posedge fastClock)
//	begin
//		if (SW[0] == 1'b1 && game ==1) 
//			begin
//				if (KEY[0] == 1'b0 && KEY[1] == 1'b0) 
//					P2y <= P2y;
//				else if (KEY[0] == 1'b0) begin
//					if(P2y+P2_paddle_len >= 895) //Paddle makes it to the bottom of the screen
//						P2y <= 895-P2_paddle_len;
//					else
//					P2y <= P2y + P2_paddle_speed;
//				end
//				else if (KEY[1] == 1'b0) begin
//					if(P2y <= 125) //Paddle makes it to the top of the screen
//						P2y <= 125;
//					else
//						P2y <= P2y - P2_paddle_speed;
//				end
//		end
//
//	else if (SW[0] == 1'b0) //Reset
//		P2y <= 500;
//	end

//Controls the top paddle
//Using SW since KEYS are used up - SW[6] to go left, SW[5] to go right
always@(posedge fastClock)
	begin
		if (SW[0] == 1'b1 && game == 1) 
			begin
				if (KEY[0] == 1'b0 && KEY[1] == 1'b0) 
					P3x <= P3x;
				else if (KEY[1] == 1'b0) begin //Moving left
					if(P3x <= 165) //Paddle makes it to the left of the area
						P3x <= 165;
					else
					P3x <= P3x - P3_paddle_speed;
				end
				else if (KEY[0] == 1'b0) begin //Moving right
					if(P3x+P3_paddle_len >= 1110) //Paddle makes it to the right of the area
						P3x <= 1110-P3_paddle_len;
					else
						P3x <= P3x + P3_paddle_speed;
				end
		end
	else if (SW[0] == 1'b0) //Reset
		P3x <= 567;
	end

//P4 Paddle SW[9] to go left SW[8] to go right
always@(posedge fastClock)
begin
	if (SW[0] == 1'b1 && game == 1) 
		begin
			if (KEY[2] == 1'b0 && KEY[3] == 1'b0) 
				P4x <= P4x;
			else if (KEY[3] == 1'b0) begin //Moving left
				if(P4x <= 165) //Paddle makes it to the left of the area
					P4x <= 165;
				else
				P4x <= P4x - P4_paddle_speed;
			end
			else if (KEY[2] == 1'b0) begin //Moving right
				if(P4x+P4_paddle_len >= 1110) //Paddle makes it to the right of the area
					P4x <= 1110-P4_paddle_len;
				else
					P4x <= P4x + P4_paddle_speed;
			end
	end
else if (SW[0] == 1'b0) //Reset
	P4x <= 567;

end
//------------------------------------------------------------------------------------------------------------------------------
//Ball movement
//It controls the movement of the ball, horizontal balls position is (X1DotPosition, Y1DotPosition), veritcal ball is (X2DotPosition, Y2DotPosition)

always@(posedge slowClock)
begin
	if (SW[0] == 1'b1 && game ==1)
		begin
			clock <= clock + 1;
			printer <= 0;
			case(hmovement)
				//Change the speed of ball by speed reg
				0:		begin //moving up right
							X1DotPosition <= X1DotPosition + speed;
							Y1DotPosition <= Y1DotPosition - speed;
						end
				1:		begin //moving down right
							X1DotPosition <= X1DotPosition + speed;
							Y1DotPosition <= Y1DotPosition + speed;
						end
				2:		begin //moving down left
							X1DotPosition <= X1DotPosition - speed;
							Y1DotPosition <= Y1DotPosition + speed;
						end
				3:		begin //moving up left
							X1DotPosition <= X1DotPosition - speed;
							Y1DotPosition <= Y1DotPosition - speed;
						end
				default:	begin
								X1DotPosition <= X1DotPosition + speed;
								Y1DotPosition <= Y1DotPosition - speed;
							end
			endcase
			
			case(vmovement)
				//Change the speed of ball by speed reg
				0:		begin //moving down left
							X2DotPosition <= X2DotPosition - speed;
							Y2DotPosition <= Y2DotPosition + speed;
						end
				1:		begin //moving down right
							X2DotPosition <= X2DotPosition + speed;
							Y2DotPosition <= Y2DotPosition + speed;
						end
				2:		begin //moving up right
							X2DotPosition <= X2DotPosition + speed;
							Y2DotPosition <= Y2DotPosition - speed;
						end
				3:		begin //moving up left
							X2DotPosition <= X2DotPosition - speed;
							Y2DotPosition <= Y2DotPosition - speed;
						end
				default:	begin
								X2DotPosition <= X2DotPosition + speed;
								Y2DotPosition <= Y2DotPosition - speed;
							end
			endcase
			
			//It runs the changes of ball or paddle randomly
			//tool is something????
			//When the ball meet the tool random point
			case(tool)
				0:		begin 
							r <= 10;
							P1_paddle_len <= 125;
							P2_paddle_len <= 125;
							speed = 1;
							P1_paddle_speed = 5;
							P2_paddle_speed = 5;
							drawItem <= 1;
						end
				1:		begin
							r <= 20;
							tool <= clock == 5000 ? 0:tool;
						end
				2:		begin
							P1_paddle_len <= 200;
							tool <= clock == 5000 ? 0:tool;
						end
				3:		begin
							P2_paddle_len <= 200;
							tool <= clock == 5000 ? 0:tool;
						end
				4: 		begin
							speed = 2;
							tool <= clock == 5000 ? 0:tool;
						end
				5:		begin
							P1_paddle_len <= 50;
							tool <= clock == 5000 ? 0:tool;
						end
				6:		begin
							P2_paddle_len <= 50;
							tool <= clock == 5000 ? 0:tool;
						end
				7:		begin
							P1_paddle_speed <= 10;
							tool <= clock == 5000 ? 0:tool;
						end
				8:		begin
							P2_paddle_speed <= 10;
							tool <= clock == 5000 ? 0:tool;
						end
				9:		begin
							P1_paddle_speed <= 3;
							tool <= clock == 5000 ? 0:tool;
						end
				10:		begin
							P2_paddle_speed <= 3;
							tool <= clock == 5000 ? 0:tool;
						end
				default:	begin
							r <= 10;
							P1_paddle_len <= 125;
							P2_paddle_len <= 125;
							speed = 1;
							P1_paddle_speed = 5;
							P2_paddle_speed = 5;
							drawItem <= 1;
						end
			endcase
			
			//(X1DotPosition, Y1DotPosition) represents the coordinate of horizontal ball
			// when the ball is in some range, change the movement.
			if(Y1DotPosition - r <= 128 && hmovement == 0) //ball hits the top of the area coming from the left
				hmovement = 1;
			else if (Y1DotPosition - r <= 128 && hmovement == 3) //ball hits the top of the area coming from the right
				hmovement = 2;
			else if (Y1DotPosition + r >= 896 && hmovement == 1) //ball hits the bottom of the area coming from left
				hmovement = 0;
			else if (Y1DotPosition + r >= 896 && hmovement == 2) //ball hits the bottom of the area coming from the right
				hmovement = 3;
			else if (X1DotPosition - r <= P1x+10 && X1DotPosition - r >= P1x+7 && Y1DotPosition > P1y && Y1DotPosition < P1y+P1_paddle_len &&  hmovement == 2)//bounce left paddle from SW
				hmovement = 1;
			else if (X1DotPosition - r <= P1x+10 && X1DotPosition - r >= P1x+7 && Y1DotPosition > P1y && Y1DotPosition < P1y+P1_paddle_len &&  hmovement == 3)//bounce left paddle from NW
				hmovement = 0;
			else if (X1DotPosition + r >= P2x && X1DotPosition + r <= P2x + 3 && Y1DotPosition > P2y && Y1DotPosition < P2y+P2_paddle_len &&  hmovement == 1)//bounce right paddle from SE 
				hmovement = 2;
			else if (X1DotPosition + r >= P2x && X1DotPosition + r <= P2x + 3 && Y1DotPosition > P2y && Y1DotPosition < P2y+P2_paddle_len &&  hmovement == 0)//bounce right paddle from NE
				hmovement = 3;
			else if (Y1DotPosition - r <= 205 && Y1DotPosition - r >= 195 + 7 && X1DotPosition > P3x && X1DotPosition < P3x+P3_paddle_len && hmovement == 0)//bounce top paddle coming from left
				hmovement = 1;
			else if (Y1DotPosition - r <= 205 && Y1DotPosition - r >= 195 + 7 && X1DotPosition > P3x && X1DotPosition < P3x+P3_paddle_len && hmovement == 3)//bounce top paddle coming from right
				hmovement = 2;
			else if (Y1DotPosition + r >= 195 && Y1DotPosition + r <= 195 + 3 && X1DotPosition > P3x && X1DotPosition < P3x+P3_paddle_len && hmovement == 1)//bounce top paddle coming from upper left
				hmovement = 0;
			else if (Y1DotPosition + r >= 195 && Y1DotPosition + r <= 195 + 3 && X1DotPosition > P3x && X1DotPosition < P3x+P3_paddle_len && hmovement == 2)//bounce top paddle coming from upper right
				hmovement = 3;
			else if (Y1DotPosition - r <= 825 && Y1DotPosition - r >= 815 + 7 && X1DotPosition > P4x && X1DotPosition < P4x+P4_paddle_len && hmovement == 0)//bounce top paddle coming from left
				hmovement = 1;
			else if (Y1DotPosition - r <= 825 && Y1DotPosition - r >= 815+ 7 && X1DotPosition > P4x && X1DotPosition < P4x+P4_paddle_len && hmovement == 3)//bounce top paddle coming from right
				hmovement = 2;
			else if (Y1DotPosition + r >= 815 && Y1DotPosition + r <= 815 + 3 && X1DotPosition > P4x && X1DotPosition < P4x+P4_paddle_len && hmovement == 1)//bounce top paddle coming from upper left
				hmovement = 0;
			else if (Y1DotPosition + r >= 815 && Y1DotPosition + r <= 815 + 3 && X1DotPosition > P4x && X1DotPosition < P4x+P4_paddle_len && hmovement == 2)//bounce top paddle coming from upper right
				hmovement = 3; 
			else if (X1DotPosition + r >= itemX - r && X1DotPosition - r <= itemX + r && Y1DotPosition + r >= itemY - r && Y1DotPosition - r <= itemY + r && drawItem == 1)// ball hit the item
				begin
				//Pick the tool randomly and make the change randomly
					clock <= 0;
					if (randomtool == 2 && (hmovement == 2 || hmovement == 3))
						tool <= 3;
					else if (randomtool == 3 && (hmovement == 1 || hmovement == 0))
						tool <= 2;
					else if (randomtool == 5 && (hmovement == 1 || hmovement == 0))
						tool <= 6;
					else if (randomtool == 6 && (hmovement == 2 || hmovement == 3))
						tool <= 5;
					else if (randomtool == 7 && (hmovement == 2 || hmovement == 3))
						tool <= 8;
					else if (randomtool == 8 && (hmovement == 1 || hmovement == 0))
						tool <= 7;
					else if (randomtool == 9 && (hmovement == 1 || hmovement == 0))
						tool <= 10;
					else if (randomtool == 10 && (hmovement == 2 || hmovement == 3))
						tool <= 9;
					else
//						tool <= randomtool;
//						
					itemX <= randX;
					itemY <= randY;
					randomtool <= rtool;
					drawItem <= 0;
				end
			else if (X1DotPosition - r <= 160) //Controlling scores when the ball goes off screen
				begin
					P2Score = P2Score + 1;
					X1DotPosition <= 640;
					Y1DotPosition <= 512;
				end
			else if (X1DotPosition + r >= 1120)
				begin
					P1Score = P1Score + 1;
					X1DotPosition <= 640;
					Y1DotPosition <= 512;
				end
			
			if(X2DotPosition - r <= 165 && vmovement == 0) //ball hits the left of the area coming from the top
				vmovement = 1;
			else if (X2DotPosition - r <= 165 && vmovement == 3) //ball hits the left of the area coming from the bottom
				vmovement = 2;
			else if (X2DotPosition + r >= 1110 && vmovement == 1) //ball hits the right of the area coming from the top
				vmovement = 0;
			else if (X2DotPosition + r >= 1110 && vmovement == 2) //ball hits the right of the area coming from the bottom
				vmovement = 3;
			else if (Y2DotPosition - r <= P3y+10 && Y2DotPosition - r >= P3y + 7 && X2DotPosition > P3x && X2DotPosition < P3x+P3_paddle_len && vmovement == 2)//bounce top paddle coming from left
				vmovement = 1;
			else if (Y2DotPosition - r <= P3y+10 && Y2DotPosition - r >= P3y + 7 && X2DotPosition > P3x && X2DotPosition < P3x+P3_paddle_len && vmovement == 3)//bounce top paddle coming from right
				vmovement = 0;
			else if (Y2DotPosition + r >= P4y && Y2DotPosition + r <= P4y + 3 && X2DotPosition > P4x && X2DotPosition < P4x+P4_paddle_len && vmovement == 1)//bounce top paddle coming from left
				vmovement = 2;
			else if (Y2DotPosition + r >= P4y && Y2DotPosition + r <= P4y + 3 && X2DotPosition > P4x && X2DotPosition < P4x+P4_paddle_len && vmovement == 0)//bounce top paddle coming from right
				vmovement = 3; //this case
			else if (Y2DotPosition + r <= 128)
				begin
					X2DotPosition <= 450;
					Y2DotPosition <= 450;
				end
			else if (Y2DotPosition - r >= 896)
				begin
					X2DotPosition <= 450;
					Y2DotPosition <= 450;
				end
			
			if(P1Score == 10 || P2Score ==10) //Checking winners

				begin
					game <= 0;
					if (P1Score == 10)
						printer <= 1;
					else
						printer <= 2;
				end
		end
	
	//Use SW[0] to reset the game
	else if (SW[0] == 0)
		begin
			X1DotPosition <= 640;
			Y1DotPosition <= 512;
			X2DotPosition <= 450;
			Y2DotPosition <= 450;
			P1Score <= 0;
			P2Score <= 0;
			tool <= 0;
			drawItem <= 0;
			itemX <= randX;
			itemY <= randY;
			printer <= 3;
			game <= 1;
		end
end

VGAFrequency VGAFreq (aresetPll, CLOCK_50, pixelClock);

VGAController VGAControl (pixelClock, redValue, greenValue, blueValue, VGA_R, VGA_G, VGA_B, VGA_VS, VGA_HS, XPixelPosition, YPixelPosition);


//---------------------------------------------------------------------------------------------------------------------------------------
//For Drawing borders, players and ball to screen
//XPixelPosition and YPixelPosition traverse the screen like in lab 6 and draw what it needs to when it hits certain spots

//VGA pattern and charactor display
always@ (posedge pixelClock)
begin		
		//Word1 on the top 
		if (XPixelPosition > 410 && XPixelPosition < 470 && YPixelPosition > 5 && YPixelPosition < 13)//row1
		begin
			if (printer == 1 || printer == 2 || printer == 3)
			begin
			redValue <= 8'b00000000; 
			blueValue <= 8'b11111111;
			greenValue <= 8'b11111111;
			end
			else
			begin
			redValue <= 8'b00000000; 
			blueValue <= 8'b00000000;
			greenValue <= 8'b00000000;
			end
		end
		else if (XPixelPosition > 410 && XPixelPosition < 470 && YPixelPosition > 46 && YPixelPosition < 54)//row2
		begin
			if (printer == 1 || printer == 2 || printer == 3)
			begin
			redValue <= 8'b00000000; 
			blueValue <= 8'b11111111;
			greenValue <= 8'b11111111;
			end
			else
			begin
			redValue <= 8'b00000000; 
			blueValue <= 8'b00000000;
			greenValue <= 8'b00000000;
			end
		end
		else if (XPixelPosition > 410 && XPixelPosition < 470 && YPixelPosition > 87 && YPixelPosition < 95)//row3
		begin
			if (printer == 3)
			begin
			redValue <= 8'b00000000; 
			blueValue <= 8'b11111111;
			greenValue <= 8'b11111111;
			end
			else
			begin
			redValue <= 8'b00000000; 
			blueValue <= 8'b00000000;
			greenValue <= 8'b00000000;
			end
		end
		else if (XPixelPosition > 410 && XPixelPosition < 418 && YPixelPosition > 5 && YPixelPosition < 50)//column 1
		begin
			if (printer == 1 || printer == 2 || printer == 3)
			begin
			redValue <= 8'b00000000; 
			blueValue <= 8'b11111111;
			greenValue <= 8'b11111111;
			end
			else
			begin
			redValue <= 8'b00000000; 
			blueValue <= 8'b00000000;
			greenValue <= 8'b00000000;
			end
		end
		else if (XPixelPosition > 410 && XPixelPosition < 418 && YPixelPosition > 50 && YPixelPosition < 95)//column 2
		begin
			if (printer == 1 || printer == 2)
			begin
			redValue <= 8'b00000000; 
			blueValue <= 8'b11111111;
			greenValue <= 8'b11111111;
			end
			else
			begin
			redValue <= 8'b00000000; 
			blueValue <= 8'b00000000;
			greenValue <= 8'b00000000;
			end
		end
		else if (XPixelPosition > 462 && XPixelPosition < 470 && YPixelPosition > 5 && YPixelPosition < 50)//column 5
		begin
			if (printer == 1 || printer == 2)
			begin
			redValue <= 8'b00000000; 
			blueValue <= 8'b11111111;
			greenValue <= 8'b11111111;
			end
			else
			begin
			redValue <= 8'b00000000; 
			blueValue <= 8'b00000000;
			greenValue <= 8'b00000000;
			end
		end
		else if (XPixelPosition > 462 && XPixelPosition < 470 && YPixelPosition > 50 && YPixelPosition < 95)//column 6
		begin
			if (printer == 3)
			begin
			redValue <= 8'b00000000; 
			blueValue <= 8'b11111111;
			greenValue <= 8'b11111111;
			end
			else
			begin
			redValue <= 8'b00000000; 
			blueValue <= 8'b00000000;
			greenValue <= 8'b00000000;
			end
		end

//Word2 on the top
		else if (XPixelPosition > 510 && XPixelPosition < 570 && YPixelPosition > 5 && YPixelPosition < 13)//row1
		begin
			if (printer == 2 || printer == 3)
			begin
			redValue <= 8'b00000000; 
			blueValue <= 8'b11111111;
			greenValue <= 8'b11111111;
			end
			else
			begin
			redValue <= 8'b00000000; 
			blueValue <= 8'b00000000;
			greenValue <= 8'b00000000;
			end
		end
		else if (XPixelPosition > 510 && XPixelPosition < 570 && YPixelPosition > 46 && YPixelPosition < 54)//row2
		begin
			if (printer == 2)
			begin
			redValue <= 8'b00000000; 
			blueValue <= 8'b11111111;
			greenValue <= 8'b11111111;
			end
			else
			begin
			redValue <= 8'b00000000; 
			blueValue <= 8'b00000000;
			greenValue <= 8'b00000000;
			end
		end
		else if (XPixelPosition > 510 && XPixelPosition < 570 && YPixelPosition > 87 && YPixelPosition < 95)//row3
		begin
			if (printer == 2)
			begin
			redValue <= 8'b00000000; 
			blueValue <= 8'b11111111;
			greenValue <= 8'b11111111;
			end
			else
			begin
			redValue <= 8'b00000000; 
			blueValue <= 8'b00000000;
			greenValue <= 8'b00000000;
			end
		end
		else if (XPixelPosition > 510 && XPixelPosition < 518 && YPixelPosition > 50 && YPixelPosition < 95)//column 2
		begin
			if (printer == 2)
			begin
			redValue <= 8'b00000000; 
			blueValue <= 8'b11111111;
			greenValue <= 8'b11111111;
			end
			else
			begin
			redValue <= 8'b00000000; 
			blueValue <= 8'b00000000;
			greenValue <= 8'b00000000;
			end
		end
		else if (XPixelPosition > 536 && XPixelPosition < 544 && YPixelPosition > 5 && YPixelPosition < 50)//column 3 not used
		begin
			if (printer == 1 || printer == 3)
			begin
			redValue <= 8'b00000000; 
			blueValue <= 8'b111111111;
			greenValue <= 8'b11111111;
			end
			else
			begin
			redValue <= 8'b00000000; 
			blueValue <= 8'b00000000;
			greenValue <= 8'b00000000;
			end
		end
		else if (XPixelPosition > 536 && XPixelPosition < 544 && YPixelPosition > 50 && YPixelPosition < 95)//column 4 not used
		begin
			if (printer == 1 || printer == 3)
			begin
			redValue <= 8'b00000000; 
			blueValue <= 8'b111111111;
			greenValue <= 8'b11111111;
			end
			else
			begin
			redValue <= 8'b00000000; 
			blueValue <= 8'b00000000;
			greenValue <= 8'b00000000;
			end
		end
		else if (XPixelPosition > 562 && XPixelPosition < 570 && YPixelPosition > 5 && YPixelPosition < 50)//column 5
		begin
			if(printer == 2)
			begin
			redValue <= 8'b00000000; 
			blueValue <= 8'b11111111;
			greenValue <= 8'b11111111;
			end
			else
			begin
			redValue <= 8'b00000000; 
			blueValue <= 8'b00000000;
			greenValue <= 8'b00000000;
			end
		end
		
//Word 3 on the top
		else if (XPixelPosition > 610 && XPixelPosition < 670 && YPixelPosition > 5 && YPixelPosition < 13)//row1
		begin
			if (printer == 3)
			begin
			redValue <= 8'b00000000; 
			blueValue <= 8'b11111111;
			greenValue <= 8'b11111111;
			end
			else
			begin
			redValue <= 8'b00000000; 
			blueValue <= 8'b00000000;
			greenValue <= 8'b00000000;
			end
		end
		else if (XPixelPosition > 610 && XPixelPosition < 670 && YPixelPosition > 46 && YPixelPosition < 54)//row2
		begin
			if (printer == 3)
			begin
			redValue <= 8'b00000000; 
			blueValue <= 8'b11111111;
			greenValue <= 8'b11111111;
			end
			else
			begin
			redValue <= 8'b00000000; 
			blueValue <= 8'b00000000;
			greenValue <= 8'b00000000;
			end
		end
		else if (XPixelPosition > 610 && XPixelPosition < 670 && YPixelPosition > 87 && YPixelPosition < 95)//row3
		begin
			if (printer == 1 || printer == 2)
			begin
			redValue <= 8'b00000000; 
			blueValue <= 8'b11111111;
			greenValue <= 8'b11111111;
			end
			else
			begin
			redValue <= 8'b00000000; 
			blueValue <= 8'b00000000;
			greenValue <= 8'b00000000;
			end
		end
		else if (XPixelPosition > 610 && XPixelPosition < 618 && YPixelPosition > 5 && YPixelPosition < 50)//column 1
		begin
			if (printer == 1 || printer == 2 || printer == 3)
			begin
			redValue <= 8'b00000000; 
			blueValue <= 8'b11111111;
			greenValue <= 8'b11111111;
			end
			else
			begin
			redValue <= 8'b00000000; 
			blueValue <= 8'b00000000;
			greenValue <= 8'b00000000;
			end
		end
		else if (XPixelPosition > 610 && XPixelPosition < 618 && YPixelPosition > 50 && YPixelPosition < 95)//column 2
		begin
			if (printer == 1 || printer == 2 || printer == 3)
			begin
			redValue <= 8'b00000000; 
			blueValue <= 8'b11111111;
			greenValue <= 8'b11111111;
			end
			else
			begin
			redValue <= 8'b00000000; 
			blueValue <= 8'b00000000;
			greenValue <= 8'b00000000;
			end
		end
		else if (XPixelPosition > 636 && XPixelPosition < 644 && YPixelPosition > 5 && YPixelPosition < 50)//column 3 not used
		begin
			if (printer == 1 || printer == 2)
			begin
			redValue <= 8'b00000000; 
			blueValue <= 8'b111111111;
			greenValue <= 8'b11111111;
			end
			else
			begin
			redValue <= 8'b00000000; 
			blueValue <= 8'b00000000;
			greenValue <= 8'b00000000;
			end
		end
		else if (XPixelPosition > 636 && XPixelPosition < 644 && YPixelPosition > 50 && YPixelPosition < 95)//column 4 not used
		begin
			if (printer == 1 || printer == 2)
			begin
			redValue <= 8'b00000000; 
			blueValue <= 8'b111111111;
			greenValue <= 8'b11111111;
			end
			else
			begin
			redValue <= 8'b00000000; 
			blueValue <= 8'b00000000;
			greenValue <= 8'b00000000;
			end
		end
		else if (XPixelPosition > 662 && XPixelPosition < 670 && YPixelPosition > 5 && YPixelPosition < 50)//column 5
		begin
			if (printer == 1 || printer == 2 || printer == 3)
			begin
			redValue <= 8'b00000000; 
			blueValue <= 8'b11111111;
			greenValue <= 8'b11111111;
			end
			else
			begin
			redValue <= 8'b00000000; 
			blueValue <= 8'b00000000;
			greenValue <= 8'b00000000;
			end
		end
		else if (XPixelPosition > 662 && XPixelPosition < 670 && YPixelPosition > 50 && YPixelPosition < 95)//column 6
		begin
			if (printer == 1 || printer == 2 || printer == 3)
			begin
			redValue <= 8'b00000000; 
			blueValue <= 8'b11111111;
			greenValue <= 8'b11111111;
			end
			else
			begin
			redValue <= 8'b00000000; 
			blueValue <= 8'b00000000;
			greenValue <= 8'b00000000;
			end
		end

//Word 4 on the top
		else if (XPixelPosition > 710 && XPixelPosition < 770 && YPixelPosition > 5 && YPixelPosition < 13)//row1
		begin
			if (printer == 3)
			begin
			redValue <= 8'b00000000; 
			blueValue <= 8'b11111111;
			greenValue <= 8'b11111111;
			end
			else
			begin
			redValue <= 8'b00000000; 
			blueValue <= 8'b00000000;
			greenValue <= 8'b00000000;
			end
		end
		else if (XPixelPosition > 710 && XPixelPosition < 770 && YPixelPosition > 46 && YPixelPosition < 54)//row2
		begin
			if (printer == 3)
			begin
			redValue <= 8'b00000000; 
			blueValue <= 8'b11111111;
			greenValue <= 8'b11111111;
			end
			else
			begin
			redValue <= 8'b00000000; 
			blueValue <= 8'b00000000;
			greenValue <= 8'b00000000;
			end
		end
		else if (XPixelPosition > 710 && XPixelPosition < 718 && YPixelPosition > 5 && YPixelPosition < 50)//column 1
		begin
			if (printer == 3)
			begin
			redValue <= 8'b00000000; 
			blueValue <= 8'b11111111;
			greenValue <= 8'b11111111;
			end
			else
			begin
			redValue <= 8'b00000000; 
			blueValue <= 8'b00000000;
			greenValue <= 8'b00000000;
			end
		end
		else if (XPixelPosition > 710 && XPixelPosition < 718 && YPixelPosition > 50 && YPixelPosition < 95)//column 2
		begin
			if (printer == 3)
			begin
			redValue <= 8'b00000000; 
			blueValue <= 8'b11111111;
			greenValue <= 8'b11111111;
			end
			else
			begin
			redValue <= 8'b00000000; 
			blueValue <= 8'b00000000;
			greenValue <= 8'b00000000;
			end
		end
		else if (XPixelPosition > 736 && XPixelPosition < 744 && YPixelPosition > 5 && YPixelPosition < 50)//column 3 not used
		begin
			if (printer == 1 || printer == 2)
			begin
			redValue <= 8'b00000000; 
			blueValue <= 8'b111111111;
			greenValue <= 8'b11111111;
			end
			else
			begin
			redValue <= 8'b00000000; 
			blueValue <= 8'b00000000;
			greenValue <= 8'b00000000;
			end
		end
		else if (XPixelPosition > 736 && XPixelPosition < 744 && YPixelPosition > 50 && YPixelPosition < 95)//column 4 not used
		begin
			if (printer == 1 || printer == 2 || printer == 3)
			begin
			redValue <= 8'b00000000; 
			blueValue <= 8'b111111111;
			greenValue <= 8'b11111111;
			end
			else
			begin
			redValue <= 8'b00000000; 
			blueValue <= 8'b00000000;
			greenValue <= 8'b00000000;
			end
		end
		else if (XPixelPosition > 762 && XPixelPosition < 770 && YPixelPosition > 5 && YPixelPosition < 50)//column 5
		begin
			if (printer == 3)
			begin
			redValue <= 8'b00000000; 
			blueValue <= 8'b11111111;
			greenValue <= 8'b11111111;
			end
			else
			begin
			redValue <= 8'b00000000; 
			blueValue <= 8'b00000000;
			greenValue <= 8'b00000000;
			end
		end

//Word 5 on the top
		else if (XPixelPosition > 810 && XPixelPosition < 870 && YPixelPosition > 5 && YPixelPosition < 13)//row1
		begin
			if (printer == 1 || printer == 2 || printer == 3)
			begin
			redValue <= 8'b00000000; 
			blueValue <= 8'b11111111;
			greenValue <= 8'b11111111;
			end
			else
			begin
			redValue <= 8'b00000000; 
			blueValue <= 8'b00000000;
			greenValue <= 8'b00000000;
			end
		end
		else if (XPixelPosition > 810 && XPixelPosition < 818 && YPixelPosition > 5 && YPixelPosition < 50)//column 1
		begin
			if (printer == 1 || printer == 2)
			begin
			redValue <= 8'b00000000; 
			blueValue <= 8'b11111111;
			greenValue <= 8'b11111111;
			end
			else
			begin
			redValue <= 8'b00000000; 
			blueValue <= 8'b00000000;
			greenValue <= 8'b00000000;
			end
		end
		else if (XPixelPosition > 810 && XPixelPosition < 818 && YPixelPosition > 50 && YPixelPosition < 95)//column 2
		begin
			if (printer == 1 || printer == 2)
			begin
			redValue <= 8'b00000000; 
			blueValue <= 8'b11111111;
			greenValue <= 8'b11111111;
			end
			else
			begin
			redValue <= 8'b00000000; 
			blueValue <= 8'b00000000;
			greenValue <= 8'b00000000;
			end
		end
		else if (XPixelPosition > 836 && XPixelPosition < 844 && YPixelPosition > 5 && YPixelPosition < 50)//column 3 not used
		begin
			if (printer == 3)
			begin
			redValue <= 8'b00000000; 
			blueValue <= 8'b111111111;
			greenValue <= 8'b11111111;
			end
			else
			begin
			redValue <= 8'b00000000; 
			blueValue <= 8'b00000000;
			greenValue <= 8'b00000000;
			end
		end
		else if (XPixelPosition > 836 && XPixelPosition < 844 && YPixelPosition > 50 && YPixelPosition < 95)//column 4 not used
		begin
			if (printer == 3)
			begin
			redValue <= 8'b00000000; 
			blueValue <= 8'b111111111;
			greenValue <= 8'b11111111;
			end
			else
			begin
			redValue <= 8'b00000000; 
			blueValue <= 8'b00000000;
			greenValue <= 8'b00000000;
			end
		end
		else if (XPixelPosition > 862 && XPixelPosition < 870 && YPixelPosition > 5 && YPixelPosition < 50)//column 5
		begin
			if (printer == 1 || printer == 2)
			begin
			redValue <= 8'b00000000; 
			blueValue <= 8'b11111111;
			greenValue <= 8'b11111111;
			end
			else
			begin
			redValue <= 8'b00000000; 
			blueValue <= 8'b00000000;
			greenValue <= 8'b00000000;
			end
		end
		else if (XPixelPosition > 862 && XPixelPosition < 870 && YPixelPosition > 50 && YPixelPosition < 95)//column 6
		begin
			if (printer == 1 || printer == 2)
			begin
			redValue <= 8'b00000000; 
			blueValue <= 8'b11111111;
			greenValue <= 8'b11111111;
			end
			else
			begin
			redValue <= 8'b00000000; 
			blueValue <= 8'b00000000;
			greenValue <= 8'b00000000;
			end
		end
		//Display the player 1's score on the left
		else if (YPixelPosition > 200 && YPixelPosition < 210 && XPixelPosition > 40 && XPixelPosition < 120)
		begin
			if (P1Score == 2 || P1Score == 3 || P1Score == 5 || P1Score == 6 || P1Score == 8 || P1Score == 9 || P1Score == 0 || P1Score == 10)
			begin
			redValue <= 8'b00000000; 
			blueValue <= 8'b11111111;
			greenValue <= 8'b11111111;
			end
			else
			begin
			redValue <= 8'b00000000; 
			blueValue <= 8'b00000000;
			greenValue <= 8'b00000000;
			end
		end
		else if (YPixelPosition > 130 && YPixelPosition < 210 && XPixelPosition > 40 && XPixelPosition < 50)
		begin
			if (P1Score == 2 || P1Score == 6 || P1Score == 8 || P1Score == 0 || P1Score == 10)
			begin
			redValue <= 8'b00000000; 
			blueValue <= 8'b11111111;
			greenValue <= 8'b11111111;
			end
			else
			begin
			redValue <= 8'b00000000; 
			blueValue <= 8'b00000000;
			greenValue <= 8'b00000000;
			end
		end
		else if (YPixelPosition > 50 && YPixelPosition <= 130 && XPixelPosition > 40 && XPixelPosition < 50)
		begin
			if (P1Score == 4 || P1Score == 5 || P1Score == 6 || P1Score == 8 || P1Score == 9 || P1Score == 0 || P1Score == 10)
			begin
			redValue <= 8'b00000000; 
			blueValue <= 8'b11111111;
			greenValue <= 8'b11111111;
			end
			else
			begin
			redValue <= 8'b00000000; 
			blueValue <= 8'b00000000;
			greenValue <= 8'b00000000;
			end
		end
		else if (YPixelPosition > 50 && YPixelPosition < 60 && XPixelPosition > 40 && XPixelPosition < 120)
		begin
			if (P1Score == 2 || P1Score == 3 || P1Score == 5 || P1Score == 6 || P1Score == 7 || P1Score == 8 || P1Score == 9 || P1Score == 0 || P1Score == 10)
			begin
			redValue <= 8'b00000000; 
			blueValue <= 8'b11111111;
			greenValue <= 8'b11111111;
			end
			else
			begin
			redValue <= 8'b00000000; 
			blueValue <= 8'b00000000;
			greenValue <= 8'b00000000;
			end
		end
		else if (YPixelPosition > 50 && YPixelPosition <= 130 && XPixelPosition > 110 && XPixelPosition < 120)
		begin
						if (P1Score == 1 || P1Score == 2 || P1Score == 3 || P1Score == 4 || P1Score == 7 || P1Score == 8 ||P1Score == 9 || P1Score == 0 || P1Score == 10)
			begin
			redValue <= 8'b00000000; 
			blueValue <= 8'b11111111;
			greenValue <= 8'b11111111;
			end
			else
			begin
			redValue <= 8'b00000000; 
			blueValue <= 8'b00000000;
			greenValue <= 8'b00000000;
			end
		end
		else if (YPixelPosition > 130 && YPixelPosition < 210 && XPixelPosition > 110 && XPixelPosition < 120)
		begin
			if (P1Score == 1 || P1Score == 3 || P1Score == 4 || P1Score == 5 || P1Score == 6 || P1Score == 7 || P1Score == 8 ||P1Score == 9 || P1Score == 0 || P1Score == 10)
			begin
			redValue <= 8'b00000000; 
			blueValue <= 8'b11111111;
			greenValue <= 8'b11111111;
			end
			else
			begin
			redValue <= 8'b00000000; 
			blueValue <= 8'b00000000;
			greenValue <= 8'b00000000;
			end
		end
		else if (YPixelPosition > 125 && YPixelPosition < 135 && XPixelPosition > 40 && XPixelPosition < 120)
		begin
			if (P1Score == 2 || P1Score == 3 || P1Score == 4 || P1Score == 5 || P1Score == 6 || P1Score == 8 ||P1Score == 9)
			begin
			redValue <= 8'b00000000; 
			blueValue <= 8'b11111111;
			greenValue <= 8'b11111111;
			end
			else
			begin
			redValue <= 8'b00000000; 
			blueValue <= 8'b00000000;
			greenValue <= 8'b00000000;
			end
		end
		//set left green border
		else if (XPixelPosition < 160 && XPixelPosition > 150)
		begin
			redValue <= 159; 
			blueValue <= 92;
			greenValue <= 225;
		end
		//Display the player2's score on the right
		else if (YPixelPosition > 50 && YPixelPosition < 60 && XPixelPosition > 1160 && XPixelPosition < 1240)
		begin
			if (P2Score == 2 || P2Score == 3 || P2Score == 5 || P2Score == 6 || P2Score == 7 || P2Score == 8 || P2Score == 9 || P2Score == 0 || P2Score == 10)
			begin
			redValue <= 8'b00000000; 
			blueValue <= 8'b11111111;
			greenValue <= 8'b11111111;
			end
			else
			begin
			redValue <= 8'b00000000; 
			blueValue <= 8'b00000000;
			greenValue <= 8'b00000000;
			end
		end
		else if (YPixelPosition > 50 && YPixelPosition <= 130 && XPixelPosition > 1160 && XPixelPosition < 1170)
		begin
			if (P2Score == 4 || P2Score == 5 || P2Score == 6 || P2Score == 8 || P2Score == 9 || P2Score == 0 || P2Score == 10)
			begin
			redValue <= 8'b00000000; 
			blueValue <= 8'b11111111;
			greenValue <= 8'b11111111;
			end
			else
			begin
			redValue <= 8'b00000000; 
			blueValue <= 8'b00000000;
			greenValue <= 8'b00000000;
			end
		end
		else if (YPixelPosition > 130 && YPixelPosition < 210 && XPixelPosition > 1160 && XPixelPosition < 1170)
		begin
			if (P2Score == 2 || P2Score == 6 || P2Score == 8 || P2Score == 0 || P2Score == 10)
			begin
			redValue <= 8'b00000000; 
			blueValue <= 8'b11111111;
			greenValue <= 8'b11111111;
			end
			else
			begin
			redValue <= 8'b00000000; 
			blueValue <= 8'b00000000;
			greenValue <= 8'b00000000;
			end
		end
		else if (YPixelPosition > 200 && YPixelPosition < 210 && XPixelPosition > 1160 && XPixelPosition < 1240)
		begin
			if (P2Score == 2 || P2Score == 3 || P2Score == 5 || P2Score == 6 || P2Score == 8 || P2Score == 9 || P2Score == 0 || P2Score == 10)
			begin
			redValue <= 8'b00000000; 
			blueValue <= 8'b11111111;
			greenValue <= 8'b11111111;
			end
			else
			begin
			redValue <= 8'b00000000; 
			blueValue <= 8'b00000000;
			greenValue <= 8'b00000000;
			end
		end
		else if (YPixelPosition > 130 && YPixelPosition < 210 && XPixelPosition > 1230 && XPixelPosition < 1240)
		begin
			if (P2Score == 1 || P2Score == 3 || P2Score == 4 || P2Score == 5 || P2Score == 6 || P2Score == 7 || P2Score == 8 ||P2Score == 9 || P2Score == 0 || P2Score == 10)
			begin
			redValue <= 8'b00000000; 
			blueValue <= 8'b11111111;
			greenValue <= 8'b11111111;
			end
			else
			begin
			redValue <= 8'b00000000; 
			blueValue <= 8'b00000000;
			greenValue <= 8'b00000000;
			end
		end
		else if (YPixelPosition > 50 && YPixelPosition <= 130 && XPixelPosition > 1230 && XPixelPosition < 1240)
		begin
			if (P2Score == 1 || P2Score == 2 || P2Score == 3 || P2Score == 4 || P2Score == 7 || P2Score == 8 ||P2Score == 9 || P2Score == 0 || P2Score == 10)
			begin
			redValue <= 8'b00000000; 
			blueValue <= 8'b11111111;
			greenValue <= 8'b11111111;
			end
			else
			begin
			redValue <= 8'b00000000; 
			blueValue <= 8'b00000000;
			greenValue <= 8'b00000000;
			end
		end
		else if (YPixelPosition > 125 && YPixelPosition < 135 && XPixelPosition > 1160 && XPixelPosition < 1240)
		begin
			if (P2Score == 2 || P2Score == 3 || P2Score == 4 || P2Score == 5 || P2Score == 6 || P2Score == 8 ||P2Score == 9)
			begin
			redValue <= 8'b00000000; 
			blueValue <= 8'b11111111;
			greenValue <= 8'b11111111;
			end
			else
			begin
			redValue <= 8'b00000000; 
			blueValue <= 8'b00000000;
			greenValue <= 8'b00000000;
			end
		end
		else if (XPixelPosition > 1120 && XPixelPosition < 1130) // set right green border
		begin
			redValue <= 159; 
			blueValue <= 92;
			greenValue <= 225;
		end
		else if (YPixelPosition > 115 && YPixelPosition < 125 && XPixelPosition >= 160 && XPixelPosition <= 1120) //set top magenta border
		begin
			redValue <= 159; 
			blueValue <= 92;
			greenValue <= 225;
		end
		else if (YPixelPosition < 905 && XPixelPosition <= 1120 && XPixelPosition >= 160 && YPixelPosition > 895) // set bottom magenta border
		begin
			redValue <= 159; 
			blueValue <= 92;
			greenValue <= 225;
		end
		else if (XPixelPosition > P1x && XPixelPosition < P1x+10 && YPixelPosition > P1y && YPixelPosition < P1y+P1_paddle_len) // draw player 1 paddle
		begin
			redValue <= 8'b00000000; 
			blueValue <= 8'b11111111;
			greenValue <= 8'b11111111;
		end
		else if (XPixelPosition > P2x && XPixelPosition < P2x+10 && YPixelPosition > P2y && YPixelPosition < P2y+P2_paddle_len) // draw player 2 paddle
		begin
			redValue <= 8'b00000000; 
			blueValue <= 8'b11111111;
			greenValue <= 8'b11111111;
		end
		else if (XPixelPosition > P3x && XPixelPosition < P3x+P3_paddle_len && YPixelPosition > P3y && YPixelPosition < P3y+10)//Draw p3 paddle
		begin
			redValue <= 8'b00000000; 
			blueValue <= 8'b11111111;
			greenValue <= 8'b11111111;
		end
		else if (XPixelPosition > P4x && XPixelPosition < P4x+P4_paddle_len && YPixelPosition > P4y && YPixelPosition < P4y+10)//Draw p4 paddle
		begin
			redValue <= 8'b00000000; 
			blueValue <= 8'b11111111;
			greenValue <= 8'b11111111;
		end

		else if (((XPixelPosition- itemX)**2 
						+ (YPixelPosition-itemY)**2) < 10**2 && drawItem == 1) 
		begin
			redValue <= color1; 
			blueValue <= color2;
			greenValue <= color3;
		end
		
		else if (tool != 1 && ((XPixelPosition-X1DotPosition)**2 
						+ (YPixelPosition-Y1DotPosition)**2) < 10**2) 
		begin
			redValue <= 8'b11111111; 
			blueValue <= 8'b00000000;
			greenValue <= 8'b00000000;
		end
		
		else if (tool == 1 && ((XPixelPosition-X1DotPosition)**2 
						+ (YPixelPosition-Y1DotPosition)**2) < 20**2) 
		begin
			redValue <= 8'b11111111; 
			blueValue <= 8'b00000000;
			greenValue <= 8'b00000000;
		end
		
		else if(((XPixelPosition-X2DotPosition)**2 + (YPixelPosition-Y2DotPosition)**2) < 10**2)
		begin
			redValue <= 8'b00000000; 
			blueValue <= 8'b11111111;
			greenValue <= 8'b00000000;
		end
		else // default background is black
		begin
			redValue <= 8'b00000000; 
			blueValue <= 8'b00000000;
			greenValue <= 8'b00000000;
		end
	
end

endmodule


//----------------------------------------------------------------------------------------------------------------------
//VGA stuff probably not needed since vga_adapter from lab 6 is included

// The VGAController is the source code
// This is a controller written for a VGA Monitor with resolution 1280 by 1024 with an refresh rate of 60 fps
// VGA Controller use to generate signals for the monitor 
module VGAController (PixelClock,
							 inRed,
							 inGreen,
							 inBlue,
							 outRed,
							 outGreen,
							 outBlue,
							 VertSynchOut,
							 HorSynchOut,
							 XPosition,
							 YPosition);
//======================================================= 
// Parameter Declarations 				
//=======================================================
// Parameters are set for a 1280 by 1024 pixel monitor running at 60 frames per second
// X Screen Constants	 
parameter XLimit = 1688;
parameter XVisible = 1280;
parameter XSynchPulse = 112;
parameter XBackPorch = 248;
// Y Screen Constants
parameter YLimit = 1066;
parameter YVisible = 1024;
parameter YSynchPulse = 3;
parameter YBackPorch = 38;

//=======================================================			 
// Port Declarations 				
//=======================================================
input PixelClock;
input [7:0] inRed;
input [7:0] inGreen;
input [7:0] inBlue;
output [7:0] outRed;
output [7:0] outGreen;
output [7:0] outBlue;
output VertSynchOut;
output HorSynchOut;
output [10:0] XPosition;
output [10:0] YPosition;

//========================================================
// REG/WIRE declarations
//========================================================

reg [10:0] XTiming;
reg [10:0] YTiming;
reg HorSynch;
reg VertSynch;

//========================================================
// Structural coding
//========================================================
assign XPosition = XTiming - (XSynchPulse + XBackPorch);
assign YPosition = YTiming - (YSynchPulse + YBackPorch);


always@(posedge PixelClock)// Control X Timing
begin
	if (XTiming >= XLimit)
		XTiming <= 11'd0;
	else
		XTiming <= XTiming + 1;
end
	
always@(posedge PixelClock)// Control Y Timing
begin
	if (YTiming >= YLimit && XTiming >= XLimit)
		YTiming <= 11'd0;
	else if (XTiming >= XLimit && YTiming < YLimit)
		YTiming <= YTiming + 1;
	else
		YTiming <= YTiming;
end

always@(posedge PixelClock)// Control Vertical Synch Signal
begin
	if (YTiming >= 0 && YTiming < YSynchPulse)
		VertSynch <= 1'b0;
	else
		VertSynch <= 1'b1;
end
	
always@(posedge PixelClock)// Control Horizontal Synch Signal
begin
	if (XTiming >= 0 && XTiming < XSynchPulse)
		HorSynch <= 1'b0;
	else
		HorSynch <= 1'b1;
end
	
// Draw black in off screen areas of screen
assign outRed = (XTiming >= (XSynchPulse + XBackPorch) && XTiming <= (XSynchPulse + XBackPorch + XVisible)) ? inRed : 8'b0;
assign outGreen = (XTiming >= (XSynchPulse + XBackPorch) && XTiming <= (XSynchPulse + XBackPorch + XVisible)) ? inGreen : 8'b0;
assign outBlue = (XTiming >= (XSynchPulse + XBackPorch) && XTiming <= (XSynchPulse + XBackPorch + XVisible)) ? inBlue : 8'b0;

assign VertSynchOut = VertSynch;
assign HorSynchOut = HorSynch;


// Initialization registers block
initial
begin
	XTiming = 11'b0;
	YTiming = 11'b0;
	HorSynch = 1'b1;
	VertSynch = 1'b1;
end
	
	
endmodule 

`timescale 1 ps / 1 ps
// The VGAFrequency is the source code
module VGAFrequency (
	areset,
	inclk0,
	c0);

	input	  areset;
	input	  inclk0;
	output	  c0;
`ifndef ALTERA_RESERVED_QIS
// synopsys translate_off
`endif
	tri0	  areset;
`ifndef ALTERA_RESERVED_QIS
// synopsys translate_on
`endif

	wire [0:0] sub_wire2 = 1'h0;
	wire [4:0] sub_wire3;
	wire  sub_wire0 = inclk0;
	wire [1:0] sub_wire1 = {sub_wire2, sub_wire0};
	wire [0:0] sub_wire4 = sub_wire3[0:0];
	wire  c0 = sub_wire4;

	altpll	altpll_component (
				.areset (areset),
				.inclk (sub_wire1),
				.clk (sub_wire3),
				.activeclock (),
				.clkbad (),
				.clkena ({6{1'b1}}),
				.clkloss (),
				.clkswitch (1'b0),
				.configupdate (1'b0),
				.enable0 (),
				.enable1 (),
				.extclk (),
				.extclkena ({4{1'b1}}),
				.fbin (1'b1),
				.fbmimicbidir (),
				.fbout (),
				.fref (),
				.icdrclk (),
				.locked (),
				.pfdena (1'b1),
				.phasecounterselect ({4{1'b1}}),
				.phasedone (),
				.phasestep (1'b1),
				.phaseupdown (1'b1),
				.pllena (1'b1),
				.scanaclr (1'b0),
				.scanclk (1'b0),
				.scanclkena (1'b1),
				.scandata (1'b0),
				.scandataout (),
				.scandone (),
				.scanread (1'b0),
				.scanwrite (1'b0),
				.sclkout0 (),
				.sclkout1 (),
				.vcooverrange (),
				.vcounderrange ());
	defparam
		altpll_component.bandwidth_type = "AUTO",
		altpll_component.clk0_divide_by = 25,
		altpll_component.clk0_duty_cycle = 50,
		altpll_component.clk0_multiply_by = 54,
		altpll_component.clk0_phase_shift = "0",
		altpll_component.compensate_clock = "CLK0",
		altpll_component.inclk0_input_frequency = 20000,
		altpll_component.intended_device_family = "Cyclone IV E",
		altpll_component.lpm_hint = "CBX_MODULE_PREFIX=VGAFrequency",
		altpll_component.lpm_type = "altpll",
		altpll_component.operation_mode = "NORMAL",
		altpll_component.pll_type = "AUTO",
		altpll_component.port_activeclock = "PORT_UNUSED",
		altpll_component.port_areset = "PORT_USED",
		altpll_component.port_clkbad0 = "PORT_UNUSED",
		altpll_component.port_clkbad1 = "PORT_UNUSED",
		altpll_component.port_clkloss = "PORT_UNUSED",
		altpll_component.port_clkswitch = "PORT_UNUSED",
		altpll_component.port_configupdate = "PORT_UNUSED",
		altpll_component.port_fbin = "PORT_UNUSED",
		altpll_component.port_inclk0 = "PORT_USED",
		altpll_component.port_inclk1 = "PORT_UNUSED",
		altpll_component.port_locked = "PORT_UNUSED",
		altpll_component.port_pfdena = "PORT_UNUSED",
		altpll_component.port_phasecounterselect = "PORT_UNUSED",
		altpll_component.port_phasedone = "PORT_UNUSED",
		altpll_component.port_phasestep = "PORT_UNUSED",
		altpll_component.port_phaseupdown = "PORT_UNUSED",
		altpll_component.port_pllena = "PORT_UNUSED",
		altpll_component.port_scanaclr = "PORT_UNUSED",
		altpll_component.port_scanclk = "PORT_UNUSED",
		altpll_component.port_scanclkena = "PORT_UNUSED",
		altpll_component.port_scandata = "PORT_UNUSED",
		altpll_component.port_scandataout = "PORT_UNUSED",
		altpll_component.port_scandone = "PORT_UNUSED",
		altpll_component.port_scanread = "PORT_UNUSED",
		altpll_component.port_scanwrite = "PORT_UNUSED",
		altpll_component.port_clk0 = "PORT_USED",
		altpll_component.port_clk1 = "PORT_UNUSED",
		altpll_component.port_clk2 = "PORT_UNUSED",
		altpll_component.port_clk3 = "PORT_UNUSED",
		altpll_component.port_clk4 = "PORT_UNUSED",
		altpll_component.port_clk5 = "PORT_UNUSED",
		altpll_component.port_clkena0 = "PORT_UNUSED",
		altpll_component.port_clkena1 = "PORT_UNUSED",
		altpll_component.port_clkena2 = "PORT_UNUSED",
		altpll_component.port_clkena3 = "PORT_UNUSED",
		altpll_component.port_clkena4 = "PORT_UNUSED",
		altpll_component.port_clkena5 = "PORT_UNUSED",
		altpll_component.port_extclk0 = "PORT_UNUSED",
		altpll_component.port_extclk1 = "PORT_UNUSED",
		altpll_component.port_extclk2 = "PORT_UNUSED",
		altpll_component.port_extclk3 = "PORT_UNUSED",
		altpll_component.width_clock = 5;


endmodule


//The module find a random x and random y for the coordinate
module RandomPoint(VGA_clk,randX, randY);
	input VGA_clk;
	output reg [9:0] randX;
	output reg [9:0] randY;

	reg [9:0] x = 260;
	reg [9:0] y = 225;

	always @(posedge VGA_clk)
	begin
	if (x < 1020)
		x <= x+1'b1;
	else
		x <= 10'd260;
	end						
	
	always @(posedge VGA_clk)
	begin
	if (y < 795)
		y <= y+1'b1;
	else
		y <= 10'd225;
	end

	always @(x,y)
	begin
		randX <= x;
		randY <= y;
	end

endmodule

//The module find a random number from 1-10 for rtool and
//random RPG for the tool point.
module RandomTool(VGA_clk, rtool, color1, color2, color3);
	input VGA_clk;
	output reg [3:0] rtool;
	output reg [7:0] color1;
	output reg [7:0] color2;
	output reg [7:0] color3;
	reg [3:0]outp = 1;
	reg [7:0] colorp1 = 1;
	reg [7:0] colorp2 = 1;
	reg [7:0] colorp3 = 1;
	always @(posedge VGA_clk)
	begin
		if (outp < 11)
			outp <= outp + 1;
		else
			outp <= 1;
	end
	always @(posedge VGA_clk)
	begin
		if (colorp1 < 8'b11111111)
			colorp1 <= colorp1 + 1;
		else
			colorp1 <= 1;
	end
	always @(posedge VGA_clk)
	begin
		if (colorp2 < 8'b11111111)
			colorp2 <= colorp2 + 2;
		else
			colorp2 <= 1;
	end
	always @(posedge VGA_clk)
	begin
		if (colorp3 < 8'b11111111)
			colorp3 <= colorp3 + 4;
		else
			colorp3 <= 1;
	end
	always @(outp)
	begin
		rtool <= outp;
	end
	always @(colorp1)
	begin
		color1 <= colorp1;
	end
	always @(colorp2)
	begin
		color2 <= colorp2;
	end
	always @(colorp3)
	begin
		color3 <= colorp3;
	end

endmodule

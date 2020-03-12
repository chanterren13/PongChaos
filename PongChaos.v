//SW[0] and SW[1] in use

module project(
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
wire [10:0] XPixelPosition;
wire [10:0] YPixelPosition; 
reg	[7:0] redValue;
reg	[7:0] greenValue;
reg	[7:0] blueValue;
reg	[2:0] movement = 0;
reg	[3:0] tool = 0;
reg [10:0] r = 10;
reg [10:0] speed = 1;
reg [10:0] P1_paddle_len = 125;
reg [10:0] P2_paddle_len = 125;
reg [10:0] P3_paddle_len = 125;
reg [10:0] P4_paddle_len = 125;
reg [10:0] P1_paddle_speed = 5;
reg [10:0] P2_paddle_speed = 5;
reg [20:0] slowClockCounter = 0;
wire slowClock;
reg [20:0] fastClockCounter = 0;
wire fastClock;
reg	[10:0] XDotPosition = 500;
reg	[10:0] YDotPosition = 500; 
reg	[10:0] P1x = 225;
reg	[10:0] P1y = 500;
reg	[10:0] P2x = 1030;
reg	[10:0] P2y = 500;
reg [10:0] P3x = 567; //midpoint of the field is 630 and paddle length is 125 -> 630 - (125/2) ~= 567
reg [10:0] P3y = 125; //upper bound drawn at y = 125
reg [10:0] P4x = 567;
reg [10:0] P4y = 885; //lower bound drawn at y = 895 + 10 for the width of the paddle
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

//------------------------------------------------------------------------------------------------------
//Controlling Player Movement
//it controls the left paddle.
always@(posedge fastClock)
begin
	if (SW[0] == 1'b1 && game == 1) 
		begin
			if (KEY[2] == 1'b0 && KEY[3] == 1'b0) 
				P1y <= P1y;
			else if (KEY[2] == 1'b0)
				begin
					if (P1y+P1_paddle_len >= 895) //Paddle makes it to the bottom of the area
						P1y <= 895-P1_paddle_len;
					else
						P1y <= P1y + P1_paddle_speed;
				end
			else if (KEY[3] == 1'b0) 
				begin
					if(P1y <= 125) //Paddle makes it to the top of the area
						P1y <= 125;
					else
						P1y <= P1y - P1_paddle_speed;
				end
		end
	
	else if (SW[0] == 1'b0) //Reset
		P1y <= 500;
end

//it controls the right paddle
always@(posedge fastClock)
	begin
		if (SW[0] == 1'b1 && game ==1) 
			begin
				if (KEY[0] == 1'b0 && KEY[1] == 1'b0) 
					P2y <= P2y;
				else if (KEY[0] == 1'b0) begin
					if(P2y+P2_paddle_len >= 895) //Paddle makes it to the bottom of the screen
						P2y <= 895-P2_paddle_len;
					else
					P2y <= P2y + P2_paddle_speed;
				end
				else if (KEY[1] == 1'b0) begin
					if(P2y <= 125) //Paddle makes it to the top of the screen
						P2y <= 125;
					else
						P2y <= P2y - P2_paddle_speed;
				end
		end
	else if (SW[0] == 1'b0) //Reset
		P2y <= 500;
	end

//Controls the top paddle
//Using SW since KEYS are used up - SW[6] to go left, SW[5] to go right
always@(posedge fastClock)
	begin
		if (SW[0] == 1'b1 && game == 1) 
			begin
				if (SW[5] == 1'b0 && SW[6] == 1'b0) 
					P3x <= P3x;
				else if (SW[6] == 1'b1) begin //Moving left
					if(P3x <= 225) //Paddle makes it to the left of the area
						P3x <= 225;
					else
					P3x <= P3x - P3_paddle_speed;
				end
				else if (SW[5] == 1'b1) begin //Moving right
					if(P3x+P3_paddle_len >= 1035) //Paddle makes it to the right of the area
						P3x <= 1035-P3_paddle_len;
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
			if (SW[8] == 1'b0 && SW[9] == 1'b0) 
				P4x <= P4x;
			else if (SW[9] == 1'b1) begin //Moving left
				if(P4x <= 225) //Paddle makes it to the left of the area
					P4x <= 225;
				else
				P4x <= P4x - P4_paddle_speed;
			end
			else if (SW[9] == 1'b1) begin //Moving right
				if(P4x+P4_paddle_len >= 1035) //Paddle makes it to the right of the area
					P4x <= 1035-P4_paddle_len;
				else
					P4x <= P4x + P4_paddle_speed;
			end
	end
else if (SW[0] == 1'b0) //Reset
	P4x <= 567;
end

//It controls the movement of the ball, (XDotPosition, YDotPosition)
always@(posedge slowClock)
begin
	if (SW[0] == 1'b1 && game ==1)
		begin
			clock <= clock + 1;
			printer <= 0;
			case(movement)
				//Change the speed of ball by speed reg
				0:		begin
							XDotPosition <= XDotPosition + speed;
							YDotPosition <= YDotPosition - speed;
						end
				1:		begin
							XDotPosition <= XDotPosition + speed;
							YDotPosition <= YDotPosition + speed;
						end
				2:		begin
							XDotPosition <= XDotPosition - speed;
							YDotPosition <= YDotPosition + speed;
						end
				3:		begin
							XDotPosition <= XDotPosition - speed;
							YDotPosition <= YDotPosition - speed;
						end
				default:	begin
								XDotPosition <= XDotPosition + speed;
								YDotPosition <= YDotPosition - speed;
							end
			endcase
			
			//It runs the changes of ball or paddle randomly
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
			
			//(XDotPosition, YDotPosition) represents the coordinate of the ball
			// when the ball is in some range, change the movement.
			if(YDotPosition - r <= 128 && movement == 0)
				movement = 1;
			else if (YDotPosition - r <= 128 && movement == 3)
				movement = 2;
			else if (YDotPosition + r >= 896 && movement == 1)
				movement = 0;
			else if (YDotPosition + r >= 896 && movement == 2)
				movement = 3;
			else if (XDotPosition - r <= P1x+10 && XDotPosition - r >= P1x+7 && YDotPosition > P1y && YDotPosition < P1y+P1_paddle_len &&  movement == 2)//bounce left paddle from SW
				movement = 1;
			else if (XDotPosition - r <= P1x+10 && XDotPosition - r >= P1x+7 && YDotPosition > P1y && YDotPosition < P1y+P1_paddle_len &&  movement == 3)//bounce left paddle from NW
				movement = 0;
			else if (XDotPosition + r >= P2x && XDotPosition + r <= P2x + 3 && YDotPosition > P2y && YDotPosition < P2y+P2_paddle_len &&  movement == 1)//bounce right paddle from SE 
				movement = 2;
			else if (XDotPosition + r >= P2x && XDotPosition + r <= P2x + 3 && YDotPosition > P2y && YDotPosition < P2y+P2_paddle_len &&  movement == 0)//bounce right paddle from NE
				movement = 3;
			else if (XDotPosition + r >= itemX - r && XDotPosition - r <= itemX + r && YDotPosition + r >= itemY - r && YDotPosition - r <= itemY + r && drawItem == 1)// ball hit the item
				begin
				//Pick the tool randomly and make the change randomly
					clock <= 0;
					if (randomtool == 2 && (movement == 2 || movement == 3))
						tool <= 3;
					else if (randomtool == 3 && (movement == 1 || movement == 0))
						tool <= 2;
					else if (randomtool == 5 && (movement == 1 || movement == 0))
						tool <= 6;
					else if (randomtool == 6 && (movement == 2 || movement == 3))
						tool <= 5;
					else if (randomtool == 7 && (movement == 2 || movement == 3))
						tool <= 8;
					else if (randomtool == 8 && (movement == 1 || movement == 0))
						tool <= 7;
					else if (randomtool == 9 && (movement == 1 || movement == 0))
						tool <= 10;
					else if (randomtool == 10 && (movement == 2 || movement == 3))
						tool <= 9;
					else
						tool <= randomtool;
						
					itemX <= randX;
					itemY <= randY;
					randomtool <= rtool;
					drawItem <= 0;
				end
			else if (XDotPosition - r <= 160)
				begin
					P2Score = P2Score + 1;
					XDotPosition <= 640;
					YDotPosition <= 512;
				end
			else if (XDotPosition + r >= 1120)
				begin
					P1Score = P1Score + 1;
					XDotPosition <= 640;
					YDotPosition <= 512;
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
			XDotPosition <= 640;
			YDotPosition <= 512;
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


// ALL FOR DRAWING ON THE SCREEN
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
		
		else if (tool != 1 && ((XPixelPosition-XDotPosition)**2 
						+ (YPixelPosition-YDotPosition)**2) < 10**2) 
		begin
			redValue <= 8'b11111111; 
			blueValue <= 8'b00000000;
			greenValue <= 8'b00000000;
		end
		
		else if (tool == 1 && ((XPixelPosition-XDotPosition)**2 
						+ (YPixelPosition-YDotPosition)**2) < 20**2) 
		begin
			redValue <= 8'b11111111; 
			blueValue <= 8'b00000000;
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

// Part 2 skeleton jackie

module ball
	(
	CLOCK_50,						//	On Board 50 MHz
		// Your inputs and outputs here
        KEY,
        SW,
		// The ports below are for the VGA output.  Do not change.
		VGA_CLK,   						//	VGA Clock
		VGA_HS,							//	VGA H_SYNC
		VGA_VS,							//	VGA V_SYNC
		VGA_BLANK_N,						//	VGA BLANK
		VGA_SYNC_N,						//	VGA SYNC
		VGA_R,   						//	VGA Red[9:0]
		VGA_G,	 						//	VGA Green[9:0]
		VGA_B,   						//	VGA Blue[9:0]
		HEX0,
		HEX1
	);

	input	CLOCK_50;						//	50 MHz
	input   [9:0]   SW;
	input   [3:0]   KEY;

	// Declare your inputs and outputs here
	// Do not change the following outputs
	output	VGA_CLK;   					//	VGA Clock
	output	VGA_HS;						//	VGA H_SYNC
	output	VGA_VS;						//	VGA V_SYNC
	output	VGA_BLANK_N;					//	VGA BLANK
	output	VGA_SYNC_N;					//	VGA SYNC
	output	[9:0]	VGA_R;   				//	VGA Red[9:0]
	output	[9:0]	VGA_G;	 				//	VGA Green[9:0]
	output	[9:0]	VGA_B;   				//	VGA Blue[9:0]
	output   [6:0] HEX0;
	output   [6:0] HEX1;
	
	wire resetn;
	assign resetn = ~SW[1];
	
	// Create the colour, x, y and writeEn wires that are inputs to the controller.
	wire [2:0] colour;
	wire [7:0] x;
	wire [6:0] y;
	wire writeEn;
	

	// Create an Instance of a VGA controller - there can be only one!
	// Define the number of colours as well as the initial background
	// image file (.MIF) for the controller.
	vga_adapter VGA(
			.resetn(resetn),
			.clock(CLOCK_50),
			.colour(colour),
			.x(x),
			.y(y),
			.plot(writeEn),
			/* Signals for the DAC to drive the monitor. */
			.VGA_R(VGA_R),
			.VGA_G(VGA_G),
			.VGA_B(VGA_B),
			.VGA_HS(VGA_HS),
			.VGA_VS(VGA_VS),
			.VGA_BLANK(VGA_BLANK_N),
			.VGA_SYNC(VGA_SYNC_N),
			.VGA_CLK(VGA_CLK));
		defparam VGA.RESOLUTION = "160x120";
		defparam VGA.MONOCHROME = "FALSE";
		defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;
		defparam VGA.BACKGROUND_IMAGE = "black.mif";
			
	// Put your code here. Your code should produce signals x,y,colour and writeEn/plot
	// for the VGA controller, in addition to any other functionality your design may require.
    
    // Instansiate datapath
	datapath d0(
		.clk(CLOCK_50),
		.reset_n(resetn),
		.plot(writeEn),
		.p1up(~KEY[3]),
		.p1down(~KEY[2]),
		.p2up(~KEY[1]),
		.p2down(~KEY[0]),
		.speed(SW[3:2]),
		.score1_out(HEX1),
		.score2_out(HEX0),
		.p1_clr(SW[9:7]),
		.p2_clr(SW[6:4]),
		.x_out(x),
		.y_out(y),
		.clr_out(colour));

    // Instansiate FSM control
    	control c0(
		.clk(CLOCK_50),
		.reset_n(resetn),
		.go(SW[0]),
		.plot(writeEn));
    
endmodule

module datapath(
	input clk,
	input reset_n,
	input plot,
	input p1up,
	input p1down,
	input p2up,
	input p2down,
	input [1:0] speed,
	input [3:0] p1_clr,
	input	[3:0] p2_clr,
	output [7:0] x_out,
	output [6:0] y_out,
	output [2:0] clr_out,
	output [6:0] score1_out,
	output [6:0] score2_out);

	reg [7:0] x = 8'd80;
	reg [6:0] y = 7'd60;
	reg [7:0] old_x = 8'd80;
	reg [6:0] old_y = 7'd60;
	reg [2:0] clr;
	reg [1:0] q = 2'b00;
	reg [4:0] frame;
	reg [2:0] dir = 3'b000;
	reg done = 1'b0;
	reg count = 1'b1;
	reg draw = 1'b0;
	reg [19:0] Q;
	reg update = 1'b0;
	reg drawed =1'b0;
	reg [2:0] tmp = 3'b000;
	reg [2:0] tmp2 = 3'b000;
	reg [3:0] score1;
	reg [3:0] score2;
	
	//paddles stuff
	reg [7:0] p1_x = 8'd0;
	reg [6:0] p1_y = 7'd55;
	reg [7:0] old_p1x = 8'd0;
	reg [6:0] old_p1y = 7'd55;
	
	reg [7:0] p2_x = 8'd158;
	reg [6:0] p2_y = 7'd55;
	reg [7:0] old_p2x = 8'd158;
	reg [6:0] old_p2y = 7'd55;
	
	reg p1_done = 0;
	reg p1_erased = 0;
	reg p2_done = 0;
	reg p2_erased = 0;
	reg ball_done =0;
	reg ball_erased = 0;
	reg [3:0] p1 = 4'b0000;
	reg [3:0] p2 = 4'b0000;
	
	reg [1:0] count2 = 2'b00;
	reg bounced = 1'b0;
	
	

	
	always @(posedge clk)
	begin //0
		if (!reset_n)
		begin //1
			x <= 8'b01001111;
			old_x <= 8'b01001111;
			y <= 7'b0111011;
			old_y <= 7'b0111011;
			clr <= 3'b111;
			q <= 2'b00;
			draw <= 1'b1;
			
			p1_x <= 8'd0;
			p1_y <= 7'd55;
			old_p1x <= 8'd0;
			old_p1y <= 7'd55;
	
			p2_x <= 8'd158;
			p2_y <= 7'd55;
			old_p2x <= 8'd158;
			old_p2y <= 7'd55;
		end // 1
		else
		begin //0
			if (draw && plot)
			begin //14
				if (q == 2'b11 && !ball_done) begin //3
					x <= old_x + {7'b0000000, q[0]};
					y <= old_y + {6'b000000, q[1]};
					q <= 2'b00;
					//draw <= 1'b0;
					drawed <= 1'b1;
					clr <= 3'b111;
					ball_done <= 1;
					if (p1_done && p2_done) begin //2
							draw <= 1'b0;
						end //2
					end //3
				else if (q == 2'b00 && !ball_done) begin //4
					x <= old_x;
					y <= old_y;
					q <= q + 1'b1;
					clr <= 3'b111;
				end // 4
				else if (!ball_done) begin //5	
					x <= old_x + {7'b0000000, q[0]};
					y <= old_y + {6'b000000, q[1]};
					clr <= 3'b111;
					q <= q + 1'b1;	
					
				end //5
			// drawing paddle 1
			if (drawed && !p1_done) begin //9
				if (p1 == 4'b1111) begin //6
					x <= old_p1x + {7'b0000000, p1[0]};
					y <= old_p1y + {4'b0000, p1[3:1]};
					p1 <= 4'b0000;
					p1_done <= 1'b1;
				end //6
				else if (p1 == 4'b0000) begin //7
					x <= old_p1x;
					y <= old_p1y;
					p1 <= p1 + 1'b1;
					clr <= p1_clr;
				end //7 
				else begin //8
					x <= old_p1x + {7'b0000000, p1[0]};
					y <= old_p1y + {4'b0000, p1[3:1]};
					clr <= p1_clr;
					p1 <= p1+1'b1;
				end //8
			end //9
			// drawing paddle 2
			if (drawed && p1_done && !p2_done) begin //13
				if (p2 == 4'b1111) begin //10
					x <= old_p2x + {7'b0000000, p2[0]};
					y <= old_p2y + {4'b0000, p2[3:1]};
					p2 <= 4'b0000;
					p2_done <= 1'b1;
					draw <= 1'b0;
				end //10
				else if (p2 == 4'b0000) begin //11
					x <= old_p2x;
					y <= old_p2y;
					p2 <= p2 + 1'b1;
					clr <= p2_clr;
				end //11
				else begin //12
					x <= old_p2x + {7'b0000000, p2[0]};
					y <= old_p2y + {4'b0000, p2[3:1]};
					clr <= p2_clr;
					p2 <= p2 + 1'b1;
				end //12
			
			end //13
			end //14

			else if (plot && count == 1'b0 && drawed && tmp2 != 3'b111) begin 
				if (tmp2 == 3'b110) begin 
					drawed <= 1'b0;
				end
				else begin 
					tmp2 <= tmp2 + 1'b1;
				end 
			end
			else if (plot && (!draw && done && !update))
			begin 
				if (q == 2'b11 && !ball_erased) begin
					x <= old_x + {7'b0000000, q[0]};
					y <= old_y + {6'b000000, q[1]};
					q <= 2'b00;
					// draw <= 1'b0;
					// update <= 1'b1;
					ball_erased <= 1'b1;
					end
				else if (q == 2'b00 && !ball_erased) begin
					clr <= 3'b000;
					x <= old_x;
					y <= old_y;
					q <= q + 1;
				end
				else if (!ball_erased) begin 
					
					x <= old_x + {7'b0000000, q[0]};
					y <= old_y + {6'b000000, q[1]};
					clr <= 3'b000;
					q <= q + 1'b1;
				end 
				// erasing p1
				if (ball_erased && !p1_erased) begin
				if (p1 == 4'b1111) begin
					x <= old_p1x + {7'b0000000, p1[0]};
					y <= old_p1y + {4'b0000, p1[3:1]};
					p1 <= 4'b0000;
					p1_erased <= 1'b1;
				end
				else if (p1 == 4'b0000) begin
					x <= old_p1x;
					y <= old_p1y;
					p1 <= p1 + 1'b1;
					clr <= 3'b000;
				end else begin
					x <= old_p1x + {7'b0000000, p1[0]};
					y <= old_p1y + {4'b0000, p1[3:1]};
					clr <= 3'b000;
					p1 <= p1+1'b1;
				end
			end
			
			// erasing paddle 2
			if (p1_erased && !p2_erased) begin
				if (p2 == 4'b1111) begin
					x <= old_p2x + {7'b0000000, p2[0]};
					y <= old_p2y + {4'b0000, p2[3:1]};
					p2 <= 4'b0000;
					p2_erased <= 1'b1;
					draw <= 1'b0;
					update <= 1'b1;
				end
				else if (p2 == 4'b0000) begin
					x <= old_p2x;
					y <= old_p2y;
					p2 <= p2 + 1'b1;
					clr <= 3'b000;
				end else begin
					x <= old_p2x + {7'b0000000, p2[0]};
					y <= old_p2y + {4'b0000, p2[3:1]};
					clr <= 3'b000;
					p2 <= p2 + 1'b1;
				end
			end
			end
			
			else if (update && plot && tmp != 3'b111) begin 
				tmp <= tmp + 1'b1;
				end
			// BALL COLLISION
			else if (update && plot) begin
			
				if (old_x < 8'd1 || old_x > 8'd159) begin
					if (old_x < 8'd1 && score1 < 4'd15) begin
						score1 <= score1 + 1'b1;
					end
					else if (old_x < 8'd1 && score1 == 4'd15) begin
						score1 <= 4'd0;
						old_p1y <= 7'd55;
						old_p2y <= 7'd55;
					end
					else if (old_x > 8'd159 && score2 < 4'd15) begin
						score2 <= score2 + 1'b1;
					end
					else if (old_x > 8'd159 && score2 == 4'd15) begin
						score2 <= 4'd0;
						old_p1y <= 7'd55;
						old_p2y <= 7'd55;
					end
					old_x <= 8'b01001111;
					old_y <= 7'b0111011;
					dir <= 3'b000;
			
				end
				
				else if ((old_y < 7'd1 || old_y > 7'd117)) begin 
					if ((dir == 3'b001) && !bounced) begin //CHANGE BACK TO 001 AFTER
						old_x <= old_x;
						old_y <= old_y +1;
						dir <= 3'b111;
						bounced <= 1'b1;
						end
					else if ((dir == 3'b111) && !bounced) begin 
						dir <= 3'b001;
						old_x <= old_x;
						old_y <= old_y - 1;
						bounced <= 1'b1;
						end
					else if ((dir == 3'b011) && !bounced) begin 
						dir <= 3'b101;
						old_x <= old_x;
						old_y <= old_y + 1;
						bounced <= 1'b1;
						end
					else if ((dir == 3'b101) && !bounced) begin
						dir <= 3'b011;
						old_x <= old_x;
						old_y <= old_y - 1;
						bounced <= 1'b1;
						end
					end
					
				else if (old_x == 8'd2) begin 
					if (old_y > old_p1y -1 && old_y < old_p1y+8) begin
						if (old_p1y == old_y || old_p1y+1 == old_y || old_p1y+2 == old_y) begin
							dir <= 3'b011;
							old_x <= old_x +1;
							old_y <= old_y -1;
						end
						else if (old_p1y + 3 == old_y || old_p1y + 4 == old_y) begin
							dir <= 3'b100;
							old_x <= old_x +1;
							old_y <= old_y;
						end
						
						else if (old_p1y + 5 == old_y || old_p1y + 6 == old_y || old_p1y +7 == old_y) begin
							dir <= 3'b101;
							old_x <= old_x +1;
							old_y <= old_y +1;
						end
					end
				end
				else if (old_x == 8'd157) begin 
					if (old_y > old_p2y -1 && old_y < old_p2y+8) begin
						if (old_p2y == old_y || old_p2y+1 == old_y || old_p2y+2 == old_y) begin
							dir <= 3'b001;
							old_x <= old_x -1;
							old_y <= old_y -1;
						end
						else if (old_p2y + 3 == old_y || old_p2y + 4 == old_y) begin
							old_x <= old_x -1;
							old_y <= old_y;
							dir <= 3'b000;
						end
						else if (old_p2y + 5 == old_y || old_p2y + 6 == old_y || old_p2y +7 == old_y) begin
							dir <= 3'b111;
							old_x <= old_x -1;
							old_y <= old_y +1;
						end
					end
				end
				
				if (count2 != 2'b11) begin
					count2 <= count2 + 1'b1;
					end
				//left
				
				
				if (dir == 3'b000 && count2 == 2'b11) begin
					old_x <= old_x - 1'b1;
					old_y <= old_y;  //CHANGED
					draw <= 1'b1; 
					update <= 1'b0;
					tmp <= 3'b0;
					ball_done <= 1'b0;
					p1_done <= 1'b0;
					p2_done <= 1'b0;
					ball_erased <= 1'b0;
					p1_erased <= 1'b0;
					p2_erased <= 1'b0;
					count2 <= 2'b00;
					bounced <= 1'b0;
					if (p2up == 1'b1 && old_p2y > 0) begin 
						old_p2y <= old_p2y - 1'b1;
						end
					if (p2down == 1'b1 && old_p2y < 7'd111) begin 
						old_p2y <= old_p2y + 1'b1;
						end
					if (p1up == 1'b1 && old_p1y > 0) begin 
						old_p1y <= old_p1y - 1'b1;
						end
					if (p1down == 1'b1 && old_p1y < 7'd111) begin 
						old_p1y <= old_p1y + 1'b1;
						end				
					
					
				end
				// up and left
				else if (dir == 3'b001 && count2 == 2'b11) begin
					old_x <= old_x - 1'b1;
					old_y <= old_y - 1'b1;
					draw <= 1'b1; 
					update <= 1'b0;
					tmp <= 3'b0;
					ball_done <= 1'b0;
					p1_done <= 1'b0;
					p2_done <= 1'b0;
					ball_erased <= 1'b0;
					p1_erased <= 1'b0;
					p2_erased <= 1'b0;
					count2 <= 2'b00;
					bounced <= 1'b0;
					if (p2up == 1'b1 && old_p2y > 0) begin 
						old_p2y <= old_p2y - 1'b1;
						end
					if (p2down == 1'b1 && old_p2y < 7'd112) begin 
						old_p2y <= old_p2y + 1'b1;
						end
					if (p1up == 1'b1 && old_p1y > 0) begin 
						old_p1y <= old_p1y - 1'b1;
						end
					if (p1down == 1'b1 && old_p1y < 7'd112) begin 
						old_p1y <= old_p1y + 1'b1;
						end	
				end
				//up
				else if (dir == 3'b010 && count2 == 2'b11) begin
					old_x <= old_x;
					old_y <= old_y - 1'b1;
					draw <= 1'b1; 
					update <= 1'b0;
					tmp <= 3'b0;
					ball_done <= 'b0;
					p1_done <= 1'b0;
					p2_done <= 1'b0;
					ball_erased <= 1'b0;
					p1_erased <= 1'b0;
					p2_erased <= 1'b0;
					count2 <= 2'b00;
					bounced <= 1'b0;
					if (p2up == 1'b1 && old_p2y > 0) begin 
						old_p2y <= old_p2y - 1'b1;
						end
					if (p2down == 1'b1 && old_p2y < 7'd112) begin 
						old_p2y <= old_p2y + 1'b1;
						end
					if (p1up == 1'b1 && old_p1y > 0) begin 
						old_p1y <= old_p1y - 1'b1;
						end
					if (p1down == 1'b1 && old_p1y < 7'd112) begin 
						old_p1y <= old_p1y + 1'b1;
						end	
				end
				// right up
				else if (dir == 3'b011 && count2 == 2'b11) begin
					old_x <= old_x + 1'b1;
					old_y <= old_y - 1'b1;
					draw <= 1'b1; 
					update <= 1'b0;
					tmp <= 3'b0;
					ball_done <= 1'b0;
					p1_done <= 1'b0;
					p2_done <= 1'b0;
					ball_erased <= 1'b0;
					p1_erased <= 1'b0;
					p2_erased <= 1'b0;
					count2 <= 2'b00;
					bounced <= 1'b0;
					if (p2up == 1'b1 && old_p2y > 0) begin 
						old_p2y <= old_p2y - 1'b1;
						end
					if (p2down == 1'b1 && old_p2y < 7'd112) begin 
						old_p2y <= old_p2y + 1'b1;
						end
					if (p1up == 1'b1 && old_p1y > 0) begin 
						old_p1y <= old_p1y - 1'b1;
						end
					if (p1down == 1'b1 && old_p1y < 7'd112) begin 
						old_p1y <= old_p1y + 1'b1;
						end	
				end
				// right
				else if (dir == 3'b100 && count2 == 2'b11) begin
					old_x <= old_x + 1'b1;
					old_y <= old_y;
					draw <= 1'b1; 
					update <= 1'b0;
					tmp <= 3'b0;
					ball_done <= 1'b0;
					p1_done <= 1'b0;
					p2_done <= 1'b0;
					ball_erased <= 1'b0;
					p1_erased <= 1'b0;
					p2_erased <= 1'b0;
					count2 <= 2'b00;
					bounced <= 1'b0;
					if (p2up == 1'b1 && old_p2y > 0) begin 
						old_p2y <= old_p2y - 1'b1;
						end
					if (p2down == 1'b1 && old_p2y < 7'd112) begin 
						old_p2y <= old_p2y + 1'b1;
						end
					if (p1up == 1'b1 && old_p1y > 0) begin 
						old_p1y <= old_p1y - 1'b1;
						end
					if (p1down == 1'b1 && old_p1y < 7'd112) begin 
						old_p1y <= old_p1y + 1'b1;
						end	
				end
				// down right
				else if (dir == 3'b101 && count2 == 2'b11) begin
					old_x <= old_x + 1'b1;
					old_y <= old_y + 1'b1;
					draw <= 1'b1; 
					update <= 1'b0;
					tmp <= 3'b0;
					ball_done <= 1'b0;
					p1_done <= 1'b0;
					p2_done <= 1'b0;
					ball_erased <= 1'b0;
					p1_erased <= 1'b0;
					p2_erased <= 1'b0;
					count2 <= 2'b00;
					bounced <= 1'b0;
					if (p2up == 1'b1 && old_p2y > 0) begin 
						old_p2y <= old_p2y - 1'b1;
						end
					if (p2down == 1'b1 && old_p2y < 7'd112) begin 
						old_p2y <= old_p2y + 1'b1;
						end
					if (p1up == 1'b1 && old_p1y > 0) begin 
						old_p1y <= old_p1y - 1'b1;
						end
					if (p1down == 1'b1 && old_p1y < 7'd112) begin 
						old_p1y <= old_p1y + 1'b1;
						end	
					end
				//down
				else if (dir == 3'b110 && count2 == 2'b11) begin
					old_x <= old_x;
					old_y <= old_y + 1'b1;
					draw <= 1'b1; 
					update <= 1'b0;
					tmp <= 3'b0;
					ball_done <= 1'b0;
					p1_done <= 1'b0;
					p2_done <= 1'b0;
					ball_erased <= 1'b0;
					p1_erased <= 1'b0;
					p2_erased <= 1'b0;
					count2 <= 2'b00;
					bounced <= 1'b0;
					if (p2up == 1'b1 && old_p2y > 0) begin 
						old_p2y <= old_p2y - 1'b1;
						end
					if (p2down == 1'b1 && old_p2y < 7'd112) begin 
						old_p2y <= old_p2y + 1'b1;
						end
					if (p1up == 1'b1 && old_p1y > 0) begin 
						old_p1y <= old_p1y - 1'b1;
						end
					if (p1down == 1'b1 && old_p1y < 7'd112) begin 
						old_p1y <= old_p1y + 1'b1;
						end	
				end
				else if (dir == 3'b111 && count2 == 2'b11) begin
					old_x <= old_x - 1'b1 ;
					old_y <= old_y + 1'b1;
					draw <= 1'b1; 
					update <= 1'b0;
					tmp <= 3'b0;
					p1_done <= 1'b0;
					p2_done <= 1'b0;
					ball_erased <= 1'b0;
					p1_erased <= 1'b0;
					p2_erased <= 1'b0;
					ball_done <= 1'b0;
					count2 <= 2'b00;
					bounced <= 1'b0;
					if (p2up == 1'b1 && old_p2y > 0) begin 
						old_p2y <= old_p2y - 1'b1;
						end
					if (p2down == 1'b1 && old_p2y < 7'd112) begin 
						old_p2y <= old_p2y + 1'b1;
						end
					if (p1up == 1'b1 && old_p1y > 0) begin 
						old_p1y <= old_p1y - 1'b1;
						end
					if (p1down == 1'b1 && old_p1y < 7'd112) begin 
						old_p1y <= old_p1y + 1'b1;
						end	
				end
		
				
		end
			
		else
			begin 
			x <= x;
			y <= y;
			old_x <= old_x;
			old_y <= old_y;
			end 
		end
	end 
	
	assign x_out = x;
	assign y_out = y;
	assign clr_out = clr;
	
	
	
	always @(posedge clk)
	begin
		if (!reset_n) begin 
			Q <= 20'b00100001111010000111;
			frame <= 5'b01110;
		end 
		else if(plot && ((!draw && count) || update)) begin
			Q <= 20'b00100001111010000111;
			if (speed == 2'b00) begin
				frame <= 5'b01110;
			end
			else if (speed == 2'b01) begin
				frame <= 5'b11100;
			end
			else if (speed == 2'b11) begin
				frame <= 5'b00111;
			end
			if (drawed) begin
				count <= 1'b0;
				end
			if (!update) begin
				done <= done;
				end
			if (!drawed) begin 
				count <= count;
				end
			if (update) begin 
				done <= 1'b0;
				end
			
		end
		else if(Q == 20'b00000000000000000000 && frame == 5'b00000) begin 
			Q <= 20'b00100001111010000111;
			if (speed == 2'b00) begin
				frame <= 5'b01110;
			end
			else if (speed == 2'b01) begin
				frame <= 5'b11100;
			end
			else if (speed == 2'b11) begin
				frame <= 5'b00111;
			end
			done <= 1'b1;
			count <= 1'b1;
						
		end
				
		else if(Q == 20'b00000000000000000000) begin
			Q <= 20'b00100001111010000111;
			frame <= frame - 1;
				
		end
		else begin
			Q <= Q - 1'b1;
		end
	end
	
	decoder d1(
		.S(score1),
		.HEX(score1_out));
	decoder d2(
		.S(score2),
		.HEX(score2_out));
		
endmodule

module control(
	input clk,
	input reset_n,
	input go,
	output reg plot);

	reg [2:0] current_state, next_state;

	localparam
		Wait = 3'd0,
		Start = 3'd1;
		
	always @(*)
	begin 
		case (current_state)
			Wait: next_state = go ? Start : Wait;
			Start: next_state = Start;
			default: next_state = Wait;
		endcase
	end

	always @(*)
	begin
		plot = 1'b0;

		case (current_state)
			Start:
				begin
					plot = 1'b1;
				end
		endcase
	end

	always @(posedge clk)
	begin
		if (!reset_n) begin 
			current_state <= Wait;
		end
		else begin 
			current_state <= next_state;
		end
	end
endmodule

module decoder(HEX, S);
	input [3:0] S;
	output [6:0] HEX;

	assign HEX[0] = (~S[3] & ~S[2] & ~S[1] & S[0]) | (~S[3] & S[2] & ~S[1] & ~S[0]) | (S[3] & S[2] & ~S[1] & S[0]) | (S[3] & ~S[2] & S[1] & S[0]);
	assign HEX[1] = (S[2] & S[1] & ~S[0]) | (S[3] & S[1] & S[0]) | (~S[3] & S[2] & ~S[1] & S[0]) | (S[3] & S[2] & ~S[1] & ~S[0]);
	assign HEX[2] = (~S[3] & ~S[2] & S[1] & ~S[0]) | (S[3] & S[2] & S[1]) | (S[3] & S[2] & ~S[0]);
	assign HEX[3] = (~S[3] & ~S[2] & ~S[1] & S[0]) | (~S[3] & S[2] & ~S[1] & ~S[0]) | (S[3] & ~S[2] & S[1] & ~S[0]) | (S[2] & S[1] & S[0]);
	assign HEX[4] = (~S[3] & S[0]) | (~S[3] & S[2] & ~S[1]) | (~S[2] & ~S[1] & S[0]);
	assign HEX[5] = (~S[3] & ~S[2] & S[0]) | (~S[3] & ~ S[2] & S[1]) | (~S[3] & S[1] & S[0]) | (S[3] & S[2] & ~S[1] & S[0]);
	assign HEX[6] = (~S[3] & ~S[2] & ~S[1]) | (S[3] & S[2] & ~S[1] & ~S[0]) | (~S[3] & S[2] & S[1] & S[0]);
endmodule

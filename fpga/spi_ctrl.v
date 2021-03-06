`timescale 1ns / 1ps
/*
   SPI controller module
   Author: ljalvs@gmail.com
   
   Simple SPI controller

   2012.05.15, ljalvs@gmail.com, Created.

*/

module spi_ctrl(
	input wire clk,
	input wire rst_n,
	
	// cpu bus interface
	input wire [15:0] spi_datain,
	output wire [15:0] spi_dataout,
	input wire spi_wrh_n,

	// spi physical interface
	input wire miso,
	output wire mosi,
	output wire cs_n,
	output reg sclk
);


	reg [1:0] state;
	reg [7:0] treg;
	assign mosi = treg[7];


	// low byte = control
	// high byte = data

	wire en;
	wire [2:0] div;
	wire busy;
	assign busy = |state;
	
	assign div   =  spi_datain[2:0];
	assign clk_p =  spi_datain[3];
	assign cs_n  = ~spi_datain[4];
	assign en    =  spi_datain[5];
	
	assign spi_dataout[7:0] = {busy, spi_datain[6:0]};
	assign spi_dataout[15:8] = treg[7:0];
	
	parameter IDLE = 2'b00;
	parameter LAT  = 2'b10;
	parameter CLK  = 2'b01;
	parameter SHFT = 2'b11;
	

	reg [2:0] bcnt;
	reg [6:0] clkcnt;

	wire ena;
	assign ena = ~|clkcnt;

	

	always @(posedge clk)
		if(en & (|clkcnt & |state))
			clkcnt <= clkcnt - 7'h1;
		else
			case (div) // synopsys full_case parallel_case
				3'b000: clkcnt <= 7'h0;   // 2
				3'b001: clkcnt <= 7'h1;   // 4
				3'b010: clkcnt <= 7'h3;   // 8
				3'b011: clkcnt <= 7'h7;   // 16
				3'b100: clkcnt <= 7'hf;   // 32
				3'b101: clkcnt <= 7'h1f;  // 64
				3'b110: clkcnt <= 7'h3f;  // 128
				3'b111: clkcnt <= 7'h7f;  // 256
			endcase	


	reg delay;
	reg miso_r;

	always @(posedge clk or negedge rst_n) begin
		if (~rst_n) begin
			treg <= 8'h00;
			sclk <= 0;
			bcnt <= 3'h7;
			state <= IDLE;
			delay <= 0;
			miso_r <= 0;
		end else begin
			case (state)
				IDLE: begin
					bcnt <= 3'h7;
					sclk <= clk_p;
					
					delay <= 0;
					if (~spi_wrh_n)
						state <= LAT;
				end
				
				LAT: begin
					delay <= 1;
					sclk <= 0;
					if (delay) begin
						treg <= spi_datain[15:8];
						state <= CLK;
					end
				end
				
				CLK: begin
					if (ena) begin
						sclk <= ~ sclk;
						state <= SHFT;
						miso_r <= miso;
					end
				end
				SHFT: begin
					if (ena) begin
						treg <= {treg[6:0], miso_r};
						bcnt <= bcnt - 3'h1;
						if (~|bcnt) begin
							state <= IDLE;
							sclk <= sclk;
						end else begin
							state <= CLK;
							sclk <= ~sclk;
						end
					end
				end
				default: state <= IDLE;

				endcase
		end
	end

endmodule

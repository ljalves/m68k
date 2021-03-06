`timescale 1ns / 1ps

/* `undef TEST_MAS3507D */

module bus_ctrl(

	input wire clk,
	input wire sysclk,
	input wire rst_n,
	
	input wire rdl_n,
	input wire rdh_n,
	input wire wrl_n,
	input wire wrh_n,

	input wire as_n,

	input wire fpga_cs_n,
	
	// interrupt controller
	output wire intr_cycle_n,
	input wire [7:0] intr_vector,
	input wire intr_vpa_n,
	input wire intr_dtack_n,
	output reg [15:0] intr_ctrl_in,
	input wire [15:0] intr_ctrl_out,
	
	
	// cpu bus interface
	output wire vpa_n,
	output wire dtack_n,
	
	
	input wire [23:1] cpu_addrbus,
	inout wire [15:0] cpu_databus,
	input wire [2:0] cpu_fc,
	
	// global peripheral control register
	output reg [7:0] pcr_ctrl,
	//input wire [7:0] pcr_status,

	// timer0
	output reg [15:0] timer0_preset,
	input wire [15:0] timer0_value,
	/*output reg [7:0] timer0_ctrl_in,
	input wire [7:0] timer0_ctrl_out,*/
	output wire timer0_rst_int_n,

	// timer1
	/*output reg [23:0] timer1_preset,
	input wire [23:0] timer1_value,
	output reg [7:0] timer1_ctrl_in,
	input wire [7:0] timer1_ctrl_out,
	output wire timer1_rst_int_n,*/
	
	// DS12887 RTC
	output reg [15:0] rtc_datain,
	input wire [15:0] rtc_dataout,
	output wire rtc_rdh_n,
	output wire rtc_rdl_n,
	output wire rtc_wrh_n,
	output wire rtc_wrl_n,
	input wire rtc_dtack_n,
	
	// ENJ28J60
	output reg [15:0] eth_datain,
	input wire [15:0] eth_dataout,
	output wire eth_wrh_n,

	// SDCARD
	output reg [15:0] sd_datain,
	input wire [15:0] sd_dataout,
	output wire sd_wrh_n,
	output wire sd_cd_rst_int_n,
	input wire sd_cd_n,

	// ADC
	output reg [15:0] adc_datain,
	input wire [15:0] adc_dataout,
	output wire adc_wrh_n,


	// UART
	output reg [7:0] uart_datain,
	input wire [7:0] uart_dataout,
	output reg [7:0] uart_ctrlin,
	input wire [7:0] uart_ctrlout,
	
	output wire uart_wrh_n,
	output wire uart_rdh_n,

	// I2C
	output reg [7:0] i2c_datain,
	input wire [7:0] i2c_dataout,
	output reg [7:0] i2c_ctrlin,
	input wire [7:0] i2c_ctrlout,

	output wire i2c_wrh_n,
	output wire i2c_wrl_n,
	output wire i2c_rdh_n

	// MAS3507D
	`ifdef TEST_MAS3507D
	output reg [15:0] mas_datain,
	input wire [15:0] mas_dataout,
	output wire mas_wrh_n,
	`endif
	

);


	wire rdl_fpga_n, rdh_fpga_n;
	assign rdl_fpga_n = ~(~rdl_n & ~fpga_cs_n);
	assign rdh_fpga_n = ~(~rdh_n & ~fpga_cs_n);

	wire wrl_fpga_n, wrh_fpga_n;
	assign wrl_fpga_n = ~(~wrl_n & ~fpga_cs_n);
	assign wrh_fpga_n = ~(~wrh_n & ~fpga_cs_n);
	


	reg [15:0] dataout;
	assign cpu_databus[15:8] = ~rdh_fpga_n ? dataout[15:8] : 8'hzz;
	// interrupt vector in D[7:0]
	assign cpu_databus[7:0] = ~intr_cycle_n ? intr_vector[7:0] : (~rdl_fpga_n ? dataout[7:0] : 8'hzz);
	


	// timer0
	//assign timer0_rst_int_n = ~((cpu_addrbus[19:1] == 19'h0) & ~wrh_fpga_n);
	
	// timer1
	//assign timer1_rst_int_n = ~((cpu_addrbus[19:1] == 19'h2) & ~wrh_fpga_n);

	// DS12887 RTC
	assign rtc_rdh_n = ~((cpu_addrbus[19:7] == 13'h2) & ~rdh_fpga_n);
	assign rtc_rdl_n = ~((cpu_addrbus[19:7] == 13'h2) & ~rdl_fpga_n);
	assign rtc_wrh_n = ~((cpu_addrbus[19:7] == 13'h2) & ~wrh_fpga_n);
	assign rtc_wrl_n = ~((cpu_addrbus[19:7] == 13'h2) & ~wrl_fpga_n);
	assign rtc_cs    =  ((cpu_addrbus[19:7] == 13'h2) & ~fpga_cs_n);
	
	// ENC28J60
	assign eth_wrh_n = ~((cpu_addrbus[19:1] == 19'h000A) & ~wrh_fpga_n);
	
	// SDCARD
	assign sd_wrh_n = ~((cpu_addrbus[19:1] == 19'h000B) & ~wrh_fpga_n);
	
	// ADC
	assign adc_wrh_n = ~((cpu_addrbus[19:1] == 19'h000C) & ~wrh_fpga_n);

	// UART
	assign uart_wrh_n = ~((cpu_addrbus[19:1] == 19'h0010) & ~wrh_fpga_n);
	assign uart_rdh_n = ~((cpu_addrbus[19:1] == 19'h0010) & ~rdh_fpga_n);
	//assign uart_rdl_n = ~((cpu_addrbus[19:1] == 19'h0010) & ~rdl_fpga_n);

	// I2C
	assign i2c_wrh_n = ~((cpu_addrbus[19:1] == 19'h0018) & ~wrh_fpga_n);
	assign i2c_wrl_n = ~((cpu_addrbus[19:1] == 19'h0018) & ~wrl_fpga_n);
	assign i2c_rdh_n = ~((cpu_addrbus[19:1] == 19'h0018) & ~rdh_fpga_n);


	// MAS3507D
	`ifdef TEST_MAS3507D
	assign mas_wrh_n = ~((cpu_addrbus[19:1] == 19'h0019) & ~wrh_fpga_n);
   `endif


	// interrupt cycle flag
	assign intr_cycle_n = ~(~as_n & (cpu_fc[2:0] == 3'b111));
	
	
	assign vpa_n = ~intr_cycle_n ? intr_vpa_n : 1;
	assign dtack_n = ~intr_cycle_n ? intr_dtack_n : (
                    rtc_cs ? rtc_dtack_n : (
                    ~as_n ? 0 : 1));




	// PCR write high
	assign wrh_pcr_n = ~((cpu_addrbus[19:1] == 19'h0) & ~wrh_fpga_n);
	// reset t0 int
	assign timer0_rst_int_n = ~(~wrh_pcr_n & cpu_databus[8]);
	// reset card detect int
	assign sd_cd_rst_int_n  = ~(~wrh_pcr_n & cpu_databus[9]);




	/* address decoder */
	always @(posedge sysclk or negedge rst_n)
		if (!rst_n) begin
			dataout[15:0] <= 16'hFFFF;
			
			//timer0_ctrl_in[7:0] <= 8'h00;
			timer0_preset[15:0] <= 16'h0000;

			/*timer1_ctrl_in[7:0] <= 8'h00;
			timer1_preset[23:0] <= 24'h234567;*/	 
			
			rtc_datain[15:0]   <= 16'h0000;
			intr_ctrl_in[15:0] <= 16'h0000;
			eth_datain[15:0]   <= 16'h0000;
			sd_datain[15:0]    <= 16'h0000;
			adc_datain[15:0]   <= 16'h0000;
			
			uart_datain[7:0] <= 8'h00;
			uart_ctrlin[7:0] <= 8'h00;
			pcr_ctrl[7:0]    <= 8'h00;
			i2c_datain[7:0]  <= 8'h00;
			i2c_ctrlin[7:0]  <= 8'h00;

		end else begin
			casex (cpu_addrbus[19:1])
				// PCR register @ 0xF00000 ~ 0xF00001
				19'h00000: begin
					/*if (~wrh_fpga_n)
						pcr_ctrl[15:8] <= cpu_databus[15:8];*/
					if (~wrl_fpga_n)
						pcr_ctrl[7:0] <= cpu_databus[7:0];
					/*if (~rdh_fpga_n)
						dataout[15:8] <= pcr_ctrl[15:8];*/
					if (~rdl_fpga_n)
						dataout[7:0] <= pcr_ctrl[7:0];
				end

			
				// timer0 @ 0xF00002 ~ 0xF00003
				19'h00001: begin
					if (~wrh_fpga_n)
						timer0_preset[15:8] <= cpu_databus[15:8];
					if (~wrl_fpga_n)
						timer0_preset[7:0] <= cpu_databus[7:0];
					if (~rdh_fpga_n)
						dataout[15:8] <= timer0_value[15:8];
					if (~rdl_fpga_n)
						dataout[7:0] <= timer0_value[7:0];
				end
				
				// timer1 @ 0xF00008 ~ 0xF0000F
				/*19'h00004: begin
					if (~wrh_fpga_n)
						timer1_ctrl_in[7:0] <= cpu_databus[15:8];
					if (~wrl_fpga_n)
						timer1_preset[23:16] <= cpu_databus[7:0];
					if (~rdh_fpga_n)
						dataout[15:8] <= timer1_ctrl_out[7:0];
					if (~rdl_fpga_n)
						dataout[7:0] <= timer1_preset[23:16];
				end
				19'h00005: begin
					if (~wrh_fpga_n)
						timer1_preset[15:8] <= cpu_databus[15:8];
					if (~wrl_fpga_n)
						timer1_preset[7:0] <= cpu_databus[7:0];
					if (~rdh_fpga_n)
						dataout[15:8] <= timer1_preset[15:8];
					if (~rdl_fpga_n)
						dataout[7:0] <= timer1_preset[7:0];
				end
				19'h00006: begin
					if (~rdh_fpga_n)
						dataout[15:8] <= 8'h00;
					if (~rdl_fpga_n)
						dataout[7:0] <= timer1_value[23:16];
				end
				19'h00007: begin
					if (~rdh_fpga_n)
						dataout[15:8] <= timer1_value[15:8];
					if (~rdl_fpga_n)
						dataout[7:0] <= timer1_value[7:0];
				end*/
				

				
				// interrupt controller @ 0xF00010
				19'h00008: begin
					if (~wrh_fpga_n)
						intr_ctrl_in[15:8] <= cpu_databus[15:8];
					if (~wrl_fpga_n)
						intr_ctrl_in[7:0] <= cpu_databus[7:0];
					if (~rdh_fpga_n)
						dataout[15:8] <= intr_ctrl_out[15:8];
					if (~rdl_fpga_n)
						dataout[7:0] <= intr_ctrl_out[7:0];
				end
				
				// eth spi @ 0xF00014
				19'h0000A: begin
					if (~wrh_fpga_n)
						eth_datain[15:8] <= cpu_databus[15:8];
					if (~wrl_fpga_n)
						eth_datain[7:0] <= cpu_databus[7:0];
					if (~rdh_fpga_n)
						dataout[15:8] <= eth_dataout[15:8];
					if (~rdl_fpga_n)
						dataout[7:0] <= eth_dataout[7:0];
				end

				// sdcard spi @ 0xF00016
				19'h0000B: begin
					if (~wrh_fpga_n)
						sd_datain[15:8] <= cpu_databus[15:8];
					if (~wrl_fpga_n)
						sd_datain[7:0] <= cpu_databus[7:0];
					if (~rdh_fpga_n)
						dataout[15:8] <= sd_dataout[15:8];
					if (~rdl_fpga_n)
						dataout[7:0] <= {sd_dataout[7], sd_cd_n, sd_dataout[5:0]};
				end

				// adc spi @ 0xF00018
				19'h0000C: begin
					if (~wrh_fpga_n)
						adc_datain[15:8] <= cpu_databus[15:8];
					if (~wrl_fpga_n)
						adc_datain[7:0] <= cpu_databus[7:0];
					if (~rdh_fpga_n)
						dataout[15:8] <= adc_dataout[15:8];
					if (~rdl_fpga_n)
						dataout[7:0] <= adc_dataout[7:0];
				end


				// uart controller @ 0xF00020
				19'h00010: begin
					if (~wrh_fpga_n)
						uart_datain[7:0] <= cpu_databus[15:8];
					if (~wrl_fpga_n)
						uart_ctrlin[7:0] <= cpu_databus[7:0];
					if (~rdh_fpga_n)
						dataout[15:8] <= uart_dataout[7:0];
					if (~rdl_fpga_n)
						dataout[7:0] <= uart_ctrlout[7:0];
				end

				// i2c controller @ 0xF00030
				19'h00018: begin
					if (~wrh_fpga_n)
						i2c_datain[7:0] <= cpu_databus[15:8];
					if (~wrl_fpga_n)
						i2c_ctrlin[7:0] <= cpu_databus[7:0];
					if (~rdh_fpga_n)
						dataout[15:8] <= i2c_dataout[7:0];
					if (~rdl_fpga_n)
						dataout[7:0] <= i2c_ctrlout[7:0];
				end

				// mas3507d controller @ 0xF00032
				`ifdef TEST_MAS3507D
				19'h00019: begin
					if (~wrh_fpga_n)
						mas_datain[15:8] <= cpu_databus[15:8];
					if (~wrl_fpga_n)
						mas_datain[7:0] <= cpu_databus[7:0];
					if (~rdh_fpga_n)
						dataout[15:8] <= mas_dataout[15:8];
					if (~rdl_fpga_n)
						dataout[7:0] <= mas_dataout[7:0];
				end
				`endif
				
				// rtc @ 0xF00100
				19'b0000000000010xxxxxx: begin
					if (~wrh_fpga_n)
						rtc_datain[15:8] <= cpu_databus[15:8];
					if (~wrl_fpga_n)
						rtc_datain[7:0] <= cpu_databus[7:0];
					if (~rdh_fpga_n)
						dataout[15:8] <= rtc_dataout[15:8];
					if (~rdl_fpga_n)
						dataout[7:0] <= rtc_dataout[7:0];
				end

				
				
				/*
				19'h0040: begin
					if (~wrh_fpga_n)
						dma_src_addr[31:24] <= cpu_databus[15:8];
					if (~wrl_fpga_n)
						dma_src_addr[23:16] <= cpu_databus[7:0];
					if (~rdh_fpga_n)
						dataout[15:8] <= dma_src_addr[31:24];
					if (~rdl_fpga_n)
						dataout[7:0] <= dma_src_addr[23:16];
				end
				19'h0041: begin
					if (~wrh_fpga_n)
						dma_src_addr[15:8] <= cpu_databus[15:8];
					if (~wrl_fpga_n)
						dma_src_addr[7:0] <= cpu_databus[7:0];
					if (~rdh_fpga_n)
						dataout[15:8] <= dma_src_addr[15:8];
					if (~rdl_fpga_n)
						dataout[7:0] <= dma_src_addr[7:0];
				end

				19'h0042: begin
					if (~wrh_fpga_n)
						dma_dst_addr[31:24] <= cpu_databus[15:8];
					if (~wrl_fpga_n)
						dma_dst_addr[23:16] <= cpu_databus[7:0];
					if (~rdh_fpga_n)
						dataout[15:8] <= dma_dst_addr[31:24];
					if (~rdl_fpga_n)
						dataout[7:0] <= dma_dst_addr[23:16];
				end
				19'h0043: begin
					if (~wrh_fpga_n)
						dma_dst_addr[15:8] <= cpu_databus[15:8];
					if (~wrl_fpga_n)
						dma_dst_addr[7:0] <= cpu_databus[7:0];
					if (~rdh_fpga_n)
						dataout[15:8] <= dma_dst_addr[15:8];
					if (~rdl_fpga_n)
						dataout[7:0] <= dma_dst_addr[7:0];
				end
			
				19'h0044: begin
					if (~rdh_fpga_n)
						dataout[15:8] <= q[31:24];
					if (~rdl_fpga_n)
						dataout[7:0] <= q[31:24];
				end
				19'h0045: begin
					if (~rdh_fpga_n)
						dataout[15:8] <= q[15:8];
					if (~rdl_fpga_n)
						dataout[7:0] <= q[7:0];
				end*/
				
			endcase
		
		
		end



endmodule

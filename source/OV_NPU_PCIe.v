module OV_NPU_PCIe   #(
   parameter MEM_ROW_WIDTH        = 15         ,
   parameter MEM_COLUMN_WIDTH     = 10         ,
   parameter MEM_BANK_WIDTH       = 3          ,
   parameter MEM_DQ_WIDTH         = 16         ,
   parameter MEM_DQS_WIDTH        = 2          ,

   parameter USER_S_ID_WIDTH   = 10           ,
   parameter USER_M_ID_WIDTH   = 11           ,
   parameter USER_ADDR_WIDTH   = 64           ,
   parameter USER_DATA_WIDTH   = 128          ,
   parameter USER_STRB_WIDTH   = 16           ,
   parameter USER_WUSER_WIDTH  = 1            ,
   parameter USER_BUSER_WIDTH  = 1            ,
   parameter USER_ARUSER_WIDTH = 1            ,
   parameter USER_RUSER_WIDTH  = 1            ,
   parameter USER_AWUSER_WIDTH = 1
)(
   input                                free_clk                  ,
   input                                board_rst_n               ,
   //DDR3
   output                               mem_cs_n                  ,  
   output                               mem_rst_n                 ,
   output                               mem_ck                    ,
   output                               mem_ck_n                  ,
   output                               mem_cke                   ,
   output                               mem_ras_n                 ,
   output                               mem_cas_n                 ,
   output                               mem_we_n                  ,
   output                               mem_odt                   ,
   output      [MEM_ROW_WIDTH-1:0]      mem_a                     ,
   output      [MEM_BANK_WIDTH-1:0]     mem_ba                    ,
   inout       [MEM_DQ_WIDTH/8-1:0]     mem_dqs                   ,
   inout       [MEM_DQ_WIDTH/8-1:0]     mem_dqs_n                 ,
   inout       [MEM_DQ_WIDTH-1:0]       mem_dq                    ,
   output      [MEM_DQ_WIDTH/8-1:0]     mem_dm                    ,
   //PCIe
   input	     			                   ref_clk_p                 ,		   
	input	     			                   ref_clk_n                 ,		   
	input	     			                   perst_n                   ,		   
	input	      [1:0]		                rxn                       ,		   
	input	      [1:0]		                rxp                       ,		   
	output wire	[1:0]		                txn                       ,		   
	output wire	[1:0]		                txp                       ,			 
   //CMOS2
   inout                                cmos2_scl                 ,
   inout                                cmos2_sda                 ,
   input                                cmos2_vsync               ,
   input                                cmos2_href                ,
   input                                cmos2_pclk                ,
   input       [7:0]                    cmos2_data                ,
   output                               cmos2_reset                 
);

parameter CTRL_ADDR_WIDTH = MEM_ROW_WIDTH + MEM_BANK_WIDTH + MEM_COLUMN_WIDTH;
parameter TH_1S = 27'd33000000;
parameter REM_DQS_WIDTH = 9 - MEM_DQS_WIDTH;
wire  [1:0]                  cmos_init_done             ;
reg                          heart_beat_led             ;
reg                          pclk_led                   ;
reg                          ref_led                    ;

wire                         ddrphy_cpd_lock            ;
wire                         ddr_init_done              ;
wire                         pll_lock                   ;
wire                         core_clk                   ;
wire  [CTRL_ADDR_WIDTH-1:0]  axi_awaddr                 ;
wire                         axi_awuser_ap              ;
wire  [3:0]                  axi_awuser_id              ;
wire  [3:0]                  axi_awlen                  ;
wire                         axi_awready                ;
wire                         axi_awvalid                ;
wire  [MEM_DQ_WIDTH*8-1:0]   axi_wdata                  ;
wire  [MEM_DQ_WIDTH*8/8-1:0] axi_wstrb                  ;
wire                         axi_wready                 ;
wire  [3:0]                  axi_wusero_id              ;
wire                         axi_wusero_last            ;
wire  [CTRL_ADDR_WIDTH-1:0]  axi_araddr                 ;
wire                         axi_aruser_ap              ;
wire  [3:0]                  axi_aruser_id              ;
wire  [3:0]                  axi_arlen                  ;
wire                         axi_arready                ;
wire                         axi_arvalid                ;
wire  [MEM_DQ_WIDTH*8-1:0]   axi_rdata                  /* synthesis syn_keep = 1 */;
wire                         axi_rvalid                 /* synthesis syn_keep = 1 */;
wire  [3:0]                  axi_rid                    ;
wire                         axi_rlast                  ;
wire                         resetn                     ;
reg   [26:0]                 cnt                        ;
wire  [7:0]                  err_cnt                    ;
wire                         free_clk_g                 ;
//cmos
reg   [15:0]                 rstn_1ms                   ;
wire                         cmos_scl                   ;
wire                         cmos_sda                   ;
wire                         cmos_vsync                 ;
wire                         cmos_href                  ;
wire                         cmos_pclk                  ;
wire  [7:0]                  cmos_data                  ;
wire                         cmos_reset                 ;
wire                         initial_en                 ;
wire  [15:0]                 cmos2_d_16bit              /*synthesis PAP_MARK_DEBUG="1"*/;
wire                         cmos2_href_16bit           /*synthesis PAP_MARK_DEBUG="1"*/;
reg   [7:0]                  cmos2_d_d0                 /*synthesis PAP_MARK_DEBUG="1"*/;
reg                          cmos2_href_d0              /*synthesis PAP_MARK_DEBUG="1"*/;
reg                          cmos2_vsync_d0             /*synthesis PAP_MARK_DEBUG="1"*/;
wire                         cmos2_pclk_16bit           /*synthesis PAP_MARK_DEBUG="1"*/;
wire  [15:0]                 o_rgb565                   ;
wire                         pclk_in_test               ;    
wire                         vs_in_test                 ;
wire                         de_in_test                 ;
wire  [15:0]                 i_rgb565                   ;
wire                         pclk_in_test_2             ;    
wire                         vs_in_test_2               ;
wire                         de_in_test_2               ;
wire  [15:0]                 i_rgb565_2                 ;

localparam      DEVICE_TYPE      =    3'b000            ;			
localparam      AXIS_SLAVE_NUM   =    3                 ;				

// PCIe core interface
wire 			                pcie_cfg_ctrl_en           ;			
wire 			                axis_master_tready_cfg     ;		
wire 			                cfg_axis_slave0_tvalid     ;		
wire  [127:0]               cfg_axis_slave0_tdata      ;		
wire 			                cfg_axis_slave0_tlast      ;		
wire 			                cfg_axis_slave0_tuser      ;		
wire 			                axis_master_tready_mem     ;		
wire 			                axis_master_tvalid_mem     ;		
wire  [127:0]               axis_master_tdata_mem      ;		
wire  [3:0]	                axis_master_tkeep_mem      ;													
wire 			                axis_master_tlast_mem      ;		
wire  [7:0]	                axis_master_tuser_mem      ;		
wire 			                cross_4kb_boundary         ;		
wire 			                dma_axis_slave0_tvalid     ;		
wire  [127:0]               dma_axis_slave0_tdata      ;		
wire 			                dma_axis_slave0_tlast      ;		
wire 			                dma_axis_slave0_tuser      ;		
// Reset debounce and sync
wire 		                   sync_button_rst_n          ; 			
wire 		                   ref_core_rst_n             ;	
wire                        sync_perst_n               ;			
wire 		                   s_pclk_rstn                ;				
// Internal signal
wire			                pclk_div2                  /*synthesis PAP_MARK_DEBUG="1"*/; 
wire			                pclk                       /*synthesis PAP_MARK_DEBUG="1"*/;				
wire			                ref_clk                    ; 					
wire			                core_rst_n                 ;					
wire			                axis_master_tvalid         ;
wire			                axis_master_tready         ;
wire  [127:0]	             axis_master_tdata          ;
wire	[3:0]	                axis_master_tkeep          ;
wire			                axis_master_tlast          ;
wire	[7:0]	                axis_master_tuser          ;
wire			                axis_slave0_tready         ;
wire			                axis_slave0_tvalid         ;
wire	[127:0]	             axis_slave0_tdata          ;
wire			                axis_slave0_tlast          ;
wire			                axis_slave0_tuser          ;
wire			                axis_slave1_tready         ;
wire			                axis_slave1_tvalid         ;
wire	[127:0]	             axis_slave1_tdata          ;
wire			                axis_slave1_tlast          ;
wire			                axis_slave1_tuser          ;
wire			                axis_slave2_tready         ;
wire			                axis_slave2_tvalid         ;
wire	[127:0]	             axis_slave2_tdata          ;
wire			                axis_slave2_tlast          ;
wire			                axis_slave2_tuser          ;
wire	[7:0]	                cfg_pbus_num               ;			
wire	[4:0]	                cfg_pbus_dev_num           ;
wire	[2:0]	                cfg_max_rd_req_size        ;
wire	[2:0]	                cfg_max_payload_size       ;
wire			                cfg_rcb                    ;
wire			                cfg_ido_req_en             ;
wire			                cfg_ido_cpl_en             ;
wire	[7:0]	                xadm_ph_cdts               ;
wire	[11:0]	             xadm_pd_cdts               ;
wire	[7:0]	                xadm_nph_cdts              ;
wire	[11:0]	             xadm_npd_cdts              ;
wire	[7:0]	                xadm_cplh_cdts             ;
wire	[11:0]	             xadm_cpld_cdts             ;
wire	[4:0]	                smlh_ltssm_state           /*synthesis PAP_MARK_DEBUG="1"*/;
// Led lights up signal
reg	[22:0]	             ref_led_cnt                ;		
reg	[26:0]	             pclk_led_cnt               ;		
wire			                smlh_link_up               ; 	
wire			                rdlh_link_up               /*synthesis PAP_MARK_DEBUG="1"*/; 	
// Uart to APB 32bits
wire			                uart_p_sel                 ;			
wire	[3:0]	                uart_p_strb                ;		
wire	[15:0]	             uart_p_addr                ;		
wire	[31:0]	             uart_p_wdata               ;		
wire			                uart_p_ce                  ;			
wire			                uart_p_we                  ;			
wire			                uart_p_rdy                 ;			
wire	[31:0]	             uart_p_rdata               ;		
// APB signal
wire	[3:0]	                p_strb                     ; 			
wire	[15:0]	             p_addr                     ; 			
wire	[31:0]	             p_wdata                    ; 			
wire			                p_ce                       ; 				
wire			                p_we                       ; 				
// APB MUX signal
// 0~5: HSSTLP 6: Reserved 7: PCIe
// 8: config
// 9: DMA
wire			                p_sel_pcie                 ;			
wire			                p_sel_cfg                  ;			
wire			                p_sel_dma                  ;			
wire	[31:0]	             p_rdata_pcie               ;		
wire	[31:0]	             p_rdata_cfg                ;		
wire	[31:0]	             p_rdata_dma                ;		
wire			                p_rdy_pcie                 ;			
wire			                p_rdy_cfg                  ;			
wire			                p_rdy_dma                  ;		
wire                        axi_rst_n                  ;
wire                        rst_n                      ;

assign axi_rst_n        =   board_rst_n                ;
assign rst_n            =   board_rst_n                ;
assign cfg_ido_req_en	=	 1'b0                       ;	
assign cfg_ido_cpl_en	=	 1'b0                       ;	
assign xadm_ph_cdts		=	 8'b0                       ;	
assign xadm_pd_cdts		=	 12'b0                      ;	
assign xadm_nph_cdts  	=	 8'b0                       ;	
assign xadm_npd_cdts	   =	 12'b0                      ;	
assign xadm_cplh_cdts	=	 8'b0                       ;	
assign xadm_cpld_cdts	=	 12'b0                      ;	

wire                        ch0_wframe_data_valid      ;
wire  [15:0]                ch0_wframe_data            ;
reg                         ch0_rframe_req             ;
wire                        ch0_rframe_req_ack         ;
wire                        ch0_rframe_data_en         ;
wire  [127:0]               ch0_rframe_data            ;
wire                        ch0_rframe_data_valid      ;
wire                        ch1_wframe_data_valid      ;
wire  [15:0]                ch1_wframe_data            ;
reg                         ch1_rframe_req             ;
wire                        ch1_rframe_req_ack         ;
wire                        ch1_rframe_data_en         ;
wire  [127:0]               ch1_rframe_data            ;
wire                        ch1_rframe_data_valid      ;
wire                        ch2_wframe_data_valid      ;
wire  [15:0]                ch2_wframe_data            ;
reg                         ch2_rframe_req             ;
wire                        ch2_rframe_req_ack         ;
wire                        ch2_rframe_data_en         ;
wire  [127:0]               ch2_rframe_data            ;
wire                        ch2_rframe_data_valid      ;
wire                        ch3_wframe_data_valid      ;
wire  [15:0]                ch3_wframe_data            ;
reg                         ch3_rframe_req             ;
wire                        ch3_rframe_req_ack         ;
wire                        ch3_rframe_data_en         ;
wire  [127:0]               ch3_rframe_data            ;
wire                        ch3_rframe_data_valid      ;
// DMA CTRL                    BASE ADDR = 0x8000
wire                        o_dma_write_data_req       ;
wire  [11:0]                o_dma_write_addr           ;
wire  [127:0]               i_dma_write_data           ;
wire                        cmos2_pclk_bufg            ;
reg                         cmos2_vsync_d1             ;
reg                         cmos2_vsync_d2             ;
reg                         cmos2_href_d1              ;
reg                         cmos2_href_d2              ;
reg   [7:0]                 cmos2_data_d1              ;
reg   [7:0]                 cmos2_data_d2              ;
wire                        line_full_flag_1           ;
wire                        line_full_flag_2           ;
wire                        line_full_flag_3           ;
wire                        line_full_flag_4           ;
//PLL
wire                        core_clk                   ;
wire                        clk_10m                    ;
wire                        clk_25m                    ;
wire                        clk_50m                    ;
wire                        clk_100m                   ;
always @(posedge cmos2_pclk)begin
    cmos2_vsync_d1 <= cmos2_vsync;
    cmos2_vsync_d2 <= cmos2_vsync_d1;
    cmos2_href_d1  <= cmos2_href;
    cmos2_href_d2  <= cmos2_href_d1;
    cmos2_data_d1  <= cmos2_data;
    cmos2_data_d2  <= cmos2_data_d1;
end

pll pll_inst (
    .clkout0(clk_10m),   
    .clkout1(clk_25m),   
    .clkout2(clk_50m),   
    .clkout3(clk_100m),   
    .lock(lock),          
    .clkin1(free_clk)       
);

//OV5640 register configure enable    
power_on_delay	power_on_delay_inst(
    .clk_50M                 (clk_50m        ),//input
    .reset_n                 (ddr_init_done  ),//input	
    .camera1_rstn            (               ),//output
    .camera2_rstn            (cmos2_reset    ),//output	
    .camera_pwnd             (               ),//output
    .initial_en              (initial_en     ) //output		
);
//CMOS2 Camera 
reg_config	coms2_reg_config(
    .clk_25M                 (clk_50m            ),//input
    .camera_rstn             (cmos2_reset        ),//input
    .initial_en              (initial_en         ),//input		
    .i2c_sclk                (cmos2_scl          ),//output
    .i2c_sdat                (cmos2_sda          ),//inout
    .reg_conf_done           (cmos_init_done[1]  ),//output config_finished
    .reg_index               (                   ),//output reg [8:0]
    .clock_20k               (                   ) //output reg
);
always@(posedge cmos2_pclk)
    begin
        cmos2_d_d0        <= cmos2_data_d2    ;
        cmos2_href_d0     <= cmos2_href_d2    ;
        cmos2_vsync_d0    <= cmos2_vsync_d2   ;
    end

cmos_8_16bit cmos2_8_16bit(
.pclk           (cmos2_pclk       ),//input
.rst_n          (cmos_init_done[1]),//input
.pdata_i        (cmos2_d_d0       ),//input[7:0]
.de_i           (cmos2_href_d0    ),//input
.vs_i           (cmos2_vsync_d0    ),//input

.pixel_clk      (cmos2_pclk_16bit ),//output
.pdata_o        (cmos2_d_16bit    ),//output[15:0]
.de_o           (cmos2_href_16bit ) //output
);

assign     pclk_in_test_2  =    cmos2_pclk_16bit    ;
assign     vs_in_test_2    =    cmos2_vsync_d0      ;
assign     de_in_test_2    =    cmos2_href_16bit    ;
assign     i_rgb565_2      =    {cmos2_d_16bit[4:0],cmos2_d_16bit[10:5],cmos2_d_16bit[15:11]};//{r,g,b}

always@(posedge core_clk or negedge ddr_init_done)
begin
   if (!ddr_init_done)
      cnt <= 27'd0;
   else if ( cnt >= TH_1S )
      cnt <= 27'd0;
   else
      cnt <= cnt + 27'd1;
end
always @(posedge core_clk or negedge ddr_init_done)
begin
   if (!ddr_init_done)
      heart_beat_led <= 1'd1;
   else if ( cnt >= TH_1S )
      heart_beat_led <= ~heart_beat_led;
end
system_top #(
    .MEM_ROW_WIDTH     (MEM_ROW_WIDTH     ),
    .MEM_COLUMN_WIDTH  (MEM_COLUMN_WIDTH  ),
    .MEM_BANK_WIDTH    (MEM_BANK_WIDTH    ),
    .MEM_DQ_WIDTH      (MEM_DQ_WIDTH      ),
    .MEM_DQS_WIDTH     (MEM_DQS_WIDTH     ),
    .USER_S_ID_WIDTH   (USER_S_ID_WIDTH   ),
    .USER_M_ID_WIDTH   (USER_M_ID_WIDTH   ),
    .USER_ADDR_WIDTH   (USER_ADDR_WIDTH   ),
    .USER_DATA_WIDTH   (USER_DATA_WIDTH   ),
    .USER_STRB_WIDTH   (USER_STRB_WIDTH   ),
    .USER_WUSER_WIDTH  (USER_WUSER_WIDTH  ),
    .USER_BUSER_WIDTH  (USER_BUSER_WIDTH  ),
    .USER_ARUSER_WIDTH (USER_ARUSER_WIDTH ),
    .USER_RUSER_WIDTH  (USER_RUSER_WIDTH  ),
    .USER_AWUSER_WIDTH (USER_AWUSER_WIDTH )
) u_system_top (
    .axi_rst_n            ( axi_rst_n           ),
    .ref_clk              ( free_clk            ), 
    .clk                  ( clk_100m            ),     
    .rst_n                ( rst_n               ),
    .core_clk             ( core_clk            ),
    .ddr_init_done        ( ddr_init_done       ),
    .mem_cs_n             ( mem_cs_n            ),
    .mem_rst_n            ( mem_rst_n           ),
    .mem_ck               ( mem_ck              ),
    .mem_ck_n             ( mem_ck_n            ),
    .mem_cke              ( mem_cke             ),
    .mem_ras_n            ( mem_ras_n           ),
    .mem_cas_n            ( mem_cas_n           ),
    .mem_we_n             ( mem_we_n            ),
    .mem_odt              ( mem_odt             ),
    .mem_a                ( mem_a               ),
    .mem_ba               ( mem_ba              ),
    .mem_dqs              ( mem_dqs             ),
    .mem_dqs_n            ( mem_dqs_n           ),
    .mem_dq               ( mem_dq              ),
    .mem_dm               ( mem_dm              ),
    .slave_M_AXI_AWID     ( axi_awuser_id       ),
    .slave_M_AXI_AWADDR   ( axi_awaddr          ),
    .slave_M_AXI_AWLEN    ( axi_awlen           ),
    .slave_M_AXI_AWSIZE   (                     ),
    .slave_M_AXI_AWBURST  (                     ),
    .slave_M_AXI_AWLOCK   (                     ),
    .slave_M_AXI_AWCACHE  (                     ),
    .slave_M_AXI_AWPROT   (                     ),
    .slave_M_AXI_AWQOS    (                     ),
    .slave_M_AXI_AWUSER   ( axi_awuser_ap       ),
    .slave_M_AXI_AWVALID  ( axi_awvalid         ),
    .slave_M_AXI_AWREADY  ( axi_awready         ),
    .slave_M_AXI_WDATA    ( axi_wdata           ),
    .slave_M_AXI_WSTRB    ( axi_wstrb           ),
    .slave_M_AXI_WLAST    ( axi_wusero_last     ),
    .slave_M_AXI_WUSER    (                     ),
    .slave_M_AXI_WVALID   (                     ),
    .slave_M_AXI_WREADY   ( axi_wready          ),
    .slave_M_AXI_BID      (                     ),
    .slave_M_AXI_BRESP    (                     ),
    .slave_M_AXI_BUSER    (                     ),
    .slave_M_AXI_BVALID   (                     ),
    .slave_M_AXI_BREADY   (                     ),
    .slave_M_AXI_ARID     ( axi_aruser_id       ),
    .slave_M_AXI_ARADDR   ( axi_araddr          ),
    .slave_M_AXI_ARLEN    ( axi_arlen           ),
    .slave_M_AXI_ARSIZE   (                     ),
    .slave_M_AXI_ARBURST  (                     ),
    .slave_M_AXI_ARLOCK   (                     ),
    .slave_M_AXI_ARCACHE  (                     ),
    .slave_M_AXI_ARPROT   (                     ),
    .slave_M_AXI_ARQOS    (                     ),
    .slave_M_AXI_ARUSER   ( axi_aruser_ap       ),
    .slave_M_AXI_ARVALID  ( axi_arvalid         ),
    .slave_M_AXI_ARREADY  ( axi_arready         ),
    .slave_M_AXI_RID      ( axi_rid             ),
    .slave_M_AXI_RDATA    ( axi_rdata           ),
    .slave_M_AXI_RRESP    (                     ),
    .slave_M_AXI_RLAST    ( axi_rlast           ),
    .slave_M_AXI_RUSER    (                     ),
    .slave_M_AXI_RVALID   ( axi_rvalid          ),
    .slave_M_AXI_RREADY   (                     )
);

wire        ch0_image_valid_out;
wire [15:0] ch0_image_data_out;
wire        ch1_image_valid_out;
wire [15:0] ch1_image_data_out;

localparam REMAP_CH0 = 1'b1;
localparam REMAP_CH1 = 1'b1;
assign ch0_wframe_data_valid = (REMAP_CH0) ? ch2_wframe_data_valid : ch0_image_valid_out;
assign ch0_wframe_data       = (REMAP_CH0) ? ch2_wframe_data       : ch0_image_data_out;
assign ch1_wframe_data_valid = (REMAP_CH1) ? ch3_wframe_data_valid : ch1_image_valid_out;
assign ch1_wframe_data       = (REMAP_CH1) ? ch3_wframe_data       : ch1_image_data_out;

assign vs_in_test=vs_in_test_2;
assign de_in_test=de_in_test_2;
assign pclk_in_test=pclk_in_test_2;
assign i_rgb565=i_rgb565_2;

image_reshape ch0_image_reshape(
    .clk                    (pclk_in_test               ),  
    .rst_n                  (lock   && ddr_init_done    ),

    .img_vs                 (vs_in_test                 ),
    .img_data_valid         (de_in_test                 ),     
    .img_data               (i_rgb565                   ),  
   
    .img_data_valid_out     (ch0_wframe_data_valid      ),
    .img_data_out           (ch0_wframe_data            )
);

image_reshape ch1_image_reshape(
    .clk                    (pclk_in_test               ),  
    .rst_n                  (lock   && ddr_init_done    ),

    .img_vs                 (vs_in_test                 ),
    .img_data_valid         (de_in_test                 ),     
    .img_data               (i_rgb565                   ),  
   
    .img_data_valid_out     (ch1_wframe_data_valid      ),
    .img_data_out           (ch1_wframe_data            )
);

image_reshape ch2_image_reshape(
    .clk                    (pclk_in_test_2             ),  
    .rst_n                  (lock && ddr_init_done      ),

    .img_vs                 (vs_in_test_2               ),
    .img_data_valid         (de_in_test_2               ),     
    .img_data               (i_rgb565_2                 ),  
   
    .img_data_valid_out     (ch2_wframe_data_valid      ),
    .img_data_out           (ch2_wframe_data            )
);

image_reshape ch3_image_reshape(
    .clk                    (pclk_in_test_2             ),  
    .rst_n                  (lock && ddr_init_done      ),

    .img_vs                 (vs_in_test_2               ),
    .img_data_valid         (de_in_test_2               ),     
    .img_data               (i_rgb565_2                 ),  
   
    .img_data_valid_out     (ch3_wframe_data_valid      ),
    .img_data_out           (ch3_wframe_data            )
);


pcie_img_select pcie_img_select_inst(
    .clk                         (pclk_div2                                 ),
    .rst_n                       (core_rst_n                                ),
    

    .dma_sim_vs                  (ch0_rframe_req                            ),
    .line_full_flag              (line_full_flag_1 && line_full_flag_2 && line_full_flag_3 && line_full_flag_4 ),                   

    .ch0_data_req                (ch0_rframe_data_en                        ),
    .ch0_data                    (ch0_rframe_data                           ),
    .ch1_data_req                (ch1_rframe_data_en                        ),
    .ch1_data                    (ch1_rframe_data                           ),
    .ch2_data_req                (ch2_rframe_data_en                        ),
    .ch2_data                    (ch2_rframe_data                           ),
    .ch3_data_req                (ch3_rframe_data_en                        ),
    .ch3_data                    (ch3_rframe_data                           ),

    .dma_wr_data_req             (o_dma_write_data_req                      ),
    .dma_wr_data                 (i_dma_write_data                          ) 
);

axi_ctrl_outside axi_ctrl_inst
(
	  .ARESETN                     (ddr_init_done         ),
	  .ACLK                        (core_clk              ),
	  .M_AXI_AWID                  (axi_awuser_id         ),
	  .M_AXI_AWADDR                (axi_awaddr            ),
	  .M_AXI_AWLEN                 (axi_awlen             ),
	  .M_AXI_AWSIZE                (                      ),
	  .M_AXI_AWBURST               (                      ),
	  .M_AXI_AWLOCK                (                      ),
	  .M_AXI_AWCACHE               (                      ),
	  .M_AXI_AWPROT                (                      ),
	  .M_AXI_AWQOS                 (                      ),
	  .M_AXI_AWUSER                (                      ),
	  .M_AXI_AWVALID               (axi_awvalid           ),
	  .M_AXI_AWREADY               (axi_awready           ),
	  .M_AXI_WDATA                 (axi_wdata             ),
	  .M_AXI_WSTRB                 (axi_wstrb             ),
	  .M_AXI_WLAST                 (                      ),
	  .M_AXI_WUSER                 (                      ),
	  .M_AXI_WVALID                (                      ),
	  .M_AXI_WREADY                (axi_wready            ),
	  .M_AXI_BID                   (0                     ),
	  .M_AXI_BRESP                 (0                     ),
	  .M_AXI_BUSER                 (0                     ),
      .M_AXI_BVALID                (1'b1                  ),

	  .M_AXI_BREADY                (                      ),
	  .M_AXI_ARID                  (axi_aruser_id         ),
	  .M_AXI_ARADDR                (axi_araddr            ),
	  .M_AXI_ARLEN                 (axi_arlen             ),
	  .M_AXI_ARSIZE                (                      ),
	  .M_AXI_ARBURST               (                      ),
	  .M_AXI_ARLOCK                (                      ),
	  .M_AXI_ARCACHE               (                      ),
	  .M_AXI_ARPROT                (                      ),
	  .M_AXI_ARQOS                 (                      ),
	  .M_AXI_ARUSER                (                      ),
	  .M_AXI_ARVALID               (axi_arvalid           ),
	  .M_AXI_ARREADY               (axi_arready           ),
	  .M_AXI_RID                   (axi_rid               ),
	  .M_AXI_RDATA                 (axi_rdata             ),
	  .M_AXI_RRESP                 (0                     ),
	  .M_AXI_RLAST                 (axi_rlast             ),
	  .M_AXI_RUSER                 (0                     ),
	  .M_AXI_RVALID                (axi_rvalid            ),
	  .M_AXI_RREADY                (                      ),  
     .key                         ({1'b1,3'b111,4'b0000} ),

     .ch0_wframe_pclk             (pclk_in_test          ),
     .ch0_wframe_rst_n            (lock && ddr_init_done ),
     .ch0_wframe_vsync            (vs_in_test            ),
     .ch0_wframe_data_valid       (ch0_wframe_data_valid ),         
     .ch0_wframe_data             (ch0_wframe_data       ),
     .ch0_rframe_pclk             (pclk_div2             ),   
     .ch0_rframe_rst_n            (ddr_init_done         ), 
     .ch0_rframe_vsync            (ch0_rframe_req        ),
     .ch0_rframe_req              (ch0_rframe_req        ),
     .ch0_rframe_req_ack          (ch0_rframe_req_ack    ),
     .ch0_rframe_data_en          (ch0_rframe_data_en    ),
     .ch0_rframe_data             (ch0_rframe_data       ),      
     .ch0_rframe_data_valid       (                      ),
     .ch0_read_line_full          (line_full_flag_1      ),

     .ch1_wframe_pclk             (pclk_in_test          ),
     .ch1_wframe_rst_n            (lock && ddr_init_done ),
     .ch1_wframe_vsync            (vs_in_test            ),
     .ch1_wframe_data_valid       (ch1_wframe_data_valid ),          
     .ch1_wframe_data             (ch1_wframe_data       ),      
     .ch1_rframe_pclk             (pclk_div2             ),   
     .ch1_rframe_rst_n            (ddr_init_done         ), 
     .ch1_rframe_vsync            (ch0_rframe_req        ),
     .ch1_rframe_req              (ch0_rframe_req        ),
     .ch1_rframe_req_ack          (                      ),
     .ch1_rframe_data_en          (ch1_rframe_data_en    ),
     .ch1_rframe_data             (ch1_rframe_data       ),      
     .ch1_rframe_data_valid       (                      ),
     .ch1_read_line_full          (line_full_flag_2      ),

     .ch2_wframe_pclk             (pclk_in_test_2        ),
     .ch2_wframe_rst_n            (lock && ddr_init_done ),
     .ch2_wframe_vsync            (vs_in_test_2          ),
     .ch2_wframe_data_valid       (ch2_wframe_data_valid ),
     .ch2_wframe_data             (ch2_wframe_data       ),
     .ch2_rframe_pclk             (pclk_div2             ),   
     .ch2_rframe_rst_n            (ddr_init_done         ), 
     .ch2_rframe_vsync            (ch0_rframe_req        ),
     .ch2_rframe_req              (ch0_rframe_req        ),
     .ch2_rframe_req_ack          (                      ),
     .ch2_rframe_data_en          (ch2_rframe_data_en    ),
     .ch2_rframe_data             (ch2_rframe_data       ),      
     .ch2_rframe_data_valid       (                      ),
     .ch2_read_line_full          (line_full_flag_3      ),

     .ch3_wframe_pclk             (pclk_in_test_2        ),  
     .ch3_wframe_rst_n            (lock && ddr_init_done ),
     .ch3_wframe_vsync            (vs_in_test_2          ),
     .ch3_wframe_data_valid       (ch3_wframe_data_valid ),
     .ch3_wframe_data             (ch3_wframe_data       ),
     .ch3_rframe_pclk             (pclk_div2             ),   
     .ch3_rframe_rst_n            (ddr_init_done         ), 
     .ch3_rframe_vsync            (ch0_rframe_req        ),
     .ch3_rframe_req              (ch0_rframe_req        ),
     .ch3_rframe_req_ack          (                      ),
     .ch3_rframe_data_en          (ch3_rframe_data_en    ),
     .ch3_rframe_data             (ch3_rframe_data       ),      
     .ch3_rframe_data_valid       (                      ),
     .ch3_read_line_full          (line_full_flag_4      )
)/*synthesis syn_black_box */;

hsst_rst_cross_sync_v1_0 #(
    `ifdef IPS2L_PCIE_SPEEDUP_SIM
    .RST_CNTR_VALUE     (16'h10             )
    `else
    .RST_CNTR_VALUE     (16'hC000           )
    `endif
)
u_refclk_buttonrstn_debounce(
    .clk                (ref_clk            ),
    .rstn_in            (board_rst_n        ),
    .rstn_out           (sync_button_rst_n  )
);

hsst_rst_cross_sync_v1_0 #(
    `ifdef IPS2L_PCIE_SPEEDUP_SIM
    .RST_CNTR_VALUE     (16'h10             )
    `else
    .RST_CNTR_VALUE     (16'hC000           )
    `endif
)
u_refclk_perstn_debounce(
    .clk                (ref_clk            ),
    .rstn_in            (perst_n            ),
    .rstn_out           (sync_perst_n       )
);

hsst_rst_sync_v1_0  u_ref_core_rstn_sync    (
    .clk                (ref_clk            ),
    .rst_n              (core_rst_n         ),
    .sig_async          (1'b1               ),
    .sig_synced         (ref_core_rst_n     )
);

hsst_rst_sync_v1_0  u_pclk_core_rstn_sync   (
    .clk                (pclk               ),
    .rst_n              (core_rst_n         ),
    .sig_async          (1'b1               ),
    .sig_synced         (s_pclk_rstn        )
);

always @(posedge ref_clk or negedge sync_perst_n) begin
	if (!sync_perst_n) begin
		ref_led_cnt <= 23'd0;
		ref_led <= 1'b1;
	end else if (smlh_link_up & rdlh_link_up) begin
		ref_led_cnt <= ref_led_cnt + 23'd1;
		if(&ref_led_cnt)
			ref_led <= ~ref_led;
	end
end

always @(posedge pclk or negedge s_pclk_rstn) begin
	if (!s_pclk_rstn) begin
		pclk_led_cnt <= 27'd0;
		pclk_led <= 1'b1;
	end else if (smlh_link_up & rdlh_link_up) begin
		pclk_led_cnt <= pclk_led_cnt + 27'd1;
		if(&pclk_led_cnt)
			pclk_led <= ~pclk_led;
	end
end

ips2l_pcie_dma #(
	.DEVICE_TYPE			(DEVICE_TYPE),
	.AXIS_SLAVE_NUM			(AXIS_SLAVE_NUM)
) u_ips2l_pcie_dma (
	.clk					(pclk_div2),				
	.rst_n					(core_rst_n),				

	// Num
	.i_cfg_pbus_num			(cfg_pbus_num),				
	.i_cfg_pbus_dev_num		(cfg_pbus_dev_num),			
	.i_cfg_max_rd_req_size	(cfg_max_rd_req_size),		
	.i_cfg_max_payload_size	(cfg_max_payload_size),		

	// AXI4-Stream master interface
	.i_axis_master_tvld		(axis_master_tvalid_mem),	
	.o_axis_master_trdy		(axis_master_tready_mem),	
	.i_axis_master_tdata	(axis_master_tdata_mem),	
	.i_axis_master_tkeep	(axis_master_tkeep_mem),	
														
	.i_axis_master_tlast	(axis_master_tlast_mem),	
	.i_axis_master_tuser	(axis_master_tuser_mem),	

	// AXI4-Stream slave0 interface
	.i_axis_slave0_trdy		(axis_slave0_tready),		
	.o_axis_slave0_tvld		(dma_axis_slave0_tvalid),	
	.o_axis_slave0_tdata	(dma_axis_slave0_tdata),	
	.o_axis_slave0_tlast	(dma_axis_slave0_tlast),	
	.o_axis_slave0_tuser	(dma_axis_slave0_tuser),	

	// AXI4-Stream slave1 interface
	.i_axis_slave1_trdy		(axis_slave1_tready),		
	.o_axis_slave1_tvld		(axis_slave1_tvalid),		
	.o_axis_slave1_tdata	(axis_slave1_tdata),		
	.o_axis_slave1_tlast	(axis_slave1_tlast),		
	.o_axis_slave1_tuser	(axis_slave1_tuser),		

	// AXI4-Stream slave2 interface
	.i_axis_slave2_trdy		(axis_slave2_tready),		
	.o_axis_slave2_tvld		(axis_slave2_tvalid),		
	.o_axis_slave2_tdata	(axis_slave2_tdata),		
	.o_axis_slave2_tlast	(axis_slave2_tlast),		
	.o_axis_slave2_tuser	(axis_slave2_tuser),		

	// From pcie
	.i_cfg_ido_req_en		(cfg_ido_req_en),			
	.i_cfg_ido_cpl_en		(cfg_ido_cpl_en),			
	.i_xadm_ph_cdts			(xadm_ph_cdts),				
	.i_xadm_pd_cdts			(xadm_pd_cdts),				
	.i_xadm_nph_cdts		(xadm_nph_cdts),			
	.i_xadm_npd_cdts		(xadm_npd_cdts),			
	.i_xadm_cplh_cdts		(xadm_cplh_cdts),			
	.i_xadm_cpld_cdts		(xadm_cpld_cdts),			

	// APB interface
	.i_apb_psel				(p_sel_dma),				
	.i_apb_paddr			(p_addr[8:0]),				
	.i_apb_pwdata			(p_wdata),					
	.i_apb_pstrb			(p_strb),					
	.i_apb_pwrite			(p_we),						
	.i_apb_penable			(p_ce),						
	.o_apb_prdy				(p_rdy_dma),				
	.o_apb_prdata			(p_rdata_dma),				
	.o_cross_4kb_boundary	(cross_4kb_boundary),		//4k边界
    //**********************************************************************
    // dma write interface
    .o_dma_write_data_req   (o_dma_write_data_req  ),
    .o_dma_write_addr       (o_dma_write_addr      ),
    .i_dma_write_data       (i_dma_write_data      )
);



assign p_rdy_cfg               = 1'b0;
assign p_rdata_cfg             = 32'b0;

assign axis_slave0_tvalid      = dma_axis_slave0_tvalid;
assign axis_slave0_tlast       = dma_axis_slave0_tlast;
assign axis_slave0_tuser       = dma_axis_slave0_tuser;
assign axis_slave0_tdata       = dma_axis_slave0_tdata;

assign axis_master_tvalid_mem  = axis_master_tvalid;
assign axis_master_tdata_mem   = axis_master_tdata;
assign axis_master_tkeep_mem   = axis_master_tkeep;
assign axis_master_tlast_mem   = axis_master_tlast;
assign axis_master_tuser_mem   = axis_master_tuser;

assign axis_master_tready      = axis_master_tready_mem;

// PCIe IP TOP : HSSTLP : 0x0000~6000 PCIe BASE ADDR : 0x7000
pcie_test u_ips2l_pcie_wrap (
	.button_rst_n				(1'b1),	
	.power_up_rst_n				(1'b1),			
	.perst_n					(1'b1),			

	// The clock and reset signals
	.pclk						(pclk),					
	.pclk_div2					(pclk_div2),			
	.ref_clk					(ref_clk),				
	.ref_clk_n					(ref_clk_n),			
	.ref_clk_p					(ref_clk_p),			
	.core_rst_n					(core_rst_n),			

	// APB interface to DBI config
	.p_sel						(p_sel_pcie),			
	.p_strb						(uart_p_strb),			
	.p_addr						(uart_p_addr),			
	.p_wdata					(uart_p_wdata),			
	.p_ce						(uart_p_ce),			
	.p_we						(uart_p_we),			
	.p_rdy						(p_rdy_pcie),			
	.p_rdata					(p_rdata_pcie),			

	// PHY diff signals
	.rxn						(rxn),					
	.rxp						(rxp),					
	.txn						(txn),					
	.txp						(txp),					
	.pcs_nearend_loop			({4{1'b0}}),			
	.pma_nearend_ploop			({4{1'b0}}),			
	.pma_nearend_sloop			({4{1'b0}}),			

	// AXI4-Stream master interface
	.axis_master_tvalid			(axis_master_tvalid),	
	.axis_master_tready			(axis_master_tready),	
	.axis_master_tdata			(axis_master_tdata),	
	.axis_master_tkeep			(axis_master_tkeep),	
														
	.axis_master_tlast			(axis_master_tlast),	
	.axis_master_tuser			(axis_master_tuser),	

	// AXI4-Stream slave 0 interface
	.axis_slave0_tready			(axis_slave0_tready),	
	.axis_slave0_tvalid			(axis_slave0_tvalid),	
	.axis_slave0_tdata			(axis_slave0_tdata),	
	.axis_slave0_tlast			(axis_slave0_tlast),	
	.axis_slave0_tuser			(axis_slave0_tuser),	

	// AXI4-Stream slave 1 interface
	.axis_slave1_tready			(axis_slave1_tready),	
	.axis_slave1_tvalid			(axis_slave1_tvalid),	
	.axis_slave1_tdata			(axis_slave1_tdata),	
	.axis_slave1_tlast			(axis_slave1_tlast),	
	.axis_slave1_tuser			(axis_slave1_tuser),	

	// AXI4-Stream slave 2 interface
	.axis_slave2_tready			(axis_slave2_tready),	
	.axis_slave2_tvalid			(axis_slave2_tvalid),	
	.axis_slave2_tdata			(axis_slave2_tdata),	
	.axis_slave2_tlast			(axis_slave2_tlast),	
	.axis_slave2_tuser			(axis_slave2_tuser),	

	.pm_xtlh_block_tlp			(),						

	.cfg_send_cor_err_mux		(),						
	.cfg_send_nf_err_mux		(),						
	.cfg_send_f_err_mux			(),						
	.cfg_sys_err_rc				(),						
	.cfg_aer_rc_err_mux			(),						

	// The radm timeout
	.radm_cpl_timeout			(),						

	// Configuration signals
	.cfg_max_rd_req_size		(cfg_max_rd_req_size),	
	.cfg_bus_master_en			(),						
	.cfg_max_payload_size		(cfg_max_payload_size),	
	.cfg_ext_tag_en				(),						
	.cfg_rcb					(cfg_rcb),				
	.cfg_mem_space_en			(),						
	.cfg_pm_no_soft_rst			(),						
	.cfg_crs_sw_vis_en			(),						
	.cfg_no_snoop_en			(),						
	.cfg_relax_order_en			(),						
	.cfg_tph_req_en				(),						
	.cfg_pf_tph_st_mode			(),						
	.rbar_ctrl_update			(),						
	.cfg_atomic_req_en			(),						

	.cfg_pbus_num				(cfg_pbus_num),			
	.cfg_pbus_dev_num			(cfg_pbus_dev_num),		

	// Debug signals
	.radm_idle					(),						
	.radm_q_not_empty			(),						
	.radm_qoverflow				(),						
	.diag_ctrl_bus				(2'b0),					
	.cfg_link_auto_bw_mux		(),						
	.cfg_bw_mgt_mux				(),						
	.cfg_pme_mux				(),						
	.app_ras_des_sd_hold_ltssm	(1'b0),					
	.app_ras_des_tba_ctrl		(2'b0),					

	.dyn_debug_info_sel			(4'b0),					
	.debug_info_mux				(),

	// System signal
	.smlh_link_up				(smlh_link_up),			//link状态
	.rdlh_link_up				(rdlh_link_up),			//link状态
	.smlh_ltssm_state			(smlh_ltssm_state)
);



//=======================
reg  [11:0]  o_dma_write_addr_dly1;
reg  [11:0]  o_dma_write_addr_dly2;
reg  [11:0]  dma_write_cnt; 

always @(posedge pclk_div2) begin
    if (!core_rst_n) begin
        o_dma_write_addr_dly1 <= 12'd0;
        o_dma_write_addr_dly2 <= 12'd0;
    end else begin
        o_dma_write_addr_dly1 <= o_dma_write_addr;
        o_dma_write_addr_dly2 <= o_dma_write_addr_dly1;
    end
end


always @(posedge pclk_div2) begin
    if (!core_rst_n) begin
        dma_write_cnt <= 12'd0;
    end else if (o_dma_write_addr_dly1 == 12'ha0 && o_dma_write_addr_dly2 == 12'h9f) begin
        dma_write_cnt <= dma_write_cnt + 1'b1;
    end
    else if (dma_write_cnt == 12'd720)begin
        dma_write_cnt <= 12'd0;
    end
    else begin
        dma_write_cnt <= dma_write_cnt;
    end
end

always @(posedge pclk_div2) begin
    if (!core_rst_n) begin
        ch0_rframe_req <=1'b0;
    end else if (dma_write_cnt == 12'd720) begin
       ch0_rframe_req <= 1'b1;
    end
    else if (ch0_rframe_req_ack) begin
        ch0_rframe_req <= 1'b0;
    end
    else begin
        ch0_rframe_req <= ch0_rframe_req;
    end
end
endmodule
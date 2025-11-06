module system_top#(
   parameter MEM_ROW_WIDTH        = 15         ,
   parameter MEM_COLUMN_WIDTH     = 10         ,
   parameter MEM_BANK_WIDTH       = 3          ,
   parameter MEM_DQ_WIDTH         = 32         ,
   parameter MEM_DQS_WIDTH        = 2          ,
   parameter USER_S_ID_WIDTH      = 10         , 
   parameter USER_M_ID_WIDTH      = 11         ,
   parameter USER_ADDR_WIDTH      = 64         ,
   parameter USER_DATA_WIDTH      = 256        ,
   parameter USER_STRB_WIDTH      = 32         ,
   parameter USER_WUSER_WIDTH     = 1          ,
   parameter USER_BUSER_WIDTH     = 1          ,
   parameter USER_ARUSER_WIDTH    = 1          ,
   parameter USER_RUSER_WIDTH     = 1          ,
   parameter USER_AWUSER_WIDTH    = 1          
)(
    input wire                               axi_rst_n                 ,
    input wire                               ref_clk                   ,
    input wire                               clk                       ,
    input wire                               rst_n                     ,

    //DDR3 interface
    output wire                               mem_cs_n                  ,  
    output wire                               mem_rst_n                 ,
    output wire                               mem_ck                    ,
    output wire                               mem_ck_n                  ,
    output wire                               mem_cke                   ,
    output wire                               mem_ras_n                 ,
    output wire                               mem_cas_n                 ,
    output wire                               mem_we_n                  ,
    output wire                               mem_odt                   ,
    output wire      [MEM_ROW_WIDTH-1:0]      mem_a                     ,
    output wire      [MEM_BANK_WIDTH-1:0]     mem_ba                    ,
    inout  wire      [MEM_DQ_WIDTH/8-1:0]     mem_dqs                   ,
    inout  wire      [MEM_DQ_WIDTH/8-1:0]     mem_dqs_n                 ,
    inout  wire      [MEM_DQ_WIDTH-1:0]       mem_dq                    ,
    output wire      [MEM_DQ_WIDTH/8-1:0]     mem_dm                    ,
    
    input  wire [USER_S_ID_WIDTH-1:0]    slave_M_AXI_AWID,
    input  wire [USER_ADDR_WIDTH-1:0]    slave_M_AXI_AWADDR,
    input  wire [8-1:0]                  slave_M_AXI_AWLEN,
    input  wire [3-1:0]                  slave_M_AXI_AWSIZE,
    input  wire [2-1:0]                  slave_M_AXI_AWBURST,
    input  wire                          slave_M_AXI_AWLOCK,
    input  wire [4-1:0]                  slave_M_AXI_AWCACHE,
    input  wire [3-1:0]                  slave_M_AXI_AWPROT,
    input  wire [4-1:0]                  slave_M_AXI_AWQOS,
    input  wire [USER_AWUSER_WIDTH-1:0]  slave_M_AXI_AWUSER,
    input  wire                          slave_M_AXI_AWVALID,
    output wire                          slave_M_AXI_AWREADY,
    input  wire [USER_DATA_WIDTH-1:0]    slave_M_AXI_WDATA,
    input  wire [USER_STRB_WIDTH-1:0]    slave_M_AXI_WSTRB,
    input  wire                          slave_M_AXI_WLAST,
    input  wire [USER_WUSER_WIDTH-1:0]   slave_M_AXI_WUSER,
    input  wire                          slave_M_AXI_WVALID,
    output wire                          slave_M_AXI_WREADY,
    output wire [USER_S_ID_WIDTH-1:0]    slave_M_AXI_BID,
    output wire [2-1:0]                  slave_M_AXI_BRESP,
    output wire [USER_BUSER_WIDTH-1:0]   slave_M_AXI_BUSER,
    output wire                          slave_M_AXI_BVALID,
    input  wire                          slave_M_AXI_BREADY,
    input  wire [USER_S_ID_WIDTH-1:0]    slave_M_AXI_ARID,
    input  wire [USER_ADDR_WIDTH-1:0]    slave_M_AXI_ARADDR,
    input  wire [8-1:0]                  slave_M_AXI_ARLEN,
    input  wire [3-1:0]                  slave_M_AXI_ARSIZE,
    input  wire [2-1:0]                  slave_M_AXI_ARBURST,
    input  wire                          slave_M_AXI_ARLOCK,
    input  wire [4-1:0]                  slave_M_AXI_ARCACHE,
    input  wire [3-1:0]                  slave_M_AXI_ARPROT,
    input  wire [4-1:0]                  slave_M_AXI_ARQOS,
    input  wire [USER_ARUSER_WIDTH-1:0]  slave_M_AXI_ARUSER,
    input  wire                          slave_M_AXI_ARVALID,
    output wire                          slave_M_AXI_ARREADY,
    output wire [USER_S_ID_WIDTH-1:0]    slave_M_AXI_RID,
    output wire [USER_DATA_WIDTH-1:0]    slave_M_AXI_RDATA,
    output wire [2-1:0]                  slave_M_AXI_RRESP,
    output wire                          slave_M_AXI_RLAST,
    output wire [USER_RUSER_WIDTH-1:0]   slave_M_AXI_RUSER,
    output wire                          slave_M_AXI_RVALID,
    input  wire                          slave_M_AXI_RREADY,
    output wire                          core_clk,
    output wire                          ddr_init_done
);

parameter PERI_ADDR_WIDTH       = 33;
parameter PERI_BUSRSTS_WIDTH    = 8;
parameter PERI_DATA_WIDTH       = 256;
parameter AXI_S_AXI_BURSTLENGTH = 32;
parameter AXI_M_AXI_BURSTLENGTH = 32;
parameter ASYN_RADDR_FIFO_DEPTH = 64;
parameter AXI_OUTSTANDING_DEPTH = 128;
parameter AXI_M_AXI_ID_WIDTH    = 10;
parameter AXI_M_AXI_ADDR_WIDTH  = 64;
parameter AXI_M_AXI_USER_WIDTH  = 1;
parameter AXI_M_AXI_DATA_WIDTH  = 128;//
parameter AXI_S_AXI_ID_WIDTH    = 10;
parameter AXI_S_AXI_ADDR_WIDTH  = 64;
parameter AXI_S_AXI_USER_WIDTH  = 1;
parameter AXI_S_AXI_DATA_WIDTH  = 128;//
parameter LOAD_INSNBITS         = 128;
parameter STORE_INSNBITS        = 128;
parameter PEA_INSNBITS          = 128;
parameter VCU_INSNBITS          = 128;
localparam integer AXI_M_AXI_DATA_BYTES = AXI_M_AXI_DATA_WIDTH / 8;
localparam integer AXI_S_AXI_DATA_BYTES = AXI_S_AXI_DATA_WIDTH / 8;

parameter ddr_ID_WIDTH = 8;
localparam integer CMD_BITS = AXI_M_AXI_ADDR_WIDTH + 8 + 1 + AXI_M_AXI_DATA_WIDTH;

parameter CTRL_ADDR_WIDTH = MEM_ROW_WIDTH + MEM_BANK_WIDTH + MEM_COLUMN_WIDTH;
parameter TH_1S = 27'd33000000;
parameter REM_DQS_WIDTH = 9 - MEM_DQS_WIDTH;

reg  [CMD_BITS-1:0] cmd;
reg         cmd_vld;
wire [31:0] cmd_rd_data;

wire [CTRL_ADDR_WIDTH-1:0]  axi_awaddr                 ;
wire [3:0]                  axi_awlen                  ;
wire                        axi_awready                ;
wire                        axi_awvalid                ;
wire [MEM_DQ_WIDTH*8-1:0]   axi_wdata                  ;
wire [MEM_DQ_WIDTH*8/8-1:0] axi_wstrb                  ;
wire                        axi_wready                 ;
wire [CTRL_ADDR_WIDTH-1:0]  axi_araddr                 ;
wire [3:0]                  axi_arlen                  ;
wire                        axi_arready                ;
wire                        axi_arvalid                ;
wire [MEM_DQ_WIDTH*8-1:0]   axi_rdata                  ;
wire                        axi_rvalid                 ;
wire [3:0]                  axi_rid                    ;
wire                        axi_rlast                  ;
wire [7:0]                  axi_awid                   ;       
wire [7:0]                  axi_awlen                  ;      
wire [2:0]                  axi_awsize                 ;     
wire [1:0]                  axi_awburst                ;    
wire                        axi_awready                ;
wire                        axi_awvalid                ;

wire [MEM_DQ_WIDTH*8-1:0]   axi_wdata                  ;
wire [MEM_DQ_WIDTH-1:0]     axi_wstrb                  ;
wire                        axi_wlast                  ;
wire                        axi_wvalid                 ;
wire                        axi_wready                 ;

wire                        axi_bready                 ;
wire [7:0]                  axi_bid                    ;
wire [1:0]                  axi_bresp                  ;
wire                        axi_bvalid                 ;

wire [7:0]                  axi_arid                   ;       
wire [7:0]                  axi_arlen                  ;
wire [2:0]                  axi_arsize                 ;
wire [1:0]                  axi_arburst                ;
wire                        axi_arvalid                ;
wire                        axi_arready                ;

wire [MEM_DQ_WIDTH*8-1:0]   axi_rdata                  ;
wire [7:0]                  axi_rid                    ;        
wire [1:0]                  axi_rresp                  ;
wire                        axi_rlast                  ;
wire                        axi_rvalid                 ;
wire                        axi_rready                 ;
wire [3:0] m00_axi_awregion_nc;
wire [3:0] m00_axi_arregion_nc;

wire [ddr_ID_WIDTH-1:0]         ddr_M_AXI_ARID;
wire [AXI_M_AXI_ADDR_WIDTH-1:0] ddr_M_AXI_ARADDR;
wire [7:0]                      ddr_M_AXI_ARLEN;
wire [2:0]                      ddr_M_AXI_ARSIZE;
wire [1:0]                      ddr_M_AXI_ARBURST;
wire                            ddr_M_AXI_ARLOCK;
wire [3:0]                      ddr_M_AXI_ARCACHE;
wire [2:0]                      ddr_M_AXI_ARPROT;
wire [3:0]                      ddr_M_AXI_ARQOS;
wire [AXI_M_AXI_USER_WIDTH-1:0] ddr_M_AXI_ARUSER;
wire                            ddr_M_AXI_ARVALID;
wire                            ddr_M_AXI_RREADY;
wire [ddr_ID_WIDTH-1:0]         ddr_M_AXI_AWID;
wire [AXI_S_AXI_ADDR_WIDTH-1:0] ddr_M_AXI_AWADDR;
wire [7:0]                      ddr_M_AXI_AWLEN;
wire [2:0]                      ddr_M_AXI_AWSIZE;
wire [1:0]                      ddr_M_AXI_AWBURST;
wire                            ddr_M_AXI_AWLOCK;
wire [3:0]                      ddr_M_AXI_AWCACHE;
wire [2:0]                      ddr_M_AXI_AWPROT;
wire [3:0]                      ddr_M_AXI_AWQOS;
wire [AXI_M_AXI_USER_WIDTH-1:0] ddr_M_AXI_AWUSER;
wire                            ddr_M_AXI_AWVALID;
wire [AXI_M_AXI_DATA_WIDTH-1:0] ddr_M_AXI_WDATA;
wire [AXI_M_AXI_DATA_BYTES-1:0] ddr_M_AXI_WSTRB;
wire                            ddr_M_AXI_WLAST;
wire [AXI_M_AXI_USER_WIDTH-1:0] ddr_M_AXI_WUSER;
wire                            ddr_M_AXI_WVALID;
wire                            ddr_M_AXI_BREADY;
wire                            ddr_M_AXI_ARREADY;
wire [ddr_ID_WIDTH-1:0]         ddr_M_AXI_RID;
wire [AXI_M_AXI_DATA_WIDTH-1:0] ddr_M_AXI_RDATA;
wire [1:0]                      ddr_M_AXI_RRESP;
wire                            ddr_M_AXI_RLAST;
wire [AXI_M_AXI_USER_WIDTH-1:0] ddr_M_AXI_RUSER;
wire                            ddr_M_AXI_RVALID;
wire                            ddr_M_AXI_AWREADY;
wire                            ddr_M_AXI_WREADY;
wire [ddr_ID_WIDTH-1:0]         ddr_M_AXI_BID;
wire [1:0]                      ddr_M_AXI_BRESP;
wire [AXI_M_AXI_USER_WIDTH-1:0] ddr_M_AXI_BUSER;
wire                            ddr_M_AXI_BVALID;

wire [AXI_M_AXI_ID_WIDTH-1:0]   data_M_AXI_ARID;
wire [AXI_M_AXI_ADDR_WIDTH-1:0] data_M_AXI_ARADDR;
wire [7:0]                      data_M_AXI_ARLEN;
wire [2:0]                      data_M_AXI_ARSIZE;
wire [1:0]                      data_M_AXI_ARBURST;
wire                            data_M_AXI_ARLOCK;
wire [3:0]                      data_M_AXI_ARCACHE;
wire [2:0]                      data_M_AXI_ARPROT;
wire [3:0]                      data_M_AXI_ARQOS;
wire [AXI_M_AXI_USER_WIDTH-1:0] data_M_AXI_ARUSER;
wire                            data_M_AXI_ARVALID;
wire                            data_M_AXI_ARREADY;
wire [AXI_M_AXI_ID_WIDTH-1:0]   data_M_AXI_RID;
wire [AXI_M_AXI_DATA_WIDTH-1:0] data_M_AXI_RDATA;
wire [1:0]                      data_M_AXI_RRESP;
wire                            data_M_AXI_RLAST;
wire [AXI_M_AXI_USER_WIDTH-1:0] data_M_AXI_RUSER;
wire                            data_M_AXI_RVALID;
wire                            data_M_AXI_RREADY;

wire [AXI_M_AXI_ID_WIDTH-1:0]   data_M_AXI_AWID;
wire [AXI_M_AXI_ADDR_WIDTH-1:0] data_M_AXI_AWADDR;
wire [7:0]                      data_M_AXI_AWLEN;
wire [2:0]                      data_M_AXI_AWSIZE;
wire [1:0]                      data_M_AXI_AWBURST;
wire                            data_M_AXI_AWLOCK;
wire [3:0]                      data_M_AXI_AWCACHE;
wire [2:0]                      data_M_AXI_AWPROT;
wire [3:0]                      data_M_AXI_AWQOS;
wire [AXI_M_AXI_USER_WIDTH-1:0] data_M_AXI_AWUSER;
wire                            data_M_AXI_AWVALID;
wire                            data_M_AXI_AWREADY;
wire [AXI_M_AXI_DATA_WIDTH-1:0] data_M_AXI_WDATA;
wire [AXI_M_AXI_DATA_BYTES-1:0] data_M_AXI_WSTRB;
wire                            data_M_AXI_WLAST;
wire [AXI_M_AXI_USER_WIDTH-1:0] data_M_AXI_WUSER;
wire                            data_M_AXI_WVALID;
wire                            data_M_AXI_WREADY;
wire [AXI_M_AXI_ID_WIDTH-1:0]   data_M_AXI_BID;
wire [1:0]                      data_M_AXI_BRESP;
wire [AXI_M_AXI_USER_WIDTH-1:0] data_M_AXI_BUSER;
wire                            data_M_AXI_BVALID;
wire                            data_M_AXI_BREADY;

wire [AXI_M_AXI_ID_WIDTH-1:0]   insn_M_AXI_ARID;
wire [AXI_M_AXI_ADDR_WIDTH-1:0] insn_M_AXI_ARADDR;
wire [7:0]                      insn_M_AXI_ARLEN;
wire [2:0]                      insn_M_AXI_ARSIZE;
wire [1:0]                      insn_M_AXI_ARBURST;
wire                            insn_M_AXI_ARLOCK;
wire [3:0]                      insn_M_AXI_ARCACHE;
wire [2:0]                      insn_M_AXI_ARPROT;
wire [3:0]                      insn_M_AXI_ARQOS;
wire [AXI_M_AXI_USER_WIDTH-1:0] insn_M_AXI_ARUSER;
wire                            insn_M_AXI_ARVALID;
wire                            insn_M_AXI_ARREADY;
wire [AXI_M_AXI_ID_WIDTH-1:0]   insn_M_AXI_RID;
wire [AXI_M_AXI_DATA_WIDTH-1:0] insn_M_AXI_RDATA;
wire [1:0]                      insn_M_AXI_RRESP;
wire                            insn_M_AXI_RLAST;
wire [AXI_M_AXI_USER_WIDTH-1:0] insn_M_AXI_RUSER;
wire                            insn_M_AXI_RVALID;
wire                            insn_M_AXI_RREADY;

wire [AXI_M_AXI_ID_WIDTH-1:0]   insn_M_AXI_AWID;
wire [AXI_M_AXI_ADDR_WIDTH-1:0] insn_M_AXI_AWADDR;
wire [7:0]                      insn_M_AXI_AWLEN;
wire [2:0]                      insn_M_AXI_AWSIZE;
wire [1:0]                      insn_M_AXI_AWBURST;
wire                            insn_M_AXI_AWLOCK;
wire [3:0]                      insn_M_AXI_AWCACHE;
wire [2:0]                      insn_M_AXI_AWPROT;
wire [3:0]                      insn_M_AXI_AWQOS;
wire [AXI_M_AXI_USER_WIDTH-1:0] insn_M_AXI_AWUSER;
wire                            insn_M_AXI_AWVALID;
wire                            insn_M_AXI_AWREADY;
wire [AXI_M_AXI_DATA_WIDTH-1:0] insn_M_AXI_WDATA;
wire [AXI_M_AXI_DATA_BYTES-1:0] insn_M_AXI_WSTRB;
wire                            insn_M_AXI_WLAST;
wire [AXI_M_AXI_USER_WIDTH-1:0] insn_M_AXI_WUSER;
wire                            insn_M_AXI_WVALID;
wire                            insn_M_AXI_WREADY;
wire [AXI_M_AXI_ID_WIDTH-1:0]   insn_M_AXI_BID;
wire [1:0]                      insn_M_AXI_BRESP;
wire [AXI_M_AXI_USER_WIDTH-1:0] insn_M_AXI_BUSER;
wire                            insn_M_AXI_BVALID;
wire                            insn_M_AXI_BREADY;

parameter DATA_WIDTH         = AXI_M_AXI_DATA_WIDTH;
parameter ADDR_WIDTH         = AXI_M_AXI_ADDR_WIDTH;
parameter STRB_WIDTH         = (DATA_WIDTH/8);
parameter S_ID_WIDTH         = 10;
parameter M_ID_WIDTH         = 11;
parameter AWUSER_ENABLE      = 0;
parameter AWUSER_WIDTH       = 1;
parameter WUSER_ENABLE       = 0;
parameter WUSER_WIDTH        = 1;
parameter BUSER_ENABLE       = 0;
parameter BUSER_WIDTH        = 1;
parameter ARUSER_ENABLE      = 0;
parameter ARUSER_WIDTH       = 1;
parameter RUSER_ENABLE       = 0;
parameter RUSER_WIDTH        = 1;
parameter S00_THREADS        = 4;
parameter S00_ACCEPT         = 8;
parameter S01_THREADS        = 4;
parameter S01_ACCEPT         = 8;
parameter M_REGIONS          = 1;
parameter M00_BASE_ADDR      = 0;
parameter M00_ADDR_WIDTH     = {M_REGIONS{64'd64}};
parameter M00_CONNECT_READ   = 4'b1111;
parameter M00_CONNECT_WRITE  = 4'b1111;
parameter M00_ISSUE          = 4;
parameter M00_SECURE         = 0;
parameter S00_AW_REG_TYPE    = 0;
parameter S00_W_REG_TYPE     = 0;
parameter S00_B_REG_TYPE     = 1;
parameter S00_AR_REG_TYPE    = 0;
parameter S00_R_REG_TYPE     = 2;
parameter S01_AW_REG_TYPE    = 0;
parameter S01_W_REG_TYPE     = 0;
parameter S01_B_REG_TYPE     = 1;
parameter S01_AR_REG_TYPE    = 0;
parameter S01_R_REG_TYPE     = 2;
parameter M00_AW_REG_TYPE    = 1;
parameter M00_W_REG_TYPE     = 2;
parameter M00_B_REG_TYPE     = 0;
parameter M00_AR_REG_TYPE    = 1;
parameter M00_R_REG_TYPE     = 0;

wire [10:0] ddr_M_AXI_ARID_virt;
wire [10:0] ddr_M_AXI_RID_virt;
wire [10:0] ddr_M_AXI_AWID_virt;
wire [10:0] ddr_M_AXI_BID_virt;

npu_top_vcs u_npu_top_vcs (
    .axi_clk            ( core_clk           ),  // input
    .axi_rst_n          ( axi_rst_n          ),  // input

    /* insn AXI master */
    .insn_M_AXI_ARID    ( insn_M_AXI_ARID    ),
    .insn_M_AXI_ARADDR  ( insn_M_AXI_ARADDR  ),
    .insn_M_AXI_ARLEN   ( insn_M_AXI_ARLEN   ),
    .insn_M_AXI_ARSIZE  ( insn_M_AXI_ARSIZE  ),
    .insn_M_AXI_ARBURST ( insn_M_AXI_ARBURST ),
    .insn_M_AXI_ARLOCK  ( insn_M_AXI_ARLOCK  ),
    .insn_M_AXI_ARCACHE ( insn_M_AXI_ARCACHE ),
    .insn_M_AXI_ARPROT  ( insn_M_AXI_ARPROT  ),
    .insn_M_AXI_ARQOS   ( insn_M_AXI_ARQOS   ),
    .insn_M_AXI_ARUSER  ( insn_M_AXI_ARUSER  ),
    .insn_M_AXI_ARVALID ( insn_M_AXI_ARVALID ),
    .insn_M_AXI_ARREADY ( insn_M_AXI_ARREADY ),
    .insn_M_AXI_RID     ( insn_M_AXI_RID     ),
    .insn_M_AXI_RDATA   ( insn_M_AXI_RDATA   ),
    .insn_M_AXI_RRESP   ( insn_M_AXI_RRESP   ),
    .insn_M_AXI_RLAST   ( insn_M_AXI_RLAST   ),
    .insn_M_AXI_RUSER   ( insn_M_AXI_RUSER   ),
    .insn_M_AXI_RVALID  ( insn_M_AXI_RVALID  ),
    .insn_M_AXI_RREADY  ( insn_M_AXI_RREADY  ),

    .insn_M_AXI_AWID    ( insn_M_AXI_AWID    ),
    .insn_M_AXI_AWADDR  ( insn_M_AXI_AWADDR  ),
    .insn_M_AXI_AWLEN   ( insn_M_AXI_AWLEN   ),
    .insn_M_AXI_AWSIZE  ( insn_M_AXI_AWSIZE  ),
    .insn_M_AXI_AWBURST ( insn_M_AXI_AWBURST ),
    .insn_M_AXI_AWLOCK  ( insn_M_AXI_AWLOCK  ),
    .insn_M_AXI_AWCACHE ( insn_M_AXI_AWCACHE ),
    .insn_M_AXI_AWPROT  ( insn_M_AXI_AWPROT  ),
    .insn_M_AXI_AWQOS   ( insn_M_AXI_AWQOS   ),
    .insn_M_AXI_AWUSER  ( insn_M_AXI_AWUSER  ),
    .insn_M_AXI_AWVALID ( insn_M_AXI_AWVALID ),
    .insn_M_AXI_AWREADY ( insn_M_AXI_AWREADY ),
    .insn_M_AXI_WDATA   ( insn_M_AXI_WDATA   ),
    .insn_M_AXI_WSTRB   ( insn_M_AXI_WSTRB   ),
    .insn_M_AXI_WLAST   ( insn_M_AXI_WLAST   ),
    .insn_M_AXI_WUSER   ( insn_M_AXI_WUSER   ),
    .insn_M_AXI_WVALID  ( insn_M_AXI_WVALID  ),
    .insn_M_AXI_WREADY  ( insn_M_AXI_WREADY  ),
    .insn_M_AXI_BID     ( insn_M_AXI_BID     ),
    .insn_M_AXI_BRESP   ( insn_M_AXI_BRESP   ),
    .insn_M_AXI_BUSER   ( insn_M_AXI_BUSER   ),
    .insn_M_AXI_BVALID  ( insn_M_AXI_BVALID  ),
    .insn_M_AXI_BREADY  ( insn_M_AXI_BREADY  ),

    /* data AXI master */
    .data_M_AXI_ARID    ( data_M_AXI_ARID    ),
    .data_M_AXI_ARADDR  ( data_M_AXI_ARADDR  ),
    .data_M_AXI_ARLEN   ( data_M_AXI_ARLEN   ),
    .data_M_AXI_ARSIZE  ( data_M_AXI_ARSIZE  ),
    .data_M_AXI_ARBURST ( data_M_AXI_ARBURST ),
    .data_M_AXI_ARLOCK  ( data_M_AXI_ARLOCK  ),
    .data_M_AXI_ARCACHE ( data_M_AXI_ARCACHE ),
    .data_M_AXI_ARPROT  ( data_M_AXI_ARPROT  ),
    .data_M_AXI_ARQOS   ( data_M_AXI_ARQOS   ),
    .data_M_AXI_ARUSER  ( data_M_AXI_ARUSER  ),
    .data_M_AXI_ARVALID ( data_M_AXI_ARVALID ),
    .data_M_AXI_ARREADY ( data_M_AXI_ARREADY ),
    .data_M_AXI_RID     ( data_M_AXI_RID     ),
    .data_M_AXI_RDATA   ( data_M_AXI_RDATA   ),
    .data_M_AXI_RRESP   ( data_M_AXI_RRESP   ),
    .data_M_AXI_RLAST   ( data_M_AXI_RLAST   ),
    .data_M_AXI_RUSER   ( data_M_AXI_RUSER   ),
    .data_M_AXI_RVALID  ( data_M_AXI_RVALID  ),
    .data_M_AXI_RREADY  ( data_M_AXI_RREADY  ),

    .data_M_AXI_AWID    ( data_M_AXI_AWID    ),
    .data_M_AXI_AWADDR  ( data_M_AXI_AWADDR  ),
    .data_M_AXI_AWLEN   ( data_M_AXI_AWLEN   ),
    .data_M_AXI_AWSIZE  ( data_M_AXI_AWSIZE  ),
    .data_M_AXI_AWBURST ( data_M_AXI_AWBURST ),
    .data_M_AXI_AWLOCK  ( data_M_AXI_AWLOCK  ),
    .data_M_AXI_AWCACHE ( data_M_AXI_AWCACHE ),
    .data_M_AXI_AWPROT  ( data_M_AXI_AWPROT  ),
    .data_M_AXI_AWQOS   ( data_M_AXI_AWQOS   ),
    .data_M_AXI_AWUSER  ( data_M_AXI_AWUSER  ),
    .data_M_AXI_AWVALID ( data_M_AXI_AWVALID ),
    .data_M_AXI_AWREADY ( data_M_AXI_AWREADY ),
    .data_M_AXI_WDATA   ( data_M_AXI_WDATA   ),
    .data_M_AXI_WSTRB   ( data_M_AXI_WSTRB   ),
    .data_M_AXI_WLAST   ( data_M_AXI_WLAST   ),
    .data_M_AXI_WUSER   ( data_M_AXI_WUSER   ),
    .data_M_AXI_WVALID  ( data_M_AXI_WVALID  ),
    .data_M_AXI_WREADY  ( data_M_AXI_WREADY  ),
    .data_M_AXI_BID     ( data_M_AXI_BID     ),
    .data_M_AXI_BRESP   ( data_M_AXI_BRESP   ),
    .data_M_AXI_BUSER   ( data_M_AXI_BUSER   ),
    .data_M_AXI_BVALID  ( data_M_AXI_BVALID  ),
    .data_M_AXI_BREADY  ( data_M_AXI_BREADY  ),

    /* S_AXI slave interface */
    .axi_S_AXI_ARID     ( axi_S_AXI_ARID     ),
    .axi_S_AXI_ARADDR   ( axi_S_AXI_ARADDR   ),
    .axi_S_AXI_ARLEN    ( axi_S_AXI_ARLEN    ),
    .axi_S_AXI_ARSIZE   ( axi_S_AXI_ARSIZE   ),
    .axi_S_AXI_ARBURST  ( axi_S_AXI_ARBURST  ),
    .axi_S_AXI_ARLOCK   ( axi_S_AXI_ARLOCK   ),
    .axi_S_AXI_ARCACHE  ( axi_S_AXI_ARCACHE  ),
    .axi_S_AXI_ARPROT   ( axi_S_AXI_ARPROT   ),
    .axi_S_AXI_ARQOS    ( axi_S_AXI_ARQOS    ),
    .axi_S_AXI_ARUSER   ( axi_S_AXI_ARUSER   ),
    .axi_S_AXI_ARVALID  ( axi_S_AXI_ARVALID  ),
    .axi_S_AXI_ARREADY  ( axi_S_AXI_ARREADY  ),
    .axi_S_AXI_RID      ( axi_S_AXI_RID      ),
    .axi_S_AXI_RDATA    ( axi_S_AXI_RDATA    ),
    .axi_S_AXI_RRESP    ( axi_S_AXI_RRESP    ),
    .axi_S_AXI_RLAST    ( axi_S_AXI_RLAST    ),
    .axi_S_AXI_RUSER    ( axi_S_AXI_RUSER    ),
    .axi_S_AXI_RVALID   ( axi_S_AXI_RVALID   ),
    .axi_S_AXI_RREADY   ( axi_S_AXI_RREADY   ),

    .axi_S_AXI_AWID     ( axi_S_AXI_AWID     ),
    .axi_S_AXI_AWADDR   ( axi_S_AXI_AWADDR   ),
    .axi_S_AXI_AWLEN    ( axi_S_AXI_AWLEN    ),
    .axi_S_AXI_AWSIZE   ( axi_S_AXI_AWSIZE   ),
    .axi_S_AXI_AWBURST  ( axi_S_AXI_AWBURST  ),
    .axi_S_AXI_AWLOCK   ( axi_S_AXI_AWLOCK   ),
    .axi_S_AXI_AWCACHE  ( axi_S_AXI_AWCACHE  ),
    .axi_S_AXI_AWPROT   ( axi_S_AXI_AWPROT   ),
    .axi_S_AXI_AWQOS    ( axi_S_AXI_AWQOS    ),
    .axi_S_AXI_AWUSER   ( axi_S_AXI_AWUSER   ),
    .axi_S_AXI_AWVALID  ( axi_S_AXI_AWVALID  ),
    .axi_S_AXI_AWREADY  ( axi_S_AXI_AWREADY  ),
    .axi_S_AXI_WDATA    ( axi_S_AXI_WDATA    ),
    .axi_S_AXI_WSTRB    ( axi_S_AXI_WSTRB    ),
    .axi_S_AXI_WLAST    ( axi_S_AXI_WLAST    ),
    .axi_S_AXI_WUSER    ( axi_S_AXI_WUSER    ),
    .axi_S_AXI_WVALID   ( axi_S_AXI_WVALID   ),
    .axi_S_AXI_WREADY   ( axi_S_AXI_WREADY   ),
    .axi_S_AXI_BID      ( axi_S_AXI_BID      ),
    .axi_S_AXI_BRESP    ( axi_S_AXI_BRESP    ),
    .axi_S_AXI_BUSER    ( axi_S_AXI_BUSER    ),
    .axi_S_AXI_BVALID   ( axi_S_AXI_BVALID   ),
    .axi_S_AXI_BREADY   ( axi_S_AXI_BREADY   ),

    .clk                ( clk                ),
    .rst_n              ( rst_n              )
   )/*synthesis syn_black_box */;

ddr3 ddr_npu (
  .ref_clk                 (ref_clk                ),// input
  .resetn                  (1'b1                   ),// input
  .core_clk                (core_clk               ),// output
  .pll_lock                (pll_lock               ),// output
  .phy_pll_lock            (phy_pll_lock           ),// output
  .gpll_lock               (gpll_lock              ),// output
  .rst_gpll_lock           (rst_gpll_lock          ),// output
  .ddrphy_cpd_lock         (ddrphy_cpd_lock        ),// output
  .ddr_init_done           (ddr_init_done          ),// output

  .axi_awaddr              (axi_awaddr             ), // input [AXI_ADDR_WIDTH-1:0]
  .axi_awid                (axi_awid               ), // input [7:0]
  .axi_awlen               (axi_awlen              ), // input [7:0]
  .axi_awsize              (axi_awsize             ), // input [2:0]
  .axi_awburst             (axi_awburst            ), // input [1:0]
  .axi_awready             (axi_awready            ), // output
  .axi_awvalid             (axi_awvalid            ), // input
  .axi_wdata               (axi_wdata              ), // input [8*MEM_DQ_WIDTH-1:0]
  .axi_wstrb               (axi_wstrb              ), // input [MEM_DQ_WIDTH-1:0]
  .axi_wlast               (axi_wlast              ), // input
  .axi_wvalid              (axi_wvalid             ), // input
  .axi_wready              (axi_wready             ), // output
  .axi_bready              (axi_bready             ), // input
  .axi_bid                 (axi_bid                ), // output [7:0]
  .axi_bresp               (axi_bresp              ), // output [1:0]
  .axi_bvalid              (axi_bvalid             ), // output

  .axi_araddr              (axi_araddr             ), // input [AXI_ADDR_WIDTH-1:0]
  .axi_arid                (axi_arid               ), // input [7:0]
  .axi_arlen               (axi_arlen              ), // input [7:0]
  .axi_arsize              (axi_arsize             ), // input [2:0]
  .axi_arburst             (axi_arburst            ), // input [1:0]
  .axi_arvalid             (axi_arvalid            ), // input
  .axi_arready             (axi_arready            ), // output
  .axi_rready              (axi_rready             ), // input
  .axi_rdata               (axi_rdata              ), // output [8*MEM_DQ_WIDTH-1:0]
  .axi_rvalid              (axi_rvalid             ), // output
  .axi_rlast               (axi_rlast              ), // output
  .axi_rid                 (axi_rid                ), // output [7:0]
  .axi_rresp               (axi_rresp              ), // output [1:0]

  .apb_clk                 (apb_clk                ),// input
  .apb_rst_n               (apb_rst_n              ),// input
  .apb_sel                 (apb_sel                ),// input
  .apb_enable              (apb_enable             ),// input
  .apb_addr                (apb_addr               ),// input [7:0]
  .apb_write               (apb_write              ),// input
  .apb_ready               (apb_ready              ),// output
  .apb_wdata               (apb_wdata              ),// input [15:0]
  .apb_rdata               (apb_rdata              ),// output [15:0]

  .mem_cs_n                (mem_cs_n               ),// output
  .mem_rst_n               (mem_rst_n              ),// output
  .mem_ck                  (mem_ck                 ),// output
  .mem_ck_n                (mem_ck_n               ),// output
  .mem_cke                 (mem_cke                ),// output
  .mem_ras_n               (mem_ras_n              ),// output
  .mem_cas_n               (mem_cas_n              ),// output
  .mem_we_n                (mem_we_n               ),// output
  .mem_odt                 (mem_odt                ),// output
  .mem_a                   (mem_a                  ),// output [14:0]
  .mem_ba                  (mem_ba                 ),// output [2:0]
  .mem_dqs                 (mem_dqs                ),// inout [1:0]
  .mem_dqs_n               (mem_dqs_n              ),// inout [1:0]
  .mem_dq                  (mem_dq                 ),// inout [15:0]
  .mem_dm                  (mem_dm                 ),// output [1:0]

  .dbg_gate_start             (1'b0                         ),
  .dbg_cpd_start              (1'b0                         ),
  .dbg_ddrphy_rst_n           (1'b1                         ),
  .dbg_gpll_scan_rst          (1'b0                         ),
  .samp_position_dyn_adj      (1'b0                         ),
  .init_samp_position_even    (16'd0                        ),
  .init_samp_position_odd     (16'd0                        ),
  .wrcal_position_dyn_adj     (1'b0                         ),
  .init_wrcal_position        (16'd0                        ),
  .force_read_clk_ctrl        (1'b0                         ),
  .init_slip_step             (8'd0                         ),
  .init_read_clk_ctrl         (6'd0                         ),
  .debug_calib_ctrl           (                             ),
  .dbg_dll_upd_state          (                             ),
  .dbg_slice_status           (                             ),
  .dbg_slice_state            (                             ),
  .debug_data                 (                             ),
  .debug_gpll_dps_phase       (                             ),
  .dbg_rst_dps_state          (                             ),
  .dbg_tran_err_rst_cnt       (                             ),
  .dbg_ddrphy_init_fail       (                             ),
  .debug_cpd_offset_adj       (1'b0                         ),
  .debug_cpd_offset_dir       (1'b0                         ),
  .debug_cpd_offset           (10'd0                        ),
  .debug_dps_cnt_dir0         (                             ),
  .debug_dps_cnt_dir1         (                             ),
  .ck_dly_en                  (1'b0                         ),
  .init_ck_dly_step           (8'd0                         ),
  .ck_dly_set_bin             (                             ),
  .align_error                (                             ),
  .debug_rst_state            (                             ),
  .debug_cpd_state            (                             )
);

axi_id_convertor #(
  .IN_ID_WIDTH  ( 11  ),
  .OUT_ID_WIDTH ( 10  )
) u_ddr_M_id_convertor(
  .clk       ( core_clk            ),
  .rst_n     ( axi_rst_n           ),
  .arvalid   ( ddr_M_AXI_ARVALID   ),
  .arready   ( ddr_M_AXI_ARREADY   ),
  .arid      ( ddr_M_AXI_ARID_virt ),
  .virt_arid ( ddr_M_AXI_ARID      ),
  .awvalid   ( ddr_M_AXI_AWVALID   ),
  .awready   ( ddr_M_AXI_AWREADY   ),
  .awid      ( ddr_M_AXI_AWID_virt ),
  .virt_awid ( ddr_M_AXI_AWID      ),
  .rvalid    ( ddr_M_AXI_RVALID    ),
  .rready    ( ddr_M_AXI_RREADY    ),
  .rid       ( ddr_M_AXI_RID_virt  ),
  .virt_rid  ( ddr_M_AXI_RID       ),
  .bvalid    ( ddr_M_AXI_BVALID    ),
  .bready    ( ddr_M_AXI_BREADY    ),
  .bid       ( ddr_M_AXI_BID_virt  ),
  .virt_bid  ( ddr_M_AXI_BID       )
)/*synthesis syn_black_box */;

assign axi_awaddr   = ddr_M_AXI_AWADDR[CTRL_ADDR_WIDTH-1:0];
assign axi_awid     = ddr_M_AXI_AWID[7:0];
assign axi_awlen    = ddr_M_AXI_AWLEN;     
assign axi_awsize   = ddr_M_AXI_AWSIZE;   
assign axi_awburst  = ddr_M_AXI_AWBURST;
assign axi_awvalid  = ddr_M_AXI_AWVALID;
assign axi_wdata    = ddr_M_AXI_WDATA;     
assign axi_wstrb    = ddr_M_AXI_WSTRB;
assign axi_wlast    = ddr_M_AXI_WLAST;
assign axi_wvalid   = ddr_M_AXI_WVALID;
assign axi_bready   = ddr_M_AXI_BREADY;

assign axi_araddr   = ddr_M_AXI_ARADDR[CTRL_ADDR_WIDTH-1:0];
assign axi_arid     = ddr_M_AXI_ARID[7:0];
assign axi_arlen    = ddr_M_AXI_ARLEN;
assign axi_arsize   = ddr_M_AXI_ARSIZE;
assign axi_arburst  = ddr_M_AXI_ARBURST;
assign axi_arvalid  = ddr_M_AXI_ARVALID;
assign axi_rready   = ddr_M_AXI_RREADY;

// ddr3 -> crossbar 方向
assign ddr_M_AXI_AWREADY = axi_awready;
assign ddr_M_AXI_WREADY  = axi_wready;
assign ddr_M_AXI_BID     = axi_bid[7:0];
assign ddr_M_AXI_BRESP   = axi_bresp;
assign ddr_M_AXI_BVALID  = axi_bvalid;

assign ddr_M_AXI_ARREADY = axi_arready;
assign ddr_M_AXI_RID     = axi_rid[7:0];
assign ddr_M_AXI_RDATA   = axi_rdata;      
assign ddr_M_AXI_RRESP   = axi_rresp;
assign ddr_M_AXI_RLAST   = axi_rlast;
assign ddr_M_AXI_RVALID  = axi_rvalid;

axi_crossbar_wrap_3x1 #(
  .DATA_WIDTH        ( AXI_M_AXI_DATA_WIDTH ),
  .ADDR_WIDTH        ( AXI_M_AXI_ADDR_WIDTH ),
  .STRB_WIDTH        ( AXI_M_AXI_DATA_WIDTH/8 ),
  .S_ID_WIDTH        ( 10 ),
  .M_ID_WIDTH        ( 11 ),
  .AWUSER_ENABLE     ( 0 ), .AWUSER_WIDTH ( 1 ),
  .WUSER_ENABLE      ( 0 ), .WUSER_WIDTH  ( 1 ),
  .BUSER_ENABLE      ( 0 ), .BUSER_WIDTH  ( 1 ),
  .ARUSER_ENABLE     ( 0 ), .ARUSER_WIDTH ( 1 ),
  .RUSER_ENABLE      ( 0 ), .RUSER_WIDTH  ( 1 ),
  .S00_THREADS       ( 4 ), .S00_ACCEPT   ( 8 ),
  .S01_THREADS       ( 4 ), .S01_ACCEPT   ( 8 ),
  .M_REGIONS         ( 1 ),
  .M00_BASE_ADDR     ( 0 ),
  .M00_ADDR_WIDTH    ( {1{64'd64}} ),
  .M00_CONNECT_READ  ( 4'b1111 ),
  .M00_CONNECT_WRITE ( 4'b1111 ),
  .M00_ISSUE         ( 4 ),
  .M00_SECURE        ( 0 ),
  .M00_AR_REG_TYPE   ( 1 ), .M00_R_REG_TYPE ( 0 )
) u_axi_crossbar_wrap_3x1_data (
  .clk              ( core_clk            ),
  .rst_n            ( axi_rst_n           ),

  /* s00 <- insn_M_AXI (master) */
  .s00_axi_awid     ( insn_M_AXI_AWID    ),
  .s00_axi_awaddr   ( insn_M_AXI_AWADDR  ),
  .s00_axi_awlen    ( insn_M_AXI_AWLEN   ),
  .s00_axi_awsize   ( insn_M_AXI_AWSIZE  ),
  .s00_axi_awburst  ( insn_M_AXI_AWBURST ),
  .s00_axi_awlock   ( insn_M_AXI_AWLOCK  ),
  .s00_axi_awcache  ( insn_M_AXI_AWCACHE ),
  .s00_axi_awprot   ( insn_M_AXI_AWPROT  ),
  .s00_axi_awqos    ( insn_M_AXI_AWQOS   ),
  .s00_axi_awuser   ( insn_M_AXI_AWUSER  ),
  .s00_axi_awvalid  ( insn_M_AXI_AWVALID ),
  .s00_axi_awready  ( insn_M_AXI_AWREADY ),
  .s00_axi_wdata    ( insn_M_AXI_WDATA   ),
  .s00_axi_wstrb    ( insn_M_AXI_WSTRB   ),
  .s00_axi_wlast    ( insn_M_AXI_WLAST   ),
  .s00_axi_wuser    ( insn_M_AXI_WUSER   ),
  .s00_axi_wvalid   ( insn_M_AXI_WVALID  ),
  .s00_axi_wready   ( insn_M_AXI_WREADY  ),
  .s00_axi_bid      ( insn_M_AXI_BID     ),
  .s00_axi_bresp    ( insn_M_AXI_BRESP   ),
  .s00_axi_buser    ( insn_M_AXI_BUSER   ),
  .s00_axi_bvalid   ( insn_M_AXI_BVALID  ),
  .s00_axi_bready   ( insn_M_AXI_BREADY  ),
  .s00_axi_arid     ( insn_M_AXI_ARID    ),
  .s00_axi_araddr   ( insn_M_AXI_ARADDR  ),
  .s00_axi_arlen    ( insn_M_AXI_ARLEN   ),
  .s00_axi_arsize   ( insn_M_AXI_ARSIZE  ),
  .s00_axi_arburst  ( insn_M_AXI_ARBURST ),
  .s00_axi_arlock   ( insn_M_AXI_ARLOCK  ),
  .s00_axi_arcache  ( insn_M_AXI_ARCACHE ),
  .s00_axi_arprot   ( insn_M_AXI_ARPROT  ),
  .s00_axi_arqos    ( insn_M_AXI_ARQOS   ),
  .s00_axi_aruser   ( insn_M_AXI_ARUSER  ),
  .s00_axi_arvalid  ( insn_M_AXI_ARVALID ),
  .s00_axi_arready  ( insn_M_AXI_ARREADY ),
  .s00_axi_rid      ( insn_M_AXI_RID     ),
  .s00_axi_rdata    ( insn_M_AXI_RDATA   ),
  .s00_axi_rresp    ( insn_M_AXI_RRESP   ),
  .s00_axi_rlast    ( insn_M_AXI_RLAST   ),
  .s00_axi_ruser    ( insn_M_AXI_RUSER   ),
  .s00_axi_rvalid   ( insn_M_AXI_RVALID  ),
  .s00_axi_rready   ( insn_M_AXI_RREADY  ),

  /* s01 <- data_M_AXI (master) */
  .s01_axi_awid     ( data_M_AXI_AWID    ),
  .s01_axi_awaddr   ( data_M_AXI_AWADDR  ),
  .s01_axi_awlen    ( data_M_AXI_AWLEN   ),
  .s01_axi_awsize   ( data_M_AXI_AWSIZE  ),
  .s01_axi_awburst  ( data_M_AXI_AWBURST ),
  .s01_axi_awlock   ( data_M_AXI_AWLOCK  ),
  .s01_axi_awcache  ( data_M_AXI_AWCACHE ),
  .s01_axi_awprot   ( data_M_AXI_AWPROT  ),
  .s01_axi_awqos    ( data_M_AXI_AWQOS   ),
  .s01_axi_awuser   ( data_M_AXI_AWUSER  ),
  .s01_axi_awvalid  ( data_M_AXI_AWVALID ),
  .s01_axi_awready  ( data_M_AXI_AWREADY ),
  .s01_axi_wdata    ( data_M_AXI_WDATA   ),
  .s01_axi_wstrb    ( data_M_AXI_WSTRB   ),
  .s01_axi_wlast    ( data_M_AXI_WLAST   ),
  .s01_axi_wuser    ( data_M_AXI_WUSER   ),
  .s01_axi_wvalid   ( data_M_AXI_WVALID  ),
  .s01_axi_wready   ( data_M_AXI_WREADY  ),
  .s01_axi_bid      ( data_M_AXI_BID     ),
  .s01_axi_bresp    ( data_M_AXI_BRESP   ),
  .s01_axi_buser    ( data_M_AXI_BUSER   ),
  .s01_axi_bvalid   ( data_M_AXI_BVALID  ),
  .s01_axi_bready   ( data_M_AXI_BREADY  ),
  .s01_axi_arid     ( data_M_AXI_ARID    ),
  .s01_axi_araddr   ( data_M_AXI_ARADDR  ),
  .s01_axi_arlen    ( data_M_AXI_ARLEN   ),
  .s01_axi_arsize   ( data_M_AXI_ARSIZE  ),
  .s01_axi_arburst  ( data_M_AXI_ARBURST ),
  .s01_axi_arlock   ( data_M_AXI_ARLOCK  ),
  .s01_axi_arcache  ( data_M_AXI_ARCACHE ),
  .s01_axi_arprot   ( data_M_AXI_ARPROT  ),
  .s01_axi_arqos    ( data_M_AXI_ARQOS   ),
  .s01_axi_aruser   ( data_M_AXI_ARUSER  ),
  .s01_axi_arvalid  ( data_M_AXI_ARVALID ),
  .s01_axi_arready  ( data_M_AXI_ARREADY ),
  .s01_axi_rid      ( data_M_AXI_RID     ),
  .s01_axi_rdata    ( data_M_AXI_RDATA   ),
  .s01_axi_rresp    ( data_M_AXI_RRESP   ),
  .s01_axi_rlast    ( data_M_AXI_RLAST   ),
  .s01_axi_ruser    ( data_M_AXI_RUSER   ),
  .s01_axi_rvalid   ( data_M_AXI_RVALID  ),
  .s01_axi_rready   ( data_M_AXI_RREADY  ),

  /* s02 <- axi_S_AXI (slave from NPU) */
  .s02_axi_awid     ( axi_S_AXI_AWID    ),
  .s02_axi_awaddr   ( axi_S_AXI_AWADDR  ),
  .s02_axi_awlen    ( axi_S_AXI_AWLEN   ),
  .s02_axi_awsize   ( axi_S_AXI_AWSIZE  ),
  .s02_axi_awburst  ( axi_S_AXI_AWBURST ),
  .s02_axi_awlock   ( axi_S_AXI_AWLOCK  ),
  .s02_axi_awcache  ( axi_S_AXI_AWCACHE ),
  .s02_axi_awprot   ( axi_S_AXI_AWPROT  ),
  .s02_axi_awqos    ( axi_S_AXI_AWQOS   ),
  .s02_axi_awuser   ( axi_S_AXI_AWUSER  ),
  .s02_axi_awvalid  ( axi_S_AXI_AWVALID ),
  .s02_axi_awready  ( axi_S_AXI_AWREADY ),
  .s02_axi_wdata    ( axi_S_AXI_WDATA   ),
  .s02_axi_wstrb    ( axi_S_AXI_WSTRB   ),
  .s02_axi_wlast    ( axi_S_AXI_WLAST   ),
  .s02_axi_wuser    ( axi_S_AXI_WUSER   ),
  .s02_axi_wvalid   ( axi_S_AXI_WVALID  ),
  .s02_axi_wready   ( axi_S_AXI_WREADY  ),
  .s02_axi_bid      ( axi_S_AXI_BID     ),
  .s02_axi_bresp    ( axi_S_AXI_BRESP   ),
  .s02_axi_buser    ( axi_S_AXI_BUSER   ),
  .s02_axi_bvalid   ( axi_S_AXI_BVALID  ),
  .s02_axi_bready   ( axi_S_AXI_BREADY  ),
  .s02_axi_arid     ( axi_S_AXI_ARID    ),
  .s02_axi_araddr   ( axi_S_AXI_ARADDR  ),
  .s02_axi_arlen    ( axi_S_AXI_ARLEN   ),
  .s02_axi_arsize   ( axi_S_AXI_ARSIZE  ),
  .s02_axi_arburst  ( axi_S_AXI_ARBURST ),
  .s02_axi_arlock   ( axi_S_AXI_ARLOCK  ),
  .s02_axi_arcache  ( axi_S_AXI_ARCACHE ),
  .s02_axi_arprot   ( axi_S_AXI_ARPROT  ),
  .s02_axi_arqos    ( axi_S_AXI_ARQOS   ),
  .s02_axi_aruser   ( axi_S_AXI_ARUSER  ),
  .s02_axi_arvalid  ( axi_S_AXI_ARVALID ),
  .s02_axi_arready  ( axi_S_AXI_ARREADY ),
  .s02_axi_rid      ( axi_S_AXI_RID     ),
  .s02_axi_rdata    ( axi_S_AXI_RDATA   ),
  .s02_axi_rresp    ( axi_S_AXI_RRESP   ),
  .s02_axi_rlast    ( axi_S_AXI_RLAST   ),
  .s02_axi_ruser    ( axi_S_AXI_RUSER   ),
  .s02_axi_rvalid   ( axi_S_AXI_RVALID  ),
  .s02_axi_rready   ( axi_S_AXI_RREADY  ),
  /* m00 -> DDR (use virtual id wires to feed id_convertor) */
  .m00_axi_awid     ( ddr_M_AXI_AWID_virt ),
  .m00_axi_awaddr   ( ddr_M_AXI_AWADDR    ),
  .m00_axi_awlen    ( ddr_M_AXI_AWLEN     ),
  .m00_axi_awsize   ( ddr_M_AXI_AWSIZE    ),
  .m00_axi_awburst  ( ddr_M_AXI_AWBURST   ),
  .m00_axi_awlock   ( ddr_M_AXI_AWLOCK    ),
  .m00_axi_awcache  ( ddr_M_AXI_AWCACHE   ),
  .m00_axi_awprot   ( ddr_M_AXI_AWPROT    ),
  .m00_axi_awqos    ( ddr_M_AXI_AWQOS     ),
  .m00_axi_awregion ( m00_axi_awregion_nc ),
  .m00_axi_awuser   ( ddr_M_AXI_AWUSER    ),
  .m00_axi_awvalid  ( ddr_M_AXI_AWVALID   ),
  .m00_axi_awready  ( ddr_M_AXI_AWREADY   ),
  .m00_axi_wdata    ( ddr_M_AXI_WDATA     ),
  .m00_axi_wstrb    ( ddr_M_AXI_WSTRB     ),
  .m00_axi_wlast    ( ddr_M_AXI_WLAST     ),
  .m00_axi_wuser    ( ddr_M_AXI_WUSER     ),
  .m00_axi_wvalid   ( ddr_M_AXI_WVALID    ),
  .m00_axi_wready   ( ddr_M_AXI_WREADY    ),
  .m00_axi_bid      ( ddr_M_AXI_BID_virt  ),
  .m00_axi_bresp    ( ddr_M_AXI_BRESP     ),
  .m00_axi_buser    ( ddr_M_AXI_BUSER     ),
  .m00_axi_bvalid   ( ddr_M_AXI_BVALID    ),
  .m00_axi_bready   ( ddr_M_AXI_BREADY    ),
  .m00_axi_arid     ( ddr_M_AXI_ARID_virt ),
  .m00_axi_araddr   ( ddr_M_AXI_ARADDR    ),
  .m00_axi_arlen    ( ddr_M_AXI_ARLEN     ),
  .m00_axi_arsize   ( ddr_M_AXI_ARSIZE    ),
  .m00_axi_arburst  ( ddr_M_AXI_ARBURST   ),
  .m00_axi_arlock   ( ddr_M_AXI_ARLOCK    ),
  .m00_axi_arcache  ( ddr_M_AXI_ARCACHE   ),
  .m00_axi_arprot   ( ddr_M_AXI_ARPROT    ),
  .m00_axi_arqos    ( ddr_M_AXI_ARQOS     ),
  .m00_axi_arregion ( m00_axi_arregion_nc ),
  .m00_axi_aruser   ( ddr_M_AXI_ARUSER    ),
  .m00_axi_arvalid  ( ddr_M_AXI_ARVALID   ),
  .m00_axi_arready  ( ddr_M_AXI_ARREADY   ),
  .m00_axi_rid      ( ddr_M_AXI_RID_virt  ),
  .m00_axi_rdata    ( ddr_M_AXI_RDATA    ),
  .m00_axi_rresp    ( ddr_M_AXI_RRESP    ),
  .m00_axi_rlast    ( ddr_M_AXI_RLAST    ),
  .m00_axi_ruser    ( ddr_M_AXI_RUSER    ),
  .m00_axi_rvalid   ( ddr_M_AXI_RVALID   ),
  .m00_axi_rready   ( ddr_M_AXI_RREADY   )
)/*synthesis syn_black_box */;

endmodule
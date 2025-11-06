module axi_ctrl_outside#(
	parameter MEM_DATA_BITS      = 128  ,
    parameter DATA_WIDTH         = 128  ,
	parameter READ_DATA_BITS     = 128  ,       
	parameter WRITE_DATA_BITS    = 16   ,       
	parameter ADDR_BITS          = 28   ,      
	parameter BUSRT_BITS         = 10   ,   
	parameter BURST_SIZE         = 256   ,
    parameter FRAME_LEN          = 28'd28800
)(
    // Reset, Clock
    input                           ARESETN,
    input                           ACLK,

    // Master Write Address
    output      [0:0]               M_AXI_AWID,
    output      [31:0]              M_AXI_AWADDR,
    output      [7:0]               M_AXI_AWLEN,    // Burst Length: 0-255
    output      [2:0]               M_AXI_AWSIZE,   // Burst Size: 100
    output      [1:0]               M_AXI_AWBURST,  // Burst Type: Fixed 2'b01(Incremental Burst)
    output                          M_AXI_AWLOCK,   // Lock: Fixed 2'b00
    output      [3:0]               M_AXI_AWCACHE,  // Cache: Fiex 2'b0011
    output      [2:0]               M_AXI_AWPROT,   // Protect: Fixed 2'b000
    output      [3:0]               M_AXI_AWQOS,    // QoS: Fixed 2'b0000
    output      [0:0]               M_AXI_AWUSER,   // User: Fixed 32'd0
    output                          M_AXI_AWVALID,
    input                           M_AXI_AWREADY,

    // Master Write Data
    output      [DATA_WIDTH-1:0]    M_AXI_WDATA,
    output      [DATA_WIDTH/8-1:0]  M_AXI_WSTRB,
    output                          M_AXI_WLAST,
    output      [0:0]               M_AXI_WUSER,
    output                          M_AXI_WVALID,
    input                           M_AXI_WREADY,

    // Master Write Response
    input       [0:0]               M_AXI_BID,
    input       [1:0]               M_AXI_BRESP,
    input       [0:0]               M_AXI_BUSER,
    input                           M_AXI_BVALID,
    output                          M_AXI_BREADY,
        
    // Master Read Address
    output      [0:0]               M_AXI_ARID,
    output      [31:0]              M_AXI_ARADDR,
    output      [7:0]               M_AXI_ARLEN,
    output      [2:0]               M_AXI_ARSIZE,
    output      [1:0]               M_AXI_ARBURST,
    output      [1:0]               M_AXI_ARLOCK,//
    output      [3:0]               M_AXI_ARCACHE,
    output      [2:0]               M_AXI_ARPROT,
    output      [3:0]               M_AXI_ARQOS,
    output      [0:0]               M_AXI_ARUSER,
    output                          M_AXI_ARVALID,
    input                           M_AXI_ARREADY,
        
    // Master Read Data 
    input       [0:0]               M_AXI_RID,
    input       [DATA_WIDTH-1:0]    M_AXI_RDATA,//
    input       [1:0]               M_AXI_RRESP,
    input                           M_AXI_RLAST,
    input       [0:0]               M_AXI_RUSER,
    input                           M_AXI_RVALID,
    output                          M_AXI_RREADY,

    // key
    input       [7:0]               key,
    //channel 0 write and read
    input                           ch0_wframe_pclk,
    input                           ch0_wframe_rst_n,
    input                           ch0_wframe_vsync,      
    input                           ch0_wframe_data_valid,
    input     [WRITE_DATA_BITS-1:0] ch0_wframe_data,
    input                           ch0_rframe_pclk,
    input                           ch0_rframe_rst_n,
    input                           ch0_rframe_vsync,
    input                           ch0_rframe_req,
    output                          ch0_rframe_req_ack,
    input                           ch0_rframe_data_en,
    output    [READ_DATA_BITS-1:0]  ch0_rframe_data,
    output                          ch0_rframe_data_valid,
    output                          ch0_read_line_full,
    //channel 1 write and read
    input                           ch1_wframe_pclk,
    input                           ch1_wframe_rst_n,
    input                           ch1_wframe_vsync,
    input                           ch1_wframe_data_valid,
    input     [WRITE_DATA_BITS-1:0] ch1_wframe_data,
    input                           ch1_rframe_pclk,
    input                           ch1_rframe_rst_n,
    input                           ch1_rframe_vsync,
    input                           ch1_rframe_req,
    output                          ch1_rframe_req_ack,
    input                           ch1_rframe_data_en,
    output    [READ_DATA_BITS-1:0]  ch1_rframe_data,
    output                          ch1_rframe_data_valid,
    output                          ch1_read_line_full,
    //channel 2 write and read
    input                           ch2_wframe_pclk,
    input                           ch2_wframe_rst_n,
    input                           ch2_wframe_vsync,
    input                           ch2_wframe_data_valid,
    input     [WRITE_DATA_BITS-1:0] ch2_wframe_data,
    input                           ch2_rframe_pclk,
    input                           ch2_rframe_rst_n,
    input                           ch2_rframe_vsync,
    input                           ch2_rframe_req,
    output                          ch2_rframe_req_ack,
    input                           ch2_rframe_data_en,
    output    [READ_DATA_BITS-1:0]  ch2_rframe_data,
    output                          ch2_rframe_data_valid,
    output                          ch2_read_line_full,
    //channel 3 write and read
    input                           ch3_wframe_pclk,
    input                           ch3_wframe_rst_n,
    input                           ch3_wframe_vsync,
    input                           ch3_wframe_data_valid,
    input     [WRITE_DATA_BITS-1:0] ch3_wframe_data,
    input                           ch3_rframe_pclk,
    input                           ch3_rframe_rst_n,
    input                           ch3_rframe_vsync,
    input                           ch3_rframe_req,
    output                          ch3_rframe_req_ack,
    input                           ch3_rframe_data_en,
    output    [READ_DATA_BITS-1:0]  ch3_rframe_data,
    output                          ch3_rframe_data_valid,
    output                          ch3_read_line_full     
);
endmodule
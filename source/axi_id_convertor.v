module axi_id_convertor#(
parameter IN_ID_WIDTH       = 10,
parameter OUT_ID_WIDTH      = 8
)(
input clk,
input rst_n,
input arvalid,
input arready,
input awvalid,
input awready,
input rvalid,
input rready,
input bvalid,
input bready,
input [IN_ID_WIDTH-1:0] arid,
input [IN_ID_WIDTH-1:0] awid,
input [OUT_ID_WIDTH-1:0] virt_rid,
input [OUT_ID_WIDTH-1:0] virt_bid,
output wire [OUT_ID_WIDTH-1:0] virt_arid,
output wire [OUT_ID_WIDTH-1:0] virt_awid,
output reg  [IN_ID_WIDTH-1:0] rid,
output reg  [IN_ID_WIDTH-1:0] bid
);
endmodule
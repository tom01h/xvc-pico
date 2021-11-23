module pmodIf (
    input  wire          M_AXI_ACLK,
    input  wire          M_AXI_ARESETN,

    output wire [31 : 0] M_AXI_AWADDR,
    output wire [7 : 0]  M_AXI_AWLEN,
    output wire [2 : 0]  M_AXI_AWSIZE,
    output wire [1 : 0]  M_AXI_AWBURST,
    output wire [2 : 0]  M_AXI_AWPROT,
    output wire          M_AXI_AWVALID,
    input  wire          M_AXI_AWREADY,

    output wire [63 : 0] M_AXI_WDATA,
    output wire [7 : 0]  M_AXI_WSTRB,
    output wire          M_AXI_WLAST,
    output wire          M_AXI_WVALID,
    input  wire          M_AXI_WREADY,

    input  wire          M_AXI_BVALID,
    output wire          M_AXI_BREADY,

    output wire [31 : 0] M_AXI_ARADDR,
    output wire [7 : 0]  M_AXI_ARLEN,
    output wire [2 : 0]  M_AXI_ARSIZE,
    output wire [1 : 0]  M_AXI_ARBURST,
    output wire [2 : 0]  M_AXI_ARPROT,
    output wire          M_AXI_ARVALID,
    input  wire          M_AXI_ARREADY,

    input  wire [63 : 0] M_AXI_RDATA,
    input  wire          M_AXI_RLAST,
    input  wire          M_AXI_RVALID,
    output wire          M_AXI_RREADY,

    input  wire          pck,
    input  wire          pwrite,
    input  wire [1:0]    pwd,
    output wire [1:0]    prd,
    output wire          pwait
);
   
   
    wire                 write_req;     // 64bit data valid
    wire                 write_bus_req; // all data valid
    wire                 read_req;      // next read data request
    wire                 read_bus_req;  // read address valid (generate bus request)

    wire [9 : 0]         len;
    wire [31 : 0]        address;
    wire [63 : 0]        wdata;
    wire [63 : 0]        rdata;

    pmodCmd pmodCmd (
        .clk(M_AXI_ACLK),
        .reset(~M_AXI_ARESETN),
        .pck(pck),
        .pwrite(pwrite),
        .pwd(pwd),
        .prd(prd),
        .pwait(pwait),

        .write_req(write_req),
        .write_bus_req(write_bus_req),
        .read_req(read_req),
        .read_bus_req(read_bus_req),
        .busy(busy),
        
        .len(len),
        .address(address),
        .wdata(wdata),
        .rdata(rdata)
    );

    budIf budIf (
        .M_AXI_ACLK(M_AXI_ACLK),
        .M_AXI_ARESETN(M_AXI_ARESETN),
        
        .M_AXI_AWADDR(M_AXI_AWADDR),
        .M_AXI_AWLEN(M_AXI_AWLEN),
        .M_AXI_AWSIZE(M_AXI_AWSIZE),
        .M_AXI_AWBURST(M_AXI_AWBURST),
        .M_AXI_AWPROT(M_AXI_AWPROT),
        .M_AXI_AWVALID(M_AXI_AWVALID),
        .M_AXI_AWREADY(M_AXI_AWREADY),
        
        .M_AXI_WDATA(M_AXI_WDATA),
        .M_AXI_WSTRB(M_AXI_WSTRB),
        .M_AXI_WLAST(M_AXI_WLAST),
        .M_AXI_WVALID(M_AXI_WVALID),
        .M_AXI_WREADY(M_AXI_WREADY),
        
        .M_AXI_BVALID(M_AXI_BVALID),
        .M_AXI_BREADY(M_AXI_BREADY),     

        .M_AXI_ARADDR(M_AXI_ARADDR),
        .M_AXI_ARLEN(M_AXI_ARLEN),
        .M_AXI_ARSIZE(M_AXI_ARSIZE),
        .M_AXI_ARBURST(M_AXI_ARBURST),
        .M_AXI_ARPROT(M_AXI_ARPROT),
        .M_AXI_ARVALID(M_AXI_ARVALID),
        .M_AXI_ARREADY(M_AXI_ARREADY),
        
        .M_AXI_RDATA(M_AXI_RDATA),
        .M_AXI_RLAST(M_AXI_RLAST),
        .M_AXI_RVALID(M_AXI_RVALID),
        .M_AXI_RREADY(M_AXI_RREADY),
        
        .write_req(write_req),
        .write_bus_req(write_bus_req),
        .read_req(read_req),
        .read_bus_req(read_bus_req),
        .busy(busy),
        
        .len(len),
        .address(address),
        .wdata(wdata),
        .rdata(rdata)
    );

endmodule
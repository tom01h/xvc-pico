module budIf (
    input  logic          M_AXI_ACLK,
    input  logic          M_AXI_ARESETN,

    output logic [31 : 0] M_AXI_AWADDR,
    output logic [7 : 0]  M_AXI_AWLEN,
    output logic [2 : 0]  M_AXI_AWSIZE,
    output logic [1 : 0]  M_AXI_AWBURST,
    output logic [2 : 0]  M_AXI_AWPROT,
    output logic          M_AXI_AWVALID,
    input  logic          M_AXI_AWREADY,

    output logic [63 : 0] M_AXI_WDATA,
    output logic [7 : 0]  M_AXI_WSTRB,
    output logic          M_AXI_WLAST,
    output logic          M_AXI_WVALID,
    input  logic          M_AXI_WREADY,

    input  logic          M_AXI_BVALID,
    output logic          M_AXI_BREADY,

    output logic [31 : 0] M_AXI_ARADDR,
    output logic [7 : 0]  M_AXI_ARLEN,
    output logic [2 : 0]  M_AXI_ARSIZE,
    output logic [1 : 0]  M_AXI_ARBURST,
    output logic [2 : 0]  M_AXI_ARPROT,
    output logic          M_AXI_ARVALID,
    input  logic          M_AXI_ARREADY,

    input  logic [63 : 0] M_AXI_RDATA,
    input  logic          M_AXI_RLAST,
    input  logic          M_AXI_RVALID,
    output logic          M_AXI_RREADY,

    input  logic          write_req,
    input  logic          write_bus_req,
    input  logic          read_req,
    input  logic          read_bus_req,
    output logic          busy,

    input  logic [9 : 0]  len, // 1:1, 2:2, 4:4, 6:8, 8n:8(n+1)
    input  logic [31 : 0] address,
    input  logic [63 : 0] wdata,
    output logic [63 : 0] rdata
);

    logic [63:0] data_buf [0:511];
    logic [63:0] rdata_w;
    logic [63:0] wdata_w;
    logic [8:0]  rptr;
    logic [8:0]  nrptr;
    logic [8:0]  wptr;

    logic        M_AXI_RREADYi;

    assign M_AXI_RREADY = (rptr != (wptr+1)) & M_AXI_RREADYi;
    assign nrptr = ((M_AXI_WVALID  & M_AXI_WREADY) | write_bus_req | read_req)? rptr+1 : rptr;
    always_ff @(posedge M_AXI_ACLK) begin
        if(~M_AXI_ARESETN) begin
            wptr <= 0;
        end else if(write_req | (M_AXI_RREADY & M_AXI_RVALID)) begin
            wptr <= wptr +1;
        end
    end
    assign wdata_w = (write_req) ? wdata : M_AXI_RDATA;
    always_ff @(posedge M_AXI_ACLK) begin
        if(write_req | (M_AXI_RREADY & M_AXI_RVALID)) begin
            data_buf[wptr] <= wdata_w;
        end
        rdata_w <= data_buf[nrptr];
    end

    assign M_AXI_AWBURST = 2'b01;
    assign M_AXI_AWPROT  = 3'b000;
    assign M_AXI_ARBURST = 2'b01;
    assign M_AXI_ARPROT  = 3'b000;

    assign M_AXI_BREADY  = 1'b1;

    assign busy = M_AXI_WVALID & ~M_AXI_WREADY |
                  ~(M_AXI_WVALID & ~M_AXI_WLAST) & M_AXI_AWVALID & ~M_AXI_AWREADY |
                  (M_AXI_RREADY & ~M_AXI_RVALID) & (rptr == wptr);

    logic [7 : 0]         wcnt;

    always_ff @(posedge M_AXI_ACLK) begin
        if(~M_AXI_ARESETN) begin
            rptr <= 0;
            M_AXI_ARVALID <= 1'b0;
            M_AXI_AWVALID <= 1'b0;
            M_AXI_WVALID  <= 1'b0;
            M_AXI_RREADYi <= 1'b0;
        end else if(read_bus_req) begin
            M_AXI_ARVALID <= 1'b1;
            M_AXI_ARADDR  <= {address[31:3],3'b0};
            M_AXI_RREADYi <= 1'b1;
            casez(len[2:0])
                3'b001: begin M_AXI_ARLEN <= 8'h00;    M_AXI_ARSIZE <= 3'b011; end
                3'b010: begin M_AXI_ARLEN <= 8'h00;    M_AXI_ARSIZE <= 3'b011; end
                3'b100: begin M_AXI_ARLEN <= 8'h00;    M_AXI_ARSIZE <= 3'b011; end
                3'b11?: begin M_AXI_ARLEN <= 8'h00;    M_AXI_ARSIZE <= 3'b011; end
                3'b000: begin M_AXI_ARLEN <= len[9:3]; M_AXI_ARSIZE <= 3'b011; end
            endcase
        end else if(write_bus_req) begin
            M_AXI_AWVALID <= 1'b1;
            M_AXI_AWADDR  <= {address[31:3],3'b0};
            M_AXI_WVALID  <= 1'b1;
            //if(len[9:3] == 0) M_AXI_WDATA   <= wdata;
            //else              M_AXI_WDATA   <= rdata_w;
            rptr <= nrptr;
            casez(len[2:0])
                3'b001: begin M_AXI_AWLEN <= 8'h00;    M_AXI_AWSIZE <= 3'b011; M_AXI_WLAST <= 1'b1; end
                3'b010: begin M_AXI_AWLEN <= 8'h00;    M_AXI_AWSIZE <= 3'b011; M_AXI_WLAST <= 1'b1; end
                3'b100: begin M_AXI_AWLEN <= 8'h00;    M_AXI_AWSIZE <= 3'b011; M_AXI_WLAST <= 1'b1; end
                3'b11?: begin M_AXI_AWLEN <= 8'h00;    M_AXI_AWSIZE <= 3'b011; M_AXI_WLAST <= 1'b1; end
                3'b000: begin M_AXI_AWLEN <= len[9:3]; M_AXI_AWSIZE <= 3'b011; M_AXI_WLAST <= 1'b0; end
            endcase
            wcnt <= len[9:3];
            casez(len[2:0])
                3'b001:  M_AXI_WSTRB <= (1'b1    << address[2:0]);
                3'b010:  M_AXI_WSTRB <= (2'b11   << address[2:0]);
                3'b100:  M_AXI_WSTRB <= (4'b1111 << address[2:0]);
                default: M_AXI_WSTRB <= 8'hff;
            endcase
        end else begin
            if(read_req) rptr <= nrptr;
            if(M_AXI_ARVALID & M_AXI_ARREADY) M_AXI_ARVALID <= 1'b0;
            if(M_AXI_RVALID  & M_AXI_RREADY)  M_AXI_RREADYi <= ~M_AXI_RLAST;
            if(M_AXI_AWVALID & M_AXI_AWREADY) M_AXI_AWVALID <= 1'b0;
            if(M_AXI_WVALID  & M_AXI_WREADY) begin
                if(~M_AXI_WLAST) begin
                    //if(nrptr == wptr) M_AXI_WDATA   <= wdata;
                    //else              M_AXI_WDATA   <= rdata_w;
                    rptr <= nrptr;
                end
                if(M_AXI_WLAST)       M_AXI_WVALID <= 1'b0;
                else if(wcnt == 8'b1) M_AXI_WLAST <= 1'b1;
                else                  wcnt <= wcnt - 1;
            end
        end
        if(M_AXI_WVALID  & M_AXI_WREADY) begin // 周波数対策
            if(nrptr == wptr) M_AXI_WDATA   <= wdata;
            else              M_AXI_WDATA   <= rdata_w;
        end else if(write_bus_req) begin
            if(len[9:3] == 0) M_AXI_WDATA   <= wdata;
            else              M_AXI_WDATA   <= rdata_w;
        end
        if(M_AXI_RVALID  & M_AXI_RREADY)begin
            if(wptr == rptr) rdata <= M_AXI_RDATA;
        end else if(read_req)begin
            rdata <= rdata_w;
        end    
    end

endmodule
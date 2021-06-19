
module reg_slice_group #(
    parameter type              PLD_TYPE        = logic     ,
    parameter integer unsigned  STAGE_NUM       = 1         ,
    parameter string            REG_SLICE_TYPE  = "FULL"    ,
    parameter logic             NO_DATA_RESET   = 1'b0
)(
    input           clk         ,
    input           rst_n       ,

    input  PLD_TYPE s_pld       ,
    input           s_vld       ,
    output          s_rdy       ,

    output PLD_TYPE m_pld       ,
    output          m_vld       ,
    input           m_rdy
);
    
    PLD_TYPE            l_pld [STAGE_NUM:0];
    logic [STAGE_NUM:0] l_vld;
    logic [STAGE_NUM:0] l_rdy;

    genvar i;
    generate

        assign l_pld[0] = s_pld;
        assign l_vld[0] = s_vld;
        assign s_rdy    = l_rdy[0];

        for(i=0;i<STAGE_NUM;i=i+1) begin:muti_rs
            basic_register_slice #(
                .REG_SLICE_TYPE  (REG_SLICE_TYPE    ),
                .PLD_TYPE        (PLD_TYPE          ),
                .NO_DATA_RESET   (NO_DATA_RESET     ))
            u_reg_slice
                .clk    (clk            ),
                .rst_n  (rst_n          ),
                .s_pld  (l_pld[i]       ),
                .s_vld  (l_vld[i]       ),
                .s_rdy  (l_rdy[i]       ),
                .m_pld  (l_pld[i+1]     ),
                .m_vld  (l_vld[i+1]     ),
                .m_rdy  (l_rdy[i+1]     )
            );
        end

        assign m_pld            = l_pld[STAGE_NUM];
        assign m_vld            = l_vld[STAGE_NUM];
        assign l_rdy[STAGE_NUM] = m_rdy;

    endgenerate

endmodule //reg_slice_group
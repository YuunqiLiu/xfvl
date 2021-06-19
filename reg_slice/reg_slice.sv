

module reg_slice #(
    parameter string REG_SLICE_TYPE = "FULL",   // PASS,SMPBUF,FORWARD,BACKWARD,FULL
    parameter type PLD_TYPE         = logic ,
    parameter logic NO_DATA_RESET   = 1'b0
)(
    input  logic    clk             ,
    input  logic    rst_n           ,

    input  PLD_TYPE s_pld           ,
    input  logic    s_vld           ,
    output logic    s_rdy           ,

    output PLD_TYPE m_pld           ,
    output logic    m_vld           ,
    input  logic    m_rdy         
);

    logic dat_rst_n;

    generate 
        if(NO_DATA_RESET == 1'b1)   dat_rst_n = 1'b1;
        else                        dat_rst_n = rst_n;
    endgenerate

    generate

    //Register Slice -- pass through
    if (REG_SLICE_TYPE == "PASS") begin:rs_pass

        assign m_pld = s_pld;
        assign m_vld = s_vld;
        assign s_rdy = m_rdy;

    end

    //Register Slice -- simple buf
    else if (REG_SLICE_TYPE == "SMPBUF") begin:rs_smp_buf

        logic rst_lock_n;

        always_ff @(posedge clk or negedge rst_n) begin
            if(~rst_n)      m_vld <= 1'b0;
            else if(m_rdy)  m_vld <= s_vld;
        end

        always_ff @(posedge clk or negedge dat_rst_n) begin
            if(~dat_rst_n)  m_pld <= {$bits(PLD_TYPE){1'b0}};
            else if(m_rdy)  m_pld <= s_pld;
        end

        always @(*) s_rdy = m_rdy && rst_lock_n;

        always_ff @(posedge clk or negedge rst_n) begin 
            if(~rst_n)  rst_lock_n <= 1'b0;
            else        rst_lock_n <= 1'b1;
        end
    end

    //Register Slice -- forward
    else if (REG_SLICE_TYPE == "FORWARD") begin:rs_forward

        logic rst_lock_n;

        always_ff @(posedge clk or negedge rst_n) begin
            if(~rst_n)      m_vld <= 1'b0;
            else if(m_rdy)  m_vld <= s_vld;
        end

        always_ff @(posedge clk or negedge dat_rst_n) begin
            if(~dat_rst_n)  m_pld <= {$bits(PLD_TYPE){1'b0}};
            else if(m_rdy)  m_pld <= s_pld;
        end

        assign s_rdy = ( m_rdy || (~m_vld) ) && rst_lock_n;

        always_ff @(posedge clk or negedge rst_n) begin
            if(~rst_n)  rst_lock_n <= 1'b0;
            else        rst_lock_n <= 1'b1;
        end
    end

    //Register Slice -- backward
    else if (REG_SLICE_TYPE =="BACKWARD") begin:rs_backward
        PLD_TYPE    buf_pld     ;
        logic       buf_vld     ;
        logic       load_en     ;
        logic       rst_lock_n  ;

        assign m_pld = buf_vld ? buf_pld : s_pld    ;
        assign m_vld = buf_vld || s_vld             ;
        assign s_rdy = (~buf_vld) && rst_lock_n     ;
        assign load_en = ~ m_rdy;


        always_ff @(posedge clk or negedge rst_n) begin
            if(~rst_n)      buf_vld <= 1'b0;
            else if(m_rdy)  buf_vld <= s_vld;
        end

        always_ff @(posedge clk or negedge dat_rst_n) begin
            if(~dat_rst_n)  buf_pld <= {$bits(PLD_TYPE){1'b0}};
            else if(m_rdy)  buf_pld <= s_pld;
        end

        always_ff @(posedge clk or negedge rst_n) begin
            if(~rst_n)  rst_lock_n <= 1'b0;
            else        rst_lock_n <= 1'b1;
        end           

    end

    //Register Slice -- full
    else if (REG_SLICE_TYPE == "FULL") begin:rs_full
        logic       wren_a      ;
        logic       wren_b      ;
        logic       rden_a      ;
        logic       rden_b      ;
        logic       wren        ;
        logic       rden        ;
        PLD_TYPE    buf_a_pld   ;
        PLD_TYPE    buf_b_pld   ;
        logic       wr_sel      ;
        logic       rd_sel      ;
        logic       buf_a_vld   ;
        logic       buf_b_vld   ;
        logic       rst_lock_n  ;

        assign wren = s_vld && s_rdy;
        assign rden = m_vld && m_rdy;

        assign wren_a = wren && (wr_sel);
        assign wren_b = wren && (~wr_sel);

        assign rden_a = rden && (rd_sel);
        assign rden_b = rden && (~rd_sel);

        assign s_rdy = ( (~buf_a_vld)||(~buf_b_vld) ) && rst_lock_n;
        assign m_vld = rd_sel ? buf_a_vld : buf_b_vld;
        assign m_pld = rd_sel ? buf_a_pld : buf_b_pld;

        always_ff @(posedge clk or negedge rst_n) begin
            if(~rst_n)      wr_sel <= 1'b0;
            else if(wren)   wr_sel <= ~wr_sel;
            else            wr_sel <= wr_sel;
        end

        always_ff @(posedge clk or negedge rst_n) begin
            if(~rst_n)      rd_sel <= 1'b0;
            else if(rden)   rd_sel <= ~rd_sel;
            else            rd_sel <= rd_sel;
        end

        always @(posedge clk or negedge dat_rst_n) begin
            if(~dat_rst_n)  buf_a_pld <= {$bits(PLD_TYPE){1'b0}};;
            else if(wren_a) buf_a_pld <= s_pld;
        end

        always @(posedge clk or negedge dat_rst_n) begin
            if(~dat_rst_n)  buf_b_pld <= {$bits(PLD_TYPE){1'b0}};;
            else if(wren_b) buf_b_pld <= s_pld;
        end

        always_ff @(posedge clk or negedge rst_n) begin
            if(~rst_n)      buf_a_vld <= 1'b0;
            else if(wren_a) buf_a_vld <= s_vld;
            else if(rden_a) buf_a_vld <= 1'b0;
        end

        always_ff @(posedge clk or negedge rst_n) begin
            if(~rst_n)      buf_b_vld <= 1'b0;
            else if(wren_b) buf_b_vld <= s_vld;
            else if(rden_b) buf_b_vld <= 1'b0;
        end

        always_ff @(posedge clk or negedge rst_n) begin
            if(~rst_n)  rst_lock_n <= 1'b0;
            else        rst_lock_n <= 1'b1;
        end        

    end

    endgenerate


endmodule
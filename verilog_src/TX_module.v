`timescale 1ns / 1ps
module TX_module(
input clk,rst,tx_start,
input wire [7:0] tx_data ,
output reg tx_busy,tx_out, tick=0
);
reg [3:0] indx_reg = 4'b0000;
integer count=0;
parameter idle = 2'b00,
          s1 = 2'b01,
          s2 = 2'b10,
          s3 = 2'b11;
reg [2:0] state = idle;           
integer cnt_reg=0;
always @(posedge clk ,posedge rst) begin 
   if (rst) begin 
       state <= idle; end
   else begin 
     case(state)
           idle : if(tx_start) state <= s1;
           
             s1 : if(cnt_reg == 2) state <= s2;
            
             s2 : if (indx_reg == 4'd8 && tick)  
                   state <= s3;
                   
             s3 : if (cnt_reg == 2) state <= idle;
        default : state <= idle; 
     endcase
    end    
end

//data 
always@(posedge tick)begin 
     if (state == s2 || state == idle) cnt_reg <= 0;
     else cnt_reg <= cnt_reg + 1;
     if (state == s2) begin
         if (indx_reg <= 4'd7)
             indx_reg <= indx_reg + 1 ; 
         else indx_reg <= 0;
      end
end

//clock that fits the system
always @(posedge clk,posedge rst) begin 
     if(rst) count <= 0;
     else begin 
     count <= count +1 ;
        if (count == 5208) begin 
               tick <= ~tick;
               count <= 0; end 
     end
end
always @(posedge clk) begin
  case (state)
    idle : begin tx_out <= 1; tx_busy <= 0; end
    s1 :   begin tx_out <= 0; tx_busy <= 1; end
    s2 :   begin if(indx_reg < 4'd8) begin tx_out <= tx_data[indx_reg]; tx_busy <= 1; end
                   else indx_reg <= 0;
                   end
    s3 :   begin tx_out <= 1; tx_busy <= 0; end
    default:   tx_out <= 1;
  endcase
end

endmodule

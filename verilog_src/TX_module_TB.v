`timescale 1ns / 1ps
module TX_module_TB();
reg [7:0] tx_data;
reg tx_start,rst,clk;
wire tx_out,tx_busy, tick;
reg [9:0] expected_bits ,act_bits;
integer i=0 ;
parameter usec = 1000;
parameter msec = 1000000;
reg checks = 0 ;
reg score_check=0;
reg done;
TX_module u(.tx_data(tx_data), .tx_start(tx_start), .rst(rst), .clk(clk), .tx_out(tx_out), .tx_busy(tx_busy), .tick(tick));

always #5 clk <= ~clk;

//DRIVER    
task driver_tx(input [7:0] data);
begin 
tx_data = data;
tx_start = 1;
#100;
tx_start = 0;
#(2*msec);
end
endtask

initial begin 
$display("========UART TX TEST starts==========="); 
clk=0; rst=1;tx_start =0; tx_data = 8'b01001101 ;
#(50*usec) ; rst = 0 ; #(10*usec); tx_start =1 ;#200; tx_start =0;#(100*usec);tx_start =1;#50;tx_start =0;#(1.5*msec);
driver_tx(8'h00);
driver_tx(8'hFF);
driver_tx(8'haa);
done = 1;
  #100;
$finish;
end

reg [256:0] txdata_cov=0;

always @(posedge tx_busy) begin
expected_bits = {1'b1 , tx_data , 1'b0} ;
checks <= 1;
score_check <= 0;
txdata_cov[tx_data] = 1;
$display ("--expected bits = %b ",expected_bits);
end

always@(posedge tick) begin 
  if (checks) begin
     for (i=0;i<10;i=i+1)begin
        @(posedge tick);
         act_bits[i]<= tx_out;
         if (tx_out != expected_bits[i]) 
           $display("ERROR!! at bit %0d: tx_out = %b , expected = %b", i, tx_out , expected_bits[i]);
          else 
           $display("CORRECT !OK at bit %0d: tx_out = %b, match expected = %b",i,tx_out, expected_bits[i]);
     end
  checks <= 0;
  score_check <= 1;
  
  end
end

//Score Board
always@(posedge score_check) begin 
   for (i=0;i<10;i=i+1) begin 
        if (act_bits[i] == expected_bits[i])  
             $display("Checking scoreboard : PASS!!");
          else $display("Checking scoreboard : FAIL!!"); 
   end
end
//assertion
always @(posedge score_check)begin 
   if(act_bits[0] !== 0) begin
       $display("ERROR! bit 0 is wrong");
       $stop;
       end
   if(act_bits[9] !== 1) begin
       $display("ERROR! bit 9 is wrong");
       $stop;
       end
end

//coverage
real cnt_cov=0;
always@(posedge done)begin
$display("====== COVERAGE REPORT ======");
for(i=0;i<256;i=i+1) begin 
    if(txdata_cov[i] == 1)begin
       cnt_cov = cnt_cov + 1; 
       $display("TX DATA value tested : %02x",i); end       
end
$display ("COVERAGE : %0d tested values and its %0.2f%%",cnt_cov, (cnt_cov/256)*100);
end




endmodule



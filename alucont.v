module alucont(aluop1,aluop0,f3,f2,f1,f0,gout,link_r,jalr,reg_31_r,jmor_mem,jump_mem);//Figure 4.12 
input aluop1,aluop0,f3,f2,f1,f0;
output [2:0] gout;
output link_r,jalr,reg_31_r,jmor_mem,jump_mem;
reg [2:0] gout;
always @(aluop1 or aluop0 or f3 or f2 or f1 or f0)
begin
if(~(aluop1|aluop0))  gout=3'b010; // 00 for add
if(~(aluop1)&aluop0)gout=3'b110;   // 01 for sub
if(aluop0&aluop1)gout=3'b000;	   // 11 for andi
if((aluop1)&(~aluop0))		   //10 for R type
begin
	if (~(f3|f2|f1|f0))gout=3'b010; 	//function code=0000,ALU control=010 (add)
	if (f1&f3&~(f2)&~(f0))gout=3'b111;	//function code=1010,ALU control=111 (set on less than)
	if (f1&~(f3)&~(f2)&~(f0))gout=3'b110;	//function code=0010,ALU control=110 (sub)
	if (f2&f0&~(f3)&~(f1))gout=3'b001;	//function code=0101,ALU control=001 (or & jmor)
	if (f2&~(f0)&~(f3)&~(f1))gout=3'b000;	//function code=0100,ALU control=000 (and)
	if (f3&~(f2)&~(f1)&(f0))gout=3'b011;	//function code=1001,ALU control=011  (jalr)
	if (~(f3)&(f2)&(f1)&~(f0))gout=3'b100;	//function code=0110,ALU control=100  (srlv)
end
end
assign link_r = ((aluop1)&(~aluop0)) & ( (f2&f0&~(f3)&~(f1)) | (f3&~(f2)&~(f1)&(f0)) );
assign reg_31_r = ((aluop1)&(~aluop0)) &  (f2&f0&~(f3)&~(f1));
assign jump_mem = ((aluop1)&(~aluop0)) & ( (f2&f0&~(f3)&~(f1)) | (f3&~(f2)&~(f1)&(f0)) );
assign jmor_mem = ((aluop1)&(~aluop0)) &  (f2&f0&~(f3)&~(f1));
assign jalr = 0;

endmodule

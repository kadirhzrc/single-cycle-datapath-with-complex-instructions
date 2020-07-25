module control(in,regdest,alusrc,memtoreg,regwrite,memread,memwrite,branch,aluop1,aluop2,jump,link,reg_31,b_invert,balv_s);
input [5:0] in;
output regdest,alusrc,memtoreg,regwrite,memread,memwrite,branch,aluop1,aluop2,jump,link,reg_31,b_invert,balv_s;
wire rformat,lw,sw,beq,andi,bneal,balv;

assign rformat=~|in;
assign lw=in[5]& (~in[4])&(~in[3])&(~in[2])&in[1]&in[0];
assign sw=in[5]& (~in[4])&in[3]&(~in[2])&in[1]&in[0];
assign beq=~in[5]& (~in[4])&(~in[3])&in[2]&(~in[1])&(~in[0]);
assign andi=(~in[5])& (~in[4])&(in[3])&in[2]&(~in[1])&(~in[0]);
assign bneal=in[5]& (~in[4])&(in[3])&in[2]&(~in[1])&(in[0]);
assign balv=in[5]& (~in[4])&(~in[3])&(~in[2])&(~in[1])&(in[0]);

assign regdest=rformat;
assign jump=0;
assign branch=beq|bneal|balv;
assign memread=lw;
assign memtoreg=lw;
assign aluop1=rformat|andi;
assign aluop2=beq|andi|bneal;
assign memwrite=sw;
assign alusrc=lw|sw|andi;
assign regwrite=rformat|lw|andi|bneal|balv;
assign link=bneal|balv;
assign reg_31=bneal|balv;
assign b_invert=bneal;
assign balv_s=balv;

endmodule

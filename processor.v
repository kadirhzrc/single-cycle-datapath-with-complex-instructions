module processor;
reg [31:0] pc; //32-bit prograom counter
reg clk; //clock
reg [7:0] datmem[0:31],mem[0:31]; //32-size data and instruction memory (8 bit(1 byte) for each location)
wire [31:0] 
dataa,	//Read data 1 output of Register File
datab,	//Read data 2 output of Register File
aluinput2,	//2nd input of ALU
memtoregOut,	//Output of mux with memtoreg signal
writeData,	//Data to write to register file
pcsrcOut,	//Output of mux with pcsrc signal
jumpOut,	//Output of mux with jump signal
next_pc,	//Next PC value
sum,		//ALU result
extad,		//Output of sign-extend unit
adder1out,	//Output of adder which adds PC and 4-add1
adder2out,	//Output of adder which adds PC+4 and 2 shifted sign-extend result-add2
sextad,		//Output of shift left 2 unit
jump_addr;	//Calculated jump address

wire [5:0] inst31_26;	//31-26 bits of instruction
wire [4:0] 
inst25_21,	//25-21 bits of instruction
inst20_16,	//20-16 bits of instruction
inst15_11,	//15-11 bits of instruction
writeReg,	//Write data input of Register File
reg31val,	//Value 31 in 5 bits
regdestOut;	//Output of mux with regdest signal

wire [25:0] inst25_0;	//25-0 bits of instruction

wire [15:0] inst15_0;	//15-0 bits of instruction

wire [27:0] s28_out;	//Sign extended bit for jump

wire [31:0] instruc,	//current instruction
dpack;	//Read data output of memory (data read from memory)

wire [2:0] gout;	//Output of ALU control unit

wire zout,	//Zero output of ALU
nout,		//1 if ALU result is negative
overflow,	//1 if there is an overflow in ALU
pcsrc,		//Output of AND gate with Branch and ZeroOut inputs
// Signals ending with Ch (check) are combination result of multiple signals
regdestCh,
reg31Ch,
memtoregCh,
linkCh,
zInvert,	// Inverse of zero output of ALU
bOut,		// Output of mux with b_invert signal
branchInput,	// Complementary 2nd input for branch signal
//Control signals
regdest,alusrc,memtoreg,regwrite,memread,memwrite,branch,aluop1,aluop0,jump,link,reg_31,b_invert,balv_s,link_r,jalr,reg_31_r,jmor_mem,jump_mem;

//32-size register file (32 bit(1 word) for each register)
reg [31:0] registerfile[0:31];

reg flag_registers[0:2];	// Status register holding flags

integer i;

// datamemory connections

always @(posedge clk)
//write data to memory
if (memwrite)
begin 
//sum stores address,datab stores the value to be written
datmem[sum[4:0]+3]=datab[7:0];
datmem[sum[4:0]+2]=datab[15:8];
datmem[sum[4:0]+1]=datab[23:16];
datmem[sum[4:0]]=datab[31:24];
end

//instruction memory
//4-byte instruction
 assign instruc={mem[pc[4:0]],mem[pc[4:0]+1],mem[pc[4:0]+2],mem[pc[4:0]+3]};
 assign inst31_26=instruc[31:26];
 assign inst25_21=instruc[25:21];
 assign inst20_16=instruc[20:16];
 assign inst15_11=instruc[15:11];
 assign inst15_0=instruc[15:0];
assign jump_addr={adder1out[31:28],s28_out[27:0]};

// registers

assign dataa=registerfile[inst25_21];//Read register 1
assign datab=registerfile[inst20_16];//Read register 2
always @(posedge clk)
 registerfile[writeReg]= regwrite ? writeData:registerfile[writeReg];//Write data to register

//read data from memory, sum stores address
assign dpack={datmem[sum[5:0]],datmem[sum[5:0]+1],datmem[sum[5:0]+2],datmem[sum[5:0]+3]};

//multiplexers
mult2_to_1_5  mult1(regdestOut, instruc[20:16],instruc[15:11],regdestCh);

mult2_to_1_5  mult2(writeReg, regdestOut,reg31val,reg31Ch);

mult2_to_1_32 mult3(aluinput2, datab,extad,alusrc);

mult2_to_1_32 mult4(memtoregOut, sum,dpack,memtoregCh);

mult2_to_1_32 mult5(writeData, memtoregOut,adder1out,linkCh);

mult2_to_1_1 mult6(bOut, zout,zInvert,b_invert);

mult2_to_1_1 mult7(branchInput, bOut,flag_registers[0],balv_s);

mult2_to_1_32 mult8(pcsrcOut, adder1out,adder2out,pcsrc);

mult2_to_1_32 mult9(jumpOut, pcsrcOut,jump_addr,jump);

mult2_to_1_32 mult10(next_pc, jumpOut,memtoregOut,jump_mem);

// load pc
always @(negedge clk)
begin
pc=next_pc;

// Status registers updated
flag_registers[0] = overflow;
flag_registers[2] = zout;
flag_registers[1] = nout;
end

// alu, adder and control logic connections

//ALU unit
alu32 alu1(sum,dataa,aluinput2,zout,gout,nout,overflow);

//adder which adds PC and 4
adder add1(pc,32'h4,adder1out);

//adder which adds PC+4 and 2 shifted sign-extend result
adder add2(adder1out,sextad,adder2out);

//Control unit
control cont(instruc[31:26],regdest,alusrc,memtoreg,regwrite,memread,memwrite,branch,
aluop1,aluop0,jump,link,reg_31,b_invert,balv_s);

//Sign extend unit
signext sext(instruc[15:0],extad);

//ALU control unit
alucont acont(aluop1,aluop0,instruc[3],instruc[2], instruc[1], instruc[0] ,gout,link_r,jalr,reg_31_r,jmor_mem,jump_mem);

//Shift-left 2 unit
shift shift2(sextad,extad);

// shifter for jump
shift_26 shift_26(s28_out,inst25_0);

//Combinational signals
assign pcsrc=branch & branchInput; 
assign regdestCh=regdest^jalr;
assign reg31val=5'b11111;
assign reg31Ch=reg_31|reg_31_r;
assign linkCh=link|link_r;
assign zInvert=(~zout);
assign memtoregCh=memtoreg|jmor_mem;

//initialize datamemory,instruction memory and registers
//read initial data from files given in hex
initial
begin
$readmemh("initDm.dat",datmem); //read Data Memory
$readmemh("initIM.dat",mem);//read Instruction Memory
$readmemh("initReg.dat",registerfile);//read Register File

	for(i=0; i<31; i=i+1)
	$display("Instruction Memory[%0d]= %h  ",i,mem[i],"Data Memory[%0d]= %h   ",i,datmem[i],
	"Register[%0d]= %h",i,registerfile[i]);
end

initial
begin
pc=0;
#400 $finish;
	
end
initial
begin
clk=0;
//40 time unit for each cycle
forever #20  clk=~clk;
end
initial 
begin
  $monitor($time,"PC %h",pc,"  SUM %h",sum,"   INST %h",instruc[31:0],
"   REGISTER %h %h %h %h ",registerfile[4],registerfile[5], registerfile[6],registerfile[1] );
end
endmodule


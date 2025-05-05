`define StallBus        8
`define IF12IF2_WD      32
`define IF22ID_WD       `IF12IF2_WD + 32
`define ID2EX_WD        32+32+32+`ALU_WD+`BRU_WD+`LSU_WD+`MUL_WD+`DIV_WD+4+1+5+32+32
`define EX2MEM1_WD      `LSU_WD+4+3+1+5+32+32+32
`define MEM12MEM2_WD    `EX2MEM1_WD+32
`define MEM22WB_WD      33
`define BYPASS_WD       1+5+32
`define ALU_WD          10
`define BRU_WD          8
`define LSU_WD          6
`define MUL_WD          4
`define DIV_WD          3
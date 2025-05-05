`include "define.vh"
module ctrl(
    input wire rst_n,
    input wire stallreq_id,
    input wire stallreq_ex,
    // input wire stallreq_outside,
    output reg [`StallBus-1:0] stall
);
    always @ (*) begin
        if (!rst_n) begin
            stall = `StallBus'b0;
        end
        // else if (stallreq_outside) begin
        //     stall = `StallBus'b11111111;
        // end
        else if (stallreq_id) begin
            stall = `StallBus'b00001111;
        end
        else if (stallreq_ex) begin
            stall = `StallBus'b00011111;
        end
        else begin
            stall = `StallBus'b0;
        end
    end
endmodule
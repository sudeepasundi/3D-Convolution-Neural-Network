module cnn_3d_max_pooling #(
    parameter CONV_SIZE = 4,      // Size of input from convolution
    parameter POOL_SIZE = 2,      // Pooling window size
    parameter NUM_FILTERS = 3    // Number of filters
    //parameter DATA_WIDTH = 16     // Data width for computations
)(
    input wire clk,
    input wire reset,
    input wire start,
    input wire signed [15:0] conv_result[(CONV_SIZE)*(CONV_SIZE)*(CONV_SIZE)*NUM_FILTERS-1:0], // Flattened convolution result
    output reg signed [15:0] pool_result[(CONV_SIZE/POOL_SIZE)*(CONV_SIZE/POOL_SIZE)*(CONV_SIZE/POOL_SIZE)*NUM_FILTERS-1:0], // Flattened pooling output
    output reg done           // Pooling done flag
);

    // Local parameters
    localparam RESULT_SIZE = CONV_SIZE / POOL_SIZE;
    localparam IDLE = 3'b000,
               LOAD = 3'b001,
               MAXPOOL = 3'b010,
               STORE = 3'b011,
               FINISH = 3'b100;

// Internal registers for FSM
reg [2:0] state, next_state;
reg signed [15:0] max_val;
reg [2:0] img_row, img_col, img_depth;
reg [1:0] pool_row, pool_col, pool_depth;
reg [15:0] pool_result_idx;
reg [1:0] filter_idx;
    


    // Helper function to get convolution result value
    function automatic signed [15:0] get_conv_value(
        input [2:0] filter,
        input [2:0] depth,
        input [2:0] row,
        input [2:0] col
    );
    begin
        get_conv_value = conv_result[
            filter * CONV_SIZE * CONV_SIZE * CONV_SIZE +
            depth * CONV_SIZE * CONV_SIZE +
            row * CONV_SIZE +
            col
        ];
    end
    endfunction

    // State transitions
always @(posedge clk or posedge reset) begin
    if (reset)
        state <= IDLE;
    else
        state <= next_state;
end

// Next state logic
always @(*) begin
    case (state)
        IDLE: begin
            next_state = !reset ? LOAD : IDLE;
        end
        
        LOAD: begin
            next_state = MAXPOOL;
        end
        
        MAXPOOL: begin
            if (pool_row == POOL_SIZE-1 && 
                pool_col == POOL_SIZE-1 && 
                pool_depth == POOL_SIZE-1)
                next_state = STORE;
            else
                next_state = MAXPOOL;
        end
        
        STORE: begin
            if (img_row == RESULT_SIZE-1 && 
                img_col == RESULT_SIZE-1 && 
                img_depth == RESULT_SIZE-1 && 
                filter_idx == NUM_FILTERS-1)
                next_state = FINISH;
            else
                next_state = LOAD;
        end
        
        FINISH: begin
            next_state = IDLE;
        end
        
        default: next_state = IDLE;
    endcase
end

// Output computation and control logic
always @(posedge clk or posedge reset) begin
    if (reset) begin
        // Reset all control signals
        img_row <= 3'b0;
        img_col <= 3'b0;
        img_depth <= 3'b0;
        pool_row <= 2'b0;
        pool_col <= 2'b0;
        pool_depth <= 2'b0;
        max_val <= 16'b0;
        pool_result_idx <= 16'b0;
        done <= 1'b0;
        filter_idx <= 2'b0;
    end 
    else begin
        case (state)
            IDLE: begin
                done <= 1'b0;
                img_row <= 3'b0;
                img_col <= 3'b0;
                img_depth <= 3'b0;
                pool_result_idx <= 16'b0;
                filter_idx <= 2'b0;
            end
            
            LOAD: begin
                max_val <= -32768; // Minimum 16-bit signed value
            end
            
            MAXPOOL: begin
                // 3D max pooling computation
                if (conv_result[(img_row * POOL_SIZE + pool_row) * CONV_SIZE * CONV_SIZE + 
                                (img_col * POOL_SIZE + pool_col) * CONV_SIZE + 
                                (img_depth * POOL_SIZE + pool_depth) + 
                                filter_idx * CONV_SIZE * CONV_SIZE * CONV_SIZE] > max_val) begin
                    max_val <= conv_result[(img_row * POOL_SIZE + pool_row) * CONV_SIZE * CONV_SIZE + 
                                           (img_col * POOL_SIZE + pool_col) * CONV_SIZE + 
                                           (img_depth * POOL_SIZE + pool_depth) + 
                                           filter_idx * CONV_SIZE * CONV_SIZE * CONV_SIZE];
                end
                
                // Increment pooling indices
                if (pool_col < POOL_SIZE - 1)
                    pool_col <= pool_col + 1'b1;
                else begin
                    pool_col <= 2'b0;
                    if (pool_row < POOL_SIZE - 1)
                        pool_row <= pool_row + 1'b1;
                    else begin
                        pool_row <= 2'b0;
                        if (pool_depth < POOL_SIZE - 1)
                            pool_depth <= pool_depth + 1'b1;
                        else
                            pool_depth <= 2'b0;
                    end
                end
            end
            
            STORE: begin
                // Store pooling result
                pool_result[pool_result_idx + filter_idx * RESULT_SIZE * RESULT_SIZE * RESULT_SIZE] <= max_val;
                pool_result_idx <= pool_result_idx + 1'b1;
                
                // Increment image indices
                if (img_col < RESULT_SIZE - 1)
                    img_col <= img_col + 1'b1;
                else begin
                    img_col <= 3'b0;
                    if (img_row < RESULT_SIZE - 1)
                        img_row <= img_row + 1'b1;
                    else begin
                        img_row <= 3'b0;
                        if (img_depth < RESULT_SIZE - 1)
                            img_depth <= img_depth + 1'b1;
                        else begin
                            img_depth <= 3'b0;
                            if (filter_idx < NUM_FILTERS - 1) begin
                                filter_idx <= filter_idx + 1'b1;
                                pool_result_idx <= 16'b0;
                            end
                        end
                    end
                end
            end
            
            FINISH: begin
                done <= 1'b1;
            end
        endcase
    end
end

endmodule

module cnn_3d_convolution #(
    parameter IMG_SIZE = 6,       // Input image size
    parameter FILT_SIZE = 3,      // Filter size
    parameter NUM_FILTERS = 3     // Number of filters
)(
    input wire clk,
    input wire reset,
    input wire start,             // Start signal for convolution
    output reg signed [15:0] conv_result [0:(IMG_SIZE-FILT_SIZE+1)*(IMG_SIZE-FILT_SIZE+1)*(IMG_SIZE-FILT_SIZE+1)*NUM_FILTERS-1],
    output reg done
);

    // Local parameters
    localparam RESULT_SIZE = IMG_SIZE - FILT_SIZE + 1;
    localparam IDLE = 3'b000,
               LOAD = 3'b001,
               COMPUTE = 3'b010,
               STORE = 3'b011,
               FINISH = 3'b100;

    // State and control signals
    reg [2:0] state, next_state;
    
    // Indexing registers for image traversal
    reg [2:0] img_depth, img_row, img_col;
    // Indexing registers for filter traversal
    reg [1:0] filt_depth, filt_row, filt_col;
    reg [1:0] filter_idx;
    
    // Computation registers
    reg signed [15:0] sum;
	 reg [15:0] result_idx;
    
    // Image and filter memory
    reg signed [7:0] img [0:IMG_SIZE*IMG_SIZE*IMG_SIZE-1];
    reg signed [7:0] filter [0:NUM_FILTERS*FILT_SIZE*FILT_SIZE*FILT_SIZE-1];

    // Load data from files
    initial begin
        $readmemh("C:/00/Verilog/Draft_3D/image_data.txt", img);
        $readmemh("C:/00/Verilog/Draft_3D/filter_data.txt", filter);
    end

// Helper function to get 3D image value
function automatic signed [7:0] get_img_value(
    input [2:0] depth,
    input [2:0] row, 
    input [2:0] col
);
begin
    return img[depth * IMG_SIZE * IMG_SIZE + row * IMG_SIZE + col];
end
endfunction

// Helper function to get 3D filter value
function automatic signed [7:0] get_filter_value(
    input [1:0] filter_idx_in,
    input [1:0] depth,
    input [1:0] row, 
    input [1:0] col
);
begin
    return filter[filter_idx_in * FILT_SIZE * FILT_SIZE * FILT_SIZE + 
                  depth * FILT_SIZE * FILT_SIZE + 
                  row * FILT_SIZE + 
                  col];
end
endfunction	

    // State transition logic
    always @(posedge clk or posedge reset) begin
        if (reset)
            state <= IDLE;
        else
            state <= next_state;
    end

    // Next state logic
    always @(*) begin
        case (state)
            IDLE: next_state = start ? LOAD : IDLE;
            LOAD: next_state = COMPUTE;
            COMPUTE: begin
                if (filt_col == FILT_SIZE-1 && filt_row == FILT_SIZE-1 && filt_depth == FILT_SIZE-1)
                    next_state = STORE;
                else
                    next_state = COMPUTE;
            end
            STORE: begin
                if (img_col == RESULT_SIZE-1 && img_row == RESULT_SIZE-1 && 
                    img_depth == RESULT_SIZE-1 && filter_idx == NUM_FILTERS-1)
                    next_state = FINISH;
                else
                    next_state = LOAD;
            end
            FINISH: next_state = IDLE;
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
        filt_row <= 2'b0;
        filt_col <= 2'b0;
        filt_depth <= 2'b0;
        sum <= 16'b0;
        result_idx <= 16'b0;
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
                result_idx <= 16'b0;
                filter_idx <= 2'b0;
            end
            
            LOAD: begin
                sum <= 16'b0;
            end
            
            COMPUTE: begin
                // 3D convolution computation
                sum <= sum + 
                    get_img_value(img_depth + filt_depth, img_row + filt_row, img_col + filt_col) * 
                    get_filter_value(filter_idx, filt_depth, filt_row, filt_col);
                
                // Increment filter indices
                if (filt_col < FILT_SIZE - 1)
                    filt_col <= filt_col + 1'b1;
                else begin
                    filt_col <= 2'b0;
                    if (filt_row < FILT_SIZE - 1)
                        filt_row <= filt_row + 1'b1;
                    else begin
                        filt_row <= 2'b0;
                        if (filt_depth < FILT_SIZE - 1)
                            filt_depth <= filt_depth + 1'b1;
                        else
                            filt_depth <= 2'b0;
                    end
                end
            end
            
            STORE: begin
                // Store convolution result
                conv_result[filter_idx * RESULT_SIZE * RESULT_SIZE * RESULT_SIZE + 
                       img_depth * RESULT_SIZE * RESULT_SIZE + 
                       img_row * RESULT_SIZE + 
                       img_col] <= sum;
                
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
                                result_idx <= 16'b0;
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

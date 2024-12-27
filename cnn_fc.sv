module cnn_fc #(
    parameter NUM_INPUTS = 24,    // Number of inputs (pooling results)
    parameter NUM_OUTPUTS = 2     // Changed to 2 outputs
)(
    input wire clk, Done,         // Clock signal
    input wire reset,             // Reset signal
    input reg signed [15:0] pool_result [0:NUM_INPUTS - 1],
    output reg signed [15:0] fc_result [0:NUM_OUTPUTS - 1],  // Fully connected output RAM
    output reg done               // Computation complete flag
);

    // Internal RAM for weights and constants
    reg signed [15:0] weights [0:(NUM_INPUTS * 4) - 1];  // Weights for 4 original outputs
    reg signed [15:0] constants [0:3];  // Constants for multiplication

    // Internal registers
    reg signed [31:0] sum [0:3]; // Temporary sum for 4 original outputs
    reg signed [31:0] constant_sum [0:1]; // Sums after constant multiplication
    integer i, j; // Loop variables

    // Load weights and constants from files
    initial begin
        // Load original weights
        $readmemb("C:/00/Verilog/Draft_3D/fc_weights.txt", weights);
        
        // Load constants from a new file
        $readmemb("C:/00/Verilog/Draft_3D/fc_weights2.txt", constants);
    end

    // FSM for computation
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            // Reset all accumulators and outputs
            for (i = 0; i < NUM_OUTPUTS; i = i + 1) begin
                fc_result[i] <= 0;
            end
            done <= 0;
        end 
        else if(Done) begin
            // Compute weighted sums for 4 original outputs
            for (j = 0; j < 4; j = j + 1) begin
                sum[j] = 0; // Reset the accumulator
                for (i = 0; i < NUM_INPUTS; i = i + 1) begin
                    sum[j] = sum[j] + (pool_result[i] * weights[j * NUM_INPUTS + i]);
                end
            end

            // Multiply each of the 4 outputs with corresponding constants
            // First output of 2x1 matrix
            constant_sum[0] = 
                sum[0] * constants[0] + 
                sum[1] * constants[1] + 
                sum[2] * constants[2] + 
                sum[3] * constants[3];

            // Second output of 2x1 matrix (can use different constant multiplication if needed)
            constant_sum[1] = 
                sum[0] * constants[0] + 
                sum[1] * constants[1] + 
                sum[2] * constants[2] + 
                sum[3] * constants[3];

            // Truncate to 16 bits
            fc_result[0] <= constant_sum[0][15:0];
            fc_result[1] <= constant_sum[1][15:0];

            // Set the done flag
            done <= 1;
        end
    end
endmodule

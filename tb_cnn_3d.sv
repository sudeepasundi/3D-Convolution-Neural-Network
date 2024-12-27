module tb_cnn_3d;

    // Inputs and Outputs
    reg clk, reset, start;
    wire done;
    wire signed [15:0] final_output [0:1];  // Assuming FC_OUTPUTS = 2

    // Internal wires for debugging
    wire signed [15:0] conv_result [(6-3+1)*(6-3+1)*(6-3+1)*3-1:0];  // Change size for NUM_FILTERS=3
    wire signed [15:0] pool_result [(2*2*2)*3-1:0];  // Assuming pooled size 2x2x2 per filter

    // Instantiate the top module
    cnn_3d_top #(
        .IMG_SIZE(6),
        .FILT_SIZE(3),
        .POOL_SIZE(2),
        .NUM_FILTERS(3),
        .FC_OUTPUTS(2)
        //.DATA_WIDTH(16)
    ) dut (
        .clk(clk),
        .reset(reset),
        .start(start),
        .final_output(final_output),
        .done(done)
    );

    assign conv_result = dut.conv_result;
    assign pool_result = dut.pool_result;

    // Clock generation
    always #5 clk = ~clk;  // 10ns clock period (100 MHz)

    // Test Procedure
    initial begin
        integer i, j, k;

        // Initialize inputs
        clk = 0;
        reset = 1;
        start = 0;

        // Apply reset
        #10 reset = 0;

        // Start the process
        #10 start = 1;

        // Wait for the pipeline to complete
        wait(done);

        // Display results

        // Display Convolution Results
        $display("Convolution Results:");
        for (i = 0; i < (6-3+1); i = i + 1) begin
            for (j = 0; j < (6-3+1); j = j + 1) begin
                for (k = 0; k < (6-3+1); k = k + 1) begin
                    $display("Conv[Depth=%0d, Row=%0d, Col=%0d] = %0d", 
                        k, j, i, conv_result[k*(6-3+1)*(6-3+1) + j*(6-3+1) + i]);
                end
            end
        end

        // Display Pooling Results
        $display("\nPooling Results:");
        for (i = 0; i < 3; i = i + 1) begin  // For each filter
            $display("Filter %0d:", i);
            for (j = 0; j < 2; j = j + 1) begin  // Pooling dimensions
                for (k = 0; k < 2; k = k + 1) begin
                    $display("Pool[Row=%0d, Col=%0d] = %0d", j, k, 
                        pool_result[i*8 + j*2 + k]);  // Adjust based on pooling indexing
                end
            end
        end

        // Display Final Fully Connected Layer Outputs
        $display("\nFinal Fully Connected Outputs:");
        for (i = 0; i < 2; i = i + 1) begin
            $display("Output[%0d] = %0d", i, final_output[i]);
        end

        $finish;
    end

endmodule


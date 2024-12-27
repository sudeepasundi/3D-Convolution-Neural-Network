module cnn_3d_top #(
    parameter IMG_SIZE = 6,           // Input image size
    parameter FILT_SIZE = 3,          // Convolution filter size
    parameter POOL_SIZE = 2,          // Pooling window size
    parameter NUM_FILTERS = 3,        // Number of convolution filters
    parameter FC_OUTPUTS = 2         // Fully connected layer outputs
    //parameter DATA_WIDTH = 16         // Data width for computations
)(
    input wire clk,
    input wire reset,
    input wire start,
    output reg signed [0:15] final_output [0:FC_OUTPUTS-1],
    output wire done
);

    // Derived parameters
    localparam CONV_RESULT_SIZE = IMG_SIZE - FILT_SIZE + 1;
    localparam POOL_RESULT_SIZE = CONV_RESULT_SIZE / POOL_SIZE;
    localparam NUM_POOL_RESULTS = NUM_FILTERS * POOL_RESULT_SIZE * POOL_RESULT_SIZE * POOL_RESULT_SIZE;

    // Internal connection registers (changed to reg signed)
    reg signed [0:15] conv_result [0:(CONV_RESULT_SIZE)*(CONV_RESULT_SIZE)*(CONV_RESULT_SIZE)*NUM_FILTERS-1];
    reg signed [0:15] pool_result [0:NUM_POOL_RESULTS-1];
    reg signed [0:15] fc_internal_output [0:FC_OUTPUTS-1];

    // Control signals for inter-module synchronization
    reg start_conv, start_pool, start_fc;

    // State machine for pipeline control
    reg signed [2:0] current_state, next_state;

    // State definitions
    localparam IDLE     = 3'b000,
               CONV_STAGE = 3'b001,
               POOL_STAGE = 3'b010,
               FC_STAGE   = 3'b011,
               COMPLETE   = 3'b100;

    // Internal done signals
    wire conv_done, pool_done, fc_done;

    // Convolution Module
    cnn_3d_convolution #(
        .IMG_SIZE(IMG_SIZE),
        .FILT_SIZE(FILT_SIZE),
        .NUM_FILTERS(NUM_FILTERS)
        //.DATA_WIDTH(DATA_WIDTH)
    ) conv_unit (
        .clk(clk),
        .reset(reset),
        .start(start_conv),
        .conv_result(conv_result),
        .done(conv_done)
    );

    // Max Pooling Module
    cnn_3d_max_pooling #(
        .CONV_SIZE(CONV_RESULT_SIZE),
        .POOL_SIZE(POOL_SIZE),
        .NUM_FILTERS(NUM_FILTERS)
        //.DATA_WIDTH(DATA_WIDTH)
    ) pool_unit (
        .clk(clk),
        .reset(reset),
        .start(start_pool),
        .conv_result(conv_result),
        .pool_result(pool_result),
        .done(pool_done)
    );

    // Fully Connected Module
    cnn_fc #(
        .NUM_INPUTS(NUM_POOL_RESULTS),
        .NUM_OUTPUTS(FC_OUTPUTS)
        //.DATA_WIDTH(DATA_WIDTH)
    ) fc_unit (
        .clk(clk),
        .reset(reset),
       // .start(start_fc),
        .pool_result(pool_result),
        .fc_result(fc_internal_output),
        .done(fc_done),
		  .Done(pool_done)
    );

    // State Transition Logic
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            current_state <= IDLE;
            start_conv <= 0;
            start_pool <= 0;
            start_fc <= 0;
            
            // Initialize final_output with zeros
            for (integer i = 0; i < FC_OUTPUTS; i = i + 1) begin
                final_output[i] <= 0;
            end
        end else begin
            current_state <= next_state;

            // Control signals management
            case(current_state)
                IDLE: begin
                    if (start) start_conv <= 1;
                end
                CONV_STAGE: begin
                    if (conv_done) begin
                        start_conv <= 0;
                        start_pool <= 1;
                    end
                end
                POOL_STAGE: begin
                    if (pool_done) begin
                        start_pool <= 0;
                        start_fc <= 1;
                    end
                end
                FC_STAGE: begin
                    if (fc_done) begin
                        start_fc <= 0;
                        // Copy fc_internal_output to final_output
                        for (integer j = 0; j < FC_OUTPUTS; j = j + 1) begin
                            final_output[j] <= fc_internal_output[j];
                        end
                    end
                end
            endcase
        end
    end

    // Next State Logic
    always @(*) begin
        case(current_state)
            IDLE:       next_state = start ? CONV_STAGE : IDLE;
            CONV_STAGE: next_state = conv_done ? POOL_STAGE : CONV_STAGE;
            POOL_STAGE: next_state = pool_done ? FC_STAGE : POOL_STAGE;
            FC_STAGE:   next_state = fc_done ? COMPLETE : FC_STAGE;
            COMPLETE:   next_state = IDLE;
            default:    next_state = IDLE;
        endcase
    end


endmodule





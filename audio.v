
module audio (
	// input
    CLOCK_50,
    AUD_ADCDAT,
    ball_hit,  // New input for ball-paddle collision

    // Bidirectionals
    AUD_BCLK,
    AUD_ADCLRCK,
    AUD_DACLRCK,
    FPGA_I2C_SDAT,

    // Outputs
    AUD_XCK,
    AUD_DACDAT,
    FPGA_I2C_SCLK
);

/*****************************************************************************
 *                           Parameter Declarations                          *
 *****************************************************************************/


/*****************************************************************************
 *                             Port Declarations                             *
 *****************************************************************************/
// Inputs
input               CLOCK_50;
input               AUD_ADCDAT;
input               ball_hit;  // Trigger for sound
// Bidirectionals
inout				AUD_BCLK;
inout				AUD_ADCLRCK;
inout				AUD_DACLRCK;

inout				FPGA_I2C_SDAT;

// Outputs
output				AUD_XCK;
output				AUD_DACDAT;

output				FPGA_I2C_SCLK;

/*****************************************************************************
 *                 Internal Wires and Registers Declarations                 *
 *****************************************************************************/
// Internal Wires
wire				audio_in_available;
wire		[31:0]	left_channel_audio_in;
wire		[31:0]	right_channel_audio_in;
wire				read_audio_in;

wire				audio_out_allowed;
wire		[31:0]	left_channel_audio_out;
wire		[31:0]	right_channel_audio_out;
wire				write_audio_out;

// Internal Registers

reg [18:0] delay_cnt;
wire [18:0] delay;
reg [31:0] timer;
wire       play_sound;
reg snd;

// State Machine Registers

/*****************************************************************************
 *                         Finite State Machine(s)                           *
 *****************************************************************************/


/*****************************************************************************
 *                             Sequential Logic                              *
 *****************************************************************************/

always @(posedge CLOCK_50)
begin
    if (ball_hit && timer == 0)
        timer <= 32'd50_000_000; // 1 second at 50 MHz clock
    else if (timer > 0)
        timer <= timer - 1;
end

assign play_sound = (timer > 0);

/*****************************************************************************
 *                            Combinational Logic                            *
 *****************************************************************************/

assign delay = 19'd69420;

wire [31:0] sound = play_sound ? 32'd10000000 : 0;


assign read_audio_in			= audio_in_available & audio_out_allowed;

assign left_channel_audio_out	= left_channel_audio_in+sound;
assign right_channel_audio_out	= right_channel_audio_in+sound;
assign write_audio_out			= audio_in_available & audio_out_allowed;

/*****************************************************************************
 *                              Internal Modules                             *
 *****************************************************************************/

// Internal reset logic
reg reset;
always @(posedge CLOCK_50)
begin
    reset <= 1'b0; // Auto-reset on power-up, remains low thereafter
end

Audio_Controller Audio_Controller (
    // Inputs
    .CLOCK_50                  (CLOCK_50),
    .reset                     (reset), // Updated reset signal

    .clear_audio_in_memory     (),
    .read_audio_in             (read_audio_in),
    
    .clear_audio_out_memory    (),
    .left_channel_audio_out    (left_channel_audio_out),
    .right_channel_audio_out   (right_channel_audio_out),
    .write_audio_out           (write_audio_out),

    .AUD_ADCDAT                (AUD_ADCDAT),

    // Bidirectionals
    .AUD_BCLK                  (AUD_BCLK),
    .AUD_ADCLRCK               (AUD_ADCLRCK),
    .AUD_DACLRCK               (AUD_DACLRCK),

    // Outputs
    .audio_in_available        (audio_in_available),
    .left_channel_audio_in     (left_channel_audio_in),
    .right_channel_audio_in    (right_channel_audio_in),

    .audio_out_allowed         (audio_out_allowed),

    .AUD_XCK                   (AUD_XCK),
    .AUD_DACDAT                (AUD_DACDAT)
);

avconf #(.USE_MIC_INPUT(1)) avc (
    .FPGA_I2C_SCLK             (FPGA_I2C_SCLK),
    .FPGA_I2C_SDAT             (FPGA_I2C_SDAT),
    .CLOCK_50                  (CLOCK_50),
    .reset                     (reset) // Updated reset signal
);

endmodule


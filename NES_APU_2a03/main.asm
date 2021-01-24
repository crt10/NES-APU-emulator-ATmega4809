;
; NES_APU_2a03.asm
;
; Created: 11/29/2020 1:44:10 AM
; Author : Tennyson Cheng
;

.nolist
.include "m4809def.inc"
.list

.dseg
pulse1_param: .byte 1 //$4000 DDlc.vvvv = Duty cycle, Length counter halt/Loop flag, Constant volume flag, Volume
pulse1_sweep_param: .byte 1 //$4001 EPPP.NSSS = Enable, Period, Negate, Shift
//NOTE: In order to account for multiplier, we use 16 instead of 11 bits for the timer
pulse1_timerL: .byte 1 //$4002 LLLL.LLLL = Low 8 bits for timer
pulse1_timerH: .byte 1 //$4002 HHHH.HHHH = High 8 bits for timer
pulse1_length: .byte 1 //$4003 000l.llll = Length counter load
pulse1_fractional_volume: .byte 1 //used with the Axy effect to calculate volume. represents the VVVV bits in $4000, but with fractional data in bits 0 to 3.
pulse1_output_volume: .byte 1 //this is the final output volume of pulse 1
pulse1_note: .byte 1 //the current note index in the note table

pulse2_param: .byte 1 //$4004 DDlc.vvvv = Duty cycle, Length counter halt/Loop flag, Constant volume flag, Volume
pulse2_sweep_param: .byte 1 //$4005 EPPP.NSSS = Enable, Period, Negate, Shift
pulse2_timerL: .byte 1 //$4006 LLLL.LLLL = Low 8 bits for timer
pulse2_timerH: .byte 1 //$4006 HHHH.HHHH = High 8 bits for timer
pulse2_length: .byte 1 //$4007 000l.llll = Length counter load
pulse2_fractional_volume: .byte 1 //used with the Axy effect to calculate volume. represents the VVVV bits in $4000, but with fractional data in bits 0 to 3.
pulse2_output_volume: .byte 1 //this is the final output volume of pulse 2
pulse2_note: .byte 1 //the current note index in the note table

triangle_timerL: .byte 1 //$400A LLLL.LLLL = Low 8 bits for timer
triangle_timerH: .byte 1 //$400A HHHH.HHHH = High 8 bits for time
triangle_note: .byte 1 //the current note index in the note table

noise_param: .byte 1 //$400C 00lc.vvvv = Length counter halt/Loop flag, Constant volume flag, Volume
noise_period: .byte 1 //$400E M000.PPPP = Mode, Period
noise_fractional_volume: .byte 1 //used with the Axy effect to calculate volume. represents the VVVV bits in $4000, but with fractional data in bits 0 to 3.
noise_output_volume: .byte 1 //this is the final output volume of pulse 2
noise_note: .byte 1 //the current note index in the period table

song_frames: .byte 2
song_frame_offset: .byte 2
song_size: .byte 2
song_speed: .byte 1
//song_channel_delay_reload: .byte 1 //bit 0-4 represents channels 0-4. a set bit means that there is a delay that needs to be calculated for that channel.
song_fx_Bxx: .byte 1
song_fx_Cxx: .byte 1
song_fx_Dxx: .byte 1

//PULSE 1
pulse1_pattern: .byte 2
pulse1_pattern_delay_rows: .byte 1
pulse1_pattern_delay_frames: .byte 1
pulse1_pattern_offset: .byte 2

pulse1_volume_macro: .byte 2
pulse1_volume_macro_offset: .byte 1
pulse1_volume_macro_loop: .byte 1
pulse1_volume_macro_release: .byte 1

pulse1_arpeggio_macro: .byte 2
pulse1_arpeggio_macro_offset: .byte 1
pulse1_arpeggio_macro_loop: .byte 1
pulse1_arpeggio_macro_release: .byte 1
pulse1_arpeggio_macro_mode: .byte 1

pulse1_total_pitch_offset: .byte 2 //used to reference the overall change in pitch for the pitch macro
pulse1_pitch_macro: .byte 2
pulse1_pitch_macro_offset: .byte 1
pulse1_pitch_macro_loop: .byte 1
pulse1_pitch_macro_release: .byte 1

pulse1_total_hi_pitch_offset: .byte 1 //used to reference the overall change in pitch for the hi pitch macro
pulse1_hi_pitch_macro: .byte 2
pulse1_hi_pitch_macro_offset: .byte 1
pulse1_hi_pitch_macro_loop: .byte 1
pulse1_hi_pitch_macro_release: .byte 1

pulse1_duty_macro: .byte 2
pulse1_duty_macro_offset: .byte 1
pulse1_duty_macro_loop: .byte 1
pulse1_duty_macro_release: .byte 1

pulse1_fx_0xy_sequence: .byte 2 //arpeggio sequence in the order of 00:xy. xy are from the parameters in 0xy
pulse1_fx_1xx: .byte 2 //refers to the rate in which to subtract the pitch from by the 1xx
pulse1_fx_1xx_total: .byte 2 //the total pitch offset for 1xx
pulse1_fx_2xx: .byte 2 //refers to the rate in which to add to the pitch by the 2xx
pulse1_fx_2xx_total: .byte 2 //the total pitch offset for 2xx
pulse1_fx_3xx_start: .byte 2 //the starting note period
pulse1_fx_3xx_target: .byte 2 //target note period
pulse1_fx_3xx_speed: .byte 2 //the amount to offset by to get to the target
pulse1_fx_3xx_total_offset: .byte 2
pulse1_fx_4xy_speed: .byte 1
pulse1_fx_4xy_depth: .byte 1
pulse1_fx_4xy_phase: .byte 1
pulse1_fx_7xy_speed: .byte 1
pulse1_fx_7xy_depth: .byte 1
pulse1_fx_7xy_phase: .byte 1
pulse1_fx_7xy_value: .byte 1 //value to offset the volume
pulse1_fx_Axy: .byte 1 //refers to the decay/addition in volume set by the Axy effect NOTE: this value is a signed fractional byte, with the decimal between bits 3 and 4.
pulse1_fx_Gxx_pre: .byte 1 //holds the # of NES frames to wait before executing the current row
pulse1_fx_Gxx_post: .byte 1 //holds the # of NES frames to add to the delay before going to the next famitracker row NOTE: Gxx is limited to delay up till the end of the row it was called on
pulse1_fx_Pxx_total: .byte 2 //refers to the fine pitch offset set by the Pxx effect
pulse1_fx_Qxy_target_note: .byte 1 //target note index
pulse1_fx_Qxy_target: .byte 2 //target note period
pulse1_fx_Qxy_speed: .byte 2 //the amount to offset by to get to the target
pulse1_fx_Qxy_total_offset: .byte 2 //NOTE: due to the way the sound driver is setup, we need to keep track of the total pitch offset
pulse1_fx_Rxy_target_note: .byte 1 //target note index
pulse1_fx_Rxy_target: .byte 2 //target note period
pulse1_fx_Rxy_speed: .byte 2 //the amount to offset by to get to the target
pulse1_fx_Rxy_total_offset: .byte 2
pulse1_fx_Sxx_pre: .byte 1 //NOTE: Gxx and Sxx can not both be in effect at the same time. Sxx has priority.
pulse1_fx_Sxx_post: .byte 1

//PULSE 2
pulse2_pattern: .byte 2
pulse2_pattern_delay_rows: .byte 1
pulse2_pattern_delay_frames: .byte 1
pulse2_pattern_offset: .byte 2

pulse2_volume_macro: .byte 2
pulse2_volume_macro_offset: .byte 1
pulse2_volume_macro_loop: .byte 1
pulse2_volume_macro_release: .byte 1

pulse2_arpeggio_macro: .byte 2
pulse2_arpeggio_macro_offset: .byte 1
pulse2_arpeggio_macro_loop: .byte 1
pulse2_arpeggio_macro_release: .byte 1
pulse2_arpeggio_macro_mode: .byte 1

pulse2_total_pitch_offset: .byte 2 //used to reference the overall change in pitch for the pitch macro
pulse2_pitch_macro: .byte 2
pulse2_pitch_macro_offset: .byte 1
pulse2_pitch_macro_loop: .byte 1
pulse2_pitch_macro_release: .byte 1

pulse2_total_hi_pitch_offset: .byte 1 //used to reference the overall change in pitch for the hi pitch macro
pulse2_hi_pitch_macro: .byte 2
pulse2_hi_pitch_macro_offset: .byte 1
pulse2_hi_pitch_macro_loop: .byte 1
pulse2_hi_pitch_macro_release: .byte 1

pulse2_duty_macro: .byte 2
pulse2_duty_macro_offset: .byte 1
pulse2_duty_macro_loop: .byte 1
pulse2_duty_macro_release: .byte 1

pulse2_fx_0xy_sequence: .byte 2 //arpeggio sequence in the order of 00:xy. xy are from the parameters in 0xy
pulse2_fx_1xx: .byte 2 //refers to the rate in which to subtract the pitch from by the 1xx
pulse2_fx_1xx_total: .byte 2 //the total pitch offset for 1xx
pulse2_fx_2xx: .byte 2 //refers to the rate in which to add to the pitch by the 2xx
pulse2_fx_2xx_total: .byte 2 //the total pitch offset for 2xx
pulse2_fx_3xx_start: .byte 2 //the starting note period
pulse2_fx_3xx_target: .byte 2 //target note period
pulse2_fx_3xx_speed: .byte 2 //the amount to offset by to get to the target
pulse2_fx_3xx_total_offset: .byte 2
pulse2_fx_4xy_speed: .byte 1
pulse2_fx_4xy_depth: .byte 1
pulse2_fx_4xy_phase: .byte 1
pulse2_fx_7xy_speed: .byte 1
pulse2_fx_7xy_depth: .byte 1
pulse2_fx_7xy_phase: .byte 1
pulse2_fx_7xy_value: .byte 1 //value to offset the volume
pulse2_fx_Axy: .byte 1 //refers to the decay/addition in volume set by the Axy effect NOTE: this value is a signed fractional byte, with the decimal between bits 3 and 4.
pulse2_fx_Gxx_pre: .byte 1 //holds the # of NES frames to wait before executing the current row
pulse2_fx_Gxx_post: .byte 1 //holds the # of NES frames to add to the delay before going to the next famitracker row NOTE: Gxx is limited to delay up till the end of the row it was called on
pulse2_fx_Pxx_total: .byte 2 //refers to the fine pitch offset set by the Pxx effect
pulse2_fx_Qxy_target_note: .byte 1 //target note index
pulse2_fx_Qxy_target: .byte 2 //target note period
pulse2_fx_Qxy_speed: .byte 2 //the amount to offset by to get to the target
pulse2_fx_Qxy_total_offset: .byte 2 //NOTE: due to the way the sound driver is setup, we need to keep track of the total pitch offset
pulse2_fx_Rxy_target_note: .byte 1 //target note index
pulse2_fx_Rxy_target: .byte 2 //target note period
pulse2_fx_Rxy_speed: .byte 2 //the amount to offset by to get to the target
pulse2_fx_Rxy_total_offset: .byte 2
pulse2_fx_Sxx_pre: .byte 1 //NOTE: Gxx and Sxx can not both be in effect at the same time. Sxx has priority.
pulse2_fx_Sxx_post: .byte 1

//TRIANGLE
triangle_pattern: .byte 2
triangle_pattern_delay_rows: .byte 1
triangle_pattern_delay_frames: .byte 1
triangle_pattern_offset: .byte 2

triangle_volume_macro: .byte 2
triangle_volume_macro_offset: .byte 1
triangle_volume_macro_loop: .byte 1
triangle_volume_macro_release: .byte 1

triangle_arpeggio_macro: .byte 2
triangle_arpeggio_macro_offset: .byte 1
triangle_arpeggio_macro_loop: .byte 1
triangle_arpeggio_macro_release: .byte 1
triangle_arpeggio_macro_mode: .byte 1

triangle_total_pitch_offset: .byte 2 //used to reference the overall change in pitch for the pitch macro
triangle_pitch_macro: .byte 2
triangle_pitch_macro_offset: .byte 1
triangle_pitch_macro_loop: .byte 1
triangle_pitch_macro_release: .byte 1

triangle_total_hi_pitch_offset: .byte 1 //used to reference the overall change in pitch for the hi pitch macro
triangle_hi_pitch_macro: .byte 2
triangle_hi_pitch_macro_offset: .byte 1
triangle_hi_pitch_macro_loop: .byte 1
triangle_hi_pitch_macro_release: .byte 1

triangle_duty_macro: .byte 2
triangle_duty_macro_offset: .byte 1
triangle_duty_macro_loop: .byte 1
triangle_duty_macro_release: .byte 1

triangle_fx_0xy_sequence: .byte 2 //arpeggio sequence in the order of 00:xy. xy are from the parameters in 0xy
triangle_fx_1xx: .byte 2 //refers to the rate in which to subtract the pitch from by the 1xx
triangle_fx_1xx_total: .byte 2 //the total pitch offset for 1xx
triangle_fx_2xx: .byte 2 //refers to the rate in which to add to the pitch by the 2xx
triangle_fx_2xx_total: .byte 2 //the total pitch offset for 2xx
triangle_fx_3xx_start: .byte 2 //the starting note period
triangle_fx_3xx_target: .byte 2 //target note period
triangle_fx_3xx_speed: .byte 2 //the amount to offset by to get to the target
triangle_fx_3xx_total_offset: .byte 2
triangle_fx_4xy_speed: .byte 1
triangle_fx_4xy_depth: .byte 1
triangle_fx_4xy_phase: .byte 1
triangle_fx_Gxx_pre: .byte 1 //holds the # of NES frames to wait before executing the current row
triangle_fx_Gxx_post: .byte 1 //holds the # of NES frames to add to the delay before going to the next famitracker row NOTE: Gxx is limited to delay up till the end of the row it was called on
triangle_fx_Pxx_total: .byte 2 //refers to the fine pitch offset set by the Pxx effect
triangle_fx_Qxy_target_note: .byte 1 //target note index
triangle_fx_Qxy_target: .byte 2 //target note period
triangle_fx_Qxy_speed: .byte 2 //the amount to offset by to get to the target
triangle_fx_Qxy_total_offset: .byte 2 //NOTE: due to the way the sound driver is setup, we need to keep track of the total pitch offset
triangle_fx_Rxy_target_note: .byte 1 //target note index
triangle_fx_Rxy_target: .byte 2 //target note period
triangle_fx_Rxy_speed: .byte 2 //the amount to offset by to get to the target
triangle_fx_Rxy_total_offset: .byte 2
triangle_fx_Sxx_pre: .byte 1 //NOTE: Gxx and Sxx can not both be in effect at the same time. Sxx has priority.
triangle_fx_Sxx_post: .byte 1

//NOISE
noise_pattern: .byte 2
noise_pattern_delay_rows: .byte 1
noise_pattern_delay_frames: .byte 1
noise_pattern_offset: .byte 2

noise_volume_macro: .byte 2
noise_volume_macro_offset: .byte 1
noise_volume_macro_loop: .byte 1
noise_volume_macro_release: .byte 1

noise_arpeggio_macro: .byte 2
noise_arpeggio_macro_offset: .byte 1
noise_arpeggio_macro_loop: .byte 1
noise_arpeggio_macro_release: .byte 1
noise_arpeggio_macro_mode: .byte 1

noise_total_pitch_offset: .byte 2 //used to reference the overall change in pitch for the pitch macro
noise_pitch_macro: .byte 2
noise_pitch_macro_offset: .byte 1
noise_pitch_macro_loop: .byte 1
noise_pitch_macro_release: .byte 1

noise_total_hi_pitch_offset: .byte 1 //used to reference the overall change in pitch for the hi pitch macro
noise_hi_pitch_macro: .byte 2
noise_hi_pitch_macro_offset: .byte 1
noise_hi_pitch_macro_loop: .byte 1
noise_hi_pitch_macro_release: .byte 1

noise_duty_macro: .byte 2
noise_duty_macro_offset: .byte 1
noise_duty_macro_loop: .byte 1
noise_duty_macro_release: .byte 1

noise_fx_0xy_sequence: .byte 2 //arpeggio sequence in the order of 00:xy. xy are from the parameters in 0xy
noise_fx_1xx: .byte 2 //refers to the rate in which to subtract the pitch from by the 1xx
noise_fx_1xx_total: .byte 2 //the total pitch offset for 1xx
noise_fx_2xx: .byte 2 //refers to the rate in which to add to the pitch by the 2xx
noise_fx_2xx_total: .byte 2 //the total pitch offset for 2xx
noise_fx_3xx_start: .byte 2 //the starting note period
noise_fx_3xx_target: .byte 2 //target note period
noise_fx_3xx_speed: .byte 2 //the amount to offset by to get to the target
noise_fx_3xx_total_offset: .byte 2
noise_fx_4xy_speed: .byte 1
noise_fx_4xy_depth: .byte 1
noise_fx_4xy_phase: .byte 1
noise_fx_7xy_speed: .byte 1
noise_fx_7xy_depth: .byte 1
noise_fx_7xy_phase: .byte 1
noise_fx_7xy_value: .byte 1 //value to offset the volume
noise_fx_Axy: .byte 1 //refers to the decay/addition in volume set by the Axy effect NOTE: this value is a signed fractional byte, with the decimal between bits 3 and 4.
noise_fx_Gxx_pre: .byte 1 //holds the # of NES frames to wait before executing the current row
noise_fx_Gxx_post: .byte 1 //holds the # of NES frames to add to the delay before going to the next famitracker row NOTE: Gxx is limited to delay up till the end of the row it was called on
noise_fx_Pxx_total: .byte 2 //refers to the fine pitch offset set by the Pxx effect
noise_fx_Qxy_target_note: .byte 1 //target note index
noise_fx_Qxy_target: .byte 2 //target note period
noise_fx_Qxy_speed: .byte 2 //the amount to offset by to get to the target
noise_fx_Qxy_total_offset: .byte 2 //NOTE: due to the way the sound driver is setup, we need to keep track of the total pitch offset
noise_fx_Rxy_target_note: .byte 1 //target note index
noise_fx_Rxy_target: .byte 2 //target note period
noise_fx_Rxy_speed: .byte 2 //the amount to offset by to get to the target
noise_fx_Rxy_total_offset: .byte 2
noise_fx_Sxx_pre: .byte 1 //NOTE: Gxx and Sxx can not both be in effect at the same time. Sxx has priority.
noise_fx_Sxx_post: .byte 1

//DPCM
dcpm_pattern_delay: .byte 1

.cseg

//NOTE: zero is defined in order to use the cp instruction without the need to load 0x00 into a register beforehand
.def zero = r2
.def pulse_channel_flags = r25 //[pulse1.pulse2] RSlc.RSlc = Reload, Start, Length halt/Loop, Constant volume
.def pulse1_sequence = r10
.def pulse1_length_counter = r11
.def pulse1_sweep = r12 //NSSS.EPPP = Negate sweep flag, Shift, Enable sweep flag, Period divider
.def pulse1_volume_divider = r16 //0000.PPPP = Period divider
.def pulse1_volume_decay = r17 //0000.dddd = Decay
.def pulse2_sequence = r13
.def pulse2_length_counter = r14
.def pulse2_sweep = r15 //NSSS.EPPP = Negate sweep flag, Shift, Enable sweep flag, Period divider
.def pulse2_volume_divider = r18 //0000.PPPP = Period divider
.def pulse2_volume_decay = r19 //0000.dddd = Decay
.def triangle_sequence = r20
.def noise_sequence_LOW = r21
.def noise_sequence_HIGH = r22

reset:
	jmp init

.org TCA0_OVF_vect
	jmp sound_driver

.org TCA0_CMP0_vect
	jmp sequence_0_2

.org TCA0_CMP1_vect
	jmp sequence_1_3

.org TCA0_CMP2_vect
	jmp sequence_0_2

.org TCB0_INT_vect
	jmp pulse1_sequence_routine

.org TCB1_INT_vect
	jmp pulse2_sequence_routine

.org TCB2_INT_vect
	jmp triangle_sequence_routine

.org TCB3_INT_vect
	jmp noise_sequence_routine

.nolist
.include "song_data.asm"
.list

init:
	//MAIN CLOCK
	ldi r28, CPU_CCP_IOREG_gc //protected write
	sts CPU_CCP, r28
	ldi r28, 0 << CLKCTRL_PEN_bp //disable prescaler for 20 MHz on main clock
	sts CLKCTRL_MCLKCTRLB, r28

	//ZERO
	clr zero

	//MEMORY
	ldi r28, 0b00110000
	sts pulse1_param, r28
	ldi r28, 0b10000000
	sts pulse1_sweep_param, r28
	ldi r28, 0xFF
	sts pulse1_timerL, r28
	sts pulse1_timerH, r28
	sts pulse1_length, r28

	ldi r28, 0b00110000
	sts pulse2_param, r28
	ldi r28, 0b10000000
	sts pulse2_sweep_param, r28
	ldi r28, 0xFF
	sts pulse2_timerL, r28
	sts pulse2_timerH, r28
	sts pulse2_length, r28

	ldi r28, 0xFF
	sts triangle_timerL, r28
	sts triangle_timerH, r28

	ldi r28, 0b00110000
	sts noise_param, r28
	ldi r28, 0b00001111
	sts noise_period, r28

	ldi r28, 0x02
	sts song_frame_offset, r28
	sts song_frame_offset+1, zero
	ldi r28, 0xFF
	sts song_fx_Bxx, r28
	sts song_fx_Cxx, zero
	sts song_fx_Dxx, zero
	ldi ZL, LOW(song0_frames << 1)
	ldi ZH, HIGH(song0_frames << 1)
	sts song_frames, ZL
	sts song_frames+1, ZH
	lpm r28, Z+ //load the song size
	lpm r29, Z+
	sts song_size, r28
	sts song_size+1, r29
	sts song_speed, zero

	//CHANNEL 0
	lpm r28, Z+
	lpm r29, Z+
	lsl r28
	rol r29
	sts pulse1_pattern, r28
	sts pulse1_pattern+1, r29
	sts pulse1_pattern_delay_rows, zero
	sts pulse1_pattern_delay_frames, zero
	sts pulse1_pattern_offset, zero
	sts pulse1_pattern_offset+1, zero

	//CHANNEL 1
	lpm r28, Z+
	lpm r29, Z+
	lsl r28
	rol r29
	sts pulse2_pattern, r28
	sts pulse2_pattern+1, r29
	sts pulse2_pattern_delay_rows, zero
	sts pulse2_pattern_delay_frames, zero
	sts pulse2_pattern_offset, zero
	sts pulse2_pattern_offset+1, zero

	//CHANNEL 2
	lpm r28, Z+
	lpm r29, Z+
	lsl r28
	rol r29
	sts triangle_pattern, r28
	sts triangle_pattern+1, r29
	sts triangle_pattern_delay_rows, zero
	sts triangle_pattern_delay_frames, zero
	sts triangle_pattern_offset, zero
	sts triangle_pattern_offset+1, zero

	//CHANNEL 3
	lpm r28, Z+
	lpm r29, Z+
	lsl r28
	rol r29
	sts noise_pattern, r28
	sts noise_pattern+1, r29
	sts noise_pattern_delay_rows, zero
	sts noise_pattern_delay_frames, zero
	sts noise_pattern_offset, zero
	sts noise_pattern_offset+1, zero

	//CHANNEL 0 instrument macros
	ldi r28, 0xFF
	sts pulse1_volume_macro_offset, zero
	sts pulse1_volume_macro_loop, r28
	sts pulse1_volume_macro_release, r28
	sts pulse1_arpeggio_macro_offset, zero
	sts pulse1_arpeggio_macro_loop, r28
	sts pulse1_arpeggio_macro_release, r28
	sts pulse1_arpeggio_macro_mode, r28
	sts pulse1_pitch_macro_offset, zero
	sts pulse1_pitch_macro_loop, r28
	sts pulse1_pitch_macro_release, r28
	sts pulse1_hi_pitch_macro_offset, zero
	sts pulse1_hi_pitch_macro_loop, r28
	sts pulse1_hi_pitch_macro_release, r28
	sts pulse1_duty_macro_offset, zero
	sts pulse1_duty_macro_loop, r28
	sts pulse1_duty_macro_release, r28

	sts pulse1_volume_macro, zero
	sts pulse1_volume_macro+1, zero
	sts pulse1_arpeggio_macro, zero
	sts pulse1_arpeggio_macro+1, zero
	sts pulse1_total_pitch_offset, zero
	sts pulse1_total_pitch_offset+1, zero
	sts pulse1_pitch_macro, zero
	sts pulse1_pitch_macro+1, zero
	sts pulse1_total_hi_pitch_offset, zero
	sts pulse1_hi_pitch_macro, zero
	sts pulse1_hi_pitch_macro+1, zero
	sts pulse1_duty_macro, zero
	sts pulse1_duty_macro+1, zero

	//CHANNEL 0 ENVELOPE
	ldi pulse1_volume_divider, 0x0F
	lds pulse1_volume_decay, pulse1_param
	andi pulse1_volume_decay, 0x0F //mask for VVVV bits
	lds pulse_channel_flags, pulse1_param
	andi pulse_channel_flags, 0b00110000
	sbr pulse_channel_flags, 0b01000000 //set start flag
	sts pulse1_output_volume, zero
	sts pulse1_fractional_volume, r28 //initialize fractional volume to max value
	
	//CHANNEL 0 LENGTH
	mov pulse1_length_counter, r28

	//CHANNEL 0 SEQUENCE
	ldi r28, 0b00000001 //12.5% is the default duty cycle sequence
	mov pulse1_sequence, r28

	//CHANNEL 0 SWEEP
	lds pulse1_sweep, pulse1_sweep_param
	swap pulse1_sweep //swap data from high byte and low byte
	sbr pulse_channel_flags, 0b10000000 //set reload flag

	//CHANNEL 0 FX
	ldi r28, 0xFF
	sts pulse1_fx_0xy_sequence, zero
	sts pulse1_fx_0xy_sequence+1, zero
	sts pulse1_fx_1xx, zero
	sts pulse1_fx_1xx+1, zero
	sts pulse1_fx_1xx_total, zero
	sts pulse1_fx_1xx_total+1, zero
	sts pulse1_fx_2xx, zero
	sts pulse1_fx_2xx+1, zero
	sts pulse1_fx_2xx_total, zero
	sts pulse1_fx_2xx_total+1, zero
	sts pulse1_fx_3xx_start, zero
	sts pulse1_fx_3xx_start+1, zero
	sts pulse1_fx_3xx_target, zero
	sts pulse1_fx_3xx_target+1, zero
	sts pulse1_fx_3xx_speed, zero
	sts pulse1_fx_3xx_speed+1, zero
	sts pulse1_fx_3xx_total_offset, zero
	sts pulse1_fx_3xx_total_offset+1, zero
	sts pulse1_fx_4xy_speed, zero
	sts pulse1_fx_4xy_depth, zero
	sts pulse1_fx_4xy_phase, zero
	sts pulse1_fx_7xy_speed, zero
	sts pulse1_fx_7xy_depth, zero
	sts pulse1_fx_7xy_phase, zero
	sts pulse1_fx_7xy_value, zero
	sts pulse1_fx_Axy, zero
	sts pulse1_fx_Gxx_pre, r28
	sts pulse1_fx_Gxx_post, r28
	sts pulse1_fx_Pxx_total, zero
	sts pulse1_fx_Pxx_total+1, zero
	sts pulse1_fx_Qxy_target_note, zero
	sts pulse1_fx_Qxy_target, zero
	sts pulse1_fx_Qxy_target+1, zero
	sts pulse1_fx_Qxy_speed, zero
	sts pulse1_fx_Qxy_speed+1, zero
	sts pulse1_fx_Qxy_total_offset, zero
	sts pulse1_fx_Qxy_total_offset+1, zero
	sts pulse1_fx_Rxy_target_note, zero
	sts pulse1_fx_Rxy_target, zero
	sts pulse1_fx_Rxy_target+1, zero
	sts pulse1_fx_Rxy_speed, zero
	sts pulse1_fx_Rxy_speed+1, zero
	sts pulse1_fx_Rxy_total_offset, zero
	sts pulse1_fx_Rxy_total_offset+1, zero
	sts pulse1_fx_Sxx_pre, r28
	sts pulse1_fx_Sxx_post, r28

	//CHANNEL 1 instrument macros
	ldi r28, 0xFF
	sts pulse2_volume_macro_offset, zero
	sts pulse2_volume_macro_loop, r28
	sts pulse2_volume_macro_release, r28
	sts pulse2_arpeggio_macro_offset, zero
	sts pulse2_arpeggio_macro_loop, r28
	sts pulse2_arpeggio_macro_release, r28
	sts pulse2_arpeggio_macro_mode, r28
	sts pulse2_pitch_macro_offset, zero
	sts pulse2_pitch_macro_loop, r28
	sts pulse2_pitch_macro_release, r28
	sts pulse2_hi_pitch_macro_offset, zero
	sts pulse2_hi_pitch_macro_loop, r28
	sts pulse2_hi_pitch_macro_release, r28
	sts pulse2_duty_macro_offset, zero
	sts pulse2_duty_macro_loop, r28
	sts pulse2_duty_macro_release, r28

	sts pulse2_volume_macro, zero
	sts pulse2_volume_macro+1, zero
	sts pulse2_arpeggio_macro, zero
	sts pulse2_arpeggio_macro+1, zero
	sts pulse2_total_pitch_offset, zero
	sts pulse2_total_pitch_offset+1, zero
	sts pulse2_pitch_macro, zero
	sts pulse2_pitch_macro+1, zero
	sts pulse2_total_hi_pitch_offset, zero
	sts pulse2_hi_pitch_macro, zero
	sts pulse2_hi_pitch_macro+1, zero
	sts pulse2_duty_macro, zero
	sts pulse2_duty_macro+1, zero

	//CHANNEL 1 ENVELOPE
	ldi pulse2_volume_divider, 0x0F
	lds pulse2_volume_decay, pulse2_param
	andi pulse2_volume_decay, 0x0F //mask for VVVV bits
	lds r29, pulse2_param
	andi r29, 0b00110000
	sbr r29, 0b0100000 //set start flag
	swap r29
	or pulse_channel_flags, r29
	sts pulse2_output_volume, zero
	sts pulse2_fractional_volume, r28 //initialize fractional volume to max value
	
	//CHANNEL 1 LENGTH
	mov pulse2_length_counter, r28

	//CHANNEL 1 SEQUENCE
	ldi r28, 0b00000001 //12.5% is the default duty cycle sequence
	mov pulse2_sequence, r28

	//CHANNEL 1 SWEEP
	lds pulse2_sweep, pulse2_sweep_param
	swap pulse2_sweep //swap data from high byte and low byte
	sbr pulse_channel_flags, 0b00001000 //set reload flag

	//CHANNEL 1 FX
	ldi r28, 0xFF
	sts pulse2_fx_0xy_sequence, zero
	sts pulse2_fx_0xy_sequence+1, zero
	sts pulse2_fx_1xx, zero
	sts pulse2_fx_1xx+1, zero
	sts pulse2_fx_1xx_total, zero
	sts pulse2_fx_1xx_total+1, zero
	sts pulse2_fx_2xx, zero
	sts pulse2_fx_2xx+1, zero
	sts pulse2_fx_2xx_total, zero
	sts pulse2_fx_2xx_total+1, zero
	sts pulse2_fx_3xx_start, zero
	sts pulse2_fx_3xx_start+1, zero
	sts pulse2_fx_3xx_target, zero
	sts pulse2_fx_3xx_target+1, zero
	sts pulse2_fx_3xx_speed, zero
	sts pulse2_fx_3xx_speed+1, zero
	sts pulse2_fx_3xx_total_offset, zero
	sts pulse2_fx_3xx_total_offset+1, zero
	sts pulse2_fx_4xy_speed, zero
	sts pulse2_fx_4xy_depth, zero
	sts pulse2_fx_4xy_phase, zero
	sts pulse2_fx_7xy_speed, zero
	sts pulse2_fx_7xy_depth, zero
	sts pulse2_fx_7xy_phase, zero
	sts pulse2_fx_7xy_value, zero
	sts pulse2_fx_Axy, zero
	sts pulse2_fx_Gxx_pre, r28
	sts pulse2_fx_Gxx_post, r28
	sts pulse2_fx_Pxx_total, zero
	sts pulse2_fx_Pxx_total+1, zero
	sts pulse2_fx_Qxy_target_note, zero
	sts pulse2_fx_Qxy_target, zero
	sts pulse2_fx_Qxy_target+1, zero
	sts pulse2_fx_Qxy_speed, zero
	sts pulse2_fx_Qxy_speed+1, zero
	sts pulse2_fx_Qxy_total_offset, zero
	sts pulse2_fx_Qxy_total_offset+1, zero
	sts pulse2_fx_Rxy_target_note, zero
	sts pulse2_fx_Rxy_target, zero
	sts pulse2_fx_Rxy_target+1, zero
	sts pulse2_fx_Rxy_speed, zero
	sts pulse2_fx_Rxy_speed+1, zero
	sts pulse2_fx_Rxy_total_offset, zero
	sts pulse2_fx_Rxy_total_offset+1, zero
	sts pulse2_fx_Sxx_pre, r28
	sts pulse2_fx_Sxx_post, r28

	//CHANNEL 2 instrument macros
	ldi r28, 0xFF
	sts triangle_volume_macro_offset, zero
	sts triangle_volume_macro_loop, r28
	sts triangle_volume_macro_release, r28
	sts triangle_arpeggio_macro_offset, zero
	sts triangle_arpeggio_macro_loop, r28
	sts triangle_arpeggio_macro_release, r28
	sts triangle_arpeggio_macro_mode, r28
	sts triangle_pitch_macro_offset, zero
	sts triangle_pitch_macro_loop, r28
	sts triangle_pitch_macro_release, r28
	sts triangle_hi_pitch_macro_offset, zero
	sts triangle_hi_pitch_macro_loop, r28
	sts triangle_hi_pitch_macro_release, r28
	sts triangle_duty_macro_offset, zero
	sts triangle_duty_macro_loop, r28
	sts triangle_duty_macro_release, r28

	sts triangle_volume_macro, zero
	sts triangle_volume_macro+1, zero
	sts triangle_arpeggio_macro, zero
	sts triangle_arpeggio_macro+1, zero
	sts triangle_total_pitch_offset, zero
	sts triangle_total_pitch_offset+1, zero
	sts triangle_pitch_macro, zero
	sts triangle_pitch_macro+1, zero
	sts triangle_total_hi_pitch_offset, zero
	sts triangle_hi_pitch_macro, zero
	sts triangle_hi_pitch_macro+1, zero
	sts triangle_duty_macro, zero
	sts triangle_duty_macro+1, zero

	//CHANNEL 2 SEQUENCE
	ldi r28, 0b00000000 //reset sequence to 0
	mov triangle_sequence, r28

	//CHANNEL 2 FX
	ldi r28, 0xFF
	sts triangle_fx_0xy_sequence, zero
	sts triangle_fx_0xy_sequence+1, zero
	sts triangle_fx_1xx, zero
	sts triangle_fx_1xx+1, zero
	sts triangle_fx_1xx_total, zero
	sts triangle_fx_1xx_total+1, zero
	sts triangle_fx_2xx, zero
	sts triangle_fx_2xx+1, zero
	sts triangle_fx_2xx_total, zero
	sts triangle_fx_2xx_total+1, zero
	sts triangle_fx_3xx_start, zero
	sts triangle_fx_3xx_start+1, zero
	sts triangle_fx_3xx_target, zero
	sts triangle_fx_3xx_target+1, zero
	sts triangle_fx_3xx_speed, zero
	sts triangle_fx_3xx_speed+1, zero
	sts triangle_fx_3xx_total_offset, zero
	sts triangle_fx_3xx_total_offset+1, zero
	sts triangle_fx_4xy_speed, zero
	sts triangle_fx_4xy_depth, zero
	sts triangle_fx_4xy_phase, zero
	sts triangle_fx_Gxx_pre, r28
	sts triangle_fx_Gxx_post, r28
	sts triangle_fx_Pxx_total, zero
	sts triangle_fx_Pxx_total+1, zero
	sts triangle_fx_Qxy_target_note, zero
	sts triangle_fx_Qxy_target, zero
	sts triangle_fx_Qxy_target+1, zero
	sts triangle_fx_Qxy_speed, zero
	sts triangle_fx_Qxy_speed+1, zero
	sts triangle_fx_Qxy_total_offset, zero
	sts triangle_fx_Qxy_total_offset+1, zero
	sts triangle_fx_Rxy_target_note, zero
	sts triangle_fx_Rxy_target, zero
	sts triangle_fx_Rxy_target+1, zero
	sts triangle_fx_Rxy_speed, zero
	sts triangle_fx_Rxy_speed+1, zero
	sts triangle_fx_Rxy_total_offset, zero
	sts triangle_fx_Rxy_total_offset+1, zero
	sts triangle_fx_Sxx_pre, r28
	sts triangle_fx_Sxx_post, r28

	//CHANNEL 3 instrument macros
	ldi r28, 0xFF
	sts noise_volume_macro_offset, zero
	sts noise_volume_macro_loop, r28
	sts noise_volume_macro_release, r28
	sts noise_arpeggio_macro_offset, zero
	sts noise_arpeggio_macro_loop, r28
	sts noise_arpeggio_macro_release, r28
	sts noise_arpeggio_macro_mode, r28
	sts noise_pitch_macro_offset, zero
	sts noise_pitch_macro_loop, r28
	sts noise_pitch_macro_release, r28
	sts noise_hi_pitch_macro_offset, zero
	sts noise_hi_pitch_macro_loop, r28
	sts noise_hi_pitch_macro_release, r28
	sts noise_duty_macro_offset, zero
	sts noise_duty_macro_loop, r28
	sts noise_duty_macro_release, r28

	sts noise_volume_macro, zero
	sts noise_volume_macro+1, zero
	sts noise_arpeggio_macro, zero
	sts noise_arpeggio_macro+1, zero
	sts noise_total_pitch_offset, zero
	sts noise_total_pitch_offset+1, zero
	sts noise_pitch_macro, zero
	sts noise_pitch_macro+1, zero
	sts noise_total_hi_pitch_offset, zero
	sts noise_hi_pitch_macro, zero
	sts noise_hi_pitch_macro+1, zero
	sts noise_duty_macro, zero
	sts noise_duty_macro+1, zero

	//CHANNEL 3 VOLUME
	sts noise_output_volume, zero
	sts noise_fractional_volume, r28 //initialize fractional volume to max value

	//CHANNEL 3 SEQUENCE
	ldi r28, 0b00000001 //noise sequence is reset to 0x0001
	mov noise_sequence_LOW, r28
	mov noise_sequence_HIGH, zero

	//CHANNEL 3 FX
	ldi r28, 0xFF
	sts noise_fx_0xy_sequence, zero
	sts noise_fx_0xy_sequence+1, zero
	sts noise_fx_1xx, zero
	sts noise_fx_1xx+1, zero
	sts noise_fx_1xx_total, zero
	sts noise_fx_1xx_total+1, zero
	sts noise_fx_2xx, zero
	sts noise_fx_2xx+1, zero
	sts noise_fx_2xx_total, zero
	sts noise_fx_2xx_total+1, zero
	sts noise_fx_3xx_start, zero
	sts noise_fx_3xx_start+1, zero
	sts noise_fx_3xx_target, zero
	sts noise_fx_3xx_target+1, zero
	sts noise_fx_3xx_speed, zero
	sts noise_fx_3xx_speed+1, zero
	sts noise_fx_3xx_total_offset, zero
	sts noise_fx_3xx_total_offset+1, zero
	sts noise_fx_4xy_speed, zero
	sts noise_fx_4xy_depth, zero
	sts noise_fx_4xy_phase, zero
	sts noise_fx_7xy_speed, zero
	sts noise_fx_7xy_depth, zero
	sts noise_fx_7xy_phase, zero
	sts noise_fx_7xy_value, zero
	sts noise_fx_Axy, zero
	sts noise_fx_Gxx_pre, r28
	sts noise_fx_Gxx_post, r28
	sts noise_fx_Pxx_total, zero
	sts noise_fx_Pxx_total+1, zero
	sts noise_fx_Qxy_target_note, zero
	sts noise_fx_Qxy_target, zero
	sts noise_fx_Qxy_target+1, zero
	sts noise_fx_Qxy_speed, zero
	sts noise_fx_Qxy_speed+1, zero
	sts noise_fx_Qxy_total_offset, zero
	sts noise_fx_Qxy_total_offset+1, zero
	sts noise_fx_Rxy_target_note, zero
	sts noise_fx_Rxy_target, zero
	sts noise_fx_Rxy_target+1, zero
	sts noise_fx_Rxy_speed, zero
	sts noise_fx_Rxy_speed+1, zero
	sts noise_fx_Rxy_total_offset, zero
	sts noise_fx_Rxy_total_offset+1, zero
	sts noise_fx_Sxx_pre, r28
	sts noise_fx_Sxx_post, r28

	//PINS
	ldi r28, 0xFF
	out VPORTA_DIR, r28 //set all pins in VPORTA to output

	//TIMERS
	//Frame Counter
	//NOTE:The frame counter will be defaulted to NTSC mode (60 Hz, 120 Hz, 240 Hz)
	//Each interrupt will be setup to interrupt every 240 Hz clock
	//CMP0 = sequence 0, CMP1 = sequence 1, CMP2 = sequence 2, OVF = sequence 3/sound driver
	//Sequence 3 will clock the sound driver every 60Hz, in which new audio data is read and written to the registers
	//Timer period Calculation: (0.00416666666 * 20000000/64)-1 = 1301.08333125 = 0x0515
	//The ATmega4809 is cofigured to run at 20000000 Hz
	//0.00416666666 seconds is the period for 240 Hz
	//The /64 comes from the prescaler divider used
	ldi r28, TCA_SINGLE_CMP0EN_bm | TCA_SINGLE_CMP1EN_bm | TCA_SINGLE_CMP2EN_bm | TCA_SINGLE_WGMODE_NORMAL_gc //interrupt mode
	sts TCA0_SINGLE_CTRLB, r28
	ldi r28, TCA_SINGLE_CMP0_bm | TCA_SINGLE_CMP1_bm | TCA_SINGLE_CMP2_bm | TCA_SINGLE_OVF_bm //enable overflow and compare interrupts
	sts TCA0_SINGLE_INTCTRL, r28
	ldi r28, 0x15 //set the period for CMP0
	sts TCA0_SINGLE_CMP0, r28
	ldi r28, 0x05
	sts TCA0_SINGLE_CMP0 + 1, r28
	ldi r28, 0x2B //set the period for CMP1
	sts TCA0_SINGLE_CMP1, r28
	ldi r28, 0x0A
	sts TCA0_SINGLE_CMP1 + 1, r28
	ldi r28, 0x41 //set the period for CMP2
	sts TCA0_SINGLE_CMP2, r28
	ldi r28, 0x0F
	sts TCA0_SINGLE_CMP2 + 1, r28
	ldi r28, 0x57 //set the period for OVF
	sts TCA0_SINGLE_PER, r28
	ldi r28, 0x14
	sts TCA0_SINGLE_PER + 1, r28
	ldi r28, TCA_SINGLE_CLKSEL_DIV64_gc | TCA_SINGLE_ENABLE_bm //use prescale divider of 64 and enable timer
	sts TCA0_SINGLE_CTRLA, r28

	//NOTE: Channel Timers are clocked (20/2)/(0.8948865) = 11.1746014718 times faster than the NES APU
	//Because of this, we multiply all the NES timer values by 11.1746014718 beforehand
	//Since we rotate the sequence when the timer goes from t-(t-1) to 0, instead of 0 to t like the NES, we add 1 to the NES timers before multiplying
	//The ATmega4809 is configured to run at 20 MHz
	//The /2 comes from the prescaler divider used
	//0.8948865 MHz is the speed of the NTSC NES APU
	//NOTE: This means that any offset to the pitch for the NES timers would be multiplied by 11.1746014718 aswell.
	//Pulse 1
	ldi r28, TCB_CNTMODE_INT_gc //interrupt mode
	sts TCB0_CTRLB, r28
	ldi r28, TCB_CAPT_bm //enable interrupts
	sts TCB0_INTCTRL, r28
	lds r28, pulse1_timerL //load the LOW bits for timer
	sts TCB0_CCMPL, r28
	lds r28, pulse1_timerH //load the HIGH bits for timer
	sts TCB0_CCMPH, r28
	ldi r28, TCB_CLKSEL_CLKDIV2_gc | TCB_ENABLE_bm //use prescaler divider of 2 and enable timer
	sts TCB0_CTRLA, r28

	//PULSE 2
	ldi r27, TCB_CNTMODE_INT_gc //interrupt mode
	sts TCB1_CTRLB, r27
	ldi r27, TCB_CAPT_bm //enable interrupts
	sts TCB1_INTCTRL, r27
	lds r27, pulse2_timerL //load the LOW bits for timer
	sts TCB1_CCMPL, r27
	lds r27, pulse2_timerH //load the HIGH bits for timer
	sts TCB1_CCMPH, r27
	ldi r27, TCB_CLKSEL_CLKDIV2_gc | TCB_ENABLE_bm //use prescaler divider of 2 and enable timer
	sts TCB1_CTRLA, r27

	//NOTE: The triangle timer is clocked at the same speed as the NES CPU, aka twice the NES APU.
	//Therefore, we won't be using a /2 clock divider like we did with the pulse timers.
	//TRIANGLE
	ldi r27, TCB_CNTMODE_INT_gc //interrupt mode
	sts TCB2_CTRLB, r27
	ldi r27, TCB_CAPT_bm //enable interrupts
	//sts TCB2_INTCTRL, r27 //keep interrupts disabled to mute channel since triangle doesn't have volume bits
	lds r27, triangle_timerL //load the LOW bits for timer
	sts TCB2_CCMPL, r27
	lds r27, triangle_timerH //load the HIGH bits for timer
	sts TCB2_CCMPH, r27
	ldi r27, TCB_CLKSEL_CLKDIV1_gc | TCB_ENABLE_bm //use prescaler divider of 1 and enable timer
	sts TCB2_CTRLA, r27
	sei //global interrupt enable

	//NOISE
	ldi r27, TCB_CNTMODE_INT_gc //interrupt mode
	sts TCB3_CTRLB, r27
	ldi r27, TCB_CAPT_bm //enable interrupts
	sts TCB3_INTCTRL, r27
	lds r27, pulse2_timerL //load the LOW bits for timer
	sts TCB3_CCMPL, r27
	lds r27, pulse2_timerH //load the HIGH bits for timer
	sts TCB3_CCMPH, r27
	ldi r27, TCB_CLKSEL_CLKDIV2_gc | TCB_ENABLE_bm //use prescaler divider of 2 and enable timer
	sts TCB3_CTRLA, r27



//https://wiki.nesdev.com/w/index.php/APU_Mixer
volume_mixer:
	lds r28, pulse1_output_volume
	lds r29, pulse2_output_volume

volume_mixer_pulse1:
	sbrs pulse1_sequence, 0 //if the sequence output is zero, return
	rjmp volume_mixer_pulse1_off

	cp pulse1_length_counter, zero //if length is zero, return
	breq volume_mixer_pulse1_off

	//NOTE: We will just mute the pulse when the current period is < $0008
	//This is done in order to account for the sweep unit muting the channel when the period is < $0008,
	//Due to the 11.1746014718 timer multiplier being applied to the timer periods, $0008 becomes $0059
	lds r30, TCB0_CCMPL
	ldi r31, 0x59
	cp r30, r31
	lds r30, TCB0_CCMPH
	ldi r31, 0x00
	cpc r30, r31
	brlo volume_mixer_pulse1_off

	//NOTE: Since it'd be too taxing to calculate a target period for every APU clock in the sweep unit,
	//we will be muting the channel if it's period ever reaches $07FF, aka the target period was == $07FF
	//Doing this does not account for the real NES "feature" of muting the pulse even if the sweep unit was disabled.
	//Due to the 11.1746014718 timer multiplier being applied to the timer periods, $07FF becomes $595A
	lds r30, TCB0_CCMPL
	ldi r31, 0x5A
	cp r30, r31
	lds r30, TCB0_CCMPH
	ldi r31, 0x59
	cpc r30, r31
	brsh volume_mixer_pulse1_off
	rjmp volume_mixer_pulse2 //if the HIGH period == $59 && LOW period < $65, pulse is not off
volume_mixer_pulse1_off:
	clr r28

volume_mixer_pulse2:
	sbrs pulse2_sequence, 0 //if the sequence output is zero, return
	rjmp volume_mixer_pulse2_off

	cp pulse2_length_counter, zero //if length is zero, return
	breq volume_mixer_pulse2_off

	lds r30, TCB1_CCMPL
	ldi r31, 0x59
	cp r30, r31
	lds r30, TCB1_CCMPH
	ldi r31, 0x00
	cpc r30, r31
	brlo volume_mixer_pulse2_off

	lds r30, TCB1_CCMPL
	ldi r31, 0x5A
	cp r30, r31
	lds r30, TCB1_CCMPH
	ldi r31, 0x59
	cpc r30, r31
	brsh volume_mixer_pulse2_off
	rjmp volume_mixer_pulse_out //if the HIGH period == $59 && LOW period < $65, pulse is not off
volume_mixer_pulse2_off:
	clr r29

volume_mixer_pulse_out:
	add r28, r29
	ldi ZL, LOW(pulse_volume_table << 1)
	ldi ZH, HIGH(pulse_volume_table << 1)
	add ZL, r28
	adc ZH, zero
	lpm r28, Z

volume_mixer_tnd_triangle:
	mov r29, triangle_sequence
	sbrc r29, 4 //check 5th bit
	com r29
	andi r29, 0x0F
	mov r30, r29
	add r29, r30 //multiply the triangle volume by 3
	add r29, r30

volume_mixer_tnd_noise:
	sbrs noise_sequence_LOW, 0 //check 0th bit, skip if set
	rjmp volume_mixer_tnd_out
	lds r30, noise_output_volume
	lsl r30 //multiply noise volume by 2
	add r29, r30

volume_mixer_tnd_out:
	ldi ZL, LOW(tnd_volume_table << 1)
	ldi ZH, HIGH(tnd_volume_table << 1)
	add ZL, r29
	adc ZH, zero
	lpm r29, Z

volume_mixer_output:
	add r28, r29
	out VPORTA_OUT, r28
	rjmp volume_mixer



//FRAME COUNTER/AUDIO SAMPLE ISR
sequence_0_2:
	in r27, CPU_SREG
	push r27
	cli

	//ENVELOPE
	rcall pulse1_envelope_routine
	rcall pulse2_envelope_routine

	ldi r27, TCA_SINGLE_CMP0_bm | TCA_SINGLE_CMP2_bm //clear OVF flag
	sts TCA0_SINGLE_INTFLAGS, r27
	pop r27
	out CPU_SREG, r27
	reti

sequence_1_3:
	in r27, CPU_SREG
	push r27
	cli

	//ENVELOPE
	rcall pulse1_envelope_routine
	rcall pulse2_envelope_routine

	//SWEEP
	sbrc pulse1_sweep, 3 //check if the sweep enable bit is cleared
	rcall pulse1_sweep_routine
	sbrc pulse2_sweep, 3
	rcall pulse2_sweep_routine

	//LENGTH
	//NOTE: The length routine is relatively simple, so we will not be using clocks to rjmp and ret to a seperate lable
sequence_1_3_pulse1_length:
	sbrc pulse_channel_flags, 5 //check if the length counter halt bit is cleared
	rjmp sequence_1_3_pulse2_length
	cpse pulse1_length_counter, zero //if length counter is already 0, don't decrement
	dec pulse1_length_counter
sequence_1_3_pulse2_length:
	sbrc pulse_channel_flags, 1 //check if the length counter halt bit is cleared
	rjmp sequence_1_3_exit
	cpse pulse2_length_counter, zero //if length counter is already 0, don't decrement
	dec pulse2_length_counter

sequence_1_3_exit:
	ldi r27, TCA_SINGLE_CMP1_bm | TCA_SINGLE_OVF_bm //clear OVF flag
	sts TCA0_SINGLE_INTFLAGS, r27
	pop r27
	out CPU_SREG, r27
	reti

//PULSE 1 ROUTINES
pulse1_sequence_routine:
	in r27, CPU_SREG
	push r27
	cli

	lsl pulse1_sequence //shifts sequence to the left
	adc pulse1_sequence, zero //if the shifted bit was a 1, it will be added to the LSB

	ldi r27, TCB_CAPT_bm //clear OVF flag
	sts TCB0_INTFLAGS, r27
	pop r27
	out CPU_SREG, r27
	reti

pulse1_sweep_routine:
	mov r27, pulse1_sweep
	andi r27, 0x07 //mask for period divider bits
	brne pulse1_sweep_routine_decrement_divider //check if divider != 0

pulse1_sweep_routine_action: //if the divider is == 0, update the pulse timer period
	push r29
	mov r29, pulse1_sweep
	swap r29
	andi r29, 0x07 //mask for shift bits
	brne pulse1_sweep_routine_action_main //shift != 0
	pop r29
	rjmp pulse1_sweep_routine_check_reload //if the shift == 0, do nothing and return

pulse1_sweep_routine_action_main:
	lds r26, TCB0_CCMPL
	lds r27, TCB0_CCMPH
pulse1_sweep_routine_action_main_loop:
	lsr r27
	ror r26
	dec r29
	brne pulse1_sweep_routine_action_main_loop //keep looping/shifting until shift count is 0

	sbrs pulse1_sweep, 7 //check the negate flag
	rjmp pulse1_sweep_routine_action_main_add //if negate flag was clear, go straight to addition

	com r26 //pulse1 uses one's complement if the negate flag is set
	com r27

pulse1_sweep_routine_action_main_add:
	lds r29, TCB0_CCMPL //perform addition to get new timer period
	add r26, r29
	lds r29, TCB0_CCMPH
	adc r27, r29

	sts TCB0_CCMPL, r26 //store the new LOW bits for timer
	sts TCB0_CCMPH, r27 //store the new HIGH bits for timer
	
	pop r29
	rjmp pulse1_sweep_routine_check_reload

pulse1_sweep_routine_decrement_divider:
	dec pulse1_sweep //if the divider != 0, decrement the divider

pulse1_sweep_routine_check_reload:
	sbrs pulse_channel_flags, 7 //if the reload flag is set, reload the sweep divider
	ret

pulse1_sweep_reload:
	lds pulse1_sweep, pulse1_sweep_param //NOTE: since the reload flag is kept in bit 6, we clear the reload flag indirectly
	swap pulse1_sweep //bring data from high byte to low byte
	cbr pulse_channel_flags, 0b10000000 //clear reload flag
	ret



pulse1_envelope_routine:
	sbrc pulse_channel_flags, 6 //check if start flag is cleared
	rjmp pulse1_envelope_routine_clear_start

	cpi pulse1_volume_divider, 0x00 //check if the divider is 0
	breq PC+3 //if the divider == 0, check loop flag
	dec pulse1_volume_divider //if the divider != 0, decrement and return
	ret

	lds pulse1_volume_divider, pulse1_param //if the divider == 0, reset the divider period
	andi pulse1_volume_divider, 0x0F //mask for VVVV bits
	sbrs pulse_channel_flags, 5 //check if the loop flag is set
	rjmp pulse1_envelope_routine_decrement_decay //if the loop flag is not set, check the decay
	ldi pulse1_volume_decay, 0x0F //if the loop flag is set, reset decay and return
	ret

pulse1_envelope_routine_decrement_decay:
	cpi pulse1_volume_decay, 0x00 //check if the decay is 0
	brne PC+2 //if decay != 0, go decrement
	ret //if decay == 0 && loop flag == 0, do nothing and return
	dec pulse1_volume_decay
	ret

pulse1_envelope_routine_clear_start:
	cbr pulse_channel_flags, 0b01000000 //if the start flag is set, clear it
	lds pulse1_volume_divider, pulse1_param //if the start flag is set, reset the divider period
	andi pulse1_volume_divider, 0x0F //mask for VVVV bits
	ldi pulse1_volume_decay, 0x0F //if the start flag is set, reset decay
	ret

//PULSE 2 ROUTINES
pulse2_sequence_routine:
	in r27, CPU_SREG
	push r27
	cli

	lsl pulse2_sequence //shifts sequence to the left
	adc pulse2_sequence, zero //if the shifted bit was a 1, it will be added to the LSB

	ldi r27, TCB_CAPT_bm //clear OVF flag
	sts TCB1_INTFLAGS, r27
	pop r27
	out CPU_SREG, r27
	reti

pulse2_sweep_routine:
	mov r27, pulse2_sweep
	andi r27, 0x07 //mask for period divider bits
	brne pulse2_sweep_routine_decrement_divider //check if divider != 0

pulse2_sweep_routine_action: //if the divider is == 0, update the pulse timer period
	push r29
	mov r29, pulse2_sweep
	swap r29
	andi r29, 0x07 //mask for shift bits
	brne pulse2_sweep_routine_action_main //shift != 0
	pop r29
	rjmp pulse2_sweep_routine_check_reload //if the shift == 0, do nothing and return

pulse2_sweep_routine_action_main:
	lds r26, TCB1_CCMPL
	lds r27, TCB1_CCMPH
pulse2_sweep_routine_action_main_loop:
	lsr r27
	ror r26
	dec r29
	brne pulse2_sweep_routine_action_main_loop //keep looping/shifting until shift count is 0

	sbrs pulse2_sweep, 7 //check the negate flag
	rjmp pulse2_sweep_routine_action_main_add //if negate flag was clear, go straight to addition

	com r26 //pulse2 uses one's complement if the negate flag is set
	com r27

pulse2_sweep_routine_action_main_add:
	lds r29, TCB1_CCMPL //perform addition to get new timer period
	add r26, r29
	lds r29, TCB1_CCMPH
	adc r27, r29

	sts TCB1_CCMPL, r26 //store the new LOW bits for timer
	sts TCB1_CCMPH, r27 //store the new HIGH bits for timer
	
	pop r29
	rjmp pulse2_sweep_routine_check_reload

pulse2_sweep_routine_decrement_divider:
	dec pulse2_sweep //if the divider != 0, decrement the divider

pulse2_sweep_routine_check_reload:
	sbrs pulse_channel_flags, 3 //if the reload flag is set, reload the sweep divider
	ret

pulse2_sweep_reload:
	lds pulse2_sweep, pulse2_sweep_param //NOTE: since the reload flag is kept in bit 6, we clear the reload flag indirectly
	swap pulse2_sweep //bring data from high byte to low byte
	cbr pulse_channel_flags, 0b00001000 //clear reload flag
	ret



pulse2_envelope_routine:
	sbrc pulse_channel_flags, 2 //check if start flag is cleared
	rjmp pulse2_envelope_routine_clear_start

	cpi pulse2_volume_divider, 0x00 //check if the divider is 0
	breq PC+3 //if the divider == 0, check loop flag
	dec pulse2_volume_divider //if the divider != 0, decrement and return
	ret

	lds pulse2_volume_divider, pulse2_param //if the divider == 0, reset the divider period
	andi pulse2_volume_divider, 0x0F //mask for VVVV bits
	sbrs pulse_channel_flags, 1 //check if the loop flag is set
	rjmp pulse2_envelope_routine_decrement_decay //if the loop flag is not set, check the decay
	ldi pulse2_volume_decay, 0x0F //if the loop flag is set, reset decay and return
	ret

pulse2_envelope_routine_decrement_decay:
	cpi pulse2_volume_decay, 0x00 //check if the decay is 0
	brne PC+2 //if decay != 0, go decrement
	ret //if decay == 0 && loop flag == 0, do nothing and return
	dec pulse2_volume_decay
	ret

pulse2_envelope_routine_clear_start:
	cbr pulse_channel_flags, 0b00000100 //if the start flag is set, clear it
	lds pulse2_volume_divider, pulse2_param //if the start flag is set, reset the divider period
	andi pulse2_volume_divider, 0x0F //mask for VVVV bits
	ldi pulse2_volume_decay, 0x0F //if the start flag is set, reset decay
	ret

//TRIANGLE ROUTINES
triangle_sequence_routine:
	in r27, CPU_SREG
	push r27
	cli

	subi triangle_sequence, -1 //increment sequence by 1
	andi triangle_sequence, 0b00011111 //mask out bits 5, 6 and 7 NOTE: the sequence only needs bits 0-4.

	ldi r27, TCB_CAPT_bm //clear OVF flag
	sts TCB2_INTFLAGS, r27
	pop r27
	out CPU_SREG, r27
	reti

//NOISE ROUTINES
noise_sequence_routine:
	in r27, CPU_SREG
	push r27
	cli

	mov r26, noise_sequence_LOW
	sbrc noise_sequence_HIGH, 7 //skip if MODE bit is clear
	rjmp noise_sequence_routine_mode_set

noise_sequence_routine_mode_clear:
	lsr r26 //move the 1th bit to the 0th bit place
	eor r26, noise_sequence_LOW
	sbrc r26, 0 //skip if the EOR of bit 0 and 1 is clear
	rjmp noise_sequence_routine_mode_clear_EOR_set

noise_sequence_routine_mode_clear_EOR_clear:
	lsr noise_sequence_HIGH
	ror noise_sequence_LOW
	rjmp noise_sequence_exit

noise_sequence_routine_mode_clear_EOR_set:
	lsr noise_sequence_HIGH
	ror noise_sequence_LOW
	ori noise_sequence_HIGH, 0b01000000 //set the 14th bit
	rjmp noise_sequence_exit

noise_sequence_routine_mode_set:
	lsl r26
	rol r26
	rol r26 //move the 6th bit to the 0th bit place
	eor r26, noise_sequence_LOW
	sbrc r26, 0 //skip if the EOR of bit 0 and 1 is clear
	rjmp noise_sequence_routine_mode_set_EOR_set

noise_sequence_routine_mode_set_EOR_clear:
	cbr noise_sequence_HIGH, 0b10000000 //clear the MODE flag
	lsr noise_sequence_HIGH
	ror noise_sequence_LOW
	sbr noise_sequence_HIGH, 0b10000000 //set the MODE flag
	rjmp noise_sequence_exit

noise_sequence_routine_mode_set_EOR_set:
	lsr noise_sequence_HIGH
	ror noise_sequence_LOW
	sbr noise_sequence_HIGH, 0b10000000 //set the MODE flag
	rjmp noise_sequence_exit

noise_sequence_exit:
	ldi r27, TCB_CAPT_bm //clear OVF flag
	sts TCB3_INTFLAGS, r27
	pop r27
	out CPU_SREG, r27
	reti

//CONVERTERS
//converts and loads 5 bit length to corresponding 8 bit length value into r29
length_converter:
	ldi ZL, LOW(length << 1)
	ldi ZH, HIGH(length << 1)
	add ZL, r29
	adc ZH, zero
	lpm r29, Z
	ret

//loads pulse sequence into r29
duty_cycle_sequences:
	ldi ZL, LOW(sequences << 1)
	ldi ZH, HIGH(sequences << 1)
	add ZL, r29
	adc ZH, zero
	lpm r29, Z
	ret



//SOUND DRIVER
sound_driver:
	in r27, CPU_SREG
	push r27
	cli
	push r28
	push r29
	push r30
	push r31

	//SOUND DRIVER
	lds r26, song_fx_Bxx
	cpi r26, 0xFF //0xFF means that the flag is disabled
	brne sound_driver_fx_Bxx_routine
	lds r26, song_fx_Cxx
	cpse r26, zero
	rjmp sound_driver_fx_Cxx_routine
	lds r26, song_fx_Dxx
	cpse r26, zero
	rjmp sound_driver_fx_Dxx_routine

	lds r26, song_frame_offset
	lds r27, song_frame_offset+1
	lds r28, song_size
	lds r29, song_size+1
	cp r26, r28
	cpc r27, r29
	brsh sound_driver_fx_song_loop
	rjmp sound_driver_channel0


sound_driver_fx_song_loop:
	ldi r26, 0x00
sound_driver_fx_Bxx_routine:
	lds ZL, song_frames
	lds ZH, song_frames+1
	clr r28 //initialize r29:r28 to 0
	clr r29
	inc r26 //increment xx parameter by 1
sound_driver_fx_Bxx_routine_loop:
	dec r26
	breq sound_driver_fx_Bxx_routine_loop_exit //once r26 == 0, r29:r28 will hold Bxx*(5*2).
	adiw r29:r28, 10 //increment the offset by 10 because 5 channels, and each address takes 2 bytes (5*2 = 10)
	rjmp sound_driver_fx_Bxx_routine_loop

sound_driver_fx_Bxx_routine_loop_exit:
	adiw r29:r28, 2 //add 2 to skip the first 2 bytes (first 2 bytes is the song size)
	sts song_frame_offset, r28
	sts song_frame_offset+1, r29
	add ZL, r28
	adc ZH, r29

	lpm r26, Z+ //load the address of the frame(pattern)
	lpm r27, Z+
	lsl r26
	rol r27
	sts pulse1_pattern, r26
	sts pulse1_pattern+1, r27
	lpm r26, Z+
	lpm r27, Z+
	lsl r26
	rol r27
	sts pulse2_pattern, r26
	sts pulse2_pattern+1, r27
	lpm r26, Z+
	lpm r27, Z+
	lsl r26
	rol r27
	sts triangle_pattern, r26
	sts triangle_pattern+1, r27
	lpm r26, Z+
	lpm r27, Z+
	lsl r26
	rol r27
	sts noise_pattern, r26
	sts noise_pattern+1, r27

	sts pulse1_pattern_offset, zero //restart the pattern offset back to 0 because we are reading from a new pattern now
	sts pulse1_pattern_offset+1, zero
	sts pulse1_pattern_delay_rows, zero //reset the delay to 0 as well
	sts pulse1_pattern_delay_frames, zero
	sts pulse2_pattern_offset, zero
	sts pulse2_pattern_offset+1, zero
	sts pulse2_pattern_delay_rows, zero
	sts pulse2_pattern_delay_frames, zero
	sts triangle_pattern_offset, zero
	sts triangle_pattern_offset+1, zero
	sts triangle_pattern_delay_rows, zero
	sts triangle_pattern_delay_frames, zero
	sts noise_pattern_offset, zero
	sts noise_pattern_offset+1, zero
	sts noise_pattern_delay_rows, zero
	sts noise_pattern_delay_frames, zero

	ldi r26, 0xFF
	sts pulse1_fx_Gxx_pre, r26 //reset all Gxx and Sxx effects. if we don't channels can get desynced
	sts pulse1_fx_Gxx_post, r26
	sts pulse1_fx_Sxx_pre, r26
	sts pulse1_fx_Sxx_post, r26
	sts pulse2_fx_Gxx_pre, r26
	sts pulse2_fx_Gxx_post, r26
	sts pulse2_fx_Sxx_pre, r26
	sts pulse2_fx_Sxx_post, r26
	sts triangle_fx_Gxx_pre, r26
	sts triangle_fx_Gxx_post, r26
	sts triangle_fx_Sxx_pre, r26
	sts triangle_fx_Sxx_post, r26
	sts noise_fx_Gxx_pre, r26
	sts noise_fx_Gxx_post, r26
	sts noise_fx_Sxx_pre, r26
	sts noise_fx_Sxx_post, r26

	sts song_fx_Bxx, r26 //reset all song effects
	sts song_fx_Cxx, zero
	sts song_fx_Dxx, zero
	rjmp sound_driver_channel0

sound_driver_fx_Cxx_routine:
	pop r31
	pop r30
	pop r29
	pop r28
	pop r27
	out CPU_SREG, r27
	cli //disable global interrupts
		
	ldi r26, 0xFF
	sts song_fx_Bxx, r26 //reset all song effects
	sts song_fx_Cxx, zero
	sts song_fx_Dxx, zero
	reti

sound_driver_fx_Dxx_routine:
	lds ZL, song_frames
	lds ZH, song_frames+1
	lds r26, song_frame_offset //we must offset to the appropriate channel
	lds r27, song_frame_offset+1
	adiw r27:r26, 10 //increment the frame offset by (5*2 = 10) since there are 5 channel patterns per frame. We *2 because we are getting byte values from the table
	sts song_frame_offset, r26
	sts song_frame_offset+1, r27
	add ZL, r26
	adc ZH, r27

	lpm r26, Z+ //load the address of the next pattern
	lpm r27, Z+
	lsl r26
	rol r27
	sts pulse1_pattern, r26
	sts pulse1_pattern+1, r27
	lpm r26, Z+
	lpm r27, Z+
	lsl r26
	rol r27
	sts pulse2_pattern, r26
	sts pulse2_pattern+1, r27
	lpm r26, Z+
	lpm r27, Z+
	lsl r26
	rol r27
	sts triangle_pattern, r26
	sts triangle_pattern+1, r27
	lpm r26, Z+
	lpm r27, Z+
	lsl r26
	rol r27
	sts noise_pattern, r26
	sts noise_pattern+1, r27

	sts pulse1_pattern_offset, zero //restart the pattern offset back to 0 because we are reading from a new pattern now
	sts pulse1_pattern_offset+1, zero
	sts pulse1_pattern_delay_rows, zero //reset the delay to 0 as well
	sts pulse1_pattern_delay_frames, zero
	sts pulse2_pattern_offset, zero
	sts pulse2_pattern_offset+1, zero
	sts pulse2_pattern_delay_rows, zero
	sts pulse2_pattern_delay_frames, zero
	sts triangle_pattern_offset, zero
	sts triangle_pattern_offset+1, zero
	sts triangle_pattern_delay_rows, zero
	sts triangle_pattern_delay_frames, zero
	sts noise_pattern_offset, zero
	sts noise_pattern_offset+1, zero
	sts noise_pattern_delay_rows, zero
	sts noise_pattern_delay_frames, zero

	ldi r26, 0xFF
	sts pulse1_fx_Gxx_pre, r26 //reset all Gxx and Sxx effects. if we don't channels can get desynced
	sts pulse1_fx_Gxx_post, r26
	sts pulse1_fx_Sxx_pre, r26
	sts pulse1_fx_Sxx_post, r26
	sts pulse2_fx_Gxx_pre, r26
	sts pulse2_fx_Gxx_post, r26
	sts pulse2_fx_Sxx_pre, r26
	sts pulse2_fx_Sxx_post, r26
	sts triangle_fx_Gxx_pre, r26
	sts triangle_fx_Gxx_post, r26
	sts triangle_fx_Sxx_pre, r26
	sts triangle_fx_Sxx_post, r26
	sts noise_fx_Gxx_pre, r26
	sts noise_fx_Gxx_post, r26
	sts noise_fx_Sxx_pre, r26
	sts noise_fx_Sxx_post, r26

	sts song_fx_Bxx, r26 //reset all song effects
	sts song_fx_Cxx, zero
	sts song_fx_Dxx, zero
	rjmp sound_driver_channel0



sound_driver_channel0:
	lds r26, pulse1_pattern_delay_rows
	lds r27, pulse1_pattern_delay_frames
	adiw r27:r26, 0
	breq sound_driver_channel0_main //if the pattern delay is 0, proceed with sound driver procedures
	rjmp sound_driver_channel0_decrement_frame_delay //if the pattern delay is not 0, decrement the delay

sound_driver_channel0_main:
	lds ZL, pulse1_pattern //current pattern for pulse 1
	lds ZH, pulse1_pattern+1
	lds r26, pulse1_pattern_offset //current offset in the pattern for pulse 1
	lds r27, pulse1_pattern_offset+1
	add ZL, r26 //offset the current pattern pointer to point to new byte data
	adc ZH, r27
	lpm r27, Z //load the byte data from the current pattern

sound_driver_channel0_check_if_note: //check if data is a note (0x00 - 0x56)
	cpi r27, 0x57
	brsh sound_driver_channel0_check_if_volume
	rjmp sound_driver_channel0_note
sound_driver_channel0_check_if_volume: //check if data is volume (0x57-0x66)
	cpi r27, 0x67
	brsh sound_driver_channel0_check_if_delay
	rjmp sound_driver_channel0_volume
sound_driver_channel0_check_if_delay: //check if data is a delay (0x67 - 0xE2)
	cpi r27, 0xE3
	brsh sound_driver_channel0_check_if_instrument
	rjmp sound_driver_channel0_delay
sound_driver_channel0_check_if_instrument: //check for instrument flag (0xE3)
	brne sound_driver_channel0_check_if_release
	rjmp sound_driver_channel0_instrument_change 
sound_driver_channel0_check_if_release: //check for note release flag (0xE4)
	cpi r27, 0xE4
	brne sound_driver_channel0_check_if_end
	rjmp sound_driver_channel0_release
sound_driver_channel0_check_if_end:
	cpi r27, 0xFF
	brne sound_driver_channel0_check_if_fx
	rjmp sound_driver_channel0_next_pattern



sound_driver_channel0_check_if_fx: //fx flags (0xE5 - 0xFE)
	adiw Z, 1 //point Z to the byte next to the flag
	lpm r26, Z //load the fx data into r26
	rcall sound_driver_channel0_increment_offset_twice

	subi r27, 0xE5 //prepare offset to perform table lookup
	ldi ZL, LOW(channel0_fx << 1) //load in note table
	ldi ZH, HIGH(channel0_fx << 1)
	lsl r27 //double the offset for the table because we are getting byte data
	add ZL, r27 //add offset
	adc ZH, zero
	lpm r28, Z+ //load address bytes
	lpm r29, Z
	mov ZL, r28 //move address bytes back into Z for an indirect jump
	mov ZH, r29
	ijmp


//ARPEGGIO
sound_driver_channel0_fx_0xy:
	sts pulse1_fx_0xy_sequence, r26
	sts pulse1_fx_0xy_sequence+1, zero
	rjmp sound_driver_channel0_main

//PITCH SLIDE UP
sound_driver_channel0_fx_1xx:
	sts pulse1_fx_2xx, zero //turn off any 2xx pitch slide down
	sts pulse1_fx_2xx+1, zero
	sts pulse1_fx_0xy_sequence, zero //disable any 0xy effect
	sts pulse1_fx_0xy_sequence+1, zero
	push r22 //only registers r16 - r23 can be used with mulsu
	push r23
	mov r22, r26 //store the rate into r22
	ldi r23, 0b10110010 //store r23 with 11.125 note: this is the closest approximation to the 11.1746014718 multiplier we can get with 8 bits
	mul r22, r23
	pop r23
	pop r22

	lsr r1 //shift out the fractional bits
	ror r0
	lsr r1
	ror r0
	lsr r1
	ror r0
	lsr r1
	ror r0
	sts pulse1_fx_1xx, r0
	sts pulse1_fx_1xx+1, r1
	rjmp sound_driver_channel0_main

//PITCH SLIDE DOWN
sound_driver_channel0_fx_2xx:
	sts pulse1_fx_1xx, zero //turn off any 1xx pitch slide down
	sts pulse1_fx_1xx+1, zero
	sts pulse1_fx_0xy_sequence, zero //disable any 0xy effect
	sts pulse1_fx_0xy_sequence+1, zero
	push r22 //only registers r16 - r23 can be used with mulsu
	push r23
	mov r22, r26 //store the rate into r22
	ldi r23, 0b10110010 //store r23 with 11.125 note: this is the closest approximation to the 11.1746014718 multiplier we can get with 8 bits
	mul r22, r23
	pop r23
	pop r22

	lsr r1 //shift out the fractional bits
	ror r0
	lsr r1
	ror r0
	lsr r1
	ror r0
	lsr r1
	ror r0
	sts pulse1_fx_2xx, r0
	sts pulse1_fx_2xx+1, r1
	rjmp sound_driver_channel0_main

//AUTOMATIC PORTAMENTO
sound_driver_channel0_fx_3xx:
	push r22 //only registers r16 - r23 can be used with mulsu
	push r23
	mov r22, r26 //store the rate into r22
	ldi r23, 0b10110010 //store r23 with 11.125 note: this is the closest approximation to the 11.1746014718 multiplier we can get with 8 bits
	mul r22, r23
	pop r23
	pop r22

	lsr r1 //shift out the fractional bits
	ror r0
	lsr r1
	ror r0
	lsr r1
	ror r0
	lsr r1
	ror r0
	sts pulse1_fx_3xx_speed, r0
	sts pulse1_fx_3xx_speed+1, r1

	cpse r26, zero //check if the effect was enabled or disabled
	rjmp sound_driver_channel0_fx_3xx_enabled
	rjmp sound_driver_channel0_main

sound_driver_channel0_fx_3xx_enabled:
	lds r26, TCB0_CCMPL //if the 3xx effect is enabled, we need to store the current timer period
	lds r27, TCB0_CCMPH
	sts pulse1_fx_3xx_start, r26
	sts pulse1_fx_3xx_start+1, r27

	sts pulse1_fx_3xx_total_offset, zero
	sts pulse1_fx_3xx_total_offset+1, zero
	rjmp sound_driver_channel0_main

//VIBRATO
sound_driver_channel0_fx_4xy:
	mov r27, r26
	andi r26, 0xF0 //mask r26 for x, the speed param
	swap r26
	andi r27, 0x0F //mask r27 for y, the depth param
	sts pulse1_fx_4xy_speed, r26
	sts pulse1_fx_4xy_depth, r27
	sts pulse1_fx_4xy_phase, zero //reset the phase to 0
	rjmp sound_driver_channel0_main

//TREMELO
sound_driver_channel0_fx_7xy:
	mov r27, r26
	andi r26, 0xF0 //mask r26 for x, the speed param
	swap r26
	andi r27, 0x0F //mask r27 for y, the depth param
	sts pulse1_fx_7xy_speed, r26
	sts pulse1_fx_7xy_depth, r27
	sts pulse1_fx_7xy_phase, zero //reset the phase to 0
	sts pulse1_fx_7xy_value, zero //reset the tremelo value
	rjmp sound_driver_channel0_main

//VOLUME SLIDE
sound_driver_channel0_fx_Axy:
	sts pulse1_fx_Axy, r26
	rjmp sound_driver_channel0_main

//FRAME JUMP
sound_driver_channel0_fx_Bxx:
	sts song_fx_Bxx, r26 //NOTE: a Bxx value of FF won't be detected since FF is used to indicate that the flag is disabled
	rjmp sound_driver_channel0_main

//HALT
sound_driver_channel0_fx_Cxx:
	sts song_fx_Cxx, r27 //NOTE: the value stored doesn't mean anything. we only need to check that it is non-zero
	rjmp sound_driver_channel0_main

//FRAME SKIP
sound_driver_channel0_fx_Dxx:
	sts song_fx_Dxx, r27 //NOTE: the value stored doesn't mean anything. we only need to check that it is non-zero
	rjmp sound_driver_channel0_main

//VOLUME
sound_driver_channel0_fx_Exx:
	lds r27, pulse1_param
	andi r27, 0xF0 //clear previous VVVV volume bits
	or r27, r26 //move new VVVV bits into pulse1_param
	sts pulse1_param, r27
	sbr pulse_channel_flags, 6
	rjmp sound_driver_channel0_main

//SPEED AND TEMPO
sound_driver_channel0_fx_Fxx:
	sts song_speed, r26 //NOTE: only changes to speed are supported
	rjmp sound_driver_channel0_main

//DELAY
sound_driver_channel0_fx_Gxx:
	cp r26, zero
	breq sound_driver_channel0_fx_Gxx_invalid
	lds r27, song_speed
	cp r26, r27
	brsh sound_driver_channel0_fx_Gxx_invalid
	sts pulse1_fx_Gxx_pre, r26 //NOTE: to be processed in the sound driver delay routine
	ldi r27, 0x01
	sts pulse1_pattern_delay_rows, r27
	rjmp sound_driver_channel1
sound_driver_channel0_fx_Gxx_invalid:
	rjmp sound_driver_channel0_main //if Gxx was 0 or >= the song speed, ignore it and continue reading note data

sound_driver_channel0_fx_Hxy: //hardware sweep up
	rjmp sound_driver_channel0_main
sound_driver_channel0_fx_Ixy: //hardware sweep down
	rjmp sound_driver_channel0_main
sound_driver_channel0_fx_Hxx: //FDS modulation depth
	rjmp sound_driver_channel0_main
sound_driver_channel0_fx_Ixx: //FDS modulation speed
	rjmp sound_driver_channel0_main

//FINE PITCH
sound_driver_channel0_fx_Pxx:
	push r22 //only registers r16 - r23 can be used with mulsu
	push r23
	mov r22, r26
	ldi r23, 0b10110010 //store r23 with 11.125 note: this is the closest approximation to the 11.1746014718 multiplier we can get with 8 bits
	mulsu r22, r23
	pop r23
	pop r22
	lsr r1 //shift out the fractional bits
	ror r0
	lsr r1
	ror r0
	lsr r1
	ror r0
	lsr r1
	ror r0
	sbrs r1, 3 //check if result was a negative number
	rjmp sound_driver_channel0_fx_Pxx_store //if the result was positive, don't fill with 1s

sound_driver_channel0_fx_Pxx_negative:
	ldi r27, 0xF0
	or r1, r27 //when right shifting a two's complement number, must use 1s instead of 0s to fill

sound_driver_channel0_fx_Pxx_store:
	sts pulse1_fx_Pxx_total, r0
	sts pulse1_fx_Pxx_total+1, r1
	rjmp sound_driver_channel0_main

//NOTE SLIDE UP
sound_driver_channel0_fx_Qxy:
sound_driver_channel0_fx_Qxy_check_arpeggio_macro:
	lds ZL, pulse1_arpeggio_macro
	lds ZH, pulse1_arpeggio_macro+1
	adiw Z, 0
	breq sound_driver_channel0_fx_Qxy_check_pitch_macro
	rjmp sound_driver_channel0_main //if there is an arpeggio macro, don't enable the effect

sound_driver_channel0_fx_Qxy_check_pitch_macro:
	lds ZL, pulse1_pitch_macro
	lds ZH, pulse1_pitch_macro+1
	adiw Z, 0
	breq sound_driver_channel0_fx_Qxy_check_hi_pitch_macro
	rjmp sound_driver_channel0_main //if there is a pitch macro, don't enable the effect

sound_driver_channel0_fx_Qxy_check_hi_pitch_macro:
	lds ZL, pulse1_hi_pitch_macro
	lds ZH, pulse1_hi_pitch_macro+1
	adiw Z, 0
	breq sound_driver_channel0_fx_Qxy_process
	rjmp sound_driver_channel0_main //if there is a pitch macro, don't enable the effect

sound_driver_channel0_fx_Qxy_process:
	mov r27, r26 //copy fx parameters into r27
	andi r27, 0x0F //mask note index offset
	lds r28, pulse1_fx_Qxy_target_note //load current note index
	add r27, r28
	cpi r27, 0x57 //largest possible note index is 0x56
	brlo sound_driver_channel0_fx_Qxy_process_continue
	ldi r27, 0x56 //if the target note was larger than the highest possible note index, keep the target at 0x56

sound_driver_channel0_fx_Qxy_process_continue:
	sts pulse1_fx_Qxy_target_note, r27
	ldi ZL, LOW(note_table << 1) //load in note table
	ldi ZH, HIGH(note_table << 1)
	lsl r27 //double the offset for the note table because we are getting byte data
	add ZL, r27 //add offset
	adc ZH, zero
	lpm r28, Z+ //load bytes
	lpm r29, Z
	sts pulse1_fx_Qxy_target, r28 //load the LOW bits for the target period
	sts pulse1_fx_Qxy_target+1, r29 //load the HIGH bits for the target period

sound_driver_channel0_fx_Qxy_process_speed:
	swap r26
	andi r26, 0x0F //mask effect speed
	lsl r26 //multiply the speed by 2 NOTE: formula for the speed is 2x+1
	inc r26 //increment the speed by 1

	push r22 //only registers r16 - r23 can be used with mulsu
	push r23
	mov r22, r26 //store the speed data into r27
	ldi r23, 0b10110010 //store r23 with 11.125 note: this is the closest approximation to the 11.1746014718 multiplier we can get with 8 bits
	mul r22, r23
	pop r23
	pop r22

	lsr r1 //shift out the fractional bits
	ror r0
	lsr r1
	ror r0
	lsr r1
	ror r0
	lsr r1
	ror r0

	sts pulse1_fx_Qxy_speed, r0 //store the effect speed
	sts pulse1_fx_Qxy_speed+1, r1
	rjmp sound_driver_channel0_main

//NOTE SLIDE DOWN
sound_driver_channel0_fx_Rxy:
sound_driver_channel0_fx_Rxy_check_arpeggio_macro:
	lds ZL, pulse1_arpeggio_macro
	lds ZH, pulse1_arpeggio_macro+1
	adiw Z, 0
	breq sound_driver_channel0_fx_Rxy_check_pitch_macro
	rjmp sound_driver_channel0_main //if there is an arpeggio macro, don't enable the effect

sound_driver_channel0_fx_Rxy_check_pitch_macro:
	lds ZL, pulse1_pitch_macro
	lds ZH, pulse1_pitch_macro+1
	adiw Z, 0
	breq sound_driver_channel0_fx_Rxy_check_hi_pitch_macro
	rjmp sound_driver_channel0_main //if there is a pitch macro, don't enable the effect

sound_driver_channel0_fx_Rxy_check_hi_pitch_macro:
	lds ZL, pulse1_hi_pitch_macro
	lds ZH, pulse1_hi_pitch_macro+1
	adiw Z, 0
	breq sound_driver_channel0_fx_Rxy_process
	rjmp sound_driver_channel0_main //if there is a pitch macro, don't enable the effect

sound_driver_channel0_fx_Rxy_process:
	mov r27, r26 //copy fx parameters into r27
	andi r27, 0x0F //mask note index offset
	lds r28, pulse1_fx_Rxy_target_note //load current note index
	sub r28, r27
	brcc sound_driver_channel0_fx_Rxy_process_continue
	ldi r28, 0x00

sound_driver_channel0_fx_Rxy_process_continue:
	sts pulse1_fx_Rxy_target_note, r28
	ldi ZL, LOW(note_table << 1) //load in note table
	ldi ZH, HIGH(note_table << 1)
	lsl r28 //double the offset for the note table because we are getting byte data
	add ZL, r28 //add offset
	adc ZH, zero
	lpm r28, Z+ //load bytes
	lpm r29, Z
	sts pulse1_fx_Rxy_target, r28 //load the LOW bits for the target period
	sts pulse1_fx_Rxy_target+1, r29 //load the HIGH bits for the target period

sound_driver_channel0_fx_Rxy_process_speed:
	swap r26
	andi r26, 0x0F //mask effect speed
	lsl r26 //multiply the speed by 2 NOTE: formula for the speed is 2x+1
	inc r26 //increment the speed by 1

	push r22 //only registers r16 - r23 can be used with mulsu
	push r23
	mov r22, r26 //store the speed data into r27
	ldi r23, 0b10110010 //store r23 with 11.125 note: this is the closest approximation to the 11.1746014718 multiplier we can get with 8 bits
	mul r22, r23
	pop r23
	pop r22

	lsr r1 //shift out the fractional bits
	ror r0
	lsr r1
	ror r0
	lsr r1
	ror r0
	lsr r1
	ror r0

	sts pulse1_fx_Rxy_speed, r0 //store the effect speed
	sts pulse1_fx_Rxy_speed+1, r1
	rjmp sound_driver_channel0_main

//MUTE DELAY
sound_driver_channel0_fx_Sxx:
	cp r26, zero
	breq sound_driver_channel0_fx_Sxx_invalid
	lds r27, song_speed
	cp r26, r27
	brsh sound_driver_channel0_fx_Sxx_invalid
	sts pulse1_fx_Sxx_pre, r26 //NOTE: to be processed in the sound driver delay routine
	ldi r27, 0x01
	sts pulse1_pattern_delay_rows, r27
	rjmp sound_driver_channel1
sound_driver_channel0_fx_Sxx_invalid:
	rjmp sound_driver_channel0_main //if Sxx was 0 or >= the song speed, ignore it and continue reading note data

//DUTY
sound_driver_channel0_fx_Vxx:
	ldi ZL, LOW(sequences << 1) //point Z to sequence table
	ldi ZH, HIGH(sequences << 1)
	add ZL, r26 //offset the pointer
	adc ZH, zero

	lsr r26 //move the duty cycle bits to the 2 MSB for pulse1_param (register $4000)
	ror r26
	ror r26
	lds r27, pulse1_param //load r27 with pulse1_param (register $4000)
	mov r28, r27 //store a copy of pulse1_param into r28
	andi r27, 0b11000000 //mask the duty cycle bits
	cpse r26, r27 //check if the previous duty cycle and the new duty cycle are equal
	rjmp sound_driver_channel0_fx_Vxx_store
	rjmp sound_driver_channel0_main //if the previous and new duty cycle are the same, don't reload the sequence

sound_driver_channel0_fx_Vxx_store:
	lpm pulse1_sequence, Z //store the sequence

	andi r28, 0b00111111 //mask out the duty cycle bits
	or r28, r27 //store the new duty cycle bits into r27
	sts pulse1_param, r28
	rjmp sound_driver_channel0_main

sound_driver_channel0_fx_Wxx: //DPCM sample speed
	rjmp sound_driver_channel0_main
sound_driver_channel0_fx_Xxx: //DPCM sample retrigger
	rjmp sound_driver_channel0_main
sound_driver_channel0_fx_Yxx: //DPCM sample offset
	rjmp sound_driver_channel0_main
sound_driver_channel0_fx_Zxx: //DPCM sample delta counter
	rjmp sound_driver_channel0_main


sound_driver_channel0_note:
	sts pulse1_note, r27 //store the note index
	sts pulse1_fx_Qxy_target_note, r27
	sts pulse1_fx_Rxy_target_note, r27
	ldi r26, 0x03
	ldi r27, 0x02
	sts pulse1_volume_macro_offset, r27 //reset all macro offsets
	sts pulse1_arpeggio_macro_offset, r26
	sts pulse1_pitch_macro_offset, r27
	sts pulse1_hi_pitch_macro_offset, r27
	sts pulse1_duty_macro_offset, r27
	sts pulse1_total_pitch_offset, zero //reset the pitch and hi pitch offset
	sts pulse1_total_pitch_offset+1, zero
	sts pulse1_total_hi_pitch_offset, zero
	sts pulse1_fx_1xx_total, zero //reset the total for 1xx and 2xx effects
	sts pulse1_fx_1xx_total+1, zero
	sts pulse1_fx_2xx_total, zero
	sts pulse1_fx_2xx_total+1, zero
	sts pulse1_fx_3xx_total_offset, zero //reset 3xx offset
	sts pulse1_fx_3xx_total_offset+1, zero
	lds r26, TCB0_CCMPL //if the 3xx effect is enabled, we need to store the current timer period
	lds r27, TCB0_CCMPH
	sts pulse1_fx_3xx_start, r26
	sts pulse1_fx_3xx_start+1, r27
	sts pulse1_sweep_param, zero //reset any sweep effect
	sbr pulse_channel_flags, 7 //set reload flag
	sts pulse1_fx_Qxy_target, zero //reset the Qxy, Rxy effects
	sts pulse1_fx_Qxy_target+1, zero
	sts pulse1_fx_Qxy_total_offset, zero
	sts pulse1_fx_Qxy_total_offset+1, zero
	sts pulse1_fx_Rxy_target, zero
	sts pulse1_fx_Rxy_target+1, zero
	sts pulse1_fx_Rxy_total_offset, zero
	sts pulse1_fx_Rxy_total_offset+1, zero
	rcall sound_driver_channel0_increment_offset
	rjmp sound_driver_channel0_main



sound_driver_channel0_volume:
	subi r27, 0x57 //NOTE: the delay values are offset by the highest volume value, which is 0x56
	lds r26, pulse1_param
	andi r26, 0xF0 //clear previous VVVV volume bits
	or r26, r27 //move new VVVV bits into pulse1_param
	sts pulse1_param, r26
	sbr pulse_channel_flags, 6
	rcall sound_driver_channel0_increment_offset
	rjmp sound_driver_channel0_main



sound_driver_channel0_delay:
	subi r27, 0x66 //NOTE: the delay values are offset by the highest volume value, which is 0x66
	sts pulse1_pattern_delay_rows, r27
	rcall sound_driver_channel0_increment_offset
	rjmp sound_driver_channel1



sound_driver_channel0_instrument_change:
	sts pulse1_volume_macro, zero //reset all macro addresses
	sts pulse1_volume_macro+1, zero
	sts pulse1_arpeggio_macro, zero
	sts pulse1_arpeggio_macro+1, zero
	sts pulse1_pitch_macro, zero
	sts pulse1_pitch_macro+1, zero
	sts pulse1_hi_pitch_macro, zero
	sts pulse1_hi_pitch_macro+1, zero
	sts pulse1_duty_macro, zero
	sts pulse1_duty_macro+1, zero
	sts pulse1_total_pitch_offset, zero //reset the pitch offset
	sts pulse1_total_pitch_offset+1, zero
	sts pulse1_total_hi_pitch_offset, zero //reset the hi pitch offset

	adiw Z, 1 //point to the byte next to the flag
	lpm r27, Z //store the instrument offset into r27
	ldi ZL, LOW(instruments) //point Z to instruments table
	ldi ZH, HIGH(instruments)
	add ZL, r27 //point Z to offsetted instrument
	adc ZH, zero
	lsl ZL //multiply by 2 to make Z into a byte pointer for the instrument's address
	rol ZH
	lpm r26, Z+ //r26:r27 now points to the instrument
	lpm r27, Z

	lsl r26 //multiply by 2 to make r26:r27 into a byte pointer for the instrument's data
	rol r27
	mov ZL, r26
	mov ZH, r27
	lpm r27, Z //get macro header byte. NOTE: Each macro type for each intrument is represented by a bit in this byte. 1 indicates that the instrument uses a macro of it's corresponding type.
	adiw Z, 2 //point Z to the address of the macro
	ldi r26, 6 //(6-1) = 5 for the 5 different macro types. NOTE: bit 0 = volume, bit 1 = arpeggio, bit 2 = pitch, bit 3 = hi pitch, bit 4 = duty
sound_driver_channel0_instrument_change_macro_loop:
	dec r26
	breq sound_driver_channel0_instrument_change_exit
	lsr r27
	brcs sound_driver_channel0_instrument_change_load_macro
	rjmp sound_driver_channel0_instrument_change_macro_loop



sound_driver_channel0_instrument_change_exit:
	ldi r26, 0x03
	ldi r27, 0x02
	sts pulse1_volume_macro_offset, r27 //reset all macro offsets
	sts pulse1_arpeggio_macro_offset, r26
	sts pulse1_pitch_macro_offset, r27
	sts pulse1_hi_pitch_macro_offset, r27
	sts pulse1_duty_macro_offset, r27
	rcall sound_driver_channel0_increment_offset_twice
	rjmp sound_driver_channel0_main



sound_driver_channel0_instrument_change_load_macro:
	lpm r28, Z+ //r28:r29 now point to the macro
	lpm r29, Z+

	cpi r26, 5
	breq sound_driver_channel0_instrument_change_load_macro_volume
	cpi r26, 4
	breq sound_driver_channel0_instrument_change_load_macro_arpeggio
	cpi r26, 3
	breq sound_driver_channel0_instrument_change_load_macro_pitch
	cpi r26, 2
	breq sound_driver_channel0_instrument_change_load_macro_hi_pitch
	rjmp sound_driver_channel0_instrument_change_load_macro_duty

sound_driver_channel0_instrument_change_load_macro_volume:
	sts pulse1_volume_macro, r28
	sts pulse1_volume_macro+1, r29
	rcall sound_driver_channel0_instrument_change_read_header
	sts pulse1_volume_macro_release, r28
	sts pulse1_volume_macro_loop, r29
	rjmp sound_driver_channel0_instrument_change_macro_loop
	
sound_driver_channel0_instrument_change_load_macro_arpeggio:
	sts pulse1_arpeggio_macro, r28
	sts pulse1_arpeggio_macro+1, r29
	sts pulse1_fx_Qxy_target, zero //reset the Qxy, Rxy effects
	sts pulse1_fx_Qxy_target+1, zero
	sts pulse1_fx_Rxy_target, zero
	sts pulse1_fx_Rxy_target+1, zero
	rcall sound_driver_channel0_instrument_change_read_header_arpeggio
	rjmp sound_driver_channel0_instrument_change_macro_loop

sound_driver_channel0_instrument_change_load_macro_pitch:
	sts pulse1_pitch_macro, r28
	sts pulse1_pitch_macro+1, r29
	sts pulse1_fx_Qxy_target, zero //reset the Qxy, Rxy effects
	sts pulse1_fx_Qxy_target+1, zero
	sts pulse1_fx_Rxy_target, zero
	sts pulse1_fx_Rxy_target+1, zero
	rcall sound_driver_channel0_instrument_change_read_header
	sts pulse1_pitch_macro_release, r28
	sts pulse1_pitch_macro_loop, r29
	rjmp sound_driver_channel0_instrument_change_macro_loop

sound_driver_channel0_instrument_change_load_macro_hi_pitch:
	sts pulse1_hi_pitch_macro, r28
	sts pulse1_hi_pitch_macro+1, r29
	sts pulse1_fx_Qxy_target, zero //reset the Qxy, Rxy effects
	sts pulse1_fx_Qxy_target+1, zero
	sts pulse1_fx_Rxy_target, zero
	sts pulse1_fx_Rxy_target+1, zero
	rcall sound_driver_channel0_instrument_change_read_header
	sts pulse1_hi_pitch_macro_release, r28
	sts pulse1_hi_pitch_macro_loop, r29
	rjmp sound_driver_channel0_instrument_change_macro_loop

sound_driver_channel0_instrument_change_load_macro_duty:
	sts pulse1_duty_macro, r28
	sts pulse1_duty_macro+1, r29
	rcall sound_driver_channel0_instrument_change_read_header
	sts pulse1_duty_macro_release, r28
	sts pulse1_duty_macro_loop, r29
	rjmp sound_driver_channel0_instrument_change_macro_loop



sound_driver_channel0_instrument_change_read_header:
	push ZL
	push ZH
	mov ZL, r28
	mov ZH, r29
	lsl ZL
	rol ZH
	lpm r28, Z+
	lpm r29, Z
	pop ZH
	pop ZL
	ret

sound_driver_channel0_instrument_change_read_header_arpeggio:
	push ZL
	push ZH
	mov ZL, r28
	mov ZH, r29
	lsl ZL
	rol ZH
	lpm r28, Z+
	lpm r29, Z+
	sts pulse1_arpeggio_macro_release, r28
	sts pulse1_arpeggio_macro_loop, r29
	lpm r28, Z
	sts pulse1_arpeggio_macro_mode, r28
	pop ZH
	pop ZL
	ret



sound_driver_channel0_release:
sound_driver_channel0_release_volume:
	lds r27, pulse1_volume_macro_release
	cpi r27, 0xFF //check if volume macro has a release flag
	breq sound_driver_channel0_release_arpeggio //if the macro has no release flag, check the next macro
	inc r27
	sts pulse1_volume_macro_offset, r27 //adjust offset so that it starts after the release flag index
sound_driver_channel0_release_arpeggio:
	lds r27, pulse1_arpeggio_macro_release
	cpi r27, 0xFF //check if arpeggio macro has a release flag
	breq sound_driver_channel0_release_pitch
	inc r27
	sts pulse1_arpeggio_macro_offset, r27
sound_driver_channel0_release_pitch:
	lds r27, pulse1_pitch_macro_release
	cpi r27, 0xFF //check if pitch macro has a release flag
	breq sound_driver_channel0_release_hi_pitch
	inc r27
	sts pulse1_pitch_macro_offset, r27
sound_driver_channel0_release_hi_pitch:
	lds r27, pulse1_hi_pitch_macro_release
	cpi r27, 0xFF //check if hi_pitch macro has a release flag
	breq sound_driver_channel0_release_duty
	inc r27
	sts pulse1_hi_pitch_macro_offset, r27
sound_driver_channel0_release_duty:
	lds r27, pulse1_duty_macro_release
	cpi r27, 0xFF //check if duty macro has a release flag
	breq sound_driver_channel0_release_exit
	inc r27
	sts pulse1_duty_macro_offset, r27
sound_driver_channel0_release_exit:
	rcall sound_driver_channel0_increment_offset
	rjmp sound_driver_channel0_main



sound_driver_channel0_next_pattern:
	lds ZL, song_frames
	lds ZH, song_frames+1
	lds r26, song_frame_offset //we must offset to the appropriate channel
	lds r27, song_frame_offset+1
	adiw r27:r26, 10 //increment the frame offset by (5*2 = 10) since there are 5 channel patterns per frame. We *2 because we are getting byte values from the table
	sts song_frame_offset, r26
	sts song_frame_offset+1, r27

	lds r28, song_size
	lds r29, song_size+1
	cp r26, r28
	cpc r27, r29
	brlo sound_driver_channel0_next_pattern_exists
	jmp sound_driver_exit

sound_driver_channel0_next_pattern_exists:
	add ZL, r26
	adc ZH, r27

	lpm r26, Z+ //load the address of the next pattern
	lpm r27, Z
	lsl r26
	rol r27
	sts pulse1_pattern, r26
	sts pulse1_pattern+1, r27

	sts pulse1_pattern_offset, zero //restart the pattern offset back to 0 because we are reading from a new pattern now
	sts pulse1_pattern_offset+1, zero
	rjmp sound_driver_channel0_main



sound_driver_channel0_increment_offset:
	lds ZL, pulse1_pattern_offset //current offset in the pattern for pulse 1
	lds ZH, pulse1_pattern_offset+1
	adiw Z, 1
	sts pulse1_pattern_offset, ZL
	sts pulse1_pattern_offset+1, ZH
	ret

sound_driver_channel0_increment_offset_twice: //used for data that takes up 2 bytes worth of space
	lds ZL, pulse1_pattern_offset //current offset in the pattern for pulse 1
	lds ZH, pulse1_pattern_offset+1
	adiw Z, 2 //increment the pointer twice
	sts pulse1_pattern_offset, ZL
	sts pulse1_pattern_offset+1, ZH
	ret

sound_driver_channel0_decrement_frame_delay:
	dec r27
	sts pulse1_pattern_delay_frames, r27



sound_driver_channel1:
	lds r26, pulse2_pattern_delay_rows
	lds r27, pulse2_pattern_delay_frames
	adiw r27:r26, 0
	breq sound_driver_channel1_main //if the pattern delay is 0, proceed with sound driver procedures
	rjmp sound_driver_channel1_decrement_frame_delay //if the pattern delay is not 0, decrement the delay

sound_driver_channel1_main:
	lds ZL, pulse2_pattern //current pattern for pulse 2
	lds ZH, pulse2_pattern+1
	lds r26, pulse2_pattern_offset //current offset in the pattern for pulse 2
	lds r27, pulse2_pattern_offset+1
	add ZL, r26 //offset the current pattern pointer to point to new byte data
	adc ZH, r27
	lpm r27, Z //load the byte data from the current pattern

sound_driver_channel1_check_if_note: //check if data is a note (0x00 - 0x56)
	cpi r27, 0x57
	brsh sound_driver_channel1_check_if_volume
	rjmp sound_driver_channel1_note
sound_driver_channel1_check_if_volume: //check if data is volume (0x57-0x66)
	cpi r27, 0x67
	brsh sound_driver_channel1_check_if_delay
	rjmp sound_driver_channel1_volume
sound_driver_channel1_check_if_delay: //check if data is a delay (0x67 - 0xE2)
	cpi r27, 0xE3
	brsh sound_driver_channel1_check_if_instrument
	rjmp sound_driver_channel1_delay
sound_driver_channel1_check_if_instrument: //check for instrument flag (0xE3)
	brne sound_driver_channel1_check_if_release
	rjmp sound_driver_channel1_instrument_change 
sound_driver_channel1_check_if_release: //check for note release flag (0xE4)
	cpi r27, 0xE4
	brne sound_driver_channel1_check_if_end
	rjmp sound_driver_channel1_release
sound_driver_channel1_check_if_end:
	cpi r27, 0xFF
	brne sound_driver_channel1_check_if_fx
	rjmp sound_driver_channel1_next_pattern



sound_driver_channel1_check_if_fx: //fx flags (0xE5 - 0xFE)
	adiw Z, 1 //point Z to the byte next to the flag
	lpm r26, Z //load the fx data into r26
	rcall sound_driver_channel1_increment_offset_twice

	subi r27, 0xE5 //prepare offset to perform table lookup
	ldi ZL, LOW(channel1_fx << 1) //load in note table
	ldi ZH, HIGH(channel1_fx << 1)
	lsl r27 //double the offset for the table because we are getting byte data
	add ZL, r27 //add offset
	adc ZH, zero
	lpm r28, Z+ //load address bytes
	lpm r29, Z
	mov ZL, r28 //move address bytes back into Z for an indirect jump
	mov ZH, r29
	ijmp


//ARPEGGIO
sound_driver_channel1_fx_0xy:
	sts pulse2_fx_0xy_sequence, r26
	sts pulse2_fx_0xy_sequence+1, zero
	rjmp sound_driver_channel1_main

//PITCH SLIDE UP
sound_driver_channel1_fx_1xx:
	sts pulse2_fx_2xx, zero //turn off any 2xx pitch slide down
	sts pulse2_fx_2xx+1, zero
	sts pulse2_fx_0xy_sequence, zero //disable any 0xy effect
	sts pulse2_fx_0xy_sequence+1, zero
	push r22 //only registers r16 - r23 can be used with mulsu
	push r23
	mov r22, r26 //store the rate into r22
	ldi r23, 0b10110010 //store r23 with 11.125 note: this is the closest approximation to the 11.1746014718 multiplier we can get with 8 bits
	mul r22, r23
	pop r23
	pop r22

	lsr r1 //shift out the fractional bits
	ror r0
	lsr r1
	ror r0
	lsr r1
	ror r0
	lsr r1
	ror r0
	sts pulse2_fx_1xx, r0
	sts pulse2_fx_1xx+1, r1
	rjmp sound_driver_channel1_main

//PITCH SLIDE DOWN
sound_driver_channel1_fx_2xx:
	sts pulse2_fx_1xx, zero //turn off any 1xx pitch slide down
	sts pulse2_fx_1xx+1, zero
	sts pulse2_fx_0xy_sequence, zero //disable any 0xy effect
	sts pulse2_fx_0xy_sequence+1, zero
	push r22 //only registers r16 - r23 can be used with mulsu
	push r23
	mov r22, r26 //store the rate into r22
	ldi r23, 0b10110010 //store r23 with 11.125 note: this is the closest approximation to the 11.1746014718 multiplier we can get with 8 bits
	mul r22, r23
	pop r23
	pop r22

	lsr r1 //shift out the fractional bits
	ror r0
	lsr r1
	ror r0
	lsr r1
	ror r0
	lsr r1
	ror r0
	sts pulse2_fx_2xx, r0
	sts pulse2_fx_2xx+1, r1
	rjmp sound_driver_channel1_main

//AUTOMATIC PORTAMENTO
sound_driver_channel1_fx_3xx:
	push r22 //only registers r16 - r23 can be used with mulsu
	push r23
	mov r22, r26 //store the rate into r22
	ldi r23, 0b10110010 //store r23 with 11.125 note: this is the closest approximation to the 11.1746014718 multiplier we can get with 8 bits
	mul r22, r23
	pop r23
	pop r22

	lsr r1 //shift out the fractional bits
	ror r0
	lsr r1
	ror r0
	lsr r1
	ror r0
	lsr r1
	ror r0
	sts pulse2_fx_3xx_speed, r0
	sts pulse2_fx_3xx_speed+1, r1

	cpse r26, zero //check if the effect was enabled or disabled
	rjmp sound_driver_channel1_fx_3xx_enabled
	rjmp sound_driver_channel1_main

sound_driver_channel1_fx_3xx_enabled:
	lds r26, TCB1_CCMPL //if the 3xx effect is enabled, we need to store the current timer period
	lds r27, TCB1_CCMPH
	sts pulse2_fx_3xx_start, r26
	sts pulse2_fx_3xx_start+1, r27

	sts pulse2_fx_3xx_total_offset, zero
	sts pulse2_fx_3xx_total_offset+1, zero
	rjmp sound_driver_channel1_main

//VIBRATO
sound_driver_channel1_fx_4xy:
	mov r27, r26
	andi r26, 0xF0 //mask r26 for x, the speed param
	swap r26
	andi r27, 0x0F //mask r27 for y, the depth param
	sts pulse2_fx_4xy_speed, r26
	sts pulse2_fx_4xy_depth, r27
	sts pulse2_fx_4xy_phase, zero //reset the phase to 0
	rjmp sound_driver_channel1_main

//TREMELO
sound_driver_channel1_fx_7xy:
	mov r27, r26
	andi r26, 0xF0 //mask r26 for x, the speed param
	swap r26
	andi r27, 0x0F //mask r27 for y, the depth param
	sts pulse2_fx_7xy_speed, r26
	sts pulse2_fx_7xy_depth, r27
	sts pulse2_fx_7xy_phase, zero //reset the phase to 0
	sts pulse2_fx_7xy_value, zero //reset the tremelo value
	rjmp sound_driver_channel1_main

//VOLUME SLIDE
sound_driver_channel1_fx_Axy:
	sts pulse2_fx_Axy, r26
	rjmp sound_driver_channel1_main

//FRAME JUMP
sound_driver_channel1_fx_Bxx:
	sts song_fx_Bxx, r26 //NOTE: a Bxx value of FF won't be detected since FF is used to indicate that the flag is disabled
	rjmp sound_driver_channel1_main

//HALT
sound_driver_channel1_fx_Cxx:
	sts song_fx_Cxx, r27 //NOTE: the value stored doesn't mean anything. we only need to check that it is non-zero
	rjmp sound_driver_channel1_main

//FRAME SKIP
sound_driver_channel1_fx_Dxx:
	sts song_fx_Dxx, r27 //NOTE: the value stored doesn't mean anything. we only need to check that it is non-zero
	rjmp sound_driver_channel1_main

//VOLUME
sound_driver_channel1_fx_Exx:
	lds r27, pulse2_param
	andi r27, 0xF0 //clear previous VVVV volume bits
	or r27, r26 //move new VVVV bits into pulse2_param
	sts pulse2_param, r27
	sbr pulse_channel_flags, 2
	rjmp sound_driver_channel1_main

//SPEED AND TEMPO
sound_driver_channel1_fx_Fxx:
	sts song_speed, r26 //NOTE: only changes to speed are supported
	rjmp sound_driver_channel1_main

//DELAY
sound_driver_channel1_fx_Gxx:
	cp r26, zero
	breq sound_driver_channel1_fx_Gxx_invalid
	lds r27, song_speed
	cp r26, r27
	brsh sound_driver_channel1_fx_Gxx_invalid
	sts pulse2_fx_Gxx_pre, r26 //NOTE: to be processed in the sound driver delay routine
	ldi r27, 0x01
	sts pulse2_pattern_delay_rows, r27
	rjmp sound_driver_channel2
sound_driver_channel1_fx_Gxx_invalid:
	rjmp sound_driver_channel1_main //if Gxx was 0 or >= the song speed, ignore it and continue reading note data

sound_driver_channel1_fx_Hxy: //hardware sweep up
	rjmp sound_driver_channel1_main
sound_driver_channel1_fx_Ixy: //hardware sweep down
	rjmp sound_driver_channel1_main
sound_driver_channel1_fx_Hxx: //FDS modulation depth
	rjmp sound_driver_channel1_main
sound_driver_channel1_fx_Ixx: //FDS modulation speed
	rjmp sound_driver_channel1_main

//FINE PITCH
sound_driver_channel1_fx_Pxx:
	push r22 //only registers r16 - r23 can be used with mulsu
	push r23
	mov r22, r26
	ldi r23, 0b10110010 //store r23 with 11.125 note: this is the closest approximation to the 11.1746014718 multiplier we can get with 8 bits
	mulsu r22, r23
	pop r23
	pop r22
	lsr r1 //shift out the fractional bits
	ror r0
	lsr r1
	ror r0
	lsr r1
	ror r0
	lsr r1
	ror r0
	sbrs r1, 3 //check if result was a negative number
	rjmp sound_driver_channel1_fx_Pxx_store //if the result was positive, don't fill with 1s

sound_driver_channel1_fx_Pxx_negative:
	ldi r27, 0xF0
	or r1, r27 //when right shifting a two's complement number, must use 1s instead of 0s to fill

sound_driver_channel1_fx_Pxx_store:
	sts pulse2_fx_Pxx_total, r0
	sts pulse2_fx_Pxx_total+1, r1
	rjmp sound_driver_channel1_main

//NOTE SLIDE UP
sound_driver_channel1_fx_Qxy:
sound_driver_channel1_fx_Qxy_check_arpeggio_macro:
	lds ZL, pulse2_arpeggio_macro
	lds ZH, pulse2_arpeggio_macro+1
	adiw Z, 0
	breq sound_driver_channel1_fx_Qxy_check_pitch_macro
	rjmp sound_driver_channel1_main //if there is an arpeggio macro, don't enable the effect

sound_driver_channel1_fx_Qxy_check_pitch_macro:
	lds ZL, pulse2_pitch_macro
	lds ZH, pulse2_pitch_macro+1
	adiw Z, 0
	breq sound_driver_channel1_fx_Qxy_check_hi_pitch_macro
	rjmp sound_driver_channel1_main //if there is a pitch macro, don't enable the effect

sound_driver_channel1_fx_Qxy_check_hi_pitch_macro:
	lds ZL, pulse2_hi_pitch_macro
	lds ZH, pulse2_hi_pitch_macro+1
	adiw Z, 0
	breq sound_driver_channel1_fx_Qxy_process
	rjmp sound_driver_channel1_main //if there is a pitch macro, don't enable the effect

sound_driver_channel1_fx_Qxy_process:
	mov r27, r26 //copy fx parameters into r27
	andi r27, 0x0F //mask note index offset
	lds r28, pulse2_fx_Qxy_target_note //load current note index
	add r27, r28
	cpi r27, 0x57 //largest possible note index is 0x56
	brlo sound_driver_channel1_fx_Qxy_process_continue
	ldi r27, 0x56 //if the target note was larger than the highest possible note index, keep the target at 0x56

sound_driver_channel1_fx_Qxy_process_continue:
	sts pulse2_fx_Qxy_target_note, r27
	ldi ZL, LOW(note_table << 1) //load in note table
	ldi ZH, HIGH(note_table << 1)
	lsl r27 //double the offset for the note table because we are getting byte data
	add ZL, r27 //add offset
	adc ZH, zero
	lpm r28, Z+ //load bytes
	lpm r29, Z
	sts pulse2_fx_Qxy_target, r28 //load the LOW bits for the target period
	sts pulse2_fx_Qxy_target+1, r29 //load the HIGH bits for the target period

sound_driver_channel1_fx_Qxy_process_speed:
	swap r26
	andi r26, 0x0F //mask effect speed
	lsl r26 //multiply the speed by 2 NOTE: formula for the speed is 2x+1
	inc r26 //increment the speed by 1

	push r22 //only registers r16 - r23 can be used with mulsu
	push r23
	mov r22, r26 //store the speed data into r27
	ldi r23, 0b10110010 //store r23 with 11.125 note: this is the closest approximation to the 11.1746014718 multiplier we can get with 8 bits
	mul r22, r23
	pop r23
	pop r22

	lsr r1 //shift out the fractional bits
	ror r0
	lsr r1
	ror r0
	lsr r1
	ror r0
	lsr r1
	ror r0

	sts pulse2_fx_Qxy_speed, r0 //store the effect speed
	sts pulse2_fx_Qxy_speed+1, r1
	rjmp sound_driver_channel1_main

//NOTE SLIDE DOWN
sound_driver_channel1_fx_Rxy:
sound_driver_channel1_fx_Rxy_check_arpeggio_macro:
	lds ZL, pulse2_arpeggio_macro
	lds ZH, pulse2_arpeggio_macro+1
	adiw Z, 0
	breq sound_driver_channel1_fx_Rxy_check_pitch_macro
	rjmp sound_driver_channel1_main //if there is an arpeggio macro, don't enable the effect

sound_driver_channel1_fx_Rxy_check_pitch_macro:
	lds ZL, pulse2_pitch_macro
	lds ZH, pulse2_pitch_macro+1
	adiw Z, 0
	breq sound_driver_channel1_fx_Rxy_check_hi_pitch_macro
	rjmp sound_driver_channel1_main //if there is a pitch macro, don't enable the effect

sound_driver_channel1_fx_Rxy_check_hi_pitch_macro:
	lds ZL, pulse2_hi_pitch_macro
	lds ZH, pulse2_hi_pitch_macro+1
	adiw Z, 0
	breq sound_driver_channel1_fx_Rxy_process
	rjmp sound_driver_channel1_main //if there is a pitch macro, don't enable the effect

sound_driver_channel1_fx_Rxy_process:
	mov r27, r26 //copy fx parameters into r27
	andi r27, 0x0F //mask note index offset
	lds r28, pulse2_fx_Rxy_target_note //load current note index
	sub r28, r27
	brcc sound_driver_channel1_fx_Rxy_process_continue
	ldi r28, 0x00

sound_driver_channel1_fx_Rxy_process_continue:
	sts pulse2_fx_Rxy_target_note, r28
	ldi ZL, LOW(note_table << 1) //load in note table
	ldi ZH, HIGH(note_table << 1)
	lsl r28 //double the offset for the note table because we are getting byte data
	add ZL, r28 //add offset
	adc ZH, zero
	lpm r28, Z+ //load bytes
	lpm r29, Z
	sts pulse2_fx_Rxy_target, r28 //load the LOW bits for the target period
	sts pulse2_fx_Rxy_target+1, r29 //load the HIGH bits for the target period

sound_driver_channel1_fx_Rxy_process_speed:
	swap r26
	andi r26, 0x0F //mask effect speed
	lsl r26 //multiply the speed by 2 NOTE: formula for the speed is 2x+1
	inc r26 //increment the speed by 1

	push r22 //only registers r16 - r23 can be used with mulsu
	push r23
	mov r22, r26 //store the speed data into r27
	ldi r23, 0b10110010 //store r23 with 11.125 note: this is the closest approximation to the 11.1746014718 multiplier we can get with 8 bits
	mul r22, r23
	pop r23
	pop r22

	lsr r1 //shift out the fractional bits
	ror r0
	lsr r1
	ror r0
	lsr r1
	ror r0
	lsr r1
	ror r0

	sts pulse2_fx_Rxy_speed, r0 //store the effect speed
	sts pulse2_fx_Rxy_speed+1, r1
	rjmp sound_driver_channel1_main

//MUTE DELAY
sound_driver_channel1_fx_Sxx:
	cp r26, zero
	breq sound_driver_channel1_fx_Sxx_invalid
	lds r27, song_speed
	cp r26, r27
	brsh sound_driver_channel1_fx_Sxx_invalid
	sts pulse2_fx_Sxx_pre, r26 //NOTE: to be processed in the sound driver delay routine
	ldi r27, 0x01
	sts pulse2_pattern_delay_rows, r27
	rjmp sound_driver_channel2
sound_driver_channel1_fx_Sxx_invalid:
	rjmp sound_driver_channel1_main //if Sxx was 0 or >= the song speed, ignore it and continue reading note data

//DUTY
sound_driver_channel1_fx_Vxx:
	ldi ZL, LOW(sequences << 1) //point Z to sequence table
	ldi ZH, HIGH(sequences << 1)
	add ZL, r26 //offset the pointer
	adc ZH, zero

	lsr r26 //move the duty cycle bits to the 2 MSB for pulse2_param (register $4000)
	ror r26
	ror r26
	lds r27, pulse2_param //load r27 with pulse2_param (register $4000)
	mov r28, r27 //store a copy of pulse2_param into r28
	andi r27, 0b11000000 //mask the duty cycle bits
	cpse r26, r27 //check if the previous duty cycle and the new duty cycle are equal
	rjmp sound_driver_channel1_fx_Vxx_store
	rjmp sound_driver_channel1_main //if the previous and new duty cycle are the same, don't reload the sequence

sound_driver_channel1_fx_Vxx_store:
	lpm pulse2_sequence, Z //store the sequence

	andi r28, 0b00111111 //mask out the duty cycle bits
	or r28, r27 //store the new duty cycle bits into r27
	sts pulse2_param, r28
	rjmp sound_driver_channel1_main

sound_driver_channel1_fx_Wxx: //DPCM sample speed
	rjmp sound_driver_channel1_main
sound_driver_channel1_fx_Xxx: //DPCM sample retrigger
	rjmp sound_driver_channel1_main
sound_driver_channel1_fx_Yxx: //DPCM sample offset
	rjmp sound_driver_channel1_main
sound_driver_channel1_fx_Zxx: //DPCM sample delta counter
	rjmp sound_driver_channel1_main


sound_driver_channel1_note:
	sts pulse2_note, r27 //store the note index
	sts pulse2_fx_Qxy_target_note, r27
	sts pulse2_fx_Rxy_target_note, r27
	ldi r26, 0x03
	ldi r27, 0x02
	sts pulse2_volume_macro_offset, r27 //reset all macro offsets
	sts pulse2_arpeggio_macro_offset, r26
	sts pulse2_pitch_macro_offset, r27
	sts pulse2_hi_pitch_macro_offset, r27
	sts pulse2_duty_macro_offset, r27
	sts pulse2_total_pitch_offset, zero //reset the pitch and hi pitch offset
	sts pulse2_total_pitch_offset+1, zero
	sts pulse2_total_hi_pitch_offset, zero
	sts pulse2_fx_1xx_total, zero //reset the total for 1xx and 2xx effects
	sts pulse2_fx_1xx_total+1, zero
	sts pulse2_fx_2xx_total, zero
	sts pulse2_fx_2xx_total+1, zero
	sts pulse2_fx_3xx_total_offset, zero //reset 3xx offset
	sts pulse2_fx_3xx_total_offset+1, zero
	lds r26, TCB1_CCMPL //if the 3xx effect is enabled, we need to store the current timer period
	lds r27, TCB1_CCMPH
	sts pulse2_fx_3xx_start, r26
	sts pulse2_fx_3xx_start+1, r27
	sts pulse2_sweep_param, zero //reset any sweep effect
	sbr pulse_channel_flags, 3 //set reload flag
	sts pulse2_fx_Qxy_target, zero //reset the Qxy, Rxy effects
	sts pulse2_fx_Qxy_target+1, zero
	sts pulse2_fx_Qxy_total_offset, zero
	sts pulse2_fx_Qxy_total_offset+1, zero
	sts pulse2_fx_Rxy_target, zero
	sts pulse2_fx_Rxy_target+1, zero
	sts pulse2_fx_Rxy_total_offset, zero
	sts pulse2_fx_Rxy_total_offset+1, zero
	rcall sound_driver_channel1_increment_offset
	rjmp sound_driver_channel1_main



sound_driver_channel1_volume:
	subi r27, 0x57 //NOTE: the delay values are offset by the highest volume value, which is 0x56
	lds r26, pulse2_param
	andi r26, 0xF0 //clear previous VVVV volume bits
	or r26, r27 //move new VVVV bits into pulse2_param
	sts pulse2_param, r26
	sbr pulse_channel_flags, 2
	rcall sound_driver_channel1_increment_offset
	rjmp sound_driver_channel1_main



sound_driver_channel1_delay:
	subi r27, 0x66 //NOTE: the delay values are offset by the highest volume value, which is 0x66
	sts pulse2_pattern_delay_rows, r27
	rcall sound_driver_channel1_increment_offset
	rjmp sound_driver_channel2



sound_driver_channel1_instrument_change:
	sts pulse2_volume_macro, zero //reset all macro addresses
	sts pulse2_volume_macro+1, zero
	sts pulse2_arpeggio_macro, zero
	sts pulse2_arpeggio_macro+1, zero
	sts pulse2_pitch_macro, zero
	sts pulse2_pitch_macro+1, zero
	sts pulse2_hi_pitch_macro, zero
	sts pulse2_hi_pitch_macro+1, zero
	sts pulse2_duty_macro, zero
	sts pulse2_duty_macro+1, zero
	sts pulse2_total_pitch_offset, zero //reset the pitch offset
	sts pulse2_total_pitch_offset+1, zero
	sts pulse2_total_hi_pitch_offset, zero //reset the hi pitch offset

	adiw Z, 1 //point to the byte next to the flag
	lpm r27, Z //store the instrument offset into r27
	ldi ZL, LOW(instruments) //point Z to instruments table
	ldi ZH, HIGH(instruments)
	add ZL, r27 //point Z to offsetted instrument
	adc ZH, zero
	lsl ZL //multiply by 2 to make Z into a byte pointer for the instrument's address
	rol ZH
	lpm r26, Z+ //r26:r27 now points to the instrument
	lpm r27, Z

	lsl r26 //multiply by 2 to make r26:r27 into a byte pointer for the instrument's data
	rol r27
	mov ZL, r26
	mov ZH, r27
	lpm r27, Z //get macro header byte. NOTE: Each macro type for each intrument is represented by a bit in this byte. 1 indicates that the instrument uses a macro of it's corresponding type.
	adiw Z, 2 //point Z to the address of the macro
	ldi r26, 6 //(6-1) = 5 for the 5 different macro types. NOTE: bit 0 = volume, bit 1 = arpeggio, bit 2 = pitch, bit 3 = hi pitch, bit 4 = duty
sound_driver_channel1_instrument_change_macro_loop:
	dec r26
	breq sound_driver_channel1_instrument_change_exit
	lsr r27
	brcs sound_driver_channel1_instrument_change_load_macro
	rjmp sound_driver_channel1_instrument_change_macro_loop



sound_driver_channel1_instrument_change_exit:
	ldi r26, 0x03
	ldi r27, 0x02
	sts pulse2_volume_macro_offset, r27 //reset all macro offsets
	sts pulse2_arpeggio_macro_offset, r26
	sts pulse2_pitch_macro_offset, r27
	sts pulse2_hi_pitch_macro_offset, r27
	sts pulse2_duty_macro_offset, r27
	rcall sound_driver_channel1_increment_offset_twice
	rjmp sound_driver_channel1_main



sound_driver_channel1_instrument_change_load_macro:
	lpm r28, Z+ //r28:r29 now point to the macro
	lpm r29, Z+

	cpi r26, 5
	breq sound_driver_channel1_instrument_change_load_macro_volume
	cpi r26, 4
	breq sound_driver_channel1_instrument_change_load_macro_arpeggio
	cpi r26, 3
	breq sound_driver_channel1_instrument_change_load_macro_pitch
	cpi r26, 2
	breq sound_driver_channel1_instrument_change_load_macro_hi_pitch
	rjmp sound_driver_channel1_instrument_change_load_macro_duty

sound_driver_channel1_instrument_change_load_macro_volume:
	sts pulse2_volume_macro, r28
	sts pulse2_volume_macro+1, r29
	rcall sound_driver_channel1_instrument_change_read_header
	sts pulse2_volume_macro_release, r28
	sts pulse2_volume_macro_loop, r29
	rjmp sound_driver_channel1_instrument_change_macro_loop
	
sound_driver_channel1_instrument_change_load_macro_arpeggio:
	sts pulse2_arpeggio_macro, r28
	sts pulse2_arpeggio_macro+1, r29
	sts pulse2_fx_Qxy_target, zero //reset the Qxy, Rxy effects
	sts pulse2_fx_Qxy_target+1, zero
	sts pulse2_fx_Rxy_target, zero
	sts pulse2_fx_Rxy_target+1, zero
	rcall sound_driver_channel1_instrument_change_read_header_arpeggio
	rjmp sound_driver_channel1_instrument_change_macro_loop

sound_driver_channel1_instrument_change_load_macro_pitch:
	sts pulse2_pitch_macro, r28
	sts pulse2_pitch_macro+1, r29
	sts pulse2_fx_Qxy_target, zero //reset the Qxy, Rxy effects
	sts pulse2_fx_Qxy_target+1, zero
	sts pulse2_fx_Rxy_target, zero
	sts pulse2_fx_Rxy_target+1, zero
	rcall sound_driver_channel1_instrument_change_read_header
	sts pulse2_pitch_macro_release, r28
	sts pulse2_pitch_macro_loop, r29
	rjmp sound_driver_channel1_instrument_change_macro_loop

sound_driver_channel1_instrument_change_load_macro_hi_pitch:
	sts pulse2_hi_pitch_macro, r28
	sts pulse2_hi_pitch_macro+1, r29
	sts pulse2_fx_Qxy_target, zero //reset the Qxy, Rxy effects
	sts pulse2_fx_Qxy_target+1, zero
	sts pulse2_fx_Rxy_target, zero
	sts pulse2_fx_Rxy_target+1, zero
	rcall sound_driver_channel1_instrument_change_read_header
	sts pulse2_hi_pitch_macro_release, r28
	sts pulse2_hi_pitch_macro_loop, r29
	rjmp sound_driver_channel1_instrument_change_macro_loop

sound_driver_channel1_instrument_change_load_macro_duty:
	sts pulse2_duty_macro, r28
	sts pulse2_duty_macro+1, r29
	rcall sound_driver_channel1_instrument_change_read_header
	sts pulse2_duty_macro_release, r28
	sts pulse2_duty_macro_loop, r29
	rjmp sound_driver_channel1_instrument_change_macro_loop



sound_driver_channel1_instrument_change_read_header:
	push ZL
	push ZH
	mov ZL, r28
	mov ZH, r29
	lsl ZL
	rol ZH
	lpm r28, Z+
	lpm r29, Z
	pop ZH
	pop ZL
	ret

sound_driver_channel1_instrument_change_read_header_arpeggio:
	push ZL
	push ZH
	mov ZL, r28
	mov ZH, r29
	lsl ZL
	rol ZH
	lpm r28, Z+
	lpm r29, Z+
	sts pulse2_arpeggio_macro_release, r28
	sts pulse2_arpeggio_macro_loop, r29
	lpm r28, Z
	sts pulse2_arpeggio_macro_mode, r28
	pop ZH
	pop ZL
	ret



sound_driver_channel1_release:
sound_driver_channel1_release_volume:
	lds r27, pulse2_volume_macro_release
	cpi r27, 0xFF //check if volume macro has a release flag
	breq sound_driver_channel1_release_arpeggio //if the macro has no release flag, check the next macro
	inc r27
	sts pulse2_volume_macro_offset, r27 //adjust offset so that it starts after the release flag index
sound_driver_channel1_release_arpeggio:
	lds r27, pulse2_arpeggio_macro_release
	cpi r27, 0xFF //check if arpeggio macro has a release flag
	breq sound_driver_channel1_release_pitch
	inc r27
	sts pulse2_arpeggio_macro_offset, r27
sound_driver_channel1_release_pitch:
	lds r27, pulse2_pitch_macro_release
	cpi r27, 0xFF //check if pitch macro has a release flag
	breq sound_driver_channel1_release_hi_pitch
	inc r27
	sts pulse2_pitch_macro_offset, r27
sound_driver_channel1_release_hi_pitch:
	lds r27, pulse2_hi_pitch_macro_release
	cpi r27, 0xFF //check if hi_pitch macro has a release flag
	breq sound_driver_channel1_release_duty
	inc r27
	sts pulse2_hi_pitch_macro_offset, r27
sound_driver_channel1_release_duty:
	lds r27, pulse2_duty_macro_release
	cpi r27, 0xFF //check if duty macro has a release flag
	breq sound_driver_channel1_release_exit
	inc r27
	sts pulse2_duty_macro_offset, r27
sound_driver_channel1_release_exit:
	rcall sound_driver_channel1_increment_offset
	rjmp sound_driver_channel1_main



sound_driver_channel1_next_pattern:
	lds ZL, song_frames
	lds ZH, song_frames+1
	lds r26, song_frame_offset //we must offset to the appropriate channel
	lds r27, song_frame_offset+1
	adiw r27:r26, 2 //offset for channel 1
	add ZL, r26
	adc ZH, r27

	lpm r26, Z+ //load the address of the next pattern
	lpm r27, Z
	lsl r26
	rol r27
	sts pulse2_pattern, r26
	sts pulse2_pattern+1, r27

	sts pulse2_pattern_offset, zero //restart the pattern offset back to 0 because we are reading from a new pattern now
	sts pulse2_pattern_offset+1, zero
	rjmp sound_driver_channel1_main



sound_driver_channel1_increment_offset:
	lds ZL, pulse2_pattern_offset //current offset in the pattern for pulse 2
	lds ZH, pulse2_pattern_offset+1
	adiw Z, 1
	sts pulse2_pattern_offset, ZL
	sts pulse2_pattern_offset+1, ZH
	ret

sound_driver_channel1_increment_offset_twice: //used for data that takes up 2 bytes worth of space
	lds ZL, pulse2_pattern_offset //current offset in the pattern for pulse 2
	lds ZH, pulse2_pattern_offset+1
	adiw Z, 2 //increment the pointer twice
	sts pulse2_pattern_offset, ZL
	sts pulse2_pattern_offset+1, ZH
	ret

sound_driver_channel1_decrement_frame_delay:
	dec r27
	sts pulse2_pattern_delay_frames, r27



sound_driver_channel2:
	lds r26, triangle_pattern_delay_rows
	lds r27, triangle_pattern_delay_frames
	adiw r27:r26, 0
	breq sound_driver_channel2_main //if the pattern delay is 0, proceed with sound driver procedures
	rjmp sound_driver_channel2_decrement_frame_delay //if the pattern delay is not 0, decrement the delay

sound_driver_channel2_main:
	lds ZL, triangle_pattern //current pattern for triangle
	lds ZH, triangle_pattern+1
	lds r26, triangle_pattern_offset //current offset in the pattern for triangle
	lds r27, triangle_pattern_offset+1
	add ZL, r26 //offset the current pattern pointer to point to new byte data
	adc ZH, r27
	lpm r27, Z //load the byte data from the current pattern

sound_driver_channel2_check_if_note: //check if data is a note (0x00 - 0x56)
	cpi r27, 0x57
	brsh sound_driver_channel2_check_if_volume
	rjmp sound_driver_channel2_note
sound_driver_channel2_check_if_volume: //check if data is volume (0x57-0x66)
	cpi r27, 0x67
	brsh sound_driver_channel2_check_if_delay
	rjmp sound_driver_channel2_volume
sound_driver_channel2_check_if_delay: //check if data is a delay (0x67 - 0xE2)
	cpi r27, 0xE3
	brsh sound_driver_channel2_check_if_instrument
	rjmp sound_driver_channel2_delay
sound_driver_channel2_check_if_instrument: //check for instrument flag (0xE3)
	brne sound_driver_channel2_check_if_release
	rjmp sound_driver_channel2_instrument_change 
sound_driver_channel2_check_if_release: //check for note release flag (0xE4)
	cpi r27, 0xE4
	brne sound_driver_channel2_check_if_end
	rjmp sound_driver_channel2_release
sound_driver_channel2_check_if_end:
	cpi r27, 0xFF
	brne sound_driver_channel2_check_if_fx
	rjmp sound_driver_channel2_next_pattern



sound_driver_channel2_check_if_fx: //fx flags (0xE5 - 0xFE)
	adiw Z, 1 //point Z to the byte next to the flag
	lpm r26, Z //load the fx data into r26
	rcall sound_driver_channel2_increment_offset_twice

	subi r27, 0xE5 //prepare offset to perform table lookup
	ldi ZL, LOW(channel2_fx << 1) //load in note table
	ldi ZH, HIGH(channel2_fx << 1)
	lsl r27 //double the offset for the table because we are getting byte data
	add ZL, r27 //add offset
	adc ZH, zero
	lpm r28, Z+ //load address bytes
	lpm r29, Z
	mov ZL, r28 //move address bytes back into Z for an indirect jump
	mov ZH, r29
	ijmp


//ARPEGGIO
sound_driver_channel2_fx_0xy:
	sts triangle_fx_0xy_sequence, r26
	sts triangle_fx_0xy_sequence+1, zero
	rjmp sound_driver_channel2_main

//PITCH SLIDE UP
sound_driver_channel2_fx_1xx:
	sts triangle_fx_2xx, zero //turn off any 2xx pitch slide down
	sts triangle_fx_2xx+1, zero
	sts triangle_fx_0xy_sequence, zero //disable any 0xy effect
	sts triangle_fx_0xy_sequence+1, zero
	push r22 //only registers r16 - r23 can be used with mulsu
	push r23
	mov r22, r26 //store the rate into r22
	ldi r23, 0b10110010 //store r23 with 11.125 note: this is the closest approximation to the 11.1746014718 multiplier we can get with 8 bits
	mul r22, r23
	pop r23
	pop r22

	lsr r1 //shift out the fractional bits
	ror r0
	lsr r1
	ror r0
	lsr r1
	ror r0
	lsr r1
	ror r0
	sts triangle_fx_1xx, r0
	sts triangle_fx_1xx+1, r1
	rjmp sound_driver_channel2_main

//PITCH SLIDE DOWN
sound_driver_channel2_fx_2xx:
	sts triangle_fx_1xx, zero //turn off any 1xx pitch slide down
	sts triangle_fx_1xx+1, zero
	sts triangle_fx_0xy_sequence, zero //disable any 0xy effect
	sts triangle_fx_0xy_sequence+1, zero
	push r22 //only registers r16 - r23 can be used with mulsu
	push r23
	mov r22, r26 //store the rate into r22
	ldi r23, 0b10110010 //store r23 with 11.125 note: this is the closest approximation to the 11.1746014718 multiplier we can get with 8 bits
	mul r22, r23
	pop r23
	pop r22

	lsr r1 //shift out the fractional bits
	ror r0
	lsr r1
	ror r0
	lsr r1
	ror r0
	lsr r1
	ror r0
	sts triangle_fx_2xx, r0
	sts triangle_fx_2xx+1, r1
	rjmp sound_driver_channel2_main

//AUTOMATIC PORTAMENTO
sound_driver_channel2_fx_3xx:
	push r22 //only registers r16 - r23 can be used with mulsu
	push r23
	mov r22, r26 //store the rate into r22
	ldi r23, 0b10110010 //store r23 with 11.125 note: this is the closest approximation to the 11.1746014718 multiplier we can get with 8 bits
	mul r22, r23
	pop r23
	pop r22

	lsr r1 //shift out the fractional bits
	ror r0
	lsr r1
	ror r0
	lsr r1
	ror r0
	lsr r1
	ror r0
	sts triangle_fx_3xx_speed, r0
	sts triangle_fx_3xx_speed+1, r1

	cpse r26, zero //check if the effect was enabled or disabled
	rjmp sound_driver_channel2_fx_3xx_enabled
	rjmp sound_driver_channel2_main

sound_driver_channel2_fx_3xx_enabled:
	lds r26, TCB2_CCMPL //if the 3xx effect is enabled, we need to store the current timer period
	lds r27, TCB2_CCMPH
	sts triangle_fx_3xx_start, r26
	sts triangle_fx_3xx_start+1, r27

	sts triangle_fx_3xx_total_offset, zero
	sts triangle_fx_3xx_total_offset+1, zero
	rjmp sound_driver_channel2_main

//VIBRATO
sound_driver_channel2_fx_4xy:
	mov r27, r26
	andi r26, 0xF0 //mask r26 for x, the speed param
	swap r26
	andi r27, 0x0F //mask r27 for y, the depth param
	sts triangle_fx_4xy_speed, r26
	sts triangle_fx_4xy_depth, r27
	sts triangle_fx_4xy_phase, zero //reset the phase to 0
	rjmp sound_driver_channel2_main

sound_driver_channel2_fx_7xy: //tremelo
	rjmp sound_driver_channel2_main
sound_driver_channel2_fx_Axy: //volume slide
	rjmp sound_driver_channel2_main

//FRAME JUMP
sound_driver_channel2_fx_Bxx:
	sts song_fx_Bxx, r26 //NOTE: a Bxx value of FF won't be detected since FF is used to indicate that the flag is disabled
	rjmp sound_driver_channel2_main

//HALT
sound_driver_channel2_fx_Cxx:
	sts song_fx_Cxx, r27 //NOTE: the value stored doesn't mean anything. we only need to check that it is non-zero
	rjmp sound_driver_channel2_main

//FRAME SKIP
sound_driver_channel2_fx_Dxx:
	sts song_fx_Dxx, r27 //NOTE: the value stored doesn't mean anything. we only need to check that it is non-zero
	rjmp sound_driver_channel2_main

//VOLUME
sound_driver_channel2_fx_Exx:
	cp r26, zero
	breq sound_driver_channel2_fx_Exx_disable
sound_driver_channel2_fx_Exx_enable:
	ldi r27, TCB_CAPT_bm //enable interrupts
	sts TCB2_INTCTRL, r27
	rjmp sound_driver_channel2_main
sound_driver_channel2_fx_Exx_disable:
	sts TCB2_INTCTRL, zero //disable interrupts
	sts TCB2_CCMPL, zero //reset timer
	sts TCB2_CCMPH, zero
	rjmp sound_driver_channel2_main

//SPEED AND TEMPO
sound_driver_channel2_fx_Fxx:
	sts song_speed, r26 //NOTE: only changes to speed are supported
	rjmp sound_driver_channel2_main

//DELAY
sound_driver_channel2_fx_Gxx:
	cp r26, zero
	breq sound_driver_channel2_fx_Gxx_invalid
	lds r27, song_speed
	cp r26, r27
	brsh sound_driver_channel2_fx_Gxx_invalid
	sts triangle_fx_Gxx_pre, r26 //NOTE: to be processed in the sound driver delay routine
	ldi r27, 0x01
	sts triangle_pattern_delay_rows, r27
	rjmp sound_driver_channel3
sound_driver_channel2_fx_Gxx_invalid:
	rjmp sound_driver_channel2_main //if Gxx was 0 or >= the song speed, ignore it and continue reading note data

sound_driver_channel2_fx_Hxy: //hardware sweep up
	rjmp sound_driver_channel2_main
sound_driver_channel2_fx_Ixy: //hardware sweep down
	rjmp sound_driver_channel2_main
sound_driver_channel2_fx_Hxx: //FDS modulation depth
	rjmp sound_driver_channel2_main
sound_driver_channel2_fx_Ixx: //FDS modulation speed
	rjmp sound_driver_channel2_main

//FINE PITCH
sound_driver_channel2_fx_Pxx:
	push r22 //only registers r16 - r23 can be used with mulsu
	push r23
	mov r22, r26
	ldi r23, 0b10110010 //store r23 with 11.125 note: this is the closest approximation to the 11.1746014718 multiplier we can get with 8 bits
	mulsu r22, r23
	pop r23
	pop r22
	lsr r1 //shift out the fractional bits
	ror r0
	lsr r1
	ror r0
	lsr r1
	ror r0
	lsr r1
	ror r0
	sbrs r1, 3 //check if result was a negative number
	rjmp sound_driver_channel2_fx_Pxx_store //if the result was positive, don't fill with 1s

sound_driver_channel2_fx_Pxx_negative:
	ldi r27, 0xF0
	or r1, r27 //when right shifting a two's complement number, must use 1s instead of 0s to fill

sound_driver_channel2_fx_Pxx_store:
	sts triangle_fx_Pxx_total, r0
	sts triangle_fx_Pxx_total+1, r1
	rjmp sound_driver_channel2_main

//NOTE SLIDE UP
sound_driver_channel2_fx_Qxy:
sound_driver_channel2_fx_Qxy_check_arpeggio_macro:
	lds ZL, triangle_arpeggio_macro
	lds ZH, triangle_arpeggio_macro+1
	adiw Z, 0
	breq sound_driver_channel2_fx_Qxy_check_pitch_macro
	rjmp sound_driver_channel2_main //if there is an arpeggio macro, don't enable the effect

sound_driver_channel2_fx_Qxy_check_pitch_macro:
	lds ZL, triangle_pitch_macro
	lds ZH, triangle_pitch_macro+1
	adiw Z, 0
	breq sound_driver_channel2_fx_Qxy_check_hi_pitch_macro
	rjmp sound_driver_channel2_main //if there is a pitch macro, don't enable the effect

sound_driver_channel2_fx_Qxy_check_hi_pitch_macro:
	lds ZL, triangle_hi_pitch_macro
	lds ZH, triangle_hi_pitch_macro+1
	adiw Z, 0
	breq sound_driver_channel2_fx_Qxy_process
	rjmp sound_driver_channel2_main //if there is a pitch macro, don't enable the effect

sound_driver_channel2_fx_Qxy_process:
	mov r27, r26 //copy fx parameters into r27
	andi r27, 0x0F //mask note index offset
	lds r28, triangle_fx_Qxy_target_note //load current note index
	add r27, r28
	cpi r27, 0x57 //largest possible note index is 0x56
	brlo sound_driver_channel2_fx_Qxy_process_continue
	ldi r27, 0x56 //if the target note was larger than the highest possible note index, keep the target at 0x56

sound_driver_channel2_fx_Qxy_process_continue:
	sts triangle_fx_Qxy_target_note, r27
	ldi ZL, LOW(note_table << 1) //load in note table
	ldi ZH, HIGH(note_table << 1)
	lsl r27 //double the offset for the note table because we are getting byte data
	add ZL, r27 //add offset
	adc ZH, zero
	lpm r28, Z+ //load bytes
	lpm r29, Z
	sts triangle_fx_Qxy_target, r28 //load the LOW bits for the target period
	sts triangle_fx_Qxy_target+1, r29 //load the HIGH bits for the target period

sound_driver_channel2_fx_Qxy_process_speed:
	swap r26
	andi r26, 0x0F //mask effect speed
	lsl r26 //multiply the speed by 2 NOTE: formula for the speed is 2x+1
	inc r26 //increment the speed by 1

	push r22 //only registers r16 - r23 can be used with mulsu
	push r23
	mov r22, r26 //store the speed data into r27
	ldi r23, 0b10110010 //store r23 with 11.125 note: this is the closest approximation to the 11.1746014718 multiplier we can get with 8 bits
	mul r22, r23
	pop r23
	pop r22

	lsr r1 //shift out the fractional bits
	ror r0
	lsr r1
	ror r0
	lsr r1
	ror r0
	lsr r1
	ror r0

	sts triangle_fx_Qxy_speed, r0 //store the effect speed
	sts triangle_fx_Qxy_speed+1, r1
	rjmp sound_driver_channel2_main

//NOTE SLIDE DOWN
sound_driver_channel2_fx_Rxy:
sound_driver_channel2_fx_Rxy_check_arpeggio_macro:
	lds ZL, triangle_arpeggio_macro
	lds ZH, triangle_arpeggio_macro+1
	adiw Z, 0
	breq sound_driver_channel2_fx_Rxy_check_pitch_macro
	rjmp sound_driver_channel2_main //if there is an arpeggio macro, don't enable the effect

sound_driver_channel2_fx_Rxy_check_pitch_macro:
	lds ZL, triangle_pitch_macro
	lds ZH, triangle_pitch_macro+1
	adiw Z, 0
	breq sound_driver_channel2_fx_Rxy_check_hi_pitch_macro
	rjmp sound_driver_channel2_main //if there is a pitch macro, don't enable the effect

sound_driver_channel2_fx_Rxy_check_hi_pitch_macro:
	lds ZL, triangle_hi_pitch_macro
	lds ZH, triangle_hi_pitch_macro+1
	adiw Z, 0
	breq sound_driver_channel2_fx_Rxy_process
	rjmp sound_driver_channel2_main //if there is a pitch macro, don't enable the effect

sound_driver_channel2_fx_Rxy_process:
	mov r27, r26 //copy fx parameters into r27
	andi r27, 0x0F //mask note index offset
	lds r28, triangle_fx_Rxy_target_note //load current note index
	sub r28, r27
	brcc sound_driver_channel2_fx_Rxy_process_continue
	ldi r28, 0x00

sound_driver_channel2_fx_Rxy_process_continue:
	sts triangle_fx_Rxy_target_note, r28
	ldi ZL, LOW(note_table << 1) //load in note table
	ldi ZH, HIGH(note_table << 1)
	lsl r28 //double the offset for the note table because we are getting byte data
	add ZL, r28 //add offset
	adc ZH, zero
	lpm r28, Z+ //load bytes
	lpm r29, Z
	sts triangle_fx_Rxy_target, r28 //load the LOW bits for the target period
	sts triangle_fx_Rxy_target+1, r29 //load the HIGH bits for the target period

sound_driver_channel2_fx_Rxy_process_speed:
	swap r26
	andi r26, 0x0F //mask effect speed
	lsl r26 //multiply the speed by 2 NOTE: formula for the speed is 2x+1
	inc r26 //increment the speed by 1

	push r22 //only registers r16 - r23 can be used with mulsu
	push r23
	mov r22, r26 //store the speed data into r27
	ldi r23, 0b10110010 //store r23 with 11.125 note: this is the closest approximation to the 11.1746014718 multiplier we can get with 8 bits
	mul r22, r23
	pop r23
	pop r22

	lsr r1 //shift out the fractional bits
	ror r0
	lsr r1
	ror r0
	lsr r1
	ror r0
	lsr r1
	ror r0

	sts triangle_fx_Rxy_speed, r0 //store the effect speed
	sts triangle_fx_Rxy_speed+1, r1
	rjmp sound_driver_channel2_main

//MUTE DELAY
sound_driver_channel2_fx_Sxx:
	cp r26, zero
	breq sound_driver_channel2_fx_Sxx_invalid
	lds r27, song_speed
	cp r26, r27
	brsh sound_driver_channel2_fx_Sxx_invalid
	sts triangle_fx_Sxx_pre, r26 //NOTE: to be processed in the sound driver delay routine
	ldi r27, 0x01
	sts triangle_pattern_delay_rows, r27
	rjmp sound_driver_channel3
sound_driver_channel2_fx_Sxx_invalid:
	rjmp sound_driver_channel2_main //if Sxx was 0 or >= the song speed, ignore it and continue reading note data

sound_driver_channel2_fx_Vxx: //duty
	rjmp sound_driver_channel2_main
sound_driver_channel2_fx_Wxx: //DPCM sample speed
	rjmp sound_driver_channel2_main
sound_driver_channel2_fx_Xxx: //DPCM sample retrigger
	rjmp sound_driver_channel2_main
sound_driver_channel2_fx_Yxx: //DPCM sample offset
	rjmp sound_driver_channel2_main
sound_driver_channel2_fx_Zxx: //DPCM sample delta counter
	rjmp sound_driver_channel2_main


sound_driver_channel2_note:
	sts triangle_note, r27 //store the note index
	sts triangle_fx_Qxy_target_note, r27
	sts triangle_fx_Rxy_target_note, r27
	ldi r26, 0x03
	ldi r27, 0x02
	sts triangle_volume_macro_offset, r27 //reset all macro offsets
	sts triangle_arpeggio_macro_offset, r26
	sts triangle_pitch_macro_offset, r27
	sts triangle_hi_pitch_macro_offset, r27
	sts triangle_duty_macro_offset, r27
	sts triangle_total_pitch_offset, zero //reset the pitch and hi pitch offset
	sts triangle_total_pitch_offset+1, zero
	sts triangle_total_hi_pitch_offset, zero
	sts triangle_fx_1xx_total, zero //reset the total for 1xx and 2xx effects
	sts triangle_fx_1xx_total+1, zero
	sts triangle_fx_2xx_total, zero
	sts triangle_fx_2xx_total+1, zero
	sts triangle_fx_3xx_total_offset, zero //reset 3xx offset
	sts triangle_fx_3xx_total_offset+1, zero
	lds r26, TCB2_CCMPL //if the 3xx effect is enabled, we need to store the current timer period
	lds r27, TCB2_CCMPH
	sts triangle_fx_3xx_start, r26
	sts triangle_fx_3xx_start+1, r27
	sts triangle_fx_Qxy_target, zero //reset the Qxy, Rxy effects
	sts triangle_fx_Qxy_target+1, zero
	sts triangle_fx_Qxy_total_offset, zero
	sts triangle_fx_Qxy_total_offset+1, zero
	sts triangle_fx_Rxy_target, zero
	sts triangle_fx_Rxy_target+1, zero
	sts triangle_fx_Rxy_total_offset, zero
	sts triangle_fx_Rxy_total_offset+1, zero
	ldi r27, TCB_CAPT_bm //enable interrupts
	sts TCB2_INTCTRL, r27
	rcall sound_driver_channel2_increment_offset
	rjmp sound_driver_channel2_main



sound_driver_channel2_volume:
	rcall sound_driver_channel2_increment_offset
	subi r27, 0x57 //NOTE: the delay values are offset by the highest volume value, which is 0x56
	breq sound_driver_channel2_volume_disable
sound_driver_channel2_volume_enable:
	ldi r27, TCB_CAPT_bm //enable interrupts
	sts TCB2_INTCTRL, r27
	rjmp sound_driver_channel2_main
sound_driver_channel2_volume_disable:
	sts TCB2_INTCTRL, zero //disable interrupts
	sts TCB2_CCMPL, zero //reset timer
	sts TCB2_CCMPH, zero
	rjmp sound_driver_channel2_main



sound_driver_channel2_delay:
	subi r27, 0x66 //NOTE: the delay values are offset by the highest volume value, which is 0x66
	sts triangle_pattern_delay_rows, r27
	rcall sound_driver_channel2_increment_offset
	rjmp sound_driver_channel3



sound_driver_channel2_instrument_change:
	sts triangle_volume_macro, zero //reset all macro addresses
	sts triangle_volume_macro+1, zero
	sts triangle_arpeggio_macro, zero
	sts triangle_arpeggio_macro+1, zero
	sts triangle_pitch_macro, zero
	sts triangle_pitch_macro+1, zero
	sts triangle_hi_pitch_macro, zero
	sts triangle_hi_pitch_macro+1, zero
	sts triangle_duty_macro, zero
	sts triangle_duty_macro+1, zero
	sts triangle_total_pitch_offset, zero //reset the pitch offset
	sts triangle_total_pitch_offset+1, zero
	sts triangle_total_hi_pitch_offset, zero //reset the hi pitch offset

	adiw Z, 1 //point to the byte next to the flag
	lpm r27, Z //store the instrument offset into r27
	ldi ZL, LOW(instruments) //point Z to instruments table
	ldi ZH, HIGH(instruments)
	add ZL, r27 //point Z to offsetted instrument
	adc ZH, zero
	lsl ZL //multiply by 2 to make Z into a byte pointer for the instrument's address
	rol ZH
	lpm r26, Z+ //r26:r27 now points to the instrument
	lpm r27, Z

	lsl r26 //multiply by 2 to make r26:r27 into a byte pointer for the instrument's data
	rol r27
	mov ZL, r26
	mov ZH, r27
	lpm r27, Z //get macro header byte. NOTE: Each macro type for each intrument is represented by a bit in this byte. 1 indicates that the instrument uses a macro of it's corresponding type.
	adiw Z, 2 //point Z to the address of the macro
	ldi r26, 6 //(6-1) = 5 for the 5 different macro types. NOTE: bit 0 = volume, bit 1 = arpeggio, bit 2 = pitch, bit 3 = hi pitch, bit 4 = duty
sound_driver_channel2_instrument_change_macro_loop:
	dec r26
	breq sound_driver_channel2_instrument_change_exit
	lsr r27
	brcs sound_driver_channel2_instrument_change_load_macro
	rjmp sound_driver_channel2_instrument_change_macro_loop



sound_driver_channel2_instrument_change_exit:
	ldi r26, 0x03
	ldi r27, 0x02
	sts triangle_volume_macro_offset, r27 //reset all macro offsets
	sts triangle_arpeggio_macro_offset, r26
	sts triangle_pitch_macro_offset, r27
	sts triangle_hi_pitch_macro_offset, r27
	sts triangle_duty_macro_offset, r27
	rcall sound_driver_channel2_increment_offset_twice
	rjmp sound_driver_channel2_main



sound_driver_channel2_instrument_change_load_macro:
	lpm r28, Z+ //r28:r29 now point to the macro
	lpm r29, Z+

	cpi r26, 5
	breq sound_driver_channel2_instrument_change_load_macro_volume
	cpi r26, 4
	breq sound_driver_channel2_instrument_change_load_macro_arpeggio
	cpi r26, 3
	breq sound_driver_channel2_instrument_change_load_macro_pitch
	cpi r26, 2
	breq sound_driver_channel2_instrument_change_load_macro_hi_pitch
	rjmp sound_driver_channel2_instrument_change_load_macro_duty

sound_driver_channel2_instrument_change_load_macro_volume:
	sts triangle_volume_macro, r28
	sts triangle_volume_macro+1, r29
	rcall sound_driver_channel2_instrument_change_read_header
	sts triangle_volume_macro_release, r28
	sts triangle_volume_macro_loop, r29
	rjmp sound_driver_channel2_instrument_change_macro_loop
	
sound_driver_channel2_instrument_change_load_macro_arpeggio:
	sts triangle_arpeggio_macro, r28
	sts triangle_arpeggio_macro+1, r29
	sts triangle_fx_Qxy_target, zero //reset the Qxy, Rxy effects
	sts triangle_fx_Qxy_target+1, zero
	sts triangle_fx_Rxy_target, zero
	sts triangle_fx_Rxy_target+1, zero
	rcall sound_driver_channel2_instrument_change_read_header_arpeggio
	rjmp sound_driver_channel2_instrument_change_macro_loop

sound_driver_channel2_instrument_change_load_macro_pitch:
	sts triangle_pitch_macro, r28
	sts triangle_pitch_macro+1, r29
	sts triangle_fx_Qxy_target, zero //reset the Qxy, Rxy effects
	sts triangle_fx_Qxy_target+1, zero
	sts triangle_fx_Rxy_target, zero
	sts triangle_fx_Rxy_target+1, zero
	rcall sound_driver_channel2_instrument_change_read_header
	sts triangle_pitch_macro_release, r28
	sts triangle_pitch_macro_loop, r29
	rjmp sound_driver_channel2_instrument_change_macro_loop

sound_driver_channel2_instrument_change_load_macro_hi_pitch:
	sts triangle_hi_pitch_macro, r28
	sts triangle_hi_pitch_macro+1, r29
	sts triangle_fx_Qxy_target, zero //reset the Qxy, Rxy effects
	sts triangle_fx_Qxy_target+1, zero
	sts triangle_fx_Rxy_target, zero
	sts triangle_fx_Rxy_target+1, zero
	rcall sound_driver_channel2_instrument_change_read_header
	sts triangle_hi_pitch_macro_release, r28
	sts triangle_hi_pitch_macro_loop, r29
	rjmp sound_driver_channel2_instrument_change_macro_loop

sound_driver_channel2_instrument_change_load_macro_duty:
	sts triangle_duty_macro, r28
	sts triangle_duty_macro+1, r29
	rcall sound_driver_channel2_instrument_change_read_header
	sts triangle_duty_macro_release, r28
	sts triangle_duty_macro_loop, r29
	rjmp sound_driver_channel2_instrument_change_macro_loop



sound_driver_channel2_instrument_change_read_header:
	push ZL
	push ZH
	mov ZL, r28
	mov ZH, r29
	lsl ZL
	rol ZH
	lpm r28, Z+
	lpm r29, Z
	pop ZH
	pop ZL
	ret

sound_driver_channel2_instrument_change_read_header_arpeggio:
	push ZL
	push ZH
	mov ZL, r28
	mov ZH, r29
	lsl ZL
	rol ZH
	lpm r28, Z+
	lpm r29, Z+
	sts triangle_arpeggio_macro_release, r28
	sts triangle_arpeggio_macro_loop, r29
	lpm r28, Z
	sts triangle_arpeggio_macro_mode, r28
	pop ZH
	pop ZL
	ret



sound_driver_channel2_release:
sound_driver_channel2_release_volume:
	lds r27, triangle_volume_macro_release
	cpi r27, 0xFF //check if volume macro has a release flag
	breq sound_driver_channel2_release_arpeggio //if the macro has no release flag, check the next macro
	inc r27
	sts triangle_volume_macro_offset, r27 //adjust offset so that it starts after the release flag index
sound_driver_channel2_release_arpeggio:
	lds r27, triangle_arpeggio_macro_release
	cpi r27, 0xFF //check if arpeggio macro has a release flag
	breq sound_driver_channel2_release_pitch
	inc r27
	sts triangle_arpeggio_macro_offset, r27
sound_driver_channel2_release_pitch:
	lds r27, triangle_pitch_macro_release
	cpi r27, 0xFF //check if pitch macro has a release flag
	breq sound_driver_channel2_release_hi_pitch
	inc r27
	sts triangle_pitch_macro_offset, r27
sound_driver_channel2_release_hi_pitch:
	lds r27, triangle_hi_pitch_macro_release
	cpi r27, 0xFF //check if hi_pitch macro has a release flag
	breq sound_driver_channel2_release_duty
	inc r27
	sts triangle_hi_pitch_macro_offset, r27
sound_driver_channel2_release_duty:
	lds r27, triangle_duty_macro_release
	cpi r27, 0xFF //check if duty macro has a release flag
	breq sound_driver_channel2_release_exit
	inc r27
	sts triangle_duty_macro_offset, r27
sound_driver_channel2_release_exit:
	rcall sound_driver_channel2_increment_offset
	rjmp sound_driver_channel2_main



sound_driver_channel2_next_pattern:
	lds ZL, song_frames
	lds ZH, song_frames+1
	lds r26, song_frame_offset //we must offset to the appropriate channel
	lds r27, song_frame_offset+1
	adiw r27:r26, 4 //offset for channel 2
	add ZL, r26
	adc ZH, r27

	lpm r26, Z+ //load the address of the next pattern
	lpm r27, Z
	lsl r26
	rol r27
	sts triangle_pattern, r26
	sts triangle_pattern+1, r27

	sts triangle_pattern_offset, zero //restart the pattern offset back to 0 because we are reading from a new pattern now
	sts triangle_pattern_offset+1, zero
	rjmp sound_driver_channel2_main



sound_driver_channel2_increment_offset:
	lds ZL, triangle_pattern_offset //current offset in the pattern for triangle
	lds ZH, triangle_pattern_offset+1
	adiw Z, 1
	sts triangle_pattern_offset, ZL
	sts triangle_pattern_offset+1, ZH
	ret

sound_driver_channel2_increment_offset_twice: //used for data that takes up 2 bytes worth of space
	lds ZL, triangle_pattern_offset //current offset in the pattern for triangle
	lds ZH, triangle_pattern_offset+1
	adiw Z, 2 //increment the pointer twice
	sts triangle_pattern_offset, ZL
	sts triangle_pattern_offset+1, ZH
	ret

sound_driver_channel2_decrement_frame_delay:
	dec r27
	sts triangle_pattern_delay_frames, r27



sound_driver_channel3:
	lds r26, noise_pattern_delay_rows
	lds r27, noise_pattern_delay_frames
	adiw r27:r26, 0
	breq sound_driver_channel3_main //if the pattern delay is 0, proceed with sound driver procedures
	rjmp sound_driver_channel3_decrement_frame_delay //if the pattern delay is not 0, decrement the delay

sound_driver_channel3_main:
	lds ZL, noise_pattern //current pattern for noise
	lds ZH, noise_pattern+1
	lds r26, noise_pattern_offset //current offset in the pattern for noise
	lds r27, noise_pattern_offset+1
	add ZL, r26 //offset the current pattern pointer to point to new byte data
	adc ZH, r27
	lpm r27, Z //load the byte data from the current pattern

sound_driver_channel3_check_if_note: //check if data is a note (0x00 - 0x56)
	cpi r27, 0x57
	brsh sound_driver_channel3_check_if_volume
	rjmp sound_driver_channel3_note
sound_driver_channel3_check_if_volume: //check if data is volume (0x57-0x66)
	cpi r27, 0x67
	brsh sound_driver_channel3_check_if_delay
	rjmp sound_driver_channel3_volume
sound_driver_channel3_check_if_delay: //check if data is a delay (0x67 - 0xE2)
	cpi r27, 0xE3
	brsh sound_driver_channel3_check_if_instrument
	rjmp sound_driver_channel3_delay
sound_driver_channel3_check_if_instrument: //check for instrument flag (0xE3)
	brne sound_driver_channel3_check_if_release
	rjmp sound_driver_channel3_instrument_change 
sound_driver_channel3_check_if_release: //check for note release flag (0xE4)
	cpi r27, 0xE4
	brne sound_driver_channel3_check_if_end
	rjmp sound_driver_channel3_release
sound_driver_channel3_check_if_end:
	cpi r27, 0xFF
	brne sound_driver_channel3_check_if_fx
	rjmp sound_driver_channel3_next_pattern



sound_driver_channel3_check_if_fx: //fx flags (0xE5 - 0xFE)
	adiw Z, 1 //point Z to the byte next to the flag
	lpm r26, Z //load the fx data into r26
	rcall sound_driver_channel3_increment_offset_twice

	subi r27, 0xE5 //prepare offset to perform table lookup
	ldi ZL, LOW(channel3_fx << 1) //load in note table
	ldi ZH, HIGH(channel3_fx << 1)
	lsl r27 //double the offset for the table because we are getting byte data
	add ZL, r27 //add offset
	adc ZH, zero
	lpm r28, Z+ //load address bytes
	lpm r29, Z
	mov ZL, r28 //move address bytes back into Z for an indirect jump
	mov ZH, r29
	ijmp


//ARPEGGIO
sound_driver_channel3_fx_0xy:
	sts noise_fx_0xy_sequence, r26
	sts noise_fx_0xy_sequence+1, zero
	rjmp sound_driver_channel3_main

//PITCH SLIDE UP
sound_driver_channel3_fx_1xx:
	sts noise_fx_2xx, zero //turn off any 2xx pitch slide down
	sts noise_fx_2xx+1, zero
	sts noise_fx_0xy_sequence, zero //disable any 0xy effect
	sts noise_fx_0xy_sequence+1, zero
	push r22 //only registers r16 - r23 can be used with mulsu
	push r23
	mov r22, r26 //store the rate into r22
	ldi r23, 0b10110010 //store r23 with 11.125 note: this is the closest approximation to the 11.1746014718 multiplier we can get with 8 bits
	mul r22, r23
	pop r23
	pop r22

	lsr r1 //shift out the fractional bits
	ror r0
	lsr r1
	ror r0
	lsr r1
	ror r0
	lsr r1
	ror r0
	sts noise_fx_1xx, r0
	sts noise_fx_1xx+1, r1
	rjmp sound_driver_channel3_main

//PITCH SLIDE DOWN
sound_driver_channel3_fx_2xx:
	sts noise_fx_1xx, zero //turn off any 1xx pitch slide down
	sts noise_fx_1xx+1, zero
	sts noise_fx_0xy_sequence, zero //disable any 0xy effect
	sts noise_fx_0xy_sequence+1, zero
	push r22 //only registers r16 - r23 can be used with mulsu
	push r23
	mov r22, r26 //store the rate into r22
	ldi r23, 0b10110010 //store r23 with 11.125 note: this is the closest approximation to the 11.1746014718 multiplier we can get with 8 bits
	mul r22, r23
	pop r23
	pop r22

	lsr r1 //shift out the fractional bits
	ror r0
	lsr r1
	ror r0
	lsr r1
	ror r0
	lsr r1
	ror r0
	sts noise_fx_2xx, r0
	sts noise_fx_2xx+1, r1
	rjmp sound_driver_channel3_main

//AUTOMATIC PORTAMENTO
sound_driver_channel3_fx_3xx:
	push r22 //only registers r16 - r23 can be used with mulsu
	push r23
	mov r22, r26 //store the rate into r22
	ldi r23, 0b10110010 //store r23 with 11.125 note: this is the closest approximation to the 11.1746014718 multiplier we can get with 8 bits
	mul r22, r23
	pop r23
	pop r22

	lsr r1 //shift out the fractional bits
	ror r0
	lsr r1
	ror r0
	lsr r1
	ror r0
	lsr r1
	ror r0
	sts noise_fx_3xx_speed, r0
	sts noise_fx_3xx_speed+1, r1

	cpse r26, zero //check if the effect was enabled or disabled
	rjmp sound_driver_channel3_fx_3xx_enabled
	rjmp sound_driver_channel3_main

sound_driver_channel3_fx_3xx_enabled:
	lds r26, TCB3_CCMPL //if the 3xx effect is enabled, we need to store the current timer period
	lds r27, TCB3_CCMPH
	sts noise_fx_3xx_start, r26
	sts noise_fx_3xx_start+1, r27

	sts noise_fx_3xx_total_offset, zero
	sts noise_fx_3xx_total_offset+1, zero
	rjmp sound_driver_channel3_main

//VIBRATO
sound_driver_channel3_fx_4xy:
	mov r27, r26
	andi r26, 0xF0 //mask r26 for x, the speed param
	swap r26
	andi r27, 0x0F //mask r27 for y, the depth param
	sts noise_fx_4xy_speed, r26
	sts noise_fx_4xy_depth, r27
	sts noise_fx_4xy_phase, zero //reset the phase to 0
	rjmp sound_driver_channel3_main

//TREMELO
sound_driver_channel3_fx_7xy:
	mov r27, r26
	andi r26, 0xF0 //mask r26 for x, the speed param
	swap r26
	andi r27, 0x0F //mask r27 for y, the depth param
	sts noise_fx_7xy_speed, r26
	sts noise_fx_7xy_depth, r27
	sts noise_fx_7xy_phase, zero //reset the phase to 0
	sts noise_fx_7xy_value, zero //reset the tremelo value
	rjmp sound_driver_channel3_main

//VOLUME SLIDE
sound_driver_channel3_fx_Axy:
	sts noise_fx_Axy, r26
	rjmp sound_driver_channel3_main

//FRAME JUMP
sound_driver_channel3_fx_Bxx:
	sts song_fx_Bxx, r26 //NOTE: a Bxx value of FF won't be detected since FF is used to indicate that the flag is disabled
	rjmp sound_driver_channel3_main

//HALT
sound_driver_channel3_fx_Cxx:
	sts song_fx_Cxx, r27 //NOTE: the value stored doesn't mean anything. we only need to check that it is non-zero
	rjmp sound_driver_channel3_main

//FRAME SKIP
sound_driver_channel3_fx_Dxx:
	sts song_fx_Dxx, r27 //NOTE: the value stored doesn't mean anything. we only need to check that it is non-zero
	rjmp sound_driver_channel3_main

//VOLUME
sound_driver_channel3_fx_Exx:
	lds r27, noise_param
	andi r27, 0xF0 //clear previous VVVV volume bits
	or r27, r26 //move new VVVV bits into noise_param
	sts noise_param, r27
	rjmp sound_driver_channel3_main

//SPEED AND TEMPO
sound_driver_channel3_fx_Fxx:
	sts song_speed, r26 //NOTE: only changes to speed are supported
	rjmp sound_driver_channel3_main

//DELAY
sound_driver_channel3_fx_Gxx:
	cp r26, zero
	breq sound_driver_channel3_fx_Gxx_invalid
	lds r27, song_speed
	cp r26, r27
	brsh sound_driver_channel3_fx_Gxx_invalid
	sts noise_fx_Gxx_pre, r26 //NOTE: to be processed in the sound driver delay routine
	ldi r27, 0x01
	sts noise_pattern_delay_rows, r27
	rjmp sound_driver_channel4
sound_driver_channel3_fx_Gxx_invalid:
	rjmp sound_driver_channel3_main //if Gxx was 0 or >= the song speed, ignore it and continue reading note data

sound_driver_channel3_fx_Hxy: //hardware sweep up
	rjmp sound_driver_channel3_main
sound_driver_channel3_fx_Ixy: //hardware sweep down
	rjmp sound_driver_channel3_main
sound_driver_channel3_fx_Hxx: //FDS modulation depth
	rjmp sound_driver_channel3_main
sound_driver_channel3_fx_Ixx: //FDS modulation speed
	rjmp sound_driver_channel3_main

//FINE PITCH
sound_driver_channel3_fx_Pxx:
	push r22 //only registers r16 - r23 can be used with mulsu
	push r23
	mov r22, r26
	ldi r23, 0b10110010 //store r23 with 11.125 note: this is the closest approximation to the 11.1746014718 multiplier we can get with 8 bits
	mulsu r22, r23
	pop r23
	pop r22
	lsr r1 //shift out the fractional bits
	ror r0
	lsr r1
	ror r0
	lsr r1
	ror r0
	lsr r1
	ror r0
	sbrs r1, 3 //check if result was a negative number
	rjmp sound_driver_channel3_fx_Pxx_store //if the result was positive, don't fill with 1s

sound_driver_channel3_fx_Pxx_negative:
	ldi r27, 0xF0
	or r1, r27 //when right shifting a two's complement number, must use 1s instead of 0s to fill

sound_driver_channel3_fx_Pxx_store:
	sts noise_fx_Pxx_total, r0
	sts noise_fx_Pxx_total+1, r1
	rjmp sound_driver_channel3_main

//NOTE SLIDE UP
sound_driver_channel3_fx_Qxy:
sound_driver_channel3_fx_Qxy_check_arpeggio_macro:
	lds ZL, noise_arpeggio_macro
	lds ZH, noise_arpeggio_macro+1
	adiw Z, 0
	breq sound_driver_channel3_fx_Qxy_check_pitch_macro
	rjmp sound_driver_channel3_main //if there is an arpeggio macro, don't enable the effect

sound_driver_channel3_fx_Qxy_check_pitch_macro:
	lds ZL, noise_pitch_macro
	lds ZH, noise_pitch_macro+1
	adiw Z, 0
	breq sound_driver_channel3_fx_Qxy_check_hi_pitch_macro
	rjmp sound_driver_channel3_main //if there is a pitch macro, don't enable the effect

sound_driver_channel3_fx_Qxy_check_hi_pitch_macro:
	lds ZL, noise_hi_pitch_macro
	lds ZH, noise_hi_pitch_macro+1
	adiw Z, 0
	breq sound_driver_channel3_fx_Qxy_process
	rjmp sound_driver_channel3_main //if there is a pitch macro, don't enable the effect

sound_driver_channel3_fx_Qxy_process:
	mov r27, r26 //copy fx parameters into r27
	andi r27, 0x0F //mask note index offset
	lds r28, noise_fx_Qxy_target_note //load current note index
	add r27, r28
	cpi r27, 0x57 //largest possible note index is 0x56
	brlo sound_driver_channel3_fx_Qxy_process_continue
	ldi r27, 0x56 //if the target note was larger than the highest possible note index, keep the target at 0x56

sound_driver_channel3_fx_Qxy_process_continue:
	sts noise_fx_Qxy_target_note, r27
	ldi ZL, LOW(note_table << 1) //load in note table
	ldi ZH, HIGH(note_table << 1)
	lsl r27 //double the offset for the note table because we are getting byte data
	add ZL, r27 //add offset
	adc ZH, zero
	lpm r28, Z+ //load bytes
	lpm r29, Z
	sts noise_fx_Qxy_target, r28 //load the LOW bits for the target period
	sts noise_fx_Qxy_target+1, r29 //load the HIGH bits for the target period

sound_driver_channel3_fx_Qxy_process_speed:
	swap r26
	andi r26, 0x0F //mask effect speed
	lsl r26 //multiply the speed by 2 NOTE: formula for the speed is 2x+1
	inc r26 //increment the speed by 1

	push r22 //only registers r16 - r23 can be used with mulsu
	push r23
	mov r22, r26 //store the speed data into r27
	ldi r23, 0b10110010 //store r23 with 11.125 note: this is the closest approximation to the 11.1746014718 multiplier we can get with 8 bits
	mul r22, r23
	pop r23
	pop r22

	lsr r1 //shift out the fractional bits
	ror r0
	lsr r1
	ror r0
	lsr r1
	ror r0
	lsr r1
	ror r0

	sts noise_fx_Qxy_speed, r0 //store the effect speed
	sts noise_fx_Qxy_speed+1, r1
	rjmp sound_driver_channel3_main

//NOTE SLIDE DOWN
sound_driver_channel3_fx_Rxy:
sound_driver_channel3_fx_Rxy_check_arpeggio_macro:
	lds ZL, noise_arpeggio_macro
	lds ZH, noise_arpeggio_macro+1
	adiw Z, 0
	breq sound_driver_channel3_fx_Rxy_check_pitch_macro
	rjmp sound_driver_channel3_main //if there is an arpeggio macro, don't enable the effect

sound_driver_channel3_fx_Rxy_check_pitch_macro:
	lds ZL, noise_pitch_macro
	lds ZH, noise_pitch_macro+1
	adiw Z, 0
	breq sound_driver_channel3_fx_Rxy_check_hi_pitch_macro
	rjmp sound_driver_channel3_main //if there is a pitch macro, don't enable the effect

sound_driver_channel3_fx_Rxy_check_hi_pitch_macro:
	lds ZL, noise_hi_pitch_macro
	lds ZH, noise_hi_pitch_macro+1
	adiw Z, 0
	breq sound_driver_channel3_fx_Rxy_process
	rjmp sound_driver_channel3_main //if there is a pitch macro, don't enable the effect

sound_driver_channel3_fx_Rxy_process:
	mov r27, r26 //copy fx parameters into r27
	andi r27, 0x0F //mask note index offset
	lds r28, noise_fx_Rxy_target_note //load current note index
	sub r28, r27
	brcc sound_driver_channel3_fx_Rxy_process_continue
	ldi r28, 0x00

sound_driver_channel3_fx_Rxy_process_continue:
	sts noise_fx_Rxy_target_note, r28
	ldi ZL, LOW(note_table << 1) //load in note table
	ldi ZH, HIGH(note_table << 1)
	lsl r28 //double the offset for the note table because we are getting byte data
	add ZL, r28 //add offset
	adc ZH, zero
	lpm r28, Z+ //load bytes
	lpm r29, Z
	sts noise_fx_Rxy_target, r28 //load the LOW bits for the target period
	sts noise_fx_Rxy_target+1, r29 //load the HIGH bits for the target period

sound_driver_channel3_fx_Rxy_process_speed:
	swap r26
	andi r26, 0x0F //mask effect speed
	lsl r26 //multiply the speed by 2 NOTE: formula for the speed is 2x+1
	inc r26 //increment the speed by 1

	push r22 //only registers r16 - r23 can be used with mulsu
	push r23
	mov r22, r26 //store the speed data into r27
	ldi r23, 0b10110010 //store r23 with 11.125 note: this is the closest approximation to the 11.1746014718 multiplier we can get with 8 bits
	mul r22, r23
	pop r23
	pop r22

	lsr r1 //shift out the fractional bits
	ror r0
	lsr r1
	ror r0
	lsr r1
	ror r0
	lsr r1
	ror r0

	sts noise_fx_Rxy_speed, r0 //store the effect speed
	sts noise_fx_Rxy_speed+1, r1
	rjmp sound_driver_channel3_main

//MUTE DELAY
sound_driver_channel3_fx_Sxx:
	cp r26, zero
	breq sound_driver_channel3_fx_Sxx_invalid
	lds r27, song_speed
	cp r26, r27
	brsh sound_driver_channel3_fx_Sxx_invalid
	sts noise_fx_Sxx_pre, r26 //NOTE: to be processed in the sound driver delay routine
	ldi r27, 0x01
	sts noise_pattern_delay_rows, r27
	rjmp sound_driver_channel4
sound_driver_channel3_fx_Sxx_invalid:
	rjmp sound_driver_channel3_main //if Sxx was 0 or >= the song speed, ignore it and continue reading note data

//DUTY
sound_driver_channel3_fx_Vxx:
	lsr r26
	ror r26 //move mode bit to bit 7
	lds r27, noise_period
	andi r27, 0b01111111
	or r27, r26 //store the new noise mode
	sts noise_param, r27

	andi noise_sequence_HIGH, 0b01111111
	or noise_sequence_HIGH, r26
	rjmp sound_driver_channel3_main

sound_driver_channel3_fx_Wxx: //DPCM sample speed
	rjmp sound_driver_channel3_main
sound_driver_channel3_fx_Xxx: //DPCM sample retrigger
	rjmp sound_driver_channel3_main
sound_driver_channel3_fx_Yxx: //DPCM sample offset
	rjmp sound_driver_channel3_main
sound_driver_channel3_fx_Zxx: //DPCM sample delta counter
	rjmp sound_driver_channel3_main


sound_driver_channel3_note:
	sts noise_note, r27 //store the note index
	sts noise_fx_Qxy_target_note, r27
	sts noise_fx_Rxy_target_note, r27
	ldi r26, 0x03
	ldi r27, 0x02
	sts noise_volume_macro_offset, r27 //reset all macro offsets
	sts noise_arpeggio_macro_offset, r26
	sts noise_pitch_macro_offset, r27
	sts noise_hi_pitch_macro_offset, r27
	sts noise_duty_macro_offset, r27
	sts noise_total_pitch_offset, zero //reset the pitch and hi pitch offset
	sts noise_total_pitch_offset+1, zero
	sts noise_total_hi_pitch_offset, zero
	sts noise_fx_1xx_total, zero //reset the total for 1xx and 2xx effects
	sts noise_fx_1xx_total+1, zero
	sts noise_fx_2xx_total, zero
	sts noise_fx_2xx_total+1, zero
	sts noise_fx_3xx_total_offset, zero //reset 3xx offset
	sts noise_fx_3xx_total_offset+1, zero
	lds r26, TCB3_CCMPL //if the 3xx effect is enabled, we need to store the current timer period
	lds r27, TCB3_CCMPH
	sts noise_fx_3xx_start, r26
	sts noise_fx_3xx_start+1, r27
	sts noise_fx_Qxy_target, zero //reset the Qxy, Rxy effects
	sts noise_fx_Qxy_target+1, zero
	sts noise_fx_Qxy_total_offset, zero
	sts noise_fx_Qxy_total_offset+1, zero
	sts noise_fx_Rxy_target, zero
	sts noise_fx_Rxy_target+1, zero
	sts noise_fx_Rxy_total_offset, zero
	sts noise_fx_Rxy_total_offset+1, zero
	rcall sound_driver_channel3_increment_offset
	rjmp sound_driver_channel3_main



sound_driver_channel3_volume:
	subi r27, 0x57 //NOTE: the delay values are offset by the highest volume value, which is 0x56
	lds r26, noise_param
	andi r26, 0xF0 //clear previous VVVV volume bits
	or r26, r27 //move new VVVV bits into noise_param
	sts noise_param, r26
	rcall sound_driver_channel3_increment_offset
	rjmp sound_driver_channel3_main



sound_driver_channel3_delay:
	subi r27, 0x66 //NOTE: the delay values are offset by the highest volume value, which is 0x66
	sts noise_pattern_delay_rows, r27
	rcall sound_driver_channel3_increment_offset
	rjmp sound_driver_channel4



sound_driver_channel3_instrument_change:
	sts noise_volume_macro, zero //reset all macro addresses
	sts noise_volume_macro+1, zero
	sts noise_arpeggio_macro, zero
	sts noise_arpeggio_macro+1, zero
	sts noise_pitch_macro, zero
	sts noise_pitch_macro+1, zero
	sts noise_hi_pitch_macro, zero
	sts noise_hi_pitch_macro+1, zero
	sts noise_duty_macro, zero
	sts noise_duty_macro+1, zero
	sts noise_total_pitch_offset, zero //reset the pitch offset
	sts noise_total_pitch_offset+1, zero
	sts noise_total_hi_pitch_offset, zero //reset the hi pitch offset

	adiw Z, 1 //point to the byte next to the flag
	lpm r27, Z //store the instrument offset into r27
	ldi ZL, LOW(instruments) //point Z to instruments table
	ldi ZH, HIGH(instruments)
	add ZL, r27 //point Z to offsetted instrument
	adc ZH, zero
	lsl ZL //multiply by 2 to make Z into a byte pointer for the instrument's address
	rol ZH
	lpm r26, Z+ //r26:r27 now points to the instrument
	lpm r27, Z

	lsl r26 //multiply by 2 to make r26:r27 into a byte pointer for the instrument's data
	rol r27
	mov ZL, r26
	mov ZH, r27
	lpm r27, Z //get macro header byte. NOTE: Each macro type for each intrument is represented by a bit in this byte. 1 indicates that the instrument uses a macro of it's corresponding type.
	adiw Z, 2 //point Z to the address of the macro
	ldi r26, 6 //(6-1) = 5 for the 5 different macro types. NOTE: bit 0 = volume, bit 1 = arpeggio, bit 2 = pitch, bit 3 = hi pitch, bit 4 = duty
sound_driver_channel3_instrument_change_macro_loop:
	dec r26
	breq sound_driver_channel3_instrument_change_exit
	lsr r27
	brcs sound_driver_channel3_instrument_change_load_macro
	rjmp sound_driver_channel3_instrument_change_macro_loop



sound_driver_channel3_instrument_change_exit:
	ldi r26, 0x03
	ldi r27, 0x02
	sts noise_volume_macro_offset, r27 //reset all macro offsets
	sts noise_arpeggio_macro_offset, r26
	sts noise_pitch_macro_offset, r27
	sts noise_hi_pitch_macro_offset, r27
	sts noise_duty_macro_offset, r27
	rcall sound_driver_channel3_increment_offset_twice
	rjmp sound_driver_channel3_main



sound_driver_channel3_instrument_change_load_macro:
	lpm r28, Z+ //r28:r29 now point to the macro
	lpm r29, Z+

	cpi r26, 5
	breq sound_driver_channel3_instrument_change_load_macro_volume
	cpi r26, 4
	breq sound_driver_channel3_instrument_change_load_macro_arpeggio
	cpi r26, 3
	breq sound_driver_channel3_instrument_change_load_macro_pitch
	cpi r26, 2
	breq sound_driver_channel3_instrument_change_load_macro_hi_pitch
	rjmp sound_driver_channel3_instrument_change_load_macro_duty

sound_driver_channel3_instrument_change_load_macro_volume:
	sts noise_volume_macro, r28
	sts noise_volume_macro+1, r29
	rcall sound_driver_channel3_instrument_change_read_header
	sts noise_volume_macro_release, r28
	sts noise_volume_macro_loop, r29
	rjmp sound_driver_channel3_instrument_change_macro_loop
	
sound_driver_channel3_instrument_change_load_macro_arpeggio:
	sts noise_arpeggio_macro, r28
	sts noise_arpeggio_macro+1, r29
	sts noise_fx_Qxy_target, zero //reset the Qxy, Rxy effects
	sts noise_fx_Qxy_target+1, zero
	sts noise_fx_Rxy_target, zero
	sts noise_fx_Rxy_target+1, zero
	rcall sound_driver_channel3_instrument_change_read_header_arpeggio
	rjmp sound_driver_channel3_instrument_change_macro_loop

sound_driver_channel3_instrument_change_load_macro_pitch:
	sts noise_pitch_macro, r28
	sts noise_pitch_macro+1, r29
	sts noise_fx_Qxy_target, zero //reset the Qxy, Rxy effects
	sts noise_fx_Qxy_target+1, zero
	sts noise_fx_Rxy_target, zero
	sts noise_fx_Rxy_target+1, zero
	rcall sound_driver_channel3_instrument_change_read_header
	sts noise_pitch_macro_release, r28
	sts noise_pitch_macro_loop, r29
	rjmp sound_driver_channel3_instrument_change_macro_loop

sound_driver_channel3_instrument_change_load_macro_hi_pitch:
	sts noise_hi_pitch_macro, r28
	sts noise_hi_pitch_macro+1, r29
	sts noise_fx_Qxy_target, zero //reset the Qxy, Rxy effects
	sts noise_fx_Qxy_target+1, zero
	sts noise_fx_Rxy_target, zero
	sts noise_fx_Rxy_target+1, zero
	rcall sound_driver_channel3_instrument_change_read_header
	sts noise_hi_pitch_macro_release, r28
	sts noise_hi_pitch_macro_loop, r29
	rjmp sound_driver_channel3_instrument_change_macro_loop

sound_driver_channel3_instrument_change_load_macro_duty:
	sts noise_duty_macro, r28
	sts noise_duty_macro+1, r29
	rcall sound_driver_channel3_instrument_change_read_header
	sts noise_duty_macro_release, r28
	sts noise_duty_macro_loop, r29
	rjmp sound_driver_channel3_instrument_change_macro_loop



sound_driver_channel3_instrument_change_read_header:
	push ZL
	push ZH
	mov ZL, r28
	mov ZH, r29
	lsl ZL
	rol ZH
	lpm r28, Z+
	lpm r29, Z
	pop ZH
	pop ZL
	ret

sound_driver_channel3_instrument_change_read_header_arpeggio:
	push ZL
	push ZH
	mov ZL, r28
	mov ZH, r29
	lsl ZL
	rol ZH
	lpm r28, Z+
	lpm r29, Z+
	sts noise_arpeggio_macro_release, r28
	sts noise_arpeggio_macro_loop, r29
	lpm r28, Z
	sts noise_arpeggio_macro_mode, r28
	pop ZH
	pop ZL
	ret



sound_driver_channel3_release:
sound_driver_channel3_release_volume:
	lds r27, noise_volume_macro_release
	cpi r27, 0xFF //check if volume macro has a release flag
	breq sound_driver_channel3_release_arpeggio //if the macro has no release flag, check the next macro
	inc r27
	sts noise_volume_macro_offset, r27 //adjust offset so that it starts after the release flag index
sound_driver_channel3_release_arpeggio:
	lds r27, noise_arpeggio_macro_release
	cpi r27, 0xFF //check if arpeggio macro has a release flag
	breq sound_driver_channel3_release_pitch
	inc r27
	sts noise_arpeggio_macro_offset, r27
sound_driver_channel3_release_pitch:
	lds r27, noise_pitch_macro_release
	cpi r27, 0xFF //check if pitch macro has a release flag
	breq sound_driver_channel3_release_hi_pitch
	inc r27
	sts noise_pitch_macro_offset, r27
sound_driver_channel3_release_hi_pitch:
	lds r27, noise_hi_pitch_macro_release
	cpi r27, 0xFF //check if hi_pitch macro has a release flag
	breq sound_driver_channel3_release_duty
	inc r27
	sts noise_hi_pitch_macro_offset, r27
sound_driver_channel3_release_duty:
	lds r27, noise_duty_macro_release
	cpi r27, 0xFF //check if duty macro has a release flag
	breq sound_driver_channel3_release_exit
	inc r27
	sts noise_duty_macro_offset, r27
sound_driver_channel3_release_exit:
	rcall sound_driver_channel3_increment_offset
	rjmp sound_driver_channel3_main



sound_driver_channel3_next_pattern:
	lds ZL, song_frames
	lds ZH, song_frames+1
	lds r26, song_frame_offset //we must offset to the appropriate channel
	lds r27, song_frame_offset+1
	sts song_frame_offset, r26
	sts song_frame_offset+1, r27
	adiw r27:r26, 6 //offset for channel 3
	add ZL, r26
	adc ZH, r27

	lpm r26, Z+ //load the address of the next pattern
	lpm r27, Z
	lsl r26
	rol r27
	sts noise_pattern, r26
	sts noise_pattern+1, r27

	sts noise_pattern_offset, zero //restart the pattern offset back to 0 because we are reading from a new pattern now
	sts noise_pattern_offset+1, zero
	rjmp sound_driver_channel3_main



sound_driver_channel3_increment_offset:
	lds ZL, noise_pattern_offset //current offset in the pattern for noise
	lds ZH, noise_pattern_offset+1
	adiw Z, 1
	sts noise_pattern_offset, ZL
	sts noise_pattern_offset+1, ZH
	ret

sound_driver_channel3_increment_offset_twice: //used for data that takes up 2 bytes worth of space
	lds ZL, noise_pattern_offset //current offset in the pattern for noise
	lds ZH, noise_pattern_offset+1
	adiw Z, 2 //increment the pointer twice
	sts noise_pattern_offset, ZL
	sts noise_pattern_offset+1, ZH
	ret

sound_driver_channel3_decrement_frame_delay:
	dec r27
	sts noise_pattern_delay_frames, r27



sound_driver_channel4:

sound_driver_calculate_delays:
	lds r31, song_speed
	mov r30, r31
	subi r30, 1
sound_driver_calculate_delays_pulse1:
	lds r26, pulse1_pattern_delay_frames
	cpse r26, zero
	rjmp sound_driver_calculate_delays_pulse2
	rjmp sound_driver_calculate_delays_pulse1_main

sound_driver_calculate_delays_pulse1_main:
	mov r26, r31 //move the speed to r26
	lds r27, pulse1_pattern_delay_rows //decrement the delay rows
	cp r27, zero
	brne PC+2
	rjmp sound_driver_calculate_delays_pulse2
	dec r27
	sts pulse1_pattern_delay_rows, r27
	cpse r27, zero
	rjmp sound_driver_calculate_delays_pulse1_store
	dec r26

sound_driver_calculate_delays_pulse1_Sxx:
	ldi r27, 0xFF
	lds r28, pulse1_fx_Sxx_pre
	lds r29, pulse1_fx_Sxx_post
sound_driver_calculate_delays_pulse1_Sxx_check_pre:
	cp r28, r27
	breq sound_driver_calculate_delays_pulse1_Sxx_check_post
	rjmp sound_driver_calculate_delays_pulse1_Sxx_pre
sound_driver_calculate_delays_pulse1_Sxx_check_post:
	cp r29, r27
	breq sound_driver_calculate_delays_pulse1_Gxx
	rjmp sound_driver_calculate_delays_pulse1_Sxx_post

sound_driver_calculate_delays_pulse1_Gxx:
	lds r28, pulse1_fx_Gxx_pre
	lds r29, pulse1_fx_Gxx_post
sound_driver_calculate_delays_pulse1_Gxx_check_pre:
	cp r28, r27
	breq sound_driver_calculate_delays_pulse1_Gxx_check_post
	rjmp sound_driver_calculate_delays_pulse1_Gxx_pre
sound_driver_calculate_delays_pulse1_Gxx_check_post:
	cp r29, r27
	breq sound_driver_calculate_delays_pulse1_store
	rjmp sound_driver_calculate_delays_pulse1_Gxx_post

sound_driver_calculate_delays_pulse1_Sxx_pre:
	sts pulse1_fx_Sxx_pre, r27
	sub r30, r28 //(song speed)-1-Sxx
	sts pulse1_fx_Sxx_post, r30
	dec r28
	sts pulse1_pattern_delay_frames, r28
	mov r30, r31
	subi r30, 1
	rjmp sound_driver_calculate_delays_pulse2

sound_driver_calculate_delays_pulse1_Sxx_post:
	sts pulse1_fx_Sxx_post, r27
	mov r26, r29
	rjmp sound_driver_calculate_delays_pulse1_store

sound_driver_calculate_delays_pulse1_Gxx_pre:
	sts pulse1_fx_Gxx_pre, r27
	sub r30, r28 //(song speed)-1-Sxx
	sts pulse1_fx_Gxx_post, r30
	dec r28
	sts pulse1_pattern_delay_frames, r28
	mov r30, r31
	subi r30, 1
	rjmp sound_driver_calculate_delays_pulse2
	
sound_driver_calculate_delays_pulse1_Gxx_post:
	sts pulse1_fx_Gxx_post, r27
	mov r26, r29
	rjmp sound_driver_calculate_delays_pulse1_store

sound_driver_calculate_delays_pulse1_store:
	sts pulse1_pattern_delay_frames, r26



sound_driver_calculate_delays_pulse2:
	lds r26, pulse2_pattern_delay_frames
	cpse r26, zero
	rjmp sound_driver_calculate_delays_triangle
	rjmp sound_driver_calculate_delays_pulse2_main

sound_driver_calculate_delays_pulse2_main:
	mov r26, r31 //move the speed to r26
	lds r27, pulse2_pattern_delay_rows //decrement the delay rows
	cp r27, zero
	brne PC+2
	rjmp sound_driver_calculate_delays_triangle
	dec r27
	sts pulse2_pattern_delay_rows, r27
	cpse r27, zero
	rjmp sound_driver_calculate_delays_pulse2_store
	dec r26

sound_driver_calculate_delays_pulse2_Sxx:
	ldi r27, 0xFF
	lds r28, pulse2_fx_Sxx_pre
	lds r29, pulse2_fx_Sxx_post
sound_driver_calculate_delays_pulse2_Sxx_check_pre:
	cp r28, r27
	breq sound_driver_calculate_delays_pulse2_Sxx_check_post
	rjmp sound_driver_calculate_delays_pulse2_Sxx_pre
sound_driver_calculate_delays_pulse2_Sxx_check_post:
	cp r29, r27
	breq sound_driver_calculate_delays_pulse2_Gxx
	rjmp sound_driver_calculate_delays_pulse2_Sxx_post

sound_driver_calculate_delays_pulse2_Gxx:
	lds r28, pulse2_fx_Gxx_pre
	lds r29, pulse2_fx_Gxx_post
sound_driver_calculate_delays_pulse2_Gxx_check_pre:
	cp r28, r27
	breq sound_driver_calculate_delays_pulse2_Gxx_check_post
	rjmp sound_driver_calculate_delays_pulse2_Gxx_pre
sound_driver_calculate_delays_pulse2_Gxx_check_post:
	cp r29, r27
	breq sound_driver_calculate_delays_pulse2_store
	rjmp sound_driver_calculate_delays_pulse2_Gxx_post

sound_driver_calculate_delays_pulse2_Sxx_pre:
	sts pulse2_fx_Sxx_pre, r27
	sub r30, r28 //(song speed)-1-Sxx
	sts pulse2_fx_Sxx_post, r30
	dec r28
	sts pulse2_pattern_delay_frames, r28
	mov r30, r31
	subi r30, 1
	rjmp sound_driver_calculate_delays_pulse2

sound_driver_calculate_delays_pulse2_Sxx_post:
	sts pulse2_fx_Sxx_post, r27
	mov r26, r29
	rjmp sound_driver_calculate_delays_pulse2_store

sound_driver_calculate_delays_pulse2_Gxx_pre:
	sts pulse2_fx_Gxx_pre, r27
	sub r30, r28 //(song speed)-1-Sxx
	sts pulse2_fx_Gxx_post, r30
	dec r28
	sts pulse2_pattern_delay_frames, r28
	mov r30, r31
	subi r30, 1
	rjmp sound_driver_calculate_delays_pulse2
	
sound_driver_calculate_delays_pulse2_Gxx_post:
	sts pulse2_fx_Gxx_post, r27
	mov r26, r29
	rjmp sound_driver_calculate_delays_pulse2_store

sound_driver_calculate_delays_pulse2_store:
	sts pulse2_pattern_delay_frames, r26



sound_driver_calculate_delays_triangle:
	lds r26, triangle_pattern_delay_frames
	cpse r26, zero
	rjmp sound_driver_calculate_delays_noise
	rjmp sound_driver_calculate_delays_triangle_main

sound_driver_calculate_delays_triangle_main:
	mov r26, r31 //move the speed to r26
	lds r27, triangle_pattern_delay_rows //decrement the delay rows
	cp r27, zero
	brne PC+2
	rjmp sound_driver_calculate_delays_noise
	dec r27
	sts triangle_pattern_delay_rows, r27
	cpse r27, zero
	rjmp sound_driver_calculate_delays_triangle_store
	dec r26

sound_driver_calculate_delays_triangle_Sxx:
	ldi r27, 0xFF
	lds r28, triangle_fx_Sxx_pre
	lds r29, triangle_fx_Sxx_post
sound_driver_calculate_delays_triangle_Sxx_check_pre:
	cp r28, r27
	breq sound_driver_calculate_delays_triangle_Sxx_check_post
	rjmp sound_driver_calculate_delays_triangle_Sxx_pre
sound_driver_calculate_delays_triangle_Sxx_check_post:
	cp r29, r27
	breq sound_driver_calculate_delays_triangle_Gxx
	rjmp sound_driver_calculate_delays_triangle_Sxx_post

sound_driver_calculate_delays_triangle_Gxx:
	lds r28, triangle_fx_Gxx_pre
	lds r29, triangle_fx_Gxx_post
sound_driver_calculate_delays_triangle_Gxx_check_pre:
	cp r28, r27
	breq sound_driver_calculate_delays_triangle_Gxx_check_post
	rjmp sound_driver_calculate_delays_triangle_Gxx_pre
sound_driver_calculate_delays_triangle_Gxx_check_post:
	cp r29, r27
	breq sound_driver_calculate_delays_triangle_store
	rjmp sound_driver_calculate_delays_triangle_Gxx_post

sound_driver_calculate_delays_triangle_Sxx_pre:
	sts triangle_fx_Sxx_pre, r27
	sub r30, r28 //(song speed)-1-Sxx
	sts triangle_fx_Sxx_post, r30
	dec r28
	sts triangle_pattern_delay_frames, r28
	mov r30, r31
	subi r30, 1
	rjmp sound_driver_calculate_delays_noise

sound_driver_calculate_delays_triangle_Sxx_post:
	sts triangle_fx_Sxx_post, r27
	mov r26, r29
	rjmp sound_driver_calculate_delays_triangle_store

sound_driver_calculate_delays_triangle_Gxx_pre:
	sts triangle_fx_Gxx_pre, r27
	sub r30, r28 //(song speed)-1-Sxx
	sts triangle_fx_Gxx_post, r30
	dec r28
	sts triangle_pattern_delay_frames, r28
	mov r30, r31
	subi r30, 1
	rjmp sound_driver_calculate_delays_noise
	
sound_driver_calculate_delays_triangle_Gxx_post:
	sts triangle_fx_Gxx_post, r27
	mov r26, r29
	rjmp sound_driver_calculate_delays_triangle_store

sound_driver_calculate_delays_triangle_store:
	sts triangle_pattern_delay_frames, r26



sound_driver_calculate_delays_noise:
	lds r26, noise_pattern_delay_frames
	cpse r26, zero
	rjmp sound_driver_calculate_delays_dpcm
	rjmp sound_driver_calculate_delays_noise_main

sound_driver_calculate_delays_noise_main:
	mov r26, r31 //move the speed to r26
	lds r27, noise_pattern_delay_rows //decrement the delay rows
	cp r27, zero
	brne PC+2
	rjmp sound_driver_calculate_delays_dpcm
	dec r27
	sts noise_pattern_delay_rows, r27
	cpse r27, zero
	rjmp sound_driver_calculate_delays_noise_store
	dec r26

sound_driver_calculate_delays_noise_Sxx:
	ldi r27, 0xFF
	lds r28, noise_fx_Sxx_pre
	lds r29, noise_fx_Sxx_post
sound_driver_calculate_delays_noise_Sxx_check_pre:
	cp r28, r27
	breq sound_driver_calculate_delays_noise_Sxx_check_post
	rjmp sound_driver_calculate_delays_noise_Sxx_pre
sound_driver_calculate_delays_noise_Sxx_check_post:
	cp r29, r27
	breq sound_driver_calculate_delays_noise_Gxx
	rjmp sound_driver_calculate_delays_noise_Sxx_post

sound_driver_calculate_delays_noise_Gxx:
	lds r28, noise_fx_Gxx_pre
	lds r29, noise_fx_Gxx_post
sound_driver_calculate_delays_noise_Gxx_check_pre:
	cp r28, r27
	breq sound_driver_calculate_delays_noise_Gxx_check_post
	rjmp sound_driver_calculate_delays_noise_Gxx_pre
sound_driver_calculate_delays_noise_Gxx_check_post:
	cp r29, r27
	breq sound_driver_calculate_delays_noise_store
	rjmp sound_driver_calculate_delays_noise_Gxx_post

sound_driver_calculate_delays_noise_Sxx_pre:
	sts noise_fx_Sxx_pre, r27
	sub r30, r28 //(song speed)-1-Sxx
	sts noise_fx_Sxx_post, r30
	dec r28
	sts noise_pattern_delay_frames, r28
	mov r30, r31
	subi r30, 1
	rjmp sound_driver_calculate_delays_dpcm

sound_driver_calculate_delays_noise_Sxx_post:
	sts noise_fx_Sxx_post, r27
	mov r26, r29
	rjmp sound_driver_calculate_delays_noise_store

sound_driver_calculate_delays_noise_Gxx_pre:
	sts noise_fx_Gxx_pre, r27
	sub r30, r28 //(song speed)-1-Sxx
	sts noise_fx_Gxx_post, r30
	dec r28
	sts noise_pattern_delay_frames, r28
	mov r30, r31
	subi r30, 1
	rjmp sound_driver_calculate_delays_dpcm
	
sound_driver_calculate_delays_noise_Gxx_post:
	sts noise_fx_Gxx_post, r27
	mov r26, r29
	rjmp sound_driver_calculate_delays_noise_store

sound_driver_calculate_delays_noise_store:
	sts noise_pattern_delay_frames, r26



sound_driver_calculate_delays_dpcm:

sound_driver_instrument_fx_routine:
sound_driver_instrument_routine_channel0_volume:
	lds ZL, pulse1_volume_macro
	lds ZH, pulse1_volume_macro+1
	adiw Z, 0
	breq sound_driver_instrument_routine_channel0_volume_default //if no volume macro is in use, use default multiplier of F
	lsl ZL //multiply by 2 to make Z into a byte pointer for the macro's address
	rol ZH
	lds r26, pulse1_volume_macro_offset
	add ZL, r26
	adc ZH, zero

	lds r27, pulse1_volume_macro_release
	cp r27, r26
	brne sound_driver_instrument_routine_channel0_volume_increment //if the current offset is not equal to the release index, increment the offset
	lds r26, pulse1_volume_macro_loop
	cp r26, r27 //check if loop flag exists NOTE: a loop flag and a release flag can only co-exist if the loop is less than the release
	brlo sound_driver_instrument_routine_channel0_volume_increment+1 //if the current offset is equal to the release index and there is a loop, load the offset with the loop index, but also read the current index data
	rjmp sound_driver_instrument_routine_channel0_volume_read //if the current offset is equal to the release index and there is no loop, then keep the offset unchanged

sound_driver_instrument_routine_channel0_volume_increment:
	inc r26 //increment the macro offset
	sts pulse1_volume_macro_offset, r26
	
sound_driver_instrument_routine_channel0_volume_read:
	lpm r27, Z //load volume data into r27
	cpi r27, 0xFF //check for macro end flag
	brne sound_driver_instrument_routine_channel0_volume_calculate //if the data was not the macro end flag, calculate the volume



sound_driver_instrument_routine_channel0_volume_macro_end_flag:
sound_driver_instrument_routine_channel0_volume_macro_end_flag_check_release:
	lds r27, pulse1_volume_macro_release
	cpi r27, 0xFF
	brne sound_driver_instrument_routine_channel0_volume_macro_end_flag_last_index //if there is a release flag, we don't need to loop. stay at the last valid index

sound_driver_instrument_routine_channel0_volume_macro_end_flag_check_loop:
	lds r27, pulse1_volume_macro_loop //load the loop index
	sts pulse1_volume_macro_offset, r27 //store the loop index into the offset
	rjmp sound_driver_instrument_routine_channel0_volume //go back and re-read the volume data

sound_driver_instrument_routine_channel0_volume_macro_end_flag_last_index:
	subi r26, 2 //go back to last valid index NOTE: Since we increment the offset everytime we read data, we have to decrement twice. 1 to account for the increment and 1 for the end flag.
	sts pulse1_volume_macro_offset, r26
	rjmp sound_driver_instrument_routine_channel0_volume //go back and re-read the volume data



sound_driver_instrument_routine_channel0_volume_calculate:
	ldi ZL, LOW(volumes << 1) //point Z to volume table
	ldi ZH, HIGH(volumes << 1)
	swap r27 //multiply the offset by 16 to move to the correct row in the volume table
	add ZL, r27 //add offset to the table
	adc ZH, zero

sound_driver_instrument_routine_channel0_volume_load:
	lds r27, pulse1_param //load main volume
	andi r27, 0x0F //mask for VVVV volume bits

	lds r26, pulse1_fx_7xy_value
	cpi r26, 0x00
	brne sound_driver_instrument_routine_channel0_volume_load_7xy

	add ZL, r27 //offset the volume table by the main volume
	adc ZH, zero
	lpm r27, Z
	sts pulse1_output_volume, r27 //store the new output volume
	rjmp sound_driver_instrument_routine_channel0_arpeggio

sound_driver_instrument_routine_channel0_volume_default:
	lds r27, pulse1_param //a multiplier of F means in no change to the main volume, so we just copy the value into the output
	andi r27, 0x0F //mask for VVVV volume bits

	lds r26, pulse1_fx_7xy_value
	cpi r26, 0x00
	brne sound_driver_instrument_routine_channel0_volume_default_7xy
	sts pulse1_output_volume, r27
	rjmp sound_driver_instrument_routine_channel0_arpeggio

sound_driver_instrument_routine_channel0_volume_load_7xy:
	sub r27, r26 //subtract the volume by the tremelo value
	brcs sound_driver_instrument_routine_channel0_volume_load_7xy_overflow
	breq sound_driver_instrument_routine_channel0_volume_load_7xy_overflow

	add ZL, r27 //offset the volume table by the main volume
	adc ZH, zero
	lpm r27, Z
	sts pulse1_output_volume, r27 //store the new output volume
	rjmp sound_driver_instrument_routine_channel0_arpeggio

sound_driver_instrument_routine_channel0_volume_load_7xy_overflow:
	ldi r27, 0x01 //if the subtraction resulted in a negative volume, cap it to 0x01
	add ZL, r27 //offset the volume table by the main volume
	adc ZH, zero
	lpm r27, Z
	sts pulse1_output_volume, r27 //store the new output volume
	rjmp sound_driver_instrument_routine_channel0_arpeggio

sound_driver_instrument_routine_channel0_volume_default_7xy:
	sub r27, r26 //subtract the volume by the tremelo value
	brcs sound_driver_instrument_routine_channel0_volume_default_7xy_overflow
	breq sound_driver_instrument_routine_channel0_volume_default_7xy_overflow
	sts pulse1_output_volume, r27
	rjmp sound_driver_instrument_routine_channel0_arpeggio
	
sound_driver_instrument_routine_channel0_volume_default_7xy_overflow:
	ldi r27, 0x01 //if the subtraction resulted in a negative volume, cap it to 0x01
	sts pulse1_output_volume, r27



sound_driver_instrument_routine_channel0_arpeggio:
	//NOTE: The arpeggio macro routine is also in charge of actually setting the timers using the note stored in SRAM. The default routine is responsible for that in the case no arpeggio macro is used.
	lds ZL, pulse1_arpeggio_macro
	lds ZH, pulse1_arpeggio_macro+1
	adiw Z, 0
	breq sound_driver_instrument_routine_channel0_arpeggio_default //if no arpeggio macro is in use, go output the note without any offsets
	lsl ZL //multiply by 2 to make Z into a byte pointer for the macro's address
	rol ZH
	lds r26, pulse1_arpeggio_macro_offset
	add ZL, r26
	adc ZH, zero

	lds r27, pulse1_arpeggio_macro_release
	cp r27, r26
	brne sound_driver_instrument_routine_channel0_arpeggio_increment //if the current offset is not equal to the release index, increment the offset
	lds r26, pulse1_arpeggio_macro_loop
	cp r26, r27 //check if loop flag exists NOTE: a loop flag and a release flag can only co-exist if the loop is less than the release
	brlo sound_driver_instrument_routine_channel0_arpeggio_increment+1 //if the current offset is equal to the release index and there is a loop, reload the loop index, but also read the current index data
	rjmp sound_driver_instrument_routine_channel0_arpeggio_read //if the current offset is equal to the release index and there is no loop, then keep the offset unchanged

sound_driver_instrument_routine_channel0_arpeggio_increment:
	inc r26 //increment the macro offset
	sts pulse1_arpeggio_macro_offset, r26
	
sound_driver_instrument_routine_channel0_arpeggio_read:
	lpm r27, Z //load arpeggio data into r27
	cpi r27, 0x80 //check for macro end flag
	breq sound_driver_instrument_routine_channel0_arpeggio_macro_end_flag
	rjmp sound_driver_instrument_routine_channel0_arpeggio_process //if the data was not the macro end flag, calculate the volume


sound_driver_instrument_routine_channel0_arpeggio_macro_end_flag:
sound_driver_instrument_routine_channel0_arpeggio_macro_end_flag_check_mode:
	subi r26, 1 //keep the offset at the end flag
	sts pulse1_arpeggio_macro_offset, r26
	lds r27, pulse1_arpeggio_macro_mode //load the mode to check for fixed/relative mode NOTE: end behavior for fixed/relative mode is different in that once the macro ends, the true note is played
	cpi r27, 0x01
	brlo sound_driver_instrument_routine_channel0_arpeggio_macro_end_flag_absolute

sound_driver_instrument_routine_channel0_arpeggio_macro_end_flag_fixed_relative_check_release:
	lds r27, pulse1_arpeggio_macro_release
	cpi r27, 0xFF
	brne sound_driver_instrument_routine_channel0_arpeggio_default //if there is a release flag, we don't need to loop. just play the true note

sound_driver_instrument_routine_channel0_arpeggio_macro_end_flag_fixed_relative_check_loop:
	lds r27, pulse1_arpeggio_macro_loop
	cpi r27, 0xFF
	brne sound_driver_instrument_routine_channel0_arpeggio_macro_end_flag_reload //if there is no release flag, but there is a loop, load the offset with the loop index
	rjmp sound_driver_instrument_routine_channel0_arpeggio_default //if there is no release flag and no loop, then play the true note

sound_driver_instrument_routine_channel0_arpeggio_macro_end_flag_absolute:
	lds r27, pulse1_arpeggio_macro_release
	cpi r27, 0xFF
	brne sound_driver_instrument_routine_channel0_arpeggio_macro_end_flag_absolute_no_loop //if there is a release flag, react as if there was no loop.

sound_driver_instrument_routine_channel0_arpeggio_macro_end_flag_absolute_check_loop:
	lds r27, pulse1_arpeggio_macro_loop //load the loop index
	cpi r27, 0xFF //check if loop flag exists
	brne sound_driver_instrument_routine_channel0_arpeggio_macro_end_flag_reload //if a loop flag exists, then load the loop value

sound_driver_instrument_routine_channel0_arpeggio_macro_end_flag_absolute_no_loop:
	lds r28, pulse1_fx_0xy_sequence //check for 0xy effect
	lds r29, pulse1_fx_0xy_sequence+1
	adiw r29:r28, 0
	brne sound_driver_instrument_routine_channel0_arpeggio_default_0xy //if 0xy effect exists, and there is no release/loop, use the default routine and apply the 0xy effect

	subi r26, 1 //if a loop flag does not exist and fixed mode is not used, use the last valid index
	sts pulse1_arpeggio_macro_offset, r26 //store the last valid index into the offset
	rjmp sound_driver_instrument_routine_channel0_arpeggio

sound_driver_instrument_routine_channel0_arpeggio_macro_end_flag_reload:
	sts pulse1_arpeggio_macro_offset, r27 //store the loop index into the offset
	rjmp sound_driver_instrument_routine_channel0_arpeggio //go back and re-read the volume data


sound_driver_instrument_routine_channel0_arpeggio_default:
	lds r28, pulse1_fx_0xy_sequence //load 0xy effect
	lds r29, pulse1_fx_0xy_sequence+1
	adiw r29:r28, 0 //check for 0xy effect
	breq sound_driver_instrument_routine_channel0_arpeggio_default_no_0xy //if there is no 0xy effect, we don't need to roll the sequence
	
//NOTE: because of the way the 0xy parameter is stored and processed, using x0 will not create a faster arpeggio
sound_driver_instrument_routine_channel0_arpeggio_default_0xy:
	lsr r29
	ror r28
	ror r29
	ror r28
	ror r29
	ror r28
	ror r29
	ror r28
	ror r29
	swap r29

	sts pulse1_fx_0xy_sequence, r28 //store the rolled sequence
	sts pulse1_fx_0xy_sequence+1, r29
	andi r28, 0x0F //mask out the 4 LSB
	lds r26, pulse1_note //load the current note index
	add r26, r28 //add the note offset
	rjmp sound_driver_instrument_routine_channel0_arpeggio_process_load
	
sound_driver_instrument_routine_channel0_arpeggio_default_no_0xy:
	//NOTE: the pitch offset does not need to be reset here because there is no new note being calculated
	lds r26, pulse1_note //load the current note index
	rjmp sound_driver_instrument_routine_channel0_arpeggio_process_load

sound_driver_instrument_routine_channel0_arpeggio_process:
	sts pulse1_total_pitch_offset, zero //the pitch offsets must be reset when a new note is to be calculated from an arpeggio macro
	sts pulse1_total_pitch_offset+1, zero
	sts pulse1_total_hi_pitch_offset, zero
	lds r26, pulse1_arpeggio_macro_mode
	cpi r26, 0x01 //absolute mode
	brlo sound_driver_instrument_routine_channel0_arpeggio_process_absolute
	breq sound_driver_instrument_routine_channel0_arpeggio_process_fixed
	rjmp sound_driver_instrument_routine_channel0_arpeggio_process_relative //relative mode

sound_driver_instrument_routine_channel0_arpeggio_process_absolute:
	lds r26, pulse1_note //load the current note index
	add r26, r27 //offset the note with the arpeggio data
	sbrc r27, 7 //check sign bit to check if we are subtracting from the note index
	rjmp sound_driver_instrument_routine_channel0_arpeggio_process_absolute_subtract

sound_driver_instrument_routine_channel0_arpeggio_process_absolute_add:
	cpi r26, 0x57 //check if the result is larger than the size of the note table (0x56 is the highest possible index)
	brlo sound_driver_instrument_routine_channel0_arpeggio_process_load //if the result is valid, go load the new note
	ldi r26, 0x56 //if the result was too large, just set the result to the highest possible note index
	rjmp sound_driver_instrument_routine_channel0_arpeggio_process_load

sound_driver_instrument_routine_channel0_arpeggio_process_absolute_subtract:
	sbrc r26, 7 //check if result is negative
	ldi r26, 0x00 //if the result was negative, reset it to the 0th index
	rjmp sound_driver_instrument_routine_channel0_arpeggio_process_load



sound_driver_instrument_routine_channel0_arpeggio_process_fixed:
	mov r26, r27 //move the arpeggio data into r26
	rjmp sound_driver_instrument_routine_channel0_arpeggio_process_load



sound_driver_instrument_routine_channel0_arpeggio_process_relative:
	lds r26, pulse1_note //load the current note index
	add r26, r27 //offset the note with the arpeggio data
	sbrc r27, 7 //check sign bit to check if we are subtracting from the note index
	rjmp sound_driver_instrument_routine_channel0_arpeggio_process_relative_subtract

sound_driver_instrument_routine_channel0_arpeggio_process_relative_add:
	sts pulse1_note, r26 //NOTE: relative mode modifies the original note index
	cpi r26, 0x57 //check if the result is larger than the size of the note table (0x56 is the highest possible index)
	brlo sound_driver_instrument_routine_channel0_arpeggio_process_load //if the result is valid, go load the new note
	ldi r26, 0x56 //if the result was too large, just set the result to the highest possible note index
	sts pulse1_note, r26
	rjmp sound_driver_instrument_routine_channel0_arpeggio_process_load

sound_driver_instrument_routine_channel0_arpeggio_process_relative_subtract:
	sbrc r26, 7 //check if result is negative
	ldi r26, 0x00 //if the result was negative, reset it to the 0th index
	sts pulse1_note, r26



sound_driver_instrument_routine_channel0_arpeggio_process_load:
	ldi ZL, LOW(note_table << 1) //load in note table
	ldi ZH, HIGH(note_table << 1)
	lsl r26 //double the offset for the note table because we are getting byte data
	add ZL, r26 //add offset
	adc ZH, zero
	lpm r26, Z+ //load bytes
	lpm r27, Z
	sts TCB0_CCMPL, r26 //load the LOW bits for timer
	sts TCB0_CCMPH, r27 //load the HIGH bits for timer
	sts pulse1_fx_3xx_target, r26 //NOTE: 3xx target note is stored here because the true note is always read in this arpeggio macro routine
	sts pulse1_fx_3xx_target+1, r27
	rjmp sound_driver_instrument_routine_channel0_pitch



sound_driver_instrument_routine_channel0_pitch:
	lds ZL, pulse1_pitch_macro
	lds ZH, pulse1_pitch_macro+1
	adiw Z, 0
	brne sound_driver_instrument_routine_channel0_pitch_continue
	rjmp sound_driver_instrument_routine_channel0_pitch_default //if no pitch macro is in use, process the current total pitch macro offset
sound_driver_instrument_routine_channel0_pitch_continue:
	lsl ZL //multiply by 2 to make z into a byte pointer for the macro's address
	rol ZH
	lds r26, pulse1_pitch_macro_offset
	add ZL, r26
	adc ZH, zero

	lds r27, pulse1_pitch_macro_release
	cp r27, r26
	brne sound_driver_instrument_routine_channel0_pitch_increment //if the current offset is not equal to the release index, increment the offset
	lds r26, pulse1_pitch_macro_loop
	cp r26, r27 //check if loop flag exists NOTE: a loop flag and a release flag can only co-exist if the loop is less than the release
	brlo sound_driver_instrument_routine_channel0_pitch_increment+1 //if the current offset is equal to the release index and there is a loop, load the offset with the loop index, but also read the current index data
	rjmp sound_driver_instrument_routine_channel0_pitch_read //if the current offset is equal to the release index and there is no loop, then keep the offset unchanged

sound_driver_instrument_routine_channel0_pitch_increment:
	inc r26 //increment the macro offset
	sts pulse1_pitch_macro_offset, r26
	
sound_driver_instrument_routine_channel0_pitch_read:
	lpm r27, Z //load pitch data into r27
	cpi r27, 0x80 //check for macro end flag
	brne sound_driver_instrument_routine_channel0_pitch_calculate //if the data was not the macro end flag, calculate the pitch offset



sound_driver_instrument_routine_channel0_pitch_macro_end_flag:
sound_driver_instrument_routine_channel0_pitch_macro_end_flag_check_release:
	subi r26, 1 //keep the macro offset at the end flag
	sts pulse1_pitch_macro_offset, r26
	lds r27, pulse1_pitch_macro_release
	cpi r27, 0xFF
	brne sound_driver_instrument_routine_channel0_pitch_default //if there is a release flag, we don't need to loop. offset the pitch by the final total pitch

sound_driver_instrument_routine_channel0_pitch_macro_end_flag_check_loop:
	lds r27, pulse1_pitch_macro_loop //load the loop index
	cpi r27, 0xFF //check if there is a loop index
	breq sound_driver_instrument_routine_channel0_pitch_default //if there is no loop flag, we don't need to loop. offset the pitch by the final total pitch
	sts pulse1_pitch_macro_offset, r27 //store the loop index into the offset
	rjmp sound_driver_instrument_routine_channel0_pitch //go back and re-read the pitch data



sound_driver_instrument_routine_channel0_pitch_default:
	ldi r27, 0x00
sound_driver_instrument_routine_channel0_pitch_calculate:
	push r22 //only registers r16 - r23 can be used with mulsu
	push r23
	mov r22, r27 //store the signed pitch offset data into r22
	ldi r23, 0b10110010 //store r23 with 11.125 note: this is the closest approximation to the 11.1746014718 multiplier we can get with 8 bits
	mulsu r22, r23
	pop r23
	pop r22

	lsr r1 //shift out the fractional bits
	ror r0
	lsr r1
	ror r0
	lsr r1
	ror r0
	lsr r1
	ror r0

sound_driver_instrument_routine_channel0_pitch_calculate_check_negative:
	sbrs r1, 3 //check if result was a negative number
	rjmp sound_driver_instrument_routine_channel0_pitch_calculate_offset //if the result was positive, don't fill with 1s

sound_driver_instrument_routine_channel0_pitch_calculate_negative:
	ldi r28, 0xF0
	or r1, r28 //when right shifting a two's complement number, must use 1s instead of 0s to fill

sound_driver_instrument_routine_channel0_pitch_calculate_check_divisible_8:
	andi r27, 0b00000111
	breq sound_driver_instrument_routine_channel0_pitch_calculate_offset

	ldi r27, 0x01
	add r0, r27
	adc r1, zero

sound_driver_instrument_routine_channel0_pitch_calculate_offset:
	lds r26, pulse1_total_pitch_offset
	lds r27, pulse1_total_pitch_offset+1
	add r0, r26
	adc r1, r27
	sts pulse1_total_pitch_offset, r0
	sts pulse1_total_pitch_offset+1, r1
	lds r26, TCB0_CCMPL //load the low bits for timer
	lds r27, TCB0_CCMPH //load the high bits for timer
	add r26, r0 //offset the timer values
	adc r27, r1
	
	lds r28, pulse1_fx_1xx_total
	lds r29, pulse1_fx_1xx_total+1
	sub r26, r28
	sbc r27, r29
	lds r28, pulse1_fx_2xx_total
	lds r29, pulse1_fx_2xx_total+1
	add r26, r28
	adc r27, r29
	lds r28, pulse1_fx_Pxx_total
	lds r29, pulse1_fx_Pxx_total+1
	add r26, r28
	adc r27, r29
	lds r28, pulse1_fx_Qxy_total_offset //NOTE: Qxy and Rxy offsets are applied here
	lds r29, pulse1_fx_Qxy_total_offset+1
	sub r26, r28
	sbc r27, r29
	lds r28, pulse1_fx_Rxy_total_offset
	lds r29, pulse1_fx_Rxy_total_offset+1
	add r26, r28
	adc r27, r29

	ldi r28, 0x59
	ldi r29, 0x00
	cp r26, r28
	cpc r27, r29
	brlo sound_driver_instrument_routine_channel0_pitch_min

	ldi r28, 0x5A
	ldi r29, 0x59
	cp r26, r28
	cpc r27, r29
	brsh sound_driver_instrument_routine_channel0_pitch_max
	rjmp sound_driver_instrument_routine_channel0_pitch_store

sound_driver_instrument_routine_channel0_pitch_min:
	ldi r28, 0x59
	ldi r29, 0x00
	rjmp sound_driver_instrument_routine_channel0_pitch_store

sound_driver_instrument_routine_channel0_pitch_max:
	ldi r28, 0x59
	ldi r29, 0x59
	rjmp sound_driver_instrument_routine_channel0_pitch_store

sound_driver_instrument_routine_channel0_pitch_store:
	sts TCB0_CCMPL, r26 //store the new low bits for timer
	sts TCB0_CCMPH, r27 //store the new high bits for timer
	


//NOTE: The hi pitch macro routine does not account for overflowing from the offset. In famitracker, if the offset
//goes beyond the note range, there will be no more offset calculations. In this routine, it is possible that
//the pitch goes from B-7 and back around to C-0. I don't believe there will ever be a song in which this will be a problem.
sound_driver_instrument_routine_channel0_hi_pitch:
	lds ZL, pulse1_hi_pitch_macro
	lds ZH, pulse1_hi_pitch_macro+1
	adiw Z, 0
	brne sound_driver_instrument_routine_channel0_hi_pitch_continue
	rjmp sound_driver_instrument_routine_channel0_duty //if no hi pitch macro is in use, go to the next macro routine
sound_driver_instrument_routine_channel0_hi_pitch_continue:
	lsl ZL //multiply by 2 to make z into a byte pointer for the macro's address
	rol ZH
	lds r26, pulse1_hi_pitch_macro_offset
	add ZL, r26
	adc ZH, zero

	lds r27, pulse1_hi_pitch_macro_release
	cp r27, r26
	brne sound_driver_instrument_routine_channel0_hi_pitch_increment //if the current offset is not equal to the release index, increment the offset
	lds r26, pulse1_hi_pitch_macro_loop
	cp r26, r27 //check if loop flag exists NOTE: a loop flag and a release flag can only co-exist if the loop is less than the release
	brlo sound_driver_instrument_routine_channel0_hi_pitch_increment+1 //if the current offset is equal to the release index and there is a loop, load the offset with the loop index, but also read the current index data
	rjmp sound_driver_instrument_routine_channel0_hi_pitch_read //if the current offset is equal to the release index and there is no loop, then keep the offset unchanged

sound_driver_instrument_routine_channel0_hi_pitch_increment:
	inc r26 //increment the macro offset
	sts pulse1_hi_pitch_macro_offset, r26
	
sound_driver_instrument_routine_channel0_hi_pitch_read:
	lpm r27, Z //load hi pitch data into r27
	cpi r27, 0x80 //check for macro end flag
	brne sound_driver_instrument_routine_channel0_hi_pitch_calculate //if the data was not the macro end flag, calculate the hi pitch offset



sound_driver_instrument_routine_channel0_hi_pitch_macro_end_flag:
sound_driver_instrument_routine_channel0_hi_pitch_macro_end_flag_check_release:
	subi r26, 1 //keep the macro offset at the end flag
	sts pulse1_hi_pitch_macro_offset, r26
	lds r27, pulse1_hi_pitch_macro_release
	cpi r27, 0xFF
	brne sound_driver_instrument_routine_channel0_hi_pitch_default //if there is a release flag, we don't need to loop. offset the hi pitch by the final total hi pitch

sound_driver_instrument_routine_channel0_hi_pitch_macro_end_flag_check_loop:
	lds r27, pulse1_hi_pitch_macro_loop //load the loop index
	cpi r27, 0xFF //check if there is a loop index
	breq sound_driver_instrument_routine_channel0_hi_pitch_default //if there is no loop flag, we don't need to loop. offset the pitch by the final total hi pitch
	sts pulse1_hi_pitch_macro_offset, r27 //store the loop index into the offset
	rjmp sound_driver_instrument_routine_channel0_hi_pitch //go back and re-read the hi pitch data



sound_driver_instrument_routine_channel0_hi_pitch_default:
	lds r27, pulse1_total_hi_pitch_offset
	rjmp sound_driver_instrument_routine_channel0_hi_pitch_calculate_multiply

sound_driver_instrument_routine_channel0_hi_pitch_calculate:
	lds r26, pulse1_total_hi_pitch_offset //load the total hi pitch offset to change
	add r27, r26
	sts pulse1_total_hi_pitch_offset, r27

sound_driver_instrument_routine_channel0_hi_pitch_calculate_multiply:
	push r22 //only registers r16 - r23 can be used with mulsu
	push r23
	mov r22, r27 //store the signed hi pitch offset data into r22
	ldi r23, 0b10110010 //store r23 with 11.125 note: this is the closest approximation to the 11.1746014718 multiplier we can get with 8 bits
	mulsu r22, r23
	pop r23
	pop r22

	//NOTE: fractional bits do not need to be shifted out because hi pitch offsets are multiplied by 16. shifting right 4 times for the fraction and left 4 times for the 16x is the same as no shift.
sound_driver_instrument_routine_channel0_hi_pitch_calculate_offset:
	lds r26, TCB0_CCMPL //load the low bits for timer
	lds r27, TCB0_CCMPH //load the high bits for timer
	add r26, r0 //offset the timer values
	adc r27, r1
	sts TCB0_CCMPL, r26 //store the new low bits for timer
	sts TCB0_CCMPH, r27 //store the new high bits for timer



//NOTE: Unlike the original NES, changing the duty cycle will reset the sequencer position entirely.
sound_driver_instrument_routine_channel0_duty:
	lds ZL, pulse1_duty_macro
	lds ZH, pulse1_duty_macro+1
	adiw Z, 0
	breq sound_driver_channel0_fx_routines //if no duty macro is in use, go to the next routine
	lsl ZL //multiply by 2 to make z into a byte pointer for the macro's address
	rol ZH
	lds r26, pulse1_duty_macro_offset
	add ZL, r26
	adc ZH, zero

	lds r27, pulse1_duty_macro_release
	cp r27, r26
	brne sound_driver_instrument_routine_channel0_duty_increment //if the current offset is not equal to the release index, increment the offset
	lds r26, pulse1_duty_macro_loop
	cp r26, r27 //check if loop flag exists NOTE: a loop flag and a release flag can only co-exist if the loop is less than the release
	brlo sound_driver_instrument_routine_channel0_duty_increment+1 //if the current offset is equal to the release index and there is a loop, load the offset with the loop index, but also read the current index data
	rjmp sound_driver_channel0_fx_routines //if the current offset is equal to the release index and there is no loop, then keep the offset unchanged and skip the rest of the routine

sound_driver_instrument_routine_channel0_duty_increment:
	inc r26 //increment the macro offset
	sts pulse1_duty_macro_offset, r26
	
sound_driver_instrument_routine_channel0_duty_read:
	lpm r27, Z //load pitch data into r27
	cpi r27, 0xFF //check for macro end flag
	brne sound_driver_instrument_routine_channel0_duty_load //if the data was not the macro end flag, load the new duty cycle



sound_driver_instrument_routine_channel0_duty_macro_end_flag:
sound_driver_instrument_routine_channel0_duty_macro_end_flag_check_release:
	subi r26, 1 //keep the macro offset at the end flag
	sts pulse1_duty_macro_offset, r26
	lds r27, pulse1_duty_macro_release
	cpi r27, 0xFF
	brne sound_driver_channel0_fx_routines //if there is a release flag, we don't need to loop. skip the rest of the routine.

sound_driver_instrument_routine_channel0_duty_macro_end_flag_check_loop:
	lds r27, pulse1_duty_macro_loop //load the loop index
	cpi r27, 0xFF //check if there is a loop index
	breq sound_driver_channel0_fx_routines //if there is no loop flag, we don't need to loop. skip the rest of the routine.
	sts pulse1_duty_macro_offset, r27 //store the loop index into the offset
	rjmp sound_driver_instrument_routine_channel0_duty //go back and re-read the duty data



sound_driver_instrument_routine_channel0_duty_load:
	ldi ZL, LOW(sequences << 1) //point Z to sequence table
	ldi ZH, HIGH(sequences << 1)
	add ZL, r27 //offset the pointer by the duty macro data
	adc ZH, zero

	lsr r27 //move the duty cycle bits to the 2 MSB for pulse1_param (register $4000)
	ror r27
	ror r27
	lds r26, pulse1_param //load r26 with pulse1_param (register $4000)
	mov r28, r26 //store a copy of pulse1_param into r28
	andi r26, 0b11000000 //mask the duty cycle bits
	cpse r27, r26 //check if the previous duty cycle and the new duty cycle are equal
	rjmp sound_driver_instrument_routine_channel0_duty_load_store
	rjmp sound_driver_channel0_fx_routines //if the previous and new duty cycle are the same, don't reload the sequence

sound_driver_instrument_routine_channel0_duty_load_store:
	lpm pulse1_sequence, Z //store the sequence

	andi r28, 0b00111111 //mask out the duty cycle bits
	or r28, r27 //store the new duty cycle bits into r27
	sts pulse1_param, r28



sound_driver_channel0_fx_routines:
sound_driver_channel0_fx_1xx_routine:
	lds ZL, pulse1_fx_1xx
	lds ZH, pulse1_fx_1xx+1
	adiw Z, 0
	breq sound_driver_channel0_fx_2xx_routine

	lds r26, pulse1_fx_1xx_total //load the rate to change the pitch by
	lds r27, pulse1_fx_1xx_total+1
	add r26, ZL //increase the total offset by the rate
	adc r27, ZH
	sts pulse1_fx_1xx_total, r26
	sts pulse1_fx_1xx_total+1, r27



sound_driver_channel0_fx_2xx_routine:
	lds ZL, pulse1_fx_2xx
	lds ZH, pulse1_fx_2xx+1
	adiw Z, 0
	breq sound_driver_channel0_fx_3xx_routine

	lds r26, pulse1_fx_2xx_total //load the rate to change the pitch by
	lds r27, pulse1_fx_2xx_total+1
	add r26, ZL //increase the total offset by the rate
	adc r27, ZH
	sts pulse1_fx_2xx_total, r26
	sts pulse1_fx_2xx_total+1, r27



sound_driver_channel0_fx_3xx_routine:
	lds ZL, pulse1_fx_3xx_speed
	lds ZH, pulse1_fx_3xx_speed+1
	adiw Z, 0
	brne sound_driver_channel0_fx_3xx_routine_check_start
	rjmp sound_driver_channel0_fx_4xy_routine

sound_driver_channel0_fx_3xx_routine_check_start:
	lds r26, pulse1_fx_3xx_start
	lds r27, pulse1_fx_3xx_start+1
	adiw r26:r27, 0
	brne sound_driver_channel0_fx_3xx_routine_main
	rjmp sound_driver_channel0_fx_4xy_routine

sound_driver_channel0_fx_3xx_routine_main:
	lds r28, pulse1_fx_3xx_target
	lds r29, pulse1_fx_3xx_target+1

	cp r26, r28 //check if the target is lower, higher or equal to the starting period
	cpc r27, r29
	breq sound_driver_channel0_fx_3xx_routine_disable
	brlo sound_driver_channel0_fx_3xx_routine_subtract //if target is larger, we need to add to the start (subtract from the current timer)
	rjmp sound_driver_channel0_fx_3xx_routine_add //if target is smaller, we need to subtract from the start (add to the current timer)

sound_driver_channel0_fx_3xx_routine_disable:
	sts pulse1_fx_3xx_start, zero //setting the starting period to 0 effectively disables this routine until a note has been changed
	sts pulse1_fx_3xx_start+1, zero //NOTE: to truly disable the effect, 300 must be written.
	rjmp sound_driver_channel0_fx_4xy_routine

sound_driver_channel0_fx_3xx_routine_subtract:
	sub r28, r26 //store the total difference between the start and the target into r28:r29
	sbc r29, r27
	lds r26, pulse1_fx_3xx_total_offset
	lds r27, pulse1_fx_3xx_total_offset+1

	add r26, ZL //add the speed to the total offset
	adc r27, ZH
	sub r28, r26 //invert the total difference with the total offset
	sbc r29, r27
	brlo sound_driver_channel0_fx_3xx_routine_disable //if the total offset has surpassed the target difference (target note has been reached)

	sts pulse1_fx_3xx_total_offset, r26 //store the new total offset
	sts pulse1_fx_3xx_total_offset+1, r27

	lds r26, TCB0_CCMPL //load the current timer period
	lds r27, TCB0_CCMPH
	sub r26, r28 //offset the current timer period with the total offset
	sbc r27, r29
	sts TCB0_CCMPL, r26
	sts TCB0_CCMPH, r27
	rjmp sound_driver_channel0_fx_4xy_routine

sound_driver_channel0_fx_3xx_routine_add:
	sub r26, r28 //store the total difference between the start and the target into r28:r29
	sbc r27, r29
	lds r28, pulse1_fx_3xx_total_offset
	lds r29, pulse1_fx_3xx_total_offset+1

	add r28, ZL //add the speed to the total offset
	adc r29, ZH
	sub r26, r28 //invert the total difference with the total offset
	sbc r27, r29
	brlo sound_driver_channel0_fx_3xx_routine_disable //if the total offset has surpassed the target difference (target note has been reached)

	sts pulse1_fx_3xx_total_offset, r28 //store the new total offset
	sts pulse1_fx_3xx_total_offset+1, r29

	lds r28, TCB0_CCMPL //load the current timer period
	lds r29, TCB0_CCMPH
	add r28, r26 //offset the current timer period with the total offset
	adc r29, r27
	sts TCB0_CCMPL, r28
	sts TCB0_CCMPH, r29



sound_driver_channel0_fx_4xy_routine:
	lds r26, pulse1_fx_4xy_speed
	cp r26, zero
	brne sound_driver_channel0_fx_4xy_routine_continue
	rjmp sound_driver_channel0_fx_7xy_routine //if speed is 0, then the effect is disabled

sound_driver_channel0_fx_4xy_routine_continue:
	lds r27, pulse1_fx_4xy_depth
	lds r28, pulse1_fx_4xy_phase
	add r28, r26 //increase the phase by the speed
	cpi r28, 64 //check if the phase overflowed NOTE: phase values range from 0-63
	brlo sound_driver_channel0_fx_4xy_routine_phase //if no overflow, map the phase to 0-15.
	ldi r28, 0x00 //reset the phase if there was overflow

sound_driver_channel0_fx_4xy_routine_phase:
	sts pulse1_fx_4xy_phase, r28 //store the new phase
	cpi r28, 16
	brlo sound_driver_channel0_fx_4xy_routine_phase_0
	cpi r28, 32
	brlo sound_driver_channel0_fx_4xy_routine_phase_1
	cpi r28, 48
	brlo sound_driver_channel0_fx_4xy_routine_phase_2
	rjmp sound_driver_channel0_fx_4xy_routine_phase_3

sound_driver_channel0_fx_4xy_routine_phase_0:
	andi r28, 0x0F //mask for values 0-15
	rjmp sound_driver_channel0_fx_4xy_routine_load_subtract

sound_driver_channel0_fx_4xy_routine_phase_1:
	ori r28, 0xF0
	com r28 //invert values 0-15
	rjmp sound_driver_channel0_fx_4xy_routine_load_subtract

sound_driver_channel0_fx_4xy_routine_phase_2:
	andi r28, 0x0F //mask for values 0-15
	rjmp sound_driver_channel0_fx_4xy_routine_load_add

sound_driver_channel0_fx_4xy_routine_phase_3:
	ori r28, 0xF0
	com r28 //invert values 0-15
	rjmp sound_driver_channel0_fx_4xy_routine_load_add

sound_driver_channel0_fx_4xy_routine_load_add:
	swap r27 //multiply depth by 16
	add r28, r27 //add the depth to the phase NOTE: the table is divided into sixteen different set of 8 values, which correspond to the depth
	
	ldi ZL, LOW(vibrato_table << 1) //point z to vibrato table
	ldi ZH, HIGH(vibrato_table << 1)
	add ZL, r28 //offset the table by the depth+phase
	adc ZH, zero
	lpm r28, Z //load the tremelo value into r28

	push r22 //only registers r16 - r23 can be used with mulsu
	push r23
	mov r22, r28 //store the vibrato value into r22
	ldi r23, 0b10110010 //store r23 with 11.125 note: this is the closest approximation to the 11.1746014718 multiplier we can get with 8 bits
	mul r22, r23
	pop r23
	pop r22

	lsr r1 //shift out the fractional bits
	ror r0
	lsr r1
	ror r0
	lsr r1
	ror r0
	lsr r1
	ror r0
	
	lds r26, TCB0_CCMPL
	lds r27, TCB0_CCMPH
	add r26, r0
	adc r27, r1
	sts TCB0_CCMPL, r26
	sts TCB0_CCMPH, r27
	rjmp sound_driver_channel0_fx_7xy_routine

sound_driver_channel0_fx_4xy_routine_load_subtract:
	swap r27 //multiply depth by 16
	add r28, r27 //add the depth to the phase NOTE: the table is divided into sixteen different set of 8 values, which correspond to the depth
	ldi ZL, LOW(vibrato_table << 1) //point z to vibrato table
	ldi ZH, HIGH(vibrato_table << 1)
	add ZL, r28 //offset the table by the depth+phase
	adc ZH, zero
	lpm r28, Z //load the vibrato value into r28

	push r22 //only registers r16 - r23 can be used with mulsu
	push r23
	mov r22, r28 //store the vibrato value into r22
	ldi r23, 0b10110010 //store r23 with 11.125 note: this is the closest approximation to the 11.1746014718 multiplier we can get with 8 bits
	mul r22, r23
	pop r23
	pop r22

	lsr r1 //shift out the fractional bits
	ror r0
	lsr r1
	ror r0
	lsr r1
	ror r0
	lsr r1
	ror r0

	lds r26, TCB0_CCMPL
	lds r27, TCB0_CCMPH
	sub r26, r0
	sbc r27, r1
	sts TCB0_CCMPL, r26
	sts TCB0_CCMPH, r27



sound_driver_channel0_fx_7xy_routine:
	lds r26, pulse1_fx_7xy_speed
	cp r26, zero
	breq sound_driver_channel0_fx_Axy_routine //if speed is 0, then the effect is disabled

	lds r27, pulse1_fx_7xy_depth
	lds r28, pulse1_fx_7xy_phase
	add r28, r26 //increase the phase by the speed
	cpi r28, 64 //check if the phase overflowed NOTE: phase values range from 0-63
	brlo sound_driver_channel0_fx_7xy_routine_phase //if no overflow, map the phase to 0-15.
	ldi r28, 0x00 //reset the phase if there was overflow

sound_driver_channel0_fx_7xy_routine_phase:
	sts pulse1_fx_7xy_phase, r28 //store the new phase
	lsr r28 //divide the phase by 2 NOTE: 7xy only uses half a sine unlike 4xy
	sbrs r28, 4
	rjmp sound_driver_channel0_fx_7xy_routine_phase_0
	rjmp sound_driver_channel0_fx_7xy_routine_phase_1
	
sound_driver_channel0_fx_7xy_routine_phase_0:
	andi r28, 0x0F //mask for values 0-15
	rjmp sound_driver_channel0_fx_7xy_routine_load

sound_driver_channel0_fx_7xy_routine_phase_1:
	ori r28, 0xF0
	com r28 //invert values 0-15
	rjmp sound_driver_channel0_fx_7xy_routine_load

sound_driver_channel0_fx_7xy_routine_load:
	swap r27 //multiply depth by 16
	add r28, r27 //add the depth to the phase NOTE: the table is divided into sixteen different set of 8 values, which correspond to the depth
	
	ldi ZL, LOW(vibrato_table << 1) //point z to vibrato table
	ldi ZH, HIGH(vibrato_table << 1)
	add ZL, r28 //offset the table by the depth+phase
	adc ZH, zero
	lpm r28, Z //load the vibrato value into r28

	lsr r28 //convert to tremelo value by shifting to the right
	sts pulse1_fx_7xy_value, r28



sound_driver_channel0_fx_Axy_routine:
	lds r27, pulse1_fx_Axy
	cp r27, zero
	breq sound_driver_channel0_fx_Qxy_routine //0 means that the effect is not in use
	
	lds r26, pulse1_fractional_volume //load fractional volume representation of the channel
	lds r28, pulse1_param //load the integer volume representation of the channel
	mov r29, r26 //copy fractional volume into r29
	mov r30, r28 //copy the pulse1_param into r30
	swap r30
	andi r29, 0xF0 //mask for integer volume bits from the fractional volume
	andi r30, 0xF0 //mask for VVVV volume bits

	cp r30, r29 //compare the fractional and integer volumes
	breq sound_driver_channel0_fx_Axy_routine_calculate

sound_driver_channel0_fx_Axy_routine_reload:
	mov r26, r30 //overwrite the fractional volume with the integer volume

sound_driver_channel0_fx_Axy_routine_calculate:
	sbrc r27, 7 //check for negative sign bit in Axy offset value
	rjmp sound_driver_channel0_fx_Axy_routine_calculate_subtraction

sound_driver_channel0_fx_Axy_routine_calculate_addition:
	add r26, r27 //add the fractional volume with the offset specified by the Axy effect
	brcc sound_driver_channel0_fx_Axy_routine_calculate_store //if the fractional volume did not overflow, go store the new volume
	ldi r26, 0xF0 //if the fractional volume did overflow, reset it back to the highest integer volume possible (0xF)
	rjmp sound_driver_channel0_fx_Axy_routine_calculate_store

sound_driver_channel0_fx_Axy_routine_calculate_subtraction:
	add r26, r27 //add the fractional volume with the offset specified by the Axy effect
	brcs sound_driver_channel0_fx_Axy_routine_calculate_store //if the fractional volume did not overflow, go store the new volume
	ldi r26, 0x00 //if the fractional volume did overflow, reset it back to the lowest integer volume possible (0x0)

sound_driver_channel0_fx_Axy_routine_calculate_store:
	sts pulse1_fractional_volume, r26 //store the new fractional volume
	andi r26, 0xF0 //mask for integer volume bits from the fractional volume
	swap r26
	andi r28, 0xF0 //mask out the old VVVV volume bits
	or r28, r26 //store the new volume back into pulse1_param
	sts pulse1_param, r28



//NOTE: The Qxy and Rxy routines ONLY calculate the total offset. The offset is applied in the pitch macro routine
sound_driver_channel0_fx_Qxy_routine:
	lds ZL, pulse1_fx_Qxy_target
	lds ZH, pulse1_fx_Qxy_target+1
	adiw Z, 0
	breq sound_driver_channel0_fx_Rxy_routine //if the effect is not enabled, skip the routine

	lds r26, pulse1_fx_Qxy_total_offset
	lds r27, pulse1_fx_Qxy_total_offset+1
	lds r28, TCB0_CCMPL
	lds r29, TCB0_CCMPH

	sub ZL, r28 //calculate the difference to the target
	sbc ZH, r29
	brsh sound_driver_channel0_fx_Qxy_routine_end //if the target has been reached (or passed)
	brlo sound_driver_channel0_fx_Qxy_routine_add

sound_driver_channel0_fx_Qxy_routine_end:
	sts pulse1_fx_Qxy_total_offset, zero //turn off the effect
	sts pulse1_fx_Qxy_total_offset+1, zero
	sts pulse1_fx_Qxy_target, zero
	sts pulse1_fx_Qxy_target+1, zero
	lds r27, pulse1_fx_Qxy_target_note
	sts pulse1_note, r27 //replace the note with the final target note
	rjmp sound_driver_channel0_fx_Rxy_routine

sound_driver_channel0_fx_Qxy_routine_add:
	lds r28, pulse1_fx_Qxy_speed
	lds r29, pulse1_fx_Qxy_speed+1
	add r26, r28 //increase the total offset by the speed
	adc r27, r29
	sts pulse1_fx_Qxy_total_offset, r26 //store the total offset
	sts pulse1_fx_Qxy_total_offset+1, r27



sound_driver_channel0_fx_Rxy_routine:
	lds ZL, pulse1_fx_Rxy_target
	lds ZH, pulse1_fx_Rxy_target+1
	adiw Z, 0
	breq sound_driver_instrument_routine_channel1_volume //if the effect is not enabled, skip the routine

	lds r26, pulse1_fx_Rxy_total_offset
	lds r27, pulse1_fx_Rxy_total_offset+1
	lds r28, TCB0_CCMPL
	lds r29, TCB0_CCMPH

	sub r28, ZL //calculate the difference to the target
	sbc r29, ZH
	brsh sound_driver_channel0_fx_Rxy_routine_end //if the target has been reached (or passed)
	brlo sound_driver_channel0_fx_Rxy_routine_add

sound_driver_channel0_fx_Rxy_routine_end:
	sts pulse1_fx_Rxy_total_offset, zero //disable the effect
	sts pulse1_fx_Rxy_total_offset+1, zero
	sts pulse1_fx_Rxy_target, zero
	sts pulse1_fx_Rxy_target+1, zero
	lds r27, pulse1_fx_Rxy_target_note
	sts pulse1_note, r27 //replace the note with the final target note
	rjmp sound_driver_instrument_routine_channel1_volume

sound_driver_channel0_fx_Rxy_routine_add:
	lds r28, pulse1_fx_Rxy_speed
	lds r29, pulse1_fx_Rxy_speed+1
	add r26, r28 //increase the total offset by the speed
	adc r27, r29
	sts pulse1_fx_Rxy_total_offset, r26 //store the total offset
	sts pulse1_fx_Rxy_total_offset+1, r27



sound_driver_instrument_routine_channel1_volume:
	lds ZL, pulse2_volume_macro
	lds ZH, pulse2_volume_macro+1
	adiw Z, 0
	breq sound_driver_instrument_routine_channel1_volume_default //if no volume macro is in use, use default multiplier of F
	lsl ZL //multiply by 2 to make Z into a byte pointer for the macro's address
	rol ZH
	lds r26, pulse2_volume_macro_offset
	add ZL, r26
	adc ZH, zero

	lds r27, pulse2_volume_macro_release
	cp r27, r26
	brne sound_driver_instrument_routine_channel1_volume_increment //if the current offset is not equal to the release index, increment the offset
	lds r26, pulse2_volume_macro_loop
	cp r26, r27 //check if loop flag exists NOTE: a loop flag and a release flag can only co-exist if the loop is less than the release
	brlo sound_driver_instrument_routine_channel1_volume_increment+1 //if the current offset is equal to the release index and there is a loop, load the offset with the loop index, but also read the current index data
	rjmp sound_driver_instrument_routine_channel1_volume_read //if the current offset is equal to the release index and there is no loop, then keep the offset unchanged

sound_driver_instrument_routine_channel1_volume_increment:
	inc r26 //increment the macro offset
	sts pulse2_volume_macro_offset, r26
	
sound_driver_instrument_routine_channel1_volume_read:
	lpm r27, Z //load volume data into r27
	cpi r27, 0xFF //check for macro end flag
	brne sound_driver_instrument_routine_channel1_volume_calculate //if the data was not the macro end flag, calculate the volume



sound_driver_instrument_routine_channel1_volume_macro_end_flag:
sound_driver_instrument_routine_channel1_volume_macro_end_flag_check_release:
	lds r27, pulse2_volume_macro_release
	cpi r27, 0xFF
	brne sound_driver_instrument_routine_channel1_volume_macro_end_flag_last_index //if there is a release flag, we don't need to loop. stay at the last valid index

sound_driver_instrument_routine_channel1_volume_macro_end_flag_check_loop:
	lds r27, pulse2_volume_macro_loop //load the loop index
	sts pulse2_volume_macro_offset, r27 //store the loop index into the offset
	rjmp sound_driver_instrument_routine_channel1_volume //go back and re-read the volume data

sound_driver_instrument_routine_channel1_volume_macro_end_flag_last_index:
	subi r26, 2 //go back to last valid index NOTE: Since we increment the offset everytime we read data, we have to decrement twice. 1 to account for the increment and 1 for the end flag.
	sts pulse2_volume_macro_offset, r26
	rjmp sound_driver_instrument_routine_channel1_volume //go back and re-read the volume data



sound_driver_instrument_routine_channel1_volume_calculate:
	ldi ZL, LOW(volumes << 1) //point Z to volume table
	ldi ZH, HIGH(volumes << 1)
	swap r27 //multiply the offset by 16 to move to the correct row in the volume table
	add ZL, r27 //add offset to the table
	adc ZH, zero

sound_driver_instrument_routine_channel1_volume_load:
	lds r27, pulse2_param //load main volume
	andi r27, 0x0F //mask for VVVV volume bits

	lds r26, pulse2_fx_7xy_value
	cpi r26, 0x00
	brne sound_driver_instrument_routine_channel1_volume_load_7xy

	add ZL, r27 //offset the volume table by the main volume
	adc ZH, zero
	lpm r27, Z
	sts pulse2_output_volume, r27 //store the new output volume
	rjmp sound_driver_instrument_routine_channel1_arpeggio

sound_driver_instrument_routine_channel1_volume_default:
	lds r27, pulse2_param //a multiplier of F means in no change to the main volume, so we just copy the value into the output
	andi r27, 0x0F //mask for VVVV volume bits

	lds r26, pulse2_fx_7xy_value
	cpi r26, 0x00
	brne sound_driver_instrument_routine_channel1_volume_default_7xy
	sts pulse2_output_volume, r27
	rjmp sound_driver_instrument_routine_channel1_arpeggio

sound_driver_instrument_routine_channel1_volume_load_7xy:
	sub r27, r26 //subtract the volume by the tremelo value
	brcs sound_driver_instrument_routine_channel1_volume_load_7xy_overflow
	breq sound_driver_instrument_routine_channel1_volume_load_7xy_overflow

	add ZL, r27 //offset the volume table by the main volume
	adc ZH, zero
	lpm r27, Z
	sts pulse2_output_volume, r27 //store the new output volume
	rjmp sound_driver_instrument_routine_channel1_arpeggio

sound_driver_instrument_routine_channel1_volume_load_7xy_overflow:
	ldi r27, 0x01 //if the subtraction resulted in a negative volume, cap it to 0x01
	add ZL, r27 //offset the volume table by the main volume
	adc ZH, zero
	lpm r27, Z
	sts pulse2_output_volume, r27 //store the new output volume
	rjmp sound_driver_instrument_routine_channel1_arpeggio

sound_driver_instrument_routine_channel1_volume_default_7xy:
	sub r27, r26 //subtract the volume by the tremelo value
	brcs sound_driver_instrument_routine_channel1_volume_default_7xy_overflow
	breq sound_driver_instrument_routine_channel1_volume_default_7xy_overflow
	sts pulse2_output_volume, r27
	rjmp sound_driver_instrument_routine_channel1_arpeggio
	
sound_driver_instrument_routine_channel1_volume_default_7xy_overflow:
	ldi r27, 0x01 //if the subtraction resulted in a negative volume, cap it to 0x01
	sts pulse2_output_volume, r27



sound_driver_instrument_routine_channel1_arpeggio:
	//NOTE: The arpeggio macro routine is also in charge of actually setting the timers using the note stored in SRAM. The default routine is responsible for that in the case no arpeggio macro is used.
	lds ZL, pulse2_arpeggio_macro
	lds ZH, pulse2_arpeggio_macro+1
	adiw Z, 0
	breq sound_driver_instrument_routine_channel1_arpeggio_default //if no arpeggio macro is in use, go output the note without any offsets
	lsl ZL //multiply by 2 to make Z into a byte pointer for the macro's address
	rol ZH
	lds r26, pulse2_arpeggio_macro_offset
	add ZL, r26
	adc ZH, zero

	lds r27, pulse2_arpeggio_macro_release
	cp r27, r26
	brne sound_driver_instrument_routine_channel1_arpeggio_increment //if the current offset is not equal to the release index, increment the offset
	lds r26, pulse2_arpeggio_macro_loop
	cp r26, r27 //check if loop flag exists NOTE: a loop flag and a release flag can only co-exist if the loop is less than the release
	brlo sound_driver_instrument_routine_channel1_arpeggio_increment+1 //if the current offset is equal to the release index and there is a loop, reload the loop index, but also read the current index data
	rjmp sound_driver_instrument_routine_channel1_arpeggio_read //if the current offset is equal to the release index and there is no loop, then keep the offset unchanged

sound_driver_instrument_routine_channel1_arpeggio_increment:
	inc r26 //increment the macro offset
	sts pulse2_arpeggio_macro_offset, r26
	
sound_driver_instrument_routine_channel1_arpeggio_read:
	lpm r27, Z //load arpeggio data into r27
	cpi r27, 0x80 //check for macro end flag
	breq sound_driver_instrument_routine_channel1_arpeggio_macro_end_flag
	rjmp sound_driver_instrument_routine_channel1_arpeggio_process //if the data was not the macro end flag, calculate the volume


sound_driver_instrument_routine_channel1_arpeggio_macro_end_flag:
sound_driver_instrument_routine_channel1_arpeggio_macro_end_flag_check_mode:
	subi r26, 1 //keep the offset at the end flag
	sts pulse2_arpeggio_macro_offset, r26
	lds r27, pulse2_arpeggio_macro_mode //load the mode to check for fixed/relative mode NOTE: end behavior for fixed/relative mode is different in that once the macro ends, the true note is played
	cpi r27, 0x01
	brlo sound_driver_instrument_routine_channel1_arpeggio_macro_end_flag_absolute

sound_driver_instrument_routine_channel1_arpeggio_macro_end_flag_fixed_relative_check_release:
	lds r27, pulse2_arpeggio_macro_release
	cpi r27, 0xFF
	brne sound_driver_instrument_routine_channel1_arpeggio_default //if there is a release flag, we don't need to loop. just play the true note

sound_driver_instrument_routine_channel1_arpeggio_macro_end_flag_fixed_relative_check_loop:
	lds r27, pulse2_arpeggio_macro_loop
	cpi r27, 0xFF
	brne sound_driver_instrument_routine_channel1_arpeggio_macro_end_flag_reload //if there is no release flag, but there is a loop, load the offset with the loop index
	rjmp sound_driver_instrument_routine_channel1_arpeggio_default //if there is no release flag and no loop, then play the true note

sound_driver_instrument_routine_channel1_arpeggio_macro_end_flag_absolute:
	lds r27, pulse2_arpeggio_macro_release
	cpi r27, 0xFF
	brne sound_driver_instrument_routine_channel1_arpeggio_macro_end_flag_absolute_no_loop //if there is a release flag, react as if there was no loop.

sound_driver_instrument_routine_channel1_arpeggio_macro_end_flag_absolute_check_loop:
	lds r27, pulse2_arpeggio_macro_loop //load the loop index
	cpi r27, 0xFF //check if loop flag exists
	brne sound_driver_instrument_routine_channel1_arpeggio_macro_end_flag_reload //if a loop flag exists, then load the loop value

sound_driver_instrument_routine_channel1_arpeggio_macro_end_flag_absolute_no_loop:
	lds r28, pulse2_fx_0xy_sequence //check for 0xy effect
	lds r29, pulse2_fx_0xy_sequence+1
	adiw r29:r28, 0
	brne sound_driver_instrument_routine_channel1_arpeggio_default_0xy //if 0xy effect exists, and there is no release/loop, use the default routine and apply the 0xy effect

	subi r26, 1 //if a loop flag does not exist and fixed mode is not used, use the last valid index
	sts pulse2_arpeggio_macro_offset, r26 //store the last valid index into the offset
	rjmp sound_driver_instrument_routine_channel1_arpeggio

sound_driver_instrument_routine_channel1_arpeggio_macro_end_flag_reload:
	sts pulse2_arpeggio_macro_offset, r27 //store the loop index into the offset
	rjmp sound_driver_instrument_routine_channel1_arpeggio //go back and re-read the volume data


sound_driver_instrument_routine_channel1_arpeggio_default:
	lds r28, pulse2_fx_0xy_sequence //load 0xy effect
	lds r29, pulse2_fx_0xy_sequence+1
	adiw r29:r28, 0 //check for 0xy effect
	breq sound_driver_instrument_routine_channel1_arpeggio_default_no_0xy //if there is no 0xy effect, we don't need to roll the sequence
	
//NOTE: because of the way the 0xy parameter is stored and processed, using x0 will not create a faster arpeggio
sound_driver_instrument_routine_channel1_arpeggio_default_0xy:
	lsr r29
	ror r28
	ror r29
	ror r28
	ror r29
	ror r28
	ror r29
	ror r28
	ror r29
	swap r29

	sts pulse2_fx_0xy_sequence, r28 //store the rolled sequence
	sts pulse2_fx_0xy_sequence+1, r29
	andi r28, 0x0F //mask out the 4 LSB
	lds r26, pulse2_note //load the current note index
	add r26, r28 //add the note offset
	rjmp sound_driver_instrument_routine_channel1_arpeggio_process_load
	
sound_driver_instrument_routine_channel1_arpeggio_default_no_0xy:
	//NOTE: the pitch offset does not need to be reset here because there is no new note being calculated
	lds r26, pulse2_note //load the current note index
	rjmp sound_driver_instrument_routine_channel1_arpeggio_process_load

sound_driver_instrument_routine_channel1_arpeggio_process:
	sts pulse2_total_pitch_offset, zero //the pitch offsets must be reset when a new note is to be calculated from an arpeggio macro
	sts pulse2_total_pitch_offset+1, zero
	sts pulse2_total_hi_pitch_offset, zero
	lds r26, pulse2_arpeggio_macro_mode
	cpi r26, 0x01 //absolute mode
	brlo sound_driver_instrument_routine_channel1_arpeggio_process_absolute
	breq sound_driver_instrument_routine_channel1_arpeggio_process_fixed
	rjmp sound_driver_instrument_routine_channel1_arpeggio_process_relative //relative mode

sound_driver_instrument_routine_channel1_arpeggio_process_absolute:
	lds r26, pulse2_note //load the current note index
	add r26, r27 //offset the note with the arpeggio data
	sbrc r27, 7 //check sign bit to check if we are subtracting from the note index
	rjmp sound_driver_instrument_routine_channel1_arpeggio_process_absolute_subtract

sound_driver_instrument_routine_channel1_arpeggio_process_absolute_add:
	cpi r26, 0x57 //check if the result is larger than the size of the note table (0x56 is the highest possible index)
	brlo sound_driver_instrument_routine_channel1_arpeggio_process_load //if the result is valid, go load the new note
	ldi r26, 0x56 //if the result was too large, just set the result to the highest possible note index
	rjmp sound_driver_instrument_routine_channel1_arpeggio_process_load

sound_driver_instrument_routine_channel1_arpeggio_process_absolute_subtract:
	sbrc r26, 7 //check if result is negative
	ldi r26, 0x00 //if the result was negative, reset it to the 0th index
	rjmp sound_driver_instrument_routine_channel1_arpeggio_process_load



sound_driver_instrument_routine_channel1_arpeggio_process_fixed:
	mov r26, r27 //move the arpeggio data into r26
	rjmp sound_driver_instrument_routine_channel1_arpeggio_process_load



sound_driver_instrument_routine_channel1_arpeggio_process_relative:
	lds r26, pulse2_note //load the current note index
	add r26, r27 //offset the note with the arpeggio data
	sbrc r27, 7 //check sign bit to check if we are subtracting from the note index
	rjmp sound_driver_instrument_routine_channel1_arpeggio_process_relative_subtract

sound_driver_instrument_routine_channel1_arpeggio_process_relative_add:
	sts pulse2_note, r26 //NOTE: relative mode modifies the original note index
	cpi r26, 0x57 //check if the result is larger than the size of the note table (0x56 is the highest possible index)
	brlo sound_driver_instrument_routine_channel1_arpeggio_process_load //if the result is valid, go load the new note
	ldi r26, 0x56 //if the result was too large, just set the result to the highest possible note index
	sts pulse2_note, r26
	rjmp sound_driver_instrument_routine_channel1_arpeggio_process_load

sound_driver_instrument_routine_channel1_arpeggio_process_relative_subtract:
	sbrc r26, 7 //check if result is negative
	ldi r26, 0x00 //if the result was negative, reset it to the 0th index
	sts pulse2_note, r26



sound_driver_instrument_routine_channel1_arpeggio_process_load:
	ldi ZL, LOW(note_table << 1) //load in note table
	ldi ZH, HIGH(note_table << 1)
	lsl r26 //double the offset for the note table because we are getting byte data
	add ZL, r26 //add offset
	adc ZH, zero
	lpm r26, Z+ //load bytes
	lpm r27, Z
	sts TCB1_CCMPL, r26 //load the LOW bits for timer
	sts TCB1_CCMPH, r27 //load the HIGH bits for timer
	sts pulse2_fx_3xx_target, r26 //NOTE: 3xx target note is stored here because the true note is always read in this arpeggio macro routine
	sts pulse2_fx_3xx_target+1, r27
	rjmp sound_driver_instrument_routine_channel1_pitch



sound_driver_instrument_routine_channel1_pitch:
	lds ZL, pulse2_pitch_macro
	lds ZH, pulse2_pitch_macro+1
	adiw Z, 0
	brne sound_driver_instrument_routine_channel1_pitch_continue
	rjmp sound_driver_instrument_routine_channel1_pitch_default //if no pitch macro is in use, process the current total pitch macro offset
sound_driver_instrument_routine_channel1_pitch_continue:
	lsl ZL //multiply by 2 to make z into a byte pointer for the macro's address
	rol ZH
	lds r26, pulse2_pitch_macro_offset
	add ZL, r26
	adc ZH, zero

	lds r27, pulse2_pitch_macro_release
	cp r27, r26
	brne sound_driver_instrument_routine_channel1_pitch_increment //if the current offset is not equal to the release index, increment the offset
	lds r26, pulse2_pitch_macro_loop
	cp r26, r27 //check if loop flag exists NOTE: a loop flag and a release flag can only co-exist if the loop is less than the release
	brlo sound_driver_instrument_routine_channel1_pitch_increment+1 //if the current offset is equal to the release index and there is a loop, load the offset with the loop index, but also read the current index data
	rjmp sound_driver_instrument_routine_channel1_pitch_read //if the current offset is equal to the release index and there is no loop, then keep the offset unchanged

sound_driver_instrument_routine_channel1_pitch_increment:
	inc r26 //increment the macro offset
	sts pulse2_pitch_macro_offset, r26
	
sound_driver_instrument_routine_channel1_pitch_read:
	lpm r27, Z //load pitch data into r27
	cpi r27, 0x80 //check for macro end flag
	brne sound_driver_instrument_routine_channel1_pitch_calculate //if the data was not the macro end flag, calculate the pitch offset



sound_driver_instrument_routine_channel1_pitch_macro_end_flag:
sound_driver_instrument_routine_channel1_pitch_macro_end_flag_check_release:
	subi r26, 1 //keep the macro offset at the end flag
	sts pulse2_pitch_macro_offset, r26
	lds r27, pulse2_pitch_macro_release
	cpi r27, 0xFF
	brne sound_driver_instrument_routine_channel1_pitch_default //if there is a release flag, we don't need to loop. offset the pitch by the final total pitch

sound_driver_instrument_routine_channel1_pitch_macro_end_flag_check_loop:
	lds r27, pulse2_pitch_macro_loop //load the loop index
	cpi r27, 0xFF //check if there is a loop index
	breq sound_driver_instrument_routine_channel1_pitch_default //if there is no loop flag, we don't need to loop. offset the pitch by the final total pitch
	sts pulse2_pitch_macro_offset, r27 //store the loop index into the offset
	rjmp sound_driver_instrument_routine_channel1_pitch //go back and re-read the pitch data



sound_driver_instrument_routine_channel1_pitch_default:
	ldi r27, 0x00
sound_driver_instrument_routine_channel1_pitch_calculate:
	push r22 //only registers r16 - r23 can be used with mulsu
	push r23
	mov r22, r27 //store the signed pitch offset data into r22
	ldi r23, 0b10110010 //store r23 with 11.125 note: this is the closest approximation to the 11.1746014718 multiplier we can get with 8 bits
	mulsu r22, r23
	pop r23
	pop r22

	lsr r1 //shift out the fractional bits
	ror r0
	lsr r1
	ror r0
	lsr r1
	ror r0
	lsr r1
	ror r0

sound_driver_instrument_routine_channel1_pitch_calculate_check_negative:
	sbrs r1, 3 //check if result was a negative number
	rjmp sound_driver_instrument_routine_channel1_pitch_calculate_offset //if the result was positive, don't fill with 1s

sound_driver_instrument_routine_channel1_pitch_calculate_negative:
	ldi r28, 0xF0
	or r1, r28 //when right shifting a two's complement number, must use 1s instead of 0s to fill

sound_driver_instrument_routine_channel1_pitch_calculate_check_divisible_8:
	andi r27, 0b00000111
	breq sound_driver_instrument_routine_channel1_pitch_calculate_offset

	ldi r27, 0x01
	add r0, r27
	adc r1, zero

sound_driver_instrument_routine_channel1_pitch_calculate_offset:
	lds r26, pulse2_total_pitch_offset
	lds r27, pulse2_total_pitch_offset+1
	add r0, r26
	adc r1, r27
	sts pulse2_total_pitch_offset, r0
	sts pulse2_total_pitch_offset+1, r1
	lds r26, TCB1_CCMPL //load the low bits for timer
	lds r27, TCB1_CCMPH //load the high bits for timer
	add r26, r0 //offset the timer values
	adc r27, r1
	
	lds r28, pulse2_fx_1xx_total
	lds r29, pulse2_fx_1xx_total+1
	sub r26, r28
	sbc r27, r29
	lds r28, pulse2_fx_2xx_total
	lds r29, pulse2_fx_2xx_total+1
	add r26, r28
	adc r27, r29
	lds r28, pulse2_fx_Pxx_total
	lds r29, pulse2_fx_Pxx_total+1
	add r26, r28
	adc r27, r29
	lds r28, pulse2_fx_Qxy_total_offset //NOTE: Qxy and Rxy offsets are applied here
	lds r29, pulse2_fx_Qxy_total_offset+1
	sub r26, r28
	sbc r27, r29
	lds r28, pulse2_fx_Rxy_total_offset
	lds r29, pulse2_fx_Rxy_total_offset+1
	add r26, r28
	adc r27, r29

	ldi r28, 0x59
	ldi r29, 0x00
	cp r26, r28
	cpc r27, r29
	brlo sound_driver_instrument_routine_channel1_pitch_min

	ldi r28, 0x5A
	ldi r29, 0x59
	cp r26, r28
	cpc r27, r29
	brsh sound_driver_instrument_routine_channel1_pitch_max
	rjmp sound_driver_instrument_routine_channel1_pitch_store

sound_driver_instrument_routine_channel1_pitch_min:
	ldi r28, 0x59
	ldi r29, 0x00
	rjmp sound_driver_instrument_routine_channel1_pitch_store

sound_driver_instrument_routine_channel1_pitch_max:
	ldi r28, 0x59
	ldi r29, 0x59
	rjmp sound_driver_instrument_routine_channel1_pitch_store

sound_driver_instrument_routine_channel1_pitch_store:
	sts TCB1_CCMPL, r26 //store the new low bits for timer
	sts TCB1_CCMPH, r27 //store the new high bits for timer
	


//NOTE: The hi pitch macro routine does not account for overflowing from the offset. In famitracker, if the offset
//goes beyond the note range, there will be no more offset calculations. In this routine, it is possible that
//the pitch goes from B-7 and back around to C-0. I don't believe there will ever be a song in which this will be a problem.
sound_driver_instrument_routine_channel1_hi_pitch:
	lds ZL, pulse2_hi_pitch_macro
	lds ZH, pulse2_hi_pitch_macro+1
	adiw Z, 0
	brne sound_driver_instrument_routine_channel1_hi_pitch_continue
	rjmp sound_driver_instrument_routine_channel1_duty //if no hi pitch macro is in use, go to the next macro routine
sound_driver_instrument_routine_channel1_hi_pitch_continue:
	lsl ZL //multiply by 2 to make z into a byte pointer for the macro's address
	rol ZH
	lds r26, pulse2_hi_pitch_macro_offset
	add ZL, r26
	adc ZH, zero

	lds r27, pulse2_hi_pitch_macro_release
	cp r27, r26
	brne sound_driver_instrument_routine_channel1_hi_pitch_increment //if the current offset is not equal to the release index, increment the offset
	lds r26, pulse2_hi_pitch_macro_loop
	cp r26, r27 //check if loop flag exists NOTE: a loop flag and a release flag can only co-exist if the loop is less than the release
	brlo sound_driver_instrument_routine_channel1_hi_pitch_increment+1 //if the current offset is equal to the release index and there is a loop, load the offset with the loop index, but also read the current index data
	rjmp sound_driver_instrument_routine_channel1_hi_pitch_read //if the current offset is equal to the release index and there is no loop, then keep the offset unchanged

sound_driver_instrument_routine_channel1_hi_pitch_increment:
	inc r26 //increment the macro offset
	sts pulse2_hi_pitch_macro_offset, r26
	
sound_driver_instrument_routine_channel1_hi_pitch_read:
	lpm r27, Z //load hi pitch data into r27
	cpi r27, 0x80 //check for macro end flag
	brne sound_driver_instrument_routine_channel1_hi_pitch_calculate //if the data was not the macro end flag, calculate the hi pitch offset



sound_driver_instrument_routine_channel1_hi_pitch_macro_end_flag:
sound_driver_instrument_routine_channel1_hi_pitch_macro_end_flag_check_release:
	subi r26, 1 //keep the macro offset at the end flag
	sts pulse2_hi_pitch_macro_offset, r26
	lds r27, pulse2_hi_pitch_macro_release
	cpi r27, 0xFF
	brne sound_driver_instrument_routine_channel1_hi_pitch_default //if there is a release flag, we don't need to loop. offset the hi pitch by the final total hi pitch

sound_driver_instrument_routine_channel1_hi_pitch_macro_end_flag_check_loop:
	lds r27, pulse2_hi_pitch_macro_loop //load the loop index
	cpi r27, 0xFF //check if there is a loop index
	breq sound_driver_instrument_routine_channel1_hi_pitch_default //if there is no loop flag, we don't need to loop. offset the pitch by the final total hi pitch
	sts pulse2_hi_pitch_macro_offset, r27 //store the loop index into the offset
	rjmp sound_driver_instrument_routine_channel1_hi_pitch //go back and re-read the hi pitch data



sound_driver_instrument_routine_channel1_hi_pitch_default:
	lds r27, pulse2_total_hi_pitch_offset
	rjmp sound_driver_instrument_routine_channel1_hi_pitch_calculate_multiply

sound_driver_instrument_routine_channel1_hi_pitch_calculate:
	lds r26, pulse2_total_hi_pitch_offset //load the total hi pitch offset to change
	add r27, r26
	sts pulse2_total_hi_pitch_offset, r27

sound_driver_instrument_routine_channel1_hi_pitch_calculate_multiply:
	push r22 //only registers r16 - r23 can be used with mulsu
	push r23
	mov r22, r27 //store the signed hi pitch offset data into r22
	ldi r23, 0b10110010 //store r23 with 11.125 note: this is the closest approximation to the 11.1746014718 multiplier we can get with 8 bits
	mulsu r22, r23
	pop r23
	pop r22

	//NOTE: fractional bits do not need to be shifted out because hi pitch offsets are multiplied by 16. shifting right 4 times for the fraction and left 4 times for the 16x is the same as no shift.
sound_driver_instrument_routine_channel1_hi_pitch_calculate_offset:
	lds r26, TCB1_CCMPL //load the low bits for timer
	lds r27, TCB1_CCMPH //load the high bits for timer
	add r26, r0 //offset the timer values
	adc r27, r1
	sts TCB1_CCMPL, r26 //store the new low bits for timer
	sts TCB1_CCMPH, r27 //store the new high bits for timer



//NOTE: Unlike the original NES, changing the duty cycle will reset the sequencer position entirely.
sound_driver_instrument_routine_channel1_duty:
	lds ZL, pulse2_duty_macro
	lds ZH, pulse2_duty_macro+1
	adiw Z, 0
	breq sound_driver_channel1_fx_routines //if no duty macro is in use, go to the next routine
	lsl ZL //multiply by 2 to make z into a byte pointer for the macro's address
	rol ZH
	lds r26, pulse2_duty_macro_offset
	add ZL, r26
	adc ZH, zero

	lds r27, pulse2_duty_macro_release
	cp r27, r26
	brne sound_driver_instrument_routine_channel1_duty_increment //if the current offset is not equal to the release index, increment the offset
	lds r26, pulse2_duty_macro_loop
	cp r26, r27 //check if loop flag exists NOTE: a loop flag and a release flag can only co-exist if the loop is less than the release
	brlo sound_driver_instrument_routine_channel1_duty_increment+1 //if the current offset is equal to the release index and there is a loop, load the offset with the loop index, but also read the current index data
	rjmp sound_driver_channel1_fx_routines //if the current offset is equal to the release index and there is no loop, then keep the offset unchanged and skip the rest of the routine

sound_driver_instrument_routine_channel1_duty_increment:
	inc r26 //increment the macro offset
	sts pulse2_duty_macro_offset, r26
	
sound_driver_instrument_routine_channel1_duty_read:
	lpm r27, Z //load pitch data into r27
	cpi r27, 0xFF //check for macro end flag
	brne sound_driver_instrument_routine_channel1_duty_load //if the data was not the macro end flag, load the new duty cycle



sound_driver_instrument_routine_channel1_duty_macro_end_flag:
sound_driver_instrument_routine_channel1_duty_macro_end_flag_check_release:
	subi r26, 1 //keep the macro offset at the end flag
	sts pulse2_duty_macro_offset, r26
	lds r27, pulse2_duty_macro_release
	cpi r27, 0xFF
	brne sound_driver_channel1_fx_routines //if there is a release flag, we don't need to loop. skip the rest of the routine.

sound_driver_instrument_routine_channel1_duty_macro_end_flag_check_loop:
	lds r27, pulse2_duty_macro_loop //load the loop index
	cpi r27, 0xFF //check if there is a loop index
	breq sound_driver_channel1_fx_routines //if there is no loop flag, we don't need to loop. skip the rest of the routine.
	sts pulse2_duty_macro_offset, r27 //store the loop index into the offset
	rjmp sound_driver_instrument_routine_channel1_duty //go back and re-read the duty data



sound_driver_instrument_routine_channel1_duty_load:
	ldi ZL, LOW(sequences << 1) //point Z to sequence table
	ldi ZH, HIGH(sequences << 1)
	add ZL, r27 //offset the pointer by the duty macro data
	adc ZH, zero

	lsr r27 //move the duty cycle bits to the 2 MSB for pulse2_param (register $4000)
	ror r27
	ror r27
	lds r26, pulse2_param //load r26 with pulse2_param (register $4000)
	mov r28, r26 //store a copy of pulse2_param into r28
	andi r26, 0b11000000 //mask the duty cycle bits
	cpse r27, r26 //check if the previous duty cycle and the new duty cycle are equal
	rjmp sound_driver_instrument_routine_channel1_duty_load_store
	rjmp sound_driver_channel1_fx_routines //if the previous and new duty cycle are the same, don't reload the sequence

sound_driver_instrument_routine_channel1_duty_load_store:
	lpm pulse2_sequence, Z //store the sequence

	andi r28, 0b00111111 //mask out the duty cycle bits
	or r28, r27 //store the new duty cycle bits into r27
	sts pulse2_param, r28



sound_driver_channel1_fx_routines:
sound_driver_channel1_fx_1xx_routine:
	lds ZL, pulse2_fx_1xx
	lds ZH, pulse2_fx_1xx+1
	adiw Z, 0
	breq sound_driver_channel1_fx_2xx_routine

	lds r26, pulse2_fx_1xx_total //load the rate to change the pitch by
	lds r27, pulse2_fx_1xx_total+1
	add r26, ZL //increase the total offset by the rate
	adc r27, ZH
	sts pulse2_fx_1xx_total, r26
	sts pulse2_fx_1xx_total+1, r27



sound_driver_channel1_fx_2xx_routine:
	lds ZL, pulse2_fx_2xx
	lds ZH, pulse2_fx_2xx+1
	adiw Z, 0
	breq sound_driver_channel1_fx_3xx_routine

	lds r26, pulse2_fx_2xx_total //load the rate to change the pitch by
	lds r27, pulse2_fx_2xx_total+1
	add r26, ZL //increase the total offset by the rate
	adc r27, ZH
	sts pulse2_fx_2xx_total, r26
	sts pulse2_fx_2xx_total+1, r27



sound_driver_channel1_fx_3xx_routine:
	lds ZL, pulse2_fx_3xx_speed
	lds ZH, pulse2_fx_3xx_speed+1
	adiw Z, 0
	brne sound_driver_channel1_fx_3xx_routine_check_start
	rjmp sound_driver_channel1_fx_4xy_routine

sound_driver_channel1_fx_3xx_routine_check_start:
	lds r26, pulse2_fx_3xx_start
	lds r27, pulse2_fx_3xx_start+1
	adiw r26:r27, 0
	brne sound_driver_channel1_fx_3xx_routine_main
	rjmp sound_driver_channel1_fx_4xy_routine

sound_driver_channel1_fx_3xx_routine_main:
	lds r28, pulse2_fx_3xx_target
	lds r29, pulse2_fx_3xx_target+1

	cp r26, r28 //check if the target is lower, higher or equal to the starting period
	cpc r27, r29
	breq sound_driver_channel1_fx_3xx_routine_disable
	brlo sound_driver_channel1_fx_3xx_routine_subtract //if target is larger, we need to add to the start (subtract from the current timer)
	rjmp sound_driver_channel1_fx_3xx_routine_add //if target is smaller, we need to subtract from the start (add to the current timer)

sound_driver_channel1_fx_3xx_routine_disable:
	sts pulse2_fx_3xx_start, zero //setting the starting period to 0 effectively disables this routine until a note has been changed
	sts pulse2_fx_3xx_start+1, zero //NOTE: to truly disable the effect, 300 must be written.
	rjmp sound_driver_channel1_fx_4xy_routine

sound_driver_channel1_fx_3xx_routine_subtract:
	sub r28, r26 //store the total difference between the start and the target into r28:r29
	sbc r29, r27
	lds r26, pulse2_fx_3xx_total_offset
	lds r27, pulse2_fx_3xx_total_offset+1

	add r26, ZL //add the speed to the total offset
	adc r27, ZH
	sub r28, r26 //invert the total difference with the total offset
	sbc r29, r27
	brlo sound_driver_channel1_fx_3xx_routine_disable //if the total offset has surpassed the target difference (target note has been reached)

	sts pulse2_fx_3xx_total_offset, r26 //store the new total offset
	sts pulse2_fx_3xx_total_offset+1, r27

	lds r26, TCB1_CCMPL //load the current timer period
	lds r27, TCB1_CCMPH
	sub r26, r28 //offset the current timer period with the total offset
	sbc r27, r29
	sts TCB1_CCMPL, r26
	sts TCB1_CCMPH, r27
	rjmp sound_driver_channel1_fx_4xy_routine

sound_driver_channel1_fx_3xx_routine_add:
	sub r26, r28 //store the total difference between the start and the target into r28:r29
	sbc r27, r29
	lds r28, pulse2_fx_3xx_total_offset
	lds r29, pulse2_fx_3xx_total_offset+1

	add r28, ZL //add the speed to the total offset
	adc r29, ZH
	sub r26, r28 //invert the total difference with the total offset
	sbc r27, r29
	brlo sound_driver_channel1_fx_3xx_routine_disable //if the total offset has surpassed the target difference (target note has been reached)

	sts pulse2_fx_3xx_total_offset, r28 //store the new total offset
	sts pulse2_fx_3xx_total_offset+1, r29

	lds r28, TCB1_CCMPL //load the current timer period
	lds r29, TCB1_CCMPH
	add r28, r26 //offset the current timer period with the total offset
	adc r29, r27
	sts TCB1_CCMPL, r28
	sts TCB1_CCMPH, r29



sound_driver_channel1_fx_4xy_routine:
	lds r26, pulse2_fx_4xy_speed
	cp r26, zero
	brne sound_driver_channel1_fx_4xy_routine_continue
	rjmp sound_driver_channel1_fx_7xy_routine //if speed is 0, then the effect is disabled

sound_driver_channel1_fx_4xy_routine_continue:
	lds r27, pulse2_fx_4xy_depth
	lds r28, pulse2_fx_4xy_phase
	add r28, r26 //increase the phase by the speed
	cpi r28, 64 //check if the phase overflowed NOTE: phase values range from 0-63
	brlo sound_driver_channel1_fx_4xy_routine_phase //if no overflow, map the phase to 0-15.
	ldi r28, 0x00 //reset the phase if there was overflow

sound_driver_channel1_fx_4xy_routine_phase:
	sts pulse2_fx_4xy_phase, r28 //store the new phase
	cpi r28, 16
	brlo sound_driver_channel1_fx_4xy_routine_phase_0
	cpi r28, 32
	brlo sound_driver_channel1_fx_4xy_routine_phase_1
	cpi r28, 48
	brlo sound_driver_channel1_fx_4xy_routine_phase_2
	rjmp sound_driver_channel1_fx_4xy_routine_phase_3

sound_driver_channel1_fx_4xy_routine_phase_0:
	andi r28, 0x0F //mask for values 0-15
	rjmp sound_driver_channel1_fx_4xy_routine_load_subtract

sound_driver_channel1_fx_4xy_routine_phase_1:
	ori r28, 0xF0
	com r28 //invert values 0-15
	rjmp sound_driver_channel1_fx_4xy_routine_load_subtract

sound_driver_channel1_fx_4xy_routine_phase_2:
	andi r28, 0x0F //mask for values 0-15
	rjmp sound_driver_channel1_fx_4xy_routine_load_add

sound_driver_channel1_fx_4xy_routine_phase_3:
	ori r28, 0xF0
	com r28 //invert values 0-15
	rjmp sound_driver_channel1_fx_4xy_routine_load_add

sound_driver_channel1_fx_4xy_routine_load_add:
	swap r27 //multiply depth by 16
	add r28, r27 //add the depth to the phase NOTE: the table is divided into sixteen different set of 8 values, which correspond to the depth
	
	ldi ZL, LOW(vibrato_table << 1) //point z to vibrato table
	ldi ZH, HIGH(vibrato_table << 1)
	add ZL, r28 //offset the table by the depth+phase
	adc ZH, zero
	lpm r28, Z //load the tremelo value into r28

	push r22 //only registers r16 - r23 can be used with mulsu
	push r23
	mov r22, r28 //store the vibrato value into r22
	ldi r23, 0b10110010 //store r23 with 11.125 note: this is the closest approximation to the 11.1746014718 multiplier we can get with 8 bits
	mul r22, r23
	pop r23
	pop r22

	lsr r1 //shift out the fractional bits
	ror r0
	lsr r1
	ror r0
	lsr r1
	ror r0
	lsr r1
	ror r0
	
	lds r26, TCB1_CCMPL
	lds r27, TCB1_CCMPH
	add r26, r0
	adc r27, r1
	sts TCB1_CCMPL, r26
	sts TCB1_CCMPH, r27
	rjmp sound_driver_channel1_fx_7xy_routine

sound_driver_channel1_fx_4xy_routine_load_subtract:
	swap r27 //multiply depth by 16
	add r28, r27 //add the depth to the phase NOTE: the table is divided into sixteen different set of 8 values, which correspond to the depth
	ldi ZL, LOW(vibrato_table << 1) //point z to vibrato table
	ldi ZH, HIGH(vibrato_table << 1)
	add ZL, r28 //offset the table by the depth+phase
	adc ZH, zero
	lpm r28, Z //load the vibrato value into r28

	push r22 //only registers r16 - r23 can be used with mulsu
	push r23
	mov r22, r28 //store the vibrato value into r22
	ldi r23, 0b10110010 //store r23 with 11.125 note: this is the closest approximation to the 11.1746014718 multiplier we can get with 8 bits
	mul r22, r23
	pop r23
	pop r22

	lsr r1 //shift out the fractional bits
	ror r0
	lsr r1
	ror r0
	lsr r1
	ror r0
	lsr r1
	ror r0

	lds r26, TCB1_CCMPL
	lds r27, TCB1_CCMPH
	sub r26, r0
	sbc r27, r1
	sts TCB1_CCMPL, r26
	sts TCB1_CCMPH, r27



sound_driver_channel1_fx_7xy_routine:
	lds r26, pulse2_fx_7xy_speed
	cp r26, zero
	breq sound_driver_channel1_fx_Axy_routine //if speed is 0, then the effect is disabled

	lds r27, pulse2_fx_7xy_depth
	lds r28, pulse2_fx_7xy_phase
	add r28, r26 //increase the phase by the speed
	cpi r28, 64 //check if the phase overflowed NOTE: phase values range from 0-63
	brlo sound_driver_channel1_fx_7xy_routine_phase //if no overflow, map the phase to 0-15.
	ldi r28, 0x00 //reset the phase if there was overflow

sound_driver_channel1_fx_7xy_routine_phase:
	sts pulse2_fx_7xy_phase, r28 //store the new phase
	lsr r28 //divide the phase by 2 NOTE: 7xy only uses half a sine unlike 4xy
	sbrs r28, 4
	rjmp sound_driver_channel1_fx_7xy_routine_phase_0
	rjmp sound_driver_channel1_fx_7xy_routine_phase_1
	
sound_driver_channel1_fx_7xy_routine_phase_0:
	andi r28, 0x0F //mask for values 0-15
	rjmp sound_driver_channel1_fx_7xy_routine_load

sound_driver_channel1_fx_7xy_routine_phase_1:
	ori r28, 0xF0
	com r28 //invert values 0-15
	rjmp sound_driver_channel1_fx_7xy_routine_load

sound_driver_channel1_fx_7xy_routine_load:
	swap r27 //multiply depth by 16
	add r28, r27 //add the depth to the phase NOTE: the table is divided into sixteen different set of 8 values, which correspond to the depth
	
	ldi ZL, LOW(vibrato_table << 1) //point z to vibrato table
	ldi ZH, HIGH(vibrato_table << 1)
	add ZL, r28 //offset the table by the depth+phase
	adc ZH, zero
	lpm r28, Z //load the vibrato value into r28

	lsr r28 //convert to tremelo value by shifting to the right
	sts pulse2_fx_7xy_value, r28



sound_driver_channel1_fx_Axy_routine:
	lds r27, pulse2_fx_Axy
	cp r27, zero
	breq sound_driver_channel1_fx_Qxy_routine //0 means that the effect is not in use
	
	lds r26, pulse2_fractional_volume //load fractional volume representation of the channel
	lds r28, pulse2_param //load the integer volume representation of the channel
	mov r29, r26 //copy fractional volume into r29
	mov r30, r28 //copy the pulse2_param into r30
	swap r30
	andi r29, 0xF0 //mask for integer volume bits from the fractional volume
	andi r30, 0xF0 //mask for VVVV volume bits

	cp r30, r29 //compare the fractional and integer volumes
	breq sound_driver_channel1_fx_Axy_routine_calculate

sound_driver_channel1_fx_Axy_routine_reload:
	mov r26, r30 //overwrite the fractional volume with the integer volume

sound_driver_channel1_fx_Axy_routine_calculate:
	sbrc r27, 7 //check for negative sign bit in Axy offset value
	rjmp sound_driver_channel1_fx_Axy_routine_calculate_subtraction

sound_driver_channel1_fx_Axy_routine_calculate_addition:
	add r26, r27 //add the fractional volume with the offset specified by the Axy effect
	brcc sound_driver_channel1_fx_Axy_routine_calculate_store //if the fractional volume did not overflow, go store the new volume
	ldi r26, 0xF0 //if the fractional volume did overflow, reset it back to the highest integer volume possible (0xF)
	rjmp sound_driver_channel1_fx_Axy_routine_calculate_store

sound_driver_channel1_fx_Axy_routine_calculate_subtraction:
	add r26, r27 //add the fractional volume with the offset specified by the Axy effect
	brcs sound_driver_channel1_fx_Axy_routine_calculate_store //if the fractional volume did not overflow, go store the new volume
	ldi r26, 0x00 //if the fractional volume did overflow, reset it back to the lowest integer volume possible (0x0)

sound_driver_channel1_fx_Axy_routine_calculate_store:
	sts pulse2_fractional_volume, r26 //store the new fractional volume
	andi r26, 0xF0 //mask for integer volume bits from the fractional volume
	swap r26
	andi r28, 0xF0 //mask out the old VVVV volume bits
	or r28, r26 //store the new volume back into pulse2_param
	sts pulse2_param, r28



//NOTE: The Qxy and Rxy routines ONLY calculate the total offset. The offset is applied in the pitch macro routine
sound_driver_channel1_fx_Qxy_routine:
	lds ZL, pulse2_fx_Qxy_target
	lds ZH, pulse2_fx_Qxy_target+1
	adiw Z, 0
	breq sound_driver_channel1_fx_Rxy_routine //if the effect is not enabled, skip the routine

	lds r26, pulse2_fx_Qxy_total_offset
	lds r27, pulse2_fx_Qxy_total_offset+1
	lds r28, TCB1_CCMPL
	lds r29, TCB1_CCMPH

	sub ZL, r28 //calculate the difference to the target
	sbc ZH, r29
	brsh sound_driver_channel1_fx_Qxy_routine_end //if the target has been reached (or passed)
	brlo sound_driver_channel1_fx_Qxy_routine_add

sound_driver_channel1_fx_Qxy_routine_end:
	sts pulse2_fx_Qxy_total_offset, zero //turn off the effect
	sts pulse2_fx_Qxy_total_offset+1, zero
	sts pulse2_fx_Qxy_target, zero
	sts pulse2_fx_Qxy_target+1, zero
	lds r27, pulse2_fx_Qxy_target_note
	sts pulse2_note, r27 //replace the note with the final target note
	rjmp sound_driver_channel1_fx_Rxy_routine

sound_driver_channel1_fx_Qxy_routine_add:
	lds r28, pulse2_fx_Qxy_speed
	lds r29, pulse2_fx_Qxy_speed+1
	add r26, r28 //increase the total offset by the speed
	adc r27, r29
	sts pulse2_fx_Qxy_total_offset, r26 //store the total offset
	sts pulse2_fx_Qxy_total_offset+1, r27



sound_driver_channel1_fx_Rxy_routine:
	lds ZL, pulse2_fx_Rxy_target
	lds ZH, pulse2_fx_Rxy_target+1
	adiw Z, 0
	breq sound_driver_instrument_routine_channel2_volume //if the effect is not enabled, skip the routine

	lds r26, pulse2_fx_Rxy_total_offset
	lds r27, pulse2_fx_Rxy_total_offset+1
	lds r28, TCB1_CCMPL
	lds r29, TCB1_CCMPH

	sub r28, ZL //calculate the difference to the target
	sbc r29, ZH
	brsh sound_driver_channel1_fx_Rxy_routine_end //if the target has been reached (or passed)
	brlo sound_driver_channel1_fx_Rxy_routine_add

sound_driver_channel1_fx_Rxy_routine_end:
	sts pulse2_fx_Rxy_total_offset, zero //disable the effect
	sts pulse2_fx_Rxy_total_offset+1, zero
	sts pulse2_fx_Rxy_target, zero
	sts pulse2_fx_Rxy_target+1, zero
	lds r27, pulse2_fx_Rxy_target_note
	sts pulse2_note, r27 //replace the note with the final target note
	rjmp sound_driver_instrument_routine_channel2_volume

sound_driver_channel1_fx_Rxy_routine_add:
	lds r28, pulse2_fx_Rxy_speed
	lds r29, pulse2_fx_Rxy_speed+1
	add r26, r28 //increase the total offset by the speed
	adc r27, r29
	sts pulse2_fx_Rxy_total_offset, r26 //store the total offset
	sts pulse2_fx_Rxy_total_offset+1, r27



sound_driver_instrument_routine_channel2_volume:
	lds ZL, triangle_volume_macro
	lds ZH, triangle_volume_macro+1
	adiw Z, 0
	breq sound_driver_instrument_routine_channel2_volume_default //if no volume macro is in use, do nothing
	lsl ZL //multiply by 2 to make Z into a byte pointer for the macro's address
	rol ZH
	lds r26, triangle_volume_macro_offset
	add ZL, r26
	adc ZH, zero

	lds r27, triangle_volume_macro_release
	cp r27, r26
	brne sound_driver_instrument_routine_channel2_volume_increment //if the current offset is not equal to the release index, increment the offset
	lds r26, triangle_volume_macro_loop
	cp r26, r27 //check if loop flag exists NOTE: a loop flag and a release flag can only co-exist if the loop is less than the release
	brlo sound_driver_instrument_routine_channel2_volume_increment+1 //if the current offset is equal to the release index and there is a loop, load the offset with the loop index, but also read the current index data
	rjmp sound_driver_instrument_routine_channel2_volume_read //if the current offset is equal to the release index and there is no loop, then keep the offset unchanged

sound_driver_instrument_routine_channel2_volume_increment:
	inc r26 //increment the macro offset
	sts triangle_volume_macro_offset, r26
	
sound_driver_instrument_routine_channel2_volume_read:
	lpm r27, Z //load volume data into r27
	cpi r27, 0xFF //check for macro end flag
	brne sound_driver_instrument_routine_channel2_volume_process //if the data was not the macro end flag



sound_driver_instrument_routine_channel2_volume_macro_end_flag:
sound_driver_instrument_routine_channel2_volume_macro_end_flag_check_release:
	lds r27, triangle_volume_macro_release
	cpi r27, 0xFF
	brne sound_driver_instrument_routine_channel2_volume_macro_end_flag_last_index //if there is a release flag, we don't need to loop. stay at the last valid index

sound_driver_instrument_routine_channel2_volume_macro_end_flag_check_loop:
	lds r27, triangle_volume_macro_loop //load the loop index
	sts triangle_volume_macro_offset, r27 //store the loop index into the offset
	rjmp sound_driver_instrument_routine_channel2_volume //go back and re-read the volume data

sound_driver_instrument_routine_channel2_volume_macro_end_flag_last_index:
	subi r26, 2 //go back to last valid index NOTE: Since we increment the offset everytime we read data, we have to decrement twice. 1 to account for the increment and 1 for the end flag.
	sts triangle_volume_macro_offset, r26
	rjmp sound_driver_instrument_routine_channel2_volume //go back and re-read the volume data



sound_driver_instrument_routine_channel2_volume_process:
	cp r27, zero
	breq sound_driver_instrument_routine_channel2_volume_process_disable
sound_driver_instrument_routine_channel2_volume_process_enable:
	lds r27, TCB2_INTCTRL
	cpi r27, TCB_CAPT_bm
	brne sound_driver_instrument_routine_channel2_volume_default //if the channel has already been muted, don't enable it again
	ldi r27, TCB_CAPT_bm //enable interrupts
	sts TCB2_INTCTRL, r27
	rjmp sound_driver_instrument_routine_channel2_arpeggio
sound_driver_instrument_routine_channel2_volume_process_disable:
	sts TCB2_INTCTRL, zero
	sts TCB2_CCMPL, zero //reset timer
	sts TCB2_CCMPH, zero
	rjmp sound_driver_instrument_routine_channel2_arpeggio

sound_driver_instrument_routine_channel2_volume_default:



sound_driver_instrument_routine_channel2_arpeggio:
	//NOTE: The arpeggio macro routine is also in charge of actually setting the timers using the note stored in SRAM. The default routine is responsible for that in the case no arpeggio macro is used.
	lds ZL, triangle_arpeggio_macro
	lds ZH, triangle_arpeggio_macro+1
	adiw Z, 0
	breq sound_driver_instrument_routine_channel2_arpeggio_default //if no arpeggio macro is in use, go output the note without any offsets
	lsl ZL //multiply by 2 to make Z into a byte pointer for the macro's address
	rol ZH
	lds r26, triangle_arpeggio_macro_offset
	add ZL, r26
	adc ZH, zero

	lds r27, triangle_arpeggio_macro_release
	cp r27, r26
	brne sound_driver_instrument_routine_channel2_arpeggio_increment //if the current offset is not equal to the release index, increment the offset
	lds r26, triangle_arpeggio_macro_loop
	cp r26, r27 //check if loop flag exists NOTE: a loop flag and a release flag can only co-exist if the loop is less than the release
	brlo sound_driver_instrument_routine_channel2_arpeggio_increment+1 //if the current offset is equal to the release index and there is a loop, reload the loop index, but also read the current index data
	rjmp sound_driver_instrument_routine_channel2_arpeggio_read //if the current offset is equal to the release index and there is no loop, then keep the offset unchanged

sound_driver_instrument_routine_channel2_arpeggio_increment:
	inc r26 //increment the macro offset
	sts triangle_arpeggio_macro_offset, r26
	
sound_driver_instrument_routine_channel2_arpeggio_read:
	lpm r27, Z //load arpeggio data into r27
	cpi r27, 0x80 //check for macro end flag
	breq sound_driver_instrument_routine_channel2_arpeggio_macro_end_flag
	rjmp sound_driver_instrument_routine_channel2_arpeggio_process //if the data was not the macro end flag, calculate the volume


sound_driver_instrument_routine_channel2_arpeggio_macro_end_flag:
sound_driver_instrument_routine_channel2_arpeggio_macro_end_flag_check_mode:
	subi r26, 1 //keep the offset at the end flag
	sts triangle_arpeggio_macro_offset, r26
	lds r27, triangle_arpeggio_macro_mode //load the mode to check for fixed/relative mode NOTE: end behavior for fixed/relative mode is different in that once the macro ends, the true note is played
	cpi r27, 0x01
	brlo sound_driver_instrument_routine_channel2_arpeggio_macro_end_flag_absolute

sound_driver_instrument_routine_channel2_arpeggio_macro_end_flag_fixed_relative_check_release:
	lds r27, triangle_arpeggio_macro_release
	cpi r27, 0xFF
	brne sound_driver_instrument_routine_channel2_arpeggio_default //if there is a release flag, we don't need to loop. just play the true note

sound_driver_instrument_routine_channel2_arpeggio_macro_end_flag_fixed_relative_check_loop:
	lds r27, triangle_arpeggio_macro_loop
	cpi r27, 0xFF
	brne sound_driver_instrument_routine_channel2_arpeggio_macro_end_flag_reload //if there is no release flag, but there is a loop, load the offset with the loop index
	rjmp sound_driver_instrument_routine_channel2_arpeggio_default //if there is no release flag and no loop, then play the true note

sound_driver_instrument_routine_channel2_arpeggio_macro_end_flag_absolute:
	lds r27, triangle_arpeggio_macro_release
	cpi r27, 0xFF
	brne sound_driver_instrument_routine_channel2_arpeggio_macro_end_flag_absolute_no_loop //if there is a release flag, react as if there was no loop.

sound_driver_instrument_routine_channel2_arpeggio_macro_end_flag_absolute_check_loop:
	lds r27, triangle_arpeggio_macro_loop //load the loop index
	cpi r27, 0xFF //check if loop flag exists
	brne sound_driver_instrument_routine_channel2_arpeggio_macro_end_flag_reload //if a loop flag exists, then load the loop value

sound_driver_instrument_routine_channel2_arpeggio_macro_end_flag_absolute_no_loop:
	lds r28, triangle_fx_0xy_sequence //check for 0xy effect
	lds r29, triangle_fx_0xy_sequence+1
	adiw r29:r28, 0
	brne sound_driver_instrument_routine_channel2_arpeggio_default_0xy //if 0xy effect exists, and there is no release/loop, use the default routine and apply the 0xy effect

	subi r26, 1 //if a loop flag does not exist and fixed mode is not used, use the last valid index
	sts triangle_arpeggio_macro_offset, r26 //store the last valid index into the offset
	rjmp sound_driver_instrument_routine_channel2_arpeggio

sound_driver_instrument_routine_channel2_arpeggio_macro_end_flag_reload:
	sts triangle_arpeggio_macro_offset, r27 //store the loop index into the offset
	rjmp sound_driver_instrument_routine_channel2_arpeggio //go back and re-read the volume data


sound_driver_instrument_routine_channel2_arpeggio_default:
	lds r28, triangle_fx_0xy_sequence //load 0xy effect
	lds r29, triangle_fx_0xy_sequence+1
	adiw r29:r28, 0 //check for 0xy effect
	breq sound_driver_instrument_routine_channel2_arpeggio_default_no_0xy //if there is no 0xy effect, we don't need to roll the sequence
	
//NOTE: because of the way the 0xy parameter is stored and processed, using x0 will not create a faster arpeggio
sound_driver_instrument_routine_channel2_arpeggio_default_0xy:
	lsr r29
	ror r28
	ror r29
	ror r28
	ror r29
	ror r28
	ror r29
	ror r28
	ror r29
	swap r29

	sts triangle_fx_0xy_sequence, r28 //store the rolled sequence
	sts triangle_fx_0xy_sequence+1, r29
	andi r28, 0x0F //mask out the 4 LSB
	lds r26, triangle_note //load the current note index
	add r26, r28 //add the note offset
	rjmp sound_driver_instrument_routine_channel2_arpeggio_process_load
	
sound_driver_instrument_routine_channel2_arpeggio_default_no_0xy:
	//NOTE: the pitch offset does not need to be reset here because there is no new note being calculated
	lds r26, triangle_note //load the current note index
	rjmp sound_driver_instrument_routine_channel2_arpeggio_process_load

sound_driver_instrument_routine_channel2_arpeggio_process:
	sts triangle_total_pitch_offset, zero //the pitch offsets must be reset when a new note is to be calculated from an arpeggio macro
	sts triangle_total_pitch_offset+1, zero
	sts triangle_total_hi_pitch_offset, zero
	lds r26, triangle_arpeggio_macro_mode
	cpi r26, 0x01 //absolute mode
	brlo sound_driver_instrument_routine_channel2_arpeggio_process_absolute
	breq sound_driver_instrument_routine_channel2_arpeggio_process_fixed
	rjmp sound_driver_instrument_routine_channel2_arpeggio_process_relative //relative mode

sound_driver_instrument_routine_channel2_arpeggio_process_absolute:
	lds r26, triangle_note //load the current note index
	add r26, r27 //offset the note with the arpeggio data
	sbrc r27, 7 //check sign bit to check if we are subtracting from the note index
	rjmp sound_driver_instrument_routine_channel2_arpeggio_process_absolute_subtract

sound_driver_instrument_routine_channel2_arpeggio_process_absolute_add:
	cpi r26, 0x57 //check if the result is larger than the size of the note table (0x56 is the highest possible index)
	brlo sound_driver_instrument_routine_channel2_arpeggio_process_load //if the result is valid, go load the new note
	ldi r26, 0x56 //if the result was too large, just set the result to the highest possible note index
	rjmp sound_driver_instrument_routine_channel2_arpeggio_process_load

sound_driver_instrument_routine_channel2_arpeggio_process_absolute_subtract:
	sbrc r26, 7 //check if result is negative
	ldi r26, 0x00 //if the result was negative, reset it to the 0th index
	rjmp sound_driver_instrument_routine_channel2_arpeggio_process_load



sound_driver_instrument_routine_channel2_arpeggio_process_fixed:
	mov r26, r27 //move the arpeggio data into r26
	rjmp sound_driver_instrument_routine_channel2_arpeggio_process_load



sound_driver_instrument_routine_channel2_arpeggio_process_relative:
	lds r26, triangle_note //load the current note index
	add r26, r27 //offset the note with the arpeggio data
	sbrc r27, 7 //check sign bit to check if we are subtracting from the note index
	rjmp sound_driver_instrument_routine_channel2_arpeggio_process_relative_subtract

sound_driver_instrument_routine_channel2_arpeggio_process_relative_add:
	sts triangle_note, r26 //NOTE: relative mode modifies the original note index
	cpi r26, 0x57 //check if the result is larger than the size of the note table (0x56 is the highest possible index)
	brlo sound_driver_instrument_routine_channel2_arpeggio_process_load //if the result is valid, go load the new note
	ldi r26, 0x56 //if the result was too large, just set the result to the highest possible note index
	sts triangle_note, r26
	rjmp sound_driver_instrument_routine_channel2_arpeggio_process_load

sound_driver_instrument_routine_channel2_arpeggio_process_relative_subtract:
	sbrc r26, 7 //check if result is negative
	ldi r26, 0x00 //if the result was negative, reset it to the 0th index
	sts triangle_note, r26



sound_driver_instrument_routine_channel2_arpeggio_process_load:
	ldi ZL, LOW(note_table << 1) //load in note table
	ldi ZH, HIGH(note_table << 1)
	lsl r26 //double the offset for the note table because we are getting byte data
	add ZL, r26 //add offset
	adc ZH, zero
	lpm r26, Z+ //load bytes
	lpm r27, Z
	sts TCB2_CCMPL, r26 //load the LOW bits for timer
	sts TCB2_CCMPH, r27 //load the HIGH bits for timer
	sts triangle_fx_3xx_target, r26 //NOTE: 3xx target note is stored here because the true note is always read in this arpeggio macro routine
	sts triangle_fx_3xx_target+1, r27
	rjmp sound_driver_instrument_routine_channel2_pitch



sound_driver_instrument_routine_channel2_pitch:
	lds ZL, triangle_pitch_macro
	lds ZH, triangle_pitch_macro+1
	adiw Z, 0
	brne sound_driver_instrument_routine_channel2_pitch_continue
	rjmp sound_driver_instrument_routine_channel2_pitch_default //if no pitch macro is in use, process the current total pitch macro offset
sound_driver_instrument_routine_channel2_pitch_continue:
	lsl ZL //multiply by 2 to make z into a byte pointer for the macro's address
	rol ZH
	lds r26, triangle_pitch_macro_offset
	add ZL, r26
	adc ZH, zero

	lds r27, triangle_pitch_macro_release
	cp r27, r26
	brne sound_driver_instrument_routine_channel2_pitch_increment //if the current offset is not equal to the release index, increment the offset
	lds r26, triangle_pitch_macro_loop
	cp r26, r27 //check if loop flag exists NOTE: a loop flag and a release flag can only co-exist if the loop is less than the release
	brlo sound_driver_instrument_routine_channel2_pitch_increment+1 //if the current offset is equal to the release index and there is a loop, load the offset with the loop index, but also read the current index data
	rjmp sound_driver_instrument_routine_channel2_pitch_read //if the current offset is equal to the release index and there is no loop, then keep the offset unchanged

sound_driver_instrument_routine_channel2_pitch_increment:
	inc r26 //increment the macro offset
	sts triangle_pitch_macro_offset, r26
	
sound_driver_instrument_routine_channel2_pitch_read:
	lpm r27, Z //load pitch data into r27
	cpi r27, 0x80 //check for macro end flag
	brne sound_driver_instrument_routine_channel2_pitch_calculate //if the data was not the macro end flag, calculate the pitch offset



sound_driver_instrument_routine_channel2_pitch_macro_end_flag:
sound_driver_instrument_routine_channel2_pitch_macro_end_flag_check_release:
	subi r26, 1 //keep the macro offset at the end flag
	sts triangle_pitch_macro_offset, r26
	lds r27, triangle_pitch_macro_release
	cpi r27, 0xFF
	brne sound_driver_instrument_routine_channel2_pitch_default //if there is a release flag, we don't need to loop. offset the pitch by the final total pitch

sound_driver_instrument_routine_channel2_pitch_macro_end_flag_check_loop:
	lds r27, triangle_pitch_macro_loop //load the loop index
	cpi r27, 0xFF //check if there is a loop index
	breq sound_driver_instrument_routine_channel2_pitch_default //if there is no loop flag, we don't need to loop. offset the pitch by the final total pitch
	sts triangle_pitch_macro_offset, r27 //store the loop index into the offset
	rjmp sound_driver_instrument_routine_channel2_pitch //go back and re-read the pitch data



sound_driver_instrument_routine_channel2_pitch_default:
	ldi r27, 0x00
sound_driver_instrument_routine_channel2_pitch_calculate:
	push r22 //only registers r16 - r23 can be used with mulsu
	push r23
	mov r22, r27 //store the signed pitch offset data into r22
	ldi r23, 0b10110010 //store r23 with 11.125 note: this is the closest approximation to the 11.1746014718 multiplier we can get with 8 bits
	mulsu r22, r23
	pop r23
	pop r22

	lsr r1 //shift out the fractional bits
	ror r0
	lsr r1
	ror r0
	lsr r1
	ror r0
	lsr r1
	ror r0

sound_driver_instrument_routine_channel2_pitch_calculate_check_negative:
	sbrs r1, 3 //check if result was a negative number
	rjmp sound_driver_instrument_routine_channel2_pitch_calculate_offset //if the result was positive, don't fill with 1s

sound_driver_instrument_routine_channel2_pitch_calculate_negative:
	ldi r28, 0xF0
	or r1, r28 //when right shifting a two's complement number, must use 1s instead of 0s to fill

sound_driver_instrument_routine_channel2_pitch_calculate_check_divisible_8:
	andi r27, 0b00000111
	breq sound_driver_instrument_routine_channel2_pitch_calculate_offset

	ldi r27, 0x01
	add r0, r27
	adc r1, zero

sound_driver_instrument_routine_channel2_pitch_calculate_offset:
	lds r26, triangle_total_pitch_offset
	lds r27, triangle_total_pitch_offset+1
	add r0, r26
	adc r1, r27
	sts triangle_total_pitch_offset, r0
	sts triangle_total_pitch_offset+1, r1
	lds r26, TCB2_CCMPL //load the low bits for timer
	lds r27, TCB2_CCMPH //load the high bits for timer
	add r26, r0 //offset the timer values
	adc r27, r1
	
	lds r28, triangle_fx_1xx_total
	lds r29, triangle_fx_1xx_total+1
	sub r26, r28
	sbc r27, r29
	lds r28, triangle_fx_2xx_total
	lds r29, triangle_fx_2xx_total+1
	add r26, r28
	adc r27, r29
	lds r28, triangle_fx_Pxx_total
	lds r29, triangle_fx_Pxx_total+1
	add r26, r28
	adc r27, r29
	lds r28, triangle_fx_Qxy_total_offset //NOTE: Qxy and Rxy offsets are applied here
	lds r29, triangle_fx_Qxy_total_offset+1
	sub r26, r28
	sbc r27, r29
	lds r28, triangle_fx_Rxy_total_offset
	lds r29, triangle_fx_Rxy_total_offset+1
	add r26, r28
	adc r27, r29

	ldi r28, 0x59
	ldi r29, 0x00
	cp r26, r28
	cpc r27, r29
	brlo sound_driver_instrument_routine_channel2_pitch_min

	ldi r28, 0x5A
	ldi r29, 0x59
	cp r26, r28
	cpc r27, r29
	brsh sound_driver_instrument_routine_channel2_pitch_max
	rjmp sound_driver_instrument_routine_channel2_pitch_store

sound_driver_instrument_routine_channel2_pitch_min:
	ldi r28, 0x59
	ldi r29, 0x00
	rjmp sound_driver_instrument_routine_channel2_pitch_store

sound_driver_instrument_routine_channel2_pitch_max:
	ldi r28, 0x59
	ldi r29, 0x59
	rjmp sound_driver_instrument_routine_channel2_pitch_store

sound_driver_instrument_routine_channel2_pitch_store:
	sts TCB2_CCMPL, r26 //store the new low bits for timer
	sts TCB2_CCMPH, r27 //store the new high bits for timer
	


//NOTE: The hi pitch macro routine does not account for overflowing from the offset. In famitracker, if the offset
//goes beyond the note range, there will be no more offset calculations. In this routine, it is possible that
//the pitch goes from B-7 and back around to C-0. I don't believe there will ever be a song in which this will be a problem.
sound_driver_instrument_routine_channel2_hi_pitch:
	lds ZL, triangle_hi_pitch_macro
	lds ZH, triangle_hi_pitch_macro+1
	adiw Z, 0
	brne sound_driver_instrument_routine_channel2_hi_pitch_continue
	rjmp sound_driver_instrument_routine_channel2_duty //if no hi pitch macro is in use, go to the next macro routine
sound_driver_instrument_routine_channel2_hi_pitch_continue:
	lsl ZL //multiply by 2 to make z into a byte pointer for the macro's address
	rol ZH
	lds r26, triangle_hi_pitch_macro_offset
	add ZL, r26
	adc ZH, zero

	lds r27, triangle_hi_pitch_macro_release
	cp r27, r26
	brne sound_driver_instrument_routine_channel2_hi_pitch_increment //if the current offset is not equal to the release index, increment the offset
	lds r26, triangle_hi_pitch_macro_loop
	cp r26, r27 //check if loop flag exists NOTE: a loop flag and a release flag can only co-exist if the loop is less than the release
	brlo sound_driver_instrument_routine_channel2_hi_pitch_increment+1 //if the current offset is equal to the release index and there is a loop, load the offset with the loop index, but also read the current index data
	rjmp sound_driver_instrument_routine_channel2_hi_pitch_read //if the current offset is equal to the release index and there is no loop, then keep the offset unchanged

sound_driver_instrument_routine_channel2_hi_pitch_increment:
	inc r26 //increment the macro offset
	sts triangle_hi_pitch_macro_offset, r26
	
sound_driver_instrument_routine_channel2_hi_pitch_read:
	lpm r27, Z //load hi pitch data into r27
	cpi r27, 0x80 //check for macro end flag
	brne sound_driver_instrument_routine_channel2_hi_pitch_calculate //if the data was not the macro end flag, calculate the hi pitch offset



sound_driver_instrument_routine_channel2_hi_pitch_macro_end_flag:
sound_driver_instrument_routine_channel2_hi_pitch_macro_end_flag_check_release:
	subi r26, 1 //keep the macro offset at the end flag
	sts triangle_hi_pitch_macro_offset, r26
	lds r27, triangle_hi_pitch_macro_release
	cpi r27, 0xFF
	brne sound_driver_instrument_routine_channel2_hi_pitch_default //if there is a release flag, we don't need to loop. offset the hi pitch by the final total hi pitch

sound_driver_instrument_routine_channel2_hi_pitch_macro_end_flag_check_loop:
	lds r27, triangle_hi_pitch_macro_loop //load the loop index
	cpi r27, 0xFF //check if there is a loop index
	breq sound_driver_instrument_routine_channel2_hi_pitch_default //if there is no loop flag, we don't need to loop. offset the pitch by the final total hi pitch
	sts triangle_hi_pitch_macro_offset, r27 //store the loop index into the offset
	rjmp sound_driver_instrument_routine_channel2_hi_pitch //go back and re-read the hi pitch data



sound_driver_instrument_routine_channel2_hi_pitch_default:
	lds r27, triangle_total_hi_pitch_offset
	rjmp sound_driver_instrument_routine_channel2_hi_pitch_calculate_multiply

sound_driver_instrument_routine_channel2_hi_pitch_calculate:
	lds r26, triangle_total_hi_pitch_offset //load the total hi pitch offset to change
	add r27, r26
	sts triangle_total_hi_pitch_offset, r27

sound_driver_instrument_routine_channel2_hi_pitch_calculate_multiply:
	push r22 //only registers r16 - r23 can be used with mulsu
	push r23
	mov r22, r27 //store the signed hi pitch offset data into r22
	ldi r23, 0b10110010 //store r23 with 11.125 note: this is the closest approximation to the 11.1746014718 multiplier we can get with 8 bits
	mulsu r22, r23
	pop r23
	pop r22

	//NOTE: fractional bits do not need to be shifted out because hi pitch offsets are multiplied by 16. shifting right 4 times for the fraction and left 4 times for the 16x is the same as no shift.
sound_driver_instrument_routine_channel2_hi_pitch_calculate_offset:
	lds r26, TCB2_CCMPL //load the low bits for timer
	lds r27, TCB2_CCMPH //load the high bits for timer
	add r26, r0 //offset the timer values
	adc r27, r1
	sts TCB2_CCMPL, r26 //store the new low bits for timer
	sts TCB2_CCMPH, r27 //store the new high bits for timer



//NOTE: The triangle channel does not have a duty cycle
sound_driver_instrument_routine_channel2_duty:



sound_driver_channel2_fx_routines:
sound_driver_channel2_fx_1xx_routine:
	lds ZL, triangle_fx_1xx
	lds ZH, triangle_fx_1xx+1
	adiw Z, 0
	breq sound_driver_channel2_fx_2xx_routine

	lds r26, triangle_fx_1xx_total //load the rate to change the pitch by
	lds r27, triangle_fx_1xx_total+1
	add r26, ZL //increase the total offset by the rate
	adc r27, ZH
	sts triangle_fx_1xx_total, r26
	sts triangle_fx_1xx_total+1, r27



sound_driver_channel2_fx_2xx_routine:
	lds ZL, triangle_fx_2xx
	lds ZH, triangle_fx_2xx+1
	adiw Z, 0
	breq sound_driver_channel2_fx_3xx_routine

	lds r26, triangle_fx_2xx_total //load the rate to change the pitch by
	lds r27, triangle_fx_2xx_total+1
	add r26, ZL //increase the total offset by the rate
	adc r27, ZH
	sts triangle_fx_2xx_total, r26
	sts triangle_fx_2xx_total+1, r27



sound_driver_channel2_fx_3xx_routine:
	lds ZL, triangle_fx_3xx_speed
	lds ZH, triangle_fx_3xx_speed+1
	adiw Z, 0
	brne sound_driver_channel2_fx_3xx_routine_check_start
	rjmp sound_driver_channel2_fx_4xy_routine

sound_driver_channel2_fx_3xx_routine_check_start:
	lds r26, triangle_fx_3xx_start
	lds r27, triangle_fx_3xx_start+1
	adiw r26:r27, 0
	brne sound_driver_channel2_fx_3xx_routine_main
	rjmp sound_driver_channel2_fx_4xy_routine

sound_driver_channel2_fx_3xx_routine_main:
	lds r28, triangle_fx_3xx_target
	lds r29, triangle_fx_3xx_target+1

	cp r26, r28 //check if the target is lower, higher or equal to the starting period
	cpc r27, r29
	breq sound_driver_channel2_fx_3xx_routine_disable
	brlo sound_driver_channel2_fx_3xx_routine_subtract //if target is larger, we need to add to the start (subtract from the current timer)
	rjmp sound_driver_channel2_fx_3xx_routine_add //if target is smaller, we need to subtract from the start (add to the current timer)

sound_driver_channel2_fx_3xx_routine_disable:
	sts triangle_fx_3xx_start, zero //setting the starting period to 0 effectively disables this routine until a note has been changed
	sts triangle_fx_3xx_start+1, zero //NOTE: to truly disable the effect, 300 must be written.
	rjmp sound_driver_channel2_fx_4xy_routine

sound_driver_channel2_fx_3xx_routine_subtract:
	sub r28, r26 //store the total difference between the start and the target into r28:r29
	sbc r29, r27
	lds r26, triangle_fx_3xx_total_offset
	lds r27, triangle_fx_3xx_total_offset+1

	add r26, ZL //add the speed to the total offset
	adc r27, ZH
	sub r28, r26 //invert the total difference with the total offset
	sbc r29, r27
	brlo sound_driver_channel2_fx_3xx_routine_disable //if the total offset has surpassed the target difference (target note has been reached)

	sts triangle_fx_3xx_total_offset, r26 //store the new total offset
	sts triangle_fx_3xx_total_offset+1, r27

	lds r26, TCB2_CCMPL //load the current timer period
	lds r27, TCB2_CCMPH
	sub r26, r28 //offset the current timer period with the total offset
	sbc r27, r29
	sts TCB2_CCMPL, r26
	sts TCB2_CCMPH, r27
	rjmp sound_driver_channel2_fx_4xy_routine

sound_driver_channel2_fx_3xx_routine_add:
	sub r26, r28 //store the total difference between the start and the target into r28:r29
	sbc r27, r29
	lds r28, triangle_fx_3xx_total_offset
	lds r29, triangle_fx_3xx_total_offset+1

	add r28, ZL //add the speed to the total offset
	adc r29, ZH
	sub r26, r28 //invert the total difference with the total offset
	sbc r27, r29
	brlo sound_driver_channel2_fx_3xx_routine_disable //if the total offset has surpassed the target difference (target note has been reached)

	sts triangle_fx_3xx_total_offset, r28 //store the new total offset
	sts triangle_fx_3xx_total_offset+1, r29

	lds r28, TCB2_CCMPL //load the current timer period
	lds r29, TCB2_CCMPH
	add r28, r26 //offset the current timer period with the total offset
	adc r29, r27
	sts TCB2_CCMPL, r28
	sts TCB2_CCMPH, r29



sound_driver_channel2_fx_4xy_routine:
	lds r26, triangle_fx_4xy_speed
	cp r26, zero
	brne sound_driver_channel2_fx_4xy_routine_continue
	rjmp sound_driver_channel2_fx_Qxy_routine //if speed is 0, then the effect is disabled

sound_driver_channel2_fx_4xy_routine_continue:
	lds r27, triangle_fx_4xy_depth
	lds r28, triangle_fx_4xy_phase
	add r28, r26 //increase the phase by the speed
	cpi r28, 64 //check if the phase overflowed NOTE: phase values range from 0-63
	brlo sound_driver_channel2_fx_4xy_routine_phase //if no overflow, map the phase to 0-15.
	ldi r28, 0x00 //reset the phase if there was overflow

sound_driver_channel2_fx_4xy_routine_phase:
	sts triangle_fx_4xy_phase, r28 //store the new phase
	cpi r28, 16
	brlo sound_driver_channel2_fx_4xy_routine_phase_0
	cpi r28, 32
	brlo sound_driver_channel2_fx_4xy_routine_phase_1
	cpi r28, 48
	brlo sound_driver_channel2_fx_4xy_routine_phase_2
	rjmp sound_driver_channel2_fx_4xy_routine_phase_3

sound_driver_channel2_fx_4xy_routine_phase_0:
	andi r28, 0x0F //mask for values 0-15
	rjmp sound_driver_channel2_fx_4xy_routine_load_subtract

sound_driver_channel2_fx_4xy_routine_phase_1:
	ori r28, 0xF0
	com r28 //invert values 0-15
	rjmp sound_driver_channel2_fx_4xy_routine_load_subtract

sound_driver_channel2_fx_4xy_routine_phase_2:
	andi r28, 0x0F //mask for values 0-15
	rjmp sound_driver_channel2_fx_4xy_routine_load_add

sound_driver_channel2_fx_4xy_routine_phase_3:
	ori r28, 0xF0
	com r28 //invert values 0-15
	rjmp sound_driver_channel2_fx_4xy_routine_load_add

sound_driver_channel2_fx_4xy_routine_load_add:
	swap r27 //multiply depth by 16
	add r28, r27 //add the depth to the phase NOTE: the table is divided into sixteen different set of 8 values, which correspond to the depth
	
	ldi ZL, LOW(vibrato_table << 1) //point z to vibrato table
	ldi ZH, HIGH(vibrato_table << 1)
	add ZL, r28 //offset the table by the depth+phase
	adc ZH, zero
	lpm r28, Z //load the tremelo value into r28

	push r22 //only registers r16 - r23 can be used with mulsu
	push r23
	mov r22, r28 //store the vibrato value into r22
	ldi r23, 0b10110010 //store r23 with 11.125 note: this is the closest approximation to the 11.1746014718 multiplier we can get with 8 bits
	mul r22, r23
	pop r23
	pop r22

	lsr r1 //shift out the fractional bits
	ror r0
	lsr r1
	ror r0
	lsr r1
	ror r0
	lsr r1
	ror r0
	
	lds r26, TCB2_CCMPL
	lds r27, TCB2_CCMPH
	add r26, r0
	adc r27, r1
	sts TCB2_CCMPL, r26
	sts TCB2_CCMPH, r27
	rjmp sound_driver_channel2_fx_Qxy_routine

sound_driver_channel2_fx_4xy_routine_load_subtract:
	swap r27 //multiply depth by 16
	add r28, r27 //add the depth to the phase NOTE: the table is divided into sixteen different set of 8 values, which correspond to the depth
	ldi ZL, LOW(vibrato_table << 1) //point z to vibrato table
	ldi ZH, HIGH(vibrato_table << 1)
	add ZL, r28 //offset the table by the depth+phase
	adc ZH, zero
	lpm r28, Z //load the vibrato value into r28

	push r22 //only registers r16 - r23 can be used with mulsu
	push r23
	mov r22, r28 //store the vibrato value into r22
	ldi r23, 0b10110010 //store r23 with 11.125 note: this is the closest approximation to the 11.1746014718 multiplier we can get with 8 bits
	mul r22, r23
	pop r23
	pop r22

	lsr r1 //shift out the fractional bits
	ror r0
	lsr r1
	ror r0
	lsr r1
	ror r0
	lsr r1
	ror r0

	lds r26, TCB2_CCMPL
	lds r27, TCB2_CCMPH
	sub r26, r0
	sbc r27, r1
	sts TCB2_CCMPL, r26
	sts TCB2_CCMPH, r27



//NOTE: The Qxy and Rxy routines ONLY calculate the total offset. The offset is applied in the pitch macro routine
sound_driver_channel2_fx_Qxy_routine:
	lds ZL, triangle_fx_Qxy_target
	lds ZH, triangle_fx_Qxy_target+1
	adiw Z, 0
	breq sound_driver_channel2_fx_Rxy_routine //if the effect is not enabled, skip the routine

	lds r26, triangle_fx_Qxy_total_offset
	lds r27, triangle_fx_Qxy_total_offset+1
	lds r28, TCB2_CCMPL
	lds r29, TCB2_CCMPH

	sub ZL, r28 //calculate the difference to the target
	sbc ZH, r29
	brsh sound_driver_channel2_fx_Qxy_routine_end //if the target has been reached (or passed)
	brlo sound_driver_channel2_fx_Qxy_routine_add

sound_driver_channel2_fx_Qxy_routine_end:
	sts triangle_fx_Qxy_total_offset, zero //turn off the effect
	sts triangle_fx_Qxy_total_offset+1, zero
	sts triangle_fx_Qxy_target, zero
	sts triangle_fx_Qxy_target+1, zero
	lds r27, triangle_fx_Qxy_target_note
	sts triangle_note, r27 //replace the note with the final target note
	rjmp sound_driver_channel2_fx_Rxy_routine

sound_driver_channel2_fx_Qxy_routine_add:
	lds r28, triangle_fx_Qxy_speed
	lds r29, triangle_fx_Qxy_speed+1
	add r26, r28 //increase the total offset by the speed
	adc r27, r29
	sts triangle_fx_Qxy_total_offset, r26 //store the total offset
	sts triangle_fx_Qxy_total_offset+1, r27



sound_driver_channel2_fx_Rxy_routine:
	lds ZL, triangle_fx_Rxy_target
	lds ZH, triangle_fx_Rxy_target+1
	adiw Z, 0
	breq sound_driver_instrument_routine_channel3_volume //if the effect is not enabled, skip the routine

	lds r26, triangle_fx_Rxy_total_offset
	lds r27, triangle_fx_Rxy_total_offset+1
	lds r28, TCB2_CCMPL
	lds r29, TCB2_CCMPH

	sub r28, ZL //calculate the difference to the target
	sbc r29, ZH
	brsh sound_driver_channel2_fx_Rxy_routine_end //if the target has been reached (or passed)
	brlo sound_driver_channel2_fx_Rxy_routine_add

sound_driver_channel2_fx_Rxy_routine_end:
	sts triangle_fx_Rxy_total_offset, zero //disable the effect
	sts triangle_fx_Rxy_total_offset+1, zero
	sts triangle_fx_Rxy_target, zero
	sts triangle_fx_Rxy_target+1, zero
	lds r27, triangle_fx_Rxy_target_note
	sts triangle_note, r27 //replace the note with the final target note
	rjmp sound_driver_instrument_routine_channel3_volume

sound_driver_channel2_fx_Rxy_routine_add:
	lds r28, triangle_fx_Rxy_speed
	lds r29, triangle_fx_Rxy_speed+1
	add r26, r28 //increase the total offset by the speed
	adc r27, r29
	sts triangle_fx_Rxy_total_offset, r26 //store the total offset
	sts triangle_fx_Rxy_total_offset+1, r27



sound_driver_instrument_routine_channel3_volume:
	lds ZL, noise_volume_macro
	lds ZH, noise_volume_macro+1
	adiw Z, 0
	breq sound_driver_instrument_routine_channel3_volume_default //if no volume macro is in use, use default multiplier of F
	lsl ZL //multiply by 2 to make Z into a byte pointer for the macro's address
	rol ZH
	lds r26, noise_volume_macro_offset
	add ZL, r26
	adc ZH, zero

	lds r27, noise_volume_macro_release
	cp r27, r26
	brne sound_driver_instrument_routine_channel3_volume_increment //if the current offset is not equal to the release index, increment the offset
	lds r26, noise_volume_macro_loop
	cp r26, r27 //check if loop flag exists NOTE: a loop flag and a release flag can only co-exist if the loop is less than the release
	brlo sound_driver_instrument_routine_channel3_volume_increment+1 //if the current offset is equal to the release index and there is a loop, load the offset with the loop index, but also read the current index data
	rjmp sound_driver_instrument_routine_channel3_volume_read //if the current offset is equal to the release index and there is no loop, then keep the offset unchanged

sound_driver_instrument_routine_channel3_volume_increment:
	inc r26 //increment the macro offset
	sts noise_volume_macro_offset, r26
	
sound_driver_instrument_routine_channel3_volume_read:
	lpm r27, Z //load volume data into r27
	cpi r27, 0xFF //check for macro end flag
	brne sound_driver_instrument_routine_channel3_volume_calculate //if the data was not the macro end flag, calculate the volume



sound_driver_instrument_routine_channel3_volume_macro_end_flag:
sound_driver_instrument_routine_channel3_volume_macro_end_flag_check_release:
	lds r27, noise_volume_macro_release
	cpi r27, 0xFF
	brne sound_driver_instrument_routine_channel3_volume_macro_end_flag_last_index //if there is a release flag, we don't need to loop. stay at the last valid index

sound_driver_instrument_routine_channel3_volume_macro_end_flag_check_loop:
	lds r27, noise_volume_macro_loop //load the loop index
	sts noise_volume_macro_offset, r27 //store the loop index into the offset
	rjmp sound_driver_instrument_routine_channel3_volume //go back and re-read the volume data

sound_driver_instrument_routine_channel3_volume_macro_end_flag_last_index:
	subi r26, 2 //go back to last valid index NOTE: Since we increment the offset everytime we read data, we have to decrement twice. 1 to account for the increment and 1 for the end flag.
	sts noise_volume_macro_offset, r26
	rjmp sound_driver_instrument_routine_channel3_volume //go back and re-read the volume data



sound_driver_instrument_routine_channel3_volume_calculate:
	ldi ZL, LOW(volumes << 1) //point Z to volume table
	ldi ZH, HIGH(volumes << 1)
	swap r27 //multiply the offset by 16 to move to the correct row in the volume table
	add ZL, r27 //add offset to the table
	adc ZH, zero

sound_driver_instrument_routine_channel3_volume_load:
	lds r27, noise_param //load main volume
	andi r27, 0x0F //mask for VVVV volume bits

	lds r26, noise_fx_7xy_value
	cpi r26, 0x00
	brne sound_driver_instrument_routine_channel3_volume_load_7xy

	add ZL, r27 //offset the volume table by the main volume
	adc ZH, zero
	lpm r27, Z
	sts noise_output_volume, r27 //store the new output volume
	rjmp sound_driver_instrument_routine_channel3_arpeggio

sound_driver_instrument_routine_channel3_volume_default:
	lds r27, noise_param //a multiplier of F means in no change to the main volume, so we just copy the value into the output
	andi r27, 0x0F //mask for VVVV volume bits

	lds r26, noise_fx_7xy_value
	cpi r26, 0x00
	brne sound_driver_instrument_routine_channel3_volume_default_7xy
	sts noise_output_volume, r27
	rjmp sound_driver_instrument_routine_channel3_arpeggio

sound_driver_instrument_routine_channel3_volume_load_7xy:
	sub r27, r26 //subtract the volume by the tremelo value
	brcs sound_driver_instrument_routine_channel3_volume_load_7xy_overflow
	breq sound_driver_instrument_routine_channel3_volume_load_7xy_overflow

	add ZL, r27 //offset the volume table by the main volume
	adc ZH, zero
	lpm r27, Z
	sts noise_output_volume, r27 //store the new output volume
	rjmp sound_driver_instrument_routine_channel3_arpeggio

sound_driver_instrument_routine_channel3_volume_load_7xy_overflow:
	ldi r27, 0x01 //if the subtraction resulted in a negative volume, cap it to 0x01
	add ZL, r27 //offset the volume table by the main volume
	adc ZH, zero
	lpm r27, Z
	sts noise_output_volume, r27 //store the new output volume
	rjmp sound_driver_instrument_routine_channel3_arpeggio

sound_driver_instrument_routine_channel3_volume_default_7xy:
	sub r27, r26 //subtract the volume by the tremelo value
	brcs sound_driver_instrument_routine_channel3_volume_default_7xy_overflow
	breq sound_driver_instrument_routine_channel3_volume_default_7xy_overflow
	sts noise_output_volume, r27
	rjmp sound_driver_instrument_routine_channel3_arpeggio
	
sound_driver_instrument_routine_channel3_volume_default_7xy_overflow:
	ldi r27, 0x01 //if the subtraction resulted in a negative volume, cap it to 0x01
	sts noise_output_volume, r27



sound_driver_instrument_routine_channel3_arpeggio:
	//NOTE: The arpeggio macro routine is also in charge of actually setting the timers using the note stored in SRAM. The default routine is responsible for that in the case no arpeggio macro is used.
	lds ZL, noise_arpeggio_macro
	lds ZH, noise_arpeggio_macro+1
	adiw Z, 0
	breq sound_driver_instrument_routine_channel3_arpeggio_default //if no arpeggio macro is in use, go output the note without any offsets
	lsl ZL //multiply by 2 to make Z into a byte pointer for the macro's address
	rol ZH
	lds r26, noise_arpeggio_macro_offset
	add ZL, r26
	adc ZH, zero

	lds r27, noise_arpeggio_macro_release
	cp r27, r26
	brne sound_driver_instrument_routine_channel3_arpeggio_increment //if the current offset is not equal to the release index, increment the offset
	lds r26, noise_arpeggio_macro_loop
	cp r26, r27 //check if loop flag exists NOTE: a loop flag and a release flag can only co-exist if the loop is less than the release
	brlo sound_driver_instrument_routine_channel3_arpeggio_increment+1 //if the current offset is equal to the release index and there is a loop, reload the loop index, but also read the current index data
	rjmp sound_driver_instrument_routine_channel3_arpeggio_read //if the current offset is equal to the release index and there is no loop, then keep the offset unchanged

sound_driver_instrument_routine_channel3_arpeggio_increment:
	inc r26 //increment the macro offset
	sts noise_arpeggio_macro_offset, r26
	
sound_driver_instrument_routine_channel3_arpeggio_read:
	lpm r27, Z //load arpeggio data into r27
	cpi r27, 0x80 //check for macro end flag
	breq sound_driver_instrument_routine_channel3_arpeggio_macro_end_flag
	rjmp sound_driver_instrument_routine_channel3_arpeggio_process //if the data was not the macro end flag, calculate the volume


sound_driver_instrument_routine_channel3_arpeggio_macro_end_flag:
sound_driver_instrument_routine_channel3_arpeggio_macro_end_flag_check_mode:
	subi r26, 1 //keep the offset at the end flag
	sts noise_arpeggio_macro_offset, r26
	lds r27, noise_arpeggio_macro_mode //load the mode to check for fixed/relative mode NOTE: end behavior for fixed/relative mode is different in that once the macro ends, the true note is played
	cpi r27, 0x01
	brlo sound_driver_instrument_routine_channel3_arpeggio_macro_end_flag_absolute

sound_driver_instrument_routine_channel3_arpeggio_macro_end_flag_fixed_relative_check_release:
	lds r27, noise_arpeggio_macro_release
	cpi r27, 0xFF
	brne sound_driver_instrument_routine_channel3_arpeggio_default //if there is a release flag, we don't need to loop. just play the true note

sound_driver_instrument_routine_channel3_arpeggio_macro_end_flag_fixed_relative_check_loop:
	lds r27, noise_arpeggio_macro_loop
	cpi r27, 0xFF
	brne sound_driver_instrument_routine_channel3_arpeggio_macro_end_flag_reload //if there is no release flag, but there is a loop, load the offset with the loop index
	rjmp sound_driver_instrument_routine_channel3_arpeggio_default //if there is no release flag and no loop, then play the true note

sound_driver_instrument_routine_channel3_arpeggio_macro_end_flag_absolute:
	lds r27, noise_arpeggio_macro_release
	cpi r27, 0xFF
	brne sound_driver_instrument_routine_channel3_arpeggio_macro_end_flag_absolute_no_loop //if there is a release flag, react as if there was no loop.

sound_driver_instrument_routine_channel3_arpeggio_macro_end_flag_absolute_check_loop:
	lds r27, noise_arpeggio_macro_loop //load the loop index
	cpi r27, 0xFF //check if loop flag exists
	brne sound_driver_instrument_routine_channel3_arpeggio_macro_end_flag_reload //if a loop flag exists, then load the loop value

sound_driver_instrument_routine_channel3_arpeggio_macro_end_flag_absolute_no_loop:
	lds r28, noise_fx_0xy_sequence //check for 0xy effect
	lds r29, noise_fx_0xy_sequence+1
	adiw r29:r28, 0
	brne sound_driver_instrument_routine_channel3_arpeggio_default_0xy //if 0xy effect exists, and there is no release/loop, use the default routine and apply the 0xy effect

	subi r26, 1 //if a loop flag does not exist and fixed mode is not used, use the last valid index
	sts noise_arpeggio_macro_offset, r26 //store the last valid index into the offset
	rjmp sound_driver_instrument_routine_channel3_arpeggio

sound_driver_instrument_routine_channel3_arpeggio_macro_end_flag_reload:
	sts noise_arpeggio_macro_offset, r27 //store the loop index into the offset
	rjmp sound_driver_instrument_routine_channel3_arpeggio //go back and re-read the volume data


sound_driver_instrument_routine_channel3_arpeggio_default:
	lds r28, noise_fx_0xy_sequence //load 0xy effect
	lds r29, noise_fx_0xy_sequence+1
	adiw r29:r28, 0 //check for 0xy effect
	breq sound_driver_instrument_routine_channel3_arpeggio_default_no_0xy //if there is no 0xy effect, we don't need to roll the sequence
	
//NOTE: because of the way the 0xy parameter is stored and processed, using x0 will not create a faster arpeggio
sound_driver_instrument_routine_channel3_arpeggio_default_0xy:
	lsr r29
	ror r28
	ror r29
	ror r28
	ror r29
	ror r28
	ror r29
	ror r28
	ror r29
	swap r29

	sts noise_fx_0xy_sequence, r28 //store the rolled sequence
	sts noise_fx_0xy_sequence+1, r29
	andi r28, 0x0F //mask out the 4 LSB
	lds r26, noise_note //load the current note index
	add r26, r28 //add the note offset
	rjmp sound_driver_instrument_routine_channel3_arpeggio_process_load
	
sound_driver_instrument_routine_channel3_arpeggio_default_no_0xy:
	//NOTE: the pitch offset does not need to be reset here because there is no new note being calculated
	lds r26, noise_note //load the current note index
	rjmp sound_driver_instrument_routine_channel3_arpeggio_process_load

sound_driver_instrument_routine_channel3_arpeggio_process:
	sts noise_total_pitch_offset, zero //the pitch offsets must be reset when a new note is to be calculated from an arpeggio macro
	sts noise_total_pitch_offset+1, zero
	sts noise_total_hi_pitch_offset, zero
	lds r26, noise_arpeggio_macro_mode
	cpi r26, 0x01 //absolute mode
	brlo sound_driver_instrument_routine_channel3_arpeggio_process_absolute
	breq sound_driver_instrument_routine_channel3_arpeggio_process_fixed
	rjmp sound_driver_instrument_routine_channel3_arpeggio_process_relative //relative mode

sound_driver_instrument_routine_channel3_arpeggio_process_absolute:
	lds r26, noise_note //load the current note index
	add r26, r27 //offset the note with the arpeggio data
	sbrc r27, 7 //check sign bit to check if we are subtracting from the note index
	rjmp sound_driver_instrument_routine_channel3_arpeggio_process_absolute_subtract

sound_driver_instrument_routine_channel3_arpeggio_process_absolute_add:
	cpi r26, 0x57 //check if the result is larger than the size of the note table (0x56 is the highest possible index)
	brlo sound_driver_instrument_routine_channel3_arpeggio_process_load //if the result is valid, go load the new note
	ldi r26, 0x56 //if the result was too large, just set the result to the highest possible note index
	rjmp sound_driver_instrument_routine_channel3_arpeggio_process_load

sound_driver_instrument_routine_channel3_arpeggio_process_absolute_subtract:
	sbrc r26, 7 //check if result is negative
	ldi r26, 0x00 //if the result was negative, reset it to the 0th index
	rjmp sound_driver_instrument_routine_channel3_arpeggio_process_load



sound_driver_instrument_routine_channel3_arpeggio_process_fixed:
	mov r26, r27 //move the arpeggio data into r26
	rjmp sound_driver_instrument_routine_channel3_arpeggio_process_load



sound_driver_instrument_routine_channel3_arpeggio_process_relative:
	lds r26, noise_note //load the current note index
	add r26, r27 //offset the note with the arpeggio data
	sbrc r27, 7 //check sign bit to check if we are subtracting from the note index
	rjmp sound_driver_instrument_routine_channel3_arpeggio_process_relative_subtract

sound_driver_instrument_routine_channel3_arpeggio_process_relative_add:
	sts noise_note, r26 //NOTE: relative mode modifies the original note index
	cpi r26, 0x57 //check if the result is larger than the size of the note table (0x56 is the highest possible index)
	brlo sound_driver_instrument_routine_channel3_arpeggio_process_load //if the result is valid, go load the new note
	ldi r26, 0x56 //if the result was too large, just set the result to the highest possible note index
	sts noise_note, r26
	rjmp sound_driver_instrument_routine_channel3_arpeggio_process_load

sound_driver_instrument_routine_channel3_arpeggio_process_relative_subtract:
	sbrc r26, 7 //check if result is negative
	ldi r26, 0x00 //if the result was negative, reset it to the 0th index
	sts noise_note, r26



sound_driver_instrument_routine_channel3_arpeggio_process_load:
	ldi ZL, LOW(noise_period_table << 1) //load in note table
	ldi ZH, HIGH(noise_period_table << 1)
	lsl r26 //double the offset for the note table because we are getting byte data
	add ZL, r26 //add offset
	adc ZH, zero
	lpm r26, Z+ //load bytes
	lpm r27, Z
	sts TCB3_CCMPL, r26 //load the LOW bits for timer
	sts TCB3_CCMPH, r27 //load the HIGH bits for timer
	sts noise_fx_3xx_target, r26 //NOTE: 3xx target note is stored here because the true note is always read in this arpeggio macro routine
	sts noise_fx_3xx_target+1, r27
	rjmp sound_driver_instrument_routine_channel3_pitch



sound_driver_instrument_routine_channel3_pitch:
	lds ZL, noise_pitch_macro
	lds ZH, noise_pitch_macro+1
	adiw Z, 0
	brne sound_driver_instrument_routine_channel3_pitch_continue
	rjmp sound_driver_instrument_routine_channel3_pitch_default //if no pitch macro is in use, process the current total pitch macro offset
sound_driver_instrument_routine_channel3_pitch_continue:
	lsl ZL //multiply by 2 to make z into a byte pointer for the macro's address
	rol ZH
	lds r26, noise_pitch_macro_offset
	add ZL, r26
	adc ZH, zero

	lds r27, noise_pitch_macro_release
	cp r27, r26
	brne sound_driver_instrument_routine_channel3_pitch_increment //if the current offset is not equal to the release index, increment the offset
	lds r26, noise_pitch_macro_loop
	cp r26, r27 //check if loop flag exists NOTE: a loop flag and a release flag can only co-exist if the loop is less than the release
	brlo sound_driver_instrument_routine_channel3_pitch_increment+1 //if the current offset is equal to the release index and there is a loop, load the offset with the loop index, but also read the current index data
	rjmp sound_driver_instrument_routine_channel3_pitch_read //if the current offset is equal to the release index and there is no loop, then keep the offset unchanged

sound_driver_instrument_routine_channel3_pitch_increment:
	inc r26 //increment the macro offset
	sts noise_pitch_macro_offset, r26
	
sound_driver_instrument_routine_channel3_pitch_read:
	lpm r27, Z //load pitch data into r27
	cpi r27, 0x80 //check for macro end flag
	brne sound_driver_instrument_routine_channel3_pitch_calculate //if the data was not the macro end flag, calculate the pitch offset



sound_driver_instrument_routine_channel3_pitch_macro_end_flag:
sound_driver_instrument_routine_channel3_pitch_macro_end_flag_check_release:
	subi r26, 1 //keep the macro offset at the end flag
	sts noise_pitch_macro_offset, r26
	lds r27, noise_pitch_macro_release
	cpi r27, 0xFF
	brne sound_driver_instrument_routine_channel3_pitch_default //if there is a release flag, we don't need to loop. offset the pitch by the final total pitch

sound_driver_instrument_routine_channel3_pitch_macro_end_flag_check_loop:
	lds r27, noise_pitch_macro_loop //load the loop index
	cpi r27, 0xFF //check if there is a loop index
	breq sound_driver_instrument_routine_channel3_pitch_default //if there is no loop flag, we don't need to loop. offset the pitch by the final total pitch
	sts noise_pitch_macro_offset, r27 //store the loop index into the offset
	rjmp sound_driver_instrument_routine_channel3_pitch //go back and re-read the pitch data



sound_driver_instrument_routine_channel3_pitch_default:
	ldi r27, 0x00
sound_driver_instrument_routine_channel3_pitch_calculate:
	push r22 //only registers r16 - r23 can be used with mulsu
	push r23
	mov r22, r27 //store the signed pitch offset data into r22
	ldi r23, 0b10110010 //store r23 with 11.125 note: this is the closest approximation to the 11.1746014718 multiplier we can get with 8 bits
	mulsu r22, r23
	pop r23
	pop r22

	lsr r1 //shift out the fractional bits
	ror r0
	lsr r1
	ror r0
	lsr r1
	ror r0
	lsr r1
	ror r0

sound_driver_instrument_routine_channel3_pitch_calculate_check_negative:
	sbrs r1, 3 //check if result was a negative number
	rjmp sound_driver_instrument_routine_channel3_pitch_calculate_offset //if the result was positive, don't fill with 1s

sound_driver_instrument_routine_channel3_pitch_calculate_negative:
	ldi r28, 0xF0
	or r1, r28 //when right shifting a two's complement number, must use 1s instead of 0s to fill

sound_driver_instrument_routine_channel3_pitch_calculate_check_divisible_8:
	andi r27, 0b00000111
	breq sound_driver_instrument_routine_channel3_pitch_calculate_offset

	ldi r27, 0x01
	add r0, r27
	adc r1, zero

sound_driver_instrument_routine_channel3_pitch_calculate_offset:
	lds r26, noise_total_pitch_offset
	lds r27, noise_total_pitch_offset+1
	add r0, r26
	adc r1, r27
	sts noise_total_pitch_offset, r0
	sts noise_total_pitch_offset+1, r1
	lds r26, TCB3_CCMPL //load the low bits for timer
	lds r27, TCB3_CCMPH //load the high bits for timer
	add r26, r0 //offset the timer values
	adc r27, r1
	
	lds r28, noise_fx_1xx_total
	lds r29, noise_fx_1xx_total+1
	sub r26, r28
	sbc r27, r29
	lds r28, noise_fx_2xx_total
	lds r29, noise_fx_2xx_total+1
	add r26, r28
	adc r27, r29
	lds r28, noise_fx_Pxx_total
	lds r29, noise_fx_Pxx_total+1
	add r26, r28
	adc r27, r29
	lds r28, noise_fx_Qxy_total_offset //NOTE: Qxy and Rxy offsets are applied here
	lds r29, noise_fx_Qxy_total_offset+1
	sub r26, r28
	sbc r27, r29
	lds r28, noise_fx_Rxy_total_offset
	lds r29, noise_fx_Rxy_total_offset+1
	add r26, r28
	adc r27, r29

	sts TCB3_CCMPL, r26 //store the new low bits for timer
	sts TCB3_CCMPH, r27 //store the new high bits for timer
	


//NOTE: The hi pitch macro routine does not account for overflowing from the offset. In famitracker, if the offset
//goes beyond the note range, there will be no more offset calculations. In this routine, it is possible that
//the pitch goes from B-7 and back around to C-0. I don't believe there will ever be a song in which this will be a problem.
sound_driver_instrument_routine_channel3_hi_pitch:
	lds ZL, noise_hi_pitch_macro
	lds ZH, noise_hi_pitch_macro+1
	adiw Z, 0
	brne sound_driver_instrument_routine_channel3_hi_pitch_continue
	rjmp sound_driver_instrument_routine_channel3_duty //if no hi pitch macro is in use, go to the next macro routine
sound_driver_instrument_routine_channel3_hi_pitch_continue:
	lsl ZL //multiply by 2 to make z into a byte pointer for the macro's address
	rol ZH
	lds r26, noise_hi_pitch_macro_offset
	add ZL, r26
	adc ZH, zero

	lds r27, noise_hi_pitch_macro_release
	cp r27, r26
	brne sound_driver_instrument_routine_channel3_hi_pitch_increment //if the current offset is not equal to the release index, increment the offset
	lds r26, noise_hi_pitch_macro_loop
	cp r26, r27 //check if loop flag exists NOTE: a loop flag and a release flag can only co-exist if the loop is less than the release
	brlo sound_driver_instrument_routine_channel3_hi_pitch_increment+1 //if the current offset is equal to the release index and there is a loop, load the offset with the loop index, but also read the current index data
	rjmp sound_driver_instrument_routine_channel3_hi_pitch_read //if the current offset is equal to the release index and there is no loop, then keep the offset unchanged

sound_driver_instrument_routine_channel3_hi_pitch_increment:
	inc r26 //increment the macro offset
	sts noise_hi_pitch_macro_offset, r26
	
sound_driver_instrument_routine_channel3_hi_pitch_read:
	lpm r27, Z //load hi pitch data into r27
	cpi r27, 0x80 //check for macro end flag
	brne sound_driver_instrument_routine_channel3_hi_pitch_calculate //if the data was not the macro end flag, calculate the hi pitch offset



sound_driver_instrument_routine_channel3_hi_pitch_macro_end_flag:
sound_driver_instrument_routine_channel3_hi_pitch_macro_end_flag_check_release:
	subi r26, 1 //keep the macro offset at the end flag
	sts noise_hi_pitch_macro_offset, r26
	lds r27, noise_hi_pitch_macro_release
	cpi r27, 0xFF
	brne sound_driver_instrument_routine_channel3_hi_pitch_default //if there is a release flag, we don't need to loop. offset the hi pitch by the final total hi pitch

sound_driver_instrument_routine_channel3_hi_pitch_macro_end_flag_check_loop:
	lds r27, noise_hi_pitch_macro_loop //load the loop index
	cpi r27, 0xFF //check if there is a loop index
	breq sound_driver_instrument_routine_channel3_hi_pitch_default //if there is no loop flag, we don't need to loop. offset the pitch by the final total hi pitch
	sts noise_hi_pitch_macro_offset, r27 //store the loop index into the offset
	rjmp sound_driver_instrument_routine_channel3_hi_pitch //go back and re-read the hi pitch data



sound_driver_instrument_routine_channel3_hi_pitch_default:
	lds r27, noise_total_hi_pitch_offset
	rjmp sound_driver_instrument_routine_channel3_hi_pitch_calculate_multiply

sound_driver_instrument_routine_channel3_hi_pitch_calculate:
	lds r26, noise_total_hi_pitch_offset //load the total hi pitch offset to change
	add r27, r26
	sts noise_total_hi_pitch_offset, r27

sound_driver_instrument_routine_channel3_hi_pitch_calculate_multiply:
	push r22 //only registers r16 - r23 can be used with mulsu
	push r23
	mov r22, r27 //store the signed hi pitch offset data into r22
	ldi r23, 0b10110010 //store r23 with 11.125 note: this is the closest approximation to the 11.1746014718 multiplier we can get with 8 bits
	mulsu r22, r23
	pop r23
	pop r22

	//NOTE: fractional bits do not need to be shifted out because hi pitch offsets are multiplied by 16. shifting right 4 times for the fraction and left 4 times for the 16x is the same as no shift.
sound_driver_instrument_routine_channel3_hi_pitch_calculate_offset:
	lds r26, TCB3_CCMPL //load the low bits for timer
	lds r27, TCB3_CCMPH //load the high bits for timer
	add r26, r0 //offset the timer values
	adc r27, r1
	sts TCB3_CCMPL, r26 //store the new low bits for timer
	sts TCB3_CCMPH, r27 //store the new high bits for timer



sound_driver_instrument_routine_channel3_duty:
	lds ZL, noise_duty_macro
	lds ZH, noise_duty_macro+1
	adiw Z, 0
	breq sound_driver_channel3_fx_routines //if no duty macro is in use, go to the next routine
	lsl ZL //multiply by 2 to make z into a byte pointer for the macro's address
	rol ZH
	lds r26, noise_duty_macro_offset
	add ZL, r26
	adc ZH, zero

	lds r27, noise_duty_macro_release
	cp r27, r26
	brne sound_driver_instrument_routine_channel3_duty_increment //if the current offset is not equal to the release index, increment the offset
	lds r26, noise_duty_macro_loop
	cp r26, r27 //check if loop flag exists NOTE: a loop flag and a release flag can only co-exist if the loop is less than the release
	brlo sound_driver_instrument_routine_channel3_duty_increment+1 //if the current offset is equal to the release index and there is a loop, load the offset with the loop index, but also read the current index data
	rjmp sound_driver_channel3_fx_routines //if the current offset is equal to the release index and there is no loop, then keep the offset unchanged and skip the rest of the routine

sound_driver_instrument_routine_channel3_duty_increment:
	inc r26 //increment the macro offset
	sts noise_duty_macro_offset, r26
	
sound_driver_instrument_routine_channel3_duty_read:
	lpm r27, Z //load pitch data into r27
	cpi r27, 0xFF //check for macro end flag
	brne sound_driver_instrument_routine_channel3_duty_load //if the data was not the macro end flag, load the new duty cycle



sound_driver_instrument_routine_channel3_duty_macro_end_flag:
sound_driver_instrument_routine_channel3_duty_macro_end_flag_check_release:
	subi r26, 1 //keep the macro offset at the end flag
	sts noise_duty_macro_offset, r26
	lds r27, noise_duty_macro_release
	cpi r27, 0xFF
	brne sound_driver_channel3_fx_routines //if there is a release flag, we don't need to loop. skip the rest of the routine.

sound_driver_instrument_routine_channel3_duty_macro_end_flag_check_loop:
	lds r27, noise_duty_macro_loop //load the loop index
	cpi r27, 0xFF //check if there is a loop index
	breq sound_driver_channel3_fx_routines //if there is no loop flag, we don't need to loop. skip the rest of the routine.
	sts noise_duty_macro_offset, r27 //store the loop index into the offset
	rjmp sound_driver_instrument_routine_channel3_duty //go back and re-read the duty data



sound_driver_instrument_routine_channel3_duty_load:
	lsr r27
	ror r27 //move mode bit to bit 7
	lds r28, noise_period
	andi r28, 0b01111111
	or r28, r27 //store the new noise mode
	sts noise_param, r28

	andi noise_sequence_HIGH, 0b01111111
	or noise_sequence_HIGH, r27



sound_driver_channel3_fx_routines:
sound_driver_channel3_fx_1xx_routine:
	lds ZL, noise_fx_1xx
	lds ZH, noise_fx_1xx+1
	adiw Z, 0
	breq sound_driver_channel3_fx_2xx_routine

	lds r26, noise_fx_1xx_total //load the rate to change the pitch by
	lds r27, noise_fx_1xx_total+1
	add r26, ZL //increase the total offset by the rate
	adc r27, ZH
	sts noise_fx_1xx_total, r26
	sts noise_fx_1xx_total+1, r27



sound_driver_channel3_fx_2xx_routine:
	lds ZL, noise_fx_2xx
	lds ZH, noise_fx_2xx+1
	adiw Z, 0
	breq sound_driver_channel3_fx_3xx_routine

	lds r26, noise_fx_2xx_total //load the rate to change the pitch by
	lds r27, noise_fx_2xx_total+1
	add r26, ZL //increase the total offset by the rate
	adc r27, ZH
	sts noise_fx_2xx_total, r26
	sts noise_fx_2xx_total+1, r27



sound_driver_channel3_fx_3xx_routine:
	lds ZL, noise_fx_3xx_speed
	lds ZH, noise_fx_3xx_speed+1
	adiw Z, 0
	brne sound_driver_channel3_fx_3xx_routine_check_start
	rjmp sound_driver_channel3_fx_4xy_routine

sound_driver_channel3_fx_3xx_routine_check_start:
	lds r26, noise_fx_3xx_start
	lds r27, noise_fx_3xx_start+1
	adiw r26:r27, 0
	brne sound_driver_channel3_fx_3xx_routine_main
	rjmp sound_driver_channel3_fx_4xy_routine

sound_driver_channel3_fx_3xx_routine_main:
	lds r28, noise_fx_3xx_target
	lds r29, noise_fx_3xx_target+1

	cp r26, r28 //check if the target is lower, higher or equal to the starting period
	cpc r27, r29
	breq sound_driver_channel3_fx_3xx_routine_disable
	brlo sound_driver_channel3_fx_3xx_routine_subtract //if target is larger, we need to add to the start (subtract from the current timer)
	rjmp sound_driver_channel3_fx_3xx_routine_add //if target is smaller, we need to subtract from the start (add to the current timer)

sound_driver_channel3_fx_3xx_routine_disable:
	sts noise_fx_3xx_start, zero //setting the starting period to 0 effectively disables this routine until a note has been changed
	sts noise_fx_3xx_start+1, zero //NOTE: to truly disable the effect, 300 must be written.
	rjmp sound_driver_channel3_fx_4xy_routine

sound_driver_channel3_fx_3xx_routine_subtract:
	sub r28, r26 //store the total difference between the start and the target into r28:r29
	sbc r29, r27
	lds r26, noise_fx_3xx_total_offset
	lds r27, noise_fx_3xx_total_offset+1

	add r26, ZL //add the speed to the total offset
	adc r27, ZH
	sub r28, r26 //invert the total difference with the total offset
	sbc r29, r27
	brlo sound_driver_channel3_fx_3xx_routine_disable //if the total offset has surpassed the target difference (target note has been reached)

	sts noise_fx_3xx_total_offset, r26 //store the new total offset
	sts noise_fx_3xx_total_offset+1, r27

	lds r26, TCB3_CCMPL //load the current timer period
	lds r27, TCB3_CCMPH
	sub r26, r28 //offset the current timer period with the total offset
	sbc r27, r29
	sts TCB3_CCMPL, r26
	sts TCB3_CCMPH, r27
	rjmp sound_driver_channel3_fx_4xy_routine

sound_driver_channel3_fx_3xx_routine_add:
	sub r26, r28 //store the total difference between the start and the target into r28:r29
	sbc r27, r29
	lds r28, noise_fx_3xx_total_offset
	lds r29, noise_fx_3xx_total_offset+1

	add r28, ZL //add the speed to the total offset
	adc r29, ZH
	sub r26, r28 //invert the total difference with the total offset
	sbc r27, r29
	brlo sound_driver_channel3_fx_3xx_routine_disable //if the total offset has surpassed the target difference (target note has been reached)

	sts noise_fx_3xx_total_offset, r28 //store the new total offset
	sts noise_fx_3xx_total_offset+1, r29

	lds r28, TCB3_CCMPL //load the current timer period
	lds r29, TCB3_CCMPH
	add r28, r26 //offset the current timer period with the total offset
	adc r29, r27
	sts TCB3_CCMPL, r28
	sts TCB3_CCMPH, r29



sound_driver_channel3_fx_4xy_routine:
	lds r26, noise_fx_4xy_speed
	cp r26, zero
	brne sound_driver_channel3_fx_4xy_routine_continue
	rjmp sound_driver_channel3_fx_7xy_routine //if speed is 0, then the effect is disabled

sound_driver_channel3_fx_4xy_routine_continue:
	lds r27, noise_fx_4xy_depth
	lds r28, noise_fx_4xy_phase
	add r28, r26 //increase the phase by the speed
	cpi r28, 64 //check if the phase overflowed NOTE: phase values range from 0-63
	brlo sound_driver_channel3_fx_4xy_routine_phase //if no overflow, map the phase to 0-15.
	ldi r28, 0x00 //reset the phase if there was overflow

sound_driver_channel3_fx_4xy_routine_phase:
	sts noise_fx_4xy_phase, r28 //store the new phase
	cpi r28, 16
	brlo sound_driver_channel3_fx_4xy_routine_phase_0
	cpi r28, 32
	brlo sound_driver_channel3_fx_4xy_routine_phase_1
	cpi r28, 48
	brlo sound_driver_channel3_fx_4xy_routine_phase_2
	rjmp sound_driver_channel3_fx_4xy_routine_phase_3

sound_driver_channel3_fx_4xy_routine_phase_0:
	andi r28, 0x0F //mask for values 0-15
	rjmp sound_driver_channel3_fx_4xy_routine_load_subtract

sound_driver_channel3_fx_4xy_routine_phase_1:
	ori r28, 0xF0
	com r28 //invert values 0-15
	rjmp sound_driver_channel3_fx_4xy_routine_load_subtract

sound_driver_channel3_fx_4xy_routine_phase_2:
	andi r28, 0x0F //mask for values 0-15
	rjmp sound_driver_channel3_fx_4xy_routine_load_add

sound_driver_channel3_fx_4xy_routine_phase_3:
	ori r28, 0xF0
	com r28 //invert values 0-15
	rjmp sound_driver_channel3_fx_4xy_routine_load_add

sound_driver_channel3_fx_4xy_routine_load_add:
	swap r27 //multiply depth by 16
	add r28, r27 //add the depth to the phase NOTE: the table is divided into sixteen different set of 8 values, which correspond to the depth
	
	ldi ZL, LOW(vibrato_table << 1) //point z to vibrato table
	ldi ZH, HIGH(vibrato_table << 1)
	add ZL, r28 //offset the table by the depth+phase
	adc ZH, zero
	lpm r28, Z //load the tremelo value into r28

	push r22 //only registers r16 - r23 can be used with mulsu
	push r23
	mov r22, r28 //store the vibrato value into r22
	ldi r23, 0b10110010 //store r23 with 11.125 note: this is the closest approximation to the 11.1746014718 multiplier we can get with 8 bits
	mul r22, r23
	pop r23
	pop r22

	lsr r1 //shift out the fractional bits
	ror r0
	lsr r1
	ror r0
	lsr r1
	ror r0
	lsr r1
	ror r0
	
	lds r26, TCB3_CCMPL
	lds r27, TCB3_CCMPH
	add r26, r0
	adc r27, r1
	sts TCB3_CCMPL, r26
	sts TCB3_CCMPH, r27
	rjmp sound_driver_channel3_fx_7xy_routine

sound_driver_channel3_fx_4xy_routine_load_subtract:
	swap r27 //multiply depth by 16
	add r28, r27 //add the depth to the phase NOTE: the table is divided into sixteen different set of 8 values, which correspond to the depth
	ldi ZL, LOW(vibrato_table << 1) //point z to vibrato table
	ldi ZH, HIGH(vibrato_table << 1)
	add ZL, r28 //offset the table by the depth+phase
	adc ZH, zero
	lpm r28, Z //load the vibrato value into r28

	push r22 //only registers r16 - r23 can be used with mulsu
	push r23
	mov r22, r28 //store the vibrato value into r22
	ldi r23, 0b10110010 //store r23 with 11.125 note: this is the closest approximation to the 11.1746014718 multiplier we can get with 8 bits
	mul r22, r23
	pop r23
	pop r22

	lsr r1 //shift out the fractional bits
	ror r0
	lsr r1
	ror r0
	lsr r1
	ror r0
	lsr r1
	ror r0

	lds r26, TCB3_CCMPL
	lds r27, TCB3_CCMPH
	sub r26, r0
	sbc r27, r1
	sts TCB3_CCMPL, r26
	sts TCB3_CCMPH, r27



sound_driver_channel3_fx_7xy_routine:
	lds r26, noise_fx_7xy_speed
	cp r26, zero
	breq sound_driver_channel3_fx_Axy_routine //if speed is 0, then the effect is disabled

	lds r27, noise_fx_7xy_depth
	lds r28, noise_fx_7xy_phase
	add r28, r26 //increase the phase by the speed
	cpi r28, 64 //check if the phase overflowed NOTE: phase values range from 0-63
	brlo sound_driver_channel3_fx_7xy_routine_phase //if no overflow, map the phase to 0-15.
	ldi r28, 0x00 //reset the phase if there was overflow

sound_driver_channel3_fx_7xy_routine_phase:
	sts noise_fx_7xy_phase, r28 //store the new phase
	lsr r28 //divide the phase by 2 NOTE: 7xy only uses half a sine unlike 4xy
	sbrs r28, 4
	rjmp sound_driver_channel3_fx_7xy_routine_phase_0
	rjmp sound_driver_channel3_fx_7xy_routine_phase_1
	
sound_driver_channel3_fx_7xy_routine_phase_0:
	andi r28, 0x0F //mask for values 0-15
	rjmp sound_driver_channel3_fx_7xy_routine_load

sound_driver_channel3_fx_7xy_routine_phase_1:
	ori r28, 0xF0
	com r28 //invert values 0-15
	rjmp sound_driver_channel3_fx_7xy_routine_load

sound_driver_channel3_fx_7xy_routine_load:
	swap r27 //multiply depth by 16
	add r28, r27 //add the depth to the phase NOTE: the table is divided into sixteen different set of 8 values, which correspond to the depth
	
	ldi ZL, LOW(vibrato_table << 1) //point z to vibrato table
	ldi ZH, HIGH(vibrato_table << 1)
	add ZL, r28 //offset the table by the depth+phase
	adc ZH, zero
	lpm r28, Z //load the vibrato value into r28

	lsr r28 //convert to tremelo value by shifting to the right
	sts noise_fx_7xy_value, r28



sound_driver_channel3_fx_Axy_routine:
	lds r27, noise_fx_Axy
	cp r27, zero
	breq sound_driver_channel3_fx_Qxy_routine //0 means that the effect is not in use
	
	lds r26, noise_fractional_volume //load fractional volume representation of the channel
	lds r28, noise_param //load the integer volume representation of the channel
	mov r29, r26 //copy fractional volume into r29
	mov r30, r28 //copy the noise_param into r30
	swap r30
	andi r29, 0xF0 //mask for integer volume bits from the fractional volume
	andi r30, 0xF0 //mask for VVVV volume bits

	cp r30, r29 //compare the fractional and integer volumes
	breq sound_driver_channel3_fx_Axy_routine_calculate

sound_driver_channel3_fx_Axy_routine_reload:
	mov r26, r30 //overwrite the fractional volume with the integer volume

sound_driver_channel3_fx_Axy_routine_calculate:
	sbrc r27, 7 //check for negative sign bit in Axy offset value
	rjmp sound_driver_channel3_fx_Axy_routine_calculate_subtraction

sound_driver_channel3_fx_Axy_routine_calculate_addition:
	add r26, r27 //add the fractional volume with the offset specified by the Axy effect
	brcc sound_driver_channel3_fx_Axy_routine_calculate_store //if the fractional volume did not overflow, go store the new volume
	ldi r26, 0xF0 //if the fractional volume did overflow, reset it back to the highest integer volume possible (0xF)
	rjmp sound_driver_channel3_fx_Axy_routine_calculate_store

sound_driver_channel3_fx_Axy_routine_calculate_subtraction:
	add r26, r27 //add the fractional volume with the offset specified by the Axy effect
	brcs sound_driver_channel3_fx_Axy_routine_calculate_store //if the fractional volume did not overflow, go store the new volume
	ldi r26, 0x00 //if the fractional volume did overflow, reset it back to the lowest integer volume possible (0x0)

sound_driver_channel3_fx_Axy_routine_calculate_store:
	sts noise_fractional_volume, r26 //store the new fractional volume
	andi r26, 0xF0 //mask for integer volume bits from the fractional volume
	swap r26
	andi r28, 0xF0 //mask out the old VVVV volume bits
	or r28, r26 //store the new volume back into noise_param
	sts noise_param, r28



//NOTE: The Qxy and Rxy routines ONLY calculate the total offset. The offset is applied in the pitch macro routine
sound_driver_channel3_fx_Qxy_routine:
	lds ZL, noise_fx_Qxy_target
	lds ZH, noise_fx_Qxy_target+1
	adiw Z, 0
	breq sound_driver_channel3_fx_Rxy_routine //if the effect is not enabled, skip the routine

	lds r26, noise_fx_Qxy_total_offset
	lds r27, noise_fx_Qxy_total_offset+1
	lds r28, TCB3_CCMPL
	lds r29, TCB3_CCMPH

	sub ZL, r28 //calculate the difference to the target
	sbc ZH, r29
	brsh sound_driver_channel3_fx_Qxy_routine_end //if the target has been reached (or passed)
	brlo sound_driver_channel3_fx_Qxy_routine_add

sound_driver_channel3_fx_Qxy_routine_end:
	sts noise_fx_Qxy_total_offset, zero //turn off the effect
	sts noise_fx_Qxy_total_offset+1, zero
	sts noise_fx_Qxy_target, zero
	sts noise_fx_Qxy_target+1, zero
	lds r27, noise_fx_Qxy_target_note
	sts noise_note, r27 //replace the note with the final target note
	rjmp sound_driver_channel3_fx_Rxy_routine

sound_driver_channel3_fx_Qxy_routine_add:
	lds r28, noise_fx_Qxy_speed
	lds r29, noise_fx_Qxy_speed+1
	add r26, r28 //increase the total offset by the speed
	adc r27, r29
	sts noise_fx_Qxy_total_offset, r26 //store the total offset
	sts noise_fx_Qxy_total_offset+1, r27



sound_driver_channel3_fx_Rxy_routine:
	lds ZL, noise_fx_Rxy_target
	lds ZH, noise_fx_Rxy_target+1
	adiw Z, 0
	breq sound_driver_instrument_routine_channel4_volume //if the effect is not enabled, skip the routine

	lds r26, noise_fx_Rxy_total_offset
	lds r27, noise_fx_Rxy_total_offset+1
	lds r28, TCB3_CCMPL
	lds r29, TCB3_CCMPH

	sub r28, ZL //calculate the difference to the target
	sbc r29, ZH
	brsh sound_driver_channel3_fx_Rxy_routine_end //if the target has been reached (or passed)
	brlo sound_driver_channel3_fx_Rxy_routine_add

sound_driver_channel3_fx_Rxy_routine_end:
	sts noise_fx_Rxy_total_offset, zero //disable the effect
	sts noise_fx_Rxy_total_offset+1, zero
	sts noise_fx_Rxy_target, zero
	sts noise_fx_Rxy_target+1, zero
	lds r27, noise_fx_Rxy_target_note
	sts noise_note, r27 //replace the note with the final target note
	rjmp sound_driver_instrument_routine_channel4_volume

sound_driver_channel3_fx_Rxy_routine_add:
	lds r28, noise_fx_Rxy_speed
	lds r29, noise_fx_Rxy_speed+1
	add r26, r28 //increase the total offset by the speed
	adc r27, r29
	sts noise_fx_Rxy_total_offset, r26 //store the total offset
	sts noise_fx_Rxy_total_offset+1, r27

sound_driver_instrument_routine_channel4_volume:

sound_driver_exit:
	pop r31
	pop r30
	pop r29
	pop r28
	jmp sequence_1_3 + 3 //+3 is to skip the stack instructions since we already pushed them



//TABLES
length: .db $05, $7F, $0A, $01, $14, $02, $28, $03, $50, $04, $1E, $05, $07, $06, $0D, $07, $06, $08, $0C, $09, $18, $0A, $30, $0B, $60, $0C, $24, $0D, $08, $0E, $10, $0F

//pulse sequences: 12.5%, 25%, 50%, 75%
sequences: .db 0b00000001, 0b00000011, 0b00001111, 0b11111100

//list of famitracker fx: http://famitracker.com/wiki/index.php?title=Effect_list
channel0_fx:
	.dw sound_driver_channel0_fx_0xy, sound_driver_channel0_fx_1xx, sound_driver_channel0_fx_2xx, sound_driver_channel0_fx_3xx, sound_driver_channel0_fx_4xy
	.dw sound_driver_channel0_fx_7xy, sound_driver_channel0_fx_Axy, sound_driver_channel0_fx_Bxx, sound_driver_channel0_fx_Cxx, sound_driver_channel0_fx_Dxx
	.dw sound_driver_channel0_fx_Exx, sound_driver_channel0_fx_Fxx, sound_driver_channel0_fx_Gxx, sound_driver_channel0_fx_Hxy, sound_driver_channel0_fx_Ixy
	.dw sound_driver_channel0_fx_Hxx, sound_driver_channel0_fx_Ixx, sound_driver_channel0_fx_Pxx, sound_driver_channel0_fx_Qxy, sound_driver_channel0_fx_Rxy
	.dw sound_driver_channel0_fx_Sxx, sound_driver_channel0_fx_Vxx, sound_driver_channel0_fx_Wxx, sound_driver_channel0_fx_Xxx, sound_driver_channel0_fx_Yxx
	.dw sound_driver_channel0_fx_Zxx

channel1_fx:
	.dw sound_driver_channel1_fx_0xy, sound_driver_channel1_fx_1xx, sound_driver_channel1_fx_2xx, sound_driver_channel1_fx_3xx, sound_driver_channel1_fx_4xy
	.dw sound_driver_channel1_fx_7xy, sound_driver_channel1_fx_Axy, sound_driver_channel1_fx_Bxx, sound_driver_channel1_fx_Cxx, sound_driver_channel1_fx_Dxx
	.dw sound_driver_channel1_fx_Exx, sound_driver_channel1_fx_Fxx, sound_driver_channel1_fx_Gxx, sound_driver_channel1_fx_Hxy, sound_driver_channel1_fx_Ixy
	.dw sound_driver_channel1_fx_Hxx, sound_driver_channel1_fx_Ixx, sound_driver_channel1_fx_Pxx, sound_driver_channel1_fx_Qxy, sound_driver_channel1_fx_Rxy
	.dw sound_driver_channel1_fx_Sxx, sound_driver_channel1_fx_Vxx, sound_driver_channel1_fx_Wxx, sound_driver_channel1_fx_Xxx, sound_driver_channel1_fx_Yxx
	.dw sound_driver_channel1_fx_Zxx

channel2_fx:
	.dw sound_driver_channel2_fx_0xy, sound_driver_channel2_fx_1xx, sound_driver_channel2_fx_2xx, sound_driver_channel2_fx_3xx, sound_driver_channel2_fx_4xy
	.dw sound_driver_channel2_fx_7xy, sound_driver_channel2_fx_Axy, sound_driver_channel2_fx_Bxx, sound_driver_channel2_fx_Cxx, sound_driver_channel2_fx_Dxx
	.dw sound_driver_channel2_fx_Exx, sound_driver_channel2_fx_Fxx, sound_driver_channel2_fx_Gxx, sound_driver_channel2_fx_Hxy, sound_driver_channel2_fx_Ixy
	.dw sound_driver_channel2_fx_Hxx, sound_driver_channel2_fx_Ixx, sound_driver_channel2_fx_Pxx, sound_driver_channel2_fx_Qxy, sound_driver_channel2_fx_Rxy
	.dw sound_driver_channel2_fx_Sxx, sound_driver_channel2_fx_Vxx, sound_driver_channel2_fx_Wxx, sound_driver_channel2_fx_Xxx, sound_driver_channel2_fx_Yxx
	.dw sound_driver_channel2_fx_Zxx

channel3_fx:
	.dw sound_driver_channel3_fx_0xy, sound_driver_channel3_fx_1xx, sound_driver_channel3_fx_2xx, sound_driver_channel3_fx_3xx, sound_driver_channel3_fx_4xy
	.dw sound_driver_channel3_fx_7xy, sound_driver_channel3_fx_Axy, sound_driver_channel3_fx_Bxx, sound_driver_channel3_fx_Cxx, sound_driver_channel3_fx_Dxx
	.dw sound_driver_channel3_fx_Exx, sound_driver_channel3_fx_Fxx, sound_driver_channel3_fx_Gxx, sound_driver_channel3_fx_Hxy, sound_driver_channel3_fx_Ixy
	.dw sound_driver_channel3_fx_Hxx, sound_driver_channel3_fx_Ixx, sound_driver_channel3_fx_Pxx, sound_driver_channel3_fx_Qxy, sound_driver_channel3_fx_Rxy
	.dw sound_driver_channel3_fx_Sxx, sound_driver_channel3_fx_Vxx, sound_driver_channel3_fx_Wxx, sound_driver_channel3_fx_Xxx, sound_driver_channel3_fx_Yxx
	.dw sound_driver_channel3_fx_Zxx

//famitracker volumes table: http://famitracker.com/wiki/index.php?title=Volume
volumes:
	.db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.db 0x00, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01
	.db 0x00, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x02
	.db 0x00, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x02, 0x02, 0x02, 0x02, 0x02, 0x03
	.db 0x00, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x02, 0x02, 0x02, 0x02, 0x03, 0x03, 0x03, 0x04
	.db 0x00, 0x01, 0x01, 0x01, 0x01, 0x01, 0x02, 0x02, 0x02, 0x03, 0x03, 0x03, 0x04, 0x04, 0x04, 0x05
	.db 0x00, 0x01, 0x01, 0x01, 0x01, 0x02, 0x02, 0x02, 0x03, 0x03, 0x04, 0x04, 0x04, 0x05, 0x05, 0x06
	.db 0x00, 0x01, 0x01, 0x01, 0x01, 0x02, 0x02, 0x03, 0x03, 0x04, 0x04, 0x05, 0x05, 0x06, 0x06, 0x07
	.db 0x00, 0x01, 0x01, 0x01, 0x02, 0x02, 0x03, 0x03, 0x04, 0x04, 0x05, 0x05, 0x06, 0x06, 0x07, 0x08
	.db 0x00, 0x01, 0x01, 0x01, 0x02, 0x03, 0x03, 0x04, 0x04, 0x05, 0x06, 0x06, 0x07, 0x07, 0x08, 0x09
	.db 0x00, 0x01, 0x01, 0x02, 0x02, 0x03, 0x04, 0x04, 0x05, 0x06, 0x06, 0x07, 0x08, 0x08, 0x09, 0x0A
	.db 0x00, 0x01, 0x01, 0x02, 0x02, 0x03, 0x04, 0x05, 0x05, 0x06, 0x07, 0x08, 0x08, 0x09, 0x0A, 0x0B
	.db 0x00, 0x01, 0x01, 0x02, 0x03, 0x04, 0x04, 0x05, 0x06, 0x07, 0x08, 0x08, 0x09, 0x0A, 0x0B, 0x0C
	.db 0x00, 0x01, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x06, 0x07, 0x08, 0x09, 0x0A, 0x0B, 0x0C, 0x0D
	.db 0x00, 0x01, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0A, 0x0B, 0x0C, 0x0D, 0x0E
	.db 0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0A, 0x0B, 0x0C, 0x0D, 0x0E, 0x0F
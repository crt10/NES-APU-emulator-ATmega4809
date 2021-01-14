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
pulse1_length: .byte 1 //$4002 000l.llll = Length counter load
pulse1_fractional_volume: .byte 1 //used with the Axy effect to calculate volume. represents the VVVV bits in $4000, but with fractional data in bits 0 to 3.
pulse1_output_volume: .byte 1 //this is the final output volume of pulse 1
pulse1_note: .byte 1 //the current note index in the note table

song_frames: .byte 2
song_frame_offset: .byte 2
song_size: .byte 2
song_speed: .byte 1
song_fx_Bxx: .byte 1
song_fx_Cxx: .byte 1
song_fx_Dxx: .byte 1


pulse1_pattern: .byte 2
pulse1_pattern_delay: .byte 2
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

pulse1_total_pitch_offset: .byte 1 //used to reference the overall change in pitch for the pitch macro
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
pulse1_fx_Pxx: .byte 1 //refers to the fine pitch offset set by the Pxx effect
pulse1_fx_Qxy_target: .byte 2 //target note period
pulse1_fx_Qxy_speed: .byte 2 //the amount to offset by to get to the target
pulse1_fx_Qxy_total_offset: .byte 2 //NOTE: due to the way the sound driver is setup, we need to keep track of the total pitch offset
pulse1_fx_Rxy_target: .byte 2 //target note period
pulse1_fx_Rxy_speed: .byte 2 //the amount to offset by to get to the target
pulse1_fx_Rxy_total_offset: .byte 2
pulse1_fx_Sxx_pre: .byte 1 //NOTE: Gxx and Sxx can not both be in effect at the same time. Sxx has priority.
pulse1_fx_Sxx_post: .byte 1

pulse2_pattern_delay: .byte 1
triangle_pattern_delay: .byte 1
noise_pattern_delay: .byte 1
dcpm_pattern_delay: .byte 1

.cseg

//NOTE: zero is defined in order to use the cp instruction without the need to load 0x00 into a register beforehand
.def zero = r2
.def channel_flags = r25 //[pulse1.pulse2] RSlc.0000 = Reload, Start, Length halt/Loop, Constant volume
.def pulse1_sequence = r13
.def pulse1_length_counter = r14
.def pulse1_sweep = r15 //NSSS.EPPP = Negate sweep flag, Shift, Enable sweep flag, Period divider
.def pulse1_volume_divider = r16 //0000.PPPP = Period divider
.def pulse1_volume_decay = r17 //0000.dddd = Decay

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

.nolist
.include "song_data.asm"
.list

init:
	//MAIN CLOCK
	ldi r27, CPU_CCP_IOREG_gc //protected write
	sts CPU_CCP, r27
	ldi r27, 0 << CLKCTRL_PEN_bp //disable prescaler for 20 MHz on main clock
	sts CLKCTRL_MCLKCTRLB, r27

/*	//TEST FOR C4, 1 SECOND, 50% DD
	ldi r26, 0x97
	ldi r27, 0x12
	ldi r26, 0x15
	ldi r27, 0x09
	sts pulse1_timerL, r26
	sts pulse1_timerH, r27
	ldi r27, 0b10111111
	sts pulse1_param, r27
	ldi r27, 0x01
	sts pulse1_length, r27
	//TEST FOR SWEEP UP
	ldi r27, 0b11111111
	sts pulse1_sweep_param, r27*/

	//ZERO
	clr zero

	//MEMORY
	ldi r27, 0b00110000
	sts pulse1_param, r27
	ldi r27, 0b10000000
	sts pulse1_sweep_param, r27
	ldi r27, 0xFF
	sts pulse1_timerL, r27
	sts pulse1_timerH, r27
	sts pulse1_length, r27

	ldi r27, 0x02
	sts song_frame_offset, r27
	sts song_frame_offset+1, zero
	ldi ZL, LOW(song0_frames << 1)
	ldi ZH, HIGH(song0_frames << 1)
	sts song_frames, ZL
	sts song_frames+1, ZH
	lpm r28, Z+ //load the song size
	lpm r29, Z+
	sts song_size, r28
	sts song_size+1, r29
	sts song_speed, zero

	//CHANNEL 0 TEST
	lpm r26, Z+
	lpm r27, Z
	lsl r26
	rol r27
	sts pulse1_pattern, r26
	sts pulse1_pattern+1, r27
	ldi r27, 0x00
	sts pulse1_pattern_delay, zero
	sts pulse1_pattern_delay+1, zero
	sts pulse1_pattern_offset, zero
	sts pulse1_pattern_offset+1, zero

	//channel 0 instrument macros
	ldi r27, 0xFF
	sts pulse1_volume_macro_offset, zero
	sts pulse1_volume_macro_loop, r27
	sts pulse1_volume_macro_release, r27
	sts pulse1_arpeggio_macro_offset, zero
	sts pulse1_arpeggio_macro_loop, r27
	sts pulse1_arpeggio_macro_release, r27
	sts pulse1_arpeggio_macro_mode, r27
	sts pulse1_pitch_macro_offset, zero
	sts pulse1_pitch_macro_loop, r27
	sts pulse1_pitch_macro_release, r27
	sts pulse1_hi_pitch_macro_offset, zero
	sts pulse1_hi_pitch_macro_loop, r27
	sts pulse1_hi_pitch_macro_release, r27
	sts pulse1_duty_macro_offset, zero
	sts pulse1_duty_macro_loop, r27
	sts pulse1_duty_macro_release, r27

	sts pulse1_volume_macro, zero
	sts pulse1_volume_macro+1, zero
	sts pulse1_arpeggio_macro, zero
	sts pulse1_arpeggio_macro+1, zero
	sts pulse1_total_pitch_offset, zero
	sts pulse1_pitch_macro, zero
	sts pulse1_pitch_macro+1, zero
	sts pulse1_total_hi_pitch_offset, zero
	sts pulse1_hi_pitch_macro, zero
	sts pulse1_hi_pitch_macro+1, zero
	sts pulse1_duty_macro, zero
	sts pulse1_duty_macro+1, zero

	sts pulse2_pattern_delay, zero
	sts triangle_pattern_delay, zero
	sts noise_pattern_delay, zero
	sts dcpm_pattern_delay, zero

	//PINS
	ldi r27, 0xFF //set all pins in VPORTD to output
	out VPORTA_DIR, r27

	//ENVELOPE
	ldi pulse1_volume_divider, 0x0F
	lds pulse1_volume_decay, pulse1_param
	andi pulse1_volume_decay, 0x0F //mask for VVVV bits
	lds channel_flags, pulse1_param
	andi channel_flags, 0b00110000
	sbr channel_flags, 0b01000000 //set start flag
	sts pulse1_output_volume, zero
	sts pulse1_fractional_volume, r27 //initialize fractional volume to max value
	
	//LENGTH
	lds r29, pulse1_length
	rcall length_converter
	mov pulse1_length_counter, r29

	//SEQUENCE
	lds r29, pulse1_param //load param for sequence table
	ldi r29, 0b00000001 //12.5% is the default duty cycle sequence
	mov pulse1_sequence, r29

	//SWEEP
	lds pulse1_sweep, pulse1_sweep_param
	swap pulse1_sweep //swap data from high byte and low byte
	sbr channel_flags, 0b10000000 //set reload flag

	//FX
	ldi r29, 0xFF
	sts song_fx_Bxx, r29
	sts song_fx_Cxx, zero
	sts song_fx_Dxx, zero
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
	sts pulse1_fx_Gxx_pre, zero
	sts pulse1_fx_Gxx_post, zero
	sts pulse1_fx_Pxx, zero
	sts pulse1_fx_Qxy_target, zero
	sts pulse1_fx_Qxy_target+1, zero
	sts pulse1_fx_Qxy_speed, zero
	sts pulse1_fx_Qxy_speed+1, zero
	sts pulse1_fx_Qxy_total_offset, zero
	sts pulse1_fx_Qxy_total_offset+1, zero
	sts pulse1_fx_Rxy_target, zero
	sts pulse1_fx_Rxy_target+1, zero
	sts pulse1_fx_Rxy_speed, zero
	sts pulse1_fx_Rxy_speed+1, zero
	sts pulse1_fx_Rxy_total_offset, zero
	sts pulse1_fx_Rxy_total_offset+1, zero
	sts pulse1_fx_Sxx_pre, zero
	sts pulse1_fx_Sxx_post, zero

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
	ldi r27, TCA_SINGLE_CMP0EN_bm | TCA_SINGLE_CMP1EN_bm | TCA_SINGLE_CMP2EN_bm | TCA_SINGLE_WGMODE_NORMAL_gc //interrupt mode
	sts TCA0_SINGLE_CTRLB, r27
	ldi r27, TCA_SINGLE_CMP0_bm | TCA_SINGLE_CMP1_bm | TCA_SINGLE_CMP2_bm | TCA_SINGLE_OVF_bm //enable overflow and compare interrupts
	sts TCA0_SINGLE_INTCTRL, r27
	ldi r27, 0x15 //set the period for CMP0
	sts TCA0_SINGLE_CMP0, r27
	ldi r27, 0x05
	sts TCA0_SINGLE_CMP0 + 1, r27
	ldi r27, 0x2B //set the period for CMP1
	sts TCA0_SINGLE_CMP1, r27
	ldi r27, 0x0A
	sts TCA0_SINGLE_CMP1 + 1, r27
	ldi r27, 0x41 //set the period for CMP2
	sts TCA0_SINGLE_CMP2, r27
	ldi r27, 0x0F
	sts TCA0_SINGLE_CMP2 + 1, r27
	ldi r27, 0x57 //set the period for OVF
	sts TCA0_SINGLE_PER, r27
	ldi r27, 0x14
	sts TCA0_SINGLE_PER + 1, r27
	ldi r27, TCA_SINGLE_CLKSEL_DIV64_gc | TCA_SINGLE_ENABLE_bm //use prescale divider of 64 and enable timer
	sts TCA0_SINGLE_CTRLA, r27

	//NOTE: Channel Timers are clocked (20/2)/(0.8948865) = 11.1746014718 times faster than the NES APU
	//Because of this, we multiply all the NES timer values by 11.1746014718 beforehand
	//Since we rotate the sequence when the timer goes from t-(t-1) to 0, instead of 0 to t like the NES, we add 1 to the NES timers before multiplying
	//The ATmega4809 is configured to run at 20 MHz
	//The /2 comes from the prescaler divider used
	//0.8948865 MHz is the speed of the NTSC NES APU
	//NOTE: This means that any offset to the pitch for the NES timers would be multiplied by 11.1746014718 aswell.
	//Pulse 1
	ldi r27, TCB_CNTMODE_INT_gc //interrupt mode
	sts TCB0_CTRLB, r27
	ldi r27, TCB_CAPT_bm //enable interrupts
	sts TCB0_INTCTRL, r27
	lds r27, pulse1_timerL //load the LOW bits for timer
	sts TCB0_CCMPL, r27
	lds r27, pulse1_timerH //load the HIGH bits for timer
	sts TCB0_CCMPH, r27
	ldi r27, TCB_CLKSEL_CLKDIV2_gc | TCB_ENABLE_bm //use prescaler divider of 2 and enable timer
	sts TCB0_CTRLA, r27
	sei //global interrupt enable

pulse1:
	sbrs pulse1_sequence, 0 //if the sequence output is zero, return
	rjmp pulse1_off

	cp pulse1_length_counter, zero //if length is zero, return
	breq pulse1_off

	//NOTE: We will just mute the pulse when the current period is < $0008
	//This is done in order to account for the sweep unit muting the channel when the period is < $0008,
	//Due to the 11.1746014718 timer multiplier being applied to the timer periods, $0008 becomes $0059
	lds r28, TCB0_CCMPL
	ldi r29, 0x059
	cp r28, r29
	lds r28, TCB0_CCMPH
	ldi r29, 0x00
	cpc r28, r29
	brlo pulse1_off

	//NOTE: Since it'd be too taxing to calculate a target period for every APU clock in the sweep unit,
	//we will be muting the channel if it's period ever reaches $07FF, aka the target period was == $07FF
	//Doing this does not account for the real NES "feature" of muting the pulse even if the sweep unit was disabled.
	//Due to the 11.1746014718 timer multiplier being applied to the timer periods, $07FF becomes $5965
	lds r28, TCB0_CCMPL
	ldi r29, 0x66
	cp r28, r29
	lds r28, TCB0_CCMPH
	ldi r29, 0x59
	cpc r28, r29
	brsh pulse1_off
	rjmp pulse1_on //if the HIGH period == $59 && LOW period < $65, pulse on

pulse1_off:
	out VPORTA_OUT, zero
	rjmp pulse1

pulse1_on:
	lds r29, pulse1_output_volume
/*	cpse r29, zero
	rjmp pulse1_off //if VVVV bits are 0, then there is no volume (channel off)*/

	out VPORTA_OUT, r29
	rjmp pulse1

//FRAME COUNTER/AUDIO SAMPLE ISR
sequence_0_2:
	in r27, CPU_SREG
	push r27
	cli

	//ENVELOPE
	rcall pulse1_envelope_routine

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

	//SWEEP
	sbrc pulse1_sweep, 3 //check if the sweep enable bit is cleared
	rcall pulse1_sweep_routine

	//LENGTH
	//NOTE: The length routine is relatively simple, so we will not be using clocks to rjmp and ret to a seperate lable
	sbrc channel_flags, 5 //check if the length counter halt bit is cleared
	rjmp sequence_1_3_exit
	cpse pulse1_length_counter, zero //if length counter is already 0, don't decrement
	dec pulse1_length_counter

sequence_1_3_exit:
	ldi r27, TCA_SINGLE_CMP1_bm | TCA_SINGLE_OVF_bm //clear OVF flag
	sts TCA0_SINGLE_INTFLAGS, r27
	pop r27
	out CPU_SREG, r27
	reti

sound_driver:
	in r27, CPU_SREG
	push r27
	cli
	push r28
	push r29

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
	lpm r27, Z
	lsl r26
	rol r27
	sts pulse1_pattern, r26
	sts pulse1_pattern+1, r27

	sts pulse1_pattern_offset, zero //restart the pattern offset back to 0 because we are reading from a new pattern now
	sts pulse1_pattern_offset+1, zero
	sts pulse1_pattern_delay, zero //reset the delay to 0 as well
	sts pulse1_pattern_delay+1, zero

	ldi r26, 0xFF
	sts song_fx_Bxx, r26 //reset all song effects
	sts song_fx_Cxx, zero
	sts song_fx_Dxx, zero
	rjmp sound_driver_channel0

sound_driver_fx_Cxx_routine:
	pop r29
	pop r28
	pop r27
	out CPU_SREG, r27
	cli //disable global interrupts
		
	ldi r26, 0xFF
	sts song_fx_Bxx, r26 //reset all song effects
	sts song_fx_Cxx, zero
	sts song_fx_Dxx, zero

	sts pulse1_output_volume, zero //mute all channels
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
	lpm r27, Z
	lsl r26
	rol r27
	sts pulse1_pattern, r26
	sts pulse1_pattern+1, r27

	sts pulse1_pattern_offset, zero //restart the pattern offset back to 0 because we are reading from a new pattern now
	sts pulse1_pattern_offset+1, zero
	sts pulse1_pattern_delay, zero //reset the delay to 0 as well
	sts pulse1_pattern_delay+1, zero

	ldi r26, 0xFF
	sts song_fx_Bxx, r26 //reset all song effects
	sts song_fx_Cxx, zero
	sts song_fx_Dxx, zero
	rjmp sound_driver_channel0



sound_driver_channel0:
	lds r26, pulse1_pattern_delay
	lds r27, pulse1_pattern_delay+1
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
	ldi ZL, LOW(fx << 1) //load in note table
	ldi ZH, HIGH(fx << 1)
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
	sbr channel_flags, 6
	rjmp sound_driver_channel0_main

//SPEED AND TEMPO
sound_driver_channel0_fx_Fxx:
	sts song_speed, r26 //NOTE: only changes to speed are supported
	rjmp sound_driver_channel0_main

//DELAY
sound_driver_channel0_fx_Gxx:
	sts pulse1_fx_Gxx_pre, r26 //NOTE: to be processed in the sound driver delay routine
	rjmp sound_driver_channel0_main

sound_driver_channel0_fx_Hxy: //hardware sweep up
	swap r26
	ori r26, 0b10001000 //enable negate and enable sweep flag
	mov pulse1_sweep, r26
	sts pulse1_sweep_param, pulse1_sweep
	sbr channel_flags, 7 //set reload flag
	rjmp sound_driver_channel0_main

sound_driver_channel0_fx_Ixy: //hardware sweep down
	swap r26
	andi r26, 0b01111111 //disable negate flag
	ori r26, 0b00001000 //enable sweep flag
	mov pulse1_sweep, r26
	sts pulse1_sweep_param, pulse1_sweep
	sbr channel_flags, 7 //set reload flag
	rjmp sound_driver_channel0_main

sound_driver_channel0_fx_Hxx: //FDS modulation depth
	rjmp sound_driver_channel0_main
sound_driver_channel0_fx_Ixx: //FDS modulation speed
	rjmp sound_driver_channel0_main

//FINE PITCH
sound_driver_channel0_fx_Pxx:
	sts pulse1_fx_Pxx, r26
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
	lds r28, pulse1_note //load current note index
	add r27, r28
	cpi r27, 0x57 //largest possible note index is 0x56
	brlo sound_driver_channel0_fx_Qxy_process_continue
	ldi r27, 0x56 //if the target note was larger than the highest possible note index, keep the target at 0x56

sound_driver_channel0_fx_Qxy_process_continue:
	ldi ZL, LOW(note_table << 1) //load in note table
	ldi ZH, HIGH(note_table << 1)
	lsl r27 //double the offset for the note table because we are getting byte data
	add ZL, r27 //add offset
	adc ZH, zero
	lpm r28, Z+ //load bytes
	lpm r29, Z
	sts pulse1_fx_Qxy_target, r28 //load the LOW bits for the target period
	sts pulse1_fx_Qxy_target+1, r29 //load the HIGH bits for the target period

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
	sts pulse1_fx_Qxy_total_offset, zero
	sts pulse1_fx_Qxy_total_offset+1, zero
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
	lds r28, pulse1_note //load current note index
	sub r28, r27
	brcc sound_driver_channel0_fx_Rxy_process_continue
	ldi r28, 0x00

sound_driver_channel0_fx_Rxy_process_continue:
	ldi ZL, LOW(note_table << 1) //load in note table
	ldi ZH, HIGH(note_table << 1)
	lsl r28 //double the offset for the note table because we are getting byte data
	add ZL, r28 //add offset
	adc ZH, zero
	lpm r28, Z+ //load bytes
	lpm r29, Z
	sts pulse1_fx_Rxy_target, r28 //load the LOW bits for the target period
	sts pulse1_fx_Rxy_target+1, r29 //load the HIGH bits for the target period

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
	sts pulse1_fx_Rxy_total_offset, zero
	sts pulse1_fx_Rxy_total_offset+1, zero
	rjmp sound_driver_channel0_main

//MUTE DELAY
sound_driver_channel0_fx_Sxx:
	sts pulse1_fx_Sxx_pre, r26
	rjmp sound_driver_channel0_main

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
	ldi r26, 0x03
	ldi r27, 0x02
	sts pulse1_volume_macro_offset, r27 //reset all macro offsets
	sts pulse1_arpeggio_macro_offset, r26
	sts pulse1_pitch_macro_offset, r27
	sts pulse1_hi_pitch_macro_offset, r27
	sts pulse1_duty_macro_offset, r27
	sts pulse1_total_pitch_offset, zero //reset the pitch and hi pitch offset
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
	sbr channel_flags, 7 //set reload flag
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
	sbr channel_flags, 6
	rcall sound_driver_channel0_increment_offset
	rjmp sound_driver_channel0_main



sound_driver_channel0_delay:
	subi r27, 0x67 //NOTE: the delay values are offset by the highest volume value, which is 0x66
	sts pulse1_pattern_delay, r27
	rcall sound_driver_channel0_increment_offset
	rjmp sound_driver_calculate_delays



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
	//adiw r27:r26, 2 //offset for channel 1 (test)
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



sound_driver_calculate_delays:
	push r22
	push r23
	lds r22, song_speed
	mov r26, r22
	subi r26, 1
	mov r29, r26

sound_driver_calculate_delays_pulse1:
sound_driver_calculate_delays_pulse1_Sxx:
	lds r27, pulse1_fx_Sxx_pre
	lds r28, pulse1_fx_Sxx_post
 	sts pulse1_fx_Sxx_pre, zero
	cp r27, zero
	breq sound_driver_calculate_delays_pulse1_Sxx_post
	cp r27, r22 //compare the Gxx fx to the song speed
	brsh sound_driver_calculate_delays_pulse1_Sxx_post
	sts pulse1_pattern_delay, r27
	sts pulse1_pattern_delay+1, zero
	sub r29, r27 //(song speed)-1-Sxx
	sts pulse1_fx_Sxx_post, r29
	rjmp sound_driver_calculate_delays_pulse2

sound_driver_calculate_delays_pulse1_Sxx_post:
	cp r28, zero
	breq sound_driver_calculate_delays_pulse1_Gxx
	sts pulse1_fx_Sxx_post, zero
	mov r26, r28
	rjmp sound_driver_calculate_delays_pulse1_main

sound_driver_calculate_delays_pulse1_Gxx:
	lds r27, pulse1_fx_Gxx_pre
	lds r28, pulse1_fx_Gxx_post
	cp r27, r22 //compare the Gxx fx to the song speed
	brlo sound_driver_calculate_delays_pulse1_Gxx_post
	ldi r27, 0 //if the Gxx effect exceeds one row (the song speed), then reset the effect to 0
	sts pulse1_fx_Gxx_pre, zero

sound_driver_calculate_delays_pulse1_Gxx_post:
	cp r28, zero
	breq sound_driver_calculate_delays_pulse1_main
	mov r26, r28 //if there was a Gxx, use its post instead of the (song speed)-1
	
sound_driver_calculate_delays_pulse1_main:
	lds r23, pulse1_pattern_delay
	mul r22, r23
	add r0, r26
	adc r1, zero
	add r0, r27
	adc r1, zero
	sts pulse1_pattern_delay, r0
	sts pulse1_pattern_delay+1, r1
	sts pulse1_fx_Gxx_post, zero

sound_driver_calculate_delays_pulse1_Gxx_pre:
	cp r27, zero //check if the Gxx effect was enabled
	breq sound_driver_calculate_delays_pulse2
	sub r29, r27 //(song speed)-1-Gxx
	sts pulse1_fx_Gxx_post, r26
	sts pulse1_fx_Gxx_pre, zero

sound_driver_calculate_delays_pulse2:
sound_driver_calculate_delays_pulse2_Gxx:
	pop r23
	pop r22
	rjmp sound_driver_instrument_routine



sound_driver_channel0_decrement_frame_delay:
	subi r26, 1
	sbc r27, zero
	sts pulse1_pattern_delay, r26
	sts pulse1_pattern_delay+1, r27



sound_driver_instrument_routine:
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
	ldi r27, 0x01 //if the subtraction resulted in a negative volume, cap it to 0x01

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
	brne sound_driver_instrument_routine_channel0_arpeggio_default_xy //if 0xy effect exists, and there is no release/loop, use the default routine and apply the 0xy effect

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
	
//NOTE: because of the way the xy parameter is stored and processed, using x0 will not create a faster arpeggio
sound_driver_instrument_routine_channel0_arpeggio_default_xy:
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



//NOTE: There is a limitation with the pitch routines in that the total pitch can not be offset by 127 in both,
//the positive and negative direction, from the original note pitch. This shouldn't be too much of a problem as
//most songs that use instruments with the pitch macro, do not stray that far from the original note pitch.
//In the case of hi pitch, the total pitch can not be offset by 127*16 from the original pitch. This is also
//not a big deal as you can easily reach the entire note range with an offset of up to 127*16.
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
	lds r27, pulse1_total_pitch_offset
	rjmp sound_driver_instrument_routine_channel0_pitch_calculate_multiply

sound_driver_instrument_routine_channel0_pitch_calculate:
	lds r26, pulse1_total_pitch_offset //load the total pitch offset to change
	add r27, r26
	sts pulse1_total_pitch_offset, r27

sound_driver_instrument_routine_channel0_pitch_calculate_multiply:
	//NOTE: The Pxx effect is processed with the pitch instrument macro because the calculations are the same
	lds r26, pulse1_fx_Pxx
	add r27, r26

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
	sbrs r1, 3 //check if result was a negative number
	rjmp sound_driver_instrument_routine_channel0_pitch_calculate_offset //if the result was positive, don't fill with 1s

sound_driver_instrument_routine_channel0_pitch_calculate_negative:
	ldi r27, 0xF0
	or r1, r27 //when right shifting a two's complement number, must use 1s instead of 0s to fill

sound_driver_instrument_routine_channel0_pitch_calculate_offset:
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
	lds r28, pulse1_fx_Qxy_total_offset //NOTE: Qxy and Rxy offsets are applied here
	lds r29, pulse1_fx_Qxy_total_offset+1
	sub r26, r28
	sbc r27, r29
	lds r28, pulse1_fx_Rxy_total_offset
	lds r29, pulse1_fx_Rxy_total_offset+1
	add r26, r28
	adc r27, r29

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
	cpi r28, 0x64 //check if the phase overflowed NOTE: phase values range from 0-63
	brlo sound_driver_channel0_fx_4xy_routine_phase //if no overflow, map the phase to 0-15.
	subi r28, 0x63 //if there was overflow, re-adjust the phase

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
	cpi r28, 0x64 //check if the phase overflowed NOTE: phase values range from 0-63
	brlo sound_driver_channel0_fx_7xy_routine_phase //if no overflow, map the phase to 0-15.
	ldi r28, 0x00
	subi r28, 0x63 //if there was overflow, re-adjust the phase

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
	sub r28, r26 //subtract the timer period by the total offset
	sbc r29, r27

	cp r28, ZL //compare the new timer period with the target
	cpc r29, ZH
	brlo sound_driver_channel0_fx_Qxy_routine_end //if the target has been reached (or passed)
	breq sound_driver_channel0_fx_Qxy_routine_end
	brsh sound_driver_channel0_fx_Qxy_routine_add

sound_driver_channel0_fx_Qxy_routine_end:
	sub ZL, r28 //calculate the difference to the target
	sbc ZH, r29
	add r26, ZL //increase the total offset to the exact amount needed to reach the target
	adc r27, ZH
	sts pulse1_fx_Qxy_total_offset, r26 //store the total offset
	sts pulse1_fx_Qxy_total_offset+1, r27
	sts pulse1_fx_Qxy_target, zero //loading the target with 0 stops any further calculations
	sts pulse1_fx_Qxy_target+1, zero
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
	breq sound_driver_channel0_fx_xy_routine //if the effect is not enabled, skip the routine

	lds r26, pulse1_fx_Rxy_total_offset
	lds r27, pulse1_fx_Rxy_total_offset+1
	lds r28, TCB0_CCMPL
	lds r29, TCB0_CCMPH
	add r28, r26 //add the total offset to the timer period
	add r29, r27

	cp r28, ZL //compare the new timer period with the target
	cpc r29, ZH
	brlo sound_driver_channel0_fx_Rxy_routine_end //if the target has been reached (or passed)
	breq sound_driver_channel0_fx_Rxy_routine_end
	brsh sound_driver_channel0_fx_Rxy_routine_add

sound_driver_channel0_fx_Rxy_routine_end:
	sub ZL, r28 //calculate the difference to the target
	sbc ZH, r29
	add r26, ZL //increase the total offset to the exact amount needed to reach the target
	adc r27, ZH
	sts pulse1_fx_Rxy_total_offset, r26 //store the total offset
	sts pulse1_fx_Rxy_total_offset+1, r27
	sts pulse1_fx_Rxy_target, zero //loading the target with 0 stops any further calculations
	sts pulse1_fx_Rxy_target+1, zero
	rjmp sound_driver_channel0_fx_xy_routine

sound_driver_channel0_fx_Rxy_routine_add:
	lds r28, pulse1_fx_Rxy_speed
	lds r29, pulse1_fx_Rxy_speed+1
	add r26, r28 //increase the total offset by the speed
	adc r27, r29
	sts pulse1_fx_Rxy_total_offset, r26 //store the total offset
	sts pulse1_fx_Rxy_total_offset+1, r27


sound_driver_channel0_fx_xy_routine:

sound_driver_exit:
	pop r29
	pop r28
	rjmp sequence_1_3 + 3 //+3 is to skip the stack instructions since we already pushed them

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

	//sts pulse1_timerL, r26
	//sts pulse1_timerH, r27

/*	//Sweep Test
	mov r29, pulse1_sweep //invert the negate bit
	ldi r27, 0b10000000
	eor r29, r27
	ori r29, 0b01111111

	lds r27, pulse1_sweep_param //reload the pulse sweep divider params
	swap r27
	ori r27, 0b10000000
	and r27, r29
	mov pulse1_sweep, r27
	sbr channel_flags, 0b10000000*/
	
	pop r29
	rjmp pulse1_sweep_routine_check_reload

pulse1_sweep_routine_decrement_divider:
	dec pulse1_sweep //if the divider != 0, decrement the divider

pulse1_sweep_routine_check_reload:
	sbrs channel_flags, 7 //if the reload flag is set, reload the sweep divider
	ret

pulse1_sweep_reload:
	lds pulse1_sweep, pulse1_sweep_param //NOTE: since the reload flag is kept in bit 6, we clear the reload flag indirectly
	swap pulse1_sweep //bring data from high byte to low byte
	cbr channel_flags, 0b10000000 //clear reload flag
	ret

pulse1_envelope_routine:
	sbrc channel_flags, 6 //check if start flag is cleared
	rjmp pulse1_envelope_routine_clear_start

	cpi pulse1_volume_divider, 0x00 //check if the divider is 0
	breq PC+3 //if the divider == 0, check loop flag
	dec pulse1_volume_divider //if the divider != 0, decrement and return
	ret

	lds pulse1_volume_divider, pulse1_param //if the divider == 0, reset the divider period
	andi pulse1_volume_divider, 0x0F //mask for VVVV bits
	sbrs channel_flags, 5 //check if the loop flag is set
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
	cbr channel_flags, 0b01000000 //if the start flag is set, clear it
	lds pulse1_volume_divider, pulse1_param //if the start flag is set, reset the divider period
	andi pulse1_volume_divider, 0x0F //mask for VVVV bits
	ldi pulse1_volume_decay, 0x0F //if the start flag is set, reset decay
	ret

//CONVERTERS (TABLES)
//converts and loads 5 bit length to corresponding 8 bit length value into r29
length_converter:
	ldi ZL, LOW(length << 1)
	ldi ZH, HIGH(length << 1)
	add ZL, r29
	adc ZH, zero
	lpm r29, Z
	ret

length: .db $05, $7F, $0A, $01, $14, $02, $28, $03, $50, $04, $1E, $05, $07, $06, $0D, $07, $06, $08, $0C, $09, $18, $0A, $30, $0B, $60, $0C, $24, $0D, $08, $0E, $10, $0F

//loads pulse sequence into r29
duty_cycle_sequences:
	ldi ZL, LOW(sequences << 1)
	ldi ZH, HIGH(sequences << 1)
	add ZL, r29
	adc ZH, zero
	lpm r29, Z
	ret

//pulse sequences: 12.5%, 25%, 50%, 75%
sequences: .db 0b00000001, 0b00000011, 0b00001111, 0b11111100

//list of famitracker fx: http://famitracker.com/wiki/index.php?title=Effect_list
fx:
	.dw sound_driver_channel0_fx_0xy, sound_driver_channel0_fx_1xx, sound_driver_channel0_fx_2xx, sound_driver_channel0_fx_3xx, sound_driver_channel0_fx_4xy
	.dw sound_driver_channel0_fx_7xy, sound_driver_channel0_fx_Axy, sound_driver_channel0_fx_Bxx, sound_driver_channel0_fx_Cxx, sound_driver_channel0_fx_Dxx
	.dw sound_driver_channel0_fx_Exx, sound_driver_channel0_fx_Fxx, sound_driver_channel0_fx_Gxx, sound_driver_channel0_fx_Hxy, sound_driver_channel0_fx_Ixy
	.dw sound_driver_channel0_fx_Hxx, sound_driver_channel0_fx_Ixx, sound_driver_channel0_fx_Pxx, sound_driver_channel0_fx_Qxy, sound_driver_channel0_fx_Rxy
	.dw sound_driver_channel0_fx_Sxx, sound_driver_channel0_fx_Vxx, sound_driver_channel0_fx_Wxx, sound_driver_channel0_fx_Xxx, sound_driver_channel0_fx_Yxx
	.dw sound_driver_channel0_fx_Zxx

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
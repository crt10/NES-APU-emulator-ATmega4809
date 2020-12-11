;
; NES_APU_2a03.asm
;
; Created: 11/29/2020 1:44:10 AM
; Author : Tennyson Cheng
;

.dseg
pulse1_param: .byte 1 //$4000 DDlc.vvvv = Duty cycle, Length counter halt/Loop flag, Constant volume flag, Volume
pulse1_sweep_param: .byte 1 //$4001 EPPP.NSSS = Enable, Period, Negate, Shift
//NOTE: In order to account for multiplier, we use 16 instead of 11 bits for the timer
pulse1_timerL: .byte 1 //$4002 LLLL.LLLL = Low 8 bits for timer
pulse1_timerH: .byte 1 //$4002 HHHH.HHHH = High 8 bits for timer
pulse1_length: .byte 1 //$4002 000l.llll = Length counter load

.cseg
//NOTE: r30 and r31 are reserved for conversion routines, since lpm can only be used with the Z register
//r28 and r29 are reserved for non-interrupt routines
//r26 and r27 are reserved for interrupt routines, but interrupt routines may use r28 and r29
//If an interrupt uses r28 and r29, then they must be pushed and popped (this should be limited as much as possible)
//This was done in order to save clock cycles due to constantly pushing/popping registers
//NOTE: zero is defined in order to use the cp instruction without the need to load 0x00 into a register beforehand
.def zero = r0
.def channel_flags = r25 //[pulse1.pulse2] RSlc.0000 = Reload, Start, Length halt/Loop, Constant volume
.def pulse1_sequence = r13
.def pulse1_length_counter = r14
.def pulse1_sweep = r15 //NSSS.EPPP = Negate sweep flag, Shift, Enable sweep flag, Period divider
.def pulse1_volume_divider = r16 //0000.PPPP = Period divider
.def pulse1_volume_decay = r17 //0000.dddd = Decay (This is the output volume of the channel)

reset:
	jmp init

.org TCA0_OVF_vect
	jmp sequence_1_3

.org TCA0_CMP0_vect
	jmp sequence_0_2

.org TCA0_CMP1_vect
	jmp sequence_1_3

.org TCA0_CMP2_vect
	jmp sequence_0_2

.org TCB0_INT_vect
	jmp pulse1_sequence_routine

init:
	//MAIN CLOCK
	ldi r27, CPU_CCP_IOREG_gc //protected write
	sts CPU_CCP, r27
	ldi r27, 0 << CLKCTRL_PEN_bp //disable prescaler for 20 MHz on main clock
	sts CLKCTRL_MCLKCTRLB, r27

	//TEST FOR C4, 1 SECOND, 50% DD
	ldi r26, 0x97
	ldi r27, 0x12
/*	ldi r26, 0x15
	ldi r27, 0x09*/
	sts pulse1_timerL, r26
	sts pulse1_timerH, r27
	ldi r27, 0b10111111
	sts pulse1_param, r27
	ldi r27, 0x01
	sts pulse1_length, r27
	//TEST FOR SWEEP UP
	ldi r27, 0b11111111
	sts pulse1_sweep_param, r27
	
	//ZERO
	clr zero

	//PINS
	ldi r27, 0xFF //set all pins in VPORTD to output
	out VPORTD_DIR, r27

	//ENVELOPE
	ldi pulse1_volume_divider, 0x0F
	lds pulse1_volume_decay, pulse1_param
	andi pulse1_volume_decay, 0x0F //mask for VVVV bits
	lds channel_flags, pulse1_param
	andi channel_flags, 0b00110000
	sbr channel_flags, 0b01000000 //set start flag
	
	//LENGTH
	lds r29, pulse1_length
	rcall length_converter
	mov pulse1_length_counter, r29

	//SEQUENCE
	lds r29, pulse1_param //load param for sequence table
	lsl r29 //shift duty cycle bits to LSB
	rol r29
	rol r29
	andi r29, 0b00000011 //mask duty cycle bits
	rcall duty_cycle_sequences
	mov pulse1_sequence, r29

	//SWEEP
	lds pulse1_sweep, pulse1_sweep_param
	swap pulse1_sweep //swap data from high byte and low byte
	sbr channel_flags, 0b10000000 //set reload flag

	//TIMERS
	//Frame Counter
	//NOTE: The frame counter will be defaulted to NTSC mode (60 Hz, 120 Hz, 240 Hz)
	//Each interrupt will be setup to interrupt every 240 Hz clock
	//CMP0 = sequence 0, CMP1 = sequence 1, CMP2 = sequence 2, OVF = sequence 4
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
	ldi r27, 0x40 //set the period for CMP2
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
	lds r29, TCB0_CCMPH
	cpi r29, 0x01 //check timer HIGH period
	brlo PC+2 //if the timer HIGH period is $00, check the LOW period
	rjmp PC+3 //if the timer HIGH period is > $01, check > $07FF condition
	cpi r28, 0x59 //check timer LOW period
	brlo pulse1_off //if the HIGH period == $00 && LOW period <= $59, pulse off

	//NOTE: Since it'd be too taxing to calculate a target period for every APU clock in the sweep unit,
	//we will be muting the channel if it's period ever reaches $07FF, aka the target period was == $07FF
	//Doing this does not account for the real NES "feature" of muting the pulse even if the sweep unit was disabled.
	//Due to the 11.1746014718 timer multiplier being applied to the timer periods, $07FF becomes $5965
	cpi r29, 0x59 //check timer HIGH period
	brlo pulse1_on //if the HIGH period is < $59, then all conditions have passed and pulse is not muted
	breq PC+2 //if the HIGH period is == $59, we go check if the LOW period is < $65
	rjmp pulse1_off //pulse off if HIGH period is > $59
	cpi r28, 0x65 //check timer LOW period
	brsh pulse1_off //if the HIGH period == $59 && LOW period >= $65, pulse off
	rjmp pulse1_on //if the HIGH period == $59 && LOW period < $65, pulse on


pulse1_off:
	cbi VPORTD_OUT, 0
	rjmp pulse1

pulse1_on:
	sbi VPORTD_OUT, 0
	rjmp pulse1

//FRAME COUNTER ISR
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
	sbrc channel_flags, 5 //check if the length counter halt bit is cleared
	rjmp PC+4
	cp pulse1_length_counter, zero //check if the length counter is already 0
	breq PC+2 //if length counter is already 0, don't decrement
	dec pulse1_length_counter

	ldi r27, TCA_SINGLE_CMP1_bm | TCA_SINGLE_OVF_bm //clear OVF flag
	sts TCA0_SINGLE_INTFLAGS, r27
	pop r27
	out CPU_SREG, r27
	reti

//PULSE 1 ISR
pulse1_sequence_routine:
	in r27, CPU_SREG
	push r27
	cli

	lsl pulse1_sequence //shifts sequence to the left
	brcc PC+2 //if the shifted bit was a 1, move it to the LSB
	inc pulse1_sequence

	ldi r27, TCB_CAPT_bm //clear OVF flag
	sts TCB0_INTFLAGS, r27
	pop r27
	out CPU_SREG, r27
	reti

pulse1_sweep_routine:
	mov r27, pulse1_sweep
	andi r27, 0x07 //mask for period divider bits
	brne PC+3 //check if divider == 0

	rcall pulse1_sweep_action //if the divider is == 0, update the pulse timer period
	rjmp PC+2

	dec pulse1_sweep //if the divider != 0, decrement the divider

	sbrc channel_flags, 7 //if the reload flag is set, reload the sweep divider
	rcall pulse1_sweep_reload
	ret

pulse1_envelope_routine:
	sbrc channel_flags, 6 //check if start flag is cleared
	rjmp PC+17

	cpi pulse1_volume_divider, 0x00 //check if the divider is 0
	breq PC+3 //if the divider == 0, check loop flag
	dec pulse1_volume_divider //if the divider != 0, decrement and return
	ret

	lds pulse1_volume_divider, pulse1_param //if the divider == 0, reset the divider period
	andi pulse1_volume_divider, 0x0F //mask for VVVV bits
	sbrs channel_flags, 5 //check if the loop flag is set
	rjmp PC+3 //if the loop flag is not set, check the decay
	ldi pulse1_volume_decay, 0x0F //if the loop flag is set, reset decay and return
	ret

	cpi pulse1_volume_decay, 0x00 //check if the decay is 0
	brne PC+2 //if decay != 0, go decrement
	ret //if decay == 0 && loop flag == 0, do nothing and return
	dec pulse1_volume_decay
	ret

	cbr channel_flags, 0b01000000 //if the start flag is set, clear it
	lds pulse1_volume_divider, pulse1_param //if the start flag is set, reset the divider period
	andi pulse1_volume_divider, 0x0F //mask for VVVV bits
	ldi pulse1_volume_decay, 0x0F //if the start flag is set, reset decay
	ret
	
//PULSE 1 HELPER METHODS
pulse1_sweep_action:
	push r29
	mov r29, pulse1_sweep
	swap r29
	andi r29, 0x07 //mask for shift bits
	brne PC+2 //check of shift == 0
	//rjmp PC+23 //if the shift == 0, do nothing and return
	rjmp PC+34

	lds r26, TCB0_CCMPL
	lds r27, TCB0_CCMPH
	lsr r27
	ror r26
	dec r29
	brne PC-3 //keep looping/shifting until shift count is 0

	sbrs pulse1_sweep, 7 //check the negate flag
	rjmp PC+3 //if negate flag was clear, go straight to addition

	com r26 //pulse1 uses one's complement if the negate flag is set
	com r27

	lds r29, TCB0_CCMPL //perform addition to get new timer period
	add r26, r29
	lds r29, TCB0_CCMPH
	adc r27, r29

	sts TCB0_CCMPL, r26 //store the new LOW bits for timer
	sts TCB0_CCMPH, r27 //store the new HIGH bits for timer

	//sts pulse1_timerL, r26
	//sts pulse1_timerH, r27

	//Sweep Test
	mov r29, pulse1_sweep //invert the negate bit
	ldi r27, 0b10000000
	eor r29, r27
	ori r29, 0b01111111

	lds r27, pulse1_sweep_param //reload the pulse sweep divider params
	swap r27
	ori r27, 0b10000000
	and r27, r29
	mov pulse1_sweep, r27
	sbr channel_flags, 0b10000000
	
	pop r29
	ret
	
pulse1_sweep_reload:
	lds pulse1_sweep, pulse1_sweep_param //NOTE: since the reload flag is kept in bit 6, we clear the reload flag indirectly
	swap pulse1_sweep //bring data from high byte to low byte
	cbr channel_flags, 0b10000000 //clear ready flag
	ret

//CONVERTERS
//converts and loads 5 bit length to corresponding 8 bit length value into r29
length_converter:
	ldi ZH, HIGH(length << 1)
	ldi ZL, LOW(length << 1)
	add ZL, r29
	adc ZH, zero
	lpm r29, Z
	ret

length: .db $05, $7F, $0A, $01, $14, $02, $28, $03, $50, $04, $1E, $05, $07, $06, $0D, $07, $06, $08, $0C, $09, $18, $0A, $30, $0B, $60, $0C, $24, $0D, $08, $0E, $10, $0F

//loads pulse sequence into r29
duty_cycle_sequences:
	ldi ZH, HIGH(sequences << 1)
	ldi ZL, LOW(sequences << 1)
	add ZL, r29
	adc ZH, zero
	lpm r29, Z
	ret

//pulse sequences: 12.5%, 25%, 50%, 75%
sequences: .db 0b00000001, 0b00000011, 0b00001111, 0b11111100
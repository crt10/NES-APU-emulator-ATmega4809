;
; NES_APU_2a03.asm
;
; Created: 11/29/2020 1:44:10 AM
; Author : creat
;

.dseg
pulse1_param: .byte 1 //$4000 DDlc.vvvv = Duty cycle, Length counter halt, Volume
pulse1_sweep: .byte 1 //$4001 EPPP.NSSS = Enable, Period, Negate, Shift
//NOTE: In order to account for multiplier, we use 16 instead of 11 bits for the timer
pulse1_timerL: .byte 1 //$4002 LLLL.LLLL = Low 8 bits for timer
pulse1_timerH: .byte 1 //$4002 HHHH.HHHH = High 8 bits for timer
pulse1_length: .byte 1 //$4002 000l.llll = Length counter load

.cseg
.def pulse1_sequence = r16
.def pulse1_length_counter = r17
.def pulse1_sweep_divider = r18 //NR00.EPPP = Negate sweep flag, Reload sweep flag, Enable sweep flag, Period divider

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
	jmp roll_sequence

init:
	//MAIN CLOCK
	ldi r29, CPU_CCP_IOREG_gc //protected write
	sts CPU_CCP, r29
	ldi r29, 0 << CLKCTRL_PEN_bp //disable prescaler for 20 MHz on main clock
	sts CLKCTRL_MCLKCTRLB, r29

	//TEST FOR C4, 1 SECOND, 50% DD
/*	ldi r27, 0x97
	ldi r29, 0x12*/
	ldi r27, 0x15
	ldi r29, 0x09
	sts pulse1_timerL, r27
	sts pulse1_timerH, r29
	ldi r29, 0x80
	sts pulse1_param, r29
	ldi r29, 0xFF
	sts pulse1_length, r29

	//TEST FOR SWEEP UP
	ldi r29, 0b10001111
	ldi r29, 0b11111011
	sts pulse1_sweep, r29
	

	//PINS
	ldi r29, 0xFF //set all pins in VPORTD to output
	out VPORTD_DIR, r29
	
	//LENGTH
	lds r29, pulse1_length
	rcall length_converter
	mov pulse1_length_counter, r29

	//SEQUENCE
	lds pulse1_sequence, pulse1_param
	lsl pulse1_sequence //shift duty cycle bits to LSB
	rol pulse1_sequence
	rol pulse1_sequence
	andi pulse1_sequence, 0b00000011 //mask duty cycle bits
	mov r29, pulse1_sequence //load param for sequence table
	rcall duty_cycle_sequences
	mov pulse1_sequence, r29

	//SWEEP
	lds pulse1_sweep_divider, pulse1_sweep //NOTE: since the reload flag is kept in bit 6, doing this will clear the reload flag
	andi pulse1_sweep_divider, 0xF8 //mask for negate, enable and period divider bits
	swap pulse1_sweep_divider //bring data from high byte to low byte
	ori pulse1_sweep_divider, 0b01000000

	//TIMERS
	//Frame Counter
	//NOTE: The frame counter will be defaulted to NTSC mode (60 Hz, 120 Hz, 240 Hz)
	//Each interrupt will be setup to interrupt every 240 Hz clock
	//CMP0 = sequence 0, CMP1 = sequence 1, CMP2 = sequence 2, OVF = sequence 4
	//Timer period Calculation: (0.00416666666 * 20000000/64)-1 = 1301.08333125 = 0x0515
	//The ATmega4809 is cofigured to run at 20000000 Hz
	//0.00416666666 seconds is the period for 240 Hz
	//The /64 comes from the prescaler divider used
	ldi r29, TCA_SINGLE_CMP0EN_bm | TCA_SINGLE_CMP1EN_bm | TCA_SINGLE_CMP2EN_bm | TCA_SINGLE_WGMODE_NORMAL_gc //interrupt mode
	sts TCA0_SINGLE_CTRLB, r29
	ldi r29, TCA_SINGLE_CMP0_bm | TCA_SINGLE_CMP1_bm | TCA_SINGLE_CMP2_bm | TCA_SINGLE_OVF_bm //enable overflow and compare interrupts
	sts TCA0_SINGLE_INTCTRL, r29
	ldi r29, 0x15 //set the period for CMP0
	sts TCA0_SINGLE_CMP0, r29
	ldi r29, 0x05
	sts TCA0_SINGLE_CMP0 + 1, r29
	ldi r29, 0x2B //set the period for CMP1
	sts TCA0_SINGLE_CMP1, r29
	ldi r29, 0x0A
	sts TCA0_SINGLE_CMP1 + 1, r29
	ldi r29, 0x40 //set the period for CMP2
	sts TCA0_SINGLE_CMP2, r29
	ldi r29, 0x0F
	sts TCA0_SINGLE_CMP2 + 1, r29
	ldi r29, 0x57 //set the period for OVF
	sts TCA0_SINGLE_PER, r29
	ldi r29, 0x14
	sts TCA0_SINGLE_PER + 1, r29
	ldi r29, TCA_SINGLE_CLKSEL_DIV64_gc | TCA_SINGLE_ENABLE_bm //use prescale divider of 64 and enable timer
	sts TCA0_SINGLE_CTRLA, r29

	//NOTE: Channel Timers are clocked (20/2)/(0.8948865) = 11.1746014718 times faster than the NES APU
	//Because of this, we multiply all the NES timer values by 11.1746014718 beforehand 
	//Since we rotate the sequence when the timer goes from t-(t-1) to 0, instead of 0 to t like the NES, we add 1 to the NES timers before multiplying
	//The ATmega4809 is configured to run at 20 MHz
	//The /2 comes from the prescaler divider used
	//0.8948865 MHz is the speed of the NTSC NES APU
	//Pulse 1
	ldi r29, TCB_CNTMODE_INT_gc //interrupt mode
	sts TCB0_CTRLB, r29
	ldi r29, TCB_CAPT_bm //enable interrupts
	sts TCB0_INTCTRL, r29
	lds r29, pulse1_timerL //load the LOW bits for timer
	sts TCB0_CCMPL, r29
	lds r29, pulse1_timerH //load the HIGH bits for timer
	sts TCB0_CCMPH, r29
	ldi r29, TCB_CLKSEL_CLKDIV2_gc | TCB_ENABLE_bm //use prescaler divider of 2 and enable timer
	sts TCB0_CTRLA, r29
	sei //global interrupt enable

pulse1:
	//ldi pulse1_length_counter, 0xFF
	//lds r29, pulse1_param
	//sbrs r29, 5 //if length count halt flag is set, don't decrement length
	//dec pulse1_length_counter
	sbrs pulse1_sequence, 0 //if the sequence output is zero, return
	rjmp pulse1_off

	cpi pulse1_length_counter, 0 //if length is zero, return
	breq pulse1_off

	lds r28, TCB0_CCMPL
	lds r29, TCB0_CCMPH
	cpi r29, 0x59
	brsh PC+2
	rjmp pulse1_on
	breq PC+2
	rjmp pulse1_off
	cpi r28, 0x65
	brsh pulse1_off
	rjmp pulse1_on


pulse1_off:
	cbi VPORTD_OUT, 0
	rjmp pulse1

pulse1_on:
	sbi VPORTD_OUT, 0
	rjmp pulse1

roll_sequence:
	in r27, CPU_SREG
	push r27
	cli

	lsl pulse1_sequence //shifts sequence to the left
	brcc PC+2 //if the shifted bit was a 1, move it to the LSB
	inc pulse1_sequence

	ldi r27, TCB_CAPT_bm //clear OVF flag
	sts TCB0_INTFLAGS, r17
	pop r27
	out CPU_SREG, r27
	reti

sequence_0_2:
	in r27, CPU_SREG
	push r27
	cli

	ldi r27, TCA_SINGLE_CMP0_bm | TCA_SINGLE_CMP2_bm //clear OVF flag
	sts TCA0_SINGLE_INTFLAGS, r27
	pop r27
	out CPU_SREG, r27
	reti

sequence_1_3:
	in r27, CPU_SREG
	push r27
	cli

	sbrc pulse1_sweep_divider, 3 //check if the sweep enable bit is set
	rcall pulse1_sweep_routine

	ldi r27, TCA_SINGLE_CMP1_bm | TCA_SINGLE_OVF_bm //clear OVF flag
	sts TCA0_SINGLE_INTFLAGS, r27
	pop r27
	out CPU_SREG, r27
	reti

pulse1_sweep_routine:
	mov r27, pulse1_sweep_divider
	andi r27, 0x07 //mask for period divider bits
	brne PC+3 //check if divider == 0

	rcall pulse1_sweep_action //if the divider is == 0, update the pulse timer period
	rjmp PC+2

	dec pulse1_sweep_divider //if the divider != 0, decrement the divider

	sbrc pulse1_sweep_divider, 6 //if the reload flag is set, reload the sweep divider
	rcall pulse1_sweep_reload
	ret

pulse1_sweep_action:
	lds r29, pulse1_sweep
	andi r29, 0x07 //mask for shift bits
	brne PC+2 //check of shift == 0
	ret  //if the shift == 0, do nothing and return

	lds r26, TCB0_CCMPL
	lds r27, TCB0_CCMPH
	lsr r27
	ror r26
	dec r29
	brne PC-3 //keep looping/shifting until shift count is 0

	sbrs pulse1_sweep_divider, 7 //check the negate flag
	rjmp PC+3 //if negate flag was clear, go straight to addition

	com r26 //pulse1 uses one's complement if the negate flag is set
	com r27

	lds r29, TCB0_CCMPL //perform addition
	add r26, r29
	lds r29, TCB0_CCMPH
	adc r27, r29

	sts TCB0_CCMPL, r26 //load the LOW bits for timer
	sts TCB0_CCMPH, r27 //load the HIGH bits for timer

	//sts pulse1_timerL, r26
	//sts pulse1_timerH, r27
	mov r29, pulse1_sweep_divider
	ldi r28, 0b10000000
	eor r29, r28
	ori r29, 0b01111111

	lds pulse1_sweep_divider, pulse1_sweep //NOTE: since the reload flag is kept in bit 6, doing this will clear the reload flag
	andi pulse1_sweep_divider, 0xF8 //mask for negate, enable and period divider bits
	swap pulse1_sweep_divider //bring data from high byte to low byte
	ori pulse1_sweep_divider, 0b11000000
	and pulse1_sweep_divider, r29
	
	ret
	
pulse1_sweep_reload:
	lds r27, pulse1_sweep //NOTE: since the reload flag is kept in bit 6, doing this will clear the reload flag
	swap r27
	ori r27, 0b11111000
	ori pulse1_sweep_divider, 0b00000111
	and pulse1_sweep_divider, r27
	andi pulse1_sweep_divider, 0b10111111
	ret

//converts and loads 5 bit length to corresponding 8 bit length value into r29
length_converter:
	ldi ZH, HIGH(length << 1)
	ldi ZL, LOW(length << 1)
	ldi r27, 0x00
	add ZL, r29
	adc ZH, r27
	lpm r29, Z
	ret

length: .db $05, $7F, $0A, $01, $14, $02, $28, $03, $50, $04, $1E, $05, $07, $06, $0D, $07, $06, $08, $0C, $09, $18, $0A, $30, $0B, $60, $0C, $24, $0D, $08, $0E, $10, $0F

//loads pulse sequence into r29
duty_cycle_sequences:
	ldi ZH, HIGH(sequences << 1)
	ldi ZL, LOW(sequences << 1)
	ldi r27, 0x00
	add ZL, r29
	adc ZH, r27
	lpm r29, Z
	ret

//pulse sequences: 12.5%, 25%, 50%, 75%
sequences: .db 0b00000001, 0b00000011, 0b00001111, 0b11111100
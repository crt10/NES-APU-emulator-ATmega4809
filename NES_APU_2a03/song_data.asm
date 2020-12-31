note_table: 
	.dw 0xb18f, 0xa797, 0x9e2f
	.dw 0x954f, 0x8ced, 0x8504, 0x7d8d, 0x7681, 0x6fdb, 0x6993, 0x63a7, 0x5e0f, 0x58c7, 0x53cc, 0x4f18
	.dw 0x4aa7, 0x4677, 0x4282, 0x3ec7, 0x3b41, 0x37ed, 0x34ca, 0x31d3, 0x2f07, 0x2c64, 0x29e6, 0x278c
	.dw 0x2554, 0x233b, 0x2141, 0x1f63, 0x1da0, 0x1bf7, 0x1a65, 0x18ea, 0x1784, 0x1632, 0x14f3, 0x13c6
	.dw 0x12aa, 0x119e, 0x10a1, 0x0fb2, 0x0ed0, 0x0dfb, 0x0d32, 0x0c75, 0x0bc2, 0x0b19, 0x0a79, 0x09e3
	.dw 0x0955, 0x08cf, 0x0850, 0x07d9, 0x0768, 0x06fe, 0x0699, 0x063a, 0x05e1, 0x058c, 0x053d, 0x04f1
	.dw 0x04aa, 0x0467, 0x0428, 0x03ec, 0x03b4, 0x037f, 0x034d, 0x031d, 0x02f0, 0x02c6, 0x029e, 0x0279
	.dw 0x0255, 0x0234, 0x0214, 0x01f6, 0x01da, 0x01bf, 0x01a6, 0x018f, 0x0178, 0x0163, 0x014f, 0x013c

song0_frames:
	.dw song0_channel0_pattern0, song0_channel1_pattern0, song0_channel2_pattern0, song0_channel3_pattern0, song0_channel4_pattern0
	.dw song0_channel0_pattern1, song0_channel1_pattern1, song0_channel2_pattern1, song0_channel3_pattern1, song0_channel4_pattern1
	.dw song0_channel0_pattern2, song0_channel1_pattern2, song0_channel2_pattern2, song0_channel3_pattern2, song0_channel4_pattern2

song0_channel0_patterns:
	song0_channel0_pattern0: .db 0x1b, 0x66, 0xe2, 0x00, 0x7e, 0x1f, 0x7e, 0x22, 0x7e, 0x1b, 0xe2, 0x01, 0x7e, 0x1f, 0x7e, 0x22, 0x7e, 0x1b, 0xe2, 0x02, 0x72, 0xe3, 0x72, 0x1f, 0x72, 0xe3, 0x72, 0x22, 0x72, 0xe3, 0x72, 0x1b, 0xe2, 0x03, 0x72, 0xe3, 0x72, 0x1f, 0x72, 0xe3, 0x72, 0x22, 0x72, 0xe3, 0x72, 0xff
	song0_channel0_pattern1: .db 0x1b, 0xe2, 0x04, 0x7e, 0x1f, 0x7e, 0x22, 0x7e, 0x1b, 0xe2, 0x05, 0x7e, 0x1f, 0x7e, 0x22, 0x7e, 0x1b, 0xe2, 0x06, 0x72, 0xe3, 0x72, 0x1f, 0x72, 0xe3, 0x72, 0x22, 0x72, 0xe3, 0x72, 0x1b, 0xe2, 0x07, 0x72, 0xe3, 0x72, 0x1f, 0x72, 0xe3, 0x72, 0x22, 0x72, 0xe3, 0x72, 0x1b, 0xe2, 0x04, 0x7e, 0x1f, 0x7e, 0x22, 0x7e, 0x1b, 0xe2, 0x05, 0x7e, 0x1f, 0x7e, 0x22, 0x7e, 0x1b, 0xe2, 0x06, 0x72, 0xe3, 0x72, 0x1f, 0x72, 0xe3, 0x72, 0x22, 0x72, 0xe3, 0x72, 0x1b, 0xe2, 0x07, 0x72, 0xe3, 0x72, 0x1f, 0x72, 0xe3, 0x72, 0x22, 0x72, 0xe3, 0x72, 0x1b, 0xe2, 0x04, 0x7e, 0x1f, 0x7e, 0x22, 0x7e, 0x1b, 0xe2, 0x05, 0x7e, 0x1f, 0x7e, 0x22, 0x7e, 0x1b, 0xe2, 0x06, 0x72, 0xe3, 0x72, 0x1f, 0x72, 0xe3, 0x72, 0x22, 0x72, 0xe3, 0x72, 0x1b, 0xe2, 0x07, 0x72, 0xe3, 0x72, 0x1f, 0x72, 0xe3, 0x72, 0x22, 0x72, 0xe3, 0x72, 0xff
	song0_channel0_pattern2: .db 0x1b, 0xe2, 0x08, 0x7e, 0x1f, 0x7e, 0x22, 0x7e, 0x1b, 0xe2, 0x09, 0x7e, 0x1f, 0x7e, 0x22, 0x7e, 0x1b, 0xe2, 0x0a, 0x72, 0xe3, 0x72, 0x1f, 0x72, 0xe3, 0x72, 0x22, 0x72, 0xe3, 0x72, 0x1b, 0xe2, 0x0b, 0x72, 0xe3, 0x72, 0x1f, 0x72, 0xe3, 0x72, 0x22, 0x72, 0xe3, 0x72, 0xff

song0_channel1_patterns:
	song0_channel1_pattern0: .db 0x66, 0xe2, 0x00, 0xe1, 0xe1, 0x8e, 0xff
	song0_channel1_pattern1: .db 0xe1, 0xe1, 0x8e, 0xff
	song0_channel1_pattern2: .db 0xe1, 0xe1, 0x8e, 0xff

song0_channel2_patterns:
	song0_channel2_pattern0: .db 0x66, 0xe2, 0x00, 0xe1, 0xe1, 0x8e, 0xff
	song0_channel2_pattern1: .db 0xe1, 0xe1, 0x8e, 0xff
	song0_channel2_pattern2: .db 0xe1, 0xe1, 0x8e, 0xff

song0_channel3_patterns:
	song0_channel3_pattern0: .db 0x66, 0xe2, 0x00, 0xe1, 0xe1, 0x8e, 0xff
	song0_channel3_pattern1: .db 0xe1, 0xe1, 0x8e, 0xff
	song0_channel3_pattern2: .db 0xe1, 0xe1, 0x8e, 0xff

song0_channel4_patterns:
	song0_channel4_pattern0: .db 0x66, 0xe2, 0x00, 0xe1, 0xe1, 0x8e, 0xff
	song0_channel4_pattern1: .db 0xe1, 0xe1, 0x8e, 0xff
	song0_channel4_pattern2: .db 0xe1, 0xe1, 0x8e, 0xff

instruments:
	.dw instrument0
	.dw instrument1
	.dw instrument2
	.dw instrument3
	.dw instrument4
	.dw instrument5
	.dw instrument6
	.dw instrument7
	.dw instrument8
	.dw instrument9
	.dw instrument10
	.dw instrument11

instrument0: .dw 0b00000010, arpeggio_macro0
instrument1: .dw 0b00000010, arpeggio_macro1
instrument2: .dw 0b00000010, arpeggio_macro2
instrument3: .dw 0b00000010, arpeggio_macro3
instrument4: .dw 0b00000010, arpeggio_macro4
instrument5: .dw 0b00000010, arpeggio_macro5
instrument6: .dw 0b00000010, arpeggio_macro6
instrument7: .dw 0b00000010, arpeggio_macro7
instrument8: .dw 0b00000010, arpeggio_macro8
instrument9: .dw 0b00000010, arpeggio_macro9
instrument10: .dw 0b00000010, arpeggio_macro10
instrument11: .dw 0b00000010, arpeggio_macro11

volume_macro0: .db 0xff, 0x06, 0x01, 0x02, 0x03, 0x04, 0x0e, 0xff

arpeggio_macro0: .db 0xff, 0xff, 0x00, 0x02, 0x02, 0xfe, 0xfe, 0x00, 0x80
arpeggio_macro1: .db 0xff, 0x03, 0x00, 0x02, 0x02, 0xfe, 0xfe, 0x00, 0x80
arpeggio_macro2: .db 0x04, 0xff, 0x00, 0x02, 0x02, 0xfe, 0xfe, 0x00, 0x80
arpeggio_macro3: .db 0x05, 0x04, 0x00, 0x02, 0x02, 0xfe, 0xfe, 0x00, 0x80
arpeggio_macro4: .db 0xff, 0xff, 0x02, 0x01, 0x02, 0x03, 0x04, 0x0e, 0x80
arpeggio_macro5: .db 0xff, 0x06, 0x02, 0x01, 0x02, 0x03, 0x04, 0xfe, 0x80
arpeggio_macro6: .db 0x04, 0xff, 0x02, 0x01, 0x02, 0x03, 0x04, 0x0e, 0x80
arpeggio_macro7: .db 0x05, 0x03, 0x02, 0xfe, 0x02, 0x03, 0x04, 0xf4, 0x80
arpeggio_macro8: .db 0xff, 0xff, 0x01, 0x0c, 0x0f, 0x14, 0x1c, 0x23, 0x80
arpeggio_macro9: .db 0xff, 0x06, 0x01, 0x0c, 0x0f, 0x14, 0x1b, 0x23, 0x80
arpeggio_macro10: .db 0x05, 0xff, 0x01, 0x0c, 0x0f, 0x14, 0x1b, 0x23, 0x80
arpeggio_macro11: .db 0x06, 0x03, 0x01, 0x0c, 0x0f, 0x14, 0x1b, 0x23, 0x80


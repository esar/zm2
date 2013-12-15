		.import RESET
		.import PS2_INT


		.org $FFFA
		.segment "VECTORS"
		.word RESET
		.word RESET
		.word PS2_INT




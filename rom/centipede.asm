VGA_POS = $ED
VGA_SRC = $EB
PS2_DOWN = $E6

		.import VGA_CLEAR
		.import BRKO_DELAY
		.import BRKO_VFILL
		.import BRKO_HFILL

		.feature labels_without_colons


		.org $FB00
		.segment "CENTIPEDE"
		
; ********************************************
;  Centipede
; ********************************************

CP_HEAD = $ED		; aka VGA_POS
CP_TAIL = $EB		; aka VGA_SRC

CP_DIR_UP = 0		; direction constants
CP_DIR_RGT = 1
CP_DIR_DWN = 2
CP_DIR_LFT = 3

CP:
		JSR VGA_CLEAR			; clear screen
		
						; draw border
						; top border
		LDY #0				; first char
		LDA #218
		STA (CP_HEAD),Y
		INC CP_HEAD			; line
		LDA #196
		LDY #78
		JSR BRKO_HFILL
		LDA #191			; last char
		STA (CP_HEAD),Y
		
		INC CP_HEAD			; left border
		LDA #179
		LDY #28
		JSR BRKO_VFILL
						; bottom border
		LDA #192			; first char
		STA (CP_HEAD),Y
		INC CP_HEAD			; line
		LDA #196
		LDY #78
		JSR BRKO_HFILL
		LDA #217			; last char
		STA (CP_HEAD),Y
		
		LDA #$9F			; right border
		STA CP_HEAD
		LDA #$C0
		STA CP_HEAD+1
		LDA #179
		LDY #28
		JSR BRKO_VFILL
		
		LDA #$C4			; reset head/tail position
		STA CP_TAIL+1
		STA CP_HEAD+1
		LDA #$CE
		STA CP_TAIL
		STA CP_HEAD
		
		LDA #CP_DIR_RGT			; reset directions
		STA CP_TDIR
		STA CP_ODIR
		
		LDY #10				; draw initial worm
		LDA #205
		JSR BRKO_HFILL
		
CP_LOOP:					; main game loop
		LDA PS2_DOWN			; get key and set new direction
		CMP #'W'
		BEQ CP_UP
		CMP #'A'
		BEQ CP_LFT
		CMP #'S'
		BEQ CP_DWN
		CMP #'D'
		BNE CP_MOVE_NOCHANGE
CP_RGT:
		LDA #CP_DIR_RGT
		JMP CP_MOVE
CP_UP:
		LDA #CP_DIR_UP
		JMP CP_MOVE
CP_LFT:
		LDA #CP_DIR_LFT
		JMP CP_MOVE
CP_DWN:
		LDA #CP_DIR_DWN

CP_MOVE:
		STA CP_NDIR
CP_MOVE_NOCHANGE:

		LDY #0				; check for hit
		LDA (CP_HEAD),Y
		BEQ CP_NOTDEAD
		JMP CP				; hit something, die
CP_NOTDEAD:

CP_MOVE_HEAD:						; lookup char based on old+new direction
		LDA CP_ODIR			; load old direction
		CLC				; shift left twice
		ROL
		ROL
		ADC CP_NDIR			; add new direction
		TAX
		LDA CP_CTAB,X			; lookup char
		BEQ CP_LOOP			; 0 => invalid move
		STA (CP_HEAD),Y			; put char on screen at current position
		
		LDX CP_NDIR			; set old direction to new direction
		STX CP_ODIR

		LDA CP_MTAB,X			; lookup offset to new position
		BPL CP_MH_NOSX			; sign extend offset, saving in Y
		LDY #$FF
CP_MH_NOSX:

		ADC CP_HEAD			; add offset, low byte
		STA CP_HEAD
		TYA
		ADC CP_HEAD+1 			; add offset, high byte (sign extension from Y)
		STA CP_HEAD+1

CP_MOVE_TAIL:					; move tail based on direction and char on screen
		LDA CP_TDIR			; load tail direction
		CLC				; shift left twice
		ROL
		ROL
		TAX
		
		LDY #0
		LDA (CP_TAIL),Y			; load char from screen
		DEX
		DEY
CP_MT_LKUP:					; scan table for match on char, result: Y=new direction
		INX
		INY
		CMP CP_CTAB,X
		BNE CP_MT_LKUP
		
		STY CP_TDIR			; store new tail direction
		LDX CP_MTAB,Y			; lookup offset to new position

		LDA #0				; remove last tail character
		TAY
		STA (CP_TAIL),Y
		
		CPX #$80			; sign extend offset, saving in Y
		BCC CP_MT_NOSX
		LDY #$FF
CP_MT_NOSX:
		
		TXA				; add offset to tail pos, low byte
		CLC
		ADC CP_TAIL
		STA CP_TAIL
		TYA				; add offset to tail pos, high byte (sign extension from Y)
		ADC CP_TAIL+1
		STA CP_TAIL+1
		
		LDA #$FF			; wait
		JSR BRKO_DELAY
		
		JMP CP_LOOP
		
;		RTS


; character lookup table, indexed by (old_direction << 2 | new_direction)
;
CP_CTAB:	.BYTE 186, 201, 0, 187		; UP->UP,  UP->RGT,  UP->DWN,  UP->LFT
		.BYTE 188, 205, 187, 0		; RGT->UP, RGT->RGT, RGT->DWN, RGT->LFT
		.BYTE 0, 200, 186, 188		; DWN->UP, DWN->RGT, DWN->DWN, DWN->LFT
		.BYTE 200, 0, 201, 205		; LFT->UP, LFT->RGT, LFT->DWN, LFT->LFT

; movement offset table, index by direction
;
CP_MTAB:	.BYTE <-80,1,80,<-1		; UP, RGT, DWN, LFT

CP_TDIR:	.BYTE CP_DIR_RGT		; tail direction
CP_ODIR:	.BYTE CP_DIR_RGT		; old head direction
CP_NDIR:	.BYTE CP_DIR_RGT		; new head direction





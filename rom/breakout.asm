VGA_POS = $ED
VGA_SRC = $EB
PS2_DOWN = $E6

		.export BRKO_DELAY
		.export BRKO_VFILL
		.export BRKO_HFILL

		.import VGA_CLEAR

		.feature labels_without_colons

		.org $FC00
		.segment "BREAKOUT"

; ********************************************
;             Breakout
; ********************************************

;BRKO_TOP = 3
;BRKO_BOT = 28
BRKO_LFT = 1
BRKO_RGT = 78
BRKO_BATLINE = 28
BRKO_SCORE1 = $C000+80+12
BRKO_SCORE10 = $C000+80+11
BRKO_SCORE100 = $C000+80+10
BRKO_SCORE1000 = $C000+80+9
BRKO_LIFEPOS = $C09A

BRKO:		
		LDA #$C0			; set initial speed
		STA BRKO_SPEED
		JSR BRKO_INIT			; draw initial screen

BRKO_START_LEVEL:
		JSR BRKO_RESET
		JSR BRKO_DRAW_BAT
		LDX #20
		JSR BRKO_FLASH_BALL
		
BRKO_LOOP:
		LDA BRKO_SPEED			; wait
		JSR BRKO_DELAY

		LDA PS2_DOWN			; get key
		
		CMP #3				; if it's ESC then quit
		BNE BRKO_NOTESC
		JMP BRKO_QUIT
		
BRKO_NOTESC:
		CMP #'A'			; if it's A then move bat left
		BNE BRKO_NOTA
		DEC BRKO_POS
		INC BRKO_RAND1
		JMP BRKO_BAT
		
BRKO_NOTA:
		CMP #'D'			; if it's D then move bat right
		BNE BRKO_BAT
		INC BRKO_POS
		INC BRKO_RAND2

BRKO_BAT:
		LDA BRKO_POS			; check left bounds of bat
		CMP #BRKO_LFT
		BCS BRKO_BAT_LFTOK
		LDA #BRKO_LFT
		STA BRKO_POS
BRKO_BAT_LFTOK:
		CMP #BRKO_RGT-10+1		; check right bounds of bat
		BCC BRKO_BAT_RGTOK
		LDA #BRKO_RGT-10+1
		STA BRKO_POS
BRKO_BAT_RGTOK:
		CMP BRKO_OPOS			; if the bat has moved then redraw it
		BEQ BRKO_BALL
		JSR BRKO_DRAW_BAT
		LDA BRKO_POS
		STA BRKO_OPOS
		
BRKO_BALL:
		INC BRKO_TICK3			; ball moves at half the speed of bat
		LDA BRKO_TICK3
		AND #1
		BEQ BRKO_LOOP

		LDA #0				; erase ball
		TAY
		STA (VGA_POS),Y
	
		LDA BRKO_VX	
		JSR BRKO_MOVE_BALL		; move ball x
		STA BRKO_VX
		
		LDA BRKO_VY
		JSR BRKO_MOVE_BALL		; move ball y
		STA BRKO_VY

		SEC				; is ball on bat line (missed)?
		LDA VGA_POS
		SBC #$C0
		LDA VGA_POS+1
		SBC #$C8
		BCC BRKO_NOTOVER

BRKO_DIE:
		LDA #0
		LDX BRKO_LIVES
		STA BRKO_LIFEPOS,X
		DEX
		STX BRKO_LIVES
		BEQ BRKO_GAME_OVER		; game over if none left
		
		LDX #10				; life lost, flash the ball ten times
		JSR BRKO_FLASH_BALL		

BRKO_NOTOVER:		
		LDY #0				; test for diagonal hit
		LDA (VGA_POS),Y
		BEQ BRKO_BALL_NOHIT
		
		JSR BRKO_TST_CLR_BLOCK		; clear the block (if it is one)
		BNE BRKO_NOTBLOCK
		JSR BRKO_UPDT_SCORE
BRKO_NOTBLOCK:
		
		SEC				; invert x velocity and move ball back
		LDA #0
		SBC BRKO_VX
		STA BRKO_VX
		JSR BRKO_MOVE_BALL
		
		SEC				; invert y velocity and move ball back
		LDA #0
		SBC BRKO_VY
		STA BRKO_VY
		JSR BRKO_MOVE_BALL
		
BRKO_BALL_NOHIT:
		LDA #2				; draw ball
		LDY #0
		STA (VGA_POS),Y

		LDA BRKO_COUNT			; test for end of level
		BNE BRKO_SKIP_RESET
		JMP BRKO_START_LEVEL
		
BRKO_SKIP_RESET:
		JMP BRKO_LOOP
		

BRKO_GAME_OVER:					; game over
		LDA #<BRKO_MSG_OVER
		STA VGA_SRC
		LDA #>BRKO_MSG_OVER
		STA VGA_SRC+1
		LDA #$FE
		STA VGA_POS
		LDA #$C1
		STA VGA_POS+1
		JSR BRKO_PRNT
		
		CLC
		LDA VGA_POS
		ADC #76
		STA VGA_POS
		BCC BRKO_GAME_OVER_NOCRY
		INC VGA_POS+1
BRKO_GAME_OVER_NOCRY:

		LDA #<BRKO_MSG_PRESS
		STA VGA_SRC
		LDA #>BRKO_MSG_PRESS
		STA VGA_SRC+1
		JSR BRKO_PRNT
		

		LDA PS2_DOWN			; get key
		CMP #3				; quit if it's ESC
		BEQ BRKO_QUIT			
		CMP #$0D			; restart if it's ENTER
		BNE BRKO_GAME_OVER
		JMP BRKO

BRKO_QUIT:					; time to quit
		JSR VGA_CLEAR			; clear screen
		LDA #$FF			; Turn cursor back on
		STA $CBFE
		RTS				; return to caller


; **************************************************
;  Flash Ball: X=Num_Flashes
; **************************************************

BRKO_FLASH_BALL:
		LDA #0
		TAY
		STA (VGA_POS),Y
		LDA #$FF
		JSR BRKO_DELAY
		LDA #2
		STA (VGA_POS),Y
		LDA #$FF
		JSR BRKO_DELAY
		DEX
		BNE BRKO_FLASH_BALL


; **************************************************
;  Move ball: A=Velocity, on return A=New_Velocity
; **************************************************
BRKO_MOVE_BALL:
		STA BRKO_VEL_L			; store velocity
		CMP #$80			; sign extend
		BCS BRKO_MB_SIGNEXT
		LDA #$00			; is positive, extend with 0's
		STA BRKO_VEL_H
		JMP BRKO_MB_MOVE
BRKO_MB_SIGNEXT:
		LDA #$FF			; is negative, extend with 1's
		STA BRKO_VEL_H

BRKO_MB_MOVE:
		CLC				; add velocity to VGA_POS
		LDA VGA_POS
		ADC BRKO_VEL_L
		STA VGA_POS
		LDA VGA_POS+1
		ADC BRKO_VEL_H
		STA VGA_POS+1

		LDY #0
		LDA (VGA_POS),Y			; load char from screen (one char right of ball)
		BNE BRKO_MB_HIT			; if screen char isn't blank, ball has hit something
		
		LDA BRKO_VEL_L			; no hit, clear carry
		RTS
		
BRKO_MB_HIT:
		JSR BRKO_TST_CLR_BLOCK		; clear block (it it's a block)
		BNE BRKO_MB_RESTORE
		JSR BRKO_UPDT_SCORE

BRKO_MB_RESTORE:
		SEC				; restore VGA_POS (sub velocity)
		LDA VGA_POS
		SBC BRKO_VEL_L
		STA VGA_POS
		LDA VGA_POS+1
		SBC BRKO_VEL_H
		STA VGA_POS+1

		SEC				; we hit something so invert direction, set carry
		LDA #0
		SBC BRKO_VEL_L
		RTS



; ***************************************************
;  Clear Block: A=block_type, VGA_POS=block_pos, on return Z=1 if hit
; ***************************************************

BRKO_TST_CLR_BLOCK:
		LDA VGA_POS			; save current position
		STA BRKO_TEMP
		AND #$FC			; mask to start of 4 char block
		STA VGA_POS
		
		LDX #0
		LDY #4
BRKO_TST_CLR_BLOCK_LOOP:
		DEY
		LDA (VGA_POS),Y			; get char from screen
		CMP #219			; test whether it's actually a block
		BEQ BRKO_TST_CLR_BLOCK_HIT
		CMP #176
		BEQ BRKO_TST_CLR_BLOCK_HIT
		CMP #177
		BEQ BRKO_TST_CLR_BLOCK_HIT
		CMP #178
		BEQ BRKO_TST_CLR_BLOCK_HIT
		JMP BRKO_TST_CLR_BLOCK_MISS
BRKO_TST_CLR_BLOCK_HIT:
		LDX #1				; remember we've had a hit
		LDA #0				
		STA (VGA_POS),Y			; erase the character
BRKO_TST_CLR_BLOCK_MISS:
		CPY #0
		BNE BRKO_TST_CLR_BLOCK_LOOP
		
		LDA BRKO_TEMP			; restore current position
		STA VGA_POS
		CPX #1				; set Z if we've had a hit
		RTS


; ******************************************
;   Draw Bat
; ******************************************

; TODO: Use HFILL

BRKO_DRAW_BAT:
		LDX BRKO_OPOS			; erase bat at old position
		LDY #10
		LDA #0
BRKO_DB_L1:
		STA $C000+BRKO_BATLINE*80,X
		INX
		DEY
		BNE BRKO_DB_L1
		
		LDX BRKO_POS			; draw bat at new position
		LDY #10
		LDA #205
BRKO_DB_L2:
		STA $C000+BRKO_BATLINE*80,X
		INX
		DEY
		BNE BRKO_DB_L2
		
		RTS


; ********************************************
;  Update Score: score += A
; ********************************************

; TODO: Rullup into loop

BRKO_UPDT_SCORE:
		DEC BRKO_COUNT

		CLC				; update units
		LDA BRKO_SCORE1
		ADC #5
		CMP #'9'+1
		BCS BRKO_US10
		STA BRKO_SCORE1
		RTS
		
BRKO_US10:
		SEC
		SBC #10
		STA BRKO_SCORE1

		DEC BRKO_SPEED			; increase speed
		
		CLC				; update tens
		LDA BRKO_SCORE10
		ADC #1
		CMP #'9'+1
		BCS BRKO_US100
		STA BRKO_SCORE10
		RTS

BRKO_US100:
		LDA #'0'
		STA BRKO_SCORE10
		
		CLC				; update hundreds
		LDA BRKO_SCORE100
		ADC #1
		CMP #'9'+1
		BCS BRKO_US1000
		STA BRKO_SCORE100
		RTS
		
BRKO_US1000:
		LDA #'0'
		STA BRKO_SCORE100
		
		INC BRKO_SCORE1000		; update thousands
		RTS


; ********************************************
;   Init: Draw Initial screen
; ********************************************		
		
BRKO_INIT:
		JSR VGA_CLEAR
		
		LDA #0			; Turn off cursor
		STA $CBFE

					; score top row
		TAY
		LDA #218		; left corner
		STA (VGA_POS),Y
		
		INC VGA_POS		; line
		LDA #196
		LDY #78
		JSR BRKO_HFILL
		
		LDA #191		; right corner
		STA (VGA_POS),Y
			
	
					; score row
		INC VGA_POS		; left corner
		LDA #179
		STA (VGA_POS),Y

		INC VGA_POS		; score text
		INC VGA_POS		
		LDA #<BRKO_MSG_SCORE
		STA VGA_SRC
		LDA #>BRKO_MSG_SCORE
		STA VGA_SRC+1
		JSR BRKO_PRNT
		LDA #'0'
		STA BRKO_SCORE1
		STA BRKO_SCORE10
		STA BRKO_SCORE100
		STA BRKO_SCORE1000
		
		CLC			; title
		LDA VGA_POS
		ADC #30
		STA VGA_POS
		LDA #<BRKO_MSG_TITLE
		STA VGA_SRC
		LDA #>BRKO_MSG_TITLE
		STA VGA_SRC+1
		JSR BRKO_PRNT
		
		LDA VGA_POS		; lives
		ADC #36
		STA VGA_POS
		LDA #<BRKO_MSG_LIVES
		STA VGA_SRC
		LDA #>BRKO_MSG_LIVES
		STA VGA_SRC+1
		JSR BRKO_PRNT
		
		LDY #0
		LDA VGA_POS
		ADC #7
		STA VGA_POS
		LDA #2
		STA (VGA_POS),Y
		INC VGA_POS
		STA (VGA_POS),Y
		INC VGA_POS
		STA (VGA_POS),Y

		INC VGA_POS
		INC VGA_POS		
		LDA #179
		STA (VGA_POS),Y
		
					
					; score bottom row
		INC VGA_POS		; left corner
		LDA #195		
		STA (VGA_POS),Y
		
		INC VGA_POS		; line
		LDA #196
		LDY #78
		JSR BRKO_HFILL
		
		LDA #180		; right corner
		STA (VGA_POS),Y
		
		INC VGA_POS		; left border
		LDA #179
		LDY #26
		JSR BRKO_VFILL
				
		LDA #$3F		; right border
		STA VGA_POS
		LDA #$C1
		STA VGA_POS + 1
		LDA #179
		LDY #26
		JSR BRKO_VFILL
		
					; bottom row
		LDA #$10		; left corner
		STA VGA_POS
		LDA #$C9
		STA VGA_POS+1
		LDA #192
		STA (VGA_POS),Y
		
		INC VGA_POS		; line
		LDA #196
		LDY #78
		JSR BRKO_HFILL
		
		LDA #217		; right corner
		STA (VGA_POS),Y
		
		LDA #$D7		; reset output and cursor positions
		STA VGA_POS
		LDA #$C4
		STA VGA_POS + 1

		LDA #BRKO_LFT
		STA BRKO_OPOS
				
		LDA #3
		STA BRKO_LIVES
		
		RTS
		

; TODO: Get rid of all the resetting of VGA_POS
		
BRKO_RESET:
		LDA #0			; erase ball
		TAY
		STA (VGA_POS),Y

		LDA #$91
		STA VGA_POS
		LDA #$C1
		STA VGA_POS + 1		
		LDA #219
		LDY #78
		JSR BRKO_HFILL

		LDA #$E1
		STA VGA_POS
		LDA #$C1
		STA VGA_POS + 1		
		LDA #178
		LDY #78
		JSR BRKO_HFILL

		LDA #$31
		STA VGA_POS
		LDA #$C2
		STA VGA_POS + 1		
		LDA #177
		LDY #78
		JSR BRKO_HFILL

		LDA #$81
		STA VGA_POS
		LDA #$C2
		STA VGA_POS + 1		
		LDA #176
		LDY #78
		JSR BRKO_HFILL

		LDA BRKO_RAND2		; randomise start direction based on presses of D key
		AND #1
		BNE BRKO_RESET_RGT
		LDA #<-1
BRKO_RESET_RGT:
		STA BRKO_VX
		LDA #<-80
		STA BRKO_VY
		
					; reset output and cursor positions
		LDA BRKO_RAND1		; randomise start position +/- 3 from centre based on presses of A
		AND #$07
		SEC
		ADC #$D7-3
		STA VGA_POS
		LDA #$C4
		STA VGA_POS + 1

		LDA #$50		; reset block count
		STA BRKO_COUNT

		LDA #$25		; centre the bat
		STA BRKO_POS

		RTS			
		
		
; ********************************************
;  Horz Line: Fill Y chars with A from current pos, horizontally
; ********************************************

BRKO_HFILL:
		STY BRKO_TEMP
BRKO_HFILL_LOOP:
		DEY
		STA (VGA_POS),Y
		BNE BRKO_HFILL_LOOP
		
		CLC
		LDA VGA_POS
		ADC BRKO_TEMP
		STA VGA_POS
		BCC BRKO_HFILL_NOCRY
		INC VGA_POS+1
BRKO_HFILL_NOCRY:
		
		RTS
		

; **********************************************
;  Vert Fill: Fill Y chars with A from current pos, vertically
; **********************************************
BRKO_VFILL:
		STA BRKO_TEMP
		TYA
		TAX
		LDY #0
BRKO_VFILL_LOOP:
		LDA BRKO_TEMP
		STA (VGA_POS),Y
		
		CLC
		LDA VGA_POS
		ADC #80
		STA VGA_POS
		BCC BRKO_VFILL_NOCRY
		INC VGA_POS+1
BRKO_VFILL_NOCRY:
		DEX
		BNE BRKO_VFILL_LOOP
		
		RTS

; ***********************************************
;  Delay: Delay A ticks
; ***********************************************

BRKO_DELAY:
		STA BRKO_TICK2
		LDA #0
		STA BRKO_TICK1
		
BRKO_DELAY_LOOP:
		DEC BRKO_TICK1
		BNE BRKO_DELAY_LOOP
		DEC BRKO_TICK2
		BNE BRKO_DELAY_LOOP
		RTS


; ***********************************************
;  Print: NULL terminated from VGA_SRC to VGA_POS
; ***********************************************

BRKO_PRNT:
		LDY #0
BRKO_PRNT_LOOP:
		LDA (VGA_SRC),Y
		BEQ BRKO_PRNT_DONE
		STA (VGA_POS),Y
		INY
		JMP BRKO_PRNT_LOOP
BRKO_PRNT_DONE:
		RTS
		
BRKO_MSG_SCORE:	.BYTE "Score:",$00
BRKO_MSG_LIVES:	.BYTE "Lives:",$00
BRKO_MSG_TITLE:	.BYTE "B R E A K O U T",$00
BRKO_MSG_OVER:	.BYTE " G A M E  O V E R ",$00
BRKO_MSG_PRESS:	.BYTE " Press ENTER to try again ",$00
		


		.org $1000
		.segment "DATA"

BRKO_VX:	.BYTE $FF
BRKO_VY:	.BYTE $FF
BRKO_POS:	.BYTE $25
BRKO_OPOS:	.BYTE BRKO_LFT
BRKO_TICK1:	.BYTE $00
BRKO_TICK2:	.BYTE $00
BRKO_TICK3:	.BYTE $00
BRKO_TEMP:	.BYTE $00
BRKO_COUNT:	.BYTE $50
BRKO_SPEED:	.BYTE $F0
BRKO_LIVES:	.BYTE $00
BRKO_VEL_L:	.BYTE $00
BRKO_VEL_H:	.BYTE $00
BRKO_RAND1:	.BYTE $00
BRKO_RAND2:	.BYTE $00





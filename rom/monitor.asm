; Memory mapped IO locations
PS2_IO = $CC00
VGA_IO = $C000

; zero page usage
VGA_POS = $ED
VGA_SRC = $EB
VGA_CURX = $EA
VGA_CURY = $E9
PS2_STATE = $E8
PS2_CHAR = $E7
PS2_DOWN = $E6
TEMP = $E5

		.export RESET
		.export PS2_INT
		.export VGA_CLEAR

		.import VEC_IN
		.import LAB_COLD

		.import BRKO_DELAY
		.import BRKO_VFILL
		.import BRKO_HFILL

		.feature labels_without_colons

		.org $F800
		.segment "MONITOR"

SYS_WELCOME:
		.byte "ZM2: Starting..."

PS2_TAB:	
		;     00   01   02   03   04   05   06   07   08   09   0A   0B   0C   0D   0E   0F
		.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $09, '`', $00	; 00
		.byte $00, $00, $00, $00, $00, 'Q', '1', $00, $00, $00, 'Z', 'S', 'A', 'W', '2', $00	; 10
		.byte $00, 'C', 'X', 'D', 'E', '4', '3', $00, $00, ' ', 'V', 'F', 'T', 'R', '5', $00	; 20
		.byte $00, 'N', 'B', 'H', 'G', 'Y', '6', $00, $00, $00, 'M', 'J', 'U', '7', '8', $00	; 30
		.byte $00, ',', 'K', 'I', 'O', '0', '9', $00, $00, '.', '/', 'L', ';', 'P', '-', $00	; 40
		.byte $00, $00, $00, $00, '[', '=', $00, $00, $00, $00, $0D, ']', $00, $5C, $00, $00	; 50
		.byte $00, $00, $00, $00, $00, $00, $08, $00, $00, '1', $00, '4', '7', $00, $00, $00	; 60
		.byte '0', '.', '2', '5', '6', '8', $03, $00, $00, '+', '3', '-', '*', '9', $00, $00	; 70

PS2_SHIFT_TAB:
		;     00   01   02   03   04   05   06   07   08   09   0A   0B   0C   0D   0E   0F
		.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $09, $AC, $00	; 00
		.byte $00, $00, $00, $00, $00, 'q', '!', $00, $00, $00, 'z', 's', 'a', 'w', $22, $00	; 10
		.byte $00, 'c', 'x', 'd', 'e', '$', $A3, $00, $00, ' ', 'v', 'f', 't', 'r', '%', $00	; 20
		.byte $00, 'n', 'b', 'h', 'g', 'y', '^', $00, $00, $00, 'm', 'j', 'u', '&', '*', $00	; 30
		.byte $00, '<', 'k', 'i', 'o', ')', '(', $00, $00, '>', '?', 'l', ':', 'p', '_', $00	; 40
		.byte $00, $00, $00, $00, '[', '+', $00, $00, $00, $00, $0D, ']', $00, $5C, $00, $00	; 50
		.byte $00, $00, $00, $00, $00, $00, $08, $00, $00, '1', $00, '4', '7', $00, $00, $00	; 60
		.byte '0', '.', '2', '5', '6', '8', $03, $00, $00, '+', '3', '-', '*', '9', $00, $00	; 70




; **************************************************
;  Reset Vector
; **************************************************

RESET:	
		CLD				; clear decimal mode
		LDX #$FF			; empty the stack
		TXS

		JSR VGA_CLEAR			; clear the screen
		LDA #$00			; reset keyboard state
		STA PS2_STATE

		LDX #16				; print the 16 character welcome banner
LOOP:	
		LDA SYS_WELCOME-1, X
		STA VGA_IO-1, X
		DEX
		BNE LOOP

		LDY #END_CODE - LAB_vec		; copy vectors to page 2 for BASIC
LAB_stlp:
		LDA LAB_vec-1, Y
		STA VEC_IN-1, Y
		DEY
		BNE LAB_stlp


		JMP LAB_COLD			; start BASIC



; *********************************************
;             VGA Clear
; *********************************************

VGA_CLEAR:				; clear 2400 bytes / $960 bytes / 80x30 cols x rows
		LDA #$C0		; VGA_POS = $C000
		STA VGA_POS + 1
		LDA #$00
		STA VGA_POS
		TAY			; Y = 0
		LDX #9			; clear 9 pages
VGA_CLEAR_PAGE:
		STA (VGA_POS), Y
		INY
		BNE VGA_CLEAR_PAGE
		INC VGA_POS+1
		DEX
		BNE VGA_CLEAR_PAGE

		LDX #$60		; clear $60 remaining bytes
VGA_CLEAR_BYTE:
		STA (VGA_POS), Y
		INY
		DEX
		BNE VGA_CLEAR_BYTE
		
		LDA #$C0		; reset output and cursor positions
		STA VGA_POS+1
		LDA #$00
		STA VGA_POS
		STA VGA_CURX
		STA VGA_CURY
		RTS


; *********************************************
;             VGA Scroll
; *********************************************

VGA_SCROLL:
		LDA #$C0		; Init src/dst for copy operation
		STA VGA_POS+1
		STA VGA_SRC+1
		LDA #$50
		STA VGA_SRC
		LDA #$00
		STA VGA_POS
		
		TAY			; Y = 0
		LDX #9			; copy 9 pages
VGA_SCROLL_PAGE:
		LDA (VGA_SRC),Y
		STA (VGA_POS),Y
		INY
		BNE VGA_SCROLL_PAGE
		INC VGA_SRC+1
		INC VGA_POS+1
		DEX
		BNE VGA_SCROLL_PAGE
		
		LDX #16			; copy remaining 16 bytes
VGA_SCROLL_BYTE:
		LDA (VGA_SRC),Y
		STA (VGA_POS),Y
		INY
		DEX
		BNE VGA_SCROLL_BYTE
		
		LDA VGA_POS		; adjust VGA_POS to start of last line
		ADC #15
		STA VGA_POS
		
		LDX #$50		; clear 80 bytes on last line
		LDA #0
		TAY
VGA_SCROLL_CLL:
		STA (VGA_POS),Y
		INY
		DEX
		BNE VGA_SCROLL_CLL

		DEC VGA_CURY
		RTS
		

; **********************************************
;                VGA Write
; **********************************************

VGA_OUT:
		STA TEMP		; save X register
		TXA
		PHA
		TYA
		PHA
		LDA TEMP

		CMP #$0A		; is it a line feed?
		BEQ VGA_LF
		CMP #$0D		; is it a carriage return
		BEQ VGA_CR
		CMP #$08		; is it backspace
		BEQ VGA_BS
					; must be a normal printable character
		
		LDY #0			; write char at current position
		STA (VGA_POS),Y
		
		CLC			; increment position by one
		LDA VGA_POS
		ADC #1
		STA VGA_POS
		BCC VGA_OUT_NOCRY
		INC VGA_POS+1
VGA_OUT_NOCRY:
		
		LDA VGA_CURX		; update cursor x position
		INC VGA_CURX		; increment cursor x position
		CMP #80			
		BCC VGA_OUT_NOTEOL
		LDA #0			; if cursor x pos is 80, make it zero and inc y position
		STA VGA_CURX
		INC VGA_CURY
VGA_OUT_NOTEOL:
		JMP VGA_DONE
		
VGA_LF:
		CLC			; clear carry
		LDA VGA_POS		; add 80 position (one line down)
		ADC #80
		STA VGA_POS
		BCC VGA_LF_NOCRY
		INC VGA_POS+1
VGA_LF_NOCRY:
		INC VGA_CURY
		JMP VGA_DONE

VGA_CR:
		SEC			; set carry
		LDA VGA_POS		; subtract current cursor x position
		SBC VGA_CURX
		STA VGA_POS
		BCS VGA_CR_NOBRW
		DEC VGA_POS+1
VGA_CR_NOBRW:
		LDA #0
		STA VGA_CURX
		JMP VGA_DONE

VGA_BS:
		LDA VGA_CURX
		BEQ VGA_DONE
		DEC VGA_CURX
		
		SEC
		LDA VGA_POS
		SBC #1
		STA VGA_POS
		BCS VGA_BS_NOBRW
		DEC VGA_POS+1
VGA_BS_NOBRW:
		LDA #0
		TAY
		STA (VGA_POS),Y

VGA_DONE:
		LDA VGA_CURY
		CMP #30
		BNE VGA_CURSOR
		JSR VGA_SCROLL

VGA_CURSOR:
		LDA VGA_CURX		; update cursor position
		STA $CBFC
		LDA VGA_CURY
		STA $CBFD

		PLA
		TAY
		PLA			; restore A & X registers and return
		TAX
		LDA TEMP
		RTS



; ************************************************
;                PS2 Read
; ************************************************

PS2_IN:
		STA TEMP		; save X register
		TXA
		PHA
		LDA TEMP

		LDA PS2_CHAR		; get the current char
		STA TEMP
		BEQ PS2_NOCHAR		; if it's zero, there's no char
		LDX #0			; clear char
		STX PS2_CHAR
		SEC			; set carry to indicate char available
		JMP PS2_DONE
PS2_NOCHAR:
		CLC			; clear carry, no char available
PS2_DONE:
		PLA			; restore A & X registers and return
		TAX
		LDA TEMP
NO_LOAD:
NO_SAVE:
		RTS



; *************************************************
;           PS2 Interrupt Handler
; *************************************************

PS2_INT:
		PHA				; save A & X registers
		TXA
		PHA

		LDA $CC00			; read char from keyboard interface
		TAX
		CMP #$F0			; is a key being released?
		BEQ PS2_SET_RELEASE
		CMP #$80			; is it extended?
		BEQ PS2_SET_EXT
		
		LDA #2				; is release flag set?
		BIT PS2_STATE
		BNE PS2_RELEASE
		
		LDA #1				; is ext flag set?
		BIT PS2_STATE
		BNE PS2_EXT

						; normal key
		CPX #$12			; is it left shift?
		BEQ PS2_SET_SHIFT
		CPX #$59			; is it right shift?
		BEQ PS2_SET_SHIFT

		LDA #16				; choose translation table
		BIT PS2_STATE
		BNE PS2_TRANS_SHIFT
		
		LDA PS2_TAB, X			; non shift translation
		STA PS2_CHAR
		STA PS2_DOWN
		JMP KBDONE
PS2_TRANS_SHIFT:
		LDA PS2_SHIFT_TAB, X		; shift translation
		STA PS2_CHAR
		JMP KBDONE

PS2_RELEASE:
		LDA PS2_STATE			; clear bit 2 (release)
		AND #$FD
		STA PS2_STATE
		
		CPX #$12			; Left Shift?
		BEQ PS2_REL_SHIFT
		CPX #$59			; Right Shift?
		BEQ PS2_REL_SHIFT
		LDA PS2_TAB, X
		CMP PS2_DOWN
		BNE KBDONE
		LDA #0
		STA PS2_DOWN
		JMP KBDONE

PS2_SET_SHIFT:
		LDA PS2_STATE			; set bit 5 (shift down)
		ORA #16
		STA PS2_STATE
		JMP KBDONE
		
PS2_REL_SHIFT:
		LDA PS2_STATE
		AND #$EF			; clear bit 5 (shift down)
		STA PS2_STATE
		JMP KBDONE

PS2_EXT:
		LDA PS2_STATE
		AND #$FE			; clear bit 1 (extended)
		STA PS2_STATE
		JMP KBDONE

PS2_SET_RELEASE:
		LDA PS2_STATE			; set bit 2 (release)
		ORA #2
		STA PS2_STATE
		JMP KBDONE
		
PS2_SET_EXT:					; set bit 1 (extended)
		LDA PS2_STATE
		ORA #1
		STA PS2_STATE
		JMP KBDONE

KBDONE:
		PLA
		TAX
		PLA
		RTI



LAB_vec:
		.word PS2_IN
		.word VGA_OUT
		.word NO_LOAD
		.word NO_SAVE
END_CODE:












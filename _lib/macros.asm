.macro SaveRegisters() {
		pha
   		txa
   		pha
   		tya
   		pha
}

.macro LoadRegisters() {
		pla
   		tay
   		pla
   		tax 
   		pla
}

.macro StabilizeIRQ(num) {
		lda #<WedgeIRQ
		sta $fffe
		lda #>WedgeIRQ
		sta $ffff
		.if(num == null) {
				inc $d012
		} else {
			lda $d012
			clc
			adc #num
			sta $d012
		}
		lda #$01
		sta $d019
		tsx
		cli

		// Execute NOPs untill the raster line changes and the Raster IRQ triggers
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop

	WedgeIRQ:
		//stabilise raster
		txs
		ldx #$08 
		dex        
		bne *-1    
		bit $00

		lda $d012
		cmp $d012
		beq *+2
		//STABLE CODE
}

.macro SetIRQ(line, handler) {
		lda #<line
		sta $d012
		lda $d011
		.if(line > $ff) {
			ora #$80
		} else {
			and #$7f
		}
		sta $d011
		lda #<handler
		sta $fffe
		lda #>handler
		sta $ffff
}

.macro wasteCycles(delay) {
	.var bits = floor(delay / 3)
	.if(delay - (bits * 3) == 1) {
		.eval bits -= 1
	}
	.var nops = (delay - (bits * 3)) / 2;
	.for(var i=0; i<bits;i++) {
		bit $ea
	}
	.for(var i=0; i<nops;i++) {
		nop
	}
}
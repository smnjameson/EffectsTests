        * = $3000
 
.label y1       = $40
.label y2       = $41
.label x1       = $42
.label x2       = $43
.label err      = $44
.label clk      = $46
.label dy       = $47
.label pos      = $48
.label step     = $49
.label fade     = $52
.label offset   = $51

 
         jmp start
irq1:
         dec $d019
         ldy #$00
loop0:
         //do fli
sta18:
         lda #$00
         sta $d018
sta11:
         lda #$1b
         sta $d011
 
         //prepare next values
         lda tab11,y
         sta sta11+1
         lda tab18,y
         sta sta18+1
 
         //wait for right moment
         bit $ea
 
         //set x-positions of cover sprite 1
         lda xpos,y
         //even too lazy to add an offset to the table, as we have enough cycles available
         adc #$66
         sta $d000
         adc #$c0
         eor #$ff
 
         //wait a bit, so that is cocky, right? :-)
         nop
         nop
 
         //advance y-position of sprites
         ldx ypos,y
         stx $d001
         stx $d003
 
         //set x-positions of cover sprite 2
         iny
         sta $d002
 
         //enough cycles left to enjoy the luxury of a loop
         cpy #100
         bcc loop0
 
         //all lines done, display something sane
col1:
         lda #$01
         sta $d020
         lda #$f0
         sta $d018
         lda #$50
         sta $d011
 
         //interlace between both banks
         lda $dd00
         and #$03
         eor #$02
         sta $dd00
 
         //even do a $d016 shift
         lda $d016
         eor #$01
         sta $d016
 
         //our fancy rasterline
         nop
         nop
         nop
         nop
         nop
         nop
         nop
         nop
col2:
         lda #$01
         sta $d020
 
         inc clk
 
         //update tables and colors
         jsr update
         jsr colors
col3:
         lda #$01
         sta $d020
         //jsr $1003
 
         //return from irq
         pla
         tay
         pla
         tax
         pla
         rti
 
start:
         sei
         //sync and turn off screen
         lda $d011
         bpl *-3
         lda $d011
         bmi *-3
         lda #$0b
         sta $d011
         lda $d011
         bpl *-3
         lda $d011
         bmi *-3
 
         //set up $d011 table
         ldx #$00
loop2:
         txa
         asl
         ora #$01
         and #$07
         ora #$10
         sta tab11,x
         inx
         bne loop2
 
         //set up colors
         lda #$09
         ldx #$00
loop3:
         sta $d800,x
         sta $d900,x
         sta $da00,x
         sta $db00,x
         dex
         bne loop3
 
         //init values
         lda #$00
         sta x1
         lda #$00
         sta y1
         lda #$00
         sta x2
         lda #99
         sta y2
 
         ldx #$d0
         stx clk
 
         ldx #$00
         stx pos
         stx step
         stx fade
         stx pos
         stx offset
 
         //copy 2nd bank
         lda #$34
         sta $01
         ldx #$3f
         ldy #$00
!:
src:
         lda $8000,y
dst:
         sta $c000,y
         dey
         bne !-
         inc src+2
         inc dst+2
         dex
         bne !-
         inc $01
 
         //fade to white
         ldy #$00
!:
         ldx #$04
         jsr wait
         lda fadec,y
         sta $d020
         iny
         cpy #$07
         bne !-
 
         //create display tables for the first time
         jsr update
 
         //vsync
         lda $d011
         bpl *-3
         lda $d011
         bmi *-3
 
         //copy last bytes now to not distroy any still active irq-pointers @ $fffe
         ldy #$00
!:
         lda $bf00,y
         sta $ff00,y
         dey
         bne !-
 
         //now use irq @ vector $0314, but we could also just use the vector @ $fffe/f as long as we have no needed data there
         sei
         lda #$37
         sta $01
         lda #$7f
         sta $dc0d
         lda $dc0d
         lda #$0b
         sta $d011
         lda #$30
         sta $d012
         lda #<irq1
         sta $0314
         lda #>irq1
         sta $0315
         lda #$01
         sta $d01a
 
         //setup sprites and colors and things
         lda #$01
         sta $d025
         sta $d026
         sta $d027
         sta $d028
         sta $d021
         sta $d022
         sta $d023
         sta $d020
         lda #$03
         sta $d015
         lda #$03
         sta $d017
         sta $d01d
         sta $d01c
         lda #$32
         sta $d001
         sta $d003
         lda #$18
         sta $d000
         lda #$28
         sta $d002
         lda #$02
         sta $d010
         ldx #$f0
         stx $7ff8
         stx $7ff9
         lda #$02
         sta $dd00
         lda #$18
         sta $d016
         cli
 
         jmp *
 
fadec:
         .byte $00,$09,$08,$0a,$0f,$07,$01
 
wait:
         lda $d011
         bmi *-3
         lda $d011
         bpl *-3
         lda #$30
         cmp $d012
         bne *-3
         dex
         bne wait
         rts
 
update:
         inc offset
         inc offset
         lda offset
         cmp #64
         bcc *+6
         lda #$00
         sta offset
 
         lda clk
         and #$01
         bne step0o
 
         //decide what to update (upper x pos, lower x pos, move xpos to left/right)
         lda step
         cmp #$00
         beq step0
         cmp #$01
         beq step1
         cmp #$02
         beq step2
         cmp #$03
         beq step3
         lda #$00
         sta step
         jmp update
step0:
         inc x2
         lda x2
         cmp #99
         bne step0o
         inc step
step0o:
         jmp drawline
 
step1:
         inc x1
         dec x2
         lda x2
         bne step1o
         inc step
step1o:
         jmp drawline
step2:
         dec x1
         inc x2
         lda x2
         cmp #99
         bne step2o
         inc step
step2o:
         jmp drawline
step3:
         dec x2
         lda x2
         bne step3o
         inc step
step3o:
         //jmp drawline
 
drawline:
         //setup bresenham (dx/dy, inx/dex)
         lda y2
         sta toy+1
         sec
         sbc y1
         sta ty2+1
         lsr
         sta err
 
         ldx #$e8
         lda x2
         sec
         sbc x1
         bcs ov2
         eor #$ff
         adc #$01
         ldx #$ca
ov2:
         stx incx2
         sta tx2+1
 
         lda x1
         clc
         adc offset
         tax
 
         //bresenham to calc slope
         ldy y1
loopy:
         lda mytab18,x
         sta tab18,y
         lda myxpos,x
         sta xpos,y
         lda err
         sec
tx2:
         sbc #$00
         bcs !+
ty2:
         adc #$00
incx2:
         inx
!:
         sta err
         iny
toy:
         cpy #$00
         bne loopy
         rts
 
colors:
         //all the color fadings
         lda clk
         cmp #$e0
         bcs *+3
         rts
 
         and #$03
         bne !Skip+
 
         lda fade
         cmp #$28
         bne !+
         lda #$00
         sta fade
         beq *+2
!:
         inc fade
         tax
         lda fade1,x
         sta $d021
         lda fade2,x
         sta $d022
         lda fade3,x
         sta $d023
         lda fade00,x
         sta $d025
         sta col1+1
         lda fade0b,x
         sta $d027
         sta $d028
         lda fade0c,x
         sta col3+1
         sta $d026
         lda fade0f,x
         sta col2+1
!Skip:
         rts
 
         //fading tables
fade0f:
         .byte $01,$01,$01,$01
         .byte $01,$01,$01,$0f
         .byte $0f,$0f,$0f,$0f
         .byte $0f,$0f,$0f,$0f
         .byte $0f,$0f,$0f,$0f
         .byte $0f,$0f,$0f,$0f
         .byte $0f,$0f,$0f,$0f
         .byte $0f,$0f,$0f,$0f
         .byte $0f,$01,$01,$01
         .byte $01,$01,$01,$01
fade00:
         .byte $01,$01,$01,$01
         .byte $0f,$0c,$0b,$00
         .byte $00,$00,$00,$00
         .byte $00,$00,$00,$00
         .byte $00,$00,$00,$00
         .byte $00,$00,$00,$00
         .byte $00,$00,$00,$00
         .byte $00,$00,$00,$00
         .byte $00,$0b,$0c,$0f
         .byte $01,$01,$01,$01
fade0c:
         .byte $01,$01,$01,$01
         .byte $01,$01,$0f,$0c
         .byte $0c,$0c,$0c,$0c
         .byte $0c,$0c,$0c,$0c
         .byte $0c,$0c,$0c,$0c
         .byte $0c,$0c,$0c,$0c
         .byte $0c,$0c,$0c,$0c
         .byte $0c,$0c,$0c,$0c
         .byte $0c,$0f,$01,$01
         .byte $01,$01,$01,$01
fade0b:
         .byte $01,$01,$01,$01
         .byte $01,$0f,$0c,$0b
         .byte $0b,$0b,$0b,$0b
         .byte $0b,$0b,$0b,$0b
         .byte $0b,$0b,$0b,$0b
         .byte $0b,$0b,$0b,$0b
         .byte $0b,$0b,$0b,$0b
         .byte $0b,$0b,$0b,$0b
         .byte $0b,$0c,$0f,$01
         .byte $01,$01,$01,$01
 
fade1:
         .byte $01,$01,$01,$01
         .byte $01,$0d,$0f,$05
         .byte $05,$0f,$0d,$01
         .byte $01,$07,$0f,$0a
         .byte $0a,$0f,$07,$01
         .byte $01,$0d,$03,$0e
         .byte $0e,$03,$0d,$01
         .byte $01,$07,$0f,$0a
         .byte $0a,$0f,$07,$01
         .byte $01,$01,$01,$01
fade2:
         .byte $01,$01,$01,$01
         .byte $01,$01,$0d,$0f
         .byte $0f,$0d,$01,$01
         .byte $01,$01,$07,$0f
         .byte $0f,$07,$01,$01
         .byte $01,$01,$0d,$03
         .byte $03,$0d,$01,$01
         .byte $01,$01,$07,$0f
         .byte $0f,$07,$01,$01
         .byte $01,$01,$01,$01
fade3:
         .byte $01,$01,$01,$01
         .byte $01,$01,$01,$0d
         .byte $0d,$01,$01,$01
         .byte $01,$01,$01,$07
         .byte $07,$01,$01,$01
         .byte $01,$01,$01,$0d
         .byte $0d,$01,$01,$01
         .byte $01,$01,$01,$07
         .byte $07,$01,$01,$01
         .byte $01,$01,$01,$01
 
         //sprite y-positions
ypos:
         .byte $32,$32,$32,$32
         .byte $32,$32,$32,$32
         .byte $32,$32,$32,$32
         .byte $32,$32,$32,$32
         .byte $32,$32,$32,$32
         .byte $32
 
         .byte $5c,$5c,$5c,$5c
         .byte $5c,$5c,$5c,$5c
         .byte $5c,$5c,$5c,$5c
         .byte $5c,$5c,$5c,$5c
         .byte $5c,$5c,$5c,$5c
         .byte $5c
 
         .byte $86,$86,$86,$86
         .byte $86,$86,$86,$86
         .byte $86,$86,$86,$86
         .byte $86,$86,$86,$86
         .byte $86,$86,$86,$86
         .byte $86
 
         .byte $b0,$b0,$b0,$b0
         .byte $b0,$b0,$b0,$b0
         .byte $b0,$b0,$b0,$b0
         .byte $b0,$b0,$b0,$b0
         .byte $b0,$b0,$b0,$b0
         .byte $b0
 
         .byte $da,$da,$da,$da
         .byte $da,$da,$da,$da
         .byte $da,$da,$da,$da
         .byte $da,$da,$da,$da
         .byte $da,$da,$da,$da
         .byte $da
 
         //corresponding $d018 values for each fragment
mytab18:
         .byte $10,$30,$50,$70
         .byte $12,$32,$52,$72
         .byte $14,$34,$54,$74
         .byte $16,$36,$56,$76
         .byte $18,$38,$58,$78
         .byte $1a,$3a,$5a,$7a
         .byte $1c,$3c,$5c,$7c
         .byte $1e,$3e,$5e,$7e
 
         .byte $10,$30,$50,$70
         .byte $12,$32,$52,$72
         .byte $14,$34,$54,$74
         .byte $16,$36,$56,$76
         .byte $18,$38,$58,$78
         .byte $1a,$3a,$5a,$7a
         .byte $1c,$3c,$5c,$7c
         .byte $1e,$3e,$5e,$7e
 
         .byte $10,$30,$50,$70
         .byte $12,$32,$52,$72
         .byte $14,$34,$54,$74
         .byte $16,$36,$56,$76
         .byte $18,$38,$58,$78
         .byte $1a,$3a,$5a,$7a
         .byte $1c,$3c,$5c,$7c
         .byte $1e,$3e,$5e,$7e
 
         .byte $10,$30,$50,$70
         .byte $12,$32,$52,$72
         .byte $14,$34,$54,$74
         .byte $16,$36,$56,$76
         .byte $18,$38,$58,$78
         .byte $1a,$3a,$5a,$7a
         .byte $1c,$3c,$5c,$7c
         .byte $1e,$3e,$5e,$7e
 
         .byte $10,$30,$50,$70
         .byte $12,$32,$52,$72
         .byte $14,$34,$54,$74
         .byte $16,$36,$56,$76
         .byte $18,$38,$58,$78
         .byte $1a,$3a,$5a,$7a
         .byte $1c,$3c,$5c,$7c
         .byte $1e,$3e,$5e,$7e
 
         .byte $10,$30,$50,$70
         .byte $12,$32,$52,$72
         .byte $14,$34,$54,$74
         .byte $16,$36,$56,$76
         .byte $18,$38,$58,$78
         .byte $1a,$3a,$5a,$7a
         .byte $1c,$3c,$5c,$7c
         .byte $1e,$3e,$5e,$7e
 
         .byte $10,$30,$50,$70
         .byte $12,$32,$52,$72
         .byte $14,$34,$54,$74
         .byte $16,$36,$56,$76
         .byte $18,$38,$58,$78
         .byte $1a,$3a,$5a,$7a
         .byte $1c,$3c,$5c,$7c
         .byte $1e,$3e,$5e,$7e
 
         .byte $10,$30,$50,$70
         .byte $12,$32,$52,$72
         .byte $14,$34,$54,$74
         .byte $16,$36,$56,$76
         .byte $18,$38,$58,$78
         .byte $1a,$3a,$5a,$7a
         .byte $1c,$3c,$5c,$7c
         .byte $1e,$3e,$5e,$7e
 
         //xpos table for sprite (TODO: should also be generated)
myxpos:
         .byte $aa,$a9,$a8,$a7,$a6,$a5
         .byte $a4,$a4,$a3,$a2,$a2,$a1
         .byte $a1,$a1,$a1,$a1,$a0,$a1
         .byte $a1,$a1,$a1,$a1,$a2,$a2
         .byte $a3,$a4,$a4,$a5,$a6,$a7
         .byte $a8,$a9
 
         .byte $aa,$a9,$a8,$a7,$a6,$a5
         .byte $a4,$a4,$a3,$a2,$a2,$a1
         .byte $a1,$a1,$a1,$a1,$a0,$a1
         .byte $a1,$a1,$a1,$a1,$a2,$a2
         .byte $a3,$a4,$a4,$a5,$a6,$a7
         .byte $a8,$a9
 
         .byte $aa,$a9,$a8,$a7,$a6,$a5
         .byte $a4,$a4,$a3,$a2,$a2,$a1
         .byte $a1,$a1,$a1,$a1,$a0,$a1
         .byte $a1,$a1,$a1,$a1,$a2,$a2
         .byte $a3,$a4,$a4,$a5,$a6,$a7
         .byte $a8,$a9
 
         .byte $aa,$a9,$a8,$a7,$a6,$a5
         .byte $a4,$a4,$a3,$a2,$a2,$a1
         .byte $a1,$a1,$a1,$a1,$a0,$a1
         .byte $a1,$a1,$a1,$a1,$a2,$a2
         .byte $a3,$a4,$a4,$a5,$a6,$a7
         .byte $a8,$a9
 
         .byte $aa,$a9,$a8,$a7,$a6,$a5
         .byte $a4,$a4,$a3,$a2,$a2,$a1
         .byte $a1,$a1,$a1,$a1,$a0,$a1
         .byte $a1,$a1,$a1,$a1,$a2,$a2
         .byte $a3,$a4,$a4,$a5,$a6,$a7
         .byte $a8,$a9
 
         .byte $aa,$a9,$a8,$a7,$a6,$a5
         .byte $a4,$a4,$a3,$a2,$a2,$a1
         .byte $a1,$a1,$a1,$a1,$a0,$a1
         .byte $a1,$a1,$a1,$a1,$a2,$a2
         .byte $a3,$a4,$a4,$a5,$a6,$a7
         .byte $a8,$a9
 
         .byte $aa,$a9,$a8,$a7,$a6,$a5
         .byte $a4,$a4,$a3,$a2,$a2,$a1
         .byte $a1,$a1,$a1,$a1,$a0,$a1
         .byte $a1,$a1,$a1,$a1,$a2,$a2
         .byte $a3,$a4,$a4,$a5,$a6,$a7
         .byte $a8,$a9
 
         .byte $aa,$a9,$a8,$a7,$a6,$a5
         .byte $a4,$a4,$a3,$a2,$a2,$a1
         .byte $a1,$a1,$a1,$a1,$a0,$a1
         .byte $a1,$a1,$a1,$a1,$a2,$a2
         .byte $a3,$a4,$a4,$a5,$a6,$a7
         .byte $a8,$a9
 
         //the final tables to be displayed
         *= $3d00
xpos:
         *= $3e00
tab18:
         *= $3f00
tab11:
 
         //include generated data

.var file = LoadBinary("5col.data")
* = $4000
.fill $4000, file.get(i+ $0002) 

* = $8000
.fill $4000, file.get(i+ $4002) 

* = $02 virtual

SX: .byte $00
IX: .byte $00
COL_INDEX: .byte $00
ANIM_INDEX: .byte $00

BasicUpstart2(Entry)


Entry:
   sei
   lda #$35
   sta $01

   lda #$1c
   sta $d018

   lda #$7f
   sta $dc0d
   sta $dd0d

   lda $d01a
   ora #$01
   sta $d01a

   lda #$30
   sta $d012
   lda $d011
   and #$7f
   sta $d011

   lda #<IRQ
   sta $fffe
   lda #>IRQ
   sta $ffff

   asl $d019
   cli


   //Setup sprite
   lda #$ff
   sta $d015

   lda #$fe
   .for(var i=0; i<8; i++){
      sta $07f8 + i
   }

   lda #$32
   .for(var i=0; i<8; i++){
      sta $d001 + i * 2
   }

   .for(var i=0; i<8; i++){
      lda colRamp + i
      sta $d027 + i
   }

   //TEXT
   ldx #$00
!:
   lda $2800, x
   sta $0400, x
   lda $2800 + 140, x
   sta $0400 + 140, x
   lda #$00
   sta $d800, x
   sta $d800 + 140, x
   inx
   cpx #140
   bne !-


   lda #$ff
   sta $d01b
   lda #$55
   sta $d01d

   lda #$00
   sta $d020
   sta $d021


!Loop:
   jmp !Loop-



.align $100
IRQ: {
   pha
   txa
   pha
   tya
   pha


   lda #<WedgeIRQ
   sta $fffe
   lda #>WedgeIRQ
   sta $ffff
   inc $d012
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

.align $100
WedgeIRQ:
      //stabilise raster
      txs
      ldx #$08 
      dex        
      bne *-1    
      ldx IX
      lda $d012
      cmp $d012
      beq *+2

      //STABLE CODE
!Loop:     
      //Apply sprite crunch
      ldy CrunchData, x //4
      bit $00 //3
      nop //2
      sty $d017 //4
      

      sta $d021 //4
      inc MOD + 1 //6
   MOD:
      lda ColorData //4
      nop //2
      nop //2
 
      //Supress badlines and do FLD      // lda $d012 //4
      ldy BadLines, x //4
      sty $d011 //4

      //Repeat until end of sprite crunch
      dex //2
      bne !Loop- //3

      
      //Setup base area
      nop
      nop
      nop
      ldx #$0c
      stx $d021


      //Reset crunch counter
      ldx #157
      stx IX
      //reset VScroll 
      lda #$11
      sta $d011

      //Reset COLS
      inc ANIM_INDEX
      ldx ANIM_INDEX 
      lda HBars, x
      sta COL_INDEX
      sta MOD + 1

      //Wait for vblank
      lda #$fe
      cmp $d012
      bne *-3

      //Move sprite Xs
      lda #$00
      sta $d010
      ldy ANIM_INDEX
      .for(var i=0; i<8; i++) {
            nop
            lda XPos0, y
            nop
            sta $d000 + i * 2
            lda XPos1, y
            beq !+
            lda $d010
            ora #[pow(2, i)]
            sta $d010
         !:
            tya
            clc
            adc #$20
            tay
      }


       //Restore raster
      lda #<IRQ
      sta $fffe
      lda #>IRQ
      sta $ffff
      lda #$30
      sta $d012
      asl $d019

      pla
      tay
      pla
      tax
      pla
      rti
}

* = $2800
      .import binary "./assets/map.bin"
* = $3000
      .import binary "./assets/chars.bin"


colRamp:
      .byte $0b,$02,$04,$0e
      .byte $03,$0d,$07,$01

.align $100
ColorData:
   .fill 16, $00
   .fill 16, $0b
   .fill 16, $02
   .fill 16, $04

   .fill 16, $0e
   .fill 16, $03
   .fill 16, $0d
   .fill 16, $07

   .fill 16, $01
   .fill 16, $07
   .fill 16, $0d
   .fill 16, $03

   .fill 16, $0e
   .fill 16, $04
   .fill 16, $02
   .fill 16, $0b

HBars:
   .fill 256, sin((i/256) * PI * 2) * 128  + 128
XPos0:
   .fill 256, <[floor(sin((i/256) * PI * 2) * 136)  + 160]
XPos1:
   .fill 256, >[floor(sin((i/256) * PI * 2) * 136)  + 160]

.align $100
BadLines:
   .byte $00,$1d,$1c,$1b,$1a,$19,$18
   .byte $1f,$1e,$1d,$1c,$1b,$1a,$19,$18
   .byte $1f,$1e,$1d,$1c,$1b,$1a,$19,$18

   .byte $1f,$1e,$1d,$1c,$1b,$1a,$19,$18
   .byte $1f,$1e,$1d,$1c,$1b,$1a,$19,$18
   .byte $1f,$1e,$1d,$1c,$1b,$1a,$19,$18
   .byte $1f,$1e,$1d,$1c,$1b,$1a,$19,$18
   .byte $1f,$1e,$1d,$1c,$1b,$1a,$19,$18
   .byte $1f,$1e,$1d,$1c,$1b,$1a,$19,$18
   .byte $1f,$1e,$1d,$1c,$1b,$1a,$19,$18
   .byte $1f,$1e,$1d,$1c,$1b,$1a,$19,$18

   .byte $1f,$1e,$1d,$1c,$1b,$1a,$19,$18
   .byte $1f,$1e,$1d,$1c,$1b,$1a,$19,$18
   .byte $1f,$1e,$1d,$1c,$1b,$1a,$19,$18
   .byte $1f,$1e,$1d,$1c,$1b,$1a,$19,$18
   .byte $1f,$1e,$1d,$1c,$1b,$1a,$19,$18
   .byte $1f,$1e,$1d,$1c,$1b,$1a,$19,$18
   .byte $1f,$1e,$1d,$1c,$1b,$1a,$19,$18
   .byte $1f,$1e,$1d,$1c,$1b,$1a,$19,$18
   .byte $1f,$1e,$1d,$1c,$1b,$1a,$19
   .byte $1c,$1b,$1a,$19,$18
   .byte $1f,$1e,$1d,$1c,$1b,$1a,$19,$18


.align $100
CrunchData:
   .byte $ff,$00,$ff,$00,$ff,$00,$ff,$00,$ff,$00,$ff,$00,$ff,$00,$ff,$00,$ff,$00,$ff,$00,$ff
   .byte $ff,$00,$ff,$00,$ff,$00,$ff,$00,$ff,$00,$ff,$00,$ff,$00,$ff,$00,$ff,$00,$ff,$00,$ff
   .byte $ff,$00,$ff,$00,$ff,$00,$ff,$00,$ff,$00,$ff,$00,$ff,$00,$ff,$00,$ff,$00,$ff,$00,$ff
   .byte $ff,$00,$ff,$00,$ff,$00,$ff,$00,$ff,$00,$ff,$00,$ff,$00,$ff,$00,$ff,$00,$ff,$00,$ff
   .byte $ff,$00,$ff,$00,$ff,$00,$ff,$00,$ff,$00,$ff,$00,$ff,$00,$ff,$00,$ff,$00,$ff,$00,$ff
   .byte $ff,$00,$ff,$00,$ff,$00,$ff,$00,$ff,$00,$ff,$00,$ff,$00,$ff,$00,$ff,$00,$ff,$00,$ff
   .byte $ff,$00,$ff,$00,$ff,$00,$ff,$00,$ff,$00,$ff,$00,$ff,$00,$ff,$00,$ff,$00,$ff,$00,$ff
   .byte $ff,$00,$ff,$00,$ff,$00,$ff,$00,$ff,$00,$ff,$00,$ff,$00,$ff,$00,$ff,$00,$ff,$00,$ff
   .byte $ff,$00,$ff,$00,$ff,$00,$ff,$00,$ff,$00,$ff,$00,$ff,$00,$ff,$00,$ff,$00,$ff,$00,$ff



//SPRITES
* = $3f80
   .fill 64, $ff
   .fill 64, 0   //Garbage byte



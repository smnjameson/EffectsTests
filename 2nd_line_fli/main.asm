#import "../_lib/macros.asm"
#import "../_lib/table_macros.asm"


BasicUpstart2(Entry)

Entry:
   sei
   lda #$35
   sta $01

   // lda #$1c
   // sta $d018

   lda #$7f
   sta $dc0d
   sta $dd0d

   lda $d01a
   ora #$01
   sta $d01a

   :SetIRQ($02d, IRQ)

   jsr SetupScreen
   jsr SetTables
   jsr SetSprites

   lda #[14 * 8- 7]
   sta FLI_START

   lda #$02    //Set vic bank
   sta $dd00

   lda #$d8
   sta $d016

   lda #$00
   sta $d020

   lda #$0b
   sta $d022
   lda #$01
   sta $d023

   asl $d019
   cli


!Loop:
   jmp *


SetSprites: {
         lda #$d0
      .for(var i=0; i<14;i++) {
         sta $4000 + $400 * i + $3f8
         sta $4000 + $400 * i + $3f9
      }

         lda #$03
         sta $d015

         lda #$00
         sta $d027
         sta $d028

         lda #$42
         sta $d010

         lda #$18
         sta $d000
         lda #$28
         sta $d002

         lda #[[14 * 8 - 7] + $30] - 1
         sta $d001 
         sta $d003

         lda #$ff
         sta $d01d

         lda #$ff
         sta $d017


         lda #$00
         sta $d01c

         ldx #$d1 
         ldy #$40
         .for(var i=0; i<5; i++) {
            stx $5800 + $3f8 + 2 + i
            sty $d005 + i * 2
            lda #$40 + i * 48
            sta $d004 + i * 2
            lda #$01
            sta $d029 + i
         }
         rts
}

SetupScreen: {
         //colors
         ldx #$00
         lda #$06
      !:
         ldy $5800, x
         lda CharColors, y
         sta $d800, y

         ldy $5800 + 130, x
         lda CharColors, y
         sta $d800 + 130, x

         ldy $5800 + 260, x
         lda CharColors, y
         sta $d800 + 260, x

         ldy $5800 + 390, x
         lda CharColors, y
         sta $d800 + 390, x
         inx
         cpx #130
         bne !-

         ldx #$00
         lda #$08
      !:
         sta $d800 + 480, x
         inx
         cpx #40
         bne !-    


         ldx #$00
         lda #$0d
      !:
         sta $d800 + 520, x
         sta $d800 + 760, x
         inx
         cpx #240
         bne !-    

         lda #$00
         .for(var i=0; i<13; i++) {
            sta $d800 + i * 40 + 0
            sta $d800 + i * 40 + 1
            sta $d800 + i * 40 + 2
            sta $d800 + i * 40 + 3
            sta $d800 + i * 40 + 4
            sta $d800 + i * 40 + 5
            sta $d800 + i * 40 + 39
            sta $d800 + i * 40 + 38
            sta $d800 + i * 40 + 37
            sta $d800 + i * 40 + 36
            sta $d800 + i * 40 + 35
            sta $d800 + i * 40 + 34
         }

      //screens
      .for(var i=13; i<25; i++) {
         ldx #$27
      !:
         lda $5800 + i * 40, x

         sta $4000 + i * 40 - 6, x
         sta $4400 + i * 40 - 5, x
         sta $4800 + i * 40 - 4, x
         sta $4c00 + i * 40 - 3, x
         sta $5000 + i * 40 - 2, x
         sta $5400 + i * 40 - 1, x

         sta $5c00 + i * 40 + 1, x
         sta $6000 + i * 40 + 2, x
         sta $6400 + i * 40 + 3, x
         sta $6800 + i * 40 + 4, x
         sta $6c00 + i * 40 + 5, x
         sta $7000 + i * 40 + 6, x
         dex
         bpl !-
      }

      rts
}




.align $100
FLI_START: 
      .byte $00

IRQ: {
         :SaveRegisters()
         
      Index:
         ldy #$00

         :StabilizeIRQ(null)


      FLI_LOOP:
         .for(var i=0; i<50; i++) {
               //FLI Line (23 cycles)
               lda #$10 + (((i*2) + 2) & 7)
               sta $d011
            MD016:
               ldx #$1b
               stx $d016
            MD018:
               ldx #$0e
               stx $d018

               // :wasteCycles(2)


               //2nd line (63 cycles)
               lda #$10 + (((i*2) + 3) & 7)
               sta $d011
          
               lda RoadColors, y
               sta $d021

               lda RoadColors + 60, y
               sta $d023

               iny
               
               .if(i >21) {
                  lda #[[14 * 8 - 7] + $30] - 1 + 84
               } else {
                  lda #[[14 * 8 - 7] + $30] - 1 + 42
               }
               sta $d001
               sta $d003

               :wasteCycles(20)
         }




      lda #$00
      sta $d021

            jsr SetNextRoadOffsets

      lda #[[14 * 8 - 7] + $30] - 1
      sta $d001
      sta $d003


      ldy LastMove   
      cpy #32
      bcs !+
      jsr ShiftLeft
      jmp !Skip+
   !:
      cpy #64
      bcc !Skip+
      jsr ShiftRight
   !Skip:
         ldx #$d1
         .for(var i=0; i<5; i++) {
            stx $5800 + $3f8 + 2 + i
         }

      //Do Starting soon
   !:
      lda #$10
      cmp $d012
      bne *-3
      lda $d011
      bmi !-

      lda #$6e
      sta $d018
      lda #$d8
      sta $d016
      lda #$ff
      sta $d015

      lda #$fc
      sta $d01b
      jsr AnimateCBoard
      lda #$04
      sta $d023


      lda #$58
      cmp $d012
      bne *-3

      lda #$00
      sta $d021


      ldx #$d2
      .for(var i=0; i<5; i++) {
         stx $5800 + $3f8 + 2 + i
      }


      //Setup horizon
      lda #$5c
      cmp $d012
      bne *-3

      lda #$00
      sta $d021
      lda #$07
      sta $d023
      lda #$03
      sta $d015







      lda FLI_START
      lsr 
      asl
      clc
      adc #$30
      sta $d012

      lda #$d8
      sta $d016

      lda #<IRQ
      sta $fffe
      lda #>IRQ
      sta $ffff

      // :SetIRQ($02d, IRQ)

      dec $d019
      :LoadRegisters()
      rti
}

LastMove:
      .byte $00

SetNextRoadOffsets: {
   RoadPos:
      ldx #$00

      .for(var i = 0; i< 50; i++) {
            lda Sinus, x
            .if(i==49) {
               sta LastMove
            }
            clc
            adc #<[RoadOffsets + $80 * i]
            sta MMOD + 1
 
            lda #>[RoadOffsets + $80 * i]
            sta MMOD + 2
             // .break
         MMOD:
            ldy $BEEF 

            lda tableD016, y
            sta IRQ.FLI_LOOP[i].MD016 + 1
            lda tableD018, y
            sta IRQ.FLI_LOOP[i].MD018 + 1

            inx
      }


      ldy IRQ.Index + 1
      dey
      dey
      bpl !+
      ldy #$08
   !:
      sty IRQ.Index + 1


      inc RoadPos + 1
      rts
}


SetTables: {
         .for(var i=0; i<96; i++) {
               lda #[mod(i,8) + $10]
               sta tableD016 + i
               lda #[floor(i/8) * 16 + $0e]
               sta tableD018 + i

         }
         rts
}

.align $100
tableD016:
      .fill 128, 0
tableD018:
      .fill 128, 0
Sinus:
      .fill 256, sin((i/128) * (PI*2)) * 47 + 47

RoadOffsets:
.for(var j=0; j<50; j++) {
   .align $80
   .fill 96, ((i-48)/48) * (48 * (1-(j/50))) + 48
}

RoadColors:
      .byte 1,2,1,1,2,2,1,1,1,2
      .byte 2,2,1,1,1,1,2,2,2,2
      .byte 1,1,1,1,1,2,2,2,2,2
      .byte 1,1,1,1,1,1,2,2,2,2
      .byte 2,2,1,1,1,1,1,1,1,2
      .byte 2,2,2,2,2,2,2,2,2,2

      .byte 11,1,11,11,1,1,11,11,11,1
      .byte 1,1,11,11,11,11,1,1,1,1
      .byte 11,11,11,11,11,1,1,1,1,1
      .byte 11,11,11,11,11,11,1,1,1,1
      .byte 1,1,11,11,11,11,11,11,11,1
      .byte 1,1,1,1,1,1,1,1,1,1


* = $5800
      // .fill 8 * 40, 0
      // .import binary "./assets/map_horizon.bin"
      // // .fill 40, 19
   Screen0:
      .import binary "./assets/map.bin"
* = $7400
      .fill 64, $ff
.byte %11100011,%10001110,%00111000
.byte %11100011,%10001110,%00111000
.byte %11100011,%10001110,%00111000
.byte %00011100,%01110001,%11000111
.byte %00011100,%01110001,%11000111
.byte %00011100,%01110001,%11000111
.byte %11100011,%10001110,%00111000
.byte %11100011,%10001110,%00111000
.byte %11100011,%10001110,%00111000
.byte %00011100,%01110001,%11000111
.byte %00011100,%01110001,%11000111
.byte %00011100,%01110001,%11000111
.byte %11100011,%10001110,%00111000
.byte %11100011,%10001110,%00111000
.byte %11100011,%10001110,%00111000
.byte %00011100,%01110001,%11000111
.byte %00011100,%01110001,%11000111
.byte %00011100,%01110001,%11000111
.byte %11100011,%10001110,%00111000
.byte %11100011,%10001110,%00111000
.byte %11100011,%10001110,%00111000, 0


* = $7800
      .import binary "./assets/chars.bin"

* = $8000
CharColors:
      .import binary "./assets/colors.bin"

ShiftLeft: {


      .for(var r = 3; r<6; r++) {
               ldx $5800 + (r + 6) * 40 + 6
               ldy $d800 + (r + 6) * 40 + 6
         .for(var c= 7; c<34; c++) {
               lda $5800 + (r + 6) * 40 + c
               sta $5800 + (r + 6) * 40 + c - 1
               lda $d800 + (r + 6) * 40 + c
               sta $d800 + (r + 6) * 40 + c - 1
         }
               stx $5800 + (r + 6) * 40 + 33
               sty $d800 + (r + 6) * 40 + 33
      }
      rts
}
ShiftRight: {

      .for(var r = 3; r<6; r++) {
               ldx $5800 + (r + 6) * 40 + 33
               ldy $d800 + (r + 6) * 40 + 33
         .for(var c= 32; c>=6; c--) {
               lda $5800 + (r + 6) * 40 + c
               sta $5800 + (r + 6) * 40 + c + 1
               lda $d800 + (r + 6) * 40 + c
               sta $d800 + (r + 6) * 40 + c + 1
         }
               stx $5800 + (r + 6) * 40 + 6
               sty $d800 + (r + 6) * 40 + 6
      }
      rts
}


CBSinusX:
      .fill 64, (i/64) * 24
      .fill 64, (i/64) * 24
      .fill 64, (i/64) * 24
      .fill 64, (i/64) * 24
CBSinusY:
      .fill 256, abs(cos((i/128) * (PI*2)) * 24)
CBIndex:
      .byte $00
CBTemp:

   .byte $00, $00
CBFadeCols2:
      .byte 0,0,0,0,0,0,0,0
      .byte 0,0,0,0,0,0,0,0
      .byte 0,0,0,0,0,0,0,0
      .byte 1,13,15,14,12,14,11,6
      .byte 0,0,0,0,0,0,0,0
      .byte 0,0,0,0,0,0,0,0
      .byte 0,0,0,0,0,0,0,0
      .byte 1,7,15,10,12,8,11,9
      .byte 0,0,0,0,0,0,0,0
      .byte 0,0,0,0,0,0,0,0
      .byte 0,0,0,0,0,0,0,0
      .byte 0,0,0,0,0,0,0,0
      .byte 0,0,0,0,0,0,0,0
      .byte 0,0,0,0,0,0,0,0
      .byte 0,0,0,0,0,0,0,0
      
// CBFadeCols2:
//       .byte 6,14, 3,13,3,12, 4,2,8,12, 5,12,4,11

AnimateCBoard: {
         lda CBIndex
         lsr
         lsr
         and #$3f
         tax 
         lda CBFadeCols2, x
         sta $d021

         // txa
         // clc
         // adc #$08
         // and #$0f
         // tax
         // lda CBFadeCols2, x
         // .for(var i=0; i<5; i++) {
         //    sta $d027 + i + 2
         // }

         inc CBIndex
         ldx CBIndex
         lda CBSinusX, x
         sta CBTemp 
         lda CBSinusY, x
         clc
         adc #$2c
         sta CBTemp + 1
         tay
         .for(var i=0; i<5; i++) {
            sty $d005 + i * 2
            lda #$40 + i * 48
            clc
            adc CBTemp
            sta $d004 + i * 2
         }
         rts
}
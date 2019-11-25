BasicUpstart2(Entry)

Entry:
        ldx #$00
    !:
        lda $4000,x
        sta $0400,x
        lda $4100,x
        sta $0500,x
        lda $4200,x
        sta $0600,x
        lda $4300,x
        sta $0700,x

        lda $4400,x
        sta $d800,x
        lda $4500,x
        sta $d900,x
        lda $4600,x
        sta $da00,x
        lda $4700,x
        sta $db00,x
        inx
        bne !-

        lda #$18
        sta $d018
        lda #$d8
        sta $d016
        lda #$3b
        sta $d011

        lda #$06
        sta $d020
        sta $d021

        lda #$ff
        sta $d015
        sta $d01c
        sta $d01b

        lda #$0b
        sta $d025
        lda #$0c
        sta $d026

        ldx #$00
    !:
        lda #$0f
        sta $d027, x
        jsr Random
        and #$03
        adc #$01
        sta SSpeed, x
        jsr Random
        sta SY, x
        jsr Random
        sta SX, x
        inx
        cpx #$08
        bne !-

        sei
loop1:
        bit $d011 // Wait for new frame
        bpl *-3
        bit $d011
        bmi *-3

        lda #$3b // Set y-scroll to normal position (because we do FLD later on..)
        sta $d011

        jsr CalcNumLines // Call sinus substitute routine

        lda #$30 // Wait for position where we want FLD to start
        cmp $d012
        bne *-3

        ldx NumFLDLines
        beq loop1 // Skip if we want 0 lines FLD
loop2:
        lda $d012 // Wait for beginning of next line
        cmp $d012
        beq *-3

        clc // Do one line of FLD
        lda $d011
        adc #1
        and #7
        ora #$38
        sta $d011

        dex // Decrease counter
        bne loop2 //Branch if counter not 0

        jmp loop1 // Next frame



CalcNumLines:
        inc FLDIndex
        ldx FLDIndex
        lda FLDTable, x
        sta NumFLDLines

        inc timer


        lda #$00
        sta $d010

        ldx #$00
        ldy #$00
    !Loop:
        lda SX, x
        asl
        sta $d000, y
        bcc !+
        lda $d010
        ora pot, x
        sta $d010
    !:
        iny
        lda SY, x
        sta $d000, y
        iny

        lda SAnim, x
        ora #$3c
        sta $07f8, x

        lda SX, x
        sec 
        sbc SSpeed, x
        sta SX, x
        cmp #$04
        bcs !+

        jsr Random
        and #$03
        adc #$01
        sta SSpeed, x
        jsr Random
        sta SY, x
        lda #$c0
        sta SX, x
        lda #$00
        sta SAnim,x
    !:

        lda timer
        and #$03
        bne !+
        inc SAnim, x
        lda SAnim, x
        and #$03
        sta SAnim, x
    !:
        inx
        cpx #$08
        bne !Loop-
        rts

SSpeed:
    .fill 8, 0
SY:
    .fill 8, 0
SX:
    .fill 8, 0
SAnim:
    .fill 8, 0
timer:
    .byte $00
pot:
    .byte 1,2,4,8,16,32,64,128
FLDIndex:
        .byte 0
NumFLDLines:
        .byte 0
FLDTable:
    .byte  50,42,34,27,21,15,11,9,7,7,9,11,15,19,24,29
    .byte  34,39,44,48,51,53,53,53,52,51,48,45,42,39,36,33
    .byte  32,31,31,32,35,38,43,48,54,61,68,75,81,87,92,95
    .byte  98,99,99,97,94,89,84,78,70,63,56,48,42,36,31,27
    .byte  24,22,22,23,25,27,30,34,38,41,44,47,49,50,50,49
    .byte  47,44,41,37,32,28,24,20,17,15,14,14,16,19,23,28
    .byte  34,41,49,57,65,72,79,85,90,93,96,97,96,94,91,87
    .byte  82,76,70,64,58,53,48,44,41,40,39,39,40,42,45,48
    .byte  51,54,57,59,60,60,59,58,55,51,46,41,35,29,23,17
    .byte  12,8,5,3,2,3,6,9,14,20,27,34,42,50,58,65
    .byte  71,76,80,83,85,85,84,82,79,75,71,67,62,58,55,52
    .byte  50,49,49,50,52,55,58,61,65,69,72,74,76,77,77,75
    .byte  72,68,63,57,51,43,36,29,21,15,10,5,2,0,0,1
    .byte  4,7,12,18,24,31,38,45,51,56,61,64,67,68,68,67
    .byte  66,63,60,57,54,51,48,47,46,46,46,48,51,55,60,65
    .byte  70,75,80,84,88,90,92,92,90,88,84,78,72,65,57,50


Random: {
        lda seed
        beq doEor
        asl
        beq noEor
        bcc noEor
    doEor:    
        eor #$1d
        eor $dc04
        eor $dd04
    noEor:  
        sta seed
        rts
    seed:
        .byte $62


    init:
        lda #$ff
        sta $dc05
        sta $dd05
        lda #$7f
        sta $dc04
        lda #$37
        sta $dd04

        lda #$91
        sta $dc0e
        sta $dd0e
        rts
}

* = $0f00
        .import binary "sprites.bin"
* = $2000
        .import binary "bitmapdata.bin"
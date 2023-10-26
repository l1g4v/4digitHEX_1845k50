; PIC18F45K50 Configuration Bit Settings

; Assembly source line config statements

; CONFIG1L
  CONFIG  PLLSEL = PLL4X        ; PLL Selection (4x clock multiplier)
  CONFIG  CFGPLLEN = OFF        ; PLL Enable Configuration bit (PLL Disabled (firmware controlled))
  CONFIG  CPUDIV = NOCLKDIV     ; CPU System Clock Postscaler (CPU uses system clock (no divide))
  CONFIG  LS48MHZ = SYS24X4     ; Low Speed USB mode with 48 MHz system clock (System clock at 24 MHz, USB clock divider is set to 4)

; CONFIG1H
  CONFIG  FOSC = HSM		; Oscillator Selection (External oscillator)
  CONFIG  PCLKEN = ON           ; Primary Oscillator Shutdown (Primary oscillator enabled)
  CONFIG  FCMEN = OFF           ; Fail-Safe Clock Monitor (Fail-Safe Clock Monitor disabled)
  CONFIG  IESO = OFF            ; Internal/External Oscillator Switchover (Oscillator Switchover mode disabled)

; CONFIG2L
  CONFIG  nPWRTEN = OFF          ; Power-up Timer Enable (Power up timer enabled)
  CONFIG  BOREN = OFF            ; Brown-out Reset Enable (BOR disabled in hardware (SBOREN is ignored))
  ;CONFIG  BORV = 190            ; Brown-out Reset Voltage (BOR set to 1.9V nominal)
  ;CONFIG  nLPBOR = OFF          ; Low-Power Brown-out Reset (Low-Power Brown-out Reset disabled)

; CONFIG2H
  CONFIG  WDTEN = OFF           ; Watchdog Timer Enable bits (WDT disabled in hardware (SWDTEN ignored))
  CONFIG  WDTPS = 32768         ; Watchdog Timer Postscaler (1:32768)

; CONFIG3H
  CONFIG  CCP2MX = RC1          ; CCP2 MUX bit (CCP2 input/output is multiplexed with RC1)
  CONFIG  PBADEN = OFF          ; PORTB A/D Enable bit (PORTB<5:0> pins are configured as digital I/O on Reset)
  CONFIG  T3CMX = RC0           ; Timer3 Clock Input MUX bit (T3CKI function is on RC0)
  CONFIG  SDOMX = RB3           ; SDO Output MUX bit (SDO function is on RB3)
  CONFIG  MCLRE = ON           ; Master Clear Reset Pin Enable (RE3 input pin enabled; external MCLR disabled)

; CONFIG4L
  CONFIG  STVREN = OFF          ; Stack Full/Underflow Reset (Stack full/underflow will cause Reset)
  CONFIG  LVP = OFF              ; Single-Supply ICSP Enable bit (Single-Supply ICSP enabled if MCLRE is also 1)
  CONFIG  ICPRT = OFF           ; Dedicated In-Circuit Debug/Programming Port Enable (ICPORT disabled)
  CONFIG  XINST = OFF           ; Extended Instruction Set Enable bit (Instruction set extension and Indexed Addressing mode disabled)

; CONFIG5L
  CONFIG  CP0 = OFF             ; Block 0 Code Protect (Block 0 is not code-protected)
  CONFIG  CP1 = OFF             ; Block 1 Code Protect (Block 1 is not code-protected)
  CONFIG  CP2 = OFF             ; Block 2 Code Protect (Block 2 is not code-protected)
  CONFIG  CP3 = OFF             ; Block 3 Code Protect (Block 3 is not code-protected)

; CONFIG5H
  CONFIG  CPB = OFF             ; Boot Block Code Protect (Boot block is not code-protected)
  CONFIG  CPD = OFF             ; Data EEPROM Code Protect (Data EEPROM is not code-protected)

; CONFIG6L
  CONFIG  WRT0 = OFF            ; Block 0 Write Protect (Block 0 (0800-1FFFh) is not write-protected)
  CONFIG  WRT1 = OFF            ; Block 1 Write Protect (Block 1 (2000-3FFFh) is not write-protected)
  CONFIG  WRT2 = OFF            ; Block 2 Write Protect (Block 2 (04000-5FFFh) is not write-protected)
  CONFIG  WRT3 = OFF            ; Block 3 Write Protect (Block 3 (06000-7FFFh) is not write-protected)

; CONFIG6H
  CONFIG  WRTC = OFF            ; Configuration Registers Write Protect (Configuration registers (300000-3000FFh) are not write-protected)
  CONFIG  WRTB = OFF            ; Boot Block Write Protect (Boot block (0000-7FFh) is not write-protected)
  CONFIG  WRTD = OFF            ; Data EEPROM Write Protect (Data EEPROM is not write-protected)

; CONFIG7L
  CONFIG  EBTR0 = OFF           ; Block 0 Table Read Protect (Block 0 is not protected from table reads executed in other blocks)
  CONFIG  EBTR1 = OFF           ; Block 1 Table Read Protect (Block 1 is not protected from table reads executed in other blocks)
  CONFIG  EBTR2 = OFF           ; Block 2 Table Read Protect (Block 2 is not protected from table reads executed in other blocks)
  CONFIG  EBTR3 = OFF           ; Block 3 Table Read Protect (Block 3 is not protected from table reads executed in other blocks)

; CONFIG7H
  CONFIG  EBTRB = OFF           ; Boot Block Table Read Protect (Boot block is not protected from table reads executed in other blocks)

#include <xc.inc> ;USING EXT OSC HSM AT 12MHz

;variable definition (RAM)
 numberhb equ 0; 00XX
 numberlb equ 1; XX00
 flags    equ 2; <00> timer0 trigger and int0 trigger
 display  equ 3; display branch table number
 holder   equ 5; holds the extracted digit from the display branch table
;................

;constant definition (program memory)
psect consts, class=CONST,delta=1
 ;filler: DB 0x01,0x02,3,4,5,6; this is used in case the table ends up in two memory seccions where the high byte differ
 digits: DB 0xc0,0xf9,0xa4,0xb0,0x99,0x92,0x82,0xf8,0x80,0x98,0x88,0x83,0xc6,0xa1,0x86,0x8e ;0,1,2,3,4,5,6,7,8,9,A,B,C,D,E,F
;....................

psect entry, class=CODE,reloc=2 ;entry point at 0x0
 entry:
    goto setup
 
psect setup,class=CODE,reloc=2 ;setup SFRs, variables, etc
setup:
    ;I/O
    movlw 0x0F
    movwf ADCON1,0
    clrf PORTD,0
    clrf TRISD,0 ;PORTD connected to the display <0-7> -> <A-DP>
    clrf TRISB,0
    bsf TRISB,0 ;PORTB<0> is used as the interrupt
    clrf TRISA,0 ;PORTA<0-3> is used to drive the display
    
    ;TIMERS
    bsf RCON,7,0 ;low priority timer0
    bcf INTCON2,2,0
    bsf INTCON2,6,0
    movlw 0xf0
    movwf INTCON    
    movlw 0x92 ;1:8 prescaler
    movwf T0CON,0
    
    bsf IPR1,0 ;high priority timer1
    bsf PIE1,0 ;enable timer1 int
    movlw 0x41 ;1:1 prescaler
    movwf T1CON,0
    movlw 0x7F
    movwf TMR1H
    
    ;table high byte
    movlw HIGH(digits)
    movwf TBLPTRH
    clrf TBLPTRL
    
    ;reset everything
    clrf numberhb
    clrf numberlb
    clrf flags
    clrf display
    clrf holder
    
    goto main

psect main,class=CODE,reloc=2 ;the main loop of the program
main:
    btfss flags,0,0
    goto addnum
    goto subnum
    
    addnum:
	infsnz numberlb
	incf numberhb
	goto endrt
    subnum:
	tstfsz numberlb
	goto skip
	decf numberhb
	skip:
	decf numberlb
	
    endrt:
    call wait_tmr0
    goto main

wait_tmr0:
    btfss flags,1,0
    goto wait_tmr0
    bcf flags,1,0
    return
    
show_digit:
    movf holder
    addlw LOW(digits)
    movwf TBLPTR,0
    tblrd *
    movff TABLAT,PORTD
    return
    
psect HPINT,class=CODE,reloc=2 ;high priority interrupt
HPINT:
    call HPISR
    retfie
psect HPISR,class=CODE,reloc=2 ;interrupt service routine (high priority)
HPISR:
    btfsc PIR1,0
    goto timer1
    goto int0
    timer1: ; display control
	clrf LATA,0
	movlw 0x10
	cpfslt display
	clrf display
	movff display, WREG
	addlw display_brat
	movwf PCL
	display_brat:
	    goto d0
	    goto d1
	    goto d2
	    goto d3
	d0:
	   movlw not 0x1
	   movwf LATA,0 ;<0111>
    	   movff numberhb,holder
	   swapf holder,1
	   movlw 0x0F
	   andwf holder,0
	   call show_digit
	   goto endlp 
	d1:
	   movlw not 0x2 ;<1011>
	   movwf LATA,0	 
	   movff numberhb,holder
	   movlw 0x0F
	   andwf holder,0
	   call show_digit
	   goto endlp
	d2:
	   movlw not 0x4 ;<1101>
	   movwf LATA,0
    	   movff numberlb,holder
	   swapf holder,1
	   movlw 0x0F
	   andwf holder,0
	   call show_digit
	   goto endlp 
	d3:
	   movlw not 0x8 ;<1110>
	   movwf LATA,0
	   movff numberlb,holder
	   movlw 0x0F
	   andwf holder,0
	   call show_digit
    endlp:
	movlw 0x2
	addwf display
	bcf PIR1,0,0 ;Clear TMR1IF
	movlw 0x7F
	movwf TMR1H
	goto hpend
    int0:
	bcf INTCON,1,0
	btg flags,0,0
    hpend:
    return

psect LPINT,class=CODE,reloc=2 ;low priority interrupt
LPINT:
    call LPISR
    retfie
psect LPISR,class=CODE,reloc=2 ;interrupt service routine (low priority)
LPISR:   
    timer0: ; go up/down number flag
	bcf INTCON,2,0
	bsf flags,1,0
	goto endlp    
    return
END entry
# pingpong-uhr

Bascom Eval. Version used.

Skeleton Program by Wolfram Herzog: http://flugwiese.de/2017/09/pingpong-uhr-mit-scrolling/

avrdude -c usbasp -p m8 -U flash:w:PingPong_Uhr_PS2.hex:i

avrdude -c usbasp -p m8 -U lfuse:w:0xe4:m -U hfuse:w:0xc9:m 

![pingponguhr](https://github.com/petersieg/pingpong-uhr/blob/main/pingponguhr.jpeg)

```
'***************************************************************
'Clock für FRANZIS PINGPONG Platine
'
'Timer0 für Update display
'Timer2 für Softclock
'
'Uhrenquarz 32 KHz an B6 und B7 löten
'
'24-1-2010 Skeleton Program Wolfram Herzog
'Isr; SoftClock; Leds driver
'
'25-7-2021 Peter Sieg
'Display in decimal binary Hh : Mm left->right; top->down
'At column 6 is just a divider betwwen hh and mm
'12:00
' 123456789ABC
'0
'1 **  *
'2  *  *
'3
'4
'5     *
'6     *
'7
'8
'9
'
'12:59
' 123456789ABC
'0
'1 **  *  **
'2  *  *  **
'3        **
'4        **
'5     *  **
'6     *   *
'7         *
'8         *
'9         *
'
'No config off time - start fix at 12:00 when powering on
'
'***************************************************************

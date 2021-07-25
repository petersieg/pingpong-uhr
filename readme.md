'***************************************************************
' Clock für FRANZIS PINGPONG Platine
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
'12:00
' 123456789ABC
'0 **  *
'1  *  *
'2
'3
'4     *
'5     *
'6
'7
'8
'9
'
'12:59
' 123456789ABC
'0 **  *  **
'1  *  *  **
'2        **
'3        **
'4     *  **
'5     *   *
'6         *
'7         *
'8         *
'9
'
'No config time - fix start at 12:00 when powering on
'
'***************************************************************

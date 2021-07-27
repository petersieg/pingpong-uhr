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
'
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
'No config off time - start fix at 12:00 when powering on
'
'***************************************************************

$crystal = 8000000
$regfile = "m8def.dat"
$hwstack = 64
$swstack = 64
$framesize = 64

Dim Leds(13) As Word                                        'LED Darstellung Datenarray aus 13 Worten (weg Index)

Dim Zeit As String * 8                                      'Zeitstring
Dim Zeitdata(9) As Byte At Zeit Overlay

Dim Speed As Word                                           '

Dim B As Byte

'* Variablen für String Management
Dim I As Byte                                               'Index für Array Zugriff
Dim Iz As Byte                                              'Index Zeichenarray
Dim Ta As String * 1                                        'Index des Timearray


Declare Sub Initialisierung

'** Softclock konfigurieren **
Config Date = Mdy , Separator = -                           'ANSI-Format
Config Clock = Soft                                         'benutzt timer2
Time$ = "12:00:00"                                          'Uhr setzen
'Time$ = "23:58:00"                                          'Uhr setzen

Speed = 1000

Initialisierung                                             'Ports und Interrupts initialisieren


'****************** Schleife zum Ansteuern aller LED'S ******************
'Trenner hh : mm
Leds(6) = &B01100110
Do
  Zeit = Time$                                              'Zeitvariable muß regelmäßig ausgelesen werden
  Gosub Machpixel                                           'update des Pixelfeldes
  Waitms Speed                                              'Wait
Loop
End

'************************* Update Leds() array **************************
UpdLeds:
Ta = Mid(zeit , I , 1)                                      'Byte 1 aus Timearray wird in TA koipert
B = Val(ta)                                                 'ASCII-String wird in Byte Wert umgerechnet
If B = 0 Then                                               '
  Leds(Iz) = &B00000000
End If
If B = 1 Then                                               '
  Leds(Iz) = &B00000010
End If
If B = 2 Then                                               '
  Leds(Iz) = &B00000110
End If
If B = 3 Then                                               '
  Leds(Iz) = &B00001110
End If
If B = 4 Then                                               '
  Leds(Iz) = &B00011110
End If
If B = 5 Then                                               '
  Leds(Iz) = &B00111110
End If
If B = 6 Then                                               '
  Leds(Iz) = &B01111110
End If
If B = 7 Then                                               '
  Leds(Iz) = &B11111110
End If
If B = 8 Then                                               '
  Leds(Iz) = &B111111110
End If
If B = 9 Then                                               '
  Leds(Iz) = &B1111111110
End If
Return                                                      '############ END ##################

'************************ ZEIT String auswerten *************************
' Erzeugt die Pixel im ZEICHEN Array
Machpixel:
'*** hh zehner 0-2
I = 1                                                       'Index String
Iz = 2                                                      'Index Leds() initialisieren
Gosub UpdLeds
'*** hh einer 0-9
I = 2                                                       'Index String
Iz = 3                                                      'Index Leds()  initialisieren
Gosub UpdLeds
'*** mm zehner 0-5
I = 4                                                       'Index String
Iz = 9                                                      'Index Leds()  initialisieren
Gosub UpdLeds
'*** mm einer 0-9
I = 5                                                       'Index String
Iz = 10                                                     'Index Leds()  initialisieren
Gosub UpdLeds
Return


'******************  Service-Unterprogramme *********************
Sub Initialisierung
  Config Portc = 15                                         'PORTC als AD-Eingang
  Config Portb = Output
  Config Portd = 255
  Config Timer0 = Timer , Prescale = 8                      'Wegen Softclock auf Timer0 umgestellt
  On Ovf0 Tim0_isr
  Enable Timer0
  Enable Interrupts
  Start Timer0
End Sub

'******************* Interrupt - Display ************************

Dim Vy As Byte
Dim Col As Byte
Dim Portdout As Byte
Dim Portcout As Byte

Tim0_isr:
 '800 µs
'Timer0 = 56
Col = Col + 1
If Col = 13 Then Col = 1
Vy = Col + 0
Portd = 0
Portb = 0
Portc = 0
If Col = 1 Then Portb.4 = 0 Else Portb.4 = 1
Portb.3 = 1                                                 'cl
Portb.3 = 0
Portb.2 = 1                                                 'Str
Portb.2 = 0
Portdout = Low(leds(vy))
Portcout = Portdout And 15
Portdout = Portdout And 240
Portd = Portdout
Portc.0 = Portcout.0                                        'Nibble einzeln ausgeben
Portc.1 = Portcout.1
Portc.2 = Portcout.2
Portc.3 = Portcout.3
Portc.4 = 1                                                 'müssen wegen Tastenabfrage auf 1 gesetzt sein
Portc.5 = 1
Portb = High(leds(vy))
'Waitms 500
Return

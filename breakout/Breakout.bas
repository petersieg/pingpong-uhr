'-----------------------------------------------------------------------
'-    Programm des Breakout Spieles auf der Ping-Pong Platine          -
'-----------------------------------------------------------------------
'-    Autor: Ralf Geske,                                               -
'-      wobei die Routinen Initialisierung, Tim2_ISR und Standby       -
'-      weitgehend aus der Feder des Originalentwicklers sind.         -
'-----------------------------------------------------------------------
'-    Programmversion:  V1.0  Release vom 04.01.2011                   -
'-    URL:              WWW.Ralf-Geske.de                              -
'-----------------------------------------------------------------------

$crystal = 8000000
$regfile = "m8def.dat"
$hwstack = 196
$swstack = 196
$framesize = 196

Dim Leds(12) As Word
Dim ___rseed As Word
Dim N As Word                                               'Als Schleifenzähler in For-Next Schleifen
Dim M As Byte                                               'Auch Schleifenzähler
Dim Dummy As Integer                                        'Hilfsvariable für Berechnungen
Dim Dummybyte As Byte                                       'Hilfsvariable für Berechnungen
Dim Index As Byte                                           'zur Berechnung des LEDs(n) Index in SUB print_at

Dim X As Byte
Dim Y As Byte
Dim Kredit As Byte : Kredit = 3                             '3 Spiele zur Verfügung
Dim Balls As Byte                                           'Bälle pro Spiel
Dim Ballx As Byte
Dim Ballxold As Byte
Dim Bally As Byte
Dim Ballyold As Byte
Dim Dirx As Integer : Dirx = 1                              '
Dim Diry As Integer : Diry = 1
Dim Bcheck As Byte
Dim T0count As Byte                                         'Geschwindigkeitsvariable
Dim T0countovf As Byte
Dim Checkl As Byte                                          'links vom Ball
Dim Checkr As Byte                                          'rechts vom Ball
Dim Checkup As Byte
Dim Checkdown As Byte
Dim Bottomline As Word
Dim Dots As Byte :

Dim Points As Integer
Dim Highscore As Eram Integer
Dim Newlinecount As Byte                                    'Zähler für: neue Reihen Steine hinzu?
Dim Tausender As Byte
Dim Hunderter As Byte
Dim Zehner As Byte
Dim Einer As Byte

Dim Dx As Word
Dim Dy As Word

Dim Fontpointer As Word
Dim Font_start_adress As Word
Font_start_adress = Loadlabel(font)                         'enthält die Anfangsadresse der Datalines

Declare Sub Move_schlaeger
Declare Sub Change_dir
Declare Sub Lost
Declare Sub Print_score(byval Value As Integer)
Declare Sub Standby
Declare Sub Initialisierung
Declare Sub Leds_cls
Declare Sub Leds_print_at(byval Print_x As Byte , Byval Print_y As Byte , Byval Num As Byte)
Declare Sub Led1(byval X As Byte , Byval Y As Byte)
Declare Sub Led0(byval X As Byte , Byval Y As Byte)


Initialisierung


'-----------------------------------------
Do
   Leds_cls                                                 ' (Wieder)Herstellen der Startbedingungen
   ___rseed = Timer2
   Points = 0
   Newlinecount = 0
   T0countovf = 5
   Balls = 3
   Bally = 2
   Ballx = Rnd(10)
   Ballx = Ballx + 1

   M = 2
   Do
      Leds(m) = 14
      M = M + 1
   Loop Until M = 12

   Tccr0 = 5                                                'Config/Start Timer0 mit prescaler 1024
'>----------------------------Hauptschleife-------------------------------------
   Do
      Waitms 20
      Move_schlaeger
      If Balls = 0 Then Exit Do
   Loop
'<----------------------------Hauptschleife-------------------------------------
   Tccr0 = 0                                                'Stop Timer0

   Print_score Points

   Dummy = Highscore
   If Points > Dummy Then Highscore = Points                'Highscore ablegen

   Waitms 5000
   Kredit = Kredit - 1
   If Kredit = 0 Then
      Kredit = 3
      Standby
   End If
Loop

'-------------------------------------------------------------------------------
'-------------------Hilfsroutinen-----------------------------------------------
'-------------------------------------------------------------------------------
Sub Led1(byval X As Byte , Byval Y As Byte)
   If X < 13 Then
      Dummybyte = 10 - Y
      Leds(x).dummybyte = 1
   End If
End Sub

Sub Led0(byval X As Byte , Byval Y As Byte)
   If X < 13 Then
      Dummybyte = 10 - Y
      Leds(x).dummybyte = 0
   End If
End Sub


'******************  Service-Unterprogramme *********************


Sub Initialisierung
  Config Portc = 15                                         'PORTC als AD-Eingang
  Config Portb = Output
  Config Portd = 255
  Config Timer2 = Timer , Prescale = 32
  On Ovf2 Tim2_isr
  Enable Timer2
  Enable Interrupts
  Start Timer2
  Config Adc = Single , Prescaler = 64 , Reference = Off
  Start Adc
  Config Int0 = Low Level
  Tccr0 = 5                                                 'Config timer0 mit prescaler 1024
  On Ovf0 Tim0_isr
  Enable Timer0
End Sub

Sub Leds_cls
   M = 1
   Do
       Leds(m) = 0
       M = M + 1
   Loop Until M = 13
End Sub

Sub Leds_print_at(byval Print_x As Byte , Byval Print_y As Byte , Byval Num As Byte)

   Print_y = Print_y - 1                                    'sonst wird zu weit 'geshiftet'
   Print_x = Print_x - 1                                    'sonst wird das falsche Zeichen geholt

   Dim Save As Word                                         'nimmt alten Leds(n) Inhalt auf
   Dim Mask As Word : Mask = &B11111                        'Zum Maskieren des
   Shift Mask , Left , Print_y                              'Y-Bereiches
   Mask = Not Mask                                          'invertiere die Maske, wird nacher ODER verknüpft.
   Fontpointer = 0
   Fontpointer = Num * 4
   Fontpointer = Fontpointer + Font_start_adress            'Fontpointer auf 'Zeichen' setzen.

   For M = 1 To 4                                           'Font ist 4 Spalten breit
      Dummybyte = M + Print_x                               'zu bearbeitende LEDs() Spalte
      Save = Leds(dummybyte)                                ' Inhalt sichern
      Leds(dummybyte) = Cpeek(fontpointer)                  'mit neuem Inhalt laden
      Shift Leds(dummybyte) , Left , Print_y                'entsprechend der Y-Pos verschieben
      Save = Save And Mask                                  'Bereich aus altem Inhalt löschen
      Leds(dummybyte) = Leds(dummybyte) Or Save             'Zeichenteil einfügen
      Incr Fontpointer                                      'nächste Spalte
   Next
End Sub


Sub Move_schlaeger
   'ist der Ball in der untersten Reihe?
   Dots = 0

   M = 1
   Do
      If Leds(m).9 = 1 Then
         Bottomline.m = 1
         Incr Dots
      End If
      M = M + 1
   Loop Until M = 13

   If Dots > 3 Then Lost
   Dx = Getadc(7)
   Dx = Dx / 113                                            '1024/12
   X = 10 - Dx
   Bottomline = &B00000000000000111
   Shift Bottomline , Left , X

   M = 1
   Do
      Leds(m).9 = Bottomline.m
      M = M + 1
   Loop Until M = 13
End Sub

Sub Change_dir
   Points = Points + 1
   If Points > 50 Then T0countovf = 4
   If Points > 100 Then T0countovf = 3
   If Points > 150 Then T0countovf = 2

   Newlinecount = Newlinecount + 1
   Checkup = 9 - Bally
   Checkdown = 11 - Bally
   If Diry = 1 Then                                         'geht der Ball nach oben
      If Leds(ballx).checkdown = 1 Then                     'und unter dem Berührten ist noch ein
         Dirx = -1 * Dirx                                   'weiterer dann muß die X-Richtung
      Else                                                  'gedreht werden
         Diry = -1 * Diry                                   'sonst die Y-Richtung ändern
      End If
   Else                                                     'geht der Ball nach unten
      If Leds(ballx).checkup = 1 Then                       'und über dem Berührten ist noch ein
         Dirx = -1 * Dirx                                   'weiterer dann muß die X-Richtung
      Else                                                  'geändert werden
         Diry = -1 * Diry                                   'sonst die Y-Richtung
      End If
   End If
   If Newlinecount > 20 Then
      If Bally < 2 Then
         Tccr0 = 0                                          'Stop Timer0
         For N = 2 To 11
         Shift Leds(n) , Left , 1
         Leds(n) = Leds(n) Or 6
         Leds(n) = Leds(n) And 127
         Next N
         Newlinecount = 0
         Tccr0 = 5                                          'Config/Start Timer0 mit prescaler 1024
      End If
   End If
End Sub


Sub Lost
   Tccr0 = 0                                                'Stop Timer0
   Timer0 = 1
   Balls = Balls - 1
   For N = 1 To 5
      Leds(1) = &B1111111111
      Leds(12) = &B1111111111
      Waitms 100
      Leds(1) = 0
      Leds(12) = 0
      Waitms 100
   Next N
   Bally = 2
   Diry = 1
   Ballx = Rnd(9)
   Ballx = Ballx + 1
   Tccr0 = 5                                                'Config/start timer0 mit prescaler 1024
End Sub

Sub Standby
  Tccr0 = 0                                                 'Stop Timer0
  Stop Timer2
  Portc = 0
  Portd = 0
  Portb = 0
  Stop Adc
  Ddrd.2 = 0
  Portd.2 = 1
  Enable Int0
  Powerdown
  Disable Int0
  Ddrd.2 = 1
  Portd.2 = 0
  Start Adc
  Start Timer2
  Dummy = Highscore
  Print_score Dummy
  Waitms 5000
  Tccr0 = 5                                                 'Config/start timer0 mit prescaler 1024
End Sub


'******************************* Interrupt - Display ****************************

Dim Vy As Byte
Dim Col As Byte
Dim Portdout As Byte
Dim Portcout As Byte


Tim2_isr:
    '800 µs
   'Timer2 = 2
   Col = Col + 1
   If Col = 13 Then Col = 1
   Vy = Col + 0
   Portd = 0
   Portb = 0
   Portc = 0
   If Col = 1 Then Portb.4 = 0 Else Portb.4 = 1
   Portb.3 = 1                                              'cl
   Portb.3 = 0
   Portb.2 = 1                                              'Str
   Portb.2 = 0
   Portdout = Low(leds(vy))
   Portcout = Portdout And 15
   Portdout = Portdout And 240
   Portd = Portdout
   Portc = Portcout
   Portb = High(leds(vy))
Return

Tim0_isr:                                                   'Ball Bewegen
   Incr T0count
   If T0count > T0countovf Then
      T0count = 0
      If Ballx = 12 Then                                    'Spielfeldgrenzen in X-Richtung checken
         Dirx = -1
         'Ballx = 12
      End If
      If Ballx = 1 Then Dirx = 1
      If Dirx = 1 Then Ballx = Ballx + 1                    'und Ball bewegen
      If Dirx = -1 Then Ballx = Ballx -1

      If Bally = 10 Then                                    'Spielfeldgrenzen in X-Richtung checken
         Diry = -1
         'Bally = 10
      End If
      If Diry = 1 Then Bally = Bally + 1                    'und Ball bewegen
      If Diry = -1 Then
         If Bally > 1 Then Bally = Bally - 1
      End If

      Bcheck = 10 - Bally

      If Leds(ballx).bcheck = 1 Then                        'ist etwas berührt worden?
         Change_dir                                         'dann Richtung ändern
      End If
      If Bally = 1 Then
         Checkl = Ballx - 1                                 'in Bottomline, Schläger vorhanden?
         Checkr = Ballx + 1                                 'If Leds(ballx).9 = 1 Then      'wird der Schläger Mittig getroffen
         If Leds(checkl).9 = 1 Then                         'Ball eine Position Hoch setzen
            If Leds(checkr).9 = 1 Then
               Bally = Bally + 1
            End If
         End If

      End If

         If Ballxold <> Ballx Then                          'alten Ball löschen
            Led0 Ballxold , Ballyold
            Ballxold = Ballx
         End If
         If Ballyold <> Bally Then
            Ballyold = Bally
         End If
      Led1 Ballx , Bally                                    'neuen zeichnen
    End If
Return


Sub Print_score(byval Value As Integer)
   Dummy = Value / 1000
   Tausender = Dummy
   Dummy = Dummy * 1000
   Value = Value - Dummy
   Dummy = Value / 100                                      'Points in Digits zerlegen
   Hunderter = Dummy
   Zehner = Hunderter * 100
   Value = Value - Zehner
   Zehner = Value / 10
   Einer = Zehner * 10
   Einer = Value - Einer

   Leds_cls
   Leds_print_at 1 , 4 , Hunderter                          'und Anzeigen
   Leds_print_at 5 , 4 , Zehner
   Leds_print_at 9 , 4 , Einer
   While Tausender > 0                                      'Aufgrund fehlender Digits wird für
      Led1 Tausender , 10                                   'jeden Tausender in der oberen Reihe
      Tausender = Tausender - 1                             'eine LED angeschaltet
   Wend
End Sub

End

Font:
Data 31 , 17 , 31 , 0                                       '0
Data 0 , 2 , 31 , 0                                         '1
Data 29 , 21 , 23 , 0                                       '2
Data 21 , 21 , 31 , 0                                       '3
Data 7 , 4 , 31 , 0                                         '4
Data 23 , 21 , 29 , 0                                       '5
Data 31 , 21 , 29 , 0                                       '6
Data 1 , 1 , 31 , 0                                         '7
Data 31 , 21 , 31 , 0                                       '8
Data 23 , 21 , 31 , 0                                       '9
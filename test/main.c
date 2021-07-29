// Scrollen mit vier Helligkeitsstufen mic 27.12.2010

#include <avr/wdt.h>
#include <avr/interrupt.h>
#include <util/delay.h>
#include <inttypes.h>

#define colors 4 // Anzahl der Farbebenen

volatile uint8_t ebene=0, col = 0;
uint8_t x, y, z, bildspeicher[colors][15];

// alle LEDs in allen Ebenen aus
void cls(void);

// Einen Bildpunkt an x, y setzen. Werte für c: 0 ist aus, 1 ist dunkel, 4 ist hell
void set(uint8_t x, uint8_t y, uint8_t c);

// Potiwerte einlesen, P2 ist Kanal 6, P3 ist Kanal 7
uint16_t readADC(uint8_t channel);

// WatchDog beim Initialisieren ausschalten
// https://www.roboternetz.de/phpBB2/viewtopic.php?p=531597#531597
void kill_WD(void) __attribute__((naked)) __attribute__((section(".init3")));
void kill_WD(void) { MCUSR = 0; wdt_disable(); }

int main(void)
{
cli();

DDRB = 0xff;
DDRC = 0x0f;
DDRD = 0xf0;

TCCR2 = (1<<CS21) | (0<<CS20); // 8-bit Timer mit 1/8 Vorteiler
TCCR2 |= (1<<WGM21) | (1<<WGM20); // Fast PWM
TCCR2 |= (0<<COM21) | (0<<COM20); // no OC2-Pin
OCR2 = 100; // 0=dunkel, 255=hell
TIFR = (1<<OCF2) | (1<<TOV2); // Clear old flags
TIMSK |= (1<<TOIE2) | (1<<OCIE2); // overflow and compare interrupt

// A/D Conversion (aus der asuro-Lib)
ADCSRA = (1 << ADEN) | (1 << ADPS2) | (1 << ADPS1); // clk/64

sei(); // Interrupts erlauben

for(x=0; x<12; x++)
for(y=0; y<10; y++)
set(x, y, (x/3)%colors+1); // Helligkeitsstufen anzeigen
_delay_ms(1000);

cls();
z=0;

while(1)
{
for(x=0; x<12; x++)
for(y=0; y<10; y++)
set(x, y, ((x+y+(z%12))/3)%colors+1);
_delay_ms(50);
z++;
}
return (0);
}

void cls(void)
{
uint8_t x, y;
for(x=0; x<15; x++)
for(y=0; y<colors; y++)bildspeicher[y][x] = 0;
}
void set(uint8_t x, uint8_t y, uint8_t c)
{
uint8_t ebene;

y = 9-y; // Koordinatennullpunkt unten links
if(y < 8) // y 9 bis 2
for(ebene=0; ebene<colors; ebene++)
if(c>ebene) bildspeicher[ebene][x] |= (1 << y);
else bildspeicher[ebene][x] &= ~(1 << y);
else // y 1 und 0
for(ebene=0; ebene<colors; ebene++)
if(c>ebene) bildspeicher[ebene][12+(x>>2)] |= (1<<((x%4)*2+(y&1)));
else bildspeicher[ebene][12+(x>>2)] &= ~(1<<((x%4)*2+(y&1)));
}
uint16_t readADC(uint8_t channel)
{
ADMUX = (1 << REFS0) | (channel & 7);// AVCC reference with external capacitor
ADCSRA |= (1 << ADSC); // Start conversion
while (!(ADCSRA & (1 << ADIF))); // wait for conversion complete
ADCSRA |= (1 << ADIF); // clear ADCIF
return(ADC);
}
SIGNAL (SIG_OUTPUT_COMPARE2)
{
OCR2 = (24<<ebene); // hihi
PORTB &= ~0x03; // Die Pins der Displaymatrix werden auf Low gesetzt
PORTC &= ~0x0f;
PORTD &= ~0xf0;
}
SIGNAL (SIG_OVERFLOW2)
{
uint8_t ledval, portb;

// Spalten
if(col) PORTB |= (1<<4); /* Danach Einsen hinterherschicken (PB4 = 1) */
else PORTB &= ~(1<<4); /* Bei der ersten Spalte eine 0 ausgeben (PB4 = 0) */
PORTB |= (1 << 3); /* PB3 = 1 (cl) */
PORTB &= ~(1 << 3); /* PB3 = 0 (!cl) */
PORTB |= (1 << 2); /* PB2 = 1 (str) */
PORTB &= ~(1 << 2); /* PB2 = 0 (!str) */

// Zeilen
ledval = bildspeicher[ebene][12+(col>>2)]; // y 1 und 0
portb = (ledval >> (col%4)*2) & 0x03;
ledval = bildspeicher[ebene][col]; // y 9 bis 2
PORTC |= ledval & 0x0f;
PORTD |= ledval & 0xf0;
PORTB |= portb;

col++;

if(col>11)
{
col=0;
ebene++;
if(ebene == colors) ebene=0;
}
}

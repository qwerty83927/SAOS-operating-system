extern int get_cursor(void);
extern void set_cursor(int offset);

unsigned char inb(unsigned short port) {
unsigned char result;
__asm__("in %%dx, %%al" : "=a" (result) : "d" (port));
return result;
}

void outb(unsigned short port, unsigned char data) {
__asm__("out %%al, %%dx" : : "a" (data), "d" (port));
}

void inc_cursor() {set_cursor((get_cursor()/2)+2);}
void dec_cursor() {set_cursor((get_cursor()/2)-2);}

void putc(char c) {
char* p = (char*)(0xb8000);
int offset = get_cursor();
p[offset] = c;
p[offset+1] = 0x0f;
inc_cursor();
}

void print(char* string) {
int i = 0;
while(string[i] != 0) {
putc(string[i]);
++i;
}
}

void main(void) {
print("hello world");
}

module WA1440B;

import std.stdio;
import std.conv;
import std.math;
import std.algorithm;

char[4000] memory;

char[128] char2bcd;

char[128] bcd2char;

int[char] addrmap;
char[int] addrmap_i;

char Breg;
char Areg;
char Oreg;
int Ireg;
int AAR;
int BAR;

bool sysHalt = false;
bool isNSI = true;

enum micstate {_iop, _i1, _i2, _i3, _i4, _i5, _i6, _i6d, _i7, _i8, _h, _e};

micstate state = micstate._iop;

char wm(char c)
{
	return (c & 0x80)>>7;
}

char extB(char c)
{
	return (c & 0x20);
}

char extA(char c)
{
	return (c & 0x10);
}

char extD(char c)
{
	return (c & 0x0f);
}

char cwm(char c)
{
	if (wm(c) == 1) {
		char i = 0;

		i = 1<<7;
		i = cast(char)~i;

		c = c & i;
	}
	return c;
}

void setwm(ref char cc)
{
	cc = cc | (1 << 7);
}

void unsetwm(ref char cc)
{
	char i = 0;

	i = 1<<7;
	i = cast(char)~i;

	cc = cc & i;
}

char[] clearwm(char[] s)
{
	char[] ss;

	ss.length = s.length;
	ss[] = s[];
	unsetwm(ss[0]);
	return ss;
}

char[] clear(char[] s)
{
	char[] ss;

	ss.length=s.length;
	ss[] = s[];
	unsetwm(ss[$-1]);
	if (isNeg(ss[0])) ss[0] -= 0x20;
	return ss;
}

char[] clearconv(char[] s)
{
	char[] ss;

	ss.length=s.length;
	ss[] = s[];
	unsetwm(ss[$-1]);
	if (isNeg(ss[0])) ss[0] -= 0x20;
	for(int i=0;i<ss.length;i++)
		ss[i] = cast(char)bcd2char[ss[i]];
	return ss;
}

bool isNeg(char c)
{
	if (((c&0x10)>>4) == 1)
		return 0;
	return (c&0x20)>>5;
}

void setB(ref char cc)
{
	cc = cc | (1 << 5);
}

void unsetB(ref char cc)
{
	char i = 0;

	i = 1<<5;
	i = cast(char)~i;

	cc = cc & i;
}

void cpymem(int d, int s)
{
	int s1 = s;
	int d1 = d;
	int sl = 0;
	int dl = 0;
	char c = 0;

	while(wm(memory[s1--]) != 1) sl++;
	while(wm(memory[d1--]) != 1) {
		dl++;
		memory[d1] = '0';
	}
	sl++;
	dl++;

	while (wm(c = memory[s--]) != 1) memory[d--] = c;
	memory[d] = c;
}

/* 
char[] c10(char[] e,long l)
{
	int c = 0;
	int t = 0;
	char[] r;
	char[] e1;
	
	long el = e.length;

	r.length=l;
	e1.length=l;

	long e1l = e1.length;

	e1[] = '0';

	for(int i=0;i<e.length;i++) {
		e1[e1l-1-i] = e[el-1-i];
	}

	if (e1[e1.length-1] == '0') {
		c = 1;
	} else {
		t = e1[e1.length-1] - 48;
		t = 10 - t;
		r[e1.length-1] = cast(char)(t + 48);
		c = 0;
	}
	for (long i=e1.length-2;i>=0;i--) {
		t = e1[i] - 48;
		t = 9 - t + c;
		r[i]=cast(char)(t + 48);
	}

	return r;
}
*/

void c10b(int addr)
{
	char c;
	int cry = 0;

	c = memory[addr];
	unsetwm(c); unsetB(c);
	c = bcd2char[c];
	c -= 48;
	c = cast(char)(10 - c);
	if (c == 10) {
		c = 0;
		cry = 1;
	} else {
		cry = 0;
	}
	c += 48;
	c = char2bcd[c];
	memory[addr] = c;
	addr--;
	while(wm(c = memory[addr]) != 1) {
		unsetwm(c); unsetB(c);
		c = bcd2char[c];
		c -= 48;
		c = cast(char)(9 - c + cry);
		if (c == 10) {
			c = 0;
			cry = 1;
		} else {
			cry = 0;
		}
		c += 48;
		c = char2bcd[c];
		memory[addr] = c;
		addr--;
	}
	unsetwm(c); 
	unsetB(c);
	c = bcd2char[c];
	c -= 48;
	c = cast(char)(9 - c + cry);
	if (c == 10) {
		c = 0;
		cry = 1;
	} else {
		cry = 0;
	}
	c += 48;
	c = char2bcd[c];
	setwm(c);
	memory[addr] = c;
}

/* 
int addN(ref char[] sum)
{
	char[] a1=readMemANI(AAR);
	char[] a2=readMemANI(BAR);
	char[] aa1;
	char[] aa2;
	long l1 = a1.length;
	long l2 = a2.length;
	int n1 = 0;
	int n2 = 0;
	int cry = 0;

	if ( (isNeg(a2[l2-1])) && (!isNeg(a1[l1-1]))) {
		aa1.length = l2;
		aa1=c10(clearwm(a1),l2);
	} else {
		aa1 = clearconv(a1);
		aa2 = clearconv(a2);
	}

	int d = aa1.length < aa2.length;
	if (d < 0) {
		d = abs(d);
		for(int j=0;j<d;j++) {
			aa1 = '0' ~ aa1;
		}
	}

	sum.length = aa2.length;

	for(long i=0;i<aa2.length;i++) {
		n1 = aa1[i]-48;
		n2 =aa2[i]-48;
		n1 += n2 + cry;
		if (n1 > 9) {
			n1 = 0;
			cry = 1;
		} else {
			cry = 0;
		}
		aa2[i] = cast(char)(n1 + 48);
	}
	
	aa2.reverse;
	sum[] = aa2[];

	return cry;
}
*/

int addOrig()
{
	int baddr = BAR;
	int aaddr = AAR;
	bool isComp = false;
	bool aEnded = false;
	bool isAneg = isNeg(memory[AAR]);
	bool isBneg = isNeg(memory[BAR]);
	char s = 0;
	int cry = 0;
	char c;
	char d;
	int Av = abs(readMemNI(AAR));
	int Bv = abs(readMemNI(BAR));

	if ( isNeg(memory[BAR]) && !isNeg(memory[AAR]) ) {
		c10b(AAR);
		isBneg = true;
		isComp = true;
	}

	if ( !isNeg(memory[BAR]) && isNeg(memory[AAR]) ) {
		c10b(AAR);
		isAneg = true;
		isComp = true;
	}

	while (wm(c = memory[baddr]) != 1) {
		unsetwm(c); unsetB(c);
		c = bcd2char[c];

		if (!aEnded) {
			d = memory[aaddr];
			if (wm(d)) aEnded = true;
			unsetwm(d); unsetB(d);
			d = bcd2char[d];
		} else {
			d = '0';
		}
		
		s = cast(char)((c - 48) + (d - 48) + cry);
		if (s>9) {
			s = 0;
			cry = 1;
		} else {
			cry = 0;
		}
		memory[baddr] = (wm(memory[baddr]) == 0) ? char2bcd[s+48] : cast(char)(char2bcd[s+48] + 0x80);
		baddr--;
		aaddr--;
	}
	unsetwm(c); unsetB(c);
	c = bcd2char[c];

	if (!aEnded) {
		d = memory[aaddr];
		if (wm(d)) aEnded = true;
		unsetwm(d); unsetB(d);
		d = bcd2char[d];
	} else {
		d = '0';
	}

	s = cast(char)((c - 48) + (d - 48) + cry);
	if (s>9) {
		s = 0;
		cry = 1;
	} else {
		cry = 0;
	}
	s = char2bcd[s+48];
	setwm(s);
	memory[baddr] = s;
	
	if ((isComp) && (cry == 0)) c10b(BAR);

	if ((isComp) && (Bv > Av)) {
		if (isBneg) setB(memory[BAR]);
	} else if ((isComp) && (Av > Bv)) {
		if (isAneg) setB(memory[BAR]);
	} else {
		if (isBneg) setB(memory[BAR]);
	}

	return cry;
}

///
/// reads an integer from memory
/// it moves left to right
///
int readMemNI(int addr)
{	int sign = 1;
	int r = 0;
	int k = 0;
	char c;

	while (wm(c = memory[addr]) != 1) {
		if (isNeg(c)) {
			sign = -1;
			c -= 0x20;
		}
		r += (bcd2char[cwm(c)]-48)*10^^k;
		k++;
		addr--;
	}
	r += (bcd2char[cwm(c)]-48)*10^^k;

	return sign * r;
}

///
/// reads memory with alphameric conversion
/// returns a string of data
/// it moves left to right
///
char[] readMemAI(int addr)
{
	char c;
	string r;

	while (wm(c = memory[addr]) != 1) {
		r ~= bcd2char[cwm(c)];
		addr--;
	}
	r ~= bcd2char[cwm(c)];

	return cast(char[])r;
}

///
/// reads memory without any conversion
/// it moves left to right
///
char[] readMemANI(int addr)
{
	char c;
	string r;

	while (wm(c = memory[addr]) != 1) {
		r ~= c;
		addr--;
	}
	r ~= c;

	return cast(char[])r;
}

///
/// reads memory with alphameric conversion
/// it moves right to left
///
char[] readMemAD(int addr)
{
	char c;
	string r;
	char[] rr;

	while (wm(c = memory[addr]) != 1) {
		r ~= bcd2char[cwm(c)];
		addr++;
	}
	r ~= bcd2char[cwm(c)];

	rr.length = r.length;
	rr[] = r[];
	rr.reverse;

	return rr;
}

///
/// it writes an integer into memory
/// it moves left to right
///
void writeMemNI(int addr, int v)
{
	int sign = 1;
	int org = addr;

	if (v<0) sign = -1;
	v = abs(v);
	while (v != 0) {
		memory[addr] = cast(char)char2bcd[(v%10) + 48];
		v /= 10;
		addr--;
	}
	if (sign == -1) setB(memory[org]);
	setwm(memory[addr+1]);
}

///
/// it writes an string of alphameric chars into memory
/// it moves left to right
///
void writeMemAI(int addr, string v)
{
	for (int i=0;i<v.length;i++) {
		memory[addr] = cast(char)char2bcd[v[i]];
		addr--;
	}
	setwm(memory[addr+1]);
}

///
/// it writes an string of alphameric chars into memory
/// it moves right to left
///
int writeMemAD(int addr, string v)
{
	foreach_reverse(char e; v) {
		memory[addr] = cast(char)char2bcd[e];
		addr++;
	}
	setwm(memory[addr-1]);
	return addr-1;
}

///
/// transfer in memory an instruction
/// direction is left to right
///
void transferInstr(int addr, string v) 
{
	int org=addr;

	foreach (char e; v) {
		memory[addr++] = char2bcd[e];
	}
	setwm(memory[org]);
}

void init()
{
	addrmap_i = [  0: '0', 10: '=', 11: '/', 12: 'S', 13: 'T', 14: 'U', 15: 'V',
				16: 'W', 17: 'X', 18: 'Y', 19: 'Z', 20: '!', 21: 'J', 22: 'K',
				23: 'L', 24: 'M', 25: 'N', 26: 'O', 27: 'P', 28: 'Q', 29: 'R',
				30: '?', 31: 'A', 32: 'B', 33: 'C', 34: 'D', 35: 'E', 36: 'F',
				37: 'G', 38: 'H', 39: 'I',  1: '1',  2: '2',  3: '3',  4: '4',
				 5: '5',  6: '6',  7: '7',  8: '8',  9: '9' ];

	addrmap = [  '0': 0, '=': 10 , '/': 11, 'S': 12, 'T': 13, 'U': 14, 'V': 15,
				 'W': 16, 'X': 17, 'Y': 18, 'Z': 19, '!': 20, 'J': 21, 'K': 22,
				'L': 23, 'M': 24, 'N': 25, 'O': 26, 'P': 27, 'Q': 28, 'R': 29,
				'?': 30, 'A': 31, 'B': 32, 'C': 33, 'D': 34, 'E': 35, 'F': 36,
				 'G': 37, 'H': 38, 'I': 39, '1': 1, '2': 2, '3': 3, '4': 4,
				'5': 5, '6': 6, '7': 7, '8': 8, '9': 9 ];

	bcd2char[64]=32;
	bcd2char[42]=33;
	bcd2char[31]=34;
	bcd2char[11]=35;
	bcd2char[109]=36;
	bcd2char[28]=37;
	bcd2char[112]=38;
	bcd2char[94]=39;
	bcd2char[61]=40;
	bcd2char[109]=41;
	bcd2char[44]=42;
	bcd2char[91]=44;
	bcd2char[32]=45;
	bcd2char[59]=46;
	bcd2char[81]=47;
	bcd2char[74]=48;
	bcd2char[1]=49;
	bcd2char[2]=50;
	bcd2char[67]=51;
	bcd2char[4]=52;
	bcd2char[69]=53;
	bcd2char[70]=54;
	bcd2char[7]=55;
	bcd2char[8]=56;
	bcd2char[73]=57;
	bcd2char[13]=58;
	bcd2char[110]=59;
	bcd2char[62]=60;
	bcd2char[93]=61;
	bcd2char[14]=62;
	bcd2char[124]=63;
	bcd2char[76]=64;
	bcd2char[49]=65;
	bcd2char[50]=66;
	bcd2char[115]=67;
	bcd2char[52]=68;
	bcd2char[117]=69;
	bcd2char[118]=70;
	bcd2char[55]=71;
	bcd2char[56]=72;
	bcd2char[121]=73;
	bcd2char[97]=74;
	bcd2char[98]=75;
	bcd2char[35]=76;
	bcd2char[100]=77;
	bcd2char[37]=78;
	bcd2char[38]=79;
	bcd2char[103]=80;
	bcd2char[104]=81;
	bcd2char[41]=82;
	bcd2char[82]=83;
	bcd2char[19]=84;
	bcd2char[84]=85;
	bcd2char[21]=86;
	bcd2char[22]=87;
	bcd2char[87]=88;
	bcd2char[88]=89;
	bcd2char[25]=90;
	bcd2char[26]=95;
	bcd2char[16]=124;
	bcd2char[79]=126;

	char2bcd = [  0,  0, 0,  0, 0, 0,  0,  0,  0,  0,
				  0,  0, 0,  0, 0, 0,  0,  0,  0,  0,
				  0,  0, 0,  0, 0, 0,  0,  0,  0,  0,
				  0,  0,64, 42,31,11,109, 28,112, 94,
				 61,109,44,  0,91,32, 59, 81, 74,  1,
				  2, 67, 4, 69,70, 7,  8, 73, 13,110,
				 62, 93,14,124,76,49, 50,115, 52,117,
				118, 55,56,121,97,98, 35,100, 37, 38,
				103,104,41, 82,19,84, 21, 22, 87, 88,
				 25,  0, 0,  0, 0,26,  0,  0,  0,  0,
				  0,  0, 0,  0, 0, 0,  0,  0,  0,  0,
				  0,  0, 0,  0, 0, 0,  0,  0,  0,  0,
				  0,  0, 0,  0,16, 0, 79, 0];

	Ireg = 1;
}

int invlook(char c){
	foreach( key, value; addrmap) {
		if (value == c) return key; 
	}
	return 0;
}

int char3addr(char[] c3)
{
	int addr = 0;

	addr = invlook(c3[0])*100+(c3[1]-48)*10+(c3[2]-48);

	return addr;
}

char[3] addrchar3(int addr)
{
	char[3] c3;
	c3[2] = cast(char)((addr % 10)+48);
	addr /= 10;
	c3[1] = cast(char)((addr % 10)+48);
	addr /= 10;
	c3[0] = addrmap_i[addr];
	
	return c3;
}

void IOp()
{
	if (isNSI) {
		Breg = memory[Ireg];
	} else {
		Breg = memory[AAR];
	}
	unsetwm(Breg);
	Breg = bcd2char[Breg];
	Oreg = Breg;
	if (Oreg == '.') { 
		state=micstate._h;
	} else {
		state=micstate._i1;
	}
	Ireg++;
	isNSI=true;
}

int I1()
{
	Breg = memory[Ireg];
	if (wm(Breg)) {
		switch(Oreg) {
			case 'B':
				break;
			case '/':
				break;
			case 'C':
				break;
			case 'N':
				break;
			case '.':
				break;
			case '1':
				break;
			case '2':
				break;
			case '4':
				break;
			case '5':
				break;
			case '6':
				break;
			case '7':
				break;
			case '8':
				break;
			case '9':
				break;
			default:
				break;
		}
		state=micstate._i7;
		return 1;
	} else {
		state=micstate._i2;
	}
	unsetwm(Breg);
	Breg = bcd2char[Breg];
	Areg = Breg;
	AAR = 0; 
	if ((Oreg != 'D') && (Oreg != 'L') && (Oreg != 'M') &&
		(Oreg != 'Y') && (Oreg != 'Z') && (Oreg != 'H') &&
		(Oreg != 'Q')) {
			BAR = 0;
		}
	if ((Oreg != 'D') && (Oreg != 'L') && (Oreg != 'M') &&
		(Oreg != 'Y') && (Oreg != 'Z') && (Oreg != 'H') &&
		(Oreg != 'Q')) {
			AAR = addrmap[Breg]*100;
			BAR = addrmap[Breg]*100;
		} else {
			AAR = addrmap[Breg]*100;
		}
	Ireg++;
	return 0;
}

int I2()
{
	Breg = memory[Ireg];
	if (wm(Breg)) {
		switch(Oreg) {
			case 'B':
				break;
			case '/':
				break;
			case 'C':
				break;
			case 'N':
				break;
			case '.':
				break;
			case '1':
				break;
			case '2':
				break;
			case '4':
				break;
			case '5':
				break;
			case '6':
				break;
			case '7':
				break;
			case '8':
				break;
			case '9':
				break;
			default:
				break;
		}
		state=micstate._i7;
		return 2;
	} else {
		state=micstate._i3;
	}
	unsetwm(Breg);
	Breg = bcd2char[Breg];
	Areg = Breg;
	if ((Oreg != 'D') && (Oreg != 'L') && (Oreg != 'M') &&
		(Oreg != 'Y') && (Oreg != 'Z') && (Oreg != 'H') &&
		(Oreg != 'Q')) {
			AAR += (Breg-48)*10;
			BAR += (Breg-48)*10;
		} else {
			AAR += (Breg-48)*10;
		}
	Ireg++;
	return 0;
}

void I3()
{
	Breg = memory[Ireg];
	unsetwm(Breg);
	Breg = bcd2char[Breg];
	Areg = Breg;
	if ((Oreg != 'D') && (Oreg != 'L') && (Oreg != 'M') &&
		(Oreg != 'Y') && (Oreg != 'Z') && (Oreg != 'H') &&
		(Oreg != 'Q')) {
			AAR += (Breg-48);
			BAR += (Breg-48);
		} else {
			AAR += (Breg-48);
		}
	Ireg++;
	state=micstate._i4;
}

int I4()
{
	Breg = memory[Ireg];
	if ((Oreg == 'B') && (wm(Breg) || (Breg == 124))) {
		// Branch instruction - Unconditional
		isNSI=false;
		state=micstate._iop;
		return 4;
	} else {
		if (wm(Breg)) {
			switch(Oreg) {
				case 'B':
					break;
				case '/':
					break;
				case 'C':
					break;
				case 'N':
					break;
				case '.':
					break;
				case '1':
					break;
				case '2':
					break;
				case '4':
					break;
				case '5':
					break;
				case '6':
					break;
				case '7':
					break;
				case '8':
					break;
				case '9':
					break;
				default:
					break;
			}
			state=micstate._i7;
			return 4;
		} else {
			state=micstate._i5;
		}
		unsetwm(Breg);
		Breg = bcd2char[Breg];
		BAR = 0;
		Areg = Breg;
		BAR = addrmap[Breg]*100;
		Ireg++;
		
	}
	return 0;
}

int I5()
{
	Breg = memory[Ireg];
	if (wm(Breg)) {
		switch(Oreg) {
			case 'B':
				break;
			case '/':
				break;
			case 'C':
				break;
			case 'N':
				break;
			case '.':
				break;
			case '1':
				break;
			case '2':
				break;
			case '4':
				break;
			case '5':
				break;
			case '6':
				break;
			case '7':
				break;
			case '8':
				break;
			case '9':
				break;
			default:
				break;
		}
		state=micstate._i7;
		return 5;
	} else {
		state=micstate._i6;
	}
	unsetwm(Breg);
	Breg = bcd2char[Breg];
	Areg = Breg;
	BAR += (Breg-48)*10;
	Ireg++;
	return 0;
}

void I6()
{
	Breg = memory[Ireg];
	unsetwm(Breg);
	Breg = bcd2char[Breg];
	Areg = Breg;
	BAR += (Breg-48);
	Ireg++;
	state=micstate._i7;
}



int I7()
{
	Breg = memory[Ireg];
	if (Oreg == ',') {
		state = micstate._e;
		return 7;
	}
	if (wm(Breg)) {
		switch(Oreg) {
			case 'B':
				break;
			case '/':
				break;
			case 'C':
				break;
			case 'N':
				break;
			case '.':
				break;
			case '1':
				break;
			case '2':
				break;
			case '4':
				break;
			case '5':
				break;
			case '6':
				break;
			case '7':
				break;
			case '8':
				break;
			case '9':
				break;
			default:
				break;
		}
		state = micstate._e;
		return 7;
	} else {
		unsetwm(Breg);
		Breg = bcd2char[Breg];
		Areg = Breg;
		Ireg++;
		state = micstate._i8;
	}
	return 0;
}

int I8()
{
	Breg = memory[Ireg];
	if (wm(Breg)) {
		switch(Oreg) {
			case 'B':
				break;
			case '/':
				break;
			case 'C':
				break;
			case 'N':
				break;
			case '.':
				break;
			case '1':
				break;
			case '2':
				break;
			case '4':
				break;
			case '5':
				break;
			case '6':
				break;
			case '7':
				break;
			case '8':
				break;
			case '9':
				break;
			default:
				break;
		}
		state = micstate._e;
		return 7;
	} else {
		unsetwm(Breg);
		Breg = bcd2char[Breg];
		Ireg++;
		state=micstate._i8;
	}
	return 0;
}

void microcode()
{
	switch(state) {
		case micstate._iop:
			IOp();
			break;
		case micstate._i1:
			I1();
			break;
		case micstate._i2:
			I2();
			break;
		case micstate._i3:
			I3();
			break;
		case micstate._i4:
			I4();
			break;
		case micstate._i5:
			I5();
			break;
		case micstate._i6:
			I6();
			break;
		case micstate._i8:
			I8();
			break;
		case micstate._h:
			sysHalt = true;
			break;
		case micstate._i7:
			I7();
			break;
		case micstate._e:
			exec();
			break;
		default:
			break;
	}
}

void exec()
{
	char[] s;
	int c = 0;

	switch(Oreg){
		case 'A':
			addOrig();
			break;
		case ',':
			Breg = memory[AAR];
			setwm(Breg);
			memory[AAR] = Breg;
			Breg = memory[BAR];
			setwm(Breg);
			memory[BAR] = Breg;
			break;
		case ' ':
			Breg = memory[AAR];
			unsetwm(Breg);
			memory[AAR] = Breg;
			Breg = memory[BAR];
			unsetwm(Breg);
			memory[BAR] = Breg;
			break;
		case 'D':
			Breg = memory[AAR];
			Areg = memory[AAR];
			Breg = memory[BAR];
			c = extB(Breg) | extA(Breg);
			memory[BAR] = cast(char)(c | extD(Areg));
			break;
		default:
			break;
	}
	state=micstate._iop;
}

void dumpArea(int addr)
{
	int sign = 1;
	char c;
	char[] output;

	output[] = "";

	if (isNeg(memory[addr])) write("-");

	while(wm(c = memory[addr--]) != 1) {
		unsetwm(c); unsetB(c);
		output ~= bcd2char[c];
	}
	unsetwm(c); unsetB(c);
	output ~= bcd2char[c];
	output.reverse;
	writeln(output);
}

int main()
{
	init();

	char[] ss1;
	
	writeMemNI(800,-2743);

	writeMemNI(900,1200);

	transferInstr(1,"A800900");
	transferInstr(8,".");

	while(sysHalt == false) {
		microcode();
	}

	dumpArea(900);

	return 0;
}
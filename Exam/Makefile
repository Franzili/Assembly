NASM=nasm

%: %.o
	$(LD) -m elf_x86_64 -static -o $@ $<

%.o: %.asm support_lsbsort.asm
	$(NASM) -f elf64 -F dwarf -g $<

prtdata: prtdata.c
	gcc -Wall -O3 -o prtdata prtdata.c

stlsort: stlsort.C
	g++ -Wall -O3 -o stlsort stlsort.C

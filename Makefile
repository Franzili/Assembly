NASM=nasm

%: %.o
	$(LD) -m elf_x86_64 -static -o $@ $<

%.o: %.asm
	$(NASM) -f elf64 -F dwarf -g $<
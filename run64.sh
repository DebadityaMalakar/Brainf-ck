nasm -f elf64 main64.asm -o bf.o
gcc -m64 -c main64.c -o main.o
gcc -m64 main.o bf.o -o brainfuck
./brainfuck
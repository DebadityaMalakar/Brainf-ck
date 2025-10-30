nasm main.asm -o bf.o
gcc -m32 -c main.c -o main.o
gcc -m32 main.o bf.o -o brainfuck
./brainfuck
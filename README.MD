# Brainfuck Interpreter (x64 Assembly + C)

A high-performance Brainfuck interpreter written in x64 Assembly with a C frontend, featuring both REPL (Read-Eval-Print Loop) and file execution capabilities.

## Overview

This project implements a complete Brainfuck programming language interpreter that combines the performance of hand-optimized x64 assembly with the convenience of a C-based interface. The interpreter supports the classic 30,000-cell Brainfuck tape and all standard operations.

## Project Structure

### Core Components

1. **`main64.asm`** - x64 Assembly Brainfuck Engine
   - Handles all Brainfuck instruction execution
   - Manages the 30,000-byte tape memory
   - Implements efficient pointer arithmetic and loop handling

2. **`main64.c`** - C Frontend and REPL Interface
   - Provides user-friendly command interface
   - Handles file I/O and interactive execution
   - Manages the REPL environment

3. **`run64.sh`** - Build and Execution Script
   - Automates compilation and linking
   - Runs the interpreter after building

## Features

### Brainfuck Operations Supported

- `>` - Move pointer right
- `<` - Move pointer left  
- `+` - Increment current cell
- `-` - Decrement current cell
- `.` - Output character from current cell
- `,` - Input character to current cell
- `[` - Start loop (while current cell != 0)
- `]` - End loop

### Execution Modes

1. **REPL Mode** - Interactive Brainfuck interpreter
   - Execute Brainfuck code directly
   - Run Brainfuck files with `run filename.bf`
   - Built-in help system
   - Persistent tape state between commands

2. **File Execution** - Run Brainfuck programs from files
   - Automatic file loading and parsing
   - Memory-efficient buffer management

## Technical Implementation

### Memory Management

- **Tape Size**: 30,000 bytes (classic Brainfuck specification)
- **Tape Wrapping**: Pointer automatically wraps at tape boundaries
- **Zero Initialization**: All tape cells initialized to 0 on startup

### Assembly Optimizations

- **Register Usage**: Efficient use of x64 registers for performance
- **Loop Handling**: Optimized forward/backward scanning for loop matching
- **System Call Integration**: Direct interface with C standard library for I/O
- **Register Preservation**: Proper saving/restoring of caller-saved registers

### C Interface Functions

```c
extern void bf_init(void);           // Initialize tape and pointer
extern void bf_execute(const char* code, long len);  // Execute Brainfuck code
extern void bf_cleanup(void);        // Cleanup resources
```

## Building and Running

### Prerequisites

- NASM (Netwide Assembler)
- GCC (GNU Compiler Collection)
- x64 Linux environment

### Build Instructions

```bash
# Make the build script executable
chmod +x run64.sh

# Build and run the interpreter
./run64.sh
```

### Manual Build

```bash
nasm -f elf64 main64.asm -o bf.o
gcc -m64 -c main64.c -o main.o
gcc -m64 main.o bf.o -o brainfuck
./brainfuck
```

## Usage Examples

### Interactive REPL

```
$ ./brainfuck
=== Brainfuck REPL ===
Type 'help' for available commands

bf> ++++++++[>++++++++<-]>.
A
bf> run hello.bf
Hello World!
bf> exit
Goodbye!
```

### Direct Code Execution

```brainfuck
bf> ++++++++[>++++++++<-]>.
A
bf> +[-[>>+<<-]>>[-<<+>>]<<<]          # Multiplication example
```

### File Execution

Create a file `hello.bf`:
```brainfuck
++++++++[>++++[>++>+++>+++>+<<<<-]>+>+>->>+[<]<-]>>.>---.+++++++..+++.>>.<-.<.+++.------.--------.>>+.>++.
```

Then execute:
```
bf> run hello.bf
Executing hello.bf...
Hello World!
```

## Brainfuck Language Reference

Brainfuck operates on an array of memory cells (the "tape"), each initially set to zero. A pointer (the "data pointer") moves between cells.

### Instruction Set

- `>` - Increment the data pointer (move to next cell to the right)
- `<` - Decrement the data pointer (move to previous cell to the left)  
- `+` - Increment the byte at the data pointer
- `-` - Decrement the byte at the data pointer
- `.` - Output the byte at the data pointer as an ASCII character
- `,` - Input one byte and store it at the data pointer
- `[` - If the byte at the data pointer is zero, jump forward to matching `]`
- `]` - If the byte at the data pointer is nonzero, jump back to matching `[`

## Performance Characteristics

- **Fast Execution**: Assembly implementation provides near-native speed
- **Efficient Memory**: Direct memory access without abstraction layers
- **Optimized Loops**: Smart loop matching reduces unnecessary scanning
- **Minimal Overhead**: Clean interface between C and assembly components

## Error Handling

- **File Errors**: Graceful handling of missing or unreadable files
- **Memory Allocation**: Proper error checking for buffer allocation
- **Boundary Checks**: Tape pointer wrapping at 0 and 29,999
- **Input Validation**: Safe handling of user input in REPL mode

## Educational Value

This project demonstrates:

- x64 Assembly programming techniques
- C and Assembly interoperability
- Brainfuck language implementation
- Memory management in low-level languages
- REPL design and implementation
- File I/O and buffer management

## License

This project is open source and available for educational and personal use.

---

*Note: This interpreter implements the classic Brainfuck specification and is compatible with most Brainfuck programs. For complex programs, ensure they adhere to the 30,000-cell tape limitation.*
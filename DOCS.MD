```markdown
# Brainf-ck x64 Interpreter — Detailed Docs

## Overview

This document provides a detailed, line-by-line explanation of the C frontend (`main64.c`) and x64 Assembly backend (`main64.asm`) for the Brainf-ck interpreter. Emphasis is given to the handling of string functions such as `strcmp` and `strncmp` in C, and the inner workings of the interpreter routines in assembly.

---

## main64.c — C Frontend

```c
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
```
- Includes standard C libraries for IO, memory, string, and character utilities.

```c
// ASM functions
extern void bf_init(void);
extern void bf_execute(const char* code, long len);
extern void bf_cleanup(void);
```
- Declares external assembly functions for initialization, execution, and cleanup.

---

### File Execution

```c
void run_file(const char* filename) {
    FILE* file = fopen(filename, "r");
    if (!file) {
        printf("Error: Cannot open file %s\n", filename);
        return;
    }
```
- Opens the given filename for reading. If the file can't be opened, prints an error and exits the function.

```c
    fseek(file, 0, SEEK_END);
    long length = ftell(file);
    fseek(file, 0, SEEK_SET);
```
- Seeks to the end for file size and rewinds to the start.

```c
    char* buffer = malloc(length + 1);
    if (buffer == NULL) {
        printf("Error: Memory allocation failed\n");
        fclose(file);
        return;
    }
```
- Allocates a buffer big enough to hold the file plus a terminator. Handles allocation failure.

```c
    size_t read_len = fread(buffer, 1, length, file);
    buffer[read_len] = '\0';
    fclose(file);
```
- Reads the file into `buffer`, null-terminates, and closes the file handle.

```c
    printf("Executing %s...\n", filename);
    bf_init();
    bf_execute(buffer, read_len);
    printf("\n");
    free(buffer);
}
```
- Notifies execution, initializes the ASM interpreter, executes code, prints newline, and frees memory.

---

### Help Printer

```c
void print_help(void) {
    printf("Brainfuck REPL Commands:\n");
    printf(" - Execute Brainfuck code directly\n");
    printf(" run <filename.bf> - Execute Brainfuck code from file\n");
    printf(" exit - Exit the REPL\n");
    printf(" help - Show this help message\n\n");
    printf("Supported Brainfuck operations: + - < > [ ] . ,\n");
}
```
- Prints available REPL commands and supported Brainfuck operations.

---

### REPL Loop

```c
void repl_loop(void) {
    char input[256];
    printf("=== Brainfuck REPL ===\n");
    printf("Type 'help' for available commands\n");
    while (1) {
        printf("bf> ");
        fflush(stdout);
        if (!fgets(input, sizeof(input), stdin)) {
            break;
        }
        input[strcspn(input, "\n")] = 0;
        if (strlen(input) == 0) {
            continue;
        }
```
- Prompts user, reads input with `fgets` (safe from buffer overflow), and trims newline. Skips empty lines.
    - `strcspn(input, "\n")`: Gives the position of the newline; sets it to zero (`\0`).
    - `strlen(input) == 0`: Skips further logic for empty input.

```c
        if (strcmp(input, "exit") == 0) {
            printf("Goodbye!\n");
            break;
        } else if (strcmp(input, "help") == 0) {
            print_help();
        } else if (strncmp(input, "run ", 4) == 0) {
            const char* filename = input + 4;
            while (*filename && isspace(*filename)) filename++;
            if (strlen(filename) > 0) {
                run_file(filename);
            } else {
                printf("Error: No filename provided\n");
            }
        } else {
            printf("Output: ");
            fflush(stdout);
            bf_init();
            bf_execute(input, strlen(input));
            printf("\n");
        }
    }
}
```
- Three string checks:
    - `strcmp(input, "exit")`: Compares input against "exit". If true, exits loop.
    - `strcmp(input, "help")`: Compares input against "help". Calls help if matched.
    - `strncmp(input, "run ", 4)`: Checks if input starts with "run ". If so, extracts filename after "run " (skipping whitespace with `isspace`). Then runs the file if non-empty, otherwise errors.
- If input doesn't match commands, interprets it as Brainfuck code and executes it with assembly backend.

#### String Functions Explanation

- `strcmp(a, b)` returns zero if strings `a` and `b` match exactly. Used for detecting the simple commands ("exit" and "help").
- `strncmp(a, b, n)` compares the first `n` characters of `a` and `b`, used here for prefix matching ("run ").
- `isspace(*filename)`: Skips spaces before filename.
- `strcspn(input, "\n") = 0`: Used to wipe out newline only.

---

### Main Function

```c
int main() {
    bf_init();
    repl_loop();
    bf_cleanup();
    return 0;
}
```
- Initializes interpreter, handles REPL, and then cleans up.

---

## main64.asm — x64 Assembly Backend

```asm
section .bss
tape: resb 30000 ; Classic Brainfuck 30k tape
```
- Allocates the Brainfuck memory tape, 30,000 bytes.

```asm
section .data
tape_ptr: dq 0
```
- Stores the current index into the tape.

```asm
section .text
global bf_init
global bf_execute
global bf_cleanup
extern putchar
extern getchar
```
- Makes interpreter functions accessible to C. Imports `putchar`/`getchar`.

---

### bf_init

```asm
bf_init:
    push rbp               ; Prologue: save base pointer
    mov rbp, rsp
    push rdi               ; Save rdi
    mov rcx, 30000         ; Set up for clearing the tape buffer
    mov rdi, tape
    xor al, al             ; Zero value
    rep stosb              ; Repeat store byte (zero out the tape)
    mov qword [tape_ptr], 0 ; Set the tape pointer to 0
    pop rdi                ; Restore rdi
    pop rbp                ; Epilogue: restore base pointer
    ret
```
- Zeros out the tape and resets tape pointer.

---

### bf_execute

```asm
bf_execute:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    mov r12, rdi ; code pointer (argument 1)
    mov r13, rsi ; code length (argument 2)
    mov r15, rdi ; original pointer to start of code
    add r13, rdi ; makes r13 the end pointer of code
    mov r14, tape
    mov rbx, [tape_ptr]
```
- Prologue: Save registers and arguments.
- `r12` traverses code, `r13` is end pointer, `r14` points to tape, `rbx` is the tape index.

```asm
.interpret_loop:
    cmp r12, r13
    jge .done
    mov al, [r12]
```
- If code consumed (r12 >= r13) exit. Loads current command char into `al`.

#### Command Dispatch

Each command is checked in turn and jumps to its handler:
- `'>'`: .inc_ptr
- `'<'`: .dec_ptr
- `'+'`: .inc_byte
- `'-'`: .dec_byte
- `'.'`: .output
- `','`: .input
- `'['`: .loop_start
- `']'`: .loop_end
- If no match: increments code pointer, restarts loop.

---

#### Brainfuck Command Handlers

- **.inc_ptr:** Increment tape pointer (`rbx`). Wrap to zero if exceeds 29999.
- **.dec_ptr:** Decrement tape pointer. Wrap to tape end if below zero.
- **.inc_byte:** Increment data byte at current tape pointer.
- **.dec_byte:** Decrement data byte.
- **.output:** Output current data cell via `putchar`, saves and restores registers to maintain state.
- **.input:** Read input character into current tape cell via `getchar`, preserves registers.
- **.loop_start:** If current cell is zero, skip to matching `]`, using RCX for nesting.
- **.loop_end:** If current cell is nonzero, search backward for matching `[`, using RCX for nesting.

---

#### Loop Matching Algorithm

- Nested loops handled by incrementing and decrementing RCX when `[` or `]` are observed inside loops, ensuring correct matching even with embedded loops.

---

#### Ending the Interpreter

```asm
.done:
    mov [tape_ptr], rbx   ; Save tape pointer position for next execution
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret
```
- Stores the tape pointer, restores registers and returns to C.

---

#### Cleanup (Unused)

```asm
bf_cleanup:
    ret
```
- No operation, stub for possible future needs.

---

## Summary

- **C Frontend**: Manages file input/output, REPL, and user interaction. Uses `strcmp` for exact string commands and `strncmp` for prefix matching—for REPL command dispatch.
- **x64 ASM Backend**: Implements tape, loop handling, and pure Brainfuck semantics with careful attention to register management and matching logic.
- **String Handling**: All string matching is handled in C, never in assembly.
- **Inter-component Calls**: Key "hooks" are the three `extern` assembly routines called from C, with complete context passed as pointers and sizes.


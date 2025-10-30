#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

// ASM functions
extern void bf_init(void);
extern void bf_execute(const char* code, int len);
extern void bf_cleanup(void);

// File execution function
void run_file(const char* filename) {
    FILE* file = fopen(filename, "r");
    if (!file) {
        printf("Error: Cannot open file %s\n", filename);
        return;
    }
    
    fseek(file, 0, SEEK_END);
    long length = ftell(file);
    fseek(file, 0, SEEK_SET);
    
    char* buffer = malloc(length + 1);
    if (buffer == NULL) {
        printf("Error: Memory allocation failed\n");
        fclose(file);
        return;
    }
    
    size_t read_len = fread(buffer, 1, length, file);
    buffer[read_len] = '\0';
    
    fclose(file);
    
    printf("Executing %s...\n", filename);
    bf_execute(buffer, read_len);
    printf("\n");  // New line after execution
    
    free(buffer);
}

void print_help(void) {
    printf("Brainfuck REPL Commands:\n");
    printf("  <brainfuck code>    - Execute Brainfuck code directly\n");
    printf("  run <filename.bf>   - Execute Brainfuck code from file\n");
    printf("  exit                - Exit the REPL\n");
    printf("  help                - Show this help message\n\n");
    printf("Supported Brainfuck operations: + - < > [ ] . ,\n");
}

void repl_loop(void) {
    char input[4096];
    
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
        
        if (strcmp(input, "exit") == 0) {
            printf("Goodbye!\n");
            break;
        }
        else if (strcmp(input, "help") == 0) {
            print_help();
        }
        else if (strncmp(input, "run ", 4) == 0) {
            const char* filename = input + 4;
            while (*filename && isspace(*filename)) filename++;
            
            if (strlen(filename) > 0) {
                run_file(filename);
            } else {
                printf("Error: No filename provided\n");
            }
        }
        else {
            // Execute Brainfuck code directly
            printf("Output: ");
            fflush(stdout);
            bf_execute(input, strlen(input));
            printf("\n");
        }
    }
}

int main() {
    bf_init();
    repl_loop();
    bf_cleanup();
    return 0;
}
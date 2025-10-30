section .bss
    tape: resb 30000  ; Classic Brainfuck 30k tape

section .data
    tape_ptr: dq 0

section .text
    global bf_init
    global bf_execute
    global bf_cleanup
    extern putchar
    extern getchar

bf_init:
    push rbp
    mov rbp, rsp
    push rdi
    ; Initialize tape to zeros
    mov rcx, 30000
    mov rdi, tape
    xor al, al
    rep stosb
    mov qword [tape_ptr], 0
    pop rdi
    pop rbp
    ret

bf_execute:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    
    mov r12, rdi   ; code pointer (1st arg in x64 System V ABI)
    mov r13, rsi   ; code length (2nd arg in x64 System V ABI)
    mov r15, rdi   ; save original code pointer
    add r13, rdi   ; r13 now points to end of code
    
    mov r14, tape
    mov rbx, [tape_ptr]
    
.interpret_loop:
    cmp r12, r13
    jge .done
    
    mov al, [r12]
    
    ; Implement Brainfuck operations
    cmp al, '>'
    je .inc_ptr
    cmp al, '<'
    je .dec_ptr
    cmp al, '+'
    je .inc_byte
    cmp al, '-'
    je .dec_byte
    cmp al, '.'
    je .output
    cmp al, ','
    je .input
    cmp al, '['
    je .loop_start
    cmp al, ']'
    je .loop_end
    
.continue:
    inc r12
    jmp .interpret_loop

.inc_ptr:
    inc rbx
    cmp rbx, 30000
    jl .continue
    xor rbx, rbx
    jmp .continue

.dec_ptr:
    dec rbx
    jge .continue
    mov rbx, 29999
    jmp .continue

.inc_byte:
    inc byte [r14 + rbx]
    jmp .continue

.dec_byte:
    dec byte [r14 + rbx]
    jmp .continue

.output:
    ; Output character - preserve registers
    push r12
    push r13
    push rbx
    movzx rdi, byte [r14 + rbx]
    call putchar wrt ..plt
    pop rbx
    pop r13
    pop r12
    jmp .continue

.input:
    ; Input character - preserve registers
    push r12
    push r13
    push rbx
    call getchar wrt ..plt
    mov [r14 + rbx], al
    pop rbx
    pop r13
    pop r12
    jmp .continue

.loop_start:
    cmp byte [r14 + rbx], 0
    jne .continue
    
    ; Find matching ] - skip forward
    mov rcx, 1
.find_loop_end:
    inc r12
    cmp r12, r13
    jge .done
    
    mov al, [r12]
    cmp al, '['
    je .nest_start
    cmp al, ']'
    je .nest_end
    jmp .find_loop_end
    
.nest_start:
    inc rcx
    jmp .find_loop_end
    
.nest_end:
    dec rcx
    jnz .find_loop_end
    jmp .continue

.loop_end:
    cmp byte [r14 + rbx], 0
    je .continue
    
    ; Find matching [ - go back
    mov rcx, 1
.find_loop_start:
    dec r12
    cmp r12, r15
    jl .done
    
    mov al, [r12]
    cmp al, ']'
    je .nest_end2
    cmp al, '['
    je .nest_start2
    jmp .find_loop_start
    
.nest_start2:
    dec rcx
    jnz .find_loop_start
    ; Now r12 points to the matching '[', continue will increment it
    jmp .continue
    
.nest_end2:
    inc rcx
    jmp .find_loop_start

.done:
    mov [tape_ptr], rbx
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret

bf_cleanup:
    ret
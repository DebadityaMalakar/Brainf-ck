section .bss
    tape: resb 30000  ; Classic Brainfuck 30k tape

section .data
    tape_ptr: dd 0

section .text
    global bf_init
    global bf_execute
    global bf_cleanup
    extern putchar
    extern getchar

bf_init:
    push ebp
    mov ebp, esp
    push edi
    ; Initialize tape to zeros
    mov ecx, 30000
    mov edi, tape
    xor al, al
    rep stosb
    mov dword [tape_ptr], 0
    pop edi
    pop ebp
    ret

bf_execute:
    push ebp
    mov ebp, esp
    push ebx
    push esi
    push edi
    
    mov esi, [ebp+8]   ; code pointer
    mov ecx, [ebp+12]  ; code length
    
    mov edi, tape
    mov ebx, [tape_ptr]
    
.interpret_loop:
    test ecx, ecx
    jle .done
    
    mov al, [esi]
    
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
    inc esi
    dec ecx
    jmp .interpret_loop

.inc_ptr:
    inc ebx
    cmp ebx, 30000
    jl .continue
    xor ebx, ebx  ; Wrap around
    jmp .continue

.dec_ptr:
    dec ebx
    jge .continue
    mov ebx, 29999  ; Wrap around
    jmp .continue

.inc_byte:
    inc byte [edi + ebx]
    jmp .continue

.dec_byte:
    dec byte [edi + ebx]
    jmp .continue

.output:
    ; Output character
    pusha
    movzx eax, byte [edi + ebx]
    push eax
    call putchar
    add esp, 4
    popa
    jmp .continue

.input:
    ; Input character
    pusha
    call getchar
    mov [edi + ebx], al
    popa
    jmp .continue

.loop_start:
    cmp byte [edi + ebx], 0
    jne .continue
    
    ; Find matching ]
    mov edx, 1
.find_loop_end:
    inc esi
    dec ecx
    jle .done  ; Unmatched [
    
    mov al, [esi]
    cmp al, '['
    je .nest_start
    cmp al, ']'
    je .nest_end
    jmp .find_loop_end
    
.nest_start:
    inc edx
    jmp .find_loop_end
    
.nest_end:
    dec edx
    jnz .find_loop_end
    jmp .continue

.loop_end:
    cmp byte [edi + ebx], 0
    je .continue
    
    ; Find matching [
    mov edx, 1
.find_loop_start:
    dec esi
    inc ecx
    cmp esi, [ebp+8]
    jl .done  ; Unmatched ]
    
    mov al, [esi]
    cmp al, ']'
    je .nest_end2
    cmp al, '['
    je .nest_start2
    jmp .find_loop_start
    
.nest_start2:
    dec edx
    jnz .find_loop_start
    jmp .continue
    
.nest_end2:
    inc edx
    jmp .find_loop_start

.done:
    mov [tape_ptr], ebx
    pop edi
    pop esi
    pop ebx
    pop ebp
    ret

bf_cleanup:
    ret
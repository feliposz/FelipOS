; os_wait_for_key -- Waits for keypress and returns key
; IN: Nothing
; OUT: AX = key pressed, other regs preserved
os_wait_for_key:
    mov ah, 11h     ; check key buffer
    int 16h
    jnz .keypress
    hlt             ; no key press, wait for interrupt and loop
    jmp os_wait_for_key

.keypress:
    mov ah, 10h     ; get key scan code
    int 16h
    ret

; os_check_for_key -- Scans keyboard for input, but doesn't wait
; IN: Nothing
; OUT: AX = 0 if no key pressed, otherwise scan code
os_check_for_key:
    mov ah, 11h     ; check key buffer
    int 16h
    jnz .keypress
    xor ax, ax      ; no keypress, return zero
    ret

.keypress:
    mov ah, 10h     ; get key scan code
    int 16h
    ret

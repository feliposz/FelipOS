; ==========================================================
; os_speaker_tone -- Generate PC speaker tone (call os_speaker_off to turn off)
; IN: AX = note frequency divisor (from 1193182 hz of the PIT)
; OUT: Nothing (registers preserved)
os_speaker_tone:
    push ax
    push bx
    push dx
    mov cx, ax
    mov al, 10110110b ; 10 = channel 2, 11 = lobyte + hibyte, 011 = square wave generator, 0 = 16 bit mode
    out 43h, al       ; set mode for PIT
    mov al, cl
    out 42h, al       ; output low byte on channel 2
    mov al, ch
    out 42h, al       ; output high byte on channel 2
    in al, 61h
    or al, 3          ; set bits 0-1 to turn on speaker
    out 61h, al
    pop dx
    pop cx
    pop ax
    ret

; ==========================================================
; os_speaker_off -- Turn off PC speaker
; IN/OUT: Nothing (registers preserved)
os_speaker_off:
    push ax
    in al, 61h
    and al, 0fch      ; clear bits 0-1 to turn off speaker
    out 61h, al
    pop ax
    ret

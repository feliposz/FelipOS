%include 'felipos.inc'

main:
    mov ax, 4560
    call os_speaker_tone
    mov ax, 10
    call os_pause
    call os_speaker_off
    ret

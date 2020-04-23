; ==========================================================
; os_port_byte_out -- Send byte to a port
; IN: DX = port address, AL = byte to send
os_port_byte_out:
    out dx, al
    ret

; ==========================================================
; os_port_byte_in -- Receive byte from a port
; IN: DX = port address
; OUT: AL = byte from port
os_port_byte_in:
    in al, dx
    ret

; ==========================================================
; os_serial_port_enable -- Set up the serial port for transmitting data
; IN: AX = 0 for normal mode (9600 baud), or 1 for slow mode (1200 baud)
os_serial_port_enable:
    push ax
    push dx
    mov dx, 0         ; Serial port 0 (COM 1)
    or ax, ax
    jz .normal
.slow:
    mov al, 10000011b ; 100 = 1200 baud, 00 = no parity, 0 = 1 stop bit, 11 = length 8 bits
    jmp .enable
.normal:
    mov al, 11100011b ; 111 = 9600 baud, 00 = no parity, 0 = 1 stop bit, 11 = length 8 bits
.enable:
    mov ah, 0         ; enable serial port
    int 14h
    pop dx
    pop ax
    ret

; ==========================================================
; os_send_via_serial -- Send a byte via the serial port
; IN: AL = byte to send via serial
; OUT: AH = Bit 7 clear on success
os_send_via_serial:
    push dx
    mov dx, 0
    mov ah, 1         ; send character
    int 14h
    pop dx
    ret

; ==========================================================
; os_get_via_serial -- Get a byte from the serial port
; OUT: AL = byte that was received
; OUT: AH = Bit 7 clear on success
os_get_via_serial:
    push dx
    mov dx, 0
    mov ah, 2         ; receive character
    int 14h
    pop dx
    ret

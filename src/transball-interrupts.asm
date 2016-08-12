;-----------------------------------------------
; Note: this routine was taken from http://map.grauw.nl/sources/vdp_detection.php
;
; Test if the VDP is a TMS9918A (MSX1).
;
; The VDP ID number was only introduced in the V9938, so we have to use a
; different method to detect the TMS9918A. We wait for the vertical blanking
; interrupt flag, and then quickly read status register 2 and expect bit 6
; (VR, vertical retrace flag) to be set as well. The TMS9918A has only one
; status register, so bit 6 (5S, 5th sprite flag) will return 0 in stead.
;
; f <- z: TMS9918A, nz: V99X8
;
VDP_IsTMS9918A:
    in a,(99H)           ; read s#0, make sure interrupt flag is reset
    di
VDP_IsTMS9918A_Wait:
    in a,(99H)           ; read s#0
    and a                ; wait until interrupt flag is set
    jp p,VDP_IsTMS9918A_Wait
    ld a,2               ; select s#2 on V9938
    out (99H),a
    ld a,15 + 128
    out (99H),a
    nop
    nop
    in a,(99H)           ; read s#2 / s#0
    ex af,af'
    xor a                ; select s#0 as required by BIOS
    out (99H),a
    ld a,15 + 128
    ei
    out (99H),a
    ex af,af'
    and 01000000B        ; check if bit 6 was 0 (s#0 5S) or 1 (s#2 VR)
    ret



;-----------------------------------------------
; saves the old interrupt
save_interrupts:
    ld hl,HKEY
    ld de,old_HKEY_interrupt_buffer
    ld bc,3
    ldir
    ld hl,TIMI
    ld de,old_TIMI_interrupt_buffer
    ld bc,3
    ldir
    ret

;-----------------------------------------------
; Checks whether we have an MSX1 or an MSX2 (or above), and sets the proper interrupt handler
Set_SmoothScroll_Interrupt:

    xor a
    ld (vertical_scroll_for_r23),a
    ld (desired_vertical_scroll_for_r23),a
    ld (horizontal_scroll_for_r18),a
    ld (desired_horizontal_scroll_for_r18),a

    ld a,(isMSX2)
    and a
    jp z,Set_SmoothScroll_Interrupt_MSX1

    ;; set the line interrupt to trigger after the first 8 lines
    ld a,5  ; I set it to 5, since apparently the code takes 5 lines of time to execute
    out (#99),a
    ld a,19+128
    out (#99),a

    di

    ld a,#c3    ;; #c3 is the opcode for "jp", so this sets "jp MSX2_SmoothScroll_Interrupt" as the interrupt code
    ld (HKEY),a
    ld hl,MSX2_SmoothScroll_Interrupt
    ld (HKEY+1),hl

    ld a,#c9    ;; #c9 is the opcode for "ret"
    ld (TIMI),a

    ;; activate line interrupts:
    ld a,(VDP_REGISTER_0)
    or #10
    ld (VDP_REGISTER_0),a
    out (#99),a
    ld a,0+128
    out (#99),a

    ei
    ret
Set_SmoothScroll_Interrupt_MSX1:

    ld a,#c3    ;; #c3 is the opcode for "jp", so this sets "jp MSX2_SmoothScroll_Interrupt" as the interrupt code
    ld (HKEY),a
    ld hl,MSX1_Interrupt
    ld (HKEY+1),hl

    ei 
    ret


Restore_Interrupt:
    xor a
    ld (vertical_scroll_for_r23),a
    ld (desired_vertical_scroll_for_r23),a
    ld (horizontal_scroll_for_r18),a
    ld (desired_horizontal_scroll_for_r18),a

    ld a,(isMSX2)
    and a
    jp z,Restore_Interrupt_MSX1

    ;; deactivate line interrupts:
    ld a,(VDP_REGISTER_0)
    and #ef
    ld (VDP_REGISTER_0),a
    out (#99),a
    ld a,0+128
    out (#99),a

    ;; Set NO vertical offset:
    ld b,0
    ld c,23
    call WRTVDP

Restore_Interrupt_MSX1:
    di
    ld hl,old_HKEY_interrupt_buffer
    ld de,HKEY
    ld bc,3
    ldir    
    ld hl,old_TIMI_interrupt_buffer
    ld de,TIMI
    ld bc,3
    ldir    
    ei

    ret

MSX2_SmoothScroll_Interrupt:
    push af
        
    ;; if bit 0 of register S#1 is 1, this is a line interrupt
    ;; read S#1:
    ld a,1  ; read S#1
    out (#99),a
    ld a,128+15
    out (#99),a
    in a,(#99)

    rrca
    jp c,MSX2_SmoothScroll_Interrupt_Line_Interrupt 

    ;; We get to this point if it's a vertical sync interrupt:
    xor a   ; read S#0 (otherwise, the program hangs)
    out (#99),a
    ld a,128+15
    out (#99),a 
    in a,(#99)

    ;; Set NO vertical offset:
;    ld b,0
;    ld c,23
;    call WRTVDP
    xor a
    out (#99),a
    ld a,128+23
    out (#99),a

;    ld b,0
;    ld c,18
;    call WRTVDP
    xor a
    out (#99),a
    ld a,128+18
    out (#99),a

    ld a,(current_game_frame)
    inc a
    ld (current_game_frame),a

    pop af
    ret

    ;; We get to this point if it's a line interrupt:
MSX2_SmoothScroll_Interrupt_Line_Interrupt:
    xor a   ; read S#0 (otherwise, the program hangs)
    out (#99),a
    ld a,128+15
    out (#99),a 
    in a,(#99)

;    ld a,(vertical_scroll_for_r23)
;    ld b,a
;    ld c,23
;    call WRTVDP
    ld a,(vertical_scroll_for_r23)
    out (#99),a
    ld a,128+23
    out (#99),a

;    ld a,(horizontal_scroll_for_r18)
;    ld b,a
;    ld c,18
;    call WRTVDP
    ld a,(horizontal_scroll_for_r18)
    out (#99),a
    ld a,128+18
    out (#99),a

    pop af
    ret


MSX1_Interrupt:
    push af
        
    ld a,(current_game_frame)
    inc a
    ld (current_game_frame),a

    pop af
    ret

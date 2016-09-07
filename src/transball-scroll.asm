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
    ld  b,a
    nop
    in a,(99H)           ; read s#2 / s#0
    and 01000000B        ; check if bit 6 was 0 (s#0 5S) or 1 (s#2 VR)
    ret z				 ; A=0 TMS9918A
	
	inc a                ; select s#1 on V99x8
    di 
	out (99H),a
    ld a,b
    out (99H),a
    nop
    nop
    in a,(99H)           ; read s#2 / s#0
    rra
	and 15 				; identification in a
	jr nz,VDP_IsTMS9918A_end	; A=2 V9958
	inc a						; A=1 V9938
VDP_IsTMS9918A_end:
    ex af,af'
    xor a                ; select s#0 as required by BIOS
    out (99H),a
    ld a,b
    ei
    out (99H),a
    ex af,af'
	ret
;-----------------------------------------------
; Code to change the VDP addresses trying to be able to use
; a 25th row of patterns in Screen 2 in MSX2
setup_VDP_addresses:
    ld bc,#3705	
    call WRTVDP		; SAT at 1b80h
	ld a,(MSXType)
	or 	a
	ret z		; hybrid mode only on msx2 and upper
    ld bc,#9F03
    call WRTVDP
    ld bc,#0004
    jp WRTVDP
	


;-----------------------------------------------
; saves the old interrupt
save_interrupts:
    ld hl,HKEY
    ld de,old_HKEY_interrupt_buffer
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

    di		;; disable interrupts before fiddling with hooks

    ld a,(useSmoothScroll)
    and a
    jr z,Set_SmoothScroll_Interrupt_MSX1

    ;; set the line interrupt to trigger after the first 8 lines
    ld a,5  ; I set it to 5, since apparently the code takes 3 lines of time to execute
    out (#99),a
    ld a,19+128
    out (#99),a

    ld a,#c3    ;; #c3 is the opcode for "jp", so this sets "jp MSX2_SmoothScroll_Interrupt" as the interrupt code
    ld (HKEY),a

    ld a,(useSmoothScroll)
    cp 2
    jp z,Set_SmoothScroll_Interrupt_MSX2P
    ld hl,MSX2_SmoothScroll_Interrupt
    ld (HKEY+1),hl
    jp Set_SmoothScroll_Interrupt_continue
Set_SmoothScroll_Interrupt_MSX2P:
    ld hl,MSX2P_SmoothScroll_Interrupt
    ld (HKEY+1),hl
Set_SmoothScroll_Interrupt_continue:

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
    ld a,#c3    ;; #c3 is the opcode for "jp", so this sets "jp MSX1_Interrupt" as the interrupt code
    ld (HKEY),a
    ld hl,MSX1_Interrupt
    ld (HKEY+1),hl

    ei 
    ret


Restore_Interrupt:

    ld a,(useSmoothScroll)
    and a
    jp z,Restore_Interrupt_MSX1

    di
	;; deactivate line interrupts:
    ld a,(VDP_REGISTER_0)
    and #ef
    ld (VDP_REGISTER_0),a
    out (#99),a
    ld a,0+128
    out (#99),a

    ;; Set NO vertical offset:
    ld bc,#0017
    call WRTVDP

Restore_Interrupt_MSX1:
    di
    ld hl,old_HKEY_interrupt_buffer
    ld de,HKEY
    ld bc,3
    ldir    
    ei

    ret

MSX2_SmoothScroll_Interrupt:
    ; push af
        
    ;; if bit 0 of register S#1 is 1, this is a line interrupt, otherwise it is vblank
    ;; read S#1:
    ld a,1  ; read S#1
    out (#99),a
    ld a,128+15
    out (#99),a

    in a,(#99)
    rrca
    jp c,MSX2_SmoothScroll_Interrupt_Line_Interrupt 

    ;; We get to this point if it's a vertical sync interrupt:
    xor a   ; select S#0 again (otherwise, the program hangs)
    out (#99),a
    ld a,128+15
    out (#99),a 
    in a,(#99)	;; read S#0 to enable next vblank

    ;; Set NO vertical/horizontal offset:
    xor a
    out (#99),a
    ld a,128+23
    out (#99),a

    xor a
    out (#99),a
    ld a,128+18
    out (#99),a

    jp MSX1_Interrupt_after_push

    ;; We get to this point if it's a line interrupt:
MSX2_SmoothScroll_Interrupt_Line_Interrupt:
    xor a   ; select S#0 again (otherwise, the program hangs)
    out (#99),a
    ld a,128+15
    out (#99),a 
    ; in a,(#99)  ;; no need to read S#0 again

    ld a,(vertical_scroll_for_r23)
    out (#99),a
    ld a,128+23
    out (#99),a

    ld a,(horizontal_scroll_for_r18)
    out (#99),a
    ld a,128+18
    out (#99),a

    ; pop af
    ret


MSX1_Interrupt:
    ; push af
        
MSX1_Interrupt_after_push:
    ld a,(current_game_frame)
    inc a
    ld (current_game_frame),a

    ; pop af
    ret

	
	
MSX2P_SmoothScroll_Interrupt:
    ; push af
        
    ;; if bit 0 of register S#1 is 1, this is a line interrupt, otherwise it is vblank
    ;; read S#1:
    ld a,1  ; read S#1
    out (#99),a
    ld a,128+15
    out (#99),a
    in a,(#99)

    rrca
    jp c,MSX2P_SmoothScroll_Interrupt_Line_Interrupt 

    ;; We get to this point if it's a vertical sync interrupt:
    xor a   ; select S#0 again (otherwise, the program hangs)
    out (#99),a
    ld a,128+15
    out (#99),a 
    in a,(#99)	;; read S#0 to enable next vblank

    ;; Set NO vertical/horizontal offset:
    xor a
    out (#99),a
    ld a,128+23
    out (#99),a
	
    xor a			;;R#27=0
    out (#99),a
    ld a,128+27
    out (#99),a

	xor a			;;R#25=0
    out (#99),a
    ld a,128+25
    out (#99),a

    jp MSX1_Interrupt_after_push

    ;; We get to this point if it's a line interrupt:
MSX2P_SmoothScroll_Interrupt_Line_Interrupt:
	ld a,2			;; mask border
    out (#99),a
    ld a,128+25
    out (#99),a

    ld a,(vertical_scroll_for_r23)
    out (#99),a
    ld a,128+23
    out (#99),a

    ; ld a,(desired_horizontal_scroll_for_r18)
    ld a,(horizontal_scroll_for_r18)
	neg
	add a,7
    out (#99),a
    ld a,128+27
    out (#99),a		;;R#27=horizontal_scroll
    

    xor a   ; select S#0 again (otherwise, the program hangs)
    out (#99),a
    ld a,128+15
    out (#99),a 
    ; in a,(#99)  ;; no need to read S#0 again

    ; pop af
    ret


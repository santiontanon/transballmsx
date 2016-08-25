;-----------------------------------------------
; data to decode in ix  (I know ix is slow, but it's convenient to have hl free in the code below)
; destination of decoding: de
; number of bytes to decode: bc
RLE_decode:
RLE_decode_loop:
    ld a,(ix)
    cp RLE_META
    jr z,RLE_decode_loop_meta_character
    ld (de),a
    inc ix
    inc de
    dec bc
    ld a,b  ;; check if bc is 0
    or c
    jr nz,RLE_decode_loop
    ret
RLE_decode_loop_meta_character:
    inc ix
    ld a,(ix)   ;; character to copy
    inc ix
    ld l,(ix)   ;; number of times to copy it
    inc ix
RLE_decode_loop2:
    ld (de),a
    inc de
    dec bc
    dec l
    jr nz,RLE_decode_loop2
    ld a,b  ;; check if bc is 0
    or c
    jr nz,RLE_decode_loop
    ret


;-----------------------------------------------
; Source: http://map.grauw.nl/articles/mult_div_shifts.php#mult
; Multiply 16-bit values (with 16-bit result)
; In: Multiply BC with DE
; Out: HL = result
Mult_BC_by_DE: 
    ld a,b
    ld b,16
Mult_BC_by_DE_Loop:
    add hl,hl
    sla c
    rla
    jr nc,Mult_BC_by_DE_NoAdd
    add hl,de
Mult_BC_by_DE_NoAdd:
    djnz Mult_BC_by_DE_Loop
    ret


;-----------------------------------------------
; In: Multiply A with DE
; Out: HL = result
Mult_A_by_DE: 
    ld b,8
    ld hl,0
Mult_A_by_DE_Loop:
    add hl,hl
    sla a 
    jr nc,Mult_A_by_DE_NoAdd
    add hl,de
Mult_A_by_DE_NoAdd:
    djnz Mult_A_by_DE_Loop
    ret


;-----------------------------------------------
; Source: http://map.grauw.nl/articles/mult_div_shifts.php#mult
; Multiply 8-bit values
; In:  Multiply H with E
; Out: HL = result
;
Mult_H_by_E:
    ld d,0
    ld l,d
    ld b,8
Mult_H_by_E_Loop:
    add hl,hl
    jr nc,Mult_H_by_E_NoAdd
    add hl,de
Mult_H_by_E_NoAdd:
    djnz Mult_H_by_E_Loop
    ret
       

;-----------------------------------------------
; Source: http://z80-heaven.wikidot.com/math#toc12
; Two routines to get the absolute value of HL and DE
absHL:
     bit 7,h
     ret z
     xor a 
     sub l 
     ld l,a
     sbc a,a 
     sub h 
     ld h,a
     ret

absDE:
     bit 7,d
     ret z
     xor a 
     sub e 
     ld e,a
     sbc a,a 
     sub d 
     ld d,a
     ret


;-----------------------------------------------
; Ensures HL is not larger than BC
HL_NOT_BIGGER_THAN_BC:
    push hl
    xor a
    sbc hl,bc
    pop hl
    ret m
    ld h,b
    ld l,c
    ret


;-----------------------------------------------
; Ensures HL is not smaller than BC
HL_NOT_SMALLER_THAN_BC:
    push hl
    xor a
    sbc hl,bc
    pop hl
    ret p
    ld h,b
    ld l,c
    ret
	
;-----------------------------------------------
; SUB HL,BC and divide by 16 HL
sub_HL_BC_divide_HL_by_16:
	xor a
	sbc hl,bc
;-----------------------------------------------
; divide by 16 HL
divide_HL_by_16: 
	ld a,h
	and a
	jp m,divide_HL_by_16_neg
    rrca	
    rr l
    rrca
    rr l
    rrca
    rr l
    rrca
    rr l
	and 15
	ld h,a
	ret
divide_HL_by_16_neg:
    rrca	
    rr l
    rrca
    rr l
    rrca
    rr l
    rrca
    rr l
	or 0F0h
	ld h,a
	ret
;-----------------------------------------------
; outi 32 times HL 
outi32:
    ld bc,32*256+VDP_DATA
b3:	outi
	jp nz,b3
	ret
;-----------------------------------------------
; Source: https://www.msx.org/forum/msx-talk/development/8-bit-atan2?page=0
; 8-bit atan2
; Calculate the angle, in a 256-degree circle.
; The trick is to use logarithmic division to get the y/x ratio and
; integrate the power function into the atan table. 
;   input
;   B = x, C = y    in -128,127
;
;   output
;   A = angle       in 0-255
;      |
;  q1  |  q0
;------+-------
;  q3  |  q2
;      |
atan2:  
        ld  de,#8000           
        
        ld  a,c
        add a,d
        rl  e               ; y-                    
        
        ld  a,b
        add a,d
        rl  e               ; x-                    
        
        dec e
        jp  z,atan2_q1
        dec e
        jp  z,atan2_q2
        dec e
        jp  z,atan2_q3
        
atan2_q0:         
        ld  h,log2_tab / 256
        ld  l,b
        
        ld  a,(hl)          ; 32*log2(x)
        ld  l,c
        
        sub (hl)          ; 32*log2(x/y)
        
        jr  nc,atan2_1f           ; |x|>|y|
        neg             ; |x|<|y|   A = 32*log2(y/x)
atan2_1f:      
        ld  l,a

        ld  h,atan_tab / 256
        ld  a,(hl)
        ret c           ; |x|<|y|
        
        neg
        and #3F            ; |x|>|y|
        ret
                
atan2_q1:     
        ld  a,b
        neg
        ld  b,a
        call    atan2_q0
        neg
        and #7F
        ret
        
atan2_q2:     
        ld  a,c
        neg
        ld  c,a
        call    atan2_q0
        neg
        ret     
        
atan2_q3:     
        ld  a,b
        neg
        ld  b,a
        ld  a,c
        neg
        ld  c,a
        call    atan2_q0
        add a,128
        ret

        ; align to byte        
        ; align #100
        ds ((($-1)/#100)+1)*#100-$
        
        ;;;;;;;; atan(2^(x/32))*128/pi ;;;;;;;;
atan_tab:   
        db 020h,020h,020h,021h,021h,022h,022h,023h,023h,023h,024h,024h,025h,025h,026h,026h
        db 026h,027h,027h,028h,028h,028h,029h,029h,02Ah,02Ah,02Ah,02Bh,02Bh,02Ch,02Ch,02Ch
        db 02Dh,02Dh,02Dh,02Eh,02Eh,02Eh,02Fh,02Fh,02Fh,030h,030h,030h,031h,031h,031h,031h
        db 032h,032h,032h,032h,033h,033h,033h,033h,034h,034h,034h,034h,035h,035h,035h,035h
        db 036h,036h,036h,036h,036h,037h,037h,037h,037h,037h,037h,038h,038h,038h,038h,038h
        db 038h,039h,039h,039h,039h,039h,039h,039h,039h,03Ah,03Ah,03Ah,03Ah,03Ah,03Ah,03Ah
        db 03Ah,03Bh,03Bh,03Bh,03Bh,03Bh,03Bh,03Bh,03Bh,03Bh,03Bh,03Bh,03Ch,03Ch,03Ch,03Ch
        db 03Ch,03Ch,03Ch,03Ch,03Ch,03Ch,03Ch,03Ch,03Ch,03Dh,03Dh,03Dh,03Dh,03Dh,03Dh,03Dh
        db 03Dh,03Dh,03Dh,03Dh,03Dh,03Dh,03Dh,03Dh,03Dh,03Dh,03Dh,03Dh,03Eh,03Eh,03Eh,03Eh
        db 03Eh,03Eh,03Eh,03Eh,03Eh,03Eh,03Eh,03Eh,03Eh,03Eh,03Eh,03Eh,03Eh,03Eh,03Eh,03Eh
        db 03Eh,03Eh,03Eh,03Eh,03Eh,03Eh,03Eh,03Eh,03Eh,03Eh,03Eh,03Eh,03Fh,03Fh,03Fh,03Fh
        db 03Fh,03Fh,03Fh,03Fh,03Fh,03Fh,03Fh,03Fh,03Fh,03Fh,03Fh,03Fh,03Fh,03Fh,03Fh,03Fh
        db 03Fh,03Fh,03Fh,03Fh,03Fh,03Fh,03Fh,03Fh,03Fh,03Fh,03Fh,03Fh,03Fh,03Fh,03Fh,03Fh
        db 03Fh,03Fh,03Fh,03Fh,03Fh,03Fh,03Fh,03Fh,03Fh,03Fh,03Fh,03Fh,03Fh,03Fh,03Fh,03Fh
        db 03Fh,03Fh,03Fh,03Fh,03Fh,03Fh,03Fh,03Fh,03Fh,03Fh,03Fh,03Fh,03Fh,03Fh,03Fh,03Fh
        db 03Fh,03Fh,03Fh,03Fh,03Fh,03Fh,03Fh,03Fh,03Fh,03Fh,03Fh,03Fh,03Fh,03Fh,03Fh,03Fh
 
        ;;;;;;;; log2(x)*32 ;;;;;;;; 
log2_tab:  
        db 000h,000h,020h,032h,040h,04Ah,052h,059h,060h,065h,06Ah,06Eh,072h,076h,079h,07Dh
        db 080h,082h,085h,087h,08Ah,08Ch,08Eh,090h,092h,094h,096h,098h,099h,09Bh,09Dh,09Eh
        db 0A0h,0A1h,0A2h,0A4h,0A5h,0A6h,0A7h,0A9h,0AAh,0ABh,0ACh,0ADh,0AEh,0AFh,0B0h,0B1h
        db 0B2h,0B3h,0B4h,0B5h,0B6h,0B7h,0B8h,0B9h,0B9h,0BAh,0BBh,0BCh,0BDh,0BDh,0BEh,0BFh
        db 0C0h,0C0h,0C1h,0C2h,0C2h,0C3h,0C4h,0C4h,0C5h,0C6h,0C6h,0C7h,0C7h,0C8h,0C9h,0C9h
        db 0CAh,0CAh,0CBh,0CCh,0CCh,0CDh,0CDh,0CEh,0CEh,0CFh,0CFh,0D0h,0D0h,0D1h,0D1h,0D2h
        db 0D2h,0D3h,0D3h,0D4h,0D4h,0D5h,0D5h,0D5h,0D6h,0D6h,0D7h,0D7h,0D8h,0D8h,0D9h,0D9h
        db 0D9h,0DAh,0DAh,0DBh,0DBh,0DBh,0DCh,0DCh,0DDh,0DDh,0DDh,0DEh,0DEh,0DEh,0DFh,0DFh
        db 0DFh,0E0h,0E0h,0E1h,0E1h,0E1h,0E2h,0E2h,0E2h,0E3h,0E3h,0E3h,0E4h,0E4h,0E4h,0E5h
        db 0E5h,0E5h,0E6h,0E6h,0E6h,0E7h,0E7h,0E7h,0E7h,0E8h,0E8h,0E8h,0E9h,0E9h,0E9h,0EAh
        db 0EAh,0EAh,0EAh,0EBh,0EBh,0EBh,0ECh,0ECh,0ECh,0ECh,0EDh,0EDh,0EDh,0EDh,0EEh,0EEh
        db 0EEh,0EEh,0EFh,0EFh,0EFh,0EFh,0F0h,0F0h,0F0h,0F1h,0F1h,0F1h,0F1h,0F1h,0F2h,0F2h
        db 0F2h,0F2h,0F3h,0F3h,0F3h,0F3h,0F4h,0F4h,0F4h,0F4h,0F5h,0F5h,0F5h,0F5h,0F5h,0F6h
        db 0F6h,0F6h,0F6h,0F7h,0F7h,0F7h,0F7h,0F7h,0F8h,0F8h,0F8h,0F8h,0F9h,0F9h,0F9h,0F9h
        db 0F9h,0FAh,0FAh,0FAh,0FAh,0FAh,0FBh,0FBh,0FBh,0FBh,0FBh,0FCh,0FCh,0FCh,0FCh,0FCh
        db 0FDh,0FDh,0FDh,0FDh,0FDh,0FDh,0FEh,0FEh,0FEh,0FEh,0FEh,0FFh,0FFh,0FFh,0FFh,0FFh

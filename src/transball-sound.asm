;-----------------------------------------------
; sets the variables to play the SFX pointed by hl
play_SFX:
    ld (SFX_pointer),hl
    ld a,1
    ld (SFX_play),a
    xor a
    ld (SFX_channel1_skip_counter),a
    ld hl,SFX_channel1_repeat_stack
    ld (SFX_channel1_repeat_stack_ptr),hl
    ret

;-----------------------------------------------
; SFX playing routine
; adapted by this example: https://www.msx.org/forum/development/msx-development/music-how-code-music-asm-or-without-bios-routines
; Thanks to NYYRIKKI
SFX_INT:    
    ld a,(SFX_play)
    and a   ;; equivalent to cp 0, but faster
    jp z,CLEAR_SFX_VOLUME_AND_END       ;; if we are not to play any SFX, return

    ld a,(SFX_channel1_skip_counter)
    ld (SFX_skip_counter),a
    ld ix,(SFX_channel1_repeat_stack_ptr)
    ld hl,(SFX_pointer)
    call SFX_INT_CHANNEL
    ld (SFX_pointer),hl
    ld (SFX_channel1_repeat_stack_ptr),ix
    ld a,(SFX_skip_counter)
    ld (SFX_channel1_skip_counter),a
    ret


MUSIC_INT:    
    ld a,(MUSIC_tempo)
    ld b,a
    ld a,(MUSIC_tempo_counter)
    inc a
    cp b
    jp p,MUSIC_INT_AT_TEMPO
    ld (MUSIC_tempo_counter),a
    ret

MUSIC_INT_AT_TEMPO:
    xor a
    ld (MUSIC_tempo_counter),a
    ld a,(MUSIC_play)
    and a   ;; equivalent to cp 0, but faster
    jr z,CLEAR_SFX_VOLUME_AND_END       ;; if we are not to play any SFX, return

    ld a,(SFX_channel1_skip_counter)
    ld (SFX_skip_counter),a
    ld ix,(SFX_channel1_repeat_stack_ptr)
    ld hl,(SFX_channel1_pointer)
    call SFX_INT_CHANNEL
    ld (SFX_channel1_pointer),hl
    ld (SFX_channel1_repeat_stack_ptr),ix
    ld a,(SFX_skip_counter)
    ld (SFX_channel1_skip_counter),a

    ld a,(SFX_channel2_skip_counter)
    ld (SFX_skip_counter),a
    ld ix,(SFX_channel2_repeat_stack_ptr)
    ld hl,(SFX_channel2_pointer)
    call SFX_INT_CHANNEL
    ld (SFX_channel2_pointer),hl
    ld (SFX_channel2_repeat_stack_ptr),ix
    ld a,(SFX_skip_counter)
    ld (SFX_channel2_skip_counter),a

    ld a,(SFX_channel3_skip_counter)
    ld (SFX_skip_counter),a
    ld ix,(SFX_channel3_repeat_stack_ptr)
    ld hl,(SFX_channel3_pointer)
    call SFX_INT_CHANNEL
    ld (SFX_channel3_pointer),hl
    ld (SFX_channel3_repeat_stack_ptr),ix
    ld a,(SFX_skip_counter)
    ld (SFX_channel3_skip_counter),a
    ret

CLEAR_SFX_VOLUME_AND_END:
    ld a,8
    ld e,0
    call WRTPSG
    ld a,9
    ld e,0
    call WRTPSG
    ld a,10
    ld e,0
    call WRTPSG
    ret


SFX_INT_CHANNEL:
    and a   ;; equivalent to cp 0, but faster
    jp nz,SFX_INT_MULTISKIP_STEP
SFX_INT_LOOP:
    ld a,(hl)
    inc hl

    cp SFX_END                 
    jr z,END_OF_SFX         ;; if the SFX is over, we are done

    cp SFX_SKIP
    ret z

    cp SFX_MULTISKIP
    jr z,SFX_INT_MULTISKIP

    cp SFX_GOTO
    jr z,SFX_INT_GOTO

    cp SFX_REPEAT
    jr z,SFX_INT_REPEAT

    cp SFX_END_REPEAT
    jr z,SFX_INT_END_REPEAT

    ld e,(hl)             
    inc hl
    call WRTPSG                ;; send command to PSG
    jr SFX_INT_LOOP     

END_OF_SFX:
    xor a
    ld (SFX_play),a
    ld (MUSIC_play),a
    pop af  ;; simulate a "ret"
    ret

SFX_INT_GOTO:
    ld e,(hl)
    inc hl
    ld d,(hl)
    inc hl
    ex de,hl
    jr SFX_INT_LOOP

SFX_INT_MULTISKIP:
    ld a,(hl)
    inc hl
    dec a
    ld (SFX_skip_counter),a
    ret

SFX_INT_MULTISKIP_STEP:
    dec a
    ld (SFX_skip_counter),a
    ret

SFX_INT_REPEAT:
    ld a,(hl)
    inc hl
    ld (ix),a
    ld (ix+1),l
    ld (ix+2),h
    inc ix
    inc ix
    inc ix
    jr SFX_INT_LOOP

SFX_INT_END_REPEAT:
    ;; decrease the top value of the repeat stack
    ;; if it is 0, pop
    ;; if it is not 0, goto the repeat point
    ld a,(ix-3)
    dec a
    jr z,SFX_INT_END_REPEAT_POP
    ld (ix-3),a
    ld l,(ix-2)
    ld h,(ix-1)
    jr SFX_INT_LOOP

SFX_INT_END_REPEAT_POP:
    dec ix
    dec ix
    dec ix
    jr SFX_INT_LOOP


CLEAR_SFX_AND_MUSIC_STATUS:
    xor a
    ld (SFX_play),a
    xor a
    ld (MUSIC_play),a
    ld (SFX_channel1_skip_counter),a
    ld (SFX_channel2_skip_counter),a
    ld (SFX_channel3_skip_counter),a
    ld hl,SFX_channel1_repeat_stack
    ld (SFX_channel1_repeat_stack_ptr),hl
    ld hl,SFX_channel2_repeat_stack
    ld (SFX_channel2_repeat_stack_ptr),hl
    ld hl,SFX_channel3_repeat_stack
    ld (SFX_channel3_repeat_stack_ptr),hl
    jp CLEAR_SFX_VOLUME_AND_END


;-----------------------------------------------
; Sound effect definition    
SFX_thrust:             ;; ship thrust
    db 8,#08        ;; #08 half volume
    db 6,#1f        ;; frequency of the noise
    db 7,#87        ;; sets channels to noise
    db SFX_END

SFX_bullet:   
    db 0,#00,1,#08   ;; frequency
    db 8,#10          ;; volume
    db 11,#00,12,#20    ;; envelope frequency
    db 13,#09       ;; shape of the envelope
    db 7,#b8        ;; sets channels to wave
    db SFX_SKIP,SFX_SKIP
    db 0,#00,1,#0f   ;; frequency
    db SFX_MULTISKIP,12
    db SFX_END    


SFX_enemy_bullet:   
    db 0,#00,1,#04   ;; frequency
    db 8,#10          ;; volume
    db 11,#00,12,#10    ;; envelope frequency
    db 13,#09       ;; shape of the envelope
    db 7,#b8        ;; sets channels to wave
    db SFX_SKIP,SFX_SKIP
    db 0,#00,1,#08   ;; frequency
    db SFX_MULTISKIP,12
    db SFX_END    


SFX_button:   
    db 0,#80,1,#00   ;; frequency
    db 8,#10          ;; volume
    db 11,#00,12,#10    ;; envelope frequency
    db 13,#09       ;; shape of the envelope
    db 7,#b8        ;; sets channels to wave
    db SFX_SKIP,SFX_SKIP
    db 0,#00,1,#01   ;; frequency
    db SFX_MULTISKIP,12
    db SFX_END   


SFX_explosion:      ;; explosion
    db 8,#10        ;; volume set to envelope
    db 6,#2f        ;; frequency of the noise
    db 7,#87        ;; sets channels to noise
    db 11,#00,12,#20    ;; envelope frequency
    db 13,#09       ;; sets the envelope
    db SFX_MULTISKIP,4
    db 6,#27        ;; frequency of the noise
    db SFX_MULTISKIP,4
    db 6,#1f        ;; frequency of the noise
    db SFX_MULTISKIP,4
    db 6,#17        ;; frequency of the noise
    db SFX_MULTISKIP,4
    db 6,#0f        ;; frequency of the noise
    db SFX_MULTISKIP,4
    db 6,#07        ;; frequency of the noise
    db SFX_MULTISKIP,8
    db SFX_END    

SFX_ball_capture:   
    db 0,#00,1,#01   ;; frequency
    db 8,#0f         ;; volume
    db 7,#b8         ;; sets channels to wave
    db SFX_MULTISKIP,4
    db 0,#00,1,#02   ;; frequency
    db SFX_MULTISKIP,4
    db 0,#00,1,#03   ;; frequency
    db SFX_MULTISKIP,4
    db 0,#00,1,#04   ;; frequency
    db SFX_MULTISKIP,4
    db SFX_END    

SFX_refuel:  
    db 0,#00,1,#01   ;; frequency
    db 8,#0f         ;; volume
    db 7,#b8         ;; sets channels to wave
    db SFX_MULTISKIP,4
    db 0,#00,1,#02   ;; frequency
    db SFX_END    

SFX_timer:   
    db 0,#00,1,#01   ;; frequency
    db 8,#0f         ;; volume
    db 7,#b8         ;; sets channels to wave
    db SFX_MULTISKIP,4
    db SFX_END      

SFX_gamestart:   
    db 0,#00,1,#0f   ;; frequency
    db 8,#10          ;; volume set to envelope
    db 11,#00,12,#08    ;; envelope frequency
    db 13,#0e       ;; shape of the envelope
    db 7,#b8        ;; sets channels to wave
    db SFX_MULTISKIP,32
    db SFX_END      

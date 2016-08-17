;-----------------------------------------------
; Game Start:
Game_StartFromBeginning:
    ld a,0
    ld (current_level),a  ;; sets which map to load
    jr Level_Restart


;-----------------------------------------------
; Restart a level:
Level_Restart:
    call Restore_Interrupt

    call CLEAR_SFX_AND_MUSIC_STATUS
    call clearScreenLeftToRight

    ld a,(current_level)
    cp 16   ;; maximum number of levels
    jp z,GameComplete

    ;; transfer variables to RAM:
    ld hl,ROMtoRAM
    ld de,RAM
    ld bc,endROMtoRAM-ROMtoRAM
    ldir

    call LOADMAP        ;; loads map
    ld de,InterLevel_text2_password
    ld hl,mappasswords
    ld b,0
    ld a,(current_level)
    ld c,a
    sla c   ;; multiply by 8 to get the password offset
    rl b
    sla c
    rl b
    sla c
    rl b
    add hl,bc   ;; hl now has a pointer to the password of this level
    ld bc,8
    ldir

    call updateTimeAndFuel_done_updating_time   ;; this will update the scoreboard string
    
    ;; render scoreboard:
    ld de,NAMTBL2
    ld hl,scoreboard
    ld bc,32
    call LDIRVM

    ld de,NAMTBL2+32*10
    ld hl,InterLevel_text
    ld bc,32
    call LDIRVM

    ld de,NAMTBL2+32*12+7
    ld hl,InterLevel_text2
    ld bc,19
    call LDIRVM

    ld de,NAMTBL2+32*14+11
    ld hl,Level_complete_text6
    ld bc,11
    call LDIRVM

    call getcharacter_nonwaiting_reset

InterLevel_Loop:
    call SFX_INT
    halt    ;; give the CPU a break
    
    call getcharacter_nonwaiting
    cp 27   ;; ESC
    jp z,SplashScreen

    ;; wait for space to be pressed:
    ld a,(fire_button_status)
    ld b,a
    call GTTRIG0AND1
    ld (fire_button_status),a
    cp b
    jr z,InterLevel_Loop_Continue
    and a   ;; equivalent to cp 0, but faster
    jr z,InterLevel_Loop_Continue

    jp Game_Loop    ; Space pressed, start the game!

InterLevel_Loop_Continue:

    jp InterLevel_Loop


Level_complete:
    call Restore_Interrupt

    call clearScreenLeftToRight

    ;; draw line 1:
    ld de,NAMTBL2+32*6+8
    ld hl,Level_complete_text1
    ld bc,15
    call LDIRVM

    ;; draw line 2:
    ;; set current time:
    call clear_best_times_buffer
    ld de,best_times_buffer+7
    ld hl,Level_complete_text2
    ld bc,15
    ldir

    ld hl,current_play_time
    ld de,current_time_buffer
    ldi ;; minutes
    ldi ;; ten seconds
    ldi ;; seconds 
    ld a,(hl)
    add a,a     ;; multiply by 2 to get hundredths of a second (assuming 50fps)
    ld b,0
Level_complete_time_convert_loop:
    cp 10
    jp m,Level_complete_time_convert_loop_done
    inc b
    sub 10
    jr Level_complete_time_convert_loop
Level_complete_time_convert_loop_done:
    ex de,hl
    ld (hl),b
    inc hl
    ld (hl),a

    ld ix,current_time_buffer
    ld a,(ix)
    add a,'0'
    ld (best_times_buffer+15),a
    ld a,(ix+1)
    add a,'0'
    ld (best_times_buffer+17),a
    ld a,(ix+2)
    add a,'0'
    ld (best_times_buffer+18),a
    ld a,(ix+3)
    add a,'0'
    ld (best_times_buffer+20),a
    ld a,(ix+4)
    add a,'0'
    ld (best_times_buffer+21),a

    ld de,NAMTBL2+32*10
    ld hl,best_times_buffer
    ld bc,32
    call LDIRVM

    ;; draw line 3:
    ;; set the best time:
    call clear_best_times_buffer
    ld de,best_times_buffer+7
    ld hl,Level_complete_text3
    ld bc,15
    ldir

    ld ix,best_times
    ld a,(current_level)
    ld c,a
    ld b,0
    add ix,bc       ;; ix = best_times + (current_level)*5
    add ix,bc    
    add ix,bc    
    add ix,bc    
    add ix,bc    

    push ix
    call update_best_times
    pop ix

    ld a,(ix)
    add a,'0'
    ld (best_times_buffer+15),a
    ld a,(ix+1)
    add a,'0'
    ld (best_times_buffer+17),a
    ld a,(ix+2)
    add a,'0'
    ld (best_times_buffer+18),a
    ld a,(ix+3)
    add a,'0'
    ld (best_times_buffer+20),a
    ld a,(ix+4)
    add a,'0'
    ld (best_times_buffer+21),a

    ld de,NAMTBL2+32*12
    ld hl,best_times_buffer
    ld bc,32
    call LDIRVM

    ;; draw line 4:
    ld de,NAMTBL2+32*16+10
    ld hl,Level_complete_text4
    ld bc,11
    call LDIRVM
    ;; draw line 5:
    ld de,NAMTBL2+32*17+4
    ld hl,Level_complete_text5
    ld bc,25
    call LDIRVM
    ;; draw line 6:
    ld de,NAMTBL2+32*18+8
    ld hl,Level_complete_text6
    ld bc,11
    call LDIRVM

    call getcharacter_nonwaiting_reset

Level_complete_Loop:
    call SFX_INT
    halt    

    call getcharacter_nonwaiting
    cp 'A'
    jp z,Level_Restart
    cp 27   ;; ESC
    jp z,SplashScreen

    ;; wait for space to be pressed:
    ld a,(fire_button_status)
    ld b,a
    call GTTRIG0AND1
    ld (fire_button_status),a
    cp b
    jp z,Level_complete_Loop
    and a   ;; equivalent to cp 0, but faster
    jp z,Level_complete_Loop

Level_complete_Loop_Continue:
    ;; next level!
    ld a,(current_level)
    inc a
    ld (current_level),a
    jp Level_Restart


;-----------------------------------------------
; assumes that the best time to update is pointed by ix
update_best_times:
    ld b,5
    ld hl,current_time_buffer
    push ix
update_best_times_loop:
    ld c,(hl)   ;; current time
    ld a,(ix)   ;; best time
    cp c
    jp m,update_best_times_worse_time
    jp nz,update_best_times_better_time ;; if it's not worse, and not equal, must be best!
    inc hl
    inc ix
    djnz update_best_times_loop

update_best_times_better_time:
    ;; update the time!
    pop ix
    ld hl,current_time_buffer
    ld b,5
update_best_times_loop_copy:
    ld a,(hl)
    ld (ix),a
    inc hl
    inc ix
    djnz update_best_times_loop_copy
    ret

update_best_times_worse_time:
    pop ix
    ret
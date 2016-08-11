;-----------------------------------------------
; Game Splash screen:
SplashScreen:
    call CLEAR_SFX_AND_MUSIC_STATUS
    call clearScreenLeftToRight

    ;; draw  text line 1
    ld de,NAMTBL2+32*8+10
    ld hl,splash_line1
    ld bc,12
    call LDIRVM

    ;; draw  text line 2
    ld de,NAMTBL2+32*10+12
    ld hl,splash_line2
    ld bc,8
    call LDIRVM

    ld bc,250
SplashScreen_Loop:
    dec bc
    ld a,b
    or c
    jp z,MainMenu

    halt
    ;; wait for space to be pressed:
    ld a,(fire_button_status)
    ld d,a
    push bc
    call GTTRIG0AND1
    pop bc
    ld (fire_button_status),a
    cp d
    jp z,SplashScreen_Loop
    and a   ;; equivalent to cp 0, but faster
    jp z,SplashScreen_Loop

    jp MainMenu    ; Space pressed, start the game!


;-----------------------------------------------
; Game complete screen:
GameComplete:
    call CLEAR_SFX_AND_MUSIC_STATUS
    call clearScreenLeftToRight

    ;; draw  text line 1
    ld de,NAMTBL2+32*6+8
    ld hl,game_complete_line1
    ld bc,16
    call LDIRVM

    ;; draw  text line 2
    ld de,NAMTBL2+32*10+3
    ld hl,game_complete_line2
    ld bc,26
    call LDIRVM

    ;; draw  text line 3
    ld de,NAMTBL2+32*11+3
    ld hl,game_complete_line3
    ld bc,19
    call LDIRVM

GameComplete_Loop:

    halt
    ;; wait for space to be pressed:
    ld a,(fire_button_status)
    ld d,a
    call GTTRIG0AND1
    ld (fire_button_status),a
    cp d
    jp z,GameComplete_Loop
    and a   ;; equivalent to cp 0, but faster
    jp z,GameComplete_Loop

    jp SplashScreen    ; Space pressed, restart


;-----------------------------------------------
; Main menu of the game:
MainMenu:
    ;; play music:
    call CLEAR_SFX_AND_MUSIC_STATUS
    ld a,6
    ld (MUSIC_tempo),a
    ld hl,Transball_song_channel1
    ld (SFX_channel1_pointer),hl
    ld hl,Transball_song_channel2
    ld (SFX_channel2_pointer),hl
    ld hl,Transball_song_channel3
    ld (SFX_channel3_pointer),hl
    ld a,1
    ld (MUSIC_play),a

    ld a,24
    ld (current_map_dimensions),a
    ld a,32
    ld (current_map_dimensions+1),a
    ld ix,titlescreen  ;; hl has now the pointer to the title screen in ROM 
    ld de,currentMap
    ld bc,24*32
    ld (current_map_dimensions+2),bc
    call RLE_decode
    call LOADMAP_find_animations
    ld bc,0
    ld (map_offset),bc
    ld (map_offset+2),bc
    ld de,scoreboard
    ld hl,currentMap
    ld bc,32
    ldir

MainMenu_music_already_playing:
    call clearScreenLeftToRight

    ;; clear the password part of the screen (just in case we come from the password entering part):
    xor a
    ld de,currentMap+32*22+13
    ld b,8
MainMenu_music_already_playing_clear_password_loop:
    ld (de),a
    inc de
    djnz MainMenu_music_already_playing_clear_password_loop

    ld (menu_selected_option),a
    ld (menu_timer),a
    ld (menu_input_buffer),a

    call KILBUF ;; clear the keyboard buffer (so we can use 1 - 5 to configure ship speed)

MainMenu_Loop:

    call checkForRotationSpeedConfigInput

    ;; check input:
    ld a,(fire_button_status)
    ld b,a
    call GTTRIG0AND1
    ld (fire_button_status),a
    cp b
    jp z,MainMenu_Loop_input_continue
    and a   ;; equivalent to cp 0, but faster
    jp nz,MainMenu_option_selected

MainMenu_Loop_input_continue:
    ld a,(menu_input_buffer)
    ld b,a
    push bc
    call GETSTCK0AND1
    ld (menu_input_buffer),a
    pop bc
    cp b
    jp z,MainMenu_Loop_input_continue2
    cp 1
    jp z,MainMenu_Loop_up
    cp 5
    jp z,MainMenu_Loop_down
    and a   ;; equivalent to cp 0, but faster
    jp nz,MainMenu_Loop_input_continue

MainMenu_Loop_input_continue2:
    ;; highlight the currently selected option:
    ld hl,currentMap
    ld bc,16*32
    add hl,bc

    ;; clear all the lasers:
    ld d,PATTERN_H_LASER
    ld e,0
    call MainMenu_Loop_Change_rowPatterns
    ld bc,32
    add hl,bc
    call MainMenu_Loop_Change_rowPatterns
    ld bc,32
    add hl,bc
    call MainMenu_Loop_Change_rowPatterns

    ;; highlight the selected option:
    ld hl,currentMap
    ld bc,16*32
    add hl,bc
    ld a,(menu_selected_option)
    sla a   ;; multiply by 64
    sla a
    sla a
    sla a
    sla a
    sla a
    ld b,0
    ld c,a
    add hl,bc

    ld a,(menu_timer)
    inc a
    ld (menu_timer),a
    and #08
    and a   ;; equivalent to cp 0, but faster
    jp z,MainMenu_Loop_clear_selectedOption
MainMenu_Loop_mark_selectedOption:
    ld d,0
    ld e,PATTERN_H_LASER
    call MainMenu_Loop_Change_rowPatterns
    jp MainMenu_Loop_continue

MainMenu_Loop_clear_selectedOption:
    ld d,PATTERN_H_LASER
    ld e,0
    call MainMenu_Loop_Change_rowPatterns

MainMenu_Loop_continue:
    call mapAnimationCycle
    call renderMap

    ;; needed for the animation cycle
    ld a,(current_game_frame)
    inc a
    ld (current_game_frame),a    

    call MUSIC_INT
    halt    ;; wait for the interrupt generated after screen is refreshed

    jp MainMenu_Loop


;; changes all the 'd's by 'e's in the row pointed to by hl:
MainMenu_Loop_Change_rowPatterns:
    ld c,32
MainMenu_Loop_Change_rowPatterns_loop:
    ld a,(hl)
    cp d
    jp nz,MainMenu_Loop_Change_rowPatterns_continue
    ld a,e
    ld (hl),a
MainMenu_Loop_Change_rowPatterns_continue:
    inc hl
    dec c
    jp nz,MainMenu_Loop_Change_rowPatterns_loop
    ret


MainMenu_Loop_up:
    ld a,(menu_selected_option)
    and a   ;; equivalent to cp 0, but faster
    jp z,MainMenu_Loop_up_overflow
    dec a
    ld (menu_selected_option),a
    jp MainMenu_Loop_input_continue2
MainMenu_Loop_up_overflow:
    ld a,2
    ld (menu_selected_option),a
    jp MainMenu_Loop_input_continue2

MainMenu_Loop_down:
    ld a,(menu_selected_option)
    cp 2
    jp z,MainMenu_Loop_down_overflow
    inc a
    ld (menu_selected_option),a
    jp MainMenu_Loop_input_continue2
MainMenu_Loop_down_overflow:
    xor a
    ld (menu_selected_option),a
    jp MainMenu_Loop_input_continue2


MainMenu_option_selected:
    ld a,(menu_selected_option)
    and a   ;; equivalent to cp 0, but faster
    jp z,Game_StartFromBeginning

    cp 1
    jp z,highscores

    cp 2
    jp z,entering_password

    jp MainMenu_Loop_input_continue


;-----------------------------------------------
; Highscores (best times) screen:
highscores:
    call clearScreenLeftToRight

    ;; 1) write hishscores_header to best_times_buffer
    call clear_best_times_buffer
    ld de,best_times_buffer+11
    ld hl,highscores_header
    ld bc,10
    ldir

    ;; 2) write best_times_buffer to VRAM
    ld bc,32
    ld de,NAMTBL2+32*2
    ld hl,best_times_buffer
    call LDIRVM

    ;; 3) for each map:
    ld ix,best_times
    ld bc,0
highscores_printloop:
    ;; 3.1) compose a best_times_buffer line with map name and best time
    push bc
    call clear_best_times_buffer
    ld de,best_times_buffer+7
    ld hl,highscores_text
    ld bc,18
    ldir

    ;; fill the level number:
    pop bc  ;; recover the level number (but keep it in the stack)
    push bc
    ld a,c
    cp 9
    jp m,highscores_SingleDigitLevel
highscores_TwoDigitLevel:    
    ld a,'1'
    ld (best_times_buffer+13),a
    ld a,c
    sub 10
    add a,'1'
    ld (best_times_buffer+14),a
    jr highscores_DoneWithLevelNumber
highscores_SingleDigitLevel:    
    add a,'1'
    ld (best_times_buffer+14),a
    ld a,0
    ld (best_times_buffer+13),a
highscores_DoneWithLevelNumber

    ;; fill the time: 
    ld a,(ix)
    cp 10
    jp z,highscores_no_time_yet
    add a,'0'
    ld (best_times_buffer+18),a
    ld a,(ix+1)
    add a,'0'
    ld (best_times_buffer+20),a
    ld a,(ix+2)
    add a,'0'
    ld (best_times_buffer+21),a
    ld a,(ix+3)
    add a,'0'
    ld (best_times_buffer+23),a
    ld a,(ix+4)
    add a,'0'
    ld (best_times_buffer+24),a
    jr highscores_done_setting_time
highscores_no_time_yet:
    ld a,'-'
    ld (best_times_buffer+18),a
    ld (best_times_buffer+20),a
    ld (best_times_buffer+21),a
    ld (best_times_buffer+23),a
    ld (best_times_buffer+24),a
highscores_done_setting_time:
    ;; 3.2) write best_times_buffer to VRAM
    sla c   ;; multiply by 32
    rl b
    sla c
    rl b
    sla c
    rl b
    sla c
    rl b
    sla c
    rl b
    ld hl,NAMTBL2+32*4
    add hl,bc
    ex de,hl
    ld hl,best_times_buffer
    ld bc,32
    call LDIRVM

    ld bc,5
    add ix,bc
    pop bc
    inc c
    ld a,c
    cp 16
    jp nz,highscores_printloop


highscoresloop:
    ;; check input:
    ld a,(fire_button_status)
    ld b,a
    call GTTRIG0AND1
    ld (fire_button_status),a
    cp b
    jp z,highscoresloop_continue
    and a   ;; equivalent to cp 0, but faster
    jp nz,MainMenu_music_already_playing
highscoresloop_continue:

    call MUSIC_INT
    halt

    jp highscoresloop


clear_best_times_buffer:
    xor a
    ld b,32
    ld hl,best_times_buffer
    clear_best_times_buffer_loop:
    ld (hl),a
    inc hl
    djnz clear_best_times_buffer_loop
    ret


;-----------------------------------------------
; Entering a password to start from a level that is not the first:
entering_password:
    ;; Initialize the password string to a string of dashes:
    ld a,'-'    
    ld b,8
    ld hl,password_buffer
entering_password_init_loop:
    ld (hl),a
    inc hl
    djnz entering_password_init_loop

    ;; reset the keyboard buffer:
    call getcharacter_nonwaiting_reset
    ld bc,0

entering_password_Loop:    
    push bc
    call getcharacter_nonwaiting
    pop bc
    and a   ;; equivalent to cp 0, but faster
    jp z,entering_password_Loop_nocharacter
    cp 27
    jp z,MainMenu_music_already_playing ;; ESC
    cp 8
    jp z,entering_password_delete
    cp 13
    jp z,entering_password_enter
;    cp 32
;    jp z,entering_password_enter
    ld hl,password_buffer
    add hl,bc
    ld (hl),a
    inc c
entering_password_Loop_nocharacter:
    push bc
    ;; draw the current password:
    ld de,currentMap+32*22+13
    ld hl,password_buffer
    ld bc,8
    ldir

    call mapAnimationCycle
    call renderMap

    call MUSIC_INT
    halt    ;; wait for the interrupt generated after screen is refreshed

    pop bc
    jp entering_password_Loop

entering_password_delete:
    ld a,c
    and a   ;; equivalent to cp 0, but faster
    jp z,entering_password_Loop_nocharacter   ;; if we are in position 0, there is nothing to delete
    ld a,'-'
    ld hl,password_buffer
    dec c
    add hl,bc
    ld (hl),a
    jp entering_password_Loop_nocharacter

entering_password_enter:
    ;; check if password is correct
    ld de,mappasswords
    ld b,0
entering_password_enter_external_loop
    ld a,(de)
    and a   ;; equivalent to cp 0, but faster
    jp z,MainMenu_music_already_playing ;; if we have reached the end of the array

    push bc
    push de
    ld hl,password_buffer
    ld b,8
entering_password_enter_internal_loop:
    ld a,(de)
    ld c,(hl)
    cp c
    jp nz,entering_password_enter_nomatch
    inc de
    inc hl
    djnz entering_password_enter_internal_loop

    ;; match!!
    pop de
    pop bc
    ld a,b
    ld (current_level),a  ;; sets which map to load
    jp Level_Restart

entering_password_enter_nomatch:
    pop de
    ld bc,8
    ex de,hl
    add hl,bc
    ex de,hl
    pop bc
    inc b
    jp entering_password_enter_external_loop


;-----------------------------------------------
;; Adapted from the CHGET routine here: https://sourceforge.net/p/cbios/cbios/ci/master/tree/src/main.asm#l289
;; It returns 0 if no key is ready to be read
;; If a key is ready to be read, it checks if it is one of these:
;; - ESC / DELETE / ENTER
;; - 'a' - 'z' (converts it to upper case and returns)
;; - 'Z' - 'Z'
;; - otherwise, it returns 0
getcharacter_nonwaiting:
    ld hl,(GETPNT)
    ld de,(PUTPNT)
    call DCOMPR
    jp z,getcharacter_nonwaiting_invalidkey
    ;; there is a character ready to be read:
    xor a
    ld a,(hl)
    push af
    inc hl
    ld a,l
    cp #00ff & (KEYBUF + 40)
    jr nz,getcharacter_nonwaiting_nowrap
    ld hl,KEYBUF
getcharacter_nonwaiting_nowrap:
    ld (GETPNT),hl
    pop af
    cp 27   ;; ESC
    ret z
    cp 8    ;; DELETE
    ret z
    cp 13   ;; ENTER
    ret z
    cp 'z'+1
    jp p,getcharacter_nonwaiting_invalidkey
    cp 'a'
    jp p,getcharacter_nonwaiting_lower_case
getcharacter_nonwaiting_after_converting_to_upper_case
    cp 'Z'+1
    jp p,getcharacter_nonwaiting_invalidkey
    cp 'A'
    jp m,getcharacter_nonwaiting_invalidkey
    ret

getcharacter_nonwaiting_invalidkey:
    xor a
    ret

getcharacter_nonwaiting_lower_case:
    add a,'A'-'a'
    jp getcharacter_nonwaiting_after_converting_to_upper_case

getcharacter_nonwaiting_reset:
    di
    ld hl,(PUTPNT)
    ld (GETPNT),hl
    ei
    ret





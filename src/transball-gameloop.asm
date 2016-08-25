Game_Loop:
    call clearScreenLeftToRight

    call Set_SmoothScroll_Interrupt

    ;; play the game start SFX!
    ld hl,SFX_gamestart
    call play_SFX

Game_Loop_loop:
    ;; check if ship collided:
    ld a,(shipstate)
    and a   ;; equivalent to cp 0, but faster
    jp nz,Ship_collided

    ;; check if level is complete
    ld a,(levelComplete)
    and a   ;; equivalent to cp 0, but faster
    jp nz,Level_complete

    call checkInput
;    call checkForRotationSpeedConfigInputInGame
    call applyGravityAndSpeed   
    call ballPhysics
    call enemyUpdateCycle
    call tankUpdateCycle
    call checkForShipToMapCollision
    call calculate_map_offset
    call calculate_ship_sprite_position
    call calculate_ball_sprite_position
    call calculate_bullet_sprite_positions
    call calculate_enemy_bullet_sprite_positions
    call checkForShipToEnemyBulletCollision     ;; this needs to go after 'calculate_enemy_bullet_sprite_positions'
                                                ;; since collisions are done in screen coordinates, to make sure it's done based 
                                                ;; on what the player sees
    call updateTimeAndFuel  
    call mapAnimationCycle
    call renderExplosions
    call changeSprites

    call SFX_INT

    ld a,(current_game_frame)
    ld b,a
Game_Loop_wait_for_next_frame:
    ld a,(current_game_frame)
    cp b
    jp z,Game_Loop_wait_for_next_frame
;    halt    ;; wait for the interrupt generated after screen is refreshed

    ld a,(desired_vertical_scroll_for_r23)
    ld (vertical_scroll_for_r23),a
    ld a,(desired_horizontal_scroll_for_r18)
    ld (horizontal_scroll_for_r18),a
    ld hl,(desired_map_offset)
    ld (map_offset),hl
    ld hl,(desired_map_offset+2)
    ld (map_offset+2),hl
    call drawSprites
    call renderMap

    jp Game_Loop_loop


Ship_collided:
    xor a
    ld (shipvelocity),a
    ld (shipvelocity+1),a
    ld (shipvelocity+2),a
    ld (shipvelocity+3),a

Ship_collided_Loop:
    ld a,(shipstate)
    inc a
    ld (shipstate),a
    cp 47
    jp z,Level_Restart

    call applyGravityAndSpeed 
    call calculate_map_offset
    call calculate_ship_sprite_position
    call calculate_ball_sprite_position
    call calculate_bullet_sprite_positions
    call calculate_enemy_bullet_sprite_positions
    call mapAnimationCycle
    call renderExplosions
    
    call SFX_INT

    ld a,(current_game_frame)
    ld b,a
Ship_collided_wait_for_next_frame:
    ld a,(current_game_frame)
    cp b
    jp z,Ship_collided_wait_for_next_frame
;    halt    ;; wait for the interrupt generated after screen is refreshed

    ld a,(desired_vertical_scroll_for_r23)
    ld (vertical_scroll_for_r23),a
    ld a,(desired_horizontal_scroll_for_r18)
    ld (horizontal_scroll_for_r18),a
    ld hl,(desired_map_offset)
    ld (map_offset),hl
    ld hl,(desired_map_offset+2)
    ld (map_offset+2),hl
    call shipExplosionSprites
    call renderMap

    jp Ship_collided_Loop


Time_is_up:
    ld c,50
Time_is_up_Loop:
    push bc

    call mapAnimationCycle

    ;; draw  text
    ld hl,NAMTBL2+32*10
    call SETWRT
    ld hl,Time_is_up_text
	call outi32
    call SFX_INT

    ld a,(current_game_frame)
    ld b,a
Time_is_up_wait_for_next_frame:
    ld a,(current_game_frame)
    cp b
    jp z,Time_is_up_wait_for_next_frame

    call renderMap

    pop bc
    dec c    
    jp nz,Time_is_up_Loop
    jp Level_Restart


;-----------------------------------------------
; updates the current time and fuel and the scoreboard 
updateTimeAndFuel:
    ;; increase time (frames):
    ld a,(current_play_time+3)
    inc a
    ld (current_play_time+3),a
    cp 50
    jr nz,updateTimeAndFuel_done_updating_time
    xor a
    ld (current_play_time+3),a

    ;; check if we need to play sound:
    ld a,(current_play_time)
    cp 9
    jp nz,updateTimeAndFuel_do_not_play_sound
    ld a,(current_play_time+1)
    cp 5
    jp nz,updateTimeAndFuel_do_not_play_sound
    ;; play the timer SFX!
    ld hl,SFX_timer
    call play_SFX
updateTimeAndFuel_do_not_play_sound:
    ;; increase time (Seconds)
    ld a,(current_play_time+2)
    inc a
    ld (current_play_time+2),a
    cp 10
    jp nz,updateTimeAndFuel_done_updating_time
    xor a
    ld (current_play_time+2),a
    ;; decrease time (ten seconds)
    ld a,(current_play_time+1)
    inc a
    ld (current_play_time+1),a
    cp 6
    jp nz,updateTimeAndFuel_done_updating_time
    xor a
    ld (current_play_time+1),a
    ;; decrease time (minutes)
    ld a,(current_play_time)
    inc a
    ld (current_play_time),a
    cp 10
    jp nz,updateTimeAndFuel_done_updating_time
    ld a,10
    ld (current_play_time),a
    ;; time is up!
    pop bc  ;; fake a "ret"
    jp Time_is_up_Loop

updateTimeAndFuel_done_updating_time:
    ;; time (minutes) 
    ld a,(current_play_time)
    add a,'0'
    ld (scoreboard+28),a

    ;; time (10 seconds) 
    ld a,(current_play_time+1)
    add a,'0'
    ld (scoreboard+30),a

    ;; time (seconds) 
    ld a,(current_play_time+2)
    add a,'0'
    ld (scoreboard+31),a

    ;; fuel
    ld c,5
    ld hl,scoreboard+5
    ld a,(current_fuel_left)
updateTimeAndFuel_fuel_loop:    
    cp 2
    jp m,updateTimeAndFuel_less_than_2
    ld b,a
    ld a,PATTERN_FUEL2
    ld (hl),a
    ld a,b
    jr updateTimeAndFuel_next_fuel
updateTimeAndFuel_less_than_2:
    cp 1
    jp m,updateTimeAndFuel_less_than_1
    ld b,a
    ld a,PATTERN_FUEL1
    ld (hl),a
    ld a,b
    jr updateTimeAndFuel_next_fuel
updateTimeAndFuel_less_than_1:
    ld b,a
    ld a,PATTERN_FUEL0
    ld (hl),a
    ld a,b
updateTimeAndFuel_next_fuel:
    sub 2
    inc hl
    dec c
    jr nz,updateTimeAndFuel_fuel_loop

    ret

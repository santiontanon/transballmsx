Game_Loop:
    call clearScreenLeftToRight

    ;; play the game start SFX!
    ld hl,SFX_gamestart
    call play_SFX

Game_Loop_loop:
    ;; check if ship collided:
    ld a,(shipstate)
    cp 0
    jp nz,Ship_collided

    ;; check if level is complete
    ld a,(levelComplete)
    cp 0
    jp nz,Level_complete

;;  this is some debug code (that prints the highscores during the game to see when they got corrupted)
;    ld hl,best_times+3*5
;    ld de,scoreboard
;    ldi
;    ldi
;    ldi
;    ldi
;    ldi


    call checkJoystick     
    call checkThrust
    call checkFireButton
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
    call renderMap
    call changeSprites
    call drawSprites

    call SFX_INT
    halt    ;; wait for the interrupt generated after screen is refreshed

    jp Game_Loop_loop


Ship_collided:
    xor a
    ld (shipvelocity),a
    ld (shipvelocity+1),a
    ld (shipvelocity+2),a
    ld (shipvelocity+3),a
Ship_collided_Loop:
    call applyGravityAndSpeed 
    call calculate_map_offset
    call calculate_ship_sprite_position
    call calculate_ball_sprite_position
    call calculate_bullet_sprite_positions
    call calculate_enemy_bullet_sprite_positions
    call mapAnimationCycle
    call renderExplosions
    call renderMap
    call shipExplosionSprites
    call drawSprites
    ld a,(shipstate)
    inc a
    ld (shipstate),a
    cp 47
    jp z,Level_Restart

    call SFX_INT
    halt    
    jp Ship_collided_Loop


Time_is_up:
    ld c,50
Time_is_up_Loop:
    push bc
    call mapAnimationCycle
    call renderMap

    ;; draw  text
    ld hl,NAMTBL2+32*10
    call SETWRT
    ex de,hl
    ld hl,Time_is_up_text
    ld b,32
    ld c,VDP_DATA
Time_is_up_text_loop:
    outi
    jp nz,Time_is_up_text_loop

    call SFX_INT
    halt    

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

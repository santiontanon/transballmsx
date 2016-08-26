;-----------------------------------------------
; updates the ship and player bullets coordinates according to its velocity and gravity 
applyGravityAndSpeed:
    ;; add gravity:
    ld de,GRAVITY
    ld hl,(shipvelocity)
    add hl,de
    ld bc,MAXSPEED
    call HL_NOT_BIGGER_THAN_BC
    ld bc,MINSPEED
    call HL_NOT_SMALLER_THAN_BC
    ld (shipvelocity),hl
    ;; add velocity (Y):
	call divide_HL_by_16
	ex de,hl
    
    ld hl,(shipposition)
    add hl,de
    ld bc,(current_map_ship_limits)
    push hl
    xor a
    sbc hl,bc
    pop hl
    jp p,applyGravityAndSpeed_y_continue1
    ld h,b      ; collision with top border, clear y velocity
    ld l,c
    ld de,0
    ld (shipvelocity),de
applyGravityAndSpeed_y_continue1:
    ld bc,(current_map_ship_limits+4)
    push hl
    xor a
    sbc hl,bc
    pop hl
    jp m,applyGravityAndSpeed_y_continue2
    ld h,b      ; collision with bottom border, clear y velocity
    ld l,c
    ld de,0
    ld (shipvelocity),de
applyGravityAndSpeed_y_continue2:
    ld (shipposition),hl
    ;; add velocity (X):
    ld hl,(shipvelocity+2)
	call divide_HL_by_16
    ld de,(shipposition+2)
    add hl,de
    ld bc,(current_map_ship_limits+2)
    push hl
    xor a
    sbc hl,bc
    pop hl
    jp p,applyGravityAndSpeed_x_continue1
    ld h,b      ; collision with top border, clear x velocity
    ld l,c
    ld de,0
    ld (shipvelocity+2),de
applyGravityAndSpeed_x_continue1:
    ld bc,(current_map_ship_limits+6)
    push hl
    xor a
    sbc hl,bc
    pop hl
    jp m,applyGravityAndSpeed_x_continue2
    ld h,b      ; collision with bottom border, clear x velocity
    ld l,c
    ld de,0
    ld (shipvelocity+2),de
applyGravityAndSpeed_x_continue2:
    ld (shipposition+2),hl

    ;; apply speed to the player bullets:
    ld a,1  ;; player bullets
    ld (bulletType_tmp),a
    ld c,0
    ld hl,player_bullet_active
    ld ix,player_bullet_positions
    ld de,player_bullet_velocities
    call applyGravityAndSpeed_bullet_loop

    ;; apply speed to the enemy bullets:
    xor a   ;; enemy bullets
    ld (bulletType_tmp),a
    ld c,a
    ld hl,enemy_bullet_active
    ld ix,enemy_bullet_positions
    ld de,enemy_bullet_velocities
    call applyGravityAndSpeed_bullet_loop

    ret


applyGravityAndSpeed_bullet_loop:
    ld a,(hl)
    and a   ;; equivalent to cp 0, but faster
    jp z,applyGravityAndSpeed_next_bullet
    push bc
    push hl
    ; y:
    ld l,(ix)
    ld h,(ix+1)
    ld a,(de)
    ld c,a
    inc de
    ld a,(de)
    ld b,a
    inc de
    add hl,bc
    ld (ix),l
    ld (ix+1),h

    ;; check that the bullet didn't go off the map:
    ld bc,(current_map_ship_limits)
    push hl
    xor a
    sbc hl,bc
    pop hl
    jp m,bullet_off_the_map_y
    ld bc,(current_map_ship_limits+4)
    xor a
    sbc hl,bc
    jp p,bullet_off_the_map_y

    ; x:
    ld l,(ix+2)
    ld h,(ix+3)
    ld a,(de)
    ld c,a
    inc de
    ld a,(de)
    ld b,a
    inc de
    add hl,bc
    ld (ix+2),l
    ld (ix+3),h

    ;; check that the bullet didn't go off the map:
    ld bc,(current_map_ship_limits+2)
    push hl
    xor a
    sbc hl,bc
    pop hl
    jp m,bullet_off_the_map_x
    ld bc,(current_map_ship_limits+6)
    xor a
    sbc hl,bc
    jp p,bullet_off_the_map_x

    ld c,(ix)
    ld b,(ix+1)
    push de
    ld e,(ix+2)
    ld d,(ix+3)

    ld a,(bulletType_tmp)
    and a   ;; equivalent to cp 0, but faster
    jp z,applyGravityAndSpeed_enemy_bullet_collision

applyGravityAndSpeed_player_bullet_collision:
    call checkMapCollision  ;; (bc,de) = (y,x)

    ;; check if any enemy has been hit:
    cp 9
    call z,player_bullet_hit_a_tank    ;; this function preserves the value of 'a', and 'ix'
    cp 8
    call z,player_bullet_hit_an_enemy  ;; this function preserves the value of 'a', and 'ix'
    cp 7
    call z,player_bullet_hit_a_button  ;; this function preserves the value of 'a', and 'ix'

    pop de

    jp applyGravityAndSpeed_common_bullet_collision

applyGravityAndSpeed_enemy_bullet_collision:
    call checkMapCollision  ;; (bc,de) = (y,x)

    pop de

    ; if a<8 && a>=4: collision! jump to bullet_off_the_map_x
    cp 8
    jp p,bullet_no_collision
    cp 4
    jp p,bullet_collided    

applyGravityAndSpeed_common_bullet_collision:
    ; if a>=4: collision! jump to bullet_off_the_map_x
    cp 4
    jp p,bullet_collided

bullet_no_collision:
    pop hl
    pop bc
    jp applyGravityAndSpeed_next_bullet2

bullet_off_the_map_y:
    inc de
    inc de    
bullet_collided:
bullet_off_the_map_x:
    pop hl
    xor a       ;; set the bullet "off"
    ld (hl),a

    pop bc
    jp applyGravityAndSpeed_next_bullet2

applyGravityAndSpeed_next_bullet:
    inc de  ;; next bullet position
    inc de
    inc de
    inc de
applyGravityAndSpeed_next_bullet2:
    inc ix
    inc ix
    inc ix
    inc ix
    inc hl
    inc c
    ld a,c
    cp MAX_PLAYER_BULLETS
    jp nz,applyGravityAndSpeed_bullet_loop
    ret


;-----------------------------------------------
; update the position and velocity of the ball, taking into account:
; gravity, collisions and ship attraction
; in order to avoid multiplications, square roots and divisions, I use Manhattan, rather than
; Euclidean distance between the ship and the ball
ballPhysics:
    ld bc,(ballposition)
    ld de,(ballposition+2)
    ld (ballPositionBeforePhysics),bc
    ld (ballPositionBeforePhysics+2),de
    call checkMapCollision  ;; (bc,de) = (y,x)
    cp 4
    jp m,ballPhysics_ball_no_collision_at_start
    cp 5
    jp z,ballPhysics_temporary_collision
    ; If the ball is in a collision here, something went wrong, so, set its velocity to 0, and make it float up:
    ld bc,0
    ld (ballvelocity),bc
    ld (ballvelocity+2),bc
    ld hl,(ballposition)
    ld bc,-16
    add hl,bc
    ld (ballposition),hl
ballPhysics_temporary_collision:
    ret

ballPhysics_ball_no_collision_at_start:
    ld hl,(shipposition)
    ld bc,(ballposition)
	call sub_HL_BC_divide_HL_by_16
    ex de,hl
    ld hl,(shipposition+2)
    ld bc,(ballposition+2)
	call sub_HL_BC_divide_HL_by_16
	;; now we have (ship.x - ball.x) in hl, and (ship.y - ball.y) in de (in pixels)

    ld a,(ballstate)
    and a   ;; equivalent to cp 0, but faster
    jp nz,ballPhysics_active

ballPhysics_inactive:
    call absHL
    call absDE
    add hl,de
    ld bc,BALL_ACTIVATION_DISTANCE
    xor a
    sbc hl,bc
    jp p,ballPhysics_inactive_ship_too_far

    ;; ball captured!
    ld a,1
    ld (ballstate),a
    call open_close_ball_doors

    ld hl,SFX_ball_capture
    call play_SFX
    
ballPhysics_inactive_ship_too_far:
    ret

ballPhysics_active:
    push hl
    push de
    ; calculate the distance between ship and ball:
    call absHL
    call absDE
    add hl,de

    ; determine the strength of the attractive force of the ship:
    ld bc,32     ;; if ball is closer than 32 pixels, force 0.5
    xor a
    sbc hl,bc
    jp m,ballPhysics_attract0.5
    ld bc,64     ;; if ball is closer than 64 pixels, force 0.25
    xor a
    sbc hl,bc
    jp m,ballPhysics_attract0.25
    ld bc,128     ;; if ball is closer than 128 pixels, force 0.125
    xor a
    sbc hl,bc
    jp m,ballPhysics_attract0.125
    pop de
    pop hl
    jp ballPhysics_gravity ;; otherwise, do not apply any attractive force
ballPhysics_attract0.5:
    ld ix,y_0.5pixel_velocity
    ld iy,x_0.5pixel_velocity
    jp ballPhysics_attractive_force
ballPhysics_attract0.25:
    ld ix,y_0.25pixel_velocity
    ld iy,x_0.25pixel_velocity
    jp ballPhysics_attractive_force
ballPhysics_attract0.125:
    ld ix,y_0.125pixel_velocity
    ld iy,x_0.125pixel_velocity
    jp ballPhysics_attractive_force

ballPhysics_attractive_force:
    pop de
    pop hl
    ; calculate the angle between the ship and the ball
    ld b,l
    ld c,e
    call atan2
    add a,64  ; transform from math standard angles, to transball angles (0 pointing up)
    ; apply the attractive force:
    srl a   ; divide by 8
    srl a
    srl a
    ld c,a
    ld b,0
    add ix,bc
    add ix,bc
    ld d,(ix+1)
    ld e,(ix)
    ld hl,(ballvelocity)
    add hl,de
    ld (ballvelocity),hl
    add iy,bc
    add iy,bc
    ld d,(iy+1)
    ld e,(iy)
    ld hl,(ballvelocity+2)
    add hl,de
    ld (ballvelocity+2),hl

ballPhysics_gravity:
    ;; drag:
    ld a,(balldragTimer)
    and a   ;; equivalent to cp 0, but faster
    call z, ballPhysics_drag
    dec a
    ld (balldragTimer),a
ballPhysics_after_drag:
    ld de,GRAVITY
    ld hl,(ballvelocity)
    add hl,de
    ld bc,MAXSPEED
    call HL_NOT_BIGGER_THAN_BC
    ld bc,MINSPEED
    call HL_NOT_SMALLER_THAN_BC
    ld (ballvelocity),hl
    ;; add velocity (Y):
    ld hl,(ballvelocity)
	call divide_HL_by_16
    ld de,(ballposition)
    add hl,de
    ld bc,(current_map_ship_limits)
    push hl
    xor a
    sbc hl,bc
    pop hl
    jp p,ballPhysics_y_continue1
    ld h,b      ; collision with top border, clear y velocity (and signal that the level is complete!)
    ld l,c
    ld de,0
    ld (ballvelocity),de
    ld a,1
    ld (levelComplete),a
ballPhysics_y_continue1:
    ld bc,(current_map_ship_limits+4)
    push hl
    xor a
    sbc hl,bc
    pop hl
    jp m,ballPhysics_y_continue2
    ld h,b      ; collision with bottom border, clear y velocity
    ld l,c
    ld de,0
    ld (ballvelocity),de
ballPhysics_y_continue2:
    ld (ballposition),hl
    ;; add velocity (X):
    ld hl,(ballvelocity+2)
	call divide_HL_by_16
    ld de,(ballposition+2)
    add hl,de
    ld bc,(current_map_ship_limits+2)
    push hl
    xor a
    sbc hl,bc
    pop hl
    jp p,ballPhysics_x_continue1
    ld h,b      ; collision with left border, clear x velocity
    ld l,c
    ld de,0
    ld (ballvelocity+2),de
ballPhysics_x_continue1:
    ld bc,(current_map_ship_limits+6)
    push hl
    xor a
    sbc hl,bc
    pop hl
    jp m,ballPhysics_x_continue2
    ld h,b      ; collision with right border, clear x velocity
    ld l,c
    ld de,0
    ld (ballvelocity+2),de
ballPhysics_x_continue2:
    ld (ballposition+2),hl

    ;; check for ball collisions with the map:

    ld bc,(ballposition)
    ld de,(ballposition+2)
    call checkMapCollision  ;; (bc,de) = (y,x)  
    cp 4
    jp m,ballPhysics_ball_no_collision_at_the_end

    ;; ball collision! determine which side to bounce:
    ;; N : 1 if there collision in - velocity_y, 0 otherwise
    ;; S = 1 if there collision in + velocity_y, 0 otherwise
    ;; E : 1 if there collision in - velocity_x, 0 otherwise
    ;; W = 1 if there collision in + velocity_x, 0 otherwise
    ;; if N+S == 1, we need to invert y velocity, and add it to position
    ;; if E+W == 1, we need to invert x velocity, and add it to position
    ;; Vertical 1:
    xor a
    ld (ballCollisioncount),a
    ld bc,(ballposition)
    ld de,(ballposition+2)
    ld hl,(ballvelocity)
	call divide_HL_by_16
    add hl,bc
    ld b,h
    ld c,l
    call checkMapCollision  ;; (bc,de) = (y,x)
    cp 4
    jp p,ballPhysics_ball_vertical_collision2
    ld a,1
    ld (ballCollisioncount),a

ballPhysics_ball_vertical_collision2:
    ;; Vertical 2:
    ld hl,0
    ld bc,(ballvelocity)
	call sub_HL_BC_divide_HL_by_16		;; hl = -(ballvelocity)/16
    ld bc,(ballposition)
    add hl,bc
    ld b,h
    ld c,l
    ld de,(ballposition+2)
    call checkMapCollision  ;; (bc,de) = (y,x)
    cp 4
    jp p,ballPhysics_ball_vertical_collision3
    ld a,(ballCollisioncount)
    inc a
    ld (ballCollisioncount),a
ballPhysics_ball_vertical_collision3:
    ld a,(ballCollisioncount)
    cp 1
    jp z,ballPhysics_ball_vertical_collision
    jp ballPhysics_ball_vertical_collision_continue

ballPhysics_ball_vertical_collision:
    ;; invert y speed (and divide by 2), and add it to the ball vertical position:
    ld hl,0
    ld bc,(ballvelocity)
    xor a
    sbc hl,bc   ;; hl = -(ballvelocity)
    sra h   ; divide by 2
    rr l
    ld (ballvelocity),hl

ballPhysics_ball_vertical_collision_continue:
    xor a
    ld (ballCollisioncount),a    
    ;; Horizontal 1:
    ld hl,0
    ld bc,(ballvelocity+2)
   	call sub_HL_BC_divide_HL_by_16	;; hl = -(ballvelocity+2)/16
    ld bc,(ballposition+2)
    add hl,bc
    ld d,h
    ld e,l
    ld bc,(ballposition)
    call checkMapCollision  ;; (bc,de) = (y,x)
    cp 4
    jp p,ballPhysics_ball_horizontal_collision2
    ld a,1
    ld (ballCollisioncount),a

ballPhysics_ball_horizontal_collision2:
    ;; Horizontal 2:
    ld bc,(ballposition)
    ld de,(ballposition+2)
    ld hl,(ballvelocity+2)
	call divide_HL_by_16
    add hl,de
    ld d,h
    ld e,l
    call checkMapCollision  ;; (bc,de) = (y,x)
    cp 4
    jp p,ballPhysics_ball_horizontal_collision3
    ld a,(ballCollisioncount)
    inc a
    ld (ballCollisioncount),a
ballPhysics_ball_horizontal_collision3:
    ld a,(ballCollisioncount)
    cp 1
    jp z,ballPhysics_ball_horizontal_collision
    jp ballPhysics_ball_horizontal_collision_continue

ballPhysics_ball_horizontal_collision:
    ;; invert x speed, and add it to the ball horizontal position:
    ld hl,0
    ld bc,(ballvelocity+2)
    xor a
    sbc hl,bc   ;; hl = -(ballvelocitx)
    sra h   ; divide by 2:
    rr l
    ld (ballvelocity+2),hl

ballPhysics_ball_horizontal_collision_continue:
    ld de,(ballPositionBeforePhysics)
    ld (ballposition),de
    ld de,(ballPositionBeforePhysics+2)
    ld (ballposition+2),de
ballPhysics_ball_no_collision_at_the_end:
    ret


ballPhysics_drag:
    ld hl,(ballvelocity)
    ld bc,0
    sbc hl,bc
    jp p,ballPhysics_drag_positive_y
ballPhysics_drag_negative_y:
    inc hl
    ld (ballvelocity),hl
    jp ballPhysics_drag_x

ballPhysics_drag_positive_y:
    dec hl
    ld (ballvelocity),hl

ballPhysics_drag_x:
    ld hl,(ballvelocity+2)
    sbc hl,bc
    jp p,ballPhysics_drag_positive_x
ballPhysics_drag_negative_x:
    inc hl
    ld (ballvelocity+2),hl

    ld a,BALLDRAG
    ld (balldragTimer),a
    ret

ballPhysics_drag_positive_x:
    dec hl
    ld (ballvelocity+2),hl

    ld a,BALLDRAG
    ld (balldragTimer),a
    ret

;-----------------------------------------------
; Checks if the ship has collided with the map
checkForShipToMapCollision:
    ld bc,(shipposition)
    ld de,(shipposition+2)
    call checkMapCollision
    ; if a>=4: collision! jump to bullet_off_the_map_x
    cp 4
    jp p,checkForShipToMapCollision_collision
    cp 1
    jp z,checkForShipToMapCollision_refuel
    ret

checkForShipToMapCollision_refuel:

    ; play refuel SFX:
    ld hl,SFX_refuel
    call play_SFX

    ; increase fuel:
    ld a,(current_fuel_left+1)
    add a,8
    ld (current_fuel_left+1),a
    cp FUEL_UNIT
    jp m,checkForShipToMapCollision_refuel_do_not_increase_major_fuel_unit
    sub FUEL_UNIT
    ld (current_fuel_left+1),a
    ld a,(current_fuel_left)
    inc a
    ld (current_fuel_left),a
    cp 11   ;; max fuel+1
    jp nz,checkForShipToMapCollision_refuel_do_not_increase_major_fuel_unit
    ld a,10 ;; max fuel
    ld (current_fuel_left),a
checkForShipToMapCollision_refuel_do_not_increase_major_fuel_unit:
    ret
checkForShipToMapCollision_collision:
    ld a,1
    ld (shipstate),a

    ld hl,SFX_explosion
    call play_SFX

    ret


;-----------------------------------------------
; Checks the map content underneath coordinates bc,de, and returns (in a) the collision type of the map tile
; it is over.
checkMapCollision:

    ;; check for bullet collision
    ; bc = y
    ; bc /= 128
    ; divide by 128: (multiply by 2, and then divide by 256)
    sla c
    rl b
    ld h,b
    ;; increment by 1 to get the center of the ship
    inc h
    ld a,(current_map_dimensions+1)
    push de
    ld e,a
    call Mult_H_by_E
    pop de

    ; bc = hl
    ld b,h
    ld c,l
    ; hl = map start
    ld hl,currentMap
    ; hl += bc
    add hl,bc
    ; bc = x
    ld b,d
    ld c,e
    ; bc /= 128
    ; divide by 128: (multiply by 2, and then divide by 256)
    sla c
    rl b
    ld c,b
    ld b,0

    ;; increment by 1 to get the center of the ship
    inc bc
    ; hl += bc
    add hl,bc
    ; a = (hl)
    ld a,(hl)
    ld hl,patterncollisiondata
    ld c,a
    ld b,0
    add hl,bc
    ld a,(hl)

    ret


;-----------------------------------------------
; velocities of objects (0.125 pixel per frame)
y_0.125pixel_velocity:
    dw -2, -2, -2, -2, -1, -1, -1, 0
x_0.125pixel_velocity:
    dw 0, 0, 1, 1, 1, 2, 2, 2
    dw 2, 2, 2, 2, 1, 1, 1, 0, 0, 0, -1, -1, -1, -2, -2, -2
    dw -2, -2, -2, -2, -1, -1, -1, 0

;-----------------------------------------------
; velocities of objects (0.25 pixel per frame)
y_0.25pixel_velocity:
    dw -4, -4, -4, -3, -3, -2, -2, -1
x_0.25pixel_velocity:
    dw 0, 1, 2, 2, 3, 3, 4, 4
    dw 4, 4, 4, 3, 3, 2, 2, 1, 0, -1, -2, -2, -3, -3, -4, -4
    dw -4, -4, -4, -3, -3, -2, -2, -1

;-----------------------------------------------
; velocities of objects (0.5 pixel per frame)
y_0.5pixel_velocity:
    dw -8, -8, -7, -7, -6, -4, -3, -2
x_0.5pixel_velocity:
    dw 0, 2, 3, 4, 6, 7, 7, 8
    dw 8, 8, 7, 7, 6, 4, 3, 2, 0, -2, -3, -4, -6, -7, -7, -8
    dw -8, -8, -7, -7, -6, -4, -3, -2

;-----------------------------------------------
; velocities of objects (1.0 pixel per frame)
y_1pixel_velocity:
    dw -16, -16, -15, -13, -11, -9, -6, -3
x_1pixel_velocity:
    dw 0, 3, 6, 9, 11, 13, 15, 16
    dw 16, 16, 15, 13, 11, 9, 6, 3, 0, -3, -6, -9, -11, -13, -15, -16
    dw -16, -16, -15, -13, -11, -9, -6, -3

;-----------------------------------------------
; velocities of objects (4.0 pixel per frame)
y_4pixel_velocity:
    dw -64, -63, -59, -53, -45, -36, -24, -12
x_4pixel_velocity:
    dw 0, 12, 24, 36, 45, 53, 59, 63
    dw 64, 63, 59, 53, 45, 36, 24, 12, 0, -12, -24, -36, -45, -53, -59, -63
    dw -64, -63, -59, -53, -45, -36, -24, -12

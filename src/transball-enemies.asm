;-----------------------------------------------
; Executes one update cycle of each enemy in the map
enemyUpdateCycle:
    ld a,(currentNEnemies)
    ld b,a
    ld ix,currentEnemies

enemyUpdateCycle_loop:
    ld a,b
    and a   ;; equivalent to cp 0, but faster
    ret z

    push bc
    ;; each enemy is 11 bytes:
    ;; type (1 byte)
    ;; map pointer (2 bytes)
    ;; enemy type pointer (2 bytes)
    ;; y (2 bytes)
    ;; x (2 bytes)
    ;; state (1 byte)
    ;; health (1 byte)
    ld a,(ix+9)     ;; state
    and a   ;; equivalent to cp 0, but faster
    jp nz,enemyUpdateCycle_cannotFire

    ld a,(ix) ; enemy type
    dec a
    jp z,enemyUpdateCycle_CannonUp
    dec a
    jp z,enemyUpdateCycle_CannonRight
    dec a
    jp z,enemyUpdateCycle_CannonDown
    dec a
    jp z,enemyUpdateCycle_CannonLeft
    dec a
    jp z,enemyUpdateCycle_DirectionalCannon
    dec a
    jp z,enemyUpdateCycle_DirectionalCannon
    dec a
    jp z,enemyUpdateCycle_DirectionalCannon
    dec a
    jp z,enemyUpdateCycle_DirectionalCannon

enemyUpdateCycle_nextEnemy:
    pop bc
    ld de,11
    add ix,de
    dec b
    jr enemyUpdateCycle_loop


enemyUpdateCycle_cannotFire:
    dec a
    ld (ix+9),a
    jp enemyUpdateCycle_nextEnemy


; ------------------------------------------------


enemyUpdateCycle_CannonUp:
    ld l,(ix+5)    ;; enemy y
    ld h,(ix+6)    ;; enemy y
    ld bc,(shipposition)  ;; player y
    xor a
    sbc hl,bc
    jp m,enemyUpdateCycle_nextEnemy

    ;; check if player is in the proper x range (enemy x-32 -> enemy + 16):
    ld l,(ix+7)    ;; enemy x
    ld h,(ix+8)    ;; enemy x
    ld bc,16*16
    xor a
    sbc hl,bc
    ld bc,(shipposition+2)  ;; player x
    sbc hl,bc
    jp p,enemyUpdateCycle_nextEnemy

    ld l,(ix+7)    ;; enemy x
    ld h,(ix+8)    ;; enemy x
    ld bc,16*16
    add hl,bc
    ld bc,(shipposition+2)  ;; player x
    sbc hl,bc
    jp m,enemyUpdateCycle_nextEnemy
    jp enemyUpdateCycle_Cannon_fireBullet


; ------------------------------------------------


enemyUpdateCycle_CannonRight:
    ld l,(ix+7)    ;; enemy x
    ld h,(ix+8)    ;; enemy x
    ld bc,(shipposition+2)  ;; player x
    xor a
    sbc hl,bc
    jp p,enemyUpdateCycle_nextEnemy

    ;; check if player is in the proper y range (enemy y -16 -> enemy + 16):
    ld l,(ix+5)    ;; enemy y
    ld h,(ix+6)    ;; enemy y
    ld bc,16*16
    xor a
    sbc hl,bc
    ld bc,(shipposition)  ;; player y
    xor a
    sbc hl,bc
    jp p,enemyUpdateCycle_nextEnemy

    ld l,(ix+5)    ;; enemy y
    ld h,(ix+6)    ;; enemy y
    ld bc,16*16
    add hl,bc
    ld bc,(shipposition)  ;; player y
    xor a
    sbc hl,bc
    jp m,enemyUpdateCycle_nextEnemy
    jp enemyUpdateCycle_Cannon_fireBullet


; ------------------------------------------------


enemyUpdateCycle_CannonDown:
    ld l,(ix+5)    ;; enemy y
    ld h,(ix+6)    ;; enemy y
    ld bc,(shipposition)  ;; player y
    xor a
    sbc hl,bc
    jp p,enemyUpdateCycle_nextEnemy

    ;; check if player is in the proper x range (enemy x-32 -> enemy + 16):
    ld l,(ix+7)    ;; enemy x
    ld h,(ix+8)    ;; enemy x
    ld bc,16*16
    xor a
    sbc hl,bc
    ld bc,(shipposition+2)  ;; player x
    sbc hl,bc
    jp p,enemyUpdateCycle_nextEnemy

    ld l,(ix+7)    ;; enemy x
    ld h,(ix+8)    ;; enemy x
    ld bc,16*16
    add hl,bc
    ld bc,(shipposition+2)  ;; player x
    sbc hl,bc
    jp m,enemyUpdateCycle_nextEnemy
    jp enemyUpdateCycle_Cannon_fireBullet


; ------------------------------------------------


enemyUpdateCycle_CannonLeft:
    ld l,(ix+7)    ;; enemy x
    ld h,(ix+8)    ;; enemy x
    ld bc,(shipposition+2)  ;; player x
    xor a
    sbc hl,bc
    jp m,enemyUpdateCycle_nextEnemy

    ;; check if player is in the proper y range (enemy y - 16 -> enemy + 16):
    ld l,(ix+5)    ;; enemy y
    ld h,(ix+6)    ;; enemy y
    ld bc,16*16
    xor a
    sbc hl,bc
    ld bc,(shipposition)  ;; player y
    xor a
    sbc hl,bc
    jp p,enemyUpdateCycle_nextEnemy

    ld l,(ix+5)    ;; enemy y
    ld h,(ix+6)    ;; enemy y
    ld bc,16*16
    add hl,bc
    ld bc,(shipposition)  ;; player y
    xor a
    sbc hl,bc
    jp m,enemyUpdateCycle_nextEnemy
    jp enemyUpdateCycle_Cannon_fireBullet


; ------------------------------------------------


enemyUpdateCycle_Cannon_fireBullet:
    ;; fire!
    ;; check if there is any bullet slot available:
    ld c,0
    ld hl,enemy_bullet_active
enemyUpdateCycle_Cannon_checking_for_free_slot:
    ld a,(hl)
    and a   ;; equivalent to cp 0, but faster
    jp z,enemyUpdateCycle_Cannon_fireBullet_slotFound
    inc hl
    inc c
    ld a,c
    cp MAX_ENEMY_BULLETS
    jr nz,enemyUpdateCycle_Cannon_checking_for_free_slot
    jp enemyUpdateCycle_nextEnemy

enemyUpdateCycle_Cannon_fireBullet_slotFound:
    ld (hl),1   ;; bullet is fired
    ld hl,enemy_bullet_positions
    sla c   ;; multiply c by 4 (to get the offset of the bullet coordinates)
    sla c 
    ld b,0
    add hl,bc
    ex de,hl
    push ix
    pop hl
    push bc
    ld bc,5
    add hl,bc   ;; get a pointer to the enemy position  
    ldi 
    ldi         ;; copied the y position
    ld c,(hl)
    inc hl
    ld b,(hl)
    inc hl
    ld h,b
    ld l,c
    ex de,hl
    ld (hl),e
    inc hl
    ld (hl),d

    ld c,(ix+3) ;; get the enemy definition into iy
    ld b,(ix+4)
    push bc
    pop iy

    pop bc

    ld hl,enemy_bullet_velocities
    add hl,bc

    ;; set the bullet speed:     
    ld a,(iy+6)  
    ld (hl),a    
    inc hl
    ld a,(iy+7)  
    ld (hl),a
    inc hl
    ld a,(iy+8)  
    ld (hl),a
    inc hl
    ld a,(iy+9)  
    ld (hl),a
    inc hl

    ld hl,SFX_enemy_bullet
    call play_SFX

    ld a,CANON_COOLDOWN_PERIOD    ;; cooldown period
    ld (ix+9),a

    jp enemyUpdateCycle_nextEnemy    

; ------------------------------------------------


enemyUpdateCycle_DirectionalCannon:
    ;; Check if player is inside of the trigger box:
    ld l,(ix+3) ;; get the enemy definition into hl
    ld h,(ix+4)
    ld c,6
    ld b,0
    add hl,bc

    ld b,(hl)   ;; get -dy to bc (the minY of the bounding box the player has to be, to activate the enemy)
    inc hl
    ld c,0
    sra b       ;; divide by 2 (so that it's actually multiplied by 128)
    rr c
    ex de,hl
    ld l,(ix+5)    ;; enemy y
    ld h,(ix+6)    ;; enemy y
    push hl
    add hl,bc      ;; hl = (enemy.y) + -dy 
    ld bc,(shipposition)  ;; player y
    xor a
    sbc hl,bc
    pop hl
    jp p,enemyUpdateCycle_nextEnemy

    ex de,hl    ;; get +dy to bc (the maxY of the bounding box the player has to be, to activate the enemy)
    ld b,(hl)
    inc hl
    ld c,0
    sra b       ;; divide by 2 (so that it's actually multiplied by 128)
    rr c
    ex de,hl
    add hl,bc      ;; hl = (enemy.y)/16 + dy 
    ld bc,(shipposition)  ;; player y
    sbc hl,bc
    jp m,enemyUpdateCycle_nextEnemy

    ex de,hl
    ld b,(hl)   ;; get -dx to bc (the minX of the bounding box the player has to be, to activate the enemy)
    inc hl
    ld c,0
    sra b       ;; divide by 2 (so that it's actually multiplied by 128)
    rr c
    ex de,hl
    ld l,(ix+7)    ;; enemy x
    ld h,(ix+8)    ;; enemy x
    push hl
    add hl,bc      ;; hl = (enemy.x) + -dx 
    ld bc,(shipposition+2)  ;; player x
    xor a
    sbc hl,bc
    pop hl
    jp p,enemyUpdateCycle_nextEnemy

    ex de,hl    ;; get +dx to bc (the maxX of the bounding box the player has to be, to activate the enemy)
    ld b,(hl)
    inc hl
    ld c,0
    sra b       ;; divide by 2 (so that it's actually multiplied by 128)
    rr c
    ex de,hl
    add hl,bc      ;; hl = (enemy.x)/16 + dx 
    ld bc,(shipposition+2)  ;; player x
    sbc hl,bc
    jp m,enemyUpdateCycle_nextEnemy    

    ;; fire!
    ;; check if there is any bullet slot available:
    ld c,0
    ld hl,enemy_bullet_active
enemyUpdateCycle_DirectionalCannon_checking_for_free_slot:
    ld a,(hl)
    and a   ;; equivalent to cp 0, but faster
    jr z,enemyUpdateCycle_DirectionalCannon_fireBullet_foundSlot
    inc hl
    inc c
    ld a,c
    cp MAX_ENEMY_BULLETS
    jr nz,enemyUpdateCycle_DirectionalCannon_checking_for_free_slot
    jp enemyUpdateCycle_nextEnemy

enemyUpdateCycle_DirectionalCannon_fireBullet_foundSlot:
    ld (hl),1   ;; bullet is fired
    ld hl,enemy_bullet_positions
    sla c   ;; multiply c by 4 (to get the offset of the bullet coordinates)
    sla c 
    ld b,0
    add hl,bc
    ex de,hl
    push ix
    pop hl
    push bc     ;; save the enemy offset
    ld bc,5
    add hl,bc   ;; get a pointer to the enemy position  
    ld c,(hl)
    inc hl
    ld b,(hl)
    inc hl
    push hl
    push de
    ld h,b
    ld l,c
    ex de,hl
    ld (hl),e
    inc hl
    ld (hl),d   ;; copied the y position - 24
    pop de
    pop hl
    inc de
    inc de
    ldi 
    ldi         ;; copied the x position
    pop bc

    ld hl,enemy_bullet_velocities
    add hl,bc    ;; hl points to the velocities we need to set
    push hl

    ; calculate the angle between the ship and the enemy
    ld hl,(shipposition)
    ld c,(ix+5)    ;; enemy y
    ld b,(ix+6)    ;; enemy y
    xor a
    sbc hl,bc
    sra h   ; divide by 16:
    rr l
    sra h
    rr l
    sra h
    rr l
    sra h
    rr l
    ex de,hl
    ld hl,(shipposition+2)
    ld c,(ix+7)    ;; enemy x
    ld b,(ix+8)    ;; enemy x
    xor a
    sbc hl,bc   
    sra h   ; divide by 16:
    rr l
    sra h
    rr l
    sra h
    rr l
    sra h
    rr l    ;; now we have (ship.x - enemy.x) in hl, and (ship.y - enemy.y) in de (in pixels)

    ld b,l
    ld c,e
    call atan2
    add a,64  ; transform from math standard angles, to transball angles (0 pointing up)
    srl a   ; divide by 8
    srl a
    srl a
    ld c,a
    ld b,0

    pop hl

    ld iy,y_1pixel_velocity
    add iy,bc
    add iy,bc
    ld a,(iy)
    ld (hl),a
    inc hl
    ld a,(iy+1)
    ld (hl),a
    inc hl
    ld iy,x_1pixel_velocity
    add iy,bc
    add iy,bc
    ld a,(iy)
    ld (hl),a
    inc hl
    ld a,(iy+1)
    ld (hl),a
    inc hl

    ;; play the enemy bullet SFX!
    ld hl,SFX_enemy_bullet
    call play_SFX

    ld a,CANON_COOLDOWN_PERIOD    ;; cooldown period
    ld (ix+9),a

    jp enemyUpdateCycle_nextEnemy


;-----------------------------------------------
; Update cycle for each tank
tankUpdateCycle:
    ld a,(currentNTanks)
    ld b,a
    ld ix,currentTanks

tankUpdateCycle_loop:
    ld a,b
    and a   ;; equivalent to cp 0, but faster
    ret z

    push bc
    ;; each tank is 8 bytes:
    ;;      health (1 byte)
    ;;      fire state (1 byte)
    ;;      movement state (1 byte)
    ;;      y (1 byte)   (in map pattern coordinates)
    ;;      x (1 byte)   (in map pattern coordinates)
    ;;      map pointer (2 bytes)
    ;;      turret angle
    
    ld a,(ix)   ;; tank is dead!
    and a   ;; equivalent to cp 0, but faster
    jp z,tankUpdateCycle_nextTank

    ;; check movement state:
    ld a,(ix+2)
    and a   ;; equivalent to cp 0, but faster
    jp p,tankUpdateCycle_moving_right
    jp tankUpdateCycle_moving_left
tankUpdateCycle_done_moving:

    ;; check fire state:
    ld a,(ix+1)
    and a   ;; equivalent to cp 0, but faster
    jp z,tankUpdateCycle_updateCanon
    dec a
    ld (ix+1),a

tankUpdateCycle_nextTank:
    pop bc
    ld de,8
    add ix,de
    dec b
    jr tankUpdateCycle_loop


tankUpdateCycle_moving_right:
    dec a
    jp z,tankUpdateCycle_move_right
    ld (ix+2),a
    jp tankUpdateCycle_done_moving


tankUpdateCycle_move_right:    
    ld l,(ix+5)
    ld h,(ix+6)

    ;; check if the tank can go to the right:
    push hl
    ld b,0
    ld c,4
    add hl,bc
    ld a,(current_map_dimensions+1)
    ld c,a
    add hl,bc
    ld a,(hl)
    pop hl
    and a   ;; equivalent to cp 0, but faster
    jp nz,tankUpdateCycle_moving_right_obstacle

    ;; erase the left-most bottom tile:
    xor a
    add hl,bc
    ld (hl),a
    sbc hl,bc

    ;; move the tank:
    ld a,(ix+4)
    inc a
    ld (ix+4),a
    inc hl
    ld (ix+5),l
    ld (ix+6),h
    call tankUpdateCycle_draw_tank

    ld (ix+2),TANK_MOVE_SPEED
    jp tankUpdateCycle_done_moving    


tankUpdateCycle_moving_right_obstacle:
    ld (ix+2),-TANK_MOVE_SPEED  ;; switch to moving to the left
    jp tankUpdateCycle_done_moving    


tankUpdateCycle_moving_left:
    inc a
    jp z,tankUpdateCycle_move_left
    ld (ix+2),a
    jp tankUpdateCycle_done_moving


tankUpdateCycle_move_left:
    ld l,(ix+5)
    ld h,(ix+6)

    ;; check if the tank can go to the left:
    push hl
    dec hl
    ld b,0
    ld a,(current_map_dimensions+1)
    ld c,a
    add hl,bc
    ld a,(hl)
    pop hl
    and a   ;; equivalent to cp 0, but faster
    jp nz,tankUpdateCycle_moving_left_obstacle

    ;; erase the two right-most tiles:
    push hl
    ld c,3
    add hl,bc
    ld a,(current_map_dimensions+1)
    ld c,a
    add hl,bc
    xor a
    ld (hl),a
    pop hl

    ;; move the tank:
    ld a,(ix+4)
    dec a
    ld (ix+4),a
    dec hl
    ld (ix+5),l
    ld (ix+6),h    
    call tankUpdateCycle_draw_tank

    ld (ix+2),-TANK_MOVE_SPEED
    jp tankUpdateCycle_done_moving    


tankUpdateCycle_moving_left_obstacle:
    ld (ix+2),TANK_MOVE_SPEED  ;; switch to moving to the right
    jp tankUpdateCycle_done_moving    


tankUpdateCycle_draw_tank:
    ld a,(ix+7) ;; turret state
    and a   ;; equivalent to cp 0, but faster
    jp z,tankUpdateCycle_draw_tank_turretLeft
    cp 1
    jp z,tankUpdateCycle_draw_tank_turretLeftUp
    cp 2
    jp z,tankUpdateCycle_draw_tank_turretRightUp

tankUpdateCycle_draw_tank_turretRight:
    ld (hl),0
    inc hl
    ld (hl),1
    inc hl
    ld (hl),3
    inc hl
    ld (hl),0
    jp tankUpdateCycle_draw_tank_turretDrawn   

tankUpdateCycle_draw_tank_turretLeft:
    ld (hl),0
    inc hl
    ld (hl),4
    inc hl
    ld (hl),5
    inc hl
    ld (hl),0
    jp tankUpdateCycle_draw_tank_turretDrawn

tankUpdateCycle_draw_tank_turretLeftUp:
    ld (hl),0
    inc hl
    ld (hl),20
    inc hl
    ld (hl),5
    inc hl
    ld (hl),0
    jp tankUpdateCycle_draw_tank_turretDrawn

tankUpdateCycle_draw_tank_turretRightUp:
    ld (hl),0
    inc hl
    ld (hl),1
    inc hl
    ld (hl),2
    inc hl
    ld (hl),0
    jp tankUpdateCycle_draw_tank_turretDrawn


tankUpdateCycle_draw_tank_turretDrawn:
    ld b,0
    ld a,(current_map_dimensions+1)
    ld c,a
    add hl,bc
    xor a
    ld c,3
    sbc hl,bc
    ld (hl),16
    inc hl
    ld (hl),17
    inc hl
    ld (hl),18
    inc hl
    ld (hl),19
    ret


tankUpdateCycle_updateCanon:
    ;; Check if player is inside of the trigger box:
    ld bc,-20*128
    ld h,(ix+3) ;; tank y
    ld l,0
    sra h   ;; divide by 2 (so that it's actually multiplied by 128)
    rr l
    add hl,bc      ;; hl = (tank.y) + -dy 
    ld bc,(shipposition)  ;; player y
    xor a
    sbc hl,bc
    jp p,tankUpdateCycle_nextTank

    ld bc,2*128
    ld h,(ix+3) ;; tank y
    ld l,0
    sra h   ;; divide by 2 (so that it's actually multiplied by 128)
    rr l
    add hl,bc      ;; hl = (tank.y)/16 + dy 
    ld bc,(shipposition)  ;; player y
    sbc hl,bc
    jp m,tankUpdateCycle_nextTank

    ld bc,-10*128
    ld h,(ix+4) ;; tank x
    ld l,0
    sra h   ;; divide by 2 (so that it's actually multiplied by 128)
    rr l
    add hl,bc      ;; hl = (tank.x) + -dx 
    ld bc,(shipposition+2)  ;; player x
    xor a
    sbc hl,bc
    jp p,tankUpdateCycle_nextTank

    ld bc,14*128
    ld h,(ix+4) ;; tank x
    ld l,0
    sra h   ;; divide by 2 (so that it's actually multiplied by 128)
    rr l
    add hl,bc      ;; hl = (tank.x)/16 + dx
    ld bc,(shipposition+2)  ;; player x
    sbc hl,bc
    jp m,tankUpdateCycle_nextTank

    ;; fire bullet:
    ;; check if there is any bullet slot available:
    ld c,0
    ld hl,enemy_bullet_active
tankUpdateCycle_updateCanon_checking_for_free_slot:
    ld a,(hl)
    and a   ;; equivalent to cp 0, but faster
    jr z,tankUpdateCycle_updateCanon_fireBullet
    inc hl
    inc c
    ld a,c
    cp MAX_ENEMY_BULLETS
    jr nz,tankUpdateCycle_updateCanon_checking_for_free_slot
    jp tankUpdateCycle_nextTank

tankUpdateCycle_updateCanon_fireBullet:
    ld (hl),1   ;; bullet is fired
    ld hl,enemy_bullet_positions
    sla c   ;; multiply c by 4 (to get the offset of the bullet coordinates)
    sla c 
    ld b,0
    add hl,bc
    push bc

    ld b,(ix+3) ;; tank y
    dec b   ;; decrement in 1, to make the bullet start above the tank
    ld c,0
    sra b   ;; divide by 2 (so that it's actually multiplied by 128)
    rr c
    ld (hl),c
    inc hl
    ld (hl),b
    inc hl
    ld b,(ix+4) ;; tank x
    inc b   ;; make the bullet start over the turret
    ld c,0
    sra b   ;; divide by 2 (so that it's actually multiplied by 128)
    rr c
    ld (hl),c
    inc hl
    ld (hl),b
    inc hl
    pop bc

    ;; calculate bullet velocity:
    ld hl,enemy_bullet_velocities
    add hl,bc    ;; hl points to the velocities we need to set
    push hl

    ; calculate the angle between the ship and the tank
    ld hl,(shipposition)
    ld b,(ix+3) ;; tank y
    dec b   ;; decrement, to make the bullet start above the tank
    ld c,0
    sra b   ;; divide by 2 (so that it's actually multiplied by 128)
    rr c

    xor a
    sbc hl,bc
    sra h   ; divide by 16:
    rr l
    sra h
    rr l
    sra h
    rr l
    sra h
    rr l
    ex de,hl
    ld hl,(shipposition+2)
    ld b,(ix+4) ;; tank x
    inc b   ;; make the bullet start over the turret
    ld c,0
    sra b   ;; divide by 2 (so that it's actually multiplied by 128)
    rr c

    xor a
    sbc hl,bc   
    sra h   ; divide by 16:
    rr l
    sra h
    rr l
    sra h
    rr l
    sra h
    rr l    ;; now we have (ship.x - enemy.x) in hl, and (ship.y - enemy.y) in de (in pixels)

    ld b,l
    ld c,e
    call atan2
    add a,64  ; transform from math standard angles, to transball angles (0 pointing up)
    cp 3*16
    jp c,tankUpdateCycle_updateCanon_fireBullet_turrentAngleRightUp
    cp 8*16
    jp c,tankUpdateCycle_updateCanon_fireBullet_turrentAngleRight
    cp 13*16
    jp c,tankUpdateCycle_updateCanon_fireBullet_turrentAngleLeft
    jp tankUpdateCycle_updateCanon_fireBullet_turrentAngleLeftUp

tankUpdateCycle_updateCanon_fireBullet_turrentAngleLeft:
    ld (ix+7),0
    jp tankUpdateCycle_updateCanon_fireBullet_turrentAngleDone
tankUpdateCycle_updateCanon_fireBullet_turrentAngleLeftUp:
    ld (ix+7),1
    jp tankUpdateCycle_updateCanon_fireBullet_turrentAngleDone
tankUpdateCycle_updateCanon_fireBullet_turrentAngleRightUp:
    ld (ix+7),2
    jp tankUpdateCycle_updateCanon_fireBullet_turrentAngleDone
tankUpdateCycle_updateCanon_fireBullet_turrentAngleRight:
    ld (ix+7),3

tankUpdateCycle_updateCanon_fireBullet_turrentAngleDone:
    srl a   ; divide by 8
    srl a
    srl a
    ld c,a
    ld b,0

    pop hl

    ld iy,y_1pixel_velocity
    add iy,bc
    add iy,bc
    ld a,(iy)
    ld (hl),a
    inc hl
    ld a,(iy+1)
    ld (hl),a
    inc hl
    ld iy,x_1pixel_velocity
    add iy,bc
    add iy,bc
    ld a,(iy)
    ;ld a,0
    ld (hl),a
    inc hl
    ld a,(iy+1)
;    ld a,0
    ld (hl),a
    inc hl

    ld hl,SFX_enemy_bullet
    call play_SFX

    ld a,TANK_COOLDOWN_PERIOD    ;; cooldown period
    ld (ix+1),a

    ld l,(ix+5)
    ld h,(ix+6)
    call tankUpdateCycle_draw_tank  ;; redraw tank, since the angle of the turret might have changed

    jp tankUpdateCycle_nextTank


;-----------------------------------------------
; check if any of the enemy bullets has hit the player ship
checkForShipToEnemyBulletCollision:
    ld c,0
    ld hl,enemy_bullet_active
    ld ix,enemy_bullet_sprite_attributes
checkForShipToEnemyBulletCollision_loop:
    ld a,(hl)
    and a   ;; equivalent to cp 0, but faster
    jr z,checkForShipToEnemyBulletCollision_next_bullet

    ;; check collision of bullet with ship:
    ld a,(ship_spriteattributes)
    sub ENEMY_BULLET_COLLISION_SIZE
    ld b,(ix)
    cp b
    jp p,checkForShipToEnemyBulletCollision_next_bullet

    ld a,(ship_spriteattributes)
    add a,ENEMY_BULLET_COLLISION_SIZE
    ld b,(ix)
    cp b
    jp m,checkForShipToEnemyBulletCollision_next_bullet

    ld a,(ship_spriteattributes+1)
    sub ENEMY_BULLET_COLLISION_SIZE
    ld b,(ix+1)
    cp b
    jp p,checkForShipToEnemyBulletCollision_next_bullet

    ld a,(ship_spriteattributes+1)
    add a,ENEMY_BULLET_COLLISION_SIZE
    ld b,(ix+1)
    cp b
    jp m,checkForShipToEnemyBulletCollision_next_bullet

    ;; collision!
    ld a,1
    ld (shipstate),a

    ld hl,SFX_explosion
    call play_SFX

checkForShipToEnemyBulletCollision_next_bullet:
    inc ix
    inc ix
    inc ix
    inc ix
    inc hl
    inc c
    ld a,c
    cp MAX_ENEMY_BULLETS
    jp nz,checkForShipToEnemyBulletCollision_loop
    ret


;-----------------------------------------------
; called when one of the player bullets hits an enemy
; the bullet coordinates (2bytes each) are in (ix,ix+2)
player_bullet_hit_an_enemy:
    push af     ;; we preserve 'a'

    ;; find which of the enemies it is:
    ld a,(currentNEnemies)
    ld b,a
    ld iy,currentEnemies

player_bullet_hit_an_enemy_loop:
    ld a,b
    and a   ;; equivalent to cp 0, but faster
    jp z,player_bullet_hit_an_enemy_done

    push bc
    ;; each enemy is 11 bytes:
    ;; type (1 byte)
    ;; map pointer (2 bytes)
    ;; enemy type pointer (2 bytes)
    ;; y (2 bytes)
    ;; x (2 bytes)
    ;; state (1 byte)
    ;; health (1 byte)
    
    ;; find an enemy whose (x,y) is not more than 8*16 away in x and y from the bullet:
    ld l,(iy+5)
    ld h,(iy+6)     ;; hl = enemy y
    ld c,(ix)
    ld b,(ix+1)     ;; bc = bullet y
    xor a
    sbc hl,bc       ;; hl = (enemy.y - bullet.y)
    ;; check the difference is in between -8*16 and 8*16
    ld d,l
    ld e,h
    ld bc,12*16
    sbc hl,bc
    jp p,player_bullet_hit_an_enemy_nextEnemy
    ld l,d
    ld h,e
    ld bc,-12*16
    sbc hl,bc
    jp m,player_bullet_hit_an_enemy_nextEnemy
    ld l,(iy+7)
    ld h,(iy+8)     ;; hl = enemy x
    ld c,(ix+2)
    ld b,(ix+3)     ;; bc = bullet x
    xor a
    sbc hl,bc       ;; hl = (enemy.x - bullet.x)
    ;; check the difference is in between -8*16 and 8*16
    ld d,l
    ld e,h
    ld bc,12*16
    sbc hl,bc
    jp p,player_bullet_hit_an_enemy_nextEnemy
    ld l,d
    ld h,e
    ld bc,-12*16
    sbc hl,bc
    jp m,player_bullet_hit_an_enemy_nextEnemy

    ;; we found our enemy!
    call enemy_hit
    pop bc
    jp player_bullet_hit_an_enemy_done

player_bullet_hit_an_enemy_nextEnemy:
    pop bc
    ld de,11
    add iy,de
    dec b
    jr player_bullet_hit_an_enemy_loop
player_bullet_hit_an_enemy_done:
    pop af
    ret


;-----------------------------------------------
; called when one of the player bullets hits a tank
; the bullet coordinates (2bytes each) are in (ix,ix+2)
player_bullet_hit_a_tank:
    push af     ;; we preserve 'a'

    ;; find which of the tanks it is:
    ld a,(currentNTanks)
    ld b,a
    ld iy,currentTanks

player_bullet_hit_a_tank_loop:
    ld a,b
    and a   ;; equivalent to cp 0, but faster
    jp z,player_bullet_hit_a_tank_done

    push bc
    ;; each tank is 8 bytes:
    ;;      health (1 byte)
    ;;      fire state (1 byte)
    ;;      movement state (1 byte)
    ;;      y (1 byte)   (in map pattern coordinates)
    ;;      x (1 byte)   (in map pattern coordinates)
    ;;      map pointer (2 bytes)
    ;;      turret angle
    
    ;; find a tank whose (x,y) is not more than 8*16 away in x and y from the bullet:
    ld h,(iy+3) ;; hl = tank y
    ld l,0
    sra h   ;; divide by 2 (so that it's actually multiplied by 128)
    rr l

    ld c,(ix)
    ld b,(ix+1)     ;; bc = bullet y
    xor a
    sbc hl,bc       ;; hl = (tank.y - bullet.y)
    ;; check the difference is in between -8*16 and 8*16
    ld d,l
    ld e,h
    ld bc,12*16
    sbc hl,bc
    jp p,player_bullet_hit_a_tank_nextTank
    ld l,d
    ld h,e
    ld bc,-12*16
    sbc hl,bc
    jp m,player_bullet_hit_a_tank_nextTank
    ld h,(iy+4) ;; hl = tank x
    inc h   ;; to make it the turret coordinates
    ld l,0
    sra h   ;; divide by 2 (so that it's actually multiplied by 128)
    rr l

    ld c,(ix+2)
    ld b,(ix+3)     ;; bc = bullet x
    xor a
    sbc hl,bc       ;; hl = (tank.x - bullet.x)
    ;; check the difference is in between -8*16 and 8*16
    ld d,l
    ld e,h
    ld bc,12*16
    sbc hl,bc
    jp p,player_bullet_hit_a_tank_nextTank
    ld l,d
    ld h,e
    ld bc,-12*16
    sbc hl,bc
    jp m,player_bullet_hit_a_tank_nextTank

    ;; we found our tank!
    call tank_hit
    pop bc
    jp player_bullet_hit_a_tank_done

player_bullet_hit_a_tank_nextTank:
    pop bc
    ld de,8
    add iy,de
    dec b
    jr player_bullet_hit_a_tank_loop
player_bullet_hit_a_tank_done:
    pop af
    ret


;-----------------------------------------------
; The enemy stored in (iy) was hit by the player:
enemy_hit:
    ld hl,SFX_explosion
    call play_SFX

    ld a,(iy+10)
    dec a
    ld (iy+10),a
    and a   ;; equivalent to cp 0, but faster
    ret nz  ;; if the enemy still has health, return

    ;; destroy enemy:
    xor a
    ld (iy),a   ;; set the enemy to be dead (makes it inactive)

    ;; find an available explosion slot:
    ld c,0
    ld hl,explosions_active
    ld de,explosions_positions_and_replacement
enemy_hit_explosion_loop:
    ld a,(hl)
    and a   ;; equivalent to cp 0, but faster
    jp z,enemy_hit_explosion_slot_found
    inc c
    inc hl
    inc de
    inc de
    inc de
    inc de
    ld a,MAX_EXPLOSIONS
    cp c
    jp nz,enemy_hit_explosion_loop

    ;; no explosion slot found, just male the enemy disappear:
    ld l,(iy+3)
    ld h,(iy+4) ;; enemy definition
    inc hl
    inc hl      ;; hl now points to the tiles we need to replace the enemy with
    ld e,(iy+1)
    ld d,(iy+2) ;; map pointer

    ldi     ;; copy the first two tiles (assume enemies are 2x2)
    ldi
    ld b,0
    ld a,(current_map_dimensions+1)
    ld c,a
    dec c
    dec c
    ex de,hl
    add hl,bc       ;; move to the next map row
    ex de,hl
    ldi
    ldi     ;; copy the second two tiles

    ret

enemy_hit_explosion_slot_found:
    ld a,24 ;; explosion timer copied to the state (which will be decreased in 1 each frame until reaching 0)
    ld (hl),a
    ld a,(iy+1) ;; write the current_map pointer of the enemy
    ld (de),a
    inc de
    ld a,(iy+2)
    ld (de),a
    inc de

    ld l,(iy+3)
    ld h,(iy+4) ;; enemy definition
    inc hl
    inc hl  ;; make hl point to the tiles to be drawn after the explosion
    ld a,l
    ld (de),a
    inc de
    ld a,h
    ld (de),a

    ret


;-----------------------------------------------
; The tank stored in (iy) was hit by the player:
tank_hit:
    ld hl,SFX_explosion
    call play_SFX

    ld a,(iy)
    dec a
    ld (iy),a
    and a   ;; equivalent to cp 0, but faster
    ret nz  ;; if the tank still has health, return

    ;; clear tank:
    ld l,(iy+5)
    ld h,(iy+6)
    call clear_tank    

    ;; find an available explosion slot:
    ld c,0
    ld hl,explosions_active
    ld de,explosions_positions_and_replacement
tank_hit_explosion_loop:
    ld a,(hl)
    and a   ;; equivalent to cp 0, but faster
    jp z,tank_hit_explosion_slot_found
    inc c
    inc hl
    inc de
    inc de
    inc de
    inc de
    ld a,MAX_EXPLOSIONS
    cp c
    jp nz,tank_hit_explosion_loop

    ;; no explosion slot found, oh well...

    ret

tank_hit_explosion_slot_found:
    ld a,24 ;; explosion timer copied to the state (which will be decreased in 1 each frame until reaching 0)
    ld (hl),a

    ld c,(iy+5)
    ld b,(iy+6)
    inc bc
    ld a,c
    ld (de),a
    inc de
    ld a,b
    ld (de),a
    inc de

    ld hl,tank_replacement_patterns
    ld a,l
    ld (de),a
    inc de
    ld a,h
    ld (de),a

    ret


;; this only clears the sides of the tank (the center will be cleared by the explosion)
clear_tank:
    ld (hl),0
    inc hl
    inc hl
    inc hl
    ld (hl),0

    ld b,0
    ld a,(current_map_dimensions+1)
    ld c,a
    add hl,bc
    xor a
    ld c,3
    sbc hl,bc
    ld (hl),0
    inc hl
    inc hl
    inc hl
    ld (hl),0
    ret

tank_replacement_patterns: db 0,0,0,0

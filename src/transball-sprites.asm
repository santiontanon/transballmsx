;-----------------------------------------------
; updates the ship and thruster sprites depending on the ship state
changeSprites:
    ld hl,SPRTBL2
    call SETWRT
    ex de,hl
    ld bc,0
    ld a,(shipangle)
    and #fc    ;; angle needs to be divided by 4 (we only have 16 frames), 
    sla a      ;; and then multiplied by 32 (each sprite is 32 bytes),
    sla a      ;; so, we just clear the lower 2 bits, and multiply by 8 (to
               ;; prevent overflow, we multiply by 4 and add it twice to hl)
    ld c,a
    ld hl,shipvpanther
    add hl,bc
    add hl,bc
    push bc
    ld b,32
    ld c,VDP_DATA
changeSprites_loop:
    outi
    jp nz,changeSprites_loop

    pop bc

    ld hl,SPRTBL2+32
    call SETWRT
    ex de,hl
    ld hl,shipvpanther_thruster
    add hl,bc
    add hl,bc
    ld b,32
    ld c,VDP_DATA
changeSprites_loop2:
    outi
    jp nz,changeSprites_loop2

    ret


;-----------------------------------------------
; updates the ship and thruster sprites to display an explosion
shipExplosionSprites:
    ld a,8
    ld (thruster_spriteattributes+3),a
    ld a,10
    ld (ship_spriteattributes+3),a

    ld hl,SPRTBL2
    call SETWRT
    ex de,hl
    ld hl,explosion_sprites_inside
    ld a,(shipstate)    ;; get the offset of the explosion frame
    and #f8
    sla a
    sla a
    cp 32*3
    jp p,shipExplosionSprites_blank_sprites
    ld c,a
    ld b,0
    add hl,bc
    ld b,32
    ld c,VDP_DATA
shipExplosionSprites_loop:
    outi
    jp nz,shipExplosionSprites_loop

    ld hl,SPRTBL2+32
    call SETWRT
    ex de,hl
    ld hl,explosion_sprites_outside
    ld a,(shipstate)    ;; get the offset of the explosion frame
    and #f8
    sla a
    sla a
    ld c,a
    ld b,0
    add hl,bc
    ld b,32
    ld c,VDP_DATA
shipExplosionSprites_loop2:
    outi
    jp nz,shipExplosionSprites_loop2
    ret

shipExplosionSprites_blank_sprites:
    xor a
    ld bc,64
    ld hl,SPRTBL2
    call FILVRM
    ret


;-----------------------------------------------
; calculates the coordinates where to draw the ship on screen based on its coordinates 
; and on the map offset
calculate_ship_sprite_position:
    ld hl,(shipposition)
    ;; project down to screen coordinates:
    ld bc,(map_offset)
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
    ld a,l
    ld (ship_spriteattributes),a
    ld (thruster_spriteattributes),a

    ld hl,(shipposition+2)
    ;; project down to screen coordinates:
    ; divide by 16:
    ld bc,(map_offset+2)
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
    ld a,l
    ld (ship_spriteattributes+1),a
    ld (thruster_spriteattributes+1),a

    ret


;-----------------------------------------------
; calculates the coordinates where to draw the ball on screen based on its coordinates 
; and on the map offset
calculate_ball_sprite_position:
    ;; calculate ball position
    ; y:
    ld hl,(ballposition)
    ld bc,(map_offset)
    ld a,(ballstate)
    cp 0
    jr nz,calculate_ball_sprite_position_snap_ball_to_map_y_continue
    ld a,c
    and #80
    ld c,a
calculate_ball_sprite_position_snap_ball_to_map_y_continue:
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
    ld a,h  ;; If "h" is anything but 0, that means that the ball is outside of the drawing area
    cp 0
    jr nz,calculate_ball_sprite_position_outside_y
    ld a,l
    cp 192
    jr nc,calculate_ball_sprite_position_outside_y
    ld (ball_spriteattributes),a
    jr calculate_ball_sprite_position_y_continue
calculate_ball_sprite_position_outside_y:
    ld a,192
    ld (ball_spriteattributes),a ;; just a value that would draw the ball out of the drawable area
calculate_ball_sprite_position_y_continue:
    ; x:
    ld hl,(ballposition+2)
    ld bc,(map_offset+2)
    ld a,(ballstate)
    cp 0
    jr nz,calculate_ball_sprite_position_snap_ball_to_map_x_continue
    ld a,c
    and #80
    ld c,a
calculate_ball_sprite_position_snap_ball_to_map_x_continue:
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
    ld a,h  ;; If "h" is anything but 0, that means that the ball is outside of the drawing area
    cp 0
    jr nz,calculate_ball_sprite_position_outside_x
    ld a,l
    ld (ball_spriteattributes+1),a
    jp calculate_ball_sprite_position_continue
calculate_ball_sprite_position_outside_x:
    ld a,224
    ld (ball_spriteattributes),a ;; just a value that would draw the ball out of the drawable area
    ld a,255
    ld (ball_spriteattributes+1),a ;; just a value that would draw the ball out of the drawable area
    ret

calculate_ball_sprite_position_continue:
    ; set the color of the ball (and also if it is inactive, make it snap to 8x8 coordinates)
    ld a,(ballstate)
    cp 0
    jr z,calculate_ball_sprite_position_ball_inactive
    ld a,BALL_ACTIVE_COLOR
    ld (ball_spriteattributes+3),a
    ret

calculate_ball_sprite_position_ball_inactive:
    ld a,BALL_INACTIVE_COLOR
    ld (ball_spriteattributes+3),a
    ret


;-----------------------------------------------
; calculates the coordinates where to draw the bullets on screen based on its coordinates 
; and on the map offset
calculate_bullet_sprite_positions:
    ld c,0
    ld hl,player_bullet_active
    ld de,player_bullet_positions
    ld ix,player_bullet_sprite_attributes
calculate_bullet_sprite_positions_loop:
    ld a,(hl)
    cp 0
    jr z,calculate_bullet_sprite_positions_next_bullet

    push hl
    push bc

    ;; turn the bullet on:
    ld (ix+3),PLAYER_BULLET_COLOR

    ;; calculate bullet position
    ;; from: player_bullet_positions to player_bullet_sprite_attributes
    ; y:
    ld a,(de)
    ld l,a
    inc de
    ld a,(de)
    ld h,a
    inc de
    ld bc,(map_offset)
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
    ld a,h  ;; If "h" is anything but 0, that means that the bullet is outside of the drawing area
    cp 0
    jr nz,calculate_bullet_sprite_positions_bullet_outside_y
    ld a,l
    cp 192
    jr nc,calculate_bullet_sprite_positions_bullet_outside_y
    ld (ix),a
    jr calculate_bullet_sprite_positions_bullet_outside_y_continue
calculate_bullet_sprite_positions_bullet_outside_y:
    ld (ix),224 ;; just a value that would draw the bullet out of the drawable area
calculate_bullet_sprite_positions_bullet_outside_y_continue:
    ; x:
    ld a,(de)
    ld l,a
    inc de
    ld a,(de)
    ld h,a
    inc de
    ld bc,(map_offset+2)
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
    ld a,h  ;; If "h" is anything but 0, that means that the bullet is outside of the drawing area
    cp 0
    jr nz,calculate_bullet_sprite_positions_bullet_outside_x
    ld a,l
    ld (ix+1),a
    jr calculate_bullet_sprite_positions_bullet_outside_x_continue
calculate_bullet_sprite_positions_bullet_outside_x:
    ld (ix),224 ;; just a value that would draw the bullet out of the drawable area
    ld (ix+1),255 ;; just a value that would draw the bullet out of the drawable area
calculate_bullet_sprite_positions_bullet_outside_x_continue:
    pop bc
    pop hl
    jr calculate_bullet_sprite_positions_next_bullet2

calculate_bullet_sprite_positions_next_bullet:
    ;; turn the bullet off:
    ld (ix+3),0
    
    inc de  ;; next bullet position
    inc de
    inc de
    inc de
calculate_bullet_sprite_positions_next_bullet2:
    inc hl
    inc ix
    inc ix
    inc ix
    inc ix
    inc c
    ld a,c
    cp MAX_PLAYER_BULLETS
    jp nz,calculate_bullet_sprite_positions_loop
    ret


;-----------------------------------------------
; calculates the coordinates where to draw the enemy bullets on screen based on its coordinates 
; and on the map offset
calculate_enemy_bullet_sprite_positions:
    ld c,0
    ld hl,enemy_bullet_active
    ld de,enemy_bullet_positions
    ld ix,enemy_bullet_sprite_attributes
calculate_enemy_bullet_sprite_positions_loop:
    ld a,(hl)
    cp 0
    jr z,calculate_enemy_bullet_sprite_positions_next_bullet

    push hl
    push bc

    ;; turn the bullet on:
    ld (ix+3),ENEMY_BULLET_COLOR

    ;; calculate bullet position
    ;; from: player_bullet_positions to player_bullet_sprite_attributes
    ; y:
    ld a,(de)
    ld l,a
    inc de
    ld a,(de)
    ld h,a
    inc de
    ld bc,(map_offset)

    ld a,c      ;; align the bullet to the exact map offset (in blocks of 8x8)
    and #80
    ld c,a

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
    ld a,h  ;; If "h" is anything but 0, that means that the bullet is outside of the drawing area
    cp 0
    jr nz,calculate_enemy_bullet_sprite_positions_bullet_outside_y
    ld a,l
    cp 192
    jr nc,calculate_enemy_bullet_sprite_positions_bullet_outside_y
    ld (ix),a
    jr calculate_enemy_bullet_sprite_positions_bullet_outside_y_continue
calculate_enemy_bullet_sprite_positions_bullet_outside_y:
    ld (ix),224 ;; just a value that would draw the bullet out of the drawable area
calculate_enemy_bullet_sprite_positions_bullet_outside_y_continue:
    ; x:
    ld a,(de)
    ld l,a
    inc de
    ld a,(de)
    ld h,a
    inc de
    ld bc,(map_offset+2)

    ld a,c      ;; align the bullet to the exact map offset (in blocks of 8x8)
    and #80
    ld c,a

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
    ld a,h  ;; If "h" is anything but 0, that means that the bullet is outside of the drawing area
    cp 0
    jr nz,calculate_enemy_bullet_sprite_positions_bullet_outside_x
    ld a,l
    ld (ix+1),a
    jr calculate_enemy_bullet_sprite_positions_bullet_outside_x_continue
calculate_enemy_bullet_sprite_positions_bullet_outside_x:
    ld (ix),224   ;; just a value that would draw the bullet out of the drawable area
    ld (ix+1),255 ;; just a value that would draw the bullet out of the drawable area
calculate_enemy_bullet_sprite_positions_bullet_outside_x_continue:
    pop bc
    pop hl
    jr calculate_enemy_bullet_sprite_positions_next_bullet2

calculate_enemy_bullet_sprite_positions_next_bullet:
    ;; turn the bullet off:
    ld (ix+3),0
    
    inc de  ;; next bullet position
    inc de
    inc de
    inc de
calculate_enemy_bullet_sprite_positions_next_bullet2:
    inc hl
    inc ix
    inc ix
    inc ix
    inc ix
    inc c
    ld a,c
    cp MAX_ENEMY_BULLETS
    jp nz,calculate_enemy_bullet_sprite_positions_loop
    ret
    
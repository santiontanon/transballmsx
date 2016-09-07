;-----------------------------------------------
; updates the ship and thruster sprites depending on the ship state
changeSprites:
    ld hl,SPRTBL2+SHIP_SPRITE*32
    call SETWRT
    ld bc,0
    ld a,(shipangle)
    and #fe    ;; angle needs to be divided by 2 (we only have 32 frames), 
    sla a      ;; and then multiplied by 32 (each sprite is 32 bytes),
    sla a      ;; so, we just clear the lower bit, and multiply by 16 (to
               ;; prevent overflow, we multiply by 4 and add it four times to hl)
    ld c,a
    ld hl,shipvpanther
    add hl,bc
    add hl,bc
    add hl,bc
    add hl,bc
	 
    ld bc,32*256+VDP_DATA
b1:	outi
	jp nz,b1

	; valid only becouse THRUSTER_SPRITE follows SHIP_SPRITE
	
	ld bc,shipvpanther_thruster-shipvpanther-32
	
    add hl,bc
    ld bc,32*256+VDP_DATA
b2:	outi
	jp nz,b2
	ret

;-----------------------------------------------
; updates the ship and thruster sprites to display an explosion
shipExplosionSprites:
    ld a,8
    ld (thruster_spriteattributes+3),a
    ld a,10
    ld (ship_spriteattributes+3),a

    ld hl,SPRTBL2+SHIP_SPRITE*32
    call SETWRT
    ld hl,explosion_sprites_inside
    ld a,(shipstate)    		;; get the offset of the explosion frame
    and #f8
    sla a
    sla a
    cp 32*3
    jp p,clearAllTheSprites 	;; we do a "jp", so that when "clearAllTheSprites" is over, we return from this function
    ld c,a
    ld b,0
    add hl,bc
	call outi32

    ld hl,SPRTBL2+THRUSTER_SPRITE*32
    call SETWRT
    
    ld hl,explosion_sprites_outside
    ld a,(shipstate)    		;; get the offset of the explosion frame
    and #f8
    sla a
    sla a
    ld c,a
    ld b,0
    add hl,bc
	call outi32
    jp drawSprites
    

;-----------------------------------------------
; calculates the coordinates where to draw the ship on screen based on its coordinates 
; and on the map offset
calculate_ship_sprite_position:
    ld hl,(shipposition)
    ;; project down to screen coordinates:
    ld bc,(desired_map_offset)
	call sub_HL_BC_divide_HL_by_16
    ;; adjust sprite position based on the smooth scroll offset:
    ld a,(desired_vertical_scroll_for_r23)
    add a,l

    ld (ship_spriteattributes),a
    ld (thruster_spriteattributes),a

    ld hl,(shipposition+2)
    ;; project down to screen coordinates
    ld bc,(desired_map_offset+2)
	call sub_HL_BC_divide_HL_by_16

    ;; adjust sprite position based on the smooth scroll offset (only in MSX2):
    ld a,(useSmoothScroll)
    dec a
    jp z,calculate_ship_sprite_position_continue1
    ld a,8  ;; in MSX2+ we need to move all sprites 8 pixels to the right
    jp calculate_ship_sprite_position_continue2
calculate_ship_sprite_position_continue1:
    ld a,(desired_horizontal_scroll_for_r18)
calculate_ship_sprite_position_continue2:
    add a,l

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

    ;; in MSX1, align the ball coordinates to the map offset:
    ld a,(useSmoothScroll)
    and a
    jp nz,calculate_ball_sprite_position_snap_ball_to_map_y_continue
    ld a,(ballstate)
    and a   ;; equivalent to cp 0, but faster
    jr nz,calculate_ball_sprite_position_snap_ball_to_map_y_continue
    ld a,c
    and #80
    ld c,a
calculate_ball_sprite_position_snap_ball_to_map_y_continue:
	call sub_HL_BC_divide_HL_by_16
	;; If "h" is anything but 0, that means that the bullet is outside of the drawing area
    jr nz,calculate_ball_sprite_position_outside_y
    ld a,l
    cp 192
    jr nc,calculate_ball_sprite_position_outside_y

    ;; adjust sprite position based on the smooth scroll offset:
    ld b,a
    ld a,(desired_vertical_scroll_for_r23)
    add a,b

    ld (ball_spriteattributes),a
    jr calculate_ball_sprite_position_y_continue
calculate_ball_sprite_position_outside_y:
    ld a,224
    ld (ball_spriteattributes),a ;; just a value that would draw the ball out of the drawable area
calculate_ball_sprite_position_y_continue:
    ; x:
    ld hl,(ballposition+2)
    ld bc,(map_offset+2)

    ;; in MSX1, align the ball coordinates to the map offset:
    ld a,(useSmoothScroll)
    and a
    jp nz,calculate_ball_sprite_position_snap_ball_to_map_x_continue
    ld a,(ballstate)
    and a   ;; equivalent to cp 0, but faster
    jr nz,calculate_ball_sprite_position_snap_ball_to_map_x_continue
    ld a,c
    and #80
    ld c,a
calculate_ball_sprite_position_snap_ball_to_map_x_continue:
	call sub_HL_BC_divide_HL_by_16
	;; If "h" is anything but 0, that means that the bullet is outside of the drawing area
    jr nz,calculate_ball_sprite_position_outside_x

    ;; adjust sprite position based on the smooth scroll offset (only in MSX2):
    ld a,(useSmoothScroll)
    dec a
    jp z,calculate_ball_sprite_position_r18_continue1
    ld a,8  ;; in MSX2+ we need to move all sprites 8 pixels to the right
    jp calculate_ball_sprite_position_r18_continue2
calculate_ball_sprite_position_r18_continue1:
    ld a,(desired_horizontal_scroll_for_r18)
calculate_ball_sprite_position_r18_continue2:    
    add a,l

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
    and a   ;; equivalent to cp 0, but faster
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
    and a   ;; equivalent to cp 0, but faster
    jr z,calculate_bullet_sprite_positions_next_bullet

    push hl
    push bc

    ;; turn the bullet on:
    ld (ix+3),PLAYER_BULLET_COLOR

    ;; calculate bullet position
    ;; from: player_bullet_positions to player_bullet_sprite_attributes
    ; y:
    ld bc,(map_offset)
    ld a,(de)
    ld l,a
    inc de
    ld a,(de)
    ld h,a
    inc de
    call sub_HL_BC_divide_HL_by_16
	;; If "h" is anything but 0, that means that the bullet is outside of the drawing area
    jr nz,calculate_bullet_sprite_positions_bullet_outside_y
    ld a,l
    cp 192
    jr nc,calculate_bullet_sprite_positions_bullet_outside_y

    ;; adjust sprite position based on the smooth scroll offset:
    ld b,a
    ld a,(desired_vertical_scroll_for_r23)
    add a,b

    ld (ix),a
    jr calculate_bullet_sprite_positions_bullet_outside_y_continue
calculate_bullet_sprite_positions_bullet_outside_y:
    ld (ix),224 ;; just a value that would draw the bullet out of the drawable area
calculate_bullet_sprite_positions_bullet_outside_y_continue:
    ; x:
    ld bc,(map_offset+2)
    ld a,(de)
    ld l,a
    inc de
    ld a,(de)
    ld h,a
    inc de
	call sub_HL_BC_divide_HL_by_16
	;; If "h" is anything but 0, that means that the bullet is outside of the drawing area
    jr nz,calculate_bullet_sprite_positions_bullet_outside_x

    ;; adjust sprite position based on the smooth scroll offset (only in MSX2):
    ld a,(useSmoothScroll)
    dec a
    jp z,calculate_bullet_sprite_positions_r18_continue1
    ld a,8  ;; in MSX2+ we need to move all sprites 8 pixels to the right
    jp calculate_bullet_sprite_positions_r18_continue2
calculate_bullet_sprite_positions_r18_continue1:
    ld a,(desired_horizontal_scroll_for_r18)
calculate_bullet_sprite_positions_r18_continue2:    
    add a,l

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
    and a   ;; equivalent to cp 0, but faster
    jp z,calculate_enemy_bullet_sprite_positions_next_bullet

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

    ;; in MSX1, align the enemy coordinates to the map offset:
    ld a,(useSmoothScroll)
    and a
    jp nz,calculate_enemy_bullet_sprite_positions_snap_y_continue
    ld a,c      ;; align the bullet to the exact map offset (in blocks of 8x8)
    and #80
    ld c,a
calculate_enemy_bullet_sprite_positions_snap_y_continue:
	call sub_HL_BC_divide_HL_by_16
    jr nz,calculate_enemy_bullet_sprite_positions_bullet_outside_y
    ld a,l
    cp 192
    jr nc,calculate_enemy_bullet_sprite_positions_bullet_outside_y
    ;; adjust sprite position based on the smooth scroll offset:
    ld a,(desired_vertical_scroll_for_r23)
    add a,l
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

    ;; in MSX1, align the enemy coordinates to the map offset:
    ld a,(useSmoothScroll)
	and a
    jp nz,calculate_enemy_bullet_sprite_positions_snap_x_continue
    ld a,c      ;; align the bullet to the exact map offset (in blocks of 8x8)
    and #80
    ld c,a
calculate_enemy_bullet_sprite_positions_snap_x_continue:
	call sub_HL_BC_divide_HL_by_16
    jr nz,calculate_enemy_bullet_sprite_positions_bullet_outside_x
    
    ;; adjust sprite position based on the smooth scroll offset (only in MSX2):
    ld a,(useSmoothScroll)
    dec a
    jp z,calculate_enemy_bullet_sprite_positions_r18_continue1
    ld a,8  ;; in MSX2+ we need to move all sprites 8 pixels to the right
    jp calculate_enemy_bullet_sprite_positions_r18_continue2
calculate_enemy_bullet_sprite_positions_r18_continue1:
    ld a,(desired_horizontal_scroll_for_r18)
calculate_enemy_bullet_sprite_positions_r18_continue2:    
    add a,l

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
    

;-----------------------------------------------
; decompresses the RLE-encoded sprites into RAM so they can be used during the game
DECOMPRESS_SPRITES:
    ;; 1) decompress shipvpanther_RLE_encoded1 onto the sprites buffer
    ld ix,shipvpanther_RLE_encoded1
    ld de,shipvpanther
    ld bc,288
    call RLE_decode

    ;; 2) decompress shipvpanther_RLE_encoded2 onto the map buffer
    ld ix,shipvpanther_RLE_encoded2
    ld de,shipvpanther+17*32
    ld bc,256
    call RLE_decode

    ;; 3) copy to sprites 0 - 7 onto 9 - 16 inverting the y 
    ld hl,shipvpanther+32*7
    ld de,shipvpanther+32*9
    call INVERT_SPRITE
    ld hl,shipvpanther+32*6
    ld de,shipvpanther+32*10
    call INVERT_SPRITE
    ld hl,shipvpanther+32*5
    ld de,shipvpanther+32*11
    call INVERT_SPRITE
    ld hl,shipvpanther+32*4
    ld de,shipvpanther+32*12
    call INVERT_SPRITE
    ld hl,shipvpanther+32*3
    ld de,shipvpanther+32*13
    call INVERT_SPRITE
    ld hl,shipvpanther+32*2
    ld de,shipvpanther+32*14
    call INVERT_SPRITE
    ld hl,shipvpanther+32*1
    ld de,shipvpanther+32*15
    call INVERT_SPRITE
    ld hl,shipvpanther+32*0
    ld de,shipvpanther+32*16
    call INVERT_SPRITE

    ;; 4) copy to sprites 17 - 23 onto 25 - 31 inverting the y 
    ld hl,shipvpanther+32*17
    ld de,shipvpanther+32*31
    call INVERT_SPRITE
    ld hl,shipvpanther+32*18
    ld de,shipvpanther+32*30
    call INVERT_SPRITE
    ld hl,shipvpanther+32*19
    ld de,shipvpanther+32*29
    call INVERT_SPRITE
    ld hl,shipvpanther+32*20
    ld de,shipvpanther+32*28
    call INVERT_SPRITE
    ld hl,shipvpanther+32*21
    ld de,shipvpanther+32*27
    call INVERT_SPRITE
    ld hl,shipvpanther+32*22
    ld de,shipvpanther+32*26
    call INVERT_SPRITE
    ld hl,shipvpanther+32*23
    ld de,shipvpanther+32*25
    call INVERT_SPRITE

    ;; 5) decompress shipvpanther_RLE_encoded1 onto the sprites buffer
    ld ix,shipvpanther_thruster_RLE_encoded1
    ld de,shipvpanther_thruster
    ld bc,288
    call RLE_decode

    ;; 6) decompress shipvpanther_RLE_encoded2 onto the map buffer
    ld ix,shipvpanther_thruster_RLE_encoded2
    ld de,shipvpanther_thruster+17*32
    ld bc,256
    call RLE_decode

    ;; 7) copy to sprites 0 - 7 onto 9 - 16 inverting the y 
    ld hl,shipvpanther_thruster+32*7
    ld de,shipvpanther_thruster+32*9
    call INVERT_SPRITE
    ld hl,shipvpanther_thruster+32*6
    ld de,shipvpanther_thruster+32*10
    call INVERT_SPRITE
    ld hl,shipvpanther_thruster+32*5
    ld de,shipvpanther_thruster+32*11
    call INVERT_SPRITE
    ld hl,shipvpanther_thruster+32*4
    ld de,shipvpanther_thruster+32*12
    call INVERT_SPRITE
    ld hl,shipvpanther_thruster+32*3
    ld de,shipvpanther_thruster+32*13
    call INVERT_SPRITE
    ld hl,shipvpanther_thruster+32*2
    ld de,shipvpanther_thruster+32*14
    call INVERT_SPRITE
    ld hl,shipvpanther_thruster+32*1
    ld de,shipvpanther_thruster+32*15
    call INVERT_SPRITE
    ld hl,shipvpanther_thruster+32*0
    ld de,shipvpanther_thruster+32*16
    call INVERT_SPRITE    

    ;; 8) copy to sprites 17 - 23 onto 25 - 31 inverting the y 
    ld hl,shipvpanther_thruster+32*17
    ld de,shipvpanther_thruster+32*31
    call INVERT_SPRITE
    ld hl,shipvpanther_thruster+32*18
    ld de,shipvpanther_thruster+32*30
    call INVERT_SPRITE
    ld hl,shipvpanther_thruster+32*19
    ld de,shipvpanther_thruster+32*29
    call INVERT_SPRITE
    ld hl,shipvpanther_thruster+32*20
    ld de,shipvpanther_thruster+32*28
    call INVERT_SPRITE
    ld hl,shipvpanther_thruster+32*21
    ld de,shipvpanther_thruster+32*27
    call INVERT_SPRITE
    ld hl,shipvpanther_thruster+32*22
    ld de,shipvpanther_thruster+32*26
    call INVERT_SPRITE
    ld hl,shipvpanther_thruster+32*23
    ld de,shipvpanther_thruster+32*25
    call INVERT_SPRITE
    ret

INVERT_SPRITE:
    push hl
    push de
    ld bc,15
    ex de,hl
    add hl,bc
    ex de,hl
    ld b,16
INVERT_SPRITE_loop1:
    ld a,(hl)
    ld (de),a
    inc hl
    dec de
    djnz INVERT_SPRITE_loop1
    pop de
    pop hl
    ld bc,16
    add hl,bc
    ld bc,31
    ex de,hl
    add hl,bc
    ex de,hl
    ld b,16
INVERT_SPRITE_loop2:
    ld a,(hl)
    ld (de),a
    inc hl
    dec de
    djnz INVERT_SPRITE_loop2
    ret

;-----------------------------------------------
; Loads a map (the map number is specified by 'current_level', starting at 0)
LOADMAP:
    ld b,0
    ld a,(current_level)
    ld c,a
    ld hl,mappointers   ; do hl = (hl + bc*2)
    add hl,bc
    add hl,bc
    ld c,(hl)
    inc hl
    ld b,(hl)
    ld h,b
    ld l,c  ;; hl has now the pointer to the map in ROM

    ;; set scoreboard string:
    cp 9
    jp m,LOADMAP_SingleDigitLevel
LOADMAP_TwoDigitLevel:    
    ld b,a
    ld a,'1'
    ld (scoreboard+scoreboard_level_offset),a
    ld a,b
    sub 10
    add a,'1'
    ld (scoreboard+scoreboard_level_offset+1),a
    jr LOADMAP_DoneWithLevelNumber
LOADMAP_SingleDigitLevel:    
    add a,'1'
    ld (scoreboard+scoreboard_level_offset+1),a
    ld a,'0'
    ld (scoreboard+scoreboard_level_offset),a

LOADMAP_DoneWithLevelNumber:    
    xor a
    ld (current_play_time),a    ; minutes
    ld (current_play_time+1),a  ; 10 seconds
    ld (current_play_time+2),a  ; 1 seconds
    ld (current_play_time+3),a  ; frames

    ld a,(hl)
    ld (current_fuel_left),a    ; major fuel units
    inc hl
    ld a,(hl)
    ld (current_fuel_left+1),a  ; minor fuel units
    inc hl

    ld a,(hl)
    ld (current_map_dimensions),a   ; store the height
    ld b,0
    ld c,a
    inc hl
    ld a,(hl)
    ld (current_map_dimensions+1),a ; store the width
    ld d,0
    ld e,a
    inc hl

    push hl
    pop ix      ;; ix has a pointer to the map in RLE in ROM
    call Mult_BC_by_DE
    ld b,h
    ld c,l
    ld (current_map_dimensions+2),bc ; store width*height
    ld de,currentMap

    call RLE_decode

    ld ix,current_map_ship_limits
    ld (ix),0
    ld (ix+1),0
    ld (ix+2),0
    ld (ix+3),0
    ; (current_map_dimensions.y-2)*128
    ld a,(current_map_dimensions)
    sub 2   ;; subtract 2
    ld c,a  ;; multiply by 128
    ld b,0
    xor a
    srl b
    rr c
    rra
    ld b,c
    ld c,a
    ld (ix+4),c
    ld (ix+5),b
    ; (current_map_dimensions.x-2)*128
    ld a,(current_map_dimensions+1)
    sub 2   ;; subtract 2
    ld c,a  ;; multiply by 128
    ld b,0
    xor a
    srl b
    rr c
    rra
    ld b,c
    ld c,a
    ld (ix+6),c
    ld (ix+7),b

    ;; initialize variables:
    xor a
    ld (ballstate),a
    ld (levelComplete),a
    ld c,MAX_PLAYER_BULLETS
    ld hl,player_bullet_active
    ld (ndoors),a
    ld (nballdoors),a
LOADMAP_initialize_variables_loop:    
    ld (hl),a
    inc hl
    dec c
    jr nz,LOADMAP_initialize_variables_loop         

    ld c,MAX_PLAYER_BULLETS
    ld hl,player_bullet_sprite_attributes
LOADMAP_initialize_variables_loop2:
    xor a
    ld (hl),a
    inc hl
    ld (hl),a
    inc hl
    ld a,BULLET_SPRITE*4    ;; pointer to the 3rd sprite (the bullet)
    ld (hl),a
    inc hl
    xor a
    ld (hl),a
    inc hl
    dec c
    jr nz,LOADMAP_initialize_variables_loop2

    ld c,MAX_ENEMY_BULLETS
    ld hl,enemy_bullet_active
LOADMAP_initialize_variables_loop3:    
    ld (hl),a
    inc hl
    dec c
    jr nz,LOADMAP_initialize_variables_loop3         

    ld c,MAX_ENEMY_BULLETS
    ld hl,enemy_bullet_sprite_attributes
LOADMAP_initialize_variables_loop4:
    xor a
    ld (hl),a
    inc hl
    ld (hl),a
    inc hl
    ld a,BULLET_SPRITE*4    ;; pointer to the 3rd sprite (the bullet)
    ld (hl),a
    inc hl
    xor a
    ld (hl),a
    inc hl
    dec c
    jr nz,LOADMAP_initialize_variables_loop4

    ld c,MAX_EXPLOSIONS
    ld hl,explosions_active
LOADMAP_initialize_variables_loop5:    
    ld (hl),a
    inc hl
    dec c
    jr nz,LOADMAP_initialize_variables_loop5

    call LOADMAP_find_animations

    ;; search for the ball starting position
    ld hl,currentMap
    ld b,0  ;; height
LOADMAP_ballstand_loop2:
    ld c,0  ;; width
LOADMAP_ballstand_loop1:
    ld a,(hl)
    cp PATTERN_BALL_STAND
    jr nz,LOADMAP_not_ballstand

    ;; ball stand found: 
    ;; (ballposition) = b*8*16
    push hl
    xor a
    ld h,a
    ld l,b
    srl h
    rr l
    rra
    ld h,l
    ld l,a
    ld de,15*16
    xor a
    sbc hl,de
    ld (ballposition),hl
    ;; (ballposition+2) = c*8*16
    ;xor a
    ld h,a
    ld l,c
    srl h
    rr l
    rra
    ld h,l
    ld l,a
    ld de,4*16
    xor a
    sbc hl,de
    ld (ballposition+2),hl
    pop hl

    jr LOADMAP_ballstand_found

LOADMAP_not_ballstand:
    inc hl
    inc c
    ld a,(current_map_dimensions+1)
    cp c
    jr nz,LOADMAP_ballstand_loop1
    inc b
    ld a,(current_map_dimensions)
    cp b
    jr nz,LOADMAP_ballstand_loop2
LOADMAP_ballstand_found:

    ;; find all the enemies:
    xor a
    ld (currentNEnemies),a
    ld iy,currentEnemies
    ld hl,enemies
LOADMAP_find_enemies_loop1:
    ld a,(hl)
    and a   ;; equivalent to cp 0, but faster
    jr z,LOADMAP_done_finding_enemies
    inc hl
    ld e,(hl)
    inc hl
    ld d,(hl)  
    inc hl
    push hl

    push de
    pop ix  ;; ix = pointer to the enemy definition

    ; iterate over the map, to find instances of this pattern:
    ld hl,currentMap
    ld b,0  ;; height
LOADMAP_find_enemies_loop_height:
    ld c,0  ;; width
LOADMAP_find_enemies_loop_width:
    push af

    ld d,(hl)
    ;; check if it's one of the enemies:
    cp d
    jr nz,LOADMAP_enemy_does_not_match

    ;; enemy found! copy to iy: 
    ;;      type (1 byte)
    ;;      map pointer (2 bytes)
    ;;      enemy type pointer (2 bytes)
    ;;      y (2 bytes)
    ;;      x (2 bytes)
    ;;      state (1 byte)    
    ;;      hit points (1 byte)
    ld a,(ix)
    ld (iy),a
    ld (iy+1),l
    ld (iy+2),h
    push ix
    pop de
    ld (iy+3),e
    ld (iy+4),d

    ;; y:
    push hl
    xor a
    ld h,a
    ld l,b
    srl h
    rr l
    rra
    ld h,l
    ld l,a
    ld (iy+5),l
    ld (iy+6),h

    ;; x:
    xor a
    ld h,a
    ld l,c
    srl h
    rr l
    rra
    ld h,l
    ld l,a
    ld (iy+7),l
    ld (iy+8),h
    pop hl

    ld (iy+9),0 ;; state
    ld a,(ix+1)
    ld (iy+10),a ;; health 

    ld de,11
    add iy,de

    ;; increment the number of enemies found:
    ld a,(currentNEnemies)
    inc a
    ld (currentNEnemies),a

LOADMAP_enemy_does_not_match:
    pop af

    inc hl
    inc c
    ld d,a
    ld a,(current_map_dimensions+1)
    cp c
    ld a,d
    jr nz,LOADMAP_find_enemies_loop_width
    inc b
    ld d,a
    ld a,(current_map_dimensions)
    cp b
    ld a,d
    jr nz,LOADMAP_find_enemies_loop_height
    pop hl

    jp LOADMAP_find_enemies_loop1
    
LOADMAP_done_finding_enemies:

    ;; find all the tanks:
    xor a
    ld (currentNTanks),a
    ld iy,currentTanks

    ; iterate over the map, to find instances of this pattern:
    ld hl,currentMap
    ld b,0  ;; height
LOADMAP_find_tanks_loop_height:
    ld c,0  ;; width
LOADMAP_find_tanks_loop_width:
    ld a,(hl)
    ;; check if it's a tank:
    cp PATTERN_TANK
    jr nz,LOADMAP_tank_does_not_match
    
    ;; tank found! copy to iy: 
    ;;      health (1 byte)
    ;;      fire state (1 byte)
    ;;      movement state (1 byte)
    ;;      y (1 byte)   (in map pattern coordinates)
    ;;      x (1 byte)   (in map pattern coordinates)
    ;;      map pointer (2 bytes)
    ;;      turrent angle (1 byte)
    ld (iy),6   ;; tank health
    ld (iy+1),0 ;; fire state
    ld (iy+2),TANK_MOVE_SPEED ;; movement state (positive: moving to the right)
    ld (iy+3),b ;; y
    dec c
    ld (iy+4),c ;; x
    inc c
    dec hl      ;; to point to the top-left position of the 4x2 grid that makes up the tank
    ld (iy+5),l ;; map pointer
    ld (iy+6),h
    inc hl
    ld (iy+7),3 ;; turrent angle
    ld de,8
    add iy,de

    ;; increment the number of tanks found:
    ld a,(currentNTanks)
    inc a
    ld (currentNTanks),a

LOADMAP_tank_does_not_match:
    inc hl
    inc c
    ld a,(current_map_dimensions+1)
    cp c
    jr nz,LOADMAP_find_tanks_loop_width
    inc b
    ld a,(current_map_dimensions)
    cp b
    jr nz,LOADMAP_find_tanks_loop_height

LOADMAP_done_finding_tanks:

    ;; search for the doors in the map
    ld hl,currentMap
    ld ix,doors
    ld b,0  ;; height
LOADMAP_door_loop2:
    ld c,0  ;; width
LOADMAP_door_loop1:
    ld a,(hl)
    cp PATTERN_LEFT_DOOR
    jr nz,LOADMAP_not_door

    ;; door found
    ld a,(ndoors)
    inc a
    ld (ndoors),a

    inc hl      ;; check the tile immediately to the right
    ld a,(hl)
    dec hl
    cp PATTERN_RIGHT_DOOR
    jr z,LOADMAP_door_is_closed
LOADMAP_door_is_open:
    ld (ix),1
    ld (ix+1),l
    ld (ix+2),h
    jr LOADMAP_inc_door_ptr

LOADMAP_door_is_closed:
    ld (ix),0
    dec hl      ;; we decrement hl in 2, to get the position where the door will be when open
    dec hl
    ld (ix+1),l
    ld (ix+2),h
    inc hl
    inc hl

LOADMAP_inc_door_ptr:

    inc ix
    inc ix
    inc ix

LOADMAP_not_door:
    inc hl    
    inc c
    ld a,(current_map_dimensions+1)
    cp c
    jr nz,LOADMAP_door_loop1
    inc b
    ld a,(current_map_dimensions)
    cp b
    jr nz,LOADMAP_door_loop2

LOADMAP_doors_found:

    ;; search for the ball doors (doors that are open/closed when the ball is picked up) in the map
    ld hl,currentMap
    ld ix,balldoors
    ld b,0  ;; height
LOADMAP_balldoor_loop2:
    ld c,0  ;; width
LOADMAP_balldoor_loop1:
    ld a,(hl)
    cp PATTERN_LEFT_BALL_DOOR
    jr nz,LOADMAP_not_balldoor

    ;; door found
    ld a,(nballdoors)
    inc a
    ld (nballdoors),a

    inc hl      ;; check the tile immediately to the right
    ld a,(hl)
    dec hl
    cp PATTERN_RIGHT_DOOR
    jr z,LOADMAP_balldoor_is_closed
LOADMAP_balldoor_is_open:
    ld (ix),1
    ld (ix+1),l
    ld (ix+2),h
    jr LOADMAP_inc_balldoor_ptr

LOADMAP_balldoor_is_closed:
    ld (ix),0
    dec hl      ;; we decrement hl in 2, to get the position where the door will be when open
    dec hl
    ld (ix+1),l
    ld (ix+2),h
    inc hl
    inc hl

LOADMAP_inc_balldoor_ptr:

    inc ix
    inc ix
    inc ix

LOADMAP_not_balldoor:
    inc hl    
    inc c
    ld a,(current_map_dimensions+1)
    cp c
    jr nz,LOADMAP_balldoor_loop1
    inc b
    ld a,(current_map_dimensions)
    cp b
    jr nz,LOADMAP_balldoor_loop2

LOADMAP_balldoors_found:    

    ret


;-----------------------------------------------
; finds all the animations in the current map
LOADMAP_find_animations:
    ;; find all the animations:
    xor a
    ld (currentNAnimations),a
    ld iy,currentAnimations
    ld hl,animations
LOADMAP_find_animations_loop1:
    ld a,(hl)
    and a   ;; equivalent to cp 0, but faster
    ret z
    inc hl
    ld e,(hl)
    inc hl
    ld d,(hl)   
    inc hl
    push hl

    inc de  ;; we need to skip the first byte
    push de
    pop ix  ;; ix = pointer to the animation definition

    ; iterate over the map, to find instances of this pattern:
    ld hl,currentMap
    ld bc,(current_map_dimensions+2)
LOADMAP_find_animations_loop2:
    ld d,(hl)

    ;; check if it's one of the animations:
    cp d
    jr nz,LOADMAP_animation_does_not_match

    ;; animation found! copy to iy: offset (dw), pointer to the animation definition (dw), 0 (timer) (db), 0 (animation step) (db)
    ld (iy),l
    inc iy
    ld (iy),h
    inc iy
    push ix
    pop de
    ld (iy),e
    inc iy
    ld (iy),d
    inc iy
    ld (iy),0
    inc iy
    ld (iy),0
    inc iy

    ;; increment the number of animations found: (but keep the value of a intact)
    ld d,a
    ld a,(currentNAnimations)
    inc a
    ld (currentNAnimations),a
    ld a,d

LOADMAP_animation_does_not_match:
    dec bc
    inc hl
    ld d,a
    ld a,b  ; check if bc is 0
    or c
    ld a,d
    jr nz,LOADMAP_find_animations_loop2
    pop hl

    jp LOADMAP_find_animations_loop1


;-----------------------------------------------
; calculates the coordinates in the map at which we need to start drawing, 
; based on the ship coordiantes
calculate_map_offset:
    ;; map_offsetRAM.y = (shippositionRAM.y - 88*16)
    ;; if map_offsetRAM.y < 0 then map_offsetRAM.y = 0
    ;; if map_offsetRAM.y > ((map_dimensions.y - 32) * 16 * 16) then map_offsetRAM.y = ((map_dimensions.y - 32) * 16 * 16)
    ld hl,(shipposition)
    ld bc,-(96-8)*16
    add hl,bc
    ld bc,0
    call HL_NOT_SMALLER_THAN_BC
    ld a,(current_map_dimensions)
    sub 24
    ld c,a  ;; multiply by 128
    ld b,0
    xor a
    srl b
    rr c
    rra
    ld b,c
    ld c,a
    call HL_NOT_BIGGER_THAN_BC
    ld (desired_map_offset),hl

    ;; calculate the offset for smooth scroll in MSX2
    ld a,(useSmoothScroll)
    and a   ;; equivalent to cp 0, but faster
    jp z,calculate_map_offset_MSX1_y
    ld a,l
    sra a
    sra a
    sra a
    sra a
    and #07
    ld (desired_vertical_scroll_for_r23),a

    ;; desired_map_offset_blockresolution

calculate_map_offset_MSX1_y:

    ;; map_offset.x = (shipposition.x - 120*16)
    ;; if map_offset.x < 0 then map_offset.x = 0
    ;; if map_offset.x > ((map_dimensions.x - 32) * 16 * 16) then map_offset.x = ((map_dimensions.x - 32) * 16 * 16)
    ld hl,(shipposition+2)
    ld bc,-(128-8)*16
    add hl,bc
    ld bc,0
    call HL_NOT_SMALLER_THAN_BC
    ld a,(current_map_dimensions+1)
    sub 32
    ld c,a  ;; multiply by 128
    ld b,0
    xor a
    srl b
    rr c
    rra
    ld b,c
    ld c,a
    call HL_NOT_BIGGER_THAN_BC
    ld (desired_map_offset+2),hl

    ;; calculate the offset for smooth scroll in MSX2
    ld a,(useSmoothScroll)
    and a   ;; equivalent to cp 0, but faster
    ret z
    ld a,l
    sra a
    sra a
    sra a
    sra a
    and #07
    ld (desired_horizontal_scroll_for_r18),a    

    ret
    

;-----------------------------------------------
; called when one of the player bullets hits a button (preserves af and ix)
player_bullet_hit_a_button:
    push af     ;; we preserve 'a'

    ld hl,SFX_button
    call play_SFX

    ld a,(ndoors)
    and a   ;; equivalent to cp 0, but faster
    jr z,player_bullet_hit_a_button_done

    ld c,0
    ld hl,doors
player_bullet_hit_a_button_loop:
    ld a,(hl)
    and a   ;; equivalent to cp 0, but faster
    jr z,player_bullet_hit_a_button_door_was_closed
player_bullet_hit_a_button_door_was_open:
    ld a,0
    ld (hl),a   ;; make the door closed
    inc hl
    ld e,(hl)
    inc hl
    ld d,(hl)
    inc hl
    ld a,PATTERN_DOOR_BEAM
    ld (de),a
    inc de
    ld (de),a
    inc de
    ld a,PATTERN_LEFT_DOOR
    ld (de),a
    inc de
    ld a,PATTERN_RIGHT_DOOR
    ld (de),a
    inc de
    ld a,PATTERN_DOOR_BEAM
    ld (de),a
    inc de
    ld (de),a
    inc de
    jr player_bullet_hit_a_button_door_continue

player_bullet_hit_a_button_door_was_closed:
    ld a,1
    ld (hl),a   ;; make the door open
    inc hl
    ld e,(hl)
    inc hl
    ld d,(hl)
    inc hl    
    ld a,PATTERN_LEFT_DOOR
    ld (de),a
    inc de
    xor a
    ld (de),a
    inc de
    ld (de),a
    inc de
    ld (de),a
    inc de
    ld (de),a
    inc de
    ld a,PATTERN_RIGHT_DOOR
    ld (de),a
    inc de

player_bullet_hit_a_button_door_continue:
    inc c
    ld a,(ndoors)
    cp c
    jr nz,player_bullet_hit_a_button_loop

player_bullet_hit_a_button_done:
    pop af
    ret


;-----------------------------------------------
; open/close the doors that depends on the ball
open_close_ball_doors:
    push af     ;; we preserve 'a'

    ld a,(nballdoors)
    and a   ;; equivalent to cp 0, but faster
    jr z,open_close_ball_doors_done

    ld c,0
    ld hl,balldoors
open_close_ball_doors_loop:
    ld a,(hl)
    and a   ;; equivalent to cp 0, but faster
    jr z,open_close_ball_doors_door_was_closed
open_close_ball_doors_door_was_open:
    ld a,0
    ld (hl),a   ;; make the door closed
    inc hl
    ld e,(hl)
    inc hl
    ld d,(hl)
    inc hl
    ld a,PATTERN_DOOR_BEAM
    ld (de),a
    inc de
    ld (de),a
    inc de
    ld a,PATTERN_LEFT_BALL_DOOR
    ld (de),a
    inc de
    ld a,PATTERN_RIGHT_DOOR
    ld (de),a
    inc de
    ld a,PATTERN_DOOR_BEAM
    ld (de),a
    inc de
    ld (de),a
    inc de
    jr open_close_ball_doors_door_continue

open_close_ball_doors_door_was_closed:
    ld a,1
    ld (hl),a   ;; make the door open
    inc hl
    ld e,(hl)
    inc hl
    ld d,(hl)
    inc hl    
    ld a,PATTERN_LEFT_BALL_DOOR
    ld (de),a
    inc de
    xor a
    ld (de),a
    inc de
    ld (de),a
    inc de
    ld (de),a
    inc de
    ld (de),a
    inc de
    ld a,PATTERN_RIGHT_DOOR
    ld (de),a
    inc de

open_close_ball_doors_door_continue:
    inc c
    ld a,(nballdoors)
    cp c
    jr nz,open_close_ball_doors_loop

open_close_ball_doors_done:
    pop af
    ret


;-----------------------------------------------
; renders the map to screeen
renderMap:

    ;; render scoreboard:
    ld hl,NAMTBL2
    call SETWRT
    ex de,hl
    ld hl,scoreboard
    ld b,32
    ld c,VDP_DATA
renderMap_scoreboard_loop:
    outi
    jp nz,renderMap_scoreboard_loop

    ;; calculate the offset in tiles
    ld de,(map_offset)   ;; y
    ; divide by 128: (multiply by 2, and then divide by 256)
    sla e
    rl d
    ld e,d
    ld d,0

    ld a,(current_map_dimensions+1)     ;; width of map
    call Mult_A_by_DE
    ld de,(map_offset+2)   ;; x
    ; divide by 128: (multiply by 2, and then divide by 256)
    sla e
    rl d
    ld e,d
    ld d,0

    add hl,de ;; now we have the starting offset position of the map in HL
    ex de,hl

    ld hl,currentMap
    add hl,de

    ; skip the first line (which is for the scoreboard)
    ld a,(current_map_dimensions+1)
    ld d,0
    ld e,a
    add hl,de

    sub 32
    ld e,a

    ld a,24-1
    ld c,VDP_DATA

renderMap_loop:
    ld b,32

renderMap_loop_internal:
    outi
;    outi
;    outi
;    outi
    jp nz,renderMap_loop_internal
    
	add hl,de

	dec a
    jp nz, renderMap_loop
    ret


;-----------------------------------------------
; executes one cycle of all the animations in the map
mapAnimationCycle:    
    ld a,(currentNAnimations)
    inc a
    ld b,a
    ld hl,currentAnimations

    ld a,(current_animation_frame)
    inc a
    ld (current_animation_frame),a

mapAnimationCycle_loop:        
    dec b
    ret z

    ;; consider only the odd tiles in odd frames, and even tiles in even frames
    ld a,(current_animation_frame)
    add a,b
    and #01
    jp z,mapAnimacionCycle_skip_this_tile

    push bc
    ld e,(hl)
    inc hl    ;; +1
    ld d,(hl) ;; map pointer
    inc hl    ;; +2
    push de 

    ld e,(hl)
    inc hl    ;; +3
    ld d,(hl) ;; animation definition pointer
    inc hl    ;; +4

    ;; get the animation step
    ex de,hl    ;; hl has now the animation definition pointer, de stores the current animation pointer
    ;; n animation steps
    ld b,(hl)
    inc hl
    ;; n animation period
    ld c,(hl)
    inc hl

    push bc
    inc de
    ld a,(de)   ;; we need to load the step into "bc", to be able to add it to hl
    ld c,a
    dec de
    ld b,0      ;; bc has the animation step now
    add hl,bc
    pop bc
    ld a,(hl)   ;; we get the animation pattern

    ex de,hl ;; we recover the pointer to the current animations in hl
    pop de
    ld (de),a

    ;; get timer
    ld a,(hl)
    inc a
    cp c
    jr nz,no_animation_change_yet
    ;; change the animation step:
    ld (hl),0
    inc hl      ;; +5
    ld a,(hl)
    inc a
    cp b
    jr nz,no_animaiton_overflow_yet
    ld (hl),0
    inc hl      ;; +6
    pop bc
    jr mapAnimationCycle_loop

no_animation_change_yet:
    ld (hl),a
    inc hl      ;; +5
    inc hl      ;; +6
    pop bc
    jr mapAnimationCycle_loop

no_animaiton_overflow_yet:
    ld (hl),a
    inc hl      ;; +6
    pop bc
    jr mapAnimationCycle_loop

mapAnimacionCycle_skip_this_tile:
    ld a,b
    ld bc,6
    add hl,bc
    ld b,a
    jr mapAnimationCycle_loop    

;-----------------------------------------------
; Map collision information:
; < 4 : no collision
; >=4 : collision
; 0 : empty
; 1 : fuel reload
; 4 : full collision
; 5 : temporary collision (e.g., lasers)
; 7 : button
; 8 : enemy
; 9 : tank
patterncollisiondata:
    db 0,9,9,9,9,9,8,8,8,8,8,8,8,8,8,8
    db 4,4,4,4,9,0,8,8,8,8,8,8,8,8,8,8
    db 0,0,0,0,0,0,0,4,0,0,0,0,0,0,0,0
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    db 0,0,0,0,0,0,0,0,0,0,0,4,4,4,4,4
    db 4,4,4,4,0,0,1,1,4,4,4,0,0,4,1,1
    db 7,7,7,7,7,7,4,4,4,4,0,4,4,0,0,4
    db 4,4,4,4,7,7,4,4,4,4,4,4,4,0,4,4
    db 4,4,4,4,4,4,4,4,4,0,0,4,4,0,0,4
    db 4,4,4,4,0,0,4,1,8,8,8,8,5,5,5,5
    db 4,4,4,4,4,4,4,4,8,8,8,8,5,5,5,5
    db 4,4,4,4,4,4,8,8,4,4,4,4,4,4,4,4
    db 4,4,4,4,4,4,8,8,4,4,4,4,8,8,0,0
    db 8,8,8,8,8,8,4,4,1,1,1,1,8,8,4,4
    db 8,8,8,8,8,8,4,4,0,0,0,0,5,5,4,4


;-----------------------------------------------
; Map animations
animations:
    db 130
    dw leftspike1
    db 131
    dw leftspike2
    db 136
    dw rightspike1
    db 137
    dw rightspike2
    db 134
    dw smallradar
    db 248
    dw redlight1
    db 249
    dw redlight2
    db 252
    dw horizontallaser
    db 253
    dw verticallaser
    db 0                ;; indicates the end

leftspike1:         db 130, 6,8, 130,131,0,0,0,131 
leftspike2:         db 131, 6,8, 131,0,0,0,0,0 
rightspike1:        db 136, 6,8, 136,0,0,0,0,0 
rightspike2:        db 137, 6,8, 137,136,0,0,0,136 
smallradar:         db 134, 4,4, 134,144,135,144
redlight1:          db 248, 2,25, 248,250   
redlight2:          db 249, 2,25, 249,251   
horizontallaser:    db 252, 2,50, 252,0
verticallaser:      db 253, 2,50, 253,0 


;-----------------------------------------------
; Map enemy definition
enemies:
    db 198      ;; normal cannon (up)
    dw normalCannonUp
    db 226      ;; normal cannon (right)
    dw normalCannonRight
    db 224      ;; normal cannon (down)
    dw normalCannonDown
    db 228      ;; normal cannon (left)
    dw normalCannonLeft

    db 14       ;; fast cannon (up)
    dw fastCannonUp
    db 8        ;; fast cannon (right)
    dw fastCannonRight
    db 12       ;; fast cannon (down)
    dw fastCannonDown
    db 10       ;; fast cannon (left)
    dw fastCannonLeft

    db 220       ;; directional cannon (up)
    dw directionalCannonUp
    db 168       ;; directional cannon (right)
    dw directionalCannonRight
    db 6         ;; directional cannon (down)
    dw directionalCannonDown
    db 170       ;; directional cannon (left))
    dw directionalCannonLeft

    db 0        ;; indicates the end


;; - enemy type: 0: enemy dead, 1: up cannon, 2: right cannon, 3: down cannon, 4: left cannon
;; - enemy health
;; - tiles that will replace the enemy after being killed (all enemies are assumed to be 2x2)
normalCannonUp:      db 1,  2,   0,0,96,97
                     dw -16,0
normalCannonRight:   db 2,  2,   93,0,93,0
                     dw 0,16
normalCannonDown:    db 3,  2,   91,92,0,0
                     dw 16,0
normalCannonLeft:    db 4,  2,   0,94,0,94
                     dw 0,-16

fastCannonUp:        db 1,  4,   0,0,96,97
                     dw -64,0
fastCannonRight:     db 2,  4,   93,0,93,0
                     dw 0,64
fastCannonDown:      db 3,  4,   91,92,0,0
                     dw 64,0
fastCannonLeft:      db 4,  4,   0,94,0,94
                     dw 0,-64

directionalCannonUp:        db 5,  6,   0,0,96,97
                            db -20,0,-12,12         ;; -dy,+dy,-dx,+dy of the area in which the player has to be to be fired at (in blocks)
directionalCannonRight:     db 6,  6,   93,0,93,0
                            db -12,12,0,20
directionalCannonDown:      db 7,  6,   91,92,0,0
                            db 0,20,-12,12
directionalCannonLeft:      db 8,  6,   0,94,0,94
                            db -12,12,-20,0


;-----------------------------------------------
; Map definition
; Maps are encoded using "run length encoding" (using 255 as the meta character) to save space
mappointers:
    dw map1,map2,map3,map4,map5,map6,map7,map8    ; put all the maps here
    dw map9,map10,map11,map12,map13,map14,map15,map16

mappasswords:
    db "TBLSTART"    ;; map 1
    db "CZIHAHNA"    ;; map 2
    db "QRKJHAUI"    ;; map 3
    db "UHEUERLS"    ;; map 4
    db "MSTCTEEV"    ;; map 5
    db "PLDJENZS"    ;; map 6
    db "AZTEZOCA"    ;; map 7
    db "CABLUNGT"    ;; map 8
    db "RETOSTAR"    ;; map 9
    db "WHIYUIOP"    ;; map 10
    db "ZSEDQWAV"    ;; map 11
    db "AUIOGTOI"    ;; map 12
    db "GTBVFHRF"    ;; map 13
    db "KMJIOGKL"    ;; map 14
    db "ZBNVNMXC"    ;; map 15
    db "AHDJFLLS"    ;; map 16
    db 0

map1:
    db 10,FUEL_UNIT
    db 36,32
    ;; number of animation tiles: 3
    db 255,0,255
    db 255,0,97
    db 104,255,0,28,134,0,0
    db 98,255,0,26,157,105,181,180,96
    db 98,255,0,25,156,181,160,161,161,160
    db 98,255,0,24,105,255,160,3,161,161,160
    db 98,255,0,24,94,160,161,161,182,161,160,160
    db 96,100,255,0,22,94,161,160,161,160,161,161
    db 160,98,255,0,23,94,255,160,3,161,161,160
    db 176,98,255,0,23,94,162,163,255,161,4
    db 176,98,255,0,23,94,178,179,160,161,160,161
    db 160,98,255,0,23,149,91,92,160,160,161,160,160
    db 98,255,0,26,149,160,161,161
    db 160,98,255,0,27,99,160,161
    db 160,98,255,0,27,99,161,161
    db 160,160,104,255,0,26,149,160,161
    db 160,160,98,255,0,27,99,161
    db 182,160,98,255,0,27,99,161
    db 160,160,98,255,0,27,99,160
    db 176,160,98,0,248,249,255,0,24,99,160
    db 176,160,98,255,231,4,202,255,0,6,146,147,148,255,0,13,99,160
    db 176,160,98,255,0,4,230,255,0,7,230,255,0,5,126,127,255,0,7,99,160
    db 176,160,98,255,0,4,230,255,0,7,230,255,0,4,122,123,124,125,255,0,4,101,97,160,160
    db 161,176,160,97,97,104,0,230,255,0,7,230,255,0,4,138,139,140,141,0,0,101,181,96,255,160,4
    db 176,176,255,160,3,255,96,4,255,97,7,96,96,97,181,160,160,180,96,181,96,160,160,176,161,255,160,3
    db 182,176,255,160,5,255,161,5,160,160,161,160,160,182,255,160,6,255,161,4,255,160,5
    db 161,176,255,160,8,176,160,160,255,176,5,160,176,160,160,176,161,160,160,176,160,160
    ;; Run-length encoding (size: 347)

map2:
    db 10,FUEL_UNIT
    db 36,32
    ;; number of animation tiles: 3
    db 255,0,255
    db 255,0,97
    db 104,255,0,28,134,0,0
    db 98,255,0,26,157,105,181,180,96
    db 98,255,0,25,156,181,160,161,161,160
    db 98,255,0,22,157,158,159,255,160,3,161,161,160
    db 98,255,0,10,248,249,0,164,165,255,0,5,101,96,96,255,160,3,161,161,160,161,160,160
    db 96,100,255,0,5,101,96,97,181,180,97,180,181,96,104,0,101,96,97,255,160,3,161,161,160,161,160,161,161
    db 160,98,255,0,7,99,255,161,3,255,160,5,96,96,161,161,160,161,161,255,160,4,161,161,160
    db 176,98,255,0,7,99,160,160,162,163,160,161,160,161,160,160,255,161,4,160,160,162,163,255,161,4
    db 176,98,255,0,7,149,91,91,178,179,160,161,161,166,161,161,160,255,161,3,160,160,178,179,160,161,160,161
    db 160,98,255,0,10,149,92,91,160,160,166,183,160,161,160,255,92,6,160,160,161,160,160
    db 98,255,0,13,149,255,91,3,92,92,95,255,0,6,149,160,161,161
    db 160,98,255,0,27,99,160,161
    db 160,98,255,0,27,99,161,161
    db 160,160,104,255,0,26,149,160,161
    db 160,160,98,255,0,27,99,161
    db 160,160,98,255,0,27,99,161
    db 160,160,98,255,0,21,146,147,148,255,0,3,99,160
    db 176,160,98,255,0,22,230,255,0,4,99,160
    db 176,160,98,255,0,22,207,231,202,0,0,99,160
    db 176,160,98,255,0,11,126,127,255,0,9,247,0,230,0,0,99,160
    db 176,160,98,255,0,10,122,123,124,125,255,0,8,230,0,230,101,97,160,160
    db 161,176,160,97,97,104,255,0,7,138,139,140,141,255,0,8,230,101,181,96,255,160,4
    db 176,176,255,160,3,255,96,4,255,97,3,181,151,150,180,96,96,97,255,96,5,181,96,160,160,176,161,255,160,3
    db 166,176,255,160,5,255,161,5,160,160,161,255,160,9,255,161,4,255,160,5
    db 161,176,255,160,8,176,160,160,176,166,255,176,3,160,176,160,160,176,161,160,160,176,160,160
    ;; Run-length encoding (size: 433)

map3:
    db 10,FUEL_UNIT
    db 36,32
    ;; number of animation tiles: 22
    db 255,0,255
    db 255,0,97
    db 104,255,0,28,248,249,0
    db 98,255,0,26,157,105,181,180,96
    db 98,255,0,25,156,181,160,161,161,160
    db 98,255,0,24,105,255,160,3,161,161,160
    db 98,255,0,24,94,160,161,161,160,161,160,160
    db 96,100,255,0,22,94,161,160,161,160,182,161
    db 160,98,255,0,23,94,255,160,3,161,161,160
    db 176,98,255,0,23,94,162,163,255,161,4
    db 176,98,255,0,23,94,178,179,160,161,160,161
    db 160,98,255,0,22,105,255,161,3,160,160,161,160,160
    db 161,255,97,3,100,255,0,18,255,161,5,160,161,161
    db 160,161,160,160,128,255,252,19,129,255,161,5,160,161
    db 160,161,161,160,93,255,0,19,94,161,177,161,161,177,161,161
    db 160,255,161,3,93,255,0,19,94,161,177,161,177,183,160,161
    db 160,160,161,161,93,255,0,19,94,177,161,161,177,177,161,161
    db 160,160,183,161,93,255,0,19,99,177,255,161,3,177,161,161
    db 160,160,255,161,3,97,100,255,0,17,99,177,161,161,182,177,161,160
    db 176,160,255,161,3,93,255,0,15,105,97,97,161,177,255,161,3,177,161,160
    db 176,255,161,5,97,100,134,255,0,5,146,147,148,255,0,4,99,255,161,3,183,161,161,177,161,161,160
    db 176,255,161,6,255,97,3,100,255,0,4,230,255,0,5,99,255,161,3,182,255,177,3,161,161,160
    db 176,160,166,255,161,6,93,255,0,5,230,255,0,3,101,97,255,161,3,177,161,161,162,163,161,161,160
    db 161,176,182,183,255,161,5,93,0,0,164,165,0,230,255,0,4,99,255,161,3,255,177,3,178,179,161,255,160,3
    db 176,176,160,255,161,6,96,97,180,181,255,97,3,96,96,97,161,160,255,161,6,160,176,161,255,160,3
    db 161,176,255,160,5,255,161,5,160,183,161,255,160,5,182,255,160,3,255,161,4,255,160,5
    db 161,176,255,160,8,176,160,160,255,176,5,160,176,160,160,176,161,160,160,176,160,160
    ;; Run-length encoding (size: 429)

map4:
    db 10,FUEL_UNIT
    db 40,44
    ;; number of animation tiles: 26
    db 255,0,255
    db 255,0,214
    db 142,143,196,197,255,0,40
    db 192,193,194,195,255,0,3,134,255,0,9
    db 248,249,255,0,8,248,249,0,101,255,97,3,255,96,6,97,97,104,0,208,209,210,211,101,96,96,255,97,3,100,255,0,4
    db 97,255,96,3,97,100,255,0,4,101,96,255,97,4,255,161,12,97,181,161,161,180,96,255,161,5,97,97,96,97,97
    db 255,161,4,93,255,0,6,94,255,161,11,162,163,255,161,6,255,176,3,255,161,12
    db 91,91,95,255,0,6,149,255,91,4,255,161,7,178,179,255,161,4,176,176,161,161,176,176,255,161,3,255,160,4,176,160
    db 161,93,255,0,14,94,255,161,10,255,176,3,161,182,161,160,176,255,160,3,162,163,160,160,176,160
    db 161,93,255,0,14,149,91,255,161,6,255,176,3,160,255,161,4,160,160,255,176,4,178,179,176,160,176,160
    db 161,226,227,255,0,15,149,91,161,161,255,160,4,255,161,6,255,160,10,176,160
    db 161,242,243,255,0,17,149,255,92,3,238,92,92,238,255,91,3,255,92,7,255,160,4,176,176
    db 161,93,255,0,22,253,0,0,253,255,0,10,149,91,91,255,160,3
    db 161,93,255,0,22,253,0,0,253,255,0,13,94,160,160
    db 161,93,255,0,22,253,0,0,253,255,0,13,94,255,160,3
    db 93,255,0,22,253,0,0,253,255,0,13,94,160,160
    db 176,93,255,0,22,253,0,0,253,255,0,13,94,160,160
    db 176,161,97,100,255,0,20,253,0,0,253,255,0,13,94,255,160,3
    db 161,161,97,106,255,0,19,253,0,0,253,255,0,13,94,255,160,3
    db 255,161,4,97,100,255,0,17,253,0,0,253,255,0,13,94,255,160,3
    db 255,161,5,180,104,154,255,0,15,253,0,0,253,255,0,13,94,182,160,160
    db 255,161,7,180,97,96,97,106,107,255,0,10,253,0,0,253,255,0,13,94,255,160,3
    db 255,161,13,97,180,106,107,255,0,3,164,165,0,253,156,97,254,97,100,255,0,11,94,255,160,4
    db 161,162,163,161,161,176,255,161,9,150,180,97,96,180,181,97,254,151,255,161,3,97,100,255,0,10,94,255,160,4
    db 161,178,179,161,161,176,255,161,3,176,176,255,161,16,93,255,0,11,94,255,160,4
    db 255,161,5,176,161,182,161,161,176,255,161,16,93,255,0,4,146,147,148,255,0,4,94,160,160
    db 176,160,255,161,5,176,255,161,5,176,176,255,161,14,93,255,0,5,230,255,0,5,94,160,160
    db 161,160,255,161,3,176,176,255,161,13,162,163,255,161,7,93,255,0,5,230,255,0,3,101,97,255,160,3
    db 255,161,5,176,255,161,10,182,255,161,3,178,179,255,161,8,96,100,255,0,3,230,0,0,101,96,255,160,4
    db 176,160,255,161,3,176,255,161,4,162,163,255,161,18,93,255,0,4,230,255,0,3,94,255,160,4
    db 161,176,255,161,8,178,179,255,161,15,182,161,160,160,97,97,255,96,3,255,97,3,255,160,6
    db 176,176,255,161,24,160,160,176,161,160,160,182,255,160,10
    ;; Run-length encoding (size: 669)

map5:
    db 10,FUEL_UNIT
    db 44,48
    ;; number of animation tiles: 28
    db 255,0,255
    db 255,0,255
    db 255,0,66
    db 96,96,106,255,0,17,134,255,0,8,109,255,96,11,106,0,101,97,255,96,3
    db 161,161,93,255,0,11,248,249,0,108,109,96,180,181,255,96,8,255,160,11,255,96,3,161,160,255,161,5
    db 106,255,0,9,105,181,181,96,255,161,3,255,160,3,255,161,8,160,161,161,162,163,255,160,3,255,161,12
    db 93,255,0,8,105,151,255,161,4,160,255,161,4,255,160,4,161,161,255,160,5,178,179,160,160,255,161,13
    db 93,255,0,7,105,151,255,161,7,255,160,3,255,161,18,255,160,4,255,161,5
    db 160,161,106,255,0,5,105,151,255,161,6,255,160,3,255,161,4,255,91,5,238,255,91,3,255,161,4,255,91,6,160,255,161,4
    db 160,160,161,161,106,255,0,4,94,255,161,3,162,163,161,160,160,255,161,4,91,95,255,0,5,253,255,0,3,149,91,91,95,255,0,6,149,255,161,4
    db 160,160,161,161,93,255,0,4,94,255,161,3,178,179,160,255,161,3,91,91,95,255,0,7,253,255,0,14,149,255,161,4
    db 160,160,161,93,255,0,4,94,161,161,160,255,161,5,95,255,0,10,253,255,0,15,94,161
    db 160,161,160,161,161,95,255,0,4,149,161,161,160,255,161,4,93,255,0,11,253,255,0,15,94,161
    db 160,162,163,161,93,255,0,6,94,161,160,255,161,4,93,255,0,11,253,255,0,12,219,212,213,161,161
    db 160,178,179,161,93,255,0,6,94,161,160,161,161,160,161,93,255,0,11,253,255,0,15,94,161
    db 160,255,161,3,95,255,0,6,94,255,161,3,255,160,3,93,255,0,11,253,255,0,15,94,160
    db 255,161,3,93,255,0,7,94,255,161,4,160,160,93,255,0,8,108,109,97,254,97,106,107,255,0,12,94,160
    db 255,161,3,95,255,0,6,109,255,161,3,177,255,160,3,93,255,0,7,105,255,161,7,255,0,12,94,160
    db 161,161,93,255,0,7,94,161,161,160,162,163,161,177,118,119,130,131,255,0,4,94,161,161,177,160,161,161,93,255,0,12,94,160
    db 161,161,93,255,0,7,94,255,161,3,178,179,177,161,93,255,0,7,94,161,161,162,163,160,161,161,106,255,0,11,94,255,161,3
    db 128,255,252,7,129,255,161,7,93,255,0,7,94,161,161,178,179,255,161,3,93,255,0,11,94,160
    db 161,161,93,255,0,7,149,92,255,161,6,95,255,0,4,136,137,120,121,161,161,177,160,160,161,161,93,255,0,5,146,147,148,255,0,3,94,160
    db 161,161,93,255,0,9,149,92,238,92,92,95,255,0,8,94,161,161,177,160,255,161,3,93,255,0,6,230,255,0,4,94,255,161,3
    db 93,255,0,11,253,255,0,11,149,91,255,161,3,160,255,161,3,106,255,0,5,230,255,0,4,94,255,161,3
    db 93,255,0,11,253,255,0,13,149,91,161,161,160,161,161,93,255,0,5,247,255,0,4,94,255,161,3
    db 93,255,0,11,253,255,0,15,149,161,160,177,161,161,106,255,0,4,230,0,101,96,96,160,255,161,4
    db 106,255,0,10,253,255,0,16,94,161,177,255,161,3,96,106,0,0,230,0,0,161,161,160,255,161,3
    db 177,98,255,0,10,253,255,0,16,94,161,177,161,161,160,161,161,255,96,5,161,161,160,161,161
    db 160,177,150,152,153,255,0,8,253,255,0,14,101,97,161,161,177,161,255,160,4,255,161,5,160,161,160,161,161
    db 160,177,255,161,3,152,153,255,0,6,253,255,0,13,101,97,161,161,177,161,160,160,161,161,160,255,161,4,255,160,4,255,161,3
    db 177,160,160,255,161,3,152,153,164,165,101,97,254,255,97,6,106,107,255,0,4,101,97,255,161,5,160,161,255,160,3,255,161,5,160,177,255,161,5
    db 177,161,160,255,161,4,180,181,97,255,161,10,255,97,5,255,161,4,177,166,161,161,160,161,255,160,6,161,177,177,255,161,4
    db 177,255,161,13,255,177,3,255,160,12,177,182,183,255,161,11,177,255,161,16
    db 177,177,255,161,3,177,255,161,11,177,255,161,13,177,255,161,16
    db 177,255,161,29,177,161,161
    ;; Run-length encoding (size: 906)

map6:
    db 10,FUEL_UNIT
    db 46,48
    ;; number of animation tiles: 12
    db 255,0,255
    db 255,0,161
    db 248,249,255,0,7,164,165,0,0,255,97,3
    db 255,0,29,105,181,255,97,10,180,181,97,97,255,160,3
    db 97,97,96,100,255,0,3,164,165,255,0,4,248,249,255,0,13,228,229,255,160,19
    db 161,161,255,97,4,180,181,255,97,7,96,100,255,0,10,244,245,255,160,5,255,161,4,255,160,5,166,255,160,4
    db 176,160,255,161,9,255,160,4,161,255,97,3,106,255,0,6,101,96,161,255,160,5,166,255,161,9,255,160,4
    db 176,255,160,5,255,177,7,161,255,160,5,98,255,0,7,94,255,160,15,161,255,160,3
    db 176,255,160,4,176,176,160,160,255,161,5,255,177,3,255,161,3,150,155,255,0,6,149,224,225,255,92,12,160,161,255,160,3
    db 176,160,160,162,163,160,160,176,176,255,160,4,161,161,160,177,182,160,161,161,93,255,0,7,240,241,255,0,12,149,161,255,160,3
    db 176,160,160,178,179,160,160,161,160,176,176,160,255,161,5,177,176,160,160,93,255,0,23,94,255,160,5
    db 177,161,160,161,161,182,161,160,166,160,161,255,160,3,161,176,177,160,93,255,0,23,94,255,160,4
    db 177,160,160,255,161,3,160,160,255,161,4,176,255,160,3,161,176,160,93,255,0,23,94,255,160,3
    db 177,161,160,161,161,160,160,255,161,3,160,255,161,3,176,160,162,163,176,160,150,155,255,0,9,126,127,255,0,11,99,160,160
    db 176,177,161,160,161,160,161,161,160,160,255,161,3,160,161,176,177,178,179,176,176,161,160,180,100,255,0,6,122,123,124,125,255,0,10,99,166,160
    db 176,160,182,161,160,160,255,161,8,160,160,255,176,3,160,176,160,161,160,255,97,3,96,100,0,0,138,139,140,141,255,0,10,94,177,255,160,3
    db 161,255,177,12,255,160,4,255,176,4,161,255,160,4,255,97,3,181,160,160,180,97,96,100,255,0,7,99,177,255,160,4
    db 161,160,255,161,4,162,163,255,177,3,160,160,182,255,160,3,255,161,3,176,161,160,160,255,161,5,160,160,161,161,128,255,252,8,129,177,255,160,5
    db 255,161,5,178,179,255,160,5,255,161,4,255,160,4,255,176,7,161,161,160,161,161,93,255,0,8,94,177,255,160,8
    db 177,255,161,8,255,160,12,176,176,160,161,161,160,161,161,95,255,0,8,94,177,255,160,5
    db 166,177,177,161,255,160,9,255,92,16,224,225,95,255,0,5,101,255,97,3,160,177,255,160,5
    db 166,160,160,161,255,160,6,224,225,95,255,0,16,240,241,255,0,7,94,160,160,177,255,160,7
    db 161,161,160,160,92,224,225,92,95,240,241,255,0,26,94,160,160,177,255,160,6
    db 161,160,160,92,95,0,240,241,255,0,27,101,97,97,255,160,3,177,255,160,4
    db 255,161,3,160,95,255,0,32,228,229,255,160,3,177,255,160,3
    db 176,161,255,160,3,95,255,0,33,244,245,255,160,3,177,255,160,3
    db 176,160,182,160,93,255,0,35,94,255,160,3,177,176,166,160
    db 176,160,177,160,93,255,0,32,101,96,96,255,161,3,177,177,176,161,160
    db 161,176,177,160,93,255,0,33,94,161,255,160,3,177,161,176,161,160,160
    db 176,177,160,93,255,0,33,94,160,161,255,160,3,176,160,161,255,160,3
    db 177,160,93,255,0,33,94,160,160,161,160,160,176,161,160,160
    db 161,160,177,160,93,255,0,27,105,255,97,5,177,162,163,160,161,160,176,161,160,160
    db 161,160,177,160,93,255,0,24,164,165,0,94,160,160,176,177,182,160,178,179,160,161,160,176,161,160,160
    db 161,177,177,166,160,106,153,255,0,19,101,96,96,180,181,96,160,160,177,176,160,255,161,7,176,161,255,160,3
    db 177,161,255,160,3,93,255,0,4,142,143,196,197,255,0,4,146,147,148,255,0,5,94,255,160,6,177,176,161,255,160,5,161,162,163,176,160,160
    db 177,177,161,255,160,3,150,152,153,154,0,192,193,194,195,255,0,5,230,255,0,6,94,255,160,4,166,160,177,160,176,255,160,4,176,176,178,179,161,255,160,3
    db 177,177,255,160,5,150,106,0,208,209,210,211,255,0,5,230,255,0,6,94,255,160,5,177,255,160,3,255,176,4,161,160,161,161,255,160,5
    db 161,255,177,3,255,160,4,96,181,160,160,180,96,100,255,0,3,230,255,0,6,94,255,160,4,177,255,160,7,255,161,3,255,160,11
    db 255,177,5,255,160,5,255,96,11,255,160,5,177,255,160,47
    db 177,255,160,15
    ;; Run-length encoding (size: 984)

map7:
    db 10,FUEL_UNIT
    db 52,48
    ;; number of animation tiles: 16
    db 255,0,255
    db 255,0,173
    db 134,255,0,44
    db 105,181,96,180,181,96,96
    db 255,0,40,105,160,161,255,160,4,177
    db 104,255,0,30,248,249,255,0,7,99,160,177,161,160,177,161,161
    db 160,255,0,27,105,97,97,181,180,104,255,0,6,99,255,160,3,161,177,182,177
    db 160,255,0,25,156,181,160,161,161,160,160,98,255,0,6,149,255,92,3,255,160,5
    db 255,0,22,157,158,159,160,161,160,161,161,160,160,98,255,0,10,99,160,160,161
    db 160,0,0,134,255,0,7,248,249,0,164,165,255,0,5,101,96,96,160,160,177,160,255,161,4,160,98,255,0,10,149,160,161,161
    db 160,96,97,180,181,255,97,4,96,97,181,180,97,180,181,96,104,0,101,96,97,160,160,177,177,160,160,177,160,160,177,177,98,255,0,11,99,255,160,3
    db 177,255,161,3,255,177,3,161,161,177,255,160,7,96,96,160,160,161,161,177,255,160,4,177,182,160,160,98,255,0,11,99,255,160,3
    db 255,161,4,166,255,161,3,177,177,160,162,163,160,160,161,255,160,5,161,160,161,160,162,163,160,160,161,161,160,226,227,255,0,10,99,160,161
    db 160,161,177,161,161,182,183,161,161,160,160,161,178,179,161,161,255,160,5,161,160,161,161,160,178,179,160,160,161,160,160,242,243,255,0,9,228,229,161,160
    db 255,161,9,255,160,8,166,161,255,160,3,255,161,5,160,160,161,255,160,3,98,255,0,10,244,245,255,160,3
    db 161,255,92,7,161,160,177,160,255,176,3,161,182,183,161,160,160,91,255,92,4,91,91,255,160,4,98,255,0,11,99,255,160,3
    db 98,255,0,7,149,91,92,91,160,160,176,160,160,91,238,91,95,255,0,7,99,255,160,3,98,255,0,11,99,177,177
    db 160,98,255,0,11,149,91,92,91,95,0,253,255,0,9,99,161,160,160,98,255,0,11,99,160,161
    db 160,160,104,255,0,16,253,255,0,9,149,160,177,160,160,212,213,202,255,0,8,99,161,255,160,3
    db 98,255,0,16,253,255,0,10,99,177,160,98,0,0,230,255,0,8,99,160,177
    db 161,177,98,255,0,16,253,255,0,10,99,177,161,98,0,0,230,255,0,8,99,161,161
    db 177,160,98,255,0,16,253,255,0,4,146,147,148,255,0,3,99,160,160,98,0,203,201,255,0,8,99,255,160,3
    db 161,98,255,0,16,253,255,0,5,230,255,0,4,99,160,161,98,0,247,255,0,9,99,177,160,160
    db 161,98,255,0,16,253,255,0,5,207,231,202,0,0,99,177,160,98,0,230,255,0,9,99,160,161
    db 160,160,98,255,0,11,126,127,255,0,3,253,255,0,5,247,0,230,0,0,99,160,160,161,96,181,100,255,0,8,99,161,161
    db 160,160,98,255,0,10,122,123,124,125,0,0,253,255,0,5,230,0,230,101,96,255,160,5,98,255,0,9,99,160,160
    db 161,160,160,97,180,100,255,0,7,138,139,140,141,0,0,253,255,0,5,230,101,180,96,255,160,3,161,161,160,98,255,0,9,99,161,160,160
    db 255,161,3,93,255,0,5,101,97,97,181,151,150,180,96,96,254,255,96,5,181,96,160,160,161,161,160,161,161,160,98,255,0,8,105,161,161,160
    db 182,160,161,161,160,231,231,239,255,255,1,231,231,255,161,3,255,176,3,255,160,4,255,176,4,160,161,161,255,177,3,161,161,177,160,98,255,0,8,94,161,160,160
    db 176,161,176,160,95,255,0,6,149,255,91,5,161,255,91,3,255,160,3,176,160,161,177,161,182,255,161,3,160,160,98,231,239,255,0,4,255,255,1,231,94,161,176,161
    db 176,161,161,160,255,0,13,230,255,0,3,149,91,160,160,255,176,4,160,176,161,255,160,3,95,255,0,8,149,92,160,160
    db 161,177,160,95,255,0,13,230,255,0,5,149,91,160,255,91,3,255,160,4,91,95,255,0,11,99,176
    db 161,177,98,255,0,14,204,231,231,202,255,0,4,230,255,0,3,149,224,225,95,255,0,13,99,160
    db 161,160,98,255,0,17,230,255,0,4,230,255,0,4,240,241,255,0,14,99,160,160
    db 177,98,255,0,16,219,246,231,216,217,231,201,255,0,20,99,176
    db 161,160,98,255,0,43,99,160
    db 161,160,98,255,0,43,99,160,160
    db 177,98,255,0,42,105,160,176
    db 161,177,160,104,255,0,40,105,160,176,176
    db 160,177,160,98,255,0,27,142,143,196,197,255,0,9,99,160,176,176
    db 160,161,160,161,104,255,0,26,192,193,194,195,255,0,8,105,255,160,4
    db 176,176,177,176,160,160,106,107,0,0,198,199,255,0,19,208,209,210,211,255,0,8,99,255,176,3,160,160
    db 161,160,176,255,160,4,96,96,214,215,255,96,5,112,113,255,96,4,104,255,0,5,105,97,181,151,150,180,97,100,255,0,4,105,97,160,176,161,160,160
    db 161,161,176,176,182,161,161,160,160,176,160,176,255,160,3,176,255,160,3,161,160,176,160,160,255,97,5,160,160,161,161,255,160,3,255,97,5,255,160,3,176,161,255,160,3
    db 161,160,176,177,176,177,176,255,160,3,161,176,161,160,161,182,161,176,160,161,176,255,160,3,255,161,3,176,176,160,160,255,161,4,255,160,7,161,176,161,161,255,160,3
    db 161,161,255,160,3,255,176,3,161,176,161,255,160,3,176,255,160,4,161,176,176,161,161,160,161,176,160,160,161,182,255,160,3,161,160,161,161,160,160,161,161,255,160,4
    ;; Run-length encoding (size: 1190)

map8:
    db 10,FUEL_UNIT
    db 36,40
    ;; number of animation tiles: 4
    db 255,0,255
    db 255,0,74
    db 248,249,255,0,18,164,165,255,0,9
    db 96,96,100,255,0,4,101,96,181,180,96,100,0,0,134,255,0,11,101,96,180,181,96,100,255,0,4,101,96,96
    db 176,93,255,0,6,94,255,161,3,96,96,97,180,104,255,0,8,105,96,96,255,161,3,93,255,0,6,94,160
    db 176,93,255,0,6,94,255,161,8,97,97,100,134,157,158,159,96,255,161,6,226,227,255,0,5,94,161
    db 176,93,255,0,6,94,161,161,162,163,255,161,6,255,96,3,151,255,161,8,242,243,255,0,5,94,160
    db 161,93,255,0,6,94,161,161,178,179,255,161,16,182,161,93,255,0,6,94,182
    db 176,93,255,0,6,94,255,161,22,93,255,0,6,94,160
    db 161,93,255,0,6,94,255,161,14,162,163,255,161,6,93,255,0,6,94,161,161
    db 93,255,0,6,94,160,255,161,5,182,255,161,7,178,179,255,161,6,93,255,0,6,94,161,161
    db 93,255,0,6,94,160,161,160,255,161,19,226,227,255,0,5,94,161,161
    db 93,255,0,6,94,160,161,160,255,91,16,255,160,3,242,243,255,0,5,94,161,161
    db 93,255,0,6,94,160,161,93,255,0,16,94,160,160,93,255,0,6,94,160
    db 176,93,255,0,6,94,160,161,93,255,0,16,94,160,160,93,255,0,6,94,160
    db 176,176,39,255,0,4,255,255,1,255,160,3,93,255,0,16,94,255,160,3,231,231,239,255,255,1,231,231,160,160
    db 176,93,255,0,6,94,160,160,93,255,0,16,94,160,160,93,255,0,6,94,182
    db 176,93,255,0,6,149,91,91,95,255,0,16,149,91,91,95,255,0,6,94,160
    db 176,93,255,0,36,94,160
    db 161,226,227,255,0,35,94,160
    db 161,242,243,255,0,35,94,161
    db 177,93,255,0,36,94,161
    db 177,93,0,0,146,147,148,255,0,31,94,177,177
    db 93,255,0,3,230,255,0,32,94,177
    db 161,93,255,0,3,230,255,0,28,198,199,0,0,94,177
    db 161,161,96,96,97,96,96,97,96,96,180,104,255,0,4,1,2,255,0,10,105,112,113,255,96,3,214,215,97,97,160,160
    db 255,161,3,255,177,6,160,160,93,255,0,3,16,17,18,19,255,0,9,94,255,160,11
    db 255,161,4,182,255,161,3,177,255,161,3,255,96,3,97,255,96,3,255,97,6,255,96,3,255,161,6,162,163,161,161,160,160
    db 161,161,177,255,161,9,255,160,3,255,161,19,178,179,161,161,160,160
    db 255,161,10,182,255,161,29
    ;; Run-length encoding (size: 546)

map9:
    db 3,FUEL_UNIT
    db 56,54
    ;; number of animation tiles: 13
    db 255,0,255
    db 255,0,244
    db 164,165,255,0,7,248,249,255,0,11,248,249,255,0,7,164,165,255,0,8
    db 96,96,100,255,0,5,105,181,255,96,3,180,181,255,96,10,180,104,255,0,5,101,255,96,11,180,181,255,96,8
    db 160,93,255,0,6,94,255,160,8,183,255,160,8,93,255,0,6,94,255,160,21
    db 93,255,0,6,94,160,160,255,91,8,224,225,255,91,3,160,160,93,255,0,6,149,255,91,14,224,225,91,91,255,160,3
    db 93,255,0,6,94,160,93,255,0,8,240,241,255,0,3,94,160,93,255,0,21,240,241,0,0,94,160,160
    db 93,255,0,6,94,160,93,255,0,13,94,160,93,255,0,25,94,160
    db 183,226,227,255,0,5,94,160,93,255,0,13,94,160,93,255,0,25,94,160,160
    db 242,243,255,0,5,94,160,93,255,0,13,94,160,93,255,0,25,94,160,160
    db 93,255,0,6,94,160,93,255,0,13,94,183,226,227,255,0,24,94,160,160
    db 93,255,0,6,94,160,93,255,0,13,94,160,242,243,255,0,10,142,143,196,197,255,0,10,94,160,160
    db 93,255,0,6,94,183,93,0,0,146,147,148,255,0,8,94,160,93,255,0,11,192,193,194,195,255,0,10,94,160,160
    db 93,255,0,6,94,160,93,255,0,3,230,255,0,9,94,160,93,255,0,11,208,209,210,211,255,0,10,99,183
    db 160,93,255,0,6,94,160,93,255,0,3,230,255,0,9,94,160,160,255,96,17,180,104,255,0,6,99,160,160
    db 93,255,0,6,94,160,160,255,231,3,201,255,0,9,94,255,160,20,93,255,0,6,99,160,160
    db 226,227,255,0,5,94,160,93,255,0,13,149,255,91,4,255,160,6,255,91,8,160,160,93,255,0,6,94,160,160
    db 242,243,255,0,5,94,160,93,255,0,18,149,92,92,238,92,95,255,0,8,94,160,93,255,0,6,94,160,160
    db 93,255,0,6,94,160,226,227,255,0,20,253,255,0,10,94,160,93,255,0,6,94,160
    db 182,93,255,0,6,94,160,242,243,255,0,20,253,255,0,10,94,160,93,255,0,6,94,160,160
    db 93,255,0,6,94,160,93,255,0,21,253,255,0,9,10,11,182,93,255,0,6,94,160,160
    db 93,255,0,6,94,160,93,255,0,21,253,255,0,9,26,27,160,93,255,0,6,99,160,160
    db 93,255,0,5,228,229,160,93,255,0,21,253,255,0,10,94,160,93,255,0,6,94,160,160
    db 93,255,0,5,244,245,160,93,255,0,21,253,255,0,10,94,160,93,255,0,6,94,160,160
    db 93,255,0,6,94,160,93,0,0,134,0,0,164,165,255,0,14,253,0,134,0,0,164,165,255,0,4,94,160,93,255,0,6,94,160,160
    db 93,255,0,6,94,160,160,255,96,5,180,181,255,96,6,100,255,0,5,105,181,254,255,96,4,180,181,255,96,4,160,160,93,255,0,6,94,160,160
    db 93,255,0,6,94,255,160,14,93,255,0,6,94,255,160,4,182,255,160,9,98,255,0,6,94,160,160
    db 93,255,0,6,94,160,162,163,255,160,11,93,255,0,6,149,255,91,12,160,160,98,255,0,6,99,160,160
    db 93,255,0,6,94,160,178,179,255,160,11,93,255,0,19,94,160,98,255,0,6,99,160,160
    db 93,255,0,6,94,255,160,14,93,255,0,19,94,160,98,255,0,6,99,160,160
    db 98,255,0,6,94,255,160,14,98,255,0,19,94,160,93,255,0,6,99,160,160
    db 98,255,0,6,94,255,160,14,98,255,0,19,94,160,93,255,0,6,94,160,160
    db 98,255,0,6,94,255,160,9,162,163,255,160,3,98,255,0,19,94,160,93,255,0,6,94,160,160
    db 98,255,0,6,94,255,160,9,178,179,255,160,3,98,255,0,19,94,160,93,255,0,6,94,160,160
    db 98,255,0,6,94,255,160,14,98,255,0,19,94,160,93,255,0,6,94,160,160
    db 93,255,0,6,149,255,91,12,160,160,93,255,0,19,94,160,93,255,0,6,94,160,160
    db 93,255,0,11,230,255,0,4,230,0,0,94,160,93,255,0,19,149,91,95,255,0,6,94,160,160
    db 93,255,0,11,207,255,231,4,205,0,0,94,160,93,255,0,28,94,160,160
    db 98,255,0,11,255,167,6,0,0,94,160,98,255,0,28,94,160,160
    db 93,255,0,11,255,167,6,0,0,94,160,93,255,0,28,99,160,160
    db 93,255,0,11,167,102,103,232,233,167,0,0,94,160,93,255,0,28,94,160,160
    db 93,255,0,11,167,110,111,234,235,167,0,0,94,160,93,255,0,19,105,181,96,100,255,0,5,94,160,160
    db 93,255,0,11,255,167,6,0,0,94,160,93,255,0,19,94,160,93,255,0,6,94,160,160
    db 93,255,0,11,255,167,6,0,0,94,160,93,255,0,19,94,160,93,255,0,6,94,160,160
    db 150,106,107,255,0,9,207,255,231,4,205,0,0,94,160,93,255,0,19,94,183,93,255,0,6,94,160,160
    db 176,176,150,152,153,154,255,0,6,230,255,0,4,230,0,0,94,160,93,255,0,8,1,2,255,0,9,94,160,93,255,0,6,94,255,160,3
    db 255,176,4,255,96,15,160,160,93,255,0,7,16,17,18,19,255,0,8,94,160,93,255,0,6,94,255,160,3
    db 183,255,160,21,255,96,19,255,160,3,255,96,6,255,160,18
    db 183,255,160,19,183,255,160,17
    ;; Run-length encoding (size: 1170)

map10:
    db 10,FUEL_UNIT
    db 44,54
    ;; number of animation tiles: 24
    db 255,0,255
    db 255,0,245
    db 164,165,255,0,13,164,165,255,0,4,248,249,255,0,16,134
    db 255,0,6,101,255,96,7,180,181,255,96,13,180,181,255,96,4,181,180,96,100,255,0,13,109,181
    db 96,100,255,0,5,149,255,160,13,255,91,13,161,161,160,93,255,0,14,94,160,160
    db 104,255,0,6,94,255,160,3,182,255,160,4,162,163,160,93,255,0,13,149,161,161,93,255,0,4,203,231,212,213,231,216,217,231,212,213,255,160,4
    db 104,255,0,5,149,238,92,92,255,160,5,178,179,160,98,255,0,14,149,161,98,255,0,4,230,255,0,9,94,255,160,3
    db 93,255,0,6,253,0,0,149,92,255,160,6,98,255,0,15,94,93,255,0,4,204,255,231,4,216,217,255,231,3,183,160
    db 182,160,160,96,100,255,0,4,253,255,0,4,149,92,255,160,4,93,255,0,15,99,93,255,0,14,94,255,160,4
    db 93,255,0,5,253,255,0,6,149,92,160,160,93,255,0,15,94,93,255,0,14,94,255,160,4
    db 98,255,0,5,253,255,0,8,149,160,93,255,0,4,146,147,148,255,0,8,94,93,255,0,14,94,255,160,4
    db 93,255,0,5,253,255,0,9,94,93,255,0,5,230,255,0,9,94,93,255,0,14,99,255,160,5
    db 255,96,5,254,100,255,0,8,94,160,255,231,5,201,255,0,9,99,160,212,213,255,231,7,202,255,0,4,99,255,160,11
    db 96,104,255,0,7,99,93,255,0,15,94,93,255,0,9,230,255,0,4,99,160,160
    db 162,163,255,160,3,182,255,160,5,96,100,255,0,5,99,93,255,0,15,94,160,231,216,217,255,231,6,201,255,0,4,99,160,160
    db 178,179,255,160,10,231,231,239,255,255,1,231,231,160,93,255,0,15,99,93,255,0,14,94,255,160,8
    db 162,163,255,160,3,93,255,0,6,94,93,255,0,15,99,93,255,0,14,94,182
    db 255,160,7,178,179,255,160,3,93,255,0,6,94,168,169,255,0,14,94,93,255,0,14,94,255,160,13
    db 128,255,252,6,129,184,185,255,0,14,94,93,255,0,14,94,160,160
    db 182,255,160,6,92,238,92,92,95,255,0,6,99,93,255,0,15,94,98,255,0,4,203,255,231,6,216,217,231,255,160,6
    db 255,92,3,95,0,253,255,0,9,99,116,255,0,15,94,98,255,0,4,247,255,0,9,94,255,160,4
    db 95,255,0,5,253,255,0,9,99,132,255,0,15,94,93,255,0,4,204,255,231,9,255,160,4
    db 95,255,0,6,253,255,0,9,94,93,255,0,15,94,98,255,0,14,94,160,160
    db 93,255,0,7,253,255,0,9,94,160,180,104,255,0,12,170,171,93,255,0,14,94,160,160
    db 93,255,0,7,253,255,0,7,101,96,160,160,161,93,255,0,12,186,187,93,255,0,14,99,160,160
    db 98,255,0,7,253,255,0,5,134,108,109,255,160,3,161,93,255,0,13,94,93,255,0,14,94,160,160
    db 98,255,0,7,253,164,165,0,0,105,181,151,160,182,183,160,92,95,255,0,13,94,93,255,0,14,94,160,160
    db 93,255,0,5,101,96,254,180,181,96,96,151,255,160,5,93,255,0,15,94,160,255,231,7,39,255,0,4,255,255,1,231,255,160,3
    db 118,119,130,131,255,0,3,149,255,92,11,95,255,0,15,149,95,255,0,14,94,160,160
    db 93,255,0,50,94,160,160
    db 98,255,0,50,94,160,160
    db 93,255,0,49,10,11,255,160,3
    db 96,100,255,0,47,26,27,255,160,4
    db 155,255,0,14,164,165,255,0,32,94,160,160
    db 182,160,160,96,104,255,0,4,105,155,255,0,3,109,96,96,180,181,96,96,100,255,0,8,198,199,255,0,6,164,165,255,0,11,94,255,160,7
    db 255,96,10,255,160,3,182,160,255,96,10,214,215,255,96,6,180,181,255,96,11,255,160,30
    db 183,255,160,18,182,255,160,6
    ;; Run-length encoding (size: 848)

map11:
    db 10,FUEL_UNIT
    db 37,54
    ;; number of animation tiles: 30
    db 255,0,255
    db 255,0,238
    db 248,249,255,0,4,164,165,255,0,3,134,0,0,105,181,255,96,4,180,104,255,0,12,164,165,255,0,16
    db 105,181,255,96,6,180,181,255,96,7,181,255,161,4,180,255,96,13,180,181,255,96,11
    db 255,0,5,94,160,183,255,160,35,183,255,160,10
    db 255,0,5,149,255,92,5,238,224,225,255,92,21,238,255,92,6,255,160,4,255,92,5,255,160,3
    db 255,0,11,253,240,241,255,0,21,253,255,0,6,94,160,160,95,255,0,5,149,160,160
    db 255,0,11,253,255,0,23,253,255,0,6,94,160,93,255,0,7,94,160
    db 255,0,11,253,255,0,23,253,255,0,6,94,160,93,255,0,6,228,229,160
    db 255,0,11,253,255,0,23,253,255,0,5,228,229,160,93,255,0,6,244,245,183
    db 255,0,11,253,255,0,9,164,165,255,0,3,164,165,255,0,7,253,255,0,5,244,245,160,93,255,0,7,94,160
    db 255,0,11,253,255,0,6,255,96,3,180,181,255,96,3,180,181,96,96,100,255,0,4,253,255,0,6,94,160,93,255,0,4,146,147,148,94,160
    db 255,0,11,253,255,0,5,228,229,255,160,10,93,255,0,5,253,255,0,5,228,229,183,93,255,0,5,230,0,94,160
    db 255,0,11,253,255,0,5,244,245,160,182,255,160,4,255,92,4,95,255,0,5,253,255,0,5,244,245,160,93,255,0,5,204,231,160,160
    db 255,0,11,253,255,0,6,94,255,160,4,92,95,255,0,10,253,255,0,6,94,160,93,255,0,7,94,160
    db 255,0,11,253,255,0,6,94,255,160,3,93,255,0,12,253,0,0,134,0,0,156,151,160,93,255,0,7,94,160
    db 255,0,11,253,255,0,6,94,255,160,3,93,255,0,11,101,254,255,96,5,151,160,160,93,255,0,7,94,160
    db 255,0,11,253,255,0,6,94,255,160,3,95,255,0,10,105,96,255,160,3,162,163,255,160,4,95,255,0,7,94,160
    db 255,0,11,253,255,0,6,94,160,160,93,255,0,8,101,96,96,255,160,5,178,179,160,160,183,93,255,0,8,94,160
    db 255,0,11,253,255,0,6,94,160,160,95,255,0,7,105,96,255,160,3,183,255,160,8,93,255,0,8,94,160
    db 255,0,11,253,255,0,5,96,151,160,93,255,0,6,105,96,160,183,160,160,255,92,4,255,160,3,255,92,3,95,255,0,8,94,160
    db 255,0,4,126,127,255,0,5,253,255,0,5,94,160,160,93,255,0,6,149,255,92,4,95,255,0,4,149,92,95,255,0,12,94,160
    db 255,0,3,122,123,124,125,255,0,3,105,254,104,255,0,4,94,160,160,93,255,0,31,94,160
    db 255,0,3,138,139,140,141,255,0,3,94,160,150,104,0,0,105,151,182,160,93,255,0,31,94,160
    db 255,96,3,181,160,160,180,155,0,105,151,160,160,150,104,105,151,255,160,3,161,212,213,202,255,0,28,94,255,160,8
    db 150,96,255,160,11,93,0,0,230,255,0,28,94,255,160,3
    db 162,163,255,160,16,93,0,0,230,255,0,12,1,2,255,0,14,94,255,160,3
    db 178,179,255,160,4,182,255,160,7,162,163,255,160,3,96,96,180,104,255,0,10,16,17,18,19,255,0,10,105,181,96,255,160,18
    db 178,179,255,160,7,255,96,24,160,160,183,255,160,56
    ;; Run-length encoding (size: 729)

map12:
    db 10,FUEL_UNIT
    db 43,72
    ;; number of animation tiles: 20
    db 255,0,255
    db 255,0,255
    db 255,0,24,142,143,196,197,255,0,68
    db 192,193,194,195,255,0,64
    db 134,255,0,3,208,209,210,211,255,0,59
    db 105,255,96,8,255,176,4,255,96,6,104,255,0,46
    db 164,165,0,105,96,96,255,160,5,92,160,91,255,92,10,160,160,255,96,9,104,255,0,6,164,165,255,0,22
    db 248,249,0,0,105,96,180,181,96,255,160,7,95,0,230,255,0,11,149,255,92,4,255,160,7,255,96,6,180,181,255,96,4,104,255,0,3,164,165,255,0,3
    db 96,96,100,255,0,4,101,96,180,181,96,96,255,160,11,93,0,0,230,255,0,16,149,255,92,4,255,160,6,182,255,160,8,255,96,3,180,181,255,96,3
    db 176,93,255,0,6,94,255,160,15,93,0,0,230,255,0,21,149,255,92,15,255,160,3,182,255,160,3
    db 176,93,255,0,6,94,255,160,4,182,255,160,7,162,163,160,93,0,0,230,255,0,37,149,255,92,4,160,160
    db 176,128,255,252,6,129,255,160,12,178,179,160,93,0,0,204,39,255,0,4,255,255,1,202,255,0,35,94,160
    db 176,93,255,0,6,94,255,160,15,93,255,0,9,230,255,0,35,94,160
    db 176,93,255,0,6,94,255,160,15,93,255,0,8,101,180,96,96,100,255,0,32,94,160
    db 176,93,255,0,6,94,160,160,162,163,255,160,11,93,255,0,9,94,160,93,255,0,33,94,160
    db 176,93,255,0,6,94,160,160,178,179,255,160,11,93,255,0,5,101,255,96,3,160,160,93,255,0,33,149,160,160
    db 128,255,252,6,129,255,160,15,93,255,0,3,136,137,120,121,255,160,4,93,255,0,4,1,2,255,0,7,105,104,255,0,19,94
    db 160,93,255,0,6,94,255,160,10,182,255,160,4,93,255,0,6,149,92,92,160,160,93,255,0,3,16,17,18,19,255,0,6,94,93,255,0,10,101,96,96,100,255,0,5,94
    db 160,93,255,0,6,94,255,160,5,166,255,160,9,93,255,0,9,94,160,160,255,96,13,151,93,255,0,11,117,93,255,0,6,94
    db 160,93,255,0,6,94,255,160,15,93,255,0,9,94,255,160,11,182,255,160,4,93,255,0,4,1,2,255,0,5,133,93,255,0,6,94
    db 160,160,255,96,3,100,0,0,94,255,160,9,162,163,255,160,5,96,96,104,255,0,6,94,255,160,3,162,163,255,160,11,93,255,0,3,16,17,18,19,255,0,4,94,93,255,0,6,94
    db 182,255,160,3,93,255,0,3,94,255,160,9,178,179,255,160,6,166,118,119,130,131,255,0,3,94,255,160,3,178,179,255,160,12,255,96,11,151,93,255,0,6,94
    db 160,160,92,92,95,255,0,3,94,255,160,16,92,92,95,255,0,6,149,255,160,7,166,255,160,21,93,255,0,6,94
    db 160,93,255,0,6,94,160,182,255,160,13,93,255,0,10,94,255,160,6,182,255,160,11,162,163,163,255,160,7,93,255,0,6,94
    db 160,93,255,0,6,94,255,160,13,166,160,93,255,0,10,94,255,160,18,178,179,179,255,160,7,93,255,0,6,94
    db 160,93,255,0,6,94,160,160,255,92,8,255,160,5,95,255,0,10,149,160,91,255,92,22,160,91,92,160,95,255,0,6,94
    db 160,93,0,0,101,255,96,3,160,160,95,255,0,8,149,224,225,92,95,255,0,12,230,255,0,23,230,0,0,230,255,0,7,94
    db 160,93,255,0,3,94,255,160,3,95,255,0,10,240,241,255,0,14,230,255,0,23,207,231,231,205,255,0,7,94
    db 160,93,255,0,3,149,92,92,95,255,0,27,230,255,0,23,255,167,4,255,0,7,94
    db 160,93,255,0,34,230,255,0,23,102,103,232,233,255,0,7,94
    db 160,93,255,0,34,230,255,0,23,110,111,234,235,255,0,7,94
    db 160,93,255,0,34,204,231,231,239,255,255,1,231,231,202,255,0,16,255,167,4,255,0,7,94
    db 160,93,255,0,41,230,255,0,16,207,231,231,205,0,146,147,148,255,0,3,94
    db 160,160,96,100,255,0,39,230,255,0,16,230,0,0,230,0,0,230,0,108,109,96,255,160,3
    db 93,0,134,255,0,38,230,255,0,15,105,181,96,96,181,255,96,4,181,255,160,6
    db 255,96,3,152,153,154,0,0,198,199,0,0,14,15,255,0,5,164,165,255,0,7,164,165,255,0,10,230,255,0,3,220,221,255,0,4,220,221,255,0,3,105,255,160,15
    db 182,255,160,3,161,161,180,96,96,214,215,96,181,30,31,180,255,96,4,180,181,255,96,7,180,181,255,96,10,181,255,96,3,236,237,255,96,4,236,237,255,96,3,255,160,6,166,255,160,3,166,255,160,75
    ;; Run-length encoding (size: 1025)

map13:
    db 10,FUEL_UNIT
    db 64,64
    ;; number of animation tiles: 12
    db 255,0,255
    db 255,0,255
    db 255,0,94
    db 134,255,0,13,101,255,96,9,100,134,255,0,34
    db 101,255,96,6,100,255,0,8,101,96,96,255,160,9,255,96,3,104,255,0,6,105,96
    db 255,0,23,101,96,151,255,160,5,96,96,100,255,0,6,105,255,160,15,239,255,0,4,255,255,1,160,160
    db 255,0,21,101,96,96,151,255,160,4,166,255,160,3,96,104,0,0,101,96,96,255,160,7,162,163,255,160,6,93,255,0,6,94,160
    db 203,255,231,3,39,255,0,4,255,255,1,255,231,12,255,160,13,255,96,3,255,160,9,178,179,255,160,6,93,255,0,6,94,160
    db 230,255,0,19,101,96,151,255,160,3,162,163,255,160,12,182,183,255,160,14,96,100,255,0,4,94,160
    db 230,255,0,20,94,255,160,4,178,179,255,160,28,93,255,0,5,94,160
    db 230,255,0,20,94,255,160,10,255,92,3,160,92,92,160,255,92,6,255,160,11,93,255,0,5,94,160
    db 230,255,0,19,105,151,255,160,6,255,92,3,95,255,0,3,230,0,0,230,255,0,6,149,92,92,255,160,8,93,255,0,5,94,160
    db 230,255,0,19,94,255,160,6,95,255,0,7,230,0,0,230,255,0,9,94,255,160,3,166,255,160,3,95,255,0,5,94,160
    db 230,255,0,17,101,96,255,160,6,95,255,0,7,247,200,216,217,205,247,255,0,8,149,255,160,6,93,255,0,6,94,160
    db 230,255,0,8,248,249,255,0,8,94,255,160,5,93,255,0,8,255,167,6,255,0,9,94,255,160,5,93,255,0,6,94,160
    db 230,255,0,7,101,255,96,3,100,255,0,4,101,96,255,160,6,95,255,0,8,255,167,6,255,0,9,149,255,160,5,93,255,0,6,94,160
    db 96,96,100,255,0,6,94,160,160,231,231,39,255,255,1,231,231,255,160,6,93,255,0,9,167,102,103,232,233,167,255,0,10,94,255,160,4,95,255,0,6,94,160,160
    db 93,255,0,7,94,160,93,255,0,6,94,255,160,5,95,255,0,9,167,110,111,234,235,167,255,0,10,94,255,160,3,95,255,0,7,94,160,160
    db 93,255,0,7,94,160,93,255,0,6,94,255,160,4,93,255,0,10,255,167,6,255,0,10,117,160,160,93,255,0,8,94,160,160
    db 93,255,0,7,94,166,93,255,0,6,94,160,160,182,183,93,255,0,10,255,167,6,255,0,10,133,160,160,93,255,0,8,94,160,160
    db 150,104,255,0,6,94,160,93,255,0,6,94,255,160,4,93,255,0,10,247,200,216,217,200,247,255,0,10,94,160,160,226,227,255,0,7,94,160
    db 166,160,128,255,252,6,129,160,226,227,255,0,5,94,255,160,4,93,255,0,11,230,0,0,230,255,0,11,94,160,160,242,243,255,0,7,94,255,160,3
    db 93,255,0,6,94,160,242,243,255,0,5,149,255,160,4,93,255,0,11,230,0,0,230,255,0,11,94,160,160,95,255,0,8,94,255,160,3
    db 93,255,0,6,94,160,93,255,0,7,94,160,166,160,93,255,0,11,230,0,0,230,255,0,5,220,221,255,0,3,105,151,160,93,255,0,9,94,255,160,3
    db 93,255,0,6,94,160,93,255,0,7,149,255,160,3,95,255,0,11,230,0,0,230,255,0,3,96,96,236,237,255,96,3,255,160,4,96,100,255,0,6,105,255,160,4
    db 93,255,0,6,94,160,93,255,0,8,149,160,95,255,0,8,164,165,0,0,230,0,0,230,255,0,3,94,255,160,10,93,255,0,7,94,255,160,4
    db 93,255,0,6,94,160,93,255,0,16,101,96,96,180,181,96,96,160,96,96,160,255,96,3,255,160,11,150,104,255,0,6,94,255,160,4
    db 93,255,0,6,94,160,160,255,96,3,100,255,0,11,101,96,255,160,25,93,255,0,6,94,255,160,5
    db 96,96,100,255,0,3,94,255,160,4,93,255,0,13,94,255,160,12,182,183,255,160,12,96,100,255,0,4,94,160,166
    db 255,160,4,93,255,0,4,94,255,160,5,104,255,0,12,94,255,160,20,162,163,255,160,4,93,255,0,5,149,255,160,6
    db 93,255,0,4,94,255,160,6,104,255,0,9,101,96,160,160,162,163,160,160,255,92,6,255,160,9,178,179,255,160,4,93,255,0,6,94,255,160,3
    db 91,91,95,255,0,4,94,160,160,162,163,255,160,3,96,104,255,0,8,94,160,160,178,179,160,93,255,0,6,149,255,92,4,255,160,10,93,255,0,6,94,160,160
    db 226,227,255,0,6,94,160,160,178,179,255,160,4,180,96,96,100,255,0,5,94,255,160,4,92,95,255,0,11,149,92,255,160,8,93,255,0,5,228,229,160,160
    db 242,243,255,0,6,94,255,160,11,231,231,239,255,255,1,231,231,255,160,4,95,255,0,15,149,255,160,7,93,255,0,5,244,245,160,160
    db 93,255,0,7,94,255,160,10,93,255,0,6,149,160,160,95,255,0,17,94,255,160,6,93,255,0,6,94,160,160
    db 93,255,0,7,149,255,92,8,255,160,3,96,100,255,0,5,94,93,255,0,18,149,255,160,6,93,255,0,6,94,160,160
    db 93,255,0,16,149,160,160,93,255,0,6,149,95,255,0,19,94,255,160,5,93,255,0,6,94,160,160
    db 150,104,255,0,16,149,160,160,104,255,0,25,105,151,255,160,5,93,255,0,6,94,255,160,3
    db 95,255,0,17,149,160,226,227,255,0,24,94,255,160,6,93,255,0,6,94,160,160
    db 93,255,0,6,101,96,96,100,255,0,9,94,242,243,255,0,17,164,165,101,96,112,113,96,255,160,4,166,160,160,118,119,130,131,255,0,3,94,160,160
    db 226,227,255,0,6,94,93,255,0,10,94,93,255,0,16,101,96,180,181,96,255,160,11,93,255,0,6,94,160,160
    db 242,243,255,0,6,94,93,255,0,10,94,93,255,0,16,105,151,255,160,14,93,255,0,6,94,160,160
    db 93,255,0,7,94,93,255,0,10,94,160,96,100,255,0,14,94,255,160,15,93,255,0,5,105,255,160,3
    db 93,255,0,7,94,93,255,0,10,94,160,93,255,0,15,149,255,160,7,182,183,255,160,6,93,255,0,5,94,255,160,3
    db 93,255,0,7,94,93,255,0,3,146,147,148,255,0,4,94,160,93,255,0,16,149,255,160,14,93,255,0,5,94,255,160,3
    db 93,255,0,7,94,93,255,0,4,230,255,0,5,94,160,160,96,100,255,0,15,149,91,91,255,160,11,95,255,0,5,94,255,160,3
    db 93,255,0,5,101,96,160,93,255,0,4,230,255,0,5,94,160,160,93,255,0,19,149,255,91,3,255,160,6,95,255,0,6,149,255,160,3
    db 93,255,0,6,94,160,93,255,0,4,247,255,0,5,94,160,160,93,255,0,23,149,255,91,4,95,255,0,8,94,160,160
    db 93,255,0,6,94,160,93,255,0,4,230,255,0,4,105,151,160,160,93,255,0,37,94,160,160
    db 93,255,0,4,101,96,160,160,93,255,0,4,230,255,0,4,94,255,160,3,93,255,0,37,94,160,160
    db 150,104,0,0,101,96,255,160,4,96,96,100,0,230,255,0,3,105,151,255,160,3,93,255,0,37,94,255,160,4
    db 255,96,3,255,160,7,255,96,6,255,160,5,93,255,0,36,228,229,255,160,21
    db 162,163,160,160,93,255,0,36,244,245,255,160,21
    db 178,179,160,160,150,104,255,0,36,94,255,160,6
    db 162,163,255,160,4,182,183,255,160,12,150,104,255,0,7,1,2,255,0,7,105,96,104,255,0,6,1,2,255,0,8,94,255,160,6
    db 178,179,255,160,19,93,255,0,6,16,17,18,19,255,0,6,94,160,93,255,0,5,16,17,18,19,255,0,7,94,255,160,28
    db 255,96,16,255,160,3,255,96,16,255,160,66
    ;; Run-length encoding (size: 1700)

map14:
    db 10,FUEL_UNIT
    db 78,40
    ;; number of animation tiles: 15
    db 255,0,255
    db 255,0,118
    db 105,96,100,255,0,3,101,96,104,255,0,31
    db 94,93,255,0,5,94,150,155,255,0,29
    db 105,151,93,255,0,5,94,160,150,104,255,0,27
    db 156,151,160,93,255,0,5,94,160,160,150,104,255,0,25
    db 105,151,182,160,93,255,0,5,94,255,160,3,150,155,255,0,23
    db 156,151,255,160,3,93,255,0,5,94,255,160,4,150,104,255,0,20
    db 105,181,255,160,5,93,255,0,5,94,160,162,163,160,160,150,155,255,0,18
    db 156,151,255,160,6,93,255,0,5,94,160,178,179,255,160,3,150,104,255,0,16
    db 105,151,255,160,5,182,160,93,255,0,5,94,255,160,7,150,155,255,0,14
    db 156,255,160,9,93,255,0,5,94,255,160,8,150,155,255,0,12
    db 105,151,255,160,3,162,163,255,160,4,93,255,0,5,94,255,160,3,182,255,160,5,150,104,255,0,10
    db 105,151,255,160,4,178,179,255,160,4,93,255,0,5,94,255,160,10,150,104,255,0,8
    db 105,151,255,160,11,93,255,0,5,94,255,160,11,150,155,255,0,6
    db 96,160,160,255,91,11,95,255,0,5,149,255,91,6,255,160,7,180,104,255,0,4
    db 160,160,95,255,0,24,149,91,255,160,6,150,104,255,0,3
    db 160,93,255,0,27,149,255,160,6,150,155,126,127
    db 160,93,255,0,28,149,91,255,160,6,180,181
    db 160,98,255,0,30,149,91,255,160,7
    db 93,255,0,32,149,255,160,3,182,160,160
    db 93,255,0,7,248,249,0,0,164,165,255,0,7,134,255,0,12,224,225,255,160,4
    db 98,255,0,5,101,255,96,5,180,181,255,96,6,97,180,155,255,0,11,240,241,94,255,160,3
    db 93,255,0,6,94,255,160,15,96,104,255,0,11,94,255,160,3
    db 128,255,252,6,129,255,160,10,162,163,255,160,5,96,96,100,255,0,8,149,255,160,3
    db 93,255,0,6,94,255,160,4,182,255,160,5,178,179,255,160,6,150,155,255,0,9,94,160,160
    db 93,255,0,6,149,91,255,160,18,150,104,255,0,8,94,160,160
    db 98,255,0,8,94,255,160,19,96,100,255,0,6,94,160,160
    db 98,255,0,8,149,91,12,13,91,224,225,255,91,7,255,160,6,93,255,0,7,94,160,160
    db 98,255,0,10,28,29,0,240,241,255,0,7,149,160,160,182,160,160,150,104,255,0,6,99,160,160
    db 93,255,0,23,94,255,160,5,93,255,0,6,99,160,160
    db 93,255,0,23,149,255,160,5,93,255,0,6,94,160,160
    db 226,227,255,0,23,149,255,160,4,98,255,0,6,94,160,160
    db 242,243,255,0,24,94,255,160,3,93,255,0,6,94,160,160
    db 98,255,0,25,149,255,160,3,93,255,0,6,99,160,160
    db 98,255,0,26,94,160,160,93,255,0,6,94,160,160
    db 98,255,0,25,228,229,160,160,98,255,0,6,94,160,160
    db 93,255,0,25,244,245,160,160,93,255,0,6,94,160,160
    db 93,255,0,26,94,160,160,93,255,0,6,99,160,160
    db 150,104,255,0,25,94,160,160,98,255,0,6,94,255,160,3
    db 150,155,0,101,96,104,255,0,20,99,160,160,93,255,0,6,94,255,160,5
    db 96,96,160,93,0,198,199,0,0,164,165,255,0,13,99,160,160,93,255,0,6,94,160,160
    db 162,163,255,160,5,96,214,215,96,96,180,181,255,96,3,104,255,0,9,94,160,160,93,255,0,6,94,160,160
    db 178,179,255,160,3,182,255,160,11,93,255,0,9,94,160,160,93,255,0,6,94,255,160,14
    db 182,255,160,4,93,255,0,9,99,255,160,3,231,231,39,255,255,1,231,231,255,160,4
    db 255,91,15,160,95,255,0,9,94,160,160,93,255,0,6,94,160,160
    db 93,255,0,15,230,255,0,10,94,160,160,93,255,0,6,99,160,160
    db 93,255,0,15,207,255,231,5,218,255,0,4,94,160,160,98,255,0,6,99,160,160
    db 93,255,0,15,230,255,0,10,94,160,160,98,255,0,6,99,160,160
    db 93,255,0,15,230,255,0,7,136,137,120,121,160,160,93,255,0,6,99,160,160
    db 93,255,0,5,203,231,39,255,0,4,255,255,1,231,231,201,255,0,10,94,160,160,93,255,0,6,94,160,160
    db 98,255,0,5,230,255,0,20,94,160,160,93,255,0,6,94,160,160
    db 98,255,0,5,230,255,0,14,142,143,196,197,0,0,99,160,160,93,255,0,6,94,160,160
    db 98,255,0,5,230,255,0,14,192,193,194,195,0,0,94,160,160,93,255,0,6,94,160,160
    db 93,255,0,5,230,255,0,12,164,165,208,209,210,211,164,165,94,160,160,118,119,130,131,136,137,120,121,160,160
    db 93,255,0,5,230,255,0,5,101,255,96,6,180,181,181,160,160,180,180,181,255,160,3,93,255,0,6,94,160,160
    db 98,255,0,5,207,255,231,6,255,160,4,162,163,255,160,10,91,95,255,0,6,94,160,160
    db 98,255,0,5,204,255,231,6,255,160,4,178,179,255,160,6,182,160,160,93,255,0,8,99,160,160
    db 98,255,0,12,149,160,255,91,13,95,255,0,8,94,160,160
    db 93,255,0,13,230,255,0,22,94,160,160
    db 98,255,0,13,230,255,0,22,94,160,160
    db 93,255,0,13,230,255,0,22,99,160,160
    db 93,255,0,7,146,147,148,255,0,3,230,255,0,22,99,160,160
    db 93,255,0,8,204,255,231,4,201,255,0,22,94,160,160
    db 93,255,0,36,94,160,160
    db 226,227,255,0,35,94,160,160
    db 242,243,255,0,35,94,160,160
    db 93,255,0,18,1,2,255,0,14,158,159,255,160,3
    db 93,255,0,17,16,17,18,19,255,0,10,105,181,96,151,255,160,5
    db 255,96,31,151,255,160,4,182,255,160,12
    db 182,255,160,28
    ;; Run-length encoding (size: 1240)

map15:
    db 10,FUEL_UNIT
    db 64,64
    ;; number of animation tiles: 18
    db 255,0,255
    db 255,0,255
    db 255,0,67
    db 248,249,255,0,10,164,165,255,0,14,126,127,0,0,134,255,0,30
    db 255,96,4,100,255,0,4,101,255,96,3,180,181,255,96,14,180,181,255,96,5,152,153,154,0,164,165,255,0,22
    db 160,183,160,160,39,255,0,4,255,255,1,255,160,14,162,163,255,160,8,162,163,160,160,180,96,180,181,96,104,255,0,20
    db 160,160,92,95,255,0,6,149,92,160,183,160,160,255,92,7,160,178,179,255,160,8,178,179,255,160,8,180,155,255,0,18
    db 160,93,255,0,10,94,160,160,93,255,0,7,94,255,160,9,255,92,7,160,255,92,3,160,160,96,96,100,255,0,15
    db 160,98,255,0,10,94,160,92,95,255,0,7,149,255,92,8,95,255,0,7,230,255,0,3,149,255,160,3,96,180,155,255,0,13
    db 160,98,255,0,10,94,93,255,0,26,230,255,0,4,230,149,114,115,92,160,180,104,255,0,11
    db 160,98,255,0,10,94,93,255,0,26,207,231,216,217,231,205,255,0,4,149,160,150,155,255,0,10
    db 160,93,0,146,147,148,255,0,6,94,98,255,0,26,255,167,6,255,0,5,149,160,150,104,255,0,9
    db 160,93,0,0,230,255,0,7,94,98,255,0,26,167,102,103,232,233,167,255,0,6,149,160,150,96,100,255,0,7
    db 160,160,231,231,201,255,0,7,94,98,255,0,26,167,110,111,234,235,167,255,0,7,149,160,93,255,0,8
    db 160,93,255,0,10,94,98,255,0,26,255,167,6,255,0,8,94,93,255,0,8
    db 160,93,255,0,10,94,93,255,0,26,207,231,216,217,231,205,255,0,8,94,98,255,0,8
    db 160,116,255,0,10,94,93,255,0,26,230,255,0,4,230,0,142,143,196,197,255,0,3,94,93,134,255,0,7
    db 160,132,255,0,10,94,93,255,0,26,230,255,0,4,230,0,192,193,194,195,101,96,96,160,160,96,100,255,0,6
    db 160,93,255,0,10,94,93,0,126,127,255,0,10,164,165,255,0,11,230,255,0,4,230,0,208,209,210,211,0,94,162,163,160,93,255,0,7
    db 160,160,96,96,100,255,0,4,101,96,96,160,160,96,180,181,96,100,255,0,4,101,255,96,3,180,181,255,96,3,100,255,0,4,101,96,96,180,255,96,4,180,96,181,160,160,180,96,160,178,179,160,93,255,0,7
    db 255,160,4,231,231,239,255,255,1,231,231,255,160,4,183,255,160,3,239,255,0,4,255,255,1,255,160,3,183,255,160,4,231,231,239,255,255,1,231,231,255,160,10,183,255,160,7,93,255,0,7
    db 160,160,92,95,255,0,6,149,92,160,160,255,92,3,95,255,0,6,149,255,92,3,160,160,92,95,255,0,6,149,255,92,15,160,160,93,255,0,7
    db 160,93,255,0,10,94,93,255,0,14,94,93,255,0,24,94,160,93,255,0,7
    db 160,98,255,0,10,94,93,255,0,14,94,116,255,0,24,94,160,93,255,0,7
    db 160,98,255,0,10,99,93,255,0,14,94,132,255,0,24,94,160,93,255,0,7
    db 160,98,255,0,10,99,93,255,0,14,94,93,255,0,24,94,160,93,255,0,7
    db 160,93,255,0,10,99,93,255,0,14,94,93,255,0,24,99,183,93,255,0,7
    db 160,226,227,255,0,9,94,168,169,255,0,12,170,171,93,255,0,24,99,160,93,255,0,7
    db 160,242,243,255,0,9,94,184,185,255,0,12,186,187,93,255,0,24,99,160,95,255,0,7
    db 160,93,255,0,10,94,93,255,0,14,94,93,255,0,24,94,93,255,0,8
    db 160,116,255,0,10,94,93,255,0,14,99,93,255,0,24,94,93,255,0,8
    db 160,132,255,0,10,94,93,255,0,14,94,93,255,0,24,94,93,255,0,7,105
    db 160,98,255,0,10,94,93,255,0,14,94,93,255,0,8,1,2,255,0,14,94,93,255,0,7,94
    db 160,93,255,0,10,94,93,255,0,14,94,93,255,0,7,16,17,18,19,255,0,3,105,104,255,0,8,94,98,255,0,7,94
    db 160,160,96,96,100,255,0,4,101,96,96,160,160,96,112,113,96,100,255,0,4,101,255,96,4,160,160,255,96,14,151,98,255,0,5,101,96,96,160,98,255,0,7,99
    db 160,183,160,160,239,255,0,4,255,255,1,255,160,8,231,231,239,255,255,1,231,231,255,160,13,183,255,160,8,239,255,0,4,255,255,1,255,160,3,98,255,0,7,99
    db 160,160,92,95,255,0,6,149,92,160,160,255,92,3,95,255,0,6,149,255,92,3,160,160,255,92,3,160,255,92,6,160,255,92,3,160,95,255,0,6,149,92,160,98,255,0,7,99
    db 160,93,255,0,9,10,11,93,255,0,14,94,93,255,0,3,230,255,0,6,230,255,0,3,230,255,0,9,94,98,255,0,6,156,151
    db 160,93,255,0,9,26,27,93,255,0,14,94,93,255,0,3,230,255,0,6,207,255,231,3,205,255,0,9,94,93,255,0,6,94,160,160
    db 98,255,0,10,94,93,255,0,14,99,93,255,0,3,230,255,0,6,230,255,0,3,204,255,231,4,218,255,0,4,94,98,255,0,6,94,160,160
    db 98,255,0,10,94,93,255,0,14,99,93,255,0,3,230,255,0,6,230,255,0,13,94,93,255,0,6,94,160,160
    db 98,255,0,10,94,93,255,0,14,99,93,255,0,3,230,255,0,6,230,255,0,13,94,93,255,0,6,94,160,160
    db 93,255,0,10,99,93,255,0,14,99,93,255,0,3,230,255,0,6,230,255,0,13,94,93,255,0,6,99,160,160
    db 93,255,0,10,99,93,255,0,14,94,160,255,231,3,246,231,218,255,0,4,247,255,0,3,219,231,231,202,255,0,6,94,93,255,0,6,99,160,160
    db 93,255,0,10,99,93,255,0,14,94,116,255,0,17,230,255,0,6,94,128,255,252,6,129,160,160
    db 116,255,0,10,99,93,255,0,14,94,132,255,0,17,230,255,0,6,94,93,255,0,6,94,160,160
    db 132,255,0,10,94,93,255,0,14,94,93,255,0,17,230,255,0,5,156,151,93,255,0,6,94,160,160
    db 93,255,0,10,94,93,255,0,14,94,160,96,96,100,255,0,4,101,255,96,9,180,255,96,5,181,160,93,255,0,6,99,183
    db 160,93,255,0,10,94,93,0,220,221,255,0,11,94,255,160,3,231,231,239,255,255,1,231,231,255,160,7,183,255,160,9,93,255,0,6,99,255,160,3
    db 96,96,100,255,0,4,101,96,96,160,160,96,236,237,96,100,255,0,4,101,96,112,113,96,160,160,92,95,255,0,6,149,255,92,16,95,255,0,6,99,255,160,5
    db 231,231,239,255,255,1,231,231,255,160,8,239,255,0,4,255,255,1,255,160,5,93,255,0,32,99,255,160,4
    db 93,255,0,6,149,238,92,114,115,92,238,95,255,0,6,149,255,92,3,160,93,255,0,32,99,255,160,4
    db 93,255,0,7,253,255,0,4,253,255,0,11,94,93,255,0,32,94,160,160
    db 162,163,98,255,0,7,253,255,0,4,253,255,0,11,94,93,255,0,32,99,160,160
    db 178,179,93,255,0,7,253,255,0,4,253,255,0,11,94,93,255,0,13,1,2,255,0,17,94,255,160,4
    db 93,255,0,7,253,255,0,4,253,255,0,11,94,93,255,0,12,16,17,18,19,255,0,16,94,255,160,5
    db 255,96,7,254,255,96,4,254,255,96,11,160,160,255,96,25,255,97,3,96,96,181,96,255,160,15
    db 183,255,160,17,183,255,160,32
    ;; Run-length encoding (size: 1640)

map16:
    db 10,FUEL_UNIT
    db 64,64
    ;; number of animation tiles: 9
    db 255,0,255
    db 255,0,255
    db 255,0,94
    db 248,249,255,0,56
    db 134,0,105,181,96,96,180,181,96,100,255,0,4,101,255,96,3,104,255,0,44
    db 105,181,96,181,255,160,4,166,93,255,0,6,94,160,160,180,96,104,164,165,255,0,34
    db 126,127,105,181,96,96,255,160,10,39,255,0,4,255,255,1,255,160,5,180,180,181,96,104,255,0,30
    db 105,181,96,96,255,160,7,162,163,255,160,4,93,255,0,6,149,255,91,7,160,160,96,104,255,0,26
    db 105,181,255,160,11,178,179,255,160,4,93,255,0,14,149,91,91,160,96,104,255,0,22
    db 105,181,255,160,6,166,255,160,9,255,91,3,95,255,0,17,149,91,150,104,255,0,20
    db 156,160,160,255,91,15,95,255,0,23,149,150,155,255,0,17
    db 101,96,160,160,95,255,0,40,94,160,96,104,255,0,16
    db 94,160,226,227,255,0,25,101,255,96,6,100,255,0,7,149,160,160,93,255,0,15
    db 105,151,160,242,243,255,0,26,94,255,160,5,255,231,3,202,255,0,5,149,160,150,104,255,0,14
    db 94,160,160,95,255,0,18,101,96,96,100,255,0,5,94,160,255,91,3,95,255,0,3,230,255,0,6,94,160,160,96,100,255,0,11
    db 156,151,160,160,255,231,9,239,255,255,1,255,231,9,160,93,255,0,6,94,93,255,0,7,230,255,0,6,149,160,160,93,255,0,12
    db 94,160,160,95,255,0,20,94,93,255,0,6,94,93,255,0,7,230,255,0,7,94,160,150,104,255,0,11
    db 94,160,95,255,0,20,228,229,93,255,0,6,94,93,255,0,7,230,255,0,7,94,255,160,3,96,100,255,0,7
    db 101,96,151,93,255,0,21,244,245,93,255,0,6,94,93,255,0,7,230,255,0,7,94,255,160,3,93,255,0,9
    db 94,160,95,255,0,22,94,93,255,0,6,94,93,255,0,3,146,147,148,0,230,255,0,7,94,255,160,4,96,100,255,0,7
    db 94,160,231,231,202,255,0,4,203,231,231,216,217,255,231,7,216,217,231,231,160,93,255,0,6,94,93,255,0,4,230,0,0,230,255,0,7,94,255,160,4,93,255,0,8
    db 94,93,0,0,230,255,0,4,230,255,0,15,94,93,255,0,6,94,93,255,0,4,204,231,231,201,255,0,7,94,255,160,4,93,255,0,8
    db 94,93,0,0,247,255,0,4,230,255,0,15,94,128,255,252,6,129,93,255,0,15,94,160,162,163,160,150,104,255,0,7
    db 94,93,0,0,230,255,0,4,230,255,0,15,94,93,255,0,6,94,93,255,0,15,94,160,178,179,160,160,93,255,0,7
    db 94,160,231,231,201,255,0,4,230,255,0,3,203,231,231,216,217,231,231,202,255,0,4,94,93,255,0,6,94,93,255,0,15,94,255,160,5,93,255,0,7
    db 94,93,255,0,7,230,255,0,3,230,255,0,6,230,255,0,4,94,93,255,0,6,94,93,255,0,13,108,109,151,255,160,5,93,255,0,7
    db 94,93,255,0,7,230,255,0,3,230,255,0,6,230,255,0,4,94,93,255,0,6,94,93,0,0,220,221,255,0,7,108,109,151,255,160,7,150,155,255,0,6
    db 94,93,255,0,7,230,255,0,3,230,255,0,6,230,255,0,4,94,93,255,0,6,94,160,96,96,236,237,255,96,7,151,160,166,255,160,8,93,255,0,6
    db 94,93,255,0,4,219,231,231,201,255,0,3,230,255,0,6,230,255,0,4,94,93,255,0,6,149,255,91,9,160,160,255,91,6,6,7,91,91,160,160,93,255,0,6
    db 94,93,255,0,11,230,255,0,6,230,255,0,4,94,93,255,0,16,94,93,255,0,6,22,23,0,0,94,160,93,255,0,6
    db 94,93,255,0,11,230,255,0,6,230,255,0,4,94,93,255,0,16,94,93,255,0,10,117,160,93,255,0,6
    db 94,93,255,0,10,203,200,255,231,6,201,255,0,4,94,93,255,0,16,94,93,255,0,10,133,160,95,255,0,6
    db 94,93,255,0,3,203,231,231,216,217,231,231,201,230,255,0,11,94,93,255,0,16,94,93,255,0,10,94,93,255,0,7
    db 94,93,255,0,3,230,255,0,7,230,255,0,11,94,93,255,0,5,101,255,96,6,100,255,0,3,94,93,255,0,3,101,255,96,6,160,93,255,0,7
    db 94,93,255,0,3,230,255,0,7,230,255,0,11,94,93,255,0,6,94,160,162,163,160,93,255,0,4,94,93,255,0,4,94,255,160,6,93,255,0,7
    db 94,93,255,0,3,230,255,0,7,247,255,0,11,94,226,227,255,0,5,94,160,178,179,160,93,255,0,4,94,93,255,0,4,94,255,160,4,166,160,93,255,0,7
    db 149,160,255,96,3,181,96,100,255,0,5,230,0,105,181,100,0,0,101,255,96,4,160,242,243,255,0,5,94,255,160,4,93,255,0,4,94,93,255,0,4,94,255,160,6,95,255,0,8
    db 94,255,160,5,255,96,6,181,96,160,93,255,0,4,94,160,166,160,160,93,255,0,6,94,255,160,4,93,255,0,4,94,93,255,0,4,94,255,160,5,93,255,0,9
    db 94,255,160,14,93,255,0,4,94,255,160,4,93,255,0,6,94,255,160,4,93,255,0,4,94,93,255,0,4,94,255,160,5,93,255,0,9
    db 94,160,160,162,163,255,160,10,93,255,0,4,94,160,255,91,3,95,255,0,6,149,255,91,3,160,93,255,0,4,94,93,255,0,4,94,255,160,5,93,255,0,9
    db 94,160,160,178,179,255,160,6,162,163,160,160,93,255,0,4,94,93,255,0,14,94,93,255,0,4,94,93,255,0,4,94,255,160,5,93,255,0,9
    db 149,255,160,5,166,255,160,4,178,179,160,160,93,255,0,4,94,93,255,0,13,10,11,93,255,0,4,94,93,255,0,4,94,255,160,5,95,255,0,10
    db 94,255,160,13,93,255,0,4,94,93,255,0,13,26,27,93,255,0,4,94,93,255,0,4,94,160,162,163,160,93,255,0,11
    db 149,255,91,13,95,255,0,4,94,93,255,0,14,94,93,255,0,4,94,93,255,0,4,94,160,178,179,160,93,255,0,30
    db 94,93,255,0,5,203,216,217,202,255,0,5,94,93,255,0,4,149,95,255,0,4,94,255,160,4,95,255,0,30
    db 94,93,255,0,5,255,167,4,255,0,5,94,93,255,0,10,94,255,160,3,93,255,0,31
    db 94,93,255,0,5,102,103,232,233,255,0,5,94,93,255,0,9,228,229,255,160,3,95,255,0,28
    db 198,199,0,94,93,255,0,5,110,111,234,235,255,0,5,94,93,255,0,9,244,245,160,160,95,255,0,17
    db 101,255,96,11,214,215,96,160,93,255,0,5,255,167,4,255,0,5,94,93,255,0,10,94,160,95,255,0,19
    db 149,255,91,3,255,160,11,93,255,0,5,207,216,217,205,255,0,5,94,160,255,96,10,160,95,255,0,24
    db 149,91,160,91,91,255,160,7,96,96,100,0,0,230,0,0,230,0,126,127,0,0,94,255,160,10,91,95,255,0,27
    db 230,0,0,149,255,91,6,160,160,255,96,3,160,96,96,160,255,96,5,255,160,3,166,160,160,255,91,3,160,95,255,0,29
    db 230,255,0,9,149,160,255,91,12,160,255,91,4,95,255,0,3,230,255,0,30
    db 230,255,0,10,230,255,0,12,230,255,0,8,230,255,0,30
    db 230,0,126,127,255,0,7,230,255,0,12,230,255,0,8,230,255,0,26
    db 164,165,0,105,181,255,96,5,104,255,0,4,230,0,101,255,96,7,104,154,0,230,255,0,8,230,255,0,4,164,165,157,105,104,154,255,0,3
    db 96,152,153,154,0,164,165,255,0,4,105,181,180,181,96,255,160,7,150,155,255,0,3,230,101,96,255,160,4,166,255,160,3,180,96,181,96,104,154,255,0,5,230,0,0,105,96,180,181,181,160,166,180,152,153,154
    db 255,160,3,180,96,180,181,255,96,4,255,160,8,166,255,160,4,150,255,96,5,255,160,14,180,255,96,5,181,96,96,151,255,160,9,180
    ;; Run-length encoding (size: 1758)

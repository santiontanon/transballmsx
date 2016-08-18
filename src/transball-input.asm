;-----------------------------------------------
; Checks the status of the joystick or arrow keys 
; this function is slow, so, I only use it in the title screen
; in-game I use another, more optimized version
GETSTCK0AND1:
    xor a
    call GTSTCK
    and a   ;; equivalent to cp 0, but faster
    jp z,GETSTCK0AND1_CALL1
    ret
GETSTCK0AND1_CALL1:
    inc a
    call GTSTCK
    ret


;-----------------------------------------------
; Checks the status of the joystick or arrow keys 
; this function is slow, so, I only use it in the title screen
; in-game I use another, more optimized version
GTTRIG0AND1:
    xor a
    call GTTRIG
    and a   ;; equivalent to cp 0, but faster
    jp z,GTTRIG0AND1_CALL1
    ret
GTTRIG0AND1_CALL1:
    inc a
    call GTTRIG
    ret


;-----------------------------------------------
; checks all the player input (left/right/thrust/fire)
checkInput:
    xor a
    ld (thruster_spriteattributes+3),a
    
    ld a,#04    ;; get the status of the 4th keyboard row (to get the status of the 'M' key)
    call SNSMAT
    cpl         
    and #04     ;; keep just bit 2: A = #04 if 'M' was pressed, and A = #00 if it was not
    ld b,a      ;; store this in B
    ld a,#08    ;; get the status of the 8th keyboard row (to get SPACE and arrow keys)
    call SNSMAT 
    cpl
    and #f1     ;; keep only the arrow keys and space
    or b        ;; add 'M' in bit 2
    jp z,Readjoystick   ;; if no key was pressed, then check the joystick
    bit 7,a
    call nz,TurnRight
    bit 4,a
    call nz,TurnLeft
    bit 0,a
    call z,noFireBullet
    bit 0,a
    push af
    call nz,FireBullet
    pop af
    and #24     ;; up or 'M' key
    jp nz,Thrust
    ret

Readjoystick:   
    ;; direct access method (I was told this might not be very compatible):
;    ld  a, 15   ;; read the joystick 1 status:
;    out (#a0), a
;    in  a, (#a2)
;    and #af
;    out (#a1), a
;    ld  a, 14
;    out (#a0), a
;    in  a, (#a2) 

    ;; Using BIOS calls:
    ld a,15   ;; read the joystick 1 status:
    call RDPSG
    and #af
    ld e,a
    ld a,15
    call WRTPSG
    dec a
    call RDPSG    

    cpl         ;; invert the bits (so that '1' means direction pressed)
    bit 3,a
    call nz,TurnRight
    bit 2,a
    call nz,TurnLeft
    bit 4,a
    call z,noFireBullet
    bit 4,a
    push af
    call nz,FireBullet
    pop af
    and #21     ;; up or second button
    jp nz,Thrust
    ret

TurnLeft:    
    ld d,a
    
    ld a,(current_game_frame)
    and #07
    ld hl,ship_rotation_speed_pattern
    ld b,0
    ld c,a
    add hl,bc
    ld a,(hl)
    and a
    jr z,TurnLeft_dont_turn

    ld a,(shipangle)
    dec a
    and #3f
    ld (shipangle),a
TurnLeft_dont_turn:
    ld a,d
    ret

TurnRight:  
    ld d,a

    ld a,(current_game_frame)
    and #07
    ld hl,ship_rotation_speed_pattern
    ld b,0
    ld c,a
    add hl,bc
    ld a,(hl)
    and a
    jr z,TurnRight_dont_turn

    ld a,(shipangle)
    inc a
    and #3f
    ld (shipangle),a
TurnRight_dont_turn:
    ld a,d
    ret

Thrust:
    ld a,(current_fuel_left)    
    and a   ;; equivalent to cp 0, but faster
    ret z   ;; if we have no fuel left, return

    ;; decrease fuel
    ld a,(current_fuel_left+1)
    dec a
    ld (current_fuel_left+1),a
    jr nz,Thrust_do_not_lose_major_fuel_unit
    ld a,FUEL_UNIT
    ld (current_fuel_left+1),a
    ld a,(current_fuel_left)
    dec a
    ld (current_fuel_left),a

Thrust_do_not_lose_major_fuel_unit:
    ; play SFX:
    ld a,(SFX_play)
    and a   ;; equivalent to cp 0, but faster
    jr nz,skip_thrust_sound

    ld hl,SFX_thrust
    call play_SFX

skip_thrust_sound:
    ld bc,0
    ld a,(shipangle)
    sra a
    and #1f ;; 32 angle steps
    sla a
    ld c,a
    push bc

    ld hl,y_1pixel_velocity
    add hl,bc
    ld e,(hl)
    inc hl
    ld d,(hl)
    ld hl,(shipvelocity)
    add hl,de
    ld bc,MAXSPEED
    call HL_NOT_BIGGER_THAN_BC
    ld bc,MINSPEED
    call HL_NOT_SMALLER_THAN_BC
    ld (shipvelocity),hl

    pop bc
    ld hl,x_1pixel_velocity
    add hl,bc
    ld e,(hl)
    inc hl
    ld d,(hl)
    ld hl,(shipvelocity+2)
    add hl,de
    ld bc,MAXSPEED
    call HL_NOT_BIGGER_THAN_BC
    ld bc,MINSPEED
    call HL_NOT_SMALLER_THAN_BC
    ld (shipvelocity+2),hl

    ld a,THRUSTERCOLOR
    ld (thruster_spriteattributes+3),a
    ret


noFireBullet:
    ld b,a
    xor a
    ld (fire_button_status),a
    ld a,b
    ret

FireBullet:
    ld a,(fire_button_status)
    and a   ;; equivalent to cp 0, but faster
    ret nz

    inc a   ;; set the fire button status to 1
    ld (fire_button_status),a

    ;; check if there is any bullet slot available:
    ld c,0
    ld hl,player_bullet_active
checkFireButton_checking_for_free_slot:
    ld a,(hl)
    and a   ;; equivalent to cp 0, but faster
    jr z,checkFireButton_fireBullet
    inc hl
    inc c
    ld a,c
    cp MAX_PLAYER_BULLETS
    jr nz,checkFireButton_checking_for_free_slot
    ret

checkFireButton_fireBullet:
    ld (hl),1   ;; bullet is fired
    ld hl,player_bullet_positions
    sla c   ;; multiply c by 4 (to get the offset of the bullet coordinates)
    sla c 
    ld b,0
    add hl,bc
    ex de,hl
    ld hl,shipposition  
    push bc
    ldi     ;; copy the ship position to the bullet position
    ldi
    ldi
    ldi
    pop bc

    ld hl,player_bullet_velocities
    add hl,bc
    ex de,hl

    ;; set the bullet speed:    
    ld bc,0
    ld a,(shipangle)
    sra a
    and #1f ;; 32 angle steps
    sla a
    ld c,a
    ld hl,y_4pixel_velocity
    add hl,bc
    ldi
    ldi

    inc bc
    inc bc

    ld hl,x_4pixel_velocity
    add hl,bc
    ldi
    ldi

    ld hl,SFX_bullet    ;; play the bullet SFX!
    call play_SFX

    ret


;-----------------------------------------------
; checks whether any of the keys from 1 - 5 have been pressed and changes ship rotation speed accordingly
; also changes scroll mode by checking keys 6 and 7
checkForRotationSpeedConfigInput:
    call CHSNS
    ret z

    call CHGET
    cp '1'
    jr z,set_ship_rotation_100
    cp '2'
    jr z,set_ship_rotation_87
    cp '3'
    jr z,set_ship_rotation_75
    cp '4'
    jr z,set_ship_rotation_62
    cp '5'
    jr z,set_ship_rotation_50
    cp '6'
    jr z,set_msx1_scroll
    cp '7'
    jr z,set_msx2_scroll
    ret


;-----------------------------------------------
; checks whether any of the keys from 1 - 5 have been pressed and changes ship rotation speed accordingly
;checkForRotationSpeedConfigInputInGame:
;    call CHSNS
;    ret z
;
;    call CHGET
;    cp '1'
;    jr z,set_ship_rotation_100_no_message
;    cp '2'
;    jr z,set_ship_rotation_87_no_message
;    cp '3'
;    jr z,set_ship_rotation_75_no_message
;    cp '4'
;    jr z,set_ship_rotation_62_no_message
;    cp '5'
;    jp z,set_ship_rotation_50_no_message
;    ret    


set_ship_rotation_100:
    ld hl,speed_change_message_100
    call display_config_change_message
set_ship_rotation_100_no_message:
    ld a,1
    ld hl,ship_rotation_speed_pattern
    ld (hl),a
    inc hl
    ld (hl),a
    inc hl
    ld (hl),a
    inc hl
    ld (hl),a
    inc hl
    ld (hl),a
    inc hl
    ld (hl),a
    inc hl
    ld (hl),a
    inc hl
    ld (hl),a
    inc hl
    ret

set_ship_rotation_87:
    ld hl,speed_change_message_87
    call display_config_change_message
set_ship_rotation_87_no_message:
    call set_ship_rotation_100_no_message

    xor a
    ld (ship_rotation_speed_pattern+7),a
    ret

set_ship_rotation_75:
    ld hl,speed_change_message_75
    call display_config_change_message
set_ship_rotation_75_no_message:
    call set_ship_rotation_87_no_message

    ld (ship_rotation_speed_pattern+3),a
    ret

set_ship_rotation_62:
    ld hl,speed_change_message_62
    call display_config_change_message
set_ship_rotation_62_no_message:
    call set_ship_rotation_87_no_message

    ld (ship_rotation_speed_pattern+2),a
    ld (ship_rotation_speed_pattern+5),a
    ret

set_ship_rotation_50:
    ld hl,speed_change_message_50
    call display_config_change_message
set_ship_rotation_50_no_message:
    call set_ship_rotation_75_no_message

    ld (ship_rotation_speed_pattern+1),a
    ld (ship_rotation_speed_pattern+5),a
    ret


set_msx1_scroll:
    xor a
    ld (useSmoothScroll),a

    ld hl,scroll_change_message_msx1
    jp display_config_change_message    

set_msx2_scroll:
    ld a,(isMSX2)
    and a
    ret z   ;; if we cannot use smooth scroll, then ignore

    ld a,1
    ld (useSmoothScroll),a

    ld hl,scroll_change_message_msx2
    jp display_config_change_message


display_config_change_message:
    ld de,currentMap+23*32
    ld bc,5
    ldir    
    ret

;-----------------------------------------------
; checks whether the player is pressing the left or right keys to turn the ship
checkJoystick:    ;; these are "jp" instead of "call", so that when "MoveUp", etc. do a "ret", we directly go out of this function
    xor a
    call GTSTCK
    cp 2
    jr z,TurnRight
    cp 3
    jr z,TurnRight
    cp 4
    jr z,TurnRight
    cp 6
    jr z,TurnLeft
    cp 7
    jr z,TurnLeft
    cp 8
    jr z,TurnLeft
    ret
TurnLeft:    
    ld a,(shipangle)
    dec a
    and #3f
    ld (shipangle),a
    ret
TurnRight:  
    ld a,(shipangle)
    inc a
    and #3f
    ld (shipangle),a
    ret


;-----------------------------------------------
; Checks whether the player is pressing the "up" key and applies thruster accordingly
checkThrust:
    xor a
    ld (thruster_spriteattributes+3),a

    ld a,(current_fuel_left)    
    cp 0
    ret z   ;; if we have no fuel left, return

    xor a
    call GTSTCK
    cp 8
    jr z,Thrust
    cp 1
    jr z,Thrust
    cp 2
    jr z,Thrust    
    ret
Thrust:
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
    cp 0
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


;-----------------------------------------------
; Checks whether the player is pressing "space", to fire bullets
checkFireButton:
    ld a,(fire_button_status)
    ld b,a
    xor a
    call GTTRIG
    ld (fire_button_status),a
    cp 0
    ret z

    ld a,b
    cp 0
    ret nz

    ;; check if there is any bullet slot available:
    ld c,0
    ld hl,player_bullet_active
checkFireButton_checking_for_free_slot:
    ld a,(hl)
    cp 0
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

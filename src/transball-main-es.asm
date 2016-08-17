    include "transball-constants.asm"

    org #4000   ; Somewhere out of the way of small basic programs

;-----------------------------------------------
    db "AB"     ; ROM signature
    dw Execute  ; start address
    db 0,0,0,0,0,0,0,0,0,0,0,0
;-----------------------------------------------


;-----------------------------------------------
; Code that gets executed when the game starts
Execute:
    call move_ROMpage2_to_memorypage1
    call save_interrupts

    call VDP_IsTMS9918A
    jr z,Execute_MSX1
Execute_MSX2:
    ld a,1
    ld (isMSX2),a
    ld (useSmoothScroll),a
    jr Execute_Continue
Execute_MSX1:
    xor a
    ld (isMSX2),a
    ld (useSmoothScroll),a
Execute_Continue:

    ; set default ship rotation speed:
    call set_ship_rotation_100

    ; Silence and init keyboard:
    xor a
    ld (CLIKSW),a
    ld (fire_button_status),a

    ld a,2      ; Change screen mode
    call CHGMOD
;    call setup_VDP_addresses

    ; Change colors:
    ld a,15
    ld (FORCLR),a
    xor a
    ld (BAKCLR),a
    ld (BDRCLR),a
    call CHGCLR

    ;; clear the screen
    xor a
    call FILLSCREEN

    ; Define the graphic patterns:
    call SETUPPATTERNS
    call DECOMPRESS_SPRITES

    ;; 16x16 sprites:
    ld bc,#e201  ;; write #e2 in VDP register #01 (activate sprites, generate interrupts, 16x16 sprites with no magnification)
    call WRTVDP

    call setupBaseSprites

    ;; clear the best times:
    ld hl,best_times
    ld b,16
clear_best_times_loop:
    ld (hl),10   ;; minutes (setting it to 10, means "no-time-yet")
    inc hl
    ld (hl),0   ;; ten seconds
    inc hl
    ld (hl),0   ;; seconds
    inc hl
    ld (hl),0  ;; tenths of a second
    inc hl
    ld (hl),0  ;; hundredths of a second
    inc hl
    djnz clear_best_times_loop

    jp SplashScreen


;-----------------------------------------------
; Source: (thanks to ARTRAG) https://www.msx.org/forum/msx-talk/development/memory-pages-again
; Sets the memory pages to : BIOS, ROM, ROM, RAM
move_ROMpage2_to_memorypage1:
    call RSLREG     ; Reads the primary slot register
    rrca
    rrca
    and #03         ; keep the two bits for page 1
    ld c,a
    add a,#C1       
    ld l,a
    ld h,#FC        ; HL = EXPTBL + a
    ld a,(hl)
    and #80         ; keep just the most significant bit (expanded or not)
    or c
    ld c,a          ; c = a || c (a had #80 if slot was expanded, and #00 otherwise)
    inc l           
    inc l
    inc l
    inc l           ; increment 4, in order to get tot the corresponding SLTTBL
    ld a,(hl)       
    and #0C         
    or c            ; in A the rom slotvar 
    ld h,#80        ; move page 1 of the ROM to page 2 in main memory
    call ENASLT       
    ret

;-----------------------------------------------
; additional assembler files
    include "transball-gameloop.asm"
    include "transball-interlevel.asm"
    include "transball-input.asm"
    include "transball-physics.asm"
    include "transball-enemies.asm"
    include "transball-scroll.asm"
    include "transball-auxiliar.asm"
    include "transball-sound.asm"
    include "transball-gfx.asm"
    include "transball-sprites.asm"
    include "transball-maps.asm"
    include "transball-titlescreen.asm"
    include "transball-song.asm"

InterLevel_text:
    db "    PULSA ESPACIO PARA EMPEZAR   "
Time_is_up_text:
    db "             TIEMPO!             "
Level_complete_text1:
    db  " FASE ACABADA! "
Level_complete_text2:
    db   "TIEMPO: 0:00:00"
Level_complete_text3:
    db   "RECORD: 0:00:00"
Level_complete_text4:
    db       "A - REPETIR"
Level_complete_text5:
    db "DISPARO - SIGUIENTE NIVEL"
Level_complete_text6:
    db     "ESC - SALIR"


splash_line1:
    db "BRAIN  GAMES"
splash_line2:
    db "PRESENTA"


game_complete_line1:
    db "  FELICIDADES!  "
game_complete_line2:
    db "HAS RECOLECTADO TODAS LAS "
game_complete_line3:
    db "ESFERAS DE ENERGIA!"


highscores_header:
    db " RECORDS  "
highscores_text:
    db "FASE       0:00:00"

titlescreen:
    db 0,0,83,65,78,84,73,0,40,80,79,80,79,76,79,78,41,0,79,78,84,65,78,79,78,0,50,48,49,54,255,0,68
    db 255,255,1,206,239,203,231,202,203,231,202,247,0,0,247,203,231,239,203,202,0,203,231,202,247,0,0,247,255,0,7
    db 230,0,230,0,230,230,0,230,207,202,0,230,230,0,0,230,230,0,230,0,230,230,0,0,230,255,0,7
    db 230,0,230,0,230,230,0,230,230,204,202,230,230,0,0,230,230,0,230,0,230,230,0,0,230,255,0,7
    db 230,0,207,206,201,207,231,205,230,0,204,205,204,231,202,207,246,202,207,231,205,230,0,0,230,255,0,7
    db 230,0,230,204,202,230,0,230,230,0,0,230,0,0,230,230,0,230,230,0,230,230,0,0,230,255,0,7
    db 247,0,247,0,247,247,0,247,247,0,0,247,255,255,1,231,201,204,231,201,247,0,247,204,231,239,204,231,239,255,0,3
    db 101,97,255,96,26,97,100,255,0,3
    db 149,92,92,160,161,176,160,176,161,160,176,161,161,160,176,176,161,161,160,160,161,177,176,176,160,91,91,95,255,0,7
    db 149,92,92,161,91,91,255,92,3,91,91,92,91,92,91,255,92,4,161,92,95,255,0,13
    db 230,255,0,15,230,255,0,15
    db 230,255,0,15,230,255,0,8
    db 248,249,255,0,5,230,255,0,15,230,255,0,5,134,105
    db 96,181,180,96,96,100,101,96,180,106,255,0,12,101,97,180,155,0,164,165,105,181,160
    db 177,176,161,161,160,96,96,161,161,128,255,0,3,69,77,80,69,90,65,82,255,0,3,129,177,150,96,180,181,151,176,255,161,3
    db 160,255,161,4,176,177,95,255,0,13,149,177,160,177,177,160,176,177,177
    db 160,161,176,162,163,160,177,160,128,255,0,4,82,69,67,79,82,68,83,255,0,4,129,176,161,161,183,161,161,160
    db 177,176,160,178,179,176,177,160,98,255,0,15,149,177,160,160,255,161,3,160
    db 182,160,176,160,160,176,176,160,128,255,0,5,67,76,65,86,69,255,0,6,129,160,177,176,161,166,176
    db 160,255,161,4,183,161,177,93,255,0,16,94,160,255,177,5
    db 255,161,3,177,255,161,3,177,95,255,0,16,149,161,161,182,255,161,6
    db 255,177,4,95,255,0,18,149,161,255,177,3,161
    ;; Run-length encoding (size: 505)

speed_change_message_100:
    db "X1.00"
speed_change_message_87:
    db "X0.87"
speed_change_message_75:
    db "X0.75"
speed_change_message_62:
    db "X0.62"
speed_change_message_50:
    db "X0.50"

scroll_change_message_msx1:
    db "MSX 1"
scroll_change_message_msx2:
    db "MSX 2"

;-----------------------------------------------
; Game variables to be copied to RAM
ROMtoRAM:
map_offsetROM:     ;; top-left coordinates of the portion of the map drawn on screen (lowest 4 bits are the decimal part)
    dw 0, 0
shipstateROM:
    db 0
shipangleROM:      ;; angle goes from 0 - 255
    db 0
shippositionROM:
    dw 16*16,128*16      ;; lowest 4 bits are the decimal part
shipvelocityROM:
    dw 0,0
ballpositionROM:
    dw 0,0
ballvelocityROM:
    dw 0,0
balldragTimerROM:
    db 0
scoreboardROM:
    db "FUEL -----  FASE 00 TIEMPO 00:00"
scoreboard_level_offset: equ 17

InterLevel_text2ROM:
    db "CLAVE:     "
InterLevel_text2_passwordROM:
    db "XXXXXXXX"


;; These variables need to be at the end of the ROM-to-RAM space, since they need to be contiguous with the bullet sprites, which are not in ROM
thruster_spriteattributesROM:
    db 64,64,THRUSTER_SPRITE*4,THRUSTERCOLOR    ;; 4 is the address of the second sprite shape, 
                                ;; since we are in 16x16 sprite mode, each shape is 4 blocks in size
ship_spriteattributesROM:       
    db 64,64,SHIP_SPRITE*4,SHIPCOLOR

ball_spriteattributesROM:
    db 0,0,BALL_SPRITE*4,0     
endROMtoRAM:


End:

    ds ((($-1)/#4000)+1)*#4000-$


;-----------------------------------------------
; Cartridge ends here, below is just a definition of the RAM space used by the game 
;-----------------------------------------------


    org #c000
RAM:    
map_offset:      ;; top-left coordinates of the portion of the map drawn on screen (lowest 4 bits are the decimal part)
    ds virtual 4
shipstate:
    ds virtual 1    ;; 0: ship alive, 1: ship collided
shipangle:       ;; angle from 0 - 63
    ds virtual 1
shipposition:
    ds virtual 4    ;; lowest 4 bits are the decimal part
shipvelocity:
    ds virtual 4
ballposition:
    ds virtual 4
ballvelocity:
    ds virtual 4
balldragTimer:
    ds virtual 1
scoreboard:
    ds virtual 32
InterLevel_text2:
    ds virtual 11
InterLevel_text2_password:
    ds virtual 8

thruster_spriteattributes:
    ds virtual 4
ship_spriteattributes:
    ds virtual 4
ball_spriteattributes:
    ds virtual 4

AdditionalRAM:  ;; things that are not copied from ROM at the beginning

enemy_bullet_sprite_attributes:
    ds virtual 4*MAX_ENEMY_BULLETS

player_bullet_sprite_attributes:
    ds virtual 4*MAX_PLAYER_BULLETS

current_level:
    ds virtual 1
current_play_time:
    ds virtual 4    ;; minutes, 10 seconds, seconds, frames
current_fuel_left:
    ds virtual 2
current_map_ship_limits:
    ds virtual 8
current_map_dimensions:
    ds virtual 4    ;; byte 0: height, byte 1: width, bytes 2,3: width*height
currentMap:
    ds virtual MAXMAPSIZE*MAXMAPSIZE

;; animations:
currentNAnimations:
    ds virtual 1
currentAnimations:
    ds virtual MAXANIMATIONS*6  ;; each animation: map pointer (dw), animation definition pointer (dw), timer (db), step (db)

;; enemies:
currentNEnemies:
    ds virtual 1
currentEnemies:
    ;; each enemy is 11 bytes:
    ;; type (1 byte)
    ;; map pointer (2 bytes)
    ;; enemy type pointer (2 bytes)
    ;; y (2 bytes)
    ;; x (2 bytes)
    ;; state (1 byte)
    ;; health (1 byte)
    ds virtual MAXENEMIES*11

;; tanks:
currentNTanks:
    ds virtual 1
currentTanks:
    ;; each tank is 8 bytes:
    ;; health (1 byte)
    ;; fire state (1 byte)
    ;; movement state (1 byte)
    ;; y (1 byte)   (in map pattern coordinates)
    ;; x (1 byte)   (in map pattern coordinates)
    ;; map pointer (2 bytes)
    ;; turret angle: 0 (left), 1 (left-up), 2 (right-up), 3 (right)
    ds virtual MAX_TANKS*8

;; bullets:
player_bullet_active:
    ds virtual MAX_PLAYER_BULLETS
player_bullet_positions:
    ds virtual 2*2*MAX_PLAYER_BULLETS
player_bullet_velocities:
    ds virtual 2*2*MAX_PLAYER_BULLETS

;; enemy bullets:
enemy_bullet_active:
    ds virtual MAX_PLAYER_BULLETS
enemy_bullet_positions:
    ds virtual 2*2*MAX_PLAYER_BULLETS
enemy_bullet_velocities:
    ds virtual 2*2*MAX_PLAYER_BULLETS

ballstate:
    ds virtual 1    ;; 0: inactive, 1: active
levelComplete:
    ds virtual 1

;; doors:
ndoors:
    ds virtual 1    
doors:
    ds virtual 3*MAX_DOORS  ;; 1st byte is state (0 closed, 1 open), 2nd and 3rd byte are a pointer to the map position

;; ball doors (doors that are open/closed when the ball is picked up):
nballdoors:
    ds virtual 1    
balldoors:
    ds virtual 3*MAX_DOORS  ;; 1st byte is state (0 closed, 1 open), 2nd and 3rd byte are a pointer to the map position

;; explosions:
explosions_active:
    ds virtual MAX_EXPLOSIONS
explosions_positions_and_replacement:
    ds virtual 4*MAX_EXPLOSIONS     ;; ptr_to_map_position,ptr_to_replacement_pattern_aftet_explosion 

;; main menu variables:
menu_selected_option:
    ds virtual 1
menu_timer:
    ds virtual 1
menu_input_buffer:  ;; previous state of the joystick
    ds virtual 1
fire_button_status:
    ds virtual 1

;; music/SFX variables:
;; SFX:
SFX_play:       ds virtual 1
MUSIC_play:       ds virtual 1
SFX_skip_counter:  ds virtual 1
SFX_pointer:    ;; pointer and channel1_pointer are the same
SFX_channel1_pointer:    ds virtual 2
SFX_channel2_pointer:    ds virtual 2
SFX_channel3_pointer:    ds virtual 2
SFX_channel1_skip_counter:  ds virtual 1
SFX_channel2_skip_counter:  ds virtual 1
SFX_channel3_skip_counter:  ds virtual 1
SFX_channel1_repeat_stack_ptr:  ds virtual 2
SFX_channel2_repeat_stack_ptr:  ds virtual 2
SFX_channel3_repeat_stack_ptr:  ds virtual 2
MUSIC_tempo:  ds virtual 1
MUSIC_tempo_counter: ds virtual 1
SFX_channel1_repeat_stack:  ds virtual 4*3
SFX_channel2_repeat_stack:  ds virtual 4*3
SFX_channel3_repeat_stack:  ds virtual 4*3

;; Sprites:
shipvpanther: ds virtual 32*32
shipvpanther_thruster: ds virtual 32*32

;; best times:
current_time_buffer:
    ds virtual 5
best_times:
    ds virtual 16*5 ;; 5 bytes per map
password_buffer:
best_times_buffer:
    ds virtual 32   ;; a one line buffer, to write things to screen

;; temporary variables:
ballPositionBeforePhysics:  ;; temporary storage to restore the position of the ball after a collision
    ds virtual 4
ballCollisioncount:         ;; temporary variable to count the number of points that collide with the ball
bulletType_tmp:             ;; temporary variable storing the type of bullet we are considering in the physics code
    ds virtual 1


;; variables to control the ship rotation speed:
ship_rotation_speed_pattern:
    ds virtual 8 

;; variables for the smooth scroll interrupt:
old_HKEY_interrupt_buffer:
    ds virtual 3
;old_TIMI_interrupt_buffer:
;    ds virtual 1
vertical_scroll_for_r23:
    ds virtual 1
horizontal_scroll_for_r18:
    ds virtual 1
desired_vertical_scroll_for_r23:
    ds virtual 1
desired_horizontal_scroll_for_r18:
    ds virtual 1
desired_map_offset:  ;; this stores the desired_map_offset for the next frame, that will be copied to map_offset immediately after vsync
    ds virtual 4
current_game_frame:
    ds virtual 1
current_animation_frame:
    ds virtual 1
isMSX2:
    ds virtual 1
useSmoothScroll:
    ds virtual 1

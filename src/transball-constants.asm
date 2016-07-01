;-----------------------------------------------
DCOMPR: equ #0020
ENASLT: equ #0024
WRTVDP: equ #0047
WRTVRM: equ #004d
SETWRT: equ #0053
FILVRM: equ #0056
LDIRMV: equ #0059
LDIRVM: equ #005c
CHGMOD: equ #005f
CHGCLR: equ #0062
GICINI: equ #0090   
WRTPSG: equ #0093 
CHGET:  equ #009f
CHPUT:  equ #00a2
GTSTCK: equ #00d5
GTTRIG: equ #00d8
RSLREG: equ #0138
KILBUF: equ #0156
;-----------------------------------------------
; System variables
VDP_DATA: equ #98
CLIKSW: equ #f3db       ; keyboard sound
FORCLR: equ #f3e9
BAKCLR: equ #f3ea
BDRCLR: equ #f3eb
PUTPNT: equ #f3f8
GETPNT: equ #f3fa
KEYS:   equ #fbe5    
KEYBUF: equ #fbf0
EXPTBL: equ #fcc1
JPCODE: equ #c3
;-----------------------------------------------
; VRAM map in Screen 2
CHRTBL2:  equ     #0000   ; pattern table address
SPRTBL2:  equ     #3800   ; sprite pattern address          
NAMTBL2:  equ     #1800   ; name table address 
CLRTBL2:  equ     #2000   ; color table address             
SPRATR2:  equ     #1b00   ; sprite attribute address            
;-----------------------------------------------
; game constants:
SHIPCOLOR:      equ 7
THRUSTERCOLOR:  equ 8
PLAYER_BULLET_COLOR: equ 15
ENEMY_BULLET_COLOR: equ 10
BALL_INACTIVE_COLOR: equ 15
BALL_ACTIVE_COLOR: equ 5
MAXSPEED:       equ 1024
MINSPEED:       equ -1024
BALLDRAG:       equ 2
GRAVITY:        equ 3
MAXMAPSIZE:     equ 64      ;; maps cannot be larger than MAXMAPSIZE*MAXMAPSIZE in bytes
MAXANIMATIONS:  equ 64   ; the maximum number of tiles in the map that can animate
MAXENEMIES:     equ 32
FUEL_UNIT:      equ 128
MAX_PLAYER_BULLETS: equ 4
MAX_ENEMY_BULLETS: equ 4
MAX_EXPLOSIONS: equ 2
MAX_DOORS: equ 10
MAX_TANKS: equ 4
TANK_MOVE_SPEED: equ 25
BALL_ACTIVATION_DISTANCE: equ 16    ; (in pixels)
ENEMY_BULLET_COLLISION_SIZE: equ 4
CANON_COOLDOWN_PERIOD: equ  150
TANK_COOLDOWN_PERIOD: equ 100
; Sound definition constants:
SFX_REPEAT:     equ  #fa
SFX_END_REPEAT: equ  #fb
SFX_GOTO:       equ  #fc
SFX_SKIP:       equ  #fd
SFX_MULTISKIP:  equ  #fe
SFX_END:        equ  #ff
; GFX definition constants:
PATTERN_FUEL2:  equ  222
PATTERN_FUEL1:  equ  223
PATTERN_FUEL0:  equ  21
PATTERN_BALL_STAND: equ 147
PATTERN_EXPLOSION1: equ 172
PATTERN_EXPLOSION2: equ 174
PATTERN_LEFT_BALL_DOOR: equ 39
PATTERN_LEFT_DOOR: equ 239
PATTERN_RIGHT_DOOR: equ 255
PATTERN_DOOR_BEAM: equ 231
PATTERN_TANK: equ 1
PATTERN_H_LASER: equ 252
; map constants:
RLE_META:   equ #ff

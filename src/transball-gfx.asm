;-----------------------------------------------
; Updates all the sprite attribute tables to draw the following:
; - ship
; - thruster
; - ball
; - enemy bullets
; - player bullets
drawSprites:
    ;; draw all the sprites:
;    ld hl,SPRATR_CUSTOM
    ld hl,SPRATR_CUSTOM+8*4   ;; we don't use the first 8 sprites, since in MSX those bytes need to be 
                        ;; set to 0 (otherwise, we would see garbage when we move the scroll with 
                        ;; register r23).
    call SETWRT
    ex de,hl
    ld hl,thruster_spriteattributes
    ld b,4+4+4+MAX_PLAYER_BULLETS*4+MAX_ENEMY_BULLETS*4-32
    ld c,VDP_DATA
drawSprites_loop:
    outi
    jp nz,drawSprites_loop
	jp outi32
    

;-----------------------------------------------
; iterates over the set of explosions, and renders them onto the corrent_map
renderExplosions:
    ld hl,explosions_active
    ld ix,explosions_positions_and_replacement
    ld c,0
renderExplosions_loop:
    ld a,(hl)
    and a   ;; equivalent to cp 0, but faster
    jr z,renderExplosions_next_explosion

    cp 16
    jp p,renderExplosions_render_frame1
    cp 8
    jp p,renderExplosions_render_frame2


renderExplosions_render_frame1:
    ;; render explosion (frame 1)
    push hl
    push bc
    ld l,(ix)
    ld h,(ix+1)
    ld a,PATTERN_EXPLOSION1
    ld (hl),a
    inc hl
    ld a,PATTERN_EXPLOSION1+1
    ld (hl),a
    inc hl

    ld b,0
    ld a,(current_map_dimensions+1)
    ld c,a
    dec c
    dec c
    add hl,bc       ;; move to the next map row

    ld a,PATTERN_EXPLOSION1+16
    ld (hl),a
    inc hl
    ld a,PATTERN_EXPLOSION1+16+1
    ld (hl),a
    inc hl

    pop bc
    pop hl
    jr renderExplosions_after_render

renderExplosions_render_frame2:
    push hl
    push bc
    ld l,(ix)
    ld h,(ix+1)
    ld a,PATTERN_EXPLOSION2
    ld (hl),a
    inc hl
    ld a,PATTERN_EXPLOSION2+1
    ld (hl),a
    inc hl

    ld b,0
    ld a,(current_map_dimensions+1)
    ld c,a
    dec c
    dec c
    add hl,bc       ;; move to the next map row

    ld a,PATTERN_EXPLOSION2+16
    ld (hl),a
    inc hl
    ld a,PATTERN_EXPLOSION2+16+1
    ld (hl),a
    inc hl

    pop bc
    pop hl


renderExplosions_after_render:
    ld a,(hl)
    dec a
    ld (hl),a
    jr nz,renderExplosions_next_explosion

    ;; explosion is over:
    ;; restore the pattern:
    push hl
    push bc

    ld e,(ix)
    ld d,(ix+1)
    ld l,(ix+2)
    ld h,(ix+3)
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

    pop bc
    pop hl

renderExplosions_next_explosion:
    inc c
    inc hl
    inc ix
    inc ix
    inc ix
    inc ix
    ld a,MAX_EXPLOSIONS
    cp c
    jp nz,renderExplosions_loop

    ret


;-----------------------------------------------
; Sets all the patterns to the appropriate graphics and colors
SETUPPATTERNS:
    ;; decode the RLE-encoded patterns:
    ld ix,patterns
    ld de,currentMap    ;; decode into "currentMap", which is the largest buffer we have in RAM
    ld bc,2048
    call RLE_decode

    ld bc,2048
    ld de,CHRTBL2
    ld hl,currentMap
    call LDIRVM
    ld bc,2048
    ld de,CHRTBL2+2048
    ld hl,currentMap
    call LDIRVM
    ld bc,2048
    ld de,CHRTBL2+4096
    ld hl,currentMap
    call LDIRVM

    ;; decode the RLE-encoded pattern attributes:
    ld ix,patternattributes
    ld de,currentMap    ;; decode into "currentMap", which is the largest buffer we have in RAM
    ld bc,2048
    call RLE_decode

    ld bc,2048
    ld de,CLRTBL_CUSTOM
    ld hl,currentMap
    call LDIRVM
    ld bc,2048
    ld de,CLRTBL_CUSTOM+2048
    ld hl,currentMap
    call LDIRVM
    ld bc,2048
    ld de,CLRTBL_CUSTOM+4096
    ld hl,currentMap
    call LDIRVM

    ret


;-----------------------------------------------
; sets the base sprites at the beginning of the game
setupBaseSprites:
    ;; setup bullet sprite
    ld de,SPRTBL2+BULLET_SPRITE*32
    ld hl,player_bullet_sprite
    ld bc,32
    call LDIRVM
    ;; ball sprite:
    ld de,SPRTBL2+BALL_SPRITE*32
    ld hl,ball_sprite
    ld bc,32
    call LDIRVM
    ret


;-----------------------------------------------
;; clear sprites:
clearAllTheSprites:
    xor a
    ld bc,32*4
    ld hl,SPRATR_CUSTOM
    call FILVRM
    ret

;-----------------------------------------------
; Clears the screen left to right
clearScreenLeftToRight:
    call clearAllTheSprites

    ld a,32
    ld bc,0
clearScreenLeftToRightExternalLoop
    push af
    push bc
    ld a,24
    ld hl,NAMTBL2
    add hl,bc
clearScreenLeftToRightLoop:
    push hl
    push af
    xor a
    ld bc,1
    call FILVRM
    pop af
    pop hl
    ld bc,32
    add hl,bc
    dec a
    jr nz,clearScreenLeftToRightLoop
    
    ld a,(SFX_play)
    and a   ;; equivalent to cp 0, but faster
    call nz,SFX_INT   ;; if music is playing, keep playing it!
    ld a,(MUSIC_play)
    and a   ;; equivalent to cp 0, but faster
    call nz,MUSIC_INT   ;; if music is playing, keep playing it!
    halt
    
    pop bc
    pop af
    inc bc
    dec a
    jr nz,clearScreenLeftToRightExternalLoop
    ret


;-----------------------------------------------
; Fills the whole screen with the pattern in register 'a'
FILLSCREEN:
    ld bc,768
    ld hl,NAMTBL2
    call FILVRM
    ret


;-----------------------------------------------
; Sprite definition
shipvpanther_RLE_encoded1:
;; original data size: 288
    db 0,0,1,1,3,2,6,6,15,15,31,31,63,60,3,255
    db 0,3,128,128,192,64,96,96,240,240,248,248,252,60,192,255
    db 0,4,1,3,7,6,14,31,31,63,127,3,12,3,255,0
    db 3,192,192,224,32,96,96,224,255,240,4,248,56,255,0,5
    db 3,7,14,30,127,255,255,1,63,7,25,6,255,0,4,96
    db 224,224,32,32,96,255,240,6,48,255,0,5,1,7,31,127
    db 127,63,15,19,13,2,255,0,4,48,112,240,144,16,48,240
    db 255,224,5,96,255,0,6,15,127,127,63,15,23,11,5,1
    db 255,0,5,24,248,144,16,48,255,224,4,255,192,3,255,0
    db 5,1,127,127,63,31,47,23,23,11,3,1,255,0,5,252
    db 156,24,48,240,224,224,192,192,128,128,255,0,5,127,127,63
    db 63,31,47,47,23,23,7,3,2,255,0,5,252,156,24,48
    db 240,224,192,128,255,0,6,96,126,127,63,63,95,95,47,47
    db 15,12,8,255,0,6,240,220,28,56,240,224,128,255,0,6
    db 48,60,63,63,255,95,4,63,63,60,48,255,0,7,192,240
    db 28,28,240,192,255,0,5
    ;; Run-length encoding (size: 247)
shipvpanther_RLE_encoded2:
;; original data size: 256
    db 0,28,31,255,15,4,7,6,6,4,7,3,3,255,0,3
    db 192,48,192,254,252,248,248,112,96,224,192,128,255,0,4,12
    db 255,15,6,6,4,4,7,7,6,255,0,4,96,152,224,252
    db 255,255,1,254,120,112,224,192,255,0,5,6,255,7,5,15
    db 12,8,9,15,14,12,255,0,4,64,176,200,240,252,254,254
    db 248,224,128,255,0,5,255,3,3,255,7,4,12,8,9,31
    db 24,255,0,5,128,160,208,232,240,252,254,254,240,255,0,6
    db 1,1,3,3,7,7,15,12,24,57,63,255,0,5,128,192
    db 208,232,232,244,248,252,254,254,128,255,0,7,1,3,7,15
    db 12,24,57,63,255,0,5,64,192,224,232,232,244,244,248,252
    db 252,254,254,255,0,8,1,7,15,28,56,59,15,255,0,6
    db 16,48,240,244,244,250,250,252,252,254,126,6,255,0,8,3
    db 15,56,56,15,3,255,0,7,12,60,252,252,255,250,4,252
    db 252,60,12,0,0
    ;; Run-length encoding (size: 213)
shipvpanther_thruster_RLE_encoded1:
;; original data size: 288
    db 255,0,14,3,1,255,0,14,192,128,255,0,13,12,7,2
    db 255,0,28,24,14,4,255,0,28,16,28,14,255,0,28,16
    db 24,12,255,0,28,32,48,48,24,255,0,28,32,96,48,16
    db 255,0,27,64,192,96,32,255,0,26,64,192,192,64,255,0
    db 22
    ;; Run-length encoding (size: 65)
shipvpanther_thruster_RLE_encoded2:
;; original data size: 256
    db 255,0,16,64,224,48,255,0,30,32,112,24,255,0,30,112
    db 56,8,255,0,30,48,24,8,255,0,29,24,12,12,4,255
    db 0,28,8,12,6,4,255,0,29,4,6,3,2,255,0,30
    db 2,3,3,2,255,0,6
    ;; Run-length encoding (size: 55)

player_bullet_sprite:
    db #00,#00,#00,#00,#00,#00,#01,#03,#03,#01,#00,#00,#00,#00,#00,#00
    db #00,#00,#00,#00,#00,#00,#80,#c0,#c0,#80,#00,#00,#00,#00,#00,#00


explosion_sprites_outside:
    ; explosion1
    db #00,#00,#00,#04,#07,#05,#0c,#1c,#1c,#1f,#0b,#08,#00,#00,#00,#00
    db #00,#00,#00,#80,#a0,#60,#20,#30,#30,#e0,#60,#30,#00,#00,#00,#00
    ; explosion2
    db #00,#10,#38,#7f,#31,#18,#18,#10,#10,#34,#3f,#7b,#60,#40,#00,#00
    db #00,#70,#e6,#dc,#78,#30,#18,#1c,#18,#b0,#f0,#b8,#1c,#0c,#04,#00
    ; explosion3
    db #00,#70,#78,#7c,#30,#10,#00,#00,#00,#20,#70,#73,#e3,#e0,#c0,#80
    db #30,#7e,#e7,#5e,#18,#00,#04,#06,#0c,#00,#00,#c0,#9c,#0e,#0e,#06
    ; explosion4
    db #00,#60,#60,#00,#00,#00,#00,#00,#00,#00,#00,#00,#80,#80,#c0,#80
    db #30,#3e,#03,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#02,#02,#06


explosion_sprites_inside:
    ; explosion1
    db #00,#00,#00,#04,#07,#07,#0f,#1f,#1f,#1f,#0b,#08,#00,#00,#00,#00
    db #00,#00,#00,#80,#a0,#e0,#e0,#f0,#f0,#e0,#60,#30,#00,#00,#00,#00
    ; explosion2
    db #00,#10,#38,#7f,#3f,#1f,#1f,#1f,#1f,#3f,#3f,#7b,#60,#40,#00,#00
    db #00,#70,#e6,#dc,#f8,#f0,#f8,#fc,#f8,#f0,#f0,#b8,#1c,#0c,#04,#00
    ; explosion3
    db #00,#70,#78,#7f,#3f,#1c,#18,#18,#1c,#3c,#7f,#77,#e3,#e0,#c0,#80
    db #30,#7e,#e7,#de,#f8,#70,#3c,#1e,#1c,#70,#f0,#f0,#9c,#0e,#0e,#06
    ; explosion4
    db #00,#60,#78,#3c,#1c,#06,#00,#00,#00,#00,#70,#78,#f0,#c0,#c0,#80
    db #30,#3e,#7f,#f8,#10,#00,#00,#00,#00,#00,#00,#08,#3c,#1e,#06,#06

ball_sprite:
    db #00,#00,#03,#0f,#1b,#17,#37,#3f,#3f,#3f,#1f,#1f,#0f,#03,#00,#00
    db #00,#00,#c0,#f0,#f8,#f8,#fc,#fc,#fc,#fc,#f8,#f8,#f0,#c0,#00,#00


;-----------------------------------------------
; Graphic pattern definition   
;; encoded: 2048
;; original size: 2048,RLE size: 1909
patterns:
    db #ff, #00, #0b, #7c, #00, #c0, #f0, #3f, #02, #0f, #3f, #fc, #30, #c0, #c0, #80, #ff
    db #00, #03, #0f, #3f, #c0, #c0, #80, #ff, #00, #03, #f0, #fc, #03, #03, #01, #ff, #00
    db #03, #3e, #00, #03, #0f, #fc, #00, #fc, #f0, #ff, #e1, #03, #1f, #1f, #00, #3f, #0f
    db #ff, #87, #03, #f8, #f8, #fe, #80, #17, #17, #57, #17, #57, #50, #00, #00, #80, #c0
    db #e0, #80, #7f, #e1, #00, #00, #01, #03, #07, #01, #fe, #87, #7f, #01, #e8, #e8, #ea
    db #e8, #ea, #0a, #00, #ea, #80, #3f, #00, #be, #be, #2e, #00, #af, #01, #fc, #00, #7d
    db #7d, #7c, #ff, #03, #07, #1c, #c0, #ff, #40, #04, #c0, #c0, #38, #3f, #7f, #3f, #40
    db #58, #20, #18, #07, #00, #03, #03, #02, #1a, #1a, #02, #fc, #00, #c0, #c0, #40, #58
    db #58, #40, #3f, #fc, #fe, #e0, #18, #04, #1a, #02, #fc, #40, #f0, #fc, #3f, #0c, #03
    db #03, #01, #ff, #00, #03, #22, #22, #ff, #00, #03, #07, #18, #39, #71, #21, #01, #00
    db #00, #e0, #18, #9c, #8e, #84, #80, #00, #00, #50, #57, #17, #57, #17, #17, #80, #fe
    db #00, #7f, #80, #e0, #c0, #80, #ff, #00, #03, #fe, #01, #07, #03, #01, #00, #00, #0a
    db #ea, #e8, #ea, #e8, #e8, #01, #7f, #1c, #ff, #03, #07, #38, #c0, #c0, #ff, #40, #04
    db #c0, #2e, #be, #be, #00, #3f, #80, #ea, #00, #7c, #7d, #7d, #00, #fc, #01, #af, #ff
    db #00, #09, #ff, #20, #05, #00, #20, #00, #6c, #24, #48, #ff, #00, #05, #28, #28, #7c
    db #28, #7c, #28, #28, #00, #3c, #50, #50, #38, #14, #14, #78, #00, #64, #68, #08, #10
    db #20, #2c, #4c, #00, #20, #50, #20, #54, #48, #4c, #30, #00, #00, #b8, #de, #d3, #d3
    db #de, #b8, #00, #10, #20, #ff, #40, #03, #20, #10, #00, #10, #08, #ff, #04, #03, #08
    db #10, #00, #10, #54, #38, #7c, #38, #54, #10, #ff, #00, #03, #10, #38, #10, #ff, #00
    db #07, #30, #10, #20, #ff, #00, #04, #38, #ff, #00, #08, #30, #30, #00, #00, #04, #08
    db #08, #10, #20, #20, #40, #00, #6c, #ff, #ee, #05, #6c, #00, #ff, #38, #07, #00, #ec
    db #ce, #9c, #38, #72, #e6, #ee, #00, #2c, #6e, #0e, #0c, #0e, #6e, #2c, #00, #2e, #6e
    db #6e, #ee, #ee, #0e, #0e, #00, #fe, #fe, #00, #fc, #0e, #0e, #fc, #00, #6e, #ee, #e0
    db #ec, #ee, #ee, #6c, #00, #fe, #fe, #1c, #ff, #38, #04, #00, #6c, #ee, #ee, #6c, #ee
    db #ee, #6c, #00, #6c, #ee, #ee, #6e, #0e, #0e, #7c, #00, #ff, #38, #03, #00, #ff, #38
    db #03, #ff, #00, #03, #30, #00, #30, #10, #20, #00, #00, #08, #10, #20, #10, #08, #ff
    db #00, #04, #38, #00, #38, #ff, #00, #04, #20, #10, #08, #10, #20, #00, #00, #70, #88
    db #08, #10, #20, #00, #20, #00, #38, #44, #04, #34, #54, #54, #38, #00, #10, #38, #38
    db #5c, #5c, #ee, #ee, #00, #ec, #ee, #ee, #ec, #ee, #ee, #ec, #00, #6c, #ee, #ff, #e0
    db #03, #ee, #6c, #00, #ec, #ff, #ee, #05, #ec, #00, #fe, #fe, #00, #fe, #e0, #e0, #fe
    db #00, #fe, #fe, #00, #fe, #ff, #e0, #03, #00, #6c, #ee, #e0, #ee, #e6, #e6, #6c, #00
    db #ff, #ee, #03, #fe, #ff, #ee, #03, #00, #ff, #38, #07, #00, #ff, #0e, #05, #ee, #6c
    db #00, #ee, #ec, #e8, #e0, #e8, #ec, #ee, #00, #ff, #e0, #04, #e2, #e6, #ee, #00, #82
    db #c6, #ff, #ee, #05, #00, #86, #c6, #66, #b6, #da, #cc, #c6, #00, #6c, #ff, #ee, #05
    db #6c, #00, #ec, #ee, #ee, #ec, #ff, #e0, #03, #00, #6c, #ee, #ee, #e6, #ea, #ec, #66
    db #00, #ec, #ee, #ec, #e0, #e8, #ec, #ee, #00, #6e, #e6, #72, #38, #9c, #ce, #ec, #00
    db #fe, #fe, #00, #ff, #38, #04, #00, #ff, #ee, #06, #6c, #00, #ff, #ee, #03, #6c, #6c
    db #28, #28, #00, #ff, #ee, #05, #c6, #82, #00, #ee, #ee, #74, #38, #5c, #ee, #ee, #00
    db #ff, #ee, #03, #6c, #ff, #38, #03, #00, #ee, #ce, #9c, #38, #72, #e6, #ee, #00, #00
    db #6f, #00, #fe, #b7, #8f, #9e, #0c, #7f, #00, #f7, #00, #00, #9b, #33, #01, #fe, #de
    db #fc, #fe, #fc, #f8, #fc, #fe, #7f, #3b, #7f, #7f, #ff, #3f, #03, #7f, #fe, #7e, #be
    db #fc, #fe, #fe, #be, #1c, #6b, #00, #37, #00, #df, #00, #fb, #00, #18, #00, #d4, #80
    db #fd, #df, #fb, #00, #ec, #fe, #fe, #dc, #ff, #fe, #04, #6f, #ff, #7f, #03, #3b, #ff
    db #7f, #03, #00, #e0, #c0, #c0, #80, #80, #ff, #00, #03, #07, #03, #03, #01, #01, #ff
    db #00, #05, #e0, #ff, #e1, #04, #00, #c0, #c0, #00, #ff, #c7, #04, #c0, #f8, #fc, #fc
    db #fe, #0f, #03, #01, #07, #0f, #3f, #3f, #7f, #e0, #80, #80, #f8, #fc, #fe, #03, #01
    db #fb, #df, #ff, #00, #04, #e0, #f8, #f8, #fe, #07, #ff, #00, #03, #01, #07, #1f, #7f
    db #c0, #1f, #3f, #7f, #c0, #80, #df, #fb, #00, #fd, #fd, #ff, #e1, #05, #00, #ff, #c7
    db #05, #ff, #00, #03, #0f, #0f, #df, #c8, #c0, #e0, #f0, #fc, #f0, #f0, #f9, #03, #03
    db #07, #0f, #3f, #fc, #f8, #e0, #c0, #c0, #9f, #0f, #0f, #3f, #0f, #07, #03, #13, #fb
    db #f0, #f0, #fe, #fe, #f8, #f8, #8b, #83, #03, #03, #3f, #3f, #1f, #1f, #c1, #c1, #c0
    db #c0, #00, #fc, #fc, #fe, #00, #fc, #fe, #00, #fe, #ff, #00, #04, #ff, #fe, #03, #7f
    db #ff, #00, #04, #ff, #7f, #03, #00, #3f, #3f, #7f, #00, #3f, #7f, #00, #00, #01, #00
    db #01, #02, #05, #0a, #05, #af, #5b, #af, #7f, #df, #00, #bf, #ff, #00, #09, #80, #80
    db #c0, #c0, #ff, #e0, #03, #f0, #00, #05, #0b, #17, #2b, #17, #2b, #55, #00, #f8, #fc
    db #fc, #fe, #fe, #ff, #00, #03, #fe, #e0, #c8, #c0, #c0, #e0, #fe, #00, #7f, #07, #13
    db #03, #03, #07, #7f, #ff, #00, #06, #fc, #ff, #00, #03, #f8, #00, #04, #f8, #00, #00
    db #03, #03, #83, #83, #f8, #f8, #fc, #fc, #c0, #c0, #c1, #d1, #1f, #1f, #3f, #3f, #00
    db #11, #1a, #0c, #0e, #03, #18, #3c, #00, #88, #58, #30, #70, #c0, #18, #3c, #00, #00
    db #1f, #00, #20, #1f, #ff, #00, #08, #3f, #00, #0b, #15, #0b, #15, #0b, #37, #2f, #08
    db #7f, #00, #7f, #00, #00, #df, #cf, #cb, #ff, #00, #05, #df, #1f, #20, #ff, #f0, #03
    db #ff, #e0, #04, #f0, #00, #00, #0f, #07, #0f, #17, #0f, #1f, #00, #00, #ff, #c0, #03
    db #e0, #f0, #e8, #00, #3c, #ff, #7e, #03, #3c, #18, #3c, #7f, #cb, #8d, #fe, #85, #7e
    db #3c, #7e, #1f, #1f, #18, #1b, #18, #0f, #07, #00, #d0, #d0, #00, #84, #00, #00, #18
    db #7e, #f8, #f8, #18, #d8, #18, #f0, #e0, #00, #7f, #7e, #7b, #3d, #00, #7f, #7d, #38
    db #03, #01, #fd, #f7, #bf, #fd, #ef, #00, #c0, #80, #db, #00, #fd, #ef, #00, #bf, #c0
    db #f0, #fe, #0f, #07, #df, #fb, #ff, #00, #05, #e0, #fe, #fe, #0f, #ff, #00, #07, #e0
    db #00, #80, #c0, #c0, #e0, #f8, #fe, #0f, #01, #01, #03, #03, #07, #0f, #1f, #f8, #ff
    db #00, #07, #07, #ff, #00, #04, #07, #7f, #7f, #f0, #03, #0f, #7f, #f0, #e0, #00, #dd
    db #00, #00, #e3, #c1, #87, #8f, #bd, #cb, #00, #00, #f1, #a6, #e3, #f7, #df, #8f, #9f
    db #00, #00, #30, #78, #39, #07, #0f, #0f, #ff, #00, #04, #c0, #f0, #f8, #fc, #00, #00
    db #11, #09, #0b, #1d, #3f, #7f, #ff, #00, #03, #4c, #78, #b8, #fe, #fe, #fd, #bf, #ef
    db #00, #08, #1e, #1e, #1c, #ff, #00, #08, #fe, #fc, #fc, #e0, #c0, #c0, #80, #9f, #00
    db #10, #38, #70, #60, #80, #80, #bc, #00, #08, #1c, #0e, #06, #01, #01, #3d, #7f, #3f
    db #3f, #07, #03, #03, #01, #f9, #ff, #00, #03, #0a, #1f, #0f, #1e, #0c, #ff, #00, #03
    db #a0, #f8, #f0, #fc, #3c, #00, #04, #4e, #7f, #2f, #3b, #7f, #17, #00, #00, #0c, #f8
    db #68, #fe, #e8, #f0, #00, #98, #90, #fb, #00, #e7, #cd, #00, #00, #f1, #c6, #8f, #bd
    db #d7, #00, #00, #1f, #1f, #3f, #3f, #1f, #07, #00, #00, #fc, #f8, #f8, #f0, #f0, #80
    db #ff, #00, #03, #37, #02, #03, #00, #df, #fb, #00, #00, #f4, #80, #c0, #00, #ef, #fb
    db #00, #00, #fd, #bf, #0c, #1e, #3e, #3c, #00, #0c, #1c, #1c, #00, #fb, #df, #fd, #00
    db #9f, #80, #c0, #c0, #e0, #fc, #fc, #fe, #bc, #80, #80, #60, #70, #38, #10, #00, #3d
    db #01, #01, #06, #0e, #1c, #08, #00, #f9, #01, #03, #03, #07, #3f, #3f, #7f, #1e, #1f
    db #17, #0f, #ff, #00, #04, #3c, #70, #f8, #f8, #d0, #ff, #00, #03, #03, #1f, #1b, #3f
    db #07, #06, #04, #00, #fc, #f8, #dc, #f8, #f8, #2c, #04, #00, #0b, #1b, #0f, #1f, #0f
    db #1c, #2f, #1f, #76, #65, #e4, #e4, #f0, #f4, #f0, #f0, #32, #c6, #43, #87, #8f, #97
    db #0f, #17, #d8, #d8, #ff, #fc, #03, #3c, #fc, #fe, #00, #00, #01, #01, #02, #05, #03
    db #07, #00, #00, #e0, #f8, #f8, #f0, #f8, #f8, #ff, #00, #03, #03, #ff, #02, #03, #0a
    db #ff, #00, #03, #ff, #c0, #04, #d0, #7e, #bf, #ff, #de, #04, #bf, #7e, #1e, #a6, #da
    db #dc, #dc, #d8, #a0, #00, #00, #a0, #d8, #dc, #dc, #da, #a6, #1e, #00, #07, #1b, #3d
    db #3d, #5d, #61, #7e, #7e, #7d, #39, #45, #3d, #1b, #07, #00, #7e, #be, #ff, #de, #04
    db #be, #7e, #00, #bf, #ff, #de, #03, #c2, #bd, #7e, #7e, #7f, #ff, #7e, #04, #7f, #7e
    db #30, #15, #35, #54, #35, #50, #7f, #7f, #f4, #b0, #f8, #38, #fa, #fc, #fe, #e0, #0e
    db #85, #0d, #54, #0d, #16, #0f, #7f, #0e, #ae, #ae, #2e, #a8, #0c, #fc, #e6, #3d, #7d
    db #2f, #ff, #22, #03, #43, #09, #c8, #fc, #e6, #e2, #66, #62, #44, #40, #14, #c1, #c0
    db #e0, #f0, #fc, #00, #00, #38, #03, #03, #07, #0f, #3f, #ff, #00, #03, #80, #aa, #80
    db #bf, #aa, #80, #00, #fe, #03, #ab, #03, #fb, #ab, #03, #fe, #00, #3c, #f8, #e6, #f1
    db #ec, #c6, #00, #00, #1c, #37, #4b, #bf, #17, #e3, #ff, #00, #03, #01, #21, #71, #39
    db #18, #07, #00, #00, #80, #84, #8e, #9c, #18, #e0, #00, #66, #ff, #77, #04, #33, #00
    db #00, #60, #70, #72, #72, #70, #30, #ff, #00, #03, #fc, #f0, #e0, #c0, #2f, #14, #00
    db #00, #3f, #0f, #07, #03, #23, #38, #fc, #fe, #fe, #f8, #f0, #f0, #e0, #e1, #ff, #00
    db #03, #80, #c0, #80, #7c, #04, #00, #00, #01, #01, #03, #01, #3e, #20, #7f, #00, #3f
    db #1f, #0f, #0f, #07, #87, #7e, #3c, #42, #7e, #66, #3c, #42, #7e, #00, #bb, #dd, #d5
    db #d5, #dd, #bb, #ff, #00, #05, #7f, #7f, #70, #70, #00, #ff, #0e, #03, #ee, #ee, #0e
    db #0e, #7f, #7f, #ff, #70, #03, #7f, #7f, #00, #ff, #0e, #05, #ee, #ee, #00, #1f, #1f
    db #ff, #e1, #03, #f0, #fc, #00, #f8, #f8, #ff, #87, #03, #0f, #3f, #ff, #00, #03, #e3
    db #c1, #d1, #c1, #3e, #3e, #00, #b8, #de, #d3, #d3, #de, #b8, #00, #0a, #ff, #02, #03
    db #03, #ff, #00, #03, #d0, #ff, #c0, #04, #ff, #00, #03, #e0, #e0, #f0, #f0, #f8, #fe
    db #f8, #f8, #7c, #7c, #80, #c0, #80, #ff, #00, #03, #3e, #3e, #01, #03, #01, #ff, #00
    db #03, #07, #07, #0f, #0f, #1f, #7f, #3f, #3f, #7e, #bf, #ff, #de, #04, #bf, #00, #00
    db #81, #bd, #81, #bd, #bd, #81, #ff, #00, #05, #03, #07, #0f, #0f, #ff, #00, #04, #e0
    db #f0, #f8, #f8, #ff, #00, #04, #03, #07, #0f, #0f, #ff, #00, #04, #e0, #f0, #f8, #f8
    db #ff, #00, #08, #ff, #08, #08, #3e, #c1, #c1, #d1, #c1, #e3, #ff, #00, #03, #1b, #7d
    db #cd, #cd, #7d, #1b, #00
endpatterns:
;; encoded: 2048
;; original size: 2048,RLE size: 1501
patternattributes:
    db #ff, #00, #0b, #40, #04, #54, #54, #60, #f0, #f0, #ff, #e0, #03, #40, #40, #60, #ff
    db #00, #03, #fe, #e0, #40, #40, #60, #ff, #00, #03, #fe, #e0, #40, #40, #60, #ff, #00
    db #03, #40, #04, #54, #54, #60, #08, #84, #84, #ff, #85, #03, #50, #40, #08, #84, #ff
    db #85, #04, #50, #50, #80, #80, #90, #90, #ff, #80, #04, #00, #00, #90, #90, #80, #80
    db #40, #40, #00, #00, #90, #90, #80, #80, #40, #40, #80, #80, #90, #90, #ff, #80, #04
    db #08, #80, #80, #60, #00, #ff, #60, #03, #08, #ff, #80, #03, #00, #ff, #80, #03, #ff
    db #40, #07, #60, #ff, #40, #07, #80, #90, #60, #ff, #40, #06, #09, #96, #64, #ff, #40
    db #05, #09, #96, #64, #ff, #40, #05, #90, #60, #ff, #40, #06, #f0, #f0, #ff, #e0, #03
    db #40, #40, #60, #ff, #00, #03, #d0, #d0, #ff, #00, #03, #40, #ff, #50, #04, #40, #00
    db #00, #ff, #50, #05, #40, #00, #00, #ff, #80, #03, #ff, #60, #03, #80, #80, #04, #40
    db #80, #ff, #60, #03, #00, #00, #04, #40, #80, #ff, #60, #03, #00, #00, #ff, #80, #03
    db #ff, #60, #03, #80, #80, #60, #ff, #40, #07, #80, #ff, #40, #07, #ff, #60, #03, #00
    db #60, #80, #80, #08, #ff, #80, #03, #00, #ff, #80, #03, #08, #ff, #00, #08, #ff, #f0
    db #05, #00, #f0, #00, #ff, #f0, #03, #ff, #00, #05, #ff, #f0, #07, #00, #ff, #f0, #07
    db #00, #ff, #f0, #07, #00, #ff, #f0, #07, #00, #00, #ff, #40, #06, #00, #ff, #f0, #07
    db #00, #ff, #f0, #07, #00, #ff, #f0, #07, #ff, #00, #03, #ff, #f0, #03, #ff, #00, #07
    db #ff, #f0, #03, #ff, #00, #04, #f0, #ff, #00, #08, #f0, #f0, #00, #00, #ff, #f0, #07
    db #00, #ff, #d0, #07, #00, #ff, #d0, #07, #00, #ff, #d0, #07, #00, #ff, #d0, #07, #00
    db #ff, #d0, #07, #00, #d0, #d0, #00, #ff, #d0, #04, #00, #ff, #d0, #07, #00, #ff, #d0
    db #07, #00, #ff, #d0, #07, #00, #ff, #d0, #07, #00, #ff, #f0, #03, #00, #ff, #f0, #03
    db #ff, #00, #03, #f0, #00, #ff, #f0, #03, #00, #00, #ff, #f0, #05, #ff, #00, #04, #f0
    db #00, #f0, #ff, #00, #04, #ff, #f0, #05, #00, #00, #ff, #f0, #05, #00, #f0, #00, #ff
    db #f0, #07, #00, #ff, #f0, #07, #00, #ff, #f0, #07, #00, #ff, #f0, #07, #00, #ff, #f0
    db #07, #00, #f0, #f0, #00, #ff, #f0, #04, #00, #f0, #f0, #00, #ff, #f0, #04, #00, #ff
    db #f0, #07, #00, #ff, #f0, #07, #00, #ff, #f0, #07, #00, #ff, #f0, #07, #00, #ff, #f0
    db #07, #00, #ff, #f0, #07, #00, #ff, #f0, #07, #00, #ff, #f0, #07, #00, #ff, #f0, #07
    db #00, #ff, #f0, #07, #00, #ff, #f0, #07, #00, #ff, #f0, #07, #00, #ff, #f0, #07, #00
    db #f0, #f0, #00, #ff, #f0, #04, #00, #ff, #f0, #07, #00, #ff, #f0, #07, #00, #ff, #f0
    db #07, #00, #ff, #f0, #07, #00, #ff, #f0, #07, #00, #ff, #f0, #07, #00, #08, #86, #08
    db #ff, #86, #03, #60, #60, #86, #08, #86, #08, #08, #86, #60, #60, #80, #86, #86, #ff
    db #80, #06, #86, #86, #ff, #80, #06, #ff, #86, #03, #80, #80, #60, #60, #c0, #0c, #c8
    db #08, #86, #08, #86, #08, #c0, #0c, #c8, #c8, #ff, #86, #03, #08, #86, #80, #80, #86
    db #86, #ff, #80, #03, #86, #80, #80, #86, #86, #ff, #80, #03, #00, #c0, #c0, #ff, #80
    db #03, #ff, #00, #03, #c0, #c0, #ff, #80, #03, #00, #00, #04, #07, #07, #70, #74, #70
    db #74, #70, #04, #70, #74, #00, #74, #70, #74, #70, #ff, #c0, #05, #ff, #c8, #03, #ff
    db #c0, #05, #ff, #c8, #03, #ff, #c0, #03, #c8, #c8, #86, #86, #08, #ff, #00, #03, #ff
    db #c0, #04, #c8, #ff, #00, #03, #ff, #c0, #04, #c8, #ff, #c0, #03, #c8, #c8, #86, #86
    db #08, #74, #70, #74, #70, #74, #70, #74, #00, #74, #70, #74, #70, #74, #07, #07, #00
    db #d0, #d0, #90, #ff, #84, #05, #d0, #d0, #90, #ff, #84, #0a, #90, #d0, #d0, #ff, #84
    db #05, #90, #d0, #d0, #ff, #80, #04, #ff, #84, #04, #ff, #80, #04, #ff, #84, #04, #08
    db #ff, #84, #03, #08, #84, #84, #08, #50, #ff, #04, #04, #d4, #e4, #e0, #50, #ff, #04
    db #04, #d4, #e4, #e0, #08, #ff, #84, #03, #08, #84, #84, #08, #00, #e0, #00, #ff, #e0
    db #0a, #0e, #e0, #ff, #0e, #09, #ff, #e0, #08, #00, #ff, #e0, #07, #00, #ff, #e0, #05
    db #0e, #0e, #08, #80, #ff, #84, #05, #80, #08, #80, #ff, #84, #05, #80, #00, #05, #ff
    db #04, #03, #0e, #fe, #ff, #00, #03, #50, #04, #e4, #e0, #00, #00, #ff, #84, #04, #ff
    db #80, #04, #ff, #84, #04, #ff, #80, #04, #00, #ff, #e0, #07, #00, #ff, #e0, #07, #00
    db #00, #50, #04, #e4, #e0, #ff, #00, #03, #05, #ff, #04, #03, #0e, #fe, #00, #ff, #e0
    db #05, #c0, #c0, #ec, #e0, #0e, #e0, #0e, #0e, #ff, #ec, #03, #ff, #0e, #05, #ff, #ec
    db #03, #ff, #e0, #05, #ff, #c0, #03, #00, #00, #ff, #c0, #04, #e0, #e0, #00, #00, #ff
    db #c0, #06, #00, #ff, #e0, #07, #c0, #c4, #c4, #30, #c4, #ff, #40, #03, #ff, #50, #03
    db #80, #ff, #50, #03, #00, #54, #54, #00, #c8, #00, #0e, #e5, #e0, #ff, #40, #03, #c0
    db #ff, #40, #03, #00, #80, #ff, #86, #03, #08, #80, #60, #60, #c8, #c8, #ff, #86, #05
    db #08, #c8, #c8, #86, #08, #86, #86, #08, #86, #ff, #c0, #03, #c8, #c8, #86, #86, #08
    db #ff, #00, #04, #ff, #c0, #03, #c8, #ff, #00, #07, #c0, #00, #ff, #c0, #06, #c8, #ff
    db #c0, #07, #c8, #ff, #00, #07, #c0, #ff, #00, #04, #ff, #c0, #03, #c8, #ff, #c0, #03
    db #c8, #c8, #08, #86, #08, #08, #ff, #86, #06, #08, #08, #ff, #86, #07, #08, #08, #ff
    db #e8, #06, #ff, #08, #04, #ff, #e8, #04, #00, #00, #ff, #c0, #06, #ff, #00, #03, #ff
    db #c0, #05, #ff, #86, #03, #08, #ff, #e8, #04, #04, #00, #04, #00, #04, #00, #04, #00
    db #ff, #80, #03, #ff, #85, #05, #00, #70, #ff, #50, #06, #00, #70, #ff, #50, #06, #ff
    db #80, #03, #ff, #85, #05, #ff, #00, #03, #ff, #60, #05, #ff, #00, #03, #ff, #60, #05
    db #00, #ff, #80, #06, #a8, #00, #00, #ff, #80, #04, #a8, #a8, #08, #ff, #86, #03, #08
    db #86, #86, #08, #08, #ff, #86, #05, #08, #08, #ff, #e8, #06, #08, #08, #ff, #e8, #06
    db #08, #08, #0c, #ff, #c8, #03, #08, #86, #86, #08, #0c, #ff, #c8, #03, #08, #86, #86
    db #08, #08, #86, #86, #ff, #e8, #04, #08, #ff, #e8, #03, #08, #ff, #86, #03, #08, #ff
    db #85, #03, #84, #84, #ff, #80, #03, #ff, #50, #06, #40, #00, #ff, #50, #06, #40, #00
    db #ff, #85, #03, #84, #84, #ff, #80, #03, #ff, #60, #04, #ff, #00, #04, #ff, #60, #05
    db #ff, #00, #03, #a8, #ff, #80, #06, #00, #ff, #80, #07, #00, #ff, #e0, #08, #ff, #c0
    db #04, #e0, #c0, #e0, #e0, #ff, #c0, #08, #ff, #e0, #08, #00, #00, #c0, #c0, #e0, #c0
    db #e0, #c0, #00, #00, #ff, #c0, #03, #ff, #e0, #03, #ff, #00, #03, #ff, #50, #05, #ff
    db #00, #03, #ff, #40, #14, #00, #00, #ff, #40, #07, #00, #ff, #40, #0e, #00, #ff, #40
    db #08, #00, #ff, #40, #0f, #ff, #e0, #06, #ff, #c0, #03, #e0, #c0, #e0, #ff, #c0, #03
    db #ec, #e0, #c0, #e0, #ff, #c0, #05, #e0, #ec, #ec, #e0, #ff, #ec, #04, #c0, #ff, #c4
    db #06, #c0, #c0, #ff, #c4, #06, #c0, #40, #ff, #84, #05, #08, #08, #40, #ff, #84, #05
    db #08, #08, #04, #40, #80, #40, #20, #80, #40, #04, #40, #40, #80, #40, #c0, #80, #40
    db #40, #00, #ff, #40, #06, #00, #00, #ff, #40, #06, #ff, #00, #03, #40, #ff, #50, #04
    db #40, #00, #00, #40, #ff, #50, #05, #00, #ff, #d0, #06, #00, #00, #ff, #d0, #06, #00
    db #08, #08, #85, #85, #84, #84, #40, #40, #08, #08, #85, #ff, #84, #04, #40, #ff, #80
    db #03, #85, #85, #ff, #84, #03, #ff, #00, #03, #50, #50, #40, #50, #50, #00, #00, #80
    db #50, #50, #40, #50, #40, #80, #08, #85, #85, #ff, #84, #04, #ff, #40, #08, #00, #ff
    db #40, #06, #00, #04, #00, #04, #00, #74, #70, #74, #70, #04, #70, #74, #70, #74, #70
    db #74, #70, #74, #70, #74, #70, #74, #70, #74, #00, #74, #70, #74, #70, #74, #70, #74
    db #00, #40, #50, #ff, #85, #03, #84, #84, #08, #50, #50, #ff, #85, #04, #84, #ff, #08
    db #03, #ff, #84, #04, #40, #40, #00, #ff, #40, #06, #00, #ff, #40, #05, #ff, #00, #03
    db #ff, #40, #05, #ff, #00, #03, #ff, #84, #05, #ff, #80, #03, #ff, #40, #05, #ff, #00
    db #03, #ff, #40, #05, #ff, #00, #03, #ff, #84, #05, #ff, #80, #03, #ff, #40, #07, #00
    db #04, #40, #c0, #40, #b0, #80, #40, #04, #ff, #00, #04, #f0, #f0, #90, #90, #ff, #00
    db #04, #ff, #90, #04, #ff, #00, #04, #ff, #60, #04, #ff, #00, #04, #ff, #60, #04, #ff
    db #00, #04, #0d, #ff, #00, #03, #ff, #d0, #08, #40, #c4, #c4, #ff, #84, #03, #08, #08
    db #00, #ff, #40, #06, #00
endpatternattributes:

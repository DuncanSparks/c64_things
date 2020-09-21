.org $080d
.segment "STARTUP"
.segment "INIT"
.segment "ONCE"
.segment "CODE"

jmp start

;CLEAR = $E544
;GETIN  =  $FFE4
;SCNKEY =  $FF9F

SPRITE_ADDR = 2040
V = $d000
JOYSTICK = $dc01

ANIM_TIMER = $c000
DIRECTION = $c001

PTRA = $fb
PTRB = $fd

player_x: .byte 100,0
player_y: .byte 100

.macro raster_wait label
	lda #$ff
	cmp $d012
	bne label
.endmacro

.macro load_sprite_addr address
	lda #<address
	ldx #>address
	sta PTRA
	stx PTRA + 1
.endmacro

.macro increment_timer amount
	lda ANIM_TIMER
	adc #amount
	sta ANIM_TIMER
.endmacro

.include "sprites.inc"

start:
	lda #147
	jsr $ffd2

	lda #13
	sta SPRITE_ADDR
	lda #5
	sta V + 21
	lda #13
	sta V + 39

	lda player_x
	sta V
	lda player_y
	sta V + 1

	lda #1
	sta V + 23
	sta V + 29

	load_sprite_addr spr_player_down
	lda #0
	sta ANIM_TIMER

main:
	raster_wait main
	increment_timer 4
	jsr load_sprite
@up:
	lda JOYSTICK
	and #1
	bne @down
	dec player_x
@down:
	lda JOYSTICK
	and #2
	bne @left
	inc player_x
@left:
	lda JOYSTICK
	and #4
	bne @right
	dec player_y
@right:
	lda JOYSTICK
	and #8
	bne @end
	inc player_y

@end:
	lda player_x
	sta V + 1
	lda player_y
	sta V
	jsr animate_player
	jmp main

	rts

load_sprite:
	ldy #62
@loop:
	lda (PTRA),y
	sta 832,y
	dey
	bpl @loop
	rts


animate_player:
	ldx JOYSTICK
;@down:
	txa
	and #2
	bne @up
	lda #1
	sta DIRECTION

	lda ANIM_TIMER
	cmp #63
	bcc @downwalk1
	cmp #127
	bcc @downidle
	cmp #192
	bcc @downwalk2
	jmp @downidle
@downidle:
	load_sprite_addr spr_player_down
	rts
@downwalk1:
	load_sprite_addr spr_player_down_walk1
	rts
@downwalk2:
	load_sprite_addr spr_player_down_walk2
	rts

@up:
	txa
	and #1
	bne @end
	lda #0
	sta DIRECTION

	lda ANIM_TIMER
	cmp #63
	bcc @upwalk1
	cmp #127
	bcc @upidle
	cmp #192
	bcc @upwalk2
	jmp @upidle
@upidle:
	load_sprite_addr spr_player_up
	rts
@upwalk1:
	load_sprite_addr spr_player_up_walk1
	rts
@upwalk2:
	load_sprite_addr spr_player_up_walk2
	rts

@end:
	lda DIRECTION
	beq @end2
	load_sprite_addr spr_player_down
	rts
@end2:
	load_sprite_addr spr_player_up
	rts

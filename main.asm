.org $080d
.segment "STARTUP"
.segment "INIT"
.segment "ONCE"
.segment "CODE"

jmp start

; ============================================

SPRITE_ADDR = 2040
V = $d000
JOYSTICK = $dc01

ANIM_TIMER = $c000
DIRECTION = $c001

PTRA = $fb
PTRB = $fd

player_x: .byte 100,0
player_y: .byte 100

; ============================================

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

.macro load_sprite_dir idle, walk1, walk2 ; A probably really bad and hacky way to do animation
	.local s_idl, s_wk1, s_wk2
	lda ANIM_TIMER
	cmp #63
	bcc s_wk1
	cmp #127
	bcc s_idl
	cmp #192
	bcc s_wk2
	jmp s_idl
s_idl:
	load_sprite_addr idle
	rts
s_wk1:
	load_sprite_addr walk1
	rts
s_wk2:
	load_sprite_addr walk2
	rts
.endmacro

.macro increment_timer amount
	lda ANIM_TIMER
	adc #amount
	sta ANIM_TIMER
.endmacro

.include "sprites.inc"

; ============================================

start:
	; Clear the screen
	lda #147
	jsr $ffd2

	; Initialize sprite memory locations
	lda #13
	sta SPRITE_ADDR
	lda #5
	sta V + 21
	lda #13
	sta V + 39

	; Initialize coordinates
	lda player_x
	sta V
	lda player_y
	sta V + 1

	; Double the size of the sprite
	lda #1
	sta V + 23
	sta V + 29

	; Initialize direction and timer
	load_sprite_addr spr_player_down
	lda #1
	sta DIRECTION
	lda #0
	sta ANIM_TIMER

main:
	raster_wait main ; Don't do anything until the screen finishes drawing
	increment_timer 4
	jsr load_sprite

; Check for joystick input and move the player
@up:
	lda JOYSTICK
	and #1
	bne @down
	dec player_y
@down:
	lda JOYSTICK
	and #2
	bne @left
	inc player_y
@left:
	lda JOYSTICK
	and #4
	bne @right
	dec player_x
@right:
	lda JOYSTICK
	and #8
	bne @end
	inc player_x

@end:
	; Apply direction changes
	lda player_x
	sta V
	lda player_y
	sta V + 1
	jsr animate_player

	; End the program if the button is pressed
	lda JOYSTICK
	and #16
	bne main
	rts

load_sprite:
	ldy #62
@loop:
	lda (PTRA),y ; Load the sprite with indirect addressing
	sta 832,y
	dey
	bpl @loop
	rts


animate_player:
	ldx JOYSTICK
down:
	txa
	and #2
	bne up
	lda #1
	sta DIRECTION

	load_sprite_dir spr_player_down, spr_player_down_walk1, spr_player_down_walk2

up:
	txa
	and #1
	bne right
	lda #0
	sta DIRECTION

	load_sprite_dir spr_player_up, spr_player_up_walk1, spr_player_up_walk2

right:
	txa
	and #8
	bne left
	lda #3
	sta DIRECTION

	load_sprite_dir spr_player_right, spr_player_right_walk1, spr_player_right_walk2

left:
	txa
	and #4
	bne end
	lda #2
	sta DIRECTION

	load_sprite_dir spr_player_left, spr_player_left_walk1, spr_player_left_walk2

end:
	; If we're not moving, change to the direction we were last moving
	lda DIRECTION
	cmp #0
	beq @endup
	cmp #1
	beq @enddown
	cmp #2
	beq @endleft
	cmp #3
	beq @endright
@endup:
	load_sprite_addr spr_player_up
	rts
@enddown:
	load_sprite_addr spr_player_down
	rts
@endleft:
	load_sprite_addr spr_player_left
	rts
@endright:
	load_sprite_addr spr_player_right
	rts

end_short_object_offset = $102;

; Vars
vsync_handled = $400

loop_count = $404

loop_count_string_pos = $ff8410
loop_count_string_start = $ff8413

config_values_start = $ff8430
palette_select = $ff8430
scroll_1_select = $ff8431
scroll_2_select = $ff8432
scroll_3_select = $ff8433
object_select = $ff8434
row_scroll_select = $ff8435

value_string_pos = $ff8460
value_string_start = $ff8463

base_vram_object_var = $ff8490

base_reg_null_ptr = $ff8490
base_reg_object_ptr = $ff8494
; Vars

; Vram constants
base_vram_object = $9100

base_reg_object = $800100
; Vram constants

; Inputs
b_input_right = $00
b_input_left = $01
b_input_down = $02
b_input_up = $03

b_input_b1 = $04
b_input_b2 = $05
b_input_b3 = $06

input_right = $0001
input_left = $0002
input_down = $0004
input_up = $0008

input_b1 = $0010
input_b2 = $0020
input_b3 = $0040
; Inputs

scroll_2_pos_offset = $3a
scroll_3_pos_offset = $3e
layer_control_offset = $52

 org  0
  incbin "build\sf2.bin"
   
 org $8D1
;  dc.b "123  "
   
 org $000A30
  jmp main

 ; Don't fade out test screen 
 org $000984
;   NOP
;   NOP
 
;-------------------
; Stop vsync handling after inputs are read and palette updated and do custom logic
 org $000A9C

  ; From 000A9C
;  move.w  ($2a,A5), $800100.l ; Object
  move.w  ($32,A5), $800108.l ; rowscroll

  move.w  $800148.l, ($5e,A5)

  jsr $001baa ; INput and update video control
  jsr $000b06 ; Palette
  ; From 000A9C  
 
  move.l D6, (loop_count, A5) ; Store loop count
  
  ; Update object base
  move.w base_vram_object_var, D0
  movea.l base_reg_object_ptr, A0
  move.w D0, (A0)
  
  movea.l #base_vram_object_var, A0
  eori.w  #$0080, (A0) ; Switch object buffers each frame
  ; Update object base
  
  movem.l (A7)+, D0-D7/A0-A6 ; Restore regs

  moveq #$1, D7 ; Vsync handled

  rte
;-------------------
; Overwrite default scroll 2 and 3 palette banks

 org $C9000
   incbin "palettes_scroll2_sagatstage.bin"
 org $CE000
   incbin "palettes_scroll3_sagatstage.bin"

;=================================
; Free space
;=================================
 org $0E0000

;-------------------
main:
  moveq #$0, D7 ; Reset vsync handled
  moveq #$0, D6 ; Reset loop count

  bsr initialize_base_register_vars
  bsr fix_palette_brightness
  bsr upload_object_data
  bsr setup_variable_strings
  bsr draw_ui
  bsr upload_scroll23_data

.loop
  moveq #$0, D7 ; Reset vsync handled

  bsr draw_count
  bsr draw_values
  bsr handle_controls

  moveq #$0, D6 ; Reset loop count

.count_loop
  addq.w #$1, D6 ; Increment loop count

  tst.b D7 ; Check vsync handled
  beq .count_loop

  bra .loop
;-------------------

;-------------------
initialize_base_register_vars:
  ; Object
  move.w #base_vram_object, D0
  move.w D0, base_vram_object_var
  
  move.l #base_reg_object, D0
  move.l D0, base_reg_object_ptr
  ; Object
  
  rts
;-------------------

;-------------------
draw_ui:
  movea.l #control_string, A2
  bsr draw_string_hook

  movea.l #config_string, A2
  bsr draw_string_hook

  movea.l #spacer_string_1, A2
  bsr draw_string_hook

  movea.l #spacer_string_2, A2
  bsr draw_string_hook

  movea.l #spacer_string_3, A2
  bsr draw_string_hook

  rts
;-------------------

;-------------------
setup_variable_strings:
  moveq #$3, D0
  movea.l #default_count_string, A1
  movea.l #loop_count_string_pos, A0

  bsr copy_mem

  moveq #$15, D0
  movea.l #default_value_string, A1
  movea.l #value_string_pos, A0

  bsr copy_mem

  rts
;-------------------

;-------------------
handle_controls:
  moveq #$00, D0
  moveq #$00, D1

  move.w  ($7e,A5), D0
  move.w  ($80,A5), D1
  eor.w D0, D1 ; Fresh input
  and.w D0, D1 ; Was a press not a release

  tst.w D1
  beq .handle_controls_continue ; Nothing pressed!
  
  bsr increment_value
  
  bsr clamp_value_and_update_pointers
  
  bsr update_value_string

.handle_controls_continue
  rts
;-------------------

;-------------------
clamp_value_and_update_pointers:
  btst #b_input_right, D1
  beq .clamp_check_left
  
  bsr handle_palette_value_change

.clamp_check_left
  btst #b_input_left, D1
  beq .clamp_check_down
  
  bsr handle_scroll1_value_change

.clamp_check_down
  btst #b_input_down, D1
  beq .clamp_check_up
  
  bsr handle_scroll2_value_change

.clamp_check_up
  btst #b_input_up, D1
  beq .clamp_check_b1
  
  bsr handle_scroll3_value_change

.clamp_check_b1
  btst #b_input_b1, D1
  beq .clamp_check_b2
  
  bsr handle_object_value_change

.clamp_check_b2
  btst #b_input_b2, D1
  beq .clamp_exit
  
  bsr handle_row_scroll_value_change

.clamp_exit
  rts
;-------------------

;-------------------
handle_palette_value_change:
  movea.l #palette_select, A0
  move.b (A0), D0
  cmpi.b #$02, D0
  bne .palette_exit
  
  move.b #$00, (A0)
  
.palette_exit
  rts
;-------------------

;-------------------
handle_scroll1_value_change:
  movea.l #scroll_1_select, A0
  move.b (A0), D0
  cmpi.b #$04, D0
  bne .scroll1_exit
  
  move.b #$00, (A0)
  
.scroll1_exit
  rts
;-------------------

;-------------------
handle_scroll2_value_change:
  movea.l #scroll_2_select, A0
  move.b (A0), D0
  cmpi.b #$04, D0
  bne .scroll2_exit
  
  move.b #$00, (A0)
  
.scroll2_exit
  rts
;-------------------

;-------------------
handle_scroll3_value_change:
  movea.l #scroll_3_select, A0
  move.b (A0), D0
  cmpi.b #$04, D0
  bne .scroll3_exit
  
  move.b #$00, (A0)
  
.scroll3_exit
  rts
;-------------------

;===========================================
handle_object_value_change:
  movea.l #object_select, A0
  move.b (A0), D0
  cmpi.b #$03, D0
  bne .object_exit
  
  move.b #$00, (A0)
  
.object_exit
  moveq #$00, D0
  move.b (A0), D0
  add.w   D0, D0
  add.w   D0, D0
  movea.l object_value_jump_tbl(PC,D0.w), A0
  jsr     (A0)
    
  rts

;-------------------

object_value_jump_tbl:
  dc.l object_value_0, object_value_1, object_value_2

;-------------------

object_value_0:
  move.l #base_reg_object, D0
  move.l D0, base_reg_object_ptr

  movea.l #base_vram_object_var, A0
  andi.w #$FFBF, (A0)   
  rts

object_value_1:
  move.l #base_reg_object, D0
  move.l D0, base_reg_object_ptr

  movea.l #base_vram_object_var, A0
  ori.w #$0040, (A0)   
  rts
  
object_value_2:
  move.l #base_reg_null_ptr, D0
  move.l D0, base_reg_object_ptr
  rts
;===========================================


;-------------------
handle_row_scroll_value_change:
  movea.l #row_scroll_select, A0
  move.b (A0), D0
  cmpi.b #$02, D0
  bne .row_scroll_exit
  
  move.b #$00, (A0)
  
.row_scroll_exit
  rts
;-------------------

;-------------------
update_value_string:
  movea.l #config_values_start, A0
  movea.l #value_string_start, A1
  movea.l #nibble_to_char, A2
  
  moveq #$05, D0

.update_value_string_loop  
  moveq #$00, D1
  moveq #$00, D2

  move.b D0, D1
  rol.b #$01, D1
  add.b D0, D1 ; D1 contains the value string offset
  
  move.b (A0, D0), D2 ; Get value
  move.b (A2, D2), D2 ; Convert to char
  
  move.b D2, (A1, D1)

  dbra D0, .update_value_string_loop  

  rts
;-------------------

;-------------------
increment_value:
  moveq #$05, D0 ; Check six inputs, 00 - 05

.increment_value_loop
  btst D0, D1
  bne .increment_value_exit
  
  dbra D0, .increment_value_loop

  rts

.increment_value_exit
  movea.l #config_values_start, A0
  addq.b #$01, (A0, D0)

  rts  
;-------------------

;-------------------
draw_values:
  movea.l #value_string_pos, A2
  bsr draw_string_hook

  rts
;-------------------

;-------------------
draw_count:
  movea.l #nibble_to_char, A2
  movea.l #$ffff8404, A1 ; loop count
  movea.l #loop_count_string_start, A0
  
  moveq #$3, D0 ; Loop three times

.draw_count_loop
  move.b (A1)+, D1
  move.b D1, D2

  ; First nibble
  andi.b #$F0, D1
  ror.b #$4, D1
  
  move.b (A2, D1), D1
  move.b D1, (A0)+

  ; Second nibble
  andi.b #$0F, D2
  
  move.b (A2, D2), D2
  move.b D2, (A0)+
  
  dbra D0, .draw_count_loop ; Do it four times

  movea.l #loop_count_string_pos, A2
  bsr draw_string_hook

  rts
;-------------------

;-------------------
draw_string_hook:
  movea.l #.draw_string_hook_continue, A5

  jmp $706

.draw_string_hook_continue
  movea.l #$ffff8000, A5 

  rts
;-------------------

;-------------------
fix_palette_brightness:
  movea.l	#$900000, A0
  move.l	#$F000F000, D0
  moveq		#0, D1
  move.b	#$80, D1

palette_brightness_loop:
  or.l		D0, (A0)+
  or.l		D0, (A0)+
  or.l		D0, (A0)+
  or.l		D0, (A0)+
  or.l		D0, (A0)+
  or.l		D0, (A0)+
  or.l		D0, (A0)+
  or.l		D0, (A0)+
  dbeq		D1, palette_brightness_loop

  rts
;-------------------

;-------------------
upload_object_data:
  moveq #$0, D0
  move.w #$4f0, D0
  movea.l #$00910000, A0
  movea.l #sf2_objects_2, A1
  
  bsr copy_mem

  moveq #$0, D0
  move.w #$104, D0
  movea.l #$00914000, A0
  movea.l #sf2_objects_2, A1
  
  bsr copy_mem

  move.b #$FF, (end_short_object_offset, A0)

  move.w #$4f0, D0
  movea.l #$00918000, A0
  movea.l #sf2_objects, A1
  
  bsr copy_mem

  move.w #$104, D0
  movea.l #$0091C000, A0
  movea.l #sf2_objects, A1
  
  bsr copy_mem
  
  move.b #$FF, (end_short_object_offset, A0)

  rts
;-----------------

; Layer control
; UU UU OO OO S1 S1 S2 S2 S3 S3 S1E S2E S3E SF1 SF2 RS    
; 0  0  0  0  1  1  1  0  0  1  0   1   1   0   1   0
;-----------------

upload_scroll23_data:
  move.w #$2000, D0
  movea.l #$00904000, A0
  movea.l #sf2_scroll2, A1
  
  bsr copy_mem
  
  move.w #$2000, D0
  movea.l #$00908000, A0
  movea.l #sf2_scroll3, A1
  
  bsr copy_mem

  move.w #$1000, D0
  movea.l #$00900000, A0
  movea.l #sf2_palettes, A1
  
  bsr copy_mem
  
  ; Position scroll layers and enable them
  move.l #$01c00200, (scroll_2_pos_offset, A5)
  move.l #$03000400, (scroll_3_pos_offset, A5)
  move.w #$079a, (layer_control_offset, A5)
  
  rts

;-----------------

;-----------------
copy_mem:
  move.b  (A1, D0.w), D1
  move.b  D1, (A0, D0.w)
  dbra D0, copy_mem
  rts
;-----------------

spacer_string_1:
  dc.b $10, $0b, $00, "                  ", $00

control_string:
  dc.b $10, $0c, $00, "R  L  D  U  B1 B2 ", $00

spacer_string_2:
  dc.b $10, $0d, $00, "                  ", $00

config_string:
  dc.b $10, $0e, $00, "PL S1 S2 S3 OB RS ", $00

spacer_string_3:
  dc.b $10, $0f, $00, "                  ", $00

default_value_string:
  dc.b $10, $10, $00, "0  0  0  0  0  0  ", $00

default_count_string:
  dc.b $14, $0A, $00, $00
 
nibble_to_char:
  dc.b "0123456789ABCDEF"

sf2_objects:
  incbin "sf2_objects_1.bin"
 
sf2_objects_2:
  incbin "sf2_objects_2.bin"
 
sf2_scroll2:
  incbin "scroll2_vega_dup.bin"
  
sf2_scroll3:
  incbin "scroll3_vega_dup.bin"
  
sf2_palettes:
  incbin "palettes_vegastage.bin"

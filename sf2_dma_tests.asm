end_short_object_offset = $102;

vsync_handled = $400

loop_count = $404

loop_count_string_pos = $ff8410
loop_count_string_start = $ff8413

 org  0
  incbin "build\sf2.bin"
   
 org $8D1
  dc.b "123  "
   
 org $000A54
  jmp main

 ; Don't fade out test screen 
 org $000984
;   NOP
;   NOP
 
;-------------------
; Stop vsync handling after inputs are read and palette updated and do custom logic
 org $000AE0
  move.l D6, (loop_count, A5) ; Store loop count
  
  eori.w  #$0080, ($2a,A5) ; Switch object buffers each frame

  movem.l (A7)+, D0-D7/A0-A6 ; Restore regs

  moveq #$1, D7 ; Vsync handled

  rte
;-------------------

;=================================
; Free space
;=================================
 org $0E0000

;-------------------
main:
  moveq #$0, D7 ; Reset vsync handled
  moveq #$0, D6 ; Reset loop count

  bsr fix_palette_brightness
  bsr upload_object_data
  bsr setup_loop_count_string

.loop
  moveq #$0, D7 ; Reset vsync handled

  bsr draw_count

  move.w  ($7e,A5), D0
  eor D0, ($80,A5)
  and D0, ($7e,A5)
  tst D0
  beq .continue
  
  eori.w  #$0040, ($2a,A5) ; If a button was pressed switch object buffers

.continue
  moveq #$0, D6 ; Reset loop count

.count_loop
  addq #$1, D6 ; Increment loop count

  tst.b D7 ; Check vsync handled
  beq .count_loop

  bra .loop
;-------------------

;-------------------
setup_loop_count_string:
  moveq #$3, D0
  movea.l #default_count_string, A1
  movea.l #loop_count_string_pos, A0

  bsr copy_mem

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
  movea.l #.draw_count_continue, A5

  jmp $706

.draw_count_continue
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

;-----------------
copy_mem:
  move.b  (A1, D0.w), D1
  move.b  D1, (A0, D0.w)
  dbra D0, copy_mem
  rts
;-----------------

default_count_string:
  dc.b $18, $0C, $00, $00
 
nibble_to_char:
  dc.b "0123456789ABCDEF"

sf2_objects:
  incbin "sf2_objects_1.bin"
 
sf2_objects_2:
  incbin "sf2_objects_2.bin"
 
end_short_object_offset = $102;

vsync_handled = $400

loop_count = $404

 org  0
  incbin  "build\sf2.bin"
   
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
  

.loop
  moveq #$0, D7 ; Reset vsync handled

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
  
  bsr upload_gfx

  moveq #$0, D0
  move.w #$104, D0
  movea.l #$00914000, A0
  movea.l #sf2_objects_2, A1
  
  bsr upload_gfx

  move.b #$FF, (end_short_object_offset, A0)

  move.w #$4f0, D0
  movea.l #$00918000, A0
  movea.l #sf2_objects, A1
  
  bsr upload_gfx

  move.w #$104, D0
  movea.l #$0091C000, A0
  movea.l #sf2_objects, A1
  
  bsr upload_gfx
  
  move.b #$FF, (end_short_object_offset, A0)

  rts
;-----------------

;-----------------
upload_gfx:
  move.b  (A1, D0.w), D1
  move.b  D1, (A0, D0.w)
  dbra D0, upload_gfx
  rts
;-----------------

nibble_to_char:
  dc.b "0123456789ABCDEF"

sf2_objects:
  incbin "sf2_objects_1.bin"
 
sf2_objects_2:
  incbin "sf2_objects_2.bin"
 
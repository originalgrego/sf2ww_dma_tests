 org $00048E
  move.w  #$12c8, $800154.l
  move.w  #$3e, $800122.l
  move.w  #$3f, $80014a.l
  move.w  #$9000, $80010a.l

 org $0004C2
  move.w  $800148.l, D0
  andi.w  #$fc3f, D0
  cmpi.w  #$407, D0

 org $0005FE
  move.w  #$3f, $800122.l
  move.w  #$3f, ($4c,A5)
  move.w  #$12da, ($52,A5)
  move.w  #$3f, ($5c,A5)

 org $000AC0
  move.w  ($2a,A5), $800100.l ; Object
  move.w  ($32,A5), $800108.l ; rowscroll
  move.w  $800148.l, ($5e,A5)

 org $000B2A
  move.w  ($5c,A5), $80014a.l
  move.w  ($34,A5), $80010a.l

 org $00167E
  move.w  D0, $800122.l
  move.w  ($52,A5), $800154.l
  move.b  ($2db,A5), $800030.l
  move.w  ($54,A5), $800152.l
  move.w  ($56,A5), $800150.l
  move.w  ($58,A5), $80014e.l
  move.w  ($5a,A5), $80014c.l

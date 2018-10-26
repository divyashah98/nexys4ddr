; Wrapper for Ethernet driver

.export eth_init
.export eth_rx

; It is assumed that the field eth_inp_len comes immediately before eth_inp.
.import eth_inp_len
.import eth_inp

ethRxdmaEnable = $7FD3
ethRxdmaPtr    = $7FD4
ethRxPending   = $7FEE

.code

; initialize the ethernet adaptor
; inputs: none
; outputs: carry flag is set if there was an error, clear otherwise
eth_init:
      lda #<eth_inp_len 
      ldx #>eth_inp_len
      sta ethRxdmaPtr
      stx ethRxdmaPtr+1
      clc
      rts

; receive a packet
; inputs: none
; outputs:
; if there was an error receiving the packet (or no packet was ready) then carry flag is set
; if packet was received correctly then carry flag is clear,
; eth_inp contains the received packet,
; and eth_inp_len contains the length of the packet
eth_rx:
      lda ethRxPending
      eor #1                  ; Invert bit 0, so '0' means pending.
      ror a                   ; Move bit 0 to carry
      bcs @2                  ; Jump if no packet is ready
      lda #1
      sta ethRxdmaEnable      ; Start transfer of packet
@1:   lda ethRxdmaEnable
      bne @1                  ; Wait until transfer is complete
@2:   rts


.org 0

	di
	ld a, $33
	ld ($8000), a
	
loop:
	ld a, ($8000)
	jr loop

.end

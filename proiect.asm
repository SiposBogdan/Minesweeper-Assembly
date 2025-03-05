.586
.model flat, stdcall
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;includem biblioteci, si declaram ce functii vrem sa importam
includelib msvcrt.lib
extern exit: proc
extern malloc: proc
extern memset: proc
extern printf: proc
includelib canvas.lib
extern BeginDrawing: proc
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;declaram simbolul start ca public - de acolo incepe executia
public start
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;sectiunile programului, date, respectiv cod
.data
;aici declaram date
window_title DB "Exemplu proiect desenare",0
area_width EQU 1080
area_height EQU 1080
matrix_width EQU 320
matrix_height EQU 320
format db "%d ",0
format2 db "%d %d ", 0
image_height equ 18
image_width equ 18
image_height1 equ 48
image_width1 equ 48
image_height2 equ 50
image_width2 equ 150
area DD 0
xx equ 150
yy equ 150
bombe equ 40
counter DD 0 ; numara evenimentele de tip timer
counter1 dd 0
counter2 dd 40
proces dd 0
flag dd 0
numar_flag dd 0
arg1 EQU 8
arg2 EQU 12
arg3 EQU 16
arg4 EQU 20

matrix db 256 dup(0)
apasat db 256 dup(0)
vector_flag db 256 dup(0)

symbol_width EQU 10
symbol_height EQU 20
include digits.inc
include letters.inc
include digits0.inc
include digits1.inc
include digits2.inc
include digits3.inc
include digits4.inc
include digits5.inc
include digits6.inc
include digits7.inc
include digits8.inc
include bomb.inc
include flag_buton_apasat.inc
include flag_buton_neapasat.inc
include flag.inc
include go.inc
include win.inc
.code
; procedura make_text afiseaza o litera sau o cifra la coordonatele date
; arg1 - simbolul de afisat (litera sau cifra)
; arg2 - pointer la vectorul de pixeli
; arg3 - pos_x
; arg4 - pos_y

	make_image_flag_buton_neapasat proc
	push ebp
	mov ebp, esp
	pusha

	lea esi, var_12
	
draw_image:
	mov ecx, image_height1
loop_draw_lines:
	mov edi, [ebp+arg1] ; pointer to pixel area
	mov eax, [ebp+arg3] ; pointer to coordinate y
	
	add eax, image_height1
	sub eax, ecx ; current line to draw (total - ecx)
	
	mov ebx, area_width
	mul ebx	; get to current line
	
	add eax, [ebp+arg2] ; get to coordinate x in current line
	shl eax, 2 ; multiply by 4 (DWORD per pixel)
	add edi, eax
	
	push ecx
	mov ecx, image_width1 ; store drawing width for drawing loop
	
loop_draw_columns:

	push eax
	mov eax, dword ptr[esi] 
	mov dword ptr [edi], eax ; take data from variable to canvas
	pop eax
	
	add esi, 4
	add edi, 4 ; next dword (4 Bytes)
	
	loop loop_draw_columns
	
	pop ecx
	loop loop_draw_lines
	popa
	
	mov esp, ebp
	pop ebp
	ret
make_image_flag_buton_neapasat endp


make_image_macro_flag_buton_neapasat macro drawArea, x, y
	push y
	push x
	push drawArea
	call make_image_flag_buton_neapasat
	add esp, 12
endm

linie_orizontal macro x, y, len, color
local bucla_linia
pusha
	mov eax, y
	mov ebx, area_width
	mul ebx
	add eax, x
	shl eax, 2
	add eax, area
	mov ecx, len
bucla_linia:
	mov dword ptr[eax], color
	add eax, 4
	loop bucla_linia
	popa
endm


linie_vertical macro x,y,len, color
  local bucla_linie
	pusha
	mov eax, y
	mov ebx,area_width
	mul ebx
	add eax,x
	shl eax,2
	add eax, area
	mov ecx,len
	bucla_linie:
 mov dword ptr[eax],color
 add eax, area_width*4
 loop bucla_linie
 popa
endm


make_text proc
	push ebp
	mov ebp, esp
	pusha
	
	mov eax, [ebp+arg1] ; citim simbolul de afisat
	cmp eax, 'A'
	jl make_digit
	cmp eax, 'Z'
	jg make_digit
	sub eax, 'A'
	lea esi, letters
	jmp draw_text
make_digit:
	cmp eax, '0'
	jl make_space
	cmp eax, '9'
	jg make_space
	sub eax, '0'
	lea esi, digits
	jmp draw_text
make_space:	
	mov eax, 26 ; de la 0 pana la 25 sunt litere, 26 e space
	lea esi, letters
	
draw_text:
	mov ebx, symbol_width
	mul ebx
	mov ebx, symbol_height
	mul ebx
	add esi, eax
	mov ecx, symbol_height
bucla_simbol_linii:
	mov edi, [ebp+arg2] ; pointer la matricea de pixeli
	mov eax, [ebp+arg4] ; pointer la coord y
	add eax, symbol_height
	sub eax, ecx
	mov ebx, area_width
	mul ebx
	add eax, [ebp+arg3] ; pointer la coord x
	shl eax, 2 ; inmultim cu 4, avem un DWORD per pixel
	add edi, eax
	push ecx
	mov ecx, symbol_width
bucla_simbol_coloane:
	cmp byte ptr [esi], 0
	je simbol_pixel_alb
	mov dword ptr [edi], 0
	jmp simbol_pixel_next
simbol_pixel_alb:
	mov dword ptr [edi], 0FFFFFFh
simbol_pixel_next:
	inc esi
	add edi, 4
	loop bucla_simbol_coloane
	pop ecx
	loop bucla_simbol_linii
	popa
	mov esp, ebp
	pop ebp
	ret
make_text endp

; un macro ca sa apelam mai usor desenarea simbolului
make_text_macro macro symbol, drawArea, x, y
	push y
	push x
	push drawArea
	push symbol
	call make_text
	add esp, 16
endm

; functia de desenare - se apeleaza la fiecare click
; sau la fiecare interval de 200ms in care nu s-a dat click
; arg1 - evt (0 - initializare, 1 - click, 2 - s-a scurs intervalul fara click)
; arg2 - x
; arg3 - y



;de facut matrice
	initializare_matrice proc
	pusha
	mov ecx, 40
	return:
	bomba:
	mov ebx, 0
	rdtsc
	mov edx, 9
	mov bl, al
	mov eax, ebx
	push ecx
	push eax
	push edx
	pop edx
	pop eax
	pop ecx
	cmp matrix[eax], dl
	je bomba
	
	mov matrix[eax], dl
	loop return
	mov ecx, 255
	
	repetare:
	
	mov esi, 0
	mov eax, 0
	cmp matrix[ecx], 9
	je e_bomba
	
	mov al, cl
	mov edx, 0
	mov edi, 16
	div edi
	mov eax, 0

	cmp edx, 0
	je rest0
	
	mov ebx, ecx
	sub ebx, 17
	cmp matrix[ebx], 9
	jne nu_e_bomba
	inc esi
	nu_e_bomba:
	
	mov ebx, ecx
	sub ebx, 1
	cmp matrix[ebx], 9
	jne nu_e_bomba3
	inc esi
	nu_e_bomba3:
	
	mov ebx, ecx
	add ebx, 15
	cmp matrix[ebx], 9
	jne nu_e_bomba02
	inc esi
	nu_e_bomba02:
	
	mov eax, 0
	mov al, cl
	mov edx, 0
	mov edi, 16
	div edi

	cmp edx, 15
	je rest15

	rest0:
	
	mov ebx, ecx
	add ebx, 1
	cmp matrix[ebx], 9
	jne nu_e_bomba03
	inc esi
	nu_e_bomba03:
	
	mov ebx, ecx
	sub ebx, 15
	cmp matrix[ebx], 9
	jne nu_e_bomba2
	inc esi
	nu_e_bomba2:
	
	mov ebx, ecx
	add ebx, 17
	cmp matrix[ebx], 9
	jne nu_e_bomba00
	inc esi
	nu_e_bomba00:
	
	rest15:
	
	mov ebx, ecx
	add ebx, 16
	cmp matrix[ebx], 9
	jne nu_e_bomba01
	inc esi
	nu_e_bomba01:
	
	mov ebx, ecx
	sub ebx, 16
	cmp matrix[ebx], 9
	jne nu_e_bomba1
	inc esi
	nu_e_bomba1:
	
	mov eax, esi
	mov matrix[ecx], al
	e_bomba:
	dec ecx
	jns repetare
	;terminarea programului
	popa
	ret
	initializare_matrice endp

desenare_vertical proc
	pusha
	mov ecx, matrix_width
	add ecx, 20
	repetare1:
	mov edx, 249
	inc ecx
	sub ecx, 20
	add ecx, edx
	linie_vertical ecx, 250, matrix_height, 0
	sub ecx, edx
	loop repetare1
	popa
	ret
desenare_vertical endp

desenare_orizontal proc
	pusha
	mov ecx, matrix_height
	add ecx, 20
	repetare2:
	mov edx, 249
	inc ecx
	sub ecx, 20
	add ecx, edx
	linie_orizontal 250, ecx, matrix_width, 0
	sub ecx, edx
	loop repetare2
	popa
	ret
desenare_orizontal endp

desenare_f proc
	pusha
	mov ecx, matrix_width
	repetare3:
	mov edx, 250
	add ecx, edx
	linie_vertical ecx, 250, matrix_height, 08090DDh


	sub ecx, edx
	loop repetare3
	popa
	ret
desenare_f endp

desenare_dreptunghi_joc proc
	pusha
	linie_vertical  230, 150, 480, 0
	linie_vertical  590, 150, 480, 0
	linie_orizontal 230, 150, 360, 0
	linie_orizontal 230, 629, 360, 0
	mov ecx, 359
	repetare4:
	mov edx, 230
	add ecx, edx
	linie_vertical ecx, 151, 478, 06D7BBEh
	sub ecx, edx
	loop repetare4
	
	;nr click uri
	linie_vertical  324, 185, 30, 0
	linie_vertical  365, 185, 30, 0
	linie_orizontal 325, 184, 40, 0
	linie_orizontal 325, 215, 40, 0
	mov ecx, 40
	repetare7:
	mov edx, 324
	add ecx, edx
	linie_vertical ecx, 185, 30, 0FCFCFCh
	sub ecx, edx
	loop repetare7

	linie_vertical  424, 185, 30, 0
	linie_vertical  465, 185, 30, 0
	linie_orizontal 425, 184, 40, 0
	linie_orizontal 425, 215, 40, 0
	mov ecx, 40
	repetare5:
	mov edx, 424
	add ecx, edx
	linie_vertical ecx, 185, 30, 0FCFCFCh
	sub ecx, edx
	loop repetare5
	;timer
	linie_vertical  524, 185, 30, 0
	linie_vertical  565, 185, 30, 0
	linie_orizontal 525, 184, 40, 0
	linie_orizontal 525, 215, 40, 0
	mov ecx, 40
	repetare6:
	mov edx, 524
	add ecx, edx
	linie_vertical ecx, 185, 30, 0FCFCFCh
	sub ecx, edx
	loop repetare6
	
	linie_vertical  469, 30, 49, 0
	linie_vertical  519, 30, 49, 0
	linie_orizontal 470, 29, 49, 0
	linie_orizontal 470, 78, 49, 0
	make_image_macro_flag_buton_neapasat area, 471, 30
	popa
	ret
desenare_dreptunghi_joc endp
	
aratat_numere macro n, x, y
local nu_0, nu_1, nu_2, nu_3, nu_4, nu_5, nu_6, nu_7, nu_8, nu_9, final, nu_e_steag,fara_steaguri_ramase, steag_pus0, steag_pus1, steag_pus2, steag_pus3, steag_pus4, steag_pus5, steag_pus6, steag_pus7, steag_pus8
	cmp flag, 1
	jne  nu_e_steag
	cmp counter2, 0
	je fara_steaguri_ramase
	dec counter2

	make_image_macro_steag area, x, y ; draw the given image at coordinates (26,26)
	mov vector_flag[n], 1
	mov apasat[n], 0
	fara_steaguri_ramase:
	dec flag
	
	jmp final
	nu_e_steag:
	cmp matrix[n], 0
	jne nu_0
	cmp vector_flag[n], 1
	jne steag_pus0
	inc counter2
	steag_pus0:
	make_image_macro_0 area, x, y ; draw the given image at coordinates (26,26)
	inc counter1
	nu_0:
	cmp matrix[n], 1
	jne nu_1
	cmp vector_flag[n], 1
	jne steag_pus1
	inc counter2
	steag_pus1:
	make_image_macro_1 area, x, y ; draw the given image at coordinates (26,26)
	inc counter1
	nu_1:
	cmp matrix[n], 2
	jne nu_2
	cmp vector_flag[n], 1
	jne steag_pus2
	inc counter2
	steag_pus2:
	make_image_macro_2 area, x, y ; draw the given image at coordinates (26,26)
	inc counter1
	nu_2:
	cmp matrix[n], 3
	jne nu_3
	cmp vector_flag[n], 1
	jne steag_pus3
	inc counter2
	steag_pus3:
	make_image_macro_3 area, x, y ; draw the given image at coordinates (26,26)
	inc counter1
	nu_3:
	cmp matrix[n], 4
	jne nu_4
	cmp vector_flag[n], 1
	jne steag_pus4
	inc counter2
	steag_pus4:
	make_image_macro_4 area, x, y ; draw the given image at coordinates (26,26)
	inc counter1
	nu_4:
	cmp matrix[n], 5
	jne nu_5
	cmp vector_flag[n], 1
	jne steag_pus5
	inc counter2
	steag_pus5:
	make_image_macro_5 area, x, y ; draw the given image at coordinates (26,26)
	inc counter1
	nu_5:
	cmp matrix[n], 6
	jne nu_6
	cmp vector_flag[n], 1
	jne steag_pus6
	inc counter2
	steag_pus6:
	make_image_macro_6 area, x, y ; draw the given image at coordinates (26,26)
	inc counter1
	nu_6:
	cmp matrix[n], 7
	jne nu_7
	cmp vector_flag[n], 1
	jne steag_pus7
	inc counter2
	steag_pus7:
	make_image_macro_7 area, x, y ; draw the given image at coordinates (26,26)
	inc counter1
	nu_7:
	cmp matrix[n], 8
	jne nu_8
	cmp vector_flag[n], 1
	jne steag_pus8
	inc counter2
	steag_pus8:
	make_image_macro_8 area, x, y ; draw the given image at coordinates (26,26)
	inc counter1
	nu_8:
	cmp matrix[n], 9
	jne nu_9
	make_image_macro_go area, 390, 575
	make_image_macro_9 area, x, y ; draw the given image at coordinates (26,26)
	mov proces, 1
	nu_9:
	final:
	popa
	mov esp, ebp
	pop ebp
	
endm

afisare macro x,y
local cautare_pe_x, cautare_pe_y, terminare, nu_e_buton
	pusha
	mov eax, x
	mov ebx, y
	cmp eax, 469
	jl nu_e_buton
	cmp eax, 518
	jg nu_e_buton
	cmp ebx, 30
	jl nu_e_buton
	cmp ebx, 78
	jg nu_e_buton

	pusha
	mov esi, 1
	mov flag, 1
	popa
	inc numar_flag
	
	nu_e_buton:
	
	cmp eax, 250
	jl terminare
	cmp eax, 569
	jg terminare
	cmp ebx, 250
	jl terminare
	cmp ebx, 569
	jg terminare

	
	mov ecx, 229;incrementam apoi la 249
	mov edx, 229
	mov edi, 16
	
	cautare_pe_x:
	add ecx, 20
	cmp eax, ecx
	jg cautare_pe_x; in ecx avem latura din drepata a patratului
	
	cautare_pe_y:
	add edx, 20
	cmp ebx, edx
	jg cautare_pe_y; in edx avem latura de jos a patratului
	
	mov eax, ecx; pun pe x in eax
	mov ecx, edx; pun pe y in ecx

	push edx
	push eax

	sub eax, 249
	push ecx
	push edx
	mov edx, 0
	mov ecx, 20
	div ecx
	
	dec eax

	pop edx
	pop ecx
	push eax
	
	push eax

	pop eax
	
	
	mov eax, ecx
	sub eax, 249

	dec eax
	push ecx
	push edx
	mov edx, 0
	mov ecx, 20

	div ecx
	
	mov edx, 0
	mov ecx, 16
	mul ecx
	pop edx
	pop ecx
	pop edi
	add edi, eax;se afla valoarea din matrice a patratului apasat
	pop eax
	pop edx
	sub eax, 20
	sub edx, 20
	push ebp
	mov ebp, esp
	pusha

	;initialize window with white pixels
	add eax, 2
	add edx, 2

	
	; mov ecx, 0
	; sare:
	cmp apasat[edi], 1
	je sari_peste
	mov apasat[edi], 1
	aratat_numere edi, eax, edx
	sari_peste:
	
	pusha
	push counter1
	push offset format
	call printf
	add esp, 12
	popa
	
	terminare:
	popa
	endm

	
make_image_steag proc
	push ebp
	mov ebp, esp
	pusha

	lea esi, var_10
	
draw_image:
	mov ecx, image_height
loop_draw_lines:
	mov edi, [ebp+arg1] ; pointer to pixel area
	mov eax, [ebp+arg3] ; pointer to coordinate y
	
	add eax, image_height 
	sub eax, ecx ; current line to draw (total - ecx)
	
	mov ebx, area_width
	mul ebx	; get to current line
	
	add eax, [ebp+arg2] ; get to coordinate x in current line
	shl eax, 2 ; multiply by 4 (DWORD per pixel)
	add edi, eax
	
	push ecx
	mov ecx, image_width ; store drawing width for drawing loop
	
loop_draw_columns:

	push eax
	mov eax, dword ptr[esi] 
	mov dword ptr [edi], eax ; take data from variable to canvas
	pop eax
	
	add esi, 4
	add edi, 4 ; next dword (4 Bytes)
	
	loop loop_draw_columns
	
	pop ecx
	loop loop_draw_lines
	popa
	
	mov esp, ebp
	pop ebp
	ret
make_image_steag endp

; simple macro to call the procedure easier
make_image_macro_steag macro drawArea, x, y
	push y
	push x
	push drawArea
	call make_image_steag
	add esp, 12
endm
	
	
	make_image_go proc
	push ebp
	mov ebp, esp
	pusha
	lea esi, var_13
	
draw_image:
	mov ecx, image_height1
loop_draw_lines:
	mov edi, [ebp+arg1] ; pointer to pixel area
	mov eax, [ebp+arg3] ; pointer to coordinate y
	
	add eax, image_height1
	sub eax, ecx ; current line to draw (total - ecx)
	
	mov ebx, area_width
	mul ebx	; get to current line
	
	add eax, [ebp+arg2] ; get to coordinate x in current line
	shl eax, 2 ; multiply by 4 (DWORD per pixel)
	add edi, eax
	
	push ecx
	mov ecx, image_width1 ; store drawing width for drawing loop
	
loop_draw_columns:

	push eax
	mov eax, dword ptr[esi] 
	mov dword ptr [edi], eax ; take data from variable to canvas
	pop eax
	
	add esi, 4
	add edi, 4 ; next dword (4 Bytes)
	
	loop loop_draw_columns
	
	pop ecx
	loop loop_draw_lines
	popa
	
	mov esp, ebp
	pop ebp
	ret
make_image_go endp

; simple macro to call the procedure easier
make_image_macro_go macro drawArea, x, y
	push y
	push x
	push drawArea
	call make_image_go
	add esp, 12
endm


make_image_win proc
	push ebp
	mov ebp, esp
	pusha
	lea esi, var_14
	
draw_image:
	mov ecx, image_height1
loop_draw_lines:
	mov edi, [ebp+arg1] ; pointer to pixel area
	mov eax, [ebp+arg3] ; pointer to coordinate y
	
	add eax, image_height1
	sub eax, ecx ; current line to draw (total - ecx)
	
	mov ebx, area_width
	mul ebx	; get to current line
	
	add eax, [ebp+arg2] ; get to coordinate x in current line
	shl eax, 2 ; multiply by 4 (DWORD per pixel)
	add edi, eax
	
	push ecx
	mov ecx, image_width1 ; store drawing width for drawing loop
	
loop_draw_columns:

	push eax
	mov eax, dword ptr[esi] 
	mov dword ptr [edi], eax ; take data from variable to canvas
	pop eax
	
	add esi, 4
	add edi, 4 ; next dword (4 Bytes)
	
	loop loop_draw_columns
	
	pop ecx
	loop loop_draw_lines
	popa
	
	mov esp, ebp
	pop ebp
	ret
make_image_win endp

; simple macro to call the procedure easier
make_image_macro_win macro drawArea, x, y
	push y
	push x
	push drawArea
	call make_image_win
	add esp, 12
endm
	
make_image_0 proc
	push ebp
	mov ebp, esp
	pusha

	lea esi, var_0
	
draw_image:
	mov ecx, image_height
loop_draw_lines:
	mov edi, [ebp+arg1] ; pointer to pixel area
	mov eax, [ebp+arg3] ; pointer to coordinate y
	
	add eax, image_height 
	sub eax, ecx ; current line to draw (total - ecx)
	
	mov ebx, area_width
	mul ebx	; get to current line
	
	add eax, [ebp+arg2] ; get to coordinate x in current line
	shl eax, 2 ; multiply by 4 (DWORD per pixel)
	add edi, eax
	
	push ecx
	mov ecx, image_width ; store drawing width for drawing loop
	
loop_draw_columns:

	push eax
	mov eax, dword ptr[esi] 
	mov dword ptr [edi], eax ; take data from variable to canvas
	pop eax
	
	add esi, 4
	add edi, 4 ; next dword (4 Bytes)
	
	loop loop_draw_columns
	
	pop ecx
	loop loop_draw_lines
	popa
	
	mov esp, ebp
	pop ebp
	ret
make_image_0 endp

; simple macro to call the procedure easier
make_image_macro_0 macro drawArea, x, y
	push y
	push x
	push drawArea
	call make_image_0
	add esp, 12
endm


make_image_1 proc
	push ebp
	mov ebp, esp
	pusha

	lea esi, var_1
	
draw_image:
	mov ecx, image_height
loop_draw_lines:
	mov edi, [ebp+arg1] ; pointer to pixel area
	mov eax, [ebp+arg3] ; pointer to coordinate y
	
	add eax, image_height 
	sub eax, ecx ; current line to draw (total - ecx)
	
	mov ebx, area_width
	mul ebx	; get to current line
	
	add eax, [ebp+arg2] ; get to coordinate x in current line
	shl eax, 2 ; multiply by 4 (DWORD per pixel)
	add edi, eax
	
	push ecx
	mov ecx, image_width ; store drawing width for drawing loop
	
loop_draw_columns:

	push eax
	mov eax, dword ptr[esi] 
	mov dword ptr [edi], eax ; take data from variable to canvas
	pop eax
	
	add esi, 4
	add edi, 4 ; next dword (4 Bytes)
	
	loop loop_draw_columns
	
	pop ecx
	loop loop_draw_lines
	popa
	
	mov esp, ebp
	pop ebp
	ret
make_image_1 endp

; simple macro to call the procedure easier
make_image_macro_1 macro drawArea, x, y
	push y
	push x
	push drawArea
	call make_image_1
	add esp, 12
endm


make_image_2 proc
	push ebp
	mov ebp, esp
	pusha

	lea esi, var_2
	
draw_image:
	mov ecx, image_height
loop_draw_lines:
	mov edi, [ebp+arg1] ; pointer to pixel area
	mov eax, [ebp+arg3] ; pointer to coordinate y
	
	add eax, image_height 
	sub eax, ecx ; current line to draw (total - ecx)
	
	mov ebx, area_width
	mul ebx	; get to current line
	
	add eax, [ebp+arg2] ; get to coordinate x in current line
	shl eax, 2 ; multiply by 4 (DWORD per pixel)
	add edi, eax
	
	push ecx
	mov ecx, image_width ; store drawing width for drawing loop
	
loop_draw_columns:

	push eax
	mov eax, dword ptr[esi] 
	mov dword ptr [edi], eax ; take data from variable to canvas
	pop eax
	
	add esi, 4
	add edi, 4 ; next dword (4 Bytes)
	
	loop loop_draw_columns
	
	pop ecx
	loop loop_draw_lines
	popa
	
	mov esp, ebp
	pop ebp
	ret
make_image_2 endp

; simple macro to call the procedure easier
make_image_macro_2 macro drawArea, x, y
	push y
	push x
	push drawArea
	call make_image_2
	add esp, 12
endm

make_image_3 proc
	push ebp
	mov ebp, esp
	pusha
	lea esi, var_3
	
draw_image:
	mov ecx, image_height
loop_draw_lines:
	mov edi, [ebp+arg1] ; pointer to pixel area
	mov eax, [ebp+arg3] ; pointer to coordinate y
	
	add eax, image_height 
	sub eax, ecx ; current line to draw (total - ecx)
	
	mov ebx, area_width
	mul ebx	; get to current line
	
	add eax, [ebp+arg2] ; get to coordinate x in current line
	shl eax, 2 ; multiply by 4 (DWORD per pixel)
	add edi, eax
	
	push ecx
	mov ecx, image_width ; store drawing width for drawing loop
	
loop_draw_columns:

	push eax
	mov eax, dword ptr[esi] 
	mov dword ptr [edi], eax ; take data from variable to canvas
	pop eax
	
	add esi, 4
	add edi, 4 ; next dword (4 Bytes)
	
	loop loop_draw_columns
	
	pop ecx
	loop loop_draw_lines
	popa
	
	mov esp, ebp
	pop ebp
	ret
make_image_3 endp

; simple macro to call the procedure easier
make_image_macro_3 macro drawArea, x, y
	push y
	push x
	push drawArea
	call make_image_3
	add esp, 12
endm

make_image_4 proc
	push ebp
	mov ebp, esp
	pusha
	lea esi, var_4
	
draw_image:
	mov ecx, image_height
loop_draw_lines:
	mov edi, [ebp+arg1] ; pointer to pixel area
	mov eax, [ebp+arg3] ; pointer to coordinate y
	
	add eax, image_height 
	sub eax, ecx ; current line to draw (total - ecx)
	
	mov ebx, area_width
	mul ebx	; get to current line
	
	add eax, [ebp+arg2] ; get to coordinate x in current line
	shl eax, 2 ; multiply by 4 (DWORD per pixel)
	add edi, eax
	
	push ecx
	mov ecx, image_width ; store drawing width for drawing loop
	
loop_draw_columns:

	push eax
	mov eax, dword ptr[esi] 
	mov dword ptr [edi], eax ; take data from variable to canvas
	pop eax
	
	add esi, 4
	add edi, 4 ; next dword (4 Bytes)
	
	loop loop_draw_columns
	
	pop ecx
	loop loop_draw_lines
	popa
	
	mov esp, ebp
	pop ebp
	ret
make_image_4 endp

; simple macro to call the procedure easier
make_image_macro_4 macro drawArea, x, y
	push y
	push x
	push drawArea
	call make_image_4
	add esp, 12
endm


make_image_5 proc
	push ebp
	mov ebp, esp
	pusha
	lea esi, var_5
	
draw_image:
	mov ecx, image_height
loop_draw_lines:
	mov edi, [ebp+arg1] ; pointer to pixel area
	mov eax, [ebp+arg3] ; pointer to coordinate y
	
	add eax, image_height 
	sub eax, ecx ; current line to draw (total - ecx)
	
	mov ebx, area_width
	mul ebx	; get to current line
	
	add eax, [ebp+arg2] ; get to coordinate x in current line
	shl eax, 2 ; multiply by 4 (DWORD per pixel)
	add edi, eax
	
	push ecx
	mov ecx, image_width ; store drawing width for drawing loop
	
loop_draw_columns:

	push eax
	mov eax, dword ptr[esi] 
	mov dword ptr [edi], eax ; take data from variable to canvas
	pop eax
	
	add esi, 4
	add edi, 4 ; next dword (4 Bytes)
	
	loop loop_draw_columns
	
	pop ecx
	loop loop_draw_lines
	popa
	
	mov esp, ebp
	pop ebp
	ret
make_image_5 endp

; simple macro to call the procedure easier
make_image_macro_5 macro drawArea, x, y
	push y
	push x
	push drawArea
	call make_image_5
	add esp, 12
endm

make_image_6 proc
	push ebp
	mov ebp, esp
	pusha
	lea esi, var_6
	
draw_image:
	mov ecx, image_height
loop_draw_lines:
	mov edi, [ebp+arg1] ; pointer to pixel area
	mov eax, [ebp+arg3] ; pointer to coordinate y
	
	add eax, image_height 
	sub eax, ecx ; current line to draw (total - ecx)
	
	mov ebx, area_width
	mul ebx	; get to current line
	
	add eax, [ebp+arg2] ; get to coordinate x in current line
	shl eax, 2 ; multiply by 4 (DWORD per pixel)
	add edi, eax
	
	push ecx
	mov ecx, image_width ; store drawing width for drawing loop
	
loop_draw_columns:

	push eax
	mov eax, dword ptr[esi] 
	mov dword ptr [edi], eax ; take data from variable to canvas
	pop eax
	
	add esi, 4
	add edi, 4 ; next dword (4 Bytes)
	
	loop loop_draw_columns
	
	pop ecx
	loop loop_draw_lines
	popa
	
	mov esp, ebp
	pop ebp
	ret
make_image_6 endp

; simple macro to call the procedure easier
make_image_macro_6 macro drawArea, x, y
	push y
	push x
	push drawArea
	call make_image_6
	add esp, 12
endm

make_image_7 proc
	push ebp
	mov ebp, esp
	pusha
	lea esi, var_7
	
draw_image:
	mov ecx, image_height
loop_draw_lines:
	mov edi, [ebp+arg1] ; pointer to pixel area
	mov eax, [ebp+arg3] ; pointer to coordinate y
	
	add eax, image_height 
	sub eax, ecx ; current line to draw (total - ecx)
	
	mov ebx, area_width
	mul ebx	; get to current line
	
	add eax, [ebp+arg2] ; get to coordinate x in current line
	shl eax, 2 ; multiply by 4 (DWORD per pixel)
	add edi, eax
	
	push ecx
	mov ecx, image_width ; store drawing width for drawing loop
	
loop_draw_columns:

	push eax
	mov eax, dword ptr[esi] 
	mov dword ptr [edi], eax ; take data from variable to canvas
	pop eax
	
	add esi, 4
	add edi, 4 ; next dword (4 Bytes)
	
	loop loop_draw_columns
	
	pop ecx
	loop loop_draw_lines
	popa
	
	mov esp, ebp
	pop ebp
	ret
make_image_7 endp

; simple macro to call the procedure easier
make_image_macro_7 macro drawArea, x, y
	push y
	push x
	push drawArea
	call make_image_7
	add esp, 12
endm

make_image_8 proc
	push ebp
	mov ebp, esp
	pusha
	lea esi, var_8
	
draw_image:
	mov ecx, image_height
loop_draw_lines:
	mov edi, [ebp+arg1] ; pointer to pixel area
	mov eax, [ebp+arg3] ; pointer to coordinate y
	
	add eax, image_height 
	sub eax, ecx ; current line to draw (total - ecx)
	
	mov ebx, area_width
	mul ebx	; get to current line
	
	add eax, [ebp+arg2] ; get to coordinate x in current line
	shl eax, 2 ; multiply by 4 (DWORD per pixel)
	add edi, eax
	
	push ecx
	mov ecx, image_width ; store drawing width for drawing loop
	
loop_draw_columns:

	push eax
	mov eax, dword ptr[esi] 
	mov dword ptr [edi], eax ; take data from variable to canvas
	pop eax
	
	add esi, 4
	add edi, 4 ; next dword (4 Bytes)
	
	loop loop_draw_columns
	
	pop ecx
	loop loop_draw_lines
	popa
	
	mov esp, ebp
	pop ebp
	ret
make_image_8 endp

; simple macro to call the procedure easier
make_image_macro_8 macro drawArea, x, y
	push y
	push x
	push drawArea
	call make_image_8
	add esp, 12
endm

make_image_9 proc
	push ebp
	mov ebp, esp
	pusha
	lea esi, var_9
	
draw_image:
	mov ecx, image_height
loop_draw_lines:
	mov edi, [ebp+arg1] ; pointer to pixel area
	mov eax, [ebp+arg3] ; pointer to coordinate y
	
	add eax, image_height 
	sub eax, ecx ; current line to draw (total - ecx)
	
	mov ebx, area_width
	mul ebx	; get to current line
	
	add eax, [ebp+arg2] ; get to coordinate x in current line
	shl eax, 2 ; multiply by 4 (DWORD per pixel)
	add edi, eax
	
	push ecx
	mov ecx, image_width ; store drawing width for drawing loop
	
loop_draw_columns:

	push eax
	mov eax, dword ptr[esi] 
	mov dword ptr [edi], eax ; take data from variable to canvas
	pop eax
	
	add esi, 4
	add edi, 4 ; next dword (4 Bytes)
	
	loop loop_draw_columns
	
	pop ecx
	loop loop_draw_lines
	popa
	
	mov esp, ebp
	pop ebp
	ret
make_image_9 endp

; simple macro to call the procedure easier
make_image_macro_9 macro drawArea, x, y
	push y
	push x
	push drawArea
	call make_image_9
	add esp, 12
endm


draw proc
	push ebp
	mov ebp, esp
	pusha
	
	mov esi, proces
	pusha
	push esi
	push offset format
	add esp, 8
	popa
	cmp esi, 1
	je pierdut
	
	mov esi, counter1
	cmp esi, 216
	jne castigati
	make_image_macro_win area, 390, 575
	castigati:
	
	mov esi, counter1
	cmp esi, 216
	je castigat
	
	mov eax, [ebp+arg1]
	cmp eax, 1
	jz evt_click
	cmp eax, 2
	jz evt_timer ; nu s-a efectuat click pe nimic
	;mai jos e codul care intializeaza fereastra cu pixeli albi
	
	mov eax, area_width
	mov ebx, area_height
	mul ebx
	shl eax, 2
	push eax
	push 255
	push area
	call memset
	add esp, 12
	call initializare_matrice
	call desenare_dreptunghi_joc
	call desenare_f
	call desenare_vertical
	call desenare_orizontal
	jmp afisare_litere
	
evt_click:
	;linie_orizontal [ebp+arg2], [ebp+arg3], 30, 0
	afisare [ebp+arg2], [ebp+arg3]
	jmp afisare_litere
	
evt_timer:
	; inc counter
	
	
afisare_litere:
	inc counter
	;afisam valoarea counter-ului curent (sute, zeci si unitati)
	mov ebx, 10
	mov edx, 0
	mov eax, counter
	mov ecx, 6
	div ecx
	;cifra unitatilor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, 549, 190
	;cifra zecilor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, 539, 190
	;cifra sutelor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, 529, 190
	
	;counter click
	mov eax, counter1
	
	;cifra unitatilor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, 449, 190
	;cifra zecilor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, 439, 190
	;cifra sutelor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, 429, 190
	
	
	;counter bombe ramase
	cmp counter2, 40
	ja sarit
	mov eax, counter2
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, 349, 190
	;cifra zecilor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, 339, 190
	;cifra sutelor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, 329, 190
	sarit:
	;linie_vertical 100, 100, matrix_height, 0
	;linie_vertical 140, 100, matrix_height, 0
	;call initializare_matrice
	;scriem un mesaj
	make_text_macro 'S', area, 40, 40
	make_text_macro 'I', area, 50, 40
	make_text_macro 'P', area, 60, 40
	make_text_macro 'O', area, 70, 40
	make_text_macro 'S', area, 80, 40
	
	make_text_macro 'B', area, 40, 80
	make_text_macro 'O', area, 50, 80
	make_text_macro 'G', area, 60, 80
	make_text_macro 'D', area, 70, 80
	make_text_macro 'A', area, 80, 80
	make_text_macro 'N', area, 90, 80
final_draw:
	pierdut:

	castigat:
	
	popa
	
	mov esp, ebp
	pop ebp
	ret
draw endp



start:
	;alocam memorie pentru zona de desenat
	mov eax, area_width
	mov ebx, area_height
	mul ebx
	shl eax, 2
	push eax
	call malloc
	add esp, 4
	mov area, eax
	;apelam functia de desenare a ferestrei
	; typedef void (*DrawFunc)(int evt, int x, int y);
	; void __cdecl BeginDrawing(const char *title, int width, int height, unsigned int *area, DrawFunc draw);
	push offset draw
	push area
	push area_height
	push area_width
	push offset window_title
	call BeginDrawing
	
	add esp, 20
	
	;terminarea programului
	push 0
	call exit
end start
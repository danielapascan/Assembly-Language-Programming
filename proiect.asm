.386
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
area_width EQU 640
area_height EQU 480
area DD 0

counter DD 0 ; numara evenimentele de tip timer

arg1 EQU 8
arg2 EQU 12
arg3 EQU 16
arg4 EQU 20
cons EQU 56

symbol_width EQU 10
symbol_height EQU 20
include digits.inc
include letters.inc

matrice dd 14 dup(0)
        dd 14 dup(0)
		dd 14 dup(0)
		dd 14 dup(0)
		dd 14 dup(0)
		dd 14 dup(0)
		dd 14 dup(0)
		dd 14 dup(0)
		dd 14 dup(0)
		dd 14 dup(0)

matrice2 dd 14 dup(0)
         dd 14 dup(0)
		 dd 14 dup(0)
		 dd 14 dup(0)
		 dd 14 dup(0)
		 dd 14 dup(0)
		 dd 14 dup(0)
		 dd 14 dup(0)
		 dd 14 dup(0)
		 dd 14 dup(0)
		
indice_bomba_x dd 0
indice_bomba_y dd 0
patratel_bomba_x dd 0
patratel_bomba_y dd 0

format1 db "%d ",0
format2 db 13,10,0
aux dd 0


linie db 0
coloana db 0

format3 db "%d %d" ,13,10,0

edii dd 0
esii dd 0
joaca db 1
nubomba db 0
win db 0
.code

; procedura make_text afiseaza o litera sau o cifra la coordonatele date
; arg1 - simbolul de afisat (litera sau cifra)
; arg2 - pointer la vectorul de pixeli
; arg3 - pos_x
; arg4 - pos_y

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
	mov dword ptr [edi], 6E2C00h
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

line_horizontal macro x,y,len,color 
local bucla_line
    mov eax,y
    mov ebx, area_width
    mul ebx
    add eax,x
    shl eax,2
    add eax,area
    mov ecx, len
bucla_line:
    mov dword ptr[eax],color
    add eax,4
loop bucla_line
endm

line_vertical macro x,y,len,color
local bucla_line
    mov eax,y
    mov ebx, area_width
    mul ebx
    add eax,x
    shl eax,2
    add eax,area
    mov ecx, len
	bucla_line:
	mov dword ptr[eax], color
	add eax,4*area_width
	loop bucla_line
	endm
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;end

castig macro
    make_text_macro 'A', area, 120, 15
	make_text_macro 'I', area, 130, 15
	make_text_macro 'C', area, 150, 15
	make_text_macro 'A', area, 160, 15
	make_text_macro 'S', area, 170, 15
	make_text_macro 'T', area, 180, 15
	
	make_text_macro 'I', area, 190, 15
	make_text_macro 'G', area, 200, 15
	make_text_macro 'A', area, 210, 15
	make_text_macro 'T', area, 220, 15

endm

pierd macro 
    make_text_macro 'G', area, 120, 15
	make_text_macro 'A', area, 130, 15
	make_text_macro 'M', area, 140, 15
	make_text_macro 'E', area, 150, 15
	make_text_macro 'O', area, 170, 15
	make_text_macro 'V', area, 180, 15
	
	make_text_macro 'E', area, 190, 15
	make_text_macro 'R', area, 200, 15

endm







;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;aici facem matricea in care generam random un numar dat de bombelor

random_macro macro numar_bombe

 local bomba
 local introducere_bomba
 local decrementare 
 
    mov aux,0
	mov edx,0
bomba:
    ; generare nr random pentru rand
    rdtsc
    xor edx, edx
	mov ebx, 10
	div ebx
	mov indice_bomba_x, edx
	mov esi,edx
	
    ;generare nr random pt coloana	
	rdtsc
    xor edx, edx
	mov ebx, 14
	div ebx
	mov indice_bomba_y, edx
	mov edi,edx
	
	add esi,1
	add edi,1
	mov eax,56
	mul esi ; eax=4*14*(esi+1)
	mov ebx,eax
	
	mov ecx,14
	sub ecx, edi
	mov eax, 4
    mul ecx ;eax=4*(14-(edi+1)
	mov ecx,eax
	
	sub ebx,ecx ;formula intreaga e in ebx
	sub ebx,4
	

	mov ecx, numar_bombe
	cmp aux,ecx
	jle introducere_bomba
	
introducere_bomba:
    mov matrice[ebx],1
	;inc bomba
	inc aux
	mov ecx, numar_bombe
	cmp aux, ecx
	jle bomba
		
endm
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
det_numar_bombe macro
     pusha
	 mov esi, 0
	 mov edi, 0
	 
	 incrementare3:
	 cmp matrice[esi][edi],1
	 je skip
	 inc nubomba
skip:
     add edi,4
     cmp edi,52
	 jle incrementare3
	 jg incrementare_rand3
	 
     incrementare_rand3:
     mov edi,0
	 add esi,56
	 cmp esi,504
	 jle incrementare3
	 jg exit_mat2
	 
exit_mat2:
     inc nubomba
	  popa


   endm




;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;aici fac matricea cu numere, unde e 9 e bomba

matrice_numere macro 
     mov esi,0
     mov edi,0
	 
bombe:
  cmp matrice[esi][edi],0
  je cautare_bombe_in_matrice
  cmp matrice[esi][edi],1
  je pune_bomba
  
   ;aici cautam toti vecinii unui element sa vedem daca sunt bombe 
	
 cautare_bombe_in_matrice:

    cmp esi,0 ; daca suntem pe prima linie
	je fara_sus
	cmp esi, 504; daca suntem pe ultima linie
	je fara_jos
	cmp edi, 0; daca suntem pe prima coloana
	je fara_stanga
	cmp edi, 52 ; daca suntem pe ultima coloana
	je fara_dreapta
	jmp interior
	
fara_sus:
    cmp edi,0 ; daca e coltul din stanga sus
	je colt_stanga_sus
	cmp edi, 52 ; daca e coltul din dreapta sus
	je colt_dreapta_sus
	;daca nu e nici o varianta de mai sus inseamna ca e doar pe linia de sus
	mov eax, 0
	add eax, matrice[esi][edi+4]
	add eax, matrice[esi][edi-4]
	add eax, matrice[esi+56][edi]
	add eax, matrice[esi+56][edi+4]
	add eax, matrice[esi+56][edi-4]
	jmp punere_matrice
	
fara_jos:
   cmp edi,0 ; daca e coltul din stanga jos
   je colt_stanga_jos
   cmp edi,52; daca e coltul din dreapta jos
   je colt_dreapta_jos
   ;daca nu e nici unul din cazurile de mai sus
   mov eax, 0
   add eax, matrice[esi][edi+4]
   add eax, matrice[esi][edi-4]
   add eax, matrice[esi-56][edi]
   add eax, matrice [esi-56][edi+4]
   add eax, matrice[esi-56][edi-4]
   jmp punere_matrice
	
fara_stanga:
    cmp esi, 0;daca e coltul din stanga sus
	je colt_stanga_sus
	cmp esi, 36; daca e coltul din stanga jos
	je colt_stanga_jos
	;daca nu e nici una dintre conditii
	mov eax,0
	add eax, matrice[esi-56][edi]
	add eax, matrice[esi-56][edi+4]
	add eax, matrice[esi+56][edi]
	add eax, matrice[esi+56][edi+4]
	add eax, matrice[esi][edi+4]
	jmp punere_matrice
	
fara_dreapta:
    cmp esi, 0 ; daca suntem pe prima linie
    je colt_dreapta_sus
    cmp esi, 36 ; daca suntem pe ultima linie
    je colt_dreapta_jos
    ; daca nu sunt indeplinite conditiile
    mov eax, 0;
    add eax, matrice[esi-56][edi]
    add eax, matrice[esi-56][edi-4]
    add eax, matrice[esi][edi-4]
    add eax, matrice[esi+56][edi-4]
    add eax, matrice[esi+56][edi]
    jmp punere_matrice
	
colt_stanga_sus:
    mov eax, 0
	add eax, matrice[esi][edi+4]
	add eax, matrice[esi+56][edi]
	add eax, matrice[esi+56][edi+4]
	jmp punere_matrice
	
colt_dreapta_sus:
    mov eax, 0
	add eax, matrice[esi][edi-4]
	add eax, matrice[esi+56][edi-4]
	add eax, matrice[esi+56][edi]
	jmp punere_matrice
	
colt_stanga_jos:
    mov eax, 0
	add eax, matrice[esi-56][edi]
	add eax, matrice[esi-56][edi+4]
	add eax, matrice[esi][edi+4]
	jmp punere_matrice
	
colt_dreapta_jos:
    mov eax, 0
	add eax, matrice[esi][edi-4]
	add eax, matrice[esi-56][edi-4]
	mov eax, matrice[esi-56][edi]
	jmp punere_matrice
	
	
interior:	
    mov eax,0  
    add eax, matrice[esi][edi+4]
	add eax, matrice[esi][edi-4]
	add eax, matrice[esi-56][edi]
	add eax, matrice[esi+56][edi]
	add eax, matrice[esi-56][edi+4]
	add eax, matrice[esi-56][edi-4]
	add eax, matrice[esi+56][edi-4]
	add eax, matrice[esi+56][edi+4] 
	jmp punere_matrice
	
pune_bomba:
    mov matrice2[esi][edi],9
	jmp incrementare
	
punere_matrice:
    mov matrice2[esi][edi],eax
	jmp incrementare	
	
incrementare:
     add edi,4
     cmp edi,52
	 jle bombe
	 jg incrementare_rand
	 
incrementare_rand:
    mov edi,0
	add esi,56
	cmp esi,504
	jle bombe
	jg exit_mat
	
exit_mat:
 endm
 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;aici avem macrouri pentru punerea in canvas

; macro bomba
bomba_canvas macro patratel_bomba_x, patratel_bomba_y
make_text_macro 'B', area, patratel_bomba_x, patratel_bomba_y
mov joaca,0
endm 

;macro 0

zero macro patratel_bomba_x, patratel_bomba_y
make_text_macro '0', area, patratel_bomba_x, patratel_bomba_y
endm 

;macro 1

unu macro patratel_bomba_x, patratel_bomba_y
make_text_macro '1', area, patratel_bomba_x, patratel_bomba_y
endm 

;macro 2

doi macro patratel_bomba_x, patratel_bomba_y
make_text_macro '2', area, patratel_bomba_x, patratel_bomba_y
endm 

;macro 3

trei macro patratel_bomba_x, patratel_bomba_y
make_text_macro '3', area, patratel_bomba_x, patratel_bomba_y
endm 

;macro 4

patru macro patratel_bomba_x, patratel_bomba_y
make_text_macro '4', area, patratel_bomba_x, patratel_bomba_y
endm 

;macro 5 

cinci macro patratel_bomba_x, patratel_bomba_y
make_text_macro '5', area, patratel_bomba_x, patratel_bomba_y
endm 

;macro 6

sase macro patratel_bomba_x, patratel_bomba_y
make_text_macro '6', area, patratel_bomba_x, patratel_bomba_y
endm 

;macro 7

sapte macro patratel_bomba_x, patratel_bomba_y
make_text_macro '7', area, patratel_bomba_x, patratel_bomba_y
endm 

;macro 8

opt macro patratel_bomba_x, patratel_bomba_y
make_text_macro '8', area, patratel_bomba_x, patratel_bomba_y
endm 



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;aici parcurgem matricea principala ca sa o transpunem in canvas

pune_canvas macro x,y
local completare
local pune_bomba2
local pune_zero
local pune_unu
local pune_doi
local pune_trei
local pune_patru
local pune_cinci
local pune_sase
local pune_sapte
local pune_opt
local incrementare2
local incrementare_linie2
local final

pusha
     mov eax, 0
     mov al, x
	 mov ebx, 4
	 mul ebx
     mov esi,eax
	 mov esii,esi
	 mov eax, 0
     mov al, y
	 mov ebx, 56
	 mul ebx
	 mov edi,eax
	 mov edii,edi
	 popa
	 
	mov edi,esii
	mov esi,edii
	 ; trebuie parcursa matricea
	 

	 cmp matrice2[esi][edi],9
	 je pune_bomba2
	 cmp matrice2[esi][edi],0
	 je pune_zero
	 cmp matrice2[esi][edi],1
	 je pune_unu
	 cmp matrice2[esi][edi],2
	 je pune_doi
	 cmp matrice2[esi][edi],3
	 je pune_trei
	 cmp matrice2[esi][edi],4
	 je pune_patru
	 cmp matrice2[esi][edi],5
	 je pune_cinci
	 cmp matrice2[esi][edi],6
	 je pune_sase
	 cmp matrice2[esi][edi],7
	 je pune_sapte
	 cmp matrice2[esi][edi],8
	 je pune_opt

pune_bomba2:
     mov edx, 0
	 mov eax,edi 
	 mov ebx, 4
	 div ebx
	 add eax, 1 
	 mov ebx, 40
	 mul ebx 
	 add eax, 10 ; ca sa incadrez in patratica
	 mov patratel_bomba_y, eax ;aici avem coordonata pixelului la care trebuie pusa bomba 
	 
	 mov edx, 0
	 mov eax, esi
	 mov ebx, 56
	 div ebx
	 add eax, 1
	 mov ebx, 40
	 mul ebx
	 add eax, 10 ; ca sa incadrez in patratica
	 mov patratel_bomba_x, eax 
	 
	 bomba_canvas patratel_bomba_y, patratel_bomba_x
	 jmp final
	 
pune_zero:
     mov edx, 0
	 mov eax,edi 
	 mov ebx, 4
	 div ebx
	 add eax, 1 
	 mov ebx, 40
	 mul ebx 
	 add eax, 10 ; ca sa incadrez in patratica
	 mov patratel_bomba_y, eax ;aici avem coordonata pixelului la care trebuie pusa bomba 
	 
	 mov edx, 0
	 mov eax, esi
	 mov ebx, 56
	 div ebx
	 add eax, 1
	 mov ebx, 40
	 mul ebx
	 add eax, 10 ; ca sa incadrez in patratica
	 mov patratel_bomba_x, eax 
	 
	 zero patratel_bomba_y, patratel_bomba_x
	 jmp final
	 
	 
pune_unu:
     mov edx, 0
	 mov eax,edi 
	 mov ebx, 4
	 div ebx
	 add eax, 1 
	 mov ebx, 40
	 mul ebx 
	 add eax, 10 ; ca sa incadrez in patratica
	 mov patratel_bomba_y, eax ;aici avem coordonata pixelului la care trebuie pusa bomba 
	 
	 mov edx, 0
	 mov eax, esi
	 mov ebx, 56
	 div ebx
	 add eax, 1
	 mov ebx, 40
	 mul ebx
	 add eax, 10 ; ca sa incadrez in patratica
	 mov patratel_bomba_x, eax 
	 
	 unu patratel_bomba_y, patratel_bomba_x
	 jmp final
	 
pune_doi:
     mov edx, 0
	 mov eax,edi 
	 mov ebx, 4
	 div ebx
	 add eax, 1 
	 mov ebx, 40
	 mul ebx 
	 add eax, 10 ; ca sa incadrez in patratica
	 mov patratel_bomba_y, eax ;aici avem coordonata pixelului la care trebuie pusa bomba 
	 
	 mov edx, 0
	 mov eax, esi
	 mov ebx, 56
	 div ebx
	 add eax, 1
	 mov ebx, 40
	 mul ebx
	 add eax, 10 ; ca sa incadrez in patratica
	 mov patratel_bomba_x, eax 
	 
	 doi patratel_bomba_y, patratel_bomba_x
	 jmp final
	 
pune_trei:
     mov edx, 0
	 mov eax,edi 
	 mov ebx, 4
	 div ebx
	 add eax, 1 
	 mov ebx, 40
	 mul ebx 
	 add eax, 10 ; ca sa incadrez in patratica
	 mov patratel_bomba_y, eax ;aici avem coordonata pixelului la care trebuie pusa bomba 
	 
	 mov edx, 0
	 mov eax, esi
	 mov ebx, 56
	 div ebx
	 add eax, 1
	 mov ebx, 40
	 mul ebx
	 add eax, 10 ; ca sa incadrez in patratica
	 mov patratel_bomba_x, eax 
	 
	 trei patratel_bomba_y, patratel_bomba_x
	 jmp final
	 
pune_patru:
     mov edx, 0
	 mov eax,edi 
	 mov ebx, 4
	 div ebx
	 add eax, 1 
	 mov ebx, 40
	 mul ebx 
	 add eax, 10 ; ca sa incadrez in patratica
	 mov patratel_bomba_y, eax ;aici avem coordonata pixelului la care trebuie pusa bomba 
	 
	 mov edx, 0
	 mov eax, esi
	 mov ebx, 56
	 div ebx
	 add eax, 1
	 mov ebx, 40
	 mul ebx
	 add eax, 10 ; ca sa incadrez in patratica
	 mov patratel_bomba_x, eax 
	 
	 patru patratel_bomba_y, patratel_bomba_x
	 jmp final
	 
pune_cinci:
     mov edx, 0
	 mov eax,edi 
	 mov ebx, 4
	 div ebx
	 add eax, 1 
	 mov ebx, 40
	 mul ebx 
	 add eax, 10 ; ca sa incadrez in patratica
	 mov patratel_bomba_y, eax ;aici avem coordonata pixelului la care trebuie pusa bomba 
	 
	 mov edx, 0
	 mov eax, esi
	 mov ebx, 56
	 div ebx
	 add eax, 1
	 mov ebx, 40
	 mul ebx
	 add eax, 10 ; ca sa incadrez in patratica
	 mov patratel_bomba_x, eax 
	 
	 cinci patratel_bomba_y, patratel_bomba_x
	 jmp final
	 
pune_sase:
     mov edx, 0
	 mov eax,edi 
	 mov ebx, 4
	 div ebx
	 add eax, 1 
	 mov ebx, 40
	 mul ebx 
	 add eax, 10 ; ca sa incadrez in patratica
	 mov patratel_bomba_y, eax ;aici avem coordonata pixelului la care trebuie pusa bomba 
	 
	 mov edx, 0
	 mov eax, esi
	 mov ebx, 56
	 div ebx
	 add eax, 1
	 mov ebx, 40
	 mul ebx
	 add eax, 10 ; ca sa incadrez in patratica
	 mov patratel_bomba_x, eax 
	 
	 sase patratel_bomba_y, patratel_bomba_x
	 jmp final
	 
pune_sapte:
     mov edx, 0
	 mov eax,edi 
	 mov ebx, 4
	 div ebx
	 add eax, 1 
	 mov ebx, 40
	 mul ebx 
	 add eax, 10 ; ca sa incadrez in patratica
	 mov patratel_bomba_y, eax ;aici avem coordonata pixelului la care trebuie pusa bomba 
	 
	 mov edx, 0
	 mov eax, esi
	 mov ebx, 56
	 div ebx
	 add eax, 1
	 mov ebx, 40
	 mul ebx
	 add eax, 10 ; ca sa incadrez in patratica
	 mov patratel_bomba_x, eax 
	 
	 sapte patratel_bomba_y, patratel_bomba_x
	 jmp final
	 
pune_opt:
     mov edx, 0
	 mov eax,edi 
	 mov ebx, 4
	 div ebx
	 add eax, 1 
	 mov ebx, 40
	 mul ebx 
	 add eax, 10 ; ca sa incadrez in patratica
	 mov patratel_bomba_y, eax ;aici avem coordonata pixelului la care trebuie pusa bomba 
	 
	 mov edx, 0
	 mov eax, esi
	 mov ebx, 56
	 div ebx
	 add eax, 1
	 mov ebx, 40
	 mul ebx
	 add eax, 10 ; ca sa incadrez in patratica
	 mov patratel_bomba_x, eax 
	 
	 opt patratel_bomba_y, patratel_bomba_x
	jmp final 
	 
final:
  
endm 

	
; functia de desenare - se apeleaza la fiecare click
; sau la fiecare interval de 200ms in care nu s-a dat click
; arg1 - evt (0 - initializare, 1 - click, 2 - s-a scurs intervalul fara click)
; arg2 - x
; arg3 - y


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
det_celula macro x,y 
	sub y,1
	sub x,1
	mov eax,0
	add al,x
	mov ebx,4
	mul ebx
	mov ecx,eax
	mov eax,0
	mov al,y
	mov ebx,56
	mul ebx
	add eax,ecx
	pune_canvas x,y
	dec nubomba
	
endm

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
numar_patratica proc
push ebp
	mov ebp, esp
	pusha
	mov eax,[ebp+arg1]
	cmp eax,40
	jb final2
	cmp eax,440
	ja final2
	mov eax,[ebp+arg2]
	cmp eax,40
	jb final2
	cmp eax,600
	ja final2
	
	
	
    mov eax,[ebp+arg1]
	mov bl, 40
	div bl
	
	mov coloana, al 
	
	mov eax,[ebp+arg2]
	mov bl, 40
	div bl
	
	mov linie, al 
	
    pusha 
	mov eax, 0
	mov ebx, 0
	mov al, linie
	mov bl, coloana

	det_celula linie, coloana
	
final2:

	popa
	mov esp, ebp
	pop ebp
	ret
	
numar_patratica endp



draw proc
	push ebp
	mov ebp, esp
	pusha
	
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
	random_macro 20 ;punerea random a bombelor in matrice
    matrice_numere  ;aici facem matricea principala
	det_numar_bombe
	;pune_canvas
	jmp afisare_litere
	
	
evt_click:
    cmp win, 1
	je button_fail
    cmp joaca,0
	je button_fail
    push [ebp+arg2]
	push [ebp+arg3]
	call numar_patratica
	add esp,8
	pusha
	mov eax, 0
	mov al ,nubomba
	push eax
	push offset format1
	call printf
	add esp,8
	
	cmp nubomba, 0
	jne skip1
    inc win
skip1:
	popa

	
button_fail:
    jmp afisare_litere

evt_timer:
     cmp win, 0
	 je skip3
	 castig
skip3:
     cmp joaca, 1
	 je skip4
	 pierd
skip4:

	inc counter
	
afisare_canvas:
     
	 
afisare_litere:
	
	;scriem un mesaj
	make_text_macro 'P', area, 420, 15
	make_text_macro 'A', area, 430, 15
	make_text_macro 'S', area, 440, 15
	make_text_macro 'C', area, 450, 15
	make_text_macro 'A', area, 460, 15
	make_text_macro 'N', area, 470, 15
	
	make_text_macro 'D', area, 490, 15
	make_text_macro 'A', area, 500, 15
	make_text_macro 'N', area, 510, 15
	make_text_macro 'I', area, 520, 15
	make_text_macro 'E', area, 530, 15
	make_text_macro 'L', area, 540, 15
	make_text_macro 'A', area, 550, 15
	
	line_horizontal 40,40,area_width-80,00000
	line_horizontal 40,80,area_width-80,00000
	line_horizontal 40,120,area_width-80,00000
	line_horizontal 40,160,area_width-80,00000
	line_horizontal 40,200,area_width-80,00000
	line_horizontal 40,240,area_width-80,00000
	line_horizontal 40,280,area_width-80,00000
	line_horizontal 40,320,area_width-80,00000
	line_horizontal 40,360,area_width-80,00000
	line_horizontal 40,400,area_width-80,00000
	line_horizontal 40,440,area_width-80,00000

	line_vertical 40,40,area_height-80,00000
	line_vertical 80,40,area_height-80,00000
	line_vertical 120,40,area_height-80,00000
	line_vertical 160,40,area_height-80,00000
	line_vertical 200,40,area_height-80,00000
	line_vertical 240,40,area_height-80,00000
	line_vertical 280,40,area_height-80,00000
	line_vertical 320,40,area_height-80,00000
	line_vertical 360,40,area_height-80,00000
	line_vertical 400,40,area_height-80,00000
	line_vertical 440,40,area_height-80,00000
	line_vertical 480,40,area_height-80,00000
	line_vertical 520,40,area_height-80,00000
	line_vertical 560,40,area_height-80,00000
	line_vertical 600,40,area_height-80,00000
	
  
    


final_draw:
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

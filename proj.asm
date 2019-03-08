org 100h
jmp start
seconds: dw 0
minutes: dw 0
hours: dw 0
count: dw 0
flag: dw 0
oldkb: dd 0
Mbutton: db 0
Hbutton: db 0
Sbutton: db 0
tmp: db 0

printnum: push bp
 mov bp, sp
 push es
 push ax
 push bx
 push cx
 push dx
 push di
 mov ax, 0xb800
 mov es, ax ; point es to video base
 mov ax, [bp+4] ; load number in ax
 mov bx, 10 ; use base 10 for division
 mov cx, 0 ; initialize count of digits
nextdigit: mov dx, 0 ; zero upper half of dividend
 div bx ; divide by 10
 add dl, 0x30 ; convert digit into ascii value
 push dx ; save ascii value on stack
 inc cx ; increment count of values
 cmp ax, 0 ; is the quotient zero
 jnz nextdigit ; if no divide it again
 mov di, [bp+6] ; point di to top left column 
 nextpos: pop dx ; remove a digit from the stack
 mov dh, 0x07 ; use normal attribute
 mov [es:di], dx ; print char on screen
 add di, 2 ; move to next screen location
 loop nextpos ; repeat for all digits on stack
 pop di
 pop dx
 pop cx
 pop bx
 pop ax
 pop es
 pop bp
 ret 4

getNum:
cmp al,0x02
jne nc1
mov dl,1
nc1:
cmp al,0x03
jne nc2
mov dl,2
nc2:
cmp al,0x04
jne nc3
mov dl,3
nc3:
cmp al,0x05
jne nc4
mov dl,4
nc4:
cmp al,0x06
jne nc5
mov dl,5
nc5:
cmp al,0x07
jne nc6
mov dl,6
nc6:
cmp al,0x08
jne nc7
mov dl,7
nc7:
cmp al,0x09
jne nc8
mov dl,8
nc8:
cmp al,0x0a
jne nc9
mov dl,9
nc9:
cmp al,0x0b
jne nc10
mov dl,0
nc10:
ret

kbisr: 
 push ax
 push bx
 push dx
 push cx
 cmp byte[cs:Mbutton],2
 jae takeInputM
 cmp byte[cs:Hbutton],2
 jb s_next
 jmp takeInputH
 s_next:
 cmp byte[cs:Sbutton],2
 jb h_next
 jmp takeInputS
 h_next:
 in al,0x60
 ;ignore the release of M
 cmp al,0x80
 jb skki
 jmp exit
 skki:
 ;;
 
 cmp al,0x32
 jne putZeroNexitM
 inc byte[cs:Mbutton]
 jmp exit
 putZeroNexitM:
 mov byte[cs:Mbutton],0
 cmp al,0x23
 jne putZeroNexitH
 inc byte[cs:Hbutton]
 jmp exit
 putZeroNexitH:
 mov byte[cs:Hbutton],0
 cmp al,0x1f
 jne putZeroNexitS
 inc byte[cs:Sbutton]
 jmp exit
 putZeroNexitS:
 mov byte[cs:Sbutton],0
 jmp exit
 
 takeInputM:
 
 cmp byte[cs:Mbutton],2
 jne skip
 mov ax,0xb800
 mov es,ax
 mov word[es:6],0
 mov word[es:8],0
 skip:

 in al,0x60
 
 cmp al,0x02
 jae nxt
 jmp putZeroNexitM
 nxt:
 cmp al,0x0b
 ja ndone
 jmp done
 ndone:
;release buttons
cmp al,0x80
 jb nexit1
 jmp exit
 nexit1:
 jmp putZeroNexitM
 
 done:
 cmp byte[cs:Mbutton],3
 je nextd
 call getNum ;expects scancode in al and returns number in dl
 mov bh,0
 mov bl,dl
 push 6
 push bx
 call printnum
 mov [cs:tmp],bl
 inc byte[cs:Mbutton]
 jmp exit
 nextd:
 call getNum ;expects scancode in al and returns number in dl
 mov dh,0
 push 8
 push dx
 call printnum
 mov ax,0
 mov al,10
 mul byte[cs:tmp]
 add al,dl
 mov ah,0
 cmp ax,60
 jae mskip
 mov [cs:minutes],ax
 jmp mmskip
 mskip:
 mov word[cs:minutes],0
 mov ax,0xb800
 mov es,ax
 mov word[es:6],0x0730
 mov word[es:8],0x0730
 mmskip:
 mov byte[cs:Mbutton],0
 jmp exit
 
 takeInputH:
 
 cmp byte[cs:Hbutton],2
 jne skipH
 mov ax,0xb800
 mov es,ax
 mov word[es:0],0
 mov word[es:2],0
 skipH:

 in al,0x60
 
 cmp al,0x02
 jae nxtH
 jmp putZeroNexitH
 nxtH:
 cmp al,0x0b
 jbe doneH
;release buttons
cmp al,0x80
 jb nexit
jmp exit
 nexit:
 jmp putZeroNexitH
 
 doneH:
 cmp byte[cs:Hbutton],3
 je nextdH
 call getNum ;expects scancode in al and returns number in dl
 mov bh,0
 mov bl,dl
 push 0
 push bx
 call printnum
 mov [cs:tmp],bl
 inc byte[cs:Hbutton]
 jmp exit
 nextdH:
 call getNum ;expects scancode in al and returns number in dl
 mov dh,0
 push 2
 push dx
 call printnum
 mov ax,0
 mov al,10
 mul byte[cs:tmp]
 add al,dl
 mov ah,0
 cmp ax,24
 jae hskip
 mov [cs:hours],ax
 jmp hhskip
 hskip:
 mov word[cs:hours],0
 mov ax,0xb800
 mov es,ax
 mov word[es:0],0x0730
 mov word[es:2],0x0730
 hhskip:
 mov byte[cs:Hbutton],0
 
 jmp exit
 
 
 takeInputS:
 
 cmp byte[cs:Sbutton],2
 jne skipS
 mov ax,0xb800
 mov es,ax
 mov word[es:12],0
 mov word[es:14],0
 skipS:

 in al,0x60
 
 cmp al,0x02
 jae nxtS
 jmp putZeroNexitS
 nxtS:
 cmp al,0x0b
 jbe doneS
;release buttons
cmp al,0x80
 ja exit

 jmp putZeroNexitS
 
 doneS:
 cmp byte[cs:Sbutton],3
 je nextdS
 call getNum ;expects scancode in al and returns number in dl
 mov bh,0
 mov bl,dl
 push 12
 push bx
 call printnum
 mov [cs:tmp],bl
 inc byte[cs:Sbutton]
 jmp exit
 nextdS:
 call getNum ;expects scancode in al and returns number in dl
 mov dh,0
 push 14
 push dx
 call printnum
 mov ax,0
 mov al,10
 mul byte[cs:tmp]
 add al,dl
 mov ah,0
 cmp ax,60
 jae sskip
 mov [cs:seconds],ax
 jmp ssskip
 sskip:
 mov word[cs:seconds],0
 ssskip:
 mov byte[cs:Sbutton],0
 jmp exit

 exit:
 pop cx
 pop dx
 pop bx
 pop ax
 jmp far [cs:oldkb]

timer:
push ax 
mov ax,0xb800
mov es,ax
cmp word[cs:flag],0xffff
je skip0
mov word [es:4],0x073a
mov word [es:10],0x073a
mov word [es:0],0x0730
mov word [es:2],0x0730
mov word [es:6],0x0730
mov word [es:8],0x0730
mov word [es:12],0x0730
mov word [es:14],0x0730
mov word[cs:flag],0xffff
skip0:
 inc word [cs:count]
 cmp word [cs:count],18
 je skipx
 jmp skipp
 skipx:
 mov word [cs:count],0
 inc word [cs:seconds]
 cmp word [cs:seconds],60
 je checkNext
 cmp word [cs:seconds],10
 jb c1
push 12
jmp c11
 c1:
 mov word[es:12],0x0730
 push 14
 c11:
 push word [cs:seconds]
 call printnum
 jmp skipp
checkNext:
mov word[es:12],0x0730
mov word[es:14],0x0730
mov word [cs:seconds],0
 inc word [cs:minutes]
 cmp word [cs:minutes],60
 je checkNext2
cmp word [cs:minutes],10
 jb c2
push 6
jmp c22
 c2:
 mov word[es:6],0x0730
 push 8
 c22:
 push word [cs:minutes]
 call printnum
 jmp skipp
checkNext2:
mov word[es:6],0x0730
mov word[es:8],0x0730
mov word [cs:minutes],0
 inc word [cs:hours]
 cmp word [cs:hours],10
 jb c3
push 0
jmp c33
 c3:
 mov word[es:0],0x0730
 push 2
 c33:
 push word [cs:hours]
 call printnum
cmp word [cs:hours],24
jne skipp
mov word[cs:seconds],0
mov word[cs:minutes],0
mov word[cs:hours],0
 skipp:
 mov al, 0x20
out 0x20, al ; send EOI to PIC
pop ax
iret

 start:
xor ax, ax
 mov es, ax ; point es to IVT base
 mov ax, [es:9*4]
 mov [oldkb], ax ; save offset of old routine
 mov ax, [es:9*4+2]
 mov [oldkb+2], ax ; save segment of old routine
 cli ; disable interrupts
 mov word [es:9*4], kbisr ; store offset at n*4
 mov [es:9*4+2], cs ; store segment at n*4+2
 mov word [es:8*4], timer ; store offset at n*4
 mov word[es:8*4+2], cs ; store segment at n*4+
 sti ; enable interrupts
 mov dx, start ; end of resident portion
 add dx, 15 ; round up to next para
 mov cl, 4
 shr dx, cl ; number of paras
 mov ax, 0x3100 ; terminate and stay resident
 int 0x21 

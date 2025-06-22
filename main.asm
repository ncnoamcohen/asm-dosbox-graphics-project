IDEAL
p286
MODEL small
STACK 100h
;constants:
PKEY equ 25
HKEY equ 35

LEFTKEY equ 75
RIGHTKEY equ 77
DOWNKEY equ 80
UPKEY equ 72

DATASEG
;BMP handling variables:
filename db ?
filehandle dw ?
Header db 54 dup (0)
Palette db 256*4 dup (0)
ScrLine db 320 dup (0)
ErrorMsg db 'Error', 13, 10,'$'

height		dw	(?)					;height of picture
wid			dw	(?)					;width of picture
left		dw	(?)					;add from left side = X
top			dw	(?)					;add from top side  = Y

lines dw (?) ;current lines of the plane from the top

currentTop dw (?)
currentLeft dw (?)

;screens:
helpSFN db 'helpscn5.bmp', 0
gameSCN	db 'gamescn.bmp', 0
mainSCN	db 'sbwp5.bmp', 0
gameOverSCN db 'gameOver.bmp', 0

;objects:
planeSML db 'planepic.bmp', 0
planeLeft db (?)
planeTop db (?)

cloud db 'cloud2.bmp', 0
cloudLeft dw 0 ;Left is randomized
cloudTop dw 0 ;Top is randomized

score db 0
currentScore dw (?)
;-------------
;Font: Arial Rounded MT Bold
score0 db 'score0.bmp', 0
score1 db 'score1.bmp', 0
score2 db 'score2.bmp', 0
score3 db 'score3.bmp', 0
score4 db 'score4.bmp', 0
score5 db 'score5.bmp', 0
score6 db 'score6.bmp', 0
score7 db 'score7.bmp', 0
score8 db 'score8.bmp', 0
score9 db 'score9.bmp', 0
;-------------
scoreLeft dw 0
scoreTop dw 51200

CODESEG
proc graphy
	;enter- none
	;exit - move to graphic mode
	mov ax, 13h
	int 10h
	ret
endp graphy

proc home
	;enter- homeS(byte),calls BMP
	;exit - print the home screen and moves to next screen according to keyboard data
	; print home screen:
	
	mov dx,offset mainSCN
	mov [height], 200
	mov [wid], 320
	mov [left],0
	mov [top],0
	call BMP
	ret
endp home

;randomize the variable [cloudLeft]:
proc randomCloudL
	pusha
	mov ah,2Ch 
	int 21h	 ;take miliseconds from clock range
	mov ah,0 ;clearing ah before divison
    mov al, dl ;miliseconds
	xor dx, dx ;set to zero
    mov cl, 5
    div cl  ;divide by cx
	mov ch, ah ;store the result of the divison (not the remainder) in cl
	mov cl, 0
	mov [cloudLeft], cx
	popa
	ret
endp randomCloudL

;randomize the variable [cloudTop]:
proc randomCloudT
	pusha
	
	mov ax, 320
	
	mov ah,2Ch 
	int 21h	 ;take miliseconds from clock range
	mov ah,0 ;clearing ah before divison
    mov al, dl ;miliseconds
	xor dx, dx ;set to zero
    mov cl, 5
    div cl  ;divide by cx
	mov ch, ah ;store the result of the divison (not the remainder) in cl
	mov cl, 0
	
	mul cx
	mov [cloudTop], ax
	
	popa
	ret
endp randomCloudT

proc OpenFile
	;enter- filehandle(word), offset ErrorMsg(byte)
	;exit - open file and if didn’t succeed print errormsg  and exit
	; NOTE: dx=offset of name of file. is set before the call to this proc
	mov ah,3Dh
	mov al,2					;reading and writing
	int 21h
	jc openError
	mov [filehandle],ax
	ret
openError:
	;if not succeed open- print error and exit
	mov dx,offset ErrorMsg
	mov ah,9h
	int 21h
	;print which kind of error
	mov dl,al					;move the error code to dl to print it
	add dl,'0'					;turn the error code to a number
	mov ah,2					;print
	int 21h
	jmp far exit
	ret
endp OpenFile

proc CloseFile
	;enter- filehandle(size word)
	;exit - Close file
	mov ah,3Eh
	mov bx,[filehandle]
	int 21h
	ret
endp CloseFile

proc ReadHeader
	; Read BMP file header, 54 bytes
    mov ah,3fh
    mov bx,[filehandle]
    mov cx,54
    mov dx,offset Header
    int 21h
	ret
endp ReadHeader

proc ReadPalette
	; Read BMP file color palette, 256 colors * 4 bytes (400h)
    mov ah,3fh
    mov cx,400h
    mov dx,offset Palette
    int 21h
endp ReadPalette

proc CopyPal
	; Copy the colors palette to the video memory registers
	; The number of the first color should be sent to port 3C8h
	; The palette is sent to port 3C9h
	mov si,offset Palette
	mov cx,256
	mov dx,3C8h
	mov al,0
	; Copy starting color to port 3C8h
	out dx,al
	; Copy palette itself to port 3C9h
	inc dx
	ret
endp CopyPal

proc PalLoop
	;Note: Colors in a BMP file are saved as BGR values rather than RGB.
	mov al,[si+2] 			; Get red value.
	shr al,2 				; Max. is 255, but video palette maximal value is 63. Therefore dividing by 4.
	out dx,al				; Send it.
	mov al,[si+1] 			; Get green value.
	shr al,2
	out dx,al 				; Send it.
	mov al,[si] 			; Get blue value.
	shr al,2
	out dx,al 				; Send it.
	add si,4		 		; Point to next color.
	; (There is a null chr. after every color.)
	loop PalLoop
	ret
endp PalLoop

proc CopyBitmap
	; BMP graphics are saved upside-down.
	; Read the graphic line by line (200 lines in VGA format),
	; displaying the lines from bottom to top.
	mov ax, 0A000h
	mov es, ax
	mov cx,[height]			;height of picture (until 200)
	ret
endp CopyBitmap

proc PrintBMPLoop
	;Print the BMP image.
	push cx
	; di = cx*320, point to the correct screen line
	mov di,cx
	shl cx,6
	shl di,8
	add di,cx

	add di,[left]			;add from left side
	add di,[top]			;add from top side
	; Read one line
	mov ah,3fh
	mov cx,[wid]			;width of picture (until 320)
	mov dx,offset ScrLine
	int 21h
	; Copy one line into video memory
	cld 					; Clear direction flag, for movsb
	mov cx,[wid]
	mov si,offset ScrLine
	rep movsb 				; Copy line to the screen
	pop cx
	loop PrintBMPLoop
	ret
endp PrintBMPLoop

proc BMP
	;enter- calls openfile, errorCode(byte), filehandle(word), Header,Palette,ScrLine (byte), height,wid,left,top(size word), calls closefile
	;exit - print BMP file
	; open file:
	pusha
	call OpenFile
	
	call ReadHeader
	call ReadPalette
	call CopyPal
	call PalLoop
	call CopyBitmap
	call PrintBMPLoop
	
	call closefile
	popa
	ret
endp BMP

proc PrintBMPCloud
	;Print the Cloud image.
redo:
	push cx
	; di = cx*320, point to the correct screen line
	mov di,cx
	shl cx,6
	shl di,8
	add di,cx

	randLeft:
		;Randomize cloudleft:
		mov ah,2Ch 
		int 21h	 ;take miliseconds from clock range
		mov ah,0 ;clearing ah before divison
		mov al, dl ;miliseconds
		xor dx, dx ;set to zero
		mov cl, 4
		div cl  ;divide by cx
		mov ch, ah ;store the result of the divison (not the remainder) in cl
		mov cl, 0
		;make ax an even number, because the plane moves only in even co-ords:
		shr ax, 1
		shl ax, 1
		;move the value to cloudLeft:
		mov [cloudLeft], cx
		; ;check if cloudLeft is bigger than 280:
		; cmp [cloudLeft], 280
		; ja randLeft ;get a new valid value
	randTop:
		;Randomize cloudTop:
		mov ah,2Ch 
		int 21h	 ;take miliseconds from clock range
		mov ah, 0 ;clearing ah before divison
		mov al, dl ;miliseconds
		xor dx, dx ;set to zero
		mov cl, 5
		div cl  ;divide by cx
		
		mov ah, 0
		mov bx, 640
		mul bx
		;^ values stores in ax currently ^
		;move the value to cloudTop:
		mov [cloudTop], ax
		add [cloudTop], ax
		add [cloudTop], ax
		add [cloudTop], ax
	
	; passed:
	add di,[cloudLeft]			;add from left side
	add di,[cloudTop]			;add from top side
	; Read one line
	mov ah,3fh
	mov cx,[wid]			;width of picture (up to 320)
	mov dx,offset ScrLine
	int 21h
	; Copy one line into video memory
	cld 					; Clear direction flag, for movsb
	mov cx,[wid]
	mov si,offset ScrLine
	rep movsb 				; Copy line to the screen
	pop cx
	;loop:
	dec cx
	cmp cx, 0
	je done
	jmp redo
	done:
	ret
endp PrintBMPCloud

proc PrintBMPCloudNR
	;Print the cloud BMP without randomizing the location values.
	push cx
	; di = cx*320, point to the correct screen line
	mov di,cx
	shl cx,6
	shl di,8
	add di,cx
	add di,[cloudLeft]			;add from left side
	add di,[cloudTop]			;add from top side
	; Read one line
	mov ah,3fh
	mov cx,[wid]			;width of picture (up to 320)
	mov dx,offset ScrLine
	int 21h
	; Copy one line into video memory
	cld 					; Clear direction flag, for movsb
	mov cx,[wid]
	mov si,offset ScrLine
	rep movsb 				; Copy line to the screen
	pop cx
	loop PrintBMPCloudNR
	ret
endp PrintBMPCloudNR

proc BMPcloud
	;enter- calls openfile, errorCode(byte), filehandle(word), Header,Palette,ScrLine (byte), height,wid,left,top(size word), calls closefile
	;exit - print BMP file
	; open file:
	mov dx, offset cloud
	call OpenFile
	
	call ReadHeader
	call ReadPalette
	call CopyPal
	call PalLoop
	call CopyBitmap	
	call PrintBMPCloud
	
	call closefile
	ret
endp BMPcloud

proc BMPcloudNR
	;Call the procs that print the cloud BMP image (without randomizing the location values).
	;BMPcloud --> NO RANDOM:
	;enter- calls openfile, errorCode(byte), filehandle(word), Header,Palette,ScrLine (byte), height,wid,left,top(size word), calls closefile
	;exit - print BMP file
	; open file:
	mov dx, offset cloud
	call OpenFile
	call ReadHeader
	call ReadPalette
	call CopyPal
	call PalLoop
	call CopyBitmap
	call PrintBMPCloudNR ;--> NOT RANDOM, BASED ON THE PREVIOUS LOCATION
	call closefile
	ret
endp BMPcloudNR

proc helpScreen
	;Print the helpScreen.
	pusha
	mov dx, offset helpSFN
	mov [height], 200
	mov [wid], 320
	mov [left],0
	mov [top],0
	call BMP
	popa
	ret
endp helpScreen

proc printGS
	;Print the GameScreen.
	pusha
	mov dx,offset gameSCN
	mov [height], 200
	mov [wid], 320
	mov [left],0
	mov [top],0
	call BMP
	popa
	ret
endp printGS

proc printGameOver
	;Print the GameOverScreen.
	pusha
	mov dx,offset gameOverSCN
	mov [height], 200
	mov [wid], 320
	mov [left],0
	mov [top],0
	call BMP
	popa
	ret
endp printGameOver

proc gameOver
	;Print the gameOverScreen and add a delay until pressing buttons is once again available.
	pusha
	call printGameOver
	delay:
		mov dx, 0ffffh
		li:
		mov bx, 0001fh
		li2:
			dec bx
			jnz li2
		dec dx
		jnz li
	popa
	; Clear keyboard buffer
	mov ah,0ch
	mov al,07h
	int 21h
	jmp start
endp gameOver

proc gameScreen
	;The whole game happens here.
	;reset score:
	mov [score], 0
	;Render the start-up objects here:
	mov dx,offset gameSCN
	mov [height], 200
	mov [wid], 320
	mov [left],0
	mov [top],0
	call BMP
	
	mov dx, offset score0
	mov [currentScore], dx ;will be used to print the current score
	mov [height], 40
	mov [wid], 40
	mov [left], 280
	mov [top], 51200
	call BMP
	
	mov dx,offset planeSML
	mov [height], 40
	mov [wid], 40
	mov [left], 140
	mov [top], 51200 ;160 lines. 320*[lines from the top], times 320 because the top essentialy just forwards the print by pixels to the right, just like the top
	mov [lines], 160
	call BMP
	
	;Print cloud:
	call BMPcloud
	
	;Start if he doesnt regret his action
startGame:
	repeatMoving:
	mov dx, [currentScore]
	mov ax, [left]
	mov bx, [top]
	mov [left], 280
	mov [top], 51200
	call BMP
	mov [left], ax
	mov [top], bx
	
	;Print cloud again, so it won't get "deleted" by the plane by a few pixels each time:
	call BMPcloudNR
	;Print plane again, to be in front the cloud:
	mov dx, offset planeSML
	call BMP
	;Clear keyboard buffer (Needed!)
		mov ah,0ch
		mov al,07h
		int 21h
	
	;Read SCAN code from keyboard port
		in al,060h
		
		cmp al, RIGHTKEY
		je rPressed
		cmp al, LEFTKEY
		je lPressed
		cmp al, UPKEY
		je uPressed
		cmp al, DOWNKEY
		je dPressed
		
		cmp al, HKEY
		jne finished
		jmp start
		
		;If non of the above were pressed:
		jmp finished
		
	rPressed:
		cmp [left], 280
		jae finished
		add [left], 2
		jmp finished
	lPressed:
		cmp [left], 0
		jle finished
		sub [left], 2
		jmp finished
	uPressed:
		cmp [lines], 0
		jle finished
		sub [top], 640
		sub [lines], 2
		jmp finished
	dPressed:
		cmp [lines], 160
		jae finished
		add [top], 640
		add [lines], 2
		
		
	finished:
	;Print plane again:
		mov dx, offset planeSML
		call BMP
		
		;check if the plane "caught" the cloud
		mov dx, [cloudLeft]
		add dx, [cloudTop]
		
		mov bx, [left]
		add bx, [top]
	
		;now, check if the plane is in range for the re-locate ("touching")
		cmp bx, dx
		jne false1
		je true
	false1:
		add dx, 320
		cmp bx, dx
		jne false2
		je true
	false2:
		sub dx, 640
		cmp bx, dx
		je true
		jmp false
	true:
		inc [score]
		mov ah, [score]
		cmp ah, 1
		je scoreIs1
		cmp ah, 2
		je scoreIs2
		cmp ah, 3
		je scoreIs3
		cmp ah, 4
		je scoreIs4
		cmp ah, 5
		je scoreIs5
		cmp ah, 6
		je scoreIs6
		cmp ah, 7
		je scoreIs7
		cmp ah, 8
		je scoreIs8
		cmp ah, 9
		je scoreIs9
		cmp ah, 10 ;check for the score, if it's "certain value", then "call gameOver":
		jne next
		call gameOver
		
		scoreIs1:
			mov [currentScore], offset score1
			jmp next
		scoreIs2:
			mov [currentScore], offset score2
			jmp next
		scoreIs3:
			mov [currentScore], offset score3
			jmp next
		scoreIs4:
			mov [currentScore], offset score4
			jmp next
		scoreIs5:
			mov [currentScore], offset score5
			jmp next
		scoreIs6:
			mov [currentScore], offset score6
			jmp next
		scoreIs7:
			mov [currentScore], offset score7
			jmp next
		scoreIs8:
			mov [currentScore], offset score8
			jmp next
		scoreIs9:
			mov [currentScore], offset score9
			jmp next
			
		;re-print the gameSCN, to make remaining cloud pieces disappear just in case they didn't already:
		;save co-ords and size of the plane
		next:
		mov ax, [top]
		mov bx, [left]
		mov cx, [wid]
		mov dx, [height]
		;print gameSCN
		call printGS
		;re-enter the plane co-ords:
		mov [top], ax
		mov [left], bx
		mov [wid], cx
		mov [height], dx
		
		;print the new cloud:
		call BMPcloud
	false:
	;Add a condition here in order to stop, if needed
	jmp repeatMoving
	
	ret
	popa
endp gameScreen
;=======================================
start:
	mov ax, @data
	mov ds, ax
	
	call graphy
	call home
; Wait for key press
	mov ah, 1
	int 21h

;Read SCAN code from keyboard port
	in al,060h
    push ax

;Checking the pressed key
	cmp al, PKEY
	je Ppressed
	
	cmp al, HKEY
	je Hpressed

	cmp al, RIGHTKEY
	je Ppressed
	cmp al, LEFTKEY
	je Ppressed
	cmp al, UPKEY
	je Ppressed
	cmp al, DOWNKEY
	je Ppressed
	
	jmp exit
	
Hpressed:
	call helpScreen
	jmp continue
	
Ppressed:
	call gameScreen

continue:
	pop ax
	
; Wait for key press
	mov ah,1
	int 21h
;Read SCAN code from keyboard port, needed so we can go back to the home page or straight into the game:
	in al,060h
    push ax
	
;Checking the pressed key
	;start the game screen;
	cmp al, PKEY
	je Ppressed
	
	pop ax
	
	;else- go back to home anyway
	jne start
	
	jmp exit
	
exit:
;Clear the screen (video mode)
	mov ax, 13h
	int 10h
;Back to text mode (exit the program right after)
	mov ah, 0
	mov al, 2
	int 10h
	
mov ax, 4c00h
int 21h
END start
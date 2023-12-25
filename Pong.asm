STACK SEGMENT PARA STACK
	DB 64 DUP (' ')
STACK ENDS

DATA SEGMENT PARA 'DATA'
	
	BALL_X DW 0Ah    ;X position (column) of the ball
	BALL_Y DW 0Ah    ;Y position (line) of the ball
	BALL_SIZE DW 04h ;size of the ball (how many pixels does the ball have in width and height)
	
DATA ENDS

CODE SEGMENT PARA 'CODE'
	
	MAIN PROC FAR
	ASSUME CS:CODE,DS:DATA,SS:STACK ;assume as code, data and stack segments the respective registers
	PUSH DS                         ;push to the stack the DS segment
	SUB AX,AX                       ;clean the AX register
	PUSH AX                         ;push AX to the stack
	MOV AX,DATA                     ;save on the AX register the contents of the DATA segment
	MOV DS,AX                       ;save on the DS segment the contets of AX
	POP AX                          ;release the top item from the stack to the AX register
	POP AX                          ;release the top item from the stack to the AX register
	
		MOV AH,00h ;set the configuration to video mode
		MOV AL,13h ;choose the video mode
		INT 10h    ;execute the configuration EXAMPLEFORALLINSTANCES-------
		
		MOV AH,0Bh ;set the configuration
		MOV BH,00h ;to the background color
		MOV BL,00h ;choose green as background color
		INT 10h
		
		;SETTING ALL PIXELS TO GREEN FOR GREEN BACKGROUND
		MOV AX, 0A000h  ; Set segment to video memory
		MOV ES, AX
		XOR DI, DI      ; Start at the beginning of video memory

		MOV CX, 320*200 ; Total number of pixels in mode 13h
		MOV AL, 2       ; Color index for green
		REP STOSB       ; Set each pixel to green
		;--------------------------------------------------------
		
		CALL DRAW_BALL
		
		RET
	MAIN ENDP
	
	DRAW_BALL PROC NEAR
	    
		MOV CX,BALL_X ;set the initial column (X)
		MOV DX,BALL_Y ;set the initial line (Y)
		
		DRAW_BALL_HORIZONTAL:
			MOV AH,0Ch    ;set the configuration to writing a pixel
			MOV AL,0Dh    ;choose pink as color
			MOV BH,00h 	  ;set the page number
			INT 10h
			
			INC CX        ;CX = CX + 1
			MOV AX,CX     ;CX - BALL_X > BALL_SIZE (Y -> we go to the next line, N -> we continue to the next column)
			SUB AX,BALL_X
			CMP AX,BALL_SIZE
			JNG DRAW_BALL_HORIZONTAL
			
			MOV CX,BALL_X ;the CX register goes back to the initial column
			INC DX        ;we advance one line
			MOV AX,DX     ;DX - BALL_Y > BALL_SIZE (Y -> we exit this procedure, N -> we continue to the next line)
			SUB AX,BALL_Y
			CMP AX,BALL_SIZE
			JNG DRAW_BALL_HORIZONTAL
		
		RET
	DRAW_BALL  ENDP
	
CODE ENDS
END
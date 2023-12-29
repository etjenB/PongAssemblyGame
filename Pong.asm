STACK SEGMENT PARA STACK
	DB 64 DUP (' ')
STACK ENDS

DATA SEGMENT PARA 'DATA'

	WINDOW_WIDTH DW 140h                        ;the width of the window (320 pixels)
	WINDOW_HEIGHT DW 0C8h                       ;the height of the window (200 pixels)
	WINDOW_BOUNDS DW 6	                        ;variable used to check collisions early

	TIME_AUX DB 0    	                        ;variable used when checking if the time has changed
	
	GAME_ACTIVE DB 1							;is the game active? (1 -> YES, 0 -> No (game over))
	
	WINNER_INDEX DB 0							;the index of the winner (1 -> player one, 2 -> player two)
	
	CURRENT_SCENE DB 1							;the index of the current scene (0 -> main menu, 1 -> game)
	
	TEXT_PLAYER_ONE_POINTS DB '0','$'			;text with the player one points
	TEXT_PLAYER_TWO_POINTS DB '0','$'			;text with the player two points
	TEXT_GAME_OVER_TITLE DB 'GAME OVER','$'		;game over menu title
	TEXT_GAME_OVER_WINNER DB 'Player 0 won','$'	;text with the winner text
	TEXT_GAME_OVER_PLAY_AGAIN DB 'Press R to play again','$' ;text with the game over play again message
	TEXT_GAME_OVER_MAIN_MENU DB 'Press E to exit to main menu','$' ;text with the game over main menu message
	TEXT_MAIN_MENU_TITLE DB 'MAIN MENU','$'		;text with the main menu title
	TEXT_MAIN_MENU_SINGLEPLAYER DB 'SINGLEPLAYER - S KEY','$' ;text with the singleplayer message
	TEXT_MAIN_MENU_MULTIPLAYER DB 'MULTIPLAYER - M KEY','$' ;text with the multiplayer message
	TEXT_MAIN_MENU_EXIT DB 'EXIT GAME - E KEY','$' ;text with the exit game message
	
	BALL_ORIGINAL_X DW 96h				   	    ;X position of the ball on the beggining of the game
	BALL_ORIGINAL_Y DW 5Ah                      ;Y position of the ball on the beggining of the game
	BALL_X DW 96h   	                        ;X position (column) of the ball
	BALL_Y DW 5Ah   	                        ;Y position (line) of the ball
	BALL_SIZE DW 04h 	                        ;size of the ball (how many pixels does the ball have in width and height)
	BALL_VELOCITY_X DW 05h                      ;X (horizontal) velocity of the ball
	BALL_VELOCITY_Y DW 02h                      ;Y (vertical) velocity of the ball
	
	PADDLE_LEFT_X DW 0Ah                        ;current X position of the left paddle
	PADDLE_LEFT_Y DW 0Ah                        ;current Y position of the left paddle
	PLAYER_ONE_POINTS DB 0						;current points of the left player (player one)
	
	PADDLE_RIGHT_X DW 130h                      ;current X position of the right paddle
	PADDLE_RIGHT_Y DW 0Ah                       ;current Y position of the right paddle
	PLAYER_TWO_POINTS DB 0						;current points of the right player (player two)
	
	PADDLE_WIDTH DW 05h                         ;default paddle width
	PADDLE_HEIGHT DW 1Fh                        ;default paddle height
	PADDLE_VELOCITY DW 05h                      ;default paddle velocity
	
DATA ENDS

CODE SEGMENT PARA 'CODE'
	
	MAIN PROC FAR
	ASSUME CS:CODE,DS:DATA,SS:STACK 		    ;assume as code, data and stack segments the respective registers
	PUSH DS                         		    ;push to the stack the DS segment
	SUB AX,AX                       		    ;clean the AX register
	PUSH AX                         		    ;push AX to the stack
	MOV AX,DATA                     		    ;save on the AX register the contents of the DATA segment
	MOV DS,AX                       		    ;save on the DS segment the contets of AX
	POP AX                          		    ;release the top item from the stack to the AX register
	POP AX                          		    ;release the top item from the stack to the AX register
	
		CALL CLEAR_SCREEN					    ;set initial video mode configuration
		
		CHECK_TIME:							    ;time checking loop
		
			CMP CURRENT_SCENE,00h
			JE SHOW_MAIN_MENU
		
			CMP GAME_ACTIVE,00h
			JE SHOW_GAME_OVER
			
			MOV AH, 2Ch 					    ;get the system time
			INT 21h     					    ;CH = hour CL = minute DH = second DL = 1/100 seconds
			
			CMP DL,TIME_AUX 				    ;is the current time equal to the previous one(TIME_AUX)?
			JE CHECK_TIME					    ;if it is the same, check again
			
;			If it reaches this point, it's because the time has passed

			MOV TIME_AUX,DL					    ;update time
			
			CALL CLEAR_SCREEN				    ;clear the screen by restarting the video mode
			
			CALL MOVE_BALL					    ;move ball
			
			CALL DRAW_BALL					    ;draw ball
			
			CALL MOVE_PADDLES				    ;move the two paddles (check for pressing keys)
			
			CALL DRAW_PADDLES				    ;draw the two paddles with the updated positions
			
			CALL DRAW_UI						;draw games user interface
			
			JMP CHECK_TIME  				    ;after everything checks time again
			
			SHOW_GAME_OVER:
				CALL DRAW_GAME_OVER_MENU
				JMP CHECK_TIME
				
			SHOW_MAIN_MENU:
				CALL DRAW_MAIN_MENU
				JMP CHECK_TIME
				
			RET
	MAIN ENDP
	
	DRAW_BALL PROC NEAR
	    
		MOV CX,BALL_X 							;set the initial column (X)
		MOV DX,BALL_Y 							;set the initial line (Y)
		
		DRAW_BALL_HORIZONTAL:
			MOV AH,0Ch    						;set the configuration to writing a pixel
			MOV AL,0Dh    						;choose pink as color
			MOV BH,00h 	  						;set the page number
			INT 10h
			
			INC CX        						;CX = CX + 1
			MOV AX,CX     						;CX - BALL_X > BALL_SIZE (Y -> we go to the next line, N -> we continue to the next column)
			SUB AX,BALL_X
			CMP AX,BALL_SIZE
			JNG DRAW_BALL_HORIZONTAL
			
			MOV CX,BALL_X 						;the CX register goes back to the initial column
			INC DX        						;we advance one line
			MOV AX,DX     						;DX - BALL_Y > BALL_SIZE (Y -> we exit this procedure, N -> we continue to the next line)
			SUB AX,BALL_Y
			CMP AX,BALL_SIZE
			JNG DRAW_BALL_HORIZONTAL
		
		RET
	DRAW_BALL  ENDP
	
	DRAW_PADDLES PROC NEAR
	
		MOV CX,PADDLE_LEFT_X 					;set the initial column (X)
		MOV DX,PADDLE_LEFT_Y 					;set the initial line (Y)
		
		DRAW_PADDLE_LEFT_HORIZONTAL:
			MOV AH,0Ch    						;set the configuration to writing a pixel
			MOV AL,0Ch    						;choose red as color
			MOV BH,00h 	  						;set the page number
			INT 10h
			
			INC CX        						;CX = CX + 1
			MOV AX,CX     						;CX - PADDLE_LEFT_X > PADDLE_WIDTH (Y -> we go to the next line, N -> we continue to the next column)
			SUB AX,PADDLE_LEFT_X
			CMP AX,PADDLE_WIDTH
			JNG DRAW_PADDLE_LEFT_HORIZONTAL
			
			MOV CX,PADDLE_LEFT_X 				;the CX register goes back to the initial column
			INC DX       					 	;we advance one line
			MOV AX,DX     						;DX - PADDLE_LEFT_Y > PADDLE_HEIGHT (Y -> we exit this procedure, N -> we continue to the next line)
			SUB AX,PADDLE_LEFT_Y
			CMP AX,PADDLE_HEIGHT
			JNG DRAW_PADDLE_LEFT_HORIZONTAL
		
			
		MOV CX,PADDLE_RIGHT_X 					;set the initial column (X)
		MOV DX,PADDLE_RIGHT_Y 					;set the initial line (Y)
		
		DRAW_PADDLE_RIGHT_HORIZONTAL:
			MOV AH,0Ch    						;set the configuration to writing a pixel
			MOV AL,0Eh    						;choose yellow as color
			MOV BH,00h 	  						;set the page number
			INT 10h
			
			INC CX        						;CX = CX + 1
			MOV AX,CX     						;CX - PADDLE_RIGHT_X > PADDLE_WIDTH (Y -> we go to the next line, N -> we continue to the next column)
			SUB AX,PADDLE_RIGHT_X
			CMP AX,PADDLE_WIDTH
			JNG DRAW_PADDLE_RIGHT_HORIZONTAL
			
			MOV CX,PADDLE_RIGHT_X 				;the CX register goes back to the initial column
			INC DX        						;we advance one line
			MOV AX,DX     						;DX - PADDLE_RIGHT_Y > PADDLE_HEIGHT (Y -> we exit this procedure, N -> we continue to the next line)
			SUB AX,PADDLE_RIGHT_Y
			CMP AX,PADDLE_HEIGHT
			JNG DRAW_PADDLE_RIGHT_HORIZONTAL
	
		RET
	DRAW_PADDLES ENDP
	
	MOVE_BALL PROC NEAR							;proccess the movement of the ball
		
;		Move the ball horizontally
		MOV AX,BALL_VELOCITY_X
		ADD BALL_X,AX
		
;		Check if the ball has passed the left boundarie (BALL_X < 0 + WINDOW_BOUNDS)
;		If it is colliding, restart it's position
		MOV AX,WINDOW_BOUNDS
		CMP BALL_X,AX		     				;BALL_X is compared with the left boundarie of the screen (0 + WINDOW_BOUNDS)
		JL GIVE_POINT_TO_PLAYER_TWO 			;if it's less, give one point to the player two and reset ball position
		
;		Check if the ball has passed the right boundarie (BALL_X > WINDOW_WIDTH - BALL_SIZE - WINDOW_BOUNDS)
;		If it is colliding, restart it's position
		MOV AX,WINDOW_WIDTH		 		
		SUB AX,BALL_SIZE
		SUB AX,WINDOW_BOUNDS
		CMP BALL_X,AX							;BALL_X is compared with the right boundarie of the screen (BALL_X > WINDOW_WIDTH - BALL_SIZE - WINDOW_BOUNDS)
		JG GIVE_POINT_TO_PLAYER_ONE 			;if it's less, give one point to the player one and reset ball position
		JMP MOVE_BALL_VERTICALLY
		
		GIVE_POINT_TO_PLAYER_ONE:				;give one point to the player one and reset ball position
			INC PLAYER_ONE_POINTS				;increment player one points
			CALL RESET_BALL_POSITION			;reset ball position to the center of the screen
			CALL UPDATE_TEXT_PLAYER_ONE_POINTS	;update the text of the player one points
			CMP PLAYER_ONE_POINTS,05h
			JGE GAME_OVER
			RET
			
		GIVE_POINT_TO_PLAYER_TWO:				;give one point to the player two and reset ball position
			INC PLAYER_TWO_POINTS				;increment player two points
			CALL RESET_BALL_POSITION			;reset ball position to the center of the screen
			CALL UPDATE_TEXT_PLAYER_TWO_POINTS	;update the text of the player two points
			CMP PLAYER_TWO_POINTS,05h
			JGE GAME_OVER
			RET
		
		GAME_OVER:								;if someone reach 5 points restart the game
			CMP PLAYER_ONE_POINTS,05h			;check which player has 5 or more points
			JNL WINNER_IS_PLAYER_ONE			;if the player one has not less than 5 points he's the winner
			JMP WINNER_IS_PLAYER_TWO			;if not then player two is the winner
			
			WINNER_IS_PLAYER_ONE:
				MOV WINNER_INDEX,01h			;update the winner index with the player one index
				JMP CONTINUE_GAME_OVER
			WINNER_IS_PLAYER_TWO:
				MOV WINNER_INDEX,02h			;update the winner index with the player two index
				JMP CONTINUE_GAME_OVER
			
			CONTINUE_GAME_OVER:
				MOV PLAYER_ONE_POINTS,00h			;reset player one points to zero
				MOV PLAYER_TWO_POINTS,00h			;reset player two points to zero
				CALL UPDATE_TEXT_PLAYER_ONE_POINTS
				CALL UPDATE_TEXT_PLAYER_TWO_POINTS
				MOV GAME_ACTIVE,00h					;stops the game
				RET
		
		MOVE_BALL_VERTICALLY:
;		Move the ball vertically
			MOV AX,BALL_VELOCITY_Y	
			ADD BALL_Y,AX

;		Check if the ball has passed the top boundarie (BALL_Y < 0 + WINDOW_BOUNDS)
;		If it's colliding, reverse the velocity in Y
		MOV AX,WINDOW_BOUNDS
		CMP BALL_Y,AX 							;BALL_Y is compared with the top boundarie of the screen (0 + WINDOW_BOUNDS)
		JL NEG_VELOCITY_Y						;if it's less reverse the velocity in Y
		
;		Check if the ball has passed the bottom boundarie (BALL_Y > WINDOW_HEIGHT - BALL_SIZE - WINDOW_BOUNDS)
;		If it's colliding, reverse the velocity in Y
		MOV AX,WINDOW_HEIGHT	 
		SUB AX,BALL_SIZE
		SUB AX,WINDOW_BOUNDS
		CMP BALL_Y,AX							;BALL_Y is compared with the bottom boundarie of the screen (BALL_Y > WINDOW_HEIGHT - BALL_SIZE - WINDOW_BOUNDS)
		JG NEG_VELOCITY_Y						;if it's greater reverse the velocity in Y
		
;		Check if the ball is colliding with the right paddle
		;maxx1 > minx2 && minx1 < maxx2 && maxy1 > miny2 && miny1 < maxy2
		;BALL_X + BALL_SIZE > PADDLE_RIGHT_X && BALL_X < PADDLE_RIGHT_X + PADDLE_WIDTH
		; && BALL_Y + BALL_SIZE > PADDLE_RIGHT_Y && BALL_Y < PADDLE_RIGHT_Y + PADDLE_HEIGHT
		MOV AX,BALL_X
		ADD AX,BALL_SIZE
		CMP AX,PADDLE_RIGHT_X
		JNG CHECK_COLLISION_WITH_LEFT_PADDLE	;if there's no collision check for the left paddle collisions
		
		MOV AX,PADDLE_RIGHT_X
		ADD AX,PADDLE_WIDTH
		CMP BALL_X,AX
		JNL CHECK_COLLISION_WITH_LEFT_PADDLE	;if there's no collision check for the left paddle collisions
		
		MOV AX,BALL_Y
		ADD AX,BALL_SIZE
		CMP AX,PADDLE_RIGHT_Y
		JNG CHECK_COLLISION_WITH_LEFT_PADDLE	;if there's no collision check for the left paddle collisions
		
		MOV AX,PADDLE_RIGHT_Y
		ADD AX,PADDLE_HEIGHT
		CMP BALL_Y,AX
		JNL CHECK_COLLISION_WITH_LEFT_PADDLE	;if there's no collision check for the left paddle collisions

;		If it reaches this point, the ball is colliding with the right paddle
		JMP NEG_VELOCITY_X						;reverses the horizontal velocity of the ball
		
;		Check if the ball is colliding with the left paddle
		CHECK_COLLISION_WITH_LEFT_PADDLE:
		;maxx1 > minx2 && minx1 < maxx2 && maxy1 > miny2 && miny1 < maxy2
		;BALL_X + BALL_SIZE > PADDLE_LEFT_X && BALL_X < PADDLE_LEFT_X + PADDLE_WIDTH
		; && BALL_Y + BALL_SIZE > PADDLE_LEFT_Y && BALL_Y < PADDLE_LEFT_Y + PADDLE_HEIGHT
			MOV AX,BALL_X
			ADD AX,BALL_SIZE
			CMP AX,PADDLE_LEFT_X
			JNG EXIT_COLLISION_CHECK			;if there's no collision exit procedure
			
			MOV AX,PADDLE_LEFT_X
			ADD AX,PADDLE_WIDTH
			CMP BALL_X,AX
			JNL EXIT_COLLISION_CHECK			;if there's no collision exit procedure
			
			MOV AX,BALL_Y
			ADD AX,BALL_SIZE
			CMP AX,PADDLE_LEFT_Y
			JNG EXIT_COLLISION_CHECK			;if there's no collision exit procedure
			
			MOV AX,PADDLE_LEFT_Y
			ADD AX,PADDLE_HEIGHT
			CMP BALL_Y,AX
			JNL EXIT_COLLISION_CHECK			;if there's no collision exit procedure

	;		If it reaches this point, the ball is colliding with the left paddle
			JMP NEG_VELOCITY_X					;reverses the horizontal velocity of the ball
			
		NEG_VELOCITY_Y:
			NEG BALL_VELOCITY_Y					;reverse the velocity in Y of the ball (BALL_VELOCITY_Y -= BALL_VELOCITY_Y)
			RET
			
		NEG_VELOCITY_X:
			NEG BALL_VELOCITY_X					;reverse the velocity in X of the ball (BALL_VELOCITY_X -= BALL_VELOCITY_X)
			RET
			
		EXIT_COLLISION_CHECK:
			RET
			
	MOVE_BALL ENDP
	
	MOVE_PADDLES PROC NEAR						;process movement of the paddles
	
;		Left paddle movement
		
		;check if any key is being pressed (if not check the other paddle)
		MOV AH,01h
		INT 16h
		JZ CHECK_RIGHT_PADDLE_MOVEMENT ;ZF = 1, JZ -> jump if zero
		;check which key is being pressed (AL = ASCII character)
		MOV AH,00h
		INT 16h
		;if it is 'w' or 'W' move up
		CMP AL,77h ;w
		JE MOVE_LEFT_PADDLE_UP
		CMP AL,57h ;W
		JE MOVE_LEFT_PADDLE_UP
		;if it is 's' or 'S' move down
		CMP AL,73h ;s
		JE MOVE_LEFT_PADDLE_DOWN
		CMP AL,53h ;S
		JE MOVE_LEFT_PADDLE_DOWN
		JMP CHECK_RIGHT_PADDLE_MOVEMENT
		
		MOVE_LEFT_PADDLE_UP:
			MOV AX,PADDLE_VELOCITY
			SUB PADDLE_LEFT_Y,AX
			
			MOV AX,WINDOW_BOUNDS
			CMP PADDLE_LEFT_Y,AX
			JL FIX_PADDLE_LEFT_TOP_POSITION
			
			JMP CHECK_RIGHT_PADDLE_MOVEMENT
			
			FIX_PADDLE_LEFT_TOP_POSITION:
				MOV AX,WINDOW_BOUNDS
				MOV PADDLE_LEFT_Y,AX
				JMP CHECK_RIGHT_PADDLE_MOVEMENT
		
		MOVE_LEFT_PADDLE_DOWN:
			MOV AX,PADDLE_VELOCITY
			ADD PADDLE_LEFT_Y,AX
			
			MOV AX,WINDOW_HEIGHT
			SUB AX,WINDOW_BOUNDS
			SUB AX,PADDLE_HEIGHT
			CMP PADDLE_LEFT_Y,AX
			JG FIX_PADDLE_LEFT_BOTTOM_POSITION
			
			JMP CHECK_RIGHT_PADDLE_MOVEMENT
			
			FIX_PADDLE_LEFT_BOTTOM_POSITION:
				MOV PADDLE_LEFT_Y,AX
				JMP CHECK_RIGHT_PADDLE_MOVEMENT
		
;		Right paddle movement
		CHECK_RIGHT_PADDLE_MOVEMENT:
			;if it is 'o' or 'O' move up
			CMP AL,6Fh ;o
			JE MOVE_RIGHT_PADDLE_UP
			CMP AL,4Fh ;O
			JE MOVE_RIGHT_PADDLE_UP
			;if it is 'l' or 'L' move down
			CMP AL,6Ch ;l
			JE MOVE_RIGHT_PADDLE_DOWN
			CMP AL,4Ch ;L
			JE MOVE_RIGHT_PADDLE_DOWN
			JMP EXIT_PADDLE_MOVEMENT
			
			MOVE_RIGHT_PADDLE_UP:
				MOV AX,PADDLE_VELOCITY
				SUB PADDLE_RIGHT_Y,AX
				
				MOV AX,WINDOW_BOUNDS
				CMP PADDLE_RIGHT_Y,AX
				JL FIX_PADDLE_RIGHT_TOP_POSITION
				
				JMP EXIT_PADDLE_MOVEMENT
				
				FIX_PADDLE_RIGHT_TOP_POSITION:
					MOV AX,WINDOW_BOUNDS
					MOV PADDLE_RIGHT_Y,AX
					JMP EXIT_PADDLE_MOVEMENT
		
			MOVE_RIGHT_PADDLE_DOWN:
				MOV AX,PADDLE_VELOCITY
				ADD PADDLE_RIGHT_Y,AX
				
				MOV AX,WINDOW_HEIGHT
				SUB AX,WINDOW_BOUNDS
				SUB AX,PADDLE_HEIGHT
				CMP PADDLE_RIGHT_Y,AX
				JG FIX_PADDLE_RIGHT_BOTTOM_POSITION
				
				JMP EXIT_PADDLE_MOVEMENT
				
				FIX_PADDLE_RIGHT_BOTTOM_POSITION:
					MOV PADDLE_RIGHT_Y,AX
					JMP EXIT_PADDLE_MOVEMENT
			
		EXIT_PADDLE_MOVEMENT:
			RET
	
	MOVE_PADDLES ENDP
	
	RESET_BALL_POSITION PROC NEAR				;restart ball position to the original position
	
		MOV AX,BALL_ORIGINAL_X
		MOV BALL_X,AX
		
		MOV AX,BALL_ORIGINAL_Y
		MOV BALL_Y,AX
	
		RET
	RESET_BALL_POSITION ENDP
	
	DRAW_UI PROC NEAR
	
;		Draw the points of the left player (player one)
		MOV AH,02h								;set cursor position
		MOV BH,00h								;set page number
		MOV DH,04h								;set row
		MOV DL,06h								;set column
		INT 10h
		
		MOV AH,09h								;write string to standard output
		LEA DX,TEXT_PLAYER_ONE_POINTS			;give DX a pointer to the string TEXT_PLAYER_ONE_POINTS
		INT 21h									;print the string

;		Draw the points of the right player (player two)
		MOV AH,02h								;set cursor position
		MOV BH,00h								;set page number
		MOV DH,04h								;set row
		MOV DL,21h								;set column
		INT 10h
		
		MOV AH,09h								;write string to standard output
		LEA DX,TEXT_PLAYER_TWO_POINTS			;give DX a pointer to the string TEXT_PLAYER_TWO_POINTS
		INT 21h									;print the string
		
		RET
	DRAW_UI ENDP
	
	UPDATE_TEXT_PLAYER_ONE_POINTS PROC NEAR
	
		XOR AX,AX 								;clear AX register
		MOV AL,PLAYER_ONE_POINTS				;given, for example that P1 -> 2 points => AL,2
		
		;before printing to the screen, we need to convert the decimal value to the ascii code character
		;we can do this by adding 30h (number to ASCII)
		;and by subtracting 30h (ASCII to number)
		ADD AL,30h								;AL,'2'
		MOV [TEXT_PLAYER_ONE_POINTS],AL
	
		RET
	UPDATE_TEXT_PLAYER_ONE_POINTS ENDP
	
	UPDATE_TEXT_PLAYER_TWO_POINTS PROC NEAR
	
		XOR AX,AX 								;clear AX register
		MOV AL,PLAYER_TWO_POINTS				;given, for example that P2 -> 2 points => AL,2
		
		;before printing to the screen, we need to convert the decimal value to the ascii code character
		;we can do this by adding 30h (number to ASCII)
		;and by subtracting 30h (ASCII to number)
		ADD AL,30h								;AL,'2'
		MOV [TEXT_PLAYER_TWO_POINTS],AL
	
		RET
	UPDATE_TEXT_PLAYER_TWO_POINTS ENDP
	
	DRAW_GAME_OVER_MENU PROC NEAR
	
		CALL CLEAR_SCREEN
		
;		Shows the menu title
		MOV AH,02h								;set cursor position
		MOV BH,00h								;set page number
		MOV DH,04h								;set row
		MOV DL,06h								;set column
		INT 10h
		
		MOV AH,09h								;write string to standard output
		LEA DX,TEXT_GAME_OVER_TITLE				;give DX a pointer to the string TEXT_GAME_OVER_TITLE
		INT 21h									;print the string
		
;		Shows the winner
		MOV AH,02h								;set cursor position
		MOV BH,00h								;set page number
		MOV DH,06h								;set row
		MOV DL,06h								;set column
		INT 10h
		
		CALL UPDATE_WINNER_TEXT
		
		MOV AH,09h								;write string to standard output
		LEA DX,TEXT_GAME_OVER_WINNER			;give DX a pointer to the string TEXT_GAME_OVER_WINNER
		INT 21h									;print the string
		
;		Shows the play again message
		MOV AH,02h								;set cursor position
		MOV BH,00h								;set page number
		MOV DH,08h								;set row
		MOV DL,06h								;set column
		INT 10h
		
		MOV AH,09h								;write string to standard output
		LEA DX,TEXT_GAME_OVER_PLAY_AGAIN		;give DX a pointer to the string TEXT_GAME_OVER_PLAY_AGAIN
		INT 21h									;print the string
		
;		Shows the main menu message
		MOV AH,02h								;set cursor position
		MOV BH,00h								;set page number
		MOV DH,0Ah								;set row
		MOV DL,06h								;set column
		INT 10h
		
		MOV AH,09h								;write string to standard output
		LEA DX,TEXT_GAME_OVER_MAIN_MENU			;give DX a pointer to the string TEXT_GAME_OVER_MAIN_MENU
		INT 21h									;print the string
		
;       Waits for a key press
		MOV AH,00h
		INT 16h
		
;		If the key is either 'R' or 'r', restart the game
		CMP AL,'R'
		JE RESTART_GAME
		CMP AL,'r'
		JE RESTART_GAME
;		If the key is either 'E' or 'e', restart the game
		CMP AL,'E'
		JE EXIT_TO_MAIN_MENU
		CMP AL,'e'
		JE EXIT_TO_MAIN_MENU
		RET
		
		RESTART_GAME:
			MOV GAME_ACTIVE,01h
			RET
			
		EXIT_TO_MAIN_MENU:
			MOV GAME_ACTIVE,00h
			MOV CURRENT_SCENE,00h
			RET
	
	DRAW_GAME_OVER_MENU ENDP
	
	DRAW_MAIN_MENU PROC NEAR
	
		CALL CLEAR_SCREEN
	
;		Shows the menu title
		MOV AH,02h								;set cursor position
		MOV BH,00h								;set page number
		MOV DH,04h								;set row
		MOV DL,06h								;set column
		INT 10h
		
		MOV AH,09h								;write string to standard output
		LEA DX,TEXT_MAIN_MENU_TITLE				;give DX a pointer to the string TEXT_GAME_OVER_TITLE
		INT 21h									;print the string
		
;		Shows the singleplayer message
		MOV AH,02h								;set cursor position
		MOV BH,00h								;set page number
		MOV DH,06h								;set row
		MOV DL,06h								;set column
		INT 10h
		
		MOV AH,09h								;write string to standard output
		LEA DX,TEXT_MAIN_MENU_SINGLEPLAYER		;give DX a pointer to the string TEXT_MAIN_MENU_SINGLEPLAYER
		INT 21h									;print the string
		
;		Shows the multiplayer message
		MOV AH,02h								;set cursor position
		MOV BH,00h								;set page number
		MOV DH,08h								;set row
		MOV DL,06h								;set column
		INT 10h
		
		MOV AH,09h								;write string to standard output
		LEA DX,TEXT_MAIN_MENU_MULTIPLAYER		;give DX a pointer to the string TEXT_MAIN_MENU_MULTIPLAYER
		INT 21h									;print the string
		
;		Shows the exit message
		MOV AH,02h								;set cursor position
		MOV BH,00h								;set page number
		MOV DH,0Ah								;set row
		MOV DL,06h								;set column
		INT 10h
		
		MOV AH,09h								;write string to standard output
		LEA DX,TEXT_MAIN_MENU_EXIT				;give DX a pointer to the string TEXT_MAIN_MENU_EXIT
		INT 21h									;print the string
		
;       Waits for a key press
		MOV AH,00h
		INT 16h
		
;		If the key is either 'R' or 'r', restart the game
		CMP AL,'R'
		JE RESTART_GAME
		CMP AL,'r'
		JE RESTART_GAME
	
		RET
	DRAW_MAIN_MENU ENDP
	
	UPDATE_WINNER_TEXT PROC NEAR
	
		MOV AL,WINNER_INDEX						;if winner index is 1 => AL,1
		ADD AL,30h								;AL,31h => AL,'1'
		MOV [TEXT_GAME_OVER_WINNER+7],AL		;update the index in the text with the character
	
		RET
	UPDATE_WINNER_TEXT ENDP
	
	CLEAR_SCREEN PROC NEAR						;clear the screen by restarting the video mode
	
		MOV AH,00h 								;set the configuration to video mode
		MOV AL,13h 								;choose the video mode
		INT 10h    								;execute the configuration EXAMPLEFORALLINSTANCES-------
		
		MOV AH,0Bh 								;set the configuration
		MOV BH,00h 								;to the background color
		MOV BL,00h 								;choose green as background color
		INT 10h
		
		;SETTING ALL PIXELS TO GREEN FOR GREEN BACKGROUND
		;MOV AX, 0A000h  ; Set segment to video memory
		;MOV ES, AX
		;XOR DI, DI      ; Start at the beginning of video memory

		;MOV CX, 320*200 ; Total number of pixels in mode 13h
		;MOV AL, 2       ; Color index for green
		;REP STOSB       ; Set each pixel to green
		;--------------------------------------------------------
	
		RET
	CLEAR_SCREEN ENDP
	
CODE ENDS
END
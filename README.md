# Pong assembly game
Pong game created in 8086 Assembly.

To test this game you can use DOSBox program, you can find and download DOSBox on the internet.

Run DOSBox and mount the PongAssemblyGame folder that you got by cloning the repository with the same name.

Example:

c:\users\username\desktop\github\pongassemblygame

after that go to c: by typing just c: in DOSBox terminal.

now that you're in c: write:

masm /a pong.asm

to compile code(skip everything after that, like Object filename, by writing ; and hitting enter), after that type:

link pong

(skip everything by writing ; and hitting enter)after that just write:

pong

and the game will start.

Alternatively, you can copy config for DOSBox options config file from DOSBoxConfig.txt file you can find in repository. It also has some optimizations for smoother gameplay.

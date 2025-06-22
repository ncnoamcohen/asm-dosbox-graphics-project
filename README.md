## Plane Simulator 1.0 - An Assembly DOSBox Project

This Assembly program is a small project of mine meant to further get into Assembly programming and a tad into the DOSBox platform- an x86 MS-DOS emulator.
Author: Noam Cohen

The game itself isn't too complicated- you have the main menu/welcome screen, the help screen, the game screen, and finally the game over screen. Regarding the game itself- all you need to do is catch a BMP photo of a cloud with your BMP photo plane using the keyboard arrows for 10 times. After that you get the game over screen, that leads you to the main menu once again.
This project was created in order to learn BMP images printing, screen creations, keyboard input responses, and simple algorithms in Assembly for the game itself.

Hopefully the source code provides a good point of reference in the future for someone or an inspiration to something great!

A little on the technical side of compilation and DOSBox execution:

1. After writing our code of the program in the main.asm file, we would want to compile in into an executable suitable for DOSBox.
2. We need to run TASM/Turbo Assembler (but you can also use MASM/Microsoft Macro Assembler) to turn main.asm into main.obj and main.map. The file we need to execute is tasm.exe, while giving it main.asm as a parameter.
3. After running tasm.exe, we want to link main.obj. Here we use tlink.exe, a file that also comes with the TASM package. We should run the file while giving it main.obj as a parameter.
4. At this point we have now created main.exe- our desired and final executable.
5. We can now run the file in DOSBox.

The basic DOSBox commands that you should know:

1. In order to execute files, you need to mount a drive that is mapped to a path, in the following order (example): "mount c c:\tasm". If you want to change into that drive, type "c:".
2. Run "main" after running "mount c c:\mainFolder" & "c:" if you want to run the main.exe executable.

I have added all the "main" files- .asm, .obj, .map, and .exe, but you only need main.exe and all the BMP photos in order to launch the game. You can also peek at main.asm for the source code.

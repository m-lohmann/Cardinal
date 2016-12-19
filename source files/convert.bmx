'This program takes a 128x192 bmp image and converts it to a .bit file
Framework brl.pixmap
Import brl.filesystem
Import brl.stream
Import brl.retro
Import brl.bmploader

Print "Converting.."

Global p=LoadPixmap ("curses.bmp")
If Not p Input("Could not load curses.bmp");End
Global bits$=""
For y=0 To 191
For x=0 To 127
	If ReadPixel(p,x,y)=-1 bits:+"0" Else bits:+"1"
Next
Next


Local fil=WriteFile("curses.bit")
Local this$=""
For Local go%=0 To Len(bits)-1
	Local b%=Int(Mid(bits,go+1,1))
	this:+b
	If go Mod 8=7
		Local num%=0
		For Local it%=0 To 7
			'WriteStdout Mid(this,it+1,1)
			num:+Int(Mid(this,it+1,1)) Shl it
		Next
		WriteByte fil,num
		this=""
	EndIf
Next
CloseFile fil

Input "Conversion complete."

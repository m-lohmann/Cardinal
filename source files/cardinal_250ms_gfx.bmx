SuperStrict
Framework brl.standardio
Import brl.blitz
Import brl.filesystem
Import brl.stream
Import brl.retro
Import brl.math

Import brl.Graphics
Import brl.glmax2d

Global gw%=720,gh%=512
Graphics 720,512
SetBlend alphablend


Global font:TPixmap=CreatePixmap(128,192,PF_I8)
Global char:TImage=CreateImage(8,12,256,0)
Function ReadBit()
	Local img:TStream=ReadFile("curses.bit")
	Local x%=0,y%=0
	Repeat
		Local bit@=ReadByte(img)
		'Print bit
		For Local bt%=0 To 7
			Local here%=(bit Shr bt) Mod 2
			If here WritePixel font,x,y,$000000 Else WritePixel font,x,y,$ffffff
			x:+1
		Next
		If x=128 x=0;y:+1
	Until Eof(img)
	DrawPixmap font,0,0
	Local gframe%=0
	For Local gy%=0 To 15
	For Local gx%=0 To 15
		GrabImage char,gx*8,gy*12,gframe
		gframe:+1
	Next
	Next
End Function
readbit



Function DrawText(t$,x%,y%)
	If Len(t)=1
		DrawImage char,x,y,Asc(t)
	ElseIf Len(t)<1
		Return
	Else
		For Local do%=1 To Len(t)
			DrawText Mid(t,do,1),x+(do-1)*8,y
		Next
	EndIf
End Function



Function Draw()
	Cls
	
	SetColor 130,130,130 'program text color
	For Local y@=0 To gh/12
		If y=>size Exit
		If Len(code[y])
			For Local x@=0 To Len(code[y])-1
				If x=>gw/8 Exit
				DrawText Mid(code[y],x+1,1),x*8+8,y*12
			Next
		EndIf
	Next
	
	SetColor 60,60,240     ' 192,12,0    pointer color
	For Local i:ip=EachIn ip.list
		If i.x<gw/12 And i.y<gh/16
			SetAlpha .5
			DrawRect i.x*8,i.y*12,8,12
			SetAlpha .9
			Local c$="X"
			Select i.dir
				Case 0 c="^"
				Case 1 c="v"
				Case 2 c="<"
				Case 3 c=">"
			End Select
			DrawText c,i.x*8,i.y*12
		EndIf
	Next

	
	SetAlpha .8
	For Local i:ip=EachIn ip.list
		If i.x<gw/8 And i.y<gh/12
			SetColor 30,240,80 '255,0,0    active value color
			DrawText i.val[i.on],i.x*8,i.y*12-24
			SetColor 240,30,80 '132,0,0    inactive value color
			DrawText i.val[Not i.on],i.x*8,i.y*12-12
		EndIf
	Next
	SetAlpha 1
	SetColor 255,255,255
	'DrawPixmap font,0,0
	DrawText " Pointers: "+ip.list.count(),0,gh-12
	If KeyDown(27) Or AppTerminate() End
	Flip
End Function



Global path$="collatz.txt"
If AppArgs.length>1 Then
	Local ona%=0
	For Local a$=EachIn AppArgs
		ona:+1
		If ona=2 Then path=a
	Next
EndIf



Global code$[1]

Local fil:TStream=ReadFile(path)
If Not fil Print "Could not load "+path;Input;End

Global size:Long=0

Local index:Long=0
Repeat
	size:+1
	code=code[..size]
	code[size-1]=ReadLine(fil)+" "
	If Len(code[size-1])>ip.maxlen ip.maxlen=Len(code[size-1])
Until Eof(fil)
CloseFile fil


Type ip
	Global list:TList=CreateList()
	'Global nlist:TList=CreateList()
	Global terminate%=0
	Global maxlen:Long=0
	Field key%=0,n%=1
	Field x%,y%,dir%,val@[2],on%=0
	Field printing@=0,remafter@=0,wait@=0
	Function spread(x%,y%,exclude%=-1,val0@=0,val1@=0,on%=0,remaft%=0)
		Local i:ip=New ip
		If exclude<>1 i.x=x;i.y=y;i.dir=0;list.addlast i;i.val[0]=val0;i.val[1]=val1;i.remafter=remaft;i.on=on
		i:ip=New ip
		If exclude<>0 i.x=x;i.y=y;i.dir=1;list.addlast i;i.val[0]=val0;i.val[1]=val1;i.remafter=remaft;i.on=on
		i:ip=New ip
		If exclude<>3 i.x=x;i.y=y;i.dir=2;list.addlast i;i.val[0]=val0;i.val[1]=val1;i.remafter=remaft;i.on=on
		i:ip=New ip
		If exclude<>2 i.x=x;i.y=y;i.dir=3;list.addlast i;i.val[0]=val0;i.val[1]=val1;i.remafter=remaft;i.on=on
	End Function
	Method update()
		n=0
		If wait>0 wait:-1
		If wait=0
			Select dir
				Case 0 y:-1
				Case 1 y:+1
				Case 2 x:-1
				Case 3 x:+1
			End Select
		EndIf
		If y=>size Or y<0
			list.remove Self
		ElseIf x>maxlen Or x<0
			list.remove Self	
		Else'If x<=Len(code[y])
			If x>Len(code[y]) code[y]:+"  "
			If printing
				If Mid(code[y],x,1)="~q" printing=0 Else WriteStdout Mid(code[y],x,1)
			Else
				Select Mid(code[y],x,1)
					Case "x" list.remove Self
					Case "#" list.remove Self;spread x,y,dir,val[0],val[1],on,remafter
					Case ";" Print "" 'newline
					Case "~q"printing=1
					Case "@" ClearList list;terminate=1
					Case "+" val[on]:+1
					Case "-" val[on]:-1
					Case "$" x=val[on];y=val[Not on]
					Case "t" val[on]:*val[Not on]
					Case "d" val[on]:/val[Not on]
					Case "*" val[on]:+val[Not on]
					Case "'" val[on]:-val[Not on]
					Case "M" val[on]=val[on] Mod val[Not on]
					Case "=" val[Not on]=val[on]
					Case "0" val[on]=0
					Case "~~"on=Not on
					Case "&" val[on]=val[on] And val[Not on]
					Case "|" val[on]=val[on] Or val[Not on]
					Case "X" val[on]=((val[on]=0) Or (val[Not on]=0)) And ((val[on]=1) Or (val[Not on]=1))
					Case "`" remafter=Not remafter
					Case "n" rebuffer(x,y-1,Chr(val[on]));val[on]=grab(x,y+1);If remafter list.remove Self
					Case "u" rebuffer(x,y+1,Chr(val[on]));val[on]=grab(x,y-1);If remafter list.remove Self
					Case "(" rebuffer(x-1,y,Chr(val[on]));val[on]=grab(x+1,y);If remafter list.remove Self  ' x-1,x has to be x-1,y
					Case ")" rebuffer(x+1,y,Chr(val[on]));val[on]=grab(x-1,y);If remafter list.remove Self  ' x+1,x has to be x+1,y
					Case "." WriteStdout val[on]
					Case "," WriteStdout Chr(val[on])
					Case ":" val[on]=Byte(ReadStdin())
					Case ">" dir=3';x:+1
					Case "<" dir=2';x:-1
					Case "^" dir=0';y:-1
					Case "v" dir=1';y:+1
					Case "?" If val[on]=0 Then list.remove Self
					Case "!" If val[on]>0 Then list.remove Self
					Case "}" If dir=3 list.remove Self
					Case "{" If dir=2 list.remove Self
					Case "A" If dir=0 list.remove Self  'was missing
					Case "V" If dir=1 list.remove Self  'was missing
					Case "8" If wait=0 wait=3
					Case "J" 
						If val[on]>0
							Select dir
								Case 0 y:+1'x:+1
								Case 1 y:-1'x:-1
								Case 2 x:-1'x:-1
								Case 3 x:+1'x:+1
							End Select
						EndIf
					Case "j" 
						If val[on]=0
							Select dir
								Case 0 y:+1'x:+1
								Case 1 y:-1'x:-1
								Case 2 x:-1'x:-1
								Case 3 x:+1'x:+1
							End Select
						EndIf
					Case "/" rebuffer(x,y,"\")
						Select dir
							Case 0 dir=3';x:+1
							Case 1 dir=2';x:-1
							Case 2 dir=1';y:+1
							Case 3 dir=0';y:-1
						End Select
					Case "\" rebuffer(x,y,"/")
						Select dir
							Case 0 dir=2';x:-1
							Case 1 dir=3';x:+1
							Case 2 dir=0';y:-1
							Case 3 dir=1';y:+1
						End Select
					Case "O"
						Select dir
							Case 0 dir=3';x:-1
							Case 1 dir=2';x:+1
							Case 2 dir=0';y:-1
							Case 3 dir=1';y:+1
						End Select
					Case "o"
						Select dir
							Case 0 dir=2';x:-1
							Case 1 dir=3';x:+1
							Case 2 dir=1';y:-1
							Case 3 dir=0';y:+1
						End Select
					Case "N"
						Select dir
							Case 2 dir=3';y:-1
							Case 3 dir=2';y:+1
						End Select
					Case "Z"
						Select dir
							Case 0 dir=1';x:-1
							Case 1 dir=0';x:+1
						End Select
					Case "I"
						Select dir
							Case 0 dir=1';x:-1
							Case 1 dir=0';x:+1
							Case 2 dir=3';y:-1
							Case 3 dir=2';y:+1
						End Select
					Case "U" If val[on]>0 dir=0
					Case "D" If val[on]>0 dir=1
					Case "L" If val[on]>0 dir=2
					Case "R" If val[on]>0 dir=3
				End Select
				If y=>size list.remove Self
			EndIf
		EndIf
	End Method
End Type


Type buf
	Global list:TList=CreateList()
	Field x%,y%,rep$
End Type

Function rebuffer(x:Long,y:Long,rep$)
	Local b:buf=New buf
	b.x=x;b.y=y;b.rep=rep
	buf.list.addlast b
End Function

Function buffer()
	For Local b:buf=EachIn buf.list
		For Local o:buf=EachIn buf.list
			If b<>o And b.x=o.x And b.y=o.y buf.list.remove o
		Next
		dorebuffer(b.x,b.y,b.rep)
	Next
	ClearList buf.list
End Function

Function dorebuffer(x:Long,y:Long,rep$)
	If y<0 Or x<0 Or y=>size Return
	If x=0 code[y]=rep+Right(code[y],Len(code[y])-1);Return
	If x=Len(code[y])-1 code[y]=Left(code[y],Len(code[y])-2)+rep;Return
	code[y]=Left(code[y],x-1)+rep+Right(code[y],Len(code[y])-x);Return
	If x=>Len(code[y]) 
		Repeat
			code[y]:+" "
		Until x=Len(code[y])+1
		code[y]:+rep;Return
	EndIf
End Function



Function grab@(x:Long,y:Long)
	If y<0 Or y=>size Return 32
	If x<0 Or x=>Len(code[y]) Return 32
	Return Asc(Mid(code[y],x,1))
End Function



For Local init:Long=0 To size-1
	If Len(code[init])>0
		For Local il:Long=1 To Len(code[init])
			If Mid(code[init],il,1)="%" ip.spread(il,init)
		Next
	EndIf
Next


Print "Executing program.."
Print ""



draw
Repeat
	Delay 250'WaitKey()'Delay 64
	
	For Local i:ip=EachIn ip.list
		i.update
		For Local o:ip=EachIn ip.list
			If o<>i And o.x=i.x And o.y=i.y And o.dir=i.dir And o.n=0 And i.n=0 ip.list.remove o
		Next
	Next
	
	draw
	If ip.list.count()<1 Exit
	If ip.terminate Exit
	buffer
Forever

Print ""
Print ""
Print "Execution complete."
Input
End
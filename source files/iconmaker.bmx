Import BRL.FileSystem
Import PUB.stdc
Strict
If AppArgs.length < 2 Then
	Print "Invalid argument count"
	Print "Usage:IconMaker filename"
	Print "Number of arguments = "+AppArgs.length
	End
EndIf
Local iconfilename:String= AppArgs[1]
If FileType(iconfilename)<>1 Then
	Print iconfilename +" does not exists or is not a file"
	End
End If
Local rcfilename:String= StripAll(iconfilename)+".rc"
Print "Creating RC File:"+rcfilename
If CreateFile(rcfilename) Then
	Print "File Created"
	Local f:TStream=OpenFile(rcfilename)
	f.WriteLine("1 ICON ~q"+iconfilename+"~q")
	CloseFile f
End If

Print "Executing Windres to create Object file"
Local objfilename:String=StripExt(rcfilename)+".o";
Local command:String="windres -i ~q"+rcfilename+"~q -o ~q"+objfilename+"~q"
Print command
If system_(command)=0 Then
	Print "Created "+objfilename
	Print "Add "
	Print "Import ~q"+objfilename+"~q" 
	Print "to your BMX project to link in icon"
End If

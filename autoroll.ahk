#requires Autohotkey v2
#include <Gdip_All>

pToken := Gdip_Startup()
form:=0
~^Esc::Pause(-1) ; bind esc to pause the script

x:=Ceil(0.276*A_ScreenWidth) ; start x
y:=Ceil(0.449*A_ScreenHeight) ; start y
w:=Ceil(0.444*A_ScreenWidth) ; width
h:=Ceil(0.383*A_ScreenHeight) ; height

if(!DirExist(".\temp")){
    DirCreate(".\temp")
}

screenshotrect:=x . '|' . y . '|' . w . '|' . h

MsgBox('Alt+F8 to start the script`nCtrl+Esc to stop the script')


!F8:: 
{
    subtype:=subvalue:=subtypes:=subvalues:=delay:=noselect:=0

    formBox:= Gui('+AlwaysOnTop +LastFound')
    formBox.AddText(,('`nSubstats to look for (as it appears ingame w/o spaces):`nLeave empty to look for all the relevant ones`n'))
    formBox.AddEdit('vSubstat',)
    formBox.AddText(,'`nLowest substat value to consider keeping:')
    formBox.AddEdit('vValue',)
    formBox.AddText(,'`nDelay between scans in ms `nLeave empty for default (1500ms)')
    formBox.AddEdit('vDelay',)
    okbutton:=formBox.AddButton('Default vOK','OK')
    okbutton.OnEvent('Click',OkPressed)
    
    OkPressed(box,_) {
        form:=formBox.Submit()
        if(form.Substat=""){
            form.Substat:=0
            noselect:=1
        }
        if(form.Delay=""){
            form.Delay:="1500"
        }
        if(form.Value=''){
            form.Value:=0
        }
        subtype:=Trim(StrLower(form.Substat))
        subvalue:=Trim(form.Value)
        subtypes:=StrSplit(subtype,' '," `t")
        subvalues:=StrSplit(subvalue,' '," `t")
        inputkeep:=Array()
        inputkeep.Length:=subtypes.Length
        delay:=form.Delay

        formBox.Destroy()
        return
    }
    
    formBox.Show()
    WinWaitClose(ControlGetHwnd(formBox))
    Loop{
        sleep delay
        snap:=Gdip_BitmapFromScreen(screenshotrect) ; screenshot a rectangle with stats
        Gdip_SaveBitmapToFile(snap, ".\temp\screen.png") ; save screenshot to pass to tesseract
        Gdip_DisposeImage(snap)
        ; run tesseract 
        RunWait '"c:\Program Files\Tesseract-OCR\tesseract.exe" .\temp\screen.png .\temp\parse -c tessedit_char_whitelist=CRITDABTKMGSPHEFLabcdefghijklmnopqrstuvwxyz0123456789.% --psm 6' ,,'Hide'
        ;wait for tesseract to finish
        
        biscinfo := FileOpen(".\temp\parse.txt",'r') ; open tess output

        textblob := biscinfo.Read()
        
        lines:= Array()
        values:= Array()

        wordarr := StrSplit(textblob,[A_Space, A_Tab,'`n'],'>»)y') ; split 
        i:=0
        while (i<wordarr.Length){ 
            i++
            percpos:= RegExMatch(wordarr[i],'%',,1)
            if (percpos!=0 and (wordarr[i]~='CRIT%')=0){
                wordarr[i]:=SubStr(wordarr[i],1,percpos-1)
            }
            if (StrLen(wordarr[i])<=2 and !(IsFloat(wordarr[i]) or IsInteger(wordarr[i])) and ((wordarr[i]~='HP')=0)) ; filter out trash
            {
                wordarr.RemoveAt(i)
                i:=i-1
            }
        }
        i:=0
        while (i<wordarr.Length){
            i++
            if (IsFloat(wordarr[i]) or IsInteger(wordarr[i])) {
                if(wordarr[i]<=20){
                    values.Push(wordarr[i])
                } else{
                    values.Push(SubStr(wordarr[i],1,-1))
                }
            }
            else{
                lines.Push(StrLower(wordarr[i]))
            }
        }
        
        cdkeep:=dmrkeep:=aspdkeep:=dmrbkeep:=eleckeep:=psnkeep:=inputkeep:=0
        
        for i,v in lines{

            try switch v
        {
            case !noselect:
                for j,s in subtypes{
                    if (s=v){
                        if(values[i]>=subvalues[j])
                        inputkeep[j]++
                    }
                }
            case "cooldown":
                if (values[i]>=5.6)
                {
                    cdkeep++
                }
            case "atkspd":
                if (values[i]>=9.5)
                {
                    aspdkeep++
                }
            case "dmgresist":
                if (values[i]>=9.6)
                {
                    dmrkeep++
                }
            case "hp":
                if (values[i]>=13)
                {
                    dmrkeep++
                }
            case "dmgresistbypass":
                if (values[i]>=14.3)
                {
                    dmrbkeep++
                }
            case "elec.dmg":
                
                if (values[i]>=14.5)
                {
                    eleckeep++
                }
            case "poisondmg":
                if (values[i]>=14.5)
                {
                    psnkeep++
                }
            }
            catch IndexError {
                break
            }
        }
        if (subtype='offense' or subtype='nodmr'){
            if (cdkeep>1 or eleckeep>1 or psnkeep>1 or aspdkeep>1)
                {
                    MsgBox "Girl YES!"
                    break
                }
        }
        else if (subtype!=0){
            if (inputkeep>1)
            {
                MsgBox "Girl YES!"
            break
            }
        }
        else if (cdkeep>1 or dmrkeep>1 or dmrbkeep>1 or eleckeep>1 or psnkeep>1 or aspdkeep>1)
            {
                MsgBox "Girl YES!"
                break
            }
        
        
        
 /* textstr:=""
        
        i:=0
        while (i<Min(lines.Length,values.Length)) {
            i++
            textstr.= lines[i] . '> ' 
            textstr.= values[i] . '`n'
        }
    */
        biscinfo.Close()
        Click('Left',0.58*A_ScreenWidth,0.91*A_ScreenHeight)
    }
}

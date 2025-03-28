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

MsgBox('Install Tesseract for the script to work`nAlt+F8 to start the script`nCtrl+Esc to stop the script')


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
        inputkeep:=Array()
        for i,v in subtypes{
            inputkeep.Push('0')
        }

        wordarr := StrSplit(textblob,[A_Space, A_Tab,'`n'],'>»)y') ; split 

        ;1st pass for cleaning up strings
        i:=0
        while (i<wordarr.Length){ 
            i++
            percpos:= RegExMatch(wordarr[i],'%',,1) ;find percent sign position is string 
            if (percpos!=0 and (RegExMatch(wordarr[i],'i)crit%'))=0) 
                {
                wordarr[i]:=SubStr(wordarr[i],1,percpos-1) ;remove it if exists in a string (but not from crit%)
            }
            if (StrLen(wordarr[i])<=2 and !(IsFloat(wordarr[i]) or IsInteger(wordarr[i])) and ((wordarr[i]~='HP')=0)) ; filter out artifacts
            {
                wordarr.RemoveAt(i)
                i:=i-1
            }
        }

        ;2nd pass for sorting cleaned up strings into arrays
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
    
        
        ;compare parsed text against accepted stats/values
        for i,v in lines{
            for j,s in subtypes{
                if (s=v){
                    if(values[i]>=subvalues[j])
                    inputkeep[j]++
                }
            }
        }
        ;check the array if we got 2+ lines of the same type to keep
        for i,v in inputkeep {
            if (v>1){
                MsgBox "Girl YES! " . subtypes[i] . ' kept'
                break 2
            }
        }
            
            
            
            
            
            
            
            
            /*try switch v
        {
            case 1:
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
        }*/
        
        
        
        
 /* textstr:=""
        
        i:=0
        while (i<Min(lines.Length,values.Length)) {
            i++
            textstr.= lines[i] . '> ' 
            textstr.= values[i] . '`n'
        }
    */
        biscinfo.Close()
        Click('Left',0.58*A_ScreenWidth,0.91*A_ScreenHeight) ; left click on the reroll all button coords
    }
}

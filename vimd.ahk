﻿#SingleInstance, Force

CoordMode, Tooltip, Screen
CoordMode, Mouse, Screen
Coordmode, Menu, Window
SetControlDelay, -1
SetKeyDelay, -1
Detecthiddenwindows, on

Menu, Tray, Icon, %A_ScriptDir%\viatc.ico
Menu, Tray, NoStandard
Menu, Tray, Add, 查看热键(&K), <vc_Keymap>
Menu, Tray, Add, 查看插件(&P), <vc_Plugin>
Menu, Tray, Add, 
Menu, Tray, Add, 重启(&R), <Reload>
Menu, Tray, Add, 退出(&X), <Exit>
iniWrite, %A_ScriptHwnd%, %A_Temp%\vimd_auto.ini, auto, hwnd

global ConfigPath := A_ScriptDir "\vimd.ini"
if (!FileExist(ConfigPath))
{
    FileCopy, %ConfigPath%.help.txt, %ConfigPath%
}

; 启用vim
vim := class_vim()
ini := class_EasyINI(A_ScriptDir "\vimd.ini")
; 第二个参数为存放描述信息的全局变量名
act := vim.SetAction("VIMD_CMD", "VIMD_CMD_LIST")
act.SetFunction("VIMD_CMD")

global default_enable_show_info
default_enable_show_info := ini.config.default_enable_show_info

;vim.Debug(true)

CheckPlugin()
CheckHotKey()

; 用于接收来自cehck.ahk的信息
OnMessage(0x4a, "Receive_WM_COPYDATA")
return

GetVimdConfig()
{
    Global ini
    return ini
}

SaveVimdConfig()
{
    Global ini
    ini.save()
}

CheckPlugin()
{
    global vim
    dc := GetVimdConfig()
    for plugin, bold in dc.plugins
        if bold
            vim.LoadPlugin(plugin)
}

CheckHotKey()
{
    global vim, VIMD_CMD_LIST
    VIMD_CMD_LIST := IsObject(VIMD_CMD_LIST) ? VIMD_CMD_LIST : []
    ini := GetVimdConfig()
    for i, k in ini.global
    {
        if not strlen(i)
            continue
        if RegExMatch(k, "\[=[^\[\]]*\]", mode)
        {
            this_mode := Substr(mode, 3, strlen(mode)-3)
            vim.Mode(this_mode)
            this_action := RegExReplace(k, "\[=[^\[\]]*\]")
            if RegExMatch(this_action, "^((run)|(key))\|")
            {
                vim.map(i, "VIMD_CMD")
                VIMD_CMD_LIST[i] := this_action
            }
            else
            {
                vim.map(i, this_action)
            }

        }
    }

    for i, k in ini.exclude
    {
        vim.SetWin(i, i)
        vim.ExcludeWin(i, true)
    }

    for i, k in ini
    {
        if RegExMatch(i, "i)(config)|(exclude)|(global)|(plugins)")
            continue

        win := vim.SetWin(i, k.set_class, k.set_file)
        vim.SetTimeOut(k.set_time_out, i)
        vim.SetMaxCount(k.set_Max_count, i)
        if (k.enable_show_info = "1") {
            win.SetInfo(true)
        }

        for m, n in k
        {
            if not strlen(m)
                continue

            if RegExMatch(m, "i)(set_class)|(set_file)|(set_time_out)|(set_Max_count)|(enable_show_info)")
                continue

            if RegExMatch(n, "\[=[^\[\]]*\]", mode)
            {
                this_mode := Substr(mode, 3, strlen(mode)-3)
                vim.mode(this_mode, i)
                this_action := RegExReplace(n, "\[=[^\[\]]*\]")
                vim.map(m, this_action, i)
            }
            else if RegExMatch(n, "i)^((run)|(key))\|")
            {
                vim.mode("normal", i)

                /*
                <c-j> 记事本 run|notepad.exe
                */

                vim.map(m, "VIMD_CMD", i)
                VIMD_CMD_LIST[m] := n
            }
        }
    }
}

VIMD_CMD()
{
    global VIMD_CMD_LIST
    obj := GetLastAction()
    if RegExMatch(VIMD_CMD_LIST[obj.keytemp], "i)^(run)\|", m)
    {
        Run, % substr(VIMD_CMD_LIST[obj.keytemp], strlen(m1) + 2)
    }
    else if RegExMatch(VIMD_CMD_LIST[obj.keytemp], "i)^(key)\|", m)
    {
        Send, % substr(VIMD_CMD_LIST[obj.keytemp], strlen(m1) + 2)
    }
}

; Receive_WM_COPYDATA(wParam, lParam) {{{2
Receive_WM_COPYDATA(wParam, lParam)
{
    ; 获取 CopyDataStruct 的 lpData 成员.
    StringAddress := NumGet(lParam + 2 * A_PtrSize) 
    ; 从结构中复制字符串.
    AHKReturn := StrGet(StringAddress)
    if RegExMatch(AHKReturn, "i)reload")
    {
        Settimer, VIMD_Reload, 500
        return true
    }
}

VIMD_Reload:
    Reload
return

/*
RunAsAdmin()
{
    local params, uacrep
    Loop %0%
        params .= " " (InStr(%A_Index%, " ") ? """" %A_Index% """" : %A_Index%)
    if(A_IsCompiled)
        uacrep := DllCall("shell32\ShellExecute", uint, 0, str, "RunAs", str, A_ScriptFullPath, str, "/r" params, str, A_WorkingDir, int, 1)
    else
        uacrep := DllCall("shell32\ShellExecute", uint, 0, str, "RunAs", str, A_AhkPath, str, "/r """ A_ScriptFullPath """" params, str, A_WorkingDir, int, 1)
    if(uacrep = 42) ;UAC Prompt confirmed, application may run as admin
        ExitApp
    else
        MsgBox 未能获取管理员权限，这可能导致部分功能无法运行。
}
*/

#Include %A_ScriptDir%\core\class_vim.ahk
#Include %A_ScriptDir%\core\VimDConfig.ahk
#Include %A_ScriptDir%\lib\class_EasyINI.ahk
#Include %A_ScriptDir%\lib\acc.ahk
#Include %A_ScriptDir%\lib\ini.ahk
#Include %A_ScriptDir%\lib\gdip.ahk
#Include %A_ScriptDir%\plugins\plugins.ahk

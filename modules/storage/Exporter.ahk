; Exporter.ahk - 导出打包
Exporter_ExportProfile(profileName) {
    global App
    srcScript := A_ScriptFullPath
    srcIni := App["ProfilesDir"] "\" profileName App["ConfigExt"]
    if !FileExist(srcIni) {
        MsgBox "配置文件不存在：" srcIni
        return
    }
    destDir := App["ExportDir"] "\" profileName
    if DirExist(destDir)
        DirDelete destDir, 1
    DirCreate(destDir)
    DirCreate(destDir "\Profiles")

    ; 拷贝脚本与配置
    FileCopy srcScript, destDir "\GW2_Macro_Main.ahk", 1
    FileCopy srcIni, destDir "\Profiles\" profileName ".ini", 1

    FileAppend(
        "使用说明：`r`n"
      . "1) 双击 GW2_Macro_Main.ahk 打开配置工具。`r`n"
      . "2) 已包含配置：" profileName "`r`n"
      . "3) 可使用 Ahk2Exe 编译为 EXE。`r`n",
      destDir "\ReadMe.txt"
    )
    Notify("已导出到：" destDir, 1800)
}
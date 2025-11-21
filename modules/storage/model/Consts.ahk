#Requires AutoHotkey v2
;modules\storage\model\Consts.ahk 数据模型常量

; Schema 版本（从模块化开始计）
global PM_SCHEMA_VERSION := 2

; 模块名（用于 NextId / IdMap）
global PM_MOD_SKILL  := "Skill"
global PM_MOD_POINT  := "Point"
global PM_MOD_RULE   := "Rule"
global PM_MOD_TRACK  := "Track"
global PM_MOD_GATE   := "Gate"
global PM_MOD_BUFF   := "Buff"
global PM_MOD_THREAD := "Thread"

PM_NowStr() {
    now := ""
    try {
        now := FormatTime(, "yyyy-MM-dd HH:mm:ss")
    } catch {
        now := ""
    }
    return now
}
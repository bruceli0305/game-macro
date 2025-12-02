; ============================================
; modules\util\JsonWrapper.ahk
; 使用 jsongo 封装 JSON 解析 / 序列化
; ============================================
#Requires AutoHotkey v2
#Include "jsongo.ahk"

Json_Load(jsonText) {
    ; 解析 JSON 字符串为 AHK 对象（Map / Array）
    return jsongo.Parse(jsonText)
}

Json_Save(obj) {
    ; 把 AHK 对象转为 JSON 字符串（目前用不上，预留）
    return jsongo.Stringify(obj)
}
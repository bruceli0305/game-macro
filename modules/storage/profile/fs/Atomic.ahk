#Requires AutoHotkey v2
;modules\storage\profile\fs\Atomic.ahk 原子替换：先删除 tmp，再写入 tmp，最后覆盖 target（调用处负责 IniWrite 到 tmp）
FS_AtomicBegin(path) {
    tmp := path ".tmp"
    try {
        if FileExist(tmp) {
            FileDelete(tmp)
        }
    } catch {
    }
    return tmp
}

FS_AtomicCommit(tmp, target, makeBak := true) {
    try {
        if (makeBak && FileExist(target)) {
            FileCopy(target, target ".bak", true)
        }
    } catch {
    }
    try {
        if FileExist(tmp) {
            FileMove(tmp, target, true)
        }
    } catch {
        ; 可选：此处用统一日志 Logger_Exception 记录
    }
}
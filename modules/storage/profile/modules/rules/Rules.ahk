#Requires AutoHotkey v2
; modules\storage\profile\Save_Rules.ahk
; 规则模块（新格式）：[Rules] Count/Order + [Rule.<Id>] 节内自带 Id
; 依赖：OM_Get（modules\util\Obj.ahk）、ID_Next（modules\util\IdGen.ahk）
; 依赖：FS_ModulePath / FS_AtomicBegin / FS_AtomicCommit / FS_Meta_Touch

SaveModule_Rules(profile) {
    if !IsObject(profile) {
        return false
    }

    name := ""
    try {
        name := profile["Name"]
    } catch {
        return false
    }

    file := FS_ModulePath(name, "rules")
    tmp := FS_AtomicBegin(file)

    arr := []
    try {
        arr := profile["Rules"]
    } catch {
        arr := []
    }

    count := 0
    try {
        count := arr.Length
    } catch {
        count := 0
    }
    IniWrite(count, tmp, "Rules", "Count")

    ; 确保每条规则有稳定 Id，并构建 Order
    order := ""
    i := 1
    while (i <= count) {
        r := 0
        try {
            r := arr[i]
        } catch {
            r := 0
        }
        if (!IsObject(r)) {
            i := i + 1
            continue
        }

        rid := 0
        try {
            rid := OM_Get(r, "Id", 0)
        } catch {
            rid := 0
        }
        if (rid <= 0) {
            newId := 0
            try {
                newId := ID_Next()
            } catch {
                newId := 0
            }
            if (newId > 0) {
                wrote := false
                try {
                    r["Id"] := newId
                    wrote := true
                } catch {
                    wrote := false
                }
                if (!wrote) {
                    try {
                        r.Id := newId
                    } catch {
                    }
                }
                rid := newId
            }
        }

        if (order = "") {
            order := "" rid
        } else {
            order := order "," rid
        }
        i := i + 1
    }
    IniWrite(order, tmp, "Rules", "Order")

    ; 写每条规则与其子节
    i := 1
    while (i <= count) {
        r := 0
        try {
            r := arr[i]
        } catch {
            r := 0
        }
        if (!IsObject(r)) {
            i := i + 1
            continue
        }

        rid := 0
        try {
            rid := OM_Get(r, "Id", 0)
        } catch {
            rid := 0
        }
        if (rid <= 0) {
            i := i + 1
            continue
        }

        rSec := "Rule." rid
        IniWrite(rid, tmp, rSec, "Id")
        IniWrite(OM_Get(r, "Name", "Rule"),           tmp, rSec, "Name")
        IniWrite(OM_Get(r, "Enabled", 1),             tmp, rSec, "Enabled")
        IniWrite(OM_Get(r, "Logic", "AND"),           tmp, rSec, "Logic")
        IniWrite(OM_Get(r, "CooldownMs", 500),        tmp, rSec, "CooldownMs")
        IniWrite(OM_Get(r, "Priority", i),            tmp, rSec, "Priority")
        IniWrite(OM_Get(r, "ActionGapMs", 60),        tmp, rSec, "ActionGapMs")
        IniWrite(OM_Get(r, "ThreadId", 1),            tmp, rSec, "ThreadId")
        IniWrite(OM_Get(r, "SessionTimeoutMs", 0),    tmp, rSec, "SessionTimeoutMs")
        IniWrite(OM_Get(r, "AbortCooldownMs", 0),     tmp, rSec, "AbortCooldownMs")

        ; 条件
        conds := []
        try {
            conds := r["Conditions"]
        } catch {
            conds := []
        }
        cCount := 0
        try {
            cCount := conds.Length
        } catch {
            cCount := 0
        }
        IniWrite(cCount, tmp, rSec, "CondCount")

        j := 1
        while (j <= cCount) {
            c := 0
            try {
                c := conds[j]
            } catch {
                c := 0
            }
            cSec := "Rule." rid ".Cond." j

            kind := ""
            try {
                kind := OM_Get(c, "Kind", "Pixel")
            } catch {
                kind := "Pixel"
            }
            kindU := StrUpper(kind)

            if (kindU = "COUNTER") {
                IniWrite("Counter", tmp, cSec, "Kind")
                IniWrite(OM_Get(c, "SkillId", 0), tmp, cSec, "SkillId")
                IniWrite(OM_Get(c, "Cmp", "GE"),  tmp, cSec, "Cmp")
                IniWrite(OM_Get(c, "Value", 1),   tmp, cSec, "Value")
                IniWrite(OM_Get(c, "ResetOnTrigger", 0), tmp, cSec, "ResetOnTrigger")
            } else {
                IniWrite("Pixel", tmp, cSec, "Kind")
                IniWrite(OM_Get(c, "RefType", "Skill"),      tmp, cSec, "RefType")
                IniWrite(OM_Get(c, "RefId", 0),              tmp, cSec, "RefId")
                IniWrite(OM_Get(c, "Op", "EQ"),              tmp, cSec, "Op")
                IniWrite(OM_Get(c, "Color", "0x000000"),     tmp, cSec, "Color")
                IniWrite(OM_Get(c, "Tol", 16),               tmp, cSec, "Tol")
            }
            j := j + 1
        }

        ; 动作
        acts := []
        try {
            acts := r["Actions"]
        } catch {
            acts := []
        }
        aCount := 0
        try {
            aCount := acts.Length
        } catch {
            aCount := 0
        }
        IniWrite(aCount, tmp, rSec, "ActCount")

        j := 1
        while (j <= aCount) {
            a := 0
            try {
                a := acts[j]
            } catch {
                a := 0
            }
            aSec := "Rule." rid ".Act." j
            IniWrite(OM_Get(a, "SkillId", 0),        tmp, aSec, "SkillId")
            IniWrite(OM_Get(a, "DelayMs", 0),        tmp, aSec, "DelayMs")
            IniWrite(OM_Get(a, "HoldMs", -1),        tmp, aSec, "HoldMs")
            IniWrite(OM_Get(a, "RequireReady", 0),   tmp, aSec, "RequireReady")
            IniWrite(OM_Get(a, "Verify", 0),         tmp, aSec, "Verify")
            IniWrite(OM_Get(a, "VerifyTimeoutMs", 600), tmp, aSec, "VerifyTimeoutMs")
            IniWrite(OM_Get(a, "Retry", 0),          tmp, aSec, "Retry")
            IniWrite(OM_Get(a, "RetryGapMs", 150),   tmp, aSec, "RetryGapMs")
            j := j + 1
        }
        i := i + 1
    }

    FS_AtomicCommit(tmp, file, true)
    FS_Meta_Touch(profile)
    return true
}

FS_Load_Rules(profileName, profile) {
    file := FS_ModulePath(profileName, "rules")
    if !FileExist(file) {
        return
    }

    arr := []
    order := ""
    try {
        order := IniRead(file, "Rules", "Order", "")
    } catch {
        order := ""
    }
    if (order = "") {
        profile["Rules"] := []
        return
    }

    ids := StrSplit(order, ",")
    i := 1
    while (i <= ids.Length) {
        idStr := ""
        try {
            idStr := Trim(ids[i])
        } catch {
            idStr := ""
        }
        rid := 0
        try {
            rid := Integer(idStr)
        } catch {
            rid := 0
        }
        if (rid <= 0) {
            i := i + 1
            continue
        }

        rSec := "Rule." rid
        r := PM_NewRule()
        try {
            r["Id"] := rid
        } catch {
        }
        try {
            r["Name"] := IniRead(file, rSec, "Name", "Rule")
        } catch {
        }
        try {
            r["Enabled"] := Integer(IniRead(file, rSec, "Enabled", 1))
        } catch {
        }
        try {
            r["Logic"] := IniRead(file, rSec, "Logic", "AND")
        } catch {
        }
        try {
            r["CooldownMs"] := Integer(IniRead(file, rSec, "CooldownMs", 500))
        } catch {
        }
        try {
            r["Priority"] := Integer(IniRead(file, rSec, "Priority", i))
        } catch {
        }
        try {
            r["ActionGapMs"] := Integer(IniRead(file, rSec, "ActionGapMs", 60))
        } catch {
        }
        try {
            r["ThreadId"] := Integer(IniRead(file, rSec, "ThreadId", 1))
        } catch {
        }
        try {
            r["SessionTimeoutMs"] := Integer(IniRead(file, rSec, "SessionTimeoutMs", 0))
        } catch {
        }
        try {
            r["AbortCooldownMs"] := Integer(IniRead(file, rSec, "AbortCooldownMs", 0))
        } catch {
        }

        cCount := 0
        try {
            cCount := Integer(IniRead(file, rSec, "CondCount", 0))
        } catch {
            cCount := 0
        }
        conds := []
        j := 1
        while (j <= cCount) {
            cSec := "Rule." rid ".Cond." j
            kind := ""
            try {
                kind := IniRead(file, cSec, "Kind", "Pixel")
            } catch {
                kind := "Pixel"
            }
            kindU := StrUpper(kind)
            if (kindU = "COUNTER") {
                c := PM_NewCondCounter()
                try {
                    c["SkillId"] := Integer(IniRead(file, cSec, "SkillId", 0))
                } catch {
                }
                try {
                    c["Cmp"] := IniRead(file, cSec, "Cmp", "GE")
                } catch {
                }
                try {
                    c["Value"] := Integer(IniRead(file, cSec, "Value", 1))
                } catch {
                }
                try {
                    c["ResetOnTrigger"] := Integer(IniRead(file, cSec, "ResetOnTrigger", 0))
                } catch {
                }
                conds.Push(c)
            } else {
                c := PM_NewCondPixel()
                try {
                    c["RefType"] := IniRead(file, cSec, "RefType", "Skill")
                } catch {
                }
                try {
                    c["RefId"] := Integer(IniRead(file, cSec, "RefId", 0))
                } catch {
                }
                try {
                    c["Op"] := IniRead(file, cSec, "Op", "EQ")
                } catch {
                }
                try {
                    c["Color"] := IniRead(file, cSec, "Color", "0x000000")
                } catch {
                }
                try {
                    c["Tol"] := Integer(IniRead(file, cSec, "Tol", 16))
                } catch {
                }
                conds.Push(c)
            }
            j := j + 1
        }
        r["Conditions"] := conds

        aCount := 0
        try {
            aCount := Integer(IniRead(file, rSec, "ActCount", 0))
        } catch {
            aCount := 0
        }
        acts := []
        j := 1
        while (j <= aCount) {
            aSec := "Rule." rid ".Act." j
            a := PM_NewAction()
            try {
                a["SkillId"] := Integer(IniRead(file, aSec, "SkillId", 0))
            } catch {
            }
            try {
                a["DelayMs"] := Integer(IniRead(file, aSec, "DelayMs", 0))
            } catch {
            }
            try {
                a["HoldMs"] := Integer(IniRead(file, aSec, "HoldMs", -1))
            } catch {
            }
            try {
                a["RequireReady"] := Integer(IniRead(file, aSec, "RequireReady", 0))
            } catch {
            }
            try {
                a["Verify"] := Integer(IniRead(file, aSec, "Verify", 0))
            } catch {
            }
            try {
                a["VerifyTimeoutMs"] := Integer(IniRead(file, aSec, "VerifyTimeoutMs", 600))
            } catch {
            }
            try {
                a["Retry"] := Integer(IniRead(file, aSec, "Retry", 0))
            } catch {
            }
            try {
                a["RetryGapMs"] := Integer(IniRead(file, aSec, "RetryGapMs", 150))
            } catch {
            }
            acts.Push(a)
            j := j + 1
        }
        r["Actions"] := acts

        arr.Push(r)
        i := i + 1
    }

    profile["Rules"] := arr
}
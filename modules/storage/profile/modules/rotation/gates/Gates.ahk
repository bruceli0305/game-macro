#Requires AutoHotkey v2
; modules\storage\profile\modules\rotation\gates\Gates.ahk
; 跳轨模块（新格式）：[Gates] Count/Order + [Gate.<Id>] 节内自带 Id
; 引用均为稳定 Id（FromTrackId/ToTrackId/RefId/RuleId/SkillId）
; 不兼容旧格式（无 NextId/Id.n）

SaveModule_Gates(profile) {
    if !IsObject(profile) {
        return false
    }

    name := ""
    try {
        name := profile["Name"]
    } catch {
        name := ""
    }
    if (name = "") {
        return false
    }

    dbgStore := 0
    try {
        if Logger_IsEnabled(50, "Storage") {
            dbgStore := 1
        } else {
            dbgStore := 0
        }
    } catch {
        dbgStore := 0
    }

    file := FS_ModulePath(name, "rotation_gates")
    tmp := FS_AtomicBegin(file)

    gates := []
    try {
        gates := profile["Rotation"]["Gates"]
    } catch {
        gates := []
    }

    count := 0
    try {
        count := gates.Length
    } catch {
        count := 0
    }
    IniWrite(count, tmp, "Gates", "Count")

    ; 分配雪花 Id 并构建 Order
    order := ""
    newIds := 0
    i := 1
    while (i <= count) {
        g := 0
        try {
            g := gates[i]
        } catch {
            g := 0
        }
        if !IsObject(g) {
            i := i + 1
            continue
        }

        gid := 0
        try {
            gid := OM_Get(g, "Id", 0)
        } catch {
            gid := 0
        }
        if (gid <= 0) {
            nid := 0
            try {
                nid := ID_Next()
            } catch {
                nid := 0
            }
            if (nid > 0) {
                setOk := false
                try {
                    g["Id"] := nid
                    setOk := true
                } catch {
                    setOk := false
                }
                if (!setOk) {
                    try {
                        g.Id := nid
                    } catch {
                    }
                }
                gid := nid
                newIds := newIds + 1
            }
        }

        if (order = "") {
            order := "" gid
        } else {
            order := order "," gid
        }

        i := i + 1
    }
    IniWrite(order, tmp, "Gates", "Order")
    if (dbgStore) {
        f0 := Map()
        try {
            f0["profile"] := name
            f0["order"] := order
            f0["count"] := count
            f0["newIds"] := newIds
            Logger_Debug("Storage", "SaveModule_Gates order", f0)
        } catch {
        }
    }

    ; 写每条 Gate
    i := 1
    while (i <= count) {
        g := 0
        try {
            g := gates[i]
        } catch {
            g := 0
        }
        if !IsObject(g) {
            i := i + 1
            continue
        }

        gid := 0
        try {
            gid := OM_Get(g, "Id", 0)
        } catch {
            gid := 0
        }
        if (gid <= 0) {
            i := i + 1
            continue
        }

        ; 统计无效引用
        if (dbgStore) {
            bad := 0
            ccnt := 0
            try {
                if (g.Has("Conds") && IsObject(g["Conds"])) {
                    ccnt := g["Conds"].Length
                } else {
                    ccnt := 0
                }
            } catch {
                ccnt := 0
            }
            j := 1
            while (j <= ccnt) {
                c0 := g["Conds"][j]
                kind := ""
                try {
                    kind := OM_Get(c0, "Kind", "PixelReady")
                } catch {
                    kind := "PixelReady"
                }
                kU := ""
                try {
                    kU := StrUpper(kind)
                } catch {
                    kU := "PIXELREADY"
                }
                if (kU = "PIXELREADY") {
                    refId := 0
                    try {
                        refId := OM_Get(c0, "RefId", 0)
                    } catch {
                        refId := 0
                    }
                    if (refId <= 0) {
                        bad := bad + 1
                    }
                    rId := 0
                    try {
                        rId := OM_Get(c0, "RuleId", 0)
                    } catch {
                        rId := 0
                    }
                    if (rId < 0) {
                        bad := bad + 1
                    }
                } else if (kU = "RULEQUIET") {
                    rId2 := 0
                    try {
                        rId2 := OM_Get(c0, "RuleId", 0)
                    } catch {
                        rId2 := 0
                    }
                    if (rId2 <= 0) {
                        bad := bad + 1
                    }
                } else if (kU = "COUNTER") {
                    sid := 0
                    try {
                        sid := OM_Get(c0, "SkillId", 0)
                    } catch {
                        sid := 0
                    }
                    if (sid <= 0) {
                        bad := bad + 1
                    }
                }
                j := j + 1
            }
            rec := Map()
            try {
                rec["GateId"] := gid
                rec["Priority"] := OM_Get(g, "Priority", i)
                rec["From"] := OM_Get(g, "FromTrackId", 0)
                rec["To"] := OM_Get(g, "ToTrackId", 0)
                rec["CondCount"] := ccnt
                rec["BadRefs"] := bad
                Logger_Warn("Storage", "SaveModule_Gates pre-write check", rec)
            } catch {
            }
        }

        gSec := "Gate." gid
        IniWrite(gid, tmp, gSec, "Id")
        IniWrite(OM_Get(g, "Priority", i), tmp, gSec, "Priority")
        IniWrite(OM_Get(g, "FromTrackId", 0), tmp, gSec, "FromTrackId")
        IniWrite(OM_Get(g, "ToTrackId", 0), tmp, gSec, "ToTrackId")
        IniWrite(OM_Get(g, "Logic", "AND"), tmp, gSec, "Logic")

        ; 写 Conds
        conds := []
        try {
            conds := g["Conds"]
        } catch {
            conds := []
        }
        cc := 0
        try {
            cc := conds.Length
        } catch {
            cc := 0
        }
        IniWrite(cc, tmp, gSec, "CondCount")

        j := 1
        while (j <= cc) {
            c := conds[j]
            cSec := "Gate." gid ".Cond." j

            kind := "PixelReady"
            try {
                kind := OM_Get(c, "Kind", "PixelReady")
            } catch {
                kind := "PixelReady"
            }
            IniWrite(kind, tmp, cSec, "Kind")

            kU := ""
            try {
                kU := StrUpper(kind)
            } catch {
                kU := "PIXELREADY"
            }

            if (kU = "PIXELREADY") {
                IniWrite(OM_Get(c, "RefType", "Skill"), tmp, cSec, "RefType")
                IniWrite(OM_Get(c, "RefId", 0),        tmp, cSec, "RefId")
                IniWrite(OM_Get(c, "Op", "NEQ"),       tmp, cSec, "Op")
                IniWrite(OM_Get(c, "Color", "0x000000"), tmp, cSec, "Color")
                IniWrite(OM_Get(c, "Tol", 16),         tmp, cSec, "Tol")
                IniWrite(OM_Get(c, "RuleId", 0),       tmp, cSec, "RuleId")
                IniWrite(OM_Get(c, "QuietMs", 0),      tmp, cSec, "QuietMs")
                IniWrite(OM_Get(c, "Cmp", "GE"),       tmp, cSec, "Cmp")
                IniWrite(OM_Get(c, "Value", 0),        tmp, cSec, "Value")
                IniWrite(OM_Get(c, "ElapsedMs", 0),    tmp, cSec, "ElapsedMs")
            } else if (kU = "RULEQUIET") {
                IniWrite(OM_Get(c, "RuleId", 0), tmp, cSec, "RuleId")
                IniWrite(OM_Get(c, "QuietMs", 0), tmp, cSec, "QuietMs")
            } else if (kU = "COUNTER") {
                IniWrite(OM_Get(c, "SkillId", 0), tmp, cSec, "SkillId")
                IniWrite(OM_Get(c, "Cmp", "GE"),  tmp, cSec, "Cmp")
                IniWrite(OM_Get(c, "Value", 1),   tmp, cSec, "Value")
            } else if (kU = "ELAPSED") {
                IniWrite(OM_Get(c, "Cmp", "GE"),      tmp, cSec, "Cmp")
                IniWrite(OM_Get(c, "ElapsedMs", 0),   tmp, cSec, "ElapsedMs")
            } else {
                ; 兜底当作 PixelReady 的基础字段
                IniWrite(OM_Get(c, "RefType", "Skill"), tmp, cSec, "RefType")
                IniWrite(OM_Get(c, "RefId", 0),        tmp, cSec, "RefId")
                IniWrite(OM_Get(c, "Op", "NEQ"),       tmp, cSec, "Op")
                IniWrite(OM_Get(c, "Color", "0x000000"), tmp, cSec, "Color")
                IniWrite(OM_Get(c, "Tol", 16),         tmp, cSec, "Tol")
            }

            j := j + 1
        }

        i := i + 1
    }

    FS_AtomicCommit(tmp, file, true)
    try {
        Logger_Info("Storage", "SaveModule_Gates ok", Map("profile", name, "count", count, "newIds", newIds))
    } catch {
    }
    FS_Meta_Touch(profile)
    return true
}

FS_Load_Gates(profileName, profile) {
    file := FS_ModulePath(profileName, "rotation_gates")
    if !FileExist(file) {
        return
    }

    dbgLoad := 0
    try {
        if Logger_IsEnabled(50, "Storage") {
            dbgLoad := 1
        } else {
            dbgLoad := 0
        }
    } catch {
        dbgLoad := 0
    }

    order := ""
    try {
        order := IniRead(file, "Gates", "Order", "")
    } catch {
        order := ""
    }
    if (dbgLoad) {
        f0 := Map()
        try {
            f0["profile"] := profileName
            f0["order"] := order
            Logger_Debug("Storage", "FS_Load_Gates order", f0)
        } catch {
        }
    }
    if (order = "") {
        try {
            profile["Rotation"]["Gates"] := []
        } catch {
        }
        try {
            Logger_Warn("Storage", "FS_Load_Gates: empty or missing Order", Map("profile", profileName))
        } catch {
        }
        return
    }

    ids := StrSplit(order, ",")
    gates := []
    i := 1
    while (i <= ids.Length) {
        idStr := ""
        try {
            idStr := Trim(ids[i])
        } catch {
            idStr := ""
        }
        gid := 0
        try {
            gid := Integer(idStr)
        } catch {
            gid := 0
        }
        if (gid <= 0) {
            i := i + 1
            continue
        }

        gSec := "Gate." gid
        g := PM_NewGate()
        try {
            g["Id"] := gid
        } catch {
        }
        try {
            g["Priority"] := Integer(IniRead(file, gSec, "Priority", i))
        } catch {
        }
        try {
            g["FromTrackId"] := Integer(IniRead(file, gSec, "FromTrackId", 0))
        } catch {
        }
        try {
            g["ToTrackId"] := Integer(IniRead(file, gSec, "ToTrackId", 0))
        } catch {
        }
        try {
            g["Logic"] := IniRead(file, gSec, "Logic", "AND")
        } catch {
        }

        cc := 0
        try {
            cc := Integer(IniRead(file, gSec, "CondCount", 0))
        } catch {
            cc := 0
        }
        conds := []
        j := 1
        while (j <= cc) {
            cSec := "Gate." gid ".Cond." j
            kind := ""
            try {
                kind := IniRead(file, cSec, "Kind", "PixelReady")
            } catch {
                kind := "PixelReady"
            }
            kU := ""
            try {
                kU := StrUpper(kind)
            } catch {
                kU := "PIXELREADY"
            }
            c := Map()
            try {
                c["Kind"] := kU
            } catch {
            }

            if (kU = "PIXELREADY") {
                try {
                    c["RefType"] := IniRead(file, cSec, "RefType", "Skill")
                } catch {
                }
                try {
                    c["RefId"] := Integer(IniRead(file, cSec, "RefId", 0))
                } catch {
                }
                try {
                    c["Op"] := IniRead(file, cSec, "Op", "NEQ")
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
                try {
                    c["RuleId"] := Integer(IniRead(file, cSec, "RuleId", 0))
                } catch {
                }
                try {
                    c["QuietMs"] := Integer(IniRead(file, cSec, "QuietMs", 0))
                } catch {
                }
                try {
                    c["Cmp"] := IniRead(file, cSec, "Cmp", "GE")
                } catch {
                }
                try {
                    c["Value"] := Integer(IniRead(file, cSec, "Value", 0))
                } catch {
                }
                try {
                    c["ElapsedMs"] := Integer(IniRead(file, cSec, "ElapsedMs", 0))
                } catch {
                }
            } else if (kU = "RULEQUIET") {
                try {
                    c["RuleId"] := Integer(IniRead(file, cSec, "RuleId", 0))
                } catch {
                }
                try {
                    c["QuietMs"] := Integer(IniRead(file, cSec, "QuietMs", 0))
                } catch {
                }
            } else if (kU = "COUNTER") {
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
            } else if (kU = "ELAPSED") {
                try {
                    c["Cmp"] := IniRead(file, cSec, "Cmp", "GE")
                } catch {
                }
                try {
                    c["ElapsedMs"] := Integer(IniRead(file, cSec, "ElapsedMs", 0))
                } catch {
                }
            } else {
                try {
                    c["RefType"] := IniRead(file, cSec, "RefType", "Skill")
                } catch {
                }
                try {
                    c["RefId"] := Integer(IniRead(file, cSec, "RefId", 0))
                } catch {
                }
                try {
                    c["Op"] := IniRead(file, cSec, "Op", "NEQ")
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
            }

            conds.Push(c)
            j := j + 1
        }
        try {
            g["Conds"] := conds
        } catch {
        }

        gates.Push(g)
        i := i + 1
    }

    try {
        profile["Rotation"]["Gates"] := gates
    } catch {
    }
    try {
        Logger_Info("Storage", "FS_Load_Gates ok", Map("profile", profileName, "count", gates.Length))
    } catch {
    }
}
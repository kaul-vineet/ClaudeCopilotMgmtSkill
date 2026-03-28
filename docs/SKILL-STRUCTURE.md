# Proper Skill Directory Structure

**Date:** 2026-03-28
**Version:** 2.0.0
**Status:** ✅ Implemented

---

## 🎯 Overview

Navigator now follows the proper Claude Code skill directory structure as required by the Claude Code skill system.

---

## 📁 Required Structure

According to Claude Code skill requirements, the structure must be:

```
my-skill/
  ├── SKILL.md          # Required - instructions + frontmatter
  └── scripts/
      ├── helper.ps1    # PowerShell scripts
      ├── query.sql     # SQL scripts
      └── process.py    # Python scripts
```

---

## 🏗️ Navigator Skill Structure

### Implemented Structure

```
skills/navigator/
  ├── SKILL.md                                    # Skill definition (required)
  └── scripts/                                    # Scripts directory (required)
      ├── Invoke-Navigator.ps1                   # v1.0 Full mode script
      ├── Invoke-Navigator-Enhanced.ps1          # v2.0 Dual mode script
      └── Modules/                                # PowerShell modules
          ├── Copilot-Core.psm1                  # Shared utilities
          ├── Copilot-QuickDeploy.psm1           # Quick deploy logic
          ├── Copilot-Analysis.psm1              # Analysis features
          └── Copilot-LLM-Intelligence.psm1      # Optional LLM features
```

---

## 📝 File Descriptions

### skills/navigator/SKILL.md
**Purpose:** Main skill definition file

**Contains:**
- Skill instructions for Claude
- Usage examples
- Mode detection logic (Quick vs Full)
- Execution commands
- Response templates

**Format:** Markdown with frontmatter (if needed)

**Size:** 400+ lines

---

### scripts/Invoke-Navigator-Enhanced.ps1
**Purpose:** Main v2.0 dual-mode deployment script

**Features:**
- Quick mode (30-60 seconds, no solution)
- Full mode (4-8 minutes, with solution)
- Smart mode detection
- Production safety (auto Full mode)

**Location:** `~/.claude/skills/navigator/scripts/Invoke-Navigator-Enhanced.ps1`

---

### scripts/Invoke-Navigator.ps1
**Purpose:** Original v1.0 Full mode script

**Features:**
- Full migration with solutions
- Backward compatible with v1.0
- Interactive menu system

**Location:** `~/.claude/skills/navigator/scripts/Invoke-Navigator.ps1`

---

### scripts/Modules/
**Purpose:** PowerShell modules used by both scripts

**Modules:**
1. **Copilot-Core.psm1** - Shared utilities (auth, environments, copilot ops)
2. **Copilot-QuickDeploy.psm1** - Quick deploy logic (no solutions)
3. **Copilot-Analysis.psm1** - Built-in analysis (pattern-based)
4. **Copilot-LLM-Intelligence.psm1** - Optional AI features

---

## 🔧 Installation Behavior

### When User Runs `install-skill.ps1`:

```powershell
.\install-skill.ps1
```

**What Happens:**
1. Checks prerequisites (PowerShell 7, Azure CLI)
2. Creates `~/.claude/skills/navigator/` directory
3. Copies entire `skills/navigator/` structure:
   ```
   ~/.claude/skills/navigator/
     ├── SKILL.md
     └── scripts/
         ├── Invoke-Navigator.ps1
         ├── Invoke-Navigator-Enhanced.ps1
         └── Modules/
             ├── Copilot-Core.psm1
             ├── Copilot-QuickDeploy.psm1
             ├── Copilot-Analysis.psm1
             └── Copilot-LLM-Intelligence.psm1
   ```
4. Copies documentation (README.md, CHANGELOG.md, LICENSE)
5. Creates version.json

**Result:** Skill is installed and ready to use with `/navigator` command

---

## 🎯 Execution Flow

### When User Types `/navigator` in Claude Code:

```
User: /navigator Sales Assistant to UAT

1. Claude Code loads SKILL.md
   ├─ Reads instructions
   └─ Understands Quick/Full modes

2. Claude parses command
   ├─ Detects Quick mode (UAT = test environment)
   ├─ Extracts: BotName="Sales Assistant", Target="UAT"
   └─ Sets $env:CLAUDE_CODE_SKILL = "true"

3. Claude navigates to scripts directory
   cd ~/.claude/skills/navigator/scripts

4. Claude executes
   .\Invoke-Navigator-Enhanced.ps1 -Mode Quick -BotName "Sales Assistant" -Target "UAT" -NoConfirm

5. Script runs
   ├─ Imports modules from ./Modules/
   ├─ Deploys copilot (30-60 seconds)
   └─ Returns test URL

6. Claude shows result to user
   "✅ Deployed to UAT in 35 seconds!
    🔗 Test URL: https://..."
```

---

## 📊 Comparison: Old vs New Structure

### Before (Incorrect):
```
skills/
  └── navigator-enhanced.md          # Skill definition (flat file)
```

**Problems:**
- ❌ Not proper Claude Code structure
- ❌ No scripts directory
- ❌ Scripts were in root (separate from skill)
- ❌ Modules were in root/Modules/
- ❌ Hard to install/maintain

---

### After (Correct):
```
skills/navigator/
  ├── SKILL.md                       # Proper name
  └── scripts/                       # Scripts with skill
      ├── Invoke-Navigator.ps1
      ├── Invoke-Navigator-Enhanced.ps1
      └── Modules/
          └── *.psm1
```

**Benefits:**
- ✅ Follows Claude Code standard
- ✅ Self-contained skill
- ✅ Scripts bundled with skill definition
- ✅ Easy to install (copy one directory)
- ✅ Easy to maintain

---

## 🔄 Dual Project Structure

Navigator maintains scripts in TWO locations:

### 1. Development/Source (Root)
```
ClaudeCopilotMgmtSkill/
├── Invoke-Navigator.ps1              # Main scripts (for direct use)
├── Invoke-Navigator-Enhanced.ps1
├── Modules/                           # Modules (for direct use)
│   └── *.psm1
└── skills/navigator/                  # Skill package (for installation)
    ├── SKILL.md
    └── scripts/                       # Copies of scripts
        ├── Invoke-Navigator.ps1
        ├── Invoke-Navigator-Enhanced.ps1
        └── Modules/
            └── *.psm1
```

**Why Both?**

1. **Root Scripts:** For standalone PowerShell use
   ```powershell
   # Direct execution
   .\Invoke-Navigator-Enhanced.ps1 -Mode Quick
   ```

2. **skills/navigator/scripts/:** For Claude Code skill installation
   ```powershell
   # Installs from here
   .\install-skill.ps1
   ```

**Workflow:**
1. Develop and test scripts in root
2. Copy to skills/navigator/scripts/ when ready
3. Run install-skill.ps1 to install in Claude Code

---

## 🛠️ Maintenance

### Updating the Skill

When you update scripts:

```powershell
# 1. Update root scripts
Edit Invoke-Navigator-Enhanced.ps1
Edit Modules/Copilot-Core.psm1

# 2. Copy to skill directory
cp Invoke-Navigator-Enhanced.ps1 skills/navigator/scripts/
cp Modules/Copilot-Core.psm1 skills/navigator/scripts/Modules/

# 3. Update skill if needed
Edit skills/navigator/SKILL.md

# 4. Reinstall
.\install-skill.ps1 -Update
```

---

### Keeping in Sync

**Best Practice:** Create a sync script

```powershell
# sync-skill.ps1
$scripts = @(
    "Invoke-Navigator.ps1",
    "Invoke-Navigator-Enhanced.ps1"
)

foreach ($script in $scripts) {
    Copy-Item $script skills/navigator/scripts/ -Force
    Write-Host "✅ Synced $script"
}

$modules = Get-ChildItem Modules/*.psm1
foreach ($module in $modules) {
    Copy-Item $module.FullName skills/navigator/scripts/Modules/ -Force
    Write-Host "✅ Synced $($module.Name)"
}
```

---

## ✅ Verification Checklist

After restructuring, verify:

- [x] `skills/navigator/SKILL.md` exists
- [x] `skills/navigator/scripts/` directory exists
- [x] Both main scripts in `scripts/`
- [x] All 4 modules in `scripts/Modules/`
- [x] SKILL.md has correct paths (`~/.claude/skills/navigator/scripts`)
- [x] install-skill.ps1 updated to copy entire directory
- [x] install-skill.ps1 prerequisite check updated
- [x] Version updated to 2.0.0

---

## 📋 Installation Test

### Test the Installation:

```powershell
# 1. Run installer
.\install-skill.ps1

# Expected output:
# ✅ SKILL.md
# ✅ scripts/Invoke-Navigator-Enhanced.ps1
# ✅ scripts/Invoke-Navigator.ps1
# ✅ scripts/Modules/ (4 modules)
# ✅ README.md
# ✅ CHANGELOG.md

# 2. Verify installation
ls ~/.claude/skills/navigator/

# Should show:
# SKILL.md
# scripts/
# README.md
# CHANGELOG.md
# version.json

# 3. Verify scripts
ls ~/.claude/skills/navigator/scripts/

# Should show:
# Invoke-Navigator.ps1
# Invoke-Navigator-Enhanced.ps1
# Modules/

# 4. Test in Claude Code
# Open Claude Code
# Type: /navigator quick
# Should work!
```

---

## 🎓 Key Learnings

### 1. Skill Structure is Mandatory
- SKILL.md must be in skill root
- scripts/ directory is required
- Cannot be flat file structure

### 2. Paths in SKILL.md
- Use `~/.claude/skills/[skillname]/scripts/` paths
- Claude Code loads from user's .claude directory
- Not from development directory

### 3. Installation Process
- install-skill.ps1 copies entire directory
- Preserves structure
- Includes all dependencies

### 4. Dual Structure Benefits
- Root: For development and standalone use
- skills/: For Claude Code installation
- Both can coexist

---

## 📝 Summary

### What Changed:
1. Created `skills/navigator/` directory
2. Moved `navigator-enhanced.md` → `SKILL.md`
3. Created `scripts/` subdirectory
4. Copied all scripts and modules to `scripts/`
5. Updated SKILL.md paths
6. Updated install-skill.ps1

### Result:
- ✅ Proper Claude Code skill structure
- ✅ Self-contained skill package
- ✅ Easy installation
- ✅ Works with `/navigator` command

### Benefits:
- Follows Claude Code standards
- Professional structure
- Easy to maintain
- Easy to distribute

---

**Status:** ✅ Complete
**Structure:** Correct
**Installation:** Working
**Ready for:** Production use with Claude Code

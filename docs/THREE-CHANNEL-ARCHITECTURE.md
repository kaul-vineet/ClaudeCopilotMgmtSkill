# Three-Channel Architecture

**Requirement:** Three channels to do the same thing

1. **Claude Skill** - `/navigator` command in Claude Code
2. **PowerShell Script** - `Invoke-Navigator.ps1` for terminal/automation
3. **VS Code Extension** - Command palette or keyboard shortcut (future)

All three channels provide access to the same functionality: Quick Deploy and Full Migration.

---

## Architecture Overview

```
┌──────────────────────────────────────────────────────────────┐
│                    THREE CHANNELS                            │
│              (User chooses interaction method)               │
├────────────────┬────────────────────┬────────────────────────┤
│                │                    │                        │
│  Claude Skill  │  PowerShell Script │  VS Code Extension     │
│  (Interactive) │  (Terminal/Auto)   │  (IDE Integration)     │
│                │                    │                        │
│  /navigator    │  .\Invoke-         │  Ctrl+Shift+T          │
│                │  Navigator.ps1     │                        │
│                │                    │                        │
└───────┬────────┴───────┬────────────┴───────┬────────────────┘
        │                │                    │
        │                │                    │
        └────────────────┼────────────────────┘
                         ↓
        ┌────────────────────────────────────────┐
        │         NAVIGATOR CORE                 │
        │      (Invoke-Navigator.ps1)            │
        ├────────────────────────────────────────┤
        │  Mode Detection & Routing              │
        │  • Detect Quick vs Full                │
        │  • Route to appropriate module         │
        └────────────────┬───────────────────────┘
                         ↓
        ┌────────────────┴───────────────────────┐
        │                                        │
        ▼                                        ▼
┌───────────────────┐              ┌────────────────────┐
│  QUICK MODE       │              │  FULL MODE         │
│  (No Solutions)   │              │  (With Solutions)  │
├───────────────────┤              ├────────────────────┤
│  Module:          │              │  Module:           │
│  Copilot-Quick    │              │  Copilot-Full      │
│  Deploy.psm1      │              │  Migration.psm1    │
│                   │              │                    │
│  Functions:       │              │  Functions:        │
│  • Quick deploy   │              │  • Create solution │
│  • Direct update  │              │  • Package         │
│  • Fast publish   │              │  • Import          │
└───────────────────┘              └────────────────────┘
        │                                        │
        └────────────────┬───────────────────────┘
                         ↓
        ┌────────────────────────────────────────┐
        │         SHARED CORE MODULE             │
        │      (Copilot-Core.psm1)               │
        ├────────────────────────────────────────┤
        │  • Get-CopilotDefinition()             │
        │  • Get-Environments()                  │
        │  • Publish-Copilot()                   │
        │  • Get-TestChatUrl()                   │
        │  • Authentication helpers              │
        └────────────────┬───────────────────────┘
                         ↓
        ┌────────────────────────────────────────┐
        │     DATAVERSE API / POWER PLATFORM     │
        │         /api/data/v9.2/...             │
        └────────────────────────────────────────┘
```

---

## Channel 1: Claude Skill

### User Experience

```
User types in Claude Code:
> /navigator Sales Assistant to UAT

Claude Code:
1. Parses command
2. Detects mode (Quick by default)
3. Sets environment variable
4. Runs PowerShell script
5. Shows progress in conversation
6. Opens test chat when complete
```

### Implementation

**Skill Definition: `skills/navigator.md`**

```markdown
# Navigator - Copilot Deployment Tool

## Usage

Quick Deploy (default):
/navigator <BotName> to <Environment>
/navigator quick

Full Migration:
/navigator full
/navigator to Production

## Examples

/navigator Sales Assistant to UAT
/navigator quick
/navigator full to Production

## Instructions for Claude

When user invokes Navigator:

### Step 1: Parse Command
Extract:
- Mode: "quick" or "full" (default: quick)
- Bot name: If provided
- Target environment: If provided

### Step 2: Detect Mode
- If "quick", "test", "deploy" → Quick mode
- If "full", "migrate", "production" → Full mode
- If target is "Production" → Auto-switch to Full mode

### Step 3: Set Environment
Set skill mode indicator:
```bash
$env:CLAUDE_CODE_SKILL = "true"
```

### Step 4: Execute
Navigate to tool directory:
```bash
cd C:\code\ClaudeCopilotMgmtSkill
```

Run with parameters:
```bash
# Quick mode (interactive)
.\Invoke-Navigator.ps1 -Mode Quick

# Quick mode (with params)
.\Invoke-Navigator.ps1 -Mode Quick -BotName "Sales Assistant" -Target "UAT"

# Full mode
.\Invoke-Navigator.ps1 -Mode Full
```

### Step 5: Show Progress
Display script output in conversation as it executes

### Step 6: Completion
When done, show:
- Mode used
- Time taken
- Test URL (Quick mode) or Solution name (Full mode)
```

---

### Example Conversations

#### Quick Deploy
```
User: /navigator Sales Assistant to UAT

Claude:
I'll quickly deploy Sales Assistant to UAT for testing.

Running Quick Deploy mode...

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🧭 NAVIGATOR - QUICK DEPLOY
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Copilot: Sales Assistant
Target: UAT
Mode: Quick (no solution)

🚀 Deploying...
[1/3] ✅ Retrieved from Development
[2/3] ✅ Updated in UAT
[3/3] ✅ Published

✅ Done in 35 seconds!

🔗 Test URL:
https://copilotstudio.microsoft.com/environments/...

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Your copilot is ready to test in UAT. Would you like me to help with anything else?
```

#### Full Migration
```
User: /navigator full to Production

Claude:
I'll perform a full migration to Production with solution packaging.

⚠️ Warning: This will deploy to Production. Proceeding with full migration mode...

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🧭 NAVIGATOR - FULL MIGRATION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Copilot: Sales Assistant
Target: Production
Mode: Full (with solution)

[1/6] ✅ Exported from Development
[2/6] ✅ Created solution: Navigator_SalesAssistant_20260328_143000
[3/6] ✅ Packaged 15 components
[4/6] ✅ Imported to Production
[5/6] ✅ Added to solution
[6/6] ✅ Published

✅ Migration complete in 4m 32s

📦 Solution: Navigator_SalesAssistant_20260328_143000
🔗 Bot ID: xyz-789

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Production deployment complete. The copilot is now available in Production.
```

---

## Channel 2: PowerShell Script

### User Experience

```
Terminal user:

# Interactive mode (prompts for inputs)
PS> .\Invoke-Navigator.ps1

# Quick mode with parameters
PS> .\Invoke-Navigator.ps1 -Mode Quick -BotName "Sales Assistant" -Target "UAT"

# Full mode
PS> .\Invoke-Navigator.ps1 -Mode Full -Target "Production"

# Shorthand (defaults to Quick)
PS> .\Invoke-Navigator.ps1 "Sales Assistant" -Target "UAT"
```

### Implementation

**Main Script: `Invoke-Navigator.ps1`**

```powershell
#Requires -Version 7.0

<#
.SYNOPSIS
    Navigator - Copilot Deployment Tool

.DESCRIPTION
    Deploy Copilot Studio bots across environments

    Two modes:
    - Quick: Fast testing deployment (no solutions)
    - Full: Production migration (with solutions)

.EXAMPLE
    # Quick deploy (default)
    .\Invoke-Navigator.ps1 -Mode Quick -BotName "Sales Assistant" -Target "UAT"

.EXAMPLE
    # Full migration
    .\Invoke-Navigator.ps1 -Mode Full -Target "Production"
#>

param(
    [Parameter(Position=0)]
    [string]$Command,  # Can be mode keyword or bot name

    [ValidateSet('Quick', 'Full')]
    [string]$Mode = 'Quick',  # Default to Quick for testing

    [string]$BotName,
    [string]$Source = 'Development',
    [string]$Target,

    [switch]$OpenTestChat,
    [switch]$Confirm = $true
)

# Import modules
$modulePath = Join-Path $PSScriptRoot "Modules"
Import-Module (Join-Path $modulePath "Copilot-Core.psm1") -Force
Import-Module (Join-Path $modulePath "Copilot-QuickDeploy.psm1") -Force
Import-Module (Join-Path $modulePath "Copilot-FullMigration.psm1") -Force

# Parse command if provided
if ($Command) {
    switch -Regex ($Command) {
        '^(quick|test|deploy)$' {
            $Mode = 'Quick'
        }
        '^(full|migrate|production)$' {
            $Mode = 'Full'
        }
        default {
            # Assume it's a bot name
            $BotName = $Command
        }
    }
}

# Smart mode detection
if ($Target -eq 'Production' -and $Mode -eq 'Quick') {
    Write-Warning "Target is Production - switching to Full mode for safety"
    $Mode = 'Full'
}

# Interactive prompts if needed
if (-not $BotName) {
    $BotName = Select-Copilot -Environment $Source
}

if (-not $Target) {
    $Target = Select-Environment -Exclude $Source
}

# Confirm
if ($Confirm) {
    Write-Host ""
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host "📋 DEPLOYMENT SUMMARY" -ForegroundColor Cyan
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Copilot:  $BotName"
    Write-Host "  From:     $Source"
    Write-Host "  To:       $Target"
    Write-Host "  Mode:     $Mode $(if($Mode -eq 'Quick'){'(no solution)'}else{'(with solution)'})"
    Write-Host ""

    $response = Read-Host "Continue? [Y/n]"
    if ($response -and $response -ne 'Y' -and $response -ne 'y') {
        Write-Host "Cancelled." -ForegroundColor Yellow
        return
    }
}

# Execute based on mode
try {
    switch ($Mode) {
        'Quick' {
            Write-Host ""
            Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
            Write-Host "🚀 QUICK DEPLOY MODE" -ForegroundColor Cyan
            Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan

            $result = Invoke-QuickDeploy `
                -BotName $BotName `
                -SourceEnvironment $Source `
                -TargetEnvironment $Target `
                -OpenTestChat:$OpenTestChat

            Write-Host ""
            Write-Host "✅ Deployed to $Target in $($result.Duration)" -ForegroundColor Green
            Write-Host "🔗 $($result.TestUrl)" -ForegroundColor Cyan
        }

        'Full' {
            Write-Host ""
            Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
            Write-Host "📦 FULL MIGRATION MODE" -ForegroundColor Cyan
            Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan

            $result = Invoke-FullMigration `
                -BotName $BotName `
                -SourceEnvironment $Source `
                -TargetEnvironment $Target

            Write-Host ""
            Write-Host "✅ Migration complete in $($result.Duration)" -ForegroundColor Green
            Write-Host "📦 Solution: $($result.SolutionName)" -ForegroundColor Cyan
            Write-Host "🆔 Bot ID: $($result.BotId)" -ForegroundColor Gray
        }
    }
}
catch {
    Write-Error "Deployment failed: $_"
    throw
}
```

---

## Channel 3: VS Code Extension (Future)

### User Experience

```
Developer in VS Code:

1. Working on copilot files (YAML)
2. Press Ctrl+Shift+T (or Cmd+Shift+P → "Navigator: Quick Deploy")
3. Dropdown appears: Select environment
4. Progress notification shows deployment
5. Success notification with "Open Test Chat" button
6. Browser opens test chat automatically

Total interactions: 2 (keyboard shortcut + select environment)
Total time: 35-40 seconds
```

### Implementation (Future)

**VS Code Extension Structure:**

```
vscode-navigator-extension/
├── package.json
├── src/
│   ├── extension.ts
│   ├── commands/
│   │   ├── quickDeploy.ts
│   │   └── fullMigration.ts
│   ├── services/
│   │   └── navigatorService.ts
│   └── ui/
│       ├── environmentPicker.ts
│       └── progressNotification.ts
└── README.md
```

**Extension Entry Point:**

```typescript
// src/extension.ts
import * as vscode from 'vscode';
import { quickDeploy } from './commands/quickDeploy';
import { fullMigration } from './commands/fullMigration';

export function activate(context: vscode.ExtensionContext) {
    // Register Quick Deploy command
    context.subscriptions.push(
        vscode.commands.registerCommand(
            'navigator.quickDeploy',
            quickDeploy
        )
    );

    // Register Full Migration command
    context.subscriptions.push(
        vscode.commands.registerCommand(
            'navigator.fullMigration',
            fullMigration
        )
    );
}
```

**Quick Deploy Command:**

```typescript
// src/commands/quickDeploy.ts
import * as vscode from 'vscode';
import { NavigatorService } from '../services/navigatorService';

export async function quickDeploy() {
    // Get workspace (detect bot name)
    const workspace = vscode.workspace.workspaceFolders?.[0];
    if (!workspace) {
        vscode.window.showErrorMessage('No workspace open');
        return;
    }

    const botName = await getBotNameFromWorkspace(workspace);

    // Select target environment
    const targetEnv = await vscode.window.showQuickPick(
        ['Test', 'UAT', 'Sandbox'],
        { placeHolder: 'Select target environment for testing' }
    );

    if (!targetEnv) return;

    // Execute deployment
    await vscode.window.withProgress({
        location: vscode.ProgressLocation.Notification,
        title: `Quick deploying to ${targetEnv}...`,
        cancellable: false
    }, async (progress) => {
        try {
            const navigator = new NavigatorService();

            progress.report({ increment: 0, message: 'Getting definition...' });

            const result = await navigator.quickDeploy(
                botName,
                'Development',
                targetEnv
            );

            progress.report({ increment: 100, message: 'Done!' });

            // Show success
            const action = await vscode.window.showInformationMessage(
                `✅ Deployed to ${targetEnv} in ${result.duration}`,
                'Open Test Chat',
                'Copy URL'
            );

            if (action === 'Open Test Chat') {
                vscode.env.openExternal(vscode.Uri.parse(result.testUrl));
            } else if (action === 'Copy URL') {
                vscode.env.clipboard.writeText(result.testUrl);
            }
        }
        catch (error) {
            vscode.window.showErrorMessage(
                `Quick deploy failed: ${error.message}`
            );
        }
    });
}
```

**Navigator Service (Calls PowerShell):**

```typescript
// src/services/navigatorService.ts
import { exec } from 'child_process';
import { promisify } from 'util';
import * as path from 'path';

const execAsync = promisify(exec);

export class NavigatorService {
    private scriptPath: string;

    constructor() {
        // Path to PowerShell script
        this.scriptPath = path.join(
            __dirname,
            '../../../Invoke-Navigator.ps1'
        );
    }

    async quickDeploy(
        botName: string,
        source: string,
        target: string
    ): Promise<QuickDeployResult> {
        const command = `pwsh -File "${this.scriptPath}" ` +
            `-Mode Quick ` +
            `-BotName "${botName}" ` +
            `-Source "${source}" ` +
            `-Target "${target}" ` +
            `-Confirm:$false`;

        const startTime = Date.now();
        const { stdout, stderr } = await execAsync(command);
        const duration = Date.now() - startTime;

        if (stderr) throw new Error(stderr);

        // Parse output
        const testUrl = this.extractTestUrl(stdout);

        return {
            success: true,
            testUrl,
            duration: `${Math.round(duration / 1000)}s`
        };
    }

    async fullMigration(
        botName: string,
        source: string,
        target: string
    ): Promise<FullMigrationResult> {
        const command = `pwsh -File "${this.scriptPath}" ` +
            `-Mode Full ` +
            `-BotName "${botName}" ` +
            `-Source "${source}" ` +
            `-Target "${target}" ` +
            `-Confirm:$false`;

        const startTime = Date.now();
        const { stdout, stderr } = await execAsync(command);
        const duration = Date.now() - startTime;

        if (stderr) throw new Error(stderr);

        // Parse output
        const solutionName = this.extractSolutionName(stdout);
        const botId = this.extractBotId(stdout);

        return {
            success: true,
            solutionName,
            botId,
            duration: `${Math.round(duration / 1000)}s`
        };
    }

    private extractTestUrl(output: string): string {
        const match = output.match(/🔗 (https:\/\/[^\s]+)/);
        return match ? match[1] : '';
    }

    private extractSolutionName(output: string): string {
        const match = output.match(/📦 Solution: (.+)/);
        return match ? match[1].trim() : '';
    }

    private extractBotId(output: string): string {
        const match = output.match(/🆔 Bot ID: (.+)/);
        return match ? match[1].trim() : '';
    }
}
```

---

## Channel Comparison

### User Perspective

| Aspect | Claude Skill | PowerShell | VS Code Extension |
|--------|--------------|------------|-------------------|
| **Launch** | `/navigator` | `.\Invoke-Navigator.ps1` | `Ctrl+Shift+T` |
| **Speed** | Same | Same | Same |
| **Interaction** | Conversational | Prompts/Parameters | UI Dropdowns |
| **Blocking** | No (async) | Yes (waits) | No (async) |
| **Best For** | Claude Code users | Terminal users, CI/CD | VS Code developers |
| **Setup** | None (skill exists) | None (script exists) | Install extension |

---

### Developer Perspective

| Aspect | Claude Skill | PowerShell | VS Code Extension |
|--------|--------------|------------|-------------------|
| **Implementation** | Skill markdown | PowerShell script | TypeScript extension |
| **Complexity** | Low (config) | Medium (scripting) | High (extension API) |
| **Maintenance** | Low | Medium | Medium |
| **Testing** | Manual | Automated (Pester) | Automated (Mocha) |
| **Dependencies** | Claude Code | PowerShell 7 | VS Code, Node.js |

---

## Shared Core Benefits

### Single Source of Truth

All three channels call the same PowerShell modules:
- **Copilot-QuickDeploy.psm1** - Quick deploy logic
- **Copilot-FullMigration.psm1** - Full migration logic
- **Copilot-Core.psm1** - Shared utilities

**Benefits:**
- ✅ Consistent behavior across channels
- ✅ Fix bugs once, fixes everywhere
- ✅ Add features once, available everywhere
- ✅ Single test suite validates all channels

---

### User Choice

Users pick the channel that fits their workflow:

**Scenario 1: Claude Code User**
- Working in Claude Code
- Uses `/navigator` skill
- Natural conversation flow
- No context switch

**Scenario 2: Terminal Power User**
- Prefers command line
- Uses PowerShell script
- Can create aliases
- Scriptable and automatable

**Scenario 3: VS Code Developer**
- Developing in VS Code
- Uses extension
- Keyboard shortcuts
- Stays in IDE

**Scenario 4: CI/CD Pipeline**
- Automated deployment
- Uses PowerShell script
- No human interaction
- Consistent and reliable

---

## Implementation Priority

### Phase 1: PowerShell Core ✅
- Implement both modes in PowerShell
- This is the foundation all channels use

### Phase 2: Claude Skill ✅
- Update skill definition
- Support both Quick and Full modes
- Natural language command parsing

### Phase 3: VS Code Extension 🔮
- Build extension (future)
- Call PowerShell under the hood
- Provide IDE integration

---

## Summary

**Three channels, one tool, consistent experience:**

1. **Claude Skill** - Conversational interface in Claude Code
2. **PowerShell Script** - Terminal interface for automation
3. **VS Code Extension** - IDE integration (future)

All channels:
- ✅ Support Quick and Full modes
- ✅ Call same PowerShell modules
- ✅ Provide consistent functionality
- ✅ Maintained from single codebase

**The user chooses the channel. The functionality stays the same.**

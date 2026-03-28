# Implementation Guide: Enhanced Navigator

**Objective:** Integrate Quick Deploy functionality into Navigator with dual-mode support

---

## Overview

### Current State
- Navigator v1.0: Full migration with solutions only
- Time: 5-10 minutes
- Focus: Production deployments

### Target State
- Navigator v2.0: Dual-mode (Quick + Full)
- Quick Mode: 30-60 seconds, no solutions
- Full Mode: 4-8 minutes, with solutions
- Three channels: Claude Skill, PowerShell, VS Code (future)

---

## Implementation Steps

### Phase 1: Refactor Current Code ✅

#### Step 1.1: Create Module Structure

```
Modules/
├── Copilot-Core.psm1           # Shared utilities (NEW)
├── Copilot-QuickDeploy.psm1    # Quick deploy logic (NEW)
├── Copilot-FullMigration.psm1  # Full migration logic (REFACTORED)
└── Copilot-LLM-Intelligence.psm1  # AI features (EXISTING)
```

#### Step 1.2: Extract Shared Functions

Move common functions from `Invoke-Navigator.ps1` to `Copilot-Core.psm1`:

```powershell
# Copilot-Core.psm1
function Get-EnvironmentUrl { }
function Get-AuthHeaders { }
function Get-CopilotDefinition { }
function Get-Environments { }
function Select-Copilot { }
function Select-Environment { }
function Publish-Copilot { }
function Get-TestChatUrl { }
```

#### Step 1.3: Refactor Full Migration

Move solution-based migration logic to `Copilot-FullMigration.psm1`:

```powershell
# Copilot-FullMigration.psm1
function Invoke-FullMigration { }
function New-NavigatorSolution { }
function Add-BotToSolution { }
function Export-BotData { }
function Import-BotWithSolution { }
```

---

### Phase 2: Implement Quick Deploy 🔨

#### Step 2.1: Create Quick Deploy Module

```powershell
# Modules/Copilot-QuickDeploy.psm1

#Requires -Version 7.0

<#
.SYNOPSIS
    Quick deploy module for rapid testing

.DESCRIPTION
    Deploys copilots directly to target environment without solutions
    Fast, simple, ideal for testing and iteration
#>

function Invoke-QuickDeploy {
    <#
    .SYNOPSIS
        Quick deploy copilot to test environment (no solution)
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$BotName,

        [Parameter(Mandatory=$false)]
        [string]$SourceEnvironment = "Development",

        [Parameter(Mandatory=$true)]
        [string]$TargetEnvironment,

        [switch]$OpenTestChat
    )

    $startTime = Get-Date

    try {
        # Import dependencies
        Import-Module "$PSScriptRoot\Copilot-Core.psm1" -Force

        # Step 1: Get copilot from source
        Write-Progress "[1/3]" "Getting copilot from $SourceEnvironment..."
        $copilotDef = Get-CopilotDefinition -Name $BotName -Environment $SourceEnvironment

        # Step 2: Deploy directly (NO SOLUTION)
        Write-Progress "[2/3]" "Deploying to $TargetEnvironment..."
        $result = Deploy-CopilotDirect `
            -Definition $copilotDef `
            -TargetEnvironment $TargetEnvironment `
            -Overwrite

        # Step 3: Publish
        Write-Progress "[3/3]" "Publishing..."
        Publish-Copilot -BotId $result.BotId -Environment $TargetEnvironment

        $duration = (Get-Date) - $startTime
        $testUrl = Get-TestChatUrl -BotId $result.BotId -Environment $TargetEnvironment

        if ($OpenTestChat) {
            Start-Process $testUrl
        }

        return @{
            Success = $true
            BotId = $result.BotId
            Action = $result.Action  # "Created" or "Updated"
            TestUrl = $testUrl
            Duration = "$([Math]::Round($duration.TotalSeconds))s"
        }
    }
    catch {
        Write-Error "Quick deploy failed: $_"
        throw
    }
}

function Deploy-CopilotDirect {
    <#
    .SYNOPSIS
        Deploy copilot directly without solution packaging
    #>
    param(
        [Parameter(Mandatory=$true)]
        [object]$Definition,

        [Parameter(Mandatory=$true)]
        [string]$TargetEnvironment,

        [switch]$Overwrite
    )

    $targetUrl = Get-EnvironmentUrl -Environment $TargetEnvironment
    $headers = Get-AuthHeaders

    # Check if copilot exists
    $existing = Find-Copilot -Name $Definition.name -Environment $TargetEnvironment

    if ($existing -and $Overwrite) {
        # Update existing copilot
        Write-Verbose "Updating existing copilot: $($existing.botid)"

        Update-CopilotInPlace `
            -BotId $existing.botid `
            -Definition $Definition `
            -Environment $TargetEnvironment

        return @{
            BotId = $existing.botid
            Action = "Updated"
        }
    }
    elseif ($existing) {
        throw "Copilot '$($Definition.name)' already exists in $TargetEnvironment. Use -Overwrite to replace."
    }
    else {
        # Create new copilot
        Write-Verbose "Creating new copilot"

        $newBot = New-CopilotDirect `
            -Definition $Definition `
            -Environment $TargetEnvironment

        return @{
            BotId = $newBot.botid
            Action = "Created"
        }
    }
}

function Find-Copilot {
    param($Name, $Environment)

    $envUrl = Get-EnvironmentUrl -Environment $Environment
    $headers = Get-AuthHeaders

    $uri = "$envUrl/api/data/v9.2/bots?\`$filter=name eq '$Name'"
    $response = Invoke-RestMethod -Uri $uri -Headers $headers -Method Get

    return $response.value | Select-Object -First 1
}

function Update-CopilotInPlace {
    param($BotId, $Definition, $Environment)

    $envUrl = Get-EnvironmentUrl -Environment $Environment
    $headers = Get-AuthHeaders

    # Clean definition (remove system fields)
    $botData = $Definition | ConvertTo-Json -Depth 10 | ConvertFrom-Json
    $systemFields = @(
        'botid', 'createdon', 'modifiedon', '_createdby_value', '_modifiedby_value',
        '_ownerid_value', 'ownerid', 'owningbusinessunit', '_owningbusinessunit_value',
        'versionnumber', 'overriddencreatedon', 'solutionid'
    )

    foreach ($field in $systemFields) {
        $botData.PSObject.Properties.Remove($field)
    }

    # Update bot
    $uri = "$envUrl/api/data/v9.2/bots($BotId)"
    Invoke-RestMethod -Uri $uri -Method Patch -Headers $headers -Body ($botData | ConvertTo-Json -Depth 10)

    # Update components
    Update-BotComponents -BotId $BotId -Components $Definition.Components -Environment $Environment
}

function New-CopilotDirect {
    param($Definition, $Environment)

    $envUrl = Get-EnvironmentUrl -Environment $Environment
    $headers = Get-AuthHeaders

    # Clean definition
    $botData = $Definition | ConvertTo-Json -Depth 10 | ConvertFrom-Json
    $systemFields = @(
        'botid', 'createdon', 'modifiedon', '_createdby_value', '_modifiedby_value',
        '_ownerid_value', 'ownerid', 'owningbusinessunit', '_owningbusinessunit_value',
        'versionnumber', 'overriddencreatedon', 'solutionid'
    )

    foreach ($field in $systemFields) {
        $botData.PSObject.Properties.Remove($field)
    }

    # Create bot
    $uri = "$envUrl/api/data/v9.2/bots"
    $newBot = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body ($botData | ConvertTo-Json -Depth 10)

    # Create components
    if ($Definition.Components) {
        New-BotComponents -BotId $newBot.botid -Components $Definition.Components -Environment $Environment
    }

    return $newBot
}

function Update-BotComponents {
    param($BotId, $Components, $Environment)

    $envUrl = Get-EnvironmentUrl -Environment $Environment
    $headers = Get-AuthHeaders

    # Get all component types
    $allComponents = @()
    if ($Components.Topics) { $allComponents += $Components.Topics }
    if ($Components.Triggers) { $allComponents += $Components.Triggers }
    if ($Components.Skills) { $allComponents += $Components.Skills }

    foreach ($component in $allComponents) {
        # Check if component exists
        $uri = "$envUrl/api/data/v9.2/botcomponents?\`$filter=_parentbotid_value eq $BotId and name eq '$($component.name)'"
        $existing = (Invoke-RestMethod -Uri $uri -Headers $headers -Method Get).value | Select-Object -First 1

        # Clean component data
        $compData = $component | ConvertTo-Json -Depth 10 | ConvertFrom-Json
        $systemFields = @('botcomponentid', 'createdon', 'modifiedon', '_parentbotid_value', 'parentbotid', 'versionnumber')
        foreach ($field in $systemFields) {
            $compData.PSObject.Properties.Remove($field)
        }
        $compData | Add-Member -Name "parentbotid@odata.bind" -Value "/bots($BotId)" -MemberType NoteProperty -Force

        if ($existing) {
            # Update existing component
            $uri = "$envUrl/api/data/v9.2/botcomponents($($existing.botcomponentid))"
            Invoke-RestMethod -Uri $uri -Method Patch -Headers $headers -Body ($compData | ConvertTo-Json -Depth 10)
        }
        else {
            # Create new component
            $uri = "$envUrl/api/data/v9.2/botcomponents"
            Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body ($compData | ConvertTo-Json -Depth 10)
        }
    }
}

function New-BotComponents {
    param($BotId, $Components, $Environment)

    $envUrl = Get-EnvironmentUrl -Environment $Environment
    $headers = Get-AuthHeaders

    # Get all component types
    $allComponents = @()
    if ($Components.Topics) { $allComponents += $Components.Topics }
    if ($Components.Triggers) { $allComponents += $Components.Triggers }
    if ($Components.Skills) { $allComponents += $Components.Skills }

    foreach ($component in $allComponents) {
        # Clean component data
        $compData = $component | ConvertTo-Json -Depth 10 | ConvertFrom-Json
        $systemFields = @('botcomponentid', 'createdon', 'modifiedon', '_parentbotid_value', 'parentbotid', 'versionnumber')
        foreach ($field in $systemFields) {
            $compData.PSObject.Properties.Remove($field)
        }
        $compData | Add-Member -Name "parentbotid@odata.bind" -Value "/bots($BotId)" -MemberType NoteProperty -Force

        # Create component
        $uri = "$envUrl/api/data/v9.2/botcomponents"
        Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body ($compData | ConvertTo-Json -Depth 10)
    }
}

function Write-Progress {
    param($Step, $Message)

    Write-Host "$Step " -NoNewline -ForegroundColor Cyan
    Write-Host $Message -ForegroundColor White
}

# Export functions
Export-ModuleMember -Function @(
    'Invoke-QuickDeploy'
    'Deploy-CopilotDirect'
)
```

---

### Phase 3: Update Main Script 🔨

#### Step 3.1: Enhanced Invoke-Navigator.ps1

```powershell
#Requires -Version 7.0

<#
.SYNOPSIS
    Navigator - Copilot Deployment Tool v2.0

.DESCRIPTION
    Deploy Copilot Studio bots across environments with two modes:

    Quick Mode (default):
    - Fast testing deployment
    - No solution packaging
    - 30-60 seconds
    - Update in place

    Full Mode:
    - Production deployment
    - Solution packaging
    - 4-8 minutes
    - Audit trail

.PARAMETER Mode
    Quick or Full (default: Quick)

.PARAMETER BotName
    Name of copilot to deploy

.PARAMETER Source
    Source environment (default: Development)

.PARAMETER Target
    Target environment

.PARAMETER OpenTestChat
    Open test chat in browser after deployment

.EXAMPLE
    # Quick deploy (default)
    .\Invoke-Navigator.ps1 -BotName "Sales Assistant" -Target "UAT"

.EXAMPLE
    # Full migration
    .\Invoke-Navigator.ps1 -Mode Full -Target "Production"

.EXAMPLE
    # Quick deploy with shorthand
    .\Invoke-Navigator.ps1 quick -BotName "Sales Assistant" -Target "UAT"
#>

param(
    [Parameter(Position=0)]
    [string]$Command,  # Can be: "quick", "full", or bot name

    [ValidateSet('Quick', 'Full')]
    [string]$Mode = 'Quick',

    [string]$BotName,
    [string]$Source = 'Development',
    [string]$Target,

    [switch]$OpenTestChat,
    [switch]$Confirm = $true
)

# Banner
Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "🧭 NAVIGATOR v2.0 - Copilot Deployment Tool" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host ""

# Import modules
$modulePath = Join-Path $PSScriptRoot "Modules"
Import-Module (Join-Path $modulePath "Copilot-Core.psm1") -Force
Import-Module (Join-Path $modulePath "Copilot-QuickDeploy.psm1") -Force
Import-Module (Join-Path $modulePath "Copilot-FullMigration.psm1") -Force

# Parse command
if ($Command) {
    switch -Regex ($Command) {
        '^(quick|test|deploy)$' {
            $Mode = 'Quick'
            Write-Verbose "Mode set to Quick via command: $Command"
        }
        '^(full|migrate|production)$' {
            $Mode = 'Full'
            Write-Verbose "Mode set to Full via command: $Command"
        }
        default {
            # Assume it's a bot name
            $BotName = $Command
            Write-Verbose "Bot name set via command: $BotName"
        }
    }
}

# Smart mode detection
if ($Target -eq 'Production' -and $Mode -eq 'Quick') {
    Write-Warning "🔒 Target is Production - switching to Full mode for safety"
    $Mode = 'Full'
}

# Interactive selection if needed
if (-not $BotName) {
    $BotName = Select-Copilot -Environment $Source
}

if (-not $Target) {
    $Target = Select-Environment -Exclude $Source
}

# Show summary
Write-Host "📋 Deployment Configuration:" -ForegroundColor Yellow
Write-Host "  Copilot:  $BotName"
Write-Host "  From:     $Source"
Write-Host "  To:       $Target"
Write-Host "  Mode:     $Mode " -NoNewline
if ($Mode -eq 'Quick') {
    Write-Host "(fast, no solution)" -ForegroundColor Green
} else {
    Write-Host "(comprehensive, with solution)" -ForegroundColor Cyan
}
Write-Host ""

# Confirm
if ($Confirm) {
    $response = Read-Host "Continue? [Y/n]"
    if ($response -and $response -notmatch '^[Yy]') {
        Write-Host "❌ Cancelled" -ForegroundColor Yellow
        return
    }
}

Write-Host ""

# Execute based on mode
try {
    switch ($Mode) {
        'Quick' {
            Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
            Write-Host "⚡ QUICK DEPLOY MODE" -ForegroundColor Green
            Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
            Write-Host ""

            $result = Invoke-QuickDeploy `
                -BotName $BotName `
                -SourceEnvironment $Source `
                -TargetEnvironment $Target `
                -OpenTestChat:$OpenTestChat

            Write-Host ""
            Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
            Write-Host "✅ QUICK DEPLOY COMPLETE" -ForegroundColor Green
            Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
            Write-Host ""
            Write-Host "  Time:   $($result.Duration)" -ForegroundColor White
            Write-Host "  Action: $($result.Action)" -ForegroundColor White
            Write-Host "  Bot ID: $($result.BotId)" -ForegroundColor Gray
            Write-Host ""
            Write-Host "🔗 Test URL:" -ForegroundColor Cyan
            Write-Host "  $($result.TestUrl)" -ForegroundColor White
            Write-Host ""
        }

        'Full' {
            Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Magenta
            Write-Host "📦 FULL MIGRATION MODE" -ForegroundColor Magenta
            Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Magenta
            Write-Host ""

            $result = Invoke-FullMigration `
                -BotName $BotName `
                -SourceEnvironment $Source `
                -TargetEnvironment $Target

            Write-Host ""
            Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Magenta
            Write-Host "✅ FULL MIGRATION COMPLETE" -ForegroundColor Magenta
            Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Magenta
            Write-Host ""
            Write-Host "  Time:     $($result.Duration)" -ForegroundColor White
            Write-Host "  Solution: $($result.SolutionName)" -ForegroundColor White
            Write-Host "  Bot ID:   $($result.BotId)" -ForegroundColor Gray
            Write-Host ""
        }
    }
}
catch {
    Write-Host ""
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Red
    Write-Host "❌ DEPLOYMENT FAILED" -ForegroundColor Red
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Red
    Write-Host ""
    Write-Host "Error: $_" -ForegroundColor Red
    Write-Host ""
    throw
}
```

---

### Phase 4: Update Skill Definition 🔨

#### Step 4.1: Update skills/navigator.md

```markdown
# Navigator - Copilot Deployment Tool v2.0

## Quick Reference

```bash
# Quick Deploy (default - for testing)
/navigator Sales Assistant to UAT
/navigator quick

# Full Migration (with solution - for production)
/navigator full
/navigator to Production
```

## Two Modes

### Quick Mode (Default)
- **Speed:** 30-60 seconds
- **Solution:** No
- **Use for:** Testing, iteration, development
- **Target:** Dev, Test, UAT, Sandbox

### Full Mode
- **Speed:** 4-8 minutes
- **Solution:** Yes (auto-created)
- **Use for:** Production deployment, formal ALM
- **Target:** Production, or when audit trail needed

## Instructions for Claude

When user invokes Navigator:

1. **Parse command** - Extract mode, bot name, target
2. **Detect mode:**
   - "quick", "test", "deploy" → Quick mode
   - "full", "migrate", "production" → Full mode
   - Target = "Production" → Auto-switch to Full
   - Default → Quick mode

3. **Set environment:**
   ```bash
   $env:CLAUDE_CODE_SKILL = "true"
   ```

4. **Execute:**
   ```bash
   cd C:\code\ClaudeCopilotMgmtSkill
   .\Invoke-Navigator.ps1 -Mode <Quick|Full> -BotName "<name>" -Target "<env>"
   ```

5. **Show progress** as script executes

6. **Confirm completion** with test URL or solution name
```

---

## Testing Plan

### Unit Tests

```powershell
# Tests/Copilot-QuickDeploy.Tests.ps1

Describe "Invoke-QuickDeploy" {
    It "Should deploy copilot in under 60 seconds" {
        $result = Invoke-QuickDeploy -BotName "Test Bot" -Target "UAT"
        $result.Success | Should -Be $true
        $duration = [int]$result.Duration.TrimEnd('s')
        $duration | Should -BeLessThan 60
    }

    It "Should update existing copilot when -Overwrite" {
        $result = Invoke-QuickDeploy -BotName "Test Bot" -Target "UAT" -Overwrite
        $result.Action | Should -Be "Updated"
    }

    It "Should throw if copilot exists and no -Overwrite" {
        { Invoke-QuickDeploy -BotName "Existing Bot" -Target "UAT" } | Should -Throw
    }
}
```

### Integration Tests

```powershell
# Tests/Navigator.Integration.Tests.ps1

Describe "Navigator Integration" {
    It "Should support Quick mode via command" {
        $result = .\Invoke-Navigator.ps1 quick -BotName "Test" -Target "UAT" -Confirm:$false
        $result.Success | Should -Be $true
    }

    It "Should auto-switch to Full for Production" {
        # Mock to prevent actual production deployment
        Mock Invoke-FullMigration { return @{Success=$true} }

        $result = .\Invoke-Navigator.ps1 -Target "Production" -Confirm:$false
        # Should have called Full mode
        Assert-MockCalled Invoke-FullMigration -Times 1
    }
}
```

---

## Deployment Checklist

### Pre-Deployment

- [ ] All unit tests pass
- [ ] Integration tests pass
- [ ] Documentation updated
- [ ] Skill definition updated
- [ ] CHANGELOG.md updated
- [ ] Version bumped to 2.0.0

### Deployment Steps

1. [ ] Merge to main branch
2. [ ] Tag release: `v2.0.0`
3. [ ] Update skill in Claude Code
4. [ ] Notify users of new Quick mode
5. [ ] Update README with Quick vs Full guidance

### Post-Deployment

- [ ] Test Quick mode in real environment
- [ ] Test Full mode in real environment
- [ ] Verify three channels work (Skill, PowerShell, prep for VS Code)
- [ ] Monitor for issues
- [ ] Gather user feedback

---

## Success Metrics

### Quick Mode
- ✅ Time < 60 seconds (target: 30-40s)
- ✅ No solution artifacts created
- ✅ Overwrites work correctly
- ✅ Clean cleanup (delete bot)

### Full Mode
- ✅ Solution created correctly
- ✅ All components packaged
- ✅ Audit trail maintained
- ✅ Production deployments succeed

### User Experience
- ✅ Default mode is correct (Quick)
- ✅ Production auto-switches to Full
- ✅ All three channels work
- ✅ Clear output and feedback

---

## Future Enhancements

### v2.1 (Next Release)
- [ ] Diff mode - Show changes before deploy
- [ ] Rollback - Quick restore previous version
- [ ] Batch deploy - Multiple bots at once

### v3.0 (Future)
- [ ] VS Code extension
- [ ] Web dashboard
- [ ] Scheduled deployments
- [ ] Environment comparison view

---

## Support & Troubleshooting

### Common Issues

**Issue: Quick deploy fails with "exists"**
- Solution: Add `-Overwrite` parameter to update in place

**Issue: Production deployment is slow**
- Expected: Full mode takes 4-8 minutes for safety

**Issue: Components not updating**
- Check: Ensure component names match exactly
- Check: Verify no schema changes in components

### Getting Help

- GitHub Issues: Report bugs and feature requests
- Documentation: Check `docs/` folder
- Examples: See `examples/` folder

---

## Summary

This implementation guide provides step-by-step instructions for integrating Quick Deploy into Navigator as a dual-mode tool with three-channel access.

**Key deliverables:**
1. ✅ Copilot-QuickDeploy.psm1 (new module)
2. ✅ Copilot-FullMigration.psm1 (refactored from existing)
3. ✅ Copilot-Core.psm1 (shared utilities)
4. ✅ Enhanced Invoke-Navigator.ps1 (dual-mode routing)
5. ✅ Updated skill definition
6. ✅ Comprehensive documentation

**Result:** One tool, two modes, three channels, consistent experience.

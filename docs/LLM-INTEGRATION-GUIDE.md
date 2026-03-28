# 🧠 LLM Intelligence Integration Guide

## ⚠️ IMPORTANT: This is 100% Optional!

**Navigator works perfectly without LLM integration.**

This guide is for users who want to **optionally enhance** Navigator with AI-powered insights. If you're happy with the built-in analysis (which is excellent), you don't need this.

### When to Use LLM Integration

**You DON'T need this if:**
- ✅ Basic migration and analysis work fine for you
- ✅ You prefer zero external dependencies
- ✅ You want to avoid API costs (even though tiny)
- ✅ You're just getting started with Navigator

**Consider LLM integration if:**
- ⭐ You frequently troubleshoot complex migration errors
- ⭐ You want AI-powered recommendations for fixing issues
- ⭐ You migrate many bots and want time savings
- ⭐ You're curious about AI-enhanced workflows

---

## Overview

This guide shows how to **optionally** integrate AI-powered reasoning into Navigator using Claude API or Azure OpenAI.

**Clarification:**
- **Claude Code** (the tool running Navigator) ≠ **Claude API** (programmatic access)
- Running Navigator in Claude Code does NOT require an API key
- This guide adds OPTIONAL AI features that make API calls from PowerShell
- Without API key, Navigator still works - just without these enhancements

---

## 🚀 Quick Start

### 1. Set Up API Access

**Option A: Claude API (Recommended)**
```powershell
# Set environment variable (Windows)
$env:ANTHROPIC_API_KEY = "sk-ant-api03-your-key-here"

# Or set permanently
[System.Environment]::SetEnvironmentVariable('ANTHROPIC_API_KEY', 'sk-ant-api03-your-key-here', 'User')
```

**Option B: Azure OpenAI**
```powershell
$env:AZURE_OPENAI_ENDPOINT = "https://your-resource.openai.azure.com"
$env:AZURE_OPENAI_KEY = "your-key-here"
```

### 2. Import LLM Module

```powershell
Import-Module .\Modules\Copilot-LLM-Intelligence.psm1
```

### 3. Test Connection

```powershell
# Quick test
$result = Invoke-ClaudeAPI -Prompt "Say hello" -MaxTokens 50
Write-Host $result
# Should output: "Hello! How can I assist you today?"
```

---

## 📍 Integration Points

### **Integration 1: Pre-Migration Analysis**

Add to the analysis workflow in `Invoke-Navigator.ps1`:

```powershell
# After generating analysis
$analysis = Get-CopilotAnalysis -CopilotData $exportData

# 🧠 ADD AI INSIGHTS
Write-Host ""
Write-Host "  🤖 Generating AI-powered migration recommendations..." -ForegroundColor Cyan

$aiInsights = Get-MigrationReadinessWithLLM `
    -BotAnalysis $analysis `
    -TargetEnvironment $targetEnvironmentUrl

if ($aiInsights) {
    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║           🤖 AI MIGRATION READINESS ASSESSMENT                    ║" -ForegroundColor Cyan
    Write-Host "╚══════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    Write-Host $aiInsights
    Write-Host ""
}
```

**Output Example:**
```
🤖 Generating AI-powered migration recommendations...

╔══════════════════════════════════════════════════════════════════╗
║           🤖 AI MIGRATION READINESS ASSESSMENT                    ║
╚══════════════════════════════════════════════════════════════════╝

## MIGRATION READINESS ASSESSMENT

### Risk Level
Medium

### Predicted Issues
1. Weather API skill likely requires connection reconfiguration
2. CRM integration topics reference environment-specific URLs
3. Power Automate flow dependencies may not exist in target

### Pre-Migration Checklist
- [ ] Create Weather API connection in target environment
- [ ] Update CRM_URL environment variable
- [ ] Verify "Create Support Ticket" flow exists in target
- [ ] Test API authentication endpoints
- [ ] Prepare connection credentials

### Recommended Approach
Full migration recommended - template-only would lose valuable conversation
logic. However, expect 20-30 minutes of post-migration configuration.

### Estimated Time
Setup: 30-45 minutes
Migration: 5-10 minutes
Validation: 15-20 minutes
Total: ~60-75 minutes

### Post-Migration Validation
1. Test all topics with connection dependencies
2. Verify API authentication works
3. Test conversation flows end-to-end
4. Validate error handling behavior
```

---

### **Integration 2: Intelligent Error Analysis**

Add to the component import error handling:

```powershell
catch {
    $componentName = if ($componentData.name) { $componentData.name } else { "Unknown" }
    $componentType = switch ($componentData.componenttype) {
        0 { "Topic" }
        1 { "Trigger" }
        2 { "Skill" }
    }

    # 🧠 USE AI TO ANALYZE THE ERROR
    Write-Host ""
    Write-Host "  ⚠️  Component failed: $componentType - $componentName" -ForegroundColor Yellow
    Write-Host "  🤖 Analyzing error..." -ForegroundColor Cyan

    $aiDiagnosis = Analyze-ComponentFailureWithLLM `
        -ComponentName $componentName `
        -ComponentType $componentType `
        -ErrorMessage $_.Exception.Message `
        -ComponentData $componentData

    if ($aiDiagnosis) {
        Write-Host ""
        Write-Host $aiDiagnosis
        Write-Host ""
    }

    $failedComponents += @{
        Name = $componentName
        Type = $componentType
        Error = $_.Exception.Message
        AIAnalysis = $aiDiagnosis
    }
}
```

**Output Example:**
```
⚠️ Component failed: Skill - Get Weather Data
🤖 Analyzing error...

## ROOT CAUSE
The skill references a custom connector "WeatherAPI" that doesn't exist
in the target environment. The connector ID is hard-coded in the component
definition and cannot be resolved during import.

## FIX STEPS
1. Navigate to Power Platform admin center for target environment
2. Create custom connector named "WeatherAPI"
3. Configure connector with same endpoints as source environment
4. Create new connection using the connector
5. Manually recreate this skill in Copilot Studio
6. Update the skill to use the new connection reference

## ALTERNATIVE APPROACH
If WeatherAPI is available in a solution, export it from source and
import to target first, then retry the bot migration.

## IMPACT IF SKIPPED
Medium - 3 topics depend on weather data. Users asking about weather
will receive error messages. Non-critical for core bot functionality.

## PRIORITY
Medium - Should be fixed before production deployment, but bot can
function without it for testing.
```

---

### **Integration 3: Post-Migration Review**

Add after import completion:

```powershell
# After import completes
Write-Host ""
Write-Host "  🤖 Generating post-migration review..." -ForegroundColor Cyan

$postReview = Get-PostMigrationReviewWithLLM `
    -BotId $newBotId `
    -TotalComponents $totalComponents `
    -SuccessCount ($totalComponents - $failedComponents.Count) `
    -FailedComponents $failedComponents

if ($postReview) {
    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║              🤖 POST-MIGRATION REVIEW                            ║" -ForegroundColor Cyan
    Write-Host "╚══════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    Write-Host $postReview
    Write-Host ""
}
```

---

## 🎨 User Experience Flow

### **Without LLM:**
```
❌ Component failed: Skill - Get Weather Data
Error: 0x80060888
```

### **With LLM:**
```
⚠️ Component failed: Skill - Get Weather Data
🤖 Analyzing error...

ROOT CAUSE:
Custom connector "WeatherAPI" not found in target environment.

FIX STEPS:
1. Create WeatherAPI connector in target
2. Configure same endpoints as source
3. Manually recreate skill

IMPACT: Medium - affects 3 weather-related topics
PRIORITY: Medium - fix before production
```

Much more helpful! ✨

---

## 📊 Cost Considerations

### Claude API Pricing (as of 2026)
- **Input:** ~$3 per million tokens
- **Output:** ~$15 per million tokens

### Typical Usage Per Migration:
- Pre-migration analysis: ~2,000 tokens ($0.05)
- Error analysis (per error): ~1,500 tokens ($0.03)
- Post-migration review: ~2,500 tokens ($0.06)

**Total per migration:** ~$0.15-0.30 depending on errors

**Very cost-effective for the value provided!**

---

## 🔒 Security Best Practices

1. **Never send sensitive data to LLM**
   ```powershell
   # Remove before sending to LLM
   $componentData.PSObject.Properties.Remove('credentials')
   $componentData.PSObject.Properties.Remove('apiKey')
   $componentData.PSObject.Properties.Remove('connectionString')
   ```

2. **Use environment variables for API keys**
   ```powershell
   # Don't hardcode keys
   $apiKey = $env:ANTHROPIC_API_KEY  # ✅ Good
   # $apiKey = "sk-ant-123..."        # ❌ Bad
   ```

3. **Sanitize error messages**
   ```powershell
   # Remove internal paths, IPs, etc.
   $sanitizedError = $error -replace 'https?://[^\s]+', '[URL]'
   ```

---

## 🧪 Testing

Test each integration point:

```powershell
# Test 1: Pre-migration analysis
$testAnalysis = @{
    BotName = "Test Bot"
    ComplexityScore = 7
    ComponentCounts = @{
        Topics = 15
        Skills = 3
        Triggers = 2
    }
}

$result = Get-MigrationReadinessWithLLM `
    -BotAnalysis $testAnalysis `
    -TargetEnvironment "Production"

Write-Host $result

# Test 2: Error analysis
$result = Analyze-ComponentFailureWithLLM `
    -ComponentName "Test Skill" `
    -ComponentType "Skill" `
    -ErrorMessage "Connection not found"

Write-Host $result

# Test 3: Post-migration review
$result = Get-PostMigrationReviewWithLLM `
    -BotId "test-123" `
    -TotalComponents 20 `
    -SuccessCount 18 `
    -FailedComponents @(
        @{ Type = "Skill"; Name = "Test Skill"; Error = "Connection issue" }
    )

Write-Host $result
```

---

## 📈 ROI Analysis

### Time Savings
- **Without LLM:** 30-60 min troubleshooting per failed component
- **With LLM:** 5-10 min with AI guidance
- **Savings:** ~80% reduction in troubleshooting time

### Example Scenario
- Migration with 5 failed components
- Without LLM: 2.5-5 hours troubleshooting
- With LLM: 25-50 minutes troubleshooting
- **Time saved: 2+ hours per migration**

At $100/hour billing rate:
- **ROI per migration: $200-400**
- **API cost: $0.15-0.30**
- **Net value: $199-399 per migration**

**Payback after just 1 migration!**

---

## 🔄 Continuous Improvement

The LLM module can learn and improve:

1. **Feedback Loop**
   - Track which AI suggestions were helpful
   - Refine prompts based on accuracy
   - Add domain-specific context

2. **Pattern Recognition**
   - Build library of common errors
   - Include in prompts for better suggestions
   - Create knowledge base

3. **Custom Fine-Tuning** (Advanced)
   - Train custom model on your migrations
   - Include organization-specific patterns
   - Even better recommendations

---

## 🎯 Next Steps

1. **Set API key** → Test basic functionality
2. **Choose integration point** → Start with error analysis
3. **Test on real migration** → Gather feedback
4. **Expand usage** → Add more integration points
5. **Measure ROI** → Track time savings

---

## 📞 Support

For issues or questions:
- Check API key is set correctly
- Verify network connectivity to API endpoint
- Review error logs in PowerShell
- Test with simple prompts first

**LLM integration is optional** - Navigator works perfectly without it,
but LLM adds significant value for complex migrations.

---

## 🌟 Advanced: Custom Prompts

Customize prompts for your organization:

```powershell
# Create organization-specific analysis
function Get-CustomMigrationAnalysis {
    param([object]$BotAnalysis)

    $prompt = @"
Analyze this bot for migration to OUR production environment.

ORGANIZATION CONTEXT:
- We use Azure API Management for all external APIs
- All bots must follow naming convention: [Dept]-[Name]-[Version]
- Production uses managed identities (no API keys)
- All Power Automate flows must be in "ProductionFlows" solution

BOT DATA:
$($BotAnalysis | ConvertTo-Json -Depth 3)

Check for:
1. Naming convention compliance
2. API Management integration requirements
3. Managed identity readiness
4. Flow solution placement

Provide organization-specific guidance.
"@

    return Invoke-ClaudeAPI -Prompt $prompt -MaxTokens 2000
}
```

**The possibilities are endless!** 🚀

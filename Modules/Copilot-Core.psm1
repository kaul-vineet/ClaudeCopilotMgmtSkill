#Requires -Version 7.0

<#
.SYNOPSIS
    Core shared utilities for Navigator

.DESCRIPTION
    Provides common functions used by both Quick Deploy and Full Migration modes
#>

#region Authentication

function Get-AuthHeaders {
    <#
    .SYNOPSIS
        Get authentication headers for Power Platform API calls
    #>
    try {
        $token = az account get-access-token --resource https://api.bap.microsoft.com --query accessToken -o tsv
        if (-not $token) {
            throw "Failed to get access token. Please run 'az login' first."
        }

        return @{
            'Authorization' = "Bearer $token"
            'Content-Type' = 'application/json'
        }
    }
    catch {
        Write-Error "Authentication failed: $_"
        throw
    }
}

#endregion

#region Environment Management

function Get-Environments {
    <#
    .SYNOPSIS
        Get list of Power Platform environments
    #>
    try {
        $environments = az powerplatform environment list --query "value[].{name:properties.displayName, id:name}" -o json | ConvertFrom-Json

        return $environments | ForEach-Object {
            @{
                Name = $_.name
                Id = $_.id
            }
        }
    }
    catch {
        Write-Error "Failed to get environments: $_"
        throw
    }
}

function Get-EnvironmentUrl {
    <#
    .SYNOPSIS
        Get environment URL from environment name
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Environment
    )

    try {
        $envs = Get-Environments
        $env = $envs | Where-Object { $_.Name -eq $Environment } | Select-Object -First 1

        if (-not $env) {
            throw "Environment '$Environment' not found"
        }

        # Get environment details
        $envDetails = az powerplatform environment show --name $env.Id --query "properties.linkedEnvironmentMetadata.instanceUrl" -o tsv

        return $envDetails
    }
    catch {
        Write-Error "Failed to get environment URL: $_"
        throw
    }
}

function Select-Environment {
    <#
    .SYNOPSIS
        Interactive environment selection
    #>
    param(
        [string]$Exclude
    )

    try {
        $environments = Get-Environments

        if ($Exclude) {
            $environments = $environments | Where-Object { $_.Name -ne $Exclude }
        }

        Write-Host "Select environment:" -ForegroundColor Yellow
        for ($i = 0; $i -lt $environments.Count; $i++) {
            Write-Host "  [$($i + 1)] $($environments[$i].Name)"
        }
        Write-Host ""

        do {
            $selection = Read-Host "Enter number (1-$($environments.Count))"
            $valid = $selection -match '^\d+$' -and [int]$selection -ge 1 -and [int]$selection -le $environments.Count
            if (-not $valid) {
                Write-Host "Invalid selection" -ForegroundColor Red
            }
        } while (-not $valid)

        return $environments[[int]$selection - 1].Name
    }
    catch {
        Write-Error "Failed to select environment: $_"
        throw
    }
}

#endregion

#region Copilot Operations

function Get-CopilotDefinition {
    <#
    .SYNOPSIS
        Get copilot definition from environment
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Name,

        [Parameter(Mandatory=$true)]
        [string]$Environment
    )

    try {
        $envUrl = Get-EnvironmentUrl -Environment $Environment
        $headers = Get-AuthHeaders

        # Get bot
        $botsUri = "$envUrl/api/data/v9.2/bots?\`$filter=name eq '$Name'"
        $botResponse = Invoke-RestMethod -Uri $botsUri -Headers $headers -Method Get

        if ($botResponse.value.Count -eq 0) {
            throw "Copilot '$Name' not found in environment '$Environment'"
        }

        $bot = $botResponse.value[0]

        # Get components
        $componentsUri = "$envUrl/api/data/v9.2/botcomponents?\`$filter=_parentbotid_value eq $($bot.botid)"
        $componentsResponse = Invoke-RestMethod -Uri $componentsUri -Headers $headers -Method Get

        # Group components by type
        $components = @{
            Topics = @($componentsResponse.value | Where-Object { $_.componenttype -eq 0 })
            Triggers = @($componentsResponse.value | Where-Object { $_.componenttype -eq 1 })
            Skills = @($componentsResponse.value | Where-Object { $_.componenttype -eq 2 })
        }

        # Return definition
        return @{
            Bot = $bot
            Components = $components
        }
    }
    catch {
        Write-Error "Failed to get copilot definition: $_"
        throw
    }
}

function Select-Copilot {
    <#
    .SYNOPSIS
        Interactive copilot selection
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Environment
    )

    try {
        $envUrl = Get-EnvironmentUrl -Environment $Environment
        $headers = Get-AuthHeaders

        # Get all bots
        $botsUri = "$envUrl/api/data/v9.2/bots"
        $response = Invoke-RestMethod -Uri $botsUri -Headers $headers -Method Get

        if ($response.value.Count -eq 0) {
            throw "No copilots found in environment '$Environment'"
        }

        $bots = $response.value

        Write-Host "Select copilot:" -ForegroundColor Yellow
        for ($i = 0; $i -lt $bots.Count; $i++) {
            Write-Host "  [$($i + 1)] $($bots[$i].name)"
        }
        Write-Host ""

        do {
            $selection = Read-Host "Enter number (1-$($bots.Count))"
            $valid = $selection -match '^\d+$' -and [int]$selection -ge 1 -and [int]$selection -le $bots.Count
            if (-not $valid) {
                Write-Host "Invalid selection" -ForegroundColor Red
            }
        } while (-not $valid)

        return $bots[[int]$selection - 1].name
    }
    catch {
        Write-Error "Failed to select copilot: $_"
        throw
    }
}

function Publish-Copilot {
    <#
    .SYNOPSIS
        Publish copilot
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$BotId,

        [Parameter(Mandatory=$true)]
        [string]$Environment
    )

    try {
        $envUrl = Get-EnvironmentUrl -Environment $Environment
        $headers = Get-AuthHeaders

        $publishUri = "$envUrl/api/data/v9.2/bots($BotId)/Microsoft.Dynamics.CRM.PvaPublish"
        Invoke-RestMethod -Uri $publishUri -Headers $headers -Method Post -Body "{}"

        Write-Verbose "Copilot published successfully"
    }
    catch {
        Write-Error "Failed to publish copilot: $_"
        throw
    }
}

function Get-TestChatUrl {
    <#
    .SYNOPSIS
        Get test chat URL for copilot
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$BotId,

        [Parameter(Mandatory=$true)]
        [string]$Environment
    )

    try {
        $environments = Get-Environments
        $env = $environments | Where-Object { $_.Name -eq $Environment } | Select-Object -First 1

        return "https://copilotstudio.microsoft.com/environments/$($env.Id)/bots/$BotId/canvas"
    }
    catch {
        Write-Error "Failed to get test chat URL: $_"
        throw
    }
}

#endregion

#region Helper Functions

function Write-StepProgress {
    <#
    .SYNOPSIS
        Write step progress message
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Step,

        [Parameter(Mandatory=$true)]
        [string]$Message
    )

    Write-Host "$Step " -NoNewline -ForegroundColor Cyan
    Write-Host $Message -ForegroundColor White
}

function Remove-SystemFields {
    <#
    .SYNOPSIS
        Remove system fields from object before create/update
    #>
    param(
        [Parameter(Mandatory=$true)]
        [object]$Data
    )

    $systemFields = @(
        'botid', 'botcomponentid', 'createdon', 'modifiedon',
        '_createdby_value', '_modifiedby_value', '_ownerid_value',
        'ownerid', 'owningbusinessunit', '_owningbusinessunit_value',
        'owninguser', '_owninguser_value', 'owningteam', '_owningteam_value',
        'versionnumber', 'overriddencreatedon', 'solutionid',
        '_parentbotid_value', 'parentbotid',
        'environmentvariabledefinitionid', '_environmentvariabledefinitionid_value'
    )

    foreach ($field in $systemFields) {
        if ($Data.PSObject.Properties[$field]) {
            $Data.PSObject.Properties.Remove($field)
        }
    }

    return $Data
}

#endregion

# Export functions
Export-ModuleMember -Function @(
    'Get-AuthHeaders'
    'Get-Environments'
    'Get-EnvironmentUrl'
    'Select-Environment'
    'Get-CopilotDefinition'
    'Select-Copilot'
    'Publish-Copilot'
    'Get-TestChatUrl'
    'Write-StepProgress'
    'Remove-SystemFields'
)

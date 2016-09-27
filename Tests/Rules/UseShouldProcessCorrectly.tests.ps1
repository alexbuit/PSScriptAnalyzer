﻿Import-Module PSScriptAnalyzer
$violationMessage = "'Verb-Files' has the ShouldProcess attribute but does not call ShouldProcess/ShouldContinue."
$violationName = "PSShouldProcess"
$directory = Split-Path -Parent $MyInvocation.MyCommand.Path
$violations = Invoke-ScriptAnalyzer $directory\BadCmdlet.ps1 | Where-Object {$_.RuleName -eq $violationName}
$noViolations = Invoke-ScriptAnalyzer $directory\GoodCmdlet.ps1 | Where-Object {$_.RuleName -eq $violationName}

Describe "UseShouldProcessCorrectly" {
    Context "When there are violations" {
        It "has 3 should process violation" {
            $violations.Count | Should Be 1
        }

        It "has the correct description message" {
            $violations[0].Message | Should Match $violationMessage
        }

    }

    Context "When there are no violations" {
        It "returns no violations" {
            $noViolations.Count | Should Be 0
        }
    }

    Context "Where ShouldProcess is called in nested function" {
        It "finds no violation" {
            $scriptDef = @'
function Outer
{
    [CmdletBinding(SupportsShouldProcess=$true)]
    param()

    Inner
}

function Inner
{
    [CmdletBinding(SupportsShouldProcess=$true)]
    param()

    if ($PSCmdlet.ShouldProcess("Inner"))
    {
        Write-Host "Process!"
    }
    else
    {
        Write-Host "Skipped!"
    }
}

Outer -WhatIf
'@
        $violations = Invoke-ScriptAnalyzer -ScriptDefinition $scriptDef -IncludeRule PSShouldProcess
        $violations.Count | Should Be 0
        }

        It "finds no violation" {
            $scriptDef = @'
function Foo
{
   [CmdletBinding(SupportsShouldProcess)]
   param()
   begin
   {
       function helper
       {
           if ($PSCmdlet.ShouldProcess('',''))
           {

           }
       }
       helper
   }
}
'@
            $violations = Invoke-ScriptAnalyzer -ScriptDefinition $scriptDef -IncludeRule PSShouldProcess
            $violations.Count | Should Be 0
        }
    }
}
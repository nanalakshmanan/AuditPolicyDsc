
$script:DSCModuleName      = 'AuditPolicyDsc'
$script:DSCResourceName    = 'MSFT_AuditPolicyOption'

#region HEADER
[String] $moduleRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $script:MyInvocation.MyCommand.Path))
if ( (-not (Test-Path -Path (Join-Path -Path $moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
     (-not (Test-Path -Path (Join-Path -Path $moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone','https://github.com/PowerShell/DscResource.Tests.git',(Join-Path -Path $moduleRoot -ChildPath '\DSCResource.Tests\'))
}
else
{
    & git @('-C',(Join-Path -Path $moduleRoot -ChildPath '\DSCResource.Tests\'),'pull')
}
Import-Module (Join-Path -Path $moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1') -Force
$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $script:DSCModuleName `
    -DSCResourceName $script:DSCResourceName `
    -TestType Unit 
#endregion

# Begin Testing
try
{
    #region Pester Tests

    InModuleScope $script:DSCResourceName {

        #region Pester Test Initialization

        # set the audit option test strings to Mock
        $optionName  = 'CrashOnAuditFail'
        
        #endregion

        #region Function Get-TargetResource
        Describe "$($script:DSCResourceName)\Get-TargetResource" {

            context 'Option Enabled' {

                $optionState = 'Enabled'
                Mock -CommandName Get-AuditOption -MockWith { 
                    return $optionState } -ModuleName MSFT_AuditPolicyOption
                
                It 'Should not throw an exception' {
                    { $script:getTargetResourceResult = Get-TargetResource -Name $optionName } | 
                        Should Not Throw
                }

                It 'Should return the correct hashtable properties' {
                    $getTargetResourceResult.Name  | Should Be $optionName
                    $getTargetResourceResult.Value | Should Be $optionState
                }
            }

            context 'Option Disabled' {

                $optionState = 'Disabled'
                Mock -CommandName Get-AuditOption -MockWith { 
                    return $optionState } -ModuleName MSFT_AuditPolicyOption

                It 'Should not throw an exception' {
                    { $script:getTargetResourceResult = Get-TargetResource -Name $optionName } | 
                        Should Not Throw
                }

                It 'Should return the correct hashtable properties' {
                    $getTargetResourceResult.Name  | Should Be $optionName
                    $getTargetResourceResult.Value | Should Be $optionState
                }
            }
        }
        #endregion

        #region Function Test-TargetResource
        Describe "$($script:DSCResourceName)\Test-TargetResource" {
            $target = @{
                Name  = $optionName 
                Value = $null
            }

            $optionStateSwap = @{
                'Disabled' = 'Enabled';
                'Enabled'  = 'Disabled'
            }

            Context 'Option set to enabled and should be' {

                $optionState = 'Enabled'
                $target.Value = $optionState
                Mock -CommandName Get-AuditOption -MockWith { 
                    return $optionState } -ModuleName MSFT_AuditPolicyOption

                It 'Should not throw an exception' {
                    { $script:testTargetResourceResult = Test-TargetResource @target } | Should Not Throw
                }

                It "Should return true" {
                    $script:testTargetResourceResult | Should Be $true
                }
            }

            Context 'Option set to enabled and should not be' {

                $optionState = 'Enabled'
                $target.Value = $optionState

                Mock -CommandName Get-AuditOption -MockWith { 
                    return $optionStateSwap[$optionState] } -ModuleName MSFT_AuditPolicyOption

                It 'Should not throw an exception' {
                    { $script:testTargetResourceResult = Test-TargetResource @target } | Should Not Throw
                }

                It "Should return false" {
                    $script:testTargetResourceResult | Should Be $false
                }
            }

            Context 'Option set to disabled and should be' {

                $optionState = 'Disabled'
                $target.Value = $optionState
                Mock -CommandName Get-AuditOption -MockWith { 
                    return $optionState } -ModuleName MSFT_AuditPolicyOption

                It 'Should not throw an exception' {
                    { $script:testTargetResourceResult = Test-TargetResource @target } | Should Not Throw
                }
                
                It "Should return true" {
                    $script:testTargetResourceResult | Should Be $true
                }
            }

            Context 'Option set to disabled and should not be' {

                $optionState = 'Disabled'
                $target.Value = $optionState
                Mock -CommandName Get-AuditOption -MockWith { 
                    return $optionStateSwap[$optionState] } -ModuleName MSFT_AuditPolicyOption
                
                It 'Should not throw an exception' {
                    { $script:testTargetResourceResult = Test-TargetResource @target } | Should Not Throw
                }

                It "Should return false" {
                    $script:testTargetResourceResult | Should Be $false
                }
            }
        }
        #endregion

        #region Function Set-TargetResource
        Describe "$($script:DSCResourceName)\Set-TargetResource" {

            context 'Option Enabled' {

                $target.Value = 'Enabled'
                Mock -CommandName Set-AuditOption -MockWith { } -ModuleName MSFT_AuditPolicyOption -Verifiable
                    
                It 'Should not throw an exception' {
                    { $script:setTargetResourceResult = Set-TargetResource @target } | Should Not Throw
                }

                It 'Should call expected Mocks' {    
                    Assert-VerifiableMocks
                    Assert-MockCalled -CommandName Set-AuditOption -Exactly 1
                } 
            }

            context 'Option Disabled' {
                $target.Value = 'Disabled'
                Mock -CommandName Set-AuditOption -MockWith { } -ModuleName MSFT_AuditPolicyOption -Verifiable
                    
                It 'Should not throw an exception' {
                    { $script:setTargetResourceResult = Set-TargetResource @target } | Should Not Throw
                }
                It 'Should call expected Mocks' {    
                    Assert-VerifiableMocks
                    Assert-MockCalled -CommandName Set-AuditOption -Exactly 1
                } 
            }
        }
        #endregion

        #region Helper Cmdlets
        Describe 'Private function Get-AuditOption' { 

            Context 'Get-AuditOption with Mock Invoke-Auditpol' {

                [string] $name  = 'CrashOnAuditFail'
                [string] $value = 'Enabled'
                # the return is 3 lines Header, blank line, data
                # ComputerName,System,Subcategory,GUID,AuditFlags
                Mock -CommandName Invoke-Auditpol -MockWith { 
                    @("","","$env:COMPUTERNAME,,Option:$name,,$value,,") 
                }

                $auditOption = Get-AuditOption -Name $name

                It "Should return the correct value" {
                    $auditOption | should Be $value
                }
            }
        }

        Describe 'Private function Set-AuditOption' { 

            Context "Set-AuditOption to enabled" {

                [string] $name  = "CrashOnAuditFail"
                [string] $value = "Enabled"

                Mock -CommandName Invoke-Auditpol -MockWith { } -Verifiable

                It 'Should not throw an exception' {
                    { Set-AuditOption -Name $name -Value $value } | Should Not Throw
                }   

                It 'Should call expected Mocks' {    
                    Assert-VerifiableMocks
                    Assert-MockCalled -CommandName Invoke-Auditpol -Exactly 1
                } 
            }

            Context "Set-AuditOption to disabled" {

                [string] $name  = "CrashOnAuditFail"
                [string] $value = "Disabled"

                Mock -CommandName Invoke-Auditpol -MockWith { } -Verifiable

                It 'Should not throw an exception' {
                    { Set-AuditOption -Name $name -Value $value } | Should Not Throw
                }   

                It 'Should call expected Mocks' {    
                    Assert-VerifiableMocks
                    Assert-MockCalled -CommandName Invoke-Auditpol -Exactly 1
                } 
            }
        }
        #endregion
    }
    #endregion
}
finally
{
    #region FOOTER
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
    #endregion
}

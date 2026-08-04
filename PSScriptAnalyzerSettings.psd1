@{
    # Fail the build on Error and Warning; Information findings stay advisory.
    Severity     = @('Error', 'Warning')

    ExcludeRules = @(
        # This is an interactive profile: Write-Host is the point (coloured
        # prompt and command output), not a diagnostic-stream mistake.
        'PSAvoidUsingWriteHost',

        # cshup/cshdel intentionally pipe the remote installer into
        # Invoke-Expression, mirroring the documented `irm ... | iex` install.
        'PSAvoidUsingInvokeExpression'
    )
}

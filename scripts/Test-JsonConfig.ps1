[CmdletBinding()]
param (
    [Parameter()]
    [string] $Environment = 'dev'
)

process {
    $validationErrors = [System.Collections.Generic.List[string]]::new()

    #Enumerate json files

    #Valid JSON
    $repoRootFolder = Split-Path -Path $PSScriptRoot -Parent
    $testConfigPath = Join-Path -Path $repoRootFolder -ChildPath 'config' -AdditionalChildPath $Environment, 'test.json'
    $testConfig = Get-Content -Path $testConfigPath -Raw
    $testConfigSchemaFilePath = Join-Path -Path $repoRootFolder -ChildPath 'schemas' -AdditionalChildPath 'test.schema.json'
    $testConfigSchema = Get-Content -Path $testConfigSchemaFilePath -Raw

    try {
        #Validate against schema
        $null = Test-Json -Json $testConfig -Schema $testConfigSchema -ErrorAction Stop
    }
    catch {
        $validationErrors.Add("Provided JSON does not pass schema is not valid. Details: $_")
    }


    $testConfig = $testConfig | ConvertTo-Json -ErrorAction Stop
    $testNumber = 0
    foreach ($test in $testConfig) {
        if ($test.name -in @('import-csv', 'load-from-baselayer')) {
            $schedule = $test.schedule

            if ($null -eq $schedule) {
                $validationErrors.Add("Provided JSON does not pass schema is not valid. Details: Schedule parameter is missing #/[$testNumber]")
            }
        }

        $testNumber++
    }

    if ($validationErrors.Count) {
        Write-Error -Message "Validation errors found. Errors: $($validationErrors -join ', ')" -ErrorAction Stop
    }
}
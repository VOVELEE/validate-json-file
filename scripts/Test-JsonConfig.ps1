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
  $testConfigAsJson = Get-Content -Path $testConfigPath -Raw
  $testConfigSchemaFilePath = Join-Path -Path $repoRootFolder -ChildPath 'schemas' -AdditionalChildPath 'test.schema.json'
  $testConfigSchema = Get-Content -Path $testConfigSchemaFilePath -Raw

  Write-Host "---------"
  $a = $testConfigAsJson | ConvertFrom-Json
  $a.Count

  Write-Host "---------"
  try {
    #Validate against schema
    $null = Test-Json -Json $testConfigAsJson -Schema $testConfigSchema -ErrorAction Stop
  } catch {
    $validationErrors.Add("Provided JSON does not pass schema. Details: $_")
  }


  $testConfig = $testConfigAsJson | ConvertFrom-Json -ErrorAction Stop
  $testNumber = 0
  foreach ($test in $testConfig) {
    if ($test.name -in @('schedule', 'loader')) {
      $schedule = $test.schedule

      if ($null -eq $schedule) {
        $validationErrors.Add("Provided JSON does not pass schema. Details: Schedule parameter is missing in #/[$testNumber]")
      }
    }

    $testNumber++
  }

  if ($validationErrors.Count) {
    Write-Error -Message "Validation errors found. Errors: $($validationErrors -join ', ')" -ErrorAction Stop
  }
}

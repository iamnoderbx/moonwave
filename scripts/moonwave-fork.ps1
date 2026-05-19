# moonwave-fork.ps1
#
# Set up and run Moonwave using the iamnoderbx fork's plugin (which adds
# nested-folder support to `autoSectionPath`) without publishing to npm.
#
# Usage:
#   .\moonwave-fork.ps1 setup            Clone or update the fork only
#   .\moonwave-fork.ps1 dev              Run `moonwave dev`  with the fork
#   .\moonwave-fork.ps1 build            Run `moonwave build` with the fork
#   .\moonwave-fork.ps1 <other args>     Pass args straight to `moonwave`
#
# Requirements: git, node (>=18), npm, and the upstream Moonwave CLI
# (install with: npm install -g moonwave).
#
# Environment overrides:
#   MOONWAVE_FORK_REPO     Defaults to https://github.com/iamnoderbx/moonwave.git
#   MOONWAVE_FORK_BRANCH   Defaults to master
#   MOONWAVE_FORK_DIR      Where to clone the fork; defaults to .moonwave-fork

param(
  [Parameter(ValueFromRemainingArguments = $true)]
  [string[]]$ArgList
)

$ErrorActionPreference = "Stop"

$forkRepo   = if ($env:MOONWAVE_FORK_REPO)   { $env:MOONWAVE_FORK_REPO }   else { "https://github.com/iamnoderbx/moonwave.git" }
$forkBranch = if ($env:MOONWAVE_FORK_BRANCH) { $env:MOONWAVE_FORK_BRANCH } else { "master" }
$forkDir    = if ($env:MOONWAVE_FORK_DIR)    { $env:MOONWAVE_FORK_DIR }    else { ".moonwave-fork" }
$pluginRel  = "docusaurus-plugin-moonwave"

function Log($msg)  { Write-Host "[moonwave-fork] $msg" }
function Need($cmd) {
  if (-not (Get-Command $cmd -ErrorAction SilentlyContinue)) {
    throw "[moonwave-fork] missing required command: $cmd"
  }
}

function Invoke-Setup {
  Need git
  Need npm

  if (Test-Path (Join-Path $forkDir ".git")) {
    Log "Updating fork in $forkDir"
    git -C $forkDir fetch --depth=1 origin $forkBranch
    git -C $forkDir reset --hard "origin/$forkBranch"
  } else {
    Log "Cloning $forkRepo ($forkBranch) into $forkDir"
    git clone --depth=1 --branch $forkBranch $forkRepo $forkDir
  }

  $pluginDir = Join-Path $forkDir $pluginRel
  if (-not (Test-Path (Join-Path $pluginDir "node_modules"))) {
    Log "Installing plugin dependencies"
    Push-Location $pluginDir
    try { npm install --silent }
    finally { Pop-Location }
  }

  Log "Fork ready at $pluginDir"
}

function Invoke-Run([string[]]$Passthrough) {
  Need moonwave
  Invoke-Setup

  $pluginAbs = (Resolve-Path (Join-Path $forkDir $pluginRel)).Path
  Log "MOONWAVE_PLUGIN_PATH=$pluginAbs"

  $env:MOONWAVE_PLUGIN_PATH = $pluginAbs
  & moonwave @Passthrough
}

if (-not $ArgList -or $ArgList.Count -eq 0) {
  Invoke-Run @("dev")
  exit
}

switch ($ArgList[0]) {
  "setup" { Invoke-Setup }
  default { Invoke-Run $ArgList }
}

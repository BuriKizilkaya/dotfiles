Set-ExecutionPolicy -ExecutionPolicy ByPass -Scope Process

# -- starship
Invoke-Expression (&starship init powershell)

# -- mise
(&mise activate pwsh) | Out-String | Invoke-Expression

# -- middlewares
Import-Module -Name Terminal-Icons
Import-Module posh-git

# -- PSReadline Module Config
Import-Module PSReadLine

# Save history across sessions
Set-PSReadLineOption -HistorySaveStyle SaveIncrementally

# Set max history size
Set-PSReadLineOption -MaximumHistoryCount 4096

# Search history with up/down arrows based on what you've typed
Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
Set-PSReadLineOption -PredictionViewStyle ListView
Set-PSReadLineOption -PredictionSource History

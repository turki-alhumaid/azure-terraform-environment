param(
    [string]$KeyPath        = "~/.ssh/az-infra-dev",
    [string]$ConfigPath     = "~/.ssh/az-infra-dev.config",
    [string]$KnownHostsPath = "~/.ssh/az-infra-dev.known_hosts"
)

$tfDir = Join-Path $PSScriptRoot "../environments/dev"
$out   = terraform "-chdir=$tfDir" output -json | ConvertFrom-Json

if (-not $out.jump_public_ip) { throw "No outputs found. Is the environment deployed?" }

$user   = $out.admin_username.value
$jumpIp = $out.jump_public_ip.value

$config = @"
Host az-jump
  HostName $jumpIp
  User $user
  IdentityFile $KeyPath
  UserKnownHostsFile $KnownHostsPath
  StrictHostKeyChecking accept-new

"@

foreach ($vm in $out.private_ips.value.PSObject.Properties) {
    if ($vm.Name -eq "jump") { continue }
    $name = $vm.Name
    $ip   = $vm.Value
    $config += @"

Host az-$name
  HostName $ip
  User $user
  IdentityFile $KeyPath
  UserKnownHostsFile $KnownHostsPath
  ProxyJump az-jump
  StrictHostKeyChecking accept-new
"@
}

Remove-Item $KnownHostsPath -ErrorAction SilentlyContinue
Set-Content -Path $ConfigPath -Value $config -Encoding ascii
Write-Host "Wrote $ConfigPath"
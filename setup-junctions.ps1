$addons = "C:\Program Files (x86)\World of Warcraft\_retail_\Interface\AddOns"
$repo   = "C:\Users\종민\repository\addon\oculus"

$modules = @("Oculus", "Oculus_UnitFrames", "Oculus_RaidFrames", "Oculus_General")

foreach ($m in $modules) {
    $dst = "$addons\$m"
    $src = "$repo\$m"

    if (Test-Path $dst) {
        Remove-Item $dst -Recurse -Force
    }

    New-Item -ItemType Junction -Path $dst -Target $src | Out-Null

    $item = Get-Item $dst
    Write-Host "[OK] $m -> $($item.Target)"
}

Write-Host "`n완료. WoW를 /reload 하세요."

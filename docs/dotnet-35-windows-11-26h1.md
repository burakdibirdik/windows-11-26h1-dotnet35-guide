# Windows 11 26H1: .NET Framework 3.5 ve dil paketi kurulum sorunu

> **Önemli uyarı:** Bu belge, kullanıcının bildirdiği “kurulum tamamlandı” mesajına rağmen .NET 3.5'in görünmemesi ve dil paketi kurulumunun temel .NET 3.5'i istemesi sorununu ve paylaşılan deneysel MSI çıkarma yaklaşımını kaydeder. MSI koşullarını silip doğrudan kurulum yapmak Microsoft'un desteklediği veya burada doğrulanmış bir çözüm değildir. Sistem dosyaları/kurulum veritabanı üzerinde değişiklik yapar; ana bilgisayar veya üretim makinesinde uygulamayın. Önce Microsoft'un sürüme özel resmi yöntemini deneyin.

## Belirti

Windows 11 26H1 (28000 serisi) için indirilen `DotNet35Setup.exe` kurucusu “kurulum tamamlandı” benzeri sonuç gösterebilir; ancak .NET Framework 3.5 sistemde kurulu görünmez veya uygulamalar tarafından kullanılamaz. Ardından `DotNet35LPSetup.exe` dil paketi kurucusu temel .NET Framework 3.5'in önce kurulması gerektiğini söyleyebilir.

Bu iki mesaj birlikteyse dil paketi kurulumunu tekrarlamak yerine temel paketin gerçekten kaydedilip kaydedilmediğini doğrulayın. Tamamlandı bildirimi tek başına kurulumun başarılı olduğunu kanıtlamaz.

## 1. Windows sürümünü ve resmi indirmeleri kontrol et

1. `Win + R` → `winver` ile Windows sürümünü ve build numarasını kontrol edin.
2. Yalnızca Windows 11 26H1 için yayımlanmış Microsoft paketlerini indirin. 26H1'e özel .NET Framework 3.5 kurucusu ve dil paketi bağlantıları Microsoft'un sayfalarında listeleniyorsa onları kullanın; eski Windows sürümlerinin kurucularını kullanmayın.
3. İndirilen `DotNet35Setup.exe` ve `DotNet35LPSetup.exe` dosyalarının dijital imzasını kontrol edin. Üçüncü taraf dosya arşivlerinden kurucu indirmeyin.

Resmi kaynaklar:

- [Windows 11'de .NET Framework 3.5'i yükleme](https://learn.microsoft.com/en-us/dotnet/framework/install/dotnet-35-windows-11)
- [.NET Framework 3.5 on Windows 11 FAQ](https://learn.microsoft.com/en-us/dotnet/framework/install/dotnet-35-windows-11-faq)
- [Microsoft .NET Framework indirme sayfası](https://dotnet.microsoft.com/en-us/download/dotnet-framework)
- [Microsoft .NET Framework dil paketleri](https://dotnet.microsoft.com/en-us/download/dotnet-framework)
- [Windows 11 26H1+ için .NET Framework 3.5 güncelleme bilgisi (KB5087077)](https://support.microsoft.com/en-us/topic/may-12-2026-kb5087077-cumulative-update-for-net-framework-3-5-for-windows-11-version-26h1-build-28000-and-later-2cef455d-75b5-4d95-9cc6-2efc37abac5b)

> İndirme sayfalarının yapısı ve dosya bağlantıları değişebilir. Microsoft sayfasındaki 26H1'e özel temel paket ve uygun dil paketi bağlantılarını takip edin. KB numaralarının değişebileceğini unutmayın; burada geçen KB5087077 bağlantısını ve Windows Update kataloğunu kontrol edin. Kullanıcı notlarında geçen KB5127696 numarasının bu sorunun çözümü olduğu burada doğrulanmamıştır.

## 2. Temel .NET 3.5 kurulumunu doğrula

Kurulumdan sonra PowerShell'i yönetici olarak açıp kontrol edin:

```powershell
Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v3.5" -ErrorAction SilentlyContinue
Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v3.5\1033" -ErrorAction SilentlyContinue
```

Dil/locale alt anahtarı farklı olabilir; örneğin Türkçe için `1055`. Kayıt defteri anahtarlarının varlığı tek başına uygulama uyumluluğunu kanıtlamaz.

26H1'de .NET 3.5'in eski Optional Feature/DISM/FOD yöntemleriyle kurulacağını varsaymayın. Microsoft'un 26H1'e özel güncel talimatları belirleyicidir; başka sürümlere ait `Enable-WindowsOptionalFeature`, ISO'dan `sxs` veya DISM komutlarını körlemesine uygulamayın.

## 3. “Kurulum tamamlandı” ama bileşen yoksa

1. Windows build'ini ve kurucunun gerçekten bu build'e uygun olduğunu yeniden kontrol edin.
2. Kurucuyu Microsoft'un resmi sayfasından yeniden indirin ve dijital imzasını doğrulayın.
3. Bilgisayarı yeniden başlatın; bekleyen Windows Update işlemlerinin bitmesini bekleyin.
4. Kurucuyu **Yönetici olarak çalıştır** seçeneğiyle deneyin.
5. Kurulum aracı hata kodlarını, gösterdiği günlük/ayrıntıları ve Olay Görüntüleyicisi kayıtlarını saklayın. Kurulum günlüklerinin konumu pakete göre değişebilir.
6. Sorun aynı build'de sürerse Microsoft Learn FAQ ve 26H1 destek makalesindeki en güncel bilinen sorunları inceleyin; hata koduyla Microsoft Support/Feedback Hub'a başvurun.

Başarısız kurulumu “temizlemek” amacıyla rastgele MSI kaldırma, kayıt defteri silme, `WinSxS` değişikliği veya sistem klasörlerini elle silme yapmayın. Bunlar bileşen deposunu ve güncellemeleri bozabilir.

## 4. Dil paketini yükleme sırası

Dil paketi temel .NET Framework 3.5'e bağımlıdır:

1. Önce Windows 11 26H1'e uygun temel .NET 3.5 paketini kurun.
2. Kurulum mesajından sonra temel bileşeni doğrulayın. Dil paketi hâlâ “önce .NET 3.5'i kurun” diyorsa temel kurulum kaydı oluşmamış olabilir.
3. Temel paket doğrulanmadan dil paketini tekrar tekrar çalıştırmayın.
4. Microsoft'un aynı Windows sürümü/paket ailesi için sunduğu doğru dil paketini seçin.
5. Türkçe locale kontrolü için:

```powershell
Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v3.5\1055" -ErrorAction SilentlyContinue
Get-ChildItem "C:\Windows\Microsoft.NET\Framework\v3.5\tr" -ErrorAction SilentlyContinue
```

Kayıt veya klasör yolunun bulunmaması, paketin bu bilgileri nasıl kaydettiğine bağlı olabilir; tek başına kesin teşhis değildir.

## 5. Paylaşılan MSI çıkarma yöntemi — deneysel ve desteklenmeyen

Aşağıdaki bölüm, kullanıcının gönderdiği notlardaki adımları **belgeleme amacıyla** tutar. Bu, Microsoft'un onayladığı bir çözüm değildir; burada doğrulanmış/önerilen kurulum yöntemi olarak sunulmaz. Bu adımlarla çıkarılan MSI'ların `LaunchCondition` tablosunu değiştirmek paketlerin orijinal bütünlük/imza güvencesini ortadan kaldırır. MSI exit code `0` veya kurulum mesajı, Windows Update'in bileşeni tanıyacağını kanıtlamaz.

**Ana bilgisayarınızda çalıştırmayın.** Deneme yapılacaksa yalnızca geri alınabilir anlık görüntüsü olan yalıtılmış test VM'sinde, yedek alındıktan sonra ve sonuçların garanti edilmediği bilinerek yapılmalıdır. PowerShell'i yönetici açmak bu adımların güvenli olduğu anlamına gelmez.

### 5.1 Dosyaları hazırlama

Microsoft kaynaklarından indirilen dosyaları `C:\sistem\` içine koyun:

- `C:\sistem\DotNet35Setup.exe`
- `C:\sistem\DotNet35LPSetup.exe`

Aşağıdaki PowerShell, Burn EXE içindeki CAB-imzalarına benzer `MSCF` bloklarını arar, CAB'ları çıkarıp manifest ve payload'ları `expand.exe` ile açar. CAB sıra numaraları, payload adları ve manifest yapısı kurucu sürümüne göre değişebilir; `paket_1`, `paket_2`, `a0`–`a5` varsayımlarını körlemesine kullanmayın.

### 5.2 Ana paketin CAB bloklarını çıkarma

```powershell
$exe = "C:\sistem\DotNet35Setup.exe"
$root = "C:\sistem\Net35_Kurulum"
New-Item -ItemType Directory -Force -Path "$root\Cabs", "$root\Manifest", "$root\Raw", "$root\MSI" | Out-Null

if (-not (Test-Path -LiteralPath $exe)) { throw "Kurucu bulunamadı: $exe" }
$bytes = [System.IO.File]::ReadAllBytes($exe)
$c = 0
for ($i = 0; $i -lt $bytes.Length - 16; $i++) {
    if ($bytes[$i] -eq 0x4D -and $bytes[$i+1] -eq 0x53 -and $bytes[$i+2] -eq 0x43 -and $bytes[$i+3] -eq 0x46 -and $bytes[$i+4] -eq 0x00) {
        $sz = [System.BitConverter]::ToInt32($bytes, $i + 8)
        if ($sz -gt 1024 -and ($i + $sz) -le $bytes.Length) {
            $c++
            $buf = New-Object byte[] $sz
            [Array]::Copy($bytes, $i, $buf, 0, $sz)
            [System.IO.File]::WriteAllBytes("$root\Cabs\paket_$c.cab", $buf)
            $i += $sz - 1
        }
    }
}
if ($c -lt 2) { throw "Beklenen CAB sayısı bulunamadı. Bu EXE sürümünde CAB düzeni farklı olabilir; durduruldu." }
Get-ChildItem "$root\Cabs"
```

Yalnızca CAB dosyalarının gerçekten beklenen içerik olduğunu doğruladıktan sonra, notlardaki sürüm varsayımına göre manifest ve ham payload CAB'larını açın:

```powershell
expand.exe -F:* "$root\Cabs\paket_1.cab" "$root\Manifest"
expand.exe -F:* "$root\Cabs\paket_2.cab" "$root\Raw"
Get-ChildItem "$root\Manifest" -Force
Get-ChildItem "$root\Raw" -Force
```

### 5.3 Ana paketten MSI dosyalarını hazırlama

Aşağıdaki isim eşlemesi yalnızca gönderilen notlardaki payload düzeni için geçerlidir. Dosyalar yoksa veya farklı görünüyorsa devam etmeyin; başka payload'ı yanlış adla kurmak ciddi sorun çıkarabilir.

```powershell
$map = @{
    "a0" = "DotNet35x86.msi"
    "a1" = "DotNet35x64.msi"
    "a2" = "DotNet35Regx86.msi"
    "a3" = "DotNet35Regx64.msi"
    "a4" = "DotNet35GACx86.msi"
    "a5" = "DotNet35GACx64.msi"
}

foreach ($k in $map.Keys) {
    $src = Join-Path "$root\Raw" $k
    $dst = Join-Path "$root\MSI" $map[$k]
    if (-not (Test-Path -LiteralPath $src)) { throw "Payload bulunamadı: $src. Manifest ve CAB eşlemesini doğrulayın." }
    Copy-Item -LiteralPath $src -Destination $dst -Force
}
Get-ChildItem "$root\MSI\*.msi"
```

> Kaynağınızın içeriğini doğrulamadan aşağıdaki değişiklik/kurulum adımlarına geçmeyin. MSI `LaunchCondition` satırlarını silmek, uygulama koşullarını ve önkoşul kontrollerini kaldırabilir. Orijinal MSI'ların imza/bütünlük doğrulaması değişiklikten sonra artık geçerli değildir.

### 5.4 MSI `LaunchCondition` tablosunu değiştirme — önerilmez

Bu işlem MSI veritabanını düzenler; Microsoft'un desteklediği bir onarım değildir.

```powershell
foreach ($msi in Get-ChildItem "$root\MSI\*.msi") {
    $inst = New-Object -ComObject WindowsInstaller.Installer
    $db = $inst.GetType().InvokeMember("OpenDatabase", "InvokeMethod", $null, $inst, @($msi.FullName, 1))
    $v = $db.GetType().InvokeMember("OpenView", "InvokeMethod", $null, $db, @("DELETE FROM LaunchCondition"))
    $v.GetType().InvokeMember("Execute", "InvokeMethod", $null, $v, $null) | Out-Null
    $db.GetType().InvokeMember("Commit", "InvokeMethod", $null, $db, $null) | Out-Null
    [System.Runtime.InteropServices.Marshal]::ReleaseComObject($v) | Out-Null
    [System.Runtime.InteropServices.Marshal]::ReleaseComObject($db) | Out-Null
    [System.Runtime.InteropServices.Marshal]::ReleaseComObject($inst) | Out-Null
}
[GC]::Collect()
[GC]::WaitForPendingFinalizers()
```

### 5.5 Ana MSI paketlerini doğrudan kurma — önerilmez

Aşağıdaki kurulum sırası ve payload adları notlardan alınmıştır, paket sürümüne göre doğrulanmamıştır. Sessiz kurulum, hataları gözden kaçırabilir; log dosyası oluşturun ve her exit code'u tek başına başarı kanıtı saymayın.

```powershell
$order = @("DotNet35x86.msi", "DotNet35x64.msi", "DotNet35Regx86.msi", "DotNet35Regx64.msi", "DotNet35GACx86.msi", "DotNet35GACx64.msi")
foreach ($msi in $order) {
    $path = Join-Path "$root\MSI" $msi
    if (-not (Test-Path -LiteralPath $path)) { throw "MSI bulunamadı: $path" }
    $log = Join-Path "$root\MSI" ($msi + ".log")
    $p = Start-Process msiexec.exe -ArgumentList @('/i', "`"$path`"", 'ARPSYSTEMCOMPONENT=1', 'MSIFASTINSTALL=7', '/qn', '/norestart', '/L*V', "`"$log`"") -Wait -PassThru
    Write-Host "$msi -> ExitCode: $($p.ExitCode); Log: $log"
    if ($p.ExitCode -notin 0, 3010) { throw "MSI kurulum hatası; inceleyin: $log" }
}
```

### 5.6 Dil paketi CAB'larını çıkarma

```powershell
$lpExe = "C:\sistem\DotNet35LPSetup.exe"
$lpRoot = "C:\sistem\LP_Kurulum"
New-Item -ItemType Directory -Force -Path "$lpRoot\Cabs", "$lpRoot\Manifest", "$lpRoot\Raw", "$lpRoot\MSI" | Out-Null

if (-not (Test-Path -LiteralPath $lpExe)) { throw "Dil paketi kurucusu bulunamadı: $lpExe" }
$bytes = [System.IO.File]::ReadAllBytes($lpExe)
$c = 0
for ($i = 0; $i -lt $bytes.Length - 16; $i++) {
    if ($bytes[$i] -eq 0x4D -and $bytes[$i+1] -eq 0x53 -and $bytes[$i+2] -eq 0x43 -and $bytes[$i+3] -eq 0x46 -and $bytes[$i+4] -eq 0x00) {
        $sz = [System.BitConverter]::ToInt32($bytes, $i + 8)
        if ($sz -gt 1024 -and ($i + $sz) -le $bytes.Length) {
            $c++
            $buf = New-Object byte[] $sz
            [Array]::Copy($bytes, $i, $buf, 0, $sz)
            [System.IO.File]::WriteAllBytes("$lpRoot\Cabs\lp_$c.cab", $buf)
            $i += $sz - 1
        }
    }
}
if ($c -lt 2) { throw "Beklenen dil paketi CAB sayısı bulunamadı. EXE sürümünün paket düzeni farklı olabilir; durduruldu." }
Get-ChildItem "$lpRoot\Cabs"
```

CAB içeriklerini doğruladıktan sonra notlardaki yapıya göre açın ve manifesti inceleyin:

```powershell
expand.exe -F:* "$lpRoot\Cabs\lp_1.cab" "$lpRoot\Manifest"
expand.exe -F:* "$lpRoot\Cabs\lp_2.cab" "$lpRoot\Raw"
Get-ChildItem "$lpRoot\Manifest" -Force
Get-ChildItem "$lpRoot\Raw" -Force
```

### 5.7 Türkçe (`TRK`) dil MSI'larını bulma ve hazırlama

Manifest dosyasının adı paket sürümüne göre değişebilir. Gönderilen notlar dosya adının `0` olduğunu varsayıyor. Manifestte Türkçe payload ve kaynak dosyalarının varlığını doğrulayın; eşleşme yoksa kurulum yapmayın.

```powershell
$manifestPath = Join-Path "$lpRoot\Manifest" "0"
if (-not (Test-Path -LiteralPath $manifestPath)) { throw "Manifest bulunamadı: $manifestPath. Manifest dosya adını ve içeriklerini inceleyin." }
[xml]$xml = Get-Content -LiteralPath $manifestPath
$trkPayloads = @($xml.BurnManifest.Payload | Where-Object { $_.FilePath -match '-TRK\.msi$' })
if ($trkPayloads.Count -eq 0) { throw "Manifestte -TRK.msi payload bulunamadı. Bu paket farklı olabilir." }

foreach ($item in $trkPayloads) {
    $src = Join-Path "$lpRoot\Raw" $item.SourcePath
    $dst = Join-Path "$lpRoot\MSI" $item.FilePath
    if (-not (Test-Path -LiteralPath $src)) { throw "Manifest payload kaynağı bulunamadı: $src" }
    Copy-Item -LiteralPath $src -Destination $dst -Force
}
Get-ChildItem "$lpRoot\MSI\*.msi"
```

Dil MSI'larında da `LaunchCondition` silme işlemi aynı şekilde uygulanabilir, ancak yine desteklenmeyen ve önerilmeyen bir değişikliktir:

```powershell
foreach ($msi in Get-ChildItem "$lpRoot\MSI\*.msi") {
    $inst = New-Object -ComObject WindowsInstaller.Installer
    $db = $inst.GetType().InvokeMember("OpenDatabase", "InvokeMethod", $null, $inst, @($msi.FullName, 1))
    $v = $db.GetType().InvokeMember("OpenView", "InvokeMethod", $null, $db, @("DELETE FROM LaunchCondition"))
    $v.GetType().InvokeMember("Execute", "InvokeMethod", $null, $v, $null) | Out-Null
    $db.GetType().InvokeMember("Commit", "InvokeMethod", $null, $db, $null) | Out-Null
    [System.Runtime.InteropServices.Marshal]::ReleaseComObject($v) | Out-Null
    [System.Runtime.InteropServices.Marshal]::ReleaseComObject($db) | Out-Null
    [System.Runtime.InteropServices.Marshal]::ReleaseComObject($inst) | Out-Null
}
[GC]::Collect()
[GC]::WaitForPendingFinalizers()
```

### 5.8 Dil MSI'larını doğrudan kurma — önerilmez

Gönderilen notlarda `REINSTALL=ALL REINSTALLMODE=vomus` kullanılıyor. Bu parametreler dosya/kayıt verilerini yeniden yazabilir ve mevcut kurulumu bozabilir; temiz kurulumda gerekli oldukları doğrulanmamıştır. Bu yüzden aşağıdaki örnek onları varsayılan olarak kullanmaz. Yine de doğrudan, değiştirilmiş MSI kurulumu desteklenmez.

```powershell
foreach ($msi in Get-ChildItem "$lpRoot\MSI\*.msi") {
    $log = $msi.FullName + ".log"
    $p = Start-Process msiexec.exe -ArgumentList @('/i', "`"$($msi.FullName)`"", 'ARPSYSTEMCOMPONENT=1', 'MSIFASTINSTALL=7', '/qn', '/norestart', '/L*V', "`"$log`"") -Wait -PassThru
    Write-Host "$($msi.Name) -> ExitCode: $($p.ExitCode); Log: $log"
    if ($p.ExitCode -notin 0, 3010) { throw "Dil paketi MSI kurulum hatası; inceleyin: $log" }
}
```

### 5.9 Doğrulama ve geçici dosyalar

```powershell
Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v3.5" -ErrorAction SilentlyContinue
Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v3.5\1055" -ErrorAction SilentlyContinue
Get-ChildItem "C:\Windows\Microsoft.NET\Framework*\v3.5\tr" -ErrorAction SilentlyContinue
```

Yalnızca logları ve çıkarılan dosyaları inceleyip ihtiyaç kalmadığında, doğru klasör olduklarını iki kez kontrol ettikten sonra geçici klasörleri silebilirsiniz:

```powershell
Remove-Item "C:\sistem\Net35_Kurulum", "C:\sistem\LP_Kurulum" -Recurse -Force -WhatIf
# WhatIf çıktısının doğru olduğundan emin olduktan sonra, ayrı bir komutla -WhatIf'i kaldırarak çalıştırın.
```

Bu yöntemle kayıt defteri anahtarı veya klasör oluşması .NET'in Windows servicing tarafından resmi olarak tanındığını kanıtlamaz. Yeniden başlatıp Windows Update'i kontrol etmek de başarılı servis kaydının garantisi değildir. Windows Update'in tanıması ve güvenlik yamalarının uygulanması Microsoft'un resmi güncelleme/servicing mekanizmasıyla ayrıca doğrulanmalıdır.

## 6. Başarı ölçütü

İşlem ancak aşağıdakiler birlikte sağlandığında başarılı kabul edilmelidir:

- İşletim sistemi .NET Framework 3.5'i beklenen biçimde kaydediyor.
- İlgili uygulama .NET 3.5 çalışma zamanını gerçekten kullanabiliyor.
- Gerekliyse doğru dil paketi kurucusu temel bileşeni artık eksik olarak raporlamıyor.
- Microsoft'un 26H1 destek ve güncelleme bilgileriyle Windows Update durumu tutarlı.

Yalnızca “Setup completed”, tek bir MSI exit code'u veya elle oluşturulmuş kayıt defteri değeri yeterli doğrulama değildir.

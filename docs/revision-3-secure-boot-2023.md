# Revizyon 3 — Windows 11 medyasını Windows UEFI CA 2023 ile güncelleme ve doğrulama

Bu revizyon, önceki notları değiştirmeden kullanıcının paylaştığı ISO oluşturma, imza zinciri kontrolü ve Secure Boot DB durumunu doğrulama adımlarını ayrı bir rehberde toplar.

> **Önemli:** Kurulum medyasındaki `bootx64.efi` imzasını güncellemek, bilgisayarın anakart UEFI `db` veritabanına sertifika eklemekle aynı işlem değildir. ISO'nun imza zincirinin doğrulanması cihazda Secure Boot'un güncellendiğini veya cihazın bu medyadan kesin önyükleyeceğini kanıtlamaz. UEFI veritabanı güncellemesi kritik bir firmware/güvenlik değişikliğidir; Microsoft'un güncel cihaz talimatlarını ve OEM uyumluluğunu izleyin.

## 1. Ön koşullar

- Microsoft'un [PCA2023 imzalı önyükleme yöneticisi kullanacak Windows medyasını güncelleme rehberini](https://support.microsoft.com/en-us/servicing/os/windows/2025/02/updating-windows-bootable-media-to-use-the-pca2023-signed-boot-manager) okuyun ve en güncel resmi `Make2023BootableMedia.ps1` dosyasını buradan temin edin.
- Kaynak medya, betiğin gerektirdiği güncellemeleri içermelidir. Betiğin kendi kullanım bilgisindeki 2024-4B veya sonraki güncelleme gereksinimini doğrulayın.
- ISO oluşturmak için Windows ADK içindeki `oscdimg.exe` gerekebilir. Betiği yönetici PowerShell'de çalıştırın; betik `oscdimg.exe` indirmeyi teklif ederse yalnızca resmi Microsoft sembol sunucusunu kullanın ve betiğin hash doğrulamasını atlamayın.
- Orijinal ISO'yu ve BitLocker kurtarma anahtarını yedekleyin. Kaynak/yeni ISO için yeterli NTFS çalışma alanı bulunduğundan emin olun.

Aşağıdaki örneklerde betik `C:\sistem\ISO\Make2023BootableMedia.ps1`, orijinal ISO ise `C:\sistem\` altındadır. Yolları kendi dosyalarınıza göre değiştirin.

## 2. ISO'yu otomatik bağlayıp yeni ISO oluşturma

Aşağıdaki örnek sürücü harfini otomatik bulur ve `finally` bloğunda kaynak ISO'yu çıkarır. Kaynak imajı mount edemediğinde, volume harfi bulunmadığında veya betik hata verdiğinde işlem hata ile durur.

```powershell
$ErrorActionPreference = 'Stop'
$scriptPath = 'C:\sistem\ISO\Make2023BootableMedia.ps1'
$sourceIso = 'C:\sistem\tr-tr_windows_11_consumer_editions_version_26h1_updated_march_2026_x64_dvd_d6bda57b.iso'
$outputIso = 'C:\sistem\ISO\Win11_2023Signed.iso'

if (-not (Test-Path -LiteralPath $scriptPath)) { throw "Betik bulunamadı: $scriptPath" }
if (-not (Test-Path -LiteralPath $sourceIso)) { throw "Kaynak ISO bulunamadı: $sourceIso" }

# Yalnızca bu PowerShell işlemi için geçerlidir; betiği yine de kaynağından doğrulayın.
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force

$mountedByThisRun = $false
try {
    $mount = Mount-DiskImage -ImagePath $sourceIso -PassThru
    $mountedByThisRun = $true
    $volume = $mount | Get-Volume | Where-Object DriveLetter | Select-Object -First 1
    if (-not $volume) { throw 'Bağlanan ISO için sürücü harfi alınamadı.' }
    $mediaPath = "$($volume.DriveLetter):\"
    Write-Host "Kaynak ISO bağlandı: $mediaPath" -ForegroundColor Green

    & $scriptPath -MediaPath $mediaPath -TargetType ISO -ISOPath $outputIso
    if (-not (Test-Path -LiteralPath $outputIso)) {
        throw "Betik çıktı ISO'sunu oluşturmadı: $outputIso"
    }
    Write-Host "Çıktı ISO'su oluşturuldu: $outputIso" -ForegroundColor Cyan
}
finally {
    if ($mountedByThisRun) {
        Dismount-DiskImage -ImagePath $sourceIso -ErrorAction SilentlyContinue | Out-Null
    }
}
```

Betik kaynak medyayı yalnızca kopyalamaz; `boot.wim` içindeki uygun önyükleme dosyalarını kullanarak yeni medyayı üretir. Betiğin gerçek çıktısını, hatalarını ve exit durumunu kontrol edin. Kaynak ISO ile yeni ISO'yu aynı dosya olarak göstermeyin.

## 3. Yeni ISO'daki EFI imza zincirini kontrol etme

Bu örnek ISO'yu bağlar, otomatik sürücü harfini bulur, `bootx64.efi` Authenticode imzasını ve zincir elemanlarını gösterir, ardından ISO'yu her koşulda çıkarmaya çalışır.

```powershell
$ErrorActionPreference = 'Stop'
$newIso = 'C:\sistem\ISO\Win11_2023Signed.iso'
if (-not (Test-Path -LiteralPath $newIso)) { throw "ISO bulunamadı: $newIso" }

$mountedByThisRun = $false
try {
    $mount = Mount-DiskImage -ImagePath $newIso -PassThru
    $mountedByThisRun = $true
    $volume = $mount | Get-Volume | Where-Object DriveLetter | Select-Object -First 1
    if (-not $volume) { throw 'Bağlanan ISO için sürücü harfi alınamadı.' }

    $efiPath = "$($volume.DriveLetter):\efi\boot\bootx64.efi"
    if (-not (Test-Path -LiteralPath $efiPath)) { throw "EFI dosyası bulunamadı: $efiPath (ARM64 medyada dosya adı farklı olabilir)." }

    $sig = Get-AuthenticodeSignature -FilePath $efiPath
    Write-Host "İmza durumu: $($sig.Status)"
    if ($sig.SignerCertificate) {
        Write-Host "İmzalayan: $($sig.SignerCertificate.Subject)"
        Write-Host "Sertifika geçerliliği: $($sig.SignerCertificate.NotBefore) -> $($sig.SignerCertificate.NotAfter)"

        $chain = New-Object System.Security.Cryptography.X509Certificates.X509Chain
        [void]$chain.Build($sig.SignerCertificate)
        Write-Host 'Zincir elemanları:'
        $chain.ChainElements | ForEach-Object { Write-Host " -> $($_.Certificate.Subject)" }
        $has2023CA = $chain.ChainElements | Where-Object { $_.Certificate.Subject -match 'Windows UEFI CA 2023' }
        if (-not $has2023CA) { Write-Warning 'Sertifika zincirinde Windows UEFI CA 2023 bulunamadı; çıktıyı ve medyanın mimarisini inceleyin.' }
    } else {
        Write-Warning 'İmzalayan sertifika alınamadı; dosyanın durumunu ve kaynağını kontrol edin.'
    }
}
finally {
    if ($mountedByThisRun) {
        Dismount-DiskImage -ImagePath $newIso -ErrorAction SilentlyContinue | Out-Null
    }
}
```

Beklenen sonuç, `bootx64.efi` için `Status` değerinin `Valid` olması ve zincirde `Windows UEFI CA 2023` görülmesidir. X.509 zincirini Windows üzerinde kurmak, firmware'in Secure Boot DB'sinde bu CA'nın bulunduğunu tek başına kanıtlamaz. ARM64 medyada önyükleme dosyası `bootaa64.efi` olabilir.

## 4. Cihazdaki Secure Boot durumunu kontrol etme

Yönetici PowerShell'de:

```powershell
Confirm-SecureBootUEFI
[System.Text.Encoding]::ASCII.GetString((Get-SecureBootUEFI -Name db).Bytes) -match 'Windows UEFI CA 2023'
Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecureBoot\Servicing' -ErrorAction SilentlyContinue
```

- `Confirm-SecureBootUEFI` yalnızca Secure Boot'un açık olup olmadığını bildirir; sertifika geçişinin tamamlandığını göstermez.
- `db` çıktısında CA adını bulmak yararlı bir kontrol olabilir; firmware değişkenlerinin biçimi ve görünürlüğü cihaza göre değişebilir. Bu kontrolün sonucu OEM/Microsoft durum bilgileriyle birlikte değerlendirilmelidir.
- `Servicing` anahtarındaki alanlar durum/ilerleme bilgisi sağlayabilir; belirli bir değerin tüm cihazlarda başarıyı kesin gösterdiğini varsaymayın.

## 5. DB/KEK güncellemesi — cihaz için resmi süreci izleyin

Windows Update, Windows'un Secure Boot servicing mekanizması ve OEM firmware güncellemeleri geçişin tercih edilen yollarıdır. Önce Windows Update'i kurun, cihaz üreticisinin BIOS/UEFI güncelleme notlarını inceleyin ve Microsoft'un güncel Secure Boot rehberindeki cihazınıza uygun adımları takip edin. Secure Boot/firmware güncellemesi öncesinde:

1. BitLocker kurtarma anahtarının erişilebilir yedeğini alın; kurumsal cihazlarda BT yöneticinizle görüşün.
2. Güç kaynağını kesmeyin ve üreticinin BIOS güncelleme talimatlarına uyun.
3. Secure Boot anahtarlarını BIOS'ta elle temizlemeyin veya varsayılan anahtarları yüklemeyin; bu, Windows'un önyüklemesini etkileyebilir.
4. Aşağıdaki registry/task komutlarını her cihazda körlemesine çalıştırmayın. Yalnızca Microsoft'un ilgili cihaz/dağıtım senaryosu için yayımladığı güncel yönerge bu yöntemi açıkça istiyorsa, yöneticiniz/OEM ile doğruladıktan sonra kullanın.

Kullanıcı tarafından sağlanan yöntem, Windows'un servicing mekanizmasına bir güncelleme isteği yazıp zamanlanmış görevi başlatır; UEFI NVRAM'e doğrudan sertifika yazmaz. `AvailableUpdates` bitmask değerinin anlamı Windows sürümü ve Microsoft'un servicing yönergelerine göre doğrulanmalıdır. Geçerli cihaz durumu kontrol edilmeden aşağıdaki değer uygulanmamalıdır.

Microsoft'un sizin senaryonuz için açıkça yönlendirdiği durumda, ilgili resmi talimata göre şu iki komut kullanılabilir; bunları evrensel/garantili adım olarak değerlendirmeyin:

```powershell
Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecureBoot' -Name 'AvailableUpdates' -Value 0x5944 -Type DWord -Force
Start-ScheduledTask -TaskPath '\Microsoft\Windows\PI\' -TaskName 'Secure-Boot-Update'
```

Görev çalıştıktan sonra, Microsoft'un talimatına göre yeniden başlatın (gerekirse birden fazla kez) ve yukarıdaki durum kontrollerini tekrarlayın. Görev adı sisteminizde yoksa, hata veriyorsa veya güncelleme durumu ilerlemiyorsa registry değerini tekrar tekrar değiştirmeyin; Windows sürümü, görev durumu, firmware ve OEM yönergelerini inceleyin.

## Kaynaklar

- [Microsoft: Updating Windows bootable media to use the PCA2023 signed boot manager](https://support.microsoft.com/en-us/servicing/os/windows/2025/02/updating-windows-bootable-media-to-use-the-pca2023-signed-boot-manager)
- [Microsoft Windows IT Pro Blog: Updating Microsoft Secure Boot keys](https://techcommunity.microsoft.com/blog/windows-itpro-blog/updating-microsoft-secure-boot-keys/4055324)
- [Microsoft Q&A: Manual installation of 2023 Secure Boot certificate](https://learn.microsoft.com/en-us/answers/questions/5967657/manual-installation-of-2023-secure-boot-certificat)

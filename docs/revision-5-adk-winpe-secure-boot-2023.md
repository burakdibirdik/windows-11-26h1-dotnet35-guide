# Revizyon 5 - Windows 11 26H1 ve Önceki Sürümler için Windows UEFI CA 2023 İmzalı ISO ve Secure Boot Rehberi

Bu belge, Microsoft'un resmi `Make2023BootableMedia.ps1` betiğiyle Windows kurulum medyasını Windows UEFI CA 2023 sertifikasıyla uyumlu hâle getiren ve Secure Boot DB durumunu doğrulayan yeni bir revizyondur.

> **Önemli:** Bu metindeki komutlar Secure Boot veya UEFI DB değişikliği yapabilir. BitLocker kurtarma anahtarını yedekleyin; önce OEM'nin firmware desteğini ve Microsoft'un güncel Secure Boot sertifika geçiş rehberini kontrol edin. `bootx64.efi` imzası ile cihazın DB veritabanı aynı şey değildir.

## 1. Resmi indirmeler

- [Windows ADK - indirme ve kurulum](https://learn.microsoft.com/en-us/windows-hardware/get-started/adk-install)
- [Windows PE - WinPE indirme ve kurulum](https://learn.microsoft.com/en-us/windows-hardware/manufacture/desktop/download-winpe--windows-pe)
- [Windows ADK araçları ve sürüm notları](https://learn.microsoft.com/en-us/windows-hardware/get-started/what-s-new-in-kits-and-tools)
- [Windows kurulum medyasını PCA2023 imzalı önyükleme yöneticisiyle güncelleme](https://support.microsoft.com/en-us/servicing/os/windows/2025/02/updating-windows-bootable-media-to-use-the-pca2023-signed-boot-manager)
- [Microsoft Secure Boot anahtarlarını güncelleme](https://techcommunity.microsoft.com/blog/windows-itpro-blog/updating-microsoft-secure-boot-keys/4055324)

### ADK sürüm seçimi

Microsoft'un yukarıdaki resmi sayfasından, hedef Windows sürümüne uygun **aynı veya daha yeni ADK ve WinPE eklentisi** kullanılmalıdır. Genel tablo:

| Hedef | ADK/WinPE eşleşmesi |
|---|---|
| Windows 11 26H1 | Windows 11 26H1 için yayımlanan 28000 dalı; Microsoft'un güncel 26H1 paketi ve sürüm notları esas alınır |
| Windows 11 24H2/25H2/26H2 | Microsoft'un 26100 dalına ait ADK/WinPE eklentisi |
| Windows 10 ve daha eski Windows 11 sürümleri | Hedef sürümün desteklediği ve Microsoft'un ADK sayfasında listelediği eşleşen sürüm |

Yapı numaraları, ADK'nın güncellemeleri ve WinPE eki sürümleri zamanla değişebilir. Kullanıcı notlarındaki 10.1.28000.3481 veya 10.1.26100.9457 gibi sayıları sabit öneri olarak kullanmadan Microsoft'un ADK sayfasındaki güncel ilişkili dosyaları doğrulayın.

## 2. ADK ve WinPE kurulumu

ISO oluşturmak için `oscdimg.exe` **Windows ADK'nın Deployment Tools** bileşeniyle gelir. `Make2023BootableMedia.ps1` betiği ISO/USB medyayı güncellerken `boot.wim` gibi medyanın kaynak dosyalarını okur. Microsoft'un WinPE talimatları ayrı WinPE eklentisinin kurulmasını önerir; WinPE ile ISO üretilecekse eşleşen WinPE eklentisi de kurulmalıdır.

GUI ile kurulum:

1. Microsoft'tan resmi ADK `adksetup.exe` dosyasını indirip çalıştırın.
2. Yalnızca Windows medyası üretmek için en az **Deployment Tools** bileşenini seçin.
3. Aynı sürümün resmi **Windows PE add-on** `adkwinpesetup.exe` dosyasını indirip kurun.
4. Windows'u yeniden başlatmayın; sürüm yüklendikten sonra `oscdimg.exe` dosyasını doğrulayın:

```powershell
where.exe oscdimg.exe
Get-Item "C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg\oscdimg.exe" -ErrorAction SilentlyContinue
```

Sessiz kurulum örneği; ADK kurulum dosyalarının gerçek sürümleri ve yolları için Microsoft sayfasını esas alın:

```powershell
Start-Process "C:\sistem\ADK\adksetup.exe" -ArgumentList "/features OptionId.DeploymentTools /quiet /norestart" -Wait
Start-Process "C:\sistem\ADK\adkwinpesetup.exe" -ArgumentList "/features OptionId.WindowsPreinstallationEnvironment /quiet /norestart" -Wait
```

## 3. Microsoft betiğini hazırlama

Microsoft'un güncel destek sayfasından `Make2023BootableMedia.ps1` betiğini indirin. Betiği PowerShell'in geçici klasöre, üçüncü taraf paketlere veya değiştirilmiş bir kopyaya koymayın. Betiğin Authenticode imzasını doğrulayın:

```powershell
Get-AuthenticodeSignature "C:\sistem\ISO\Make2023BootableMedia.ps1" | Format-List Status,StatusMessage,SignerCertificate
```

Kaynak ISO:

- 2024-4B veya daha yeni güncellemeleri içermelidir.
- Betiğin desteklediği mimariye uygun olmalıdır.
- İşlem için ISO, betik, staging ve çıktı için yeterli disk alanı bırakın.

## 4. ISO oluşturma: sürücü harfi otomatik

```powershell
$ErrorActionPreference = 'Stop'
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force

$scriptPath = 'C:\sistem\ISO\Make2023BootableMedia.ps1'
$sourceIso  = 'C:\sistem\tr-tr_windows_11_consumer_editions_version_26h1_updated_march_2026_x64_dvd_d6bda57b.iso'
$outputIso  = 'C:\sistem\ISO\Win11_2023Signed.iso'

if (-not (Test-Path -LiteralPath $scriptPath)) { throw "Betik bulunamadı: $scriptPath" }
if (-not (Test-Path -LiteralPath $sourceIso)) { throw "Kaynak ISO bulunamadı: $sourceIso" }

$mounted = $false
try {
    $mount = Mount-DiskImage -ImagePath $sourceIso -PassThru
    $mounted = $true
    $volume = $mount | Get-Volume | Where-Object DriveLetter | Select-Object -First 1
    if (-not $volume) { throw 'Bağlanan ISO için sürücü harfi alınamadı.' }

    $mediaPath = "$($volume.DriveLetter):\"
    Write-Host "Kaynak ISO bağlandı: $mediaPath"
    & $scriptPath -MediaPath $mediaPath -TargetType ISO -ISOPath $outputIso

    if (-not (Test-Path -LiteralPath $outputIso)) {
        throw "Betik çıktı ISO dosyasını oluşturmadı: $outputIso"
    }
    Write-Host "Yeni ISO oluşturuldu: $outputIso" -ForegroundColor Green
}
finally {
    if ($mounted) {
        Dismount-DiskImage -ImagePath $sourceIso -ErrorAction SilentlyContinue | Out-Null
    }
}
```

## 5. Çıktı ISO'daki EFI imzasını doğrulama

```powershell
$ErrorActionPreference = 'Stop'
$outputIso = 'C:\sistem\ISO\Win11_2023Signed.iso'
if (-not (Test-Path -LiteralPath $outputIso)) { throw "ISO bulunamadı: $outputIso" }

$mounted = $false
try {
    $mount = Mount-DiskImage -ImagePath $outputIso -PassThru
    $mounted = $true
    $volume = $mount | Get-Volume | Where-Object DriveLetter | Select-Object -First 1
    if (-not $volume) { throw 'Bağlanan ISO için sürücü harfi alınamadı.' }

    $efiPath = "$($volume.DriveLetter):\efi\boot\bootx64.efi"
    if (-not (Test-Path -LiteralPath $efiPath)) {
        throw "bootx64.efi bulunamadı. ARM64 medyada dosya adı bootaa64.efi olabilir: $efiPath"
    }

    $signature = Get-AuthenticodeSignature -FilePath $efiPath
    Write-Host "Imza Durumu : $($signature.Status)" -ForegroundColor Green

    if ($signature.SignerCertificate) {
        Write-Host "Imzalayan : $($signature.SignerCertificate.Subject)"
        Write-Host "Gecerlilik: $($signature.SignerCertificate.NotBefore) -> $($signature.SignerCertificate.NotAfter)"

        $chain = New-Object System.Security.Cryptography.X509Certificates.X509Chain
        [void]$chain.Build($signature.SignerCertificate)
        $chain.ChainElements | ForEach-Object {
            Write-Host " -> $($_.Certificate.Subject)"
        }
    }
}
finally {
    if ($mounted) {
        Dismount-DiskImage -ImagePath $outputIso -ErrorAction SilentlyContinue | Out-Null
    }
}
```

Beklenen `Status` değeri `Valid`; zincirde `CN=Microsoft Windows`, `CN=Windows UEFI CA 2023` ve `Microsoft Root Certificate Authority 2010` görülebilir. Bu kontrol medyanın imza zincirini doğrular; firmware DB'deki sertifikanın var olduğunu tek başına kanıtlamaz.

## 6. Cihaz durumunu doğrulama

Yönetici PowerShell oturumunda:

```powershell
Confirm-SecureBootUEFI
[System.Text.Encoding]::ASCII.GetString((Get-SecureBootUEFI -Name db).Bytes) -match 'Windows UEFI CA 2023'
Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\SecureBoot\Servicing' -ErrorAction SilentlyContinue
```

- `Confirm-SecureBootUEFI` Secure Boot durumunu bildirir.
- `db` sorgusu, firmware değişkeninde yeni CA'nın görünmesini kontrol eder; donanım/firmware sürümüne göre yorumlanmalıdır.
- Servicing anahtarındaki alanlar ilerleme bilgisi verebilir; tek başına başarı kanıtı değildir.

## 7. Secure Boot DB güncellemesi

Önce OEM BIOS/UEFI güncellemesini ve Windows Update yollarını kontrol edin. BitLocker kurtarma anahtarını yedekleyin. Manuel kullanım ancak Microsoft'un ilgili cihaz/talimatı tarafından açıkça destekleniyorsa ve cihaz OEM'iyle uyumluluk doğrulanmışsa yapılmalıdır.

```powershell
Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecureBoot' -Name 'AvailableUpdates' -Value 0x5944 -Type DWord -Force
Start-ScheduledTask -TaskPath '\Microsoft\Windows\PI\' -TaskName 'Secure-Boot-Update'
```

Görevden sonra bir veya daha fazla yeniden başlatma gerekebilir. Görev veya kayıt yoksa bu komutların tekrar tekrar çalıştırılması yerine sürüm, görev durumu, Windows Update, OEM firmware ve cihaz uyumluluğu incelenmelidir. UEFI anahtarlarını BIOS'tan rastgele silmeyin veya varsayılan anahtarları yüklemeyin.

## 8. Güvenli geri dönüş ve kontrol

- Windows Update ve OEM BIOS işlemleri arasında beklenmeyen yeniden başlatma yapmayın.
- Firmware güncellemesi sırasında güç kaynağını kesmeyin.
- Kurulumdan önce BitLocker kurtarma anahtarını cihaz dışında saklayın.
- Güncelleme başarısız olursa Microsoft/OEM desteğine loglar ve firmware sürümüyle başvurun.
- `diskpart`, EFI klasör silme veya Secure Boot anahtar silme komutları yalnızca kurtarma uzmanı ve yedekli sistemde kullanılmalıdır.

## Resmi kaynaklar

- [Download and install Windows ADK](https://learn.microsoft.com/en-us/windows-hardware/get-started/adk-install)
- [Download WinPE](https://learn.microsoft.com/en-us/windows-hardware/manufacture/desktop/download-winpe--windows-pe)
- [What's new in the Windows ADK](https://learn.microsoft.com/en-us/windows-hardware/get-started/what-s-new-in-kits-and-tools)
- [Updating Windows bootable media to use the PCA2023 signed boot manager](https://support.microsoft.com/en-us/servicing/os/windows/2025/02/updating-windows-bootable-media-to-use-the-pca2023-signed-boot-manager)
- [Updating Microsoft Secure Boot keys](https://techcommunity.microsoft.com/blog/windows-itpro-blog/updating-microsoft-secure-boot-keys/4055324)

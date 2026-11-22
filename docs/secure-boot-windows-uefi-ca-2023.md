# Windows UEFI CA 2023 ve Secure Boot

## Güvenli doğrulama

Secure Boot'un etkin olduğunu doğrulamak için Yönetici PowerShell oturumunda:

```powershell
Confirm-SecureBootUEFI
```

UEFI sertifika veritabanında Windows UEFI CA 2023 sertifikasının olup olmadığını kontrol etmek için:

```powershell
[System.Text.Encoding]::ASCII.GetString((Get-SecureBootUEFI db).bytes) -match "Windows UEFI CA 2023"
```

`True` döndürmesi beklenir; ancak yalnızca bu kontrol önyükleme dosyasının gerçekten 2023 zinciriyle imzalandığını kanıtlamaz. ISO veya kurulum medyasının `bootx64.efi` dosyasını Authenticode zinciriyle doğrulayın.

## ISO/USB medya doğrulaması

Bağlı ISO üzerindeki EFI dosyasının imzasını kontrol etmek için:

```powershell
$isoPath = "C:\ISO\Win11_2023Signed.iso"
$m = Mount-DiskImage -ImagePath $isoPath -PassThru
$drv = ($m | Get-Volume).DriveLetter + ":"
$sig = Get-AuthenticodeSignature "$drv\efi\boot\bootx64.efi"
$sig.Status
$sig.SignerCertificate.Subject

$chain = New-Object System.Security.Cryptography.X509Certificates.X509Chain
$chain.Build($sig.SignerCertificate) | Out-Null
$chain.ChainElements | ForEach-Object {
    Write-Host $_.Certificate.Subject
}
Dismount-DiskImage -ImagePath $isoPath | Out-Null
```

Beklenen imza zincirinde **Microsoft Windows**, **Windows UEFI CA 2023** ve **Microsoft Root Certificate Authority 2010** görünebilir.

## Kurtarma medyası oluşturma

Microsoft'un Secure Boot için 2023 sertifikalı önyükleme medyası betiğini kullanabilir veya güncel Windows kurulum medyasını resmi Microsoft araçlarıyla hazırlayabilirsiniz.

Örnek kullanım — betik Microsoft'tan alınmışsa:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\Make2023BootableMedia.ps1 -MediaPath "C:\Media\Win11.iso" -TargetType ISO -ISOPath "C:\ISO\Win11_2023Signed.iso"
```

## EFI kurtarması için uyarılar

- `diskpart`, EFI bölümünü yanlış seçerseniz sistemin önyüklemesini bozabilir.
- EFI dosyalarını silmeden önce başka sistemden veri yedeğini alın.
- Anakart üreticisinin BIOS/UEFI güncellemesi varsa önce resmi güncellemeyi uygulayın.
- Secure Boot'u kapatarak veya Windows Repair modunda rastgele dosya silmek kalıcı veri kaybına neden olabilir.

## Resmi medya güncelleme bilgisi

- [Servicing — Windows Bootable Media 2025](https://support.microsoft.com/en-us/servicing/os/windows/2025/02/updating-windows-bootable-media-to-use-the-pca2023-signed-boot-manager)

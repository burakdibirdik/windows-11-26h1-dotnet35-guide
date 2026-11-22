# Revizyon 7 — ISO içinden SecureBootRecovery.efi çıkarma, imza raporu ve Ventoy'a kopyalama

Bu revizyon, kullanıcının verdiği PowerShell kodunu **değiştirmeden** içerir. Kod en yeni ISO'yu seçmeye çalışır, ISO'yu bağlar, boot EFI imza zincirini inceler, `install.wim` içinden `SecureBootRecovery.efi` çıkarmaya çalışır, rapor üretir ve ISO'yu çıkarır.

> **Önemli:** ISO'dan dosya çıkarmak, Secure Boot UEFI `db` veritabanına sertifika eklemez. `SecureBootRecovery.efi` dosyasını Ventoy'un exFAT veri bölümüne kopyalamak da dosyayı çalıştırmaz. Ventoy içinden bu EFI dosyasını başlatma Microsoft tarafından genel desteklenen bir kurtarma prosedürü olarak belgelenmemiştir; firmware ve dosya sistemi uyumluluğu değişebilir. Secure Boot/firmware değişikliğinden önce BitLocker kurtarma anahtarınızı yedekleyin ve Casper/OEM ile Microsoft'un ilgili talimatlarını izleyin.

## Ön koşul ve işlem sırası

1. Önce [Revizyon 5 — Windows ADK/WinPE ve PCA2023 imzalı ISO oluşturma](revision-5-adk-winpe-secure-boot-2023.md) içindeki resmi Microsoft `Make2023BootableMedia.ps1` medya güncelleme adımlarını tamamlayın. Kaynak ISO ile yeni oluşturulan 2023 imzalı ISO'yu ayrı adlarla saklayın.
2. Bu betik ISO klasöründeki en son değiştirilmiş `.iso` dosyasını seçer. Yanlış ISO seçilmemesi için betiği hedef ISO'nun bulunduğu klasörden çalıştırın ve klasördeki ISO listesini önceden kontrol edin.
3. Başlat menüsünden **Windows PowerShell** açın. Örneğin ISO'lar `C:\sistem\ISO` içindeyse şu komutla o klasöre geçin:

```powershell
Set-Location 'C:\sistem\ISO'
Get-ChildItem -File -Filter '*.iso' | Sort-Object LastWriteTime -Descending | Select-Object Name,FullName,LastWriteTime
```

4. Aşağıdaki kod bloğunu kopyalayın. PowerShell penceresine tıklayıp `Ctrl+V` ile yapıştırın; yapıştırmadan önce tamamını seçip kopyaladığınızdan emin olun. Komutlar çalışırken PowerShell penceresini kapatmayın. Yolları değiştirmeden kullanacaksanız ISO'yu `C:\sistem\ISO` içine koyun.
5. Betik sonunda rapor Not Defteri'nde açılır. Rapor yalnızca bu kodun yaptığı dosya/imza kontrollerini yansıtır; UEFI `db` güncellemesinin başarıyla yapıldığını göstermez.

## Kullanıcının verdiği PowerShell kodu — değiştirilmeden

```powershell
$ErrorActionPreference = 'Stop'

# 1. Çalışılan klasördeki en güncel .iso dosyasını otomatik bul (yoksa varsayılan yolu dene)
$workDir = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
$foundIso = Get-ChildItem -LiteralPath $workDir -Filter '*.iso' | Sort-Object LastWriteTime -Descending | Select-Object -First 1
$isoPath = if ($foundIso) { $foundIso.FullName } else { 'C:\sistem\ISO\Win11-26h1_2023Signed.iso' }

if (-not (Test-Path -LiteralPath $isoPath)) { throw "ISO bulunamadı: $isoPath" }

$desktop = [Environment]::GetFolderPath('Desktop')
$destination = Join-Path $desktop 'Secure Boot 2023 sertifika inceleme'
$reportPath = Join-Path $destination 'Sertifika_ve_ISO_Raporu.txt'
$mountDir = Join-Path $env:TEMP ("SecureBootWim_" + [guid]::NewGuid().ToString('N'))
$isoMounted = $false
$wimMounted = $false

New-Item -ItemType Directory -Force -Path $destination | Out-Null

try {
    # 2. ISO'yu bağla ve sürücü harfi atanana kadar bekle
    Dismount-DiskImage -ImagePath $isoPath -ErrorAction SilentlyContinue | Out-Null
    Mount-DiskImage -ImagePath $isoPath | Out-Null
    $isoMounted = $true

    $driveLetter = $null
    for ($i = 0; $i -lt 15; $i++) {
        Start-Sleep -Milliseconds 500
        $vol = Get-DiskImage -ImagePath $isoPath | Get-Volume -ErrorAction SilentlyContinue
        if ($vol -and $vol.DriveLetter) {
            $driveLetter = $vol.DriveLetter
            break
        }
    }
    if (-not $driveLetter) { throw 'ISO bağlandı fakat sürücü harfi alınamadı.' }
    $drive = "$($driveLetter):"

    # 3. Boot EFI imza zincirini kontrol et (x64 / ARM64 uyumlu)
    $bootEfi = if (Test-Path -LiteralPath (Join-Path $drive 'efi\boot\bootx64.efi')) {
        Join-Path $drive 'efi\boot\bootx64.efi'
    } elseif (Test-Path -LiteralPath (Join-Path $drive 'efi\boot\bootaa64.efi')) {
        Join-Path $drive 'efi\boot\bootaa64.efi'
    } else {
        throw "EFI önyükleme dosyası (bootx64.efi / bootaa64.efi) bulunamadı."
    }

    $isoSignature = Get-AuthenticodeSignature -FilePath $bootEfi
    $isoChain = @()
    if ($isoSignature.SignerCertificate) {
        $chain1 = New-Object System.Security.Cryptography.X509Certificates.X509Chain
        [void]$chain1.Build($isoSignature.SignerCertificate)
        $isoChain = @($chain1.ChainElements | ForEach-Object { $_.Certificate.Subject })
    }

    # 4. WIM / ESD tespiti
    $wimPath = Join-Path $drive 'sources\install.wim'
    $esdPath = Join-Path $drive 'sources\install.esd'
    if (Test-Path -LiteralPath $wimPath) {
        $imagePath = $wimPath
    } elseif (Test-Path -LiteralPath $esdPath) {
        throw 'Bu ISO install.esd kullanıyor. Doğrudan mount edilemez; önce DISM ile WIM formatına dönüştürün.'
    } else {
        throw 'ISO sources klasöründe install.wim veya install.esd bulunamadı.'
    }

    $images = @(Get-WindowsImage -ImagePath $imagePath)
    if ($images.Count -eq 0) { throw "Windows imajı listelenemedi: $imagePath" }
    $imageInfo = $images | Where-Object ImageIndex -eq 1 | Select-Object -First 1

    # 5. SecureBootRecovery.efi dosyasını çıkar (7-Zip varsa 2 sn, yoksa standart Mount)
    $efiDestination = Join-Path $destination 'SecureBootRecovery.efi'
    $7zExe = @('C:\Program Files\7-Zip\7z.exe', 'C:\Program Files (x86)\7-Zip\7z.exe') | Where-Object { Test-Path $_ } | Select-Object -First 1

    if ($7zExe) {
        & $7zExe e $imagePath 'Windows\Boot\EFI\SecureBootRecovery.efi' '1\Windows\Boot\EFI\SecureBootRecovery.efi' "-o$destination" -y | Out-Null
    }

    if (-not (Test-Path -LiteralPath $efiDestination)) {
        New-Item -ItemType Directory -Force -Path $mountDir | Out-Null
        Mount-WindowsImage -ImagePath $imagePath -Index 1 -Path $mountDir -ReadOnly | Out-Null
        $wimMounted = $true
        $sourceEfi = Join-Path $mountDir 'Windows\Boot\EFI\SecureBootRecovery.efi'
        if (-not (Test-Path -LiteralPath $sourceEfi)) {
            throw "SecureBootRecovery.efi bu imajda yok: $sourceEfi"
        }
        Copy-Item -LiteralPath $sourceEfi -Destination $efiDestination -Force
    }

    # 6. Çıkarılan EFI dosyasının dış imzasını, SHA256 değerini ve iç gömülü sertifika yükünü analiz et
    $efiSignature = Get-AuthenticodeSignature -FilePath $efiDestination
    $efiHash = (Get-FileHash -LiteralPath $efiDestination -Algorithm SHA256).Hash
    $efiChain = @()
    if ($efiSignature.SignerCertificate) {
        $chain2 = New-Object System.Security.Cryptography.X509Certificates.X509Chain
        [void]$chain2.Build($efiSignature.SignerCertificate)
        $efiChain = @($chain2.ChainElements | ForEach-Object { $_.Certificate.Subject })
    }

    $has2023 = ($isoChain -join ' ') -match 'Windows UEFI CA 2023'
    $rawText = [System.Text.Encoding]::ASCII.GetString([System.IO.File]::ReadAllBytes($efiDestination))
    $embedded2023 = $rawText.Contains('Windows UEFI CA 2023')
    $embeddedKek  = $rawText.Contains('Microsoft Windows UEFI Key Exchange Key')

    $lines = @(
        '==================================================================',
        '   WINDOWS ISO / SECURE BOOT EFI ANALIZ RAPORU',
        '==================================================================',
        ('Tarih                        : {0}' -f (Get-Date -Format 'dd.MM.yyyy HH:mm:ss')),
        ('ISO Dosyasi                  : {0}' -f $isoPath),
        ('Windows Imaji                : {0} (Build {1})' -f $imageInfo.ImageName, $imageInfo.Version),
        ('ISO Boot EFI Imza Durumu     : {0}' -f $isoSignature.Status),
        ('ISO 2023 Sertifika Durumu    : {0}' -f $(if ($has2023) { 'EVET (Windows UEFI CA 2023)' } else { 'HAYIR (PCA 2011)' })),
        'ISO Boot EFI Sertifika Zinciri:',
        $(if ($isoChain.Count) { $isoChain | ForEach-Object { "  -> $_" } } else { '  -> zincir alinamadi' }),
        '------------------------------------------------------------------',
        ('Cikarilan Dosya              : {0}' -f $efiDestination),
        ('Cikarilan EFI Imza Durumu    : {0}' -f $efiSignature.Status),
        ('Cikarilan EFI SHA256         : {0}' -f $efiHash),
        'Cikarilan EFI Dis Sertifika Zinciri:',
        $(if ($efiChain.Count) { $efiChain | ForEach-Object { "  -> $_" } } else { '  -> zincir alinamadi' }),
        '------------------------------------------------------------------',
        ('EFI Govdesinde UEFI CA 2023 Yuku : {0}' -f $(if ($embedded2023) { 'MEVCUT (DOGRULANDI)' } else { 'BULUNAMADI' })),
        ('EFI Govdesinde UEFI KEK Yuku     : {0}' -f $(if ($embeddedKek) { 'MEVCUT (DOGRULANDI)' } else { 'BULUNAMADI' })),
        '=================================================================='
    )
    $lines | Out-File -LiteralPath $reportPath -Encoding utf8 -Force
}
finally {
    if ($wimMounted) {
        Dismount-WindowsImage -Path $mountDir -Discard -ErrorAction SilentlyContinue | Out-Null
    }
    if ($isoMounted) {
        Dismount-DiskImage -ImagePath $isoPath -ErrorAction SilentlyContinue | Out-Null
    }
    if (Test-Path -LiteralPath $mountDir) {
        Remove-Item -LiteralPath $mountDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Write-Host "Rapor: $reportPath" -ForegroundColor Green
Write-Host "Cikarilan EFI: $(Join-Path $destination 'SecureBootRecovery.efi')" -ForegroundColor Cyan
Start-Process notepad.exe -ArgumentList "`"$reportPath`""
```

## 3. Kodun değiştirilmeden kullanımıyla ilgili dikkat notları

Kod yukarıdaki blokta kullanıcı tarafından verildiği biçimde bırakılmıştır; bu nedenle aşağıdaki hususlar kod içinde düzeltilmemiştir:

- `$PSScriptRoot` bir PowerShell betik dosyası (`.ps1`) olarak çalıştırıldığında betik klasörüdür. Kodu konsola yapıştırınca genellikle boş olur ve geçerli çalışma klasörü kullanılır.
- Klasördeki son değiştirilen ISO otomatik seçilir. Birden fazla ISO varsa istenmeyen kaynak veya eski ISO seçilebilir; betiği çalıştırmadan önce klasörü kontrol edin.
- Başta `Dismount-DiskImage` çağrısı, aynı ISO'yu başka bir işlem kullanıyor olsa bile ayırabilir. ISO'nun başka yerde kullanılmadığından emin olun.
- `install.esd` dalındaki hata metninin aksine, bu betik ESD'yi dönüştürmez; çalışmaya devam etmek için WIM kullanan ISO gerekir.
- 7-Zip'in WIM içindeki dosya yolunu/index'i ele alış biçimi farklılık gösterebilir. Kopyalama başarısız olursa kod DISM ile index 1'i salt okunur bağlayıp dener. `SecureBootRecovery.efi` index 1'de yoksa dosya bulunamaz.
- `Get-AuthenticodeSignature` ile zincir kurulması bir kontrol sağlar; Windows zincir oluşturma sonucu firmware'in kendi Secure Boot `db` trust policy'sini ispatlamaz.
- `$embedded2023` ve `$embeddedKek` kontrolleri EFI'nin ham baytlarında ASCII metin arar. Metnin bulunması, sertifika paketinin kriptografik olarak doğrulandığını veya firmware'e yüklendiğini kanıtlamaz; bulunmaması da kesin yokluk kanıtı değildir. Rapordaki “DOGRULANDI” ifadesini bu sınırlı metin eşleşmesi olarak yorumlayın.
- ISO boot imzasında CA 2023 metni yoksa rapor bunu PCA 2011 diye adlandırır; bu otomatik sınıflandırma imza durumu, mimari ve zincir oluşturma başarısızlığını ayrı raporlamaz. Sonucu sertifika zinciri satırlarıyla birlikte değerlendirin.

## 4. EFI dosyasını Ventoy USB'sine kopyalama

Ventoy'u yalnızca [resmi indirme sayfasından](https://www.ventoy.net/en/download.html) indirin; Secure Boot davranışı için [resmi Ventoy Secure Boot belgesini](https://www.ventoy.net/en/doc_secure.html) izleyin. Ventoy kurulumu USB'deki verileri silebilir; USB içeriğini yedekleyin ve doğru aygıtı seçin.

1. Kodun çıkardığı `SecureBootRecovery.efi` dosyasını ve raporu masaüstündeki `Secure Boot 2023 sertifika inceleme` klasöründe bulun.
2. Dosyanın kaynağını ve imza durumunu inceleyin. Kaynak ISO'da dosya bulunduğu veya rapor oluşturulduğu için onun cihazınıza uygun olduğu varsaymayın.
3. Ventoy USB'yi Windows'ta açın ve dosyayı isterseniz Ventoy'un normal **data** bölümünde örneğin `EFI\Recovery\SecureBootRecovery.efi` olarak saklayın. Bu yalnızca dosya kopyalama işlemidir.
4. Ventoy'un kendi Secure Boot/MOK enrollment adımlarını Microsoft'un UEFI `db` sertifika güncellemesiyle karıştırmayın. Ventoy MOK kaydı, Windows UEFI CA 2023'ü firmware `db`'sine yüklemez.
5. Ventoy data bölümü exFAT ise UEFI firmware'in dosya tarayıcısı onu okuyacağını garanti etmez. Microsoft, Ventoy'un exFAT bölümünden bu EFI uygulamasını seçip çalıştırmayı evrensel desteklenen yöntem olarak belgelemez. Firmware'in Boot from File özelliği ve desteklediği dosya sistemi için Casper/OEM talimatı gerekir.
6. EFI uygulamasını çalıştırmak firmware değişikliği riski taşır. Bu belgedeki dosya çıkarma/kopyalama işlemi onu çalıştırmaz. UEFI DB değişikliği için Microsoft/OEM'in modelinize uygun talimatı yoksa denemeyin; özellikle BitLocker anahtarı elinizde değilken firmware ayarlarını değiştirmeyin.
7. Bir EFI uygulaması yeniden başlatırsa bu tek başına güncellemenin başarıyla yazıldığını kanıtlamaz. Windows açılırsa Secure Boot ve DB durumunu Microsoft/OEM talimatına göre ayrıca doğrulayın.

## Resmi kaynaklar

- [Microsoft PCA2023 imzalı önyükleme yöneticisiyle Windows medyasını güncelleme](https://support.microsoft.com/en-us/servicing/os/windows/2025/02/updating-windows-bootable-media-to-use-the-pca2023-signed-boot-manager)
- [Microsoft Project Mu — Secure Boot Recovery açıklaması](https://microsoft.github.io/mu/dyn/mu_plus/MsApplicationPkg/SecureBootRecovery/Readme/)
- [Microsoft Secure Boot playbook (2026 sertifika geçişi)](https://techcommunity.microsoft.com/blog/windows-itpro-blog/secure-boot-playbook-for-certificates-expiring-in-2026/4469235)
- [Ventoy resmi indirme sayfası](https://www.ventoy.net/en/download.html)
- [Ventoy Secure Boot belgesi](https://www.ventoy.net/en/doc_secure.html)
- [Windows ADK ve WinPE resmi indirmeleri](https://learn.microsoft.com/en-us/windows-hardware/get-started/adk-install)

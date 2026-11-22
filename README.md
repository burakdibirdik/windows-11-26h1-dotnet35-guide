# Windows 11 26H1 .NET Framework 3.5 ve Secure Boot Dokümantasyonu

Bu depo, Windows 11 26H1 üzerinde .NET Framework 3.5 kurulumu ve Secure Boot 2023 sertifika dönemlerini ele alan teknik notları, doğrulama komutlarını ve güvenli kurtarma yollarını toplar.

> **Önemli:** Bu depodaki komutları çalıştırmadan önce Windows'un yedeğini alın ve yalnızca gerçek Microsoft kaynaklarından indirilmiş dosyaları kullanın.

## İçindekiler

- [Windows 11 26H1 .NET Framework 3.5](docs/dotnet-35-windows-11-26h1.md)
- [Secure Boot ve Windows UEFI CA 2023](docs/secure-boot-windows-uefi-ca-2023.md)
- [PowerShell betiği: Kurulum medyasını 2023 sertifikasıyla güncelleme](scripts/Make2023BootableMedia.ps1)

## Genel güvenlik uyarıları

- MSIX/MSI/EXE dosyalarını resmi kaynaktan indirin.
- Microsoft tarafından imzalanmamış veya doğrulanmamış betikleri **Run as Administrator** yetkisiyle çalıştırmayın.
- DiskPart ve EFI bölümü komutları veri kaybına yol açabilir.
- Güvenli kurtarma prosedürü kullanmadan önce kişisel dosyaları dışarıya yedekleyin.
- Windows'un desteklenen sürümüne göre güncel kurulumu tercih edin.

## Katkı

Hatalı veya yanıltıcı bilgiler varsa konu açarak düzeltme önerisi gönderebilirsiniz.

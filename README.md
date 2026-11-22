# Windows 11 26H1 .NET Framework 3.5 ve Secure Boot Notları

Windows 11 26H1'de .NET Framework 3.5 kurulumunun "başarılı/tamamlandı" demesine rağmen bileşenin sistemde görünmemesi ve dil paketi kurucusunun önce temel .NET 3.5'i istemesi için gözlem, doğrulama ve sorun giderme notları.

## İçindekiler

- [.NET Framework 3.5: 26H1 kurulum ve dil paketi sorun giderme](docs/dotnet-35-windows-11-26h1.md)
- [Revizyon 2: MSI çıkarma akışı (deneysel)](docs/revision-2-dotnet35-experimental.md)
- [Secure Boot / Windows UEFI CA 2023](docs/secure-boot-windows-uefi-ca-2023.md)
- [Revizyon 3: 2023 imzalı ISO ve Secure Boot doğrulaması](docs/revision-3-secure-boot-2023.md)

## Önemli

.NET kurulum paketlerini düzenleyerek MSI `LaunchCondition` satırlarını kaldırmak, Microsoft'un desteklenen kurulum yolu değildir. Bu depoda söz konusu yöntemin başarıyla kurduğu veya Windows Update'in paketi tanıyacağı garanti edilmez. Belgede yöntem, yalnızca deneysel yaklaşım olarak ve riskleriyle açıklanmıştır. Önce Microsoft'un sürüme özel resmi paketini kullanın.

Secure Boot/UEFI veritabanı güncellemeleri cihazın önyükleme güvenini etkiler. BitLocker kurtarma anahtarınızı güvenli bir yerde saklayın, OEM BIOS/UEFI güncellemelerini ve Microsoft talimatlarını kontrol edin; kaynağı doğrulanmamış betik veya firmware/DB değişikliği çalıştırmayın.

DiskPart, EFI veya Windows Installer değişiklikleri veri kaybına ve servis edilebilirlik sorunlarına yol açabilir. Önemli dosyalarınızı yedeklemeden yönetici yetkisiyle işlem yapmayın.

# Windows 11 26H1 .NET Framework 3.5 ve Secure Boot Notları

Windows 11 26H1'de .NET Framework 3.5 kurulumunun "başarılı/tamamlandı" demesine rağmen bileşenin sistemde görünmemesi ve dil paketi kurucusunun önce temel .NET 3.5'i istemesi için gözlem, doğrulama ve sorun giderme notları.

## İçindekiler

- [.NET Framework 3.5: 26H1 kurulum ve dil paketi sorun giderme](docs/dotnet-35-windows-11-26h1.md)
- [Secure Boot / Windows UEFI CA 2023](docs/secure-boot-windows-uefi-ca-2023.md)

## Önemli

.NET kurulum paketlerini düzenleyerek MSI `LaunchCondition` satırlarını kaldırmak, Microsoft'un desteklenen kurulum yolu değildir. Bu depoda söz konusu yöntemin başarıyla kurduğu veya Windows Update'in paketi tanıyacağı garanti edilmez. Belgede yöntem, yalnızca deneysel/son çare yaklaşımı olarak ve riskleriyle açıklanmıştır. Önce Microsoft'un sürüme özel resmi paketini kullanın.

DiskPart, EFI veya Windows Installer değişiklikleri veri kaybına ve servis edilebilirlik sorunlarına yol açabilir. Önemli dosyalarınızı yedeklemeden yönetici yetkisiyle işlem yapmayın.

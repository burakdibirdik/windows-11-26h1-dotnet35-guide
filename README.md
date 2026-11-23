# Windows 11 26H1 ve Önceki Sürümler için .NET 3.5 ve Secure Boot Notları

Windows 11 26H1 ve önceki sürümlerde `.NET Framework 3.5` kurulum hataları, dil paketi yükleme problemi ve Windows UEFI CA 2023 medyasıyla Secure Boot durumunu belgeleyen çalışma alanı.

## Belgeler

- [.NET Framework 3.5: 26H1 kurulum ve dil paketi sorunu](docs/dotnet-35-windows-11-26h1.md)
- [Revizyon 2: Deneysel .NET MSI çıkarma akışı](docs/revision-2-dotnet35-experimental.md)
- [Secure Boot / Windows UEFI CA 2023](docs/secure-boot-windows-uefi-ca-2023.md)
- [Revizyon 3: PCA2023 ISO ve Secure Boot doğrulaması](docs/revision-3-secure-boot-2023.md)
- [Revizyon 5: ADK/WinPE ve 2023 imzalı ISO oluşturma](docs/revision-5-adk-winpe-secure-boot-2023.md)
- [Revizyon 6: Ventoy ve SecureBootRecovery.efi senaryosu](docs/revision-6-ventoy-securebootrecovery.md)
- [Revizyon 7: ISO'dan SecureBootRecovery.efi çıkarma ve Ventoy'a kopyalama](docs/revision-7-securebootrecovery-iso-ventoy.md)
- [Revizyon 8: Eski cihazlarda kurulum arayüzü ve USB portu seçimi](docs/revision-8-legacy-setup-usb-port-tips.md)

## Önemli

.NET MSI çıkarma/LaunchCondition değiştirme yöntemi Microsoft tarafından desteklenen kurulum yolu değildir. Secure Boot, UEFI DB ve firmware işlemleri önyükleme güvenini etkileyebilir; önce BitLocker kurtarma anahtarınızı yedekleyin ve OEM/Microsoft yönergelerini izleyin.

- [Windows ADK resmi indirme sayfası](https://learn.microsoft.com/en-us/windows-hardware/get-started/adk-install)
- [Windows PE resmi indirme sayfası](https://learn.microsoft.com/en-us/windows-hardware/manufacture/desktop/download-winpe--windows-pe)
- [Ventoy resmi indirme sayfası](https://www.ventoy.net/en/download.html)
- [Microsoft PCA2023 önyükleme medyası rehberi](https://support.microsoft.com/en-us/servicing/os/windows/2025/02/updating-windows-bootable-media-to-use-the-pca2023-signed-boot-manager)

# Windows 11 26H1 ve Önceki Sürümler için .NET 3.5, Secure Boot ve Kurtarma Notları

> 📂 **Tüm ikili BCD dosyalarını, Ventoy şablonlarını ve kaynak belgeleri indirmek için:** [GitHub Deposunu Açın (burakdibirdik/windows-11-26h1-dotnet35-guide)](https://github.com/burakdibirdik/windows-11-26h1-dotnet35-guide)


Windows 11 26H1 ve önceki sürümler için `.NET Framework 3.5`, Secure Boot/UEFI CA 2023, BCD ve WinRE kurtarma profilleri, `bcdedit` kullanımı ve Ventoy otomasyonu hakkında Türkçe teknik notlar ve saha belgeleri.

**Konular:** `windows-11` · `26h1` · `bcdedit` · `winre` · `ventoy` · `secure-boot`

## Belgeler

- [.NET Framework 3.5: 26H1 kurulum ve dil paketi sorunu](docs/dotnet-35-windows-11-26h1.md)
- [Revizyon 2: Deneysel .NET MSI çıkarma akışı](docs/revision-2-dotnet35-experimental.md)
- [Secure Boot / Windows UEFI CA 2023](docs/secure-boot-windows-uefi-ca-2023.md)
- [Revizyon 3: PCA2023 ISO ve Secure Boot doğrulaması](docs/revision-3-secure-boot-2023.md)
- [Revizyon 5: ADK/WinPE ve 2023 imzalı ISO oluşturma](docs/revision-5-adk-winpe-secure-boot-2023.md)
- [Revizyon 6: Ventoy ve SecureBootRecovery.efi senaryosu](docs/revision-6-ventoy-securebootrecovery.md)
- [Revizyon 7: ISO'dan SecureBootRecovery.efi çıkarma ve Ventoy'a kopyalama](docs/revision-7-securebootrecovery-iso-ventoy.md)
- [Revizyon 8: Eski cihazlarda kurulum arayüzü ve USB portu seçimi](docs/revision-8-legacy-setup-usb-port-tips.md)

## Kurtarma BCD Profilleri ve Ventoy Otomasyonu

- [BCD profilleri ve kurtarma ortamı](BCD/README.md)
- [BCD profilleri ve kullanılan komutlar](BCD/komutlar-ve-profiller.md)
- [BCD ve sürücü yükleme saha bulguları](BCD/saha-bulgulari.md)
- [BCD ve sürücü yükleme saha bulguları 2](BCD/bcd-surucu-saha-bulgulari-2.md)
- [Eski nesil cihazlarda Windows sürücüsü yükleme sorunları](BCD/eski-nesil-surucu-yukleme-sorunlari.md)
- [Secure Boot açıkken sürücü saha testi](BCD/eski-nesil-surucu-saha-testi.md)
- [Eski nesil cihazlar için BCD profili](BCD/BCD_eskinesilciihazlar)
- [Metro cihazlar için BCD profili](BCD/BCD_metroac%C4%B1k)
- [WinPE başlangıç yapılandırması](winpeshl.ini)
- [Ventoy yapılandırması](ventoy/ventoy.json)
- [Otomatik kurulum yanıt dosyası](ventoy/autounattend.xml)

> BCD dosyaları ikili `registry-hive` biçimindedir; metin editörüyle düzenlenmemelidir. Değişikliklerden önce yedek alın ve doğru depoyu `bcdedit /store <yol> /enum all /v` ile doğrulayın.

## Önemli

.NET MSI çıkarma/LaunchCondition değiştirme yöntemi Microsoft tarafından desteklenen kurulum yolu değildir. Secure Boot, UEFI DB ve firmware işlemleri önyükleme güvenini etkileyebilir; donanım ve Windows sürümü üretici belgelerine göre değerlendirilmelidir.

- [Windows ADK resmi indirme sayfası](https://learn.microsoft.com/en-us/windows-hardware/get-started/adk-install)
- [Windows PE resmi indirme sayfası](https://learn.microsoft.com/en-us/windows-hardware/manufacture/desktop/download-winpe--windows-pe)
- [Ventoy resmi indirme sayfası](https://www.ventoy.net/en/download.html)
- [Microsoft PCA2023 önyükleme medyası rehberi](https://support.microsoft.com/en-us/servicing/os/windows/2025/02/updating-windows-bootable-media-to-use-the-pca2023-signed-boot-manager)

---

## 🏆 Windows Insider Programı Kıdem ve Başarı Rozetleri (2016–2026)

Bu bölüm, **10 Şubat 2016** tarihinden bu yana sürdürülen Windows Insider erken önizleme (Canary / Dev / Beta) test geçmişini ve kazanılan Microsoft başarı rozetlerini belgeliyor.

### 1. Aşamalar ve Yıldönümü Rozetleri (`Milestones`)

![Windows Insider Yıldönümü Rozetleri](./asamalar.jpg)

| Rozet Adı | Durum |
| :--- | :---: |
| **Insider since 10.02.2016** | ✅ Aktif |
| **Shipped Windows 11!** | ✅ Aktif |
| **Windows Insider Program turns 5!** | ✅ Aktif |
| **Windows Insider Program 6th Anniversary** | ✅ Aktif |
| **Windows Insider Program 7th Anniversary** | ✅ Aktif |
| **Windows Insider Program 8th Anniversary** | ✅ Aktif |
| **Windows Insider Program 9th Anniversary** | ✅ Aktif |
| **Windows Insider Program 10th Anniversary** | ✅ Aktif |
| **Windows Insider Program 11th Anniversary** | ✅ Aktif |
| **Windows Insider Program 12th Anniversary** | 🔒 Kilitli |

### 2. Sınırlı Dağıtımlar (`Limited Flights` — Rütbe Rozetleri)

![Windows Insider Sınırlı Dağıtım Rozetleri](./sınırlı%20dağıtımlar.jpg)

Microsoft'un sınırlı/erken dağıtım yapılarını (**Canary / Dev**) kurup test ettikçe kazanılan iki seri (Mor ve Yeşil) ve rütbeler:

| Rütbe / Rozet Adı | Seri & Yıldız |
| :--- | :---: |
| **Flight Lieutenant** *(Uçuş Teğmeni)* | 🟣 Mor Seri (1 Yıldız) |
| **Flight Captain** *(Uçuş Yüzbaşısı)* | 🟣 Mor Seri (2 Yıldız) |
| **Flight Major** *(Uçuş Binbaşısı)* | 🟣 Mor Seri (3 Yıldız) |
| **Flight Lieutenant** *(Uçuş Teğmeni)* | 🟢 Yeşil Seri (1 Yıldız) |
| **Flight Captain** *(Uçuş Yüzbaşısı)* | 🟢 Yeşil Seri (2 Yıldız) |
| **Flight Major** *(Uçuş Binbaşısı)* | 🟢 Yeşil Seri (3 Yıldız) |

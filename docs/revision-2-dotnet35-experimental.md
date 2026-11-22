# Revizyon 2 — Windows 11 26H1 .NET 3.5 + Türkçe dil paketi iş akışı

Bu, ana [.NET 3.5 kurulum notlarının](dotnet-35-windows-11-26h1.md) altına eklenen ayrı bir revizyondur. Önceki teşhis ve uyarılar korunur; bu sayfa kullanıcının paylaştığı `DotNet35Setup.exe` / `DotNet35LPSetup.exe` akışını hangi sırayla uygulamayı düşündüğünü bir arada gösterir.

> **Durum: deneysel, Microsoft tarafından desteklenmiyor ve bu depoda doğrulanmış bir çözüm değil.** Burn paketinden MSI çıkarmak, `LaunchCondition` tablosunu değiştirmek ve MSI'ları doğrudan çalıştırmak imza/bütünlük doğrulamasını bozar ve Windows servicing kayıtlarını beklenmedik biçimde etkileyebilir. `Setup Completed`, MSI kodu `0` veya Windows Update'in sonradan güncelleme sunması tek başına bu yöntemin güvenli/başarılı olduğunu kanıtlamaz. Ana veya üretim bilgisayarında çalıştırmayın.

## Sorunun tarif edilen hali

- Windows 11 26H1 / 28000+ üzerinde temel kurucu tamamlandı mesajı veriyor.
- .NET Framework 3.5 uygulamalarda/sistemde kurulu görünmüyor.
- Dil paketi kurucusu temel .NET 3.5'in önce kurulmasını istiyor.

Bu akış, kurulum sarmalayıcısındaki build kontrolünü atlayıp içerideki MSI'ları kurma önerisini belgeliyor; bu bir resmi çözüm taahhüdü değildir.

## Resmi indirme ve hazırlık

1. `winver` ile Windows sürüm/build numarasını kontrol edin.
2. Yalnızca Windows 11 26H1'e uygun resmi Microsoft paketlerini indirin. Microsoft'un [Windows 11 .NET Framework 3.5 kurulum rehberini](https://learn.microsoft.com/en-us/dotnet/framework/install/dotnet-35-windows-11), [FAQ sayfasını](https://learn.microsoft.com/en-us/dotnet/framework/install/dotnet-35-windows-11-faq) ve [Microsoft .NET Framework indirme sayfasını](https://dotnet.microsoft.com/en-us/download/dotnet-framework) kullanın. İlgili sürüm için sunulmayan bir doğrudan URL'yi tahmin etmeyin.
3. EXE'lerin Microsoft dijital imzasını doğrulayın. Dosyaları `C:\sistem\` altına şu adlarla yerleştirin:
   - `C:\sistem\DotNet35Setup.exe`
   - `C:\sistem\DotNet35LPSetup.exe`
4. Deneme yapılacaksa geri alınabilir snapshot'ı bulunan yalıtılmış VM ve yedek kullanın. Yönetici yetkisi tek başına güvenlik sağlamaz.

## Uygulama sırası — kullanıcının gönderdiği kodlara göre

Aşağıdaki ayrıntılı PowerShell blokları ana [kurulum/sorun giderme belgesinin 5. bölümünde](dotnet-35-windows-11-26h1.md#5-paylaşılan-msi-çıkarma-yöntemi--deneysel-ve-desteklenmeyen) yer alır. Bu revizyon, onları çalıştırma sırasını ayırır:

1. **Temel kurucu CAB'larını çıkar:** Ana belgede 5.2'deki `$exe` ve `$root` bölümü `DotNet35Setup.exe` içindeki MSCF imzalı CAB bloklarını bulur ve `C:\sistem\Net35_Kurulum\Cabs` altına yazar.
2. **Manifest ve payload'ları aç:** Yalnızca CAB içeriği ve sırası doğrulandıktan sonra `paket_1.cab` manifest için, `paket_2.cab` ham payload için açılır. Dosya/sıra isimleri paket sürümüne göre değişebilir.
3. **Temel MSI'ları hazırla:** 5.3'teki `a0`–`a5` eşlemesi yalnızca gönderilen notlardaki varsayımdır. Gerçek manifest/payload eşleşmesini doğrulamadan bu isimlerle devam etmeyin.
4. **MSI koşullarını değiştirme:** 5.4'teki `DELETE FROM LaunchCondition` MSI veritabanını değiştirir. Bu adım desteklenmez; MSI imza/bütünlük güvencesini kaybeder ve kurulum koşullarını atlayabilir.
5. **Temel MSI'ları sırayla kurma:** 5.5'teki sıra `DotNet35x86`, `DotNet35x64`, `Reg x86/x64`, `GAC x86/x64` şeklindedir. Günlükleri inceleyin; exit code `0` tek başına .NET servicing'in doğru kurulduğunu göstermez.
6. **Dil paketi CAB'larını çıkar:** `DotNet35LPSetup.exe` için 5.6'daki akışı kullanıp CAB içeriklerini listeleyin ve manifest/payload yapısını kontrol edin.
7. **Türkçe MSI'ları bul:** 5.7'deki `-TRK.msi` filtresi ve manifest adı `0` varsayımlarını paketin kendi manifestiyle doğrulayın. Başka dil gerekiyorsa locale/payload adını doğrulayın; yalnızca uzantı veya isim benzerliğine güvenmeyin.
8. **Dil MSI'larını kur:** 5.8'deki doğrudan kurulum da desteklenmeyen deneysel adımdır. Notlardaki `REINSTALL=ALL REINSTALLMODE=vomus` parametreleri mevcut dosya/kayıt verilerini yeniden yazabildiğinden varsayılan çözüm olarak eklenmemiştir.
9. **Doğrula:** 5.9'daki kayıt defteri/klasör kontrollerini yapın, uygulama testi gerçekleştirin ve yeniden başlatın. Bu kontroller Windows Update'in paketi resmi olarak servis ettiğini tek başına doğrulamaz.

## Beklenen kontroller

```powershell
Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v3.5" -ErrorAction SilentlyContinue
Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v3.5\1055" -ErrorAction SilentlyContinue
Get-ChildItem "C:\Windows\Microsoft.NET\Framework*\v3.5\tr" -ErrorAction SilentlyContinue
```

Türkçe dil kaynağı için verilen `1055` ve `tr` örnekleridir; paketin gerçek kayıt düzeni farklı olabilir. Ana paketin görünmesi, dil paketinin etkin olduğu veya Windows Update'in onu tanıdığı anlamına gelmez.

## Geri alma ve temizleme

Test VM'sinde beklenmeyen sonuç çıkarsa snapshot'a geri dönmek, tek tek MSI/kayıt dosyalarını elle silmekten daha güvenlidir. Geçici CAB/MSI çalışma klasörlerini temizlemeden önce günlükleri saklayın ve yolları doğrulayın. Bu yöntem gerçek sisteme uygulanmışsa dosyaları rastgele silmek veya kayıt defterini düzenlemek yerine Microsoft desteğine hata kodları ve kurulum günlükleriyle başvurun.

## Başarı iddiası için gerekenler

- .NET 3.5 gerçek bir uygulama tarafından kullanılabiliyor olmalı.
- Dil paketi artık temel .NET eksik uyarısı vermemeli.
- Windows'un servicing/güncelleme durumu, Microsoft'un bu build için yayımladığı bilgiyle uyumlu olmalı.

Yalnızca kurulum sihirbazının tamamlandı bildirimi, tek MSI exit code'u, kayıt anahtarı/klasör veya KB numarası iddiayı doğrulamaz. Kullanıcı notlarında geçen KB5127696 bu akışla ilgili çözüm olduğu burada doğrulanmadı; Microsoft'un build'e özel destek makalesindeki güncel KB bilgisini esas alın.

# Windows 11 26H1: .NET Framework 3.5 ve dil paketi kurulum sorunu

## Belirti

Windows 11 26H1 (28000 serisi) için indirilen `DotNet35Setup.exe` kurucusu "kurulum tamamlandı" benzeri bir sonuç gösterebilir; ancak .NET Framework 3.5 uygulamalar tarafından kullanılamaz veya sistemde kurulu görünmez. Sonrasında `DotNet35LPSetup.exe` dil paketi kurucusu temel .NET Framework 3.5'in önce kurulması gerektiğini söyleyebilir.

Bu iki mesaj birlikteyse dil paketi kurulumuna devam etmek yerine önce temel paketin gerçekten kurulu olup olmadığını doğrulayın. Kurucunun tamamlandı mesajı tek başına kurulumun ve kayıt işleminin başarılı olduğunu kanıtlamaz.

## 1. Sürüm ve kurulum paketini doğrula

`Win + R` → `winver` ile Windows sürümünü/build'ini kontrol edin. Yalnızca Windows 11 26H1 için yayımlanmış Microsoft paketlerini kullanın; eski Windows 11 .NET 3.5 kurucuları 26H1 için uygun olmayabilir.

Microsoft kaynakları:

- [Windows 11'de .NET Framework 3.5'i yükleme](https://learn.microsoft.com/en-us/dotnet/framework/install/dotnet-35-windows-11)
- [.NET Framework 3.5 on Windows 11 FAQ](https://learn.microsoft.com/en-us/dotnet/framework/install/dotnet-35-windows-11-faq)
- [Microsoft .NET Framework indirme sayfası](https://dotnet.microsoft.com/en-us/download/dotnet-framework)
- [Windows 11 26H1+ için .NET Framework 3.5 güncelleme bilgisi (KB5087077)](https://support.microsoft.com/en-us/topic/may-12-2026-kb5087077-cumulative-update-for-net-framework-3-5-for-windows-11-version-26h1-build-28000-and-later-2cef455d-75b5-4d95-9cc6-2efc37abac5b)

> İndirme sayfalarının yapısı ve paket bağlantıları değişebilir. Yukarıdaki Microsoft sayfalarındaki Windows 11 26H1'e özel indirme bağlantılarını kullanın; üçüncü taraf dosya arşivlerinden EXE/MSI indirmeyin. Dil paketi de Microsoft'un aynı sürüm için sağladığı resmi dil paketi olmalıdır. Bu belge sabit, doğrudan EXE URL'si vermek yerine resmi ürün sayfalarına yönlendirir.

## 2. Temel .NET 3.5 kurulumunu doğrula

Kurulumdan sonra Yönetici PowerShell'de:

```powershell
Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v3.5" -ErrorAction SilentlyContinue
Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v3.5\1033" -ErrorAction SilentlyContinue
```

Dil/locale alt anahtarı farklı olabilir; örneğin Türkçe için `1055`. Kayıt defteri anahtarlarının varlığı tek başına tüm uygulama uyumluluğunu kanıtlamaz. Kurum/uygulama ortamında ayrıca ilgili uygulamayla test edin.

26H1'de .NET 3.5'in eski Optional Feature/DISM/FOD yöntemleriyle kurulduğunu varsaymayın. Microsoft'un 26H1'e özel talimatları ve paketi belirleyicidir; başka sürümlere ait `Enable-WindowsOptionalFeature`, kaynak ISO'dan `sxs` veya DISM komutlarını körlemesine uygulamayın.

## 3. Kurulum tamamlandı görünüyor ama bileşen yoksa

1. Windows build'ini ve indirdiğiniz kurucunun gerçekten 26H1'e uygun olduğunu yeniden kontrol edin.
2. Kurulum dosyalarını yalnızca Microsoft'un resmi sayfasından yeniden indirin. İndirme tamamlandıktan sonra dosya özelliklerinden dijital imzayı Microsoft adına doğrulayın.
3. Bilgisayarı yeniden başlatın; bekleyen Windows Update işlemlerinin bitmesini bekleyin.
4. Kurucuyu sağ tıklayıp **Yönetici olarak çalıştır** seçeneğiyle tekrar deneyin.
5. Kurulum ve Windows Update hata kodlarını, kurulum günlüğünü ve Olay Görüntüleyicisi kayıtlarını saklayın. Kurulum aracı günlüğünün yeri pakete göre değişebilir; kurucunun oluşturduğu günlük/ayrıntı ekranını inceleyin.
6. Aynı build'de sorun devam ederse Microsoft Learn FAQ ve ilgili 26H1 destek makalesindeki en güncel bilinen sorunları kontrol edin. Hata koduyla Microsoft Support/Feedback Hub'a başvurun.

Başarısız kurulumu "temizlemek" amacıyla rastgele MSI kaldırma, kayıt defteri silme, `WinSxS` değişikliği veya sistem klasörlerini elle silme yapmayın. Bunlar bileşen deposunu ve gelecekteki güncellemeleri bozabilir.

## 4. Dil paketini yükleme sırası

Dil paketi temel .NET Framework 3.5'e bağımlıdır. Bu nedenle:

1. Önce Windows 11 26H1'e uygun temel .NET 3.5 paketini kurun.
2. Kurucunun başarı bildiriminden sonra temel bileşeni doğrulayın; dil paketi tekrar "önce .NET 3.5'i kurun" diyorsa temel kurulum kaydı oluşmamış demektir.
3. Temel paket doğrulanmadan dil paketini tekrar tekrar çalıştırmayın.
4. Microsoft'un aynı Windows sürümü/paket ailesi için sunduğu doğru dil paketini seçip yükleyin.
5. Türkçe locale kontrolü için, paket ilgili dil kaynaklarını içeriyorsa:

```powershell
Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v3.5\1055" -ErrorAction SilentlyContinue
Get-ChildItem "C:\Windows\Microsoft.NET\Framework\v3.5\tr" -ErrorAction SilentlyContinue
```

Yolun veya kayıt anahtarının bulunmaması, ilgili dil paketinin bu pakette nasıl kaydedildiğine bağlı olabilir; Microsoft'un kurulum talimatlarıyla birlikte değerlendirin.

## 5. MSI çıkarma ve LaunchCondition silme hakkında — deneysel, desteklenmeyen

Kullanıcı tarafından sağlanan notlardaki yaklaşım `DotNet35Setup.exe` / `DotNet35LPSetup.exe` içindeki Burn/CAB payload'larını ikili `MSCF` imzasıyla arayıp çıkarmayı, manifestten MSI'ları eşleştirmeyi, `WindowsInstaller.Installer` COM arayüzüyle MSI veritabanındaki `LaunchCondition` satırlarını silmeyi ve MSI'ları doğrudan `msiexec` ile kurmayı öneriyor.

Bu, **Microsoft tarafından belgelenmiş veya desteklenen bir onarım yöntemi değildir** ve bu depoda doğrulanmış bir çözüm olarak sunulmaz. Özellikle:

- `LaunchCondition` satırları yalnızca sürüm kontrolü olmayabilir; paketin uygulanabilirlik ve önkoşul kontrollerini de içerir. Tüm satırları silmek yanlış paket/yanlış sistem üzerinde kurulumu zorlayabilir.
- MSI'ı değiştirmek Microsoft dijital imzasını geçersiz kılar. Kaynağın orijinalliği ve sonradan değişmediği artık imzayla doğrulanamaz.
- Burn manifestindeki payload adları/sıraları sürümler arasında değişebilir; `a0`–`a5`, CAB sırası veya `TRK` eşlemesi varsayımları farklı pakette yanlış dosya seçebilir.
- Doğrudan MSI kurulumu, Windows bileşen servisi/servicing kaydını resmi kurucuyla aynı şekilde oluşturmayabilir. Kurulum mesajı veya MSI exit code `0`, Windows Update'in paketi tanıdığını ya da yamalayacağını kanıtlamaz.
- `REINSTALL=ALL REINSTALLMODE=vomus` gibi parametreler dosya/kayıt kayıtlarını yeniden yazabilir ve mevcut kurulumu bozabilir.
- Böyle bir deneme, yalnızca yedekli ve geri alınabilir test makinesi/VM üzerinde, sonuçların garanti edilmediği bilinerek yapılmalıdır. Ana bilgisayar veya üretim makinesinde uygulamayın.

Bu nedenle bu depo, MSI koşullarını silen ve doğrudan sistem kurulumunu yapan betiği çalıştırılabilir çözüm olarak dağıtmıyor. Amaç, görülen hata durumunu ve neden bu workaround iddiasının kesin çözüm sayılamayacağını kaydetmek; önce Microsoft'un sürüme özel kurucusu ve destek kanalları kullanılmalıdır.

## 6. Başarı ölçütü

İşlem ancak aşağıdakiler birlikte sağlandığında başarılı kabul edilmelidir:

- Kurulum sonrası işletim sistemi .NET Framework 3.5'i beklenen biçimde kaydediyor.
- İlgili uygulama .NET 3.5 çalışma zamanını gerçekten kullanabiliyor.
- Gerekliyse doğru dil paketi kurucusu temel bileşeni artık eksik olarak raporlamıyor.
- Windows Update / Microsoft'un 26H1 destek makalesi ve güncelleme mekanizması sistemin durumuyla tutarlı.

Yalnızca "Setup completed", tek bir MSI exit code'u veya elle oluşturulmuş kayıt defteri değeri yeterli doğrulama değildir.

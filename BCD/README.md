# Eski ve Yeni Nesil Cihazlar için BCD Tabanlı Kurtarma Ortamı

Bu çalışma, harici kurtarma medyasından Windows PE/kurtarma ortamını başlatmayı ve menüden diskteki mevcut Windows kurulumunu seçebilmeyi hedefleyen iki BCD profilini belgeliyor. Eski nesil cihazlarda metin tabanlı/Legacy menü, yeni nesil ve yüksek çözünürlüklü ekranlarda ise grafiksel Standard (Metro) menü profili amaçlanmıştır.

> **Durum notu:** İki BCD ikili dosyası şu anda depo kökünde duruyor; aşağıdaki bağlantılar yüklenen dosyaların kendisine gider. Bu sayfa `BCD/` klasörünü oluşturur ve açıklama/indeks görevi görür. BCD veritabanı ikili dosyalarını metin olarak yeniden oluşturmamak veya değiştirmemek için mevcut ikili dosyaları burada yeniden üretmedim.

- [Eski nesil cihazlar BCD dosyası](../BCD_eskinesilciihazlar%20i%C3%A7in)
- [Metro BCD dosyası](../BCD_metroac%C4%B1k)

## Çalışmanın amacı ve test durumu

Amaç, bilgisayarın dahili Windows önyükleme girdisi hasar görmüş olsa bile harici kurtarma ortamından açılıp BCD menüsündeki **Windows 11 ile devam et** girdisiyle mevcut Windows'u başlatma seçeneği sunmaktır. İkinci hedef, kurtarma ortamında **Başlangıç Ayarları / Güvenli Mod** seçeneğinin kullanılabilir olmasını araştırmaktır.

Paylaşılan saha notlarına göre kurtarma araçları ve Windows'u başlatma seçeneği çalışıyor; eski nesil cihaz profilinde **Gelişmiş seçenekler > Başlangıç Ayarları > Güvenli Mod** akışı henüz çalışmıyor. Bu nedenle bu belge o işlevi tamamlanmış veya tüm makinelerde çalışacağı kanıtlanmış gibi sunmaz. Menü görünürlüğü ve kurtarma akışı Windows derlemesine, WinRE/WinPE imajına, firmware'e ve BCD'nin bulunduğu ortama bağlıdır.

## BCD profilleri

### Eski nesil cihaz profili

Eski firmware ve düşük çözünürlüklü ekranlarla uyumluluğu denemek için metin tabanlı `bootmenupolicy Legacy` yaklaşımı ve `1024x768` ekran çözünürlüğü ayarları kullanılmıştır. Bu profil eski cihaz testleri içindir; Legacy menü desteği firmware ve önyükleme biçimine bağlıdır. UEFI/GPT ile BIOS/MBR senaryoları aynı değildir; UEFI için `winload.efi`, BIOS tabanlı kurulumlarda uygun `winload.exe` yolu ve ayrı BCD/önyükleme dosyaları gerekebilir.

### Yeni nesil cihazlar için Metro profili

Yeni/yüksek çözünürlüklü ekranlarda grafiksel menü ve okunabilirlik amacıyla `bootmenupolicy Standard`, `graphicsresolution 1024x768` ve `highestmode No` değerleri kullanılmıştır. Çözünürlük seçeneğinin uygulanması görüntü donanımının/firmware'in sunduğu modlara bağlıdır; her cihazda tam olarak aynı boyut veya görünüm garanti edilmez.

### Paylaşılan BCD girdilerinin işlevi

Kullanıcının paylaştığı `bcdedit /store "C:\Boot\BCD"` çıktısı ve komut geçmişine göre yapılandırmada şu öğeler bulunuyor:

| BCD öğesi/ayar | Amaç ve dikkat edilmesi gerekenler |
| --- | --- |
| `{bootmgr}` `displayorder`, `default`, `timeout` | BCD menüsündeki girdileri, varsayılan seçimi ve bekleme süresini belirler. Kurtarma ile Windows girişlerinin sırası önemlidir. |
| `device` / `osdevice` `ramdisk=[boot]\sources\boot.wim,...` | Kurtarma/WinPE girdisini WIM imajı ve ramdisk seçenekleriyle başlatır. Medyada belirtilen WIM ve `boot.sdi` yolları mevcut olmalıdır. |
| `winpe Yes`, `detecthal Yes`, `systemroot`, `path` | WinPE önyükleme girdisinin ortam ve yükleyici ayarlarıdır. EFI/BIOS yükleyici yolu kullanılan önyükleme biçimine uygun olmalıdır. |
| `bootmenupolicy Legacy` veya `Standard` | Eski tip önyükleme menüsü ile modern grafik menü davranışı arasında seçim yapar. Profil başına test edilmelidir. |
| `graphicsresolution 1024x768`, `highestmode No` | Önyükleme arayüzü çözünürlüğünü sınırlamayı/otomatik en yüksek modu kullanmamayı dener. Destek firmware'in grafik modlarına bağlıdır. |
| `displaymessage Recovery`, `recoveryenabled Yes` | Önyükleme/kurtarma mesajı ve kurtarma davranışıyla ilgili değerlerdir; tek başlarına Gelişmiş Seçenekler veya Güvenli Mod menüsünü oluşturdukları garanti değildir. |
| `device locate=\Windows\system32\winload.efi`, `osdevice locate=\Windows` | Windows girdisinde bölüm harfi yerine Windows yükleyicisini ve Windows dizinini bulmaya yönelik konum belirleme kullanır. Birden fazla Windows kurulumu veya özel disk düzeninde yanlış bölümü seçme/başlatamama ihtimali vardır; cihazlar arası evrensel çalıştığı varsayılmamalıdır. |
| `isolatedcontext`, `nx`, `usefirmwarepcisettings` | Önyükleme/işletim sistemi seçenekleridir. Donanım, sürücü ve Windows sürümüne göre etkileri değişebilir; yalnızca başarılı test edilmiş sistemlerde kullanılmalıdır. |
| `flightsigning Yes` | Belirli test imzalama senaryolarıyla ilişkilidir. Secure Boot'u veya imza denetimini genel olarak devre dışı bırakan bir ayar gibi değerlendirilmemeli; güvenlik etkileri anlaşılmadan üretim cihazlarında kullanılmamalıdır. |
| `nocrashautoreboot Yes` | Hata sonrası otomatik yeniden başlamayı önlemeye yönelik hata ayıklama davranışıdır; arızayı düzeltmez. |
| `recoverysequence {default}` | Windows girdisinin kurtarma girdisine referans vermesini sağlar. Harici medyadaki BCD, hedef Windows'un yerel kurtarma yapılandırmasıyla aynı şey değildir. |

## Güvenli Mod konusunda önemli ayrım

BCD'de `safeboot minimal` ayarı seçilen Windows girdisini Güvenli Mod'da başlatmayı ister. Bunu yanlış BCD deposuna veya yanlış girdiye uygulamak normal açılışı engelleyebilir. Bu, harici WinPE/WinRE ortamındaki **Başlangıç Ayarları** menüsünün çalıştığını kanıtlamaz.

Ayrıca hedef Windows'ta depolama denetleyicisi sürücüsü (ör. Intel RST/VMD veya RAID) Güvenli Mod'da yüklenemezse `INACCESSIBLE_BOOT_DEVICE` görülebilir. Her sistem için sürücü adı veya SafeBoot kayıt defteri değişikliği tahmin edilmemelidir. Güvenli Mod denemesinden önce hedef bilgisayarın doğru BCD deposunun ve Windows yükleyici tanımlayıcısının belirlenmesi, mevcut BCD'nin yedeklenmesi ve geri dönüş yönteminin hazır olması gerekir.

`recoveryenabled`, `displaymessage` veya özel BCD öğeleri ayarlamak, kurtarma arayüzünde **Başlangıç Ayarları** kutusunu tek başına garanti etmez. Bu menü WinRE bileşenleri, hedef Windows ile kurtarma ortamının ilişkilendirilmesi ve imaj yapılandırmasına da bağlıdır. Bu projede eski profil için güvenli mod seçeneği henüz doğrulanmamıştır.

## BCD değişikliklerini yönetirken

Aşağıdaki örnekler açıklama amaçlıdır; körlemesine çalıştırılacak kurulum betiği değildir. Yönetici yetkisi gerekir. Harfler, BCD yolu ve GUID her bilgisayarda farklı olabileceğinden önce mevcut yapılandırmayı inceleyin ve yedekleyin. Önce test makinesi veya sanal makine kullanın.

```bat
:: BCD deposunu dışa aktararak yedekle (hedef dosya yolunu önceden hazırlayın)
bcdedit /store "C:\Boot\BCD" /export "C:\Boot\BCD.backup"

:: Belirli depodaki girişleri görüntüle; GUID'leri tam görmek için /v kullan
bcdedit /store "C:\Boot\BCD" /enum all /v

:: Örnek: bir girdideki safeboot değerini kaldırıp normal önyüklemeye dön
:: {GUID} yerine gerçekten hedef Windows'a ait doğrulanmış tanımlayıcıyı yazın
bcdedit /store "C:\Boot\BCD" /deletevalue {GUID} safeboot
```

UEFI Sistem Bölümü'nü bağlama, `bcdboot` çalıştırma veya BCD'yi geri yükleme gibi işlemler canlı önyükleme yapılandırmasını değiştirebilir. Örneğin `bcdboot C:\Windows /s S: /f UEFI` yanlış Windows bölümü ya da EFI sistem bölümü seçildiğinde önyükleme dosyalarını yanlış yere yazabilir. Sürücü harflerini WinPE'de varsaymayın; `diskpart` ile bölümleri doğrulayın ve mevcut EFI/BCD yedeğini alın. İlgili komutları test edilmeden bu belgede otomatik uygulama olarak kullanmayın.

## Windows Hello, PIN ve BitLocker

Harici kurtarma medyasından başlatmak veya önyükleme ölçümlerini değiştirmek TPM/Windows Hello korumalı kimlik bilgileri için PIN'in yeniden kurulmasını ya da Microsoft hesabı parolasıyla doğrulamayı gerektirebilir. Bu her cihazda aynı şekilde gerçekleşmez. PIN uyarısı tek başına verilerin kaybolduğu anlamına gelmez; ancak parola ve BitLocker kurtarma anahtarı önceden erişilebilir olmalıdır. BitLocker kurtarma ekranı çıkarsa kurtarma anahtarını kullanın; korumayı veya güvenlik denetimlerini gelişigüzel kapatmayın. Güvenlik ilkesi gerektiriyorsa normal dahili disk önyüklemesine dönün ve Windows Hello durumunu orada yeniden doğrulayın.

## Test ve kapsam

- BCD dosyaları, üretim sisteminde denenmeden önce yedeklenmelidir.
- Eski nesil profil, Metro profil ve UEFI/BIOS senaryoları ayrı ayrı test edilmelidir.
- Kurtarma menüsü, Windows'u başlatma girdisi ve Güvenli Mod akışı ayrı başarı ölçütleridir; birinin çalışması diğerlerini doğrulamaz.
- Önyükleme dosyalarının/BCD'nin değiştirilmesi cihazı açılmaz hâle getirebilir. Bu çalışma, veri yedeği ve çalışan kurtarma medyası olan test sistemlerinde kullanılmalıdır.
- Windows 11 donanım gereksinimlerini atlatma veya imza denetimini değiştirme, cihazı desteklenen hâle getirmez ve güvenlik/güncelleme/kararlılık garantisi sağlamaz.


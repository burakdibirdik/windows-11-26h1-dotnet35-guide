# BCD profilleri ve kullanılan komutlar — ayrıntılı notlar

Bu belge, depoda paylaşılan eski nesil cihaz ve Metro BCD dosyalarını, sohbet sırasında verilen `bcdedit`, `mountvol`, `reg`, `bcdboot` ve diğer komutları ayrı ayrı açıklar. BCD dosyaları ikili (registry-hive biçimli) dosyalardır; metin dosyası gibi düzenlenmemelidir.

## Önemli doğrulama sınırı

Dosyalar depo kökünde ikili BCD olarak bulunuyor. Bu oturumda Windows üzerinde `bcdedit /store <dosya> /enum all /v` çalıştırıp ikili dosyaları işletim sistemi tarafından doğrulama olanağı yok. Bu nedenle aşağıdaki profil çözümlemesi, dosyalarla birlikte kullanıcının paylaştığı `bcdedit` çıktıları ve test notlarına dayanır; yalnızca yüklenmiş dosyanın adına veya 24 KiB boyutuna bakarak her BCD değerinin mevcut olduğunu kesinleştirmek mümkün değildir. Bir dosyanın son durumunu doğrulamanın doğru yolu, kopyasını Windows test ortamında `bcdedit /store` ile okumaktır.

## Dosyalar ve profiller

- [Eski nesil cihaz profili (ikili BCD)](../BCD_eskinesilciihazlar%20i%C3%A7in)
- [Metro profili (ikili BCD)](../BCD_metroac%C4%B1k)

### 1. Eski nesil cihaz profili

Paylaşılan son BCD dökümünde kurtarma girdisi `{default}` şu ayarlarla gösterilmiştir:

- `device` ve `osdevice`: `ramdisk=[boot]\sources\boot.wim,{7619dcc8-fafe-11d9-b411-000476eba25f}` — WinPE/WinRE WIM'ini RAM diskten başlatmayı hedefler. BCD'deki ramdisk seçenekleri ve medyadaki `boot.sdi`/WIM yolları eşleşmelidir.
- `path`: `\windows\system32\boot\winload.efi` — UEFI Windows yükleyicisi yolu.
- `winpe Yes`, `detecthal Yes`, `systemroot \windows` — WinPE davranışına ve yükleme ortamına ait ayarlar.
- `bootmenupolicy Legacy` veya denemelerin erken aşamalarında `Standard` — eski tip ve grafiksel önyükleme politikası arasında profil seçimi. Kullanıcının son eski cihaz testi, kurtarma araçları dışındaki işlevlerin çalıştığını, **Gelişmiş seçenekler > Başlangıç Ayarları > Güvenli Mod** seçeneğinin ise çalışmadığını bildiriyor.
- Bazı dökümlerde `displaymessage Recovery`, `recoveryenabled Yes`, `flightsigning Yes`, `isolatedcontext Yes` ve `nocrashautoreboot Yes` görülmüştür. Bunlar ilgili çıktıda görülen değerlerdir; tek başlarına Gelişmiş Seçenekler menüsünü veya Güvenli Modu etkinleştirdikleri kanıtlanmış değildir.

Eski profilde amaç, eski ekran/firmware uyumluluğu ve okunabilir önyükleme arayüzüdür. `Legacy` seçimi Windows'un her cihazda fiziksel F8 tuşunu yakalayacağı anlamına gelmez; firmware, hızlı açılış, klavye ve Windows sürümü etkili olabilir. UEFI BCD'sinde `winload.efi` kullanılmıştır; BIOS/MBR için dosya ve önyükleme düzeni farklı olabilir. Bu BCD evrensel veya tüm eski cihazlarda doğrulanmış kabul edilmemelidir.

### 2. Yeni nesil cihazlar için Metro profili

Paylaşılan Metro çalışma çıktısında kurtarma girdisi `{default}` için `bootmenupolicy Standard`, `graphicsresolution 1024x768`, `highestmode No`, `displaymessage Recovery`, `recoveryenabled Yes`, `winpe Yes` ve ramdisk WIM yolu görülmüştür. Amaç modern grafiksel önyükleme menüsü ve farklı ekranlarda daha okunaklı kurtarma arayüzüdür.

`{bootmgr}` ve yükleyici girdilerine `graphicsresolution 1024x768`/`highestmode No` uygulama denemeleri yapılmıştır. Ayarlar ancak firmware/önyükleme görüntü sürücüsü bu çözünürlüğü sunarsa etkili olur; 1024×768'in her cihazda destekleneceği veya yazıyı kesin büyüteceği garanti değildir. Metro profili de eski profil gibi gerçek donanımda ve sanal makinede ayrı ayrı sınanmalıdır.

### 3. Windows 11 hedef girdisi ve `locate`

Paylaşılan tam dökümde ikinci bir Windows girdisi (örnek GUID: `{6e93deb7-4b32-41d7-8b3c-f1027d9d26fa}`) şu biçimde görünmüştür:

- `device locate=\Windows\system32\winload.efi`
- `osdevice locate=\Windows`
- `path \Windows\system32\winload.efi`
- `description Windows 11`
- `recoverysequence {default}`

`locate`, bölüm harfi yerine belirtilen dosya/Windows yolunu bulmaya çalışır. Birden çok Windows kurulumunda, birden çok diskte veya sıra dışı bölüm düzeninde doğru kurulumu seçeceği garanti değildir. `recoverysequence {default}` de harici BCD'deki WinPE girdisinin hedef Windows'un yerel, kayıtlı WinRE yapılandırması olduğu anlamına gelmez. Bu nedenle “evrensel” olduğu veya her arızalı Windows'u başlatacağı iddia edilmemelidir.

## Komutlar: ne yaparlar, riskleri nelerdir?

Aşağıdaki komutlar geçmişte kullanılan örneklerdir; otomatik çalıştırılacak tek bir betik değildir. `C:`, `S:`, BCD yolu ve `{GUID}` örnektir. Yanlış BCD'yi değiştirmek sistemi başlatılamaz duruma getirebilir. Önce hangi Windows kurulumunun ve hangi BCD deposunun hedeflendiğini doğrulayın, yedek alın ve test cihazı kullanın.

### BCD'yi görüntüleme ve yedekleme

```bat
bcdedit /store "C:\Boot\BCD"
bcdedit /store "C:\Boot\BCD" /enum all /v
bcdedit /store "C:\Boot\BCD" /export "C:\Boot\BCD.backup"
```

- `bcdedit /store <yol>`: Belirtilen BCD deposunu görüntüler; `/set` verilmediği için ayar değiştirmez.
- `/enum all`: Depodaki tüm nesne ve girdileri listeler.
- `/v`: `{default}` gibi kısaltmalar yerine tam GUID'leri gösterir. Komutlar çalıştırılmadan önce gerçek GUID'nin belirlenmesine yardımcı olur.
- `/export`: BCD deposunun yedeğini belirtilen dosyaya çıkarır. Hedef klasör mevcut olmalı, yedek başka bir konumda tutulmalı ve geri yükleme yöntemi önceden bilinmelidir.

### EFI Sistem Bölümünü bağlama ve ayırma

```bat
mountvol S: /s
bcdedit /store S:\EFI\Microsoft\Boot\BCD /enum all /v
mountvol S: /d
```

- `mountvol S: /s`: Windows'un EFI Sistem Bölümü'nü `S:` harfiyle bağlamayı dener. Harfin boş olduğundan ve doğru bölümün bağlandığından emin olun.
- `bcdedit /store ...`: Bu örnekte EFI bölümündeki BCD'yi okur. `S:` yanlışsa başka bir dosya veya hiç dosya hedeflenebilir.
- `mountvol S: /d`: `S:` bağlama noktasını kaldırır. BCD'yi kendi başına değiştirmez.

`mountvol S: /s` ile ulaşılan EFI BCD'si, harici kurtarma medyasının BCD'siyle aynı olmak zorunda değildir. Harici BCD'de bir ayar yapmak istiyorsanız o medyanın BCD yolunu ayrıca ve kesin olarak belirleyin.

### Güvenli Mod bayrağı

```bat
bcdedit /store "<hedef-BCD-yolu>" /set {GERCEK-WINDOWS-GUID} safeboot minimal
bcdedit /store "<hedef-BCD-yolu>" /deletevalue {GERCEK-WINDOWS-GUID} safeboot
```

- `safeboot minimal`: Belirtilen **Windows yükleyici girdisini** Minimal Güvenli Modda başlatma isteği yazar. `minimal`, ağ desteği eklemez.
- `safeboot` değerini silmek: O girdideki zorunlu Güvenli Mod seçeneğini kaldırıp normal önyüklemeye dönüşü sağlar.
- Paylaşılan notlarda `/store S:\EFI\Microsoft\Boot\BCD` ile `{default}` hedeflenmiştir. `{default}` kurtarma BCD'sinde WinPE girdisi olabilir; bu yüzden gerçek hedef Windows GUID'si olduğu kontrol edilmeden komutu kopyalamayın. `bcdedit` sistem deposunda da `{current}` ile `{default}` farklı anlamlara gelebilir.
- Güvenli Mod sonrası `INACCESSIBLE_BOOT_DEVICE` görülmesi depolama sürücüsü/denetleyicisi, servis başlangıç ayarı veya başka nedenlerle ilişkili olabilir. Notlardaki Intel RST/VMD açıklaması olası bir hipotezdir; her sistem için kesin kök neden değildir.

### BCD ayarlarını değiştirme

Komut geçmişinde şu biçimler denenmiştir:

```bat
bcdedit /store "C:\Boot\BCD" /set {default} bootmenupolicy Legacy
bcdedit /store "C:\Boot\BCD" /set {default} bootmenupolicy Standard
bcdedit /store "C:\Boot\BCD" /set {bootmgr} graphicsresolution 1024x768
bcdedit /store "C:\Boot\BCD" /set {default} graphicsresolution 1024x768
bcdedit /store "C:\Boot\BCD" /set {default} highestmode No
bcdedit /store "C:\Boot\BCD" /set {GERCEK-WINDOWS-GUID} graphicsresolution 1024x768
bcdedit /store "C:\Boot\BCD" /set {GERCEK-WINDOWS-GUID} highestmode No
bcdedit /store "C:\Boot\BCD" /set {GERCEK-WINDOWS-GUID} device locate=\Windows\system32\winload.efi
bcdedit /store "C:\Boot\BCD" /set {GERCEK-WINDOWS-GUID} osdevice locate=\Windows
bcdedit /store "C:\Boot\BCD" /deletevalue {GERCEK-WINDOWS-GUID} resumeobject
```

- `/set`: Seçili BCD nesnesinin bir öğesini değiştirir.
- `bootmenupolicy Legacy` / `Standard`: İlgili önyükleme girdisi için menü davranışı seçer; hangi profilin uygun olduğu test edilmelidir.
- `graphicsresolution` ve `highestmode`: Önyükleme arayüzü çözünürlük/mod seçimini etkiler; GPU/firmware desteği gerekir.
- `device` ve `osdevice` `locate=...`: Windows yükleyici ve işletim sistemi bölümünü yol üzerinden bulmaya çalışır; bölüm harfine bağımlılığı azaltabilir ancak belirsiz kurulumlarda yanlış hedef riski vardır.
- `resumeobject` silme: Hazırda bekletme/devam nesnesi bağlantısını kaldırır. Bu değer gerekli olabilir; ne yaptığını bilmeden silmeyin.
- `recoveryenabled Yes/No`, `displaymessage Recovery` için notlarda verilen komutlar da BCD öğesini ayarlar. Bunlar tek başına Gelişmiş Seçenekler, Başlangıç Ayarları veya Güvenli Mod seçeneğini yaratmaz.

Komut geçmişinde ayrıca `{default}` ve Windows GUID'si için `recoveryenabled`, `isolatedcontext`, `nx OptIn`, `usefirmwarepcisettings No`, `flightsigning Yes` ve `nocrashautoreboot Yes` değerleri kullanılmıştır. Bu değerler Windows/BCD sürümüne, önyükleme nesnesine ve cihaza bağlıdır; “tüm makinelerde gerekli” veya “tam uyumlu” diye genellenemez. `numproc` gibi cihaza özgü değerlerin başka makineye taşınmaması doğru bir tedbirdir.

### Özel `custom:` BCD öğeleri hakkında uyarı

Notlarda aşağıdaki özel öğeler ve bunların belirli Recovery/RecoveryOS anlamı olduğu iddiaları yer almıştır:

```bat
bcdedit /store "C:\Boot\BCD" /set {default} custom:46000010 yes
bcdedit /store "C:\Boot\BCD" /set {default} custom:250000c2 2
bcdedit /store "C:\Boot\BCD" /set {default} custom:250000c2 0x3
bcdedit /store "C:\Boot\BCD" /set {default} custom:26000024 yes
bcdedit /store "C:\Boot\BCD" /set {default} custom:1600007E yes
```

Standart `bcdedit` tarafından kabul edilmesi, özel BCD öğesinin Windows tarafından beklenen semantik ile yorumlandığını veya kurtarma menüsünü açacağını **kanıtlamaz**. Notlarda `custom:250000c2` için hem `2` hem `3` değerleri, `custom:1600007E` ile `flightsigning` ilişkisi ve RecoveryOS için farklı hex açıklamaları verilmiş; bunlar kendi içinde tutarlı ve resmi olarak doğrulanmış değildir. `RecoverOs` adıyla doğrudan `/set` denemesi de hata vermiştir. Bu özel öğeleri doğrulanmış çözüm gibi kullanmayın; gerçek BCD'yi bir test makinesinde `bcdedit /enum all /v` ve bilinen bir BCD/WinRE ile karşılaştırarak araştırın.

### Çevrimdışı SYSTEM hive kayıt defteri komutları

Notlarda aşağıdaki biçimler kullanılmıştır:

```bat
reg load HKLM\WIM_SYS "<mount>\Windows\System32\config\SYSTEM"
reg add "HKLM\WIM_SYS\ControlSet001\Control\WinRE" /v RecoverOs /t REG_DWORD /d 1 /f
reg unload HKLM\WIM_SYS
```

ve hedef Windows çevrimdışı iken:

```bat
reg load HKLM\OFFLINE_SYS "<hedef-Windows>\Windows\System32\config\SYSTEM"
reg add "HKLM\OFFLINE_SYS\ControlSet001\Control\SafeBoot\Minimal\<anahtar>" /ve /t REG_SZ /d "<değer>" /f
reg unload HKLM\OFFLINE_SYS
```

- `reg load`: Bir SYSTEM hive dosyasını geçici `HKLM` adı altında bağlar.
- `reg add`: Belirtilen hive'a anahtar/değer ekler. `/v` adlandırılmış değer, `/ve` varsayılan/adsız değer, `/t` veri türü, `/d` veri, `/f` onay sormadan üzerine yazma demektir.
- `reg unload`: Hive'ı güvenli şekilde ayırır. İşlem sonunda bunu atlamayın.
- `ControlSet001` her çevrimdışı Windows için etkin kontrol kümesi olmayabilir. `SYSTEM\Select` içindeki `Current`/`Default` değerleri incelenmeden sabit `ControlSet001` değiştirilmemelidir.
- `RecoverOs` veya SafeBoot anahtarlarının eklenmesi tek başına kurtarma arayüzünü ya da depolama sürücüsünü doğru yapılandırdığı anlamına gelmez. Intel/AMD sınıf GUID'si veya `iaStorVD` adı her cihazda geçerli değildir; sürücü ve mevcut kayıtlar önce incelenmelidir.

### Kayıt defteri yedeği ve geri yükleme örnekleri

```bat
mkdir C:\RegYedek
reg save HKLM\SYSTEM C:\RegYedek\SYSTEM.hiv /y
reg save HKLM\SOFTWARE C:\RegYedek\SOFTWARE.hiv /y
reg export "HKLM\SYSTEM\CurrentControlSet\Control\SafeBoot" C:\SafeBoot_Yedek.reg /y
reg import C:\SafeBoot_Yedek.reg
```

- `mkdir`: Yedek klasörünü oluşturur.
- `reg save`: Kovanı ikili hive biçiminde yedekler. Bu dosya `.reg` metin dışa aktarımı değildir.
- `reg export`: Seçili anahtarları `.reg` dosyasına dışa aktarır.
- `reg import`: `.reg` dosyasındaki değişiklikleri kayıt defterine işler; yanlış veya eski dosya istenmeyen değişiklik yapabilir.

Notlarda görülen `copy /y C:\RegYedek\SYSTEM.hiv C:\Windows\System32\config\SYSTEM` ve SOFTWARE karşılığı mevcut canlı hive dosyasının üzerine yazmayı dener. Bu işlem açık/çalışan kayıt defteri kovanlarında güvenli bir geri yükleme yöntemi değildir; dosya kilidi, bozuk hive veya önyükleme sorunu doğurabilir. Bu örnekleri **çalıştırmayın**. Hive geri yükleme işlemi çevrimdışı kurtarma ortamında, tam olarak doğru Windows kurulumu doğrulandıktan ve yedek alındıktan sonra uygun kurtarma prosedürüyle yapılmalıdır.

### Önyükleme dosyalarını yeniden oluşturma ve DiskPart

Notlarda şu komutlar yer almıştır:

```bat
bcdboot C:\Windows /s S: /f UEFI
```

```text
select volume 2
assign letter=S
exit
```

- `bcdboot`: Belirtilen Windows dizisinden önyükleme dosyalarını hedef sistem bölümüne kopyalar/oluşturur. `/s S:` hedef sistem bölümünü belirtir, `/f UEFI` UEFI dosyalarını ister. Yanlış Windows veya EFI bölümü seçilirse önyükleme dosyaları yanlış yere yazılabilir. `C:` ve `S:` sabit varsayılmamalıdır.
- `select volume 2`: DiskPart içinde 2 numaralı birimi seçer. Numara cihazlar arasında değişir; önce `list volume` ile boyut, FAT32 türü ve bölüm rolü doğrulanmalıdır.
- `assign letter=S`: Seçili birime `S:` harfi atar.
- `exit`: DiskPart'tan çıkar.

Bu komutlar mevcut BCD'yi veya UEFI önyükleme dosyalarını değiştirebilir. Önce mevcut BCD'yi ve EFI bölümünü yedekleyin; yanlış bölüme uygulanırsa cihaz açılmayabilir.

### Donanım/sürücü teşhis komutları

```bat
sc query type= driver | findstr /i "stor nvme vmd"
wmic baseboard get manufacturer,product,version
```

- `sc query type= driver`: Servis Denetleyicisi'nden sürücü hizmetlerini listeler.
- `findstr /i`: Çıktıda belirtilen metinleri büyük/küçük harf duyarsız arar. Sonuçta görülen sürücünün aktif sistem diski sürücüsü olduğu tek başına kanıtlanmış olmaz.
- `wmic baseboard get ...`: Anakart üretici/model/sürüm bilgisini sorgulamaya çalışan eski WMIC aracıdır; güncel Windows sürümlerinde bulunmayabilir. Daha yeni sistemlerde PowerShell `Get-CimInstance Win32_BaseBoard` alternatifi kullanılabilir.

### PowerShell ile BCD registry verisini elle değiştirme denemesi

Notlarda, `SeTakeOwnershipPrivilege`, `SeRestorePrivilege` ve `SeBackupPrivilege` etkinleştirmeye çalışan uzun bir PowerShell/C# komutu; BCD hive'ını `reg load` ile bağlama, bir registry anahtarının sahibini/ACL'sini değiştirme ve `Element` değerine ham bayt yazma işlemleri yer almıştır.

Bu yöntem BCD hive'ının iç registry yapısını ve erişim denetimlerini elle değiştirir. Yanlış GUID/element yolu, yanlış binary türü veya eksik yazma BCD'yi bozabilir; ayrıca istenen BCD öğesinin Windows tarafından doğru yorumlanacağını kanıtlamaz. Bu komut burada tekrarlanmıyor ve genel kullanım için önerilmiyor. Önce standart `bcdedit` arayüzü, kopya BCD ve test makinesi tercih edilmelidir.

## Windows Hello, PIN ve BitLocker notu

Harici önyükleme, firmware/önyükleme zinciri değişikliği veya TPM ölçümleri Windows Hello PIN'i yeniden kurmayı ya da hesap parolasıyla doğrulamayı gerektirebilir. Bu davranış cihaz politikası ve yapılandırmasına bağlıdır; PIN uyarısının mutlaka zararsız olduğu veya dahili Windows'a dönünce her zaman kendiliğinden düzeleceği garanti edilemez. Microsoft hesabı/yerel hesap parolası ve BitLocker kurtarma anahtarı önceden erişilebilir olmalıdır. Chrome/Edge kayıtlı parolalarının tümü doğrudan PCR değerine bağlıdır şeklindeki genel iddia da fazla kesin bir genellemedir; parola saklama davranışı işletim sistemi, tarayıcı ve hesap yapılandırmasına göre farklılık gösterir.

## Kısa güvenli çalışma sırası

1. Test edilen bilgisayarda hangi modda (UEFI/BIOS) açılacağını, Windows bölümünü, EFI bölümünü ve kullanılacak BCD yolunu doğrulayın.
2. Mevcut BCD'yi ve önemli verileri yedekleyin; BitLocker kurtarma anahtarını hazır tutun.
3. BCD'yi önce yalnızca okuyun: `bcdedit /store "<yol>" /enum all /v`.
4. Gerekli tek değişikliği, doğrulanmış doğru GUID üzerinde yapın; ardından aynı depoyu tekrar okuyup değişikliği kontrol edin.
5. Harici WinPE menüsü, Windows'u başlatma girdisi ve Güvenli Modu ayrı ayrı test edin. Birinin çalışması diğerinin de çalıştığını kanıtlamaz.
6. Deneme sonrası `safeboot` gibi geçici değerleri kaldırın ve yalnızca doğru hedef BCD'yi değiştirdiğinizi doğrulayın.

Bu çalışma deneysel kurtarma/önyükleme notlarıdır; Windows 11 donanım gereksinimlerini atlatma, imza güvenliğini değiştirme veya BCD'yi başka cihaza taşıma cihazı desteklenen hâle getirmez ve güvenlik, güncelleme ya da her donanımda çalışma garantisi sağlamaz.

# Eski nesil cihazlarda Windows sürücüsü yükleme sorunları

Bu ek not, eski bilgisayarlarda ekran kartı, yonga seti, ağ ve depolama sürücüsü yüklenirken karşılaşılabilecek uyumluluk ve imza sorunlarını BCD/kurtarma çalışmasından ayrı olarak açıklar. Buradaki maddeler teşhis rehberidir; belirli bir sürücünün güvenli veya uyumlu olduğunu garanti etmez.

## Sık görülen sorunlar

- **Windows sürücü bulamıyor veya kurulum reddediliyor:** Sürücü paketi cihazın tam modeline, donanım kimliğine, Windows sürümüne ve mimarisine (x64/x86) uymayabilir. Benzer model adına bakarak sürücü seçmeyin; üretici ve Aygıt Yöneticisi'ndeki donanım kimliğini doğrulayın.
- **Eski imza / imza doğrulama hatası:** Eski sürücü SHA-1 ile imzalanmış, sertifikası geçersiz/süresi dolmuş veya paketin imzası Windows tarafından kabul edilmiyor olabilir. “Yine de yükle” seçeneğinin görünmesi sürücünün güvenli ya da Windows 11 ile uyumlu olduğunun kanıtı değildir.
- **Bellek Bütünlüğü (HVCI) veya güvenlik açığı bulunan sürücü engelleme listesi:** Windows güvenlik özellikleri uyumsuz ya da bilinen zafiyetli sürücüyü engelleyebilir. Bu, sürücüyü zorla yüklemek yerine güncel ve üretici tarafından desteklenen sürücüyü bulmak için bir işarettir.
- **Güvenli Modda donanım işlevlerinin olmaması:** Güvenli Mod sınırlı sürücü kümesiyle çalışır. Ekran çözünürlüğü, ağ, ses veya kurulum programının ihtiyaç duyduğu servisler burada çalışmayabilir. Sürücü yüklemesi için normal Windows oturumu tercih edilir; Güvenli Mod esas olarak kaldırma/arıza giderme içindir.
- **Kurulumdan sonra siyah ekran, çökme veya aygıt hatası:** Yanlış model sürücüsü, eski sürüm, GPU/Windows uyumsuzluğu veya sürücü imza/politika sorunu olabilir. Bu belirtiler tek başına imza zorlamasını neden olarak kanıtlamaz.

## Önerilen teşhis sırası

1. Önce önemli verileri yedekleyin; cihaz için BitLocker etkinse kurtarma anahtarının erişilebilir olduğundan emin olun.
2. Bilgisayarın üretici/modelini ve aygıtın donanım kimliğini doğrulayın. Mümkünse bilgisayar veya bileşen üreticisinin destek sayfasındaki sürücüyü kullanın.
3. Windows sürümünü ve sistem mimarisini kontrol edin; paketin desteklediği işletim sistemi ve donanım kimliklerini okuyun.
4. Aygıt Yöneticisi'ndeki hata kodunu ve Windows Update/üretici kurulum günlüklerini kaydedin. Önceki sürücüye geri dönme veya Sistem Geri Yükleme seçeneğini hazır bulundurun.
5. İmza/politika engeli bildiriliyorsa sürücünün kaynağını ve imza durumunu üreticiden doğrulayın. İmza kontrolünü veya Secure Boot'u kalıcı olarak kapatmayın; HVCI ve güvenlik açığı sürücü listesi korumalarını sırf sürücüyü yüklemek için devre dışı bırakmayın.
6. Sürücü yüklemesinden sonra normal açılışı, Aygıt Yöneticisi durumunu ve ilgili donanım işlevlerini test edin. Sorun çıkarsa sürücüyü geri alın veya kaldırın.

### Güvenli, salt-okunur inceleme komutları

Yönetici Komut İstemi veya PowerShell'de kullanılabilecek örnekler:

```bat
:: Sistemdeki üçüncü taraf sürücü paketlerini listeler; hiçbir şey yüklemez/kaldırmaz
pnputil /enum-drivers

:: Windows İmza Doğrulama aracını başlatır (arayüz Windows sürümüne göre değişebilir)
sigverif
```

```powershell
# Tak-Çalıştır aygıtlarının adını ve durumunu listeler; değişiklik yapmaz
Get-PnpDevice | Select-Object Status, Class, FriendlyName, InstanceId
```

`pnputil` seçeneklerinin kullanılabilirliği Windows sürümüne göre değişebilir. Komut çıktısında görünen sürücü adını/INF dosyasını tek başına güvenilirlik onayı saymayın; dijital imza, yayıncı ve dosyanın üretici kaynağından gelip gelmediği ayrıca doğrulanmalıdır.

## Başlangıç Ayarları'ndaki 7. seçenek hakkında

Windows'un **Başlangıç Ayarları > 7: Sürücü imzası zorlamasını devre dışı bırak** seçeneği, desteklenen yapılandırmalarda yalnızca ilgili açılış için imza zorlamasını geçici olarak devre dışı bırakmaya yönelik bir sorun giderme seçeneğidir. Bu seçenek:

- sürücüyü güvenli, uyumlu veya doğru model için yapılmış hâle getirmez;
- bütün imza/politika kontrollerini her Windows sürümünde aşacağı anlamına gelmez;
- siyah ekranı önleme veya normal açılışı garanti etmez;
- kalıcı imza denetimi kapatma yöntemi değildir.

Saha notlarında eski/SHA-1 sürücüsü kurulumundan sonra 7. seçeneği kullanmanın gerekli olduğu öne sürülmüştür. Bu, belirli cihaz ve test akışı için bir gözlemdir; tüm sürücüler için “normal moda geçmeden önce mutlaka yapılmalı” şeklinde genellenemez. Sürücü yalnızca böyle bir geçici seçenekle çalışıyorsa mümkünse kurulumdan vazgeçip desteklenen, güncel ve geçerli imzalı sürücü arayın. Güvenlik özelliklerini kapatarak üretim veya hassas verili cihazı riske atmayın.

## Bu projedeki BCD/kurtarma çalışmasıyla ilişkisi

BCD menüsünün açılması, `bootmenupolicy`, `displaymessage Recovery` veya Windows girdisinin `locate` ile bulunması sürücüyü kurmaz ve imza sorununu çözmez. Harici ISO'dan Windows'u başlatma, dahili diskten başlatma ve Güvenli Mod ayrı önyükleme senaryolarıdır. Harici kurtarma akışında `INACCESSIBLE_BOOT_DEVICE` görülmesi depolama sürücüsü dâhil çeşitli nedenlerden kaynaklanabilir; yalnızca bu hata koduna dayanarak sürücü değişikliği veya SafeBoot kayıt defteri düzenlemesi yapmayın.

Eski cihazlarda sürücü desteği bulunmaması donanımın arızalı olduğunu kanıtlamaz; ancak desteklenmeyen sürücüyü zorlamak da güvenli bir çözüm değildir. Her değişikliği önce test sisteminde, yedeği ve çalışan kurtarma medyası hazırken deneyin.

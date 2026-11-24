# Saha bulguları: BCD profilleri, kurtarma ve Güvenli Mod

Bu ek belge, [BCD profilleri ve kullanılan komutlar](komutlar-ve-profiller.md) sayfasındaki dört saha bulgusunu günceller. Buradaki “doğrulandı” ifadeleri yalnızca paylaşılan komut çıktıları ve saha gözlemleri kapsamındadır; tüm Windows sürümlerinde veya donanımlarda aynı sonucun alınacağını garanti etmez.

## 1. `displaymessage Recovery` ve `custom:250000c2`

Paylaşılan denemede şu adlandırılmış BCD komutu başarıyla çalıştırılmış ve sonrasında BCD dökümünde `displaymessage Recovery` görülmüştür:

```bat
bcdedit /store "C:\Boot\BCD" /set {default} displaymessage Recovery
bcdedit /store "C:\Boot\BCD"
```

Bu test, kullanılan depodaki `{default}` girdisinin `displaymessage` öğesini `Recovery` olarak kaydettiğini ve `bcdedit` çıktısında adlandırılmış öğe olarak gösterdiğini doğrular. Önceki notlarda bu öğe için `custom:250000c2` adıyla ham sayısal değerler (`2`, `0x2` ve `3`) de denenmiştir. Bu değerlerin hepsi eşdeğer kabul edilmemelidir: paylaşılan son BCD dökümünde `displaymessage Recovery` görülmüş, ham ikili düzenleme örneğinde `03 00 00 00 00 00 00 00` kullanılmıştır. Bu yüzden belgede önerilen okunabilir biçim `displaymessage Recovery` komutudur; özel `custom:` biçiminde sayısal değer yazmak yerine adlandırılmış öğeyi kullanın ve sonucu tekrar `/enum` ile kontrol edin.

`displaymessage Recovery` önyükleme mesajı/arayüz işaretidir. Bu alanın yazılması tek başına WinRE'nin tüm Gelişmiş Seçenekler menülerini veya Başlangıç Ayarları/Güvenli Mod seçeneğini etkinleştirdiğini kanıtlamaz.

## 2. Güvenli Mod: dahili BCD ile harici kurtarma BCD'si aynı senaryo değil

Saha notlarında dahili EFI BCD'si üzerinden Windows'u Güvenli Modda başlatma ile harici ISO/WinPE BCD'sinden `locate` ile bulunan Windows girdisini başlatma ayrı davranışlar göstermiştir:

- Dahili Windows önyükleme zincirindeki EFI BCD'si kullanıldığında Güvenli Modun çalıştığı bildirilmiştir.
- Harici kurtarma medyasının BCD'sindeki Windows girdisi `locate` ile hedeflenip `isolatedcontext` gibi ayarlarla kullanıldığında Güvenli Mod denemesinde `INACCESSIBLE_BOOT_DEVICE` görüldüğü bildirilmiştir.
- Harici kurtarma ortamındaki **Başlangıç Ayarları > Güvenli Mod** seçeneğinin eski nesil profil üzerinde çalışmadığı ayrıca belirtilmiştir.

Bu gözlemler, sorunun yalnızca “Intel RST/VMD sürücüsü SafeBoot listesinde yok” şeklinde kesinleştirilemeyeceğini gösterir. Dahili ve harici BCD yolu, hangi Windows yükleyici girdisinin seçildiği, kurtarma ortamının hedef Windows ile ilişkisi, `locate` çözümlemesi, `isolatedcontext` ve depolama sürücüsü başlangıç koşulları birbirinden farklı etkenler olabilir. Mevcut saha verisi bu etkenlerden hangisinin tek başına kök neden olduğunu kanıtlamaz. Bu nedenle önceki “kesin teknik sebep” ifadesi düzeltilmiştir: depolama sürücüsü olası nedenlerden biridir, fakat harici BCD akışındaki farklar da araştırılmalıdır.

Güvenli Mod bayrağı yalnızca doğru Windows yükleyici girdisine yazılmalıdır. `/store` ile kullanılan dosyanın gerçekten hedef Windows'un BCD'si olduğu ve seçilen GUID'nin `{default}` WinPE girdisi değil Windows girdisi olduğu kontrol edilmelidir. Yanlış girdide bırakılan `safeboot` değeri normal açılışı engelleyebilir; deneme sonrası aynı doğru BCD ve GUID üzerinde kaldırıldığı doğrulanmalıdır.

## 3. Eski nesil kurtarma girdisindeki `bootmenupolicy 3`

Paylaşılan eski nesil kurtarma BCD'sinin son çıktısında `{default}` WinPE/kurtarma girdisi için şu satır görülmüştür:

```text
bootmenupolicy          3
```

Dolayısıyla bu saha profilini yalnızca `bootmenupolicy Legacy` diye tanımlamak doğru değildir. Deneylerde `Legacy` ve `Standard` değerleri de kullanılmış olsa da, bildirilen eski nesil kurtarma profilinin son dökümünde değer `3` olarak raporlanmıştır. Bu değer gözlenen yapılandırma olarak kaydedilmiştir; `3` değerinin Windows sürümleri arasında belgelenmiş/taşınabilir bir karşılığı olduğu veya tek başına F8/Gelişmiş Seçenekler/Güvenli Mod menüsünü açtığı doğrulanmış değildir.

Metro profilinde paylaşılan son çalışma çıktısı `bootmenupolicy Standard` göstermiştir. İki profilin politikalarını karıştırmayın: eski nesil kurtarma girdisinde saha dökümünde görülen değer `3`, Metro denemesinde ise `Standard` idi. Her kopyayı hedef Windows sürümünde `bcdedit /store "<BCD-yolu>" /enum all /v` ile ayrıca inceleyin.

## 4. Eski sürücü ve “Sürücü imzası zorlamasını devre dışı bırak” seçeneği

Saha notlarında, Güvenli Modda eski/SHA-1 imzalı bir sürücü kurulumu sırasında “Yine de yükle” seçiminin yapıldığı; sonraki açılışta sorun yaşanmaması için **Başlangıç Ayarları > 7: Sürücü imzası zorlamasını devre dışı bırak** seçeneğinin kullanılması gerektiği öne sürülmüştür.

Bu, evrensel bir zorunluluk veya siyah ekranı önlediği kanıtlanmış bir çözüm olarak sunulmamalıdır. Başlangıç Ayarları'ndaki 7. seçenek, ilgili önyükleme için sürücü imza denetimini geçici olarak gevşetmeye yönelik bir sorun giderme seçeneğidir; sürücüyü uyumlu hâle getirmez, sürekli imza denetimi kapatma yöntemi değildir ve her sistemde normal moda dönüşü garanti etmez. SHA-1 imzalı, eski veya uyumsuz sürücüler Windows sürümü/politikası nedeniyle yine engellenebilir ya da kararsızlığa yol açabilir.

Bu seçenek ancak imza denetiminin sürücünün yüklenmesini gerçekten engellediği doğrulanmış bir testte, etkisi anlaşılarak ve kurtarma/yedekleme hazırken değerlendirilmelidir. Mümkünse üretici tarafından sağlanan güncel, desteklenen ve geçerli imzalı sürücü tercih edilmelidir. Seçenek kullanılmış olsa bile sistem açıldıktan sonra sürücünün kaynağı, imza durumu ve Aygıt Yöneticisi hataları kontrol edilmeli; Secure Boot veya sürücü imza güvenliği kalıcı olarak kapatılmamalıdır.

## Profil ve saha testi özeti

| Alan | Eski nesil kurtarma profili | Metro profili | Saha durumu / sınır |
| --- | --- | --- | --- |
| Menü politikası | Paylaşılan son kurtarma dökümünde `bootmenupolicy 3` | Paylaşılan Metro çalışmasında `Standard` | Farklı profiller; her cihazda ayrı doğrulama gerekir. |
| Ekran | `1024x768` ayarları denenmiş | `graphicsresolution 1024x768`, `highestmode No` denenmiş | Firmware/GOP desteğine bağlı; garanti edilen çözünürlük değildir. |
| Kurtarma mesajı | `displaymessage Recovery` çıktıda görülmüş | Metro BCD çıktısında da görülmüş | Mesaj alanı, kurtarma menüsü özelliklerinin tamamını etkinleştirmez. |
| Windows'u başlatma girdisi | `locate` ile Windows yükleyici girdisi eklenmiş | Aynı yaklaşım denenmiş | Paylaşılan testte Windows'u başlatma çalışmış; çoklu kurulumlarda yanlış hedef riski sürer. |
| Başlangıç Ayarları / Güvenli Mod | Eski nesil harici kurtarma akışında çalışmadığı bildirilmiş | Ayrı test sonucu verilmemiş | Çalışıyor varsayılmamalı; çözülmemiş test alanıdır. |
| Dahili BCD'den Güvenli Mod | Kullanıcının notlarında çalıştığı belirtilmiş | Profil karşılaştırması değildir | Harici ISO'dan başlatma ile aynı BCD/önyükleme yolu değildir. |

## Önceki belgedeki düzeltmeler

- `custom:250000c2` için `2` ve `3` değerleri doğrulanmış eşdeğerler gibi sunulmamalı; başarılı saha çıktısında adlandırılmış `displaymessage Recovery` öğesi görülmüştür.
- `INACCESSIBLE_BOOT_DEVICE` için yalnızca RST/VMD/SafeBoot sürücüsü kök neden olarak ilan edilmemeli; dahili ve harici önyükleme yolları arasındaki fark da hesaba katılmalıdır.
- Eski nesil kurtarma profilinin paylaşılan son çıktısında `bootmenupolicy 3` görülmüştür; bunu `Legacy` ile eşitlemeyin.
- Sürücü imza denetimini geçici olarak gevşetme seçeneği, standart adım veya siyah ekranı önleme garantisi değildir; yalnızca kontrollü sorun giderme bağlamında değerlendirilmelidir.

BCD dosyasının gerçek içeriği ve her alanın son değeri, her zaman ilgili ikili BCD üzerinde Windows'un `bcdedit /store ... /enum all /v` çıktısı ve gerçek cihaz testiyle doğrulanmalıdır. Bir profilde çalışan ayar diğer profile veya başka donanıma doğrudan genellenmemelidir.

# Eski ve Yeni Nesil Cihazlar için BCD Tabanlı Kurtarma Ortamı

Bu çalışma, harici kurtarma medyasından Windows PE/kurtarma ortamını başlatmayı ve menüden mevcut Windows kurulumunu seçebilmeyi hedefleyen iki BCD profilini belgeliyor. Profiller cihaz, firmware, önyükleme biçimi ve Windows sürümüne göre ayrıca test edilmelidir.

## BCD dosyaları

- [Eski nesil cihazlar BCD dosyası](BCD_eskinesilciihazlar)
- [Metro BCD dosyası](BCD_metroac%C4%B1k)

## Profiller ve test kapsamı

Eski nesil profil, metin tabanlı `bootmenupolicy Legacy` yaklaşımı ve `1024x768` ekran çözünürlüğü ayarlarıyla denenmiştir. Yeni nesil/ yüksek çözünürlüklü ekranlar için Metro profili `bootmenupolicy Standard`, `graphicsresolution 1024x768` ve `highestmode No` ayarlarını kullanır. Firmware'in desteklediği grafik modları sonucu etkileyebilir.

Kurtarma ortamının açılması, Windows'u başlatma girdisi ve Güvenli Mod akışı ayrı başarı ölçütleridir; birinin çalışması diğerlerini doğrulamaz. Harici WinPE/WinRE ile dahili Windows önyüklemesini ve BCD deposunu birbirinden ayırın. Yanlış BCD deposu veya girişinde yapılan değişiklik normal açılışı engelleyebilir.

## BCD ayarları hakkında

BCD ayarları (`device`, `osdevice`, `ramdisk`, `locate`, `bootmenupolicy`, `displaymessage`, `recoveryenabled`, `isolatedcontext`, `flightsigning` ve benzerleri) kullanılan ortam, firmware, Windows sürümü ve donanıma bağlıdır. Özel BCD öğeleri tek başına Başlangıç Ayarları veya Güvenli Mod menüsünü garanti etmez. `safeboot` yanlış girdiye uygulanırsa Windows'un normal açılışını etkileyebilir.

Aşağıdaki örnekler yalnızca inceleme ve geri dönüş bağlamındadır; yol ve GUID'leri her sistemde doğrulayın:

```bat
:: Önce yedek alın, sonra doğru depoyu görüntüleyin
bcdedit /store "C:\Boot\BCD" /export "C:\Boot\BCD.backup"
bcdedit /store "C:\Boot\BCD" /enum all /v

:: Yalnızca doğrulanmış Windows girdisinden safeboot değerini kaldırma örneği
bcdedit /store "C:\Boot\BCD" /deletevalue {GUID} safeboot
```

UEFI Sistem Bölümü, `bcdboot`, kayıt defteri kovanları veya canlı önyükleme dosyalarında yapılacak değişiklikler cihazı açılmaz hâle getirebilir. Önce yedek alın, doğru hedefi doğrulayın ve çalışan kurtarma medyası bulundurun. Secure Boot veya sürücü imza denetimini kalıcı kapatmak bu profillerin önerisi değildir.

## İlgili belgeler

- [BCD profilleri ve kullanılan komutlar](komutlar-ve-profiller.md)
- [Saha bulguları](saha-bulgulari.md)
- [Saha bulguları 2: BCD ve sürücü yükleme](bcd-surucu-saha-bulgulari-2.md)
- [Eski nesil sürücü yükleme sorunları](eski-nesil-surucu-yukleme-sorunlari.md)
- [Secure Boot açıkken sürücü saha testi](eski-nesil-surucu-saha-testi.md)

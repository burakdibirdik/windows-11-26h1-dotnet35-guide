# BCD ve sürücü yükleme saha bulguları 2

Bu bölüm, BCD/kurtarma ortamı ile eski sürücü yükleme denemelerinden elde edilen saha gözlemlerini toplar. Sonuçlar cihaz ve sürücüye özgü deneysel bulgulardır; tüm Windows 11 sistemlerinde veya sürücülerde geçerli olduğu kesin olarak bildirilemez.

## Eski nesil BCD profili

Eski nesil kurtarma girdisinde saha dökümünde `bootmenupolicy 3` görülmüştür. Bu yapılandırma ile metin tabanlı/F8 odaklı kurtarma profili denenmiştir. Aynı dökümde `displaymessage Recovery`, `recoveryenabled`, `isolatedcontext`, `winpe`, `detecthal`, `flightsigning` ve `nocrashautoreboot` gibi öğeler kaydedilmiştir.

Bu ayarlar tek başına Güvenli Mod, Başlangıç Ayarları veya WinRE bileşenlerini etkinleştirmez. Menülerin her cihazda görünmesi ve çalışması firmware, WinRE bileşenleri, hedef Windows sürümü ve BCD yolu gibi faktörlere bağlıdır.

## Harici ISO ve Güvenli Mod gözlemi

Saha notlarında dahili EFI BCD üzerinden Güvenli Modun çalıştığı, ancak harici kurtarma ISO/WinPE BCD üzerinden `locate` ve `isolatedcontext` kullanan Windows girdisiyle başlatılan Güvenli Modun `INACCESSIBLE_BOOT_DEVICE` verebildiği belirtilmiştir.

Bu hata; depolama sürücüsünün veya harici/yerel önyükleme zincirinin nasıl bağlandığına bağlı olarak farklı nedenlerden gelebilir. Harici ISO'dan belirli bir kök nedenini kesinleştirmek için cihazın dahili EFI BCD'si ve harici BCD ayrı ayrı incelenmelidir. `safeboot` değerinin yalnızca doğru Windows yükleyici girdisine yazıldığı doğrulanmalı ve normal açılışa dönerken kaldırılmalıdır.

## Eski sürücüler ve Secure Boot

Saha testinde, Secure Boot açık bırakılarak eski bir sürücünün yüklenip çalıştığı bildirilmiştir. Bu, belirli cihaz/sürücü/Windows yapılandırmasında alınmış bir sonuçtur; Secure Boot'un açık veya kapalı olduğunun sürücünün gerçek imzasını değiştirdiği anlamına gelmez ve tüm eski sürücüler için geçerli değildir.

Normal kullanımda üretici tarafından desteklenen, güncel ve Windows sürümüne uygun sürücüler tercih edilmelidir. Secure Boot, HVCI/Bellek Bütünlüğü veya sürücü engelleme korumalarını kalıcı olarak kapatmak bu saha testinin yöntemi veya önerisi değildir.

## Sürücü imzası zorlaması seçeneği

Eski sürücü kurulumunda Başlangıç Ayarları'ndaki **Sürücü imzası zorlamasını devre dışı bırak** seçeneği bir sorun giderme adımı olarak kullanılabilir. Bu seçenek:

- sürücüyü güvenli veya desteklenen hâle getirmez;
- siyah ekran, çökme veya açılış hatasını önleyeceği garanti etmez;
- tüm sürücüler veya tüm Windows sürümleri için geçerli değildir;
- geçici bir test seçeneğidir.

Deneysel kullanımda veriler yedeklenmeli, BitLocker kurtarma anahtarı hazır tutulmalı ve geri dönüş yöntemi bilinmelidir. Test sonrası sürücünün sürümünü, imzasını ve Aygıt Yöneticisi durumunu kontrol etmek gerekir.

## Windows Hello ve TPM alanı

Harici USB/ISO üzerinden başlatılan Windows, dahili diskten başlatılan zincirden farklı TPM/önyükleme ölçümüne yol açabilir. Bu nedenle PIN veya parola doğrulamasında sorun görülebilir. Veri kaybı olduğu anlamına gelmez; yerel/Microsoft hesap bilgileri ve BitLocker kurtarma anahtarı ayrıca korunmalıdır.

## Ayrıntılı belgeler

- [BCD profilleri ve kullanılan komutlar](komutlar-ve-profiller.md)
- [BCD profilleri ve saha bulguları](saha-bulgulari.md)
- [Eski nesil cihazlarda Windows sürücüsü yükleme sorunları](eski-nesil-surucu-yukleme-sorunlari.md)
- [Secure Boot açıkken sürücü saha testi](eski-nesil-surucu-saha-testi.md)

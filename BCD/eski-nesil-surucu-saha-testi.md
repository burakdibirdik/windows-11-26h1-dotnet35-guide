# Eski nesil cihazlarda sürücü yükleme — saha testi eki

Bu ek, eski nesil donanım için sürücü yükleme denemesinin saha sonucunu kaydeder. Bu, belirli cihaz ve sürücüyle yapılmış deneysel bir testtir; genel sürücü kurulum talimatı veya her Windows sürümünde geçerli bir garanti değildir.

## Saha gözlemi

Testte eski nesil bir aygıt sürücüsü, Windows'un Başlangıç Ayarları'ndaki **Sürücü imzası zorlamasını devre dışı bırak** seçeneği kullanılarak yüklenmiştir. Test sırasında **Secure Boot açık kalmıştır**; saha notuna göre sürücü yüklenmiş ve aygıt çalışmıştır.

Bu gözlem, bu belirli cihaz/sürücü/Windows yapılandırmasında Secure Boot'un açık olmasının denenen yükleme akışını tek başına engellemediğini gösterir. Secure Boot'un tüm imza kontrollerini devre dışı bıraktığı, her eski sürücüyü kabul ettiği veya başka cihazlarda aynı sonucun alınacağı anlamına gelmez. Sürücünün gerçek imza durumu ve Windows'un hangi politikayı uyguladığı sistem sürümü ile sürücü paketine bağlıdır.

## Genel kullanıcılar için öneri

Cihaz için üretici tarafından desteklenen, güncel ve Windows sürümüyle uyumlu sürücü varsa normal kullanıcılar imza zorlamasını devre dışı bırakmamalı ve güvenlik ayarlarını değiştirmemelidir. Öncelik Windows Update, bilgisayar üreticisinin destek sayfası veya bileşen üreticisinin güncel sürücüsüdür.

Eski sürücüyü denemek yalnızca desteklenen sürücünün bulunamadığı, donanım kimliğinin ve sürücü kaynağının doğrulandığı, kullanıcının riskleri anladığı kontrollü test/laboratuvar senaryosunda değerlendirilmelidir. Bilinen güvenlik açığı bulunan, kaynağı belirsiz veya yanlış modele ait sürücüyü yüklemeyin. HVCI/Bellek Bütünlüğü, Secure Boot ya da sürücü engelleme korumalarını kalıcı olarak kapatmak bu saha testinin parçası veya önerisi değildir.

Başlangıç Ayarları'ndaki imza zorlaması seçeneği geçici bir sorun giderme seçeneğidir; sürücüyü güvenli ya da desteklenen hâle getirmez ve sonraki açılışlarda aynı davranışın görüleceğini garanti etmez. Test öncesinde verileri yedekleyin, BitLocker kurtarma anahtarını hazır bulundurun ve çalışan bir geri dönüş/kurtarma yöntemi sağlayın. Test sonrasında Aygıt Yöneticisi durumunu, sürücü sağlayıcısı/sürümünü ve imza bilgilerini kontrol edin.

## Kapsam ve sınırlar

- **Testte bildirilen sonuç:** Secure Boot açıkken seçilen eski sürücü yüklenmiş ve çalışmıştır.
- **Genellenemeyen noktalar:** Sürücü modeli, imza zinciri, Windows yapısı, donanım ve güvenlik ilkeleri değiştiğinde sonuç değişebilir.
- **Bu testin kanıtlamadığı şeyler:** Tüm eski/SHA-1 sürücülerinin yüklenebileceği, her Secure Boot yapılandırmasının aynı davranacağı veya bu yöntemin günlük/üretim cihazlarında önerildiği.

İlgili genel teşhis ve sürücü güvenliği notları: [Eski nesil cihazlarda Windows sürücüsü yükleme sorunları](eski-nesil-surucu-yukleme-sorunlari.md).

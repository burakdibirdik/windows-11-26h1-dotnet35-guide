# Ventoy ile Windows 11 otomatik kurulum yapılandırması

Bu klasörde, Ventoy üzerinden Windows kurulumunu kolaylaştırmak için iki yapılandırma dosyası bulunur:

- [`ventoy.json`](../ventoy/ventoy.json): Hangi ISO dosyalarının hangi kurulum yanıt dosyasını kullanacağını belirtir.
- [`autounattend.xml`](../ventoy/autounattend.xml): Windows Kurulumu sırasında dil, bazı donanım kontrolleri ve ilk kullanıcı/OOBE seçeneklerini ayarlar.

## Kimler için?

Bu yapılandırma, özellikle eski nesil bilgisayarlarda Windows Kurulumu'nun donanım denetimi, OOBE/hesap oluşturma ekranı veya internet bağlantısı aşamasında takıldığı durumlarda deneysel bir kurulum kolaylığı olarak hazırlanmıştır. Kurulum takılmalarını her cihazda çözeceği garanti edilmez. Sürücü, firmware, ISO ve Windows derlemesine bağlı olarak sonuç değişebilir.

## Ventoy USB'sine kopyalama

1. Ventoy ile hazırlanmış USB belleğin ilk bölümünde `ventoy` adlı klasör oluşturun.
2. Bu depodaki iki dosyayı bu klasöre kopyalayın; USB'de yollar şu şekilde olmalıdır:
   - `/ventoy/ventoy.json`
   - `/ventoy/autounattend.xml`
3. `ventoy.json` içindeki `image` değerlerini kendi USB'nizdeki ISO dosyalarının **tam ve birebir adlarıyla** değiştirin. Örnek yapılandırmada iki ISO tanımlıdır; istemiyorsanız satırlardan birini kaldırabilir, yeni ISO'lar için yeni giriş ekleyebilirsiniz. Her girişin `template` değeri `/ventoy/autounattend.xml` olarak kalmalıdır.
4. ISO'yu Ventoy menüsünden seçip kurulumu başlatın. Önce önemli verilerin yedeğini alın.

ISO adları ve yolları büyük/küçük harf, boşluk ve noktalama işaretleri dahil USB'deki adlarla eşleşmelidir. Yanlış ad, otomatik yanıt dosyasının o ISO için uygulanmamasına yol açabilir.

## Kurulum davranışı ve önemli güvenlik notları

- Yanıt dosyası Türkçe (`tr-TR`) kurulum ve kullanıcı bölgesi ayarlarını yapar.
- Windows 11 kurulumunun TPM, Secure Boot ve RAM denetimlerini atlamaya yönelik kayıt defteri değerleri yazar. Bu, cihazı Windows 11 için desteklenen hâle getirmez; donanım uyumluluğu, güncelleme alma, sürücü desteği veya kararlılık garantisi vermez. Kurulum ve kullanım Microsoft'un desteklenen donanım koşulları dışında kalabilir.
- OOBE'de çevrimiçi hesap ve kablosuz ağ ekranlarını gizleme/çevrimdışı kurulumu kolaylaştırma ayarları bulunur. Bu ayarların etkisi Windows sürümüne göre değişebilir; internet bağlantısını veya sonraki güncellemeleri kalıcı olarak kapatmaz.
- Kurulum `Admin` adlı yerel bir yönetici hesabı oluşturur. XML'de hesap parolası **boş** bırakılmıştır ve otomatik oturum açma açıktır. Bu nedenle bilgisayara fiziksel veya uzaktan erişebilen biri yönetici oturumu elde edebilir. Yapılandırmayı ortak, internete açık veya hassas veri içeren bir cihazda bu hâliyle kullanmayın.
- İlk kurulum tamamlandıktan hemen sonra `Admin` hesabına güçlü, benzersiz bir parola belirleyin; otomatik oturum açmayı kapatın ve gerekiyorsa kendi güvenli kullanıcı hesabınızı oluşturun. Parola değiştirme ya da giriş davranışı Windows ilkeleri ve sürüme göre farklı olabilir; parola değişikliğinin kendiliğinden zorunlu olacağı varsayılmamalıdır.
- `PreventDeviceEncryption` ayarı otomatik cihaz şifrelemesini önlemeye yöneliktir. Verilerin korunması için kurulumdan sonra BitLocker/cihaz şifrelemesi ihtiyacınızı değerlendirin ve kurtarma anahtarını güvenli bir yerde saklayın. Şifreleme kullanmak, boş parolalı ve otomatik oturum açan hesabın riskini ortadan kaldırmaz.

Bu dosyalar, Windows Kurulumu'nu otomatikleştiren topluluk yapılandırmalarıdır; Microsoft tarafından desteklenen veya her cihaz için doğrulanmış bir kurulum yöntemi olarak değerlendirilmemelidir. Gerektiğinde Microsoft'un ve cihaz üreticisinin desteklenen kurulum yönergelerini kullanın.

# Revizyon 8 — Eski cihazlarda Windows kurulumu: arayüz ve USB portu seçimi

Bu sayfa Revizyon 7'deki ISO/EFI inceleme rehberine ek kurulum notlarıdır. Buradaki saha gözlemleri her Casper, Lenovo, ASUS veya başka üreticinin cihazında geçerli kabul edilmemelidir. Model, BIOS/UEFI sürümü, USB denetleyicisi ve kurulum medyası davranışı farklılık gösterebilir.

> [!IMPORTANT]
> **Eski nesil cihazlarda arayüz ve kurulum USB'si seçimi**
>
> ### 1. Kurulum arayüzü
>
> Bazı kurulum medyaları başlangıç ekranında **“Önceki kurulum sürümü”**, **“Legacy Setup”** veya benzer bir seçenek sunabilir. Bu seçenek görünüyorsa ve yeni arayüz donma/yeniden başlatma sorunu çıkarıyorsa, önce önemli verileri yedekleyip cihaz üreticisinin desteklediği seçeneklerle klasik arayüzü deneyebilirsiniz. Bu seçeneğin her Windows 11 26H1 medyasında bulunduğu veya VBIOS/UEFI GOP sorunlarını kesin çözdüğü Microsoft tarafından burada doğrulanmış değildir; görünmüyorsa zorla etkinleştirmeye çalışmayın.
>
> **UEFI/Legacy önyükleme modu ile kurulum arayüzünü karıştırmayın.** Klasik kurulum arayüzünü seçmek, BIOS'ta CSM/Legacy Boot'u açmanız gerektiği anlamına gelmez. Secure Boot ve GPT kurulum hedefi için firmware'in UEFI modunda kalması gerekir; Windows 11 gereksinimleri ve üretici kılavuzu esas alınmalıdır.
>
> ### 2. Dizüstü bilgisayarda USB portu seçimi
>
> Sol/sağ taraf, port rengi veya kasadaki konum USB hızını ve anakarta bağlantı biçimini güvenilir şekilde göstermez. “Sol taraf daima USB 3.x, sağ taraf daima USB 2.0” gibi bir kural yoktur; modelin servis kılavuzunu, port yanındaki `SS` işaretini ve üretici teknik özelliklerini kontrol edin.
>
> - Kurulum belleğini USB hub/dock yerine doğrudan bilgisayardaki porta takın.
> - USB 3.x uyumlu bellek ve port varsa genellikle daha hızlı dosya aktarımı sağlar; kurulum USB aygıtı tanınmıyor veya kararsız çalışıyorsa başka bir porta geçin.
> - USB 3.x sürücüsü/firmware uyumluluğundan şüpheleniyorsanız USB 2.0 portunu da deneyin. Bu daha yavaş olabilir, fakat bazı eski sistemlerde tanı amaçlı işe yarar.
> - Kurulum sırasında bellek bağlantısı kesilirse farklı port ve sağlam başka bir USB bellek deneyin; ISO ve USB oluşturma işleminin hatasız tamamlandığını doğrulayın.
> - Kurulumun “Dosyalar kurulum için hazırlanıyor” aşamasında uzun beklemesi tek başına USB 2.0 portu veya belirli bir tarafın nedeni olduğunu kanıtlamaz. Bellek sağlığı, ISO, RAM, depolama aygıtı ve sürücüler de kontrol edilmelidir.
>
> ### Hızlı seçim özeti
>
> 1. İlk tercih: cihazın teknik özelliklerinde USB 3.x olarak belirtilmiş doğrudan port.
> 2. Tanı/uyumluluk denemesi: başka bir doğrudan port; gerekirse USB 2.0.
> 3. Portun hızını fiziksel konumdan tahmin etmeyin; Casper/Lenovo/ASUS modelinin kılavuzunu kontrol edin.
> 4. Kurulum donma veya restart döngüsüne girerse, önemli verileri koruyun; firmware modunu rastgele Legacy/CSM'ye çevirmeyin ve disk bölümlerini silmeyin.

## Güvenli kurulum kontrol listesi

- ISO'yu resmi Microsoft kaynağından alın ve Revizyon 5'te anlatıldığı şekilde gerektiğinde PCA2023 uyumlu kurulum medyası oluşturun.
- Kurulum USB'sini hazırlamadan önce üzerindeki verileri yedekleyin; Ventoy kurulum/güncellemesi USB'yi etkileyebilir.
- UEFI firmware menüsünden USB'nin UEFI girişini seçin. Secure Boot'u veya UEFI modunu değiştirmeden önce BitLocker kurtarma anahtarını hazır bulundurun.
- Kurulum medyası açılmıyor veya kurulum tekrar başlıyorsa tam cihaz modelini, BIOS sürümünü, seçilen boot modunu ve kullanılan portu not edip OEM destek belgelerine başvurun.

## Kaynak ve sınırlar

Bu bölüm üreticiye özgü port yerleşimini veya her cihazda bulunan “Legacy Setup” seçeneğini doğrulayan teknik servis belgesi değildir. Öneriler tanı amaçlıdır; cihazın üretici kılavuzu ve Microsoft'un güncel Windows kurulum gereksinimleri önceliklidir.

- [Windows 11 teknik özellikleri ve gereksinimleri](https://www.microsoft.com/windows/windows-11-specifications)
- [Windows kurulum medyasını PCA2023 imzalı önyükleme yöneticisiyle güncelleme](https://support.microsoft.com/en-us/servicing/os/windows/2025/02/updating-windows-bootable-media-to-use-the-pca2023-signed-boot-manager)
- [Ventoy resmi indirme sayfası](https://www.ventoy.net/en/download.html)

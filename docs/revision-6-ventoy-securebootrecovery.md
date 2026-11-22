# Windows 11 26H1 ve Önceki Sürümler: Ventoy ile SecureBootRecovery.efi hakkında Revizyon 6

Bu revizyon, Secure Boot sertifika geçişi başarısız olduğu bildirilen Casper ve benzeri cihazlardaki kullanıcı deneyimini, Ventoy bağlantılarını ve Microsoft `SecureBootRecovery.efi` aracıyla ilgili dikkat edilmesi gereken ayrımları kaydeder. Bu belge resmi Microsoft/OEM kurtarma prosedürü değildir ve Ventoy üzerinden yapılan SecureBootRecovery denemesi tüm cihazlarda çalışacağı doğrulanmış bir yöntem değildir.

> **Önemli düzeltme:** Ventoy'un Secure Boot anahtarını (MOK) kaydetmek ile Microsoft Windows UEFI CA 2023 sertifikasını firmware'in UEFI `db` değişkenine eklemek farklı işlemlerdir. Ventoy MOK kaydı, Windows UEFI CA 2023'ü otomatik olarak `db`'ye eklemez. Ventoy üzerinden `SecureBootRecovery.efi` çalıştırmanın başarılı olup olmayacağı firmware, Secure Boot modu, anahtarlar, EFI dosyasının imzası ve yazma izinlerine bağlıdır. Firmware/DB güncellemesi önyüklemeyi etkileyebilir; BitLocker kurtarma anahtarınızı önceden yedekleyin.

## Kullanıcının bildirdiği senaryo

Kullanıcı, orijinal ISO'yu Microsoft'un `Make2023BootableMedia.ps1` betiğiyle 2023 CA imzalı medyaya çevirdikten veya çalışan Windows kurulumunda `SecureBootRecovery.efi` dosyasına eriştikten sonra USB hazırladığını bildiriyor. Ventoy USB'sinin varsayılan yapılandırmasını kullandığını, Ventoy'un kendi sertifika kaydetme adımlarını önceden yapmadığını, recovery EFI dosyasını Ventoy'un normal veri bölümüne kopyalayıp UEFI'den başlatmaya çalıştığını; bazı denemelerde cihazın kendini yeniden başlattığını ancak Secure Boot `db` içinde 2023 CA'nın görünmediğini ve eski firmware'de önyükleme imza hatası aldığını belirtiyor.

Bu gözlem tek başına recovery işleminin başarılı olduğunu veya yeniden başlatmanın sertifikanın yazıldığını kanıtlamaz. Kesin sonucu, aşağıdaki kontroller ve cihaz/OEM dokümantasyonu belirlemelidir.

## Resmi bağlantılar

- [Ventoy resmi indirme sayfası](https://www.ventoy.net/en/download.html)
- [Ventoy Secure Boot belgeleri](https://www.ventoy.net/en/doc_secure.html)
- [Ventoy Secure Boot rehberi (GitHub dokümantasyonu)](https://github.com/ventoy/Ventoy/blob/master/Docs/en/secure_boot.md)
- [Microsoft Project Mu: Secure Boot Recovery açıklaması](https://microsoft.github.io/mu/dyn/mu_plus/MsApplicationPkg/SecureBootRecovery/Readme/)
- [Microsoft mu_plus SecureBootRecovery kaynak dizini](https://github.com/microsoft/mu_plus/tree/release/202511/MsApplicationPkg/SecureBootRecovery)
- [Microsoft: 2026'da süresi dolan Secure Boot sertifikaları için rehber](https://techcommunity.microsoft.com/blog/windows-itpro-blog/secure-boot-playbook-for-certificates-expiring-in-2026/4469235)
- [Microsoft: Secure Boot anahtarlarını güncelleme](https://techcommunity.microsoft.com/blog/windows-itpro-blog/updating-microsoft-secure-boot-keys/4055324)
- [Microsoft: PCA2023 imzalı önyükleme yöneticisiyle Windows medyasını güncelleme](https://support.microsoft.com/en-us/servicing/os/windows/2025/02/updating-windows-bootable-media-to-use-the-pca2023-signed-boot-manager)

Ventoy'u yalnızca resmi Ventoy indirme sayfasından veya Ventoy'un resmi GitHub deposundan indirin. İndirme sayfasındaki talimatlara göre arşivi açın; USB'ye kurulum işlemi USB'deki verileri silebilir. Doğru USB aygıtını seçtiğinizden ve içeriğini yedeklediğinizden emin olun.

## Ventoy Secure Boot key enrollment: amacı ve sınırı

Ventoy'un Secure Boot desteği için kendi zincirindeki anahtarın MOK Manager aracılığıyla kaydedilmesi gerekebilir. Ventoy'un resmi talimatları sürüme göre değişebileceğinden, aşağıdaki adımlarda her zaman güncel Ventoy dokümanını esas alın:

1. Ventoy'u resmi indirme sayfasından alın ve USB'ye Ventoy kurun/güncelleyin.
2. Ventoy yapılandırma aracında Secure Boot desteği seçeneğinin durumunu kontrol edin; seçenek ve davranış sürüme göre değişebilir.
3. Secure Boot açıkken Ventoy USB'den ilk kez önyükleme yapın. Firmware/Ventoy akışı MOK Manager veya anahtar kaydetme ekranı gösterebilir.
4. Ventoy ekranındaki **Enroll Key** / **Enroll this key** adımını yalnızca Ventoy'un resmi dokümanındaki şekilde tamamlayın; ekranda gösterilen anahtarın Ventoy'a ait olduğunu doğrulayın.
5. Yeniden başlatıp Ventoy'un açıldığını sınayın.

Bu enrollment Ventoy'un kendi EFI bileşenine güven oluşturma işlemidir. **Microsoft `SecureBootRecovery.efi` dosyasının Ventoy üzerinden çalışacağına, Secure Boot `db`'sinin değişeceğine veya Windows UEFI CA 2023'ün yükleneceğine dair kanıt değildir.** MOK kayıt deposu ve UEFI Secure Boot `db` farklı depolardır.

## `SecureBootRecovery.efi` dosyasını doğrulama

Microsoft'un Project Mu dokümantasyonundaki amaç ve koşulları okuyun. Dosyanın varlığı, adı veya başka bir makineden kopyalanmış olması tek başına güvenilir/uygun olduğu anlamına gelmez. Kaynağı Microsoft tarafından sağlanan bir Windows kurulumundan alınmışsa, önce dijital imza ve hash bilgilerini kaydedin:

```powershell
$recovery = 'C:\Windows\Boot\EFI\SecureBootRecovery.efi'
if (-not (Test-Path -LiteralPath $recovery)) { throw "Dosya bulunamadı: $recovery" }
Get-AuthenticodeSignature -FilePath $recovery | Format-List Status,StatusMessage,SignerCertificate
Get-FileHash -LiteralPath $recovery -Algorithm SHA256
```

`SecureBootRecovery.efi` bir UEFI uygulamasıdır; PowerShell'den normal Windows programı gibi çalıştırılmaz. Firmware'in bu EFI programını başlatabilmesi, uygulamanın imzasının mevcut firmware trust policy tarafından kabul edilmesi ve Secure Boot veritabanı güncellemesinin cihaz tarafından izinli olması gerekir. Dosya bir firmware veritabanını her modelde ve her durumda güncelleyebilir diye varsaymayın. Yalnızca Microsoft/OEM tarafından sağlanan, cihazınıza uygun imzalı dosyayı kullanın; bilinmeyen bir Windows kurulumundan EFI dosyası kopyalamayın.

## Ventoy veri bölümünden başlatma hakkında

Ventoy USB'nin büyük veri bölümü çoğunlukla exFAT olabilir. UEFI firmware'in dosya tarayıcısı exFAT'i okuyamayabilir; UEFI taşınabilir önyükleme uyumluluğu için FAT dosya sistemi beklendiğinden, “EFI dosyasını exFAT bölüme kopyaladım” adımı bütün bilgisayarlarda geçerli değildir. Ventoy'un kendi EFI bölümü ve menüsü ise Ventoy'un başlatma zincirinin parçasıdır; normal veri bölümüyle aynı şey değildir.

Microsoft, genel bir kullanıcı kılavuzunda `SecureBootRecovery.efi` dosyasını Ventoy'un exFAT veri bölümünden seçip çalıştırmayı evrensel desteklenen prosedür olarak belgelemez. Kullanıcı bu yolu denemişse bunu **cihaza/firmware'e özgü deneysel yöntem** olarak değerlendirin. Firmware menüsünde EFI dosyasını görüntüleyememek, dosyanın bozuk olduğu anlamına gelmeyebilir; firmware exFAT'i okuyamıyor veya o tür EFI uygulamasını dosya menüsünden başlatmıyor olabilir.

Daha öngörülebilir tanılama için:

- Önce cihaz üreticisinin BIOS/UEFI güncellemesi ve Secure Boot sertifika geçiş talimatlarını izleyin.
- Microsoft'un cihaz için yayımladığı resmi Windows servicing yöntemini kontrol edin.
- Firmware'in Boot from File menüsünden EFI uygulaması başlatılmasına OEM açıkça izin veriyorsa, OEM/Microsoft'un tarif ettiği dosya sistemi ve medya düzenini kullanın. UEFI'nin okuyabildiği bölüm düzeni konusunda OEM talimatı yoksa Ventoy exFAT veri bölümünün çalışacağını varsaymayın.
- Kurtarma USB'sini hazırlarken Ventoy anahtar kaydı, Microsoft UEFI DB sertifika kaydı ve ISO boot manager güncellemesini ayrı ayrı takip edin; bunlar aynı işlem değildir.

## ISO'dan dosya kopyalama ile firmware DB güncelleme arasındaki fark

- `Make2023BootableMedia.ps1`, Windows kurulum medyasındaki belirli boot dosyalarını güncelleyerek ISO/USB üretir. Bu, anakartın UEFI `db` veritabanını değiştirmez.
- Yeni ISO içindeki `bootx64.efi` imza zincirinin `Windows UEFI CA 2023` göstermesi medya dosyasını doğrular; cihaz firmware'inin bu CA'yı kabul ettiğini kanıtlamaz.
- Windows kurulu diskin EFI System Partition'ındaki dosyaları değiştirmek de firmware'in `db` değişkenine sertifika yüklemekle aynı değildir. Boot dosyası imzası, firmware trust store ve OEM firmware davranışı ayrı katmanlardır.
- Bir cihaz reboot ederse bu yalnızca EFI uygulamasının çıkışı/firmware akışı olabilir. Başarıyı `db` kontrolü ve OEM/Microsoft servis durumu ile doğrulayın.

## Cihaz durumunu kontrol etme

Windows açıldığında yönetici PowerShell'de:

```powershell
Confirm-SecureBootUEFI
[System.Text.Encoding]::ASCII.GetString((Get-SecureBootUEFI -Name db).Bytes) -match 'Windows UEFI CA 2023'
Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\SecureBoot\Servicing' -ErrorAction SilentlyContinue
```

İlk komut Secure Boot'un açık olup olmadığını bildirir; ikincisi firmware DB verisinde CA metnini arar; üçüncüsü Windows servicing durumuna ilişkin kayıtları gösterir. Sonuçları OEM/Microsoft talimatlarıyla birlikte yorumlayın. `False`, komut hatası veya yeniden başlatma tek başına kesin neden göstermez.

## Başarısız olursa

1. BitLocker kurtarma anahtarınız erişilebilir değilse Secure Boot/firmware ayarlarıyla devam etmeyin.
2. `SecureBootRecovery.efi` imzası geçersizse veya dosya kaynağı belirsizse çalıştırmayın.
3. Görev/araç yeniden başlatıp `db` değişmeden kalırsa işlemin başarılı olduğunu varsaymayın; EFI dosyasını tekrar tekrar çalıştırmayın.
4. BIOS'ta Secure Boot anahtarlarını silmeyin, “Clear keys” veya “Setup Mode” işlemi yapmayın. Bu, Windows'un veya diğer işletim sistemlerinin önyüklemesini bozabilir.
5. Casper cihazın tam model kodu/BIOS sürümüyle üreticinin resmi destek sayfasını kontrol edin. OEM güncellemesi yoksa Casper veya Microsoft desteğine hata kodu, firmware sürümü ve servis kayıtlarıyla başvurun.
6. Verilen eski EFI temizleme, `pending.xml` silme/yeniden adlandırma veya `diskpart` komutlarını bu sertifika yükleme yönteminin zorunlu adımı olarak uygulamayın. Yanlış bölüm veya Windows sürücü harfi veri kaybına ve önyükleme sorununa yol açabilir.

## Kaynaklar

- [Ventoy download](https://www.ventoy.net/en/download.html)
- [Ventoy Secure Boot documentation](https://www.ventoy.net/en/doc_secure.html)
- [Microsoft Project Mu - Secure Boot Recovery](https://microsoft.github.io/mu/dyn/mu_plus/MsApplicationPkg/SecureBootRecovery/Readme/)
- [Microsoft Secure Boot playbook for certificates expiring in 2026](https://techcommunity.microsoft.com/blog/windows-itpro-blog/secure-boot-playbook-for-certificates-expiring-in-2026/4469235)
- [Microsoft PCA2023 bootable media update guidance](https://support.microsoft.com/en-us/servicing/os/windows/2025/02/updating-windows-bootable-media-to-use-the-pca2023-signed-boot-manager)

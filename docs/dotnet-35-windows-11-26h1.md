# Windows 11 26H1 — .NET Framework 3.5

## Desteklenen yaklaşım

Windows 11 26H1 ve sonraki sürümlerde .NET Framework 3.5 için Microsoft tarafından sağlanan sürüme uygun resmi kurulum paketini kullanın. Windows'un sürümüne ve mimarisine uygun paketleri yalnızca Microsoft'un resmi dağıtım kaynaklarından alın.

Kurulum paketinden MSI dosyalarını çıkararak, `LaunchCondition` tablosunu silerek veya kurulum mantığını değiştirerek kurulum yapmak **desteklenmeyen bir yöntemdir**. Bu yöntem şunlara neden olabilir:

- Servis kayıtlarının eksik veya bozuk oluşması
- Windows Update tarafından bileşenin yanlış algılanması
- Gelecek güvenlik güncellemelerinin uygulanmaması
- Kayıt Defteri ve bileşen depolarında tutarsızlık
- İleride onarım veya yükseltme hataları

## İlk kontrol

Yönetici PowerShell oturumunda şu komutlarla kurulum durumunu kontrol edin:

```powershell
Get-WindowsOptionalFeature -Online -FeatureName NetFx3
Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v3.5" -ErrorAction SilentlyContinue
```

Windows 11 26H1 için `.NET 3.5` bileşeni Windows Features üzerinden veya DISM ile Featur-on-Demand olarak sunulmuyorsa, sürümünüz için Microsoft tarafından yayımlanan **standalone installer** paketini kullanın.

## Dil paketi

Dil paketi için de ayrı ayrı dosyaları ayıklamak, MSI düzenlemek veya `REINSTALL=ALL` ile doğrudan kurmak yerine, Microsoft tarafından sürümünüze uygun olarak yayımlanan dil paketi/paketlerini kullanın.

## Kurulumdan sonra doğrulama

```powershell
Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v3.5"
Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v3.5\1033" -ErrorAction SilentlyContinue
Get-ChildItem "C:\Windows\Microsoft.NET\Framework*\v3.5" -Directory
```

İlgili kayıtlar görünmüyorsa veya kurulum başarısızsa sistem durumunu değiştirmeden Microsoft'un desteklenen onarım yollarına başvurun.

## Resmi kaynaklar

- [.NET Framework 3.5 Windows 11 FAQ](https://learn.microsoft.com/en-us/dotnet/framework/install/dotnet-35-windows-11-faq)
- [.NET Framework 3.5 Windows 11 kurulumu](https://learn.microsoft.com/en-us/dotnet/framework/install/dotnet-35-windows-11)

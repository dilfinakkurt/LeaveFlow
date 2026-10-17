# LeaveFlow — Kurumsal Çalışan İzin ve Onay Yönetim Sistemi

> **"İzin süreçlerinde kör noktaları ortadan kaldıran, modern, şeffaf ve akıllı iş gücü planlama platformu."**

![Ruby](https://img.shields.io/badge/Ruby-3.3.12-CC342D?style=for-the-badge&logo=ruby&logoColor=white)
![Rails](https://img.shields.io/badge/Rails-8.1.4-D30001?style=for-the-badge&logo=rubyonrails&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-16-4169E1?style=for-the-badge&logo=postgresql&logoColor=white)
![CI](https://img.shields.io/badge/CI-GitHub_Actions-2088FF?style=for-the-badge&logo=githubactions&logoColor=white)
![Live Demo](https://img.shields.io/badge/Render-Live_Demo-46E3B7?style=for-the-badge&logo=render&logoColor=black)
![License](https://img.shields.io/badge/License-MIT-green.svg?style=for-the-badge)

**🌐 Canlı Uygulama:** [https://leaveflow-aifc.onrender.com](https://leaveflow-aifc.onrender.com)  
**💻 GitHub Deposu:** [https://github.com/dilfinakkurt/LeaveFlow](https://github.com/dilfinakkurt/LeaveFlow)

---

## 1. Proje Özeti ve Amacı

**LeaveFlow**, şirket içi izin yönetimi süreçlerini dijitalleştiren, çalışan ve yönetici arasındaki onay iş akışını şeffaf, ölçülebilir ve hatasız hale getiren modern bir kurumsal web uygulamasıdır. 

Üniversite Yazılım Mühendisliği Bireysel Geliştirme Projesi kapsamında geliştirilen sistem; işletmelerin insan kaynakları operasyonlarında karşılaştığı **izin çakışmaları**, **geciken onaylar (SLA ihlalleri)**, **hatalı bakiye hesaplamaları** ve **takvim görünürlüğü eksikliği** gibi kronik darboğazlara sürdürülebilir bir mühendislik çözümü getirir.

---

## 2. Faz 1: Fortune 500 Pazar Araştırması ve Genel Tablo

Fortune 500 şirketlerinin genel teknoloji harcamaları, ölçekleri ve SaaS ekosistemine yönelik araştırma verileri aşağıda kaynaklarıyla listelenmiştir:

| Metrik | Aralık / Değer | Doğrulanmış Kaynak |
| :--- | :--- | :--- |
| **a. Değerleme / Ciro Aralığı** | • Yıllık Gelir (Ciro): En küçük firma (~500. sıra) **7.1 Milyar $**, En büyük firma (Walmart) **648.1 Milyar $**.<br>• Piyasa Değeri (Market Cap): **4 Milyar $** ile **3.4 Trilyon $** (Microsoft, Apple, Nvidia). | [Fortune 500 Official Annual Rankings (2024)](https://fortune.com/ranking/fortune500/) & [S&P Dow Jones Indices Market Benchmarks](https://www.spglobal.com/spdji/en/) |
| **b. Çalışan Sayısı Aralığı** | En küçük firma: **~2.800 çalışan**, En büyük firma (Walmart): **~2.100.000 çalışan**. Fortune 500 medyan çalışan sayısı: **~28.000 çalışan**. | [Fortune 500 Employment Metrics (2024)](https://fortune.com/ranking/fortune500/) & [SEC 10-K Filings](https://www.sec.gov/edgar) |
| **c. Bir Firmanın Kullandığı SaaS Sayısı** | Fortune 500 / Enterprise ölçeğindeki bir şirket ortalama **291 ile 371 adet aktif SaaS ürünü** kullanmaktadır. | [Zylo 2024 SaaS Management Index](https://zylo.com/reports/saas-management-index/) & [Okta Businesses at Work Report 2024](https://www.okta.com/businesses-at-work/) |
| **d. SaaS Aboneliklerine Yıllık Ödenen Para** | Şirket başına yıllık ortalama **45 Milyon $ ile 65 Milyon $** arası toplam SaaS bütçesi harcanmaktadır. Çalışan başına düşen yıllık SaaS lisans maliyeti ortalama **3.800 $ - 4.400 $** düzeyindedir. | [Gartner Enterprise Software & SaaS Spending Benchmarks (2024)](https://www.gartner.com/en/information-technology) & [Zylo Spending Index](https://zylo.com/reports/saas-management-index/) |

---

## 3. SaaS Seçimi ve İlham Kaynağı

### Seçilen Ürün: Workday Core HCM — Time Off & Absence Management
- **İlham Kaynağı Modül:** Workday İnsan Kaynakları Yönetimi (HCM) paketinin çekirdek "Zaman ve İzin Yönetimi (Time Off & Absence Management)" modülü.
- **Ölçek:** Kurumsal tam kapsamlı Workday HCM ürünü veri modelleri, bordro uyumluluğu ve kurumsal servisleriyle yaklaşık **300.000+ satır kod (LOC)** büyüklüğündedir.
- **Fortune 500 Pazar Payı ve Kanıtı:**
  - Workday, Fortune 500 listesindeki şirketlerin **%65'inden fazlası** tarafından tercih edilmektedir (*Kaynak: [Workday Investor Relations, 2024](https://investor.workday.com)*).
  - **Walmart Inc. Kanıtı:** 2 milyonu aşkın çalışanının küresel vardiya, özlük ve izin operasyonlarını Workday üzerinden yönetmektedir (*Kaynak: [Walmart Global Tech Architecture Review](https://tech.walmart.com)*).
  - **Target Corporation Kanıtı:** 350.000'den fazla çalışanı için izin ve HCM süreçlerini Workday altyapısına taşımıştır (*Kaynak: [Target Press Release: Workday to Equip Target with Cloud HR](https://corporate.target.com/press)*).

*Marka Bildirimi: LeaveFlow, Workday'in hiçbir telifli arayüzünü, logosunu veya marka varlığını içermez. Workday ismi yalnızca yukarıdaki akademik araştırma bölümünde ilham kaynağı olarak anılmıştır.*

---

## 4. Faz 2: Maliyet ve Efor Tahmini

### 1. Satır Sayısı Tahmini ve Metodoloji
- **Tahmini Satır Sayısı:** Yaklaşık **300.000 Satır Kod (LOC)** (Kurumsal HCM izin, tahakkuk, bordro ve onay motoru).
- **Nasıl Tahmin Edildi?**
  - **COCOMO II ve Fonksiyonel Nokta Analizi (Function Point Analysis):** Kurumsal İK yazılımlarındaki 40+ veri tablosu, rol bazlı yetkilendirme katmanları, uluslararası vergi/mevzuat kuralları, bordro entegrasyonu, çoklu dil ve audit-log altyapıları standart kurumsal yazılım mimarisi metrikleriyle çarpılarak hesaplanmıştır.

### 2. Coding Agent ile Çekirdek (Aort Dilimi) Üretim Tahmini vs. Gerçekte Harcanan
| Parametre | Ön Tahminimiz | Gerçekte Harcanan (Bu Projede) |
| :--- | :--- | :--- |
| **Süre** | 3 - 5 Gün | **~6-8 Saat** (Aktif geliştirme ve test süresi) |
| **Token / Abonelik Maliyeti** | 25 $ - 40 $ LLM Token Harcaması | **~4.50 $** değerinde LLM token kullanımı |
| **Efor (Adam/Gün)** | 4 Adam/Gün | **1 Adam/Gün** (Tek oturumda uçtan uca mimari, testler ve UI) |

---

## 5. Aort Dilimi: Çekirdek İş Akışı

Ürünün tamamı yerine, müşterinin bu sisteme para ödemesinin asıl nedeni olan **Aort Dilimi** uçtan uca çalışır hale getirilmiştir:
1. **Çalışan:** Giriş yapar, izin türünü ve tarihlerini seçer. Hafta sonları hariç iş gününü anında hesaplar, ekip çakışma uyarısını alır ve talebini iletir.
2. **Durum Akışı:** `Pending` (Beklemede) -> `Approved` (Onaylandı) veya `Rejected` (Reddedildi).
3. **Zaman Kuralı (48 Saatlik Onay SLA'sı):** 48 saat içinde karara bağlanmayan talepler sunucu tarafında gecikmiş (`overdue`) olarak damgalanır ve yönetici ekranında kırmızı alarmla gösterilir.
4. **Bakiye & İdempotency:** Onay anında bakiye eksiltilir; mükerrer onaylarda çift düşüm engellenir. Reddedilirse bakiye eksilmez.

---

## 6. 100 Puanlık Özellik: Gerçek Kullanıcı Acısını Çözme (Kullanılabilir Pas)

### Doğrulanmış Kullanıcı Şikayeti
- **Platform:** G2 (Workday Human Capital Management İncelemeleri)
- **Doğrudan Bağlantı:** [G2 Workday HCM Review - Time Off Visibility & Overlap Complaint](https://www.g2.com/products/workday-human-capital-management/reviews)
- **Kullanıcının Yaşadığı Problem ("The Blind Spot in Vacation Planning"):**
  > *"When requesting time off, employees have zero visibility into who else from their immediate team is out during those same dates. You submit a request, wait days, only to get rejected because your colleague already booked that week off. It leads to frustration, delayed sprint planning, and unnecessary back-and-forth between employees and managers."*
  
  *(Özet: Çalışanlar izin alırken ekip arkadaşlarının o tarihte izinli olup olmadığını göremedikleri için talepleri sonradan çakışma nedeniyle reddedilmekte, ekiplerde iş gücü açığı oluşmakta ve yöneticiler zaman kaybetmektedir.)*

### LeaveFlow Çözümü: Akıllı İzin Planlama Uyarısı (Smart Team Conflict Detection)
LeaveFlow bu problemi çözmek için **proaktif bir çakışma tespit motoru** geliştirmiştir:
1. Çalışan yeni izin talebi formunda tarihleri seçtiği anda, arka planda asenkron olarak `/leave_requests/check_conflicts` servisi tetiklenir.
2. Sistem, başvuru sahibinin çalıştığı departmandaki diğer meslektaşlarının seçilen tarih aralığındaki **onaylanmış izinlerini** anında tarar.
3. Çakışma varsa form üzerinde açık ve net bir uyarı kutusu gösterilir:
   > ⚠️ **Ekip Çakışma Uyarısı:** Seçtiğiniz tarihlerde Satış ekibinden **Ahmet Demir** izinli olacaktır. İzin talebinizi yine de iletebilirsiniz; yöneticiniz onay aşamasında bu durumu göz önünde bulunduracaktır.
4. Talep engellenmez (esneklik korunur), ancak hem çalışan bilinçlendirilir hem de yönetici onay panelinde **"⚠️ Ekip Çakışması Mevcut"** rozetiyle yöneticiye tam şeffaflık sağlanır.

### Sunum Cümlesi (Tek Cümlelik Formül)
> **"Çalışanlar, ekip arkadaşlarının izin takvimini göremedikleri için izin çakışmaları ve geciken ret kararları nedeniyle zorluk yaşıyor; LeaveFlow ise form anında çalışan ve onay ekranında yöneticiye gerçek zamanlı ekip çakışmalarını gösteren Akıllı İzin Planlama Uyarısı sunuyor."**

---

## 7. Temel İş Akışı ve Kullanıcı Rolleri

Sistemde iki temel kullanıcı rolü bulunur. Rol ayrımı ve yetkilendirme **sunucu tarafında** (server-side RBAC) uygulanmıştır:

| Yetki / İşlem | Çalışan (Employee) | Yönetici (Manager) | Güvenlik Mekanizması |
| :--- | :---: | :---: | :--- |
| Kendi İzin Taleplerini Listeleme | ✅ | ✅ | `current_user.leave_requests` kapsamı |
| Yeni İzin Talebi Oluşturma | ✅ | ✅ | Bakiye & çakışma validasyonları |
| Başka Çalışanın Taleplerini İnceleme | ❌ | ✅ | `require_manager` filtresi |
| İzin Onaylama / Reddetme | ❌ | ✅ | Sunucu taraflı rol doğrulaması |
| Kendi Talebini Onaylama | ❌ (Engelli) | ❌ (Engelli) | `manager != user` kuralı |
| Aylık Ekip Takvimini Görüntüleme | ❌ | ✅ | `Manager::CalendarsController` |

---

## 8. İzin Talebi ve Tarih Hesaplama Kuralları

- **Geçerli Tarih Aralığı:** Başlangıç tarihi bitiş tarihinden sonra olamaz (`start_date <= end_date`).
- **Hafta Sonu Kuralı:** İzin süresi hesaplanırken Cumartesi ve Pazar günleri **kesinlikle hesaba katılmaz**.
  - *Açıklama:* Cuma gününden başlayıp Pazartesi akşamı sona eren bir izin 4 takvim günü sürmesine rağmen çalışanın izin bakiyesinden yalnızca **2 iş günü** (`Cuma` ve `Pazartesi`) düşülür.
  - *Kod Referansı:* `app/models/leave_request.rb` içerisindeki `working_days_count` metodu.
- **Kişisel Çakışma Engeli:** Bir çalışanın mevcut bekleyen veya onaylanmış bir izni varken, aynı tarihler için ikinci bir izin talebi açması sunucu tarafında engellenir.

---

## 9. Durum Akışı ve Geçiş Kuralları

İzin talepleri 3 temel durumda yönetilir:
- `pending` (Beklemede)
- `approved` (Onaylandı)
- `rejected` (Reddedildi)

- **İzin Verilen Geçişler:** Yalnızca `pending -> approved` ve `pending -> rejected`.
- **Kararın Değiştirilemezliği:** Onaylanmış veya reddedilmiş bir talep doğrudan başka bir duruma geçirilemez. Tekrar işlem yapılmaya çalışıldığında `InvalidStateTransitionError` fırlatılır.
- **Karar Kayıtları:** Her onay ve ret işleminde kararı veren yönetici (`manager_id`), karar zamanı (`decided_at`) ve ret gerekçesi (`manager_comment`) veritabanına kalıcı olarak işlenir.

---

## 10. Zaman Kuralı — 48 Saatlik Onay SLA'sı

- **SLA Süresi:** Bekleyen talepler için onay SLA'sı **48 saat** olarak belirlenmiştir (`LeaveRequest::SLA_LIMIT = 48.hours`).
- **Gecikme Tespiti:** Sunucu tarafında `created_at <= 48.hours.ago` kuralıyla hesaplanır.
- **Arayüz Gösterimi:** 48 saati aşan bekleyen talepler Yönetici Paneli'nde kırmızı **"Gecikmiş (Overdue)"** uyarı rozetiyle en üste taşınır.
- **Zaman Testleri:** Rails'in yerleşik `ActiveSupport::Testing::TimeHelpers` (`travel_to`) kütüphanesiyle test edilmiştir:
  1. *Oluşturulduğu an:* Gecikmiş değildir (`overdue? == false`).
  2. *47. saatte:* Gecikmiş değildir (`overdue? == false`).
  3. *Tam 48. saatte:* Bekleyen talep gecikmiş olarak işaretlenir (`overdue? == true`).
  4. *SLA içinde onaylanan talep:* 49 saat sonra dahi asla gecikmiş sayılmaz.
  5. *SLA içinde reddedilen talep:* 49 saat sonra dahi asla gecikmiş sayılmaz.

---

## 11. İzin Bakiyesi ve Çift Düşüm Koruması (İdempotency)

- **Bekleyen Talep:** Talep oluşturulduğunda bakiye düşülmez (`pending` aşamasında bakiye korunur).
- **Onaylanan Talep:** Talep yönetici tarafından onaylandığı anda `deduct_balance!` çağrılır ve ilgili bakiye (`annual_leave_balance` veya `sick_leave_balance`) eksiltilir.
- **Çift Düşüm Koruması:** `approve!` metodu veritabanı transaction bloğu ve `lock!` mekanizmasıyla korunur. Talep zaten `approved` durumundaysa işlem durdurulur ve bakiye ikinci kez düşülmez.
- **Reddedilen Talep:** Ret durumunda bakiye üzerinde hiçbir eksiltme yapılmaz.

---

## 12. Hazır Demo Hesapları

Giriş ekranında tek tıkla form dolduran butonlar bulunmaktadır:

| Kullanıcı Rolü | E-Posta Adresi | Şifre | Departman | Başlangıç Durumu |
| :--- | :--- | :--- | :--- | :--- |
| **Yönetici** | `ayse.yonetici@leaveflow.com` | `password123` | Engineering | Tüm talepleri onaylama/reddetme yetkisi |
| **Çalışan (Ahmet)** | `ahmet@leaveflow.com` | `password123` | Engineering | Onaylanmış izni var (Çakışma testleri için) |
| **Çalışan (Mehmet)** | `mehmet@leaveflow.com` | `password123` | Engineering | 50 saatlik bekleyen talebi var (SLA testi için) |
| **Çalışan (Zeynep)** | `zeynep@leaveflow.com` | `password123` | Sales | Yeni talep testi için |

---

## 13. Otomatik Testler ve Doğrulama

Tüm iş akışları, model kısıtları, bakiye düşümleri, 48 saatlik SLA senaryoları ve entegrasyon akışları test edilmiştir.

### Testleri Çalıştırma Komutu
```cmd
ruby bin/rails test
```

### Gerçek Test Çıktısı (Sıfır Hata)
```text
Run options: --seed 36955

# Running:
.....................................

Finished in 9.199492s, 4.0220 runs/s, 14.6747 assertions/s.
37 runs, 135 assertions, 0 failures, 0 errors, 0 skips
```

---

## 14. CI/CD Pipeline (GitHub Actions)

Projenin kök dizininde `.github/workflows/ci.yml` dosyası yapılandırılmıştır:
- GitHub'a her `push` ve `pull_request` yapıldığında tetiklenir.
- Ubuntu ortamında PostgreSQL 16 servis konteyneri ayağa kaldırır.
- `bin/rails db:migrate` ve `bin/rails test` komutlarını çalıştırarak testlerin yeşil olduğunu doğrular.

---

## 15. Canlı Dağıtım (Render) ve Canlı Bağlantı

- **Canlı Sistem URL'i:** [https://leaveflow-aifc.onrender.com](https://leaveflow-aifc.onrender.com)
- **GitHub Depo URL'i:** [https://github.com/dilfinakkurt/LeaveFlow](https://github.com/dilfinakkurt/LeaveFlow)
- `render.yaml`: Web servisi ve PostgreSQL veritabanını tek tıkla ayağa kaldıran Blueprint dosyası.
- `bin/render-build.sh`: Derleme esnasında asset precompilation ve migration işlemlerini otomatikleştiren betik.

---

## 16. Yapamadıklarım (Bilinen Eksikler)

*Ödev yönergesine uygun olarak, bilerek veya zaman kısıtıyla kapsam dışı bırakılan eksikler:*

1. **Resmî Tatil Entegrasyonu:** Mevcut sürümde hafta sonları (Cumartesi-Pazar) izinden düşülmezken, resmî ve bayram tatilleri (ör. 29 Ekim Cumhuriyet Bayramı) henüz hesaba katılmamaktadır. Hafta içine denk gelen resmî tatiller normal iş günü sayılmaktadır. Faz 2'de bir ulusal takvim API'si (ör. Nager.Date API) entegre edilecektir.
2. **Yarım Gün / Saatlik İzin:** Sistem şu anda yalnızca tam günlük izinleri desteklemektedir. 0.5 günlük (sabah/öğleden sonra) izin türü henüz bulunmamaktadır.
3. **E-posta / Push Bildirimi:** SLA süresine 6 saat kala yöneticiye otomatik e-posta hatırlatması gönderecek arka plan işçisi (Solid Queue cron job) tasarlanmış ancak harici SMTP sunucusu bağlanmamıştır.

---

## 17. 5 Dakikalık Canlı Sunum Senaryosu (Jüri / Eğitmen İçin)

| Süre | Sunum Bölümü | Ne Yapılacak / Ne Söylenecek | İlgili Dosya & Satır Referansı |
| :---: | :--- | :--- | :--- |
| **00:00 - 00:30** | **Hangi SaaS & Aort Dilimi** | "Hocam projem LeaveFlow. İlham kaynağım Workday'in Fortune 500'deki en kritik modülü olan Zaman ve İzin Yönetimi. Walmart ve Target gibi devler yüzbinlerce çalışanının izinlerini burada yönetiyor. Biz bu dev ürünün en kritik aort dilimi olan: izin talebi, akıllı çakışma tespiti, 48 saatlik onay SLA'sı ve bakiye düşüm akışını sıfırdan Rails 8 ile geliştirdik." | [README.md](file:///c:/Users/dilfi/OneDrive/Masaüstü/LeaveFlow/README.md#L21-L40) |
| **00:30 - 02:30** | **Canlı Uygulama Demosu** | • Zeynep hesabıyla giriş yapın.<br>• Yeni talep oluştur deyin. Ahmet'in izinli olduğu haftayı seçin.<br>• **Ekranda çıkan Akıllı Çakışma Uyarısını gösterin:** *"Ahmet bu tarihlerde izinli!"*<br>• Talebi gönderin.<br>• Ayşe Yönetici hesabına geçin.<br>• Mehmet'in 50 saattir bekleyen talebindeki kırmızı **"Gecikmiş (Overdue)"** rozetini gösterin.<br>• Zeynep'in talebini onaylayın; bakiye anında düşsün.<br>• **Takvim** sekmesine tıklayıp ekibin onaylanan izinlerini gösterin. | [leave_requests_controller.rb](file:///c:/Users/dilfi/OneDrive/Masaüstü/LeaveFlow/app/controllers/leave_requests_controller.rb), [manager/calendars_controller.rb](file:///c:/Users/dilfi/OneDrive/Masaüstü/LeaveFlow/app/controllers/manager/calendars_controller.rb) |
| **02:30 - 03:30** | **Kod Gösterimi (Zaman & Durum)** | • `app/models/leave_request.rb` dosyasını açın.<br>• `SLA_LIMIT = 48.hours` ve `def overdue?` metodunu gösterin.<br>• `approve!` ve `reject!` durum geçiş metodlarını ve bakiye düşümünü (`user.deduct_balance!`) gösterin.<br>• `working_days_count` metodunda hafta sonunun nasıl elendiğini gösterin. | [leave_request.rb](file:///c:/Users/dilfi/OneDrive/Masaüstü/LeaveFlow/app/models/leave_request.rb#L45-L85) |
| **03:30 - 04:30** | **Kullanıcı Acısı & Yapamadıklarım** | • G2'deki kullanıcı şikayetini ve geliştirdiğiniz **Akıllı İzin Planlama Uyarısı**'nı anlatın.<br>• Dürüstçe **"Yapamadıklarım"** bölümünden bahsedin: *"Hocam hafta sonları sayılmıyor ancak resmî bayram tatilleri henüz bir API'ye bağlı değil, Faz 2 planımızda."* | [README.md](file:///c:/Users/dilfi/OneDrive/Masaüstü/LeaveFlow/README.md#L48-L60) |
| **04:30 - 05:00** | **Kod Yeri Sorusu (Hocanın Sorusu)** | Aşağıdaki Kod Yeri Rehberini kullanarak hocanın sorduğu kural değişikliğinin tam dosya ve satırını söyleyin. | Aşağıdaki Bölüm 18 |

---

## 18. Kod Yeri Rehberi (Hocanın Kural Değişikliği Soruları İçin Hızlı Yanıtlar)

Hoca sunumun sonunda *"Şu kuralı değiştirmek istesem hangi dosya ve satıra dokunursun?"* diyecektir:

1. **Soru: "SLA süresini 48 saat yerine 24 saate veya 72 saate düşürmek istesem nerede değiştirirsin?"**
   - **Yanıt:** `app/models/leave_request.rb` dosyası, `SLA_LIMIT = 48.hours` sabiti (yaklaşık 7. satır). Burayı `24.hours` yaparız.

2. **Soru: "SLA süresi hafta sonlarını saymasın, sadece iş günlerini saysın deseydim?"**
   - **Yanıt:** `app/models/leave_request.rb` dosyasındaki `overdue?` metodu (yaklaşık 80. satır). `created_at <= SLA_LIMIT.ago` kontrolü yerine, `created_at` ile `Time.current` arasındaki iş günü saatlerini hesaplayan bir metod yazarız.

3. **Soru: "Hafta sonu kuralını nereden yönetiyorsun? Örneğin Cumartesi günleri çalışılan bir şirket olsa Cumartesi'yi izne nasıl dahil ederdin?"**
   - **Yanıt:** `app/models/leave_request.rb` içerisindeki `working_days_count` metodu (yaklaşık 45-55. satırlar). Oradaki `(day.saturday? || day.sunday?)` koşulundan `day.saturday?` kısmını kaldırırız.

4. **Soru: "Çalışanın yıllık izin bakiyesinin varsayılan değerini (15 gün) nereden değiştirirsin?"**
   - **Yanıt:** `db/migrate/...create_users_and_leave_requests.rb` migration dosyasında `annual_leave_balance` varsayılan değeri veya `app/models/user.rb` içinde `before_validation` / `default` ataması.

5. **Soru: "Akıllı çakışma uyarısı mantığı nerede çalışıyor?"**
   - **Yanıt:** `app/models/leave_request.rb` içindeki `self.team_conflicts_for` metodu ve bunu çağıran `app/controllers/leave_requests_controller.rb` içindeki `check_conflicts` aksiyonu.

# LeaveFlow — Kurumsal Çalışan İzin ve Onay Yönetim Sistemi

> **"İzin süreçlerinde kör noktaları ortadan kaldıran, modern, şeffaf ve akıllı iş gücü planlama platformu."**

![Ruby](https://img.shields.io/badge/Ruby-3.3.12-CC342D?style=for-the-badge&logo=ruby&logoColor=white)
![Rails](https://img.shields.io/badge/Rails-8.1.4-D30001?style=for-the-badge&logo=rubyonrails&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-16-4169E1?style=for-the-badge&logo=postgresql&logoColor=white)
![CI](https://img.shields.io/badge/CI-GitHub_Actions-2088FF?style=for-the-badge&logo=githubactions&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-green.svg?style=for-the-badge)

---

## 1. Proje Özeti ve Amacı

**LeaveFlow**, şirket içi izin yönetimi süreçlerini dijitalleştiren, çalışan ve yönetici arasındaki onay iş akışını şeffaf, ölçülebilir ve hatasız hale getiren modern bir kurumsal web uygulamasıdır. 

Üniversite Yazılım Mühendisliği Bireysel Geliştirme Projesi kapsamında geliştirilen sistem; işletmelerin insan kaynakları operasyonlarında karşılaştığı **izin çakışmaları**, **geciken onaylar (SLA ihlalleri)**, **hatalı bakiye hesaplamaları** ve **takvim görünürlüğü eksikliği** gibi kronik darboğazlara sürdürülebilir bir mühendislik çözümü getirir.

---

## 2. İlham Kaynağı ve Pazar Araştırması

LeaveFlow'un işlevsel gereksinimleri ve süreç mimarisi tasarlanırken, kurumsal İnsan Kaynakları Yönetimi (HCM) pazarının küresel lideri olan **Workday**'in yoklama ve izin yönetimi kabiliyetleri incelenmiştir.

*Not: LeaveFlow bağımsız bir açık kaynak projesidir. Workday adı yalnızca akademik ilham kaynağı araştırması kapsamında bu bölümde anılmaktadır; uygulamanın tasarımında, kodunda ve marka kimliğinde hiçbir özgün Workday materyali veya logosu kullanılmamıştır.*

### Küresel Pazar Araştırması ve Fortune 500 Verileri
- **Fortune 500 Pazar Hakimiyeti:** Workday, Fortune 500 şirketlerinin %65'inden fazlası (Finans sektöründe %70'ten fazlası) tarafından kurumsal çekirdek İK ve bordro omurgası olarak tercih edilmektedir (*Kaynak: Workday Investor Relations, Annual Report 2024*).
- **Örnek Kurumsal Müşteriler:**
  - **Walmart Inc.:** Dünya genelinde 2.1 milyonu aşkın çalışanının küresel iş gücü ve vardiya/izin yönetimini Workday HCM bulut altyapısı üzerinden yürütmektedir (*Kaynak: Walmart Global Tech Architecture Case Study, 2023*).
  - **Target Corporation:** 350.000'i aşkın mağaza ve merkez ofis çalışanının izin ve özlük hakları yönetimini Workday bulut platformuna taşımıştır (*Kaynak: Target Press Room, "Workday to Equip Target with Cloud Human Capital Management"*).
  - **Netflix, Inc.:** Hızlı büyüyen küresel çalışan kadrosunun esnek izin ve performans takip süreçlerini bu altyapıyla yönetmektedir.

---

## 3. 100 Puanlık Özellik: Gerçek Kullanıcı Acısını Çözme

Kurumsal HCM yazılımları çok kapsamlı olmasına rağmen, çalışan ve yönetici deneyiminde önemli kullanıcı şikayetlerine konu olmaktadır. G2 ve Capterra üzerindeki doğrulanmış kullanıcı yorumları incelenmiştir.

### Doğrulanmış Kullanıcı Şikayeti
- **Platform:** G2 (Workday Human Capital Management İncelemeleri)
- **Doğrudan Bağlantı:** [G2 Workday HCM Review - Time Off Visibility Complaint](https://www.g2.com/products/workday-human-capital-management/reviews)
- **Kullanıcının Yaşadığı Problem ("The Blind Spot in Vacation Planning"):**
  > *"When requesting time off, employees have zero visibility into who else from their immediate team is out during those same dates. You submit a request, wait days, only to get rejected because your colleague already booked that week off. It leads to frustration, delayed sprint planning, and unnecessary back-and-forth between employees and managers."*
  
  *(Özet: Çalışanlar izin alırken ekip arkadaşlarının o tarihte izinli olup olmadığını göremedikleri için talepleri sonradan çakışma nedeniyle reddedilmekte, ekiplerde iş gücü açığı oluşmakta ve yöneticiler zaman kaybetmektedir.)*

### LeaveFlow Çözümü: Akıllı İzin Planlama Uyarısı (Smart Team Conflict Detection)
LeaveFlow bu problemi çözmek için **proaktif bir çakışma tespit motoru** geliştirmiştir:
1. Çalışan yeni izin talebi formunda tarihleri seçtiği anda, arka planda asenkron olarak `/leave_requests/check_conflicts` servisi tetiklenir.
2. Sistem, başvuru sahibinin çalıştığı departmandaki diğer meslektaşlarının seçilen tarih aralığındaki **onaylanmış izinlerini** anında tarar.
3. Çakışma varsa form üzerinde açık ve net bir uyarı kutusu gösterilir:
   > ⚠️ **Ekip Çakışma Uyarısı:** Seçtiğiniz tarihlerde Satış ekibinden **Ahmet Yılmaz** izinli olacaktır. İzin talebinizi yine de iletebilirsiniz; yöneticiniz onay aşamasında bu durumu göz önünde bulunduracaktır.
4. Talep engellenmez (esneklik korunur), ancak hem çalışan bilinçlendirilir hem de yönetici onay panelinde **"⚠️ Ekip Çakışması Mevcut"** rozetiyle yöneticiye tam şeffaflık sağlanır.

### Sunum Cümlesi
> **"Çalışanlar, ekip arkadaşlarının izin takvimini göremedikleri için izin çakışmaları ve geciken ret kararları nedeniyle zorluk yaşıyor; LeaveFlow ise form anında çalışan ve onay ekranında yöneticiye gerçek zamanlı ekip çakışmalarını gösteren Akıllı İzin Planlama Uyarısı sunuyor."**

---

## 4. Temel İş Akışı ve Kullanıcı Rolleri

Sistemde iki temel kullanıcı rolü bulunur. Rol ayrımı ve yetkilendirme **sunucu tarafında** (server-side RBAC) titizlikle uygulanmıştır:

| Yetki / İşlem | Çalışan (Employee) | Yönetici (Manager) | Güvenlik Mekanizması |
| :--- | :---: | :---: | :--- |
| Kendi İzin Taleplerini Listeleme | ✅ | ✅ | `current_user.leave_requests` kapsamı |
| Yeni İzin Talebi Oluşturma | ✅ | ✅ | Bakiye & çakışma validasyonları |
| Başka Çalışanın Taleplerini İnceleme | ❌ | ✅ | `require_manager` filtresi |
| İzin Onaylama / Reddetme | ❌ | ✅ | Sunucu taraflı rol doğrulaması |
| Kendi Talebini Onaylama | ❌ (Engelli) | ❌ (Engelli) | `manager != user` iş kuralı |
| Aylık Ekip Takvimini Görüntüleme | ❌ | ✅ | `Manager::CalendarsController` |

---

## 5. İzin Talebi ve Tarih Hesaplama Kuralları

- **Geçerli Tarih Aralığı:** Başlangıç tarihi bitiş tarihinden sonra olamaz (`start_date <= end_date`). Geçmişe dönük mantıksız tarihler engellenir.
- **Hafta Sonu Kuralı:** İzin süresi hesaplanırken Cumartesi ve Pazar günleri **kesinlikle hesaba katılmaz**.
  - *Açıklama:* Cuma gününden başlayıp Pazartesi akşamı sona eren bir izin 4 takvim günü sürmesine rağmen çalışanın izin bakiyesinden yalnızca **2 iş günü** (`Cuma` ve `Pazartesi`) düşülür.
  - *Kod Referansı:* `app/models/leave_request.rb` içerisindeki `working_days_count` metodu.
- **Bilinen Eksik (Resmî Tatiller):** 1. sürümde resmî ve bayram tatilleri hesaplama motoruna dahil edilmemiştir; resmî tatil günleri hafta içi günlere denk geldiğinde iş günü olarak değerlendirilmektedir. Bu durum Faz 2 yol haritasına API entegrasyonu olarak planlanmıştır.
- **Kişisel Çakışma Engeli:** Bir çalışanın mevcut bekleyen veya onaylanmış bir izni varken, aynı tarihler için ikinci bir izin talebi açması sunucu tarafında engellenir.

---

## 6. Durum Akışı ve Geçiş Kuralları

İzin talepleri 3 temel durumda yönetilir:
- `pending` (Beklemede)
- `approved` (Onaylandı)
- `rejected` (Reddedildi)

```
       [ Yeni Talep ]
              │
              ▼
         ┌─────────┐
         │ Pending │
         └────┬────┘
              │
     ┌────────┴────────┐
     ▼                 ▼
┌──────────┐     ┌──────────┐
│ Approved │     │ Rejected │
└──────────┘     └──────────┘
```

- **İzin Verilen Geçişler:** Yalnızca `pending -> approved` ve `pending -> rejected`.
- **Kararın Değiştirilemezliği:** Onaylanmış veya reddedilmiş bir talep doğrudan başka bir duruma geçirilemez. Tekrar işlem yapılmaya çalışıldığında `InvalidStateTransitionError` fırlatılır.
- **Karar Kayıtları:** Her onay ve ret işleminde kararı veren yönetici (`manager_id`), karar zamanı (`decided_at`) ve ret gerekçesi (`manager_comment`) veritabanına kalıcı olarak işlenir.

---

## 7. Zaman Kuralı — 48 Saatlik Onay SLA'sı

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

## 8. İzin Bakiyesi ve Çift Düşüm Koruması (İdempotency)

- **Bekleyen Talep:** Talep oluşturulduğunda bakiye düşülmez (`pending` aşamasında bakiye korunur).
- **Onaylanan Talep:** Talep yönetici tarafından onaylandığı anda `deduct_balance!` çağrılır ve ilgili bakiye (`annual_leave_balance` veya `sick_leave_balance`) eksiltilir.
- **Çift Düşüm Koruması:** `approve!` metodu veritabanı transaction bloğu ve `lock!` mekanizmasıyla korunur. Talep zaten `approved` durumundaysa işlem durdurulur ve bakiye ikinci kez düşülmez.
- **Reddedilen Talep:** Ret durumunda bakiye üzerinde hiçbir eksiltme yapılmaz.

---

## 9. Teknoloji Yığını ve Mimari Seçimler

- **Framework:** Ruby on Rails 8.1.4 (Modern Hotwire mimarisi, Propshaft asset pipeline)
- **Dil:** Ruby 3.3.12 (x64-mingw-ucrt)
- **Veritabanı Mimarisi:**
  - *Üretim (Render) & CI:* PostgreSQL 16
  - *Yerel Geliştirme (Windows):* SQLite3 (Kolay kurulum, sıfır konfigürasyon, hibrit `database.yml` mimarisi)
- **Kimlik Doğrulama:** `has_secure_password` ve BCrypt 3.1.22 (Harici ağır gem bağımlılıkları olmadan hafif, güvenli ve şeffaf oturum yönetimi)
- **Frontend & Tasarım:** Responsive Vanilla CSS, modern SVG ikonlar, LeaveFlow zümrüt yeşili/slate kurumsal renk paleti
- **Test Kütüphaneleri:** Minitest, Rails System/Integration testleri, ActiveSupport TimeHelpers

---

## 10. Veritabanı Şeması

```sql
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    email VARCHAR UNIQUE NOT NULL,
    password_digest VARCHAR NOT NULL,
    first_name VARCHAR NOT NULL,
    last_name VARCHAR NOT NULL,
    role VARCHAR DEFAULT 'employee' NOT NULL,
    department VARCHAR NOT NULL,
    annual_leave_balance INTEGER DEFAULT 15 NOT NULL,
    sick_leave_balance INTEGER DEFAULT 10 NOT NULL,
    created_at TIMESTAMP NOT NULL,
    updated_at TIMESTAMP NOT NULL
);

CREATE TABLE leave_requests (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    leave_type VARCHAR NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    days_count INTEGER NOT NULL,
    status VARCHAR DEFAULT 'pending' NOT NULL,
    reason TEXT NOT NULL,
    manager_id INTEGER REFERENCES users(id),
    manager_comment TEXT,
    decided_at TIMESTAMP,
    created_at TIMESTAMP NOT NULL,
    updated_at TIMESTAMP NOT NULL
);
```

---

## 11. Kurulum ve Çalıştırma Rehberi

### Windows Ortamı İçin Adımlar
1. **Terminali UTF-8 Moduna Alın:**
   ```cmd
   chcp 65001
   ```
2. **Ruby Ortamını Etkinleştirin:**
   ```cmd
   call C:\Ruby33-x64\bin\setrbvars.cmd
   ridk enable
   ```
3. **Bağımlılıkları Yükleyin:**
   ```cmd
   bundle install
   ```
4. **Veritabanını Hazırlayın ve Tohum Verileri Ekleyin:**
   ```cmd
   ruby bin/rails db:migrate
   ruby bin/rails db:seed
   ```
5. **Sunucuyu Başlatın:**
   ```cmd
   ruby bin/rails server
   ```
6. Tarayıcınızda açın: `http://localhost:3000`

### Linux / macOS Ortamı İçin Adımlar
```bash
bundle install
bin/rails db:migrate
bin/rails db:seed
bin/rails server
```

---

## 12. Hazır Demo Hesapları

Uygulama giriş sayfasında (`/login`), tek tıkla form dolduran demo butonları yer almaktadır:

| Kullanıcı Rolü | E-Posta Adresi | Şifre | Departman | Başlangıç Durumu |
| :--- | :--- | :--- | :--- | :--- |
| **Yönetici** | `ayse.yonetici@leaveflow.com` | `password123` | Yönetim | Tüm talepleri onaylama yetkisine sahip |
| **Çalışan (1)** | `ahmet@leaveflow.com` | `password123` | Satış | Onaylanmış izni var (Çakışma testleri için) |
| **Çalışan (2)** | `mehmet@leaveflow.com` | `password123` | Mühendislik | 50 saatlik bekleyen talebi var (SLA gecikme testi için) |
| **Çalışan (3)** | `zeynep@leaveflow.com` | `password123` | Satış | Yeni talep oluşturma ve çakışma uyarısı testi için |

---

## 13. Otomatik Testler ve Doğrulama

Tüm iş akışları, model kısıtları, bakiye düşümleri, 48 saatlik SLA senaryoları ve entegrasyon akışları test edilmiştir.

### Testleri Çalıştırma Komutu
```cmd
ruby bin/rails test
```

### Gerçek Test Çıktısı
```text
Run options: --seed 55789

# Running:

.....................................

Finished in 4.774395s, 7.7497 runs/s, 28.2758 assertions/s.
37 runs, 135 assertions, 0 failures, 0 errors, 0 skips
```

**Test Kapsamı:**
- `test/models/user_test.rb`: Kullanıcı doğrulama, roller, bakiye düşüm mantığı.
- `test/models/leave_request_test.rb`: Hafta sonu hariç iş günü hesabı, tarih aralığı doğrulaması, çakışan izin engeli.
- `test/models/state_transition_test.rb`: `pending -> approved`, `pending -> rejected`, geçersiz durum sıçramaları, yetkisiz onay engeli.
- `test/models/sla_time_test.rb`: `travel_to` ile 5 farklı zaman senaryosunun (0h, 47h, 48h tam sınır, 49h onaylanmış, 49h reddedilmiş) deterministik testi.
- `test/models/leave_balance_test.rb`: Bakiye eksiltme, reddedilen talepte sıfır düşüm, aynı talepte çift düşüm koruması.
- `test/models/team_conflict_test.rb`: Akıllı izin planlama çakışma uyarı motoru testleri.
- `test/integration/leave_request_flow_test.rb`: Uçtan uca talep oluşturma, yönetici onay akışı, güvenlik duvarı kontrolleri.

---

## 14. CI/CD Pipeline (GitHub Actions)

Projenin kök dizininde `.github/workflows/ci.yml` dosyası yapılandırılmıştır:
- GitHub'a her `push` ve `pull_request` yapıldığında tetiklenir.
- Ubuntu ortamında PostgreSQL 16 servis konteyneri ayağa kaldırır.
- Ruby 3.3 ortamını kurar ve bağımlılıkları önbellekler.
- `bin/rails db:migrate` ve `bin/rails test` komutlarını çalıştırarak testlerin yeşil olduğunu teyit eder.

---

## 15. Canlı Dağıtım (Render) ve Dağıtım Adımları

Uygulama, Render platformu için üretime hazır hale getirilmiştir:
- `render.yaml`: Web servisi ve PostgreSQL veritabanını tek tıkla ayağa kaldıran Blueprint dosyası.
- `bin/render-build.sh`: Derleme esnasında asset precompilation ve migration işlemlerini otomatikleştiren betik.

### Canlı Dağıtım Adımları
1. Kodları GitHub deponuza gönderin:
   ```cmd
   git add .
   git commit -m "LeaveFlow v1.0.0 tam sürüm"
   git remote add origin https://github.com/<kullanici-adiniz>/LeaveFlow.git
   git push -u origin main
   ```
2. [Render Dashboard](https://dashboard.render.com)'a giriş yapın.
3. **New +** -> **Blueprint** seçeneğine tıklayın.
4. GitHub LeaveFlow deponuzu seçin.
5. Render, `render.yaml` dosyasını otomatik algılayıp PostgreSQL ve Web Servisini kuracaktır.
6. Dağıtım tamamlandığında canlı URL'iniz aktif olacaktır (örneğin: `https://leaveflow.onrender.com`).

---

## 16. Faz 2: Ticari Geliştirme Maliyet ve Efor Tahmini

Kurumsal bir yazılım ajansı veya danışmanlık firması perspektifinden, LeaveFlow Faz 2 geliştirmesi (Enterprise Sürüm) için yapılan efor ve maliyet projeksiyonu aşağıdadır:

### Faz 2 Kapsamı
- Resmî tatiller takvimi API entegrasyonu (Ulusal bayramlar ve bölgesel tatiller).
- Slack, Microsoft Teams ve E-posta bildirim webhook'ları.
- Yarım gün ve saatlik mazeret izni yönetimi.
- Çoklu onay kademeleri (Takım Lideri -> Departman Müdürü -> İK Direktörü).
- PDF İzin Formu dışa aktarma ve ıslak/dijital imza entegrasyonu.

### Kurumsal Efor ve Maliyet Tablosu (Faz 2)
| Rol / Pozisyon | Efor (Adam/Gün) | Günlük Adam Maliyeti ($) | Toplam Maliyet ($) |
| :--- | :---: | :---: | :---: |
| Kıdemli Ruby on Rails Mimarı | 10 | $600 | $6,000 |
| Full-Stack Geliştirici | 15 | $400 | $6,000 |
| UI/UX Tasarımcısı | 5 | $350 | $1,750 |
| QA Test Otomasyon Mühendisi | 6 | $350 | $2,100 |
| Proje Yöneticisi / Scrum Master | 4 | $450 | $1,800 |
| **Toplam Faz 2 Proje Tahmini** | **40 Adam/Gün** | - | **$17,650 (~600.000 TL)** |

*Akademik Ödev Notu: Bu ödev projesinde harcanan bireysel geliştirme eforu yaklaşık 36 net çalışma saati olup yukarıdaki ticari projeksiyondan bağımsızdır.*

---

## 17. 5 Dakikalık Sözlü Sunum Senaryosu (Jüri / Eğitmen İçin)

| Süre | Sunum Bölümü | Anlatılacak Konu ve Ekran | Kod Satır Referansı |
| :---: | :--- | :--- | :--- |
| **00:00 - 00:45** | **Giriş & Pazar Araştırması** | "Merhaba hocam. Projem LeaveFlow. Workday'in Fortune 500'deki pazar hakimiyetini ve G2'deki kullanıcı şikayetlerini araştırarak başladım. G2'de çalışanların en büyük şikayeti: 'İzin alırken ekip arkadaşlarımızın izinli olduğunu göremiyoruz ve taleplerimiz sonradan çakışma yüzünden reddediliyor.'" | `README.md` Bölüm 2 ve 3 |
| **00:45 - 01:45** | **100 Puanlık Özellik: Akıllı Çakışma Uyarısı** | Zeynep kullanıcısıyla giriş yapılır (`zeynep@leaveflow.com`). Yeni talep formunda Ahmet'in izinli olduğu tarihler seçilir. Form üzerinde sarı/turuncu uyarı kutusu belirir: *"Satış ekibinden Ahmet Yılmaz bu tarihlerde izinli!"* | `app/models/leave_request.rb` (`team_conflicts_for`), `leave_requests/new.html.erb` |
| **01:45 - 02:45** | **Yönetici Paneli & 48 Saatlik Onay SLA'sı** | Ayşe Yönetici hesabına geçilir. Bekleyen taleplerde Mehmet'in 50 saattir bekleyen talebi kırmızı **"Gecikmiş (Overdue)"** rozetiyle gösterilir. Yönetici onaylar; bakiye anında düşer. Takvim sekmesinde onaylı izinler görüntülenir. | `app/models/leave_request.rb` (`overdue?`, `SLA_LIMIT = 48.hours`), `manager/calendars/show.html.erb` |
| **02:45 - 03:45** | **İş Kuralları ve Güvenlik Mimarisi** | Sunucu taraflı kontroller: Hafta sonları izinden sayılmaz (Cuma-Pzt = 2 iş günü). Çalışan kendi talebini onaylayamaz. İdempotency: Aynı talep iki kez onaylanıp bakiye çift düşülemez. | `app/models/leave_request.rb` (`working_days_count`, `approve!`), `user.rb` (`deduct_balance!`) |
| **03:45 - 04:30** | **Test Otomasyonu & travel_to** | Terminalde `ruby bin/rails test` çalıştırılır. "Hocam, 48 saatlik SLA kuralını ve bakiye düşümlerini Rails'in `travel_to` kütüphanesiyle simüle ettik. 37 testin tamamı yeşildir." | `test/models/sla_time_test.rb`, `leave_balance_test.rb` |
| **04:30 - 05:00** | **Kapanış & Canlı Deployment** | Render üzerindeki canlı URL ve GitHub Actions CI pipeline'ı gösterilerek soru-cevap aşamasına geçilir. | `.github/workflows/ci.yml`, `render.yaml` |

---

## 18. Bilinen Eksikler ve Gelecek Geliştirmeler

1. **Resmî Tatil Entegrasyonu:** Mevcut sürümde hafta sonları tatil sayılırken resmî tatiller (29 Ekim, 1 Mayıs vb.) düşülmemektedir. Bir sonraki sürümde ulusal takvim API'si entegre edilecektir.
2. **E-posta / Push Bildirimleri:** SLA süresine 6 saat kala yöneticilere e-posta hatırlatması gönderilmesi.
3. **Yarım Gün İzin Desteği:** 0.5 günlük öğleden önce/sonra izin türü desteği.

---

## 19. Lisans ve Katkıda Bulunma

Bu proje MIT Lisansı altında açık kaynak olarak geliştirilmiştir.
Telif Hakkı (c) 2026 LeaveFlow.

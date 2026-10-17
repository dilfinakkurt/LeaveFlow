# AGENT.md — LeaveFlow Sistem ve Mimari Rehberi

> Bu belge, LeaveFlow projesinin teknik mimarisini, yapay zeka ajanının (Senior Rails Architect) öğrenci geliştirici ile birlikte aldığı teknik kararları (ADR), iş kurallarını, test stratejisini ve operasyonel yönergelerini içeren teknik referans dokümanıdır.

---

## 1. Ajan Kimliği ve Çift Programlama (Pair Programming) Rolü

- **Ajan Rolü:** Kıdemli Ruby on Rails Yazılım Mimarı ve Teknik Rehber (Senior Architect & Pair Programmer).
- **Geliştirici:** Yazılım Mühendisliği 3. Sınıf Öğrencisi.
- **Çalışma Prensibi:**
  - Sadece kod üretmek değil; Windows geliştirme ortamındaki hataları teşhis etmek, Türkçe ve pedagojik açıklamalar sunmak.
  - "Aort Dilimi" prensibine sadık kalarak gereksiz özellik eklememek, çalışan ve test edilmiş ürünü zamanında teslim etmek.
  - Test çıktısı görmeden hiçbir özelliğe "çalışıyor" dememek.

---

## 2. Proje Özeti ve Hedefler

- **Ürün Adı:** LeaveFlow
- **Proje Türü:** B2B SaaS Çalışan İzin ve Yönetici Onay Sistemi
- **İlham Kaynağı:** Workday Core HCM Zaman ve İzin Modülü (özgün LeaveFlow marka kimliği ve sıfırdan geliştirilmiş Rails mimarisi).
- **Teknoloji Yığını:**
  - **Framework:** Ruby on Rails 8.1.4 (Ruby 3.3.12 x64-mingw-ucrt)
  - **Veritabanı:** PostgreSQL 16 (Render Canlı Ortamı & GitHub Actions CI) / SQLite3 (Yerel Windows geliştirme ortamı için hibrit adaptör)
  - **Frontend:** HTML5, Modern Vanilla CSS3, Hotwire (Turbo & Stimulus), Vanilla JavaScript Fetch API
  - **Kimlik Doğrulama:** `has_secure_password` (BCrypt 3.1.22), Sunucu Taraflı Rol Bazlı Yetkilendirme (RBAC)
  - **Test Otomasyonu:** Rails Minitest, ActiveSupport::Testing::TimeHelpers (`travel_to`)
  - **CI/CD:** GitHub Actions (PostgreSQL servis konteyneri ile)
  - **Deployment:** Render (Puma, Managed PostgreSQL)

---

## 3. Mimari Karar Günlüğü (Architectural Decision Records - ADR)

### ADR-01: Kimlik Doğrulama İçin Devise Yerine `has_secure_password` Seçimi
- **Gerekçe:** Devise gem'i Rails 8 ile bazen sürüm uyumsuzlukları çıkarabilen ağır bir DSL içerir. Rails'in yerleşik `has_secure_password` (BCrypt) altyapısı, hem eğitim amacıyla oturum akışını (session lifecycle) şeffaf şekilde öğrenmeyi sağlar hem de harici bağımlılıkları minimize eder.

### ADR-02: Yerelde Hibrit SQLite / Üretimde PostgreSQL Mimarisi
- **Gerekçe:** Windows işletim sisteminde yerel PostgreSQL servislerinin kurulumu, port çakışmaları ve kullanıcı şifre yapılandırmaları öğrenci ortamında ciddi zaman kaybettirir. `config/database.yml` dosyasında `DATABASE_URL` varsa PostgreSQL, yoksa SQLite3 kullanacak hibrit mimari kurulmuştur. Render ve GitHub Actions ortamında PostgreSQL 16 sorunsuz çalışır.

### ADR-03: Sunucu Tarafı Güvenlik ve RBAC (Never Trust the Client)
- **Gerekçe:** Bir çalışanın yöneticinin onay butonuna erişememesi sadece HTML'de butonu gizlemekle sağlanamaz. Controller katmanında `require_manager` ve `current_user.leave_requests` kapsamları; Model katmanında ise `manager != user` doğrulamasıyla güvenlik sunucu tarafında kilitlenmiştir.

### ADR-04: Geliştirme Sunucusu Olarak WEBrick Uyarlaması
- **Gerekçe:** Windows ortamında Puma gem'inin C derleme kütüphanelerine takılmasını önlemek için yerel geliştirmede WEBrick varsayılan yapılmış; üretim (Render) ortamı için ise `render.yaml` üzerinde Puma yapılandırılmıştır.

---

## 4. Etki Alanı Modeli ve Veritabanı Şeması

```
+------------------------------------+          +------------------------------------+
|               User                 |          |            LeaveRequest            |
+------------------------------------+          +------------------------------------+
| id: integer                        | 1      * | id: integer                        |
| email: string (unique, indexed)    |<-------->| user_id: integer (foreign key)     |
| password_digest: string            |          | leave_type: string                 |
| first_name: string                 |          | start_date: date                   |
| last_name: string                  |          | end_date: date                     |
| role: string (employee / manager)  |          | days_count: integer                |
| department: string                 |          | status: string (pending/app./rej.) |
| annual_leave_balance: integer      |          | reason: text                       |
| sick_leave_balance: integer        |          | manager_id: integer (nullable FK)  |
| created_at, updated_at             |          | manager_comment: text              |
+------------------------------------+          | decided_at: datetime               |
                                                | created_at, updated_at             |
                                                +------------------------------------+
```

### Rol ve Yetki Matrisi
| İşlem / Kaynak | Çalışan (Employee) | Yönetici (Manager) | Sunucu Güvencesi |
| :--- | :---: | :---: | :--- |
| Giriş / Çıkış | Evet | Evet | `SessionsController` |
| Kendi İzin Taleplerini Listeleme | Evet | Evet | `current_user.leave_requests` kapsamı |
| Yeni İzin Talebi Oluşturma | Evet | Evet | Kendi bakiyesi ve çakışma kontrolleri |
| Başka Çalışanın Talebini Görme | **Hayır** | Evet | Yalnızca `manager` rolüne açık |
| İzin Talebini Onaylama / Reddetme | **Hayır** | Evet | `require_manager` + kendi talebini onaylayamama kuralı |
| Kendi Talebini Onaylama | **Engelli** | **Engelli** | Model seviyesinde `manager != user` doğrulaması |
| Departman Takvimi Görüntüleme | Hayır | Evet | `Manager::CalendarsController` |

---

## 5. Temel İş Kuralları ve Uygulama Detayları

### 5.1. İş Günü ve Hafta Sonu Hesabı (`working_days_count`)
- İzin günleri hesaplanırken Cumartesi (`wday == 6`) ve Pazar (`wday == 0`) günleri hesaba katılmaz.
- Cuma başlangıç, Pazartesi bitiş olan bir talep 4 takvim günü sürmesine rağmen 2 iş günü (`Cuma` + `Pazartesi`) izin tüketir.
- Form doldurulurken arayüzde JavaScript tarafından anlık olarak, sunucu tarafında ise `before_validation :calculate_days_count` ile hesaplanır.

### 5.2. Bakiye Düşümü ve Çift Düşüm Koruması (İdempotency)
- İzin talebi oluşturulduğunda (`pending`), kullanıcının bakiyesinden gün düşülmez.
- Talep yönetici tarafından **onaylandığında** (`approve!`), ilgili izin türünün bakiyesinden (`annual_leave_balance` veya `sick_leave_balance`) gün düşülür.
- `transaction` bloğu içerisinde `lock!` uygulanır. Talep zaten `approved` ise tekrar düşüm yapılmaz (`raise InvalidStateTransitionError`).
- Reddedilen taleplerde hiçbir bakiye düşümü yapılmaz.

### 5.3. 48 Saatlik Onay SLA Kuralı (`SLA_LIMIT = 48.hours`)
- Bekleyen (`pending`) bir talep, oluşturulma zamanından (`created_at`) itibaren 48 saat geçmişse sunucu tarafında **Gecikmiş (Overdue)** olarak değerlendirilir.
- Tanım: `def overdue?; pending? && created_at <= SLA_LIMIT.ago; end`
- Onaylanan veya reddedilen talepler, 48 saat geçse bile asla gecikmiş sayılmaz (`pending?` false olduğu için).
- Yönetici paneli ve gösterge panellerinde gecikmiş talepler kırmızı uyarı rozetleriyle önceliklendirilir.

### 5.4. 100 Puanlık Özellik: Akıllı İzin Planlama Uyarısı (Smart Team Conflict Detection)
- **Doğrulanan Kullanıcı Acısı:** G2 Workday kullanıcı yorumlarında belirtilen *"İzin alırken aynı ekibin izin takvimini görememe ve çakışmalar yüzünden onay süreçlerinin tıkanması"* problemi.
- **LeaveFlow Çözümü:**
  - Çalışan talep oluştururken başlangıç-bitiş tarihleri seçildiği anda arka planda `/leave_requests/check_conflicts` uç noktasına istek atılır.
  - Aynı departmandaki diğer çalışanların o tarihlerdeki onaylanmış izinleri sorgulanır.
  - Eğer çakışma varsa arayüzde turuncu bilgilendirme kutusu açılır: *"Dikkat: Bu tarihler arasında Satış ekibinden Ahmet Demir izinli olacaktır."*
  - Talep engellenmez (özgürce gönderilebilir); ancak hem çalışan uyarılır hem de yönetici onay panelinde bu çakışma yöneticinin dikkatine sunulur.

---

## 6. Geliştirme Sürecinde Karşılaşılan Sorunlar ve Çözüm Günlüğü (Debugging Log)

1. **Windows Türkçe Karakter Dizin Hatası (`Masaüstü`):**
   - *Sorun:* Windows terminali varsayılan olarak CP1254 veya OEM kod sayfasıyla açıldığından, `Masaüstü` yolundaki `ü` karakteri Ruby require işlemlerinde soru işaretine dönüşerek dosya bulma hataları üretti.
   - *Çözüm:* Terminal açılışında `chcp 65001` (UTF-8) zorunlu hale getirildi.

2. **Rails 8 `travel_to` İç İçe Blok Hatası:**
   - *Sorun:* `freeze_time` bloğu içinde `travel` çağrıldığında Rails 8 ActiveSupport `nested travel_to` hatası fırlattı.
   - *Çözüm:* `test/models/sla_time_test.rb` dosyasında iç içe bloklar kaldırıldı; her zaman adımı için bağımsız, sıralı `travel_to(@base_time + X.hours)` blokları kurgulandı.

3. **Geliştirme Veritabanı Tohumlama (Seed):**
   - *Sorun:* Test ortamı otomatik tohumlanırken geliştirme veritabanı boş kaldığı için kullanıcı girişi yapılamadı.
   - *Çözüm:* Güvenli `db/seeds.rb` betiği (`find_or_initialize_by`) geliştirme ortamında çalıştırılarak demo hesaplar üretildi.

---

## 7. Dosya ve Dizin Yapısı

```
LeaveFlow/
├── app/
│   ├── assets/stylesheets/application.css      # Özgün responsive UI stilleri
│   ├── controllers/
│   │   ├── application_controller.rb          # Auth & RBAC filtreleri
│   │   ├── dashboards_controller.rb           # Rol bazlı gösterge paneli
│   │   ├── leave_requests_controller.rb       # Çalışan izin akışları & API
│   │   ├── manager/
│   │   │   ├── base_controller.rb             # Yönetici yetki filtresi
│   │   │   ├── calendars_controller.rb        # Departman takvimi
│   │   │   └── leave_requests_controller.rb   # Onay/Ret kuyruğu
│   │   └── sessions_controller.rb             # Login/Logout & Hızlı Demo
│   ├── models/
│   │   ├── user.rb                            # Kullanıcı, roller ve bakiye
│   │   └── leave_request.rb                   # İzin modeli, SLA, çakışma analizi
│   └── views/
│       ├── dashboards/                        # İstatistik kartları & SLA uyarıları
│       ├── layouts/application.html.erb       # Global layout & bildirimler
│       ├── leave_requests/                    # Yeni talep, liste, detay
│       ├── manager/calendars/                 # Aylık ekip takvim görünümü
│       ├── manager/leave_requests/            # Yönetici inceleme ve filtreler
│       └── sessions/new.html.erb              # Giriş kartı ve tek tık demo
├── config/
│   ├── database.yml                           # SQLite (yerel) / PostgreSQL (prod)
│   ├── routes.rb                              # RESTful rotalar & manager namespace
│   └── environments/production.rb             # Render üretim ortamı yapılandırması
├── db/
│   ├── migrate/20261017000001_create_users_and_leave_requests.rb
│   └── seeds.rb                               # Güvenli demo hesapları
├── test/
│   ├── integration/leave_request_flow_test.rb # Uçtan uca onay ve güvenlik testleri
│   ├── models/
│   │   ├── leave_balance_test.rb              # Bakiye ve çift düşüm testleri
│   │   ├── leave_request_test.rb              # Validasyon & hafta sonu testleri
│   │   ├── sla_time_test.rb                   # travel_to ile 48 saat SLA testleri
│   │   ├── state_transition_test.rb           # Durum makinesi testleri
│   │   ├── team_conflict_test.rb              # Akıllı çakışma uyarı testleri
│   │   └── user_test.rb                       # Rol ve kullanıcı testleri
│   └── test_helper.rb
├── .github/workflows/ci.yml                   # GitHub Actions PostgreSQL CI
├── bin/render-build.sh                        # Render derleme ve migration betiği
├── render.yaml                                # Render Blueprint altyapı tanımı
├── README.md                                  # Kapsamlı proje dokümantasyonu
└── AGENT.md                                   # Ajan sistem ve mimari dokümantasyonu
```

---

## 8. Komut Referansı

### Yerel Ortamda Çalıştırma (Windows PowerShell)
```powershell
$env:PATH = "C:\Ruby33-x64\bin;C:\Ruby33-x64\bin\ruby_builtin_dlls;$env:PATH"
ruby bin/rails server -u webrick
# Tarayıcıda: http://localhost:3000
```

### Testleri Çalıştırma
```powershell
$env:PATH = "C:\Ruby33-x64\bin;C:\Ruby33-x64\bin\ruby_builtin_dlls;$env:PATH"
ruby bin/rails test
```

---

## 9. Gelecek Geliştiriciler / Ajanlar İçin Notlar
- İzin hesaplamalarında değişiklik yapılacaksa `app/models/leave_request.rb` içindeki `working_days_count` güncellenmelidir.
- SLA sınırını değiştirmek için `LeaveRequest::SLA_LIMIT` sabiti tek bir yerden yönetilmektedir.
- Tüm zaman simülasyonu testlerinde `travel_to` bloklarının sıralı açılmasına özen gösterilmelidir.

# AGENT.md — LeaveFlow Sistem ve Mimari Rehberi

Bu belge, LeaveFlow projesinin teknik mimarisini, etki alanı modelini, iş kurallarını, test stratejisini ve operasyonel yönergelerini içeren teknik referans dokümanıdır.

---

## 1. Proje Özeti ve Hedefler

- **Ürün Adı:** LeaveFlow
- **Proje Türü:** B2B SaaS İzin ve Onay Yönetim Sistemi
- **İlham Kaynağı:** Workday Core HCM İzin ve Yoklama Yönetim Modülleri (özgün marka kimliği, sıfırdan geliştirilmiş Rails mimarisi)
- **Teknoloji Yığını:**
  - **Framework:** Ruby on Rails 8.1.4 (Ruby 3.3.12)
  - **Veritabanı:** PostgreSQL 16 (Production & CI) / SQLite3 (Yerel Windows geliştirme ve hızlı testler için hibrit adaptör)
  - **Frontend:** HTML5, Modern Vanilla CSS3, Hotwire (Turbo & Stimulus), Vanilla JavaScript Fetch API
  - **Kimlik Doğrulama & Yetkilendirme:** `has_secure_password` (BCrypt 3.1.22), Sunucu Taraflı Rol Bazlı Yetkilendirme (RBAC)
  - **Test Otomasyonu:** Rails Minitest, ActiveSupport::Testing::TimeHelpers (`travel_to`)
  - **CI/CD:** GitHub Actions
  - **Deployment:** Render (Puma, managed PostgreSQL)

---

## 2. Etki Alanı Modeli ve Veritabanı Şeması

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

## 3. Temel İş Kuralları ve Uygulama Ayrıntıları

### 3.1. İş Günü ve Hafta Sonu Hesabı (`working_days_count`)
- İzin günleri hesaplanırken Cumartesi (`wday == 6`) ve Pazar (`wday == 0`) günleri hesaba katılmaz.
- Örnek: Cuma başlangıç, Pazartesi bitiş olan bir talep 4 takvim günü sürmesine rağmen 2 iş günü (`Cuma` + `Pazartesi`) izin tüketir.
- Form doldurulurken arayüzde JavaScript tarafından anlık olarak, sunucu tarafında ise `before_validation :calculate_days_count` ile hesaplanır.

### 3.2. Bakiye Düşümü ve Çift Düşüm Koruması (İdempotency)
- İzin talebi oluşturulduğunda (`pending`), kullanıcının bakiyesinden gün düşülmez.
- Talep yönetici tarafından **onaylandığında** (`approve!`), ilgili izin türünün bakiyesinden (`annual_leave_balance` veya `sick_leave_balance`) gün düşülür.
- `transaction` bloğu içerisinde `lock!` uygulanır. Talep zaten `approved` ise tekrar düşüm yapılmaz (`raise InvalidStateTransitionError`).
- Reddedilen taleplerde hiçbir bakiye düşümü yapılmaz.

### 3.3. 48 Saatlik Onay SLA Kuralı (`SLA_LIMIT = 48.hours`)
- Bekleyen (`pending`) bir talep, oluşturulma zamanından (`created_at`) itibaren 48 saat geçmişse sunucu tarafında **Gecikmiş (Overdue)** olarak değerlendirilir.
- Tanım: `def overdue?; pending? && created_at <= SLA_LIMIT.ago; end`
- Onaylanan veya reddedilen talepler, 48 saat geçse bile asla gecikmiş sayılmaz (`pending?` false olduğu için).
- Yönetici paneli ve gösterge panellerinde gecikmiş talepler kırmızı uyarı rozetleriyle önceliklendirilir.

### 3.4. 100 Puanlık Özellik: Akıllı İzin Planlama Uyarısı (Smart Team Conflict Detection)
- **Doğrulanan Kullanıcı Acısı:** G2 Workday kullanıcı yorumlarında belirtilen *"İzin alırken aynı ekibin izin takvimini görememe ve çakışmalar yüzünden onay süreçlerinin tıkanması"* problemi.
- **LeaveFlow Çözümü:**
  - Çalışan talep oluştururken başlangıç-bitiş tarihleri seçildiği anda arka planda `/leave_requests/check_conflicts` uç noktasına istek atılır.
  - Aynı departmandaki diğer çalışanların o tarihlerdeki onaylanmış izinleri sorgulanır.
  - Eğer çakışma varsa arayüzde turuncu bilgilendirme kutusu açılır: *"Dikkat: Bu tarihler arasında Satış ekibinden Ahmet Yılmaz izinli olacaktır."*
  - Talep engellenmez (özgürce gönderilebilir); ancak hem çalışan uyarılır hem de yönetici onay panelinde bu çakışma yöneticinin dikkatine sunulur.

---

## 4. Dosya ve Dizin Yapısı

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
└── README.md                                  # Kapsamlı proje dokümantasyonu
```

---

## 5. Komut Referansı

### Yerel Ortamda Çalıştırma (Windows)
```bash
# Bağımlılıkları yükleme
bundle install

# Veritabanını hazırlama ve demo verileri yükleme
ruby bin/rails db:migrate
ruby bin/rails db:seed

# Rails sunucusunu başlatma
ruby bin/rails server
# Tarayıcıda: http://localhost:3000
```

### Testleri Çalıştırma
```bash
# Tüm test paketini koşturma
ruby bin/rails test

# Belirli bir test dosyasını koşturma (örnek: SLA testleri)
ruby bin/rails test test/models/sla_time_test.rb
```

---

## 6. Güvenlik ve Mimari Prensipler
1. **Never Trust the Client:** İzin günü sayısı, bakiye yeterliliği ve onay yetkisi asla arayüzden gönderilen parametrelere bırakılmaz; sunucu tarafında model doğrulamaları ve ActiveRecord transaction blokları ile garantiye alınır.
2. **Deterministic Time Simulation:** Zaman testleri sistem saatine bağımlı kılınmamış, `ActiveSupport::Testing::TimeHelpers` (`travel_to`) ile tam deterministik olarak kurgulanmıştır.
3. **Graceful Degradation:** JavaScript devre dışı kalsa dahi Rails'in standart form submit akışı ve sunucu tarafı kontrolleri eksiksiz çalışır.

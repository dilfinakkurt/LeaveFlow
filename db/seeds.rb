# LeaveFlow Seed Data
# Güvenli seed: Her çalışan için ayrı izin senaryosu ve WorkEvent içerir.
# Demo hesaplar: ahmet@, mehmet@, zeynep@, ayse.yonetici@ / password123

puts "=== LeaveFlow Seed İşlemi Başlatılıyor ==="

# ================================================================
# 1. KULLANICILAR
# ================================================================

manager_ayse = User.find_or_initialize_by(email: "ayse.yonetici@leaveflow.com")
manager_ayse.assign_attributes(
  name: "Ayşe Yılmaz",
  password: "password123",
  password_confirmation: "password123",
  role: "manager",
  department: "Engineering",
  annual_leave_balance: 20,
  sick_leave_balance: 10
)
manager_ayse.save!
puts "Manager ready: #{manager_ayse.name}"

employee_ahmet = User.find_or_initialize_by(email: "ahmet@leaveflow.com")
employee_ahmet.assign_attributes(
  name: "Ahmet Demir",
  password: "password123",
  password_confirmation: "password123",
  role: "employee",
  department: "Engineering",
  manager: manager_ayse,
  annual_leave_balance: 12,
  sick_leave_balance: 10
)
employee_ahmet.save!
puts "Employee ready: #{employee_ahmet.name}"

employee_mehmet = User.find_or_initialize_by(email: "mehmet@leaveflow.com")
employee_mehmet.assign_attributes(
  name: "Mehmet Kaya",
  password: "password123",
  password_confirmation: "password123",
  role: "employee",
  department: "Engineering",
  manager: manager_ayse,
  annual_leave_balance: 15,
  sick_leave_balance: 10
)
employee_mehmet.save!
puts "Employee ready: #{employee_mehmet.name}"

employee_zeynep = User.find_or_initialize_by(email: "zeynep@leaveflow.com")
employee_zeynep.assign_attributes(
  name: "Zeynep Çelik",
  password: "password123",
  password_confirmation: "password123",
  role: "employee",
  department: "Sales",
  annual_leave_balance: 14,
  sick_leave_balance: 10
)
employee_zeynep.save!
puts "Employee ready: #{employee_zeynep.name}"

# ================================================================
# 2. IZIN TALEPLERI — Her çalışan için farklı senaryo
# ================================================================
LeaveRequest.where(user: [employee_ahmet, employee_mehmet, employee_zeynep]).destroy_all

today       = Date.current
next_monday = today.next_week(:monday)

# A. AHMET — Yaklaşan onaylı izin (gelecek hafta Pzt-Çrş)
#    AI Asistan: "Yaklaşan izin" banner'ı + 7 WorkEvent
ahmet_leave_start = next_monday
ahmet_leave_end   = next_monday + 2.days

ahmet_approved = LeaveRequest.create!(
  user: employee_ahmet,
  start_date: ahmet_leave_start,
  end_date: ahmet_leave_end,
  leave_type: "annual",
  reason: "Aile ziyareti ve dinlenme amaçlı yıllık izin.",
  status: "approved",
  decided_by: manager_ayse,
  decided_at: 2.days.ago,
  backup_user: employee_mehmet,
  handover_notes: "Ödeme API entegrasyonu ve güvenlik açığı uyarılarını vekaleten takip edebilir misin?"
)
puts "Approved leave ready (Ahmet, backup: Mehmet): #{ahmet_approved.start_date} - #{ahmet_approved.end_date}"

# B. MEHMET — Aktif izin (bugün dahil)
#    AI Asistan: "Şu anda izindesiniz!" banner'ı + 5 WorkEvent
mehmet_leave_start = today - 1.day
mehmet_leave_end   = today + 1.day

mehmet_approved = LeaveRequest.create!(
  user: employee_mehmet,
  start_date: mehmet_leave_start,
  end_date: mehmet_leave_end,
  leave_type: "annual",
  reason: "Kişisel dinlenme ve aile ziyareti.",
  status: "approved",
  decided_by: manager_ayse,
  decided_at: 3.days.ago
)
puts "Active approved leave ready (Mehmet): #{mehmet_approved.start_date} - #{mehmet_approved.end_date}"

# Mehmet'in SLA geçkini bekleyen izin talebi (yönetici paneli testi için)
LeaveRequest.create!(
  user: employee_mehmet,
  start_date: next_monday + 14.days,
  end_date: next_monday + 16.days,
  leave_type: "annual",
  reason: "Konferans katılımı ve kişisel gelişim izni.",
  status: "pending",
  created_at: 50.hours.ago
)
puts "Overdue SLA pending leave ready (Mehmet)"

# C. ZEYNEP — Son 30 gün içinde biten izin (işe dönüş senaryosu)
#    AI Asistan: "Hoş geldiniz, işe dönüş" banner'ı + 6 WorkEvent
zeynep_leave_start = today - 5.days
zeynep_leave_end   = today - 1.day

zeynep_approved = LeaveRequest.create!(
  user: employee_zeynep,
  start_date: zeynep_leave_start,
  end_date: zeynep_leave_end,
  leave_type: "annual",
  reason: "Yaz tatili başlangıcı.",
  status: "approved",
  decided_by: manager_ayse,
  decided_at: 7.days.ago
)
puts "Past approved leave ready (Zeynep - return scenario): #{zeynep_approved.start_date} - #{zeynep_approved.end_date}"

# Zeynep'in bekleyen yeni talebi
LeaveRequest.create!(
  user: employee_zeynep,
  start_date: next_monday + 21.days,
  end_date: next_monday + 23.days,
  leave_type: "annual",
  reason: "Sonbahar tatili planlaması.",
  status: "pending",
  created_at: 4.hours.ago
)
puts "Pending leave ready (Zeynep)"

# ================================================================
# 3. AI LEAVE ASSISTANT DEMO DATA — Her çalışana özel WorkEvent'ler
# ================================================================
puts "\n=== AI Leave Assistant Demo Data ==="

WorkEvent.where(is_demo: true).destroy_all
Notification.destroy_all
LeaveReturnSummary.destroy_all
AiChatMessage.destroy_all

# ---------------------------------------------------------------
# AHMET — 7 WorkEvent (izin dönemi: ahmet_leave_start..ahmet_leave_end)
# ---------------------------------------------------------------
puts "  Creating Ahmet's work events..."

WorkEvent.create!(
  user: employee_ahmet, department: "Engineering",
  event_type: "task_assigned",
  title: "API Entegrasyon Görevi Atandı",
  description: "Ödeme sistemi API entegrasyonu için yeni bir görev atandı. Sprint planlama toplantısında karar verildi. Teslim tarihi: #{(ahmet_leave_end + 5.days).strftime('%d.%m.%Y')}.",
  occurred_at: ahmet_leave_start + 4.hours, source_record: "Jira #LF-302",
  severity: "important", is_demo: true
)

WorkEvent.create!(
  user: employee_ahmet, department: "Engineering",
  event_type: "pending_action",
  title: "Güvenlik Açığı: Bağımlılık Güncellemesi Gerekli",
  description: "Dependabot, kritik bir güvenlik açığı tespit etti (CVE-2026-4521). bcrypt gem'inin 3.1.23 sürümüne güncellenmesi acil olarak gerekiyor. Ahmet'in sorumluluğunda.",
  occurred_at: ahmet_leave_start + 2.days, source_record: "GitHub Security Alert",
  severity: "urgent", is_demo: true
)

WorkEvent.create!(
  user: employee_ahmet, department: "Engineering",
  event_type: "task_deadline_changed",
  title: "Frontend Redesign Teslim Tarihi Güncellendi",
  description: "Müşteri geri bildirimi nedeniyle Frontend Redesign projesinin teslim tarihi #{(ahmet_leave_end + 3.days).strftime('%d.%m.%Y')} tarihinden #{(ahmet_leave_end + 10.days).strftime('%d.%m.%Y')} tarihine ertelendi.",
  occurred_at: ahmet_leave_start + 1.day + 2.hours, source_record: "Sprint Planı",
  severity: "important", is_demo: true
)

WorkEvent.create!(
  user: employee_ahmet, department: "Engineering",
  event_type: "task_status_changed",
  title: "Veritabanı Migration PR'ı Birleştirildi",
  description: "Ahmet'in izinden önce oluşturduğu veritabanı migration pull request'i incelendi ve ana dala birleştirildi. Staging ortamına deploy edildi.",
  occurred_at: ahmet_leave_start + 6.hours, source_record: "GitHub PR #187",
  severity: "normal", is_demo: true
)

WorkEvent.create!(
  user: nil, department: "Engineering",
  event_type: "project_update",
  title: "v2.5 Sürüm Planı Açıklandı",
  description: "Engineering ekibi için v2.5 sürüm yol haritası yayınlandı. Yeni özellikler: Gerçek zamanlı bildirimler, Dashboard yeniden tasarımı, Performans iyileştirmeleri.",
  occurred_at: ahmet_leave_start + 1.day + 5.hours, source_record: "Confluence",
  severity: "normal", is_demo: true
)

WorkEvent.create!(
  user: nil, department: "Engineering",
  event_type: "meeting_rescheduled",
  title: "Haftalık Sprint Review Toplantısı Ertelendi",
  description: "Bu haftanın Sprint Review toplantısı Çarşamba'dan Perşembe 14:00'e ertelendi. Sebebi: Ürün yöneticisinin toplantı çakışması.",
  occurred_at: ahmet_leave_start + 1.day + 8.hours, source_record: "Google Calendar",
  severity: "normal", is_demo: true
)

WorkEvent.create!(
  user: employee_ahmet, department: "Engineering",
  event_type: "task_assigned",
  title: "Code Review: Authentication Modülü",
  description: "Mehmet'in hazırladığı Authentication modülü refactor PR'ının code review'ı Ahmet'e atandı. PR boyutu: +450 / -120 satır.",
  occurred_at: ahmet_leave_start + 2.days + 5.hours, source_record: "GitHub PR #192",
  severity: "normal", is_demo: true
)

puts "  Ahmet: #{WorkEvent.where(user: employee_ahmet, is_demo: true).count} personal + #{WorkEvent.where(user: nil, department: 'Engineering', is_demo: true).count} team events"

# ---------------------------------------------------------------
# MEHMET — 5 WorkEvent (izin dönemi: mehmet_leave_start..mehmet_leave_end)
# Mehmet şu an aktif izinde
# ---------------------------------------------------------------
puts "  Creating Mehmet's work events..."

WorkEvent.create!(
  user: employee_mehmet, department: "Engineering",
  event_type: "task_assigned",
  title: "Acil: Müşteri Dashboard Bug Fix",
  description: "Müşteri panelinde kritik bir görsel hata raporlandı. Tüm ürün görselleri yüklenmeyip boş görünüyor. Mehmet izinden döner dönmez öncelikli olarak ele alması bekleniyor.",
  occurred_at: mehmet_leave_start + 5.hours, source_record: "Jira #LF-318",
  severity: "urgent", is_demo: true
)

WorkEvent.create!(
  user: employee_mehmet, department: "Engineering",
  event_type: "task_deadline_changed",
  title: "Authentication Refactor Teslim Tarihi Öne Çekildi",
  description: "Q4 sprint planlaması nedeniyle Authentication Refactor PR'ının teslim tarihi 1 hafta öne çekildi. Yeni teslim: #{(today + 3.days).strftime('%d.%m.%Y')}.",
  occurred_at: mehmet_leave_start + 1.day, source_record: "Sprint Planı v3",
  severity: "important", is_demo: true
)

WorkEvent.create!(
  user: employee_mehmet, department: "Engineering",
  event_type: "task_status_changed",
  title: "CI/CD Pipeline Güncellendi",
  description: "GitHub Actions CI/CD pipeline konfigürasyonu güncellendi. Ruby 3.3.12 ve yeni test matrisi eklendi. Mehmet'in mevcut PR'ları otomatik yeniden tetiklenecek.",
  occurred_at: mehmet_leave_start + 3.hours, source_record: "GitHub Actions",
  severity: "normal", is_demo: true
)

WorkEvent.create!(
  user: nil, department: "Engineering",
  event_type: "team_announcement",
  title: "Engineering All-Hands: Yeni Teknik Yol Haritası",
  description: "CTO, tüm Engineering ekibini kapsayan yeni teknik yol haritasını paylaştı. Mikroservis mimarisine geçiş planı ve Q1 2027 hedefleri belirlendi. Sunum kaydı intranet'te mevcut.",
  occurred_at: mehmet_leave_start + 2.days, source_record: "Intranet - Tech Announcements",
  severity: "important", is_demo: true
)

WorkEvent.create!(
  user: employee_mehmet, department: "Engineering",
  event_type: "pending_action",
  title: "Bekleyen: 2FA Implementasyon Raporu",
  description: "İki faktörlü kimlik doğrulama modülü implementasyon raporu Mehmet'ten bekleniyor. Proje yöneticisi 3 kez hatırlatma yaptı. Acil teslim gerekiyor.",
  occurred_at: mehmet_leave_start + 1.day + 6.hours, source_record: "Project Management System",
  severity: "urgent", is_demo: true
)

puts "  Mehmet: #{WorkEvent.where(user: employee_mehmet, is_demo: true).count} personal events"

# ---------------------------------------------------------------
# ZEYNEP — 6 WorkEvent (izin dönemi: zeynep_leave_start..zeynep_leave_end)
# Sales departmanı, işe dönüş senaryosu
# ---------------------------------------------------------------
puts "  Creating Zeynep's work events..."

WorkEvent.create!(
  user: employee_zeynep, department: "Sales",
  event_type: "task_assigned",
  title: "Q4 Satış Hedefi Planlaması Atandı",
  description: "2026 Q4 satış hedefi planlaması ve müşteri portföy analizi görevi Zeynep'e atandı. Yöneticinin beklentisi: İlk hafta içinde taslak rapor sunulması.",
  occurred_at: zeynep_leave_start + 3.hours, source_record: "Salesforce Task #SF-441",
  severity: "important", is_demo: true
)

WorkEvent.create!(
  user: employee_zeynep, department: "Sales",
  event_type: "pending_action",
  title: "Acil: Enterprise Müşteri Teklifi Yanıtı",
  description: "TechCorp Enterprise hesabından gelen 250.000 TL'lik teklif yanıtı bekleniyor. Müşteri 2 kez e-posta gönderdi. Zeynep işe dönünce ilk iş olarak yanıtlamalı.",
  occurred_at: zeynep_leave_start + 1.day + 2.hours, source_record: "CRM - TechCorp Deal #D-2891",
  severity: "urgent", is_demo: true
)

WorkEvent.create!(
  user: nil, department: "Sales",
  event_type: "meeting_rescheduled",
  title: "Aylık Sales Review Toplantısı Taşındı",
  description: "Ekip takvim çakışması nedeniyle Aylık Sales Review toplantısı #{(today + 2.days).strftime('%d.%m.%Y')} Salı 10:00'a alındı. Zeynep'in katılımı bekleniyor.",
  occurred_at: zeynep_leave_start + 2.days, source_record: "Google Calendar",
  severity: "important", is_demo: true
)

WorkEvent.create!(
  user: nil, department: "Sales",
  event_type: "team_announcement",
  title: "Yeni CRM Sistemi Eğitimi Zorunlu",
  description: "Tüm Sales ekibi için yeni Salesforce v3 eğitimi zorunlu hale getirildi. Eğitim tarihleri: #{(today + 5.days).strftime('%d.%m.%Y')} - #{(today + 7.days).strftime('%d.%m.%Y')}. Kayıt yapılması gerekiyor.",
  occurred_at: zeynep_leave_start + 1.day, source_record: "HR Announcement",
  severity: "important", is_demo: true
)

WorkEvent.create!(
  user: employee_zeynep, department: "Sales",
  event_type: "task_deadline_changed",
  title: "Q3 Kapanış Raporu Teslimi Öne Alındı",
  description: "Muhasebe departmanının talebi üzerine Q3 satış kapanış raporunun teslim tarihi #{(today + 1.day).strftime('%d.%m.%Y')}'a öne çekildi. Acil dikkat gerektiriyor!",
  occurred_at: zeynep_leave_start + 3.days, source_record: "Finance Request #FIN-89",
  severity: "urgent", is_demo: true
)

# Şirket geneli duyuru — tüm çalışanlar görür (department: nil)
WorkEvent.create!(
  user: nil, department: nil,
  event_type: "team_announcement",
  title: "Şirket Geneli: Yeni Uzaktan Çalışma Politikası",
  description: "İK departmanı yeni uzaktan çalışma politikasını duyurdu. Kasım ayından itibaren haftada 3 gün ofis, 2 gün uzaktan çalışma modeli uygulanacak.",
  occurred_at: today - 3.days, source_record: "HR Announcement",
  severity: "important", is_demo: true
)

puts "  Zeynep: #{WorkEvent.where(user: employee_zeynep, is_demo: true).count} personal + #{WorkEvent.where(user: nil, department: 'Sales', is_demo: true).count} Sales team events"
puts "  Company-wide: #{WorkEvent.where(user: nil, department: nil, is_demo: true).count} events (visible to all)"
puts "  Total demo work events: #{WorkEvent.where(is_demo: true).count}"

# ================================================================
# 4. AI SOHBET ÖRNEK MESAJLARI — Her çalışana özel
# ================================================================
puts "\n  Creating AI chat example messages..."

# Ahmet
AiChatMessage.create!(user: employee_ahmet, leave_request: ahmet_approved, role: "user",
  content: "Bana atanan en acil iş hangisi?")
AiChatMessage.create!(user: employee_ahmet, leave_request: ahmet_approved, role: "assistant",
  content: "🔴 **İzin sürenizde tespit edilen öncelikli konu:**\n\n🚨 [ACİL] **Güvenlik Açığı: Bağımlılık Güncellemesi Gerekli** — Dependabot, kritik bir güvenlik açığı tespit etti (CVE-2026-4521). bcrypt gem'inin 3.1.23 sürümüne güncellenmesi acil olarak gerekiyor. *(Kaynak: GitHub Security Alert)*\n\n💡 *Öneri: İşe döndüğünüzde ilk olarak bu güvenlik yamasını ele almanız tavsiye edilir.*")

# Mehmet
AiChatMessage.create!(user: employee_mehmet, leave_request: mehmet_approved, role: "user",
  content: "İzindeyken benim için ne değişti?")
AiChatMessage.create!(user: employee_mehmet, leave_request: mehmet_approved, role: "assistant",
  content: "📋 **İzin sürenizde size ait 5 gelişme tespit edildi:**\n\n🔴 [ACİL] **Müşteri Dashboard Bug Fix** — Müşteri panelinde kritik görsel hata raporlandı. *(Jira #LF-318)*\n🔴 [ACİL] **2FA Implementasyon Raporu Bekleniyor** — Proje yöneticisi 3 kez hatırlatma yaptı.\n🟡 [ÖNEMLİ] **Authentication Refactor teslim tarihi öne çekildi** — Yeni teslim: #{(today + 3.days).strftime('%d.%m.%Y')}.\n\n💡 *İşe döndüğünüzde önce bu iki acil konuyu ele almanızı öneririm.*")

# Zeynep
AiChatMessage.create!(user: employee_zeynep, leave_request: zeynep_approved, role: "user",
  content: "Hangi toplantım kaydı değişti?")
AiChatMessage.create!(user: employee_zeynep, leave_request: zeynep_approved, role: "assistant",
  content: "📅 **Toplantı Değişikliği Tespit Edildi:**\n\n🗓️ **Aylık Sales Review Toplantısı** tarih değişikliğine uğradı. Yeni tarih: **#{(today + 2.days).strftime('%d.%m.%Y')} Salı, 10:00**. Katılımınız bekleniyor. *(Kaynak: Google Calendar)*\n\n⚠️ Ayrıca **Yeni CRM Sistemi Eğitimi** için kayıt yaptırmanız gerekiyor (#{(today + 5.days).strftime('%d.%m.%Y')} - #{(today + 7.days).strftime('%d.%m.%Y')}).")

puts "  AI chat example messages created."

puts "\n=== Seed Completed Successfully ==="
puts ""
puts "Demo Accounts:"
puts "  Manager  : ayse.yonetici@leaveflow.com  / password123  (Manager dashboard)"
puts "  Employee1: ahmet@leaveflow.com           / password123  (Upcoming leave — 7 events)"
puts "  Employee2: mehmet@leaveflow.com          / password123  (Active leave NOW — 5 events)"
puts "  Employee3: zeynep@leaveflow.com          / password123  (Return from leave — 6 events)"

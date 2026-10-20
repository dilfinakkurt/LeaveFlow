# LeaveFlow Seed Data
# Güvenli seed: find_or_initialize_by kullanarak var olan veya production verilerini silmez/ezmez.

puts "=== LeaveFlow Seed İşlemi Başlatılıyor ==="

# 1. Yöneticiler
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
puts "✓ Yönetici hazır: #{manager_ayse.name} (#{manager_ayse.email})"

# 2. Çalışanlar
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
puts "✓ Çalışan hazır: #{employee_ahmet.name} (#{employee_ahmet.email})"

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
puts "✓ Ekip arkadaşı hazır: #{employee_mehmet.name} (#{employee_mehmet.email})"

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
puts "✓ Satış çalışanı hazır: #{employee_zeynep.name} (#{employee_zeynep.email})"

# 3. İzin Talepleri
# Seed her çalıştığında tarihi değiştiği için eski çakışan talepleri temizle
LeaveRequest.where(user: [employee_ahmet, employee_mehmet, employee_zeynep]).destroy_all

# A. Ahmet'in onaylanmış izni (Gelecek hafta - Ekip çakışması testi için baz veri)
next_monday = Date.current.next_week(:monday)
next_wednesday = next_monday + 2.days

ahmet_approved = LeaveRequest.create!(
  user: employee_ahmet,
  start_date: next_monday,
  end_date: next_wednesday,
  leave_type: "annual",
  reason: "Aile ziyareti ve dinlenme amaçlı yıllık izin.",
  status: "approved",
  decided_by: manager_ayse,
  decided_at: 1.day.ago,
  backup_user: employee_mehmet,
  handover_notes: "Ödeme API entegrasyonu ve güvenlik açığı uyarılarını vekaleten takip edebilir misin?"
)
puts "✓ Onaylı izin hazır (Ahmet, Yedek: Mehmet): #{ahmet_approved.start_date} - #{ahmet_approved.end_date}"

# B. Mehmet'in Gecikmiş (SLA >48h) Bekleyen İzni (SLA kuralı testi için)
mehmet_overdue = LeaveRequest.create!(
  user: employee_mehmet,
  start_date: next_monday + 7.days,
  end_date: next_monday + 9.days,
  leave_type: "annual",
  reason: "Konferans katılımı ve kişisel gelişim izni.",
  status: "pending",
  created_at: 50.hours.ago
)
puts "✓ Gecikmiş SLA bekleyen izin hazır (Mehmet, oluşturulma: 50 saat önce)"

# C. Zeynep'in Yeni Bekleyen İzni (Normal SLA içinde)
zeynep_pending = LeaveRequest.create!(
  user: employee_zeynep,
  start_date: next_monday + 14.days,
  end_date: next_monday + 16.days,
  leave_type: "annual",
  reason: "Yaz tatili başlangıcı planlaması.",
  status: "pending",
  created_at: 4.hours.ago
)
puts "✓ Bekleyen normal izin hazır (Zeynep, oluşturulma: 4 saat önce)"

# ===============================================================
# 4. AI İzin Asistanı — Demo İş Hareketleri (Work Events)
# ===============================================================
puts "\n=== AI İzin Asistanı Demo Verileri Oluşturuluyor ==="

# Ahmet'in izin dönemi: next_monday – next_wednesday
# Bu dönemde oluşan iş hareketleri
leave_start = next_monday
leave_end   = next_wednesday

# Eski demo verileri temizle
WorkEvent.where(is_demo: true).destroy_all
Notification.destroy_all
LeaveReturnSummary.destroy_all
AiChatMessage.destroy_all

puts "  İş hareketleri (Work Events) oluşturuluyor..."

  WorkEvent.create!(
    user: employee_ahmet,
    department: "Engineering",
    event_type: "task_assigned",
    title: "API Entegrasyon Görevi Atandı",
    description: "Ödeme sistemi API entegrasyonu için yeni bir görev atandı. Sprint planlama toplantısında karar verildi. Teslim tarihi: #{(leave_end + 5.days).strftime('%d.%m.%Y')}.",
    occurred_at: leave_start + 4.hours,
    source_record: "Jira #LF-302",
    severity: "important",
    is_demo: true
  )

  WorkEvent.create!(
    user: employee_ahmet,
    department: "Engineering",
    event_type: "task_status_changed",
    title: "Veritabanı Migration PR'ı Birleştirildi",
    description: "Ahmet'in izinden önce oluşturduğu veritabanı migration pull request'i incelendi ve ana dala birleştirildi. Staging ortamına deploy edildi.",
    occurred_at: leave_start + 6.hours,
    source_record: "GitHub PR #187",
    severity: "normal",
    is_demo: true
  )

  WorkEvent.create!(
    user: employee_ahmet,
    department: "Engineering",
    event_type: "task_deadline_changed",
    title: "Frontend Redesign Teslim Tarihi Güncellendi",
    description: "Müşteri geri bildirimi nedeniyle Frontend Redesign projesinin teslim tarihi #{(leave_end + 3.days).strftime('%d.%m.%Y')} tarihinden #{(leave_end + 10.days).strftime('%d.%m.%Y')} tarihine ertelendi.",
    occurred_at: leave_start + 1.day + 2.hours,
    source_record: "Sprint Planı",
    severity: "important",
    is_demo: true
  )

  WorkEvent.create!(
    user: nil,
    department: "Engineering",
    event_type: "project_update",
    title: "v2.5 Sürüm Planı Açıklandı",
    description: "Engineering ekibi için v2.5 sürüm yol haritası yayınlandı. Yeni özellikler: Gerçek zamanlı bildirimler, Dashboard yeniden tasarımı, Performans iyileştirmeleri.",
    occurred_at: leave_start + 1.day + 5.hours,
    source_record: "Confluence",
    severity: "normal",
    is_demo: true
  )

  WorkEvent.create!(
    user: employee_ahmet,
    department: "Engineering",
    event_type: "pending_action",
    title: "Güvenlik Açığı: Bağımlılık Güncellemesi Gerekli",
    description: "Dependabot, kritik bir güvenlik açığı tespit etti (CVE-2026-4521). bcrypt gem'inin 3.1.23 sürümüne güncellenmesi acil olarak gerekiyor. Ahmet'in sorumluluğunda.",
    occurred_at: leave_start + 2.days,
    source_record: "GitHub Security Alert",
    severity: "urgent",
    is_demo: true
  )

  WorkEvent.create!(
    user: nil,
    department: "Engineering",
    event_type: "meeting_rescheduled",
    title: "Haftalık Sprint Review Toplantısı Ertelendi",
    description: "Bu haftanın Sprint Review toplantısı Çarşamba'dan Perşembe 14:00'e ertelendi. Sebebi: Ürün yöneticisinin toplantı çakışması.",
    occurred_at: leave_start + 1.day + 8.hours,
    source_record: "Google Calendar",
    severity: "normal",
    is_demo: true
  )

  WorkEvent.create!(
    user: nil,
    department: nil,
    event_type: "team_announcement",
    title: "Şirket Geneli: Yeni Uzaktan Çalışma Politikası",
    description: "İK departmanı yeni uzaktan çalışma politikasını duyurdu. Kasım ayından itibaren haftada 3 gün ofis, 2 gün uzaktan çalışma modeli uygulanacak.",
    occurred_at: leave_start + 2.days + 3.hours,
    source_record: "İK Duyurusu",
    severity: "important",
    is_demo: true
  )

  WorkEvent.create!(
    user: employee_ahmet,
    department: "Engineering",
    event_type: "task_assigned",
    title: "Code Review: Authentication Modülü",
    description: "Mehmet'in hazırladığı Authentication modülü refactor PR'ının code review'ı Ahmet'e atandı. PR boyutu: +450 / -120 satır.",
    occurred_at: leave_start + 2.days + 5.hours,
    source_record: "GitHub PR #192",
    severity: "normal",
    is_demo: true
  )

  puts "  ✓ #{WorkEvent.count} demo iş hareketi oluşturuldu."

  # Ahmet için başlangıç AI Soru-Cevap örneği
  AiChatMessage.create!(
    user: employee_ahmet,
    leave_request: ahmet_approved,
    role: "user",
    content: "Bana atanan en acil iş hangisi?"
  )
  AiChatMessage.create!(
    user: employee_ahmet,
    leave_request: ahmet_approved,
    role: "assistant",
    content: "⚡ **İzin sürenizde tespit edilen öncelikli konular:**\n\n• 🚨 [ACİL] Güvenlik Açığı: Bağımlılık Güncellemesi Gerekli: Dependabot, kritik bir güvenlik açığı tespit etti (CVE-2026-4521). bcrypt gem'inin 3.1.23 sürümüne güncellenmesi acil olarak gerekiyor. *(Kaynak: GitHub Security Alert)*\n\n💡 *Öneri: İşe döndüğünüzde ilk olarak bu güvenlik yamasını ele almanız tavsiye edilir.*"
  )
  puts "  ✓ Örnek AI sohbet mesajı oluşturuldu."

puts "=== Seed İşlemi Başarıyla Tamamlandı ==="

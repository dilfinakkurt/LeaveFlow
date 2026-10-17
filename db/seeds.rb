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
# A. Ahmet'in onaylanmış izni (Gelecek hafta - Ekip çakışması testi için baz veri)
next_monday = Date.current.next_week(:monday)
next_wednesday = next_monday + 2.days

ahmet_approved = LeaveRequest.find_or_initialize_by(
  user: employee_ahmet,
  start_date: next_monday,
  end_date: next_wednesday
)
ahmet_approved.assign_attributes(
  leave_type: "annual",
  reason: "Aile ziyareti ve dinlenme amaçlı yıllık izin.",
  status: "approved",
  decided_by: manager_ayse,
  decided_at: 1.day.ago
)
ahmet_approved.save!
puts "✓ Onaylı izin hazır (Ahmet): #{ahmet_approved.start_date} - #{ahmet_approved.end_date}"

# B. Mehmet'in Gecikmiş (SLA >48h) Bekleyen İzni (SLA kuralı testi için)
mehmet_overdue = LeaveRequest.find_or_initialize_by(
  user: employee_mehmet,
  start_date: next_monday + 7.days,
  end_date: next_monday + 9.days
)
mehmet_overdue.assign_attributes(
  leave_type: "annual",
  reason: "Konferans katılımı ve kişisel gelişim izni.",
  status: "pending",
  created_at: 50.hours.ago # 48 saati aştığı için SLA gecikmiş olarak işaretlenir
)
mehmet_overdue.save!
puts "✓ Gecikmiş SLA bekleyen izin hazır (Mehmet, oluşturulma: 50 saat önce)"

# C. Zeynep'in Yeni Bekleyen İzni (Normal SLA içinde)
zeynep_pending = LeaveRequest.find_or_initialize_by(
  user: employee_zeynep,
  start_date: next_monday + 14.days,
  end_date: next_monday + 16.days
)
zeynep_pending.assign_attributes(
  leave_type: "annual",
  reason: "Yaz tatili başlangıcı planlaması.",
  status: "pending",
  created_at: 4.hours.ago
)
zeynep_pending.save!
puts "✓ Bekleyen normal izin hazır (Zeynep, oluşturulma: 4 saat önce)"

puts "=== Seed İşlemi Başarıyla Tamamlandı ==="

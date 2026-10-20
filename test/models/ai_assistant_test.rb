require "test_helper"

class AiAssistantTest < ActiveSupport::TestCase
  setup do
    @user = create_user(name: "Ali Veli", email: "ali@example.com", department: "Engineering")
    @other_user = create_user(name: "Canan Can", email: "canan@example.com", department: "Sales")
    @manager = create_user(name: "Müdür Bey", email: "mudur@example.com", role: "manager")
  end

  # Senaryo 1: Onaylanmış izni olmayan çalışan
  test "calisanin onaylanmis izni yoksa ozet olusturulamaz" do
    result = LeaveReturnSummaryService.new(@user, nil).generate!
    assert_not result.success?
    assert_includes result.error, "Geçerli bir onaylanmış izin kaydı"
  end

  # Senaryo 2: İzin talebi beklemede olan çalışan
  test "beklemedeki izin icin ozet olusturulamaz" do
    pending_leave = LeaveRequest.create!(
      user: @user,
      leave_type: "annual",
      start_date: Date.current + 2.days,
      end_date: Date.current + 4.days,
      reason: "Bekleyen izin",
      status: "pending"
    )

    result = LeaveReturnSummaryService.new(@user, pending_leave).generate!
    assert_not result.success?
    assert_includes result.error, "onaylanmış"
  end

  # Senaryo 3 & 5: İzin süresinde iş hareketleri oluşan ve işe dönen çalışan (Tüm 6 bölümün oluşturulması)
  test "izin suresindeki is hareketleri 6 bolumlu ozete basariyla donusturulur" do
    leave_start = Date.current - 5.days
    leave_end = Date.current - 2.days

    approved_leave = LeaveRequest.new(
      user: @user,
      leave_type: "annual",
      start_date: leave_start,
      end_date: leave_end,
      reason: "Yıllık tatil",
      status: "approved",
      decided_by: @manager,
      decided_at: 6.days.ago
    )
    approved_leave.save!(validate: false)

    # İzin süresinde oluşan iş hareketleri
    e1 = WorkEvent.create!(
      user: @user,
      department: "Engineering",
      event_type: "task_assigned",
      title: "Yeni Güvenlik Görevi",
      description: "OAuth entegrasyonu tamamlanacak",
      occurred_at: leave_start + 1.day,
      severity: "important",
      source_record: "Jira #LF-501"
    )

    e2 = WorkEvent.create!(
      user: @user,
      department: "Engineering",
      event_type: "task_deadline_changed",
      title: "API Teslimi Ertelendi",
      description: "Teslim tarihi cuma gününe ertelendi",
      occurred_at: leave_start + 2.days,
      severity: "urgent",
      source_record: "Sprint Planı"
    )

    e3 = WorkEvent.create!(
      user: nil,
      department: "Engineering",
      event_type: "meeting_rescheduled",
      title: "Departman Toplantısı Saati Değişti",
      description: "Pazartesi 10:00 yerine 15:00",
      occurred_at: leave_start + 2.days,
      severity: "normal",
      source_record: "Google Meet"
    )

    e4 = WorkEvent.create!(
      user: nil,
      department: "Engineering",
      event_type: "project_update",
      title: "Ana Veritabanı Kümesi Güncellendi",
      description: "Postgres 16 yükseltmesi tamamlandı",
      occurred_at: leave_start + 3.days,
      severity: "normal",
      source_record: "DevOps Bülteni"
    )

    result = LeaveReturnSummaryService.new(@user, approved_leave).generate!
    assert result.success?, "Özet başarıyla oluşturulmalı"

    summary = result.summary
    assert_equal 4, summary.events_count

    # 6 Bölümün doluluğu kontrol edilir
    assert summary.assigned_tasks.present?, "Yeni atanan görevler bölümü dolu olmalı"
    assert summary.updated_tasks.present?, "Güncellenen görevler bölümü dolu olmalı"
    assert summary.meeting_announcements.present?, "Toplantı ve duyurular bölümü dolu olmalı"
    assert summary.key_developments.present?, "Önemli gelişmeler bölümü dolu olmalı"
    assert summary.priority_items.present?, "Öncelikli işler (urgent) bölümü dolu olmalı"
    assert summary.action_items.present?, "Önerilen adımlar bölümü dolu olmalı"
  end

  # Senaryo 4: İzin süresinde hiçbir gelişme olmayan çalışan (Halüsinasyonsuz boş durum)
  test "izin suresinde gelisme yoksa ozet bos durum bilgisi ile olusturulur" do
    leave_start = Date.current - 5.days
    leave_end = Date.current - 2.days

    approved_leave = LeaveRequest.new(
      user: @user,
      leave_type: "annual",
      start_date: leave_start,
      end_date: leave_end,
      reason: "Sakin izin",
      status: "approved",
      decided_by: @manager,
      decided_at: 6.days.ago
    )
    approved_leave.save!(validate: false)

    result = LeaveReturnSummaryService.new(@user, approved_leave).generate!
    assert result.success?
    summary = result.summary

    assert_equal 0, summary.events_count
    assert_nil summary.assigned_tasks
    assert_nil summary.priority_items
  end

  # Senaryo 6: Aynı olayın iki kez özete eklenmemesi (Deduplication)
  test "ayni olay birden fazla kez ozete eklenmez" do
    leave_start = Date.current - 4.days
    leave_end = Date.current - 1.day

    approved_leave = LeaveRequest.new(
      user: @user,
      leave_type: "annual",
      start_date: leave_start,
      end_date: leave_end,
      reason: "İzin",
      status: "approved",
      decided_by: @manager
    )
    approved_leave.save!(validate: false)

    event = WorkEvent.create!(
      user: @user,
      department: "Engineering",
      event_type: "pending_action",
      title: "Tekil Acil Görev",
      description: "Acil işlem gerekiyor",
      occurred_at: leave_start + 1.day,
      severity: "urgent"
    )

    result = LeaveReturnSummaryService.new(@user, approved_leave).generate!
    assert result.success?

    # priority_items kontrol edilir: Tek bir kayıt olmalı
    priority_items = JSON.parse(result.summary.priority_items)
    event_ids = priority_items.map { |i| i["id"] }
    assert_equal 1, event_ids.count(event.id), "Olay kimliği tekrarlanmamalı"
  end

  # Senaryo 7: Yetkisiz kullanıcının başka çalışanın iznine/özetine erişiminin engellenmesi
  test "yetkisiz kullanici baska calisanin izni icin ozet olusturamaz" do
    approved_leave = LeaveRequest.new(
      user: @user,
      leave_type: "annual",
      start_date: Date.current - 3.days,
      end_date: Date.current - 1.day,
      reason: "Ali'nin izni",
      status: "approved",
      decided_by: @manager
    )
    approved_leave.save!(validate: false)

    # Canan (başka kullanıcı) Ali'nin izni için özet oluşturmaya çalışır
    result = LeaveReturnSummaryService.new(@other_user, approved_leave).generate!
    assert_not result.success?
    assert_includes result.error, "yetkiniz bulunmamaktadır"
  end

  # Senaryo 7 (Gizlilik): Başka kullanıcının özel iş hareketlerini görememe
  test "calisan baska calisana ozel atanmis is hareketlerini goremez" do
    # Canan'a özel olay
    private_event = WorkEvent.create!(
      user: @other_user,
      department: "Sales",
      event_type: "task_assigned",
      title: "Gizli Satış Raporu",
      description: "Sadece Canan görebilir",
      occurred_at: 1.day.ago,
      severity: "normal"
    )

    # Ali'nin görebileceği olaylar listesi
    ali_events = WorkEvent.for_user(@user)
    assert_not_includes ali_events, private_event, "Kullanıcı başka bir çalışanın özel iş hareketini görmemelidir"
  end

  # Senaryo 8: Boş veya hatalı olay verileri yönetimi
  test "hatali olay verileri guvenli sekilde validasyondan gecmez" do
    invalid_event = WorkEvent.new(
      event_type: "invalid_type",
      title: "",
      description: "",
      occurred_at: nil,
      severity: "invalid_severity"
    )
    assert_not invalid_event.valid?
    assert invalid_event.errors[:event_type].any?
    assert invalid_event.errors[:title].any?
    assert invalid_event.errors[:description].any?
    assert invalid_event.errors[:occurred_at].any?
    assert invalid_event.errors[:severity].any?
  end

  # Senaryo 9: Bildirimlerin okunması ve unread sayısının doğru güncellenmesi
  test "bildirim okundugunda unread sayisi guncellenir" do
    notif = Notification.create!(
      user: @user,
      notification_type: "leave_started",
      title: "İzniniz Başladı",
      message: "İyi tatiller dileriz"
    )

    assert_equal 1, @user.unread_notifications_count
    assert notif.unread?

    notif.mark_as_read!
    assert notif.read?
    assert_equal 0, @user.unread_notifications_count
  end

  # Senaryo 9 (Deduplication): Aynı bildirim anahtarıyla gereksiz tekrar bildirim üretilmez
  test "ayni bildirim tekrarlanmaz" do
    service = NotificationService.new(@user)

    # Yaklaşan izin
    upcoming_leave = LeaveRequest.new(
      user: @user,
      leave_type: "annual",
      start_date: Date.current + 2.days,
      end_date: Date.current + 4.days,
      reason: "Yaklaşan tatil",
      status: "approved",
      decided_by: @manager
    )
    upcoming_leave.save!(validate: false)

    # İlk kontrol bildirim oluşturur
    service.check_and_notify!
    count_after_first = @user.notifications.count
    assert count_after_first >= 1

    # İkinci kontrol mükerrer bildirim oluşturmaz
    service.check_and_notify!
    assert_equal count_after_first, @user.notifications.count
  end

  # Senaryo 10: İzin tarihlerinin sınır durumları (Boundary / Timezone)
  test "izin baslangic ve bitis gunu sinirlarindaki olaylar kapsama dahil edilir" do
    leave_start = Date.current - 3.days
    leave_end = Date.current - 1.day

    approved_leave = LeaveRequest.new(
      user: @user,
      leave_type: "annual",
      start_date: leave_start,
      end_date: leave_end,
      reason: "Sınır durum izni",
      status: "approved",
      decided_by: @manager
    )
    approved_leave.save!(validate: false)

    # Başlangıç günü sabah 00:01
    event_start_edge = WorkEvent.create!(
      user: @user,
      event_type: "task_assigned",
      title: "Başlangıç Sınır Olayı",
      description: "00:01 olayı",
      occurred_at: leave_start.beginning_of_day + 1.minute,
      severity: "normal"
    )

    # Bitiş günü gece 23:58
    event_end_edge = WorkEvent.create!(
      user: @user,
      event_type: "task_assigned",
      title: "Bitiş Sınır Olayı",
      description: "23:58 olayı",
      occurred_at: leave_end.end_of_day - 1.minute,
      severity: "normal"
    )

    # İzin başlamadan 1 dakika önceki olay (hariç tutulmalı)
    event_before = WorkEvent.create!(
      user: @user,
      event_type: "task_assigned",
      title: "İzin Öncesi Olay",
      description: "Kapsam dışı",
      occurred_at: leave_start.beginning_of_day - 1.minute,
      severity: "normal"
    )

    # İzin bittikten 1 dakika sonraki olay (hariç tutulmalı)
    event_after = WorkEvent.create!(
      user: @user,
      event_type: "task_assigned",
      title: "İzin Sonrası Olay",
      description: "Kapsam dışı",
      occurred_at: leave_end.end_of_day + 1.minute,
      severity: "normal"
    )

    events_in_range = WorkEvent.for_user(@user).in_range(leave_start.beginning_of_day, leave_end.end_of_day)

    assert_includes events_in_range, event_start_edge, "Başlangıç günü sınır olayı dahil edilmeli"
    assert_includes events_in_range, event_end_edge, "Bitiş günü sınır olayı dahil edilmeli"
    assert_not_includes events_in_range, event_before, "İzin öncesi olay dahil edilmemeli"
    assert_not_includes events_in_range, event_after, "İzin sonrası olay dahil edilmemeli"
  end

  # ========================================================
  # Yeni Özellik 1: İnteraktif AI Chat Testleri
  # ========================================================
  test "ai chat servisi acil isleri ve toplantilari dogru tespit eder" do
    leave_start = Date.current - 3.days
    leave_end = Date.current - 1.day

    approved_leave = LeaveRequest.new(
      user: @user,
      leave_type: "annual",
      start_date: leave_start,
      end_date: leave_end,
      reason: "Chat test izni",
      status: "approved",
      decided_by: @manager
    )
    approved_leave.save!(validate: false)

    WorkEvent.create!(
      user: @user,
      department: "Engineering",
      event_type: "pending_action",
      title: "Kritik Güvenlik Yaması",
      description: "CVE-2026-9999 yamalanmalı",
      occurred_at: leave_start + 1.day,
      severity: "urgent"
    )

    WorkEvent.create!(
      user: nil,
      department: "Engineering",
      event_type: "meeting_rescheduled",
      title: "Sprint Review Ertelendi",
      description: "Perşembe saat 14:00'e alındı",
      occurred_at: leave_start + 2.days,
      severity: "normal"
    )

    chat_service = AiChatService.new(@user, approved_leave)

    # 1. Acil iş sorusu
    answer_urgent = chat_service.answer("Bana atanan en acil iş hangisi?")
    assert_includes answer_urgent, "Kritik Güvenlik Yaması"
    assert_includes answer_urgent, "ACİL"

    # 2. Toplantı sorusu
    answer_meeting = chat_service.answer("İzindeyken toplantı saatim değişti mi?")
    assert_includes answer_meeting, "Sprint Review Ertelendi"

    # 3. Chat mesajlarının veritabanında saklandığını doğrula
    assert_equal 2, @user.ai_chat_messages.where(role: "user").count
    assert_equal 2, @user.ai_chat_messages.where(role: "assistant").count
  end

  # ========================================================
  # Yeni Özellik 2: Akıllı İş Devri ve Yedek Çalışan Testleri
  # ========================================================
  test "calisan kendisini yedek calisan olarak secemez" do
    leave = LeaveRequest.new(
      user: @user,
      leave_type: "annual",
      start_date: Date.current + 5.days,
      end_date: Date.current + 7.days,
      reason: "Yedek testi",
      backup_user: @user
    )
    assert_not leave.valid?
    assert leave.errors[:backup_user_id].any?
    assert_includes leave.errors[:backup_user_id].first, "Kendinizi"
  end

  test "yedek calisana is devri bildirimi iletilir" do
    leave = LeaveRequest.new(
      user: @user,
      leave_type: "annual",
      start_date: Date.current,
      end_date: Date.current + 2.days,
      reason: "Vekalet izni",
      status: "approved",
      decided_by: @manager,
      backup_user: @other_user,
      handover_notes: "Acil durumlarda PR 180'e bak"
    )
    leave.save!(validate: false)

    # Bildirim servisi çalıştırılır
    NotificationService.new(@other_user).check_and_notify!

    backup_notif = @other_user.notifications.find_by("notification_key LIKE ?", "handover_assign_notice_%")
    assert backup_notif.present?, "Yedek çalışana vekalet bildirimi gitmeli"
    assert_includes backup_notif.message, "Ali Veli"
    assert_includes backup_notif.message, "Acil durumlarda PR 180'e bak"
  end

  # ========================================================
  # Yeni Özellik 3: Yönetici Ekip Kapsama ve İzin Dönüş Analitiği
  # ========================================================
  test "ekip analitigi servisi kapasite oranini ve gecikme risklerini hesaplar" do
    analytics_service = TeamAnalyticsService.new(@manager, "Engineering")
    data = analytics_service.analyze

    assert data[:total_employees] >= 1
    assert data[:capacity_percentage] >= 0
    assert data[:capacity_percentage] <= 100
    assert data[:capacity_status].present?
    assert data[:capacity_status][:label].present?
    assert_kind_of Array, data[:project_delay_risks]
    assert_kind_of Array, data[:return_surge_analysis]
  end
end

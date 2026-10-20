require "test_helper"

class AiAssistantFlowTest < ActionDispatch::IntegrationTest
  setup do
    @user = create_user(name: "Ahmet Demir", email: "ahmet.flow@example.com", department: "Engineering")
    @other_user = create_user(name: "Canan Çelik", email: "canan.flow@example.com", department: "Sales")
    @manager = create_user(name: "Ayşe Yönetici", email: "ayse.flow@example.com", role: "manager")

    # Ahmet'in tamamlanmış onaylı izni
    @leave = LeaveRequest.new(
      user: @user,
      leave_type: "annual",
      start_date: Date.current - 4.days,
      end_date: Date.current - 1.day,
      reason: "Yıllık izin",
      status: "approved",
      decided_by: @manager,
      decided_at: 5.days.ago
    )
    @leave.save!(validate: false)

    # İzin sırasında gerçekleşen demo iş hareketi
    @event = WorkEvent.create!(
      user: @user,
      department: "Engineering",
      event_type: "task_assigned",
      title: "Flow Test Görevi",
      description: "Entegrasyon testi için görev",
      occurred_at: Date.current - 2.days,
      severity: "urgent",
      source_record: "Jira #LF-999"
    )
  end

  test "giris yapmamis kullanici login sayfasina yonlendirilir" do
    get ai_assistant_path
    assert_redirected_to login_path
  end

  test "giris yapmis calisan asistan sayfasini goruntuler" do
    log_in_as(@user)
    get ai_assistant_path
    assert_response :success
    assert_select "h1", text: /AI İzin Asistanı/
    assert_select ".stat-title", text: /Kaydedilen Gelişme/
  end

  test "calisan ise donus ozetini basariyla olusturabilir" do
    log_in_as(@user)
    get ai_assistant_path
    assert_response :success

    post generate_summary_path, params: { leave_request_id: @leave.id }
    assert_redirected_to ai_assistant_path
    follow_redirect!

    assert_select ".flash-notice", text: /İşe dönüş özetiniz başarıyla oluşturuldu/
    assert_select "h2", text: /İşe Dönüş Özetiniz/
    assert_select ".summary-section-title", text: /Yeni Atanan Görevler/
  end

  test "calisan baska bir calisanin izni icin ozet olusturamaz" do
    log_in_as(@other_user)

    # Canan, Ahmet'in izni için istek atar
    post generate_summary_path, params: { leave_request_id: @leave.id }
    assert_redirected_to ai_assistant_path
    follow_redirect!

    assert_select ".flash-alert", text: /Geçerli bir onaylanmış izin kaydı bulunamadı/
  end

  test "bildirim tekil olarak okundu isaretlenebilir" do
    notif = Notification.create!(
      user: @user,
      notification_type: "general",
      title: "Test Bildirimi",
      message: "Bu bir test mesajıdır."
    )

    log_in_as(@user)
    patch mark_notification_read_path(notif)
    assert_redirected_to ai_assistant_path

    assert notif.reload.read?
  end

  test "tum bildirimler topluca okundu isaretlenebilir" do
    Notification.create!(user: @user, notification_type: "general", title: "B1", message: "M1")
    Notification.create!(user: @user, notification_type: "general", title: "B2", message: "M2")

    log_in_as(@user)
    assert_equal 2, @user.unread_notifications_count

    patch mark_all_notifications_read_path
    assert_redirected_to ai_assistant_path

    assert_equal 0, @user.reload.unread_notifications_count
  end

  test "calisan ai asistana soru sorabilir ve sohbet gecmisini temizleyebilir" do
    log_in_as(@user)

    # Soru gönder
    post ai_chat_path, params: { question: "Bana atanan görevler neler?", leave_request_id: @leave.id }
    assert_redirected_to ai_assistant_path(anchor: "chat-box")
    follow_redirect!

    assert_select ".chat-bubble-user", text: /Bana atanan görevler neler?/
    assert_select ".chat-bubble-assistant", text: /Flow Test Görevi/

    # Sohbeti temizle
    delete clear_ai_chat_path
    assert_redirected_to ai_assistant_path(anchor: "chat-box")
    follow_redirect!

    assert_equal 0, @user.ai_chat_messages.count
  end

  test "yonetici ekip analitigi sayfasini goruntuleyebilir ama normal calisan erisemez" do
    # 1. Normal çalışan erişmeye çalışır -> dashboard'a yönlendirilir
    log_in_as(@user)
    get manager_analytics_path
    assert_redirected_to dashboard_path
    follow_redirect!
    assert_select ".flash-alert", text: /yönetici yetkisine sahip olmalısınız/

    # 2. Yönetici erişir -> başarılı
    log_in_as(@manager)
    get manager_analytics_path
    assert_response :success
    assert_select "h1", text: /Ekip Kapsama ve İzin Dönüş Analitiği/
    assert_select ".stat-title", text: /Aktif Ekip Kapasitesi/
  end
end

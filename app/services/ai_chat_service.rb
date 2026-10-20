# AiChatService
# İzin dönemindeki olaylara dayalı, halüsinasyonsuz, akıllı soru-cevap motoru.
class AiChatService
  def initialize(user, leave_request)
    @user = user
    @leave_request = leave_request
  end

  def answer(question_text)
    clean_question = question_text.to_s.strip
    return "Lütfen yanıtlamamı istediğiniz bir soru yazınız." if clean_question.blank?

    # 1. Kullanıcı mesajını kaydet
    user_msg = AiChatMessage.create!(
      user: @user,
      leave_request: @leave_request,
      role: "user",
      content: clean_question
    )

    # 2. Olayları ve bağlamı hazırla
    events = fetch_events
    response_text = generate_response(clean_question, events)

    # 3. Asistan yanıtını kaydet
    AiChatMessage.create!(
      user: @user,
      leave_request: @leave_request,
      role: "assistant",
      content: response_text
    )

    response_text
  end

  private

  def fetch_events
    return WorkEvent.none unless @leave_request
    start_time = @leave_request.start_date.beginning_of_day
    end_time   = @leave_request.end_date.end_of_day
    WorkEvent.for_user(@user).in_range(start_time, end_time).urgent_first
  end

  def generate_response(question, events)
    q = question.downcase

    # A. Yedek Çalışan / İş Devri ile ilgili sorular
    if q.match?(/yedek|vekalet|devir|yerime|baktı|bakan/)
      if @leave_request&.backup_user
        msg = "🤝 İzin süreniz boyunca yedek çalışma arkadaşınız **#{@leave_request.backup_user.name}** (#{@leave_request.backup_user.email}) olarak belirlenmiştir."
        if @leave_request.handover_notes.present?
          msg += "\n\n📝 **Bıraktığınız Devir Notu:** \"#{@leave_request.handover_notes}\""
        end
        return msg
      else
        return "ℹ️ Bu izin talebiniz için belirlenmiş bir yedek çalışan kaydı bulunmuyor."
      end
    end

    # Hiç olay yoksa
    if events.empty?
      return "🌴 İzin döneminizde (#{@leave_request&.start_date&.strftime('%d.%m.%Y')} - #{@leave_request&.end_date&.strftime('%d.%m.%Y')}) adınıza veya ekibinize kayıtlı herhangi bir iş hareketi bulunmamaktadır. Tüm projeler planlandığı şekilde devam etmiştir."
    end

    # B. Acil / Öncelikli İşler
    if q.match?(/acil|öncelik|kritik|urgent|hemen|ilk iş/)
      urgent_events = events.select { |e| e.severity.in?(%w[urgent important]) }
      if urgent_events.any?
        lines = urgent_events.map do |e|
          badge = e.severity == "urgent" ? "🚨 [ACİL]" : "⚠️ [ÖNEMLİ]"
          "• **#{badge} #{e.title}**: #{e.description} *(Kaynak: #{e.source_record || 'Sistem'})*"
        end
        return "⚡ **İzin sürenizde tespit edilen öncelikli konular:**\n\n" + lines.join("\n\n") + "\n\n💡 *Öneri: İşe döndüğünüzde ilk olarak bu görevleri ele almanız tavsiye edilir.*"
      else
        return "✅ İzniniz süresince kaydedilmiş acil veya yüksek öncelikli bir kriz/gelişme bulunmuyor."
      end
    end

    # C. Toplantı Değişiklikleri
    if q.match?(/toplantı|saat|zaman|meet|görüşme|ertelendi/)
      meetings = events.select { |e| e.event_type == "meeting_rescheduled" || e.title.downcase.include?("toplantı") }
      if meetings.any?
        lines = meetings.map do |m|
          "• 📅 **#{m.title}**: #{m.description} *(Tarih: #{m.occurred_at.strftime('%d.%m.%Y %H:%M')})*"
        end
        return "📅 **Toplantı güncellemeleri:**\n\n" + lines.join("\n\n")
      else
        return "📅 İzniniz süresince planlanan toplantılarınızda herhangi bir saat veya tarih değişikliği olmamıştır."
      end
    end

    # D. Yeni Atanan Görevler
    if q.match?(/görev|task|atandı|atanan|yeni iş|yeni görev/)
      tasks = events.select { |e| e.event_type == "task_assigned" }
      if tasks.any?
        lines = tasks.map do |t|
          "• 📋 **#{t.title}** (#{t.severity_label}): #{t.description} *(#{t.source_record})*"
        end
        return "📋 **İzniniz sırasında size atanan yeni görevler:**\n\n" + lines.join("\n\n")
      else
        return "📋 İzniniz boyunca adınıza doğrudan yeni bir görev ataması yapılmamıştır."
      end
    end

    # E. Teslim Tarihi / Deadline Değişiklikleri
    if q.match?(/teslim|tarih|deadline|süre|erte/)
      deadlines = events.select { |e| e.event_type == "task_deadline_changed" }
      if deadlines.any?
        lines = deadlines.map do |d|
          "• ⏳ **#{d.title}**: #{d.description} *(Kaynak: #{d.source_record})*"
        end
        return "⏳ **Teslim tarihi güncellenen işler:**\n\n" + lines.join("\n\n")
      else
        return "⏳ Görevlerinizin teslim tarihlerinde bir değişiklik gerçekleşmemiştir."
      end
    end

    # F. Duyurular ve Proje Güncellemeleri
    if q.match?(/duyuru|haber|politika|şirket|ekip|proje|yol haritası/)
      news = events.select { |e| e.event_type.in?(%w[team_announcement project_update]) }
      if news.any?
        lines = news.map do |n|
          "• 📢 **#{n.title}**: #{n.description}"
        end
        return "📢 **Ekip ve Şirket Duyuruları:**\n\n" + lines.join("\n\n")
      else
        return "📢 İzniniz sırasında yayınlanan önemli bir ekip duyurusu bulunmuyor."
      end
    end

    # G. Kod, PR, Review
    if q.match?(/pr|pull request|kod|review|merge|git/)
      code_events = events.select { |e| e.title.downcase.match?(/pr|kod|review|migration|merge/) || e.description.downcase.match?(/pr|kod|review/) }
      if code_events.any?
        lines = code_events.map do |c|
          "• 💻 **#{c.title}**: #{c.description}"
        end
        return "💻 **Kod ve Geliştirme Hareketleri:**\n\n" + lines.join("\n\n")
      else
        return "💻 İzin döneminizde doğrudan adınızla ilgili bir PR veya kod inceleme hareketi bulunmuyor."
      end
    end

    # H. Genel Özet Sorusu ("neler oldu?", "özetle", "genel durum")
    urgent_count = events.count { |e| e.severity == "urgent" }
    task_count   = events.count { |e| e.event_type == "task_assigned" }
    meeting_count = events.count { |e| e.event_type == "meeting_rescheduled" }

    "👋 İzin sürenizde toplam **#{events.size} gelişme** kaydedildi.\n\n" \
    "• 🚨 **Acil Konular:** #{urgent_count} adet\n" \
    "• 📋 **Yeni Görevler:** #{task_count} adet\n" \
    "• 📅 **Toplantı Değişiklikleri:** #{meeting_count} adet\n\n" \
    "Detaylar için bana *'Bana atanan görevler neler?'*, *'Acil işler hangileri?'* veya *'Toplantı saatim değişti mi?'* şeklinde sorabilirsiniz!"
  end
end

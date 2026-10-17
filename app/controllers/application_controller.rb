class ApplicationController < ActionController::Base
  helper_method :current_user, :logged_in?

  private

  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
  end

  def logged_in?
    current_user.present?
  end

  def require_login
    unless logged_in?
      flash[:alert] = "Lütfen önce giriş yapınız."
      redirect_to login_path
    end
  end

  def require_manager
    require_login
    return if performed?

    unless current_user.manager?
      flash[:alert] = "Bu sayfaya erişmek için yönetici yetkisine sahip olmalısınız."
      redirect_to dashboard_path
    end
  end
end

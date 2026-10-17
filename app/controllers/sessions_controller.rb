class SessionsController < ApplicationController
  def new
    redirect_to dashboard_path if logged_in?
  end

  def create
    user = User.find_by(email: params[:email].to_s.strip.downcase)
    if user&.authenticate(params[:password])
      session[:user_id] = user.id
      flash[:notice] = "Hoş geldiniz, #{user.name}! Giriş başarılı."
      if user.manager?
        redirect_to manager_leave_requests_path
      else
        redirect_to dashboard_path
      end
    else
      flash.now[:alert] = "Geçersiz e-posta veya parola."
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    session[:user_id] = nil
    flash[:notice] = "Başarıyla çıkış yapıldı."
    redirect_to login_path
  end
end

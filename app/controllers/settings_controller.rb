class SettingsController < ApplicationController
  before_action :authenticate_user!
  def index

  end

  def update
    if current_user.update(profile_params)
      redirect_to profile_setting_path, notice: "Profile updated"
    else
      redirect_to profile_setting_path
    end
  end

  def update_password
    current_user.password = current_user.password_confirmation = password_params[:password]
    if current_user.save
      redirect_to profile_setting_path, notice: "Password updated"
    else
      redirect_to profile_setting_path
    end
  end

  def team
  end

  private

  def profile_params
    params.require(:user).permit(:name, :phone)
  end

  def password_params
    params.require(:user).permit(:password)
  end
end
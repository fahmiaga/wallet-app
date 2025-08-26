class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  skip_before_action :verify_authenticity_token
  allow_browser versions: :modern
  include ActionController::Cookies

  private

  def current_user
    @current_user ||= User.find_by(id: session[:uid])
  end

  def require_auth!
    render json: { error: "unauthorized" }, status: :unauthorized unless current_user
  end
end

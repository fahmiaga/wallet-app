class SessionsController < ApplicationController
  def create
    user = User.find_by(email: params[:email].to_s.downcase)
    if user&.authenticate(params[:password].to_s)
      session[:uid] = user.id
      render json: { ok: true }
    else
      render json: { error: "invalid credentials" }, status: :unauthorized
    end
  end

  def destroy
    reset_session
    head :no_content
  end
end

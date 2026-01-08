class UsersController < ApplicationController
  def index
    @users = User.all
  end

  def show
    @user = User.find(params[:id])
  end

  def update
    @user = User.find(params[:id])

    if @user.update_attributes(user_params)
      redirect_to @user, notice: "User updated"
    else
      render :show
    end
  end

  private

  def user_params
    params.require(:user).permit(:name, :email)
  end
end

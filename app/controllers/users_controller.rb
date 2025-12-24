class UsersController < ApplicationController
  def index
    @user = User.all
  end

  def show
    @user = User.find(params[:id])
    @User.set_k_to_nil
  end
end

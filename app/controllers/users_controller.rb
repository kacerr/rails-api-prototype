class UsersController < ApplicationController

  # GET /tasks/1
  # GET /tasks/1.json
  def show
    @user = User.find(params[:id])

    render json: @user
  end

end

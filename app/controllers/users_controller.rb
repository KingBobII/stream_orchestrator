class UsersController < ApplicationController
  before_action :authenticate_request!, except: [:create]
  before_action :authorize_admin!, only: [:index, :destroy] # only admins list/delete users
  before_action :set_user, only: [:show, :update, :destroy]

  # POST /users
  # open to create initial users (you may lock this down later)
  def create
    user = User.new(user_params)
    user.email = user.email.downcase
    if user.save
      render json: { user: user.slice(:id, :email, :name, :role) }, status: :created
    else
      render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # GET /users
  def index
    users = User.order(created_at: :desc).select(:id, :email, :name, :role, :created_at)
    render json: users
  end

  # GET /users/:id
  def show
    render json: @user.slice(:id, :email, :name, :role, :created_at)
  end

  # PATCH/PUT /users/:id
  def update
    # only admins or the user themselves can update
    unless current_user.admin? || current_user.id == @user.id
      return render json: { error: "Forbidden" }, status: :forbidden
    end

    if @user.update(update_user_params)
      render json: @user.slice(:id, :email, :name, :role)
    else
      render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /users/:id
  def destroy
    @user.destroy
    render json: { message: "User deleted" }, status: :ok
  end

  private

  def set_user
    @user = User.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Not found" }, status: :not_found
  end

  def user_params
    params.require(:user).permit(:email, :name, :role, :password, :password_confirmation)
  end

  def update_user_params
    permitted = [:name]
    permitted << :password << :password_confirmation if params[:user][:password].present?
    permitted << :role if current_user&.admin?
    params.require(:user).permit(permitted)
  end
end

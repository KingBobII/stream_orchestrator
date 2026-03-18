module Admin
  class UsersController < Admin::BaseController
    def index
      @users = User.order(created_at: :desc)
    end

    def show
      @user = User.find(params[:id])
    end

    def edit
      @user = User.find(params[:id])
    end

    def update
      @user = User.find(params[:id])
      if @user.update(user_params)
        redirect_to admin_user_path(@user), notice: "User updated"
      else
        render :edit
      end
    end

    def destroy
      user = User.find(params[:id])
      user.destroy
      redirect_to admin_users_path, notice: "User removed"
    end

    private

    def user_params
      params.require(:user).permit(:email, :name, :role)
    end
  end
end

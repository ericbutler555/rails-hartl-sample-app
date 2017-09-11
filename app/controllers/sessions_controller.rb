class SessionsController < ApplicationController
  
  def new
  end
  
  def create
    @user = User.find_by(email: params[:session][:email].downcase)
    if @user && @user.authenticate(params[:session][:password])
      if @user.activated?
        log_in @user
        params[:session][:remember_me] == '1' ? remember(@user) : forget(@user)
        redirect_back_or @user
      else
        flash[:warning] = "Account has not yet been activated. Check your email for the activation link."
        redirect_to root_path
      end
    else
      flash.now[:danger] = "Invalid username and/or password"
      render 'new'
    end
  end
  
  def destroy
    log_out if logged_in?
    redirect_to root_url
  end
  
end

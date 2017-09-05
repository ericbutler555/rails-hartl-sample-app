module SessionsHelper

  # log in the given user
  def log_in(user)
    session[:user_id] = user.id
  end

  # save the user token into a persistent cookie
  def remember(user)
    user.remember # run the remember method in the User model
    cookies.permanent.signed[:user_id] = user.id
    cookies.permanent[:remember_token] = user.remember_token
  end

  # check the session/cookie and return the current logged-in user (if any)
  def current_user
    # note: "user_id" is assigned in the conditions so you can find_by it instead of looking it up again in next line
    if (user_id = session[:user_id])
      @current_user ||= User.find_by(id: user_id)
    elsif (user_id = cookies.signed[:user_id])
      user = User.find_by(id: user_id)
      if user && user.authenticated?(cookies[:remember_token])
        log_in user
        @current_user = user
      end
    end
  end

  # check if the current user is logged in
  def logged_in?
    !current_user.nil?
  end

  # remove the user session db token and cookies
  def forget(user)
    user.forget # run the forget method in the User model
    cookies.delete(:user_id)
    cookies.delete(:remember_token)
  end

  # log out the given user
  def log_out
    forget(current_user)
    session.delete(:user_id)
    @current_user = nil
  end

end

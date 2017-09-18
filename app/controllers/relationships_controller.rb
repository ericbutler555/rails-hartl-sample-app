class RelationshipsController < ApplicationController

  before_action :logged_in_user

  def create
    @user = User.find(params[:followed_id])
    current_user.follow(@user)
    # This doesn't work with Ajax: flash.now[:success] = "You are now following this user"
    respond_to do |format|
      format.html { redirect_to @user }
      format.js
    end
  end

  def destroy
    @user = Relationship.find(params[:id]).followed
    current_user.unfollow(@user)
    # This doesn't work with Ajax: flash.now[:warning] = "You are no longer following this user"
    respond_to do |format|
      format.html { redirect_to @user }
      format.js
    end
  end

end

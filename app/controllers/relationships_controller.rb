class RelationshipsController < ApplicationController

  before_action :logged_in_user

  def create
    user = User.find(params[:followed_id])
    current_user.follow(user)
    flash[:success] = "You are now following this user"
    redirect_to user
  end

  def destroy
    user = Relationship.find(params[:id]).followed
    current_user.unfollow(user)
    flash[:warning] = "You are no longer following this user"
    redirect_to user
  end

end

class UserController < ApplicationController
  def login
    if request.post?
      user = User.authenticate(params[:username], params[:pass])
      unless user.blank?
        session[:user_id] = user['user_id'].to_i
        redirect_to '/'
      else
        reset_session
      end
    else
      reset_session
      User.current = nil
    end

  end

  def logout
    reset_session
    User.current = nil
    redirect_to '/'
  end

end

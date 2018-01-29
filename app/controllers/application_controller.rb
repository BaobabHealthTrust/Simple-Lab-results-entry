# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time
  # protect_from_forgery # See ActionController::RequestForgeryProtection for details
  before_filter :check_if_login, :except => ['login']

  # Scrub sensitive parameters from your log
  # filter_parameter_logging :password
  
  
  protected

  def check_if_login

    if session[:user_id].blank?
      respond_to do |format|
        format.html { redirect_to '/login' }
      end
    elsif not session[:user_id].blank?
      User.current = User.find(session[:user_id])
    end
  end

end

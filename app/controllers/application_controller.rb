# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time
  # protect_from_forgery # See ActionController::RequestForgeryProtection for details
  before_filter :check_if_login, :except => ['login']

  # Scrub sensitive parameters from your log
  # filter_parameter_logging :password
  
  def connect_to_app_database
    app_env = ApplicationDB
    ActiveRecord::Base.establish_connection(
    :adapter  => app_env['adapter'],
    :host     => app_env['host'],
    :database => app_env['database'],
    :username => app_env['username'],
    :password => app_env['password'])
  end
    
  def connect_to_bart_database
    national_art = National_ART
    ActiveRecord::Base.establish_connection(
    :adapter  => national_art['adapter'],
    :host     => national_art['host'],
    :database => national_art['database'],
    :username => national_art['username'],
    :password => national_art['password'])
  end

  def connect_to_remote_bart_database
    national_art = Remote_national_ART
    ActiveRecord::Base.establish_connection(
    :adapter  => national_art['adapter'],
    :host     => national_art['host'],
    :database => national_art['database'],
    :username => national_art['username'],
    :password => national_art['password'])
  end

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

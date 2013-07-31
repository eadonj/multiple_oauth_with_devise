class AuthenticationsController < Devise::OmniauthCallbacksController
  include AuthenticationsHelper

  before_filter :attempt_to_find_existing_user
  before_filter :attempt_to_add_credentials_to_current_user
  before_filter :attempt_to_create_new_user
  before_filter :redirect_to_new_user_page

  def facebook
  end

  def twitter
  end

  private

  def omniauth
    request.env['omniauth.auth']
  end
  
  def attempt_to_find_existing_user
    authentication = Authentication.find_from_omniauth(omniauth)
    sign_in_and_redirect User.find(authentication.user_id) unless authentication.nil?
  end
  
  def attempt_to_add_credentials_to_current_user
    # Authentication.create_from_omniauth!(omniauth, current_user.id)
    current_user.add_new_authentication_from_omniauth(omniauth)
    redirect_to root_url
  end
  
  def attempt_to_create_new_user
    user = User.create_from_omniauth!(omniauth)
    sign_in_and_redirect user unless user.nil?
  end
  
  def redirect_to_new_user_page
    session[:omniauth] = omni.except('extra')
    redirect_to new_user_registration_path
  end

  
  # def authenticate
  #   find_existing_user and return
  #   add_

  #   if authentication = Authentication.find_from_omniauth(omniauth)
  #     sign_in_and_redirect User.find(authentication.user_id)
  #     return
  #   end

  #   if signed_in?
  #     Authentication.create_from_omniauth!(omniauth, current_user.id)
  #     redirect_to root_url
  #     return
  #   end

  #   if user = User.create_from_omniauth!(omniauth)
  #     sign_in_and_redirect user
  #     return
  #   end

  #   session[:omniauth] = omni.except('extra')
  #   redirect_to new_user_registration_path
  # end

  # def find_existing_user
  #   authentication = Authentication.find_from_omniauth(omniauth)
  #   return false if authentication.nil?
  #   sign_in_and_redirect User.find(authentication.user_id)
  #   true
  # end


end

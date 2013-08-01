class AuthenticationsController < Devise::OmniauthCallbacksController
  include AuthenticationsHelper

  before_filter :raise_if_omniauth_error
  before_filter :debugger
  before_filter :attempt_to_find_existing_user
  before_filter :attempt_to_add_credentials_to_current_user
  before_filter :attempt_to_create_new_user
  before_filter :redirect_to_new_user_page

  def facebook
  end

  def twitter
  end

  private

  def debugger
    binding.pry
  end

  def omniauth
    request.env['omniauth.auth'] 
  end

  def raise_if_omniauth_error
    if request.env["omniauth.error"]
      binding.pry
      raise request.env["omniauth.error"] 
    end
  end

  
  def attempt_to_find_existing_user
    authentication = Authentication.find_from_omniauth(omniauth)
    sign_in_and_redirect User.find(authentication.user_id) unless authentication.nil?
  end
  
  def attempt_to_add_credentials_to_current_user
    # Authentication.create_from_omniauth!(omniauth, current_user.id)
    return unless signed_in?
    current_user.add_new_authentication_from_omniauth(omniauth)
    redirect_to user_url(current_user)
  end
  
  def attempt_to_create_new_user
    user = User.create_from_omniauth!(omniauth)
    sign_in_and_redirect user unless user.nil?
  end
  
  def redirect_to_new_user_page
    session[:omniauth] = omniauth.except('extra')
    redirect_to new_user_registration_path
  end
end

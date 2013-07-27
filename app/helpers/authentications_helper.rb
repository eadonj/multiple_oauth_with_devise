module AuthenticationsHelper
  def sign_in_user(authentication)
    sign_in_and_redirect User.find(authentication.user_id)
  end

  def add_new_oauth(authentication, omni)
    token = omni['credentials'].token
    token_secret = omni['credentials'].secret
    current_user.authentications.create!(provider: omni['provider'], uid: omni['uid'], 
                                         token: token, token_secret: token_secret)
    sign_in_and_redirect current_user
  end

  def create_new_user(omni)
    user = User.new
    user.email = omni['extra']['raw_info'].email if omni['extra']['raw_info'].email
    user.apply_omniauth(omni)
    if user.save
      sign_in_and_redirect user
    elsif User.omniauth_providers.include?(omni['provider'].to_sym)
      send "#{omni['provider']}_signup", omni
    else
      redirect_to new_user_registration_path
    end
  end

  def twitter_signup(omni)
    session[:omniauth] = omni.except('extra')
    redirect_to new_user_registration_path
  end

  def after_sign_in_path_for(user)
    user_path(user)
  end

  def build_resource(*args)
    super
    @user.apply_omniauth(session[:omniauth]) if session[:omniauth]
  end
end

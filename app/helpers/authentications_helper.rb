module AuthenticationsHelper

  def signed_in?
    !!current_user
  end

  def sign_in_user(user_id)
    sign_in_and_redirect User.find(user_id)
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

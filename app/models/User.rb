class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable,
  # :lockable, and :timeoutable
  devise(
    :database_authenticatable, :registerable,
    :recoverable, :rememberable, :trackable, :validatable,
    :omniauthable, omniauth_providers: [:facebook, :twitter]
  )

  # Setup accessible (or protected) attributes for your model
  attr_accessible :email, :password, :password_confirmation, :remember_me
  
  has_many :authentications, dependent: :destroy

  def apply_omniauth(omni)

  end

  def password_required?
    authentications.empty? && super
  end

  # def facebook_credentials
  # end

  # def add_authentication

  def add_new_oauth(authentication, token, token_secret)
    token = omni['credentials'].token
    token_secret = omni['credentials'].secret
    current_user.authentications.create!(provider: omni['provider'], uid: omni['uid'], 
                                         token: token, token_secret: token_secret)
    sign_in_and_redirect current_user
  end

  def self.create_from_omniauth!(omni)
    user = new
    user.email = omni['extra']['raw_info'].email if omni['extra']['raw_info'].email
    user.authentications.build(
      provider: omni['provider'], 
      uid: omni['uid'],                    
      token: omni['credentials'].token,
      token_secret: omni['credentials'].secret
    )
    user.save ? user : nil
  end

end  

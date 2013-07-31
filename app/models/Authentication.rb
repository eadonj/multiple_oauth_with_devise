class Authentication < ActiveRecord::Base
  belongs_to :user

  attr_accessible :provider, :uid, :token, :token_secret

  def self.create_from_omniauth!(omni, user_id)
    create!(
      user_id: user_id,
      provider: omni['provider'], 
      uid: omni['uid'], 
      token: omni['credentials'].token,
      token_secret: omni['credentials'].secret
    )
  end
end

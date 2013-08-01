class Authentication < ActiveRecord::Base
  belongs_to :user

  attr_accessible :provider, :uid, :token, :token_secret

  def self.find_from_omniauth(omniauth)
    where(
      provider: omniauth['provider'],
      token: omniauth['credentials'].token,
      token_secret: omniauth['credentials'].secret
    ).first
  end

  def self.create_from_omniauth!(omniauth, user_id)
    create!(
      user_id: user_id,
      provider: omniauth['provider'], 
      uid: omniauth['uid'], 
      token: omniauth['credentials'].token,
      token_secret: omniauth['credentials'].secret
    )
  end
end

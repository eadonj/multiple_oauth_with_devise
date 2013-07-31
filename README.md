## Multiple OmniAuth for Devise

This tutorial will cover how to create a Rails app that allows users to register and sign in using a choice of multiple OmniAuth providers.  It's intended to be used any time you create a Rails app that you'd like to integrate with multiple OAuth providers.  After you get through the steps in this guide, it's on you to make the rest of your app awesome.  We're just here to start you off on the right foot.

We'll begin with the barebone basics of how to setup your Rails app, then get it working with one provider (Facebook) and finally go over how to integrate other OAuth providers into your app.



# Basic Setup

We're going to start out where every Rails app starts out: with 'rails new'.  Go ahead and run that in your terminal to create your new Rails app.

```
rails new
```

Include the Devise gem in your Gemfile.

```ruby
gem 'devise'
```

Run bundle to install the gem then run the generator, which will install an initializer that describes all Devise's configuration options.

```
bundle install
rails generate devise:install
```

You're on your own for this next one. Create a User model, including migration, controller and routes.

Once you've done that, choose one route within the User model to be your homepage -- we'd recommend users#index -- and make it so in config/routes.rb. After you've completed this tutorial, feel free to change this to any page you like.

```ruby
root to: 'users#index'
```

*Make sure to also delete the index.html file in the public folder.*

Next, add Devise to your User model and run the migration to make it official.  While you're all the way over there in terminal land, might as well add in your Devise views, too.

```
rails generate devise User
rake db:migrate
rails generate devise Views
```

That's it for basic setup.  You could technically move on to building out your app at this point, but you came here to harness the power of multiple OAuth, right?.  So, let's keep going!



# Single Provider: Facebook Example

Ok, we kind of lied just now. We'll get to multiple OAuths, but first, let's understand how you could go about connecting just one provider: Facebook. Once we've got that working, it'll just take a few more hacks to make it work for any other provider.


### Thinking Ahead: Authentications Table

While the focus of this section is Facebook, we still want to set up our app with the intention of someday allowing multiple providers.  If our plan was to use just one provider, the easiest thing to do would be to add a couple columns to our Users table that would allow us to store a user's authentication information (as discussed in the [original Devise OmniAuth wikipage](https://github.com/plataformatec/devise/wiki/OmniAuth:-Overview)).  Since our goal here is to allow a user to authenticate with multiple providers (i.e. connect both Facebook and Twitter accounts to the app), we'll have to store this info in a separate table that references the appropriate user_id in the Users table.

Create a migration file that looks something like this and then, as always, run bundle install.

```ruby
class CreateAuthenticationsTable < ActiveRecord::Migration
  def change
    create_table :authentications do |t|
      t.string :provider, :uid, :token, :token_secret
      t.references :user
    end
  end
end
```


### It's OmniAuth Time!

If you've gotten this far and haven't taken a coffee break yet, now would be a good time to do so...

First things first, add the necessary gems to your Gemfile.

```ruby
gem 'omniauth'
gem 'omniauth-facebook'
```

*Might be a good idea to run 'bundle install', too*

As of 1.0.0, Omniauth doesn't contain providers strategies anymore. So you should add the strategies as gems on your Gemfile. Generally, the gem name is "omniauth-#{provider}" where provider can be `:facebook`, `:twitter` or any other provider. For a full list, please check [Omniauth wiki](https://github.com/intridea/omniauth/wiki/List-of-Strategies).

To enable Devise's omniauthable module, edit the devise line in your User model by adding `:omniauthable` and `omniauth_providers: [:facebook]`. It should now look like this:

```ruby
devise :database_authenticatable, :registerable,
       :recoverable, :rememberable, :trackable, :validatable,
       :omniauthable, omniauth_providers: [:facebook]
```

If you navigate to your /users/sign_up page, you should now see a link to **Sign in with Facebook**.  Go ahead, pat yourself on the back or high-five your programming buddy.  Clicking that link will return some sort of JSON object. This is because we haven't yet told our app *how* to interact with Facebook.


### Get You Some Facebook Developer Action

Your next mission is to head to the [Facebook Developers](https://www.google.com/url?sa=t&rct=j&q=&esrc=s&source=web&cd=1&ved=0CE4QFjAA&url=http%3A%2F%2Fdevelopers.facebook.com%2F&ei=CrnyUd6LJKSnigKatIGICA&usg=AFQjCNFVzsdWCNvnTJQfu8XOcDUXZcAqwA&sig2=FlX0G9mec4ckuFTJ4M_Qaw&bvm=bv.49784469,d.cGE) page, set up an account (if you don't already have one) and create a new app.  The goal is to get two important pieces of information: your Facebook App ID/API Key and App Secret.

In your setup, make sure to enable the **Website with Facebook login** feature within the 'Select how your app integrates with Facebook' section. You may want to do something like this:

![alt text](http://s24.postimg.org/694ebqat1/Screen_shot_2013_07_26_at_11_07_38_AM.png)

In order to facilitate the handshake between Facebook and your app, the first step is to store your Facebook App ID and App Secret somewhere as environment variables. There are a few methods for doing so (check out this [blog post](http://railsapps.github.io/rails-environment-variables.html)). We'd recommend using the Figaro gem.

The second step is allowing your app to access those environment variables by adding the following line to your config/devise.rb file:

```ruby
config.omniauth :facebook, ENV['FACEBOOK_APP_ID'], ENV['FACEBOOK_APP_SECRET'], {scope: 'email'}
```

*Make sure that wherever you store your environment variables, you call them `FACEBOOK_APP_ID` and `FACEBOOK_APP_SECRET`.*

Now, when you click the **Sign in with Facebook** link on your /users/sign_up page, you will properly be directed to Facebook to authorize your app.  That's what we call a handshake!  Once you authorize your app to communicate with Facebook, you'll be directed back to your app where... you'll see an 'Unknown action' error.  Womp womp.  Read the error message -- it might be helpful.  Then continue on, my friend.


### Almost There: Configuring Your App to Communicate with Facebook

According to the aforementioned error message, we need to create an Authentications Controller (i.e. Devise::OmniauthCallbacksController) and Facebook method in order to allow our app to communicate with Facebook.  Get ready to do some heavy copy/pasting, but don't worry, we'll explain everything in detail later.

#### The Code

Create your authentications_controller.rb that includes a Facebook method:

```ruby
class AuthenticationsController < Devise::OmniauthCallbacksController
  include AuthenticationsHelper

  def facebook
    omni = request.env['omniauth.auth']
    authentication = Authentication.find_by_provider_and_uid(omni['provider'], omni['uid'])
    if authentication
      sign_in_user(authentication)
    elsif current_user
      add_new_oauth(authentication, omni)
    else
      create_new_user(omni)
    end
  end
end
```

Create your authentications_helper.rb file in the Helper folder with the following methods (notice in the controller above that this module is included and these methods are being called):

```ruby
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
    else
      redirect_to new_user_registration_path
    end
  end

  def after_sign_in_path_for(user)
    user_path(user)
  end
end
```

Add the following methods to your User model:

```ruby
class User < ActiveRecord::Base
  .
  .
  .
  def apply_omniauth(omni)
    user.authentications.build(provider: omni['provider'], uid: omni['uid'],
                          token: omni['credentials'].token,
                          token_secret: omni['credentials'].secret)
  end
  
  def password_required?
    authentications.empty? && super
  end
end
```

#### The Explanation
Explain what's happening in detail...
- Create an AuthenticationsController that inherits from Devise::OmniauthCallbacksController
- Edit the 'devise_for :users' line in config/routes to the following: 'devise_for :users, controllers: {:omniauth_callbacks => 'authentications'}'
- Create def facebook method in AuthenticationsController (same as def all method --> just copy paste for now and explain later) --> also involves creating Authentications Helper and adding apply_omniauth and password_required? methods to User model --> remove Twitter logic from methods for now 

1. Add Authentication model and add 'belongs_to: :user' association. Make attr_accessible :provider, :uid, :token, :token_secret
2. Add 'has_many: :authentications, dependent: :destroy' to User model

### Twitter

Explain why process is different --> twitter does not pass back email address

1. add gem 'omniauth-twitter' + bundle install
2. edit Devise line in User model to include twitter
3. get twitter env variables
4. set env variables in config/devise.rb
5. auth controller --> switch def facebook to def all and add alias methods for facebook and twitter
6. auth_helper --> add elsif line that takes in any provider
7. auth_helper --> add twitter_signup(omni) method
8. auth_helper --> add build_resource method
9. create registrations controller -> include Authentications Helper
10. routes.rb --> add `registrations: 'registrations'` to devise_for line
11. views/devise/registrations/new --> add if statement for session[:omniauth]

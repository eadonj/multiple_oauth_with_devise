require 'spec_helper'

describe AuthenticationsController do

  let(:omniauth){ double(:omniauth) }

  let(:user){ 
    User.create!(
      email: 'test.user@example.com',
      password: 'password',
    )
  }

  before do
    # @request.env["devise.mapping"] = Devise.mappings[:user]
    request.env["devise.mapping"] = Devise.mappings[:user]
    request.env['omniauth.auth'] = omniauth
  end

  before do
    expect(Authentication).to receive(:find_from_omniauth). \
      with(omniauth). \
      and_return(authentication_find_result)
  end


  describe "GET :facebook" do

    context "when a matching authentication is found" do
      let(:authentication){ double(:authentication, user_id: user.id) }
      let(:authentication_find_result){ authentication }

      it "should sign in the user for that authentication and redirect" do
        expect(User).to receive(:find).with(user.id).and_return(user)
        get :facebook
        expect(subject.current_user).to eq user
        expect(response).to redirect_to user_url(user)
      end
    end

    context "when a matching authentication is not found" do
      let(:authentication_find_result){ nil }

      context "when we are logged in" do
        before do
          sign_in user
        end

        it "should add a new authentication to the current user" do
          User.any_instance.should_receive(:add_new_authentication_from_omniauth).with(omniauth)
          get :facebook
          expect(subject.current_user).to eq user
          expect(response).to redirect_to user_url(user)
        end

      end

      context "when we are not logged in" do

        before do
          expect(User).to receive(:create_from_omniauth!).with(omniauth).and_return(user_create_return_value)
        end
        context "when a new user is created" do
          let(:user_create_return_value){ user }
          it "should sign in as the new user and redirect to that users page" do
            get :facebook
            expect(subject.current_user).to eq user
            expect(response).to redirect_to user_url(user)
          end

        end

        context "when a new user fails to be created" do
          let(:token){ 'SOME FAKE TOKEN' }
          let(:token_secret){ 'TOKEN SECRET WHATEVER' }
          let(:user_create_return_value){ nil }
          it "save the omniauth in the session and redirect to the new user registration path" do
            credentials = double(token: token, secret: token_secret)
            omniauth.stub(:[] => credentials)

            get :facebook
            expect(subject.current_user).to eq nil
            expect(session[:omniauth]).to eq({
              token: token,
              token_secret: token_secret,
            })
            expect(response).to redirect_to new_user_registration_path
          end
        end

      end
    end

  end

end

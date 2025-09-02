class AuthController < ApplicationController
  skip_before_action :authenticate_user!, only: [:sign_in]
  
  def sign_in
    user = User.find_by(email: params[:email])
    
    if user&.authenticate(params[:password])
      session = Session.create_for_user(user)
      render_success({
        token: session.token,
        expires_at: session.expires_at,
        user: {
          id: user.id,
          email: user.email
        }
      })
    else
      render_error('Invalid email or password', :unauthorized)
    end
  end
  
  def sign_out
    session = Session.find_by(token: request.headers['Authorization']&.split(' ')&.last)
    session&.destroy
    render_success({ message: 'Signed out successfully' })
  end
  
  def profile
    render_success({
      user: {
        id: current_user.id,
        email: current_user.email,
        balance: current_user.balance.format
      }
    })
  end
end

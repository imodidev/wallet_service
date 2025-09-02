class ApplicationController < ActionController::API
  before_action :authenticate_user!
  
  private
  
  def authenticate_user!
    token = request.headers['Authorization']&.split(' ')&.last
    return render_unauthorized unless token
    
    session = Session.find_by(token: token)
    return render_unauthorized unless session&.active?
    
    @current_user = session.user
  end
  
  def current_user
    @current_user
  end
  
  def render_unauthorized
    render json: { error: 'Unauthorized' }, status: :unauthorized
  end
  
  def render_error(message, status = :unprocessable_entity)
    render json: { error: message }, status: status
  end
  
  def render_success(data = {}, status = :ok)
    render json: data, status: status
  end
end

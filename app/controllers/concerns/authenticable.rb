module Authenticable

  # Devise methods overwrites
  def current_user
    @current_user ||= User.find_by(auth_token: request.headers['Authorization'])
    # HACK: Because of what ember sends by defayult, i can't change it now
    @current_user ||= User.find_by(auth_token: request.headers['Authorization'].split("\"")[1])
  end

  def authenticate_with_token!
    render json: { errors: "Not authenticated" }, status: :unauthorized unless user_signed_in?
  end

  def user_signed_in?
    current_user.present?
  end  
end
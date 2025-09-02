module ApiHelpers
  def auth_headers(user = nil)
    user ||= create(:user)
    session = Session.create_for_user(user)
    { 'Authorization' => "Bearer #{session.token}" }
  end
  
  def json_response
    JSON.parse(response.body)
  end
  
  def expect_success_response
    expect(response).to have_http_status(:success)
  end
  
  def expect_error_response(status = :unprocessable_entity)
    expect(response).to have_http_status(status)
    expect(json_response).to have_key('error')
  end
end

module ApiSupport
  include Rack::Test::Methods

  def app
    App::API
  end

  def last_json
    ActiveSupport::HashWithIndifferentAccess.new(
      MultiJson.load(last_response.body)
    )
  end

  def login(user)
    get("/v1/cheat/login/#{user.id}")
  end

  def get_json(path, user = nil)
    get(path)
  end
end

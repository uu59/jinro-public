module App
  class Auth < Sinatra::Base
    enable :inline_templates

    get "/token" do
      token = request.cookies["session_id"]
      if false && Session.active.exists?(unique_id: token)
        token
      else
        halt 404, ""
      end
    end

    get "/logout" do
      sess_id = request.cookies[App.session_id]
      Session.find_by(unique_id: sess_id).destroy
      redirect request.referer || "/"
    end

    get "/cheat/:user_id" do
      halt 403 if App.env != :development
      session = Session.create(body: {user_id: params[:user_id]})
      response.set_cookie(
        App.session_id,
        value: session.unique_id,
        path: "/", httponly: true
      )
      redirect request.referer || "/"
    end

    get "/:provider/callback" do
      result = request.env['omniauth.auth']
      account = ExternalAccount.register(result)
      app_session = Session.create(body: {user_id: account.user.id})
      response.set_cookie(
        App.session_id,
        value: app_session.unique_id,
        path: "/", httponly: true
      )
      # session.clear
      redirect request.env["omniauth.origin"]
      # erb "<a href='/'>Top</a><br>
      #    <h1>#{params[:provider]}</h1>
      #    <pre>#{JSON.pretty_generate(result)}</pre>"
    end
  end
end

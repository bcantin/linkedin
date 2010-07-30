# assuming you are using bundler...

## Gemfile
  gem 'linkedin'

# your controller to interact with the gem and their API
class AuthController < ApplicationController

  def index
    # get your api keys at https://www.linkedin.com/secure/developer
    client = LinkedIn::Client.new("your_api_key", "your_secret")
    request_token = client.request_token(:oauth_callback => 
                                      "http://#{request.host_with_port}/auth/callback")
    session[:rtoken] = request_token.token
    session[:rsecret] = request_token.secret

    redirect_to client.request_token.authorize_url
  end

  def callback
    client = LinkedIn::Client.new("your_api_key", "your_secret")
    if session[:atoken].nil?
      pin = params[:oauth_verifier]
      atoken, asecret = client.authorize_from_request(session[:rtoken], session[:rsecret], pin)
      session[:atoken] = atoken
      session[:asecret] = asecret
    else
      client.authorize_from_access(session[:atoken], session[:asecret])
    end
    @profile = client.profile
    @connections = client.connections
  end
  
end

# So the flow your user sees is this:
# 
#     * visit /auth/ which automatically redirects me to log in via LinkedIn
#     * type in my LinkedIn user name and password, click submit
#     * submitting takes me to /auth/callback which might show my profile and connections
# 
# What the code does:
# 
#     * creates a new LI client based on your credentials as a LinkedIn developer
#     * get a request token (pay attention, there's 2 kinds) , and sets the callback to your callback action
#     * saves off the request token-token and the request token-secret into the session, you'll need to reconstruct the request token in the callback, and the request token itself doesn't have a marshal-load method defined.
#     * sends the user off to the LinkedIn log in page --- user logs in and is send to the callback action ---
#     * create a new LI client with the developer key and secret from LinkedIn
#     * check to see if the access token (2nd kind of token) has been created before
#     * create the access token using the oauth_verifier sent from LinkedIn and the old request token (1st kind) that you save in the session.
#     * authorize the client and save off the access token info so you don't have to send your user back to LI when he comes back (*here I save the access token into the session for simplicity in the example, you should put this in a database probably)
#     * if the access token exists, just authorize the client usoing the access token
#     * finally, use the client to do interesting things like show the user his profile and his connections.

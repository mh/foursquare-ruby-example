require 'rubygems'
require 'sinatra'
gem 'oauth2', '=0.4.1'
require 'oauth2'
require 'json'
require 'net/https'

# as found on https://foursquare.com/oauth/
CLIENT_ID = your_client_id
CLIENT_SECRET = your_client_secret
CALLBACK_PATH = '/auth/foursquare/callback'

def client
    OAuth2::Client.new(CLIENT_ID, CLIENT_SECRET, 
      :site => 'http://foursquare.com/v2/',
      :request_token_path => "/oauth2/request_token",
      :access_token_path  => "/oauth2/access_token",
      :authorize_path     => "/oauth2/authenticate?response_type=code",
      :parse_json => true
    )
end

get '/auth/foursquare/callback' do
  # access_token = client.web_server.get_access_token(params[:code], :redirect_uri => redirect_uri)
  # It would be better to use the line above but it returns a 301 error, so I use the hack below instead.
  
  # start hack
  uri = URI.parse("https://foursquare.com/oauth2/access_token?client_id=#{CLIENT_ID}&client_secret=#{CLIENT_SECRET}&grant_type=authorization_code&redirect_uri=#{redirect_uri}&code=" + params[:code])
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  http.verify_mode = OpenSSL::SSL::VERIFY_NONE
  
  request = Net::HTTP::Get.new(uri.request_uri)
  response = JSON.parse(http.request(request).body)
  access_token = OAuth2::AccessToken.new(client, response["access_token"])
  # end hack
  
  # some user data as an example
  user = access_token.get('https://api.foursquare.com/v2/users/self')
  user.inspect
end

def redirect_uri()
  uri = URI.parse(request.url)
  uri.path = CALLBACK_PATH
  uri.query = nil
  uri.to_s
end

get '/' do
  redirect client.web_server.authorize_url(:redirect_uri => redirect_uri)
end

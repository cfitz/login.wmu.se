# Sample app for Google OAuth2 Strategy
# Make sure to setup the ENV variables GOOGLE_KEY and GOOGLE_SECRET
# Run with "bundle exec rackup"

require 'rubygems'
require 'bundler'
require 'sinatra'
require 'omniauth'
require 'omniauth-google-oauth2'
require 'digest'
# Do not use for production code.
# This is only to make setup easier when running through the sample.
#
# If you do have issues with certs in production code, this could help:
# http://railsapps.github.io/openssl-certificate-verify-failed.html
#OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE

class App < Sinatra::Base
  get '/' do
      
    unless request["ez"].nil? 
      session[:return_to] = request['ez'] 
      redirect to('/auth/google_oauth2')
    end 
      
    <<-HTML
    <ul>
      <li><a href='/auth/google_oauth2'>Sign in with Google</a></li>
    </ul>
    HTML
  end

  get '/auth/:provider/callback' do
    email = request.env['omniauth.auth'].info.email rescue "No Data"
    
    unless /^[a-zA-Z]+@wmu\.se$/.match email 
      halt "You must login with a current WMU email address"
    end
    
    key = ENV["EZPROXY_KEY"]
    packet = "$u#{Time.now.to_i}$e"
    ticket = "#{key}#{email}#{packet}"  
    ticket = Digest::MD5.hexdigest ticket 
    ticket << packet

    url = "https://login.proxy.wmu.se/login?user=#{email}&ticket=#{ticket}&"
    unless session[:return_to].nil?
      url << "url=#{session[:return_to]}" 
    end
    redirect to(url)
  end
  

  get '/auth/failure' do
    content_type 'text/plain'
    request.env['omniauth.auth'].to_hash.inspect rescue "No Data"
  end
end

use Rack::Session::Cookie, :secret => ENV['RACK_COOKIE_SECRET']

use OmniAuth::Builder do
  # For additional provider examples please look at 'omni_auth.rb'
  provider :google_oauth2, ENV['GOOGLE_KEY'], ENV['GOOGLE_SECRET'], {}
end

run App.new

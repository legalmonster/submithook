require 'sinatra'
require 'sinatra/reloader' if development?
require 'net/http'
require 'json'
require 'sidekiq'
require 'sidekiq/api'
require 'redis'
require 'rack/ssl-enforcer'

use Rack::SslEnforcer if production?

Sidekiq.configure_client do |config|
  config.redis = { url: ENV['REDIS_URL'] }
end

$redis = Redis.new( url: ENV['REDIS_URL'] )

class App < Sinatra::Application
  get '/' do
    erb :index
  end

  get '/demo' do
    erb :demo
  end

  post '/' do
    webhook_url = params[:webhook]
    redirect_url = params[:redirect]

    params.delete(:webhook)
    params.delete(:redirect)

    payload = params.to_json

    DeliverWebhook.perform_async(webhook_url, payload)

    redirect redirect_url
  end

  class DeliverWebhook
    include Sidekiq::Worker

    def perform(webhook_url,payload)
      uri = URI.parse(webhook_url)

      request = Net::HTTP::Post.new(uri.request_uri)
      request['Content-Type'] = 'application/json'
      request.body = payload

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = (uri.scheme == 'https')

      http.request(request)
    end
  end
end

require 'sinatra'
require 'sinatra/reloader' if development?
require 'net/http'
require 'json'
require 'sidekiq'
require 'sidekiq/api'
require 'redis'

Sidekiq.configure_client do |config|
  config.redis = { url: "redis://#{ENV['REDIS_HOST']}:#{ENV['REDIS_PORT']}" }
end

$redis = Redis.new( url: "redis://#{ENV['REDIS_HOST']}:#{ENV['REDIS_PORT']}" )

class App < Sinatra::Application
  get '/' do
    erb :index
  end

  post '/post' do
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

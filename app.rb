require 'sinatra'
require 'net/http'
require 'json'
require 'sinatra/reloader' if development?

get '/' do
  erb :index
end

post '/post' do
  webhook_url = params[:webhook]
  redirect_url = params[:redirect]

  params.delete(:webhook)
  params.delete(:redirect)

  payload = params.to_json

  request_webhook(webhook_url, payload)

  redirect redirect_url
end

def request_webhook(webhook_url, payload)
  uri = URI.parse(webhook_url)

  request = Net::HTTP::Post.new(uri.request_uri)
  request['Content-Type'] = 'application/json'
  request.body = payload

  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = (uri.scheme == 'https')

  http.request(request)
end

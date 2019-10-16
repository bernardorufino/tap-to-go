require 'sinatra'
require 'sinatra/reloader' if development?

class Server < Sinatra::Base
  get "/" do
    "Hello world!"
  end
end


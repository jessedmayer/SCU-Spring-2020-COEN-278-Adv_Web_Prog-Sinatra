
# test2.rb
require 'sinatra'

get '/:age' do
  "Hi, I'm #{params[:age]} years old."
end

#go to http://localhost:4567/33 for result
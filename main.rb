require 'sinatra'
require 'data_mapper' #includes dm-core and dm-migrations
enable :sessions

configure :development do
  DataMapper.setup(:default,"sqlite3://#{Dir.pwd}/gamblers.db")
end

configure :production do
  DataMapper.setup(:default, ENV['DATABASE_URL'])
end

#creates model (table will be called in plural)
class User_data
  include DataMapper::Resource #mixin
  #property :ID, Serial
  property :User, String, :key => true
  property :Password, String
  property :total_win, Integer
  property :total_loss, Integer
  property :total_profit, Integer
end
DataMapper.finalize
DataMapper.auto_upgrade!


User_data.create(User: 'admin', Password: 'admin', total_win: 0, total_loss: 0, total_profit: 0)
#@init_user = User_data.get('admin')
#unless @init_user.User == params[:Username] && @user.Password == params[:Password]
#@init_user = User_data.create(User: 'admin', Password: 'admin', total_win: 0, total_loss: 0, total_profit: 0)
#@init_user.save
#end


get '/login' do
  erb :login
end

#if credentials are correct initializes session values from database gamblers.db
post '/login' do
  @user=User_data.get(params[:Username])
  if @user.User==params[:Username] && @user.Password==params[:Password]
    session[:admin]=true # mark as logged in\
    session[:Username]=params[:Username]
    session[:session_win]=0
    session[:session_loss]=0
    session[:session_profit]=0
    session[:total_win]=@user.total_win
    session[:total_loss]=@user.total_loss
    session[:total_profit]=@user.total_profit
    session[:roll]=0
    redirect :betting
  else
    erb :login
  end
end

get '/betting' do
  halt(401, 'Not Authorized') unless session[:admin]==true  #does not allow access unless logged in
  erb :betting
end

post '/betting' do
  stake = params[:stake].to_i
  number = params[:number].to_i
  roll = rand(6) + 1
  session[:roll] = roll   #saves roll so it can be displayed using bet_lost and bet_won partial views
  if number == roll
    session[:session_win] += (0.9*stake).to_i
    session[:total_win] += (0.9*stake).to_i
    session[:session_profit] = session[:session_win]-session[:session_loss]
    session[:total_profit] = session[:total_win]-session[:total_loss]
    erb :betting, :layout => :bet_won   #bet_won partial view tells user what was rolled and that they won
  else
    session[:session_loss] += stake
    session[:total_loss] += stake
    session[:session_profit] = session[:session_win]-session[:session_loss]
    session[:total_profit] = session[:total_win]-session[:total_loss]
    erb :betting, :layout => :bet_lost  #bet_lost partial view tells user what was rolled and that they lost
  end
end

get '/logout' do
  @user=User_data.get(session[:Username])
  #updates database values for user to include wins, losses, and profit from this session
  @user.update(total_win: session[:total_win], total_loss: session[:total_loss], total_profit: session[:total_profit])
  session.clear #clears all session values
  redirect :login
end
require 'rubygems'
require 'sinatra'
require 'pry'
require "sinatra/reloader" if development?

set :sessions, true

def calculate_total(cards)
  # [['H', '3'], ['S', 'Q'], ... ]
  arr = cards.map{|e| e[1] }

  total = 0
  arr.each do |value|
    if value == "A"
      total += 11
    elsif value.to_i == 0 # J, Q, K
      total += 10
    else
      total += value.to_i
    end
  end

  #correct for Aces
  arr.select{|e| e == "A"}.count.times do
    total -= 10 if total > 21
  end

  total
end


helpers do
  def new_deck
    suits = ['H', 'D', 'S', 'C']
    cards = ['2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K', 'A']

    deck = suits.product(cards)
    deck.shuffle!
  end

  def calculate_total(cards)
      # [['H', '3'], ['S', 'Q'], ... ]
      arr = cards.map{|e| e[1] }

      total = 0
      arr.each do |value|
        if value == "A"
          total += 11
        elsif value.to_i == 0 # J, Q, K
          total += 10
        else
          total += value.to_i
        end
      end

      #correct for Aces
      arr.select{|e| e == "A"}.count.times do
        total -= 10 if total > 21
      end

      total
    end
  end
#route that renders text in the browser
get '/home' do
  'Welcome Home!'
end

#route that renders a template
get '/users' do
  erb :users
end


#route that renders a nested template
get '/groceries' do
  erb :'/misc/groceries'
end

get '/bet' do
  erb :bet
end

get '/game' do
  session[:player_cards] = []
  session[:dealer_cards] = []
  session[:deck] = new_deck
  session[:player_cards] << session[:deck].pop
  session[:dealer_cards] << session[:deck].pop
  session[:player_cards] << session[:deck].pop
  session[:dealer_cards] << session[:deck].pop
  session[:player_total] = calculate_total(session[:player_cards])
  erb :game
end

#get '/' do
#  erb :new_game
#  #redirect '/new_game'
#end
get '/' do
  if session[:username]
    redirect '/game'
  else
    redirect '/new_game'
  end
end

get '/new_game' do
  erb :clear_sessions
#  #redirect '/'
  erb :new_game
end

#get '/new_game' do
#  if session[:username]
#    redirect '/game'
#  else
#    erb :new_game
#  end
#end

post '/new_game' do
  session[:username] = params[:username]
  #erb :new_game
  redirect '/game'
end

post '/game/player/hit' do
  session[:player_cards] << session[:deck].pop
  session[:player_total] = calculate_total(session[:player_cards])
  erb :game
end

post '/game/player/stay' do
  erb :game
end

get '/game_over' do
  erb :game_over
end







require 'rubygems'
require 'sinatra'
require 'pry'
require "sinatra/reloader" if development?

set :sessions, true

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

  def display_cards(cards)
    suit = case cards[0]
      when 'C'
        'clubs'
      when 'D'
        'diamonds'
      when 'H'
        'hearts'
      when 'S'
        'spades'
    end

    card = case cards[1]
      when 'K'
        'king'
      when 'Q'
        'queen'
      when 'J'
        'jack'
      when 'A'
        'ace'
      else
         cards[1]
    end
    "#{suit}_#{card}.jpg"
  end
end

before do
  @show_hit_or_stay_buttons = true
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
  session[:dealer_cards_suit] = []
  session[:deck] = new_deck
  session[:player_cards] << session[:deck].pop
  session[:dealer_cards] << session[:deck].pop
  #session[:dealer_cards_suit] << display_cards(session[:dealer_cards])
  session[:player_cards] << session[:deck].pop
  session[:dealer_cards] << session[:deck].pop
  session[:dealer_cards_suit] << display_cards(session[:dealer_cards])
  session[:dealer_total] = calculate_total(session[:dealer_cards])
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
  erb :new_game
end

post '/new_game' do
  if params[:username].empty?
    @error = "Name must be supplied."
  end
  halt(erb :new_game)

  session[:username] = params[:username]
  redirect '/game'
end

post '/game/player/hit' do
  #session[:player_cards] << session[:deck].pop
  #session[:player_total] = calculate_total(session[:player_cards])
  #erb :game
  session[:player_cards] << session[:deck].pop
  player_total = calculate_total(session[:player_cards])
  if player_total == 21
    @success = 'Congratulations you hit blackjack!'
    @show_hit_or_stay_buttons = false
  elsif player_total > 21
    @error = "You busted. Got #{calculate_total(session[:player_cards])}!"
    @show_hit_or_stay_buttons = false
  end
  erb :game
end

#get '/game/player/stay' do
#  session[:dealer_total] = calculate_total(session[:dealer_cards])
#
#  while session[:dealer_total] < 17
#    session[:dealer_cards] << session[:deck].pop
#    session[:dealer_total] = calculate_total(session[:dealer_cards])
#    erb :game
#  end
#end

post '/game/player/stay' do
  @success = "You have chosen to stay"
  @show_hit_or_stay_buttons = false
  session[:dealer_total] = calculate_total(session[:dealer_cards])

  while session[:dealer_total] < 17
    session[:dealer_cards] << session[:deck].pop
    session[:dealer_total] = calculate_total(session[:dealer_cards])
    #erb :game
  end
  erb :game

  #if session[:dealer_total] > 21
  #  "Dealer busted #{session[:dealer_total]}."
  #  erb :game
  #else
  #  "Dealer: #{session[:dealer_total]} vs. #{session[:username]}: #{session[:player_total]}"
  #  erb :game
  #end
end

get '/game_over' do
  erb :game_over
end







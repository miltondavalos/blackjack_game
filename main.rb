require 'rubygems'
require 'sinatra'
require 'pry'
#require "sinatra/reloader" if development?

set :sessions, true

BLACKJACK_AMOUNT = 21
DEALER_STAY_AMOUNT = 17
INITIAL_AMT = 500

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
  @show_dealers_next_card_button = false
  @hide_first_card = true
  @play_again = false
  @show_message = true
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

post '/bet' do
  bet = params[:bet]
  if bet.to_i == 0 || bet.nil?
    @error = "Please make a bet!"
    halt(erb :bet)
  elsif bet.to_f > session[:bet_left].to_f
    @error = "Your bet of $#{bet} is more than you current balance $#{session[:bet_left]}."
    halt(erb :bet)
  else
    session[:bet] = bet
    redirect '/game'
  end
end

get '/game' do
  #session[:bet] = params[:bet]
  session[:player_cards] = []
  session[:dealer_cards] = []
  session[:deck] = new_deck
  session[:player_cards] << session[:deck].pop
  session[:dealer_cards] << session[:deck].pop
  session[:player_cards] << session[:deck].pop
  session[:dealer_cards] << session[:deck].pop
  session[:dealer_total] = calculate_total(session[:dealer_cards])
  session[:player_total] = calculate_total(session[:player_cards])
  erb :game
end

get '/' do
  if session[:username]
    redirect '/game'
  else
    redirect '/new_game'
  end
end

get '/new_game' do
  erb :clear_sessions
  session[:bet_left] = INITIAL_AMT
  erb :new_game
end

post '/new_game' do
  if params[:username].empty?
    @error = "Name must be supplied."
    halt(erb :new_game)
  else
    if !params[:username].match(/^[a-zA-Z\-\s]*$/)
      @error = "Please provide an alphabetic name."
      halt(erb :new_game)
    end
  end

  session[:username] = params[:username]
  #redirect '/game'
  redirect '/bet'
end

post '/game/player/hit' do
  session[:player_cards] << session[:deck].pop
  player_total = calculate_total(session[:player_cards])
  if player_total == BLACKJACK_AMOUNT
    @winner = 'Congratulations you hit blackjack!'
    session[:bet_left] = session[:bet_left].to_f + session[:bet].to_f
    @show_hit_or_stay_buttons = false
    @show_message = false
    @play_again = true
  elsif player_total > BLACKJACK_AMOUNT
    @loser = "You busted. Got #{calculate_total(session[:player_cards])}!. Dealer #{session[:dealer_total]}"
    session[:bet_left] = session[:bet_left].to_f - session[:bet].to_f
    @show_hit_or_stay_buttons = false
    @show_message = false
    @play_again = true
  end
  erb :game, layout: false
end

post '/game/player/stay' do
  @winner = "You have chosen to stay"
  @show_hit_or_stay_buttons = false
  @hide_first_card = false
  dealer_total = calculate_total(session[:dealer_cards])

  if dealer_total >= DEALER_STAY_AMOUNT
    redirect '/game/dealer/stay'
  else
    @show_dealers_next_card_button = true
    erb :game, layout: false
  end


  #erb :game
end

post '/game/dealer/hit' do
  @show_hit_or_stay_buttons = false
  @hide_first_card = false
  session[:dealer_cards] << session[:deck].pop

  dealer_total = calculate_total(session[:dealer_cards])

  if dealer_total >= DEALER_STAY_AMOUNT
    redirect '/game/dealer/stay'
  else
    @show_dealers_next_card_button = true
    erb :game, layout: false
  end
end

get '/game/dealer/stay' do
  @show_hit_or_stay_buttons = false
  @hide_first_card = false

  dealer_total = calculate_total(session[:dealer_cards])
  player_total = calculate_total(session[:player_cards])

  if player_total <= dealer_total && dealer_total < BLACKJACK_AMOUNT
    @loser = "You lose!. Dealer got #{dealer_total}! and you #{player_total}!"
    session[:bet_left] = session[:bet_left].to_f - session[:bet].to_f
    @show_message = false
  elsif dealer_total == BLACKJACK_AMOUNT
    @loser = 'You lose!. Dealer hit Blackjack!'
    session[:bet_left] = session[:bet_left].to_f - session[:bet].to_f
    @show_message = false
  elsif dealer_total == player_total
    @info = "It is a tie!. Dealer got #{dealer_total}! and you #{player_total}!"
    @show_message = false
  elsif dealer_total > BLACKJACK_AMOUNT
    @info = "You win!. Dealer got #{dealer_total}! and you #{player_total}!"
    session[:bet_left] = session[:bet_left].to_f + session[:bet].to_f
    @show_message = false
  end

  @play_again = true

  erb :game
end

get '/play_again' do
  if session[:bet_left].to_f > 0
    redirect '/bet'
  else
    erb :broke
  end
end

get '/game_over' do
  erb :game_over
end

get '/broke' do
  erb :broke
end







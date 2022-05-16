require 'sinatra'
require 'slim'
require 'sqlite3'
require 'bcrypt'

require_relative 'model'

enable :sessions

include Model

# Attempts to check if the client has authorization
#
before do
  
  #inloggag
  if (session[:inloggad] == nil || session[:inloggad] == false) && (request.path_info != '/login' &&request.path_info != '/error' && request.path_info != '/' && request.path_info != '/users/login' && request.path_info != '/register' && request.path_info != '/users/new')
    redirect('/error')
  end

  #admin
  if (session[:authority] == nil || session[:authority] == false) && (request.path_info == '/delete_users')
    redirect('/error')
  end
end

# Display Landing Page
#
get('/') do 
  slim(:start)
end

# Displays register form
#
get('/register') do #visa registreringssidan
  slim(:register)
end

# Displays login form
#
get ('/login') do 
  slim(:login)
end

# Attempts to logout user
#
get ('/loggaut') do  
  session[:empty] = false
  session[:stress] = false
  session[:badname] = false
  session[:inloggad] = false
  session[:authority] = false
  session[:false_img] = false
  session[:wrong_psw] = false
  session[:wrong_type] = false
  session[:wrong_creator_id] = false
  session[:no_unique_digname] = false
  session[:no_unique_username] = false
  redirect('/')
end

# Displays a new post form
#
# @see Model#types
get("/cards/new") do
  types = types(false)
  slim(:"digimon/new", locals: {types: types})
end

# Display users own cards
#
# @see Model#result
get('/egna') do #visa bara användarens #följer jag rest?(user/:id/cards)
  result = result(session[:user_id])
  slim(:"digimon/mine", locals:{dig:result})
end

# Displays all cards
#
# @see Model#all_dig
get('/cards') do #visa alla  
  result = all_dig(true)
  slim(:"digimon/index", locals:{dig:result})
end

# Displays a edit post form
#
#@see Model#types
get("/cards/:id/edit") do #visa edit formuläret
  types = types(false)
  slim(:"digimon/edit", locals: {types: types,})
end

# Attempts to register new user
#
# @param [String] :password, The new users password
# @param [String] :password_confirm, The password confirm
# @param [Integer] :username, The new users username
# @see Model#spamtime
# @see Model#isEmpty
# @see Model#wrong_psw
# @see Model#no_unique_user
# @see Model#make_user
post('/users/new') do#registrerara användare.
  session[:empty] = false
  session[:stress] = false
  session[:badname] = false
  session[:inloggad] = false
  session[:false_img] = false
  session[:wrong_psw] = false
  session[:wrong_type] = false
  session[:no_unique_username] = false
  session[:no_unique_digname] = false

  username = params[:username]
  password = params[:password]
  password_confirm = params[:password_confirm]
  
  #cooldown till #spammar register
  if session[:timeLogged] == nil #first time
    session[:timeLogged] = 0
  end

  spam =  spamtime(session[:timeLogged])
  session[:timeLogged] = Time.now.to_i #for next possible itteration

  if spam #spammar registre
    session[:stress] = true
    redirect('/register')
  end

  if isEmpty(username) || isEmpty(password)
    session[:empty]=true
    redirect('/register')
  end

  if wrong_psw(password, password_confirm)
    session[:wrong_psw] = true #säg att lösenordet var fel
    redirect('/register')
  end

  if no_unique_user(username)
    session[:no_unique_username]=true
    redirect('/register')
  end

  make_user(username, password)
  redirect('/login')
end

# Attempts to login user
#
# @param [String] :password, The users password
# @param [Integer] :username, The users username
#
# @see Model#spamtime
# @see Model#isEmpty
# @see Model#bad_psw
# @see Model#no_unique_user
# @see Model#allfromUsername
post('/users/login') do #logga in användare

  session[:empty] = false
  session[:stress] = false
  session[:badname] = false
  session[:false_img] = false
  session[:wrong_psw] = false
  session[:wrong_type] = false
  session[:no_username] = false
  session[:wrong_creator_id] = false
  session[:no_unique_digname] = false
  session[:no_unique_username] = false

  username=params[:username]
  password=params[:password]

  #cooldown till #spammar loggin
  if session[:timeLogged] == nil #first time
    session[:timeLogged] = 0
  end

  spam =  spamtime(session[:timeLogged])
  session[:timeLogged] = Time.now.to_i #for next possible itteration

  if spam #spammar loggin
    session[:stress] = true
    redirect('/login')
  end

  if isEmpty(username) || isEmpty(password)#tomt användarnamn
    session[:empty] = true
    redirect('/login')
  end

  if allfromUsername(username, false).empty? # användarnamn som inte finns
    session[:no_username] = true
    redirect('/login')
  end

  user = allfromUsername(username, true).first

  if user["authority"].to_i==2
    session[:authority]=true
  end

  if bad_psw(password, user)
    session[:wrong_psw] = true
    redirect('/login')
  end

  session[:user_id] = user["id"]
  
  session[:inloggad]=true
  redirect('/')
end

# Creates a new card
#
# @param [String] :digname, The card title
# @param [Intiger] :creator_id, The creators id
# @param [Sinatra::IndifferentHash] :creature_img, The creature img
# @param [String] :creature_type, The creature type
#
# @see Model#spamtime
# @see Model#false_img
# @see Model#isEmpty
# @see Model#badname
# @see Model#no_unique_name
# @see Model#wrong_type
# @see Model#write_img
# @see Model#create
post('/cards') do #gör kort 
  session[:empty] = false
  session[:stress] = false
  session[:badname] = false
  session[:false_img] = false
  session[:wrong_psw] = false
  session[:wrong_type] = false
  session[:wrong_creator_id] = false
  session[:no_unique_digname] = false
  session[:no_unique_username] = false

  digname= params[:diginame]
  creator_id= session[:user_id]
  creature_img=params[:image]
  creature_type=params[:type]


  #cooldown till #spammar kort
  if session[:timeLogged] == nil #first time
    session[:timeLogged] = 0
  end
  spam =  spamtime(session[:timeLogged])
  session[:timeLogged] = Time.now.to_i #for next possible itteration

  if spam #spammar kort
    session[:stress] = true
    redirect('/cards/new')
  end

  #felaktig img
  if false_img(creature_img)
    session[:false_img] = true
    redirect('/cards/new')
  end
 #tomt namn
  if isEmpty(digname)
    session[:empty] = true
    redirect('/cards/new')
  end

  #felaktigt namn
  if badname(digname)
    session[:badname] = true
    redirect('/cards/new')
  end

  #unikt namn på kort
  if no_unique_name(digname)
    session[:no_unique_digname] = true
    redirect('/cards/new')
  end

  #felaktig typ
  if wrong_type(creature_type)
    session[:wrong_type] = true
    redirect('/cards/new')
  end

  temp_path = creature_img[:tempfile]
  img_path = "/uploads/#{creature_img[:filename]}"

  # Write file to disk
  write_img(img_path, temp_path)
  
  #make card
  create(session[:user_id], params[:diginame], img_path, params[:type])
  redirect('/cards')
end

# Updates an existing post
#
# @param [Integer] :id, The card id
# @param [String] :diginame_new, The new cardname
# @param [String] :type_new, The new type
#
# @see Model#spamtime
# @see Model#badname
# @see Model#wrong_type
# @see Model#isEmpty
# @see Model#no_unique_name
# @see Model#no_card_has_id
# @see Model#owner
# @see Model#update
post("/cards/:id/update") do #uppdatera korten
  session[:empty] = false
  session[:stress] = false
  session[:badname] = false
  session[:false_img] = false
  session[:wrong_psw] = false
  session[:wrong_user] = false
  session[:no_card_id] = false
  session[:wrong_type] = false
  session[:wrong_creator_id] = false
  session[:no_unique_digname] = false
  session[:no_unique_username] = false
  
  id = params[:id]
  diginame_new = params[:diginame_new]
  type_new = params[:type_new]

  #cooldown till #spammar uppdaterig
  if session[:timeLogged] == nil #first time
    session[:timeLogged] = 0
  end
  spam =  spamtime(session[:timeLogged])
  session[:timeLogged] = Time.now.to_i #for next possible itteration

  if spam #spammar uppdatering
    session[:stress] = true
    redirect("/cards/#{id}/edit")
  end
  
  #felaktigt namn
  if badname(diginame_new)
    session[:badname] = true
    redirect("/cards/#{id}/edit")
  end

  #felaktig typ
  if wrong_type(type_new)
    session[:wrong_type] = true
    redirect("/cards/#{id}/edit")
  end

  #tomt namn
  if isEmpty(diginame_new)
    session[:empty] = true
    redirect("/cards/#{id}/edit")
  end

  #unikt namn
  if no_unique_name(diginame_new)
    session[:no_unique_digname] = true
    redirect("/cards/#{id}/edit")
  end

  #är id ett id på ett av alla kort?
  if no_card_has_id(id).length==0
    session[:no_card_id] = true
    redirect("/cards/#{id}/edit")
  end

  # Äger inloggad resursen?
  if owner(id)["creator_id"] != session[:user_id]
    session[:wrong_user] = true
    redirect("/cards/#{id}/edit")
  end

  update(id,false)
  redirect('/cards')
end

# Delets a post
#
# @param [Integer] :id, The card id
#
# @see Model#delete               ## #(validera)!!!!!!!!
post("/cards/:id/delete") do #ta bort kort #behövs verkligen mer validering här?
  id=params[:id]
  delete(id,false)
  redirect('/cards')
end

#Displays a delete user form      ### #(validera)!!!!!!!!
#
# @see Model#all_from_user
get ('/delete_users') do # följer jag inte rest här? ska de vara /uder/:id/delete?
  result = all_from_user(true)
  slim(:"delete_user", locals:{use:result})
end

# Delets a user
#
# @param [Integer] :id, The users id
#
# @see Model#delete_user
# @see Model#delete_user_cards
# @see Model#delete_user_rating
post("/user/:id/delete") do #ta bort user
  #delet users 
  id=params[:id]
  delete_user(id,false)
  #delete all cards from deleted_users
  delete_user_cards(id,false)
  #delete all ratings from deleted user
  delete_user_rating(id,false)

  redirect('/cards')
end

# Error
get('/error') do
  p "errorsidan"
  redirect('/')
end

# Displays a rate form
#
get("/cards/:id/rate") do
  slim(:"digimon/rate")
end

# Rate cards
#
# @param [Integer] :digi_id, The card id
# @param [Integer] :rating, The rating
#
# @see Model#spamtime
# @see Model#check_rate
# @see Model#rate
post("/cards/:id/rate") do
  session[:empty] = false
  session[:stress] = false
  session[:badname] = false
  session[:false_img] = false
  session[:wrong_psw] = false
  session[:wrong_type] = false
  session[:wrong_creator_id] = false
  session[:no_unique_username] = false
  session[:no_unique_digname] = false
  
  digi_id = params[:id].to_i
  rating = params[:rating].to_i
  user_id = session[:user_id]

  #cooldown till #spammar raings
  if session[:timeLogged] == nil #first time
    session[:timeLogged] = 0
  end
  spam =  spamtime(session[:timeLogged])
  session[:timeLogged] = Time.now.to_i #for next possible itteration

  if spam #spammar ratins
    session[:stress] = true
    redirect("/error")
  end

  if check_rate(rating)
    session[:bad_rating]=false
    rate(digi_id, rating, user_id)
    redirect('/cards')
  else
    session[:bad_rating]=true
    redirect("/cards/#{digi_id}/rate")
  end
end
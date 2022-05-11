require 'sinatra'
require 'slim'
require 'sqlite3'
require 'bcrypt'

require_relative 'funk'

enable :sessions

#secure routes


get('/') do #visa startsida
  slim(:start)
end

get('/register') do #visa registreringssidan
  slim(:register)
end

get ('/login') do #visa loginsidan
  slim(:login)
end

get ('/loggaut') do # logga ut anvädare 
  session[:empty] = false
  session[:inloggad] = false
  session[:authority] = false
  session[:wrong_psw] = false
  session[:no_unique_username] = false
  redirect('/')
end

get("/cards/new") do #visa formulär för att skapa kort 
  types = types(false)
  slim(:"digimon/new", locals: {types: types})
end

get('/egna') do #visa bara användarens 
  result = result(session[:user_id])
  slim(:"digimon/mine", locals:{dig:result})
end

get('/cards') do #visa alla  
  result = all_dig(true)
  slim(:"digimon/index", locals:{dig:result})
end

get("/cards/:id/edit") do #visa edit formuläret
  types = types(false)
  slim(:"digimon/edit", locals: {types: types,})
end

post('/users/new') do#registrerara användare.
  session[:empty] = false
  session[:inloggad] = false
  session[:wrong_psw] = false
  session[:no_unique_username] = false

  username = params[:username]
  password = params[:password]
  password_confirm = params[:password_confirm]
  
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

post('/users/login') do #logga in användare
  session[:empty] = false
  session[:wrong_psw] = false
  session[:no_username] = false

  username=params[:username]
  password=params[:password]

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
    session[:wrong_psw] = false
    redirect('/login')
  end

  session[:user_id] = user["id"]
  session[:inloggad]=true

  redirect('/')
end

post('/cards') do #gör kort 
  session[:empty] = false
  session[:badname] = false
  session[:false_img] = false
  session[:wrong_type] = false
  session[:no__unique_digname] = false

  digname= params[:diginame]
  creator_id= session[:user_id]
  creature_img=params[:image]
  creature_type=params[:type]


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
  File.open("./public#{img_path}", 'wb') do |f|
    f.write(temp_path.read)
  end

  create(session[:user_id], params[:diginame], img_path, params[:type])
  redirect('/cards')
end

post("/cards/:id/update") do #uppdatera korten
  session[:empty] = false
  session[:badname] = false
  session[:wrong_type] = false
  session[:wrong_creator_id] = false
  session[:no_unique_digname] = false

  diginame_new = params[:diginame_new]
  type_new = params[:type_new]
  id = params[:id]

  #felaktigt namn
  if badname(diginame_new)
    session[:badname] = true
    redirect("/cards/:id/edit")

  end

  #felaktig typ
  if wrong_type(type_new)
    session[:wrong_type] = true
    redirect("/cards/:id/edit")
  end

  #tomt namn
  if isEmpty(diginame_new)
    session[:empty] = true
    redirect("/cards/:id/edit")
  end

  #unikt namn
  if no_unique_name(diginame_new)
    session[:no_unique_digname] = true
    redirect("/cards/:id/edit")
  end

  update(id)
  redirect('/cards')
end

post("/cards/:id/delete") do #ta bort kort
  id=params[:id]
  delete('db\wsp22_db.db', id)
  redirect('/cards')
end

get ('/delete_users') do
  db=db_conect(true)
  result = db.execute("SELECT * FROM user")
  slim(:"delete_user", locals:{use:result})

end

post("/user/:id/delete") do #ta bort kort
  #delet users 
  id=params[:id]
  db=db_conect(false)
  db.execute("DELETE FROM user WHERE id=?", id)
  #delete all post from deleted_users
  db.execute("DELETE FROM digimon WHERE creator_id=?", id)
  redirect('/cards')
end

get('/error') do
  redirect('/')
end

get("/cards/:id/rate") do
  slim(:"digimon/rate")
end

post("/cards/:id/rate") do
  digi_id = params[:id].to_i
  rating = params[:rating].to_i
  user_id = session[:user_id]

  p rating
  p rating.class

  if check_rate(rating)
    session[:bad_rating]=false
    rate(digi_id, rating, user_id)
    redirect('/cards')
  else
    session[:bad_rating]=true
    redirect('/cards/:id/rate')
  end
end
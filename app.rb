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
  types = types('db\wsp22_db.db')
  slim(:"digimon/new", locals: {types: types})
end

get('/egna') do #visa bara användarens 
  db = db_conect('db\wsp22_db.db')
  db.results_as_hash = true
  result = result('db\wsp22_db.db', session[:user_id])
  slim(:"digimon/mine", locals:{dig:result})
end

get('/cards') do #visa alla  
  db = db_conect('db\wsp22_db.db')
  db.results_as_hash = true
  result = db.execute("SELECT * FROM digimon")

  p result

  slim(:"digimon/index", locals:{dig:result})
end

get("/cards/:id/edit") do #visa edit formuläret
  id=params[:id]
  db = db_conect('db\wsp22_db.db')
  types = types('db\wsp22_db.db')
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

  if password == password_confirm
    password_digest = BCrypt::Password.create(password)
    db = SQLite3::Database.new('db/wsp22_db.db')
    begin
      db.execute("INSERT INTO user (username,pswdig,authority) VALUES (?,?,?)",username,password_digest,1)
      redirect('/login')
    rescue SQLite3::ConstraintException #fixa så de e mer specifikt ###Db.execute("SELECT username FROM users WHERE username=?", username)
      session[:no_unique_username]=true
      redirect('/register')
    end
  else 
    session[:wrong_psw] = true #säg att lösenordet var fel
      redirect('/register')
  end
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

  if allfromUsername(username).empty? # användarnamn som inte finns
    session[:no_username] = true
    redirect('/login')
  end

  db = db_conect('db\wsp22_db.db')
  db.results_as_hash=true
  res=db.execute("SELECT * FROM user WHERE username=?",username).first
  if res["authority"]==2
    session[:authority]=true
  end
  
  
  db.results_as_hash = true

  
  login(username, password)
end

post('/cards') do #gör kort 
  session[:empty] = false
  session[:badname] = false
  session[:false_img] = false
  session[:wrong_type] = false
  session[:wrong_creator_id] = false

  digname= params[:diginame]
  creator_id= session[:user_id]
  creature_img=params[:image]
  creature_type=params[:type]


  #felaktig img
  if false_img(creature_img)
    session[:false_img] = true
    redirect('/cards/new')
  end

  #felaktigt namn
  if badname(digname)
    session[:badname] = true
    redirect('/cards/new')

  end

  #felaktig typ
  if wrong_type(creature_type)
    session[:wrong_type] = true
    redirect('/cards/new')
  end

  #tomt namn
  if isEmpty(digname)
    session[:empty] = true
    redirect('/cards/new')
  end

  if wrong_creator_id(creator_id)
    session[:wrong_creator_id] = true
    redirect('/cards/new')
  end


 
  temp_path = creature_img[:tempfile]

  img_path = "/uploads/#{creature_img[:filename]}"
  # Write file to disk
  File.open("./public#{img_path}", 'wb') do |f|
    f.write(temp_path.read)
  end

  create('db\wsp22_db.db', session[:user_id], params[:diginame], img_path, params[:type])
  redirect('/cards')
end

post("/cards/:id/update") do #uppdatera korten
  diginame_new = params[:diginame_new]
  type_new = params[:type_new]
  id = params[:id]
  update('db\wsp22_db.db', id)
  redirect('/cards')
end

post("/cards/:id/delete") do #ta bort kort
  id=params[:id]
  delete('db\wsp22_db.db', id)
  redirect('/cards')
end

get ('/delete_users') do
  db=db_conect('db\wsp22_db.db')
  db.results_as_hash = true
  result = db.execute("SELECT * FROM user")
  slim(:"delete_user", locals:{use:result})

end

post("/user/:id/delete") do #ta bort kort
  #delet users 
  id=params[:id]
  db=db_conect('db\wsp22_db.db')
  db.execute("DELETE FROM user WHERE id=?", id)
  #delete all post from deleted_users
  db.execute("DELETE FROM digimon WHERE creator_id=?", id)
  redirect('/cards')
end

get('/error') do
  redirect('/')
end

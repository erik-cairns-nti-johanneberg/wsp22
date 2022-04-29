require 'sinatra'
require 'slim'
require 'sqlite3'
require 'bcrypt'

require_relative 'funk'

enable :sessions

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
  session[:inloggad] = false
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
    username = params[:username]
    password = params[:password]
    password_confirm = params[:password_confirm]
    
    if isEmpty(username) || isEmpty(password)
      redirect('/register')
    end

    

    if password == password_confirm
      password_digest = BCrypt::Password.create(password)
      db = SQLite3::Database.new('db/wsp22_db.db')
      begin
        db.execute("INSERT INTO user (username,pswdig,authority) VALUES (?,?,?)",username,password_digest,1)
        session[:registration] = true #ny använader registreras
        redirect('/login')
      rescue => exeption
        p exeption
        session[:registration] = false #säg att användarnamnet redan finns
        redirect('/')
      end


      session[:pass] = true #korekt lösen
    else 
      session[:pass] = false #säg att lösenordet var fel
      redirect('/register')
    end
end

post('/users/login') do #logga in användare
  username=params[:username]
  password=params[:password]

  if isEmpty(username) || isEmpty(password)
    redirect('/login')
  end

  db = db_conect('db\wsp22_db.db')
  db.results_as_hash=true
  res=db.execute("SELECT * FROM user WHERE username=?",username).first
  if res["authority"]==2
    session[:authority]=true
  end
  
  
  db.results_as_hash = true

  if allfromUsername(username).empty? #undantagshantera ett användarnamn som inte finns
    #säg finns ingen sådan användare()()()()()()()()()()()()()(/(/(/(/((/(/(/(/(/(/(/(/(/(/(/(/(/(/(/(/)))))))))))))))))))))
    redirect('/error')
  end
  login(username, password)
end

post('/cards') do #gör kort 
  
  digname= params[:diginame]
  creator_id= session[:user_id]
  creature_img=params[:image]
  temp_path = creature_img[:tempfile]
  creature_type=params[:type]
  if creator_id
    img_path = "/uploads/#{creature_img[:filename]}"

    # Write file to disk
    File.open("./public#{img_path}", 'wb') do |f|
      f.write(temp_path.read)
    end

    create('db\wsp22_db.db', session[:user_id], params[:diginame], img_path, params[:type])
    redirect('/cards')
  else
    redirect('/error')
  end
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

get('/error') do
  redirect('/')
end

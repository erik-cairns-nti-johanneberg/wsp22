require 'sinatra'
require 'slim'
require 'sqlite3'
require 'bcrypt'

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

post('/users/new') do#registrerara användare.
    username = params[:username]
    password = params[:password]
    password_confirm = params[:password_confirm]
  
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

post('/users/login') do 
    username=params[:username]
    password=params[:password]
  
    db = SQLite3::Database.new('db\wsp22_db.db')
    db.results_as_hash = true
  
    result = db.execute('SELECT * FROM user WHERE username=?', username).first #ta alla med önskat username
    
    if result == nil #undantagshantera ett användarnamn som inte finns
      #säg finns ingen sådan användare()()()()()()()()()()()()()(/(/(/(/((/(/(/(/(/(/(/(/(/(/(/(/(/(/(/(/)))))))))))))))))))))
      redirect('/register')
    end

    pswdig = result["pswdig"]
    id=result["id"]
  
    if BCrypt::Password.new(pswdig) == password
      session[:id] = id
      session[:inloggad]=true
     redirect('/')
    else
      redirect('/login')
    end
end

get ('/loggaut') do # logga ut anvädare #gör alla till resful 
  session[:inloggad] = false
  redirect('/')
end


get("/skapa") do #gör alla till resful 
  db = SQLite3::Database.new('db\wsp22_db.db')
  types = db.execute("SELECT type_name FROM types").map {|type| type[0]}
  slim(:"digimon/new", locals: {types: types})
end


post('/create') do #gör alla till resful 
  digname= params[:diginame]
  creator_id= session[:id]
  creature_img=params[:image]
  temp_path = creature_img[:tempfile]
  creature_type=params[:type]

  path = "/uploads/#{creature_img[:filename]}"

  # Write file to disk
  File.open("./public#{path}", 'wb') do |f|
    f.write(temp_path.read)
  end
#lägg in type
  db = SQLite3::Database.new('db\wsp22_db.db')
  db.execute("INSERT INTO digimon (creator_id, name, img, type) VALUES (?,?,?,?)", creator_id, digname, path, creature_type)
  redirect('/allt')
end

get('/egna') do #visa mina #gör alla till resful 
  db = SQLite3::Database.new('db\wsp22_db.db')
  db.results_as_hash = true
  result = db.execute("SELECT * FROM digimon WHERE creator_id == #{session[:id]}")
  p result
  slim(:"digimon/mine", locals:{dig:result})
end

get('/allt') do #visa alla #gör alla till resful 
  db = SQLite3::Database.new('db\wsp22_db.db')
  db.results_as_hash = true
  result = db.execute("SELECT * FROM digimon")
  p result
  slim(:"digimon/index", locals:{dig:result})
end

post('/delete') do
  digi_id=params[:digimon_id].to_i
  db = SQLite3::Database.new('db\wsp22_db.db')
  db.execute("DELETE FROM digimon WHERE id=?", digi_id)
  redirect('/allt')
end

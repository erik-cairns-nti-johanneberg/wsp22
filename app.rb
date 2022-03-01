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

        db.execute("INSERT INTO user (username,pswdig,money) VALUES (?,?,?)",username,password_digest, 100)
        session[:registration] = true #ny använader registreras
        redirect('/login')
      rescue => exeption
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
  
    result = db.execute('SELECT * FROM user WHERE username =?', username).first #ta alla med önskat username
    
    if result == nil #undantagshantera ett användarnamn som inte finns
      #säg finns ingen sådan användare()()()()()()()()()()()()()(/(/(/(/((/(/(/(/(/(/(/(/(/(/(/(/(/(/(/(/)))))))))))))))))))))
      redirect('/login')
    end

    pswdig = result["pswdig"]
    id=result["id"]
  
    if BCrypt::Password.new(pswdig) == password
      session[:id] = id
      session[:inloggad]=true
     redirect('/')
    else
      redirect('/')
    end
end

get ('/loggaut') do # logga ut anvädare 
  session[:inloggad] = false
  redirect('/')
end

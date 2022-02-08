require 'sinatra'
require 'slim'
require 'sqlite3'
require 'bcrypt'

enable :sessions

get('/') do #visa startsida
  slim(:start)
end

get('/showcards') do
    db = SQLite3::Database.new('/db/wsp22_db.db')
    db.results_as_hash = true
    all_digimon = db.execute("SELECT * FROM digimon")
    slim(:"digimon/index",locals:{digimon:all_digimon})
end

post('/users/new') do #registrera användrae
    username=params[:username]
    password=params[:password]
    password_conf=params[:password_confirm]

    if (password_confirm=password)
        #lägg till användeare
    else
        #hantera fel lösen
    end
end
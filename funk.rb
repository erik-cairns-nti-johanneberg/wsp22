def db_conect(path)
    return SQLite3::Database.new(path)
end

def allfromUsername(username)
    db = db_conect('db\wsp22_db.db')
    db.results_as_hash = true
    return db.execute('SELECT * FROM user WHERE username=?', username)
end

def login(username, password)
    db = db_conect('db\wsp22_db.db')
    user = allfromUsername(username).first
    
    pwdigest = user["pswdig"]
    id = user["id"]

    if BCrypt::Password.new(pwdigest) == password
        session[:user_id] = id
        session[:inloggad]=true
        redirect('/')
    else
        #say wrong password
        redirect('/login')
    end
end
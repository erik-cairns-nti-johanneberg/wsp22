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

def types(path)
    db = db_conect(path)
    return db.execute("SELECT type_name FROM types").map {|type| type[0]}
end

def update(path, id)
    db = db_conect(path)
    return db.execute("UPDATE digimon SET name=?,type=? WHERE id=?", params[:diginame_new],params[:type_new], id)
end

def delete(path, id)
    db = db_conect(path)
    return db.execute("DELETE FROM digimon WHERE id=?", id)
end

def create(path, creator_id, digname, img_path, creature_type)
    db = db_conect(path)
    return db.execute("INSERT INTO digimon (creator_id, name, img, type) VALUES (?,?,?,?)", creator_id, digname, img_path, creature_type)
end

def result(path, user_id)
    db = db_conect(path)
    db.results_as_hash = true
    return db.execute("SELECT * FROM digimon WHERE creator_id = ?", user_id)
end
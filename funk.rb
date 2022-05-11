#inga sessions eller redirekcts
MAX_IMG_SIZE = 300  # MB
MAX_NAME_CHAR = 20  #nr.char

def db_conect(bool)
    db = SQLite3::Database.new('db\wsp22_db.db')
    db.results_as_hash = bool
    return db
end

def allfromUsername(username, bool)
    db = db_conect(bool)
    return db.execute('SELECT * FROM user WHERE username=?', username)
end

def login(username, password)
    user = allfromUsername(username, true).first
    
    pwdigest = user["pswdig"]
    id = user["id"]

    if BCrypt::Password.new(pwdigest) == password
        session[:user_id] = id
        session[:inloggad]=true
        redirect('/')
    else
        session[:wrong_psw]=true
        redirect('/login')
    end
end

def wrong_psw

end



def types()
    db = db_conect(false)
    return db.execute("SELECT type_name FROM types").map {|type| type[0]}
end

def update( id)
    db = db_conect()
    return db.execute("UPDATE digimon SET name=?,type=? WHERE id=?", params[:diginame_new],params[:type_new], id)
end

def delete(id)
    db = db_conect()
    return db.execute("DELETE FROM digimon WHERE id=?", id)
end

def create(creator_id, digname, img_path, creature_type)
    db = db_conect(false)
    return db.execute("INSERT INTO digimon (creator_id, name, img, type) VALUES (?,?,?,?)", creator_id, digname, img_path, creature_type)
end

def result(user_id)
    db = db_conect(true)
    return db.execute("SELECT * FROM digimon WHERE creator_id = ?", user_id)
end



def isEmpty(text)
    if text == nil
        return true
    elsif text == "" || text.scan(/ /).empty? == false 
        return true
    else
        return false
    end    
end

def get_file_size(file)
    return (File.size(file).to_f / 1024000).round(2) 
end

def false_img(img)
    #check
    if img == nil
        return true

    elsif img["type"] != "image/jpeg" && img["type"] != "image/png"
        return true

    elsif get_file_size(img["tempfile"]) > MAX_IMG_SIZE
        return true

    else
        return false
    end
end


def str_has_bad_char(str)
    return (str =~ /[^a-zA-Z0-9]/) != nil || (str =~ /[0-9]/) != nil
end

def badname(name)
    return name.length > MAX_NAME_CHAR || str_has_bad_char(name)
end

def wrong_type(type)
    #check
    return false
end

def not_creator_id(digi_id,creator_id)
    #check
    db=db_conect(false)
    dig_id=db.execute("SELECT * FROM digimon WHERE id =?",digi_id).first
    return if dig_id["creator_id"] != creator_id
   
end

def no_unique_name(diginame)
    db=db_conect(false)
    dig_name=db.execute("SELECT name FROM digimon WHERE name =?",diginame).first
    return dig_name != nil
end

def rate(digi_id, rating, user_id)
    db = db_conect()
    db.execute("INSERT INTO digimon_and_rating (user_id,digimon_id,rating) VALUES (?,?,?)", user_id,digi_id,rating).first
end

def check_rate(rating)
    return rating <= 10 && rating.class == Integer
end

def avg_rate(digi_id)
    db = db_conect()
    res = db.execute("SELECT AVG(rating) FROM digimon_and_rating WHERE digimon_id =?", digi_id)
    return res
end

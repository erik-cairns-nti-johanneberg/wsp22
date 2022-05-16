module Model
    #inga sessions eller redirekcts
    MAX_IMG_SIZE = 300  # MB
    MAX_NAME_CHAR = 20  #nr.char

    # Attempts to open a new database connection
    #
    # @param [Boolean] bool, return as hash or no hash
    #
    # @return [Array] containing all the data from the database
    def db_conect(bool)
        db = SQLite3::Database.new('db\wsp22_db.db')
        db.results_as_hash = bool
        return db
    end

    #Find all from the user with unsername
    #
    # @see Model#db_conect
    #
    # @param [String] username, the user username
    # @param [Boolean] bool, return as hash or no hash
    #
    # @return [Array] specific user information by username
    def allfromUsername(username, bool)
        db = db_conect(bool)
        return db.execute('SELECT * FROM user WHERE username=?', username)
    end

    # Attempts to register user
    #
    # @see Model#db_conect
    #
    # @param [String] password, the password input
    # @param [String] username, the user username
    #
    def make_user(username,password)
        db=db_conect(false)
        password_digest = BCrypt::Password.create(password)
        db.execute("INSERT INTO user (username,pswdig,authority) VALUES (?,?,?)",username,password_digest,1)
    end

    #Check if password is correct
    #
    # @param [String] password, the password input
    # @param [String] username, the user username
    #
    # @return [Boolean] whether password is wrong
    def bad_psw(password, user)
        return BCrypt::Password.new(user["pswdig"]) != password
    end

    #Check if password is same as passwordconfirm
    #
    # @param [String] psw, the password input
    # @param [String] psw_comf, the passwordcmofirm input
    #
    # @return [Boolean] whether password is not same as passwordconfirm
    def wrong_psw(psw, psw_comf)
        return psw != psw_comf
    end

    #Find all from all cards
    #
    # @see Model#db_conect
    #
    # @param [Boolean] bool, return as hash or no hash
    #
    # @return [Array] all information from digimon
    def all_dig(bool)
        db = db_conect(bool)
        return db.execute("SELECT * FROM digimon")  
    end

    #Find all names from types
    #
    # @see Model#db_conect
    #
    # @param [Boolean] bool, return as hash or no hash
    #
    # @return [Array] all names of types
    def types(bool)
        db = db_conect(bool)
        return db.execute("SELECT type_name FROM types").map {|type| type[0]}
    end

    # Attempts to update a card
    #
    # @param [Integer] id, the card ID
    # @param [Boolean] bool, return as hash or no hash
    #
    # @see Model#db_conect
    #
    # @return [Array] all updated card info
    def update(id,bool)
        db = db_conect(bool)
        return db.execute("UPDATE digimon SET name=?,type=? WHERE id=?", params[:diginame_new],params[:type_new], id)
    end

    # Deletes card
    #
    # @param [Integer] id, the card ID
    # @param [Boolean] bool, return as hash or no hash
    #
    # @see Model#db_conect
    def delete(id,bool)
        db = db_conect(bool)
        return db.execute("DELETE FROM digimon WHERE id=?", id)
    end

    # Deletes user
    #
    # @param [Integer] id, the user ID
    # @param [Boolean] bool, return as hash or no hash
    #
    # @see Model#db_conect
    def delete_user(id, bool)
        db=db_conect(bool)
        db.execute("DELETE FROM user WHERE id=?", id)
    end

    # Deletes users cards 
    #
    # @param [Integer] id, the user ID
    # @param [Boolean] bool, return as hash or no hash
    #
    # @see Model#db_conect
    def delete_user_cards(id,bool)
        db=db_conect(bool)
        db.execute("DELETE FROM digimon WHERE creator_id=?", id)
    end
  
    # Deletes users rating from "digimon_and_rating" table 
    #
    # @param [Integer] id, the user ID
    # @param [Boolean] bool, return as hash or no hash
    #
    # @see Model#db_conect
    def delete_user_rating(id,bool)
        db=db_conect(bool)
        db.execute("DELETE FROM digimon_and_rating WHERE user_id=?", id)
    end

    # Atempts to create a card
    #
    # @param [Integer] creator_id, the creator ID
    # @param [String] digname, card name
    # @param [String] creature_type, card type
    # @param [Sinatra::IndifferentHash] img_path, path to card img
    #
    # @see Model#db_conect
    #
    # @return [Array] card info
    def create(creator_id, digname, img_path, creature_type)
        db = db_conect(false)
        return db.execute("INSERT INTO digimon (creator_id, name, img, type) VALUES (?,?,?,?)", creator_id, digname, img_path, creature_type)
    end

    #Show own cards
    #
    # @param [Integer] user_id, the users ID
    #
    # @see Model#db_conect
    #
    # @return [Array] card info where the creator is the user
    def result(user_id)
        db = db_conect(true)
        return db.execute("SELECT * FROM digimon WHERE creator_id = ?", user_id)
    end

    #Find all from the user
    #
    # @see Model#db_conect
    #
    # @param [Boolean] bool, return as hash or no hash
    #
    # @return [Array] all user information
    def all_from_user(bool)
        db = db_conect(bool)
        return db.execute("SELECT * FROM user")
    end

    #Check if text box is empty
    #
    # @param [String] text, the boxes input
    #
    # @return [Boolean] whether input is empty
    def isEmpty(text)
        if text == nil
            return true
        elsif text == "" || text.scan(/ /).empty? == false 
            return true
        else
            return false
        end    
    end

    #Get file size 
    #
    # @param [blob] file, the file
    #
    # @return [Float] The filesize rouded 
    def get_file_size(file)
        return (File.size(file).to_f / 1024000).round(2) 
    end

    #Check if img is wrong type or size
    #
    # @param [blob] img, the file
    #
    # @see Model#get_file_size
    #
    # @return [Boolean] whether file is not ok
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

    #Check if text input contains bad characters
    #
    # @param [String] str, the text input
    #
    # @return [Boolean] whether text contains bad characters
    def str_has_bad_char(str)
        return (str =~ /[^a-zA-Z0-9]/) != nil || (str =~ /[0-9]/) != nil
    end

    #Check if text input contains bad characters or is too long
    #
    # @param [String] name, the text input
    #
    # @return [Boolean] whether text contains bad characters or is too long
    def badname(name)
        return name.length > MAX_NAME_CHAR || str_has_bad_char(name)
    end

    def wrong_type(type)#gör??
        #check
        return false
    end

    #Check if cards creator is same as current user
    #
    # @param [Integer] digi_id, the cards id
    # @param [Integer] creator_id, the current users id
    #
    # @see Model#db_conect
    #
    # @return [Boolean] whether creator_id of card is not the current users id
    def not_creator_id(digi_id,creator_id)
        #check
        db=db_conect(false)
        dig_id=db.execute("SELECT * FROM digimon WHERE id =?",digi_id).first
        return dig_id["creator_id"] != creator_id
    end

    #Check if name of card is not unique
    #
    # @param [String] diginame, the cards name
    #
    # @see Model#db_conect
    #
    # @return [Boolean] whether given name dose not exist
    def no_unique_name(diginame)
        db=db_conect(false)
        dig_name=db.execute("SELECT name FROM digimon WHERE name =?",diginame).first
        return dig_name != nil
    end

    #Check if name of user is not unique
    #
    # @param [String] username, the users name
    #
    # @see Model#db_conect
    #
    # @return [Boolean] whether given name dose not exist
    def no_unique_user(username)
        db=db_conect(false)
        user_name=db.execute("SELECT username FROM user WHERE username =?",username).first
        return user_name != nil
    end

    #Rate cards
    #
    # @param [Integer] digi_id, the card id
    # @param [Integer] rating, the rating
    # @param [Integer] user_id, the users id
    #
    # @see Model#db_conect
    #
    def rate(digi_id, rating, user_id)
        db = db_conect(false)
        db.execute("INSERT INTO digimon_and_rating (user_id,digimon_id,rating) VALUES (?,?,?)", user_id,digi_id,rating).first
    end

    #check if rating is within ratin value and int type
    #
    # @param [Integer] rating, the rating
    #
    # @return [Boolean] whether given rating is correct
    def check_rate(rating)
        return rating <= 10 && rating >= 0 && rating.class == Integer
    end

    #Calculate avg rating
    #
    # @param [Integer] digi_id, the card id
    #
    # @return [Float] AVG of all rating on card
    def avg_rate(digi_id)
        db = db_conect(false)
        res = db.execute("SELECT AVG(rating) FROM digimon_and_rating WHERE digimon_id =?", digi_id)
        return res
    end

    #write img to disk
    #
    # @param [String] img_path, the file path
    # @param [blob] temp_path, the file path in blob
    #
    def write_img(img_path, temp_path)
        f = File.open("./public#{img_path}", 'wb')
        f.write(temp_path.read)
        f.close()
    end

    #check if time between events is too fast
    #
    # @param [String] lastTime, the time last checked
    #
    # @return [Boolean] if the difference in time is not loger than 1.5s
    def spamtime(lastTime)
        timeDiff = Time.now.to_i - lastTime
        return timeDiff < 1.5      
    end

    #Find creator id on card 
    #
    # @param [Integer] id, the cards id
    # @see Model#db_conect
    #
    # @return [Integer] creator id on card with id 
    def owner(id)
        db=db_conect(true)
        return db.execute("SELECT creator_id FROM digimon WHERE id=?", id).first
    end

    #Check if card has id 
    #
    # @param [Integer] id, the cards id
    # @see Model#db_conect
    #
    # @return [Array] all from card with id 
    def no_card_has_id(id)
        db=db_conect(true)
        return db.execute("SELECT * FROM digimon WHERE id=?", id)
    end
end
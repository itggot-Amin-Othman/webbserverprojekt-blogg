require 'slim'
require 'sinatra'
require 'sqlite3'
require 'bcrypt'

enable :sessions

get('/') do
    db = SQLite3::Database.new('blog.db')
    db.results_as_hash = true
    posts = db.execute("SELECT posts.ContentText, posts.ContentImage, users.Username FROM posts INNER JOIN users ON users.UserId = posts.UserId")
    slim(:home, locals:{
        posts: posts
    })
end

post('/login') do
    db=SQLite3::Database.new('blog.db')
    db.results_as_hash = true
    result = db.execute("SELECT Password, UserId FROM users WHERE Username =(?)", params["name"])

    if result == []
        redirect('/home')
        #ha ngn popup som säger att du är en potatis
    end

    encrypted_pass = result[0]["Password"]
    if BCrypt::Password.new(encrypted_pass) == params["pass"]
        session[:loggedin] = true
        session[:user_id] = result[0]["UserId"]
        session[:name] = params["name"]
        redirect('/profile')
    else
        session.destroy
        redirect('/')
        #ha ngn popup som säger att du är en potatis
    end
end

get('/profile') do
    if session[:loggedin] == true
        db = SQLite3::Database.new('blog.db')
        db.results_as_hash = true
        posts = db.execute("SELECT posts.PostId, posts.ContentText, posts.ContentImage, users.Username FROM posts INNER JOIN users ON users.UserId = posts.UserId WHERE posts.UserId =(?)", session[:user_id])
        slim(:profile, locals:{
            username: session[:name],
            posts: posts
        })
    else
        redirect('/')
    end
end
    
post('/logout') do
    session.destroy
    redirect('/')
end

get('/register') do
    slim(:register)
end

post('/create') do
    name = params["name"]
    password = BCrypt::Password.create(params["pass"])
    db = SQLite3::Database.new('blog.db')
    db.execute("INSERT INTO users(Username,Password) VALUES((?),(?))",name,password) 
    redirect('/')
end

post('/post') do
    text = params["post_text"]
    image = params["post_image"]
    user_id = session[:user_id]
    db = SQLite3::Database.new('blog.db')
    if image != nil
        db.execute("INSERT INTO posts(UserId, ContentText, ContentImage) VALUES((?),(?),(?))",user_id,text,image)
    else
        db.execute("INSERT INTO posts(UserId, ContentText) VALUES((?),(?))",user_id,text)
    end
    redirect('/profile')
end

post('/update/:id') do
    db = SQLite3::Database.new('blog.db')
    poster_id = db.execute("SELECT UserId FROM posts WHERE PostId = (?)", params["id"])
    if poster_id[0][0] == session[:user_id]
        if params["post_image"]
            db.execute("UPDATE posts SET ContentText = (?), ContentImage = (?) WHERE PostId = (?)",params["post_text"], params["post_image"], params["id"])
        else
            db.execute("UPDATE posts SET ContentText = (?), WHERE PostId = (?)",params["post_text"],  params["id"])
        end
        redirect('/profile')
    else
        redirect('/home')
    end
end

get('/edit/:id') do
    db = SQLite3::Database.new('blog.db')
    db.results_as_hash = true
    post = db.execute("SELECT PostId, ContentText, ContentImage FROM posts WHERE PostId = (?)", params["id"])
    slim(:edit, locals:{
        post: post
    })
end

post('/delete/:id') do
    db = SQLite3::Database.new('blog.db')
    db.execute("DELETE FROM posts WHERE PostId = (?)",params["id"])
    redirect('/profile')
end

require 'slim'
require 'sinatra'
require 'sqlite3'
require 'bcrypt'

enable :sessions

get('/') do
    slim(:home)
end

post('/login') do
    db=SQLite3::Database.new('blog.db')
    db.result_as_hash = true
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
        redirect('/home')
        #ha ngn popup som säger att du är en potatis
    end
end

get('/profil') do
    if session[:loggedin] == true
        db = SQLite3::Database.new('blogg.db')
        db.results_as_hash = true
        posts = db.execute("SELECT posts.PostId, posts.ContentText, posts.ContentImage, users.Username FROM posts INNER JOIN users ON users.UserId = posts.UserId WHERE posts.UserId =(?)", session[:user_id])
        slim(:profil, locals:{
            username: session[:name],
            posts: posts
        })
    else
        redirect('/')
    end
end
    

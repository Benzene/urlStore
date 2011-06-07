require 'sinatra'
require 'sqlite3'
require 'bcrypt'

class AuthenticationError < StandardError; end
class ParameterError < StandardError; end

use Rack::Session::Pool, :expire => 60 * 60 * 24

error AuthenticationError do
	"Authentication failed !"
	redirect url('/login')
end

error ParameterError do
	"Wrong parameters given !"
end

helpers do
	def is_authed?
		!session[:user].nil?
	end
	def auth(user, pass)
		raise AuthenticationError, 'No credentials given' unless (user.is_a?(String) && pass.is_a?(String))
		pair = [ user ]
		res = @db.execute("SELECT hashed_pass FROM users WHERE username=?", pair)
		raise AuthenticationError, 'Invalid credentials (username not found)' unless res.length > 0
		raise AuthenticationError, 'Invalid credentials (wrong password)' unless BCrypt::Password.new(res[0][0]) == pass
		session[:user] = user
	end
	def require_auth
		if !is_authed? then
			redirect url('/login')
		end
	end
	def require_non_auth
		if is_authed? then
			redirect url('/')
		end
	end
end

before do
	@db = SQLite3::Database.new "urls.db"
end

get '/' do
	require_auth
	pair = [ session[:user] ]
	@cats = @db.execute("SELECT shortname, title, description FROM categories WHERE belongs_to=?", pair)
	haml :listcats
end

get '/login' do
	require_non_auth
	haml :login
end

post '/login' do
	require_non_auth
	auth(params[:user], params[:pass])
	is_authed?
	redirect url('/')
end

get '/list/:category' do
	require_auth
	pair = [ session[:user], params[:category] ]
	@links = @db.execute("SELECT url, title, description, date, read FROM urls WHERE added_by=? AND category=?", pair)
	haml :listlinks
end

get '/add' do
	require_auth
	pair = [ session[:user] ]
	@cats = @db.execute("SELECT shortname,title FROM categories WHERE belongs_to=?", pair)
	haml :urlform
end

post '/add' do
	require_auth
	@category = params[:category]
	if (@category.nil? || @category == '') then
		@category = 'default'
	end
	@url = params[:url]
	@title = params[:title]
	@description = params[:description]
	raise ParameterError, 'Insufficient parameters' unless (@url.is_a?(String) && @url != '' && @title.is_a?(String) && @description.is_a?(String))
	pair = [ @url, @title, @description, @category, session[:user] ]
	@db.execute("INSERT INTO urls (url, title, description, date, category, read, added_by) VALUES (?, ?, ?, datetime('now'), ?, 0, ?)", pair)
	redirect url('/')
end

post '/add/*:*' do
	require_auth
	@category = params[:splat][0]
	if (!@category.is_a?(String) || @category == '') then
		@category = 'default'
	end
	@url = params[:splat][1]
	raise ParameterError, 'Insufficient parameters' unless (@url.is_a?(String) && @url != "") 
#	@category + " / " + @url + " by " + @user + " (" + @pass + ")\n"
	pair = [ @url, @category, @user ]
	@db.execute("INSERT INTO urls (url, title, description, date, category, read, added_by) VALUES (?, '', '', datetime('now'), ?, 0, ?)", pair)
end

get '/addcategory' do
	require_auth
	haml :addcategory
end

post '/addcategory' do
	require_auth
	@shortname = params[:shortname]
	@title = params[:title]
	@description = params[:description]
	pair = [ @shortname, @title, @description, session[:user] ]
	@db.execute("INSERT INTO categories (shortname, title, description, belongs_to) VALUES (?, ?, ?, ?)", pair)
	redirect url('/')
end

get '/register' do
	haml :register
end

post '/register' do
	pair = [ params[:user], BCrypt::Password.create(params[:pass]), params[:email] ]
	@db.execute("INSERT INTO users (username,hashed_pass,email) VALUES(?,?,?)", pair)
	redirect url('/')
end

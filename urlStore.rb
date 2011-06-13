require 'sinatra'
require 'sqlite3'
require 'bcrypt'

require_relative 'login-commons/loginHandler'

before do
	@db = SQLite3::Database.new "urls.db"
end

get '/' do
	require_auth
	pair = [ session[:user], session[:user], session[:user] ]
	@cats = @db.execute("SELECT shortname, title, description, IFNULL(c1.cnt, 0), IFNULL(c2.cnt, 0) FROM categories LEFT JOIN (SELECT category, read, COUNT(id) as cnt FROM urls WHERE added_by=? AND read=0 GROUP BY category) AS c1 ON categories.shortname=c1.category LEFT JOIN (SELECT category, read, COUNT(id) as cnt FROM urls WHERE added_by=? AND read=1 GROUP BY category) AS c2 ON categories.shortname=c2.category WHERE belongs_to=?", pair)
	haml :listcats
end

get '/list/:category' do
	require_auth
	pair = [ session[:user], params[:category] ]
	@links = @db.execute("SELECT url, title, description, date, read, id FROM urls WHERE added_by=? AND category=?", pair)
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

# More 'RESTful' requests. Supposed to be called from inside the app, via js.
post '/s/read/:id/:value' do
	if (params[:value] == "0" || params[:value] == "1") then
		require_auth
		pair = [ params[:value], session[:user], params[:id] ]
		@db.execute("UPDATE urls SET read=? WHERE added_by=? AND id=?", pair)
		if (@db.changes > 0) then
			201
		else
			400
		end
	else
		400
	end
end

require 'sinatra'

use Rack::Lint
use Rack::ContentLength

require './urlStore'
run Sinatra::Application

require 'sinatra'
require 'json'

# Sample web server, supported endpoints are commented inside this class.
# See http://sinatrarb.com/intro.html
class Server < Sinatra::Base
  DB_FILE = 'server.db'

  # GET /
  #
  # Prints out the database in JSON.
  get '/' do
    db = load_db

    [200, db.to_json]
  end

  # GET /create?key=<KEY>&value=<VALUE>
  #
  # Inserts <KEY> and <VALUE> in the database.
  get '/create' do
    key = params['key']
    value = params['value']
    if not key or not value
        "Call /create?key=<KEY>&value=<VALUE>"
    end
    db = load_db
    db[key] = value
    save_db(db)

    [200, "Added %s = %s" % [key, value]]
  end

  # GET /delete/<key>
  #
  # Deletes <KEY> from the database.
  get '/delete/:key' do
    key = params['key']
    db = load_db
    db.delete(key)
    save_db(db)

    [200, "%s deleted or key wasn't present" % [key]]
  end

  private
  def load_db
    db_string = File.open(DB_FILE).read rescue "{}"
    JSON.parse(db_string)
  end

  def save_db(db)
    File.write(DB_FILE, db.to_json)
  end
end


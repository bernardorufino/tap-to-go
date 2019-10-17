require 'sinatra'
require 'json'

# Sample web server, supported endpoints are commented inside this class.
# See http://sinatrarb.com/intro.html
class Server < Sinatra::Base
  DB_FILE = 'server.db'

  # GET /cc?pin=<PIN>
  #
  # Waits for CC information from one of the devices pooling
  get '/cc' do
    pin = params['pin']
    if pin.nil?
      return [400, "Need a pin"]
    end

    db = load_db
    db['pending_requests'] ||= []
    db['pending_requests'] << pin
    save_db(db)

    deadline = Time.now + 15
    while Time.now <= deadline
      db = load_db
      cc = db.fetch('requests', {})[pin]
      if not cc.nil?
        db['pending_requests'].delete(pin)
        db['requests'].delete(pin)
        save_db(db)
        return [200, {'success' => true, 'cc' => cc}.to_json]
      end
      sleep(1)
    end

    db = load_db
    db['pending_requests'].delete(pin)
    save_db(db)
    [200, {'success' => false}.to_json]
  end

  # GET /request
  #
  # Asks if there is a request present, if there is server returns the pin of one of them
  get '/request' do
    db = load_db
    first_request = db.fetch('pending_requests', [])[0]
    if first_request.nil?
      return [400, ""]
    end

    [200, first_request]
  end

  # GET /push_cc
  #   ?pin=<PIN>
  #   &CardNumber=<CardNumber>
  #   &CardHolderName=<CardHolderName>
  #   &ExpMonth=<ExpMonth>
  #   &ExpYear=<ExpYear>
  #
  # Sends credit card information to <PIN>
  get '/push_cc' do
    pin = params['pin']
    card_number = params['CardNumber']
    card_holder_name = params['CardHolderName']
    exp_month = params['ExpMonth']
    exp_year = params['ExpYear']

    db = load_db
    db['requests'] ||= {}
    db['requests'][pin] = {
      'CardNumber' => card_number,
      'CardHolderName' => card_holder_name,
      'ExpMonth' => exp_month.to_i,
      'ExpYear' => exp_year.to_i
    }
    save_db(db)

    [200, ""]
  end

  # GET /reset
  #
  # Empty DB
  get '/reset' do
    save_db({})

    [200, "Reset"]
  end

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
        [400, "Call /create?key=<KEY>&value=<VALUE>"]
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


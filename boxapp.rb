require 'rubygems' if RUBY_VERSION < '1.9'
require 'em-http-stream/json_stream'

#BoxApp using Sinatra , Box-API and Haml

require 'box-api'
require 'sinatra'
require 'rack-flash'
require 'haml'
require 'pony'
require 'mongoid'
require 'json'
require "./models/user"
require "./models/pitchfile"
require 'logger'
require 'pry'
# Sessions are used to keep track of user logins.
enable :sessions


# This is where we set the API key given by Box.
# Get a key here: https://www.box.net/developers/services
set :box_api_key, ENV['BOX_API_KEY']

configure do

  Mongoid.load!("config/mongoid.yml")
  set :environment, 'development'
  log = Logger.new("logs/#{ENV['RACK_ENV']}.txt")
  Box_API = "w9ipbwehe4spgdp49o4rlqulhaz69p4l" #Temporary. Will be changed later
  #FIXME: Change later when the app is more stable
  log.level = Logger::DEBUG
  settings.box_api_key ||= Box_API

end

# Helper methods are avaliable for access throughout the application.
helpers do

  # Requires the user to be logged into Box, or redirect them to the login page.
  def require_login
    box_login(settings.box_api_key, session) do |auth_url|
      redirect auth_url
    end
  end
  def update_box_login
    # update the variables if passed parameters (such as during a redirect)
    session[:box_ticket] ||= params[:ticket]
    session[:box_token] ||= params[:auth_token]

  end

  def send_pitch_email(locals = {})

    # Pony to send email. Currently sent with Gmail SMTP. 
    # Called when the file is copied to the pitch folder
    # ENV variables has to be set for email id and password
    Pony.mail :to => 'pitch@crushpath.com',
      :from => ENV['GMAIL_SMTP_USER'],
      :subject => 'Hola! New Pitch File Created',
      :html_body => (haml :email, :layout => false, :format => :html5, :locals => locals),
      :via => :smtp,
      :via_options => {
      :address => 'smtp.gmail.com',
      :user_name => ENV['GMAIL_SMTP_USER'],
      :password => ENV['GMAIL_SMTP_PASSWORD']
    }
  end

  # Authenticates the user using the given API key and session information.
  # The session information is used to keep the user logged in.
  def box_login(box_api_key, session)
    # make a new Account object using the API key
    account = Box::Account.new(box_api_key)      
    #session[:folder] ||= nil #Session for pitch folder created with login

    # use a saved ticket or request a new one
    ticket = session[:box_ticket] || account.ticket
    token = session[:box_token]

    # try to authorize the account using the ticket and/or token
    authed = account.authorize(:ticket => ticket, :auth_token => token) do |auth_url|
      # this block is called if the authorization failed

      # save the ticket we used for later
      session[:box_ticket] = ticket

      # yield with the url the user must visit to authenticate
      yield auth_url if block_given?
    end

    if authed
      # authentication was successful, save the token for later
      session[:box_token] = account.auth_token

      # return the account
      return account
    end
  end

  # Removes session information so the account is forgotten.

  # Note: This doesn't actually log the user out, it just clears the session data.
  def box_logout(session)
    session.delete(:box_token)
    session.delete(:box_ticket)
  end

  # Just renders a template with no special options
  def full(template, locals = {})
    haml(template, :locals => locals)
  end

  # Renders a template, but without the entire layout (good for AJAX calls).
  def partial(template, locals = {})
    haml(template, :layout => false, :locals => locals)
  end
end


# Different Routes for the Box-App

#Root of Box-App . Takes to Box site login, if the user is not logged in.
get '/' do 
  update_box_login            # updates login information if given
  account = require_login     # make sure the user is authorized
  root = account.root         # get the root folder of the account 

  full :index, :account => account, :root => root
end 


# Gets a folder by id and returns its details.
get "/folder/:folder_id" do |folder_id|
  account = require_login        # make sure the user is authorized
  folder = account.folder(folder_id) # get the folder by id

  # Note: Getting a folder by ID is fastest, but it won't know about its parents.
  # If you need this information, use 'account.root.find(:id => folder_id)' instead.

  partial :folder, :folder => folder # render the information about this folder
end


# Displays the form for adding a new folder based on the parent_id.
get "/folder/add/:parent_id" do |parent_id|
  partial :add_folder, :parent_id => parent_id
end

# Creates a new folder with the given information.
post "/folder/add/:parent_id" do |parent_id|
  account = require_login        # make sure the user is authorized
  parent = account.folder(parent_id) # get the parent folder by id


  name = params[:name]         # get the desired folder name
  folder = parent.create(name) # create a new folder with this name


  partial :item, :item => folder # render the information about this folder
end


#Copy the pitch file and create a new folder for pitch if the folder
#doesn't exist already
post "/file/pitch/:file_id" do |file_id|
  account = require_login # make sure the user is authorized
  user = account.info #Retrieve account information
  user_id = user["user_id"] #Retrieve the box user id

  name = params[:name]    # Get the Pitch folder name from post

  db_user = User.find_or_create_by(box_user_id: user_id) #Raise error exception set to false

  #Check for existence of pitch folde by name, parent :0  and is_Folder condition
  db_folder = Pitchfile.find_by(name: name, parent_id: 0, is_Folder: true)


  if db_folder.nil?
    begin
      parent = account.root   # getting the root folder as parent
      folder = parent.create(name) # Create the pitch folder with the name
      folder = parent.at(name) if folder.nil? # If the folder exists you cannot create it
      folder_id = folder.id
      db_folder = Pitchfile.create(file_id: folder_id, name: name, parent_id: 0, is_Folder: true )
    rescue Box::Api::NameTaken
      puts $!.inspect
    rescue Box::Api::NoAccess 
      puts $!    
    end
  end

  begin
    #Check for the Folder match with Box.
    folder = account.folder(db_folder.file_id)
    file = account.file(file_id) # get the file by id
    file_copy = file.copy(folder)   #Copy the file to the Pitch folder
    pitchfile = file_copy.name #Stores the copied file name
    username = user["login"] #Gets the user login. 
    Pitchfile.create(file_id: file_copy.id, name: pitchfile, parent_id: folder.id, is_Folder: false )
    #Function to send pitch mail after the file is copied.
    send_pitch_email(pitchfile: pitchfile, username: username)
  rescue Box::Api::NameTaken
    puts $!
  end
  partial :item, :item => folder # render the information about this folder

end

# Gets a file by id and returns its details.
get "/file/:file_id" do |file_id|
  account = require_login  # make sure the user is authorized
  file = account.file(file_id) # get the file by id
  user = account.info
  #FIXME: puts to logger

  logger.debug "FIle_id" + file.id
  logger.debug "Account "+user["user_id"]

  # Note: Getting a file by ID is fastest, but it won't know about its parents.
  # If you need this information, use 'account.root.find(:id => file_id)' instead.

  partial :file, :file => file # render the information about this file
end

# Displays the form for adding a new file based on the parent_id.
get "/file/add/:parent_id" do |parent_id|
  partial :add_file, :parent_id => parent_id
end

# Creates a new file with the given information.
post "/file/add/:parent_id" do |parent_id|
  account = require_login        # make sure the user is authorized
  parent = account.folder(parent_id) # get the parent folder by id

  tmpfile = params[:file][:tempfile] # get the path of the file
  name = params[:file][:filename]    # get the name of the file

  file = parent.upload(tmpfile) # upload the file by its path
  file.rename(name)             # rename the file to match its desired name

  redirect "/" # redirect to the home page
end



# Handles logout requests.
get "/logout" do
  box_logout(session)
  redirect "/" # redirect to the home page
end

EventMachine::run {
  puts "Hi"
}

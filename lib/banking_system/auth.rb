require "banking_system/utility.rb"
include Utility

# Handles authentication flow of users
class BankingSystem::Auth

    # Intialises basic dependencies
    def initialize
        @prompt = TTY::Prompt.new
        @client = BankingSystem::Database.new.dbClient
    end

    # Handles the login process of a user
    def login
        enterCredentials
        authenticate
    end

    # Asks user to enter the credentials which consists of username and password
    def enterCredentials
        @username = @prompt.ask("Enter your username?", required: true)
        @password = @prompt.mask("Enter your password?", required: true)
    end

    # Asks user to renter the password to login
    def renter_password
        @password = @prompt.mask("Enter your password?", required: true)
        authenticate
    end

    # Authenticates s user on the basis of username and password entered by him 
    def authenticate
        begin
        users = @client.query("SELECT * FROM users WHERE username='#{@username}' LIMIT 1")
        
        # If user exists by enetered username
        if users.first
            current_user = users.first
            # Checks if password enetered by the user is correct or not
            if  Utility.verify_password(current_user["password"], @password)
                @prompt.ok("Welcome #{current_user["username"]} to Maropost bank.")
                
                @banking = BankingSystem::Banking.new current_user,@client
                @banking.dashboard
            else
                @prompt.error("Username or password incorrect.")
                renter_password
            end
        else
            reautheticate_user
        end
        rescue => exception
            reautheticate_user
        end
      
    end

    # Creates a new user account 
    def signup
        enterCredentials
        create_new_user
    end

    # Creates a new user entry in the database
    def create_new_user
        begin
        # Creates hash of the password enetered by the user
        password = Utility.encrypt_password(@password)
        # Insert a new entry in the database for a user
        @client.query("
        INSERT INTO Users (username,first_name,last_name,created_at,updated_at,password)
        VALUES ('#{@username}','','','#{Utility.get_timestamp}','#{Utility.get_timestamp}','#{password}')")
        
        @prompt.ok("Account created sucessfully.")
        sleep 1
        @prompt.ok("Please login to your account => ")
        login
        rescue => exception
        @prompt.error("Invalid username enter a new one.")
        signup
        end
    end

    # Reauthenticates a user if he enters wrong password or username
    def reautheticate_user
        @prompt.error("Username or password incorrect.")
        login
    end

    private :authenticate,:reautheticate_user
end
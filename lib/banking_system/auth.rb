require "banking_system/utility.rb"
include Utility

class BankingSystem::Auth
    def initialize
        @prompt = TTY::Prompt.new
        @client = BankingSystem::Database.new.dbClient
    end

    def login
        enterCredentials
        authenticate
    end

    def enterCredentials
        @username = @prompt.ask("Enter your username?", required: true)
        @password = @prompt.mask("Enter your password?", required: true)   
    end

    def authenticate
        users = @client.query("SELECT * FROM users WHERE username='#{@username}' LIMIT 1")
        puts "user =>#{users.first}"
        
        if users.first
            current_user = users.first
            if  Utility.verify_password(current_user["password"], @password)
                @prompt.ok("Welcome #{current_user["username"]} to Maropost bank.")
            else
            @prompt.error("Username or password incorrect.")
            login
            end
        else
            @prompt.error("Username or password incorrect.")
            login
        end
    end

    def signup
        enterCredentials
        create_new_user
    end

    def create_new_user
        begin
        password = Utility.encrypt_password(@password)
        @client.query("
        INSERT INTO Users (username,first_name,last_name,created_at,updated_at,password)
        VALUES ('#{@username}','','','#{Utility.get_timestamp}','#{Utility.get_timestamp}','#{password}')")
        
        @prompt.ok("Account created sucessfully.")
        sleep 1
        @prompt.ok("Please login to your account => ")
        login
        rescue => exception
        @prompt.error(exception)   
        end
    end

    private :authenticate
end
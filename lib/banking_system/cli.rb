class BankingSystem::CLI

    def initialize
        # BankingSystem::Database.new
        @prompt = TTY::Prompt.new
        @auth = BankingSystem::Auth.new
    end

    def call
        @action = @prompt.select("What would you like to do?", %w(Login Signup Exit))
        perform_action
    end

    def perform_action
         case @action
         when "Login"
            @auth.login
         when "Signup"
            @auth.signup
         else
             puts "Exit"
             exit
         end
    end

    def exit
        puts "Exit the program"
    end

end
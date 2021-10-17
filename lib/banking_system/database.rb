require "mysql2"

class BankingSystem::Database
    def initialize
    @client = Mysql2::Client.new(:host => "localhost", :username => "root",:database => "banking")
    end

    def dbClient
        return @client
    end
end

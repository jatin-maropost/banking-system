require "banking_system/utility.rb"
include Utility

class BankingSystem::Banking
    def initialize(user,dbClient)
        @current_user = user
        @dbClient = dbClient
        @prompt = TTY::Prompt.new
    end

    def current_user_id
        return @current_user["id"]
    end

    def dashboard
        banking_choices = {
            "Deposit money to your account" => 1,
            "Withdraw money from your account" => 2,
            "Transfer money to your friend" => 3,
            "Check Balance" => 4
        }
        @choice = @prompt.select("What would you like to do with your account?", banking_choices, required: true)
        perform_action
    end

    def perform_action
        case @choice
        when 1
            deposit_money
        when 2
            withdraw_money
        when 3
        
        when 4
            @prompt.warn("Your balance is => #{user_balance current_user_id }")
            dashboard
        else
            
        end
    end

    def withdraw_money
        begin
             amount = @prompt.ask("Enter amount to be withdraw?", required: true)
        balance = user_balance current_user_id
        if Integer(amount) <= balance
            @dbClient.query("
                insert into Transactions (
                current_balance,
                trans_amount,
                transaction_type,
                transferred_by,
                transferred_to,
                created_at,
                updated_at,account_id)
                values ('#{Integer(balance) - Integer(amount)}','#{amount}','2','#{current_user_id}','#{current_user_id}'
                    ,'#{Utility.get_timestamp}','#{Utility.get_timestamp}','#{current_user_id}')")
                
            @prompt.ok("#{amount} withdraw successfully.")
            dashboard
            else
            @prompt.error("You have insufficient balance, Enter a different amount!!")
            sleep 0.3
            withdraw_money
        end
        rescue => exception
            puts exception
        end
       
    end

    private
    def deposit_money
        begin
            amount = @prompt.ask("Enter amount to be deposited?", required: true)
            @dbClient.query("
                insert into Transactions (
                current_balance,
                trans_amount,
                transaction_type,
                transferred_by,
                transferred_to,
                created_at,
                updated_at,account_id)
                values ('#{user_balance(@current_user["id"]) + Integer(amount)}','#{amount}','1','#{@current_user["id"]}','#{@current_user["id"]}'
                    ,'#{Utility.get_timestamp}','#{Utility.get_timestamp}','#{@current_user["id"]}')")
            @prompt.ok("#{amount} deposited successfully.")
            dashboard
        rescue => exception
            puts exception   
        end
    end

    def user_balance(user_id)
        begin
            trans = @dbClient.query("select current_balance from Transactions where account_id='#{user_id}' order by created_at desc limit 1")
            
            if trans.first
                return trans.first["current_balance"]
            else
                return 0
            end    
        rescue => exception
            puts exception            
        end
    end

 

end
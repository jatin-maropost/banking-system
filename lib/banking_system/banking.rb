require "tty-table"
require "banking_system/utility.rb"
include Utility

# Handles user bank transactions
class BankingSystem::Banking
    def initialize(user,dbClient)
        @current_user = user
        @dbClient = dbClient
        @prompt = TTY::Prompt.new
    end

    # Returns latest current user id
    def current_user_id
        return @current_user["id"]
    end

    # Shows banking dasboard to the user
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

    # Hanldes user selectes actions 
    # And responds on the basis of user selected action
    # whether he want to [deposit, withdraw,transfer] the money
    def perform_action
        case @choice
        when 1
            amount = @prompt.ask("Enter amount to be deposited?", required: true)
            balance =  user_balance(current_user_id) + Integer(amount)
            deposit_money amount,balance,current_user_id,current_user_id,1
        when 2
            withdraw_money
        when 3
            show_users
        when 4
            @prompt.warn("Your balance is => #{user_balance current_user_id }")
            dashboard
        else
            
        end
    end

    #  Handles money withdraw from a user account
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

    # Private methods of Banking class
    private
    # Deposit money in user account
    def deposit_money(amount,balance,deposit_to,deposit_by,trans_type)
        begin
            @dbClient.query("
                insert into Transactions (
                current_balance,
                trans_amount,
                transaction_type,
                transferred_by,
                transferred_to,
                created_at,
                updated_at,account_id)
                values ('#{balance}','#{amount}','#{trans_type}','#{deposit_by}','#{deposit_to}'
                    ,'#{Utility.get_timestamp}','#{Utility.get_timestamp}','#{deposit_to}')")
            @prompt.ok("#{amount} deposited successfully.")
            dashboard
        rescue => exception
            puts exception   
        end
    end

    # Fetches balanace of a user account on the basis of its user id
    # @returns Account balanace of the user
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

    # Show list of the users in table format with their username 
    def show_users
        users = @dbClient.query("select username,id from users where id != '#{current_user_id}'")
        if users.count > 0
            transfer_money users
        else
            @prompt.say("No accounts found.")
        end
        
    end

    # List username of the user accounts 
    def transfer_money(users)
        transfer_to_user = @prompt.ask("Enter username to tranfer money?", required: true)
        amount = Integer(@prompt.ask("Enter amount to be transferred?", required: true))
        balance = user_balance current_user_id
        
        if balance >= amount
            updated_balance = balance - amount 
            deposit_money amount,updated_balance,3,current_user_id,1
            @prompt.ok("An amount of #{amount} have been transferred to #{amount}.")
            @prompt.warn("Your account balance is #{balance - amount}.")
        else
            @prompt.error("You have insufficient balance, Enter a different amount!!")
            sleep 1
            show_users
        end

    end

end
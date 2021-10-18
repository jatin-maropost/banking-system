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

    # Returns logged in current user id
    def current_user_id
        return @current_user["id"]
    end

    # Shows banking dasboard to the user
    def dashboard
        banking_choices = {
            "Deposit money to your account" => 1,
            "Withdraw money from your account" => 2,
            "Transfer money to your friend" => 3,
            "Check Balance" => 4,
            "Show latest transactions" => 5
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
            @prompt.ok("#{amount} deposited successfully.")
            dashboard

        when 2
            amount = @prompt.ask("Enter amount to be withdraw?", required: true)
            balance = user_balance current_user_id

            withdraw_money(amount,balance,amount,current_user_id,current_user_id,3)
            @prompt.ok("#{amount} withdraw successfully.")
            dashboard
        
        when 3
            show_users
        when 4
            @prompt.warn("Your balance is => #{user_balance current_user_id }")
            dashboard

            when 5
               transactions = latest_transactions
               if transactions.count
                table = TTY::Table.new(
                    ["Trans id","Transaction Amount","Transferred on","Trsanaction Type"],
                    transactions.map {|x| x.values})
                
                # Prins transactions in table format in the console
                puts table.render(:ascii)
                dashboard
                else
                @prompt.warn("No tansactions found.")
               end

        else
            
        end
    end

    #  Handles money withdraw from a user account
    def withdraw_money(amount,balance,trans_amount,withdraw_by,deposit_to,trans_type)
        begin
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
                values ('#{Integer(balance) - Integer(amount)}','#{trans_amount}','#{trans_type}','#{withdraw_by}','#{deposit_to}'
                    ,'#{Utility.get_timestamp}','#{Utility.get_timestamp}','#{deposit_to}')")
                
            else
            @prompt.error("You have insufficient balance, Enter a different amount!!")
            sleep 0.3
            withdraw_money
        end
        rescue => exception
            puts exception
        end
       
    end

    # Fetches latest transactions of a user and returns a list of transactions
    def latest_transactions
        transactions = @dbClient.query("
            select ts.tranid,ts.trans_amount,ts.created_at,UPPER(tp.type) trans_type from transactions ts
            inner join TransactionTypes tp on ts.transaction_type = tp.id
            where ts.account_id = '#{current_user_id}'
            order by ts.created_at desc")
    return transactions
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
        begin
            users = @dbClient.query("select username,id from users where id != '#{current_user_id}'")
            if users.count > 0
                user_choices = {}
                for user in users do
                    user_choices[user["username"]] = user["id"]
                end
                transfer_money user_choices
            else
                @prompt.say("No accounts found.")
            end
        rescue => exception
            puts exception
        end
        
    end

    # List name of the accounts available and transfer the money from one user
    # to another user in fraction of seconds
    def transfer_money(users)
        # User id to whom money is to be transferred
        transfer_to_user = @prompt.select("Select user to tranfer money?", users,required: true,help: "(Select a user from the list)", show_help: :always)
        amount = Integer(@prompt.ask("Enter amount to be transferred?", required: true))
        
        balance = user_balance current_user_id
        
        if balance >= amount
            updated_balance = balance - amount 
            deposit_money(amount,updated_balance,transfer_to_user,current_user_id,1)
            withdraw_money(amount,balance,amount,current_user_id,transfer_to_user,3)
            
            @prompt.ok("An amount of #{amount} have been transferred to #{amount}.")
            @prompt.warn("Your updated  account balance is #{balance - amount}.")
            dashboard
        else
            @prompt.error("You have insufficient balance, Enter a different amount!!")
            sleep 1
            show_users
        end

    end

end
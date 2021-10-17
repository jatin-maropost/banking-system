require 'bcrypt'
module Utility

def get_timestamp
    return DateTime.now.strftime('%F %T')
end

def encrypt_password(password)
    return BCrypt::Password.create(password)     
end

def verify_password(hash,password)
    return BCrypt::Password.new(hash) == password
end

end
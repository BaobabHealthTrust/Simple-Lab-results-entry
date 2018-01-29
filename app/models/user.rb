require 'digest/sha1'
require 'digest/sha2'

class User < ActiveRecord::Base
	#devise :database_authenticatable, :token_authenticatable, :authentication_keys => [:login]

  set_table_name :users
  set_primary_key :user_id

  cattr_accessor :current
	
  def self.authenticate(username, password)
		user = User.find_by_username(username)
		if !user.blank?
			user.valid_password?(password) ? user : nil
		end
	end

	def valid_password?(password)
		return false if encrypted_password.blank?
	  	is_valid = Digest::SHA1.hexdigest("#{password}#{salt}") == encrypted_password	|| encrypt(password, salt) == encrypted_password || Digest::SHA512.hexdigest("#{password}#{salt}") == encrypted_password
	end

	def encrypted_password
		self.password
	end
   
	def self.encrypt(password,salt)
		Digest::SHA1.hexdigest(password+salt)
	end
  
  def name
    national_art = National_art
    database_name = national_art['database']

    person_name = ActiveRecord::Base.connection.select_one <<EOF
    SELECT given_name, family_name FROM #{database_name}.person_name n 
    WHERE n.voided = 0 AND n.voided = 0 AND n.person_id = #{self.person_id} 
    ORDER BY n.date_created DESC LIMIT 1;
EOF

    return "#{person_name['given_name']} #{person_name['family_name']}"
  end

end

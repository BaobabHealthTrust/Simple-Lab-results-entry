class User < ActiveRecord::Base
  set_table_name :Clinician
  set_primary_key :Clinician_ID

  cattr_accessor :current
	
  def self.authenticate(password)
    self.find(:first, :conditions =>["Clinician_ID = ?", password])
	end

  def name
    "#{self.Clinician_F_Name} #{self.Clinician_L_Name}"
  end

end

# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_LabEntry_session',
  :secret      => '45fb6bd2f9ec9e853e664640cd03f7bd8dcea49909474e5e6264b9f56123869c7e3da0dc316724f8ae520b95a252fc3e0b3664082e908a81e4126fa62cbfcc26'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store

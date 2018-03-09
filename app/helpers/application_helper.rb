# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  def app_title
    return "Lab Sample Entry"
  end
  
  def site_name
    connect_to_bart_database

    loc_name = ActiveRecord::Base.connection.select_one <<EOF
    SELECT * FROM location l
    WHERE location_id = (SELECT property_value FROM global_property g 
    WHERE property = 'current_health_center_id' LIMIT 1);
EOF

    connect_to_app_database
    return "#{loc_name['name']}"
  end
  
  def connect_to_app_database
    app_env = ApplicationDB
    ActiveRecord::Base.establish_connection(
    :adapter  => app_env['adapter'],
    :host     => app_env['host'],
    :database => app_env['database'],
    :username => app_env['username'],
    :password => app_env['password'])
  end
    
  def connect_to_bart_database
    national_art = National_ART
    ActiveRecord::Base.establish_connection(
    :adapter  => national_art['adapter'],
    :host     => national_art['host'],
    :database => national_art['database'],
    :username => national_art['username'],
    :password => national_art['password'])
  end

  def connect_to_remote_bart_database
    national_art = Remote_national_ART
    ActiveRecord::Base.establish_connection(
    :adapter  => national_art['adapter'],
    :host     => national_art['host'],
    :database => national_art['database'],
    :username => national_art['username'],
    :password => national_art['password'])
  end

end

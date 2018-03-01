# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  def app_title
    return "Lab Sample Entry"
  end
  
  def site_name
    database_name = National_art['database']

    loc_name = ActiveRecord::Base.connection.select_one <<EOF
    SELECT * FROM #{database_name}.location l
    WHERE location_id = (SELECT property_value FROM #{database_name}.global_property g 
    WHERE property = 'current_health_center_id' LIMIT 1);
EOF

    return "#{loc_name['name']}"
  end
end

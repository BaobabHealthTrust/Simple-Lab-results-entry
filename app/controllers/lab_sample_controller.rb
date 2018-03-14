class LabSampleController < ApplicationController
  def index
    connect_to_app_database
  end

  def create
    lab_sample = LabSample.create(:PATIENTID => params[:identifier], :TESTDATE => params[:test_date].to_date,
      :USERID => User.current.username, :DATE => Date.today, :TIME => Time.now().strftime('%H:%M:%S'),
      :SOURCE => 0, :Attribute => params[:test_range], :UpdateBy => User.current.username,
      :UpdateTimeStamp => Time.now().strftime('%Y-%m-%d %H:%M:%S'), :DeleteYN => 0)

    redirect_to "/sample/#{lab_sample.Sample_ID}" and return
  end

  def get_patients
   
    patients = []
     
    unless params[:search_string].blank?
      search_strings = params[:search_string].squish.split(' ')

			begin
        connect_to_bart_database
      
        (search_strings || []).each do |search_string|
          search_patients(search_string, patients)
        end
		  rescue 
        connect_to_app_database
			end

    
			begin
        connect_to_remote_bart_database
         
        (search_strings || []).each do |search_string|
          search_patients(search_string, patients)
        end
		  rescue 
        connect_to_app_database
			end

    
        
    end

    connect_to_app_database
    patients = patients.uniq
    render :text => patients.to_json
	end

	def get_samples
    connect_to_app_database

    from  = params[:start].to_i
    to    = (from + 99)
		length 				= params[:length].to_i


    column_order  = params['order']['0']['dir'].upcase
    column_number = params['order']['0']['column'].to_i
    column_name   = ['Sample_ID','AccessionNum','PATIENTID',
                    'TestOrdered','OrderDate','Clinician_F_Name','DATE',
                    'UpdateBy','TimeStamp','Attribute','']
    
    if params[:search]['value'].blank?
=begin
		  lab_samples = LabSample.find(:all, 
      :joins => "LEFT JOIN LabTestTable l ON l.AccessionNum = Lab_Sample.AccessionNum 
        LEFT JOIN Clinician c ON c.Clinician_ID = l.OrderedBy",
      :select => "Lab_Sample.*, l.TestOrdered,l.OrderDate, c.*",
      :conditions => ["Lab_Sample.DeleteYN = 0"], 
      :limit => "#{from}, #{length}",
      :order => "#{column_name[column_number]} #{column_order}")

      total_count = ActiveRecord::Base.connection.select_one <<EOF
      SELECT count(*) as total_count FROM Lab_Sample l 
      LEFT JOIN LabTestTable t ON l.AccessionNum = t.AccessionNum 
      LEFT JOIN Clinician c ON c.Clinician_ID = t.OrderedBy 
      WHERE l.DeleteYN = 0;
EOF

      total_count = total_count['total_count'].to_i
=end
      lab_samples = []
      total_count = 0
    else
      #search_str = "#{params[:search]['value']}%"
      search_str = params[:search]['value'].squish
      search_attribute = params[:search_attribute] == 1 ? 'AccessionNum' : 'PATIENTID'

		  lab_samples = LabSample.find(:all, :select => "Lab_Sample.*, l.TestOrdered, l.OrderDate, c.*",
        :joins => "LEFT JOIN LabTestTable l ON l.AccessionNum = Lab_Sample.AccessionNum 
        LEFT JOIN Clinician c ON c.Clinician_ID = l.OrderedBy",
        :conditions =>["Lab_Sample.#{search_attribute} = ? AND DeleteYN = 0", search_str],
        :limit => "#{from}, #{length}", :order => "#{column_name[column_number]} #{column_order}")

      total_count = ActiveRecord::Base.connection.select_one <<EOF
      SELECT count(*) as total_count FROM Lab_Sample l
      LEFT JOIN LabTestTable t ON l.AccessionNum = t.AccessionNum
      LEFT JOIN Clinician c ON c.Clinician_ID = t.OrderedBy 
      WHERE l.DeleteYN = 0 AND (l.#{search_attribute} = ('#{search_str}')); 
EOF

      total_count = total_count['total_count'].to_i
    end

    lab_samples_results = []
    

    (lab_samples || []).each do |l|
      lab_samples_results << [
        l.Sample_ID,
        l.AccessionNum,
        l.PATIENTID,
        l.TestOrdered,
        "#{(l.OrderDate.to_date.strftime('%d/%b/%Y') rescue nil)}",
        "#{l.Clinician_F_Name} #{l.Clinician_L_Name}",
        "#{(l.DATE.to_date.strftime('%d/%b/%Y') rescue nil)}",
        getUserName(l.UpdateBy),
        "#{(l.UpdateTimeStamp.to_time.strftime('%d/%b/%Y %H:%M:%S') rescue nil)}",
        l.Attribute,
        buildSampleBTN(l.Sample_ID)
      ]
		end

		data_table = {
			"draw" => params[:draw].to_i,
			"recordsTotal" => (total_count),
			"recordsFiltered" => (total_count),
			"data" => lab_samples_results
		} 
 

    render :text => data_table.to_json
	end

  def sample
    connect_to_app_database

    @sample = []
    lab_sample = LabSample.find(params[:sample_id])
    (lab_sample.attributes.keys || []).each_with_index do |l, i|
      attribute = lab_sample.send(lab_sample.attributes.keys[i])
      if l.upcase.match(/timestamp/i) and not attribute.blank?
        attribute = attribute.to_time.strftime('%d/%b/%Y %H:%M:%S') rescue attribute
      elsif l.upcase.match(/date/i) and not attribute.blank?
        attribute = attribute.to_date.strftime('%d/%b/%Y') rescue attribute 
      end unless attribute.blank?

      @sample << [l, attribute]
    end

    lab_test_table = ActiveRecord::Base.connection.select_one <<EOF
      SELECT * FROM LabTestTable l
      WHERE l.AccessionNum = #{lab_sample.AccessionNum};
EOF

    unless lab_test_table.blank?
      location = lab_test_table['Location']
      @sample  << ["Ordered location", "<b style='font-size: 15px; color: green;'>#{location}</b>"]
    end

    @patient_identifier = lab_sample.PATIENTID
  end

  def get_parameters
    connect_to_app_database

    from  = params[:start].to_i
    to    = (from + 99)
		length 				= params[:length].to_i


    column_order  = params['order']['0']['dir'].upcase rescue 'ASC'
    column_number = params['order']['0']['column'].to_i rescue 0
    column_name   = ['TestName','Range','TESTVALUE','TimeStamp']
    
    search_value = params[:search]['value'].upcase rescue nil
    if search_value.blank?
		  lab_parameters = LabParameter.find(:all, 
        :conditions => ["Sample_ID = ?",params[:sample_id]], 
        :joins => "INNER JOIN codes_TestType c ON c.TestType = Lab_Parameter.TESTTYPE",
        :limit => "#{from}, #{length}", :select => "Lab_Parameter.*, c.TestName",
        :order => "#{column_name[column_number]} #{column_order}")

      total_count = lab_parameters.length
    else
      search_str = "%#{params[:search]['value']}%"

		  lab_parameters = LabParameter.find(:all, 
        :conditions => ["Sample_ID = ? AND (c.TestName LIKE ('#{search_str}') 
        OR Lab_Parameter.TESTVALUE LIKE ('#{search_str}') 
        OR Lab_Parameter.TimeStamp LIKE('#{search_str}'))", params[:sample_id]], 
        :joins => "INNER JOIN codes_TestType c ON c.TestType = Lab_Parameter.TESTTYPE",
        :limit => "#{from}, #{length}", :select => "Lab_Parameter.*, c.TestName",
        :order => "#{column_name[column_number]} #{column_order}")


      total_count = ActiveRecord::Base.connection.select_one <<EOF
      SELECT count(*) as total_count FROM Lab_Parameter l 
      INNER JOIN codes_TestType c ON c.TestType = l.TESTTYPE
      WHERE l.Sample_ID = #{params[:sample_id]}
      AND (c.TestName LIKE ('#{search_str}') 
      OR l.TESTVALUE LIKE ('#{search_str}') 
      OR l.TimeStamp LIKE('#{search_str}'));
EOF

      total_count = total_count['total_count'].to_i
    end

    lab_parameter_results = []
    

    (lab_parameters || []).each do |l|
      lab_parameter_results << [
        l.TestName,
        l.Range,
        l.TESTVALUE,
        "#{(l.TimeStamp.to_time.strftime('%d/%b/%Y %H:%M:%S') rescue nil)}",
        buildParameterBTN(l.ID)
      ]
		end

		data_table = {
			"draw" => params[:draw].to_i,
			"recordsTotal" => (total_count),
			"recordsFiltered" => (total_count),
			"data" => lab_parameter_results
		} 
 

    render :text => data_table.to_json
	end

  def get_patient_details
    identifier = params[:identifier].gsub('-','').squish rescue ''

    begin
      connect_to_bart_database
    rescue
      connect_to_app_database
    end
    filing_number_location = ActiveRecord::Base.connection.select_one <<EOF
    SELECT name FROM location l 
    INNER JOIN global_property g ON g.property_value = l.location_id
    WHERE g.property = 'current_health_center_id';
EOF
        
    person_name = ActiveRecord::Base.connection.select_one <<EOF
        SELECT given_name, middle_name, family_name, gender, DATE_FORMAT(birthdate, '%d/%b/%Y') birthdate, 
        birthdate_estimated, f.identifier filing_number, d.identifier dormant_filing_number,
        "#{filing_number_location['name']}" AS location
        FROM person p
        INNER JOIN patient_identifier i ON i.patient_id = p.person_id
        LEFT JOIN person_name n ON p.person_id = n.person_id
        LEFT JOIN patient_identifier f ON p.person_id = f.patient_id 
        AND f.identifier_type = 17 AND f.voided = 0
        LEFT JOIN patient_identifier d ON p.person_id = d.patient_id 
        AND d.identifier_type = 18 AND d.voided = 0
        WHERE i.identifier = '#{identifier}' AND i.voided = 0 AND n.voided = 0 
        AND p.voided = 0 ORDER BY n.date_created DESC LIMIT 1;
EOF

    if person_name.blank?
			begin
        connect_to_remote_bart_database
		  rescue 
        connect_to_app_database
			end

			begin
				filing_number_location = ActiveRecord::Base.connection.select_one <<EOF
        SELECT name FROM location l 
        INNER JOIN global_property g ON g.property_value = l.location_id
        WHERE g.property = 'current_health_center_id';
EOF
        
				person_name = ActiveRecord::Base.connection.select_one <<EOF
        SELECT given_name, middle_name, family_name, gender, DATE_FORMAT(birthdate, '%d/%b/%Y') birthdate, 
        birthdate_estimated, f.identifier filing_number, d.identifier dormant_filing_number,
        "#{filing_number_location['name']}" AS location
        FROM person p
        INNER JOIN patient_identifier i ON i.patient_id = p.person_id
        LEFT JOIN person_name n ON p.person_id = n.person_id
        LEFT JOIN patient_identifier f ON p.person_id = f.patient_id 
        AND f.identifier_type = 17 AND f.voided = 0
        LEFT JOIN patient_identifier d ON p.person_id = d.patient_id 
        AND d.identifier_type = 18 AND d.voided = 0
        WHERE i.identifier = '#{identifier}' AND i.voided = 0 AND n.voided = 0 
        AND p.voided = 0 ORDER BY n.date_created DESC LIMIT 1;
EOF

			rescue
				
			end
    end
    
    connect_to_app_database
    render :text => person_name.to_json
  end

  def delete_lab_parameter
    connect_to_app_database
    lab_parameter_id = params[:lab_parameter_id]
    lab_parameter = LabParameter.find(lab_parameter_id)
      
    ActiveRecord::Base.connection.execute <<EOF
    CREATE TABLE IF NOT EXISTS `voided_lab_parameters` (
 		`id` int(11) NOT NULL AUTO_INCREMENT,
 		`sample_id` int(11) NOT NULL,
 		`test_type` int(11) NOT NULL,
 		`time_stamp` datetime NOT NULL,
 		`result_range` varchar(5) NOT NULL,
		 PRIMARY KEY (`id`)
	 );
EOF


    ActiveRecord::Base.connection.execute <<EOF
    INSERT INTO voided_lab_parameters
    VALUES(#{lab_parameter.ID},#{lab_parameter.Sample_ID},#{lab_parameter.TESTTYPE},'#{lab_parameter.TimeStamp.to_time.strftime('%Y-%m-%d %H:%M:%S')}','#{lab_parameter.Range}');
EOF

    ActiveRecord::Base.connection.execute <<EOF
    DELETE FROM Lab_Parameter WHERE ID = #{lab_parameter_id};
EOF

    render :text => "Delete lab parameter: #{lab_parameter_id}"    
  end

  private
  
  def getUserName(user_id)
    connect_to_bart_database

    username = user_id
    user_id = user_id.to_i

    if user_id > 0
      connect_to_app_database
      return User.find(user_id).name rescue nil
    else
      connect_to_app_database
      return username
    end
  end

  def buildParameterBTN(id)
    btn_html =<<EOF
    <table style="width: 100%;">
      <tr>
        <td><button class="btn btn-warning" onclick="editParameter(#{id});">Edit</button></td>
        <td><button class="btn btn-danger" onclick="deleteParameter(#{id});">Delete</button></td>
      </tr>
    </table>
EOF

    return btn_html
  end

  def buildSampleBTN(sample_id)
    btn_html =<<EOF
    <table style="width: 100%;">
      <tr>
        <td><button class="btn btn-primary" onclick="document.location='/sample/#{sample_id}'">Show</button></td>
        <td><button class="btn btn-danger" onclick="/void_sample/#{sample_id}">Delete</button></td>
      </tr>
    </table>
EOF

    return btn_html
  end

  def buildCreateSampleBTN(identifier)
    btn_html =<<EOF
    <table style="width: 100%;">
      <tr>
        <td><button class="btn btn-primary" onclick="document.location='/sample/#{identifier}'">Create Lab sample</button></td>
      </tr>
    </table>
EOF

    return btn_html
  end

  def search_patients(search_string, patients)

    results = ActiveRecord::Base.connection.select_all <<EOF
    SELECT 
      DISTINCT(p.person_id) patient_id ,n.given_name, n.middle_name, n.family_name, p.birthdate, p.birthdate_estimated, gender  ,
      i.identifier, p.date_created
    FROM person p 
    INNER JOIN person_name n ON p.person_id = n.person_id 
    INNER JOIN patient_identifier i ON p.person_id = i.patient_id
    WHERE i.voided = 0 AND i.identifier_type = 3 
    AND (identifier LIKE '%#{search_string}%' OR given_name LIKE '%#{search_string}%' 
    OR middle_name LIKE '%#{search_string}%' OR family_name LIKE '%#{search_string}%')
    LIMIT 10;
EOF

    (results || []).each do |result|
      patients << {
        :identifier           =>  result['identifier'],
        :given_name           =>  result['given_name'],
        :middle_name          =>  result['middle_name'],
        :family_name          =>  result['family_name'],
        :gender               =>  result['gender'],
        :birthdate            =>  "#{(result['birthdate'].to_date.strftime('%d/%b/%Y') rescue nil)}",
        :birthdate_estimated  =>  (result['birthdate_estimated'] == 1 ? true : false),
        :date_created         =>  "#{(result['date_created'].to_date.strftime('%d/%b/%Y') rescue nil)}",
      }
    end
  end

end

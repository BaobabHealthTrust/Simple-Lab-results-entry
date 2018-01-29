class LabSampleController < ApplicationController
  def index
    @lab_samples = LabSample.find(:all, :limit => "0, 99", :order => "TimeStamp DESC")
  end

	def get_samples
		#raise params[:search].inspect
	  #location = []
    from  = params[:start].to_i
    to    = (from + 99)
		length 				= params[:length].to_i


    column_order  = params['order']['0']['dir'].upcase
    column_number = params['order']['0']['column'].to_i
    column_name   = ['AccessionNum','PATIENTID',
                    'TESTDATE','USERID','DATE',
                    'UpdateBy','TimeStamp','Attribute','']
    
    if params[:search]['value'].blank?
		  lab_samples = LabSample.find(:all, :conditions => ["DeleteYN = 0"], 
      :limit => "#{from}, #{length}",
      :order => "#{column_name[column_number]} #{column_order}")

      #total_count = LabSample.find(:all, :conditions =>["DeleteYN = 0"]).count
      total_count = ActiveRecord::Base.connection.select_one <<EOF
      SELECT count(*) as total_count FROM Lab_Sample WHERE DeleteYN = 0;
EOF

      total_count = total_count['total_count'].to_i

    else
      search_str = "%#{params[:search]['value']}%"

		  lab_samples = LabSample.find(:all, 
        :conditions =>["AccessionNum LIKE (?) OR PATIENTID LIKE (?) OR TESTDATE LIKE (?) 
        OR USERID LIKE(?) OR UpdateBy LIKE (?) OR Attribute LIKE(?) AND DeleteYN = 0", 
        search_str, search_str, search_str, search_str, search_str, search_str], 
        :limit => "#{from}, #{length}", :order => "#{column_name[column_number]} #{column_order}")

		  #lab_samples_count = LabSample.find(:all, 
       # :conditions =>["AccessionNum LIKE (?) OR PATIENTID LIKE (?) OR TESTDATE LIKE (?) 
        #OR USERID LIKE(?) OR UpdateBy LIKE (?) OR Attribute LIKE(?) AND DeleteYN = 0", 
        #search_str, search_str, search_str, search_str, search_str, search_str], 
        #:order => "TimeStamp DESC").count

      total_count = ActiveRecord::Base.connection.select_one <<EOF
      SELECT count(*) as total_count FROM Lab_Sample WHERE DeleteYN = 0
      AND (AccessionNum LIKE ('#{search_str}') OR PATIENTID LIKE ('#{search_str}') 
      OR TESTDATE LIKE ('#{search_str}') 
      OR USERID LIKE('#{search_str}') OR UpdateBy LIKE ('#{search_str}') 
      OR Attribute LIKE('#{search_str}'));
EOF

      total_count = total_count['total_count'].to_i
    end

    lab_samples_results = []
    

    (lab_samples || []).each do |l|
      lab_samples_results << [
        l.AccessionNum,
        l.PATIENTID,
        l.TESTDATE,
        getUserName(l.USERID),
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
    @sample = []
    lab_sample = LabSample.find(params[:sample_id])
    (lab_sample.attributes.keys || []).each_with_index do |l, i|
      attribute = lab_sample.send(lab_sample.attributes.keys[i])
      if l.upcase.match(/timestamp/i) and not attribute.blank?
        attribute = attribute.to_time.strftime('%d/%b/%Y %H:%M:%S')
      elsif l.upcase.match(/date/i) and not attribute.blank?
        attribute = attribute.to_date.strftime('%d/%b/%Y') rescue attribute 
      end unless attribute.blank?

      @sample << [l, attribute]
    end

    @patient_identifier = lab_sample.PATIENTID
  end

  def get_parameters
		#raise params[:search].inspect
	  #location = []
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
    national_art = National_art
    database_name = national_art['database']
    identifier = params[:identifier]

    person_name = ActiveRecord::Base.connection.select_one <<EOF
    SELECT given_name, middle_name, family_name, gender, DATE_FORMAT(birthdate, '%d/%b/%Y') birthdate, 
    birthdate_estimated,
    a.address1, a.address2, a.city_village, a.state_province
    FROM #{database_name}.person p
    INNER JOIN #{database_name}.patient_identifier i ON i.patient_id = p.person_id
    INNER JOIN #{database_name}.person_name n ON p.person_id = n.person_id
    INNER JOIN #{database_name}.person_address a ON p.person_id = a.person_id
    WHERE identifier = '#{identifier}' AND i.voided = 0 AND n.voided = 0 
    AND p.voided = 0 AND a.voided = 0
    ORDER BY n.date_created DESC LIMIT 1;
EOF

    
    render :text => person_name.to_json
  end

  def delete_lab_parameter
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
    username = user_id
    user_id = user_id.to_i

    if user_id > 0
      return User.find(user_id).name rescue nil
    else
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

end

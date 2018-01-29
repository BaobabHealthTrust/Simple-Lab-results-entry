class LabParameterController < ApplicationController
  def index
    @lab_parameters = LabParameter.find(:all,
    :joins => "INNER JOIN codes_TestType c 
    ON c.TestType = Lab_Parameter.TESTTYPE",
    :order => "TimeStamp DESC",:limit => 10,
    :select => "Lab_Parameter.*, c.TestName")
  end

  def lab_parameter_search
    lab_parameters = LabParameter.find(:all,
    :conditions =>["#{params[:search_para]} LIKE (?)", "#{params[:search_str]}%"],
    :joins => "INNER JOIN codes_TestType c 
    ON c.TestType = Lab_Parameter.TESTTYPE",
    :order => "TimeStamp DESC",
    :select => "Lab_Parameter.*, c.TestName")

    results = []
    (lab_parameters || []).each do |l|
      results << {:sample_id => l.Sample_ID,
        :test_name => l.TestName, :test_value => "#{l.Range} #{l.TESTVALUE}",
        :test_date => l.TimeStamp.strftime('%d/%b/%Y'),
        :test_time => l.TimeStamp.strftime('%H:%M:%S') }
    end

    render :text => results.to_json 
  end

  def create
    #{"test_value"=>"122.3", "sample_id"=>"175598", "test_type"=>"9", "range"=>"=", "date"=>"2018-01-29"}
    begin
      parameter_id  = params[:parameter_id].to_i
      lab_parameter = LabParameter.find(parameter_id)
      lab_parameter.update_attributes(:Sample_ID => params[:sample_id], :TESTTYPE => params[:test_type],
        :TESTVALUE => params[:test_value], :Range => params[:range], 
        :TimeStamp => params[:date].to_time.strftime('%Y-%m-%d 00:00:01'))
    rescue
      lab_parameter = LabParameter.create(:Sample_ID => params[:sample_id], :TESTTYPE => params[:test_type],
        :TESTVALUE => params[:test_value], :Range => params[:range], 
        :TimeStamp => params[:date].to_time.strftime('%Y-%m-%d 00:00:01'))
    end

    render :text => lab_parameter.to_json
  end

end

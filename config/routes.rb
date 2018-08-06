ActionController::Routing::Routes.draw do |map|
  # The priority is based upon order of creation: first created -> highest priority.

  # Sample of regular route:
  #   map.connect 'products/:id', :controller => 'catalog', :action => 'view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   map.purchase 'products/:id/purchase', :controller => 'catalog', :action => 'purchase'
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   map.resources :products

  # Sample resource route with options:
  #   map.resources :products, :member => { :short => :get, :toggle => :post }, :collection => { :sold => :get }

  # Sample resource route with sub-resources:
  #   map.resources :products, :has_many => [ :comments, :sales ], :has_one => :seller
  
  # Sample resource route with more complex sub-resources
  #   map.resources :products do |products|
  #     products.resources :comments
  #     products.resources :sales, :collection => { :recent => :get }
  #   end

  # Sample resource route within a namespace:
  #   map.namespace :admin do |admin|
  #     # Directs /admin/products/* to Admin::ProductsController (app/controllers/admin/products_controller.rb)
  #     admin.resources :products
  #   end

  # You can have the root of your site routed with map.root -- just remember to delete public/index.html.
  # map.root :controller => "welcome"
  
  map.root :controller => "home"
	map.clinic  '/', :controller => 'home', :action => 'index'
	map.clinic  '/login', :controller => 'user', :action => 'login'
	map.clinic  '/logout', :controller => 'user', :action => 'logout'
	map.clinic  '/lab_parameter', :controller => 'lab_parameter', :action => 'index'
	map.clinic  '/lab_sample', :controller => 'lab_sample', :action => 'index'
	map.clinic  '/lab_parameter_search', :controller => 'lab_parameter', :action => 'lab_parameter_search'
	map.clinic  '/get_samples', :controller => 'lab_sample', :action => 'get_samples'
	map.clinic  '/sample/:sample_id', :controller => 'lab_sample', :action => 'sample'
	map.clinic  '/void_sample/:sample_id', :controller => 'lab_sample', :action => 'void_sample'
	map.clinic  '/get_parameters/:sample_id', :controller => 'lab_sample', :action => 'get_parameters'
	map.clinic  '/get_patient_details/:identifier', :controller => 'lab_sample', :action => 'get_patient_details'
	map.clinic  '/delete_lab_parameter/:lab_parameter_id', :controller => 'lab_sample', :action => 'delete_lab_parameter'
	map.clinic  '/create_lab_parameter', :controller => 'lab_parameter', :action => 'create'
	map.clinic  '/find_patient', :controller => 'lab_sample', :action => 'patient'
	map.clinic  '/get_patients/:search_string', :controller => 'lab_sample', :action => 'get_patients'
	map.clinic  '/create_sample/:identifier', :controller => 'lab_sample', :action => 'create_sample'
	map.clinic  '/create_sample_id/:accession_num', :controller => 'lab_sample', :action => 'create_sample_id'

  # See how all your routes lay out with "rake routes"

  # Install the default routes as the lowest priority.
  # Note: These default routes make all actions in every controller accessible via GET requests. You should
  # consider removing or commenting them out if you're using named routes and resources.
  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'
end

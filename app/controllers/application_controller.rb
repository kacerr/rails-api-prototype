#class ApplicationController < ActionController::API
class ApplicationController < ActionController::Base
  include ActionController::MimeResponds
  include ActionController::ImplicitRender  

  include Authenticable
end

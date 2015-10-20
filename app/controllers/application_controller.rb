#class ApplicationController < ActionController::API
class ApplicationController < ActionController::Base
  include ActionController::MimeResponds
  include ActionController::ImplicitRender  

  include Authenticable

  if ::Rails.application.config.etlogger
    require "./lib/et_support/logger.rb"
    unless $et_logger 
      $et_logger = ET::Logger.instance
      $et_logger.configure (
        {
          path: ::Rails.application.config.etlogger.path
        }
      )
    end
  end

end

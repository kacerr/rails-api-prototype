class Api::V1::AmadeusClientController < ApplicationController
  require './lib/amadeus/amadeus-client/client.rb'

  before_action :authenticate_with_token!

  respond_to :json

  def raw_query
    ac = Amadeus::AmadeusClient.new "AMADEUS"
    ac.xml_content = params[:xmlQuery]
    ac.endpoint = params[:amadeusEndpoint]
    soap_request = ac.generate_soap_request
    soap_result = ac.post_xml Amadeus::AmadeusClient::MAIN_URL, soap_request
    doc = Nokogiri::XML(soap_result.body)
    output = {}
    output["xmlContent"] = doc.serialize
    output["resultCode"] = soap_result.code
    output["header"] = soap_result.header
    output["timestamp"] = Time.now.to_s
    render json: output
  end

  def search_flight
    start_time = Time.now
    adults = []
    counter = 0
    for i in (params[:adults].to_i).downto(1)
      counter += 1
      traveller = {}
      traveller[:ptc] = "ADT"
      traveller[:id] = counter
      adults << traveller
    end

    children = []
    for i in (params[:children].to_i).downto(1)
      counter += 1
      traveller = {}
      traveller[:ptc] = "CH"
      traveller[:id] = counter
      children << traveller
    end

    infants = []
    counter = 0
    for i in (params[:infants].to_i).downto(1)
      counter += 1
      traveller = {}
      traveller[:ptc] = "INF"
      traveller[:id] = counter
      infants << traveller
    end

    template_locals = {}
    template_locals[:from] = params[:from]
    template_locals[:to] = params[:to]
    template_locals[:adults] = adults
    template_locals[:children] = children
    template_locals[:infants] = infants
    template_locals[:total_number_of_units] = params[:adults].to_i + params[:children].to_i
    template_locals[:number_of_requested_results] = 10

    template_locals[:departure_date] = params[:departureDate].to_datetime.strftime("%d%m%y")
    template_locals[:departure_time] = params[:departureDate].to_datetime.strftime("%H%M")
    template_locals[:departure_time_window] = 3
    template_locals[:departure_time_window] = params[:departureTimeWindow] if params[:departureTimeWindow].to_i>0

    template_locals[:return_date] = params[:returnDate].to_datetime.strftime("%d%m%y")
    template_locals[:return_time] = params[:returnDate].to_datetime.strftime("%H%M")
    template_locals[:return_time_window] = 3
    template_locals[:return_time_window] = params[:returnTimeWindow] if params[:returnTimeWindow].to_i>0

    template_locals[:flight_type] = "C"
    template_locals[:flight_type] = "D" if params[:directFlight]=='true'



    request = render_to_string "api/v1/amadeus_queries/search_flight.xml", locals: template_locals
    # clean up comments from XML
    doc = Nokogiri::XML::Document.parse request
    doc.xpath('//comment()').remove
    request = doc.serialize.gsub(/\n(\s*\n)+/,"\n")
    $et_logger.save_to_file(1, request, { prefix: 'xml-request'})


    ac = Amadeus::AmadeusClient.new "AMADEUS"
    ac.xml_content = request
    #binding.pry
    #a=1
    ac.endpoint = ac.get_endpoint_target_by_label 'MasterPricer'
    soap_request = ac.generate_soap_request
    soap_result = ac.post_xml Amadeus::AmadeusClient::MAIN_URL, soap_request
    
    $et_logger.save_to_file(1, soap_result.body, { prefix: 'xml-response'})
    doc = Nokogiri::XML(soap_result.body)


    recommendations = []
    ### --- parse XML document 
    doc.remove_namespaces!

    doc.xpath("//Body/Fare_MasterPricerTravelBoardSearchReply/recommendation").each do |r|
      recommendation = {}
      recommendation[:price_1] = r.xpath("recPriceInfo/monetaryDetail[1]/amount").first.content
      recommendation[:price_2] = r.xpath("recPriceInfo/monetaryDetail[2]/amount").first.content

      counter = 0
      r.xpath("segmentFlightRef/referencingDetail").each do |d|
        if d.xpath("refQualifier").first.content == "S"
          counter += 1
          flight_detail_number = d.xpath("refNumber").first.content
          group_of_flights = doc.xpath("//Body/Fare_MasterPricerTravelBoardSearchReply/flightIndex[#{counter}]/groupOfFlights[#{flight_detail_number}]")

          attr_name = "group_of_flights_#{counter}".to_sym
          recommendation[attr_name] = parse_group_of_flights group_of_flights
        end
      end
      recommendations << recommendation
    end

    ### --- parse XML document end

    output = {}
    output[:xmlContent] = doc.serialize
    output[:resultCode] = soap_result.code
    output[:header] = soap_result.header
    output[:timestamp] = Time.now.to_s
    output[:request] = request
    output[:parsedRecommendations] = recommendations.to_json

    finished_time = Time.now
    output[:timeToProcess] = finished_time - start_time

    #binding.pry
    #a=1

    render json: output
  end

  # --- this needs to be moved into another place: amadeus::parser ... ???
  def parse_group_of_flights data_to_parse
    out = {}
    counter = 0
    data_to_parse.xpath("flightDetails").each do |fd|
      counter += 1
      flight_segment_detail = {}
      flight_segment_detail[:dateOfDeparture] = fd.xpath("flightInformation/productDateTime/dateOfDeparture").first.content
      flight_segment_detail[:timeOfDeparture] = fd.xpath("flightInformation/productDateTime/timeOfDeparture").first.content
      flight_segment_detail[:dateOfArrival] = fd.xpath("flightInformation/productDateTime/dateOfArrival").first.content
      flight_segment_detail[:timeOfArrival] = fd.xpath("flightInformation/productDateTime/timeOfArrival").first.content
      flight_segment_detail[:from] = fd.xpath("flightInformation/location[1]/locationId").first.content
      flight_segment_detail[:to] = fd.xpath("flightInformation/location[2]/locationId").first.content
      attr_name = "segment_#{counter}".to_sym
      out[attr_name] = flight_segment_detail
    end
    out

  end
end

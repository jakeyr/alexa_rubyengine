# Alexa RubyEngine
# This Engine receives and responds to Amazon Echo's (Alexa) JSON requests.
require 'sinatra'
require 'json'
require 'bundler/setup'
require 'alexa_rubykit'
require 'muni'
require 'active_support/core_ext/string'

# We must return application/json as our content type.
before do
  content_type('application/json')
end

#enable :sessions
post '/' do
  # Check that it's a valid Alexa request
  request_json = JSON.parse(request.body.read.to_s)
  # Creates a new Request object with the request parameter.
  request = AlexaRubykit.build_request(request_json)

  # We can capture Session details inside of request.
  # See session object for more information.
  session = request.session
  p session.new?
  p session.has_attributes?
  p session.session_id
  p session.user_defined?

  # We need a response object to respond to the Alexa.
  response = AlexaRubykit::Response.new

  # We can manipulate the request object.
  #
  #p "#{request.to_s}"
  #p "#{request.request_id}"

  # Response
  # If it's a launch request
  if (request.type == 'LAUNCH_REQUEST')
    # Process your Launch Request
    # Call your methods for your application here that process your Launch Request.
    #response.add_speech('Ruby running ready!')
    #response.add_hash_card( { :title => 'Ruby Run', :subtitle => 'Ruby Running Ready!' } )
  end

  if (request.type == 'INTENT_REQUEST')
    # Process your Intent Request
    p "#{request.slots}"
    p "#{request.slots['Bus']['value']}"

    direction = request.slots['Direction']['value'].start_with?("in") ? "inbound" : "outbound"

    preds = []
    Muni::Route.find(request.slots['Bus']['value']).method(direction).call.stop_at("Sansome and Sutter").predictions.each do |pred|
      p pred.pretty_time
      break if pred.pretty_time == "about 1 hour"
      preds << pred.pretty_time
    end

    response.add_speech("The #{request.slots['Bus']['value']} bus going #{direction} will be arriving in #{preds.to_sentence}")
    #response.add_hash_card( { :title => 'Ruby Intent', :subtitle => "Intent #{request.name}" } )
  end

  if (request.type =='SESSION_ENDED_REQUEST')
    # Wrap up whatever we need to do.
    p "#{request.type}"
    p "#{request.reason}"
    halt 200
  end

  # Return response
  response.build_response
end

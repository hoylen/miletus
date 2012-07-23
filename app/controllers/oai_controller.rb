require 'miletus/output/oaipmh/record_provider'

class OaiController < ApplicationController

  def initialize
    @provider = Miletus::Output::OAIPMH::RecordProvider.new
  end

  def index
    # Remove controller and action from the options.
    # (Rails adds them automatically.)
    options = params.delete_if { |k,v| %w{controller action}.include?(k) }
    options['url'] = "#{request.base_url}/oai"
    response =  @provider.process_request(options)
    render :text => response, :content_type => 'text/xml'
  end
end

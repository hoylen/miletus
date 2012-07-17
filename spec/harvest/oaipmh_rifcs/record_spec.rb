require 'spec_helper'
require 'miletus/harvest/oaipmh_rifcs/record'

describe Miletus::Harvest::OAIPMH::RIFCS::Record do

  it "is creatable with no arguments" do
    Miletus::Harvest::OAIPMH::RIFCS::Record.new()
  end

  it "is creatable using an OAI::Record" do
    oaiRecord = Struct.new(:header, :metadata).new(
        Struct.new(:identifier, :datestamp, :status) do
          def deleted?
            self.status == 'deleted'
          end
        end.new(
          'http://example.test/1',
          DateTime.now),
        LibXML::XML::Node.new('xml'))
    oaiRecord.header.should respond_to :'deleted?'
    record = Miletus::Harvest::OAIPMH::RIFCS::Record.from_oai(oaiRecord)
    record.identifier.should == oaiRecord.header.identifier
    record.datestamp.should == oaiRecord.header.datestamp
    record.metadata.should == oaiRecord.metadata
  end

  it "converts to an OAI::Record" do
    record = Miletus::Harvest::OAIPMH::RIFCS::Record.new(
      :identifier => 'http://example.test/1',
      :datestamp => DateTime.now,
      :metadata => '<xml/>')
    oaiRecord = record.to_oai
    record.identifier.should == oaiRecord.header.identifier
    record.datestamp.should == oaiRecord.header.datestamp
    record.metadata.should == oaiRecord.metadata
  end

end
require 'spec_helper'

describe RifcsRecordObserver do

  subject { RifcsRecordObserver.instance }

  it { should respond_to(:after_create, :after_update) }

  def create_input_record(type = 'party', fixture_id = 1)
    # Load data from fixture
    fixture_file = File.join(File.dirname(__FILE__),
      '..', 'fixtures',"rifcs-#{type}-#{fixture_id}.xml")
    xml = File.open(fixture_file) { |f| f.read }
    # Create collection
    rc = Miletus::Harvest::OAIPMH::RIFCS::RecordCollection.create(
      :endpoint => 'http://example.test/oai'
    )
    # Create record
    Miletus::Harvest::OAIPMH::RIFCS::Record.new.tap do |r|
      r.record_collection = rc
      r.identifier = 'http://example.test/1'
      r.datestamp = Time.now
      r.metadata = Nokogiri::XML(xml).tap do |doc|
        old_root = doc.root
        doc.root = Nokogiri::XML::Node.new('metadata', doc)
        doc.root << old_root
      end.to_s
      r.save!
    end
  end

  it "should create a new concept for a new harvested record" do
    # Disable delayed run for hooks
    RifcsRecordObserver.stub(:run_job).and_return { |j| j.run }
    input_record = create_input_record
    # Run hook - which will happen as part of the environment
    # subject.after_create(input_record)
    # A new concept should exist as a result
    concept = Miletus::Merge::Concept.find(:first)
    concept.should_not be(nil)
    concept.to_rif.should_not be(nil)
    doc = Nokogiri::XML(concept.to_rif)
    doc.at_xpath('/rif:registryObjects', ns_decl).should_not be_nil
  end

  it "should update concept when the harvested record changes" do
    # Disable delayed run for hooks
    RifcsRecordObserver.stub(:run_job).and_return { |j| j.run }
    input_record = create_input_record
    # Run hook - which will happen as part of the environment
    # subject.after_create(input_record)
    Miletus::Merge::Concept.all.count.should == 1
    # A new concept should exist as a result
    concept = Miletus::Merge::Concept.find(:first)
    concept.should_not be_nil
    concept.to_rif.should_not be_nil
    # Change input record
    input_record.reload
    doc = Nokogiri::XML(input_record.metadata)
    nodes = doc.xpath("//rif:namePart[@type='given'][text()='John']",
      'rif' => 'http://ands.org.au/standards/rif-cs/registryObjects')
    nodes.each do |e|
      e.remove
    end
    input_record.metadata = doc
    input_record.save!
    # Run hook - which will happen as part of the environment
    # subject.after_update(input_record)
    # Check the concept was updated
    Miletus::Merge::Concept.all.count.should == 1
    concept = Miletus::Merge::Concept.find(:first)
    rifcs_doc = Nokogiri::XML::Document.parse(concept.to_rif)
    rifcs_doc.xpath("//rif:namePart[@type='given'][text()='John']",
      'rif' => 'http://ands.org.au/standards/rif-cs/registryObjects')\
       .should be_empty
  end

  it "should delete facets when the harvested record is deleted" do
    # Disable delayed run for hooks
    RifcsRecordObserver.stub(:run_job).and_return { |j| j.run }
    input_record = create_input_record
    # Run hook - which will happen as part of the environment
    # subject.after_create(input_record)
    Miletus::Merge::Concept.all.count.should == 1
    # A new record should exist as a result
    concept = Miletus::Merge::Concept.find(:first)
    concept.should_not be_nil
    concept.to_rif.should_not be_nil
    # Delete input record
    input_record.reload
    input_record.deleted = true
    input_record.save!
    # Run hook - which will happen as part of the environment
    # subject.after_update(input_record)
    # Check the record was updated
    Miletus::Merge::Concept.all.count.should == 1
    concept = Miletus::Merge::Concept.find(:first)
    concept.should_not be_nil
    concept.to_rif.should be_nil
  end

  it "should merge output record data when identifiers match" do
    # Disable delayed run for hooks
    RifcsRecordObserver.stub(:run_job).and_return { |j| j.run }
    input_record_1 = create_input_record('party', 1)
    # Run hook - which will happen as part of the environment
    # subject.after_create(input_record)
    Miletus::Merge::Concept.all.count.should == 1
    # Run hook - which will happen as part of the environment
    input_record_2 = create_input_record('party', '1b')
    Miletus::Merge::Concept.all.count.should == 1
    # A new record should exist as a result
    concept = Miletus::Merge::Concept.find(:first)
    concept.should_not be(nil)
    concept.to_rif.should_not be(nil)
    concept.should have(2).facets
  end

end

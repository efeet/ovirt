require 'spec_helper'
require 'rest-client'

describe Ovirt::Service do
  let(:service) { build(:service) }

  context "#resource_post" do
    it "raises Ovirt::Error if HTTP 409 response code received" do
      error_detail = "API error"
      return_data = <<-EOX.chomp
<action>
    <fault>
        <detail>#{error_detail}</detail>
    </fault>
</action>
EOX

      rest_client = double('rest_client').as_null_object
      rest_client.should_receive(:post) do |&block|
        return_data.stub(:code).and_return(409)
        block.call(return_data)
      end

      service.stub(:create_resource).and_return(rest_client)
      expect { service.resource_post('uri', 'data') }.to raise_error(Ovirt::Error, error_detail)
    end

    it "raises Ovirt::Error if HTTP 409 response code received" do
      error_detail = "Usage message"
      return_data = <<-EOX.chomp
<usage_message>
  <message>#{error_detail}</message>
</usage_message>
EOX

      rest_client = double('rest_client').as_null_object
      rest_client.should_receive(:post) do |&block|
        return_data.stub(:code).and_return(409)
        block.call(return_data)
      end

      service.stub(:create_resource).and_return(rest_client)
      expect { service.resource_post('uri', 'data') }.to raise_error(Ovirt::UsageError, error_detail)
    end
  end

  it "#resource_get on exception" do
    service.stub(:create_resource).and_raise(Exception, "BLAH")
    expect { service.resource_get('api') }.to raise_error(Exception, "BLAH")
  end

  context ".ovirt?" do
    it "false when ResourceNotFound" do
      described_class.any_instance.should_receive(:engine_ssh_public_key).and_raise(RestClient::ResourceNotFound)
      described_class.ovirt?(:server => "127.0.0.1").should be false
    end

    it "true when key non-empty" do
      fake_key = "ssh-rsa " + ("A" * 372) + " ovirt-engine\n"
      described_class.any_instance.should_receive(:engine_ssh_public_key).and_return(fake_key)
      described_class.ovirt?(:server => "127.0.0.1").should be true
    end

    it "false when key empty" do
      fake_key = "\n"
      described_class.any_instance.should_receive(:engine_ssh_public_key).and_return(fake_key)
      described_class.ovirt?(:server => "127.0.0.1").should be false
    end
  end

  context "#base_uri" do
    let(:defaults) { {:username => nil, :password => nil}}
    subject { described_class.new(defaults.merge(@options)).send(:base_uri) }

    it "ipv4" do
      @options = {:server => "127.0.0.1"}
      subject.should == "https://127.0.0.1:443"
    end

    it "ipv6" do
      @options = {:server => "::1"}
      subject.should == "https://[::1]:443"
    end

    it "hostname" do
      @options = {:server => "nobody.com"}
      subject.should == "https://nobody.com:443"
    end

    it "port 4443" do
      @options = {:server => "nobody.com", :port => 4443}
      subject.should == "https://nobody.com:4443"
    end

    it "blank port" do
      @options = {:server => "nobody.com", :port => ""}
      subject.should == "https://nobody.com"
    end

    it "nil port uses defaults" do
      @options = {:server => "nobody.com", :port => nil}
      subject.should == "https://nobody.com:443"
    end
  end
end

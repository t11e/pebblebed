require 'pebblebed/river'

# Note to readers. This is verbose and ugly
# because I'm trying to understand what I'm doing.
# When I do understand it, I'll clean up the tests.
# Until then, please just bear with me.
# Or explain it to me :)
describe Pebblebed::River do

  after(:each) do
    Pebblebed::River.purge
    Pebblebed::River.disconnect
  end

  it "is disconnected by default" do
    Pebblebed::River.should_not be_connected
  end

  it "will connect if you tell it to" do
    Pebblebed::River.connect
    Pebblebed::River.should be_connected
  end

  it "will connect if you try to publish something" do
    # guard
    Pebblebed::River.should_not be_connected

    Pebblebed::River.publish(:event => :test, :uid => '123', :attributes => {:a => 'b'})
    Pebblebed::River.should be_connected
  end

  it "connects if you try to talk to the exchange" do
    # guard
    Pebblebed::River.should_not be_connected

    Pebblebed::River.exchange
    Pebblebed::River.should be_connected
  end

  it "disconnects" do
    Pebblebed::River.connect
    Pebblebed::River.should be_connected

    Pebblebed::River.disconnect
    Pebblebed::River.should_not be_connected
  end

  describe "the exchange" do
    subject { Pebblebed::River.exchange }

    its(:name) { should eq('pebblebed.river') }
    its(:type) { should eq(:topic) }
  end

  describe "publishing" do
    after(:each) do
      @queue.delete
    end

    it "gets selected messages" do
      @queue = Pebblebed::River.queue_me('carnivore', :key => 'rspec.*')

      @queue.message_count.should eq(0)
      Pebblebed::River.publish(:event => 'smile', :source => 'rspec', :uid => '1', :attributes => {:a => 'b'})
      Pebblebed::River.publish(:event => 'frown', :source => 'rspec', :uid => '2', :attributes => {:a => 'b'})
      Pebblebed::River.publish(:event => 'laugh', :source => 'testunit', :uid => '3', :attributes => {:a => 'b'})
      @queue.message_count.should eq(2)
    end

    it "gets everything if it connects without a key" do
      @queue = Pebblebed::River.queue_me('carnivore')

      @queue.message_count.should eq(0)
      Pebblebed::River.publish(:event => 'smile', :source => 'rspec', :uid => '1', :attributes => {:a => 'b'})
      Pebblebed::River.publish(:event => 'frown', :source => 'rspec', :uid => '2', :attributes => {:a => 'b'})
      Pebblebed::River.publish(:event => 'laugh', :source => 'testunit', :uid => '3', :attributes => {:a => 'b'})
      @queue.message_count.should eq(3)
    end

    it "sends messages as json" do
      @queue = Pebblebed::River.queue_me('carnivore')
      Pebblebed::River.publish(:event => 'smile', :source => 'rspec', :uid => '1', :attributes => {:a => 'b'})
      JSON.parse(@queue.pop[:payload])['uid'].should eq('1')
    end

  end

end

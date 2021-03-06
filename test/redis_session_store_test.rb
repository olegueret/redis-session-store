require 'minitest/autorun'
require 'minitest/mock'
require File.expand_path('../fake_action_controller_session_abstract_store', __FILE__)
require 'redis-session-store'

describe RedisSessionStore do
  def random_string
    "#{rand}#{rand}#{rand}"
  end

  def options
    {}
  end

  def store
    RedisSessionStore.new(nil, options)
  end

  def default_options
    store.instance_variable_get(:@default_options)
  end

  it 'assigns a :namespace to @default_options' do
    default_options[:namespace].must_equal 'rack:session'
  end

  describe 'when initializing with the redis sub-hash options' do
    def options
      {
        :key => random_string,
        :secret => random_string,
        :redis => {
          :host => 'hosty.local',
          :port => 16379,
          :db => 2,
          :key_prefix => 'myapp:session:',
          :expire_after => 60 * 120
        }
      }
    end

    it 'creates a redis instance' do
      store.instance_variable_get(:@redis).wont_equal nil
    end

    it 'assigns the :host option to @default_options' do
      default_options[:host].must_equal 'hosty.local'
    end

    it 'assigns the :port option to @default_options' do
      default_options[:port].must_equal 16379
    end

    it 'assigns the :db option to @default_options' do
      default_options[:db].must_equal 2
    end

    it 'assigns the :key_prefix option to @default_options' do
      default_options[:key_prefix].must_equal 'myapp:session:'
    end

    it 'assigns the :expire_after option to @default_options' do
      default_options[:expire_after].must_equal 60 * 120
    end
  end

  describe 'when initializing with top-level redis options' do
    def options
      {
        :key => random_string,
        :secret => random_string,
        :host => 'hostersons.local',
        :port => 26379,
        :db => 4,
        :key_prefix => 'appydoo:session:',
        :expire_after => 60 * 60
      }
    end

    it 'creates a redis instance' do
      store.instance_variable_get(:@redis).wont_equal nil
    end

    it 'assigns the :host option to @default_options' do
      default_options[:host].must_equal 'hostersons.local'
    end

    it 'assigns the :port option to @default_options' do
      default_options[:port].must_equal 26379
    end

    it 'assigns the :db option to @default_options' do
      default_options[:db].must_equal 4
    end

    it 'assigns the :key_prefix option to @default_options' do
      default_options[:key_prefix].must_equal 'appydoo:session:'
    end

    it 'assigns the :expire_after option to @default_options' do
      default_options[:expire_after].must_equal 60 * 60
    end
  end

  describe 'when initializing with store_expire_after' do
    def options
      {
        :key => random_string,
        :secret => random_string,
        :redis => {
          :host => 'hosty.local',
          :port => 16379,
          :db => 2,
          :key_prefix => 'myapp:session:',
          :store_expire_after => 60 * 180
        }
      }
    end

    it 'creates a redis instance' do
      store.instance_variable_get(:@redis).wont_equal nil
    end

    it 'doesn\'t assign the :expire_after option to @default_options' do
      default_options[:expire_after].must_be_nil
    end

    it 'assigns the :store_expire_after option to @default_options' do
      default_options[:store_expire_after].must_equal 60 * 180
    end

    it 'uses store_expire_after to set expiry' do
      st = store

      env_mock = Minitest::Mock.new
      env_mock.expect(:[], default_options, ['rack.session.options'])

      sid = '1234'
      session_data = 'abc'

      key = st.send(:prefixed, sid)
      mock = Minitest::Mock.new
      mock.expect(:setex, true, [key, 60 * 180, Marshal.dump(session_data)])

      st.instance_variable_set(:@redis, mock)
      
      st.send(:set_session, env_mock, sid, session_data).must_equal true

      env_mock.verify
      mock.verify
    end
  end

  describe 'when initializing with both expire_after and store_expire_after' do
    def options
      {
        :key => random_string,
        :secret => random_string,
        :redis => {
          :host => 'hosty.local',
          :port => 16379,
          :db => 2,
          :key_prefix => 'myapp:session:',
          :expire_after => 60 * 30,
          :store_expire_after => 60 * 90
        }
      }
    end

    it 'creates a redis instance' do
      store.instance_variable_get(:@redis).wont_equal nil
    end

    it 'assigns the :expire_after option to @default_options' do
      default_options[:expire_after].must_equal 60 * 30
    end

    it 'assigns the :store_expire_after option to @default_options' do
      default_options[:store_expire_after].must_equal 60 * 90
    end

    it 'expire_after takes precedence over store_expire_after to set expiry' do
      st = store

      env_mock = Minitest::Mock.new
      env_mock.expect(:[], default_options, ['rack.session.options'])

      sid = '1234'
      session_data = 'abc'

      key = st.send(:prefixed, sid)
      mock = Minitest::Mock.new
      mock.expect(:setex, true, [key, 60 * 30, Marshal.dump(session_data)])

      st.instance_variable_set(:@redis, mock)
      
      st.send(:set_session, env_mock, sid, session_data).must_equal true

      env_mock.verify
      mock.verify
    end
  end
end

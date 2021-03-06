require 'spec_helper'

describe LitmusPaper do
  describe 'configure' do
    it 'populates services from the config file' do
      LitmusPaper.configure(TEST_CONFIG)
      LitmusPaper.services.has_key?('test').should == true
    end
  end

  describe "reload" do
    it "will reconfigure the services" do
      LitmusPaper.configure(TEST_CONFIG)
      LitmusPaper.services["bar"] = :service

      LitmusPaper.reload

      LitmusPaper.services.has_key?('bar').should == false
      LitmusPaper.services.has_key?('test').should == true
    end

    it "reloads on a USR1 signal" do
      LitmusPaper.configure(TEST_CONFIG)
      LitmusPaper.services["bar"] = :service

      current_pid = $$
      Process.kill("USR1", current_pid)

      sleep 0.5 # wait for reload

      LitmusPaper.services.has_key?('bar').should == false
      LitmusPaper.services.has_key?('test').should == true
    end

    it "blows up when initial configuration is invalid" do
      bad_config_file = SpecHelper.create_temp_file(<<-END)
        service :old_service do |s|
          syntax error here
        end
      END
      expect do
        LitmusPaper.configure(bad_config_file)
      end.should raise_error
    end

    it "keeps the old config if there are errors in the new config" do
      config_file = SpecHelper.create_temp_file(<<-END)
        service :old_service do |s|
          s.measure_health Metric::CPULoad, :weight => 100
        end
      END

      LitmusPaper.configure(config_file)
      LitmusPaper.services.keys.should == ["old_service"]

      File.open(config_file, "w") do |file|
        file.write(<<-END)
          service :old_service do |s|
            syntax error here
          end
        END
      end

      LitmusPaper.reload
      LitmusPaper.services.keys.should == ["old_service"]
    end
  end
end

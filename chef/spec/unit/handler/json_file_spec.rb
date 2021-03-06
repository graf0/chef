#
# Author:: Adam Jacob (<adam@opscode.com>)
# Copyright:: Copyright (c) 2010 Opscode, Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "spec_helper"))

describe Chef::Handler::JsonFile do
  before(:each) do
    @handler = Chef::Handler::JsonFile.new(:the_sun => "will rise", :path => '/tmp/foobarbazqux')
  end

  it "accepts arbitrary config options" do
    @handler.config[:the_sun].should == "will rise"
  end

  it "creates the directory where the reports will be saved" do
    FileUtils.should_receive(:mkdir_p).with('/tmp/foobarbazqux')
    File.should_receive(:chmod).with(00700, '/tmp/foobarbazqux')
    @handler.build_report_dir
  end

  describe "when reporting a succ" do
    before(:each) do
      @node = Chef::Node.new
      @run_status = Chef::RunStatus.new(@node)
      @expected_time = Time.now
      Time.stub(:now).and_return(@expected_time, @expected_time + 5)
      @run_status.start_clock
      @run_status.stop_clock
      @run_context = Chef::RunContext.new(@node, {})
      @run_status.run_context = @run_context
      @run_status.exception = Exception.new("Boy howdy!")
      @file_mock = StringIO.new
      File.stub!(:open).and_yield(@file_mock)
    end


    it "saves run status data to a file as JSON" do
      @handler.should_receive(:build_report_dir)
      @handler.run_report_unsafe(@run_status)
      reported_data = Chef::JSONCompat.from_json(@file_mock.string)
      reported_data['exception'].should == "Exception: Boy howdy!"
      reported_data['start_time'].should == @expected_time.iso8601
      reported_data['end_time'].should == (@expected_time + 5).iso8601
      reported_data['elapsed_time'].should == 5
    end

  end
end

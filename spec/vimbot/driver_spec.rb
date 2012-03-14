require 'spec_helper'

describe Vimbot::Driver do
  subject { driver }

  let(:driver) do
    Vimbot::Driver.new
  end

  describe "#start" do
    before { driver.start }
    after  { driver.stop }

    it "starts a vimbot server" do
      driver.server.should be_a Vimbot::Server
      driver.server.should be_up
    end

    describe "#stop" do
      it "stops the server" do
        driver.stop
        driver.server.should_not be_up
      end
    end
  end

  describe "running commands" do
    before(:all) { driver.start }
    after(:all)  { driver.stop }

    describe "#run" do
      it "concatenates its arguments before sending them to the server" do
        driver.server.should_receive(:run).once.with("OneTwoThreeFour")
        driver.run "One", "Two", "Three", "Four"
      end
    end

    describe "predicate methods for getting the current mode" do
      before { driver.run "<Esc>" }

      context "when in normal mode" do
        its(:mode) { should == "n" }
        it { should be_in_normal_mode }

        it { should_not be_in_insert_mode }
        it { should_not be_in_visual_mode }
        it { should_not be_in_select_mode }
        it { should_not be_in_command_mode }
      end

      context "when in insert mode" do
        before { driver.run "i" }
        its(:mode) { should == "i" }
        it { should be_in_insert_mode }
      end

      context "when in visual mode" do
        before { driver.run "v" }
        its(:mode) { should == "v" }
        it { should be_in_visual_mode }
      end

      context "when in command mode" do
        before { driver.run ":" }
        its(:mode) { should == "c" }
        it { should be_in_command_mode }
      end

      context "when in replace mode" do
        before { driver.run "R" }
        its(:mode) { should == "R" }
        it { should be_in_replace_mode }
      end
    end

    describe "#insert" do
      it "types the given text in insert mode" do
      end

      it "exits insert mode" do
      end
    end

    describe "#current_line" do
      it "returns the text of the current line" do
        driver.run "i", "foo"
        driver.eval("getline('.')").should_not be_empty
      end
    end

    describe "#clear_buffer" do
      it "deletes all text in the buffer" do
        driver.run "i", "foo"
        driver.eval("getline('.')").should_not be_empty
        driver.clear_buffer
        driver.eval("getline('.')").should be_empty
      end
    end
  end

  it "passes its 'vim', 'vimrc' and 'gvimrc' options to the server" do
    Vimbot::Server.should_receive(:new).with(
      :vim => 'my_vim_bin',
      :vimrc => 'my_vimrc',
      :gvimrc => 'my_gvrimc'
    )

    Vimbot::Driver.new(
      :vim => 'my_vim_bin',
      :vimrc => 'my_vimrc',
      :gvimrc => 'my_gvrimc'
    )
  end
end

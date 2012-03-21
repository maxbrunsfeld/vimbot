require 'spec_helper'

describe Vimbot::Driver do
  subject { driver }

  let(:driver) do
    Vimbot::Driver.new(
      :vimrc  => File.expand_path("../../fixtures/example_vimrc.vim", __FILE__)
    )
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
    before { driver.clear_buffer }

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

    describe "#current_line" do
      it "returns the text of the current line" do
        driver.run "i", "foo"
        driver.current_line.should == "foo"
      end
    end

    describe "#normal" do
      it "runs the given keystrokes after returning to normal mode" do
        driver.run "i", "foobar"
        driver.normal "xx"
        driver.current_line.should == "foob"
      end

      it "returns to normal mode afterward" do
        driver.normal "i"
        driver.should be_in_normal_mode
      end

      it "uses mappings from the vimrc" do
        driver.run "i", "foobar", "<Esc>", "hh"
        driver.normal "Y"
        driver.register("\"").should == "bar"
      end
    end

    describe "#insert" do
      before { driver.insert "First", "Second" }
      its(:current_line) { should == "FirstSecond" }
      it { should_not be_in_insert_mode }
    end

    describe "#append" do
      before do
        driver.insert "First"
        driver.append "Second", "Third"
      end

      its(:current_line) { should == "FirstSecondThird"}
      it { should_not be_in_insert_mode }
    end

    describe "#register" do
      before do
        driver.insert "I belong in register a"
        driver.normal '"ayy'
        driver.append "<CR>"
        driver.insert "I belong in register b"
        driver.normal '"byy'
      end

      it "returns the contents of the given register" do
        driver.register('a').should == "I belong in register a"
        driver.register('b').should == "I belong in register b"
      end
    end

    describe "#exec" do
      it "executes the given vim command" do
        driver.insert "foo"
        driver.current_line.should == "foo"
        driver.exec "s/foo/bar"
        driver.current_line.should == "bar"
      end

      it "returns the output of the command" do
        driver.exec("echo 'hello world'").should  == "hello world"

        driver.insert "jello\n", "jello\n", "jello\n"
        driver.exec("%s/jello/pudding").should == "3 substitutions on 3 lines"
      end
    end

    describe "#source" do
      it "sources the given vimscript file" do
        path = File.expand_path("../../fixtures/foo.vim", __FILE__)
        driver.source path
        driver.eval("g:foo").should == "1"
      end
    end

    describe "#clear_buffer" do
      it "deletes all text in the buffer" do
        driver.run "i", "foo", "<CR>", "bar"
        driver.current_line.should_not be_empty
        driver.clear_buffer
        driver.current_line.should be_empty
      end

      it "does not affect the contents of the registers" do
        driver.insert "one\n", "two\n", "three\n"
        driver.normal "gg", "yy"
        expect {
          driver.clear_buffer
        }.to_not change { driver.exec "registers" }
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

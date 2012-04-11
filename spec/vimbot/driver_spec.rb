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
      before { driver.type "<Esc>" }

      context "when in normal mode" do
        its(:mode) { should == "n" }
        it { should be_in_normal_mode }

        it { should_not be_in_insert_mode }
        it { should_not be_in_visual_mode }
        it { should_not be_in_select_mode }
        it { should_not be_in_command_mode }
      end

      context "when in insert mode" do
        before { driver.type "i" }
        its(:mode) { should == "i" }
        it { should be_in_insert_mode }
      end

      context "when in visual mode" do
        before { driver.type "v" }
        its(:mode) { should == "v" }
        it { should be_in_visual_mode }
      end

      context "when in command mode" do
        before { driver.type ":" }
        its(:mode) { should == "c" }
        it { should be_in_command_mode }
      end

      context "when in replace mode" do
        before { driver.type "R" }
        its(:mode) { should == "R" }
        it { should be_in_replace_mode }
      end
    end

    describe "#line" do
      it "returns the text of the current line" do
        driver.insert "foo"
        driver.line.should == "foo"
      end
    end

    describe "#type" do
      before do
        driver.insert "a treatise<CR>", "on treats"
        driver.normal
      end

      it "uses mappings from the vimrc" do
        driver.type "b", "Y"
        driver.register('"').should == "treats" # since Y is mapped to y$
      end

      it "handles quotation marks" do
        driver.type %("x), "yiw"
        driver.register('x').should == "treats"

        driver.type "o", %("foo")
        driver.line.should == %("foo")
      end

      it "handles special vim characters" do
        driver.line.should == "on treats"
        driver.append "<CR>", "like the world has never known"
        driver.type "<Esc>"
        driver.line.should == "like the world has never known"

        driver.type "^"
        driver.column_number.should == 1
        driver.type "<Space><Space>"
        driver.column_number.should == 3
        driver.type "<Left>"
        driver.column_number.should == 2
      end

      it "creates an undo entry (despite vim server mode not doing this)" do
        driver.type "x"
        driver.line.should == "on treat"
        driver.type "x"
        driver.line.should == "on trea"

        driver.undo
        driver.line.should == "on treat"
        driver.undo
        driver.line.should == "on treats"

        driver.redo
        driver.line.should == "on treat"
        driver.redo
        driver.line.should == "on trea"
      end

      describe "when in insert mode" do
        before do
          driver.type "a"
          driver.should be_in_insert_mode
          driver.type " and all"
        end

        it "sends the given keystrokes in insert mode" do
          driver.line.should == "on treats and all"
        end

        it "stays in insert mode afterwards" do
          driver.should be_in_insert_mode
        end
      end

      describe "when in visual mode" do
        before do
          driver.type "V"
          driver.should be_in_visual_mode
          driver.type "k"
        end

        it "sends the given keystrokes in visual mode" do
          driver.type "gU"
          driver.line.should == "A TREATISE"
        end

        it "stays in visual mode afterwards" do
          driver.should be_in_visual_mode
        end
      end

      describe "when in command mode" do
        before do
          driver.type ":"
          driver.should be_in_command_mode
          driver.type "s/treats/slime"
        end

        xit "sends the given keystrokes in command mode" do
          driver.line.should == "on slime"
        end

        xit "stays in command mode afterwards" do
          driver.should be_in_command_mode
        end
      end
    end

    describe "#normal" do
      it "runs the given keystrokes after returning to normal mode" do
        driver.type "i", "foobar"
        driver.normal "xx"
        driver.line.should == "foob"
      end
    end

    describe "#insert" do
      it "inserts the given text" do
        driver.insert "omg"
        driver.line.should == "omg"
      end

      it "handles special characters" do
        driver.insert "first line", "<CR>", "second line"
        driver.line.should == "second line"
      end

      it "uses mappings from the vimrc" do
        driver.insert "hello world"
        driver.insert "<C-a>"
        driver.column_number.should == 1
        driver.insert "<C-e>"
        driver.normal
        driver.column_number.should == "hello world".length
      end
    end

    describe "#append" do
      before do
        driver.insert "First"
        driver.append "Second", "Third"
      end

      its(:line) { should == "FirstSecondThird"}
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
        driver.line.should == "foo"
        driver.exec "s/foo/bar"
        driver.line.should == "bar"
      end

      it "returns the output of the command" do
        driver.exec("echo 'hello world'").should  == "hello world"

        driver.insert "jello<CR>", "jello<CR>", "jello<CR>"
        driver.exec("%s/jello/pudding").should == "3 substitutions on 3 lines"
      end
    end

    describe "#source" do
      it "sources the given vimscript file" do
        path = File.expand_path("../../fixtures/foo.vim", __FILE__)
        driver.source path
        driver.evaluate("g:foo").should == "1"
      end
    end

    describe "#has_popup_menu_visible?" do
      it "returns true when the autocomplete pop-up menu is open" do
        driver.insert "fur<CR>", "fun<CR>", "fuzz<CR>"
        driver.insert "fu", "<C-n>"
        driver.should have_popup_menu_visible
      end

      it "returns false otherwise" do
        driver.normal
        driver.should_not have_popup_menu_visible
      end
    end

    describe "#clear_buffer" do
      it "deletes all text in the buffer" do
        driver.type "i", "foo", "<CR>", "bar"
        driver.line.should_not be_empty
        driver.clear_buffer
        driver.line.should be_empty
      end

      it "does not affect the contents of the registers" do
        driver.insert "one<CR>", "two<CR>", "three<CR>"
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

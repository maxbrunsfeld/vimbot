require 'spec_helper'

describe Vimbot::Server do
  let(:server) do
    Vimbot::Server.new(:vimrc => vimrc, :gvimrc => gvimrc)
  end

  let(:vim_binary) { nil }
  let(:vimrc)  { nil }
  let(:gvimrc) { nil }

  subject { server }

  describe "#initialize" do
    before do
      Vimbot::Server.any_instance.stub(:wait_until_up)
      Vimbot::Server.any_instance.stub(:fork).and_yield
    end

    context "when a vim binary is specified" do
      let(:server) { Vimbot::Server.new(:vim_binary => vim_binary) }

      context "and the version supports client-server mode" do
        let(:vim_binary) { File.expand_path("../../fixtures/fake_vim", __FILE__) }

        it "uses the given vim binary" do
          expect_vim_command_to_match /^#{vim_binary}/
        end

        context "when the version has a '--nofork' option" do
          let(:vim_binary) { File.expand_path("../../fixtures/fake_vim", __FILE__) }

          it "passes that option" do
            expect_vim_command_to_match /--nofork/
          end
        end

        context "when the version does not have a '--nofork' option" do
          let(:vim_binary) { File.expand_path("../../fixtures/fake_vim_without_nofork", __FILE__) }

          it "omits that option" do
            expect_vim_command_not_to_match /--nofork/
          end
        end
      end

      context "and the binary does not support client-server mode" do
        it "raises an exception" do
          vim_binary = File.expand_path("../../fixtures/fake_vim_without_server_mode", __FILE__)
          expect {
            Vimbot::Server.new(:vim_binary => vim_binary)
          }.to raise_error Vimbot::IncompatibleVim
        end
      end
    end

    context "when no vim binary is specified" do
      let(:server) { Vimbot::Server.new }

      let(:vim_has_server_mode)  { true }
      let(:mvim_has_server_mode) { true }
      let(:gvim_has_server_mode) { true }

      before do
        Vimbot::Server.any_instance.stub(:binary_supports_server_mode?) do |binary|
          case binary
          when "vim"
            vim_has_server_mode
          when "mvim"
            mvim_has_server_mode
          when "gvim"
            gvim_has_server_mode
          end
        end
      end

      context "when 'vim' supports server mode" do
        its(:vim_binary) { should == "vim" }
      end

      context "when 'vim' does not support server mode, but 'mvim' does" do
        let(:vim_has_server_mode) { false }
        its(:vim_binary) { should == "mvim" }
      end

      context "when 'vim' and 'mvim' do not support server mode, but 'gvim' does" do
        let(:vim_has_server_mode)  { false }
        let(:mvim_has_server_mode) { false }
        its(:vim_binary) { should == "gvim" }
      end

      context "when neither 'vim', 'mvim', nor 'gvim' support server mode" do
        let(:vim_has_server_mode)  { false }
        let(:mvim_has_server_mode) { false }
        let(:gvim_has_server_mode) { false }

        it "raises an exception" do
          expect { server }.to raise_error Vimbot::NoCompatibleVim
        end
      end
    end

    context "with custom vim config files" do
      let(:server) { Vimbot::Server.new(:vimrc => vimrc, :gvimrc => gvimrc) }
      let(:vimrc)  { nil }
      let(:gvimrc) { nil }

      context "when a vimrc is specified" do
        let(:vimrc) { File.expand_path('../../fixtures/foo.vim', __FILE__) }

        it "uses the specificied vimrc" do
          expect_vim_command_to_match /-u #{vimrc}/
        end
      end

      context "when no vimrc is specified" do
        let(:vimrc) { nil }

        it "uses an empty vimrc" do
          empty_vimrc = Vimbot::Server::EMPTY_VIMSCRIPT
          IO.read(empty_vimrc).should be_empty
          expect_vim_command_to_match /-u #{empty_vimrc}/
        end
      end

      context "when a gvimrc is specified" do
        let(:gvimrc) { File.expand_path('../../fixtures/foo.vim', __FILE__) }

        it "uses the specificied gvimrc" do
          expect_vim_command_to_match /-U #{vimrc}/
        end
      end

      context "when no gvimrc is specified" do
        let(:gvimrc) { nil }

        it "uses an empty gvimrc" do
          empty_gvimrc = Vimbot::Server::EMPTY_VIMSCRIPT
          expect_vim_command_to_match /-U #{empty_gvimrc}/
        end
      end
    end

    def expect_vim_command_to_match(pattern)
      server.should_receive(:exec).once.with(pattern)
      server.start
    end

    def expect_vim_command_not_to_match(pattern)
      server.should_receive(:exec).once
      server.should_not_receive(:exec).with(pattern)
      server.start
    end
  end

  describe "#name" do
    it "is unique between instances" do
      server.name.should include "VIMBOT"
      server.name.should_not == Vimbot::Server.new.name
    end
  end

  describe "#start" do
    before do
      @initial_vim_server_names = running_vim_server_names
      @initial_vim_commands = running_vim_commands
      server.start
    end

    after { server.stop  }

    it { should be_up }

    it "starts a vim process with its server name" do
      new_vim_commands.length.should == 1
      new_vim_server_names.length.should == 1
      new_vim_server_names.first.should == server.name
    end

    it "doesn't start another vim server if it has already started one" do
      server.start
      new_vim_commands.length.should == 1
      new_vim_server_names.length.should == 1
    end

    describe "#stop" do
      it "kills the vim process" do
        server.stop
        server.should_not be_up
        new_vim_server_names.should be_empty
        new_vim_commands.should be_empty
      end
    end

    def new_vim_server_names
      running_vim_server_names - @initial_vim_server_names
    end

    def new_vim_commands
      running_vim_commands - @initial_vim_commands
    end

    def running_vim_commands
      `ps ax -o command | grep vim | grep -v grep`.split("\n")
    end

    def running_vim_server_names
      `#{server.vim_binary} --serverlist`.split("\n")
    end
  end

  context "with the server up" do
    before(:all) { server.start }
    after(:all)  { server.stop }

    describe "#evaluate" do
      it "returns the result of the given vimscript expression" do
        server.evaluate("8 + 1").should == "9"
        server.evaluate("len([1, 2, 3, 4, 5])").should == "5"
      end

      it "handles expressions containing single quotes" do
        server.evaluate("'foo' . 'bar' . 'baz'").should == "foobarbaz"
      end

      it "handles expressions containing double quotes" do
        server.evaluate('"foo" . "bar" . "baz"').should == "foobarbaz"
      end

      it "handles expressions that return empty strings" do
        server.evaluate("[]").should == ""
      end

      it "raises an exception for invalid expressions" do
        expect {
          server.evaluate("1 + []")
        }.to raise_error Vimbot::InvalidExpression
      end
    end

    describe "#run" do
      before { server.run "<Esc>dd" }

      it "sends the given keystrokes to the vim server" do
        server.run "i"
        server.run "foo"
        current_line.should == "foo"
      end

      it "handles commands containing single quotes" do
        server.run "i"
        server.run "who's that?"
        current_line.should == "who's that?"
      end

      it "handles expressions containing double quotes" do
        server.run "i"
        server.run 'foo "bar"'
        current_line.should == 'foo "bar"'
      end

      def current_line
        server.evaluate "getline('.')"
      end
    end
  end
end

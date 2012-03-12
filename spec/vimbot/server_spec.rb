require 'spec_helper'

describe Vimbot::Server do
  let(:vim_binary) { 'mvim' }
  let(:vimrc)  { nil }
  let(:gvimrc) { nil }
  let(:server) do
    Vimbot::Server.new(
      :vim    => vim_binary,
      :vimrc  => vimrc,
      :gvimrc => gvimrc
    )
  end

  subject { server }

  before do
    @initial_vim_server_names = running_vim_server_names
    @initial_vim_commands = running_vim_commands
  end

  describe "#start" do
    before { server.start }
    after  { server.stop  }

    it { should be_up }

    it "creates a unique name" do
      server.name.should include "VIMBOT"
      server.name.should_not == Vimbot::Server.new(:vim => vim_binary).name
    end

    it "starts a vim process with that server name" do
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
  end

  describe "custom vim binaries and vim configs" do
    before { server.start }
    after  { server.stop }

    context "when a vimrc is specified" do
      let(:vimrc) { File.expand_path('../../fixtures/foo.vim', __FILE__) }

      it "uses the specificied vimrc" do
        expect_vimrc(vimrc)
      end

      context "and no gvimrc is specified" do
        let(:gvimrc) { nil }

        it "uses an empty gvimrc, since the default gvimrc might depend on the default vimrc" do
          empty_gvimrc = ::Vimbot::Server::EMPTY_GVIMRC
          expect_gvimrc(empty_gvimrc)
        end
      end

      context "and a gvimrc is specified" do
        let(:gvimrc) { File.expand_path('../../fixtures/bar.vim', __FILE__) }

        it "uses the specified gvimrc file" do
          expect_gvimrc(gvimrc)
        end
      end
    end

    context "when no vimrc is specified" do
      let(:vimrc) { nil }

      it "uses the default vimrc" do
        expect_vimrc(File.expand_path("~/.vimrc"))
      end

      context "and no gvimrc is specified" do
        let(:gvimrc) { nil }

        it "uses the default gvimrc" do
          expect_gvimrc(File.expand_path("~/.gvimrc"))
        end
      end

      context "and a gvimrc is specified" do
        let(:gvimrc) { File.expand_path('../../fixtures/bar.vim', __FILE__) }

        it "uses the specified gvimrc" do
          expect_gvimrc(gvimrc)
        end
      end
    end

    def expect_vimrc(vimrc)
      new_vim_commands.first.should match /-u #{vimrc}/
    end

    def expect_gvimrc(gvimrc)
      new_vim_commands.first.should match /-U #{gvimrc}/
    end
  end

  describe "#eval" do
    before(:all) { server.start }
    after(:all)  { server.stop }

    it "returns the result of the given vimscript expression" do
      server.eval("8 + 1").should == "9"
      server.eval("len([1, 2, 3, 4, 5])").should == "5"
    end

    it "handles expressions containing single quotes" do
      server.eval("'foo' . 'bar' . 'baz'").should == "foobarbaz"
    end

    it "handles expressions containing double quotes" do
      server.eval('"foo" . "bar" . "baz"').should == "foobarbaz"
    end

    describe "with an invalid expression" do
      it "returns false" do
        server.eval("1 + []").should be_false
        server.eval("'foo").should be_false
      end

      it "silences standard error" do
        server.should_receive(:`).with(/2>\/dev\/null/).and_return("")
        server.eval("1 + []")
      end
    end
  end

  describe "#run" do
    before(:all) { server.start }
    after(:all)  { server.stop }

    before { server.run "<Esc>dd" }

    it "sends the given keystrokes to the vim server" do
      server.run "i"
      server.run "foo"
      current_line.should == "foo"
    end

    it "handles commands containing single quotes" do
      server.run "i"
      server.run "who's house?"
      current_line.should == "who's house?"
    end

    it "handles expressions containing double quotes" do
      server.run "i"
      server.run 'foo "bar"'
      current_line.should == 'foo "bar"'
    end

    def current_line
      server.eval "getline('.')"
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
    `#{vim_binary} --serverlist`.split("\n")
  end
end

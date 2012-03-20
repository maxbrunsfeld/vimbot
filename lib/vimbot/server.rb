module Vimbot
  class Server
    attr_reader :vim_binary, :vimrc, :gvimrc, :errors

    def initialize(options={})
      @errors = []
      set_vim_binary(options[:vim_binary])
      set_config_files(options[:vimrc], options[:gvimrc])
    end

    def start
      return if @pid
      @pid = fork { exec start_command }
      wait_until_up
    end

    def stop
      return unless @pid
      run "<Esc>:qall!<CR>"
      Process.wait(@pid)
      @pid = nil
    end

    def run(command)
      system "#{command_prefix} --remote-send \"#{escape(command)}\""
    end

    def eval(expression)
      output, error = Open3.capture3 "#{command_prefix} --remote-expr \"#{escape(expression)}\""
      if error.empty?
        output.gsub(/\n$/, "")
      else
        errors.push(error) && nil
      end
    end

    def name
      unless @name
        @@next_id = @@next_id + 1
        @name = "VIMBOT_#{@@next_id}"
      end
      @name
    end

    def up?
      running_server_names.include? name
    end

    private

    @@next_id = 0

    DEFAULT_VIM_BINARIES = ["vim", "mvim", "gvim"]
    EMPTY_GVIMRC       = File.expand_path("../../../vim/empty.vim", __FILE__)

    def wait_until_up
      sleep 0.25 until up?
    end

    def set_vim_binary(binary)
      if binary
        if binary_supports_server_mode?(binary)
          @vim_binary = binary
        else
          raise "Error - vim binary '#{binary}' does not support client-server mode."
        end
      else
        @vim_binary = DEFAULT_VIM_BINARIES.find {|binary| binary_supports_server_mode?(binary)}
        unless @vim_binary
          raise "Error - couldn't find a vim binary that supports client-server mode."
        end
      end
    end

    def set_config_files(vimrc, gvimrc)
      @vimrc = vimrc
      @gvimrc = gvimrc
      if vimrc && !gvimrc
        @gvimrc = EMPTY_GVIMRC
      end
    end

    def binary_supports_server_mode?(binary)
      !(`#{binary} --help | grep -e --server`).empty?
    end

    def binary_has_no_fork_option?
      !(`#{vim_binary} --help | grep -e --nofork`).empty?
    end

    def start_command
      [command_prefix, no_fork_option, vimrc_option, gvimrc_option].compact.join(" ")
    end

    def no_fork_option
      "--nofork" if binary_has_no_fork_option?
    end

    def gvimrc_option
      "-U #{gvimrc}" if gvimrc
    end

    def vimrc_option
      "-u #{vimrc}" if vimrc
    end

    def escape(string)
      string.gsub(/"/, '\"')
    end

    def command_prefix
      "#{vim_binary} --servername #{name}"
    end

    def running_server_names
      `#{vim_binary} --serverlist`.split("\n")
    end
  end
end

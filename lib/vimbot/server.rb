module Vimbot
  class Server
    DEFAULT_VIM_BINARY = "mvim"
    DEFAULT_VIMRC  = File.expand_path("~/.vimrc")
    DEFAULT_GVIMRC = File.expand_path("~/.gvimrc")
    EMPTY_GVIMRC   = File.expand_path("../../../vim/empty.vim", __FILE__)

    attr_reader :vim_binary, :vimrc, :gvimrc
    @@next_id = 0

    def initialize(args={})
      @@next_id += 1
      @id = @@next_id
      @vim_binary = DEFAULT_VIM_BINARY
      @vimrc  = args[:vimrc]  || DEFAULT_VIMRC
      @gvimrc = args[:gvimrc] || (args[:vimrc] ? EMPTY_GVIMRC : DEFAULT_GVIMRC)
    end

    def start
      unless @pid
        @pid = fork { exec "#{shell_command} -f -u #{vimrc} -U #{gvimrc}" }
        sleep 0.25 until up?
      end
    end

    def stop
      if @pid
        run "<Esc>:qall!<CR>"
        Process.wait(@pid)
        @pid = nil
      end
    end

    def run(command)
      system "#{shell_command} --remote-send \"#{escape(command)}\""
    end

    def eval(expression)
      output = `#{shell_command} --remote-expr \"#{escape(expression)}\" 2>/dev/null`
      (output.length > 0) ? output.gsub(/\n$/, "") : false
    end

    def name
      @name ||= "VIMBOT_#{@id}"
    end

    def up?
      running_server_names.include? name
    end

    private

    def escape(string)
      string.gsub(/"/, '\"')
    end

    def shell_command
      "#{vim_binary} --servername #{name}"
    end

    def running_server_names
      `#{vim_binary} --serverlist`.split("\n")
    end
  end
end

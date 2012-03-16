module Vimbot
  class Driver
    attr_reader :server

    def initialize(options={})
      @server = Vimbot::Server.new(options)
    end

    def clear_buffer
      normal "ggdG"
    end

    def normal(*commands)
      run(["<Esc>"] + commands + ["<Esc>"])
    end

    def insert(*strings)
      normal(["i"] + strings)
    end

    def append(*strings)
      normal(["a"] + strings)
    end

    def exec(command)
      normal
      run ":redir => vimbot_temp<CR>"
      run ":silent ", command, "<CR>"
      run ":redir END<CR>"
      eval("vimbot_temp").gsub(/^\n/, "")
    end

    def current_line
      eval("getline('.')")
    end

    def register(reg_name)
      eval("getreg('#{reg_name}')")
    end

    def mode
      eval("mode(1)")
    end

    def in_insert_mode?;   mode == "i"; end
    def in_normal_mode?;   mode == "n"; end
    def in_visual_mode?;   mode == "v"; end
    def in_select_mode?;   mode == "s"; end
    def in_replace_mode?;  mode == "R"; end
    def in_command_mode?;  mode == "c"; end

    def run(*commands)
      server.run(commands.join)
    end

    def eval(expr)
      server.eval(expr)
    end

    def start; server.start; end
    def stop;  server.stop;  end
  end
end

module Vimbot
  class Driver
    attr_reader :server

    def initialize(options={})
      @server = Vimbot::Server.new(options)
    end

    def clear_buffer
      normal 'gg"_dG'
    end

    def normal(*strings)
      run(
        '<Esc>',
        ':call feedkeys("',
        escape(strings.join),
        '", "t")<CR>'
      )
      run '<Esc>'
    end

    def escape(string)
      string.gsub(/[()]/, '\\\\\0').gsub(/"/, '\\\\\"')
    end

    def insert(*strings)
      run(
        "<Esc>",
        "i",
        strings.join,
        "<Esc>"
      )
    end

    def append(*strings)
      run(
        "<Esc>",
        "a",
        strings.join,
        "<Esc>"
      )
    end

    def exec(command)
      run(
        "<Esc>",
        ":redir => vimbot_temp<CR>",
        ":silent ", command, "<CR>",
        ":redir END<CR>",
        ":<Esc>"
      )
      eval("vimbot_temp").gsub(/^\n/, "")
    end

    def source(file)
      exec "source #{file}"
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

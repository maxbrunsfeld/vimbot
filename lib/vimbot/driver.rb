module Vimbot
  class Driver
    attr_reader :server

    def initialize(options={})
      @server = Vimbot::Server.new(options)
    end

    def normal(*strings)
      create_undo_entry
      feedkeys(strings.join, "<Esc>")
    end

    def insert(*strings)
      normal "i", strings.join
    end

    def append(*strings)
      normal "a", strings.join
    end

    def exec(command)
      run(
        "<Esc>",
        ":redir => #{TEMP_VARIABLE_NAME}<CR>",
        ":silent #{command}<CR>",
        ":redir END<CR>",
        "<C-l>"
      )
      evaluate(TEMP_VARIABLE_NAME).gsub(/^\n/, "")
    end

    def clear_buffer
      run '<Esc>gg"_dG<Esc>'
    end

    def source(file)
      exec "source #{file}"
    end

    def line
      evaluate("getline('.')")
    end

    def register(reg_name)
      evaluate("getreg('#{reg_name}')")
    end

    def mode
      evaluate("mode(1)")
    end

    def column_number
      evaluate("col('.')").to_i
    end

    def line_number
      evaluate("line('.')").to_i
    end

    def in_insert_mode?;   mode == "i"; end
    def in_normal_mode?;   mode == "n"; end
    def in_visual_mode?;   mode == "v"; end
    def in_select_mode?;   mode == "s"; end
    def in_replace_mode?;  mode == "R"; end
    def in_command_mode?;  mode == "c"; end

    def has_popup_menu_visible?
      evaluate("pumvisible()") == "1"
    end

    def create_undo_entry
      run "<Esc>:set undolevels=#{undo_levels}<CR>"
    end

    def feedkeys(*strings)
      run %(<Esc>:call feedkeys("#{escape_argument(strings.join)}", 'm')<CR><C-l>)
    end

    def run(*commands)
      server.run(commands.join)
    end

    def evaluate(expr)
      server.evaluate(expr)
    end

    TEMP_VARIABLE_NAME = "vimbot_temp"
    SPECIAL_CHARACTERS  = %w(CR Cr cr ESC Esc esc Space space)
    MODIFIER_CHARACTERS = %w(C D M S)

    VIM_PATTERNS = [
      SPECIAL_CHARACTERS.map  {|char| /<(#{char})>/},
      MODIFIER_CHARACTERS.map {|char| /<(#{char}-\w+)>/}
    ].flatten

    def undo_levels
      @undo_levels ||= evaluate("&ul")
    end

    def escape_argument(string)
      string.tap do |string|
        string.gsub!(/[()"]/, '\\\\\0')
        VIM_PATTERNS.each { |pattern| string.gsub!(pattern, '\\\<\1_<BS>>') }
      end
    end

    def start; server.start; end
    def stop;  server.stop;  end
  end
end

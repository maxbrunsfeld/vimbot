module Vimbot
  class Driver
    attr_reader :server

    def initialize(options={})
      @server = Vimbot::Server.new(options)
    end

    def type(*strings)
      create_undo_entry
      feedkeys(strings.join)
    end

    def normal(*strings)
      type "<Esc>", strings.join
    end

    def insert(*strings)
      normal "i", strings.join
    end

    def append(*strings)
      normal "a", strings.join
    end

    def exec(command)
      normal
      raw_command("redir => #{TEMP_VARIABLE_NAME}")
      raw_command("silent #{command}")
      raw_command("redir END")
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
    def in_visual_mode?;   ["v", "V"].include?(mode); end
    def in_select_mode?;   mode == "s"; end
    def in_replace_mode?;  mode == "R"; end
    def in_command_mode?;  mode == "c"; end

    def has_popup_menu_visible?
      evaluate("pumvisible()") == "1"
    end

    def create_undo_entry
      raw_command %(set undolevels=#{undo_levels})
    end

    def feedkeys(*strings)
      raw_command %(call feedkeys("#{escape_argument(strings.join)}", 'm'))
    end

    def raw_command(string)
      prefix, suffix = case mode
        when 'n'
          [":", "<C-l>"]
        when 'i'
          "<C-o>:"
        when 'v'
        when 'V'
          [":<C-w>", "<C-l>gv"]
        else
          "<Esc>"
      end

      run "#{prefix}#{string}<CR>#{suffix}"
    end

    def undo
      normal "u"
    end

    def redo
      normal "<C-r>"
    end

    def run(*commands)
      server.run(commands.join)
    end

    def evaluate(expr)
      server.evaluate(expr)
    end

    TEMP_VARIABLE_NAME = "vimbot_temp"
    SPECIAL_CHARACTERS  = %w(CR Cr cr ESC Esc esc Space space LEFT Left RIGHT Right)
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

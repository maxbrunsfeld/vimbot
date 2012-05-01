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

    def command(command)
      normal
      temp_variable_name = "vimbot_temp"
      raw_command("redir => #{temp_variable_name}")
      raw_command("silent #{command}")
      raw_command("redir END")
      evaluate(temp_variable_name).gsub(/^\n/, "")
    end

    def clear_buffer
      normal 'gg"_dG'
    end

    def source(file);  command "source #{file}";  end
    def runtime(file); command "runtime #{file}"; end

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

    ['', 'n', 'i', 'v', 'x', 's', 'c'].each do |mode_prefix|
      map_cmd = "#{mode_prefix}map"
      define_method(map_cmd) {|input, output| raw_command "#{map_cmd} #{input} #{output}"}
    end

    def has_popup_menu_visible?
      evaluate("pumvisible()") == "1"
    end

    def undo
      raw_command "undo"
    end

    def redo
      raw_command "redo"
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
        when /[vV]/
          [":<C-w>", "<C-l>gv"]
        else
          "<Esc>:"
      end

      raw_type "#{prefix}#{escape_command(string)}<CR>#{suffix}"
    end

    def raw_type(*commands)
      server.remote_send(commands.join)
    end

    def evaluate(expr)
      server.remote_expr(expr)
    end

    def set(option, value=nil)
      cmd = [option, value].compact.join("=")
      raw_command "set #{cmd}"
    end

    def undo_levels
      @undo_levels ||= evaluate("&ul")
    end

    def escape_command(string)
      string.gsub(/<((\w+-)*\w+)>/, '<\1_<bs>>')
    end

    def escape_argument(string)
      string.
        gsub(/[()"]/, '\\\\\0').
        gsub(/<[^>]+>/, '\\\\\0')
    end

    def start
      server.start
      set "nocompatible"
    end

    def stop;  server.stop;  end
  end
end

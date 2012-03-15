class Vimbot::Driver
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
    run(["<Esc>i"] + strings + ["<Esc>"])
  end

  def append(*strings)
    run(["<Esc>a"] + strings + ["<Esc>"])
  end

  def exec(command)
    temp_reg = "x"
    run "<Esc>"
    run ":let save_register = @#{temp_reg}<CR>"
    run ":redir @#{temp_reg}<CR>"
    run ":", command, "<CR>"
    result = register(temp_reg)
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

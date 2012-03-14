class Vimbot::Driver
  attr_reader :server

  def initialize(options={})
    @server = Vimbot::Server.new(options)
  end

  def clear_buffer
    normal "ggdG"
  end

  def normal(*commands)
    run ["<Esc>"].concat(commands)
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

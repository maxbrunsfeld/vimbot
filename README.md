# Vimbot - test drive vim from ruby

## Usage

Start up a vim application like this:

    > vim = Vimbot::Driver.new
    > vim.start

When you want to quit vim,

    > vim.stop

By default, Vimbot will try to guess what vim application to use,
and use an *empty* `.vimrc` and `.gvimrc`. If you want to specify a
vim binary or some config files, you can do this:

    > vim = Vimbot::Driver.new(
      :vim => "bin/my_vim",
      :vimrc => "~/.vimrc",
      :gvimrc => ".alternative_gvimrc"
    )

From there, you can begin editing:

    > vim.type "i", "Hey vim users,"
    > vim.append "<CR><CR>", "Try testing your vim plugins with vimbot!"
    > vim.command "%s/vim/best_editor_ever/g"

    => "2 substitutions on 2 lines"

## API

### editing

- `type` - sends keyboard input to vim,
  applying mappings and creating an undo entry where needed
- `normal` - like, `type`, but enters normal mode first
- `insert` - like, `type`, but enters insert mode first
- `append` - like, `type`, but enters insert mode first
- `undo`
- `redo`
- `clear_buffer`
- `raw_type` - like `type`, but does not do vimbot's normal
  behavior of ensuring that an undo entry is created and
  that mappings are applied

### querying the state of the editor

- `line` - get the text of the line the cursor is on
- `line_number`, `column_number` - get the position of the cursor
- `register` - get the contents of a given register
- `mode` - returns the mode as a letter: `i`, `n`, `c`, `v`, `V`, `s`
- `evaluate` - get value of arbitrary vimscript expression
- `in_insert_mode?`
- `in_normal_mode?`
- `in_command_mode?`
- `in_visual_mode?`
- `in_select_mode?`

### configuration
- `source`, `runtime` - load vimscript files
- `set` - set a vim option
- `map` - add a key mapping

## Contributing
New convenience methods are easy to add, and pull requests are welcome!

## Dependencies
Vimbot is developed with Vim 7.3 and Ruby 1.9.2.

## Author
Vimbot is developed by Max Brunsfeld | @maxbrunsfeld | maxbrunsfeld@gmail.com

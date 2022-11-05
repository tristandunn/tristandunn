---
part: 2
title: "Save Time, Type Less"
image: "posts/2022-11-04/image@2x.png"
category: tips
subtitle: "Part 2: Sending Commands to tmux from Vim"
description: "How to send commands to tmux, specifically panes, from vim."
permalink: /journal/save-time-type-less-part-2-vim-controls-tmux/
---

My tmux setup has one left, full-height pane for code, one top-right, two-thirds
pane for tests, and one bottom-right, one-third pane for other commands. With
this setup I've been using [vim-tmux-runner][] to allow me to execute tests from
vim in the top-right pane with [rspec.vim][]. It's been a great time saver over
the years, but I've had one issue bothering me: I still have to switch to the
bottom-right pane and type other commands.

The `vim-tmux-runner` plug-in attaches to a single pane and doesn't provide an
argument for which pane to run in. Initially, I attempted to switch the attached
pane, run a command, and switch back to the default but didn't have much luck.

After two unsuccessful attempts, I created my own vim function to execute
command in a specific pane. The first argument is the command, which it
requires, followed by optional focus and pane arguments. With the focus argument
enable it will switch to the pane and zoom it, whereas the pane argument allows
customizing where the command runs.

```vim
" Define function to execute command in specific tmux pane.
function! ExecuteCommandInPane(...)
  " Ensure a command is present.
  if !a:0
    echohl ErrorMsg |
      echo "\rExecuteCommandInPane: No command provided." |
    echohl None

    return 0
  end

  " Extract the command from the first argument.
  let command = a:1
  " Determine if the pane should focus or not, defaulting to not.
  let focus = a:0 < 2 ? 0 : a:2
  " Determine the pane to execute in, defaulting to the pane three.
  let pane = a:0 < 3 ? 3 : a:3

  " Clear the target pane.
  call system("tmux send-keys -t " . pane . " clear Enter")
  " Execute the provided command in the pane.
  call system("tmux send-keys -t " . pane . " '" . command . "' Enter")

  if focus
    " Focus the pane.
    call system("tmux select-pane -t " . pane)
    " Zoom in on the pane.
    call system("tmux resize-pane -t " . pane . " -Z")
  end
endfunction
```

Full disclosure, this is the most Vimscript I've ever written.

At the time of writing I'm using it to run four specific `git` commands, which I
can now do while tests are running with minimal typing.

```vim
" Add commands to show the differences, with focus and zoom.
map <Leader>gd  :call ExecuteCommandInPane("git diff", 1)<CR>
map <Leader>gdc :call ExecuteCommandInPane("git diff --cached", 1)<CR>

" Add commands to pull or show the status, without focus and zoom.
map <Leader>gp :call ExecuteCommandInPane("git pull")<CR>
map <Leader>gs :call ExecuteCommandInPane("git status")<CR>
```

It's not nearly as robust or as well tested as `vim-tmux-runner`, but it's
solved a long-running problem for me and allows me to type less. If it continues
to work well, I'll certainly use it to replace `vim-tmux-runner`.

[rspec.vim]: https://github.com/thoughtbot/vim-rspec
[vim-tmux-runner]: https://github.com/christoomey/vim-tmux-runner

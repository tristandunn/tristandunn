---
part: 1
title: "Save Time, Type Less"
image: "posts/2020-04-30/image@2x.png"
category: tips
subtitle: "Part 1: Using Aliases for Common Tasks"
description: "Use aliases for common tasks to save time by typing less."
permalink: /journal/save-time-type-less-part-1-aliases/
twitter_card: summary_large_image
modified_at: 2021-09-11
---

I started using `vim` in 2009, and after the initial hurdle of figuring out how
to quit, I learned to love it. Not long after, the idea of reducing the amount
of typing for actions anywhere became an on-again, off-again obsession.

Over ten years later I think optimizing actions, such as typing, are a major
skill for developers. Speeding up or simplifying a single task might seem like a
waste, but when you continue doing so over your career it can become a major
advantage.

Last month I was pairing with a co-worker and realized how surprised I was that
they were typing out full `git` commands. After years of having shell and `git`
aliases, I was actually a little annoyed waiting for them to type the commands.
Later that week I wrote a quick introduction to the aliases to share with my
team, which is what follows below and is hopefully the first part of a series.

## Shell Aliases

You probably spend a lot of time in a shell, second to your editor. The shell is
a great place to start saving keystrokes to speed up your workflow. And the
easiest way to get started is with aliases.

While you can add aliases directly to your "run commands" file, such as
`.bashrc` and `.zshrc`, it can be a bit easier to organize them in a separate
file. Let's load an `.aliases` file from your home directory in the shell with a
condition to ensure the file exists before sourcing it.

```sh
if [ -e "$HOME/.aliases" ]; then
  source "$HOME/.aliases"
fi
```
{: caption="Loading a separate file where aliases will live."}

A quick and easy win for your first alias would be shortening `git`, which is
probably one of your top commands each day.

```sh
alias g="git"
```
{: caption="Assigning an alias for the `git` command."}

I know saving two characters may not seem like much, but it adds up. Go ahead
and try to think about the number of times you've typed `git` this year alone.

## `git` Aliases

Adding aliases to `git` itself can reduce the characters you type for common
actions. For example, going from `git add -A .` to add files and `git status` to
see what you're committing, you could run `g a`. You would go from 24 characters
to 4 characters, including hitting return to run both commands.

You define `git`-specific aliases in `~/.gitconfig` under an `alias` section.
Let's add the `a` alias we mentioned.

```ini
[alias]
  a = !git add -A && git status
```
{: caption="Adding a `git` alias to add all files and display the status in
`~/.gitconfig`."}

Typically an alias expands as an argument to `git`, but if you prefix the
alias command with a bang (`!`) it runs the command in the shell. This allows
you to chain commands together, as we're doing above, or run any other command
or script.

If you need ideas for other helpful aliases, here's my current collection with
descriptions and examples for each.

```ini
[alias]
  # Add all files and display the status. (`g a`)
  a = !git add -A && git status

  # Commit the current index with a message. (`g c "Initial commit."`)
  c = commit -m

  # Amend the last commit message. (`g ca`)
  ca = commit --amend

  # Clear the terminal and display the unstaged differences.
  d = !clear && git diff

  # Clear the terminal and display the staged differences.
  dc = !clear && git diff --cached

  # Determine the default branch name.
  default-branch-name = !git remote show origin | awk '/HEAD branch/ {print $NF}'

  # Pull updates. (`g pl`)
  pl = pull

  # Push updates. (`g ps origin main`)
  ps = push

  # Pull and rebase the current branch. (`g plre`)
  plre = pull --rebase

  # Display the status. (`g st`)
  st = status

  # Rebase the current branch from an up-to-date origin/main. (`g up`)
  up = !git fetch origin && git rebase origin/`git default-branch-name`
```
{: caption="A collection of personal `git` aliases in `~/.gitconfig`."}

## Summary

By making minimal changes you can save a decent amount of time on tasks you run
countless times every single day. Apart from saving time, another big advantage
is the commands become so easy to run that you may run them more often. And
running commands more often can be a big win with testing, linting, and more.
Try to keep track of the common tasks you run for an opportunity to create more
aliases.

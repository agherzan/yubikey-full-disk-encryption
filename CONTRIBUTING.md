# How Can I Contribute?

### All contributions welcome!

## Open issue

If you found a bug, have an idea for improvement or just wanted to ask some questions, please take a look if we have already [opened Issue](https://github.com/agherzan/yubikey-full-disk-encryption/issues) covering it where you may add a comment. If it isn't covered there, please open a new Issue and describe the problem.


## Open pull request

If you want to fix some bug, typo or implement an idea by yourself don't hesitate from opening a new [Pull request](https://github.com/agherzan/yubikey-full-disk-encryption/pulls). You may also help to review an existing one.

Here are couple of resources which may help you with writing shell scripts:

### [shellcheck (finds bugs in your shell scripts)](https://www.shellcheck.net/)

#### Installation:
`pacman -Syu shellcheck`

#### Usage:
`shellcheck -x "file"`

See `shellcheck -h` or `man shellcheck`for help.

### [shellharden (The corrective bash syntax highlighter)](https://github.com/anordal/shellharden)

#### Installation:
`pacman -Syu shellharden`

#### Usage:
Output a colored diff suggesting changes:

`shellharden --suggest "file"`

Replace file contents with suggested changes:

`shellharden --replace "file"`

See `shellharden -h` for help.

### [shfmt (A shell parser, formatter and interpreter (POSIX/Bash/mksh))](https://github.com/mvdan/sh)

#### Installation:
`pacman -Syu shfmt`

#### Usage:
Error with a diff when the formatting differs:

`shfmt -i 2 -ci -d "file"`

Write result to file instead of stdout:

`shfmt -i 2 -ci -w "file"`

See `shfmt -h` for help.

### [Shell Style Guide by Google](https://google.github.io/styleguide/shell.xml)

### Thanks for taking the time to contribute to our project!

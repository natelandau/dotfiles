[![Codacy Badge](https://app.codacy.com/project/badge/Grade/96fb62a631014ebbacb9a19193012741)](https://www.codacy.com/gh/natelandau/dotfiles/dashboard?utm_source=github.com&amp;utm_medium=referral&amp;utm_content=natelandau/dotfiles&amp;utm_campaign=Badge_Grade)

This repository contains my dotfiles for BASH and ZSH.  They are opinionated and based on my own work flows. I highly recommend that you read through the files and customize them for your own purposes.

# Installation
In `.zshrc` and `.bash_profile` ensure the correct directory is used for the `DOTFILES_LOCATION` variable.

Symlink the dotfiles from this repository to your user directory. To avoid doing this manually file-by-file, run the following snippet from the root of this repository.

```bash
for f in .*; do
  [[ "$f" =~ (vscode|DS_Store|^.git$) ]] && continue
  if [ -e "${HOME}/${f}" ]; then
    mv "${HOME}/${f}" "${HOME}/${f}.bak"
  fi
  if [ -L "${HOME}/${f}" ]; then
    rm "${HOME}/${f}"
  fi
  ln -s "$(pwd)/$f" "${HOME}/${f}" && echo "Created symlink for ${f}"
done
```

## A Note on Code Reuse
I compiled these scripting utilities over many years without ever having an intention to make them public.  As a novice programmer, I have Googled, GitHubbed, and StackExchanged a path to solve my own scripting needs. I often lift a function whole-cloth from a GitHub repo don't keep track of its original location. I have done my best within these files to recreate my footsteps and give credit to the original creators of the code when possible. I fear that I missed as many as I found. My goal in making this repository public is not to take credit for the code written by others. If you recognize something that I didn't credit, please let me know.

## License
MIT

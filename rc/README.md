###  Macvim
*  `brew install macvim`
    * Then `cp -R  /usr/local/Cellar/macvim/8.2-171_1/MacVim.app ~/Applications`
    * And add `alias mvim=/Users/${username}/Applications/MacVim.app/Contents/bin/mvim` to `~/.bash_profile`


* If above not possible, then download MacVIM from [macvim github](https://github.com/macvim-dev/macvim/releases) ( which was forked from [here](https://github.com/b4winckler/macvim) originally I think ) 

### other vim stuff
* ctrlp, from https://github.com/ctrlpvim/ctrlp.vim

    ```
    mkdir -p ~/.vim/pack/plugins/start
    git clone --depth=1 https://github.com/ctrlpvim/ctrlp.vim.git ~/.vim/pack/plugins/start/ctrlp 
    ```
    
* theme, solarized8 sometimes is good (also `slate` too ) 

```
mkdir -p ~/.vim/pack/themes/opt/

cd ~/.vim/pack/themes/opt/
git clone git@github.com:lifepillar/vim-solarized8.git

```


### Vim notes
* Vim doesnt know about "terraform" files like `.tf` and [the hashivim github](https://github.com/hashivim/vim-terraform) helps with that. `vim-terraform` actually has a magical `:TerraformFmt` command that inspects the syntax of your `.tf` file too.

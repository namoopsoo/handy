
#### Create New ssh key
With `ssh-keygen`, w/ a pass phrase too.

#### Let ssh-agent manage the ssh key passphrase
With `ssh-add ~/.ssh/path/to/key` 

#### And Save to macbook keychain
Save that passphrase with 

```
ssh-add -K ~/.ssh/path/to/private/key
```

But apparently according to [this stackoverflow answer](https://apple.stackexchange.com/questions/48502/how-can-i-permanently-add-my-ssh-private-key-to-keychain-so-it-is-automatically), with Monterey, `ssh-add` uses  #  

```
ssh-add --apple-use-keychain ~/.ssh/path/to/private/key
```
because `--apple-use-keychain` is the new `-K`. 

And similarly `--apple-load-keychain` is the new `-A` , to load a key into your `ssh-agent` after logging in.

```
ssh-add --apple-load-keychain ~/.ssh/path/to/private/key
```

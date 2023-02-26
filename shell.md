
#### Edit files in place
* This `-i ''` was necessary on _MacOs_ to avoid creating a `greatings.txt.bak` file as a backup

```bash
$ sed -i '' 's/hello/bonjour/' greetings.txt
```

#### xargs into vim
* Per [this helpful answer](https://unix.stackexchange.com/a/44428)  , you can `xargs` into `vim` on macos x with `xargs -o`  ...  

```
find . -name 'blahfile*py' |head -1 |xargs -o vim 
```

#### xargs to md5 
This is nice too, quickly md5 files.
```
$ fd spark-wee
en/post/2021-01-23-spark-weekend.md
posts/2021-01-23-spark-weekend.md
$ 
$ fd spark-wee|xargs -o md5
MD5 (./en/post/2021-01-23-spark-weekend.md) = 5534f81599860e239340b41ffa5aee09
MD5 (./posts/2021-01-23-spark-weekend.md) = 5534f81599860e239340b41ffa5aee09
```



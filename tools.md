
#### ag the silver searcher
* [here](https://geoff.greer.fm/2011/12/27/the-silver-searcher-better-than-ack/)
* usually `the_silver_searcher` on homebrew
* preserve color when paging! (This is amazing!)

  ```
  ag "search term" --pager "less -R"
  ```

#### Faster and more colorful find!
* Wow `fd` , `brew install fd` , from https://github.com/sharkdp/fd 
* Preserve color when paging like this

  ```
  fd "foo" --color always |less -R
  ```

#### jq
* command line json parsing 
* [here](https://stedolan.github.io/jq/download/)

#### markdown to pdf
* With [pandoc](https://pandoc.org) (I used `brew install pandoc` ).
* And [thanks stackoverflow](https://stackoverflow.com/a/55484165/472876)  , `pandoc MANUAL.md -o example13.pdf`
* [documentation](https://pandoc.org/MANUAL.html)  
* from markdown to latex

```
pandoc -f markdown -t latex hello.txt
```
* Even `--toc, --table-of-contents`  , `--toc-depth=NUMBER`  , for automatic table of contents. 

* Specifically for double spaced output pdf [this stackoverflow](https://stackoverflow.com/a/14972019/472876) tip was amazing, to create a file like `options.sty` 
 
``` 
 \usepackage{setspace}
 \doublespacing
 \usepackage[vmargin=1in,hmargin=1in]{geometry}
 \usepackage{lineno}
 \linenumbers) 
```

And then use `pandoc -H options.sty blah.md -o blah.pdf` . Amazing! 

#### pdf for kindle !!
* Equally as amazing is the [k2pdf](https://www.willus.com/k2pdfopt/) software which restructures pdf files to comfortable kindle viewing. This is absolutely mind blowing work!

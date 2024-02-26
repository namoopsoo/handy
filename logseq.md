
## Open Loops query recent
with a not tag
```
{{query (and (between -4w +1d) (or (todo todo) (todo later) (todo now) (todo doing)) (not [[brag-document]] ))  }}
```

## one to two months old
```
{{query (and (between -8w -4w) (or (todo todo) (todo later) (todo now) (todo doing)) )  }}
```


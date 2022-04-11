

### My Rules of text `dbutils.widgets`

(0) Reading a widget that does not exist results in
```python
"com.databricks.dbutilsvl.InputWidgetNotDefined"`
```
(1)
```python
"dbutils.widgets.text (name, value)"
```

will set the value of a widget only if it does not already exist. If it already exists, this does nothing

(2)
You cannot change the value of a widget, but you can remove it and then set it again with the same
name, with 

```python
"dbutils.widgets.text (name, value)"
```

. However, if a widget was set in cell1, then cell2
cannot both remove and reset the widget. This will surprisingly have no effect!

For example you can do this

```python
# Cell 1
dbutils.widgets. text ("root" , "potato")
dbutils.widgets. get ( "root") # => "potato"

# Cell 2
dbutils.widgets.remove ( "root" )
dbutils.widgets. get ("root") # => InputWidgetNotDefined

# Cell 3
dbutils.widgets.text ( "root", "yam" )
dbutils.widgets. get ("root" ) # => "yam"
```

But this will have no effect,

```python
# Cell 1
dbutils.widgets.text ("root", "potato")
dbutils.widgets.get ("root") # => "potato"

# Cell 2
dbutils.widgets. remove ("root")
dbutils.widgets.text("root", "yam")
dbutils.widgets.get("root") # => "potato" 
```

(3) In spite of the above, if a single cell sets a widget, it can then remove it and reset it, any number of
times

```python
# Cell 1
dbutils.widgets.text ( "root", "potato" )
print (dbutils.widgets. get ("root" )) # => "potato"
dbutils.widgets.remove ("root" )

dbutils.widgets.text("root", "yam")
print (dbutils.widgets. get ("root," ) # =>"yam"
dbutils.widgets.remove ("root")

dbutils.widgets.text("root", "potato" )
print (dbutils.widgets.get ( "root" )) # => "potato"
dbutils.widgets.remove ("root" )
```

(4) If you set a widget in "notebookA" and then "%run notebookB", "notebookB" will be able to read
the widget that was set by "notebookA".

(5) Trying to remove a widget twice results in a `"com.databricks.dbutils_v1.InputwidgetNotDefined"` error.

(6) If "notebookA" defines a widget and then calls "%run notebookB" and "notebookB" tries to remove
the widget, it will not be able to. Basically seems like a notebook cannot remove a widget that was
defined in another notebook, but it can still read it, as long as "%run" is used.



## Quick sqlite3 query utils


### Querying
```python
import sqlite3
import pandas as pd
def run_query(loc, sql):
    sqliteConnection = sqlite3.connect(loc)
    cursor = sqliteConnection.cursor()
    # sql_query = """SELECT name FROM sqlite_master    WHERE type='table';"""

    cursor.execute(sql)
    data = cursor.fetchall()
    if not data:
        return pd.DataFrame()
    
    cursor.row_factory = sqlite3.Row
    cursor.execute(sql)
    columns = cursor.fetchone().keys()
    return pd.DataFrame(data, columns=columns)


```

### See all tables
The standard sqlite query for showing all the table names,

```python
query = "SELECT name FROM sqlite_master  WHERE type='table';"
```

### Example of using this to interact with macos apple photos.sqlite ,

```python
from pathlib import Path
workdir = "/Users/me/Pictures/Photos Library.photoslibrary/"

sqlite_loc = Path(workdir)/"database/Photos.sqlite"

cols = ["ZUUID", "ZLATITUDE", "ZLONGITUDE", "ZCLOUDASSETGUID", "ZDATECREATED", "ZADDEDDATE", "ZHEIGHT", "ZWIDTH"]
othercols = ["ZTRASHEDDATE"]
sql = "select * from ZASSET  "
zasset_df = run_query(sqlite_loc, sql)[cols]

sql = "select * from ZADDITIONALASSETATTRIBUTES  "
additional_df = run_query(loc, sql)

```
```python
In [26]: zasset_df.head()
Out[26]: 
                                  ZUUID   ZLATITUDE  ZLONGITUDE                       ZCLOUDASSETGUID  ZDATECREATED    ZADDEDDATE  ZHEIGHT  ZWIDTH
0  54ACC8C9-A682-4A4C-A4F1-E1808DBF8B0A -180.000000 -180.000000  82D279B2-7494-48E0-9FF2-21AB7835D84E   438044596.0  6.742372e+08     1537    2049
1  162CBC99-72D3-44AD-AB4E-9FC1909BCFA6   36.064239  -75.691788  3FF37260-EA49-44AE-BD5B-22676BE1D773   462412254.0  6.742372e+08     2049    1537
2  182AD204-814A-4E0E-94D1-6E9D7A9ED26B   38.801262  -77.005464  1E11234D-6A84-4BC3-A6E4-3D8BB79436AB   456156128.0  6.742372e+08     2049    1537
3  5C0D5113-9017-4E5A-BB67-EF875F99B906   40.608087  -73.931778  AA6C46CC-1BD1-4B32-9EB2-4E0900C4CF39   472687385.0  6.742372e+08     2049    1537
4  576C9DCB-71A1-4AEF-A4C8-6EC4B561AFDB   38.812528  -77.047517  9A4666F9-8828-4C75-A456-79823666C077   450274209.0  6.742372e+08     2049    1537


```

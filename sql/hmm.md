[[_TOC_]]

#### List indexes
* From [here](https://www.postgresqltutorial.com/postgresql-indexes/postgresql-list-indexes/)
```sql
SELECT
    tablename,
    indexname,
    indexdef
FROM
    pg_indexes
WHERE
    schemaname = 'public'
    
ORDER BY
    tablename,
    indexname;

```

#### Disk Usage per table

* from [the postgresql wiki](https://wiki.postgresql.org/wiki/Disk_Usage)
* except one minor change ... for `('user_blah', 'user_blar', 'schema1', 'schema2')` schemas only ... 
```sql
SELECT *, pg_size_pretty(total_bytes) AS total
    , pg_size_pretty(index_bytes) AS INDEX
    , pg_size_pretty(toast_bytes) AS toast
    , pg_size_pretty(table_bytes) AS TABLE
  FROM (
  SELECT *, total_bytes-index_bytes-COALESCE(toast_bytes,0) AS table_bytes FROM (
      SELECT c.oid,nspname AS table_schema, relname AS TABLE_NAME
              , c.reltuples AS row_estimate
              , pg_total_relation_size(c.oid) AS total_bytes
              , pg_indexes_size(c.oid) AS index_bytes
              , pg_total_relation_size(reltoastrelid) AS toast_bytes
          FROM pg_class c
          LEFT JOIN pg_namespace n ON n.oid = c.relnamespace
          WHERE relkind = 'r'
          and nspname in ('user_blah', 'user_blar', 'schema1', 'schema2')
  ) a
) a
```



#### detect blocked queries?

* This didnt exactly work for me as expected, but colleague had mentioned this ... 
```sql
SELECT
  COALESCE(blockingl.relation::regclass::text,blockingl.locktype) as locked_item,
  now() - blockeda.query_start AS waiting_duration, blockeda.pid AS blocked_pid,
  blockeda.query as blocked_query, blockedl.mode as blocked_mode,
  blockinga.pid AS blocking_pid, blockinga.query as blocking_query,
  blockingl.mode as blocking_mode
FROM pg_catalog.pg_locks blockedl
JOIN pg_stat_activity blockeda ON blockedl.pid = blockeda.pid
JOIN pg_catalog.pg_locks blockingl ON(
  ( (blockingl.transactionid=blockedl.transactionid) OR
  (blockingl.relation=blockedl.relation AND blockingl.locktype=blockedl.locktype)
  ) AND blockedl.pid != blockingl.pid)
JOIN pg_stat_activity blockinga ON blockingl.pid = blockinga.pid
  AND blockinga.datid = blockeda.datid
WHERE NOT blockedl.granted
AND blockinga.datname = current_database()


```



#### hmmmm how about this

```sql
select blockingl.relation, blockingl.pid, blockingl.mode, blockingl.granted,
        pgclass.relname, stat.usename, stat.application_name, stat.wait_event_type, stat.wait_event, stat.state, stat.query
    from pg_catalog.pg_locks blockingl
    join pg_class pgclass on blockingl.relation = pgclass.oid 
    join pg_stat_activity stat on stat.pid = blockingl.pid 

```


#### check role membership

```sql
select rr.*, pam.* from pg_catalog.pg_roles rr 
 join pg_catalog.pg_auth_members pam on rr."oid" = pam.roleid 
 
```


#### in line table
* using a CTE ...
```sql
with datar(col1,col2) as (
    values (1,2), (2,3), (4,5)
    )
select col1, col2 from datar

```

#### COALESCE uses early stopping
* I had a pretty expensive `COALESCE(col1, col2, ..., col50)` with 50 arguments recently. And in testing whether my non-null value was first or last made a big difference!


#### round does not work on double precision
* Wow interesting. I was comparing features generated in two tables to do some QA. Table 1 was the original or "target gold" table and table 2 was a table generated by production code. Using a simple `table1.col1 = table2.col1` comparison, a particular float column was coming back as `0.092` , for about `100k` rows. Hand inspecting, this looked like a difference of precision, but when I applied `round(table1.col1, 3) = round(table2.col1, 3)` instead, I got 

```
UndefinedFunction: function round(double precision, integer) does not exist
```
And surely enough after reading the [docs](https://www.postgresql.org/docs/9.6/functions-math.html) , oddly enough `round` with precision is only defined for `numeric` and not `float8` (aka `double precision`). After casting to `numeric` my result of `round(table1.col1::numeric, 3) = round(table2.col1::numeric, 3)` was `0.990`. Can dig deeper about the implementation later!

#### To infinity and beyond

```sql
select 999999> 'infinity'::float 
```

#### unnesting , the opposite of crosstab (aka pivoting)

```sql
CREATE  TABLE foo (id int, a text, b text, c text);
INSERT INTO foo VALUES (1, 'ant', 'cat', 'chimp'), (2, 'grape', 'mint', 'basil'),
                        (3, 'blur', 'cart', 'jump');
```
```sql
select * from foo
```

id|a|b|c
--|--|--|--
1|ant|cat|chimp
2|grape|mint|basil
3|blur|cart|jump

```
SELECT id,
       unnest(array['a', 'b', 'c']) AS colname,
       unnest(array[a, b, c]) AS thing
FROM foo
ORDER BY id;
```


id|colname|thing
--|--|--
1|a|ant
1|b|cat
1|c|chimp
2|a|grape
2|b|mint
2|c|basil
3|a|blur
3|b|cart
3|c|jump

#### copy paste a table with create table as
* Copy-pastaing a table with `CREATE TABLE AS` is sort of obvious, but laying it out doesn't hurt

```sql
CREATE TABLE blah_backup AS
SELECT *
FROM source_table

```

* [cool stack overflow response here too](https://dba.stackexchange.com/questions/156105/create-table-as-vs-select-into?newreg=f13041cd0d564c7f97956cde8793af0e)



#### Create user

```sql
CREATE USER blah_user WITH PASSWORD 'swear_words';

GRANT CONNECT ON DATABASE mycooldb TO blah_user;
GRANT USAGE ON SCHEMA myschema TO blah_user;
GRANT SELECT ON myschema.quick_table TO blah_user;

```
* Change password

```sql
ALTER USER user_name WITH PASSWORD 'new_password';

```
* check grants.. ( user w/ appropriate permissions )

```sql
SELECT table_catalog, table_schema, table_name, privilege_type, grantee
FROM   information_schema.table_privileges 
```
* list users

```sql
select * from pg_user
```

#### set lock_timeout to avoid waiting endlessly on table alter
```sql
# example from article , which bit me personally..
SET lock_timeout TO '2s';
ALTER TABLE items ADD COLUMN last_update timestamptz;
```
* source: [here](https://www.citusdata.com/blog/2018/02/22/seven-tips-for-dealing-with-postgres-locks/)



#### arbitrarily select unrelated data for presentation purposes
* Not sure if this is the best way to do this, but I wanted to be able select three different max values in one shot
```sql
with arf as (select 1 as aa, 
            max(id) as max_arf
            from mytable 
            where key = 'arf'),
bar as (select 1 as aa, 
            max(id) as max_bar
            from mytable
            where key = 'bar'),
car as (select 1 as aa,
            max(id) as max_car
            from mytable 
            where key = 'car')
            
select arf.*, bar.*, car.*
from arf join bar on arf.aa = bar.aa
join car on arf.aa = car.aa

```

aa|max_arf|aa|max_bar|aa|max_car
--|--|--|--|--|--
1|4,585,834|1|4,046,591|1|4,585,835


#### Random sample from a table
* Read this cool solution [here](https://anitagraser.com/2011/03/12/selecting-a-random-sample-from-postgresql/)

```sql

SELECT * FROM myTable
WHERE attribute = 'myValue'
ORDER BY random()
LIMIT 1000;


```


#### in place jsonb  extraction / unnesting
* If we have a table with a `jsonb` type column , called `value` , and we want to "un-nest" or normalize some data that happens to be one level below, in the jsonb...

```python

ids_sql = '(1, 2, 3)' 
blah_key = 'green_type' # some additional constraint other than the id

target_cols = ['norm_col_1', 'norm_col_2', 'norm_col_3']

# Map between 
foovec = [['norm_col_1', 'nested_col_1'], 
          ['norm_col_2', 'nested_col_2'],
          ['norm_col_3', 'nested_col_3']]

select_cols = ', '.join([f'''value->>'{x[1]}' as "{x[0]}"'''
                         for x in foovec])

col_str = ', '.join([f'"{x}"' for x in target_cols])
targetcol_str = ', '.join([f'blah."{x}"' for x in target_cols])

```

```sql
UPDATE {schema}.mytable as dp
SET ({col_str}) = ({targetcol_str})
FROM (select id, key, 
      {select_cols}  -- json->expressions->to->unpack->data!
      from {schema}.mytable
      where {ids_sql}
            and key = '{blah_key}'
        ) as blah(id, key, {col_str})

WHERE (blah.id = dp.id
       AND blah.key = dp.key)

```


#### order of joins matters looks like 
* I had two gigantic tables (10million+ each) , t1, t2, 
* this first query was taking forever...

```sql
with ids(foo) as (
    select * from generate_series(1, 5000) as foo    
    )    

select * 
from t1 join t2 
on t1.id = t2.id
where t2.id in (select foo from ids)
```

* but this one was quick , I think because the join was done after constraining the ids not before

```sql
with ids(foo) as (
    select * from generate_series(1, 5000) as foo    
    )    

select * 
from t1 join t2 
on t1.id = t2.id
where t1.id in (select foo from ids)
```

#### hashtag binning
* `width_bucket` very nice func for binning some data and then running a `sum()` aggregation afterwards for instance, 
* the array passed to `width_bucket` is an array of the lower bounds
```sql
with deltas(delta, countt) as (
    values (-1, 3), (0, 4), (19, 9), 
           (50, 2), (2, 8), (189, 3), 
           (2000, 98), (2001, 3),
           (null::int, 2),
           (null, 9)
           ),
binned as (
    select  width_bucket (deltas.delta::float, array[
                0, 50, 100, 150,200, 2000]::float[] ) as bin, 
    deltas.delta, deltas.countt
    from deltas 
)
select delta, countt, bin  -- sum(countt) 
from binned 
```

delta|countt|bin
--|--|--
-1|3|0
0|4|1
19|9|1
50|2|2
2|8|1
189|3|4
2,000|98|6
2,001|3|6
[NULL]|2|[NULL]
[NULL]|9|[NULL]

```sql
with deltas(delta, countt) as (
    values (10, 3), (11, 4), (19, 9), 
           (50, 2), (2, 8), (189, 3), 
           (77, 98), (178, 3)),
binned as (
    select  width_bucket (deltas.delta::float, array[
                0::float, 50::float, 100::float, 150::float,200::float, 2000::float] ) as bin, 
    deltas.delta, deltas.countt
    from deltas 
)
select bin, sum(countt) 
from binned
group by bin 
order by bin
```

bin|sum
--|--
1|24
2|100
4|6


#### auto make that markdown table header line

```python
def make_table_header_line(header):
    dashes = ['--' for x in header.split('|')]
    return '|'.join(dashes)
    

```


#### list constraints
* from [stack overflow](https://dba.stackexchange.com/a/214877) ... 
```sql
SELECT con.*
       FROM pg_catalog.pg_constraint con
            INNER JOIN pg_catalog.pg_class rel
                       ON rel.oid = con.conrelid
            INNER JOIN pg_catalog.pg_namespace nsp
                       ON nsp.oid = connamespace
       WHERE nsp.nspname = '<schema name>'
             AND rel.relname = '<table name>';
```

* Oh wow... also this section from the [ALTER TABLE ADD CONSTRAINT postgresql doc ](https://www.postgresql.org/docs/9.6/sql-altertable.html) was super useful/well written..

> _Scanning a large table to verify a new foreign key or check constraint can take a long time, and other updates to the table are locked out until the `ALTER TABLE ADD CONSTRAINT` command is committed. The main purpose of the `NOT VALID` constraint option is to reduce the impact of adding a constraint on concurrent updates. With `NOT VALID`, the `ADD CONSTRAINT` command does not scan the table and can be committed immediately. After that, a VALIDATE CONSTRAINT command can be issued to verify that existing rows satisfy the constraint. The validation step does not need to lock out concurrent updates, since it knows that other transactions will be enforcing the constraint for rows that they insert or update; only pre-existing rows need to be checked. Hence, validation acquires only a `SHARE UPDATE EXCLUSIVE` lock on the table being altered. (If the constraint is a foreign key then a ROW SHARE lock is also required on the table referenced by the constraint.) In addition to improving concurrency, it can be useful to use `NOT VALID` and `VALIDATE CONSTRAINT` in cases where the table is known to contain pre-existing violations. Once the constraint is in place, no new violations can be inserted, and the existing problems can be corrected *at leisure* until `VALIDATE CONSTRAINT` finally succeeds._

```sql
-- step one.
alter table    the_table_name
ADD constraint the_constraint_name unique (col1, col2) NOT VALID 

-- step two..
alter table the_table_name
    VALIDATE CONSTRAINT the_constraint_name
```

#### Having
* Interesting conditional syntax aroung group by , without using a CTE...

```sql
select id, key  , count(*) countt
from my_table

group by id, key 
having count(*) > 1
```
* =>

id|key|countt
--|--|--
1|foo|2
2|bar|3


#### invalid input syntax for integer
* Having come across this a few times, writing down here..
```
InvalidTextRepresentation: invalid input syntax for integer: ""
```
* This typically means a blank string is being coaxed as an integer somewhere. 
* The solution is basically to find these and make sure they're nulls on the db.
* And can also partition with an `id` column too for example, to do a little at a time to experiment.
```sql
update mytable
    set blahcol = null
where  blahcol = ''
    and ( id between 1 and 100000)




```

#### A warning about CTEs 
* Per [this article](https://hakibenita.medium.com/be-careful-with-cte-in-postgresql-fca5e24d2119)  , postgresql will run full CTE and store it, which is why I feel the only practical way of using CTEs in large expressions is along with  partitioning .
* In other words, although most postgresql queries will be able to run only the first `200` rows like a "generator"  and return that to you really quickly, when you have a CTE in there, it has to run the whole thing first.


#### Triggers 
* Per [here](https://serverfault.com/questions/331024/how-can-i-show-the-content-of-a-trigger-with-psql)

```sql
SELECT trigger_schema,event_object_table,trigger_schema,trigger_name,event_manipulation,action_statement,action_timing 
FROM information_schema.triggers 

ORDER BY event_object_table,event_manipulation
```


#### Using window function to dedupe some data
* Given some rows like 

user_id|laptop|purchase_date
--|--|--
1|sony|1
1|nokia|2
1|bell|3
2|3m|2
2|nokia|8

* If we want to dedupe by this simplified integer `purchase_date` 

```sql

with laptops(user_id, laptop, purchase_date) as  (
    values (1, 'sony', 1),
           (1, 'nokia', 2),
           (1, 'bell', 3),
           (2, '3m', 2),
           (2, 'nokia', 8)
)
select l.*, row_number() over w as rnum
from laptops as l
window w as (partition by l.user_id order by purchase_date asc )

```

user_id|laptop|purchase_date|rnum
--|--|--|--
1|sony|1|1
1|nokia|2|2
1|bell|3|3
2|3m|2|1
2|nokia|8|2

And then keep only the `rnum = 1` ...

```sql
with laptops(user_id, laptop, purchase_date) as  (
    values (1, 'sony', 1),
           (1, 'nokia', 2),
           (1, 'bell', 3),
           (2, '3m', 2),
           (2, 'nokia', 8)
),
select aa.* from 
(
    select l.*, row_number() over w as rnum
    from laptops as l
    window w as (partition by l.user_id order by purchase_date asc )
) as aa
where aa.rnum = 1


```

user_id|laptop|purchase_date|rnum
--|--|--|--
1|sony|1|1
2|3m|2|1



#### length of an array  is cardinality

```sql
select cardinality(ARRAY[[1,2],[3,4]])
```
```
4
```

#### logistic

```sql
CREATE or replace FUNCTION myschema.logistic(val float) RETURNS float AS $$
BEGIN
RETURN (1/(1 + ( exp(1)^(-(val))))) ;
END; $$
LANGUAGE PLPGSQL;

```

#### left join two tables with an extra condition and keep the null join rows
* This was bothering me for a bit but I think I have found the solution multiple times now. 
* Writing this out for later
* In this example, there are authors and authors can have one or multiple articles. Self Join articles , to get multiple articles, but only where the left id is less than the right id.
* This is a contrived example, but my use case typically is not a self join but a join with different tables, but the idea still holds.

```sql
with articles(author, article_id, article_title) as (values 
        ('joe', 1, 'birds'),
        ('joe', 2, 'more birds'),
        ('sally', 3, 'eagles'),
        ('sally', 4, 'seagulls'),
        ('jan', 5, 'the philosophical of flying'))
select a.author, a.article_id as left_id, a.article_title as left_title, b.article_id as right_id, b.article_title as right_title
from articles as a left join articles as b on (a.author = b.author and a.article_id < b.article_id)

```

author|left_id|left_title|right_id|right_title
--|--|--|--|--
joe|1|birds|2|more birds
joe|2|more birds|[NULL]|[NULL]
sally|3|eagles|4|seagulls
sally|4|seagulls|[NULL]|[NULL]
jan|5|the philosophical of flying|[NULL]|[NULL]


## using cte for variables
from [this stacko](https://stackoverflow.com/a/16552441/472876) , really handy since yea I don't recall postgresql having declare statements like microsoft sql?
```sql
WITH myconstants (var1, var2) as (
   values (5, 'foo')
)
SELECT *
FROM somewhere, myconstants
WHERE something = var1
   OR something_else = var2;
```



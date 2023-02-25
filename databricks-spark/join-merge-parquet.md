### comparing really large spark dataframes
I had this usecase where I wanted to be able to check if very large multi-million row and multi-thousand column dataframes were equal, but the advice online about using `df1.subtract(df2)` just was not cutting it because it was just too slow. It seems to me the `df1.subtract(df2)` approach more or less is a `O(n^2)` approach where it is necessary to compare each row in `df1` with each row in `df2`. Instead I was wondering, hey if there are known index columns in these dataframes, maybe we can cheat a little and join them first and then do the comparison after joining them.

What I came up with below so far does not handle the case yet of index keys that are not common. I would like to add that at some point. And for now this also requires the schemas of the dataframes to be the same.

```python
def join_compare(df1, df2, index_cols, head_n_rows=None, cache=True):
    # TODO fix to be outer join I think is needed? For now assumes all index cols match fully.
    assert_schema_equality_ignore_nullable(df1.schema, df2.schema)

    if head_n_rows is not None:
        df1 = df1.limit(head_n_rows)

    feature_cols = list(set(df1.columns) - set(index_cols))
    which_type_names = {
        x.name: x.dataType.typeName()
        for x in df1.schema.fields
        if x.name not in index_cols
    }

    double_cols = [k for (k, v) in which_type_names.items() if v == "double"]
    string_cols = [k for (k, v) in which_type_names.items() if v == "string"]
    integer_cols = [k for (k, v) in which_type_names.items() if v == "integer"]

    # To find the actual doubles that are < 1, calculate col means.
    stats_dict = dict(
        df1.select([f.mean(k).alias(k) for k in double_cols])
        .toPandas()
        .to_dict(orient="records")[0]
    )
    double_cols_for_reals = [k for (k, v) in stats_dict.items() if v <= 1]

    integer_types_double_on_paper = [k for (k, v) in stats_dict.items() if v > 1]

    print(
        "all doubles:",
        len(double_cols),
        ", doubles for real:",
        len(double_cols_for_reals),
    )

    diff_dfs = {}
    double_sensitivity = 0.1
    integer_condition = reduce(
        or_,
        (
            [
                (f.round(f.abs(f.col(f"x.{col)") - f.col(f"y.{col}"))) > 0)
                for col in (integer_types_double_on_paper + integer_cols)
            ]
        ),
    )

    string_condition = reduce(
        or_, ([(f.col(f"x.{col}") != f.col(f"y.{col)")) for col in string_cols])
    )

    doubles_condition = reduce(
        or_,
        (
            [
                (f.abs(f.col(f"x.{col}") - f.col(f"y.{col)")) > double_sensitivity)
                for col in double_cols_for_reals
            ]
        ),
    )

    rounded_cols = reduce(
        lambda x, y: x + y,
        [
            (
                f.round(f.col(f"x.{col)"), 2).alias(f"x_{col}"),
                f.round(f.col(f"y.{col)"), 2).alias(f"y_{col}"),
            )
            for col in double_cols_for_reals
        ],
    )

    select_integer_cols = reduce(
        lambda x, y: x + y,
        [
            (f.col(f"x.{col}").alias(f"y_ {col)"), f.col(f"y.{col}").alias(f"y_{col}"))
            for col in (integer_types_double_on_paper + integer_cols)
        ],
    )

    select_string_cols = reduce(
        lambda x, y: x + y,
        [
            (f.col(f"x.{col}").alias(f"x_{col}"), f.col(f"y.{col}").alias(f"y_{col}"))
            for col in string_cols
        ],
    )
```

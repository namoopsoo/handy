
### Passing large dataframes with dbutils.notebook.run !
At one point when migrating databricks notebooks to be useable purely with `dbutils.notebook.run`, the question came up, hey `dbutils.notebook.run` is a great way of calling notebooks explicitly, avoiding global variables that make code difficult to lint and debug, but what about spark dataframes?

I had come across this  https://docs.databricks.com/notebooks/notebook-workflows.html#pass-structured-data nice bit of documentation about using the spark global temp view to handle name references to nicely shuttle around dataframes by reference, given that a caller notebook and a callee notebook share a JVM and theoretically this is instantaneous.

However the example code was a bit lacking and I ended up writing some nice helper functions to make the passing of dataframes, alongside other parameters, a little bit easier and more intuitive!

One of the issues I had with the toy example was that it used static names to pass dataframes, like `my_data`. This was clearly just an example, but I wanted a higher gurantee in avoiding weird collisions, so I used `uuid` to help randomize the names.

But also I wanted to be able to nicely debug my new view names, so I wanted to mix the random `uuid` names with informative names too. It is not straightforward to programmatically capture the name of a variable as a string (you can go down a rabbit hole trying to figure this out haha) so I just settled on creating a simple function `prepare_arguments` which takes keyword arguments  and uses them as the string names of dataframes, when creating random temp view names.

I also wanted the flexibility of just mixing and matching the plain parmeters you pass in, along with dataframes, without making a big deal about it. 

Here is where I ended up below :) 


```python

import json
import pandas as pd
from uuid import uuid4
from pyspark.sql import SparkSession


def prepare_arguments(**kwargs):
    """Create the dbutils.notebook.run payload and put dataframes into global_temp."""
    input_dataframes = {k: v for (k, v) in kwargs.items() if isinstance(v, pd.DataFrame)}
    the_rest = {k: v for (k, v) in kwargs.items() if k not in input_dataframes}

    dataframes_dict = prepare_dataframe_references(**input_dataframes)
    return {**the_rest, "input_dataframes": json.dumps(dataframes_dict)}

def handle_output(raw_output):
    output = json.loads(raw_output)
    dataframes_dict = output.pop("output_dataframe_references", {})
    output_dataframes = dereference_dataframes(dataframes_dict)
    the_rest = {k: v for (k, v) in output.items() if k not in output_dataframes}
    return {**output_dataframes, **the_rest}


def dereference_dataframes(dataframes_dict):
    spark = SparkSession.builder.appName("project").getOrCreate()
    return {
        name: spark.table("global_temp." + view_name)
        for (name, view_name) in dataframes_dict.items()
    }


def prepare_dataframe_references(**kwargs):
    """Puts dataframes into the global_temp schema and returns the view names.

    Args:
        kwargs: key value pairs of names and dataframes
        e.g.
        "some_df": <DataFrame>,
        "another_df": <DataFrame>,

        If any value is not a DataFrame, throws an exception.

    Returns:
        Dict mapping the same input names to view names.
        e.g.
        {
            "some_df": "some_df_fae8f78",
            "another_df": "another_df_0a54d6fe", }
    """
    input_dataframes = [
        {"name": k, "df": v, "view_name": f"{k}_{str(uuid4())[:8]}"}
        for (k, v) in kwargs.items()
        if isinstance(v, pd.DataFrame)
    ]

    the_rest = {
        k: v
        for (k, v) in kwargs.items()
        if k not in [x["name"] for x in input_dataframes]
    }
    print("the_rest", the_rest)
    if the_rest:
        print("also got non dataframe arguments, oops", the_rest)
        raise Exception("Oops, got some non dataframe arguments.")

    for x in input_dataframes:
        x["df"].createOrReplaceGlobalTempView(x["view_name"])

    return {x["name"]: x["view_name"] for x in input_dataframes}



```


### Passing large dataframes with dbutils.notebook.run !
# At one point when migrating
# https://docs.databricks.com/notebooks/notebook-workflows.html#pass-structured-data


import json
import pandas as pd
from uuid import uuid4
from pyspark.sql import SparkSession


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


def prepare_arguments(**kwargs):
    """Create the dbutils.notebook.run payload and put dataframes into global_temp."""
    input_dataframes = {k: v for (k, v) in kwargs.items() if isinstance(v, pd.DataFrame)}
    the_rest = {k: v for (k, v) in kwargs.items() if k not in input_dataframes}

    dataframes_dict = prepare_dataframe_references(**input_dataframes)
    return {**the_rest, "input_dataframes": json.dumps(dataframes_dict)}

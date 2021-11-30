
#### Quick Spark ml lib Logistic Regression Pipeline

Given a dataframe with features you would like to use/transform in a LogisticRegression, similarly to sklearn taking an input without feature names, the spark flavor does the same, taking a single column for the input features.

```python

from pyspark.ml.classification import LogisticRegression
from pyspark.ml.linalg import Vectors
from pyspark.ml.feature import VectorAssembler
from pyspark.ml import Pipeline

def predict_all_of_the_things(df):
    vector_assembler = VectorAssembler(inputCols=[
        "f1",
        "f2",
        "f3",        
    ], outputCol="features")

    # df = vector_assembler.transform(df)
    # print(df.toPandas().head(10))

    lr = LogisticRegression(
        featuresCol="features",
        labelCol="y_my_label",
        maxIter=10,
        regParam=0.1,
        elasticNetParam=1,
        threshold=0.5,
        )
    # blorModel = lr.fit(df)

    pipeline = Pipeline(stages=[vector_assembler, lr])
    e2e = pipeline.fit(df)
    
    outdf = e2e.transform(df)
    # outdf.toPandas.head(10)
    print(outdf.head(10))
    return outdf.select(["user_id", "rawPrediction", "probability", "prediction"])

```

#### spark StringIndexer is like scikitlearn's LabelEncoder
Given a dataframe `flugts` and a categorical col `blah` ,  we can do a `fit` , `transform` , kind of like in scikitlearn.

```python
from pyspark.ml.feature import StringIndexer

flugts = StringIndexer(
    inputCol="blah", 
    outputCol="blah_index"
).fit(
    flugts
).transform(
    flugts
)
```

#### Decision tree classifier

```python
from pyspark.ml.classification import DecisionTreeClassifier
model = DecisionTreeClassifier.fit(foo_train)
prediction = model.transform(foo_test)
```
*  This will produce two new columns, in prediction, 
*   "prediction" and "probability"
* quick confusion matrix , if you also for instance, had the "label" column,

```python
prediction.groupBy("label", "prediction").count().show()
```





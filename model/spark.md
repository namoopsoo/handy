
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

#### Logistic Regression 

```python
from pyspark.ml.classification import LogisticRegression
```

#### Linear Regression

```python
from pyspark.ml.regression import LinearRegression
from pyspark.ml.evaluation import RegressionEvaluator
regression = LinearRegression(labelCol="the_label_col")
regression = regression.fit(train_df)
predictions = regression.transform(test_df)
regression.intercept
regression.coefficients # <== weights for the regression 

# using whatever the default evaluator is ... ( rmse I think)
RegressionEvaluator(labelCol="the_label_col").evaluate(predictions)

# And also if "predictions_col" is where predictions are , 
evaluator = RegressionEvaluator(labelCol="the_label_col").setPredictionCol("predictions_col")
evaluator.evaluate(predictions, {evaluator.metricName: "mae"}) # "mean absolute error"
evaluator.evaluate(predictions, {evaluator.metricName: "r2"})
```

#### And Linear Regression with regularization
* Lambda term =0 ==> no regularization
* Lambda term =inf ==> complete regularization , all coefficients are zero.
* Ridge 
```python
ridge = LinearRegression(
    labelCol="my_label",
    elasticNetParam=0,
    regParam=0.1
)
ridge.fit(train_df)
```
* Lasso
```python
lasso = LinearRegression(
    labelCol="my_label",
    elasticNetParam=1,
    regParam=0.1
)
lasso.fit(train_df)
```


#### Train test split
A Dataframe has this built in func, 

```python
train, test = mydf.randomSplit([0.8, 0.2], seed=42)
```

But it does not produce separate X/y train/test variables the way that is typical in scikitlearn. Maybe that is a helper func that is available.

#### Getting fancier with evaluation 
Given a `prediction` dataframe with columns, `label` and `prediction` , which have been calculated at a particular threshold, we can evaluate as follows,

```python
from pyspark.ml.evaluation import MulticlassClassificationEvaluator
evaluator = MulticlassClassificationEvaluator()
evaluator.evaluate(prediction, {evaluator.metricName: "weightedPrecision"})
evaluator.evaluate(prediction, {evaluator.metricName: "weightedRecall"})
evaluator.evaluate(prediction, {evaluator.metricName: "accuracy"})
evaluator.evaluate(prediction, {evaluator.metricName: "f1"})

from pyspark.ml.evaluation import BinaryClassificationEvaluator
binary_evaluator = BinaryClassificationEvaluator()
auc = binary_evaluator.evaluate(
    prediction,
    {binary_evaluator.metricName: "areaUnderROC"}
)
```

### Text

#### Simple regex substitution
```python
from pyspark.sql.functions import regexp_replace
REGEX = '[,\\-]'
df = df.withColumn('text', regexp_replace(books.text, REGEX, ' '))
```

#### Tokenization
Create a new column with an array of words from free form text. 
```python
from pyspark.ml.feature import Tokenizer
df = Tokenizer(inputCol="text", outputCol="tokens").transform(df)

```
Remove stop words
```python
from pyspark.ml.feature import StopWordsRemover
stopwords = StopWordsRemover()

stopwords.getStopWords()
['i', 'me', 'my', 'myself', 'we', 'our', 'ours', 'ourselves', 'you', 'your', 'yours','yourself', 'yourselves', 'he', 'him', 'his', 'himself', 'she', 'her', 'hers', 'herself','it', 'its', 'itself', 'they', 'them', 'their', 'theirs', 'themselves', 'what', 'which','who', 'whom', 'this', 'that', 'these', 'those', 'am', 'is', 'are', 'was', 'were', 'be','been', 'being', 'have', 'has', 'had', 'having', 'do', 'does', 'did', 'doing', ...]

# Specify the input and output column names
stopwords = stopwords.setInputCol('tokens').setOutputCol('words')
df = stopwords.transform(df)
```

#### Term frequency transformer

```python
from pyspark.ml.feature import HashingTF
hasher = HashingTF(inputCol="words", outputCol="hash", numFeatures=32)
df = hasher.transform(df)

```
And we can do page-rank like proportional inverted indexing too

```python
from pyspark.ml.feature import IDF
df = IDF(inputCol="hash", outputCol="features").fit(df).transform(df)

```

#### One Hot Encoding
Spark uses a sparse representation of one-hot-encoded features
```python
from pyspark.ml.feature import OneHotEncoderEstimator
onehot = OneHotEncoderEstimator(inputCols=["type_blah"], outputCols=["type_one_hot"])
onehot.fit(df)

onehot.categorySizes # <== gives how many categories processed.
df = onehot.transform(df)
```
A `SparseVector` takes the length of the vector as the first arg and a key-val dict for the sparse values
```python
from pyspark.mllib.linalg import DenseVector, SparseVector
DenseVector([1, 0, 0, 0, 0, 7, 0, 0]) # each value is kept

SparseVector(8, {0: 1.0, 5: 7.0})
```

#### Bucketing

```python
from pyspark.ml.feature import Bucketizer

bucketizer = Bucketizer(
    splits=[20, 30, 40, 50],
    inputCol="age",
    outputCol="age_bin"
)
df = bucketizer.transform(df)

```
Similar to categorical encoding benefiting from one hot encoding, bucketing will also benefit from one hot encoding


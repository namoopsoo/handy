
#### Read 

```python
loc = "dbfs:/databricks-datasets/wine-quality/winequality-red.csv"
blah_df = spark.read.csv(loc, sep=";", header=True)
```

#### Map an existing function 

```python
import spark.sql.functions as F
loc = "dbfs:/databricks-datasets/wine-quality/winequality-red.csv"
df = spark.read.csv(loc, sep=";", header=True)
df = df.withColumn("sugar_rounded", F.round(df["residual sugar"]))
df.select("residual sugar", "sugar_rounded").show(5)
```

```
+--------------+-------------+
|residual sugar|sugar_rounded|
+--------------+-------------+
| 1.9          |          2.0|
| 2.6          |          3.0|
+--------------+-------------+
```

#### User Defined Functions
* A user defined function needs to be defined with a  return type 
* For instance, say there's a dataframe `df` with a `name` column, that have spaces between first and last names say, and you can split them up like so, only grabbing the first `2` , for example, by also using `F.lit` to specify a literal value being passed to the func as well.

```python
import pyspark.sql.functions as F
from pyspark.types import ArrayType, StringType

def split_name(name):
    return name.split(" ")[:2]
    
udfSplitter = F.udf(split_name, ArrayType(StringType()))

df = ...
df = df.withColumn("separated_names", udfSplitter(df.name, F.lit(2)))

```

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

    lr = LogisticRegression(
        featuresCol="features",
        labelCol="y_my_label",
        maxIter=10,
        regParam=0.1,
        elasticNetParam=1,
        threshold=0.5,
        )

    pipeline = Pipeline(stages=[vector_assembler, lr])
    e2e = pipeline.fit(df)
    
    outdf = e2e.transform(df)
    print(outdf.head(10))
    return outdf.select(["user_id", "rawPrediction", "probability", "prediction"])

```

#### Pipeline with train/test handling also

```python
from pyspark.ml.classification import LogisticRegression
from pyspark.ml.linalg import Vectors
from pyspark.ml.feature import VectorAssembler
from pyspark.ml.feature import OneHotEncoderEstimator
from pyspark.ml.feature import StringIndexer
from pyspark.ml import Pipeline

indexer = StringIndexer(...)
onehot = OneHotEncoderEstimator(...)
assemble = VectorAssembler(...)
regression = LogisticRegression(...)
pipeline = Pipeline(stages=[indexer, onehot, assemble, regression])

blah_df = spark.read.csv(...)
train_df, test_df = blah_df.randomSplit([0.8, 0.2], seed=42)

# And now fit the pipeline only on the train part
pipeline = pipeline.fit(train_df)

# And predictions..
predictions = pipeline.transform(test_df)
```
And the various stages of the pipeline are indexable, for example, to get the intercept and coefficient of the `regression` step, 

```python
print(pipeline.stages[3].intercept, pipeline.stages[3].coefficients)
```
Will produce the intercept `3.9` and coefficients, `DenseVector([...])` for the regression stage of the pipeline.


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
HashingTF , will use a hash algo `MurmurHash 3` (not sure why not a more well known hash func) , to map to an integer from `1` to a default of `262,144` . (Oh  that's probably part of the difference, using an integer as opposed to a long 256 bit output hash then) . And the output will include the frequency of the hashed output.

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

#### pipeline for some of these NLP steps
Below, assume we have an input dataframe with some kind of `raw_text` column that has free form text. Then the below pipeline can tokenize that text, remove stop words, and create a term frequency inverted index, 

```python
from pyspark.ml.feature import Tokenizer, StopWordsRemover, HashingTF, IDF
from pyspark.ml.regression import LogisticRegression
from pyspark.ml.feature import Pipeline

tokenizer = Tokenizer(
    inputCol="raw_text", outputCol="tokens"
)

remover = StopWordsRemover(
    inputCol="tokens", outputCol="terms"
)

hasher = HashingTF(
    inputCol="terms", outputCol="hash"
)
idf = IDF(
    inputCol="hash", outputCol="features"
)

logistic = LogisticRegression()
pipeline = Pipeline(
    stages=[
        tokenizer,
        remover,
        hasher,
        idf,
        logistic,
    ]
)

```

#### One Hot Encoding
Spark uses a sparse representation of one-hot-encoded features
```python
from pyspark.ml.feature import OneHotEncoderEstimator
onehot = OneHotEncoderEstimator(
    inputCols=["type_blah"], 
    outputCols=["type_one_hot"]
)
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

#### Cross Validation
Given a model and an evaluator, where the model can also be a pipeline, 

```python
from pyspark.ml.tuning import CrossValidator, ParamGridBuilder
model = LinearRegression(labelCol="y_label")
evaluator = RegressionEvaluator(labelCol="y_label")

grid = ParamGridBuilder() \
    .addGrid(model.elasticNetParam, [0, 0.5, 1.]) \
    .addGrid(model.regParam, [0.01, 0.1, 1, 10]) \
    .addGrid(model.fitIntercept, [True, False]) \
    .build()

print("number of models to be built from the grid =>", len(grid))

cv = CrossValidator(
    estimator=model,
    estimatorParamMaps=grid,
    evaluator=evaluator,
    numFolds=5,
    seed=42,
)

cv.fit(train_df)

# the average metric whatever it is, for each combo in the grid.
cv.avgMetrics 

# can use the best model like this,
cv.bestModel.transform(test_df) 

# Can also use the best model implicitly...
cv.transform(test_df)

# And look at a metric hence for that model, 
print("rmse", evaluator.evaluate(cv.bestModel.transform(test_df), {evaluator.metricName: "rmse"}))

# You can get some quick documentation like this wow. Neat trick.
cv.bestModel.explainParam("elasticNetParam")

# Can look at the params like this too
for param, val in cv.bestModel.extractParamMap().items:
    print((param.name, val), f"({param.doc})")
```
for a RandomForestClassifier this will print for instance ... something like 

```
predictionCol prediction
featureSubsetStrategy onethird
maxMemoryInMB 256
rawPredictionCol rawPrediction
cacheNodeIds False
probabilityCol probability
impurity gini
featuresCol features
maxDepth 20
labelCol label
subsamplingRate 1.0
maxBins 32
checkpointInterval 10
minInstancesPerNode 1
minInfoGain 0.0
numTrees 20
seed 1720035589386331064
```

#### random forest

```python
from pyspark.ml.classification import RandomForestClassifier, GBTClassifier
from pyspark.ml.evaluation import BinaryClassificationEvaluator

forest = RandomForestClassifier()

forest.featureImportances # produces a SparseVector , 

gbt = GBTClassifier()

gbt.getNumTrees  # number of trees 

```
There is also an amazing debug output available with , `gbt.toDebugString`

```python
In [10]:
print(gbt.toDebugString.split("Tree")[0])
GBTClassificationModel (uid=GBTClassifier_c601194e39a1) with 20 trees
  
In [12]:
print(gbt.toDebugString.split("Tree")[1])
 0 (weight 1.0):
    If (feature 1 <= 9.6)
     If (feature 2 <= 118.5)
      If (feature 0 <= 2.5)
       If (feature 1 <= 7.075)
        If (feature 2 <= 109.5)
         Predict: -0.5702479338842975
        Else (feature 2 > 109.5)
         Predict: -0.17391304347826086
       Else (feature 1 > 7.075)
        If (feature 2 <= 92.5)
         Predict: -0.3117782909930716
        Else (feature 2 > 92.5)
         Predict: -0.1232876712328767
      Else (feature 0 > 2.5)
       If (feature 0 <= 10.5)
        If (feature 2 <= 92.5)
         Predict: -0.6527027027027027
        Else (feature 2 > 92.5)
         Predict: -0.48745046235138706
       Else (feature 0 > 10.5)
        If (feature 1 <= 7.075)
         Predict: -0.47368421052631576
        Else (feature 1 > 7.075)
         Predict: -0.19090909090909092
     Else (feature 2 > 118.5)
      If (feature 0 <= 5.5)
       If (feature 1 <= 7.74)
        If (feature 2 <= 197.5)
         Predict: -0.3770491803278688
        Else (feature 2 > 197.5)
         Predict: -0.0916030534351145
       Else (feature 1 > 7.74)
        If (feature 0 <= 4.5)
         Predict: -0.10258418167580266
        Else (feature 0 > 4.5)
         Predict: 0.10580204778156997
      Else (feature 0 > 5.5)
       If (feature 0 <= 10.5)
        If (feature 0 <= 8.5)
         Predict: -0.27740863787375414
        Else (feature 0 > 8.5)
         Predict: -0.5332348596750369
       Else (feature 0 > 10.5)
        If (feature 1 <= 8.66)
         Predict: -0.014492753623188406
        Else (feature 1 > 8.66)
         Predict: 0.23333333333333334
    Else (feature 1 > 9.6)
     If (feature 0 <= 6.5)
      If (feature 2 <= 124.5)
       If (feature 1 <= 16.509999999999998)
        If (feature 0 <= 1.5)
         Predict: 0.11760883690708251
        Else (feature 0 > 1.5)
         Predict: -0.023830031581969568
       Else (feature 1 > 16.509999999999998)
        If (feature 2 <= 50.5)
         Predict: -0.23404255319148937
        Else (feature 2 > 50.5)
         Predict: 0.20102827763496145
      Else (feature 2 > 124.5)
       If (feature 1 <= 15.675)
        If (feature 0 <= 1.5)
         Predict: 0.2877813504823151
        Else (feature 0 > 1.5)
         Predict: 0.19178515007898894
       Else (feature 1 > 15.675)
        If (feature 2 <= 288.0)
         Predict: 0.475375296286542
        Else (feature 2 > 288.0)
         Predict: 0.18562874251497005
     Else (feature 0 > 6.5)
      If (feature 0 <= 10.5)
       If (feature 0 <= 8.5)
        If (feature 2 <= 85.5)
         Predict: -0.27121464226289516
        Else (feature 2 > 85.5)
         Predict: 0.0723354000590493
       Else (feature 0 > 8.5)
        If (feature 1 <= 13.16)
         Predict: -0.4181152790484904
        Else (feature 1 > 13.16)
         Predict: -0.2569395017793594
      Else (feature 0 > 10.5)
       If (feature 1 <= 15.125)
        If (feature 2 <= 60.5)
         Predict: 0.3333333333333333
        Else (feature 2 > 60.5)
         Predict: 0.15768056968463887
       Else (feature 1 > 15.125)
        If (feature 2 <= 76.5)
         Predict: 0.12863070539419086
        Else (feature 2 > 76.5)
         Predict: 0.37316017316017314
```

### Special databricks stuff 
Check out what local file system  access is available , by 

```
display(dbutils.fs.ls("dbfs:/"))
```



### References
A lot of this was inspired by [this great DataCamp course](https://campus.datacamp.com/courses/machine-learning-with-pyspark) . 


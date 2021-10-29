
* One particularly killer feature about the `ColumnTransformer` is that you can apply a specific preprocessor for a subset of the columns, and then set `remainder="passthrough"` for the others
 
```python
import numpy as np
from sklearn.preprocessing import (MinMaxScaler, OneHotEncoder, LabelEncoder)
from sklearn.preprocessing import Binarizer

from sklearn.compose import ColumnTransformer


from sklearn.pipeline import Pipeline
from sklearn import metrics
from sklearn.ensemble import RandomForestClassifier
from sklearn.datasets import make_classification
from sklearn.model_selection import cross_val_score, train_test_split

def make_data():
    X, y = make_classification(n_samples=1000, n_features=4,
                               n_informative=2, n_redundant=0,
                               random_state=42, shuffle=False,
                               weights=(0.25,),

                               )
    # return X, y
    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.33, random_state=42,
    )
    return X_train, X_test, y_train, y_test
# In [90]: Counter(y)
# Out[90]: Counter({0: 258, 1: 742})

def forest_one():
    preprocessor = ColumnTransformer([
        ("scaler", MinMaxScaler(), [0, 1]),

        ],
        remainder="passthrough")

    pipeline = Pipeline([
        # ("scale", MinMaxScaler()),
        ("preproc", preprocessor),
        (
            "clf",
            RandomForestClassifier(
                max_depth=2,
                random_state=0,
                n_estimators=100,
                # class_weight="balanced_subsample", # "balanced", "balanced_subsample" or {0: 0.1, 1: 0.9 } weights per class 
            )
        ),
    ])
    return pipeline


def forest_balanced():
    pipeline = Pipeline([
        ("scale", MinMaxScaler()
            ),
        (
            "clf",
            RandomForestClassifier(
                max_depth=2,
                random_state=0,
                n_estimators=100,
                class_weight="balanced_subsample", # "balanced", "balanced_subsample" or {0: 0.1, 1: 0.9 } weights per class 
            )
        ),
    ])
    return pipeline

def e2e(X_train, y_train, pipeline):
    scorers = ["f1_micro", "roc_auc"]
    scores = [
            [scorer, 
cross_val_score(pipeline, X_train, y_train, cv=3,
            scoring=scorer)
                ]
            for scorer in scorers
            ]

    pipeline.fit(X_train, y_train)

    return pipeline, scores

def holdout_test(X_test, y_test, pipeline):
    y_preds = pipeline.predict(X_test)
    f1 = metrics.f1_score(y_test, y_preds, average="micro")

    y_preds = pipeline.predict_proba(X_test)[:, 1]

    fpr, tpr, thresholds = metrics.roc_curve(y_test, y_preds, pos_label=1)
    auc = metrics.auc(fpr, tpr)

    return {"f1": f1, "auc": auc}


"""
# X = np.array([[-1, 2], [-0.5, 6], [0, 10], [1, 18]])
scaler = MinMaxScaler()
print(scaler.fit(X))
print(scaler.data_min_, scaler.data_max_)
print(scaler.transform(X))
# X_std = (X - X.min(axis=0)) / (X.max(axis=0) - X.min(axis=0))
"""


"""
X_train, X_test, y_train, y_test = qp.make_data()
p1 = qp.forest_one()
p2 = qp.forest_balanced()
_, scores1 = qp.e2e(X, y, p1)
print("p1", scores1)
qp.holdout_test(X_test, y_test, p1)
_, scores2 = qp.e2e(X, y, p2)
print("p2", scores2)
qp.holdout_test(X_test, y_test, p2)
"""
```

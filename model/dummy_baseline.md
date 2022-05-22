### Super cool model baseline technique
From scikitlearn, this is a super cool way of getting a baseline. In the past I had done this majority class assignment manually. But it is super cool this is kind of built in.

```python
from sklearn.dummy import DummyClassifier 
X, y = get_some_data()
X_train, X_test, y_train, y_test = do_some_splitting(X, y)

dummy_clf = DummyClassifier(strategy="most_frequent")
dummy_clf.fit(X_train, y_train)
dummy_clf.score(X_test, y_test)

```

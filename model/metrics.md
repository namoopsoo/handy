
###  TPR, FPR

```python
tpr = 1.0*TP/(FN + TP) # aka recall
fpr = 1.0*FP/(FP + TN) # 
```

### Confusion matrix
* Given a `testdf` where first column contains actual labels, `0`, `1`, and `predictions` is a list of probabilities, 
```python
y_pred = (y_prob >= 0.08)
confusion = pd.crosstab(index=y_true, 
            columns=y_pred, 
            rownames=['actual'], colnames=['predictions'])
```

predictions	|False	|True
--|--|--
actual		||
0|	509	|132
1|	32	|22


#### Also there is a super nice helper in scikitlearn 
Below, using some pre-baked results from running some of the chapter 2 code from https://transformersbook.com/ . 

So first, when using `ConfusionMatrixDisplay` out of the box, I get
```python
from sklearn.metrics import ConfusionMatrixDisplay, confusion_matrix

with plt.style.context('dark_background'):
    cm = confusion_matrix(y_valid, y_preds, normalize="true")
    disp = ConfusionMatrixDisplay(confusion_matrix=cm, display_labels=labels)
    disp.plot()
    plt.show()    

```
<img src="https://github.com/namoopsoo/handy/blob/master/assets/Screen%20Shot%202022-05-22%20at%205.49.35%20PM--standard.png" width="50%">

And I can see why that was not used in the book haha because the modified version, below, looks much better indeed, 
```python
from sklearn.metrics import ConfusionMatrixDisplay, confusion_matrix 
def plot_confusion_matrix(y_preds, y_true, labels):
    with plt.style.context("dark_background"):
        cm = confusion_matrix(y_true, y_preds, normalize="true")
        fix, ax = plt.subplots(figsize=(6, 6))
        disp = ConfusionMatrixDisplay(confusion_matrix=cm, display_labels=labels)
        disp.plot(cmap="Blues", values_format=".2f", ax=ax, colorbar=False)
        plt.title("Normalized confusion matrix")
        plt.show()

y_preds = lr_clf.predict(X_valid)     
plot_confusion_matrix(y_preds, y_valid, labels)

```
<img src="https://github.com/namoopsoo/handy/blob/master/assets/Screen%20Shot%202022-05-22%20at%205.50.22%20PM--nice.png"  width="50%">


### f1
```python
def calc_f1(confusion):
    TN = confusion.loc[0, 0]
    FP = confusion.loc[0, 1]
    FN = confusion.loc[1, 0]
    TP = confusion.loc[1, 1]
    
    precision = TP/(FP + TP)
    recall = TP/(FN + TP)
    return 2*(precision**2)/(precision + recall)
    
predictions = [] # list of probabilities , e.g. array([0.05567192, 0.03781519, 0.05437384, 0.01572161, ...])
cutoffs = np.arange(0.01, 0.5, 0.01)
f1_vec = []
for c in cutoffs:
    confusion = pd.crosstab(index=testdf.iloc[:, 0], 
                columns= (predictions > c), 
                rownames=['actual'], colnames=['predictions'])
    try:
        f1 = calc_f1(confusion)
    except TypeError:
        f1 = np.nan
    f1_vec.append(f1)
    

# fig = plt.figure()
plt.plot(cutoffs, np.array(f1_vec))
plt.xlabel('cutoff')
plt.ylabel('f1')
plt.show()
```

<img src="https://github.com/seanickle/handy/blob/master/assets/f1-output.png">


#### ks for a cutoff 

```python
def get_flargs(confusion):
    cols = confusion.columns.tolist()
    if False not in cols:
        TN = 0
        FN = 0
    else:
        TN = confusion.loc[0, False] # loc[0, 0] this works in newer pandas , not 0.18
        FN = confusion.loc[1, False]

    if True not in cols:
        FP = 0
        TP = 0
    else:
        FP = confusion.loc[0, True]
        TP = confusion.loc[1, True]
        
    return (TP, FP, TN, FN)
        
def calc_f1(TP, FP, TN, FN):
    if (FP + TP) == 0 or (FN + TP) == 0:
        return np.nan
    
    precision = 1.0*TP/(FP + TP)
    recall = 1.0*TP/(FN + TP)

    return {2*(precision*recall)/(precision + recall)}

def ks_for_cutoff(TP, FP, TN, FN):
    
    #  It is the maximum difference between TPR (aka recall) and FPR ()
    tpr = 1.0*TP/(FN + TP) # aka recall
    fpr = 1.0*FP/(FP + TN)
    return tpr - fpr
    

def thisthings(y_true, y_prob):
    cutoffs = np.arange(0.01, 1.0, 0.01)
    f1_vec = []
    ks_vec = []
    tpr_vec = []
    fpr_vec = []
    tnr_vec = []

    for c in cutoffs:
        y_pred = (y_prob > c)
        confusion = pd.crosstab(index=y_true, 
                    columns=y_pred, 
                    rownames=['actual'], colnames=['predictions'])

        # print (c, confusion.shape, confusion.columns.tolist())

        (TP, FP, TN, FN) = get_flargs(confusion)
        try:
            tpr = 1.0*TP/(FN + TP) # aka recall
        except:
            tpr = np.nan

        try:
            fpr = 1.0*FP/(FP + TN)
        except:
            fpr = np.nan

        tpr_vec.append(tpr)
        fpr_vec.append(fpr)

        # f1 = calc_f1(confusion)
        f1 = sklearn.metrics.f1_score(y_true, y_pred)
        f1_vec.append(f1)

        ks = ks_for_cutoff(TP, FP, TN, FN)
        ks_vec.append(ks)

    return [cutoffs,
            f1_vec,
            ks_vec,
            tpr_vec,
            fpr_vec,
            tnr_vec]

```

```python
[cutoffs,
            f1_vec,
            ks_vec,
            tpr_vec,
            fpr_vec,
            tnr_vec] = thisthings(y_true, y_prob)
            
plt.plot(cutoffs[:20], np.array(ks_vec)[:20], label='ks')
plt.plot(cutoffs[:20], np.array(fpr_vec)[:20], label='fpr')
plt.plot(cutoffs[:20], np.array(tpr_vec)[:20], label='tpr')
plt.xlabel('cutoff')

plt.legend()
plt.show()

```

<img src="https://github.com/seanickle/handy/blob/master/assets/ks.png">

### Weighted Precision
* Had to reverse engineer this from the source code here , https://scikit-learn.org/stable/modules/generated/sklearn.metrics.precision_score.html  ... 
* But for a 2 class classification problem weighted precision is basically weighing correctness of positive predictions and correctness of negative predictions, proportional to the number of positive and negative labels in the data. 
 
```
weighted_precision = [(TN/(FN + TN)) * ((size (label = N))/( size (total)))]  + [(TP/(FP + TP)) * ((size(label = P))/(size (total)))]
```


### References
* https://www.datavedas.com/model-evaluation-in-python/


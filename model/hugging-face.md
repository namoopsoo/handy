
#### Read a dataset to pandas 

```python
import pandas as pd
from datasets import load_dataset
emotions = load_dataset("emotion")

# emotions["train"] # this is still a datasets.arrow_dataset.Dataset
df = emotions["train"][:]  # but adding that "[:]" slice grants a DataFrame !
df.head()
```

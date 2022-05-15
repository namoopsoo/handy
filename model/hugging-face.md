### Mainly notes from reaading the Natural Language Processing with Transformers book 
Really nice book! I have the urge to write down for myself some snippets so I can more easily refer to them later.

#### Read a dataset to pandas 

```python
import pandas as pd
from datasets import load_dataset
emotions = load_dataset("emotion")

# emotions["train"] # this is still a datasets.arrow_dataset.Dataset
emotions.set_format(type="pandas")
df = emotions["train"][:]  # but adding that "[:]" slice grants a DataFrame !
df.head()

# Go back to initial format
emotions.reset_format()
```

#### Cool Mini Tokenization example 
```python
from transformers import AutoTokenizer
model_ckpt = "distilbert-base-uncased"
tokenizer = AutoTokenizer.from_pretrained(model_ckpt)
text = "Tokenizing text is a core task of NLP."

encoded_text = tokenizer(text)
print(encoded_text)
```
```python
{'input_ids': [101, 19204, 6026, 3793, 2003, 1037, 4563, 4708, 1997, 17953,
2361, 1012, 102], 'attention_mask': [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]}
```
```python
# oh cool and the tokenizer lets you convert back , 
tokens = tokenizer.convert_ids_to_tokens(encoded_text.input_ids)
print(tokens)
```
```python
['[CLS]', 'token', '##izing', 'text', 'is', 'a', 'core', 'task', 'of', 'nl',
'##p', '.', '[SEP]']
```
And finally
```python
print(tokenizer.convert_tokens_to_string(tokens))
[CLS] tokenizing text is a core task of nlp. [SEP]
```

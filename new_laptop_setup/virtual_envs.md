Nice that now python has this built in method for creating virtual environments per [docs](https://docs.python.org/3/library/venv.html)

```sh
# like this 
python3 -m venv /path/to/new/virtual/environment


python -m venv ~/.python_venvs/skpy39
source  ~/.python_venvs/skpy39/bin/activate
pip install scikit-learn scikit-learn pandas ipdb ipython matplotlib tqdm colormap easydev 
```


### concurrent.futures
Recently at work I needed to add retry logic to some code that was using the `concurrent` python library.

I had done some research and I ended up also answering  [this](https://stackoverflow.com/questions/55455309/how-to-re-execute-function-in-threadpoolexecutor-in-case-of-error/72672692#72672692) stack overflow question too in the process. 

I am finding `concurrent.futures` to be pretty nice! Of course `joblib` is nice too. 

Anyway, re-posting my answer below as well.

```python
import concurrent.futures
import time
import urllib
from random import randint
from collections import defaultdict

URLS = ['http://www.foxnews.com/',
        'http://www.cnn.com/',
        'http://europe.wsj.com/',
        'http://www.bbc.co.uk/',
        'http://some-made-up-domain.com/']
URLS = [f"http://fake{i}.com" for i in range(20)]

# Retrieve a single page and report the URL and contents
def load_url(url, timeout):
    if "fake" in url:
        time.sleep(1)
        x = randint(1, 10)
        if x <= 5:
            return {"timeout": True, "error": "SimulatedTimeout", "url": url}
        elif x in [6, 7]:
            return {"error": "SomeOtherError", "url": url}
        else:
            return {"data": "<html>" + str(randint(1, 999999)) + "</html>", "url": url}

    try:
        with urllib.request.urlopen(url, timeout=timeout) as conn:
            data = conn.read()
            return {"data": data, "url": url}
    # except urllib.error.URLError as e:
    except Exception as e:
        if "TimeoutError" in repr(e):
            return {"timeout": True, "error": repr(e), "url": url}
        else:
            return {"error": repr(e), "url": url}

todo = [{"url": url} for url in URLS]
final_results = []
retry_counts = defaultdict(int)
max_retries = 5
with concurrent.futures.ThreadPoolExecutor(max_workers=5) as executor:
    while True:
        future_list = [executor.submit(load_url, item["url"], 60) for item in todo]
        todo = []
        for future in concurrent.futures.as_completed(future_list):
            result = future.result()
            if result.get("data"):
                final_results.append({**result, "retries": retry_counts[result["url"]]})
            elif result.get("error") and not result.get("timeout"):
                final_results.append({**result, "retries": retry_counts[result["url"]]})
            elif result.get("timeout") and retry_counts[result["url"]] < max_retries:
                retry_counts[result["url"]] += 1
                todo.append({"url": result["url"]})
            else:
                final_results.append({**result, "reached_max_retries": True, "retries": retry_counts[result["url"]]})
        if len(final_results) == len(URLS):
            print("Done!")
            break
        else:
            print(f"we are now {len(final_results)} out of {len(URLS)}")
```

with the output

```python
we are now 10 out of 20
we are now 11 out of 20
we are now 16 out of 20
we are now 17 out of 20
we are now 18 out of 20
Done!

In [45]: pd.DataFrame.from_records(final_results)
Out[45]: 
               error                url  retries                 data timeout reached_max_retries
0     SomeOtherError   http://fake0.com        0                  NaN     NaN                 NaN
1                NaN   http://fake2.com        0  <html>124983</html>     NaN                 NaN
2     SomeOtherError   http://fake3.com        0                  NaN     NaN                 NaN
3                NaN   http://fake7.com        0  <html>459880</html>     NaN                 NaN
4     SomeOtherError  http://fake10.com        0                  NaN     NaN                 NaN
5                NaN  http://fake13.com        0  <html>598498</html>     NaN                 NaN
6                NaN  http://fake15.com        0  <html>477976</html>     NaN                 NaN
7                NaN  http://fake16.com        0  <html>748633</html>     NaN                 NaN
8     SomeOtherError  http://fake17.com        0                  NaN     NaN                 NaN
9                NaN  http://fake19.com        0  <html>104853</html>     NaN                 NaN
10               NaN   http://fake9.com        1  <html>677035</html>     NaN                 NaN
11               NaN   http://fake8.com        2  <html>249557</html>     NaN                 NaN
12               NaN   http://fake5.com        2  <html>516063</html>     NaN                 NaN
13    SomeOtherError   http://fake6.com        2                  NaN     NaN                 NaN
14    SomeOtherError  http://fake11.com        2                  NaN     NaN                 NaN
15               NaN  http://fake12.com        2   <html>66441</html>     NaN                 NaN
16               NaN   http://fake1.com        3  <html>604868</html>     NaN                 NaN
17    SomeOtherError  http://fake18.com        4                  NaN     NaN                 NaN
18  SimulatedTimeout   http://fake4.com        5                  NaN    True                True
19  SimulatedTimeout  http://fake14.com        5                  NaN    True                True
```



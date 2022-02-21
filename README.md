# Offwrist-detection
This program can label the data from actigraphy as non-wear or wear based on a trained random forest algorithm 

You can test the program with the actigraphy series inside ./data/ directory.

The real label is presented on column "NA2":
- `0`: Wearing

- `1`: Not-wearing

## Requriments
You need to install Python 3.8+ to run this code.
Check if python is installed by using the following command:
```Shell
> python --version
```
Output:
```Shell
Python 3.8.x
```

To install all the needed packages to run this code.
In the folder of this project, run the following command:
```Shell
> pip install -r requirements.txt
```

You can run the program with the following command:
```Shell
> python main.py "actigraphy_sequence.xlsx"
```

The output will be added to the end of your xlsx file.
Output example:

| ........ |     timeVar      |   NA2   |  NA3  |  ML_OffWrist_Prediction |
| -------- | ---------------- | ------- | ----- |  ---------------------- |
| ........ | 28/09/2020 00:00 |    1    |   NA  |           1             |
| ........ | 28/09/2020 00:01 |    1    |   NA  |           1             |
| ........ | 28/09/2020 00:02 |    1    |   NA  |           1             |


### Try the code using our examples in ./data/
```Shell
> python main.py "data/01.xlsx"
```
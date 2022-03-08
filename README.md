# Offwrist-detection
This program can label the data from actigraphy as non-wear or wear based on a trained random forest algorithm 

You can test the program with the actigraphy series inside ./data/ directory.

The real label is presented on column "NA2":
- `0`: Wearing

- `1`: Not wearing

## Requirements
You need to install Python 3.8+ to run this code.
Check if Python is installed by using the following command:
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

## Running the code

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


## Datasets

The data are divided in three directories:
- [./data_train/](https://github.com/LMicol/offwrist-detection/tree/main/data_train) : off-wrist periods shorter than 30 minutes were considered wear for training purposes (true label = "NA2" column).
- [./data_raw/](https://github.com/LMicol/offwrist-detection/tree/main/data_raw) : raw data from the actimeters - HA was run on those in our publication.
- [./data_test/](https://github.com/LMicol/offwrist-detection/tree/main/data_test): The column "NA2" is the user record for off-wrist (with intervals <30min included; true label). The results of both ML and HA performances reported in our publication were computed using this.

Data from our validation (proof-of-concept) cannot be made available, but results are described in the publication.

### Try the code using our examples in ./data/
```Shell
> python main.py "data/01.xlsx"
```


## HA function

You can also find the HA function as described in our publication [here](https://github.com/LMicol/offwrist-detection/blob/main/Fct_HA_NAid_Condor_v3.1.R).

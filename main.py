# -*- coding: utf-8 -*-
"""
    This is a offwrits identification program for actigraphy analysis

This program will classify data from an actigraph as offwrist or not. Based in
those features: ['DATE.TIME', 'TEMPERATURE', 'LIGHT', 'RED.LIGHT', 'GREEN.LIGHT',
                 'BLUE.LIGHT', 'PIM', 'TAT', 'ZCM']
Be sure that you are providing all the above features to execute properly.

We also generated other features to compute the ML solution. It may take a
while to execute.

The program works using a RandonForestClassifier trained with colected data
that you can check on ./data directory.

The results from the tests got around 98% accuracy.

Note that this detector only recognizes offwrtist periods longer than 30 minutes

@author: Lucas Micol
"""
import sys
import time
import pandas as pd

import DataProcessing as dp
from OffWristDetection import OffWristEstimator


def main():
    try:
        # read the file from arg
        file = str(sys.argv[1])
        df = pd.read_excel(file)
        
        # in this step the DataProcessing will verify if the file contains all
        # the required columns - check data integrity
        if (not(dp.check_integrity(df))):
            print("Your file does not contain all the required columns\n")
            print("Be sure that you are providing this columns with the exact label")
            print("['DATE.TIME', 'TEMPERATURE', 'LIGHT', 'RED.LIGHT','GREEN.LIGHT','BLUE.LIGHT','PIM', 'TAT', 'ZCM']")
            exit (-1)
        
        # time to compute
        start_time = time.time()
        
        # if the data is okay, then we calculate the features for the estimator
        features = dp.offwrist_features(df)
        
        # after the calculation we finish the data preparation
        X = dp.data_preparation(df, features)
        
        # instantiate the classifier
        Estimator = OffWristEstimator()
        
        # predict based on the data
        # the fillna solve the problem of Input contains NaN, infinity or a value too large for dtype('float32').
        prediction = Estimator.predict(X.fillna(0))
        
        ############################################################
        # If you have a visual inspetion use this code bellow to test de acc
        # just change the 'NA2' to the name of the column you want to compare
        #y = df['NA2'].values.ravel()
        #hit = 0
        #mis = 0 
        #for i in range(len(prediction)):
        #    if (prediction[i] == y[i]):
        #        hit += 1
        #    else:
        #        mis += 1
        #print("accuracy :" + str(hit/(hit+mis)) )
        ############################################################
        
        # time to compute print
        print(time.time() - start_time)
        
        # This last part saves the dataset on your local execution folder
        prediction = pd.DataFrame({'ML_OffWrist_Prediction':prediction})
        final = pd.concat([df, prediction], axis=1)
        final.to_excel(str(sys.argv[1])[:-5]+'_prediction.xlsx')
        
        
    ########################### ERROR treatment ##############################        
    except OSError as err:
        print("ERROR: OS error {0}".format(err))
    #except ValueError:
    #    print("ERROR:  Your file was not recognized by the program, are sure you're inputing an excel file?")
    except FileNotFoundError:
        print("ERROR: File not founded!")
    #except:
    #    print("UNKNOW ERROR->", sys.exc_info()[0])
        
if __name__ == "__main__":
    main()
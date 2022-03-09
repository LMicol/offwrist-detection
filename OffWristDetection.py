# -*- coding: utf-8 -*-
"""
    This is a offwrits identification program for actigraphy analysis

This program will classify data from an actigraph as offwrist or not. Based in
those features: ['DATE.TIME', 'TEMPERATURE', 'LIGHT', 'RED.LIGHT', 'GREEN.LIGHT',
                 'BLUE.LIGHT', 'PIM', 'TAT', 'ZCM']
Be sure that you are providing all the above features to execute properly

We also generated other features to compute the ML solution. It may take a
while to execute.

The program works using a RandonForestClassifier trained with colected data
that you can check on ./data directory.

The results from the tests got around 98% accuracy.

Note that this detector only recognizes offwrtist periods longer than 30 minutes

@author: Lucas Micol
"""

#from sklearn.ensemble import RandomForestClassifier
import pickle as pkl
import numpy as np

def Offwrist_filter(data):
    count = 0
    output = data.copy()

    for i in range(len(data)):
        if (data[i] == 1):
            count += 1
        else :
            if(count < 30):
                output[i-count:i] = 0
            count = 0
    return output
    

class OffWristEstimator:
    
    def __init__(self):
        with open('RandomForest_Estimator.pkl', 'rb') as f:
            self.estimator = pkl.load(f)

    def predict(self, data):
        return Offwrist_filter(self.estimator.predict(data))
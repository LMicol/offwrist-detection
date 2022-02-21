# -*- coding: utf-8 -*-
"""
@author: Lucas Micol
"""
import pandas as pd
from sklearn import preprocessing

def normalize(X):
    x = X.values
    min_max_scaler = preprocessing.MinMaxScaler()
    x_scaled = min_max_scaler.fit_transform(x)
    return pd.DataFrame(x_scaled)
    
    #X_norm = (X-X.min())/(X.max()-X.min())
    #return X_norm

def data_preparation(df, metrics):
    columns = ['TEMPERATURE', 'LIGHT', 'RED.LIGHT', 'GREEN.LIGHT',
               'BLUE.LIGHT','PIM', 'TAT', 'ZCM']
    df = df[columns]
    X = pd.concat([df, metrics],axis=1)
    X = normalize(X)
    return X


def check_integrity(dataset):
    columns_needed = ['DATE.TIME', 'TEMPERATURE', 'LIGHT', 'RED.LIGHT',
                      'GREEN.LIGHT','BLUE.LIGHT','PIM', 'TAT', 'ZCM']
    columns = list(dataset.columns)
    
    for i in columns_needed:
        if (i in columns):
            continue
        else:
            return False
    return True

#   We generate 5 new variables for the random forest classification
#   1) Hour of the day
#   2) PIM 60 min window numeber of 0s
#   3) PIM nº of previous 0s
#   4) Temperature variation in 30 min 
#   5) Temperature variation against previous
def offwrist_features(df):
    m = ['H','PIMW','PIMS','TEMP.DELTA.30','TEMP.DELTA']
    new_columns = pd.DataFrame(columns=m)
    for i in range(len(df)):    
        ### 1)
        hour = int(str(df['DATE.TIME'][i])[11:13])
        
        ### 2)
        pim_w = 0
        if (i < 30):
            pim_w = df['PIM'][:60]
            pim_w = list(pim_w).count(0)
        else:
            pim_w = df['PIM'][i-30:i+30]
            pim_w = list(pim_w).count(0)
            
        ### 3)
        pim_s = 0
        j = i
        while (j != 0):
            j -= 1
            if( df['PIM'][j] == 0):
                pim_s += 1
            else:
                break
        
        ### 4)
        t_0 = df['TEMPERATURE'][i]
        t_1 = list(df['TEMPERATURE'][i:i+30])[-1]

        delta_temp_30 = t_0 - t_1
        
        ### 5)
        if (i > 0):
            delta_temp_now = t_0 - (df['TEMPERATURE'][i-1])
        else:
            delta_temp_now = 0
            
        new_row = {'H':hour, 'PIMW':pim_w,'PIMS':pim_s,
                   'TEMP.DELTA.30':delta_temp_30,
                   'TEMP.DELTA':delta_temp_now}
        new_columns = new_columns.append(new_row, ignore_index=True, )
        
    return new_columns
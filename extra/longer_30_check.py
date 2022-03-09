# checks if there is an interval smaller than 30 minutes in the column_name
import sys
import pandas as pd

def main():
    f = pd.read_excel(sys.argv[1])
    
    column_name = "ML_OffWrist_Prediction"
    
    sequence = 0
    for i in range(len(f)):
        if (f[column_name][i] == 1):
            sequence += 1
        else:
            if(sequence < 30 and sequence != 0):
                print('sequence less than 30: ' + str(sequence) )
                print('found in: ' + str((i+1)-sequence) + ' --> ' + str(i+1) )
            sequence = 0
    

if __name__ == "__main__":
    main()
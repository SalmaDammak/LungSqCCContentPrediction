# -*- coding: utf-8 -*-
"""
Created on Mon Apr 12 17:00:33 2021

@author: sdammak
"""
import sys
import numpy as np
import tensorflow as tf
import pandas as pd
from tensorflow.keras.preprocessing.image import ImageDataGenerator
import random
import os
import matplotlib.pyplot as plt
import scipy.io as sio

def RunExperiment(sTestDataCSVPath, sResultsDir, iBatchSize, sModelPath):

    # Set random number generators and determinisim controllers to allow for repeatability
    SEED = 123
    random.seed(SEED)
    np.random.seed(SEED)
    tf.random.set_seed(SEED)
    os.environ['TF_DETERMINISTIC_OPS'] = '1'
    os.environ['PYTHONHASHSEED'] = '0'

    # Prepare image datagenerators testing
    dfTestData = pd.read_csv(sTestDataCSVPath,dtype = 'str',header=0)
    dfTestData = dfTestData.rename(columns={'c1sPaths': 'filename', 'c1xLabels': 'class'})
    dfTestData['class'] = dfTestData['class'].astype(dtype='float')
    dfTestData['filename'] = dfTestData['filename'].astype(dtype='string')

    #dfTestData = dfTestData.rename(columns={'c1sPaths': 'filename'})

    test_batches = ImageDataGenerator(rescale = 1./255) \
        .flow_from_dataframe(
            dfTestData,
            target_size=(224,224),
            class_mode = "raw",
            batch_size=iBatchSize,
            shuffle = False)

    # Plot 25 test images (the first image in every batch)
    fig2, rows2 = plt.subplots(nrows=5, ncols=5, figsize=(18,18))
    for row in rows2:
        for col in row:
            col.imshow(test_batches.next()[0][0])
    fig2.suptitle('Test images')
    fig2.savefig(sResultsDir + '\\Test images', dpi = 330)


	# Load the model (uncomment when necessary)
    model = tf.keras.models.load_model(sModelPath, custom_objects=None,compile=True)
    model.summary()

    # Get predictions on the test set
    vsConfidences = model.predict(x=test_batches, steps=len(test_batches), verbose=1)

    # Save all important 'simple' variables
    sio.savemat(sResultsDir + 'Workspace_in_python.mat',
                {'vsFilenames': test_batches.filenames,
				 'viTruth': test_batches.labels,
                 'vsiConfidences': vsConfidences})

    return

if __name__ == "__main__":
    sTestDataCSVPath =sys.argv[1]
    sResultsDir = sys.argv[2]

    # Set these arguments to the right type
    iBatchSize = int(sys.argv[3])
    sModelPath = sys.argv[4]

    RunExperiment(sTestDataCSVPath,
                  sResultsDir,
                  iBatchSize,
                  sModelPath)
# -*- coding: utf-8 -*-
"""
Created on Mon Apr 12 17:00:33 2021

@author: sdammak
"""
import sys
import numpy as np
import tensorflow as tf
import keras
import pandas as pd
from tensorflow.keras.models import Sequential
from tensorflow.keras.layers import Dense
from tensorflow.keras.optimizers import Adam
from tensorflow.keras.preprocessing.image import ImageDataGenerator
import random
import os
import sklearn.metrics as metrics
import matplotlib.pyplot as plt
import scipy.io as sio

def RunExperiment(sTrainDataCSVPath, sTestDataCSVPath, sResultsDir, iEpochs, dLearningRate, iBatchSize, sExperimentFolderName):

    # Set random number generators and determinisim controllers to allow for repeatability
    SEED = 123
    random.seed(SEED)
    np.random.seed(SEED)
    tf.random.set_seed(SEED)
    os.environ['TF_DETERMINISTIC_OPS'] = '1'
    os.environ['PYTHONHASHSEED'] = '0'

    # Prepare image datagenerators for training and testing
    dfTrainData = pd.read_csv(sTrainDataCSVPath, dtype = 'str')
    dfTrainData = dfTrainData.rename(columns={'c1sPaths': 'filename', 'c1xLabels': 'class'})
    dfTrainData['class'] = dfTrainData['class'].astype(dtype='float')
    dfTrainData['filename'] = dfTrainData['filename'].astype(dtype='string')

    dfTestData = pd.read_csv(sTestDataCSVPath,dtype = 'str')
    dfTestData = dfTestData.rename(columns={'c1sPaths': 'filename', 'c1xLabels': 'class'})
    dfTestData['class'] = dfTestData['class'].astype(dtype='float')
    dfTestData['filename'] = dfTestData['filename'].astype(dtype='string')

    # Create datagenerators with augmentations for training
    # The values and augmentations were decided based on visual inspection
    train_batches = ImageDataGenerator(
        rescale = 1./255,
        rotation_range = 360,
        horizontal_flip = True,
        vertical_flip = True,
        brightness_range = [0.5,1.5],
        channel_shift_range = 40
        ).flow_from_dataframe(
            dfTrainData,
            target_size=(224,224),
            class_mode = "raw",
            batch_size=iBatchSize,
            shuffle = True)

    test_batches = ImageDataGenerator(rescale = 1./255) \
        .flow_from_dataframe(
            dfTestData,
            target_size=(224,224),
            class_mode = "raw",
            batch_size=iBatchSize,
            shuffle = False)

    # Plot 25 train images (the first image in every batch)
    fig1, rows1 = plt.subplots(nrows=5, ncols=5, figsize=(18,18))
    for row in rows1:
        for col in row:
            col.imshow(train_batches.next()[0][0])
    fig1.suptitle('Train images: '  + sExperimentFolderName)
    fig1.savefig(sResultsDir + '\\Train images', dpi = 330)

    # Plot 25 test images (the first image in every batch)
    fig2, rows2 = plt.subplots(nrows=5, ncols=5, figsize=(18,18))
    for row in rows2:
        for col in row:
            col.imshow(test_batches.next()[0][0])
    fig2.suptitle('Test images: '  + sExperimentFolderName)
    fig2.savefig(sResultsDir + '\\Test images', dpi = 330)

    # Load the model for transfer learning
    base_model = tf.keras.applications.vgg16.VGG16()

    # Onto a fresh model, copy all layers but the last one
    model = Sequential()
    for layer in base_model.layers[:-1]:
        model.add(layer)

    # Set all layers except the last 5 to non-trainable (this plus the dense layer are the last 6 layers)
    for layer in model.layers:
        layer.trainable = False

    # Add the last layer, ie the one corresponding to my classes
    model.add(Dense(units=1, activation='linear'))

    # Print model summary
    model.summary()

    # Compile the model
    model.compile(optimizer=Adam(learning_rate = dLearningRate),
                  loss='mse',
                  metrics=['mse','mae'])

    # Add callback to allow early stopping
    # my_callback = keras.callbacks.EarlyStopping(monitor='val_loss', patience=3, mode='auto' )
    # [keras.callbacks.EarlyStopping(patience=3)]

    # Fit to the training data, using the test data for validation
    history = model.fit(x=train_batches,
              steps_per_epoch=len(train_batches),
              epochs=iEpochs,
              verbose=1,
              validation_data=test_batches,
              validation_steps=len(test_batches),
              callbacks = [keras.callbacks.EarlyStopping(monitor='loss', patience=3)]
    )

	# Save the model
    tf.keras.models.save_model(model, sResultsDir + 'Model', save_format='h5')

	# Load the model (uncomment when necessary)
	# model2 = tf.keras.models.load_model('Model',custom_objects=None,compile=True)

    # Get predictions on the test set
    vsConfidences = model.predict(x=test_batches, steps=len(test_batches), verbose=1)
    viTruth = test_batches.labels

    fig4, ax4 = plt.subplots()
    ax4.plot(history.history['loss'])
    ax4.plot(history.history['val_loss'])
    ax4.set_title('model loss: ' + sExperimentFolderName)
    ax4.set_ylabel('loss')
    ax4.set_xlabel('epoch')
    fig4.legend(['train', 'test'], loc='upper left')
    fig4.savefig(sResultsDir + 'Loss history')


    # Save all important 'simple' variables
    sio.savemat(sResultsDir + 'Workspace_in_python.mat',
                {'vsFilenames': test_batches.filenames,
                 'viTruth':viTruth,
                 'vsiConfidences': vsConfidences})

    return

def GetErrorMetrics(sResultsDir, history, vsConfidences, viTruth):
    # I need to call this block of code twice for the model when I fine-tune,
    # encapsulating it in a function makes it easy to do that with minimal
    # repeated code.

    # Calculate and print some error metrics
    #print(sResultsDir)
    #print('AUC is: %0.2f' %(round(metrics.roc_auc_score(viTruth, vsConfidences), 2)))
    #print('precision is: %d%s' %(round(100 * metrics.precision_score(viTruth, vsConfidences>0.5)),'%'))
    #print('recall is: %d%s' %(round(100 * metrics.recall_score(viTruth, vsConfidences>0.5)),'%'))

# Plot history for accuracy and save the figure
    fig3, ax3 = plt.subplots()
    ax3.plot(history.history['accuracy'])
    ax3.plot(history.history['val_accuracy'])
    ax3.set_title('Model accuracy: ' + sExperimentFolderName)
    ax3.set_ylabel('accuracy')
    ax3.set_xlabel('epoch')
    fig3.legend(['train', 'test'], loc='upper left')
    fig3.savefig(sResultsDir + 'accuracy history')

    # Plot history for loss and save the figure
    fig4, ax4 = plt.subplots()
    ax4.plot(history.history['loss'])
    ax4.plot(history.history['val_loss'])
    ax4.set_title('model loss: ' + sExperimentFolderName)
    ax4.set_ylabel('loss')
    ax4.set_xlabel('epoch')
    fig4.legend(['train', 'test'], loc='upper left')
    fig4.savefig(sResultsDir + 'Loss history')

    return

if __name__ == "__main__":
    sTrainDataCSVPath = sys.argv[1]
    sTestDataCSVPath =sys.argv[2]
    sResultsDir = sys.argv[3]

    # Set these arguments to the right type
    iEpochs = int(sys.argv[4])
    dLearningRate = float(sys.argv[5])
    iBatchSize = int(sys.argv[6])
    sExperimentFolderName = sys.argv[7]

    RunExperiment(sTrainDataCSVPath,
                  sTestDataCSVPath,
                  sResultsDir,
                  iEpochs,
                  dLearningRate,
                  iBatchSize,
                  sExperimentFolderName)
'''
sTrainDataCSVPath = 'G:\\Users\\sdammak\\Experiments\\LUSC Segment\\116 slides\\0p2520 regression\\4 Collect tile tables for python [2022-09-23_15.54.23]\\Results\\01 Train\\TilesWithScalarTargets.csv'
sTestDataCSVPath = 'G:\\Users\\sdammak\\Experiments\\LUSC Segment\\116 slides\\0p2520 regression\\4 Collect tile tables for python [2022-09-23_15.54.23]\\Results\\02 Val\\TilesWithScalarTargets.csv'
sResultsDir = os.getcwd()
epochs = 100
learning_rate = 0.001
batch_size = 10
sExperimentFolderName = 'Direct'

RunExperiment(sTrainDataCSVPath, sTestDataCSVPath, sResultsDir, epochs, learning_rate, batch_size, sExperimentFolderName)
'''
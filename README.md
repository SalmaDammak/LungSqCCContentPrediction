# LungSqCCContentPrediction


The model is currently stored [here](https://uwoca-my.sharepoint.com/:u:/g/personal/sdammak_uwo_ca/EaUAWC6ClFhDodxLFLlEhiEBTD-prS0cUuDmy9woDCGBnA?e=1ic20a).
To load the model, download and unzip the "Model" folder, set ```model_path``` to where the Model file is and run the following in python:
```
import tensorflow as tf
model = tf.keras.models.load_model(model_path, custom_objects=None,compile=True)
```
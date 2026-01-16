import joblib
import numpy as np

scaler = joblib.load("clustering_model/swing_scaler.pkl")
kmeans = joblib.load("clustering_model/swing_kmeans_model.pkl")

X_dummy = np.random.rand(1, scaler.mean_.shape[0])
X_scaled = scaler.transform(X_dummy)
cluster = kmeans.predict(X_scaled)

print("Predicted cluster:", cluster)

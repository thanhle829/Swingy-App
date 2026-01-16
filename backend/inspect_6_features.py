import joblib

scaler = joblib.load("clustering_model/swing_scaler.pkl")
kmeans = joblib.load("clustering_model/swing_kmeans_model.pkl")

print("Scaler expects:", scaler.mean_.shape[0])

# check if scaler has feature names
if hasattr(scaler, "feature_names_in_"):
    print("Scaler feature names:", list(scaler.feature_names_in_))
else:
    print("Scaler has no feature_names_in_")

# check swing_features.pkl
try:
    feats = joblib.load("clustering_model/swing_features.pkl")
    print("swing_features.pkl type:", type(feats))
    if isinstance(feats, list):
        print("swing_features.pkl length:", len(feats))
        print("swing_features.pkl content:", feats)
    else:
        print("swing_features.pkl content:", feats)
except Exception as e:
    print("Failed to load swing_features.pkl:", e)

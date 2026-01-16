import joblib

feat_list_path = "clustering_model/swing_features_list.pkl"

features = joblib.load(feat_list_path)

print("Feature list type:", type(features))
print("Number of features:", len(features))
print("Feature names:")
for i, f in enumerate(features):
    print(i, f)

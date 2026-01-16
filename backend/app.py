from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi import UploadFile, File
import os
import uuid
from pydantic import BaseModel
import joblib
import numpy as np
from feature_extractor import extract_6_features

app = FastAPI(title="Swingy API")
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

def build_feedback(features):
    # features order:
    # [STANCE_RATIO, SHOULDER_ROT_RANGE, X_FACTOR_TOP, SPINE_ANGLE, LEFT_ARM_ANGLE, HIP_SWAY_RANGE]
    stance, sh_rot, xfactor, spine, left_arm, hip_sway = features

    posture_score = 100
    key_issues = []
    improvements = []

    # Rule-based penalties (tune later)
    if spine > 25:
        posture_score -= 15
        key_issues.append("Excessive forward spine tilt during setup.")
        improvements.append("Keep your spine more neutral and hinge from the hips.")

    if hip_sway > 0.08:
        posture_score -= 15
        key_issues.append("Too much lateral hip sway.")
        improvements.append("Focus on controlled hip rotation rather than sliding.")

    if left_arm < 145:
        posture_score -= 10
        key_issues.append("Left arm is too bent during backswing.")
        improvements.append("Try keeping your left arm straighter for a wider arc.")

    if abs(xfactor) > 280:
        posture_score -= 10
        key_issues.append("X-Factor is extreme, which may reduce control.")
        improvements.append("Aim for a smoother separation between hips and shoulders.")

    if stance < 1.0:
        posture_score -= 5
        key_issues.append("Stance may be too narrow.")
        improvements.append("Widen your stance slightly for stability.")

    # Clamp 0–100
    posture_score = max(0, min(100, int(posture_score)))

    body_areas = ["Head", "Shoulders", "Spine", "Hips", "Legs"]

    if not key_issues:
        key_issues.append("Posture looks stable overall.")
        improvements.append("Maintain this posture consistency through the swing.")

    return posture_score, key_issues, improvements, body_areas


# Load models once at startup
scaler = joblib.load("clustering_model/swing_scaler.pkl")
kmeans = joblib.load("clustering_model/swing_kmeans_model.pkl")

print("Scaler expects:", scaler.mean_.shape[0])
print("Feature list length:", len(joblib.load("clustering_model/swing_features_list.pkl")))
print("Expected feature length:", scaler.mean_.shape[0])

mapping = joblib.load("clustering_model/swing_mapping.pkl")  # cluster -> label (if available)

class PredictRequest(BaseModel):
    # IMPORTANT: later this must be the real feature vector your pipeline produces
    features: list[float]

@app.get("/health")
def health():
    return {"status": "ok"}

@app.post("/predict")
def predict(req: PredictRequest):
    x = np.array(req.features, dtype=float).reshape(1, -1)

    # scale
    x_scaled = scaler.transform(x)

    # predict cluster
    cluster = int(kmeans.predict(x_scaled)[0])

    # map to label if possible
    label = mapping.get(cluster, str(cluster)) if isinstance(mapping, dict) else str(cluster)

    return {
        "cluster": cluster,
        "label": label
    }

@app.post("/predict_video")
async def predict_video(file: UploadFile = File(...)):
    os.makedirs("uploads", exist_ok=True)

    ext = os.path.splitext(file.filename)[1]
    save_name = f"{uuid.uuid4().hex}{ext}"
    save_path = os.path.join("uploads", save_name)

    with open(save_path, "wb") as f:
        content = await file.read()
        f.write(content)

    features = extract_6_features(save_path)
    print("Extracted features:", features)

    posture_score, key_issues, improvements, body_areas = build_feedback(features)

    x = np.array(features, dtype=float).reshape(1, -1)
    x_scaled = scaler.transform(x)
    cluster = int(kmeans.predict(x_scaled)[0])
    label = mapping.get(cluster, str(cluster)) if isinstance(mapping, dict) else str(cluster)

    feature_names = [
    "0-STANCE-RATIO",
    "Shoulder_Rotation_Range",
    "X_Factor_Top",
    "0-SPINE-ANGLE",
    "1-LEFT-ARM-ANGLE",
    "Hip_Sway_Range"
    ]

    return {
    "status": "uploaded",
    "filename": file.filename,
    "saved_as": save_name,
    "path": save_path,
    "cluster": cluster,
    "label": label,
    "features": features,
    "feature_names": feature_names,

    # NEW UI values from backend
    "postureScore": posture_score,
    "keyIssues": key_issues,
    "improvements": improvements,
    "bodyAreas": body_areas
}



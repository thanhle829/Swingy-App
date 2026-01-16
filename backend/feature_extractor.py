import cv2
import mediapipe as mp
import numpy as np
import math

# Compatibility: some mediapipe releases expose a `solutions` API, others use the newer `tasks` API.
# Guard for environments (like this dev machine) where `mp.solutions` isn't available and fall back to
# a deterministic mock feature vector so the backend can be tested in Chrome. Replace with a proper
# mediapipe tasks implementation or use an older mediapipe wheel in production.
try:
    have_mp_solutions = hasattr(mp, 'solutions')
    if have_mp_solutions:
        mp_pose = mp.solutions.pose
    else:
        mp_pose = None
except Exception as e:
    print('Warning importing mediapipe.solutions:', e)
    mp_pose = None
    have_mp_solutions = False

def angle(a, b, c):
    """Angle ABC in degrees"""
    a = np.array(a); b = np.array(b); c = np.array(c)
    ba = a - b
    bc = c - b
    cosine = np.dot(ba, bc) / (np.linalg.norm(ba) * np.linalg.norm(bc) + 1e-6)
    return np.degrees(np.arccos(np.clip(cosine, -1.0, 1.0)))

def extract_6_features(video_path, max_frames=200):
    """
    Extract the 6 features required by the clustering model.
    Returns list of 6 floats in correct order:
    ['0-STANCE-RATIO', 'Shoulder_Rotation_Range', 'X_Factor_Top', '0-SPINE-ANGLE', '1-LEFT-ARM-ANGLE', 'Hip_Sway_Range']
    """

    # If mediapipe.solutions is not available (dev environment), return a deterministic mock
    # feature vector so we can test the API without a full mediapipe installation.
    if mp_pose is None:
        print('mediapipe.solutions not available -- returning MOCK features for', video_path)
        return [1.0, 0.15, 200.0, 10.0, 160.0, 0.02]

    cap = cv2.VideoCapture(video_path)
    pose = mp_pose.Pose(static_image_mode=False, model_complexity=1)

    stance_ratios = []
    spine_angles = []
    left_arm_angles = []
    shoulder_rotations = []
    x_factors = []
    hip_sways = []

    frame_count = 0

    while cap.isOpened() and frame_count < max_frames:
        ret, frame = cap.read()
        if not ret:
            break

        frame_count += 1
        rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        result = pose.process(rgb)

        if not result.pose_landmarks:
            continue

        lm = result.pose_landmarks.landmark

        # Key landmark helper
        def pt(idx):
            return [lm[idx].x, lm[idx].y]

        # Mediapipe indices
        L_SH = 11
        R_SH = 12
        L_HIP = 23
        R_HIP = 24
        L_ELB = 13
        L_WRIST = 15
        L_ANK = 27
        R_ANK = 28

        left_sh = pt(L_SH); right_sh = pt(R_SH)
        left_hip = pt(L_HIP); right_hip = pt(R_HIP)
        left_elb = pt(L_ELB); left_wrist = pt(L_WRIST)
        left_ank = pt(L_ANK); right_ank = pt(R_ANK)

        # 1) 0-STANCE-RATIO (distance between ankles / distance between hips)
        ankle_dist = np.linalg.norm(np.array(left_ank) - np.array(right_ank))
        hip_dist = np.linalg.norm(np.array(left_hip) - np.array(right_hip)) + 1e-6
        stance_ratio = ankle_dist / hip_dist
        stance_ratios.append(stance_ratio)

        # 2) 0-SPINE-ANGLE (angle between shoulder midpoint -> hip midpoint and vertical)
        sh_mid = (np.array(left_sh) + np.array(right_sh)) / 2
        hip_mid = (np.array(left_hip) + np.array(right_hip)) / 2
        spine_vec = sh_mid - hip_mid
        vertical = np.array([0, -1])
        spine_angle = np.degrees(np.arccos(
            np.dot(spine_vec, vertical) / (np.linalg.norm(spine_vec) * np.linalg.norm(vertical) + 1e-6)
        ))
        spine_angles.append(spine_angle)

        # 3) 1-LEFT-ARM-ANGLE (shoulder-elbow-wrist)
        left_arm_angle = angle(left_sh, left_elb, left_wrist)
        left_arm_angles.append(left_arm_angle)

        # Shoulder rotation proxy (difference in x between shoulders)
        shoulder_rot = (right_sh[0] - left_sh[0])
        shoulder_rotations.append(shoulder_rot)

        # Hip sway proxy (difference in x between hip midpoint and ankle midpoint)
        ankle_mid = (np.array(left_ank) + np.array(right_ank)) / 2
        hip_sway = hip_mid[0] - ankle_mid[0]
        hip_sways.append(hip_sway)

        # X-Factor proxy (shoulder line angle - hip line angle)
        shoulder_line_angle = math.degrees(math.atan2(right_sh[1]-left_sh[1], right_sh[0]-left_sh[0]))
        hip_line_angle = math.degrees(math.atan2(right_hip[1]-left_hip[1], right_hip[0]-left_hip[0]))
        x_factor = shoulder_line_angle - hip_line_angle
        x_factors.append(x_factor)

    cap.release()
    pose.close()

    # Aggregate
    stance_ratio_0 = float(np.mean(stance_ratios)) if stance_ratios else 0.0
    spine_angle_0 = float(np.mean(spine_angles)) if spine_angles else 0.0
    left_arm_angle_1 = float(np.mean(left_arm_angles)) if left_arm_angles else 0.0

    shoulder_rotation_range = float(np.max(shoulder_rotations) - np.min(shoulder_rotations)) if shoulder_rotations else 0.0
    x_factor_top = float(np.max(np.abs(x_factors))) if x_factors else 0.0
    hip_sway_range = float(np.max(hip_sways) - np.min(hip_sways)) if hip_sways else 0.0

    return [
        stance_ratio_0,
        shoulder_rotation_range,
        x_factor_top,
        spine_angle_0,
        left_arm_angle_1,
        hip_sway_range
    ]

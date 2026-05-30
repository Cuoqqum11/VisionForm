#!/bin/bash

# MediaPipe 모델 다운로드 스크립트
# 사용법: ./download_models.sh

ASSETS_DIR="android/src/main/assets/models"

# assets 폴더 생성
mkdir -p "$ASSETS_DIR"

echo "Downloading MediaPipe models..."

# Face Landmarker 모델
echo "1. Downloading face_landmarker.task..."
curl -L -o "$ASSETS_DIR/face_landmarker.task" \
  "https://storage.googleapis.com/mediapipe-models/face_landmarker/face_landmarker/float16/1/face_landmarker.task"

# Pose Landmarker 모델 (lite 버전 - 더 가벼움)
echo "2. Downloading pose_landmarker_lite.task..."
curl -L -o "$ASSETS_DIR/pose_landmarker_lite.task" \
  "https://storage.googleapis.com/mediapipe-models/pose_landmarker/pose_landmarker_lite/float16/1/pose_landmarker_lite.task"

echo ""
echo "Download complete!"
echo ""
echo "Files downloaded to: $ASSETS_DIR"
ls -la "$ASSETS_DIR"

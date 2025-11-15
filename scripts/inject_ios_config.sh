#!/bin/bash

# iOS 빌드 시 Info.plist에 환경 변수 주입하는 스크립트
# Xcode 빌드 스크립트에서 자동으로 호출됨

set -e

# 프로젝트 루트 디렉토리
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
INFO_PLIST="$PROJECT_ROOT/ios/Runner/Info.plist"

if [ ! -f "$INFO_PLIST" ]; then
  exit 0  # Info.plist가 없으면 스킵
fi

# 카카오 API 키 주입 (.env에서 읽기)
ENV_FILE="$PROJECT_ROOT/assets/env/.env"
if [ -f "$ENV_FILE" ]; then
  KAKAO_KEY=$(grep -E "^KAKAO_NATIVE_APP_KEY=" "$ENV_FILE" | cut -d '=' -f2 | tr -d '"' | tr -d "'" | xargs)
  if [ -n "$KAKAO_KEY" ]; then
    if [[ "$OSTYPE" == "darwin"* ]]; then
      sed -i '' "s|<string>\$(KAKAO_API_KEY)</string>|<string>$KAKAO_KEY</string>|g" "$INFO_PLIST" 2>/dev/null || true
    else
      sed -i "s|<string>\$(KAKAO_API_KEY)</string>|<string>$KAKAO_KEY</string>|g" "$INFO_PLIST" 2>/dev/null || true
    fi
  fi
fi

# Google reversed client ID 주입 (GoogleService-Info.plist에서 읽기)
GOOGLE_PLIST="$PROJECT_ROOT/ios/Runner/GoogleService-Info.plist"
if [ -f "$GOOGLE_PLIST" ]; then
  if [[ "$OSTYPE" == "darwin"* ]]; then
    REVERSED_CLIENT_ID=$(/usr/libexec/PlistBuddy -c "Print :REVERSED_CLIENT_ID" "$GOOGLE_PLIST" 2>/dev/null || echo "")
    if [ -n "$REVERSED_CLIENT_ID" ]; then
      sed -i '' "s|<string>\$(GOOGLE_REVERSED_CLIENT_ID)</string>|<string>$REVERSED_CLIENT_ID</string>|g" "$INFO_PLIST" 2>/dev/null || true
    fi
  else
    REVERSED_CLIENT_ID=$(grep -A 1 "<key>REVERSED_CLIENT_ID</key>" "$GOOGLE_PLIST" | grep "<string>" | sed 's/.*<string>\(.*\)<\/string>.*/\1/' | head -1)
    if [ -n "$REVERSED_CLIENT_ID" ]; then
      sed -i "s|<string>\$(GOOGLE_REVERSED_CLIENT_ID)</string>|<string>$REVERSED_CLIENT_ID</string>|g" "$INFO_PLIST" 2>/dev/null || true
    fi
  fi
fi


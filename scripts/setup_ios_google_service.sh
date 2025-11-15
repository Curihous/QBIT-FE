#!/bin/bash

# iOS GoogleService-Info.plist를 설정하는 스크립트
# 사용법:
#   ./scripts/setup_ios_google_service.sh
#   또는 환경 변수로: GOOGLE_SERVICE_INFO_PATH=/path/to/plist ./scripts/setup_ios_google_service.sh

set -e

# 프로젝트 루트 디렉토리로 이동
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

# 대상 파일 경로
TARGET_PLIST="$PROJECT_ROOT/ios/Runner/GoogleService-Info.plist"
EXAMPLE_PLIST="$PROJECT_ROOT/ios/Runner/GoogleService-Info.plist.example"

# GoogleService-Info.plist 소스 찾기
if [ -n "$GOOGLE_SERVICE_INFO_PATH" ]; then
  # 환경 변수로 경로 지정
  SOURCE_PLIST="$GOOGLE_SERVICE_INFO_PATH"
elif [ -f "$PROJECT_ROOT/assets/env/GoogleService-Info.plist" ]; then
  # assets/env/ 디렉토리에서 찾기
  SOURCE_PLIST="$PROJECT_ROOT/assets/env/GoogleService-Info.plist"
elif [ -f "$PROJECT_ROOT/GoogleService-Info.plist" ]; then
  # 프로젝트 루트에서 찾기
  SOURCE_PLIST="$PROJECT_ROOT/GoogleService-Info.plist"
else
  echo "❌ 오류: GoogleService-Info.plist를 찾을 수 없습니다."
  echo ""
  echo "다음 중 하나를 수행하세요:"
  echo "  1. 환경 변수로 경로 지정:"
  echo "     GOOGLE_SERVICE_INFO_PATH=/path/to/GoogleService-Info.plist ./scripts/setup_ios_google_service.sh"
  echo ""
  echo "  2. 다음 위치 중 하나에 파일 배치:"
  echo "     - assets/env/GoogleService-Info.plist"
  echo "     - 프로젝트 루트/GoogleService-Info.plist"
  echo ""
  echo "  3. Firebase Console에서 GoogleService-Info.plist를 다운로드하여 위 위치에 배치하세요."
  echo ""
  echo "참고: GoogleService-Info.plist.example 파일을 참고하여 필요한 필드를 확인하세요."
  exit 1
fi

# 소스 파일이 존재하는지 확인
if [ ! -f "$SOURCE_PLIST" ]; then
  echo "❌ 오류: 소스 파일을 찾을 수 없습니다: $SOURCE_PLIST"
  exit 1
fi

# 대상 디렉토리가 존재하는지 확인
TARGET_DIR="$(dirname "$TARGET_PLIST")"
if [ ! -d "$TARGET_DIR" ]; then
  echo "❌ 오류: 대상 디렉토리가 존재하지 않습니다: $TARGET_DIR"
  exit 1
fi

# 파일 복사
cp "$SOURCE_PLIST" "$TARGET_PLIST"

# GoogleService-Info.plist에서 REVERSED_CLIENT_ID 읽기
INFO_PLIST="$PROJECT_ROOT/ios/Runner/Info.plist"

if [[ "$OSTYPE" == "darwin"* ]]; then
  # macOS: PlistBuddy 사용
  REVERSED_CLIENT_ID=$(/usr/libexec/PlistBuddy -c "Print :REVERSED_CLIENT_ID" "$TARGET_PLIST" 2>/dev/null || echo "")
  
  if [ -n "$REVERSED_CLIENT_ID" ] && [ -f "$INFO_PLIST" ]; then
    # Info.plist에서 $(GOOGLE_REVERSED_CLIENT_ID) 플레이스홀더를 실제 값으로 교체
    sed -i '' "s|<string>\$(GOOGLE_REVERSED_CLIENT_ID)</string>|<string>$REVERSED_CLIENT_ID</string>|g" "$INFO_PLIST"
    echo "✅ Info.plist의 Google reversed client ID가 업데이트되었습니다."
  fi
else
  # Linux: grep/sed 사용
  REVERSED_CLIENT_ID=$(grep -A 1 "<key>REVERSED_CLIENT_ID</key>" "$TARGET_PLIST" | grep "<string>" | sed 's/.*<string>\(.*\)<\/string>.*/\1/' | head -1)
  
  if [ -n "$REVERSED_CLIENT_ID" ] && [ -f "$INFO_PLIST" ]; then
    sed -i "s|<string>\$(GOOGLE_REVERSED_CLIENT_ID)</string>|<string>$REVERSED_CLIENT_ID</string>|g" "$INFO_PLIST"
    echo "✅ Info.plist의 Google reversed client ID가 업데이트되었습니다."
  fi
fi

echo "✅ GoogleService-Info.plist가 설정되었습니다."
echo "   소스: $SOURCE_PLIST"
echo "   대상: $TARGET_PLIST"
echo ""
echo "⚠️  주의: GoogleService-Info.plist는 .gitignore에 포함되어 있습니다."
echo "   이 파일은 저장소에 커밋되지 않습니다."


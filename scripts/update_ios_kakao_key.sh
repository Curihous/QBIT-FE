#!/bin/bash

# iOS Info.plist에 카카오 API 키를 주입하는 스크립트
# 사용법:
#   ./scripts/update_ios_kakao_key.sh
#   또는 환경 변수로: KAKAO_API_KEY=your_key ./scripts/update_ios_kakao_key.sh

set -e

# 프로젝트 루트 디렉토리로 이동
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

# Info.plist 경로
INFO_PLIST="$PROJECT_ROOT/ios/Runner/Info.plist"

# 카카오 API 키 가져오기
if [ -z "$KAKAO_API_KEY" ]; then
  # 환경 변수가 없으면 .env 파일에서 읽기
  ENV_FILE="$PROJECT_ROOT/assets/env/.env"
  
  if [ -f "$ENV_FILE" ]; then
    # .env 파일에서 KAKAO_NATIVE_APP_KEY 읽기
    KAKAO_API_KEY=$(grep -E "^KAKAO_NATIVE_APP_KEY=" "$ENV_FILE" | cut -d '=' -f2 | tr -d '"' | tr -d "'" | xargs)
  fi
fi

# 키가 여전히 없으면 에러
if [ -z "$KAKAO_API_KEY" ]; then
  echo "❌ 오류: KAKAO_API_KEY를 찾을 수 없습니다."
  echo "다음 중 하나를 수행하세요:"
  echo "  1. 환경 변수 설정: export KAKAO_API_KEY=your_key"
  echo "  2. assets/env/.env 파일에 KAKAO_NATIVE_APP_KEY=your_key 추가"
  exit 1
fi

# Info.plist가 존재하는지 확인
if [ ! -f "$INFO_PLIST" ]; then
  echo "❌ 오류: Info.plist를 찾을 수 없습니다: $INFO_PLIST"
  exit 1
fi

# Info.plist 백업
cp "$INFO_PLIST" "$INFO_PLIST.backup"

# Info.plist에서 카카오 키 업데이트
# $(KAKAO_API_KEY) 플레이스홀더를 실제 키로 교체
if [[ "$OSTYPE" == "darwin"* ]]; then
  # macOS: plutil 사용
  /usr/libexec/PlistBuddy -c "Set :CFBundleURLTypes:0:CFBundleURLSchemes:0 $KAKAO_API_KEY" "$INFO_PLIST" 2>/dev/null || {
    # plutil이 실패하면 sed 사용
    sed -i '' "s|<string>\$(KAKAO_API_KEY)</string>|<string>$KAKAO_API_KEY</string>|g" "$INFO_PLIST"
  }
else
  # Linux: sed 사용
  sed -i "s|<string>\$(KAKAO_API_KEY)</string>|<string>$KAKAO_API_KEY</string>|g" "$INFO_PLIST"
fi

echo "✅ Info.plist에 카카오 API 키가 업데이트되었습니다."
echo "   키: ${KAKAO_API_KEY:0:10}... (처음 10자만 표시)"


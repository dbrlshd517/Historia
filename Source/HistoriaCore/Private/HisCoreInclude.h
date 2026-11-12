// 거시 core 입구 헤더 (historia-headless playheadless/core.hpp) — 언리얼 매크로·경고와 섞이지 않게 감싸서 부른다.
// core 소스는 복사하지 않는다: include 경로가 headless 폴더를 가리킴 (Historia.Build.cs · Config/HisCore.json).
#pragma once

#include "CoreMinimal.h"

THIRD_PARTY_INCLUDES_START
#pragma push_macro("check")
#pragma push_macro("verify")
#pragma push_macro("ensure")
#undef check
#undef verify
#undef ensure
#include "playheadless/core.hpp"
#pragma pop_macro("ensure")
#pragma pop_macro("verify")
#pragma pop_macro("check")
THIRD_PARTY_INCLUDES_END

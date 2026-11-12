// 거시 서브시스템 (TASK_거시연결 U1) — 게임 하나에 거시 core 하나. 경로는 Config/HisCore.json.
// U1 은 화면·스레드 없음: 불러오기 → 날 진행 → 해시. U2 에서 core 를 제 스레드(Runner)로 옮기고 게임 스레드는 스냅샷만 본다.
#pragma once

#include "CoreMinimal.h"
#include "Subsystems/GameInstanceSubsystem.h"

#include "Macro/HisCoreConfig.h"
#include "HisMacroCore.h"

#include "HisMacroSubsystem.generated.h"

UCLASS()
class HISTORIA_API UHisMacroSubsystem : public UGameInstanceSubsystem
{
	GENERATED_BODY()

public:
	// 지도 시드의 start_state · fields + gamedata 로 새 판. RngSeed < 0 이면 지도 시드
	bool StartNew(int64 MapSeed, int64 RngSeed, FString& Error);
	FHisMacroCore& Core() { return MacroCore; }
	const FHisCoreConfig& Config() const { return Cfg; }

	// Days 일 진행 (틱을 어떻게 끊든 결과는 같음 — core 몫)
	static void Advance(FHisMacroCore& C, int64 Days);

private:
	FHisCoreConfig Cfg;
	FHisMacroCore MacroCore;
};

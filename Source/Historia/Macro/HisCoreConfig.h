// Config/HisCore.json — 거시 core 자리 (headless 짝 폴더) · 지도·데이터 경로 · 확인 시드 (TASK_거시연결 U1). 경로를 코드에 박지 않는다.
#pragma once

#include "CoreMinimal.h"

struct FHisCoreConfig
{
	FString HeadlessDir;     // historia-headless 저장소 뿌리 (절대)
	FString MapDirPattern;   // {seed} 자리 — headless 기준
	FString GamedataRel;
	FString HistoriaRunRel;  // 프로젝트 기준
	int64 CheckSeed = 0;
	double CheckYears = 0.0;
	FString CheckHash;       // 기준 해시 (headless_commit 에서 historia_run) — 비면 안 견줌
	FString HeadlessCommit;  // 고정 커밋

	// 실패하면 false + Error
	bool Load(FString& Error);

	FString MapDir(int64 Seed) const;
	FString StartState(int64 Seed) const { return MapDir(Seed) / TEXT("start_state.npz"); }
	FString Fields(int64 Seed) const { return MapDir(Seed) / TEXT("fields.npz"); }
	FString Gamedata() const;
	FString HistoriaRun() const;
};

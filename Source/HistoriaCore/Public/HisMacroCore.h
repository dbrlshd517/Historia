// 거시 core 하나 (historia::Sim) — 언리얼 타입으로 감싼 얇은 손잡이. 규칙은 전부 core 안 (CLAUDE.md 규칙 1).
// U1: 불러오기 · 날 진행 · 해시. 스레드는 아직 없음 (U2 에서 core Runner 로) — 이 객체를 만지는 스레드는 하나여야 한다.
#pragma once

#include "CoreMinimal.h"

namespace historia { class Sim; }

class HISTORIACORE_API FHisMacroCore
{
public:
	FHisMacroCore();
	~FHisMacroCore();
	FHisMacroCore(const FHisMacroCore&) = delete;
	FHisMacroCore& operator=(const FHisMacroCore&) = delete;

	// start_state.npz · gamedata_core.json · fields.npz. RngSeed ≥ 0 이면 이 판의 난수 (historia_run 의 rng_seed 와 같은 뜻)
	bool Load(const FString& StartState, const FString& Gamedata, const FString& Fields, int64 RngSeed, FString& Error);
	void Tick(int32 Days);
	int64 Day() const;
	FString Hash() const;
	bool IsLoaded() const;

private:
	TUniquePtr<historia::Sim> Sim;
};

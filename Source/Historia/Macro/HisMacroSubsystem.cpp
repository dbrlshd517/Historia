#include "Macro/HisMacroSubsystem.h"

bool UHisMacroSubsystem::StartNew(int64 MapSeed, int64 RngSeed, FString& Error)
{
	if (!Cfg.Load(Error)) return false;
	return MacroCore.Load(Cfg.StartState(MapSeed), Cfg.Gamedata(), Cfg.Fields(MapSeed), RngSeed >= 0 ? RngSeed : MapSeed, Error);
}

void UHisMacroSubsystem::Advance(FHisMacroCore& C, int64 Days)
{
	const int64 End = C.Day() + Days;
	while (C.Day() < End)
	{
		const int64 Step = FMath::Min<int64>(End - C.Day(), MAX_int32);
		C.Tick(static_cast<int32>(Step));
	}
}

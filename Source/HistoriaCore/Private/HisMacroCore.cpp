#include "HisMacroCore.h"

#include "HisCoreInclude.h"

namespace
{
std::string Utf8(const FString& S) { return std::string(TCHAR_TO_UTF8(*S)); }
}  // namespace

FHisMacroCore::FHisMacroCore() = default;
FHisMacroCore::~FHisMacroCore() = default;

bool FHisMacroCore::Load(const FString& StartState, const FString& Gamedata, const FString& Fields, int64 RngSeed, FString& Error)
{
	Sim = MakeUnique<historia::Sim>();
	historia::SimOptions Opt;   // 기록 없음 · AI 켬 — historia_run 과 같은 판 (기록은 해시에 안 들어감)
	const historia::Status S = Sim->load(Utf8(StartState), Utf8(Gamedata), Utf8(Fields), Opt);
	if (!S.ok)
	{
		Error = UTF8_TO_TCHAR(S.message.c_str());
		Sim.Reset();
		return false;
	}
	if (!Sim->ctx().fields_ok())
	{
		Error = FString::Printf(TEXT("fields.npz 없음: %s"), *Fields);
		Sim.Reset();
		return false;
	}
	if (RngSeed >= 0) Sim->world().seed = RngSeed;
	Sim->game().ensure_loaded();
	return true;
}

void FHisMacroCore::Tick(int32 Days)
{
	if (Sim) Sim->tick(Days);
}

int64 FHisMacroCore::Day() const { return Sim ? Sim->day() : 0; }

FString FHisMacroCore::Hash() const { return Sim ? FString(UTF8_TO_TCHAR(Sim->content_hash().c_str())) : FString(); }

bool FHisMacroCore::IsLoaded() const { return Sim.IsValid(); }

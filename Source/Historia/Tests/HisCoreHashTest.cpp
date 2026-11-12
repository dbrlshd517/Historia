// His.CoreHash (TASK_거시연결 U1) — 언리얼 안에서 돈 core 의 해시 = historia_run 해시 (같은 컴퓨터·같은 gamedata·같은 core 빌드).
// 시드·햇수·historia_run 자리는 Config/HisCore.json. 창 없이: UnrealEditor-Cmd Historia.uproject -nullrhi -ExecCmds="Automation RunTests His.CoreHash;Quit"
#include "Misc/AutomationTest.h"

#include "HAL/FileManager.h"
#include "HAL/PlatformProcess.h"
#include "HAL/PlatformTime.h"
#include "Macro/HisCoreConfig.h"
#include "HisMacroCore.h"
#include "Macro/HisMacroSubsystem.h"
#include "Misc/FileHelper.h"
#include "Misc/Paths.h"

#if WITH_DEV_AUTOMATION_TESTS

namespace
{
// historia_run 을 돌려 runs.csv 의 hash 칸을 읽음
bool RunHistoriaRun(const FHisCoreConfig& Cfg, int64 Days, FString& Hash, double& Seconds, FString& Error)
{
	const FString Exe = Cfg.HistoriaRun();
	if (!FPaths::FileExists(Exe))
	{
		Error = FString::Printf(TEXT("historia_run 없음 (Tools/his_core_lib.bat): %s"), *Exe);
		return false;
	}
	const FString Out = FPaths::ConvertRelativePathToFull(FPaths::ProjectIntermediateDir() / TEXT("HisCore/check_run"));
	IFileManager::Get().DeleteDirectory(*Out, false, true);
	const FString Args = FString::Printf(TEXT("--root \"%s\" --seed %lld --days %lld --no-save --out \"%s\""), *Cfg.HeadlessDir, Cfg.CheckSeed, Days, *Out);
	int32 Code = -1;
	FString StdOut, StdErr;
	const double T0 = FPlatformTime::Seconds();
	FPlatformProcess::ExecProcess(*Exe, *Args, &Code, &StdOut, &StdErr);
	Seconds = FPlatformTime::Seconds() - T0;
	TArray<FString> Lines;
	if (Code != 0 || !FFileHelper::LoadFileToStringArray(Lines, *(Out / TEXT("runs.csv"))) || Lines.Num() < 2)
	{
		Error = FString::Printf(TEXT("historia_run 실패 (code %d): %s"), Code, *StdErr.Left(400));
		return false;
	}
	TArray<FString> Head, Row;
	Lines[0].ParseIntoArray(Head, TEXT(","), false);
	Lines[1].ParseIntoArray(Row, TEXT(","), false);
	const int32 Col = Head.IndexOfByKey(TEXT("hash"));
	if (Col == INDEX_NONE || Col >= Row.Num())
	{
		Error = TEXT("runs.csv 에 hash 칸 없음");
		return false;
	}
	Hash = Row[Col];
	return true;
}
}  // namespace

IMPLEMENT_SIMPLE_AUTOMATION_TEST(FHisCoreHashTest, "His.CoreHash", EAutomationTestFlags_ApplicationContextMask | EAutomationTestFlags::EngineFilter)

bool FHisCoreHashTest::RunTest(const FString& Parameters)
{
	FHisCoreConfig Cfg;
	FString Error;
	if (!Cfg.Load(Error))
	{
		AddError(Error);
		return false;
	}
	const int64 Days = static_cast<int64>(Cfg.CheckYears * 365.0 + 0.5);   // historia_run --years 와 같은 반올림

	FHisMacroCore Core;
	double T0 = FPlatformTime::Seconds();
	if (!Core.Load(Cfg.StartState(Cfg.CheckSeed), Cfg.Gamedata(), Cfg.Fields(Cfg.CheckSeed), Cfg.CheckSeed, Error))
	{
		AddError(FString::Printf(TEXT("불러오기 실패: %s"), *Error));
		return false;
	}
	const double LoadS = FPlatformTime::Seconds() - T0;
	const int64 Day0 = Core.Day();
	T0 = FPlatformTime::Seconds();
	UHisMacroSubsystem::Advance(Core, Days);
	const double TickS = FPlatformTime::Seconds() - T0;
	const FString Mine = Core.Hash();

	FString Theirs;
	double RunS = 0.0;
	if (!RunHistoriaRun(Cfg, Days, Theirs, RunS, Error))
	{
		AddError(Error);
		return false;
	}
	AddInfo(FString::Printf(TEXT("시드 %lld · %lld 일 · 언리얼 안: 불러오기 %.1f s · 틱 %.1f s (%.3f ms/일) · 해시 %s"), Cfg.CheckSeed, Days, LoadS, TickS,
		1000.0 * TickS / FMath::Max<int64>(Days, 1), *Mine));
	AddInfo(FString::Printf(TEXT("historia_run: %.1f s (불러오기 포함) · 해시 %s"), RunS, *Theirs));
	TestEqual(TEXT("core 날"), Core.Day() - Day0, Days);
	TestEqual(TEXT("해시 = historia_run"), Mine, Theirs);
	return true;
}

#endif

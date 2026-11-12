#include "Macro/HisCoreConfig.h"

#include "Dom/JsonObject.h"
#include "HAL/PlatformMisc.h"
#include "Misc/FileHelper.h"
#include "Misc/Paths.h"
#include "Serialization/JsonReader.h"
#include "Serialization/JsonSerializer.h"

namespace
{
FString Abs(const FString& Base, const FString& P)
{
	FString R = FPaths::IsRelative(P) ? FPaths::Combine(Base, P) : P;
	FPaths::NormalizeFilename(R);
	FPaths::CollapseRelativeDirectories(R);
	return FPaths::ConvertRelativePathToFull(R);
}
}  // namespace

bool FHisCoreConfig::Load(FString& Error)
{
	const FString Proj = FPaths::ConvertRelativePathToFull(FPaths::ProjectDir());
	const FString File = Proj / TEXT("Config/HisCore.json");
	FString Text;
	if (!FFileHelper::LoadFileToString(Text, *File))
	{
		Error = FString::Printf(TEXT("못 읽음: %s"), *File);
		return false;
	}
	TSharedPtr<FJsonObject> J;
	if (!FJsonSerializer::Deserialize(TJsonReaderFactory<>::Create(Text), J) || !J.IsValid())
	{
		Error = FString::Printf(TEXT("JSON 틀림: %s"), *File);
		return false;
	}
	FString Dir = J->GetStringField(TEXT("headless_dir"));
	const FString Env = FPlatformMisc::GetEnvironmentVariable(TEXT("HISTORIA_HEADLESS"));
	if (!Env.IsEmpty()) Dir = Env;
	// {sub} = 프로젝트 폴더 이름의 'Historia' 뒤 꼬리 (짝 폴더)
	FString Name = FPaths::GetCleanFilename(Proj.LeftChop(Proj.EndsWith(TEXT("/")) ? 1 : 0));
	const FString Sub = Name.StartsWith(TEXT("Historia")) ? Name.Mid(8) : FString();
	Dir.ReplaceInline(TEXT("{sub}"), *Sub);
	HeadlessDir = Abs(Proj, Dir);
	MapDirPattern = J->GetStringField(TEXT("map_dir"));
	GamedataRel = J->GetStringField(TEXT("gamedata"));
	HistoriaRunRel = J->GetStringField(TEXT("historia_run"));
	CheckSeed = static_cast<int64>(J->GetNumberField(TEXT("check_seed")));
	CheckYears = J->GetNumberField(TEXT("check_years"));
	J->TryGetStringField(TEXT("check_hash"), CheckHash);
	J->TryGetStringField(TEXT("headless_commit"), HeadlessCommit);
	if (!FPaths::FileExists(HeadlessDir / TEXT("playheadless/core.hpp")))
	{
		Error = FString::Printf(TEXT("headless_dir 가 historia-headless 가 아님: %s"), *HeadlessDir);
		return false;
	}
	return true;
}

FString FHisCoreConfig::MapDir(int64 Seed) const
{
	return Abs(HeadlessDir, MapDirPattern.Replace(TEXT("{seed}"), *LexToString(Seed)));
}

FString FHisCoreConfig::Gamedata() const { return Abs(HeadlessDir, GamedataRel); }

FString FHisCoreConfig::HistoriaRun() const
{
	return Abs(FPaths::ConvertRelativePathToFull(FPaths::ProjectDir()), HistoriaRunRel);
}

using UnrealBuildTool;

public class Historia : ModuleRules
{
	public Historia(ReadOnlyTargetRules Target) : base(Target)
	{
		PCHUsage = PCHUsageMode.UseExplicitOrSharedPCHs;
		CppStandard = CppStandardVersion.Cpp20;   // 거시 core 가 C++20

		// 하위 폴더를 "Macro/HisMacroSubsystem.h" 처럼 모듈 뿌리에서 include
		PublicIncludePaths.Add(ModuleDirectory);

		PublicDependencyModuleNames.AddRange(new string[] { "Core", "CoreUObject", "Engine", "InputCore", "EnhancedInput", "HistoriaCore" });
		// 화면은 C++ Slate (위젯 블루프린트 없음) · 설정은 DeveloperSettings
		PrivateDependencyModuleNames.AddRange(new string[] { "Slate", "SlateCore", "DeveloperSettings", "ProceduralMeshComponent", "Json" });

		// 거시 core 는 모듈 HistoriaCore (FHisMacroCore 손잡이) 로만 부른다 — 링크 길은 Config/HisCore.json (TASK_거시연결 U0)
	}
}

using System;
using System.IO;
using System.Text.RegularExpressions;
using UnrealBuildTool;

// 거시 core 모듈 (TASK_거시연결 U0) — headless core(historia::Sim)를 감싼 손잡이 FHisMacroCore 만 내보낸다(HISTORIACORE_API).
// headless 코드엔 DLL 내보내기 표시가 없어서, 게임 모듈은 core 를 직접 부르지 않고 이 손잡이로만 부른다.
// 링크 길(Config/HisCore.json link_mode): prebuilt = ⓐ 미리 빌드한 정적 라이브러리 · source = ⓑ headless 소스를 이 모듈이 직접 컴파일
//   (Private/Gen/*.cpp = headless .cpp 를 #include 하는 한 줄짜리 — Tools/his_core_gen.bat 가 headless CMakeLists 목록에서 만든다, git 밖. 소스 복사 아님)
public class HistoriaCore : ModuleRules
{
	public HistoriaCore(ReadOnlyTargetRules Target) : base(Target)
	{
		CppStandard = CppStandardVersion.Cpp20;
		PublicDependencyModuleNames.AddRange(new string[] { "Core" });

		HisCore C = HisCore.Read(Path.GetFullPath(Path.Combine(ModuleDirectory, "..", "..")));
		PrivateIncludePaths.Add(C.HeadlessDir);   // #include "playheadless/core.hpp"
		string GenDir = Path.Combine(ModuleDirectory, "Private", "Gen");

		if (C.LinkMode == "prebuilt")
		{
			string LibDir = Path.Combine(C.ProjectDir, "ThirdParty", "historia_core", "lib", "Win64");
			foreach (string Lib in new string[] { "historia_core", "historia_bakelib", "historia_tools", "historia_setting", "yyjson", "miniz" })
			{
				PublicAdditionalLibraries.Add(Path.Combine(LibDir, Lib + ".lib"));
			}
			PCHUsage = PCHUsageMode.UseExplicitOrSharedPCHs;
		}
		else
		{
			// ⓑ Gen(headless CMakeLists 목록 + miniz·yyjson)은 Tools/his_core_gen.bat 가 만든다 — uproject PreBuildSteps 가 UBT 소스 훑기 전에 부름.
			// 여기서 만들면 UBT 가 이미 폴더를 읽은 뒤라 첫 빌드에 안 들어감. 여기서는 있는지만 본다.
			// 단 UBT 는 이 규칙을 PreBuildSteps 보다 먼저 돌린다(BuildMode.cs: 규칙 → 미리 빌드 단계 → 소스 훑기) — 처음 빌드엔 Gen 이 아직 없는 게 맞다.
			// 그래서 오류 = Gen 이 비었는데 uproject 에 만들 단계도 없을 때. 만들다 실패하면 미리 빌드 단계가 끝 코드 1 + 이유로 빌드를 멈춘다.
			string Deps = Path.GetFullPath(Path.Combine(C.ProjectDir, C.DepsDir));
			bool GenEmpty = !Directory.Exists(GenDir) || Directory.GetFiles(GenDir, "his_*").Length == 0;
			string Uproject = Target.ProjectFile != null ? File.ReadAllText(Target.ProjectFile.FullName) : "";
			if (GenEmpty && !Uproject.Contains("his_core_gen.bat"))
			{
				throw new BuildException("HistoriaCore: Gen 폴더가 비었고 (" + GenDir + ") Historia.uproject PreBuildSteps 에 Tools\\his_core_gen.bat 도 없음 — " +
					"Tools\\his_core_gen.bat 를 먼저 돌리거나 PreBuildSteps 를 되살리세요 (바깥 소스가 없다는 오류면 Tools\\his_core_build.bat 부터).");
			}
			PrivateIncludePaths.Add(Path.Combine(Deps, "miniz-src"));
			PrivateIncludePaths.Add(Path.Combine(Deps, "miniz-build"));   // miniz_export.h (CMake 가 만듦)
			PrivateIncludePaths.Add(Path.Combine(Deps, "yyjson-src", "src"));
			PrivateIncludePaths.Add(Path.Combine(Deps, "stb-src"));
			PrivateDefinitions.Add("MINIZ_STATIC_DEFINE");

			// headless 설정에 맞춤: tools·bake 는 예외를 씀 → 모듈 전체 켬 · RTTI 끔 · 묶음 빌드 끔(파일마다 익명 이름공간) · PCH 없음
			bEnableExceptions = true;
			bUseRTTI = false;
			bUseUnity = false;
			PCHUsage = PCHUsageMode.NoPCHs;
			bDisableStaticAnalysis = true;
			CppCompileWarningSettings.ShadowVariableWarningLevel = WarningLevel.Off;
			CppCompileWarningSettings.UndefinedIdentifierWarningLevel = WarningLevel.Off;
			CppCompileWarningSettings.UnsafeTypeCastWarningLevel = WarningLevel.Off;
			bWarningsAsErrors = false;
		}
	}
}

// Config/HisCore.json 읽기 — Historia.Build.cs 도 같은 것을 씀
public class HisCore
{
	public string ProjectDir;
	public string HeadlessDir;
	public string LinkMode;
	public string DepsDir;

	// 평평한 JSON 의 문자열 칸 하나 (UBT 규칙 어셈블리엔 System.Text.Json 참조가 없음)
	static string Field(string Json, string Key)
	{
		Match M = Regex.Match(Json, "\"" + Regex.Escape(Key) + "\"\\s*:\\s*\"([^\"]*)\"");
		if (!M.Success) throw new BuildException("Config/HisCore.json 에 " + Key + " 없음");
		return M.Groups[1].Value;
	}

	public static HisCore Read(string ProjectDir)
	{
		HisCore C = new HisCore();
		C.ProjectDir = ProjectDir;
		string Json = File.ReadAllText(Path.Combine(ProjectDir, "Config", "HisCore.json"));
		string Dir = Field(Json, "headless_dir");
		C.LinkMode = Field(Json, "link_mode");
		C.DepsDir = Field(Json, "deps_dir");
		string Env = Environment.GetEnvironmentVariable("HISTORIA_HEADLESS");
		if (!string.IsNullOrEmpty(Env)) Dir = Env;
		string Name = Path.GetFileName(ProjectDir.TrimEnd(Path.DirectorySeparatorChar, Path.AltDirectorySeparatorChar));
		string Sub = Name.StartsWith("Historia") ? Name.Substring("Historia".Length) : "";
		Dir = Dir.Replace("{sub}", Sub);
		C.HeadlessDir = Path.GetFullPath(Path.IsPathRooted(Dir) ? Dir : Path.Combine(ProjectDir, Dir));
		if (!File.Exists(Path.Combine(C.HeadlessDir, "playheadless", "core.hpp")))
		{
			throw new BuildException("Config/HisCore.json headless_dir 가 historia-headless 가 아님: " + C.HeadlessDir);
		}
		return C;
	}
}

using System;
using System.Collections.Generic;
using System.IO;
using System.Text;
using System.Text.RegularExpressions;
using UnrealBuildTool;

// 거시 core 모듈 (TASK_거시연결 U0) — headless core(historia::Sim)를 감싼 손잡이 FHisMacroCore 만 내보낸다(HISTORIACORE_API).
// headless 코드엔 DLL 내보내기 표시가 없어서, 게임 모듈은 core 를 직접 부르지 않고 이 손잡이로만 부른다.
// 링크 길(Config/HisCore.json link_mode): prebuilt = ⓐ 미리 빌드한 정적 라이브러리 · source = ⓑ headless 소스를 이 모듈이 직접 컴파일
//   (Private/Gen/*.cpp = headless .cpp 를 #include 하는 한 줄짜리 — 빌드 때 headless CMakeLists 의 목록에서 만든다, git 밖. 소스 복사 아님)
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
			HisCore.WriteGen(GenDir, new List<string>());   // ⓑ 의 남은 것 지움
			string LibDir = Path.Combine(C.ProjectDir, "ThirdParty", "historia_core", "lib", "Win64");
			foreach (string Lib in new string[] { "historia_core", "historia_bakelib", "historia_tools", "historia_setting", "yyjson", "miniz" })
			{
				PublicAdditionalLibraries.Add(Path.Combine(LibDir, Lib + ".lib"));
			}
			PCHUsage = PCHUsageMode.UseExplicitOrSharedPCHs;
		}
		else
		{
			// ⓑ headless 의 정적 라이브러리 넷(core·setting·tools·bake) 소스 목록 = headless CMakeLists 그대로 + FetchContent 바깥 것(miniz·yyjson·stb)
			string Deps = Path.GetFullPath(Path.Combine(C.ProjectDir, C.DepsDir));
			List<string> Files = new List<string>();
			Files.AddRange(HisCore.CMakeSources(Path.Combine(C.HeadlessDir, "playheadless"), "historia_corelib"));
			foreach (string L in new string[] { "historia_setting", "historia_tools", "historia_bakelib" })
			{
				Files.AddRange(HisCore.CMakeSources(Path.Combine(C.HeadlessDir, "Startsetting"), L));
			}
			foreach (string F in new string[] { "miniz.c", "miniz_tdef.c", "miniz_tinfl.c", "miniz_zip.c" }) Files.Add(Path.Combine(Deps, "miniz-src", F));
			Files.Add(Path.Combine(Deps, "yyjson-src", "src", "yyjson.c"));
			HisCore.WriteGen(GenDir, Files);
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

	// CMakeLists.txt 의 add_library(Name STATIC 파일 …) 목록 → 절대 경로
	public static List<string> CMakeSources(string Dir, string Lib)
	{
		string Text = File.ReadAllText(Path.Combine(Dir, "CMakeLists.txt"));
		Match M = Regex.Match(Text, "add_library\\(\\s*" + Regex.Escape(Lib) + "\\s+STATIC([^)]*)\\)");
		if (!M.Success) throw new BuildException(Dir + "/CMakeLists.txt 에 add_library(" + Lib + " STATIC …) 없음");
		List<string> R = new List<string>();
		foreach (string Line in M.Groups[1].Value.Split('\n'))
		{
			string T = Line.Split('#')[0].Trim();
			if (T.EndsWith(".cpp") || T.EndsWith(".c")) R.Add(Path.GetFullPath(Path.Combine(Dir, T)));
		}
		return R;
	}

	// Gen 폴더 = 파일마다 한 줄 #include (같은 내용이면 다시 안 씀 — 빌드 시간)
	public static void WriteGen(string GenDir, List<string> Files)
	{
		HashSet<string> Keep = new HashSet<string>();
		if (Files.Count > 0) Directory.CreateDirectory(GenDir);
		for (int i = 0; i < Files.Count; ++i)
		{
			string F = Files[i];
			string D1 = Path.GetDirectoryName(F); string Rel = Path.GetFileName(Path.GetDirectoryName(D1)) + "_" + Path.GetFileName(D1) + "_" + Path.GetFileNameWithoutExtension(F);
			string Ext = F.EndsWith(".c") ? ".c" : ".cpp";
			string Out = Path.Combine(GenDir, "his_" + Rel + Ext);
			string Body = "// 만든 것 (HistoriaCore.Build.cs) — 고치지 말 것. headless 원본을 그대로 컴파일\n#include \"" + F.Replace('\\', '/') + "\"\n";
			Keep.Add(Out);
			if (!File.Exists(Out) || File.ReadAllText(Out) != Body) File.WriteAllText(Out, Body, new UTF8Encoding(false));
		}
		if (Directory.Exists(GenDir))
		{
			foreach (string Old in Directory.GetFiles(GenDir)) if (!Keep.Contains(Old)) File.Delete(Old);
		}
	}
}

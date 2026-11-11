using UnrealBuildTool;
using System.Collections.Generic;

public class HistoriaEditorTarget : TargetRules
{
	public HistoriaEditorTarget(TargetInfo Target) : base(Target)
	{
		Type = TargetType.Editor;
		DefaultBuildSettings = BuildSettingsVersion.V7;
		IncludeOrderVersion = EngineIncludeOrderVersion.Unreal5_8;
		ExtraModuleNames.Add("Historia");
	}
}

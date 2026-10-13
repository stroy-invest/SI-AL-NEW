codeunit 50572 "SI App Registry Mgt."
{
    // No persistent snapshots: the source of truth is the BC runtime.
    procedure LoadApplications(var Buffer: Record "SI App Registry Buffer" temporary)
    var
        InstalledApp: Record "NAV App Installed App";
        Info: ModuleInfo;
        Dep: ModuleDependencyInfo;
        Deps: List of [ModuleDependencyInfo];
        DepInfo: ModuleInfo;
    begin
        Buffer.Reset();
        Buffer.DeleteAll();
        if InstalledApp.FindSet() then
            repeat
                if NavApp.GetModuleInfo(InstalledApp."App ID", Info) then begin
                    Buffer.Init();
                    Buffer."App ID" := Info.Id();
                    Buffer."App Name" := CopyStr(Info.Name(), 1, MaxStrLen(Buffer."App Name"));
                    Buffer.Publisher := CopyStr(Info.Publisher(), 1, MaxStrLen(Buffer.Publisher));
                    Buffer."App Version" := Format(Info.AppVersion());
                    Buffer."Data Version" := Format(Info.DataVersion());
                    Buffer."Package ID" := Info.PackageId();
                    Buffer."Upgrade Pending" := Info.AppVersion() <> Info.DataVersion();
                    Deps := Info.Dependencies();
                    Buffer."Dependency Count" := Deps.Count();
                    foreach Dep in Deps do
                        if not NavApp.GetModuleInfo(Dep.Id(), DepInfo) then
                            Buffer."Missing Dependencies" += 1;
                    Buffer.Insert();
                end;
            until InstalledApp.Next() = 0;
    end;

    procedure LoadDependencies(AppId: Guid; var Buffer: Record "SI App Dependency Buffer" temporary)
    var
        Info: ModuleInfo;
        Dep: ModuleDependencyInfo;
        DepInfo: ModuleInfo;
        Deps: List of [ModuleDependencyInfo];
        LineNo: Integer;
    begin
        Buffer.Reset();
        Buffer.DeleteAll();
        if not NavApp.GetModuleInfo(AppId, Info) then
            exit;
        Deps := Info.Dependencies();
        foreach Dep in Deps do begin
            LineNo += 10000;
            Buffer.Init();
            Buffer."Line No." := LineNo;
            Buffer."Dependency App ID" := Dep.Id();
            Buffer."Dependency Name" := CopyStr(Dep.Name(), 1, MaxStrLen(Buffer."Dependency Name"));
            Buffer.Publisher := CopyStr(Dep.Publisher(), 1, MaxStrLen(Buffer.Publisher));
            Buffer.Installed := NavApp.GetModuleInfo(Dep.Id(), DepInfo);
            if Buffer.Installed then begin
                Buffer."Installed Version" := Format(DepInfo.AppVersion());
                Buffer.Status := 'Installed';
            end else
                Buffer.Status := 'Missing';
            Buffer.Insert();
        end;
    end;
}

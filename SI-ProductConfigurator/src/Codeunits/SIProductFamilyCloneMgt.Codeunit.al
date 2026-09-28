codeunit 53017 "SI Product Family Clone Mgt."
{
    procedure CloneFamily(
        SourceFamilyCode: Code[30];
        NewFamilyCode: Code[30];
        NewDescription: Text[100]): Code[30]
    var
        SourceFamily: Record "SI Product Family";
        NewFamily: Record "SI Product Family";
    begin
        SourceFamily.Get(SourceFamilyCode);

        NewFamilyCode := UpperCase(DelChr(NewFamilyCode, '<>', ' '));
        if NewFamilyCode = '' then
            Error(NewFamilyCodeRequiredErr);

        NewDescription := CopyStr(DelChr(NewDescription, '<>', ' '), 1, MaxStrLen(NewFamily.Description));
        if NewDescription = '' then
            Error(NewFamilyDescriptionRequiredErr);

        if NewFamily.Get(NewFamilyCode) then
            Error(FamilyAlreadyExistsErr, NewFamilyCode);

        NewFamily.Init();
        NewFamily.Code := NewFamilyCode;
        NewFamily.Description := NewDescription;

        // Minimal clone: copy only Family business setup.
        // Family Template is intentionally NOT copied and no template logic is invoked.
        NewFamily."Description EN" := SourceFamily."Description EN";
        NewFamily."Supports Recipes" := SourceFamily."Supports Recipes";
        NewFamily.Validate("Item Category Code", SourceFamily."Item Category Code");
        NewFamily.Validate("Base Unit of Measure", SourceFamily."Base Unit of Measure");
        NewFamily."Name Prefix" := SourceFamily."Name Prefix";
        NewFamily.Validate("Item Template Code", SourceFamily."Item Template Code");
        NewFamily.Validate("Item Code Prefix", SourceFamily."Item Code Prefix");
        NewFamily.Validate("Variant Code Prefix", SourceFamily."Variant Code Prefix");

        // Deliberately start the clone as a normal active family in the default sort position.
        NewFamily.Blocked := false;
        NewFamily."Sort Order" := 0;
        Clear(NewFamily."Family Template Code");
        NewFamily.Insert(true);

        CopyFamilyParameters(SourceFamily.Code, NewFamily.Code);

        exit(NewFamily.Code);
    end;

    local procedure CopyFamilyParameters(
        SourceFamilyCode: Code[30];
        TargetFamilyCode: Code[30])
    var
        SourceParameter: Record "SI Family Parameter";
        TargetParameter: Record "SI Family Parameter";
    begin
        SourceParameter.SetRange("Family Code", SourceFamilyCode);
        if SourceParameter.FindSet() then
            repeat
                TargetParameter.Init();
                TargetParameter."Family Code" := TargetFamilyCode;
                TargetParameter."Parameter Code" := SourceParameter."Parameter Code";
                TargetParameter."Parameter Order" := SourceParameter."Parameter Order";
                TargetParameter.Mandatory := SourceParameter.Mandatory;
                TargetParameter."Identity Parameter" := SourceParameter."Identity Parameter";
                TargetParameter."ERP Projection Role" := SourceParameter."ERP Projection Role";
                TargetParameter."Include in Description" := SourceParameter."Include in Description";
                TargetParameter."Description Order" := SourceParameter."Description Order";
                TargetParameter."Include in Code" := SourceParameter."Include in Code";
                TargetParameter."Code Order" := SourceParameter."Code Order";
                TargetParameter."Include in Search" := SourceParameter."Include in Search";
                TargetParameter."Recipe Relevant" := SourceParameter."Recipe Relevant";
                TargetParameter."Default Value Code" := SourceParameter."Default Value Code";
                TargetParameter.Blocked := SourceParameter.Blocked;
                TargetParameter.Insert(true);
            until SourceParameter.Next() = 0;
    end;

    var
        NewFamilyCodeRequiredErr: Label 'Вкажіть код нового сімейства.';
        NewFamilyDescriptionRequiredErr: Label 'Вкажіть назву нового сімейства.';
        FamilyAlreadyExistsErr: Label 'Сімейство з кодом %1 уже існує.';
}

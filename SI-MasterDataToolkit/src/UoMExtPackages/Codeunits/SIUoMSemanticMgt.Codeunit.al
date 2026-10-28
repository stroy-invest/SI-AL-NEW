codeunit 58020 "SI UoM Semantic Mgt."
{
    procedure ValidateScaledCompatibility(UoM: Record "Unit of Measure")
    var RefUoM: Record "Unit of Measure";
    begin
        if UoM."SI UoM Kind" <> UoM."SI UoM Kind"::Scaled then exit;
        if UoM."SI Reference UoM Code" = '' then exit;
        RefUoM.Get(UoM."SI Reference UoM Code");
        // During initial classification, allow either side to be unassigned.
        // Once both profiles are assigned, they must be identical.
        if (UoM."SI Semantic Profile Code" = '') or
           (RefUoM."SI Semantic Profile Code" = '') then
            exit;
        if UoM."SI Semantic Profile Code" <> RefUoM."SI Semantic Profile Code" then
            Error('Масштабована одиниця %1 (%2) та її базова одиниця %3 (%4) мають належати до одного семантичного профілю.',
                UoM.Code, UoM."SI Semantic Profile Code", RefUoM.Code, RefUoM."SI Semantic Profile Code");
    end;

    procedure ValidateUoMSemantics(UoM: Record "Unit of Measure")
    var Profile: Record "SI UoM Semantic Profile";
    begin
        if UoM."SI Semantic Profile Code" = '' then exit; // Backward-compatible until migration.
        Profile.Get(UoM."SI Semantic Profile Code");
        if Profile.Blocked then Error('Семантичний профіль %1 заблокований.', Profile.Code);
        if UoM."SI UoM Kind" = UoM."SI UoM Kind"::Packaging then begin
            if not Profile."Is Package" then
                Error('Пакувальна одиниця %1 має використовувати профіль з ознакою Паковання.', UoM.Code);
        end else
            if Profile."Is Package" then
                Error('Профіль Паковання не дозволено для непакувальної одиниці %1.', UoM.Code);
        ValidateScaledCompatibility(UoM);
    end;

    procedure ValidateExistingDependents(UoM: Record "Unit of Measure")
    var Child: Record "Unit of Measure";
    begin
        Child.SetRange("SI Reference UoM Code", UoM.Code);
        Child.SetRange("SI UoM Kind", Child."SI UoM Kind"::Scaled);
        if Child.FindSet() then
            repeat
                // Missing profiles are allowed while migrating existing UoMs.
                // A conflict is invalid only when both sides have profiles.
                if (Child."SI Semantic Profile Code" <> '') and
                   (UoM."SI Semantic Profile Code" <> '') and
                   (Child."SI Semantic Profile Code" <> UoM."SI Semantic Profile Code") then
                    Error('Зміна семантики %1 порушує зв’язок масштабування з %2.', UoM.Code, Child.Code);
            until Child.Next() = 0;
    end;

    procedure ValidateProfileChange(Profile: Record "SI UoM Semantic Profile")
    var UoM: Record "Unit of Measure";
    begin
        UoM.SetRange("SI Semantic Profile Code", Profile.Code);
        if UoM.FindSet() then
            repeat
                if (UoM."SI UoM Kind" = UoM."SI UoM Kind"::Packaging) <> Profile."Is Package" then
                    Error('Зміна ознаки Паковання для профілю %1 суперечить типу одиниці %2.', Profile.Code, UoM.Code);
            until UoM.Next() = 0;
    end;

    procedure AssertPhysicalUoM(UoMCode: Code[10]; RequiredSemantic: Code[30])
    var UoM: Record "Unit of Measure"; Profile: Record "SI UoM Semantic Profile";
    begin
        UoM.Get(UoMCode);
        UoM.TestField("SI Blocked", false);
        if UoM."SI UoM Kind" = UoM."SI UoM Kind"::Packaging then
            Error('Пакувальна одиниця %1 не може описувати фізичну місткість.', UoMCode);
        UoM.TestField("SI Semantic Profile Code");
        Profile.Get(UoM."SI Semantic Profile Code");
        if Profile.Blocked or Profile."Is Package" then
            Error('Семантичний профіль %1 не дозволений для фізичної місткості.', Profile.Code);
        if Profile.Code <> RequiredSemantic then
            Error('Одиниця %1 має семантику %2; потрібна %3.', UoMCode, Profile.Code, RequiredSemantic);
        ValidateUoMSemantics(UoM);
    end;
}

codeunit 53018 "SI Reference Parameter Mgt."
{
    procedure LookupValue(
        ProductConfig: Record "SI Product Config.";
        FamilyParameter: Record "SI Family Parameter";
        ReferenceType: Enum "SI Parameter Reference Type";
        CurrentSystemId: Guid;
        var SelectedSystemId: Guid;
        var SelectedKey: Text[250];
        var DisplayValue: Text[250]): Boolean
    var
        Handled: Boolean;
    begin
        OnLookupReferenceValue(
            ProductConfig,
            FamilyParameter,
            ReferenceType,
            CurrentSystemId,
            SelectedSystemId,
            SelectedKey,
            DisplayValue,
            Handled);

        if not Handled then
            Error(ReferenceProviderMissingErr, Format(ReferenceType));

        exit(not IsNullGuid(SelectedSystemId));
    end;

    procedure ValidateValue(
        ProductConfig: Record "SI Product Config.";
        FamilyParameter: Record "SI Family Parameter";
        ReferenceType: Enum "SI Parameter Reference Type";
        ReferenceSystemId: Guid;
        ReferenceKey: Text[250];
        DisplayValue: Text[250])
    var
        Handled: Boolean;
    begin
        if IsNullGuid(ReferenceSystemId) then
            Error(ReferenceValueRequiredErr, FamilyParameter."Parameter Code");

        OnValidateReferenceValue(
            ProductConfig,
            FamilyParameter,
            ReferenceType,
            ReferenceSystemId,
            ReferenceKey,
            DisplayValue,
            Handled);

        if not Handled then
            Error(ReferenceProviderMissingErr, Format(ReferenceType));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLookupReferenceValue(
        ProductConfig: Record "SI Product Config.";
        FamilyParameter: Record "SI Family Parameter";
        ReferenceType: Enum "SI Parameter Reference Type";
        CurrentSystemId: Guid;
        var SelectedSystemId: Guid;
        var SelectedKey: Text[250];
        var DisplayValue: Text[250];
        var Handled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateReferenceValue(
        ProductConfig: Record "SI Product Config.";
        FamilyParameter: Record "SI Family Parameter";
        ReferenceType: Enum "SI Parameter Reference Type";
        ReferenceSystemId: Guid;
        ReferenceKey: Text[250];
        DisplayValue: Text[250];
        var Handled: Boolean)
    begin
    end;

    var
        ReferenceProviderMissingErr: Label 'Для джерела посилального параметра «%1» не встановлено постачальника значень.';
        ReferenceValueRequiredErr: Label 'Для посилального параметра %1 потрібно вибрати значення.';
}

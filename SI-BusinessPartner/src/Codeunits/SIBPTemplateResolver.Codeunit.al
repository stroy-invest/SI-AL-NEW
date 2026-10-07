codeunit 54080 "SI BP Template Resolver"
{
    procedure ResolveTemplateCode(
        RoleType: Enum "SI BP Role Type";
        CountryRegionCode: Code[10];
        VATStatus: Enum "SI BP VAT Status"): Code[20]
    var
        TemplateSetting: Record "SI BP Template Setting";
        TemplateCode: Code[20];
    begin
        if CountryRegionCode = '' then
            Error(CountryRequiredErr);

        TemplateSetting.SetRange("Role Type", RoleType);
        TemplateSetting.SetRange("Country/Region Code", CountryRegionCode);
        TemplateSetting.SetRange("VAT Status", VATStatus);
        TemplateSetting.SetRange(Active, true);

        if not TemplateSetting.FindFirst() then
            Error(
                MappingNotFoundErr,
                Format(RoleType),
                CountryRegionCode,
                Format(VATStatus));

        TemplateCode := TemplateSetting."Template Code";

        if TemplateSetting.Next() <> 0 then
            Error(
                MappingAmbiguousErr,
                Format(RoleType),
                CountryRegionCode,
                Format(VATStatus));

        exit(TemplateCode);
    end;

    var
        CountryRequiredErr: Label 'Не вказано країну/регіон для визначення шаблону контрагента.';
        MappingNotFoundErr: Label 'Не знайдено активного налаштування шаблону для Тип ролі = %1, Країна/регіон = %2, Статус ПДВ = %3.', Comment = '%1 = Role Type, %2 = Country/Region Code, %3 = VAT Status';
        MappingAmbiguousErr: Label 'Знайдено більше одного активного налаштування шаблону для Тип ролі = %1, Країна/регіон = %2, Статус ПДВ = %3. Залиште активним лише одне правило.', Comment = '%1 = Role Type, %2 = Country/Region Code, %3 = VAT Status';
}

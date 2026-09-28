codeunit 50194 "SI Country Currency Mgt."
{
    procedure GetDefaultCurrency(
        CountryRegionCode: Code[10]
    ): Code[10]
    var
        CountryCurrency: Record "SI Country Currency";
    begin
        if CountryRegionCode = '' then
            exit('');

        CountryCurrency.SetCurrentKey(
            "Country/Region Code",
            Priority);

        CountryCurrency.SetRange(
            "Country/Region Code",
            CountryRegionCode);

        if CountryCurrency.FindFirst() then
            exit(CountryCurrency."Currency Code");

        exit('');
    end;
}
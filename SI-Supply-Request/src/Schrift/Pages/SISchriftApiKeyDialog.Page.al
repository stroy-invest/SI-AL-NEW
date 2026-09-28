page 61020 "SI Schrift API Key Dialog"
{
    PageType = StandardDialog;
    Caption = 'API-ключ Schrift';

    layout
    {
        area(Content)
        {
            field(ApiKeyValue; ApiKeyValue)
            {
                ApplicationArea = All;
                Caption = 'API-ключ';
                ExtendedDatatype = Masked;
            }
        }
    }

    procedure GetApiKey(): Text
    begin
        exit(ApiKeyValue);
    end;

    var
        ApiKeyValue: Text[250];
}

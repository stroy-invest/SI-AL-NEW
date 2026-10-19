page 54091 "SI BP EDS Route Lookup"
{
    Caption = 'Вибір маршруту EDS';
    PageType = List;
    SourceTable = "SI EDS Provider Route";
    SourceTableView = where(Enabled = const(true));
    ApplicationArea = All;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Routes)
            {
                field("Provider Code"; Rec."Provider Code")
                {
                    ApplicationArea = All;
                }
                field(ProviderDescription; ProviderDescription)
                {
                    Caption = 'Назва провайдера';
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Service Code"; Rec."Service Code")
                {
                    ApplicationArea = All;
                }
                field("Operation Code"; Rec."Operation Code")
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        Provider: Record "SI EDS Provider";
    begin
        Clear(ProviderDescription);
        if Provider.Get(Rec."Provider Code") then
            ProviderDescription := Provider.Description;
    end;

    var
        ProviderDescription: Text[250];
}

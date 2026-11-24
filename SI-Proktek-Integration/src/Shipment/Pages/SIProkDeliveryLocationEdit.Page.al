page 57189 "SI Prok Delivery Location Edit"
{
    PageType = StandardDialog;
    Caption = 'Редагувати місце довозу';
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            group(Delivery)
            {
                ShowCaption = false;
                field(SiteName; SiteNameValue)
                {
                    Caption = 'Точка розвантаження';
                    ApplicationArea = All;
                }
                field(Address; AddressValue)
                {
                    Caption = 'Адреса';
                    ApplicationArea = All;
                    ShowMandatory = true;
                }
            }
        }
    }

    procedure SetValues(NewSiteName: Text[255]; NewAddress: Text[255])
    begin
        SiteNameValue := NewSiteName;
        AddressValue := NewAddress;
    end;

    procedure GetValues(var NewSiteName: Text[255]; var NewAddress: Text[255])
    begin
        NewSiteName := SiteNameValue;
        NewAddress := AddressValue;
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction = Action::OK then
            if DelChr(AddressValue, '<>', ' ') = '' then
                Error('Адреса обов’язкова. Вкажіть адресу місця довозу.');
    end;

    var
        SiteNameValue: Text[255];
        AddressValue: Text[255];
}

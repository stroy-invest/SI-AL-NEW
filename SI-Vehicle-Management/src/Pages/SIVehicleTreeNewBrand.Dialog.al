page 63262 "SI Vehicle Tree New Brand"
{
    PageType = StandardDialog;
    Caption = 'Новий бренд транспорту';
    layout
    {
        area(Content)
        {
            field(BrandCode; BrandCode) { ApplicationArea = All; Caption = 'Код бренду'; }
            field(BrandName; BrandName) { ApplicationArea = All; Caption = 'Назва бренду'; }
        }
    }
    var
        BrandCode: Code[20];
        BrandName: Text[100];
    procedure GetValues(var NewCode: Code[20]; var NewName: Text[100])
    begin
        NewCode := BrandCode;
        NewName := BrandName;
    end;
}

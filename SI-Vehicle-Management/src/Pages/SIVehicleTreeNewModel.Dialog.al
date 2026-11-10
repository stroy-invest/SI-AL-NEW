page 63263 "SI Vehicle Tree New Model"
{
    PageType = StandardDialog;
    Caption = 'Нова модель транспорту';
    layout
    {
        area(Content)
        {
            field(BrandCode; BrandCode) { ApplicationArea = All; Caption = 'Бренд'; Editable = false; }
            field(TypeCode; TypeCode) { ApplicationArea = All; Caption = 'Тип транспорту'; Editable = false; }
            field(ModelCode; ModelCode) { ApplicationArea = All; Caption = 'Код моделі'; }
            field(ModelName; ModelName) { ApplicationArea = All; Caption = 'Назва моделі'; }
        }
    }
    var
        BrandCode: Code[20];
        TypeCode: Code[20];
        ModelCode: Code[20];
        ModelName: Text[100];
    procedure SetContext(NewBrand: Code[20]; NewType: Code[20])
    begin
        BrandCode := NewBrand;
        TypeCode := NewType;
    end;
    procedure GetValues(var NewCode: Code[20]; var NewName: Text[100])
    begin
        NewCode := ModelCode;
        NewName := ModelName;
    end;
}

page 61017 "SI Supply Source Locations"
{
    PageType = List;
    SourceTable = Location;
    Caption = 'Склади-джерела забезпечення';
    ApplicationArea = All;
    UsageCategory = None;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Locations)
            {
                field(Code; Rec.Code)
                {
                    ApplicationArea = All;
                    Caption = 'Код';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = All;
                    Caption = 'Назва';
                }
                field("SI Location Type Code"; Rec."SI Location Type Code")
                {
                    ApplicationArea = All;
                    Caption = 'Тип складу';
                }
            }
        }
    }
}

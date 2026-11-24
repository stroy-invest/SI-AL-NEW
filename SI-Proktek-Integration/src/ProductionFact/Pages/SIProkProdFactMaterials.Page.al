page 57092 "SI Prok Prod Fact Materials"
{
    PageType = ListPart;
    SourceTable = "SI Prok Prod Fact Material";
    Caption = 'Матеріали';
    ApplicationArea = All;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Material Name"; Rec."Material Name") { ApplicationArea = All; Caption = 'Матеріал'; }
                // Proktek material Requested/Actual/Variance values are stored in kilograms.
                // Never display the item's BC base UoM next to those source quantities.
                field(DisplayMassUoM; DisplayMassUoM)
                {
                    ApplicationArea = All;
                    Caption = 'Од. виміру';
                    ToolTip = 'Одиниця кількостей Proktek: кілограм. Код визначається через SI Master Data Toolkit.';
                }
                field("Requested Kg"; Rec."Requested Kg") { ApplicationArea = All; Caption = 'План, кг'; }
                field("Actual Kg"; Rec."Actual Kg") { ApplicationArea = All; Caption = 'Факт, кг'; }
                field("Variance Kg"; Rec."Variance Kg") { ApplicationArea = All; Caption = 'Відхилення, кг'; }
            }
        }
    }
    var
        DisplayMassUoM: Code[10];

    trigger OnAfterGetRecord()
    var
        Converter: Codeunit "SI Item UoM Conversion";
    begin
        DisplayMassUoM := Converter.ResolveLocalUoMCode('KG');
    end;
}

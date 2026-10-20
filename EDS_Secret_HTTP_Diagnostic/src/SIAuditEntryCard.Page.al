page 70026 "SI Audit Entry Card"
{
    PageType = Card;
    SourceTable = "SI Audit Entry";
    Caption = 'Картка перевірки контрагента';
    ApplicationArea = All;
    Editable = false;
    layout
    {
        area(Content)
        {
            group(Source)
            {
                Caption = 'Дані 1С';
                field("Batch No."; Rec."Batch No.") { ApplicationArea = All; }
                field("Entry No."; Rec."Entry No.") { ApplicationArea = All; }
                field(Code1C; Rec.Code1C) { ApplicationArea = All; }
                field(EDRPOU; Rec.EDRPOU) { ApplicationArea = All; }
                field("Source Legal Form"; Rec."Source Legal Form") { ApplicationArea = All; }
                field("Source Name"; Rec."Source Name") { ApplicationArea = All; }
            }
            group(Comparison)
            {
                Caption = 'Порівняння назв';
                field("Full Name 1C"; Rec."Full Name 1C") { ApplicationArea = All; MultiLine = true; }
                field("Registry Full Name"; Rec."Registry Full Name") { ApplicationArea = All; MultiLine = true; }
                field("Normalized Name 1C"; Rec."Normalized Name 1C") { ApplicationArea = All; MultiLine = true; }
                field("Normalized Registry Name"; Rec."Normalized Registry Name") { ApplicationArea = All; MultiLine = true; }
            }
            group(Outcome)
            {
                Caption = 'Результат аудиту';
                field("Processing Status"; Rec."Processing Status") { ApplicationArea = All; }
                field("Result Code"; Rec."Result Code") { ApplicationArea = All; }
                field("Result Details"; Rec."Result Details") { ApplicationArea = All; MultiLine = true; }
                field("Audit BP No."; Rec."Audit BP No.") { ApplicationArea = All; }
            }
        }
    }
}

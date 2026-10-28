table 58020 "SI UoM Semantic Profile"
{
    Caption = 'Семантичний профіль UoM';
    DataClassification = CustomerContent;
    LookupPageId = "SI UoM Semantic Profiles";
    DrillDownPageId = "SI UoM Semantic Profiles";
    fields
    {
        field(1; Code; Code[30]) { Caption = 'Код'; NotBlank = true; }
        field(2; Description; Text[100]) { Caption = 'Назва'; }
        field(3; "Is Package"; Boolean)
        {
            Caption = 'Паковання';
            trigger OnValidate()
            var Mgt: Codeunit "SI UoM Semantic Mgt.";
            begin
                Mgt.ValidateProfileChange(Rec);
            end;
        }
        field(4; Blocked; Boolean) { Caption = 'Заблоковано'; }
    }
    keys { key(PK; Code) { Clustered = true; } }
    trigger OnDelete()
    var UoM: Record "Unit of Measure";
    begin
        UoM.SetRange("SI Semantic Profile Code", Code);
        if not UoM.IsEmpty() then
            Error('Профіль %1 використовується одиницями вимірювання.', Code);
    end;
}

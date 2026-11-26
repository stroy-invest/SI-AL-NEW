page 53032 "SI Family Template Parameters"
{
    PageType = ListPart;
    SourceTable = "SI Family Template Parameter";
    ApplicationArea = All;
    Caption = 'Параметри шаблону';
    DelayedInsert = true;

    layout
    {
        area(Content)
        {
            repeater(Parameters)
            {
                field("Parameter Code"; Rec."Parameter Code") { ApplicationArea = All; }
                field("Parameter Order"; Rec."Parameter Order") { ApplicationArea = All; }
                field("Requirement Group Code"; Rec."Requirement Group Code") { ApplicationArea = All; }
                field(Mandatory; Rec.Mandatory) { ApplicationArea = All; }
                field("ERP Projection Role"; Rec."ERP Projection Role") { ApplicationArea = All; }
                field("Include in Description"; Rec."Include in Description") { ApplicationArea = All; }
                field("Description Order"; Rec."Description Order") { ApplicationArea = All; Editable = Rec."Include in Description"; }
                field("Include in Search"; Rec."Include in Search") { ApplicationArea = All; }
                field("Recipe Relevant"; Rec."Recipe Relevant") { ApplicationArea = All; }
                field("Default Value Code"; Rec."Default Value Code") { ApplicationArea = All;
                    trigger OnLookup(var Text: Text): Boolean
                    var Source: Codeunit "SI Dynamic Value Source"; SelectedCode: Code[30];
                    begin
                        if not Source.Lookup(Rec."Parameter Code", SelectedCode) then exit(false);
                        Text := SelectedCode;
                        exit(true);
                    end;
 }
                field(Blocked; Rec.Blocked) { ApplicationArea = All; }
            }
        }
    }
}

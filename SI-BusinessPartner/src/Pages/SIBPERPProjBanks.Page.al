page 54061 "SI BP ERP Proj. Banks"
{
    PageType = ListPart;
    SourceTable = "SI BP ERP Proj. Bank";

    Caption = 'Банківські рахунки';
    ApplicationArea = All;

    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field(Code; Rec.Code)
                {
                    ApplicationArea = All;
                }

                field(IBAN; Rec.IBAN)
                {
                    ApplicationArea = All;
                }

                field("Bank Name"; Rec."Bank Name")
                {
                    ApplicationArea = All;
                }

                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = All;
                }

                field(MFO; Rec.MFO)
                {
                    ApplicationArea = All;
                }

                field(Primary; Rec.Primary)
                {
                    ApplicationArea = All;
                }
            }
        }
    }
}
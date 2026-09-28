page 52044 "SI Supply Decision Lines"
{
    PageType = ListPart;
    SourceTable = "SI Supply Decision Line";
    ApplicationArea = All;
    Caption = 'Рядки заявки';

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Request Line No."; Rec."Request Line No.")
                {
                    ApplicationArea = All;
                    Visible = false;
                    Editable = false;
                }
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Requested Quantity"; Rec."Requested Quantity")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Allocated Quantity"; Rec."Allocated Quantity")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field(RemainingQuantity; Rec.GetRemainingQuantity())
                {
                    ApplicationArea = All;
                    Caption = 'Нерозподілена кількість';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Required Date"; Rec."Required Date")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = All;
                    Editable = IsPageEditable;
                }
                field(Comment; Rec.Comment)
                {
                    ApplicationArea = All;
                    Editable = IsPageEditable;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        SetPageState();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        SetPageState();
    end;

    local procedure SetPageState()
    var
        DecisionHeader: Record "SI Supply Decision Header";
    begin
        IsPageEditable := false;

        if DecisionHeader.Get(Rec."Document No.") then
            IsPageEditable :=
                DecisionHeader.Status = DecisionHeader.Status::Draft;
    end;

    var
        IsPageEditable: Boolean;
}
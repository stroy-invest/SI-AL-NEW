page 61042 "SI VSC Resolver Results"
{
    Caption = 'Вибір постачання';
    PageType = List;
    SourceTable = "SI VSC Candidate";
    SourceTableTemporary = true;
    ApplicationArea = All;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Candidates)
            {
                field("Vendor Name"; Rec."Vendor Name") { ApplicationArea = All; Caption = 'Постачальник'; }
                field("Matched Category Description"; Rec."Matched Category Description") { ApplicationArea = All; Caption = 'Категорія постачання'; }
                field("Shipment Method Description"; Rec."Shipment Method Description") { ApplicationArea = All; Caption = 'Спосіб поставки'; }
                field("Suggested Purchase Quantity"; Rec."Suggested Purchase Quantity") { ApplicationArea = All; Caption = 'Рекомендована кількість'; }
                field("UoM Code"; Rec."UoM Code") { ApplicationArea = All; Caption = 'Од. вим.'; }
                field("Minimum Order Quantity"; Rec."Minimum Order Quantity") { ApplicationArea = All; Caption = 'Мінімальна партія'; }
                field("Order Multiple"; Rec."Order Multiple") { ApplicationArea = All; Caption = 'Кратність'; }
                field("Lead Time Calculation"; Rec."Lead Time Calculation") { ApplicationArea = All; Caption = 'Строк постачання'; }
                field("Earliest Delivery Date"; Rec."Earliest Delivery Date") { ApplicationArea = All; Caption = 'Можлива поставка'; }
            }
        }
    }

    procedure LoadCandidates(var TempCandidate: Record "SI VSC Candidate" temporary)
    begin
        Rec.Reset();
        Rec.DeleteAll();
        TempCandidate.Reset();
        if TempCandidate.FindSet() then
            repeat
                Rec := TempCandidate;
                Rec.Insert();
            until TempCandidate.Next() = 0;
        Rec.Reset();
        if Rec.FindFirst() then;
    end;

    procedure GetSelectedCandidate(var Candidate: Record "SI VSC Candidate" temporary): Boolean
    begin
        if Rec."Capability Code" = '' then
            exit(false);
        Candidate := Rec;
        exit(true);
    end;
}

page 57143 "SI Prok Shipment Card"
{
    PageType = Card;
    SourceTable = "SI Prok Shipment";
    Caption = 'Документ відвантаження бетону';
    ApplicationArea = All;
    Editable = false;
    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'Відвантаження';
                field("Entry No."; Rec."Entry No.") { ApplicationArea = All; }
                field(Status; Rec.Status) { ApplicationArea = All; }
                field("Source Order No."; Rec."Source Order No.") { ApplicationArea = All; }
                field("BC Prod. Order No."; Rec."BC Prod. Order No.") { ApplicationArea = All; }
                field("Item No."; Rec."Item No.") { ApplicationArea = All; }
                field("Variant Code"; Rec."Variant Code") { ApplicationArea = All; }
                field("Recipe Name"; Rec."Recipe Name") { ApplicationArea = All; }
                field("Quantity M3"; Rec."Quantity M3") { ApplicationArea = All; }
                field("Simulation Quantity"; Rec."Simulation Quantity") { ApplicationArea = All; }
                field("Truck Plate"; Rec."Truck Plate") { ApplicationArea = All; }
                field("Employee No."; Rec."Employee No.") { ApplicationArea = All; }
                field("Driver Name"; Rec."Driver Name") { ApplicationArea = All; }
                field("Shipment Date/Time"; Rec."Shipment Date/Time") { ApplicationArea = All; }
            }
            group(Technical)
            {
                Caption = 'Зв’язки';
                field("Production UUID"; Rec."Production UUID") { ApplicationArea = All; }
                field("Production Fact Entry No."; Rec."Production Fact Entry No.") { ApplicationArea = All; }
                field("Prod. Request Entry No."; Rec."Prod. Request Entry No.") { ApplicationArea = All; }
                field("Driver UUID"; Rec."Driver UUID") { ApplicationArea = All; }
                field("Connection Code"; Rec."Connection Code") { ApplicationArea = All; }
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action(PrintPackage)
            {
                Caption = 'Надрукувати пакет документів';
                ApplicationArea = All;
                Image = Print;
                Enabled = IsOpen;
                trigger OnAction()
                begin
                    // PF-03.1 demo stub: no real printer invocation.
                    Rec.CloseAfterPrint();
                    CurrPage.Update(false);
                    Message('Заглушка друку виконана. Документ закрито; фізичний друк не виконувався.');
                end;
            }
            action(Reprint)
            {
                Caption = 'Повторити друк';
                ApplicationArea = All;
                Image = Print;
                Enabled = IsClosed;
                trigger OnAction()
                begin
                    // PF-03.1 demo stub. Closed status must not change.
                    Message('Заглушка повторного друку: реальний механізм друку ще не підключено. Статус не змінено.');
                end;
            }
        }
    }
    trigger OnAfterGetCurrRecord()
    begin
        IsOpen := Rec.Status = Rec.Status::Open;
        IsClosed := Rec.Status = Rec.Status::Closed;
    end;
    var
        IsOpen: Boolean;
        IsClosed: Boolean;
}

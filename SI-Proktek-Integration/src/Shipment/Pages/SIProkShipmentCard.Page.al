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
                field("Concrete Description"; Rec."Concrete Description") { ApplicationArea = All; }
                field("Quantity M3"; Rec."Quantity M3") { ApplicationArea = All; }
                //field("Simulation Quantity"; Rec."Simulation Quantity") { ApplicationArea = All; }
                field("Truck Plate"; Rec."Truck Plate") { ApplicationArea = All; }
                field("Driver Name"; Rec."Driver Name") { ApplicationArea = All; }
                field("Shipment Date/Time"; Rec."Shipment Date/Time") { ApplicationArea = All; }
            }
            group(Delivery)
            {
                Caption = 'Місце довозу';
                field("Delivery Site Name"; Rec."Delivery Site Name") { ApplicationArea = All; }
                field("Delivery Address"; Rec."Delivery Address") { ApplicationArea = All; }
            }
            group(Signatories)
            {
                Caption = 'Підписанти';
                field("Shipped By Name"; Rec."Shipped By Name") { ApplicationArea = All; }
                field("Received By Name"; Rec."Received By Name") { ApplicationArea = All; }
            }
        }
        area(FactBoxes)
        {
            part(TechnicalLinks; "SI Prok Shipment Links FB")
            {
                ApplicationArea = All;
                SubPageLink = "Entry No." = field("Entry No.");
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action(VerifyAllocationBinding)
            {
                Caption = 'Перевірити зв’язок із розподілом';
                ApplicationArea = All;
                Image = Refresh;
                Enabled = IsOpen;
                trigger OnAction()
                var
                    Binder: Codeunit "SI Prok Allocation Binder";
                begin
                    Binder.BindExistingOpen(Rec."Entry No.");
                    Rec.Get(Rec."Entry No.");
                    CurrPage.Update(false);
                    Message('Статус зв’язку: %1', Rec."Allocation Binding Status");
                end;
            }

            action(RefreshDocumentDetails)
            {
                Caption = 'Заповнити реквізити документа';
                ApplicationArea = All;
                Image = Refresh;
                Enabled = IsOpen;
                trigger OnAction()
                var
                    Snapshot: Codeunit "SI Prok Shipment Snapshot";
                begin
                    Snapshot.RefreshDeliveryExistingOpen(Rec."Entry No.");
                    Rec.Get(Rec."Entry No.");
                    CurrPage.Update(false);
                    Message('Стан реквізитів: %1', Rec."Document Snapshot Status");
                end;
            }
            action(ChangeShippedBy)
            {
                Caption = 'Змінити... (Відвантажив)';
                ApplicationArea = All;
                Image = Change;
                Enabled = IsOpen;
                trigger OnAction()
                begin
                    ChooseSignatory(true);
                end;
            }
            action(ChangeReceivedBy)
            {
                Caption = 'Змінити... (Прийняв)';
                ApplicationArea = All;
                Image = Change;
                Enabled = IsOpen;
                trigger OnAction()
                begin
                    ChooseSignatory(false);
                end;
            }
            action(ClearShippedBy)
            {
                Caption = 'Очистити підписанта (Відвантажив)';
                ApplicationArea = All;
                Image = Delete;
                Enabled = IsOpen;
                trigger OnAction()
                var
                    Snapshot: Codeunit "SI Prok Shipment Snapshot";
                begin
                    Snapshot.ClearSignatory(Rec."Entry No.", true);
                    Rec.Get(Rec."Entry No.");
                    CurrPage.Update(false);
                end;
            }
            action(ClearReceivedBy)
            {
                Caption = 'Очистити підписанта (Прийняв)';
                ApplicationArea = All;
                Image = Delete;
                Enabled = IsOpen;
                trigger OnAction()
                var
                    Snapshot: Codeunit "SI Prok Shipment Snapshot";
                begin
                    Snapshot.ClearSignatory(Rec."Entry No.", false);
                    Rec.Get(Rec."Entry No.");
                    CurrPage.Update(false);
                end;
            }
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
    local procedure ChooseSignatory(IsShipper: Boolean)
    var
        Employee: Record Employee;
        EmployeeList: Page "Employee List";
        Snapshot: Codeunit "SI Prok Shipment Snapshot";
    begin
        EmployeeList.LookupMode(true);
        if EmployeeList.RunModal() <> Action::LookupOK then
            exit;
        EmployeeList.GetRecord(Employee);
        Snapshot.OverrideSignatory(Rec."Entry No.", IsShipper, Employee."No.");
        Rec.Get(Rec."Entry No.");
        CurrPage.Update(false);
    end;

    trigger OnOpenPage()
    var
        Snapshot: Codeunit "SI Prok Shipment Snapshot";
    begin
        if (Rec.Status = Rec.Status::Open) and (Rec."Shipped By Employee No." = '') and
           (not Rec."Shipped By Manual") then begin
            Snapshot.InitializeExistingOpen(Rec."Entry No.");
            Rec.Get(Rec."Entry No.");
        end;
    end;

    trigger OnAfterGetCurrRecord()
    begin
        IsOpen := Rec.Status = Rec.Status::Open;
        IsClosed := Rec.Status = Rec.Status::Closed;
    end;

    var
        IsOpen: Boolean;
        IsClosed: Boolean;
}

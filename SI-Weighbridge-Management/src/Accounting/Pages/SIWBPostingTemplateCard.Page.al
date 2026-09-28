page 59131 "SI WB Posting Template Card"
{
    PageType = Card;
    SourceTable = "SI WB Posting Template";
    Caption = 'Шаблон обліку вагової';
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'Загальне';

                field(Code; Rec.Code)
                {
                    ApplicationArea = All;
                }

                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                }

                field(Enabled; Rec.Enabled)
                {
                    ApplicationArea = All;
                }

                field(Priority; Rec.Priority)
                {
                    ApplicationArea = All;
                }

                field("Valid From"; Rec."Valid From")
                {
                    ApplicationArea = All;
                }

                field("Valid To"; Rec."Valid To")
                {
                    ApplicationArea = All;
                }
            }

            group(Criteria)
            {
                Caption = 'Критерії маршрутизації';

                field("Operation Type"; Rec."Operation Type")
                {
                    ApplicationArea = All;
                    ValuesAllowed = Receipt, Shipment;
                    ToolTip = 'Доступні лише фізичні напрямки Надходження або Відвантаження.';

                    trigger OnValidate()
                    begin
                        SyncScenarioControls();
                        CurrPage.Update(false);
                    end;
                }

                field(ReceiptScenarioPick; ReceiptScenarioPick)
                {
                    ApplicationArea = All;
                    Caption = 'Тип операції';
                    Visible = ReceiptScenarioVisible;
                    Editable = false;
                    ToolTip = 'Для операції Надходження тип операції завжди Постачання.';
                }

                field(ShipmentScenarioPick; ShipmentScenarioPick)
                {
                    ApplicationArea = All;
                    Caption = 'Тип операції';
                    Visible = ShipmentScenarioVisible;
                    ToolTip = 'Для операції Відвантаження доступні лише Продаж або Внутрішнє переміщення.';

                    trigger OnValidate()
                    begin
                        case ShipmentScenarioPick of
                            "SI WB Shipment Scenario Pick"::Sales:
                                Rec.Validate("Shipment Scenario", "SI WB Shipment Scenario"::Sales);
                            "SI WB Shipment Scenario Pick"::"Internal Transfer":
                                Rec.Validate("Shipment Scenario", "SI WB Shipment Scenario"::"Internal Transfer");
                        end;
                        CurrPage.Update(false);
                    end;
                }

                field("Basis Type"; Rec."Basis Type")
                {
                    ApplicationArea = All;
                }

                field("Item Category Code"; Rec."Item Category Code")
                {
                    ApplicationArea = All;
                }

                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = All;
                }

                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = All;
                }
            }

            group(AccountingDefaults)
            {
                Caption = 'Облікові значення за замовчуванням';

                field("Default Location Code"; Rec."Default Location Code")
                {
                    ApplicationArea = All;
                }

                field("Gen. Bus. Posting Group"; Rec."Gen. Bus. Posting Group")
                {
                    ApplicationArea = All;
                }

                field("VAT Bus. Posting Group"; Rec."VAT Bus. Posting Group")
                {
                    ApplicationArea = All;
                }

                field("Customer Posting Group"; Rec."Customer Posting Group")
                {
                    ApplicationArea = All;
                }

                field("Vendor Posting Group"; Rec."Vendor Posting Group")
                {
                    ApplicationArea = All;
                }

                field("Gen. Prod. Posting Group"; Rec."Gen. Prod. Posting Group")
                {
                    ApplicationArea = All;
                }

                field("VAT Prod. Posting Group"; Rec."VAT Prod. Posting Group")
                {
                    ApplicationArea = All;
                }

                field("Shortcut Dimension 1 Code"; Rec."Shortcut Dimension 1 Code")
                {
                    ApplicationArea = All;
                }

                field("Shortcut Dimension 2 Code"; Rec."Shortcut Dimension 2 Code")
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        SyncScenarioControls();
    end;

    trigger OnAfterGetRecord()
    begin
        SyncScenarioControls();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        SyncScenarioControls();
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        if Rec."Operation Type" = "SI WB Operation Type"::Undefined then
            Rec.Validate("Operation Type", "SI WB Operation Type"::Receipt);
        SyncScenarioControls();
    end;

    var
        ReceiptScenarioPick: Enum "SI WB Receipt Scenario Pick";
        ShipmentScenarioPick: Enum "SI WB Shipment Scenario Pick";
        //[InDataSet]
        ReceiptScenarioVisible: Boolean;
        //[InDataSet]
        ShipmentScenarioVisible: Boolean;

    local procedure SyncScenarioControls()
    begin
        case Rec."Operation Type" of
            "SI WB Operation Type"::Receipt:
                begin
                    if Rec."Shipment Scenario" <> "SI WB Shipment Scenario"::Supply then
                        Rec.Validate("Shipment Scenario", "SI WB Shipment Scenario"::Supply);
                    ReceiptScenarioPick := "SI WB Receipt Scenario Pick"::Supply;
                    ReceiptScenarioVisible := true;
                    ShipmentScenarioVisible := false;
                end;
            "SI WB Operation Type"::Shipment:
                begin
                    if not (Rec."Shipment Scenario" in [
                        "SI WB Shipment Scenario"::Sales,
                        "SI WB Shipment Scenario"::"Internal Transfer"])
                    then
                        Rec.Validate("Shipment Scenario", "SI WB Shipment Scenario"::Sales);

                    case Rec."Shipment Scenario" of
                        "SI WB Shipment Scenario"::"Internal Transfer":
                            ShipmentScenarioPick := "SI WB Shipment Scenario Pick"::"Internal Transfer";
                        else
                            ShipmentScenarioPick := "SI WB Shipment Scenario Pick"::Sales;
                    end;
                    ReceiptScenarioVisible := false;
                    ShipmentScenarioVisible := true;
                end;
            else begin
                // Undefined is not a valid UI state for posting templates.
                ReceiptScenarioVisible := false;
                ShipmentScenarioVisible := false;
            end;
        end;
    end;

}

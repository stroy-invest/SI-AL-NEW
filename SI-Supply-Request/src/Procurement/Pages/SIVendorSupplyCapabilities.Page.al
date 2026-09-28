page 61037 "SI Vendor Supply Capabilities"
{
    PageType = List;
    SourceTable = "SI Vendor Supply Capability";
    CardPageId = "SI Vendor Supply Cap. Card";
    Caption = 'Канали постачання постачальників';
    ApplicationArea = All;
    UsageCategory = Lists;

    layout
    {
        area(Content)
        {
            repeater(Capabilities)
            {
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Показує назву каналу постачання.';
                }
                field("Vendor Name"; Rec."Vendor Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Показує постачальника.';
                }
                field("Item Category Description"; Rec."Item Category Description")
                {
                    ApplicationArea = All;
                    ToolTip = 'Показує категорію товарів.';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                    ToolTip = 'Показує поточний стан каналу.';
                }
                field("Shipment Method Code"; Rec."Shipment Method Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Показує спосіб або умови поставки.';
                }
                field("Minimum Order Quantity"; Rec."Minimum Order Quantity")
                {
                    ApplicationArea = All;
                    ToolTip = 'Показує мінімальну кількість замовлення.';
                }
                field("Order Multiple"; Rec."Order Multiple")
                {
                    ApplicationArea = All;
                    ToolTip = 'Показує кратність замовлення.';
                }
                field("UoM Code"; Rec."UoM Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Показує одиницю виміру кількісних обмежень.';
                }
                field("Lead Time Calculation"; Rec."Lead Time Calculation")
                {
                    ApplicationArea = All;
                    ToolTip = 'Показує строк постачання.';
                }
                field(Code; Rec.Code)
                {
                    ApplicationArea = All;
                    ToolTip = 'Показує системний код каналу постачання.';
                }
                field("Vendor No."; Rec."Vendor No.")
                {
                    ApplicationArea = All;
                    Visible = false;
                    ToolTip = 'Показує номер постачальника.';
                }
                field("Item Category Code"; Rec."Item Category Code")
                {
                    ApplicationArea = All;
                    Visible = false;
                    ToolTip = 'Показує код категорії товарів.';
                }
            }
        }
    }
}

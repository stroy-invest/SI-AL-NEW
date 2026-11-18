
pageextension 65001 "SI IW IWSVehicle Card Ext"
    extends IWSVehicleCard
{
    layout
    {
        modify("Registration No.")
        {
            Editable = false;
        }

        modify(Make)
        {
            Editable = false;
        }

        modify(Model)
        {
            Editable = false;
        }

        modify("Vehicle Category")
        {
            Editable = false;
        }

        modify("Storage Location")
        {
            Visible = false;
        }

        modify(Length)
        {
            Visible = false;
        }

        modify(Width)
        {
            Visible = false;
        }

        modify(Height)
        {
            Visible = false;
        }

        modify("Gross Weight")
        {
            Visible = false;
        }

        // Основні поля SI Vehicle Management
        addafter(Model)
        {
            field(SIVehicleTypeDescription; SIVehicleTypeDescription)
            {
                ApplicationArea = All;
                Caption = 'Тип транспорту';
                Editable = false;
            }
        }

        addafter("Vehicle Category")
        {
            field(SIVehicleOwnershipType; SIVehicleOwnershipType)
            {
                ApplicationArea = All;
                Caption = 'Тип володіння';
                Editable = false;
            }

            field(SIVehicleVIN; SIVehicleVIN)
            {
                ApplicationArea = All;
                Caption = 'VIN';
                Editable = false;
            }
        }

        // Порядок стандартних полів IW
        moveafter("Registration No."; Make)
        moveafter(Make; Model)
        moveafter(SIVehicleTypeDescription; "Vehicle Category")

        // SI Capacity Grid
        addlast(Content)
        {
            group(SIVehicleCapacities)
            {
                Caption = 'Характеристики транспорту';

                usercontrol(CapacityGrid; "SI IW Capacity Grid")
                {
                    ApplicationArea = All;

                    trigger ControlReady()
                    begin
                        CapacityGridReady := true;
                        RefreshCapacityGrid();
                    end;
                }
            }
        }

        // Технічний зв'язок із SI Vehicle Management
        addlast(Content)
        {
            group(SIVehicleIntegration)
            {
                Caption = 'Інтеграція';

                field("SI Vehicle No."; Rec."SI Vehicle No.")
                {
                    ApplicationArea = All;
                    Caption = 'SI Vehicle No.';
                    ToolTip = 'Ідентифікатор транспортного засобу в SI Vehicle Management.';
                    Editable = false;
                }
            }
        }

        // Legacy-дані IW Foundation
        addlast(Content)
        {
            group(IWAdditionalData)
            {
                Caption = 'Додаткові дані IW Foundation';

                field(IWStorageLocation; Rec."Storage Location")
                {
                    ApplicationArea = All;
                    Caption = 'Місце зберігання';
                    Editable = false;
                }

                field(IWLength; Rec.Length)
                {
                    ApplicationArea = All;
                    Caption = 'Довжина, м';
                    Editable = false;
                }

                field(IWWidth; Rec.Width)
                {
                    ApplicationArea = All;
                    Caption = 'Ширина, м';
                    Editable = false;
                }

                field(IWHeight; Rec.Height)
                {
                    ApplicationArea = All;
                    Caption = 'Висота, м';
                    Editable = false;
                }

                field(IWGrossWeight; Rec."Gross Weight")
                {
                    ApplicationArea = All;
                    Caption = 'Маса брутто, т';
                    Editable = false;
                }
            }
        }
    }

    actions
    {
        addlast(Processing)
        {
            action(OpenSIVehicle)
            {
                ApplicationArea = All;
                Caption = 'Відкрити в SI Vehicle Management';
                ToolTip = 'Відкрити основну картку транспортного засобу для редагування.';
                Image = Navigate;

                trigger OnAction()
                var
                    SIVehicle: Record "SI Vehicle Profile";
                begin
                    Rec.TestField("SI Vehicle No.");

                    SIVehicle.Get(Rec."SI Vehicle No.");

                    Page.Run(Page::"SI Vehicle Card", SIVehicle);
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        LoadSIVehicleDetails();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        LoadSIVehicleDetails();
        RefreshCapacityGrid();
    end;

    local procedure LoadSIVehicleDetails()
    var
        SIVehicle: Record "SI Vehicle Profile";
        SIVehicleType: Record "SI Vehicle Type";
    begin
        Clear(SIVehicleTypeDescription);
        Clear(SIVehicleVIN);
        Clear(SIVehicleOwnershipType);

        if Rec."SI Vehicle No." = '' then
            exit;

        if not SIVehicle.Get(Rec."SI Vehicle No.") then
            exit;

        SIVehicleVIN := SIVehicle.VIN;
        SIVehicleOwnershipType := SIVehicle."Ownership Type";

        if SIVehicleType.Get(SIVehicle."Vehicle Type Code") then
            SIVehicleTypeDescription := SIVehicleType.Description;
    end;

    local procedure RefreshCapacityGrid()
    var
        Capacity: Record "SI Vehicle Capacity";
        CapacityType: Record "SI Vehicle Capacity Type";
        DataArray: JsonArray;
        DataObject: JsonObject;
        DataText: Text;
    begin
        if not CapacityGridReady then
            exit;

        if Rec."SI Vehicle No." <> '' then begin
            Capacity.SetRange("Vehicle No.", Rec."SI Vehicle No.");

            if Capacity.FindSet() then
                repeat
                    Clear(DataObject);

                    if CapacityType.Get(Capacity."Capacity Type Code") then
                        DataObject.Add('description', CapacityType.Description)
                    else
                        DataObject.Add('description', Capacity."Capacity Type Code");

                    DataObject.Add('nominal', Capacity."Nominal Quantity");
                    DataObject.Add('actual', Capacity."Actual Quantity");
                    DataObject.Add('uom', Capacity."Unit of Measure Code");

                    DataArray.Add(DataObject);
                until Capacity.Next() = 0;
        end;

        DataArray.WriteTo(DataText);
        CurrPage.CapacityGrid.SetData(DataText);
    end;

    var
        CapacityGridReady: Boolean;
        SIVehicleTypeDescription: Text[100];
        SIVehicleVIN: Code[50];
        SIVehicleOwnershipType: Enum "SI Vehicle Ownership Type";
}
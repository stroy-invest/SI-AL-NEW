page 63261 "SI Vehicle Model Char FactBox"
{
    PageType = ListPart;
    SourceTable = "SI Vehicle Model Capacity";
    SourceTableTemporary = true;
    Caption = 'Характеристики моделі';
    ApplicationArea = All;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Capacities)
            {
                field("Capacity Type Code"; Rec."Capacity Type Code") { ApplicationArea = All; }
                field(Quantity; Rec.Quantity) { ApplicationArea = All; }
                field("Unit of Measure Code"; Rec."Unit of Measure Code") { ApplicationArea = All; }
            }
        }
    }

    procedure SetModelContext(BrandCode: Code[20]; ModelCode: Code[20])
    var
        ModelCapacity: Record "SI Vehicle Model Capacity";
    begin
        // A temporary snapshot prevents stale rows from the previously selected model.
        Rec.Reset();
        Rec.DeleteAll();

        if (BrandCode <> '') and (ModelCode <> '') then begin
            ModelCapacity.SetRange("Brand Code", BrandCode);
            ModelCapacity.SetRange("Model Code", ModelCode);
            if ModelCapacity.FindSet() then
                repeat
                    Rec.Init();
                    Rec.TransferFields(ModelCapacity);
                    Rec.Insert();
                until ModelCapacity.Next() = 0;
        end;

        CurrPage.Update(false);
    end;
}

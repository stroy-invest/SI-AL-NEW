table 63200 "SI Vehicle Profile"
{
    Caption = 'Транспортний засіб';
    DataClassification = CustomerContent;
    LookupPageId = "SI Vehicle List";
    DrillDownPageId = "SI Vehicle List";
    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'Номер';
            // No. is assigned by the standard No. Series in OnInsert.
            // NotBlank on a non-editable page field prevents the initial insert.
            Editable = false;
        }
        field(2; Description; Text[100]) { Caption = 'Найменування'; }
        field(3; "Vehicle Type Code"; Code[20])
        {
            Caption = 'Тип транспорту';
            TableRelation = "SI Vehicle Type".Code;
            trigger OnValidate()
            var T: Record "SI Vehicle Type";
            begin
                if "Vehicle Type Code" = '' then exit;
                T.Get("Vehicle Type Code");
                T.TestField(Blocked, false);
            end;
        }
        field(4; "Registration No."; Code[20])
        {
            Caption = 'Державний номер';
            trigger OnValidate()
            var Mgt: Codeunit "SI Vehicle Management";
            begin
                Mgt.AssertUniqueRegistration(Rec);
            end;
        }
        field(5; VIN; Code[50])
        {
            Caption = 'VIN';
            trigger OnValidate()
            var Mgt: Codeunit "SI Vehicle Management";
            begin
                Mgt.AssertUniqueVIN(Rec);
            end;
        }
        field(6; "Ownership Type"; Enum "SI Vehicle Ownership Type") { Caption = 'Тип володіння'; }
        field(7; "Fixed Asset No."; Code[20])
        {
            Caption = 'Основний засіб';
            TableRelation = "Fixed Asset"."No.";
        }
        field(8; Blocked; Boolean) { Caption = 'Заблоковано'; }
        field(9; "Search Description"; Code[100]) { Caption = 'Пошукове найменування'; }
        field(10; "Brand Code"; Code[20])
        {
            Caption = 'Бренд';
            TableRelation = "SI Vehicle Brand".Code where(Blocked = const(false));
            trigger OnValidate()
            var Brand: Record "SI Vehicle Brand"; Mgt: Codeunit "SI Vehicle Management";
            begin
                if "Brand Code" <> '' then begin
                    Brand.Get("Brand Code");
                    Brand.TestField(Blocked, false);
                end;
                if "Brand Code" <> xRec."Brand Code" then
                    "Model Code" := '';
                Mgt.RefreshVehicleDescription(Rec);
            end;
        }
        field(12; "Inventory No."; Code[30])
        {
            Caption = 'Інвентарний номер';
            trigger OnValidate()
            var Mgt: Codeunit "SI Vehicle Management";
            begin
                Mgt.AssertUniqueInventoryNo(Rec);
            end;
        }
        field(11; "Model Code"; Code[20])
        {
            Caption = 'Модель';
            TableRelation = "SI Vehicle Model".Code where("Brand Code" = field("Brand Code"), Blocked = const(false));
            trigger OnValidate()
            var Mgt: Codeunit "SI Vehicle Management";
            begin
                Mgt.AssertBrandModel(Rec);
                Mgt.RefreshVehicleDescription(Rec);
            end;
        }
    }
    keys
    {
        key(PK; "No.") { Clustered = true; }
        key(Type; "Vehicle Type Code") { }
        key(Registration; "Registration No.") { }
        key(FA; "Fixed Asset No.") { }
        key(Inventory; "Inventory No.") { }
    }
    trigger OnInsert()
    var Mgt: Codeunit "SI Vehicle Management";
    begin
        Mgt.AssignVehicleNo(Rec);
        Mgt.AssertUniqueVIN(Rec);
        Mgt.AssertUniqueRegistration(Rec);
        Mgt.AssertUniqueInventoryNo(Rec);
        Mgt.AssertBrandModel(Rec);
    end;
    trigger OnModify()
    var Mgt: Codeunit "SI Vehicle Management";
    begin
        Mgt.AssertUniqueVIN(Rec);
        Mgt.AssertUniqueRegistration(Rec);
        Mgt.AssertUniqueInventoryNo(Rec);
        Mgt.AssertBrandModel(Rec);
    end;
    trigger OnDelete()
    var Capacity: Record "SI Vehicle Capacity";
    begin
        Capacity.SetRange("Vehicle No.", "No.");
        if not Capacity.IsEmpty() then
            Error('Спочатку видаліть характеристики транспортного засобу %1.', "No.");
    end;
}

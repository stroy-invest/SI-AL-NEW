table 50501 "SI Location Setup"
{
    Caption = 'Налаштування типів складів';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Ключ';
        }
        field(10; "Finished Goods Type"; Code[20])
        {
            Caption = 'Склад ГП';
            TableRelation = "SI Location Type".Code where(Active = const(true));
        }
        field(11; "Main Warehouse Type"; Code[20])
        {
            Caption = 'Основний склад';
            TableRelation = "SI Location Type".Code where(Active = const(true));
        }
        field(12; "Material Warehouse Type"; Code[20])
        {
            Caption = 'Склад матеріалів';
            TableRelation = "SI Location Type".Code where(Active = const(true));
        }
        field(13; "Metal Warehouse Type"; Code[20])
        {
            Caption = 'Склад металовиробів';
            TableRelation = "SI Location Type".Code where(Active = const(true));
        }
        field(14; "Fuel Warehouse Type"; Code[20])
        {
            Caption = 'Склад ПММ';
            TableRelation = "SI Location Type".Code where(Active = const(true));
        }
        field(15; "Project Location Type"; Code[20])
        {
            Caption = 'Склад проєкту';
            TableRelation = "SI Location Type".Code where(Active = const(true));
        }
        field(16; "Department Location Type"; Code[20])
        {
            Caption = 'Склад підрозділу';
            TableRelation = "SI Location Type".Code where(Active = const(true));
        }
        field(17; "Vehicle Location Type"; Code[20])
        {
            Caption = 'Склад ТЗ';
            TableRelation = "SI Location Type".Code where(Active = const(true));
        }
        field(18; "Location No. Series"; Code[20])
        {
            Caption = 'Серія номерів складів';
            TableRelation = "No. Series".Code;
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(PK; "Primary Key") { Clustered = true; }
    }

    procedure UsesLocationType(LocationTypeCode: Code[20]): Boolean
    begin
        exit(("Finished Goods Type" = LocationTypeCode) or
             ("Main Warehouse Type" = LocationTypeCode) or
             ("Material Warehouse Type" = LocationTypeCode) or
             ("Metal Warehouse Type" = LocationTypeCode) or
             ("Fuel Warehouse Type" = LocationTypeCode) or
             ("Project Location Type" = LocationTypeCode) or
             ("Department Location Type" = LocationTypeCode) or
             ("Vehicle Location Type" = LocationTypeCode));
    end;
}

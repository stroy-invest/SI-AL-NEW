
table 65001 "SI IW Vehicle Type Mapping"
{
    Caption = 'SI IW Vehicle Type Mapping';
    DataClassification = CustomerContent;
    LookupPageId = "SI IW Vehicle Type Mappings";
    DrillDownPageId = "SI IW Vehicle Type Mappings";

    fields
    {
        field(1; "SI Vehicle Type Code"; Code[20])
        {
            Caption = 'SI Vehicle Type Code';
            DataClassification = CustomerContent;
            NotBlank = true;

            TableRelation = "SI Vehicle Type".Code;

            trigger OnValidate()
            var
                SIVehicleType: Record "SI Vehicle Type";
            begin
                if "SI Vehicle Type Code" = '' then
                    exit;

                SIVehicleType.Get("SI Vehicle Type Code");
                SIVehicleType.TestField(Blocked, false);
            end;
        }

        field(2; "IW Vehicle Category"; Enum IWSVehicleCategory)
        {
            Caption = 'IW Vehicle Category';
            DataClassification = CustomerContent;

            // Validation to ensure that if the mapping is enabled, the IW Vehicle Category must be specified.
            trigger OnValidate()
            begin
                if Enabled and ("IW Vehicle Category".AsInteger() = 0) then
                    Error('IW Vehicle Category must be specified for an enabled mapping.');
            end;
        }

        field(3; Enabled; Boolean)
        {
            Caption = 'Enabled';
            DataClassification = CustomerContent;
            InitValue = false;

            trigger OnValidate()
            var
                SIVehicleType: Record "SI Vehicle Type";
            begin
                if not Enabled then
                    exit;

                TestField("SI Vehicle Type Code");

                SIVehicleType.Get("SI Vehicle Type Code");
                SIVehicleType.TestField(Blocked, false);
            end;
        }
    }

    keys
    {
        key(PK; "SI Vehicle Type Code")
        {
            Clustered = true;
        }
    }
}
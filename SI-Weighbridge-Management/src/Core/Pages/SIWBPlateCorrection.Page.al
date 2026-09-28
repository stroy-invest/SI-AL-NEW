page 59003 "SI WB Plate Correction"
{
    PageType = StandardDialog;
    Caption = 'Виправлення номера транспортного засобу';

    layout
    {
        area(Content)
        {
            group(Vehicle)
            {
                Caption = 'Автомобіль';

                field(SourceVehiclePlate; SourceVehiclePlate)
                {
                    ApplicationArea = All;
                    Caption = 'Номер від камери';
                    Editable = false;
                }

                field(NewVehiclePlate; NewVehiclePlate)
                {
                    ApplicationArea = All;
                    Caption = 'Робочий номер';
                    Editable = CanEditVehicle;

                    trigger OnValidate()
                    var
                        PlateMgt: Codeunit "SI WB Plate Mgt.";
                    begin
                        if NewVehiclePlate = OriginalVehiclePlate then
                            exit;

                        PlateMgt.ValidateManualPlate(
                            NewVehiclePlate,
                            'Номер авто');
                    end;
                }

                field(VehicleCorrectionAllowed; CanEditVehicle)
                {
                    ApplicationArea = All;
                    Caption = 'Ручне виправлення дозволено';
                    Editable = false;
                }
            }

            group(Trailer)
            {
                Caption = 'Причіп';

                field(SourceTrailerPlate; SourceTrailerPlate)
                {
                    ApplicationArea = All;
                    Caption = 'Номер від камери';
                    Editable = false;
                }

                field(NewTrailerPlate; NewTrailerPlate)
                {
                    ApplicationArea = All;
                    Caption = 'Робочий номер';
                    Editable = CanEditTrailer;

                    trigger OnValidate()
                    var
                        PlateMgt: Codeunit "SI WB Plate Mgt.";
                    begin
                        if NewTrailerPlate = OriginalTrailerPlate then
                            exit;

                        PlateMgt.ValidateManualPlate(
                            NewTrailerPlate,
                            'Номер причепа');
                    end;
                }

                field(TrailerCorrectionAllowed; CanEditTrailer)
                {
                    ApplicationArea = All;
                    Caption = 'Ручне виправлення дозволено';
                    Editable = false;
                }
            }
        }
    }

    procedure SetWeighingRecord(
        WeighingRecord: Record "SI Weighing Record")
    var
        PlateMgt: Codeunit "SI WB Plate Mgt.";
    begin
        SourceVehiclePlate :=
            WeighingRecord."Source Vehicle Plate";

        SourceTrailerPlate :=
            WeighingRecord."Source Trailer Plate";

        OriginalVehiclePlate :=
            WeighingRecord."Vehicle Plate";

        OriginalTrailerPlate :=
            WeighingRecord."Trailer Plate";

        NewVehiclePlate :=
            WeighingRecord."Vehicle Plate";

        NewTrailerPlate :=
            WeighingRecord."Trailer Plate";

        CanEditVehicle :=
            PlateMgt.CanCorrectVehiclePlate(WeighingRecord);

        CanEditTrailer :=
            PlateMgt.CanCorrectTrailerPlate(WeighingRecord);
    end;

    procedure GetCorrectedPlates(
        var VehiclePlate: Text[50];
        var TrailerPlate: Text[50])
    begin
        VehiclePlate := NewVehiclePlate;
        TrailerPlate := NewTrailerPlate;
    end;

    var
        SourceVehiclePlate: Text[50];
        SourceTrailerPlate: Text[50];

        OriginalVehiclePlate: Text[50];
        OriginalTrailerPlate: Text[50];

        NewVehiclePlate: Text[50];
        NewTrailerPlate: Text[50];

        CanEditVehicle: Boolean;
        CanEditTrailer: Boolean;
}
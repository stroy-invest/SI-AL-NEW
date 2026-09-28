page 59001 "SI Weighing Record Card"
{
    PageType = Card;
    SourceTable = "SI Weighing Record";

    ApplicationArea = All;
    UsageCategory = None;

    Caption = 'Зважування';
    Editable = false;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'Загальне';

                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = All;
                }

                field("Event Date/Time"; Rec."Event Date/Time")
                {
                    ApplicationArea = All;
                }

                field("Site Code"; Rec."Site Code")
                {
                    ApplicationArea = All;
                }

                field("Scale No."; Rec."Scale No.")
                {
                    ApplicationArea = All;
                }
            }

            group(Weight)
            {
                Caption = 'Зважування';

                field("Gross Weight"; Rec."Gross Weight")
                {
                    ApplicationArea = All;
                }

                field("Tare Weight"; Rec."Tare Weight")
                {
                    ApplicationArea = All;
                }

                field("Net Weight"; Rec."Net Weight")
                {
                    ApplicationArea = All;
                }
            }

            group(Transport)
            {
                Caption = 'Транспорт';

                field("Vehicle Plate"; Rec."Vehicle Plate")
                {
                    ApplicationArea = All;
                }

                field("Vehicle Plate Source"; Rec."Vehicle Plate Source")
                {
                    ApplicationArea = All;
                }

                field("Source Vehicle Plate"; Rec."Source Vehicle Plate")
                {
                    ApplicationArea = All;
                }

                field("Vehicle Plate Corrected At"; Rec."Vehicle Plate Corrected At")
                {
                    ApplicationArea = All;
                }

                field("Vehicle Plate Corrected By"; Rec."Vehicle Plate Corrected By")
                {
                    ApplicationArea = All;
                }

                field("Trailer Plate"; Rec."Trailer Plate")
                {
                    ApplicationArea = All;
                }

                field("Trailer Plate Source"; Rec."Trailer Plate Source")
                {
                    ApplicationArea = All;
                }

                field("Source Trailer Plate"; Rec."Source Trailer Plate")
                {
                    ApplicationArea = All;
                }

                field("Trailer Plate Corrected At"; Rec."Trailer Plate Corrected At")
                {
                    ApplicationArea = All;
                }

                field("Trailer Plate Corrected By"; Rec."Trailer Plate Corrected By")
                {
                    ApplicationArea = All;
                }
            }

            group(Source)
            {
                Caption = 'Джерело';

                field("Source System"; Rec."Source System")
                {
                    ApplicationArea = All;
                }

                field("Source Table"; Rec."Source Table")
                {
                    ApplicationArea = All;
                }

                field("Source Record ID"; Rec."Source Record ID")
                {
                    ApplicationArea = All;
                }

                field("Source Event Type"; Rec."Source Event Type")
                {
                    ApplicationArea = All;
                }

                field("Source Evidence Record ID"; Rec."Source Evidence Record ID")
                {
                    ApplicationArea = All;
                }
            }

            group(EDS)
            {
                Caption = 'EDS';

                field("Inbound Entry No."; Rec."Inbound Entry No.")
                {
                    ApplicationArea = All;
                }

                field("External Event ID"; Rec."External Event ID")
                {
                    ApplicationArea = All;
                }
            }

            group(Audit)
            {
                Caption = 'Аудит';

                field("Created At"; Rec."Created At")
                {
                    ApplicationArea = All;
                }

                field("Created By"; Rec."Created By")
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(CorrectPlate)
            {
                ApplicationArea = All;
                Caption = 'Виправити номер ТЗ';

                trigger OnAction()
                var
                    PlateMgt: Codeunit "SI WB Plate Mgt.";
                    PlateCorrection: Page "SI WB Plate Correction";
                    NewVehiclePlate: Text[50];
                    NewTrailerPlate: Text[50];
                    CanCorrectVehicle: Boolean;
                    CanCorrectTrailer: Boolean;
                begin
                    CanCorrectVehicle :=
                        PlateMgt.CanCorrectVehiclePlate(Rec);

                    CanCorrectTrailer :=
                        PlateMgt.CanCorrectTrailerPlate(Rec);

                    if not CanCorrectVehicle and
                       not CanCorrectTrailer
                    then
                        Error(
                            'Ручне виправлення номера ТЗ не дозволено. Номери, отримані від камери, мають допустимий формат.');

                    Clear(PlateCorrection);

                    PlateCorrection.SetWeighingRecord(
                        Rec);

                    if PlateCorrection.RunModal() <>
                       Action::OK
                    then
                        exit;

                    PlateCorrection.GetCorrectedPlates(
                        NewVehiclePlate,
                        NewTrailerPlate);

                    PlateMgt.ApplyCorrection(
                        Rec,
                        NewVehiclePlate,
                        NewTrailerPlate);

                    CurrPage.Update(false);
                end;
            }

            action(CreateOperationalDocument)
            {
                ApplicationArea = All;
                Caption = 'Створити операційний документ';

                trigger OnAction()
                var
                    DocumentCreator: Codeunit "SI WB Document Creator";
                begin
                    DocumentCreator.CreateManuallyAndOpen(
                        Rec);
                end;
            }
        }

        area(Navigation)
        {
            action(OpenInboundEvent)
            {
                ApplicationArea = All;
                Caption = 'Вхідна подія EDS';

                trigger OnAction()
                var
                    InboundEvent: Record "SI EDS Inbound Event";
                begin
                    if not InboundEvent.Get(
                        Rec."Inbound Entry No.")
                    then
                        Error(
                            'EDS inbound event %1 не знайдено.',
                            Rec."Inbound Entry No.");

                    Page.Run(
                        Page::"SI EDS Inbound Event Card",
                        InboundEvent);
                end;
            }

            action(OpenOperationalDocument)
            {
                ApplicationArea = All;
                Caption = 'Операційний документ';

                trigger OnAction()
                var
                    WeighbridgeDocument: Record "SI Weighbridge Document";
                begin
                    WeighbridgeDocument.Reset();

                    WeighbridgeDocument.SetRange(
                        "Weighing Entry No.",
                        Rec."Entry No.");

                    if not WeighbridgeDocument.FindFirst() then
                        Error(
                            'Для зважування %1 операційний документ ще не створено.',
                            Rec."Entry No.");

                    Page.Run(
                        Page::"SI Weighbridge Document Card",
                        WeighbridgeDocument);
                end;
            }
        }
    }
}

codeunit 65002 "SI IW Vehicle Projection Mgt."
{
    procedure PublishVehicle(VehicleNo: Code[20])
    var
        SIVehicle: Record "SI Vehicle Profile";
        SIBrand: Record "SI Vehicle Brand";
        SIModel: Record "SI Vehicle Model";
        Mapping: Record "SI IW Vehicle Type Mapping";
        IWVehicle: Record IWSVehicle;
        ExistingProjection: Record IWSVehicle;
        RegistrationNo: Code[20];
        MakeName: Text[100];
        ModelName: Text[100];
    begin
        // 1. Resolve source vehicle.
        SIVehicle.Get(VehicleNo);
        SIVehicle.TestField("Registration No.");
        SIVehicle.TestField("Vehicle Type Code");
        SIVehicle.TestField("Brand Code");
        SIVehicle.TestField("Model Code");

        RegistrationNo := SIVehicle."Registration No.";

        // 2. Resolve brand.
        SIBrand.Get(SIVehicle."Brand Code");
        SIBrand.TestField(Name);
        MakeName := SIBrand.Name;

        if StrLen(MakeName) > MaxStrLen(IWVehicle.Make) then
            Error(
                'Vehicle %1: brand name exceeds IW Make length (%2).',
                VehicleNo,
                MaxStrLen(IWVehicle.Make));

        // 3. Resolve model using compound primary key.
        SIModel.Get(
            SIVehicle."Brand Code",
            SIVehicle."Model Code");

        SIModel.TestField(Name);
        ModelName := SIModel.Name;

        if StrLen(ModelName) > MaxStrLen(IWVehicle.Model) then
            Error(
                'Vehicle %1: model name exceeds IW Model length (%2).',
                VehicleNo,
                MaxStrLen(IWVehicle.Model));

        // 4. Resolve vehicle category mapping.
        if not Mapping.Get(SIVehicle."Vehicle Type Code") then
            Error(
                'IW category mapping not found for vehicle type %1.',
                SIVehicle."Vehicle Type Code");

        Mapping.TestField(Enabled, true);

        if Mapping."IW Vehicle Category".AsInteger() = 0 then
            Error(
                'IW category is not configured for vehicle type %1.',
                SIVehicle."Vehicle Type Code");

        // 5. Find projection by immutable SI identity.
        ExistingProjection.SetRange("SI Vehicle No.", VehicleNo);

        if ExistingProjection.FindFirst() then begin
            // No duplicates are allowed.
            if ExistingProjection.Count() > 1 then
                Error(
                    'Multiple IW projections found for SI vehicle %1.',
                    VehicleNo);

            // Registration number changes are out of scope.
            if ExistingProjection."Registration No." <> RegistrationNo then
                Error(
                    'Registration number mismatch for SI vehicle %1. ' +
                    'IW: %2, SI: %3. Automatic rename is not supported.',
                    VehicleNo,
                    ExistingProjection."Registration No.",
                    RegistrationNo);

            IWVehicle.Get(ExistingProjection."Registration No.");
        end else begin
            // Prevent collision with an unrelated IW record.
            if IWVehicle.Get(RegistrationNo) then
                Error(
                    'IW vehicle %1 already exists and is not linked ' +
                    'to SI vehicle %2.',
                    RegistrationNo,
                    VehicleNo);

            IWVehicle.Init();
            IWVehicle.Validate("Registration No.", RegistrationNo);
            IWVehicle.Validate("SI Vehicle No.", VehicleNo);

            IWVehicle.Validate("Make", MakeName);
            IWVehicle.Validate("Model", ModelName);
            IWVehicle.Validate("Vehicle Category", Mapping."IW Vehicle Category");

            IWVehicle.Insert(true);
            exit;
        end;

        // 6. Update only adapter-managed fields.
        // Legacy IW fields remain untouched.
        if (IWVehicle.Make = MakeName) and
           (IWVehicle.Model = ModelName) and
           (IWVehicle."Vehicle Category" =
                Mapping."IW Vehicle Category")
        then
            exit;

        IWVehicle.Validate("Make", MakeName);
        IWVehicle.Validate("Model", ModelName);
        IWVehicle.Validate("Vehicle Category", Mapping."IW Vehicle Category");

        IWVehicle.Modify(true);
    end;
}
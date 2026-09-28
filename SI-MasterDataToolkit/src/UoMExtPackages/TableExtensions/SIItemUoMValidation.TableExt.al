tableextension 58002 "SI Item UoM Validation" extends Item
{
    fields
    {
        modify("Base Unit of Measure")
        {
            trigger OnAfterValidate()
            var
                UoMMgt: Codeunit "SI UoM Mgt.";
                UoMWarning: Notification;
                WarningText: Text;
            begin
                WarningText := UoMMgt.GetUoMSetupWarning("Base Unit of Measure");
                if WarningText = '' then
                    exit;

                UoMWarning.Message := WarningText;
                UoMWarning.Scope := NotificationScope::LocalScope;
                UoMWarning.Send();
            end;
        }
    }
}

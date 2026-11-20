codeunit 57227 "SI Prok Prod Safe Guard"
{
    // TEMPORARY PROD-safe fence (Production Feedback Only).
    // Intentionally non-configurable. Remove only after accounting policy
    // and the end-to-end posting/printing workflow are approved and tested.
    // A UI action being hidden is NOT a security boundary.
    procedure AssertDisabled(Operation: Text)
    begin
        Error('SI Proktek PROD-safe: операція "%1" тимчасово заблокована. Дозволено отримання виробничих фактів і звіт План/Факт. Друк, закриття Shipment та складські/облікові операції не активовано.', Operation);
    end;
}

tableextension 57077 "SI Prok Supply Alloc Guard" extends "SI Supply Allocation"
{
    fields
    {
        modify("Selected Revision No.")
        {
            trigger OnAfterValidate()
            var
                Readiness: Codeunit "SI Prok Prod Readiness";
            begin
                if "Supply Method" <> "Supply Method"::Production then
                    exit;
                if ("Selected Recipe No." = '') or ("Selected Revision No." <= 0) then
                    exit;

                Readiness.ValidateRecipe("Selected Recipe No.", "Selected Revision No.");
            end;
        }
    }
}

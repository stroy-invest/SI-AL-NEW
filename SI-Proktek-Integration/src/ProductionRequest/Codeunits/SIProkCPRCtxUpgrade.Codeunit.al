codeunit 57071 "SI Prok CPR Ctx Upgrade"
{
    Subtype = Upgrade;

    trigger OnUpgradePerCompany()
    begin
        BackfillSupplyRequestContext();
    end;

    local procedure BackfillSupplyRequestContext()
    var
        ProdRequest: Record "SI Concrete Prod Request";
        Allocation: Record "SI Supply Allocation";
        DecisionHeader: Record "SI Supply Decision Header";
        RequestHeader: Record "SI Supply Req Header";
        Project: Record Job;
        Changed: Boolean;
    begin
        ProdRequest.SetRange("Source Type", ProdRequest."Source Type"::"Supply Request");
        if not ProdRequest.FindSet(true) then
            exit;

        repeat
            Clear(Allocation);
            Allocation.SetRange("Execution System ID", ProdRequest.SystemId);
            if not Allocation.FindFirst() then begin
                Allocation.Reset();
                if (ProdRequest."Supply Decision No." <> '') and
                   (ProdRequest."Supply Decision Line No." <> 0) and
                   (ProdRequest."Supply Allocation Line No." <> 0)
                then
                    if not Allocation.Get(
                        ProdRequest."Supply Decision No.",
                        ProdRequest."Supply Decision Line No.",
                        ProdRequest."Supply Allocation Line No.")
                    then
                        Clear(Allocation);
            end;

            if Allocation."Decision No." <> '' then begin
                Changed := false;

                if ProdRequest."Supply Decision No." = '' then begin
                    ProdRequest."Supply Decision No." := Allocation."Decision No.";
                    Changed := true;
                end;
                if ProdRequest."Supply Decision Line No." = 0 then begin
                    ProdRequest."Supply Decision Line No." := Allocation."Decision Line No.";
                    Changed := true;
                end;
                if ProdRequest."Supply Allocation Line No." = 0 then begin
                    ProdRequest."Supply Allocation Line No." := Allocation."Line No.";
                    Changed := true;
                end;
                if ProdRequest."Source Location Code" = '' then begin
                    ProdRequest."Source Location Code" := Allocation."Source Location Code";
                    Changed := true;
                end;
                ProdRequest."Supply Method" := Allocation."Supply Method";
                Changed := true;

                if ProdRequest."Location Code" = '' then begin
                    ProdRequest."Location Code" := Allocation."Target Location Code";
                    Changed := true;
                end;

                if DecisionHeader.Get(Allocation."Decision No.") then begin
                    if ProdRequest."Project No." = '' then begin
                        ProdRequest."Project No." := DecisionHeader."Project No.";
                        Changed := true;
                    end;
                    if ProdRequest."Project Location Code" = '' then begin
                        ProdRequest."Project Location Code" := DecisionHeader."Project Location Code";
                        Changed := true;
                    end;

                    if RequestHeader.Get(DecisionHeader."Request No.") then begin
                        ProdRequest."Request Type" := RequestHeader."Request Type";
                        Changed := true;
                    end;

                    if (DecisionHeader."Project No." <> '') and Project.Get(DecisionHeader."Project No.") then begin
                        if ProdRequest."Integration Customer No." = '' then begin
                            ProdRequest."Integration Customer No." := Project."SI Internal Customer No.";
                            Changed := true;
                        end;
                        if ProdRequest."Customer No." = '' then begin
                            ProdRequest."Customer No." := Project."SI Internal Customer No.";
                            Changed := true;
                        end;
                    end;
                end;

                if Changed then
                    ProdRequest.Modify(false);
            end;
        until ProdRequest.Next() = 0;
    end;
}

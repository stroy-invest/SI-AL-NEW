codeunit 57242 "SI Prok Internal Cust Resolver"
{
    // Resolves operational customer; never infers one from name or Proktek ID.
    procedure ResolveForPurpose(Purpose: Code[30]): Code[20]
    var
        Resolver: Codeunit "SI Internal Customer Resolver";
    begin
        exit(Resolver.ResolveCustomer(Purpose));
    end;

    procedure ResolveTechnological(): Code[20]
    begin
        exit(ResolveForPurpose('TECH-RECIPE'));
    end;

    procedure ResolveNoOrder(): Code[20]
    begin
        exit(ResolveForPurpose('NO-ORDER-PROD'));
    end;
}

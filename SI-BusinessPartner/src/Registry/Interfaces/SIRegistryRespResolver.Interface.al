interface "SI Registry Resp. Resolver"
{
    procedure ResolveResponse(
        ResponseText: Text;
        ProviderCode: Code[50];
        CountryRegionCode: Code[10];
        EntityType: Enum "SI BP Entity Type";
        IdentifierType: Enum "SI Registry Identifier Type";
        IdentifierValue: Text[50];
        var RegistryResult: Record "SI Registry Result" temporary);
}

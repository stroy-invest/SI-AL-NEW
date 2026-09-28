permissionset 59153 "SI WB ACCOUNTING"
{
    Assignable = true;
    Caption = 'SI Weighbridge - Accounting Access';

    Permissions =
        // ---------------------------------------------------------
        // Weighing facts - read only
        // ---------------------------------------------------------
        tabledata "SI Weighing Record" = R,
        table "SI Weighing Record" = X,

        // ---------------------------------------------------------
        // Operational documents
        // ---------------------------------------------------------
        tabledata "SI Weighbridge Document" = RM,
        table "SI Weighbridge Document" = X,

        tabledata "SI Weighbridge Document Line" = RIM,
        table "SI Weighbridge Document Line" = X,

        // ---------------------------------------------------------
        // Supporting documents
        // ---------------------------------------------------------
        tabledata "SI WB Supporting Document" = RM,
        table "SI WB Supporting Document" = X,

        // ---------------------------------------------------------
        // Technical queue - read only
        // ---------------------------------------------------------
        tabledata "SI WB Document Creation Queue" = R,
        table "SI WB Document Creation Queue" = X,

        // ---------------------------------------------------------
        // Accounting/reference configuration
        // ---------------------------------------------------------
        tabledata "SI WB Document Setup" = R,
        table "SI WB Document Setup" = X,

        tabledata "SI WB Posting Template" = R,
        table "SI WB Posting Template" = X,

        tabledata "SI WB Receipt Location Rule" = R,
        table "SI WB Receipt Location Rule" = X,

        // ---------------------------------------------------------
        // UI
        // ---------------------------------------------------------
        page "SI Weighing Records" = X,
        page "SI Weighing Record Card" = X,

        page "SI Weighbridge Documents" = X,
        page "SI Weighbridge Document Card" = X,
        page "SI Weighbridge Document Lines" = X,

        page "SI WB Supporting Docs FactBox" = X,
        page "SI WB ERP Document FactBox" = X,
        page "SI WB Audit FactBox" = X,
        page "SI WB Conversion Panel" = X,
        page "SI WB Supporting Documents" = X,

        // ---------------------------------------------------------
        // Accounting/business logic
        // ---------------------------------------------------------
        codeunit "SI WB Document Mgt." = X,
        codeunit "SI WB UoM Conversion Mgt." = X,
        codeunit "SI WB Supporting Docs Mgt." = X,
        codeunit "SI WB Document Generation Mgt." = X,
        codeunit "SI WB Posting Templ. Resolver" = X,
        codeunit "SI WB Posting Templ. Applier" = X;
}